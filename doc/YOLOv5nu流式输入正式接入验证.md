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

共享 DMA 性能优化和本次元数据/EDF/TTL 改动尚未生成新 bitstream，因此当前结论限于 RTL/host 仿真与固件构建；板上吞吐、WNS 和新元数据寄存器仍需后续统一生成 bitstream 验证。
