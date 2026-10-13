# SW Runtime R1c 与完整 R1 离线验收

日期：2026-10-13。基线：`0eb072a`（R1b），实施分支：`main`。
本次按 [重构设计](sw-runtime-refactor.md) 完成 R1 的 overlay/cache 边界；
机器可读证据见 [验证记录](../validation/sw-runtime-r1c.json)。

## 1. Overlay 与策略边界

`sw/src/drivers/overlay/ai_overlay_device.h/.c` 只执行 mailbox busy 读取、stream/count 写入、
box/label 写入及 commit，不带 job/frame/version、最新结果选择或 TTL。
`ai_overlay.c` 保留原 API、坐标映射/打包、16 字节标签格式与测试图案，调用设备层；
计时改用原 `rdcycle` 对应的 `platform_read_cycle()`。
`sw/Makefile` 为三个固件加入设备源文件；Runtime 和 Result Manager 源码未改。

原调用次序保留：先映射/校验结果，再读 BUSY，写 stream/count，逐 box 写 INDEX/XY0/XY1，
格式化标签，再重复写 INDEX 和四个 label word，最后 commit。没有新增 fence。
硬件 overlay 的 metadata-only 结果继续在映射前直接返回成功，不重画 CPU boxes。
busy 时返回 0，Runtime 保留 dirty/clear 状态待下轮重试；排序和 TTL 留在原业务层。
测试图案保留 100 ms 超时，以及已 commit 但计时超限仍返回 -2 的原检查顺序。

## 2. Cache 能力与操作

`sw/src/platform/cache_ops.h/.c` 集中设备常量和 `AiCacheCapabilities`。
能力表描述现有视频构建协议，供后续资源层使用；此次不使用能力表改变运行策略或 UART。

| 能力 | 当前约定 |
| --- | --- |
| CPU DDR alias | bit31 OR；`cache_cpu_ddr_alias()` 保留高地址位；旧 `AI_DDR_CPU_ALIAS` 使用同一 mask，并保留常量表达式形式 |
| Flush64 | CSR `0x02010200`，64B covering lines；写原 CPU 地址，不自动增删 alias 位 |
| CPU/IO fence | `cache_cpu_fence()` 执行原普通 fence；裸 `fence` 与 `fence iorw,iorw` 对应相同编码，不把源码拼写当作不同能力 |
| 数据可见性 | V3 READY 在成功 B 后证明 L2 coherence，不能当作 DDR writeback；旧配置记录原 READY 协议，未替换为统一 DMA sync |
| PPU ordering | V17A 保留 ordered CPU readback，旧配置保留普通 fence；特殊编译宏仍只在原两个 PPU 对象上 |
| Accelerator completion | 原模型 accepted/retired 与本地 Head 完成证明；CPU fence/PPU readback 不替代停止或 clean 证明 |

后端 `yolo32_ppu_io_barrier` 中两个空 memory-clobber asm 改用同义 `cache_compiler_barrier()`，
中间的 availability read、故障处理和次序不变。native 模型/RoCC/Flush64 协议源码未改。
cache 实现新增编译检查，拒绝 PPU-only ordered override 误入普通 Flush64 路径。
逐行 flush 仍是普通 fence → volatile 64 位写 → 普通 fence；原 unaligned zero-length
覆盖一行、地址算术回绕的行为保留，不混入本次等价抽离。

## 3. 验证与产物

| 命令 | 结果/范围 |
| --- | --- |
| `make test-overlay-device` | PASS；1609 个完整事件与冻结 R1b 一致，覆盖 16 stream、8 box 上限、坐标 clamp/打包、标签截断/四舍五入/未知 class、busy 重试、count0 清框、硬件结果 bypass、测试图案重试/超时 |
| `make test-runtime-overlay-hal` | PASS；真实旧/新 overlay 接相同生产 Runtime，2/3 worker 分别 593/379 个事件一致；原 pipeline、busy 不写入、运行中结果保留、停用后 TTL 清框重试、晚到/重复/显式 stale 拒绝及 metadata-only 不重画 |
| `make test-cache-ops` | PASS；Host/RV64 × legacy/V17A 四组，各 42 个事件一致；11 flush 场景、7 alias 场景、实际 fake CSR 存储值采样及能力表校验；错误特殊宏负例被拒绝，RV64 未跳过 |
| `make test-software` | PASS；全部当时的 host runners、ABI/QEMU、R0/R1a/R1b；新增 RV64 cache 扩展随后按最终测试入口通过 |
| `make test-v17a` | PASS；101 个 Python 用例、Host/RV64 QEMU live context/backend，未跳过 |
| `make test-video` | PASS；含 overlay 的视频控制桥/CSR partition 与其余视频回归 |
| `make test-cache SOC_VARIANT=triple32_v3_tensor` | PASS；真实生成 L2 的 publication completion，8 行完成 |
| `make firmware SOC_VARIANT=triple32_v3_tensor` | PASS；V17A 三 worker 实时固件 |
| `make firmware SOC_VARIANT=dual16` | PASS；双 worker 固件 |
| `make firmware SOC_VARIANT=single4` | PASS；单 worker 固件 |
| `make firmware-benchmark` | PASS；原三图基准构建入口保持 |
| `make check-v17a-firmware check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；特殊 PPU 屏障、light context、manifest/source lock 与源依赖闭包 |

三个配置的 `cache_flush_range` 对照 R1b ELF，机器码均完全一致（13 条指令、两处普通 fence）。
最终 ELF、map、反汇编、依赖、源码清单和日志保存在忽略的 `build/runtime-refactor/r1c/`。
Overlay/cache 单测使用 `-O2 -Wall -Wextra -Werror`；Runtime 集成沿用原 host runner
的无显式优化选项。cache 单测把 CSR 地址映射为进程私有内存，RV64 在 QEMU user mode 执行；
这些证明软件操作等价，不替代真实 cache/DMA 板测或设备与 CPU 的完整协同仿真。

## 4. 完整 R1 验收范围

R1a Tensor、R1b PPU、R1c overlay/cache 各有独立接口、旧路径适配/构建接线、冻结 oracle
对照、原有回归和三配置构建。业务 Runtime/后端/overlay 适配层不再直接拼装 Tensor/PPU/overlay CSR；
读写、屏障及逻辑计时顺序经对照保持，调度、结果排序、所有权和超时未改。
据此签收 **R1 离线结构等价**，不是 R2–R6、目标安全契约或持续视频板测的验收。
原应用诊断及冻结模型私有 orchestration 保留既有入口，后续按应用/后处理边界迁移。

R0-GAP-01（abort 缺少停止证明）和 R0-GAP-02（Tensor version 回绕误判 stale）仍为目标契约 FAIL，
characterization PASS 仅表示现状未变。多 stream 同时双 READY 的交错仍保留 R0 限制。
新增 overlay 函数调用的板上开销未测；同步设备操作仍没有硬耗时预算保证。
板上下载、UART 捕获、FPS、完整综合及布局布线均 NOT_RUN。

回退：整体 revert 本阶段即可回到 `0eb072a`。下一步 R2 建立资源身份与所有权边界，
先保证没有停止证明的 abort/fault 路径保留占有；版本回绕修复仍须独立记录协议变更。
