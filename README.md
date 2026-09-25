# sixteen_camera

基于 Xilinx Virtex UltraScale+ VU13P 的 16 路视频采集、YOLOv5nu 推理与 HDMI 显示工程。当前 SoC 配置为 1 个 Rocket、1 个 RVV 和 1 个 4×4 Gemmini。

## 功能

- **视频输入**：8 路 OV7670 DVP 摄像头；另从一路 4K30 HDMI RGB888 输入中裁剪 8 路 640×480 视频。
- **摄像头接收**：300 MHz 采样与 PCLK 恢复、HREF/VSYNC 滤波、跨时钟域传输和坏帧恢复。
- **显示**：每路视频缩放为 360×270，按 RGB565 存入 DDR；16 路组成 1920×1080p60 的 4×4 mosaic。每路使用 4 个帧槽。
- **AI**：独立生成 640×480×3 INT8 Tensor，通过 FBus 供 Gemmini 执行 YOLOv5nu 推理，硬件后处理器完成分类筛选、DFL、BBox 和 NMS，并通过任务/结果队列直接发布显示框。
- **带宽与诊断**：FBus 读 ID 0～17、Tensor 写 ID 18～31；提供视频、AI 和带宽串口状态命令。

```text
8 × OV7670 ───────────────┐
                          ├─ 16 路视频 ─┬─ RGB565 帧缓存 ─ 4×4 mosaic ─ HDMI TX
4K30 HDMI ─ 裁剪 8 路视频 ┘             └─ INT8 Tensor ─ Gemmini ─ 后处理
```

显示帧在 DDR 中为 368×270 RGB565，其中 360×270 是有效图像，8 像素用于行对齐。HDMI 输入封装见 [4K30 空间封装规范](doc/接口规范/8路640x480视频在4K30_HDMI中的空间封装规范.md)；显示与采集实现见 [RGB565 与 PCLK 优化方案](doc/架构设计/sixteen_camera_Display_RGB565与PCLK_Capture优化方案.md)。

## 构建与运行

环境：Vivado 2023.2、RISC-V GCC/GDB、OpenOCD；仿真使用 iverilog 和 Verilator 5.x。

使用仓库中的 Vivado 工程生成比特流：

```bash
cd prj
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source build_bitstream.tcl
cd ..
```

比特流输出为 `prj/sixteen_camera.runs/impl_1/top_wrapper.bit`。单 4×4 视频推理固件使用独立脚本构建：

```bash
python3 scripts/build_single4_video_yolov5nu.py
```

输出为 `sw/build/gemmini_single4_video_yolov5nu.elf`。下载比特流和固件：

```bash
bash scripts/download_bitstream.sh
bash scripts/download_single4_video.sh
tio-start
```

`sw/run.sh` 和 `scripts/download_software.sh` 默认也使用这版单 4×4 固件。双 16×16 使用相同 PPU 功能，独立构建与下载：

```bash
python3 scripts/build_dual16_video_yolov5nu.py
bash scripts/download_dual16_video.sh
```

双 16×16 输出为 `sw/build/gemmini_dual16_video_yolov5nu.elf`，需匹配双 16×16 SoC。两个视频下载脚本支持 `--build` 和 `--check`；`ELF_FILE` 可覆盖文件路径。

## 串口命令

| 命令 | 功能 |
| --- | --- |
| `v` | 视频链路、帧缓存和 DMA 状态；再次输入可查看区间增量 |
| `s` | AI runtime 状态 |
| `i` | 启用或排空 AI stream runtime |
| `P` | PPU 分阶段性能计数 |
| `R` / `W` / `C` | FBus 读取、Tensor 写入、读写并发带宽诊断 |
| `r` | 重新初始化视频链路 |
| `c` | 读取板载时钟芯片 ID |

CH1～CH8 对应本地摄像头，CH9～CH16 对应 HDMI 裁剪通道。`PIPE ... tx_underflows` 与 `FB ... underflow` 分别表示 HDMI AXIS bridge 和 DDR reader 欠流。

## 目录

| 路径 | 内容 |
| --- | --- |
| `rtl/video/` | 摄像头、HDMI、帧缓存与显示 RTL |
| `rtl/ai/` | Tensor 数据通路与硬件后处理 |
| `generated/soc/` | Rocket/Chipyard SoC RTL |
| `build/*_manifest.tcl` | 构建使用的 RTL、SoC、IP 和约束清单 |
| `sw/` | 裸机软件与下载脚本 |
| `sim/` | 定向仿真测试平台 |
| `prj/` | Vivado 工程与构建脚本 |
| [`doc/`](doc/README.md) | 架构、接口与验证文档 |
