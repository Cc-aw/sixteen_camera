# SW Runtime R1a：Tensor Device HAL

日期：2026-10-13。基线：`0975b01`（R0），分支：`refactor/sw-runtime-r1a`。
范围来自 [重构设计](sw-runtime-refactor.md) R1 与 [R0 最小计划](sw-runtime-baseline.md)：
本次完成 Tensor 设备边界，完整 R1 的 PPU、overlay/cache 部分仍待实施。
机器可读证据见 [验证记录](../validation/sw-runtime-r1a.json)。

## 1. 变更与接口

| 文件 | 职责/变更 |
| --- | --- |
| `sw/src/drivers/tensor/ai_tensor_device.h/.c` | 32 槽状态 bitmap、稳定描述符读取、同步 release ack、Producer admission/启停、诊断选择和 14 类计数 |
| `sw/src/ai/runtime/ai_batch_runtime_stream.c` | 原 helper 接设备接口；消除该文件全部直接 Tensor CSR/MMIO，包括状态输出；调度和所有权策略留在 Runtime |
| `sw/src/platform/cycle.h` | 独立 `platform_read_cycle()`，仍用原 `rdcycle` 指令，Runtime 不再依赖 MMIO 头 |
| `sw/Makefile` | 三个固件配置纳入新设备源文件，原 ABI/编译选项保持 |
| `tests/host/`、`tests/data/runtime/r0/`、根 Makefile | 修复原测试链接依赖；增加设备和 Runtime 对照测试及冻结 R0 oracle；增加两个测试入口 |

`AiTensorDeviceDescriptor` 只表示硬件元数据，不带 worker owner 或软件 generation。
设备把硬件 32 位 frame 零扩展到 64 位字段，保留 64 位 timestamp。
Runtime 的兼容 wrapper 仍将 owner 置为 INVALID、旧 generation 字段置为 version；
此次未将硬件 version 改成独立 generation，也未修改请求/完成事件 ABI。

读、释放、启用接口延续 `0` 成功、`-1` 无效/超时/拒绝。读取失败不改输出。
新增设备接口对越界 slot 做提前拒绝；现有 Runtime 的有效 slot 路径保持原顺序。
`release(slot, producer_enabled)` 由 Runtime 提供 enable 状态，设备不决定消费方能否安全释放。
诊断 `select_slot()` 与计数读取由单 CPU 串行调用；计数读取不是原子快照。

## 2. 保持的协议与行为

- `INDEX → fence → 1000 cycle settle → version/metadata/version`，稳定且非零 version、固定地址/stream/字节数、READY state 与 READY bit 全部校验。
- release 先等待前一次 GO 清零，再写 RELEASE、fence、CONTROL、fence，等待 READY/ERROR 与 GO 清零；原 100 ms 超时阈值及比较运算保持。
- admission mask/limit、Producer enable 回读、disable 写入和 fence 顺序保持；普通 Tensor MMIO fence 未替换为 V17A 的 PPU 专用屏障。
- worker 调度、同 stream 在途限制、held mask、Compute/Result 顺序、Head 归属、TTL、drain、错误路径与 UART 文本保持。

模型计算、RoCC、PPU、overlay、cache 操作及硬件源码未更改。
同步设备等待仍可超出上层软预算；此次不承诺严格调用耗时上限或 FPS 提升。

## 3. 验证

| 命令 | 结果与覆盖 |
| --- | --- |
| `make test-tensor-device` | PASS；32 固定槽、40 读取场景、8 release 场景、2 重复 release、2 enable 场景，以及 disable、无效参数、bitmap/14 类计数；与冻结 R0 比对每次 MMIO/fence/时钟读的序列摘要 |
| `make test-runtime-tensor-hal` | PASS；2/3 worker 分别 1059/822 个事件；完整文本轨迹的 MMIO、fence、模拟 cycle、dispatch、Compute/Result、UART 调用参数完全一致，含状态和错误槽诊断 |
| `make test-software test-v17a` | PASS；全部 host runners、101 个 Python 用例、RV64/QEMU ABI 与 V17A live context/backend 回归；新增测试随后以最终覆盖再次通过 |
| `make test-tensor-ingress test-tensor` | PASS；入口协议、真实生成 L2、DMA stress/overflow/abort drain/stall recovery |
| `make firmware SOC_VARIANT=triple32_v3_tensor` | PASS；V17 A 三 worker 实时固件 |
| `make firmware SOC_VARIANT=dual16` | PASS；双 worker 固件 |
| `make firmware SOC_VARIANT=single4` | PASS；单 worker 固件 |
| `make firmware-benchmark check-v17a-firmware check-deps` | PASS；基准构建、V17A 屏障/context/manifest、默认源闭包与工具依赖 |
| `make check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；V3 源闭包与工具依赖 |

三个配置的 Tensor 设备对象反汇编均确认 select/release/enable/disable 分别保留
1/2/2/1 条普通 fence，未引入 `yolo32_ppu_io_barrier`；冻结 Runtime oracle 内容与 R0
源码 SHA256 一致。专项检查亦确认硬件、模型、backend、postprocess 和 cache 源码无变更。

设备单测使用 `-O2 -Wall -Wextra -Werror`。Runtime 对照采用原 host runner 的编译选项
（无显式优化），因为冻结 R0 源在 GCC 11 的 `-O2 -Werror` 下触发已有
`selected_metadata.frame_id` maybe-uninitialized 诊断；未为适配测试改写旧 oracle。
生产固件按原优化选项编译。模拟 cycle 相等仅证明调用轨迹相等，不代表真实板上开销相等。
UART 比较的是实际传入 console 函数的参数；板上串口采集、下载、FPS 测量均 NOT_RUN。
本次没有启动完整综合或布局布线。

## 4. 已知缺口与回退

R0-GAP-01（abort=0 缺少停止证明）和 R0-GAP-02（version 回绕被判 stale）仍为目标契约 FAIL；
characterization 回归 PASS 表示现状未变，不能视为缺口修复。
单 worker 有固件构建与 ABI 检查，完整 fake-pipeline 等价轨迹覆盖 2/3 worker。
多 stream 同时双 READY 的选择顺序保留 R0，尚未补齐全部交错验证。

本次是独立提交，可整体 revert 回到 `0975b01` 的 Tensor/Runtime 路径。
生成 ELF、map、依赖文件、反汇编、日志保存在忽略的 `build/runtime-refactor/r1a/`，不提交 Git。

下一步 R1b 只封装 PPU CSR/receipt/完成读取与 generation 校验，保留兼容调用、Head 生命周期
及两个对象专用 ordered MMIO；建立同样的寄存器/屏障轨迹对照并单独提交。
R1c 再处理 overlay/cache 接口，完成后签收完整 R1。abort 安全回收留给 R2，
version 回绕修复须单独记录协议行为变更。
