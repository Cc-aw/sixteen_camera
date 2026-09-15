# YOLOv5nu 流式张量旁路下板验证

本阶段使用当前 **1 Rocket + 1 Saturn RVV + 2×Gemmini16** 工程。视频采集原有路径、双 Arena 批量预处理和 YOLOv5nu 推理仍可独立运行。新增的诊断旁路从 16 路中选一路的已接受像素流，在下一帧 SOF 开始生成 640×480×3 NHWC RGB INT8 张量，写入一致性 FBus。量化与现有 YOLOv5nu 输入合同相同：RGB 各通道右移一位。

旁路以一次一帧的方式工作，可逐路验证 16 个输入。它尚未替换现有批量预处理调度，也不提供 16 路同时写张量的生产吞吐保证。`sw/src/ai_tensor_slot_pool.c` 已实现 32 个独立槽位的生命周期，但当前固件尚未将该槽池接到旁路命令或推理调度。

## 构建

```bash
bash scripts/run_yolov5nu_tensor_stream_tests.sh
bash scripts/run_yolov5nu_tensor_frame_writer_tests.sh
bash scripts/run_yolov5nu_tensor_capture_sidecar_tests.sh
bash scripts/run_axi4_write_arbiter2_tests.sh
bash sw/test/run_ai_tensor_slot_pool_test.sh
make -C sw
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch \
  -source scripts/build_tensor_sidecar_bitstream.tcl
```

构建脚本先把已有 `top_wrapper.bit` 备份到 `/tmp/sixteen_camera_before_tensor_sidecar.bit`，再重新综合、实现并生成 `prj/sixteen_camera.runs/impl_1/top_wrapper.bit`。综合或实现失败时不能使用旧的 `.bit` 声称本次旁路通过。

## 下板

使用现有的 `scripts/download_bitstream.sh` 下载新的 bitstream，再运行 `sw/run.sh` 下载本目录 `sw/build/hdmi_tx_test.elf`。串口 `115200 8N1`。固件启动时 AI 默认停用，可以直接按 `n` 抓取 CH1 的一帧；如果之前启用了 AI，先按 `i` 停用并等待 idle。按 `N` 切换到下一路（CH1→CH16 循环），再按 `n` 抓取。串口会打印 `TENSOR SIDECAR PASS/FAIL`、通道、帧号、921600 字节、FNV 哈希、非零字节数和累计 FIFO 溢出次数。

旁路写入专用诊断 DDR 地址 `0x33000000`；CPU 通过 `0xB3000000` 一致性别名读取。只有在 AI 停用、原预处理空闲时运行诊断，避免与其它 DDR 测试重叠。FIFO 溢出、坏帧、AXI 错误或帧超时会使状态报错；视频采集和显示本身不会被旁路反压。

### 下板结果（2026-09-14）

使用修正 `.sbss` 清零范围后的固件，用户反馈 CH1–CH16 逐路诊断抓取功能全部正常。提供的 CH1–CH7 串口日志均为 `TENSOR SIDECAR PASS`：每帧写入 921600 字节、读回数据非零、累计 FIFO 溢出为 0。CH8–CH16 的逐路正常结果由用户确认，未保存逐路原始日志。该结论覆盖单路一次一帧的板上写入和读回；同一帧与旧预处理张量逐字节比较、十六路并发吞吐及正式推理接入仍未验证。

## 寄存器

基址为 `FRAMEBUFFER_BASE` (`0x10140000`)。寄存器偏移：`0x2B0` 启动（写 bit0）、`0x2B4` 通道 0–15、`0x2B8` 32 字节对齐的张量物理地址、`0x2BC` 状态、`0x2C0` 完成帧号、`0x2C4` 已写字节、`0x2C8` 累计 FIFO 溢出。状态 bit0 为忙，bit1 为完成，bit2 为错误，bit3 为命令 CDC 忙，bit[7:4] 为完成通道。
