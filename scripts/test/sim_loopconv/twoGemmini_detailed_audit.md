# twoGemmini 稳定版本与当前 triple64 详细审计

后续实现与诊断 ABI 见 [修复说明](rtl_fix_diagnostics_v9.md)。下文保留修复前审计结论。

日期：2026-09-29。范围：Gemmini Scala、稳定版实际生成 RTL、当前生成 RTL、相关配置和诊断接口。此审计不是全 SoC 形式等价证明，也未重新下板验证。

## 1. 基线与证据规则

- 稳定项目：`/mnt/data/wzr/13p/chipyard_mipihdmi/twoGemmini`，HEAD `1cdcddd74507e61f26ac93c282ff7d38b511eb20`，提交说明“双gemmini64 yolov5nu 稳定版本”。
- 以其 XPR 实际引用的 `rtl/soc/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256Bit1BankSbusNoCConfig/gen-collateral` 为硬件基线，以下称 OLD_RTL。
- 运行证据为 `log/onr_bank_npc_dual_gemmini64_yolov5_graph_profile.log` 的多次整网 MATCH、errors=0、PASS。未将日志与 bitstream 做哈希绑定；其他旧日志也有失败记录。
- 当前源为 `soc_shell/npu100_video/src/main/scala/gemmini`，当前生成 RTL 为 `generated/soc/*PackedInference100MHzConfig/gen-collateral`。
- `/home/wzr/chipyard` 是辅助源码参考，不等于 twoGemmini 当时完整源码快照。例如 AccumulatorMem 本地加法器的 9/27 改动晚于稳定版 9/25 提交。源码差异必须用 OLD_RTL 再确认，不能把 home 新增功能全部称为“漏迁的旧修复”。
- Gemmini 顶层 Scala 文件清单比较（home 对当前）：28 个完全一致，27 个不同，5 个仅 home 有，3 个仅当前有。清单及逐文件 diff 在 `build/twogemmini_audit/`，该目录按项目规则不提交。

## 2. 核心结论

确认遗漏了完整内部死锁诊断能力。未发现证据足以证明“twoGemmini 有一个已经启用的明确退休修复，而当前版只是忘记复制它”。相反，当前版改变了多处握手和流水边界，其中 EX 操作数消费问题已通过仿真实验定位并修正数值错误。

板上的 accepted=4 / retired=3 尚未在完整仿真中复现，不能把数值错误修正直接宣布为板上死锁根因。下一版应移植经过实验验证的 EX 握手修正并恢复观测，以便确认最后一个任务究竟等待哪一项 completion。

## 3. 逐项审计

| 项目 | 稳定版/源码参考 | 当前版 | 判断与处理 |
| --- | --- | --- | --- |
| 原子命令入口 | OLD_RTL 使用 RegisteredIngressAtomicReserve | 仍保留完整 packet 提交/原子入口 | 没有漏掉原子入口机制，不调整队列深度 |
| LoopConv request retire | 完整 head slot 完成并 reset 时退休 | `LoopConv.scala:1957` 同一条件 `running && all_completed()`，同步 reset/翻转 head | 没有退回按单个子命令提前归还 credit 的版本 |
| RS 完成/依赖 | LD/EX/ST issue、ROB completion、conv 完成计数 | 主干保留；主要删去 VI 分支与诊断、增加 SiLU 配置条件 | 未发现独立的已启用退休修复被删除 |
| LoopMatmul B padding | 最后一行使用 `max_row_iterator-1` | `LoopMatmul.scala:185` 已保留 | 不是遗漏 |
| LoopMatmul B 提前量 | B 加载进度比较 `io.ld_kb` | `LoopMatmul.scala:459` 已保留 | 不是遗漏 |
| DMACommandTracker | OLD_RTL 仍为旧 valid/bytes_left 更新；home 也是旧形式 | `DMACommandTracker.scala:68–111` 使用逐 entry next-state、完成后同拍可复用、明确更新优先级 | 当前已有不同且更明确的生命周期处理，不能用旧文件整体覆盖 |
| EX 控制与结果路径 | 普通控制队列、原 mesh 输出路径 | BankedShallowQueue、writeTags、TimingResultQueue、writes、futureRows 预留 | 是实质架构变化；已定位操作数独立握手问题，优先修正 |
| V02 返回 valid 保护 | home ExecuteController 有 `virtual_i_enable` 条件下的 A/B/D valid 保护 | 无此分支 | OLD_RTL ExecuteController.sv:2695 也没有启用该保护，不能说稳定版靠此通过 |
| VirtualI 系列 | home 有描述符、输入地址生成、驻留证明、跨行推进 | 删除这些文件及元数据 | 属于未在所选稳定 RTL 启用的可选路径，不作为此次修复迁入 |
| LoopConv 地址派生 | 原版组合计算 | 派生参数三级流水、缓存 stride，增加 derive_pending/deriving | 新时序实现；当前已阻止派生窗口重复透传命令，不能直接换回旧状态逻辑 |
| DMA/BeatMerger | 元数据与首 beat 可同拍接收、直接输出 | 分拍接收、整包响应缓冲、请求从已寄存 idle 接收 | 时序优化引入的协议边界变化；当前卷积仿真已覆盖部分反压，尚非所有地址/请求类型穷举 |
| Scratchpad | 直接仲裁及旧 response 队列 | 写缓冲、读 skid/响应缓冲、pending 写地址 hazard、Scale 前后缓冲 | 数据与 tag/完成反馈必须一起移动；本次首 tile 跟踪未发现 SRAM 数据错误 |
| AccumulatorMem | 旧读返回路径，共享加法器 | 本地 select、读数据/元数据延迟两拍、readBusy 限制在途 | 属于时序实现变化；首 tile 累加写入/读回与 mesh 输出一致 |
| bank 本地加法器选项 | home 9/27 新增 `acc_use_shared_adder=false` 分支 | 无此选项 | OLD_RTL 是共享路径，不是稳定版旧修复遗漏 |
| Scale scheduler | OLD_RTL 为三 entry、fired/completed mask、head/tail one-hot 旧调度 | 仍有三 entry 主干，但计算和输出流水改变 | home 的 chunked_no_norm 不能视为稳定版正在使用的修复 |
| Scale 数值格式 | OLD_RTL scale 端口 32 位 | FP16 Float(5,11)、64 scale 单元、分级计算 | 必须保留匹配的指令编码/软件参数；不能直接套用旧 FP32 ELF |
| SiLU LUT | 旧寄存器查表与写入路径 | BRAM 查表、寄存写脉冲、silu_lut_ready 门控 | 编程握手和读延迟发生变化；仿真使用测试 LUT，不等于已验证完整模型量化精度 |
| 激活 ISA | activation=3 位，SiLU=6 | 仍为 3 位、SiLU=6，相关 CONFIG 位布局保留 | 未发现退回旧两位激活 ABI |
| TLB | 旧生成 DMA 有翻译路径 | 配置 use_tlb=false，DMA 使用物理地址 | 是运行前提变化；裸机使用物理地址可用，不可假设能直接接虚拟地址 |
| FullOps 功能 | 支持更多算子和路径 | 禁用 maxpool/training/depthwise/transposer/normalization 等 | 属于有意裁剪；今后启用这些算子须同时检查软件调用，不可仅凭 DIM=64 认定完全兼容 |
| 内部诊断 | OLD_RTL 存在完整 ABI v8、64 页快照 | 仅 busy/status/accepted/retired，没有完整 deadlock_debug 链路 | 确认遗漏，下一版应恢复 |
| ingress debug escape | OLD_RTL 超时后可丢弃阻塞命令用于诊断逃生 | 配置关闭，逻辑消除 | 不作为功能修复恢复；丢弃命令不代表正确完成推理 |

## 4. 必须恢复的观测链

OLD_RTL/Gemmini.sv:3457 的页表包含签名 `0x4442475f00080040`，不是只在 home Scala 里写了但没有生成。

- 页 1–9：LoopConv 两个 slot 的 started/completed、子生成器和迭代状态。
- 页 10–29：RS 占用、issue/completion 身份与 entry 摘要（配置裁剪后部分页为零）。
- 页 30–41：DMA Reader/Writer、Scale 进度。
- 页 42–47：完成仲裁、计数、busy、入口与进展。
- 页 48–51：LD/ST/EX 控制器、tracker 和 mesh 握手。
- 页 52：完成历史；53–58：RS 阻塞 entry 与具体依赖；59–63：Scale fault 信息。

恢复必须贯穿子模块 → Scratchpad/Controller → Gemmini CSR → Rocket CSR 配置 → 软件读取。仅复制 LazyRoCC.scala 不会恢复这些生产端信号。三 worker 的现有 CSR 已占用部分旧地址，不能照搬双 worker 地址表；需要重新分配并同步 ABI。新增 timing 队列和 EX sent/结果预留状态也应纳入观测，旧页表本身看不到这些新增状态。

## 5. 已有仿真证据及边界

当前生产 RTL 的完整大卷积可退休，但存在数值错误；首 tile 的输入/权重 SRAM 内容正确，权重进入 mesh 的拍号随反压发生错位。build 内 EX 实验副本加入逐操作数已消费状态、独立消费对应读响应并调整首拍门控后：

- 首 tile 在 delay8/stall0 与 delay100/stall13 下，各 8192 输出全部正确。
- 小卷积 1280 输出全部正确。
- 大卷积 150 个任务全部退休，1,228,800 输出逐元素正确；无漏写、无重复写。
- 证据：`build/sim_loopconv/handshake_full.log`；复现脚本：`scripts/test/sim_loopconv/run_handshake_experiment.sh`。

这些是本次系列工作已有的结果，本轮审计核查日志，未重复运行。实验修改仍只在 build 副本中，生产 ExecuteController.scala 仍保留原握手表达式。测试为完整单 worker 加速器加模拟外部 TileLink 内存，不等于 Rocket/L2/NoC/三 worker/视频并发的完整 SoC 回归，也未复现板上 accepted=4/retired=3。

## 6. 下一版改动范围建议

1. 将 EX 实验修正落实到当前 Scala，保持时序优化结构；重新生成后复跑现有数值和反压回归，防止手工 SV 实验与 Scala 实现不一致。
2. 恢复稳定版被动诊断链，并扩展当前新增流水状态；不依靠丢弃命令的 debug escape 来宣称推理成功。
3. 保留现有原子入口、credit 退休条件、DMA tracker next-state、LoopMatmul 修正、FP16/SiLU ABI 和视频接入。
4. 不整体覆盖 home 或 twoGemmini 的 Gemmini 文件。新 RTL 仍由当前 overlay 同步到隔离 Chipyard 工作区后编译。
5. 上板若仍出现最后一个 request 不退休，用快照明确是 LD、EX、ST、Scale、DMA 哪项未完成，再修对应链路；不再通过改队列深度或权重复用开关绕过问题。

本轮仅新增审计文档和 build 内比较清单，没有改动生产 Scala/RTL、生成新 bitstream 或提交 Git。
