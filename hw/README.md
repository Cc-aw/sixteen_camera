# 当前硬件

默认版本是 [S1 DMA streaming + ASRAM](soc/version/dma_load_streaming_asram_s1_512kib_2bank/README.md)。
1 Rocket、1 RVV、3 × DIM32 Gemmini，100 MHz，L2 512 KiB / 2 bank，三路私有 ASRAM 各 2.25 MiB。
DMA 固定模式 2（read_assembled），row_ready_v1 流式回放；前端 FIFO 8、Get 32 B、IRQ13。

[当前清单](manifests/current.json) 唯一选择其生成 RTL、源快照、板级 RTL/IP/XDC、比特流和视频固件。
S1 的现有目录作为正式源目录，根目录 `make project / elaborate / synth / bitstream / soc` 调用该包。
旧默认的 `soc/source/` 及生成导出已删除，历史源码可由 Git 恢复。

比特流 ID `e037701c8d7cfc59`，SHA256 `cb907a77e0c0bf97f5074208956884517d349485003a8d6613ca61b9f7e93a01`。
已导入的 bit 位于 S1 包的 `bitstream/top_wrapper.bit`，按仓库规则不提交大型产物。
用户已验证实时视频识别，详见 [当前验证](../docs/validation/current.md)。导入 WNS −3.068 ns，不添加负时序 bitgen 门禁。

`rtl/`、`constraints/`、`ip/`、Vivado 旧集成 helper 仅供显式历史实验复用；
默认工程直接读取 S1 包的 `board/`，不会混入这些旧板级文件。
独立功能包保留在 `versions/`，默认清单不随其私有候选而切换。
