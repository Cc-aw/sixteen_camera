# sixteen_camera

面向 Xilinx VU13P 的十六路视频与 AI 外设底座，供 SoC 开发人员合并到计算系统，或将新的 SoC 合并进本工程。仓库负责板级视频、DDR 数据通路、Tensor 生产、硬件后处理、显示叠加及配套裸机软件；计算 SoC 通过明确的接口接入。

`generated/soc/` 与 `soc_shell/` 中保留双 Gemmini16 和单 Gemmini4 的集成示例。默认 `dual16` 仅用于已有示例的构建与检查，不规定后续 SoC 的计算规模。Gemmini64、N6 和专用实现流程已移除。

## 数据通路

- 输入：8 路 OV7670 DVP，以及一路 4K30 HDMI RGB888 中裁剪出的 8 路 640×480 视频。
- 显示：每路缩放为 360×270，按 RGB565 写入 DDR，每路四个帧槽；4×4 mosaic 输出 1920×1080p60。
- AI 输入：视频流独立生成 640×480×3 NHWC RGB INT8 Tensor，共 32 个输入槽；通过现有 coherent FBus 写入。
- 后处理：计算侧产生 YOLOv5nu raw heads，经 Head publication、URAM 和 PPU 完成分类筛选、DFL、BBox、NMS，再发布检测框与标签。
- 软件：裸机运行时管理视频初始化、Tensor/Head 槽所有权、推理调度、PPU 队列和串口诊断。

```text
8 × OV7670 ───────────────┐
                          ├─ 16 路视频 ─┬─ RGB565 / DDR ─ mosaic ─ HDMI TX
4K30 HDMI ─ 裁剪 8 路视频 ┘             └─ INT8 Tensor ─ 外部 SoC ─ Head / PPU ─ overlay
```

显示缓存每行为 368 像素，其中 360 像素有效，其余用于对齐。输入封装见 [HDMI 空间封装规范](doc/接口规范/8路640x480视频在4K30_HDMI中的空间封装规范.md)。

## SoC 合并入口

板级顶层为 `rtl/top_wrapper.sv`，计算侧适配入口为 `rtl/control/control_soc_subsystem.sv`。
现有连接契约包括 256-bit memory AXI、64-bit MMIO AXI、256-bit FBus AXI，以及 UART、复位和视频中断；具体地址/ID 位宽以顶层接口为准。

- `config/manifests/rtl_manifest.tcl`：底座手写 RTL 白名单。
- `config/manifests/soc_manifest.tcl`：选择计算侧生成 RTL。
- `config/manifests/ip_manifest.tcl`、`xdc_manifest.tcl`：板级 IP 和约束。
- `sw/src/platform/platform.h`：软件地址、时钟和外设寄存器。
- `sw/src/ai/backend/`：模型请求/完成 ABI 与计算后端。

新 SoC 放入 `generated/soc/<配置名>/gen-collateral/`，兼容现有 harness 接口时可直接用 `SOC_CONFIG=<配置名>` 选择。接口、时钟、缓存一致性或计算指令发生变化时，需要同步适配 wrapper、软件 ABI、参数头和约束。`SOC_CONFIG` 只选择硬件，不自动推导软件。

通用 Head 队列和 PPU 保留多 worker 的资源管理能力；这不依赖某种 Gemmini 阵列尺寸。

## 构建与验证

环境：Vivado 2023.2、RISC-V GCC/GDB、OpenOCD；定向仿真使用 iverilog、Verilator。
软件示例还依赖外部 Chipyard 和 HDMI BSP，路径覆盖见 `config/tools.example.mk`。

```bash
make help
make check
make firmware                         # dual16 示例
make bitstream                        # dual16 示例
make check SOC_VARIANT=single4
make bitstream SOC_CONFIG=<配置名>     # 新 SoC
make test-software
make test-tensor
make test-video
make test-ppu
```

固件输出在 `build/firmware/`，比特流及本次报告输出在 `build/bitstream/<配置>/<运行标识>/`。输入清单通过、仿真通过、生成比特流和板级验收是不同状态，构建后应检查本次时序与 DRC。

示例下载入口：

```bash
bash scripts/program/download_bitstream.sh --bitstream /path/to/video.bit
bash scripts/program/download_dual16_video.sh --check
bash scripts/program/download_dual16_video.sh
```

硬件与固件必须匹配。`sw/run.sh` 和 `download_software.sh` 默认使用 dual16；`VIDEO_VARIANT=single4` 选择单 worker 示例，`ELF_FILE` 可覆盖 ELF 路径。

## 目录与文档

| 路径 | 内容 |
| --- | --- |
| `rtl/` | 视频、DDR、Tensor、PPU、控制与总线接口 |
| `config/` | 生产输入清单与本机工具配置示例 |
| `generated/` | 集成示例的生成 SoC RTL 和 Xilinx IP |
| `soc_shell/` | 现有参考 SoC 生成材料 |
| `sw/` | 裸机软件、模型、后端 ABI 和 host 测试 |
| `scripts/`、`sim/` | 构建、下载、生成、检查和定向仿真 |
| `legacy/` | 已退出生产清单的历史实现 |
| `artifacts/` | 冻结的验证输入 |
| `build/`、`reports/` | 本地产物和历史验证证据 |
| [doc/](doc/README.md) | 架构、接口与验证导航 |

使用入口和功能定位见 [项目入口与功能索引](doc/实现记录/项目入口与功能索引.md)。历史文档保留当时配置和验收范围，不代表新合并 SoC 已通过验证。
