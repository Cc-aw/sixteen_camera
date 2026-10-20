# Vivado 源码入口

默认工程属于 `hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/`。
根目录 `make project` 调用该包的 `scripts/create_project.tcl`，默认在其 build/production/ 创建 s1.xpr。
工程包含 S1 板级 RTL、生成 SoC、十个 IP、DDR BD、六个 XDC 和完整实现 hook。
Vivado 2023.2，器件 `xcvu13p-fhga2104-2-i`。

```sh
make project
make elaborate
make synth
make bitstream
```

用 PROJECT_OUTPUT 指定 S1 包 build/ 下的新目录。现有目录不被 project 重建覆盖；
elaborate/synth/bitstream 会打开匹配工程，缺少时先创建。新 bit 保留在该工程 impl_1/，
不会自动替换已验证的 bitstream/top_wrapper.bit。没有 write_bitstream 前的负时序门禁。

GUI source 本目录 create_project.tcl 也会选择 S1。其余旧 BD/setup helper 仅用于显式私有历史候选上下文，
不允许默认工程混入旧板级输入。生产选择见 `hw/manifests/current.json`。
XPR、BD、XCI、IP 输出与缓存均不提交，S1 包使用 JSON IP 参数重建本地 XCI。
