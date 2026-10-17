# 独立板测功能目录

每个新增板测功能使用自己的子目录，包含源码、头文件、模型输入、构建、下载、
日志解析、版本来源和使用说明。需要已有代码时复制到功能目录内并记录来源，
不通过软链接、相对路径或构建时 Git 提取依赖其他功能目录。

构建输出和日志留在各功能目录自己的 `build/`、`logs/`。安装的编译器、Vivado、
OpenOCD、GDB 等工具路径通过各目录的 `config.local.mk` 配置。

当前功能：`l2_1m_4bank/`，对应 S1 L2 1 MiB／4 bank 的独立板测包。

`dma_load_512kib_2bank/`：512 KiB／2 bank 的 DMA 短请求合并与 SPAD 行组装
三模式板测，包含首层、整网及跨批次 PPU 编号修复。使用方法见
[功能说明](dma_load_512kib_2bank/README.md)。

`dma_spad_micro/`：复用当前 DMA 候选的独立小 ELF，连续／非连续短行各对比三个
运行时模式，记录完整 mvin 批次周期、TL Get 和 SPAD 写次数；不带模型权重。
默认 C=12、N=32、P=2、非连续 stride=64，使用方法见
[微基准说明](dma_spad_micro/README.md)。
