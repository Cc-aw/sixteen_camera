# 固件源码依赖快照

这里保存双 DIM16 / 单 DIM4 视频固件实际使用的源码，不需要外部 Chipyard 或 HDMI 工程参与编译。

- `gemmini/`：当前 Taihang packed Gemmini ABI、RoCC 及两份参数头；保留上游 LICENSE。
- `gemmini_v3/`：V3 DIM32/FP16 三 worker ABI，参数直接来自本次生成的 SoC；独立来源锁见该目录。
- `board/`：已验证的 AXI IIC、时钟初始化和板级兼容头。
- `amd/`：AMD/Xilinx 2023.2 BSP 使用的八组驱动，仅保留编译源文件及相邻头文件；版本号在目录名中，版权和许可声明保留在源文件中。
- `sources.lock.json`：每个文件的原始来源及 SHA-256，基线提交 `3715539`。来源路径仅用于追溯，不参与构建。

依赖由两种固件的编译依赖文件提取，再补齐 BSP 相邻头文件。源码保持原样；本项目板级地址配置仍由 `sw/src/board/xparameters.h` 提供。

许可标识：Gemmini 保留上游 BSD 条款文件；AMD 驱动保留原有 MIT SPDX 标识；板级自定义源文件按原样保留，所复制的自定义文件未标注统一许可标识。具体声明以各文件头和 LICENSE 为准。
