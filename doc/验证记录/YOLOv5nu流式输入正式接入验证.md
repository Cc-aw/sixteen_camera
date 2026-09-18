# YOLOv5nu 流式输入正式接入

默认 YOLOv5nu 构建使用 2×Gemmini16。顶层已移除旧的 `batch_preprocess_engine`：视频流由共享多通道 Tensor DMA 直接写 640×480×3 NHWC RGB INT8 张量到 Arena0/1 的 32 个独立槽。旧帧缓冲和显示链路仍工作，但推理不再从 DDR framebuffer 读回并二次预处理。原 `p/x/f` 串口命令退出默认固件；移除前 CH1–CH16 的 `x` 同帧 921600 字节比较已全部由板上验证通过。

## 槽位与调度

每路两个槽，Arena0 的槽号 0–15、Arena1 的槽号 16–31。16 路 packer/FIFO 可同时接收视频；共享 DMA 在完整 burst payload 已缓存后，以 RR、水位和 aging 选择通道，并支持多笔 outstanding。最后一个 AXI B 返回后才发布 READY。固件 `i` 从 READY 槽中选最新 version，过期 READY 槽立即释放；以每路 33.333 ms deadline 执行 EDF，deadline 相同再选择较新的 frame，同一路最多一个任务在途。任务完成（包括后处理）后才释放其输入槽，保证 Gemmini 仍在读取时不会被重写。该释放时机保守；未来后端提供 input-DMA-done 事件后可提前释放。

## 完整槽位元数据

每路在源帧 SOF 接受时锁存 64 位 video-clock capture timestamp，并递增该 stream 独立的 32 位 version。每个物理槽保存 `tensor_addr/stream_id/frame_id/capture_timestamp/version/byte_count/state`；worker acquire 后的软件所有权记录补充 `RUNNING/owner_worker`。固件读取 descriptor 时前后两次读取 version，并同时验证 READY、stream、地址、字节数和状态，避免跨时钟同步期间接受半更新元数据。

在既有 `FRAMEBUFFER_TENSOR_PROD_INDEX` 选择槽位后，新增 MMIO 为：`0x328/0x32c` capture timestamp 低/高 32 位，`0x330` version，`0x334` stream，`0x338` tensor address，`0x33c` hardware state（FREE=0、WRITING=1、READY=2、ERROR=4），`0x340` error code。错误位定义为 stream/format `0x01`、FIFO overflow `0x02`、AXI response `0x04`、stop/cancel `0x08`。

## 调度与结果时效

每路保存 `last_complete_cycle/next_deadline/max_service_gap/missed_deadline_count`。worker 空闲时先选 deadline 最早的 READY stream，相同 deadline 选择 frame_id 较大的 descriptor。完成后下一 deadline 设为完成时刻加 33.333 ms。结果发布后启动 100 ms TTL；TTL 内没有更新时，Result Manager 使旧结果失效，并向 overlay 提交该 stream 的零框结果，避免旧检测框长期停留。串口 `s` 的逐路状态增加 `ver/deadline_miss/expire`。

`m` 仍是只验证十六路张量写入和槽位元数据的诊断模式，与 `i` 互斥。`n` 仍能单路抓取到诊断地址。`s` 打印 `AI RT stream enable/drain/fault held/ready/writing/error`、任务完成/发布统计和逐路 dispatch/done/supersede/inflight/frame；`i` 再按一次停用并排空 READY 槽和运行中的 worker。

## 构建前检查

```bash
bash scripts/run_yolov5nu_multi_channel_tensor_dma_tests.sh
bash sw/test/run_ai_batch_runtime_stream_test.sh
make -C sw
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch \
  -source scripts/check_tensor_production_elaboration.tcl
```

这两项测试分别覆盖多通道 burst 调度、槽位发布/元数据，以及较旧 READY 帧丢弃、双 worker 派发、EDF 优先级、运行期间保留槽位、Result TTL 清框和停机排空。

## 板上验收

先按 `m`，观察每路完成计数增长，`overflow=0`、`error=0x00000000`，再按 `m` 排空。之后按 `i` 启动流式推理，隔一段时间按 `s`：各路 `dispatch/done` 应增长，`inflight` 不超过 1，总 `held` 只对应在途 worker，`pub` 增长、`err=0`；HDMI 视频与检测框正常。再按 `i` 停用，等待 `drain=0` 且 `held/ready/writing=0`。若 `fault=1` 或后端拒绝中止，输入槽会保持占用以防仍在执行的 DMA 被覆盖，应记录日志并复位检查。

## 2026-09-18 板上状态

已使用拥塞优化布局布线生成的 bitstream 完成一轮 VU13P 板上验证。当前物理接入
CH1–CH8 摄像头，CH9–CH16 未接摄像头，因此以下正式数据链验收范围为前 8 路。

### 已通过项

- 固件正常启动，视频与 overlay 通路可用；固定 dog 框能成功提交到 CH1。
- CH1–CH8 依次执行 `n/N` sidecar 抓取全部 PASS。每路字节数均为
  `921600 = 640×480×3`，`nonzero > 0`，`overflows=0`。
- `m` 生产模式中 CH1–CH8 完成数均衡增长，实测末次为
  `21,21,21,21,21,21,21,20`；`no_slot=0`、`overflow=0`、
  `error=0x00000000`，停用后正常进入 `drained`。
- 共享 DMA 最大 outstanding 实测达到 8，AW burst 发出/完成均为
  `155682`，非 OKAY AXI 响应数为 0，表明 AW/W/B 独立推进和响应回收已在板上工作。
- `i` 流式 runtime 能够启动，两个 PPU worker 都有实际任务，观测到
  6300 positions 扫描、candidate 过滤和 NMS 完成。

### 当前性能与限制

这一轮 `m` 模式约 8 秒内每路增加 18–19 帧，当前约为 **2–3 FPS/路**，未达到
8 路各 30 FPS，也未达到文档的 16 路各 30 FPS 目标。同期累计计数为：

```text
missed/admit_skip/no_slot/overflow/error=
2006/2006/0/0/0x00000000
```

`missed` 与 `admit_skip` 完全相等，同时没有 no-slot、FIFO overflow 或 AXI error，说明帧是在
**SOF 准入阶段被主动跳过**，不是 DDR 写入失败。当前固件将
`FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT` 设为 1，一次只允许一路完整帧处于采集状态；
RTL 中 `admission_rr` 又每个 DDR 时钟轮转，只有当轮转令牌与该路单拍
`tap_sof` 同周期时才接收帧。这会产生额外的帧首等待，是当前低吞吐的直接原因。

后续修复需将“每拍转动令牌碰撞 SOF”改为能在帧边界稳定决策的准入机制，然后分阶段提高
`admission_limit`，先验证 8 路并发采集，再扩展到 16 路。每次提高并发度都应同时验收
`overflow=0`、`resp=0`、burst 发出/完成一致和全部已连接通道的完成数公平增长。

### 仍需补充的板上证据

- runtime 启动后连续运行 10–20 秒再按 `s`，确认 `jobs/done/post/pub` 持续且接近增长，
  `stale/err/last_err=0`，CH1–CH8 的 `dispatch/done` 全部增长且 `inflight<=1`。
- 等待停机后输出 `AI stream runtime drained`，并确认 `held/ready/writing=0`。
- 进行长时间压力测试；当前 bitstream 虽然可以启动和完成上述测试，最后一次布线阶段观测到的
  WNS 约为 `-8.373 ns`，主要由 Gemmini 时序路径主导，实现时序仍未签收。板上功能通过不代表
  已满足最终 PVT 稳定性。
