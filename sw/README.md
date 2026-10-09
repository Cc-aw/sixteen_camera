# 视频与 AI 底座裸机软件

本目录提供板级初始化、摄像头/HDMI 服务、Tensor 与 Head 槽管理、YOLOv5nu 流式调度、PPU 和 overlay 驱动，以及 host 测试。SoC 计算实现通过 `src/ai/backend/` 接入。

## 集成示例

| 配置 | 计算示例 | ELF |
| --- | --- | --- |
| `dual16`（默认） | 双 Gemmini16 | `../build/firmware/gemmini_dual16_video_yolov5nu.elf` |
| `single4` | 单 Gemmini4 | `../build/firmware/gemmini_single4_video_yolov5nu.elf` |

在项目根目录运行 `make firmware SOC_VARIANT=dual16` 或 `single4`。直接 `make -C sw` 的输出在 `build/firmware/<配置>/hdmi_tx_test.*`；根目录构建入口生成上表中的交付 ELF。

软件依赖外部 RISC-V 工具链、Chipyard 的 Gemmini 头文件、参考 HDMI 工程的板级 IIC/时钟代码及 AMD 2023.2 BSP。通过根目录 `config/tools.local.mk` 或相应环境变量配置路径；示例见 `config/tools.example.mk`。

`src/platform/platform.h` 定义软件时钟、地址和寄存器；`src/ai/backend/ai_model_abi.h` 定义任务/完成契约。合并新 SoC 时还要匹配 Gemmini 参数、指令 opcode、busy/credit CSR 和缓存发布协议。硬件的 `SOC_CONFIG` 选择不会自动生成这些软件配置。

## 下载与检查

```bash
bash sw/run.sh --check
bash sw/run.sh --build
VIDEO_VARIANT=single4 bash sw/run.sh --check
make test-software
```

下载前需在 FPGA 中加载匹配的 bitstream。串口为 115200 8N1，输入 `h` 查看当前固件命令。`v` 查看视频，`s` 查看 AI 状态，`i` 启用或排空流式推理；诊断命令以源码帮助输出为准。

## 源码分层

- `src/board/`、`src/platform/`：板级配置、启动、控制台、缓存与基础运行时。
- `src/video/`：视频初始化和持续服务。
- `src/ai/runtime/`：Tensor/Head 所有权、调度和生命周期。
- `src/ai/backend/`：计算后端与 ABI。
- `src/ai/postprocess/`：PPU、结果管理和 overlay。
- `src/diagnostics/`：固定输入、后处理和带宽诊断。
- `yolov5/dim16_dual/`：现有单/双 worker 的 YOLOv5nu 模型适配与生成器。

YOLOv5nu 使用固定输入、模型和量化契约；迁入模型材料的来源说明见 [yolov5/README.md](yolov5/README.md)。
