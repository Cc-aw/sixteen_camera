# L2 1 MiB / 4 bank 硬件版本

本目录保存已生成并板测的 `l2_1m_4bank` 对应 SoC shell，源码取自硬件提交
`d7cbd61836cc2f4336e07c42d7ca2cd3a741a35b`，与
[软件测试目录](../../../sw/board_tests/l2_1m_4bank/README.md)对应。
这里的源码是实际文件副本，后续公共 `hw/soc/source/` 下的 DMA 修改不会进入本目录。

| 位置 | 内容 |
| --- | --- |
| [soc_shell/](soc_shell/) | Scala/Chisel shell、Gemmini、Rocket/L2 冻结依赖、V3 覆盖与原始来源记录 |
| [command_frontend/](command_frontend/) | 此版命令前端与 RoCC 接入覆盖 |
| [tensor_ingress/](tensor_ingress/) | 此版 TensorIngress 源码 |
| [board_rtl/](board_rtl/) | 此版 Head 路由和内存桥副本，供对应的结构检查使用 |
| [scripts/build_soc.py](scripts/build_soc.py) | 本目录专用 SoC 生成入口，从上述副本应用覆盖 |
| [manifests/SOURCE_ORIGINS.json](manifests/SOURCE_ORIGINS.json) | 每个复制文件的原路径、提交、原始及本地 SHA256；记录生成器和检查器的适配 |
| [manifests/artifacts.json](manifests/artifacts.json) | 现有生成 RTL、候选 bitstream、软件、验证记录的对应关系 |
| [validation/organization.json](validation/organization.json) | 本次目录整理的验证记录；与历史板测分开记录 |

最常用的修改位置：

- L2 容量、bank 数及映射：[MemoryParallelV3.scala](soc_shell/memory_parallel_v3/scala/MemoryParallelV3.scala)。
- 组合配置与两 bank 回退：[MemoryParallelV3TensorIngress.scala](soc_shell/memory_parallel_v3/scala/MemoryParallelV3TensorIngress.scala)。
- L2 控制器：[inclusivecache/src/](soc_shell/memory_parallel_v3/chipyard/generators/rocket-chip-inclusive-cache/design/craft/inclusivecache/src/)。
- 三 Gemmini/100 MHz 配置：[Configs.scala](command_frontend/integration/fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram/Configs.scala)。接入覆盖在生成顺序中优先于 shell 中的同名配置。

此版参数为 1 MiB、4 bank、每 bank 256 KiB / 8 way / 512 set、64 B cache line；
bank 使用地址位 A13:A12，统计 ABI 1.2，命令前端 ABI 2。
保留 S1 Head、S1 组合式 L2 请求池/调度器、TensorIngress 和 DDR 模式 1。
两 bank 回退保留在本目录配置中，容量 512 KiB，统计 ABI 1.1。

从本目录检查现有版本：

```sh
cd /mnt/data/wzr/13p/ov7670/sixteen_camera/hw/versions/l2_1m_4bank
make check
make check-bitstream
```

`check` 检查冻结源码和现有生成 RTL 的哈希与结构；`check-bitstream` 额外读取本地候选
bitstream 核验哈希。两者都不访问开发板。
将来主动修改副本后，冻结哈希检查会报出差异；应为新功能建立新目录并记录新的来源及产物。

需要从源码重新生成时，复用已安装的 Chipyard 与工具链，在新的私有工作区运行：

```sh
make prepare SOC_REFERENCE=/home/wzr/chipyard
make check-workspace
make resume
# 或在另一全新工作区一次完成准备与生成：
make soc SOC_REFERENCE=/home/wzr/chipyard WORKSPACE=/tmp/l2_1m_4bank_rebuild
# 两 bank 回退使用独立工作区：
make soc-fallback SOC_REFERENCE=/home/wzr/chipyard
```

默认工作区是仓库的 `build/soc_workspaces/l2_1m_4bank/`；回退工作区是
`build/soc_workspaces/l2_1m_4bank_fallback/`。入口拒绝覆盖已经存在的准备目录；
继续生成使用 `make resume`。生成结果在工作区的
`fpga/generated-src/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.<Config>/`，
包括 `gen-collateral/` 和新的 `GENERATION_CONTEXT.json`。
本入口始终生成私有候选，不会替换仓库唯一的正式 SoC RTL 导出。

本目录依赖完整仓库、参考 Chipyard、Python、rsync、Java/SBT/CIRCT 及已安装工具链，
不要求在空目录复现。板级视频 RTL、约束、IP 重建 Tcl、Vivado 实现流程继续复用仓库；
`board_rtl/` 仅是这版对应文件的副本，公共 Vivado 工程不会自动切换到这些副本。
`manifests/product.json` 是原交付清单的冻结副本，其中公共路径用于追溯，
本目录生成器的实际源码路径以上表为准。
`soc_shell/` 内原始 README、旧脚本和绝对路径记录保留作历史资料；本目录入口为此处 Makefile。

现有正式生成 RTL 位于仓库 `hw/soc/` 下的长配置名目录，准确路径及哈希见
`manifests/artifacts.json`。已有候选工程位于
`build/projects/l2_1m_4bank_candidate/sixteen_camera.xpr`，候选 bitstream 位于
`sw/board_tests/l2_1m_4bank/hardware/top_wrapper.bit`，二进制保留在本地并受 Git 忽略规则管理。

历史验收状态：bitstream 已生成，布线后 WNS −7.159 ns，时序未满足；CPU/L2 smoke 通过，
完整模型在候选上卡住，同一 ELF 在指定旧 S1 上通过 36 帧。问题尚未修复，未测得性能收益。
详细证据见[板测记录](../../../sw/board_tests/l2_1m_4bank/validation/board_status_20261017.md)。
本次只整理源码、接入私有生成入口并做离线核验；未重新综合、布局布线、生成 bitstream 或板测。
