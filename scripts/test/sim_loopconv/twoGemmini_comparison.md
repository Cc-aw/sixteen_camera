# twoGemmini 与当前 triple64 的基线核对（2026-09-29）

## 核对对象与证据

- 已跑通项目：`/mnt/data/wzr/13p/chipyard_mipihdmi/twoGemmini`。
- HEAD：`1cdcddd74507e61f26ac93c282ff7d38b511eb20`，2026-09-25，
  `feat: 双gemmini64 yolov5nu 稳定版本`。
- 当前 Vivado XPR 引用的 SoC 为
  `TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256Bit1BankSbusNoCConfig`。
  本次硬件对比以该配置的 `rtl/soc/.../gen-collateral` 为准，而非目录中其他实验 RTL。
- `log/onr_bank_npc_dual_gemmini64_yolov5_graph_profile.log` 多次记录
  `compare dual=MATCH errors=0`、整网 `RESULT: PASS`、`baremetal exit 0`。
  这支持将其作为“能完整运行”的参考，但本次没有重新下板，也没有证明日志与
  当前 bitstream 的哈希绑定。
- 当前项目对比对象为 checked-in triple64 `PackedInference100MHzConfig` RTL
  和 `soc_shell/npu100_video/src/main/scala/gemmini`。

## 实际差异

| 项目 | twoGemmini / 自有 Chipyard | 当前 triple64 | 结论 |
| --- | --- | --- | --- |
| ExecuteController 返回同步保护 | `/home/wzr/chipyard/.../ExecuteController.scala:912` 有 V02 `virtual_i_enable` 分支，在控制出队条件上增加 A/B/D data-valid 条件 | 没有该分支 | 源码改动没有迁入；但 twoGemmini 当前生成 RTL 也没有启用该分支，不能用它解释两者运行差异 |
| EX 控制及结果路径 | `MultiHeadedQueue_1`、`Queue5_ComputeCntlSignals`；没有 TimingResultQueue | BankedShallowQueue 控制路径，加 writeTags、TimingResultQueue、writes、futureRows 预留 | 属于实质实现变化，不能视为稳定版仅改变频率/worker 数 |
| 内部死锁观测 | Gemmini/LoopConv/RS/Scratchpad/控制器存在 deadlock_debug 链路，Gemmini 有 debug status/data CSR 输出 | 无 deadlock_debug，仅 busy/status/accepted/retired 四个 CSR 数据输出 | 丢失了稳定版定位阻塞级、缺失 completion 的能力；诊断缺失本身不是功能死锁根因 |
| LazyRoCC debug escape | 生成 RTL 有 blockedRunCycles、debugEscapeArmed、debugDropIngressCommand/SerializedPacket；阻塞达到 2^26 周期后可进入诊断逃生 | 当前关闭该功能，相应逻辑被消除 | 它可丢弃命令以让 CPU 恢复并导出诊断，不能当作正确完成推理的修复迁入 |
| AccumulatorScale | FullOps scale 实现，有相关死锁诊断扩展 | 定制 SiLU BRAM/分级 FP16 等实现，结构明显不同 | 需按实际完成链核对，不能认为整体继承了自有稳定版 |

两边入口都保留 RegisteredIngressAtomicReserve 和完整 packet 提交机制。
不能把本次问题重新解释为“没有原子入口队列”，也没有修改队列深度。

## 与当前仿真定位的关系

当前生成 RTL 确实复现了 EX 操作数握手导致的数值错误。读到的输入、权重正确，
但权重进入 mesh 的拍号会随反压错位。只修改 build 内的 EX 握手副本后：

- 首 tile 在 delay8/stall0 和 delay100/stall13 下均 8192 个输出正确；
- 小卷积 1280 个输出正确；
- 完整大卷积 150 个任务全部退休，1228800 个输出逐元素正确。

该实验支持优先审计当前 timing 版本的 EX 握手改动。它尚未复现板上
accepted=4/retired=3 的停滞，不能直接宣称已证明两种症状同源。

后续应以已跑通的 twoGemmini 生成 RTL 为功能参考，按 EX → Scratchpad/Scale →
完成反馈逐块对照，并恢复内部观测；不应整体覆盖会丢掉现有时序优化的 Scala。
本次仅核对源码、生成 RTL 和日志，没有修改任一项目的生产 Scala/RTL。
