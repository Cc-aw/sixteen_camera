# S1 FIFO16 / 四条批量取表

以本仓库 `hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank` 的完整源码为基线，
建立独立版本。基线硬件 ID 为 `e037701c8d7cfc59`。
仅移植 2026-10-16 前端交接版的 FIFO16 和批量取表；生成和测试不依赖交接项目目录。

每路命令 FIFO 为 16 条，每条 32B；每批最多四条（128B）。32B 对齐的表首过渡、
尾部不足四条时使用一条或两条读取，保持原来的表 ABI。满批通过两次 64B Get 完成，
每个 Get 返回两个 256-bit beat。每路仍只有一个逻辑批次在途，并在发送前预留整批 FIFO 空位。
source31 在每个物理事务完成后释放，原 DMA 的全部 64 个 source 和 33-bit 地址保留。

仅三个生产 Scala 文件发生变化：

- `source/chipyard/generators/rocket-chip/src/main/scala/tile/commandfrontend/CommandFrontend.scala`
- 同目录的 `CommandFrontendMemory.scala`
- 同目录的 `CommandFrontendAttach.scala`

当前 S1 的 ASRAM 重定位、DMA 固定模式2、能力/模式/拒绝计数/build ID 查询、
TensorIngress、L2 优化、Gemmini 计算及板级 RTL/IP/XDC 均保留。
`manifests/BASELINE.json` 和 `FRONTEND_PORT.json` 记录来源和哈希；
`frontend_port.patch` 是相对当前 S1 的最小源码差异。

## 生成和验证

在本目录执行。机器相关的 Java、RISC-V、SBT、Vivado、Verilator 路径放在忽略的
仓库的 `tools/config/tools.local.mk`；依赖缓存可以通过 `COURSIER_CACHE_SEED`、`SBT_BOOT_SEED`、
`IVY_CACHE_SEED` 提供。缓存复制到本版本的私有工作区，仅复用第三方依赖，
完整 SoC 由本地全部 Scala 源码经 SBT 编译、Chisel/firtool 生成。

```sh
make soc
make check
make test-frontend RTL_RUN=acceptance_01
make test-rtl RTL_RUN=numerical_01
make project PROJECT_OUTPUT="$PWD/build/project_01"
make synth PROJECT_OUTPUT="$PWD/build/project_01"
make bitstream PROJECT_OUTPUT="$PWD/build/project_01"
# 再次生成须选择新工作区及输出目录：
make soc WORKSPACE="$PWD/build/workspace_02" OUTPUT="$PWD/build/generated_02"
```

`generated/GENERATION_CONTEXT.json` 绑定源码、生成 RTL 和新硬件 ID。
`generated/gen-collateral/` 是本版本生产 RTL；保留基线数学参数头的逐字节检查和原内存推断后处理。
Vivado 工程从本版本的板级输入和生成 RTL 重建，所有输出位于私有 `build/`。

`test-frontend` 对本次完整生成的生产模块运行交接版原有批量取表压力测试，
包括表首/表尾、FIFO 满载、DMA 争用、HOST/DRAIN、总线错误、超时排空、
并检查命令顺序。
`test-rtl` 使用三颗真实 DIM32/FP16 Gemmini 和 ASRAM 的原生数值用例，
测试模型为批量取表增加 size/last 接线，并继续按返回表项统计 fetched。
本地结果汇总在 `validation/status.json`。

本次完整源码生成、配置检查及 155 个批量取表用例通过。
现有数值回归在提交前停止，尚未完成整套测试；完整计算、综合、布局布线和上板均未签核。

## 软件和交付边界

命令表格式、custom0/1/2 直接命令、custom3 控制、IRQ13、HOST/RESUME、
计数器语义均保持当前 S1 ABI。软件在提交前完成命令表绑定并发布内存，
执行期间保持表不变；允许预取 HOST 后的命令，执行仍等待匹配标签的 RESUME。
当前实时 Runtime 满足该约定，模型命令和调度流程无需为批量读取改写。

新硬件使用新的 build ID。软件上新硬件前仍需更新硬件身份和 bitstream SHA 绑定并重新构建；
现有 S1 ELF 检查旧 ID，不直接配本版本。该身份更新应在生成并确定新 bitstream 后进行。

默认硬件、正式清单和软件未切换。本版本不携带旧 bit/DCP 或旧时序结果；
RTL 功能仿真不代表布局布线收敛、完整模型性能或板上验证。
