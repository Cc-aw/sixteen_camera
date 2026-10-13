# SW Runtime R3：调度、Pipeline 与状态机

日期：2026-10-13。基线：`4a8dcf7`（R2），实施分支：`main`。
按 [重构设计](sw-runtime-refactor.md) 完成 R3 的离线结构拆分。
机器可读证据见 [验证记录](../validation/sw-runtime-r3.json)。

## 1. 模块边界

`ai_batch_runtime_stream.c` 从 1031 行缩减到 275 行，保留旧公开 API、主轮询编排、
状态/资源查询和原 UART 诊断；诊断及 Application 的进一步迁移留给 R5。
新增模块仍放在 `sw/src/ai/runtime/`，与 R2 资源层保持一致。

| 模块 | 职责 |
| --- | --- |
| `core/rt_internal.h` | 私有 `AiRtCore` Context；Worker/Post Job、资源、结果、统计与 profile；模块显式接收 Context，不引入新的 Runtime 全局状态 |
| `core/rt_core.c` | 安全初始化、错误记录、Post Job 计数 |
| `core/rt_pipeline.c` | Compute/Result completion、身份核验、Post Job 注册、输入释放/ack 重试及故障保留 |
| `core/rt_state.h/.c` | Producer phase、fault latch、enable/disable、idle 证明和 drain/admission |
| `core/rt_stats.c` | 原完成统计、deadline 更新、frame profile 环形记录 |
| `scheduler/rt_frame_scheduler.h/.c` | 纯候选槽选择及 EDF/frame tie 选择，不读 MMIO、不调用 backend 或 clock |
| `scheduler/rt_worker_dispatch.c` | 按旧顺序采样 metadata；每个空闲 Worker 单独建立快照；派发事务建立 Job/Tensor 所有权并调用原 Backend submit |
| `services/rt_tensor_service.c` | READY/ERROR/WRITING 缓存、metadata 适配、stale 回收、单槽 drain |
| `services/rt_result_service.c` | 原结果发布、stale 计数、overlay dirty/clear 更新与停用后 TTL |
| `services/rt_overlay_service.c` | 原单 stream overlay 服务、busy 重试与清框 |

私有 Context 保留 R2 的 Worker/Post Job 统计投影字段，避免同时重写 ABI 和统计来源。
三种视频配置及所有直接编译 Runtime 的 host runners 都更新了源码闭包；
测试共享 `runtime_module_sources.sh`，冻结的旧 Runtime 不链接新的模块。

## 2. 选择与完成顺序

候选采样与纯选择分开。采样仍按 stream 0→15，跳过 in-flight stream 和 held Tensor；
使用原固定双槽地址及稳定 READY metadata 读取。只有内存快照交给纯选择器：
过滤已完成版本，选最早 deadline；deadline 相同时选新 frame；frame 也相同则保留低 stream。
没有跨 Worker 复用快照，没有新增 metadata 读取、轮询或 fence，也没有重排 Device transaction。

派发事务独立为 `dispatch_candidate()`：保留 job ID 增长、计时位置、Tensor reserve/accept/reject、
Head 背压等待计时与 unconfirmed submit 的 Fault 保留。

主轮询保持：READY/track → Worker Compute → Result → TTL → Overlay → drain/fault/admission。
每个匹配 Compute Done 仍在同一服务轮中注册 Post Job、归还输入、补充派发，
**随后**才轮询结果；不能让短 PPU result 隐藏 Worker 与旧 Head 的重叠窗口。
结果发布计时、deadline/missed deadline、tensor/head/PPU wait、service gap 和 UART profile 均保留。

## 3. Runtime 状态

`AiRtControl` 用 STOPPED/RUNNING/DRAINING phase 替代分散的 enabled/draining 控制，
另保留 fault latch；对外新增纯查询 `ai_batch_runtime_state()`，故障锁存时返回 FAULTED。
`AiBatchRuntimeStatus.enabled` 仅为兼容统计投影，由状态模块更新。

Fault 可能在 Pipeline 中产生，而关闭 Producer 必须留在原轮询位置。
因此 FAULTED 不表示 Producer 已立即关闭；状态机继续在原位置 stop/drain。
Fault drain 完成后锁存仍保留，start 被拒绝。`is_idle()` 独立检查占有者与设备掩码，
不能用 enum==STOPPED 替代静止证明。资源已确实静止时仍允许原初始化路径清锁；
R2 中没有停止证明的占有者仍阻止 init/re-enable，并保留到硬件复位。
重复 disable 继续执行原设备写入，未优化成无操作。ERROR-only 的启动清理和 drain、
release GO pending/late ack/新帧保护、错误 completion 与 timeout 都保留 R2 行为。

## 4. 验证

| 命令 | 结果与范围 |
| --- | --- |
| `make test-runtime-scheduler` | PASS；Host/RV64 QEMU，固定 32 槽、busy/held、EDF、frame/stream tie、stale、零 deadline、原 version wrap characterization 与 phase/fault latch；无需 Fake CSR/backend/clock 链接 |
| `make test-runtime-r3` | PASS；47 组真实旧/新 Runtime 完整事件对照，1/2/3 worker，所有 MMIO 读写/fence/cycle、submit/compute/release/result/drain/UART 参数逐行相同，**不做事件过滤** |
| `make test-software` | PASS；全部 host runners，含 R0–R2、R3、ABI、HAL 与 RV64 QEMU，未跳过 |
| `make test-v17a` | PASS；101 Python 用例、Host backend 和 Host/RV64 live context |
| 三种 `make firmware SOC_VARIANT=...` | PASS；triple32_v3_tensor、dual16、single4 |
| `make firmware-benchmark` | PASS；原三图 benchmark |
| `make check-v17a-firmware check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；ELF 特殊屏障、manifest/source lock 与源依赖闭包 |

R3 对照以 `tests/data/runtime/r2/stream-runtime-reference.c.inc` 保存 `4a8dcf7` 的实际实现，
不是新旧均链接新 Runtime。5 场景 × 3 worker 配置覆盖 pipeline 重叠、Head 背压、metadata
失败、多个 stream 同时双 READY、writing-only drain；10 个 R2 故障场景 × 3 配置另作完整对照；
再加 2/3 worker 原完整回归（含错误结果身份及 UART/profile），共 47 组。
原完整回归 2/3 worker 分别 1044/825 个事件一致。

Fault/metadata timeout 的 trace harness 在指定失败读取时推进 Fake clock，避免输出千万级轮询；
旧/新使用同一规则。普通 R2 故障回归仍保留原计时 Fake。测试没有主张实际 CPU 周期开销相同。
Host/RV64 的纯策略/控制状态测试使用 `-O2 -Wall -Wextra -Werror`；
Runtime 集成保持原无显式优化的 host runner 选项。
ELF、map、反汇编、依赖、编译参数、源码清单和日志保存在忽略的 `build/runtime-refactor/r3/`。

## 5. 保留的问题与验收边界

此次没有修复版本协议或改变调度策略：UINT32_MAX→1 仍会被旧 `<=` 比较判为 stale，
R0-GAP-02 仍记目标契约 FAIL、characterization PASS。
新增对照明确复现了另一个已有兜底：stale service 每 poll 只处理首个 pair，
后续仍双 READY 的 stream 在 dispatch 时优先 s+16，即使其 version 较旧。
R3 保留该行为；单个已知交错的 characterization 不等于穷尽全部 READY 交错。

Backend、native execution、参数/固定包、task switch、Head 布局、R2 资源管理、HAL/cache/fence、
RTL/CSR 与 main/视频业务未改。R3 不重复 RTL 回归；协议基线仍见 R2 记录。
板上 UART、持续视频、FPS、模块调用与快照准备的开销未测；未下载、未综合或布局布线。
这里验收 R3 的离线结构等价，不声称 R4–R6 或整体 Runtime 重构完成。

下一阶段 R4a：Backend Ops 与 legacy/V17A 适配边界；等 R4a 对照通过后再做 R4b 的 PPU 服务迁移。
回退可整体 revert 本阶段，恢复到 `4a8dcf7`。
