# SW Runtime R4a：Backend Ops 与 legacy/V17A 适配

日期：2026-10-13。基线：`02e0a0b`（R3），实施分支：`main`。
按 [重构设计](sw-runtime-refactor.md) 完成 R4a 的兼容适配，
机器可读证据见 [验证记录](../validation/sw-runtime-r4a.json)。

## 1. 接口与配置

新增 `sw/src/ai/backend/rt_backend.h/.c`：`AiRtBackendOps`、请求/完成 ABI 别名、
Compute/Result phase、COMPUTE_DONE/RESULT_READY/FAULT 事件及一次性 mailbox。
Runtime 的 Core/Pipeline/Dispatcher/状态与资源查询改用这些接口，
不再直接调用或包含旧 `ai_model_backend_*` 入口。
R2 Head Queue 的兼容参数类型、Application/独立诊断仍保留原入口；R5 再清理应用依赖。

`adapters/rt_backend_compat.c` 集中旧 compute/result poll 的精确转发，
`adapters/legacy/rt_backend_legacy.c` 和 `adapters/v17a/rt_backend_v17a.c`
各提供静态 Ops 表。`sw/Makefile` 显式选择一个 profile 和源文件，没有根据设备探测静默降级。

| 构建 | Profile | Worker/DIM | 保留的执行方式 |
| --- | --- | --- | --- |
| single4 | legacy | 1 / 4 | 原 AOT 与 CPU/单 reader PPU 路径 |
| dual16 | legacy | 2 / 16 | 原双 Worker AOT 与 PPU 路径 |
| triple32_v3_tensor | V17A | 3 / 32 | 原 live context、固定包、local Head proof 与 ordered PPU MMIO |

缺少/错误 profile、legacy 绑定 live、Worker 数或 DIM 错配均编译失败。
请求、完成记录、profile、输出 descriptor 与资源快照使用原布局的 typedef 别名，
没有改变 firmware/hardware ABI。Head 背压 -3 和 uncertain submit -4 改为具名常量，数值及含义保留。

## 2. Progress 与事件证明

兼容 phase 由调用点明确指定：COMPUTE progress 原样调用一次 `poll_compute(worker)`；
RESULT progress 原样调用一次 `poll_result()`。Runtime 随后立即读取 mailbox。
这保留 R3 的 per-worker 顺序、同轮补充派发和先 Compute 后 Result 的服务位置。
V17A 的 `yolo32_independent_step()` 次数、早期 Head 回调/commit/admission/tail wait 均没有改变，
没有增加集中的全 Worker pump 或每 packet 的 Ops 回调。

非零 native 返回才形成事件。`poll_event()` 只复制并消费已有事件，不读设备、不推进模型：
同一事件只取一次，空 mailbox 返回 0；空目标指针不消耗事件。
未消费时 progress/submit 返回 EVENT_PENDING=-5，不覆盖原事件，init 不清掉它，idle 返回 false。
这项新 API 约束不改变生产轮询轨迹，因为生产调用始终立即消费事件。
handle 必须从零初始化存储开始；Runtime 仍先验证静止，才清零 Context 并调用 init。
底层 native backend 保持 singleton，多 handle 不代表多个独立加速器实例。

FAULT 保留原负返回值，既不合成 Compute Done，也不授权回收；
即使 native 在负返回前写入了看似有效的 metadata，也不能用它当停止证明。
abort 保留原 advisory 含义，不创建或清掉事件。
COMPUTE_DONE/RESULT_READY 负载保留完整五元组和 profile，Runtime 继续核验身份、completion status 与资源租约。
结果地址仍是借用的 native 指针，必须在后续 native progress 前按原流程消费，未扩展其生命周期。

本阶段没有对外合成 partial HEAD_READY；原部分 Head 生产与 publication 链仍在 native 后端内部。
R4b 才能迁移这条事务，且不能把 Head 事件或 mask 自动当作 Input/PPU 的释放证明。

## 3. 验证

| 命令 | 结果与范围 |
| --- | --- |
| `make test-runtime-backend` | PASS；Host/RV64 QEMU × 3 profile，身份/profile/pointer/status 传递、一次消费、no overwrite、init/abort 不清事件、错误返回不变为停止证明；8 个错误配置编译负例 |
| `make test-runtime-r4a` | PASS；27 组真实后端直接调用与 Ops 适配调用的完整 MMIO/fence/逻辑周期/结果/占有/UART 对照，1/2/3 Worker；不过滤事件 |
| `make test-runtime-r3` | PASS；原 47 组 Runtime 完整事件轨迹仍与冻结 R2 相同；延续 R3 的相同 oracle/workload |
| `make test-software` | PASS；全部 host runners、ABI、R0–R3/HAL 与新适配测试；RV64 未跳过 |
| `make test-v17a` | PASS；101 Python corpus/packet/scheduler/PPU 用例、Host backend 与 Host/RV64 live context |
| 三种 `make firmware SOC_VARIANT=...` | PASS；triple32_v3_tensor、dual16、single4 |
| `make firmware-benchmark` | PASS；冻结三图基准 |
| `make check-v17a-firmware check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；特殊 PPU 屏障、manifest/source lock 与源依赖闭包 |

真实后端对照用同一生产 backend：reference 直接调用原入口，current 经真实 Ops/事件桥接再调用；
源码审计另外证明该生产 backend 与 R3 提交完全一致。
legacy 各 10 场景：publication、flush fallback、reader busy、PPU error/timeout、CPU fallback、
BEGIN ack/部分 start/model error 与 DONE+READ_BUSY。
V17A 7 场景：身份、generation fault、abort、六槽并行及 BEGIN/start 故障；
名为 model-error 的 live fixture 实际通过 abort→ERROR 路径验证占有，未声称注入了 native task 内部 fatal error。
故障 fixture 增加 MMIO/fence/UART/占有快照记录；仅在指定缺失 BEGIN ack 的读取上推进 Fake clock，
新旧规则一致，避免千万级 timeout 日志；普通故障回归不启用该 trace clock。

Backend 单测与真实 adapter 对照使用 `-O2 -Wall -Wextra -Werror`；
Runtime 对照保持原无显式优化的 host runner。
固件、map、反汇编、编译参数、依赖、源码清单与日志保存于忽略的 `build/runtime-refactor/r4a/`。

## 4. 验收边界与后续

native/backend 执行与 PPU 服务实现、旧诊断、参数/固定包、task switch、
R2 资源与 R3 调度/状态策略、HAL/cache/fence、RTL/CSR、main/视频代码未改。
只完成 **R4a 离线兼容适配**，不是 R4b、R5 或整项 Runtime 重构验收。

R0-GAP-01 的 R2 故障保留行为继续通过。version 回绕的 R0-GAP-02 仍为目标 FAIL、
characterization PASS；双 READY 兜底保持原行为。板上连续视频、恢复、UART/FPS 与 Ops/事件复制开销未测。
未下载、未综合/布局布线，未重复 RTL 回归；不得将本次结果当作板上或性能等价。

下一阶段 R4b：在保持真实后端轨迹的前提下，将 Head/PPU 事务迁入独立后处理服务，
保留各 Worker 的 local completion、producer mask、tail wait、admission 与下一帧前的旧占有释放。
回退可整体 revert 本阶段，恢复到 `02e0a0b`。
