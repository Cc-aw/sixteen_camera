# SW Runtime R5：应用、Facade 与指标分层

日期：2026-10-13。基线：`4c704f5`（R4b），实施分支：`main`。
按 [重构设计](sw-runtime-refactor.md) 完成 R5 离线结构验收，
机器可读证据见 [验证记录](../validation/sw-runtime-r5.json)。

## 1. 启动与应用

`main.c` 缩减为启动和事件循环：`board_boot()`、`app_video_init()`、
`rt_init()`、`app_init()`；循环保持 video → Runtime → app。
原 console 初始化/启动文字进入 `board/board_boot.c`。
`app_video_init()` 保留 video 初始化后、Runtime 初始化前的 Tensor reset preflight，
防止调试器复位留下的 WRITING/READY 被新 Runtime 接管。
启动仍是 board → video → 原 Tensor preflight → Runtime → app，未把清理挪到 Runtime 启动之后。

`app/app.c` 编排诊断服务和命令读取；`app/command.c` 处理 UART/help；
`app/mode_manager.c` 持有原模式状态并保留命令 gate、自测互斥和 Runtime toggle 条件。
带宽/读写测试移到 `diagnostics/board_bandwidth.c`，Tensor-only 与 `g` 统计移到
`diagnostics/tensor_production.c`。诊断仍按 bandwidth → tensor → write-only → UART 顺序运行。

保持 `t/u/U/T/R/W/C/b/s/v/o/p/P/m/i/r/c/h/?` 行为，
`g` 仍只在启用 `TENSOR_INGRESS_STATS` 的构建中开放。
Tensor 活动时只允许原白名单，V17A 自测命令继续提示使用独立 benchmark ELF。
带宽窗口、admission 修改与恢复、busy/错误/超时、restart 路径及 UART 字段均保留。
本阶段沿用已有互斥规则，没有引入新的模式策略或改写同步等待。

Application 和公开 Runtime header 不直接包含 Model Backend、Head queue、
私有 Core 或资源 lease；诊断头只提供调用入口，原设备/model 自测留在 diagnostics。

## 2. 真实 Facade 与迁移 shim

新增 `ai/runtime/rt.h`、`rt_types.h`、`rt.c`：单例 Context、初始化、enable/drain、
idle/state、原 poll 顺序、状态/stream/result 查询和通用帧指标。
原 batch/stream 状态布局与字段含义保留，用 canonical 类型和旧 typedef 别名兼容。
`ai_batch_runtime_stream.c` 只剩无状态转发，不再持有 Context、调度或设备逻辑。
旧 `context(arena)` 仍返回 NULL，未给已退休的 batch ABI 构造新对象。

`rt_init()` 调用真实 Core，原重新初始化保护触发时返回 -1，保留活动输入、
模型和 profile；返回 0 表示 Context 初始化完成，不代表所有板上设备已验证可用。
旧 void init shim 保留原调用行为；Application 在真实初始化之后输出既有
`AI_STAGE runtime_init`，并可报告返回错误。
`ai_runtime_bridge.c/.h` 的 no-op 已删除，生产源、Makefile 和调用点没有残留引用。

Facade 继续同步推进现有服务，未引入 budget 参数或承诺硬耗时上限。
borrowed detection pointer 保持原生命周期，调用者需按原流程消费。
诊断资源快照位于 `rt_debug.h`，不进入通用 Application contract。

## 3. 通用指标与专属诊断

`AiRtFrameMetrics` 只暴露 job/frame/stream/worker 与已有 scheduler、Tensor wait、
Head wait、PPU queue wait；查询返回按时间排序的副本，不读取设备、不推进模型、不消耗记录。
既有 16 条 profile ring 的生成位置、容量和回绕行为未改。

原 `s/p` UART 输出移到 `diagnostics/runtime_diagnostics.c`；
原 Gemmini 指令/stall、RVV、fence、DMA、错误和详细所有权字段保留。
`P` 仍走原 PPU 专属诊断，日志解析器无需更改。
没有添加 R6 的测量点，也没有改变 native step/服务频率。

## 4. 验证

| 命令 | 结果与范围 |
| --- | --- |
| `make test-runtime-r5` | PASS；91 组 Application 对照、47 组 canonical Facade 对照、Host/RV64 × 2/3 Worker 指标测试 |
| `make test-software` | PASS；原 ABI、R0–R4、HAL/资源、shim 与新增应用/Facade/指标 runners；RV64 未跳过 |
| `make test-v17a` | PASS；101 Python 用例、Host 后端与 Host/RV64 原 live context |
| 三种 `make firmware SOC_VARIANT=...` | PASS；triple32_v3_tensor、dual16、single4 |
| `make firmware-benchmark` | PASS；原三图冻结基准 |
| `make check-v17a-firmware check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；实际 ELF 屏障/身份、source lock、硬件参数和依赖闭包 |

`tests/data/runtime/r4b/` 冻结 `4c704f5` 的 main、旧 Runtime facade 与 bridge header，
按字节核验来源，不引用当前 Application 实现来生成 oracle。
91 组应用对照为 13 场景 × 7 配置：1/2/3 Worker × ingress stats 开/关，
另加 dual16 的 dedicated bandwidth banner。场景覆盖所有命令、互斥、四种带宽模式、
Tensor soak、enable 拒绝、metadata/release 超时、启动 stale/timeout、reader 错误与 idle gate。
运行实际新旧 main 循环，逐项比较诊断 MMIO、fence、Fake cycle、UART 参数和服务/API 调用，不过滤事件。
video、Runtime、reader 和 CSR 使用相同 doubles；`g` 比较 snapshot API 与 delta 输出，
snapshot HAL 本身未改，未宣称这些 doubles 模拟板上采集或 reader。

47 组 Facade 对照复用原 scheduler/fault/full workload；reference 为冻结 R4b facade，
current fixture 直接调用真实 `rt_*` 和 diagnostics，生产源不接受名字替换。
另保留原 R3 的 47 组 shim 对照，以及 R4b 的 27 组真实后端冻结对照。
指标测试用真实 Runtime 完成 24 个任务，验证 16 条记录的回绕/顺序、非法索引、
非消费查询与 stream/status；再验证活动计算期间 init 失败而占有和历史记录保留。

`sw/Makefile` 显式加入新源、删除 bridge；相关 build scripts 已通过实际构建，
它们仍统一调用 Makefile，无需另维护源列表。Host runner 明确区分 canonical facade 与冻结 Core 源。
legacy/V17A profile 和三变体 ABI 选择未改，错误 profile 的既有编译负例仍通过。
ELF/map、反汇编、编译参数、依赖、源码清单及日志位于忽略的 `build/runtime-refactor/r5/`。

## 5. 验收边界与下一步

native 模型、固定包/参数、task switch、Backend Ops、R4b 服务、Core 算法、
HAL/cache/fence、资源管理器、RTL/CSR、video 与原设备/model 诊断实现未改。
R0–R5 的离线结构迁移已完成，板上稳定性与实际函数/事件开销未验证。
version 回绕的 R0-GAP-02 仍是目标 FAIL、characterization PASS；双 READY 兜底保持原行为。
未下载、未综合或布局布线；本阶段没有硬件修改，未重复 RTL 回归。

R6 需先取得匹配 bitstream/固件/输入的连续视频、恢复和测量基线，
再逐项优化并比较吞吐、公平性、CPU 占用和 tail latency。本次不把离线轨迹或历史性能作为板测结论。
回退可整体 revert 本阶段，恢复到 `4c704f5`。
