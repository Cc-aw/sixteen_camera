# DMA 短读合并与 SPAD 行组装硬件版本

本目录是本次 DMA/SPAD SoC 的独立源码与生成入口，按
[硬件版本目录规范](../README.md)组织。源码来自 2026-10-17 的实际工作区，包含
当前四模式实现；准确基础提交、逐文件来源和 SHA256 见
[SOURCE_ORIGINS.json](manifests/SOURCE_ORIGINS.json)。所有硬件源码均为实际文件副本。

后续本版本的硬件修改在本目录进行。生成器只使用这里的 shell、命令前端和
TensorIngress，不再读取公共 `hw/soc/source/` 的覆盖源码。公共板级工程与工具链仍复用仓库。

| 位置 | 内容 |
| --- | --- |
| [soc_shell/](soc_shell/) | Gemmini、Rocket/L2 冻结依赖、视频 shell 和 MPV3 覆盖 |
| [command_frontend/](command_frontend/) | 前端控制、source31 租借和最终配置覆盖 |
| [tensor_ingress/](tensor_ingress/) | TensorIngress 源码副本 |
| [board_rtl/](board_rtl/) | 结构检查使用的 Head 路由和内存桥副本 |
| [scripts/build_soc.py](scripts/build_soc.py) | 仅生成本版本私有候选的入口 |
| [scripts/run_dma_load_tests.py](scripts/run_dma_load_tests.py) | 使用本目录源码及测试台的单元／完整候选回归入口 |
| [manifests/artifacts.json](manifests/artifacts.json) | 新源码规格、旧三模式产物和验证状态 |
| [validation/organization.json](validation/organization.json) | 本次目录整理的离线核验记录 |

本版固定为三路 DIM32 Gemmini、100 MHz 目标、512 KiB / 2 bank S1 L2、
每 bank 8 way / 512 set、64 B line、MPV3 统计 ABI 1.1。
配置为 `TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankDmaLoadConfig`。
能力值为 `0x1000f`，控制版本 1，复位默认 `legacy`：

| ID | 模式 | 跨行 TL 合并 | SPAD 行组装 |
| --- | --- | --- | --- |
| 0 | legacy | 关 | 关 |
| 1 | read_coalesced | 开 | 关 |
| 2 | read_assembled | 开 | 开 |
| 3 | spad_assembled | 关 | 开 |

模式 3 保留 Group 命令收集、有序返回缓冲、缩放和完成机制，只关闭跨逻辑行读合并。
当前快照仍是整组返回后重放；[流式优化方案](../../../docs/architecture/gemmini-dma-load-streaming-and-write-combining.md)
中的 A1、A2 和跨命令写合并尚未实现。

常用修改位置：

- 装载上下文：[DmaLoadGroup.scala](soc_shell/npu100_video/src/main/scala/gemmini/DmaLoadGroup.scala)。
- 读规划与行组装：同目录的 `DmaLoadReadPlanner.scala`、`DmaLoadRowAssembler.scala`。
- Reader、缩放、写入及完成：同目录的 `DMA.scala`、`Scratchpad.scala`。
- 最终配置：[Configs.scala](command_frontend/integration/fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram/Configs.scala)。
  它在生成顺序中覆盖 shell 的同名文件；工作区检查核对最终有效副本。

在本目录执行离线检查：

```sh
make check
make test
make check-bitstream
```

`check` 核对本地快照哈希；`test` 用最小参考目录实际执行私有复制与覆盖，检查
前端配置优先级、旧源码／错误版本拒绝、禁止覆盖及参考目录不变。
`check-bitstream` 只核对已有**三模式** bitstream 的哈希，不访问开发板，
也不据此接受新四模式硬件。修改本目录后需同步来源清单，保留修改依据并重新验证。

需要生成新的 SoC RTL 时，使用新的私有工作区：

```sh
make prepare SOC_REFERENCE=/home/wzr/chipyard
make check-workspace
make resume
# 或一次完成准备与生成，候选输出目录须尚不存在：
make soc SOC_REFERENCE=/home/wzr/chipyard \
    WORKSPACE=/tmp/dma_load_512kib_2bank_rebuild \
    CANDIDATE_OUTPUT=/tmp/dma_load_four_mode_candidate
```

默认工作区为 `build/soc_workspaces/dma_load_512kib_2bank/`；未指定
`CANDIDATE_OUTPUT` 时，候选及新 `GENERATION_CONTEXT.json` 位于工作区的
`fpga/generated-src/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.<Config>/`。
入口禁止输出到 `hw/soc/` 或 `hw/versions/`，拒绝复用其他版本的工作区；
没有生产导出分支。新上下文记录四模式、有效 Scala、生成器及来源清单身份。

新候选生成后，显式指定它的上下文运行验收：

```sh
make check-rtl DMA_CONTEXT=<新候选>/GENERATION_CONTEXT.json
make test-unit WORKSPACE=<带依赖的Chipyard工作区> DMA_OUTPUT=<新的单元结果目录>
make test-rtl WORKSPACE=<新候选的Chipyard工作区> \
    DMA_CONTEXT=<新候选>/GENERATION_CONTEXT.json DMA_OUTPUT=<新的整合结果目录>
```

单元测试编译本目录的源码和测试台；整合测试复用仓库公共 runner，要求同一候选四模式
的首层、代表层、SPAD、fault 和 memory mux 证据。公共测试、完整 Chipyard 和已安装的
Java/SBT/CIRCT/RISC-V 工具链仍是依赖，不能将本目录视为空目录独立构建包。
`manifests/product.json` 及 `soc_shell/` 内旧上下文、旧说明保留作来源资料，
不选择本版参数或替代新的生成上下文；操作入口以上述 Makefile 为准。

对应软件为[首层／整网独立包](../../../sw/board_tests/dma_load_512kib_2bank/README.md)
和[DMA/SPAD 微基准](../../../sw/board_tests/dma_spad_micro/README.md)。现有包及微基准
仍绑定旧硬件 build ID `2a95a4ca64390235`；新候选须按新上下文更新软件硬件身份，
不能直接使用旧身份进行板测。软件包目前的四模式短测支持不代表旧 bitstream 支持模式 3。

旧三模式 bitstream 的 WNS 为 −1.467 ns，setup 时序未通过，偶发数值差异未关闭。
详见[历史板测记录](../../../docs/validation/gemmini-dma-load-coalescing.md)及
[四模式离线记录](../../../docs/validation/gemmini-dma-load-ablation-short.md)。
本次仅整理目录和核验生成入口，未编译新 Scala、生成新 SoC RTL、执行综合／布局布线、
生成 bitstream 或连接开发板；旧三模式结果不能验收本目录的四模式候选。
