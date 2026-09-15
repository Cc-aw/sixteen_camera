# YOLOv5nu 流式输入正式接入

默认 YOLOv5nu 构建使用 2×Gemmini16。顶层已移除旧的 `batch_preprocess_engine`：视频流直接写 640×480×3 NHWC RGB INT8 张量到 Arena0/1 的 32 个独立槽。旧帧缓冲和显示链路仍工作，但推理不再从 DDR framebuffer 读回并二次预处理。原 `p/x/f` 串口命令退出默认固件；移除前 CH1–CH16 的 `x` 同帧 921600 字节比较已全部由板上验证通过。

## 槽位与调度

每路两个槽，Arena0 的槽号 0–15、Arena1 的槽号 16–31。源帧抓取按通道轮转、同一时刻最多一帧，避免 16 路同时抓取时共用 AXI 写口导致的输入 FIFO 溢出。张量 writer 收到最后一个 AXI B 后才发布 READY。固件 `i` 从 READY 槽中选最新帧，过期帧释放；按最近服务时间公平分配给两个 Gemmini16 worker，同一路最多一个任务在途。任务完成（包括后处理）后才释放其输入槽，保证 Gemmini 仍在读取时不会被重写。该释放时机保守；未来后端提供 input-DMA-done 事件后可提前释放。

`m` 仍是只验证十六路张量写入和槽位元数据的诊断模式，与 `i` 互斥。`n` 仍能单路抓取到诊断地址。`s` 打印 `AI RT stream enable/drain/fault held/ready/writing/error`、任务完成/发布统计和逐路 dispatch/done/supersede/inflight/frame；`i` 再按一次停用并排空 READY 槽和运行中的 worker。

## 构建前检查

```bash
bash scripts/run_yolov5nu_tensor_slot_ingest_tests.sh
bash sw/test/run_ai_batch_runtime_stream_test.sh
make -C sw
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch \
  -source scripts/check_tensor_production_elaboration.tcl
```

这两项测试分别覆盖受限 AXI 写口下的轮转抓帧、槽位释放/错误恢复，以及较旧 READY 帧丢弃、双 worker 派发、运行期间保留槽位和停机排空。

## 板上验收

先按 `m`，观察每路完成计数增长，`overflow=0`、`error=0x00000000`，再按 `m` 排空。之后按 `i` 启动流式推理，隔一段时间按 `s`：各路 `dispatch/done` 应增长，`inflight` 不超过 1，总 `held` 只对应在途 worker，`pub` 增长、`err=0`；HDMI 视频与检测框正常。再按 `i` 停用，等待 `drain=0` 且 `held/ready/writing=0`。若 `fault=1` 或后端拒绝中止，输入槽会保持占用以防仍在执行的 DMA 被覆盖，应记录日志并复位检查。

本版本的轮转准入主动跳过其他路的部分源帧；因此 `missed` 正常增长，不能据此宣称达到文档的每路 30 FPS。板上尚未验证新 bitstream 的 `m/i` 结果，也尚未完成最终时序收敛。
