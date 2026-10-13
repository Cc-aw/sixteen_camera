# SW Runtime R4b：Head/PPU 后处理服务

日期：2026-10-13。基线：`b1de2e3`（R4a），实施分支：`main`。
按 [重构设计](sw-runtime-refactor.md) 完成 R4b 离线验收，
机器可读证据见 [验证记录](../validation/sw-runtime-r4b.json)。

## 1. 计算与后处理边界

新增 `sw/src/ai/runtime/services/rt_postprocess_service.h/.c`。
服务独立持有 Head Queue、Head lease、publication mask、PPU reader/queue 状态、
超时与故障锁存、Head profile 和结果 ring；负责 BEGIN、commit receipt、
admission、descriptor submission、结果匹配及 Head retirement。
服务内部调用现有 PPU driver/publication/queue，没有改变 CSR 或 descriptor ABI。

模型后端保留请求、原始 CPU 结果、running/stage、起始周期、activation arena，
以及 native 模型的启动、轮询、局部完成与释放。它通过同步 Head 事件调用服务，
不再持有 Head Queue/lease/PPU 结果状态，也不直接调用 PPU HAL、publication 或 queue。
CPU fallback 仍由模型转换 detections，服务持有最终结果及原借用指针生命周期。

旧 `ai_model_backend_*` 入口作为兼容 facade 继续组合计算和服务，
R4a Ops、Application/诊断入口及 Runtime 调用点保持一致。
没有另加全 Worker pump；每个原 compute/result/early-service 位置仍推进一次原服务。
V17A 的 `yolo32_independent_step()` 频率与 local completion/tail wait 实现未改。

## 2. 完成证明与占有

`AiRtHeadEvent` 传递完整任务身份、产生的 mask、native local-completed mask、
请求 mask、任务起始周期及各 Head 的完成周期。
后端从原 `Yolo32IndependentStats` 生成事件；服务核验当前 Head 身份与 WRITING 状态，
确认请求存在、局部完成有效且完成周期不早于本任务，然后发布 delta 并等待原 receipt。
错误身份、非法 mask、缺失请求或过早完成均在 publication 前拒绝。
这项新内部接口不允许应用自行伪造完成证明。

部分 Head 完成只授权 publication。legacy Class0 的早期 admission 保持原位置，
V17A 仍等待全部六个 Head 及原 done/finished 证明，再进入完整任务 admission。
随后按原顺序完成 profile、native live release/finish、activation 回收，
清掉 worker→Head 生产关联后才允许该 Worker 进入下一帧。
PPU 仍独立占有旧 Head，直到结果的 bank/generation/stream/frame/version、
Head lease 身份及 producer_complete 均匹配，才 pop 并 retire。

BEGIN 未确认、部分 start、abort/ERROR、PPU timeout、DONE+READ_BUSY 继续保留资源。
service init 同样拒绝覆盖未退休的 Head、结果或故障。
身份验证允许既有故障 Head 接收可靠的 graph completion；它不会把 PPU 故障当作
计算未停止，也不会凭 graph completion 强制回收 PPU Head。
软件 generation 与硬件 generation/version 保持原独立语义。

`yolo32_ppu_io_barrier()` 迁入服务，保留两侧 compiler barrier 与原 uncached readback。
ordered-MMIO 编译覆盖仍仅用于原 publication/queue 对象；服务和设备函数不获得该覆盖，
避免将普通 CPU/IO fence 替换为 PPU readback。

## 3. 验证

| 命令 | 结果与范围 |
| --- | --- |
| `make test-runtime-r4b` | PASS；Host/RV64 完成证明负例与占有测试；冻结 R4a 的 27 组完整后端轨迹相同 |
| `make test-runtime-r3 test-runtime-backend test-runtime-r4a` | PASS；原 47 组 Runtime 对照、Host/RV64 Ops/profile 及真实 adapter 对照 |
| `make test-software` | PASS；全部 host runners、R0–R4/HAL/资源与新增后处理测试，RV64 未跳过 |
| `make test-v17a` | PASS；101 Python 数值/packet/scheduler/PPU 用例、Host backend 与 Host/RV64 live context |
| 三种 `make firmware SOC_VARIANT=...` | PASS；triple32_v3_tensor、dual16、single4 |
| `make firmware-benchmark` | PASS；原冻结三图基准 |
| `make check-v17a-firmware check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；实际 ELF 特殊屏障、manifest/source lock 与依赖闭包 |
| `make test-tensor-ingress test-tensor test-ppu SOC_VARIANT=triple32_v3_tensor` | PASS；Tensor 写入与 PPU publication、descriptor/128-bit 结果及六任务集成 |

R4b 对照独立编译 `tests/data/runtime/r4a/model-backend-reference.c.inc`，
它是 `b1de2e3` 原后端的逐字冻结副本。reference/current 均经过同一真实 Ops，
使用相同原 PPU/HAL、资源实现和 native/CSR doubles；新服务只链接进 current。
比较全部 MMIO、fence、逻辑周期、结果身份、资源快照与 UART 参数，不过滤事件。
legacy 各 10 场景，V17A 7 场景；覆盖 CPU/flush fallback、reader busy、错误/超时、
generation fault、六槽占有/复用与 BEGIN/start/abort 故障。
live fixture 中的 model-error 仍是 abort→ERROR 占有测试，不代表 native task 内部 fatal 注入。

新增 proof 测试在 Host 与 RV64 QEMU 上分别拒绝五种身份错配、非法 mask、
缺失 local completion/request 和过早周期；拒绝过程无 PPU IO、无资源释放。
同时验证 init 保留占有、部分 Head 不提前 admission、graph completion 只释放 activation、
匹配 PPU 结果才释放 Head。native 执行与 DMA 仍由 doubles 模拟。

固件、map、反汇编、依赖、编译参数、源码清单及日志保存于忽略的
`build/runtime-refactor/r4b/`。新 Host/RV64 测试使用 `-O2 -Wall -Wextra -Werror`。

## 4. 验收边界

native 模型、固定包/参数、task switch、ABI、HAL/cache/fence 实现、资源管理器、
R3 调度/状态策略、R4a Ops、RTL/CSR 与应用/诊断代码未改。
完成的是 R4b 离线服务迁移，尚未完成 R5/R6 或板上整体验收。
version 回绕的 R0-GAP-02 仍是目标 FAIL、characterization PASS；双 READY 兜底保持原行为。

未下载、未综合或布局布线；未测板上连续视频、恢复、FPS、时延与新增函数/事件复制开销。
逻辑周期轨迹相同不能证明实际 CPU 周期或性能等价。
下一阶段为 R5 Application/CLI/shim/profiling 分层。回退可整体 revert 本阶段，恢复到 `b1de2e3`。
