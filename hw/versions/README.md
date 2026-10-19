# 独立硬件功能目录

每个硬件功能使用独立子目录保存对应 shell、配置、来源和验证入口；公共板级工程与工具链可复用。

| 目录 | 对应软件 | 说明 |
| --- | --- | --- |
| [l2_1m_4bank/](l2_1m_4bank/README.md) | [l2_1m_4bank](../../sw/board_tests/l2_1m_4bank/README.md) | 已生成候选对应的 1 MiB / 4 bank S1 L2 源码快照与私有 SoC 生成入口 |
| [dma_load_512kib_2bank/](dma_load_512kib_2bank/README.md) | [dma_load_512kib_2bank](../../sw/board_tests/dma_load_512kib_2bank/README.md)、[dma_spad_micro](../../sw/board_tests/dma_spad_micro/README.md) | 512 KiB / 2 bank、四种运行时 DMA/SPAD 模式的源码快照与私有生成入口；旧三模式产物单独追溯 |
| [activation_sram_512kib_2bank/](activation_sram_512kib_2bank/README.md) | [activation_sram_512kib_2bank](../../sw/board_tests/activation_sram_512kib_2bank/README.md)、[YOLO 对照](../../sw/board_tests/activation_sram_512kib_2bank/YOLO.md) | 从 DMA/SPAD 版本派生的 ASRAM-1：每路 2.25 MiB 私有 SRAM；比特流生成、通路诊断和整网四模式 DDR/ASRAM 板测通过，时序未收敛；见[验证状态](activation_sram_512kib_2bank/validation/status.json) |
| [dma_load_streaming_512kib_2bank/](dma_load_streaming_512kib_2bank/README.md) | DMA/SPAD 微基准及新候选诊断 ELF | A1 按行就绪流式重放；功能仿真、综合、首层及整网四模式板测通过，已生成验证比特流；时序未收敛；见[验证记录](dma_load_streaming_512kib_2bank/validation/README.md) |
| [dma_load_streaming_asram_512kib_2bank/](dma_load_streaming_asram_512kib_2bank/README.md) | [dma_load_streaming_asram_512kib_2bank](../../sw/board_tests/dma_load_streaming_asram_512kib_2bank/README.md) | DMA Stream A1 与三路私有 ASRAM 合并版；三路功能仿真和离线软件验证通过，未构建 bitstream；实际结果见[验证状态](dma_load_streaming_asram_512kib_2bank/validation/status.json) |

`hw/soc/` 仍保留仓库唯一的正式生成 SoC 导出；功能目录中的生成操作输出到私有工作区。
