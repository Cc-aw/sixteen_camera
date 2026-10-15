# 工具入口

| 目录 | 用途 |
| --- | --- |
| `build/` | 当前视频固件和 Vivado 实现包装 |
| `soc/` | 独立 Chipyard 工作区准备、生成与导出；硬件源码在 `hw/soc/source/` |
| `program/` | bitstream / ELF 下载及本机 JTAG 配置 |
| `check/` | 当前身份、来源、依赖、ELF、工程和综合检查 |
| `generate/` | 跨子系统 LUT 与参考向量生成 |
| `analyze/yolov5nu/` | 当前三图 UART、credit、Pool/PPU 与性能分析 |
| `timing/` | 时序/实现报告分析 |
| `config/` | example 与忽略的本机覆盖 |

根目录 `make help` 提供常用入口，`make help-tests` 列出定向回归。
个人工具路径和 `SOC_REFERENCE` 只放在本机配置；原 donor/source 路径用于追溯，不作为生产输入。
SoC 生成保持正常 SBT/Chisel/firtool 与既有 RAM/实现策略；本地产物统一放入忽略的 `build/`。
