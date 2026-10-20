# 独立 SoC 导入版本

按用户指定，外部已实现 SoC 版本存放在 `hw/soc/version/`；每版包含本地源快照、
生成导出、板级工程输入、产物身份及独立软件绑定。S1 已提升为默认生产版本，根目录 Makefile 与 current.json 直接选择它。
原有 `hw/versions/` 功能版本继续保留。

- [dma_load_streaming_asram_s1_512kib_2bank](dma_load_streaming_asram_s1_512kib_2bank/README.md)：
  S1 L2/板级时序优化，固定模式 2，实际导入比特流 ID `e037701c8d7cfc59`。
