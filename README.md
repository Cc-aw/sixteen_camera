# sixteen_camera

面向 Xilinx VU13P 的十六路视频与 AI 外设底座，供 SoC 开发人员合并到计算系统，或将新的 SoC 合并进本工程。仓库提供视频采集、DDR 数据通路、Tensor 生产、硬件后处理、显示叠加和配套裸机软件。

默认 `dual16` 是双 Gemmini16 集成示例；`single4` 是单 Gemmini4 示例。两者保留生成 RTL 和匹配固件 ABI。后续计算规模由接入的 SoC 决定，SoC 生成在计算侧工程完成。

```text
8 × OV7670 ───────────────┐
                          ├─ 16 路视频 ─┬─ RGB565 / DDR ─ mosaic ─ HDMI TX
4K30 HDMI ─ 裁剪 8 路视频 ┘             └─ INT8 Tensor ─ SoC ─ Head / PPU ─ overlay
```

## 目录

| 路径 | 内容 |
| --- | --- |
| `hw/rtl/` | 底座手写 RTL、总线接口、视频与 AI 外设 |
| `hw/constraints/` | 六份当前有效的板级约束 |
| `hw/ip/` | Xilinx IP 配置和配套输入 |
| `hw/soc/` | dual16 / single4 生成 SoC 集成示例 |
| `hw/vivado/`、`hw/manifests/` | XPR、DDR BD、建立脚本与生产输入清单 |
| `sw/src/`、`sw/models/` | 裸机软件、计算后端和当前 YOLOv5nu 模型 |
| `sw/third_party/` | 已验证的板级驱动、AMD BSP、Gemmini 头文件快照 |
| `tools/` | 构建、下载、生成、检查、时序分析与工具配置 |
| `tests/` | host 测试、RTL 回归、整数模型参考数据 |
| `docs/` | SoC 合并接口、架构、验证记录 |
| `build/` | 忽略的固件、工作工程、仿真、抓取与历史结果 |

## 构建

工具需单独安装：Vivado **2023.2**、支持 RV64GCV / LP64D 的 RISC-V GCC/GDB、支持 RISC-V BSCAN tunnel 的 OpenOCD、iverilog、Verilator、host C/C++ 编译器、Python 3.10+ 和 NumPy。源码依赖已收入仓库，无需外部 Chipyard、HDMI 或 BSP 源码目录。

工具默认从 PATH 查找；本机覆盖配置复制 [tools.example.mk](tools/config/tools.example.mk) 为 `tools/config/tools.local.mk`，后者不提交。Python 回归依赖见 [requirements.txt](tests/requirements.txt)。

```bash
make help
make check-deps
make firmware                       # dual16
make firmware SOC_VARIANT=single4
make elaborate SOC_VARIANT=single4  # Vivado RTL elaboration
make bitstream                      # 综合、实现及 bitstream
make test-software
make test-video
make test-tensor
make test-ppu
make test-cache SOC_VARIANT=single4
```

固件在 `build/firmware/`。命令行 Vivado 工作工程及 IP/BD 生成物在 `build/vivado/<配置>/`；每次 bitstream 和报告另存至 `build/bitstream/<配置>/<运行标识>/`。直接打开 XPR 的 GUI 会在项目旁创建 Vivado 临时目录。

## SoC 合并与下载

合并入口为 [top_wrapper.sv](hw/rtl/top_wrapper.sv) 和 [control_soc_subsystem.sv](hw/rtl/control/control_soc_subsystem.sv)。新 SoC 放入 `hw/soc/<配置名>/gen-collateral/`，兼容 harness 时用 `SOC_CONFIG=<配置名>` 选择硬件。软件 ABI、指令和缓存发布协议需要匹配；`SOC_CONFIG` 不自动选择固件。

具体交接步骤见 [SoC 合并指南](docs/integration/soc-integration.md)，源码说明见 [软件说明](sw/README.md)，验证范围见 [重构验收记录](docs/validation/structure-refactor.md)。

```bash
bash tools/program/download_bitstream.sh --bitstream /path/to/video.bit
make program PROGRAM_ARGS=--check    # 检查现有 ELF 和工具，不连接板卡
make program                        # 下载固件，需已加载匹配的 bitstream
make program SOC_VARIANT=single4
```

使用 `BOARD_JTAG_SERIAL` 选择适配器；默认不绑定某一块板卡。串口 115200 8N1，输入 `h` 查看命令。`make outputs` 查看本地产物；重构前的本地结果保存在 `build/history/`。文档导航见 [docs/README.md](docs/README.md)。
