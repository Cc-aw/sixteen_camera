# 当前 SoC

正式 SoC 为 [DMA streaming + ASRAM S1](version/dma_load_streaming_asram_s1_512kib_2bank/README.md)，
源、生成导出、板级工程、约束、IP 和已验证比特流保存在这个版本目录。
[hw/manifests/current.json](../manifests/current.json) 为默认身份入口。

旧的 1 MiB / 4 bank 默认 SoC 导出和生成源码已删除，Git 历史保留原版本。
重新生成：根目录 `make soc SOC_WORKSPACE=<S1 build/下的新目录> SOC_OUTPUT=<新输出>`。
重新构建不覆盖导入的生成 RTL 和比特流。

独立开发候选位于 [hw/versions/](../versions/README.md)，包括基于当前 S1 的
[FIFO16 / 四条批量取表版本](../versions/dma_load_streaming_asram_s1_fifo16_batch4_512kib_2bank/README.md)。
