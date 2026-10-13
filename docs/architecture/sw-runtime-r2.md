# SW Runtime R2：资源身份与安全回收

日期：2026-10-13。基线：`751178e`（R1c），实施分支：`main`。
按 [重构设计](sw-runtime-refactor.md) 完成 R2 的资源边界；
机器可读证据见 [验证记录](../validation/sw-runtime-r2.json)。

## 1. 管理对象和接线

新增 `sw/src/ai/runtime/resources/`：`rt_job`、`rt_tensor_manager`、
`rt_arena_manager` 和 `rt_head_manager`。三个视频配置均编入这些源文件。

| 对象 | 身份与生命周期 |
| --- | --- |
| Job | `job_id/worker_id/stream_id/frame_id/version` 五元组；Worker Job 与 Post Job 共用身份，分别记录计算、后处理和退休状态 |
| Tensor | 固定 32 槽，stream s 对应 s/s+16；校验物理地址、长度、READY metadata；提交前 RESERVED，接受后 OWNED，匹配 Compute Done 后 RELEASE_PENDING，硬件 release ack 后 FREE |
| Activation | 每 Worker 独占，1/2/3 worker 配置；匹配 native 计算完成证明后释放；activation 地址仍由原 native 模型分配，诊断快照读取原指针 |
| Head | 最大 6 槽，每 Worker 两槽；原 `ai_head_slot_queue` 继续执行 WRITING/READY/PROCESSING/FREE 转换，资源层记录完整身份、软件租约、硬件 generation 和 producer mask |

Tensor 与 Head 的软件租约使用独立的 64 位 generation，不复用硬件 version/generation，
到 `UINT64_MAX` 拒绝新租约；软件 job ID 也拒绝回绕。
匹配五元组但租约过期的请求不能释放新占有者。硬件 32 位版本协议及其比较方法未改。
资源层初始化只用于新存储或已确认静止的状态，Runtime/backend 入口阻止有占有者时清零。

## 2. 两种完成证明

原 healthy 路径的调度和 native/V17A 计算协议保留。
Compute Done 必须匹配完整身份，才能归还 activation 并授权 Tensor release；
release ack 失败时保留 RELEASE_PENDING，成功只增加一次 consumed。
新增 Tensor HAL `release_poll` 只读取 ack 状态，原 release 函数的写入和屏障不变。
重试先等待未结束的 GO；观察到 ack 后不重发。若槽仍存在，必须重新读取稳定 metadata，
核对 stream/frame/version/timestamp/address/bytes 后才能重发。若已出现新帧则保留 Fault，
不发第二次 release，避免释放新帧。
Post Job 可以在 Tensor 归还后继续存在，同一 Worker 的下一帧可以与旧 Head 后处理重叠。

Head 的退休另需 PPU 完成。队列路径先核验 slot、当前 publication generation、
stream/frame/version 和 CPU 保存的完整 Job 身份，再等 producer_complete，最后 pop 完成记录、
完成原 Head Queue 转换并归还软件租约。旧单 reader 路径要求 DONE 且 BUSY/READ_BUSY 均清零。
设备 generation 的现有宽度和复用边界没有改变；软件租约不能替代硬件协议中的 generation。

## 3. 故障保留与诊断

以下行为是 R2 安全契约要求的明确变更，不能作为全路径行为等价声称：

- worker error、计算超时、错误 Compute identity，以及没有停止证明的 abort：
  Tensor/activation/Head 保持占有，标记 FAULT_HELD，停止新派发。
- 后端新增 `AI_MODEL_SUBMIT_FAULT_HELD=-4`，表示 BEGIN ack 或 model start 返回错误后
  仍不能证明未被设备接受；Runtime 保留输入。原其他负提交状态仍表示未接受。
- ERROR polling 不再清除 running；重复 abort 不会随后伪装成成功。
  software init、重新 enable 都不能绕过仍被持有的资源。
- 错误 PPU identity/generation 不 pop、不归还 Head；DONE 与 reader busy 同时出现也保留 Head。
  Runtime 收到无法匹配的结果 completion 时保留对应 Post Job。
  有有效退休证明但结果内容非法的情况仍按原错误结果路径处理。
- ERROR-only Tensor 不再被判为 idle；drain 也回收无占有者的 ERROR 槽。
  初始 enable 保留原错误清理能力，先确认没有占有者、READY 和 WRITING，再执行 release ack。

当前 native 接口没有可验证的取消完成事件，因此不实现“等待一下便强行释放”。
无法确认停止的 Fault 保留到真实硬件复位及固件重启。已经证明完成的其他资源仍可正常回收。

`ai_batch_runtime_get_resources()` 和 `ai_model_backend_get_resources()` 提供 Tensor/activation/Head 的占有者与状态，以及 Post Job 数量快照；
不增加 MMIO/fence/clock 操作。READY/ERROR/WRITING 是最近一次设备读数。
`held_tensor/active_worker/owned_head` 是物理 slot/worker mask；`pending_post` 是数量，
`release_retry` 是 ack 重试计数，`unsafe_fault` 是标记为故障保留的资源/任务数量，
不是已经发生不安全 FREE 的计数。故障 UART 增加汇总及 Tensor slot/job/lease/frame/version。

## 4. 离线验证

| 命令 | 结果与范围 |
| --- | --- |
| `make test-runtime-resources` | PASS；Host/RV64 QEMU，32 Tensor、6 Head 容量、1/2/3 worker、五元组错配、重复硬件版本、旧租约/重复释放拒绝、租约上限、独立退休 |
| `make test-runtime-faults` | PASS；Runtime 10 场景 × 3 配置：ERROR-only drain/startup、release retry/GO pending/late ack/新帧复用、abort 假成功、timeout、错误 compute、未确认 submit；backend 4/4/3 场景：BEGIN ack、部分 start、legacy model error/live abort，以及 legacy DONE+READ_BUSY |
| `make test-software` | PASS；全部 host runners，含原 pipeline、ABI、HAL 与 R2 资源/故障测试；RV64 未跳过 |
| `make test-runtime-baseline test-runtime-ppu-hal` | PASS；healthy backend 与冻结 R1a 的 MMIO/屏障/计时/UART 一致；abort-gap 明确核验旧 FAIL 与新保留状态，未要求两条故障轨迹相同 |
| Runtime Tensor/overlay HAL 对照 | PASS；healthy Tensor 集成 2/3 worker 957/825 事件，overlay 集成 545/388 事件；保留 dispatch/result/TTL/busy 次序 |
| `make test-v17a` | PASS；101 Python 用例与 Host/RV64 live context/backend；六 Head 全占有时 activation 已归还，退休后占有 mask 清零 |
| `make test-tensor-ingress test-tensor test-ppu SOC_VARIANT=triple32_v3_tensor` | PASS；TensorIngress/真实 L2、DMA stress/overflow/abort/stall、publication/PPU 六槽及 reset/error/wrap 回归 |
| 三种 `make firmware SOC_VARIANT=...` | PASS；triple32_v3_tensor、dual16、single4 |
| `make firmware-benchmark` | PASS；冻结三图 benchmark |
| `make check-v17a-firmware check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；ELF 特殊屏障和 source/ABI closure |

Tensor Runtime 的旧/新 healthy trace 只规范化新增的 **ERROR=0 读取**；
不筛除正 ERROR、写入、fence、cycle 或业务事件。ERROR 分支另由故障测试覆盖。
原 corrupted-result 场景移到 healthy pipeline 场景之后，分别验收新的故障保留行为。
历史 R0/R1 验证报告及冻结源码未重写；当前 baseline runner 使用新的 R2 ownership golden。

ELF、map、反汇编、编译参数、依赖、源码清单及日志保存于忽略的
`build/runtime-refactor/r2/`。RTL、CSR、模型参数、固定包、task switch、source locks、
cache/Flush64、PPU fence 和原 Tensor release 实现未改；仅新增 Tensor ack 观察接口。独立 benchmark/native 私有 orchestration 仍使用原入口；
本阶段资源管理接入范围是生产视频 Runtime 与 legacy/V17A 视频 backend。

## 5. 验收边界与后续

R0-GAP-01 在当前视频路径离线测试中已修复：没有停止证明时保留占有。
R0-GAP-02（UINT32_MAX → 1 被误判 stale）仍为目标契约 FAIL，characterization PASS；
应按设计单独提交版本协议修复。多 stream 同时双 READY 的全部交错仍未穷尽。

Host/Fake CSR 与 QEMU 证明软件状态和操作次序；RTL 测试证明既有协议回归。
真实异步硬件与 CPU 协同、板上恢复、UART/FPS/性能开销未验证。
没有下载、完整综合或布局布线。本次只验收 R2 离线资源边界，不声称 R3–R6 或整项重构完成。

下一阶段 R3：拆分纯候选选择、派发事务、Pipeline completion 与 Runtime 状态机，
继续保留原 latest-frame/EDF 策略。回退可整体 revert 本阶段，恢复到 `751178e`。
