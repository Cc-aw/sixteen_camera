# S1 DMA Stream + ASRAM，512 KiB / 2 bank

本目录冻结 2026-10-19 S1 供体的有效 Scala、生成 RTL、板级 RTL、DDR BD、IP 配置、
约束、实现 hook 和实际比特流。独立软件位于
`sw/board_tests/dma_load_streaming_asram_s1_512kib_2bank/`。

导入比特流：`bitstream/top_wrapper.bit`，113318492 字节，SHA256
`cb907a77e0c0bf97f5074208956884517d349485003a8d6613ca61b9f7e93a01`。
硬件 ID `e037701c8d7cfc59`；100 MHz，三路 DIM32 Gemmini，FIFO 8 / Get 32 B / source 31。
DMA 固定模式 2（read_assembled），能力字 `0x10004`，streaming `row_ready_v1`。
L2 512 KiB、2 bank、34 secondary entries。ASRAM 每路 2.25 MiB，地址分别为
`0x20000000 / 0x20400000 / 0x20800000`，控制区 `0x20c00000`。

S1 改善 L2 ListBuffer 的头/后继缓存、Scheduler 局部标签和 MSHR 并行预解码仲裁，
保留原 ASRAM 及三路前端 ABI；包含板级 AXI、PPU、复位和摄像头时序修改。
实际 FIFO 深度为 8，不能使用供体旧文档里的 FIFO 16 说法。

导入实现结果：2026-10-20 09:01:13 完成 bitgen；route errors=0。
布局 URAM 588，其中 ASRAM 216（SLR0/1/3 各 72）、Head 192（SLR2）。
postroute_physopt WNS −3.068 ns、WHS +0.001 ns；负时序保留为实测约束，不添加
write_bitstream 前的时序门禁。完整报告在 `validation/imported/`。
供体 GENERATION_CONTEXT 内 PnR 的 NOT_RUN 是生成时历史状态，不代表后来 bitgen 失败。

```sh
make check
make test-rtl
# 重跑保留原始证据，指定新的结果目录
make test-rtl RTL_RUN=rtl_acceptance_02
# 创建私有源码工作区；不重新生成 RTL
make prepare-workspace WORKSPACE="$PWD/build/workspace_01"
# 按需重新生成，需配置本机 Java、RISC-V、SBT 及依赖下载环境
make soc WORKSPACE="$PWD/build/workspace_regen_01" OUTPUT="$PWD/build/generated_01"
# 只重建项目，不启动综合、实现或 bitgen
make project PROJECT_OUTPUT="$PWD/build/project_01"
```

本机工具路径只放在忽略的 `config.local.mk`。`source/chipyard` 是源码快照，不带
编译缓存、工具链或第三方仿真压缩 trace/ASIC 编译库；排除项有独立清单。
`source/donor_scripts` 保留原始脚本作为历史记录，正式入口是本目录 Makefile。
`board/ip/config/*.json` 保留原 XCI 配置，由项目脚本在私有 build 中物化为 XCI。

`manifests/SOURCE_ORIGINS.json` 记录导入前字节，`LOCAL_FILES.json` 锁定适配后输入。
导入比特流、原生成身份与新重建产物分别保存：新产物不会覆盖现有 RTL、bit 或软件绑定。
本地验证范围见 `validation/status.json`；`validation/donor` 是历史证据，不计为本地运行。
比特流按仓库规则忽略，但已实际复制到以上路径；本轮没有自动下板。
