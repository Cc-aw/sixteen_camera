# AI Postprocessor P1C 板测记录与 P1C-2 准备

> 最新状态（2026-09-14）：新版 FBus 已由用户生成比特流并上板。
> 对齐修复后的软件完成 256/256 次带宽测试，CRC/timeout/AXI 均为零，
> pre/job=2/12，带宽 351 MB/s，600 MB/s Gate 仍未通过。
> 详见第 13 节；第 1～12 节保留各阶段历史条件与结论。

## 1. 结论

测试日期：2026-09-11。

本次 P1C 并发压力测试的结论分为两部分：

- **数据正确性与一致性通过**：256 次完整读取全部完成，累计读取
  541,900,800 byte；expected/observed CRC 完全一致；无 CRC mismatch、
  timeout、AXI error 或 reader backpressure；测试期间 preprocess 与两个
  Gemmini worker 均有活动。
- **当前 8 路平台带宽 Gate 未通过**：实测 118 MB/s，低于 600 MB/s
  平台 Gate。最终 16 路产品的 1.2 GB/s Gate 仍未进入验收；当前
  64-bit @100 MHz FBus 的理论 payload 上限只有 800 MB/s。

因此 P1C 暂不能关闭。下一阶段命名为 **P1C-2：FBus source 扩容与有序多
ID reader**。P1C-2 通过后再开始 P2 TinyYOLOv2 Decode。

## 2. 板端原始日志

```text
AI TRACE SNAPSHOT_BEGIN
AI TRACE SNAPSHOT_DONE
AI TRACE PREPROCESS_BEGIN
AI TRACE PREPROCESS_DONE
AI POST bandwidth prepare bytes/iterations=2116800/256
AI POST bandwidth running with preprocess + Gemmini DMA
AI POST bandwidth PLATFORM NO-GO MBps/bytes/cycles=118/0x00000000204CC000/0x000000001B3FCE4E
AI POST bandwidth stall(ar/rwait/rbp)=0x000000001B2F4419/0x000000001A3D664E/0x0000000000000000 bursts/beats/eff_permille=0x0000000000020500/0x0000000001026600/1000 max_outstanding=2
AI POST bandwidth verify(iter/crc/timeout/axi/flags)=256/0/0/0/0x00000000 crc(expected/observed)=0x8246D8B8/0x8246D8B8 overlap(pre/job/busy_skip/valid_mask)=16/76/76/0x000000FF
```

## 3. 数据解释

测试时钟按 100 MHz 计算。

| 指标 | 结果 | 说明 |
| --- | ---: | --- |
| 单次 tensor | 2,116,800 byte | YOLOv5 大小的后处理输入 |
| 迭代数 | 256 | 全部完成 |
| 累计读取 | 541,900,800 byte | 与 `2,116,800 × 256` 一致 |
| 累计周期 | 457,166,414 | 约 4.572 s |
| 实际吞吐 | 118.53 MB/s | 控制台取整为 118 MB/s |
| 单 tensor 时间 | 17.858 ms | `cycles / 256 / 100 MHz` |
| AR stall | 456,082,457 cycles | 占 active cycles 99.763% |
| R wait | 440,231,502 cycles | 占 active cycles 96.296% |
| R backpressure | 0 cycles | CRC consumer 没有限制吞吐 |
| burst | 132,352 | 每次 517 个 burst |
| beat | 16,934,400 | 每次 66,150 个 256-bit beat |
| burst efficiency | 1000 permille | burst 内 payload 完整 |
| 最大未完成 burst | 2 | 远低于 reader 名义配置 8 |

8 路、每路 30 FPS 要求每 4.167 ms 消化一个 tensor，仅 tensor payload 约为
508 MB/s。600 MB/s Gate 为仲裁、DDR refresh 和其他 DMA 留出余量。当前每个
tensor 需要 17.858 ms，距离平台 Gate 约有 4.28 倍差距。

## 4. 已确认的瓶颈

reader 虽然允许 8 个 burst 未完成，但当前 SoC 生成配置限制了 FBus AXI 到
TileLink 的 source 空间：

1. Chipyard 的 `WithCustomSlavePort(data_width, id_bits)` 把
   `sourceBits` 固定为 4。
2. 生成的 `AXI4IdIndexer_1.sv` 接收 4-bit AXI ID，却只把 ID bit 0 送给
   `AXI4ToTL`；ID bits 3:1 仅保存在 echo metadata 中。
3. 生成的 `AXI4ToTL.sv` 只有两个读计数器，并生成 4-bit TL source：1-bit
   物理 AXI ID、2-bit 计数器和 1-bit 读写标识。
4. 当前 reader 所有请求都使用 AXI ID 0，板测最终只观察到两个高层 AXI
   burst 未完成。99.763% AR stall 说明请求注入能力是首要瓶颈。

对应的可维护源文件是：

- `/home/wzr/chipyard/generators/rocket-chip/src/main/scala/subsystem/Configs.scala`
- `/home/wzr/chipyard/fpga/src/main/scala/taihang_soc/Configs.scala`

当前项目使用的配置为
`TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig`。生成后的 RTL
位于 `rtl/soc/.../gen-collateral/`，不能作为源文件直接修补。

## 5. P1C-2 实现范围

实现状态（2026-09-11）：reader、diagnostic、软件、Chipyard 配置和生成
collateral 已完成；乱序多 ID 仿真与软件构建通过。顶层 Vivado elaboration 和
新版 bitstream 上板复测待完成。

### 5.1 扩大 SoC source 容量

- 给 `WithCustomSlavePort` 增加 `source_bits` 参数，默认值保持 4，避免影响
  其他配置。
- 仅在本项目目标配置中设置 `source_bits = 7`。
- 使用 `scripts/generate_taihang16_rtl.sh` 重新生成 SoC collateral。
- 静态确认生成后的 TL source 宽度从 4 bit 增加到 7 bit，且读 source 计数
  容量达到 64。

实际生成结果仍由 `AXI4IdIndexer` 将 4-bit 外部 AXI ID 映射为两个物理 ID
组，并通过 echo metadata 恢复外部 RID；每组读计数容量从 4 增加到 32，合计
提供 64 个读 source。使用 `scripts/sync_taihang16_rtl.sh` 检查该结构并将生成
结果同步到项目。

### 5.2 实现有序多 ID reader

- 使用 8 个 AXI ID/slot 并行发起请求。
- 每个 slot 最多保存一个 4 KiB burst，即 128 个 256-bit beat；8 个 slot
  需要 32 KiB reorder storage，目标实现为 true dual-port BRAM。
- R channel 按 RID 将返回 beat 写入对应 slot，允许不同 ID 的 response
  交错或乱序完成。
- 输出端严格按请求顺序释放 slot，保持现有 tensor byte stream 和 CRC 顺序。
- unaligned first/last byte keep 在有序输出路径处理。
- 保留 RRESP、RID、RLAST 协议检查，并增加 slot/reorder 高水位诊断。

diagnostic capability 已更新为 `0x00202105`，新增：

- `0x54 MAX_REORDER`：本次命令的 reorder slot 占用高水位；
- `0x58 ACTIVE_ID_MASK`：本次命令实际发出过的外部 AXI ID。

### 5.3 验证顺序

1. 仿真：AXI responder 接收多个 ID，主动制造跨 ID 乱序完成和合法交错；检查
   输出 byte stream、byte count 与 CRC 精确一致。
2. RTL elaboration：确认 SoC collateral、reader 和顶层端口一致。
3. 生成 bitstream 和 ELF，重复控制台 `w` 测试。

## 6. P1C-2 Go / No-Go

以下条件必须同时满足：

- 256/256 iteration 完成；
- expected/observed CRC 一致；
- CRC mismatch、timeout、AXI error、error flags 全为 0；
- preprocess overlap 与 Gemmini job overlap 均非 0；
- 当前 8 路板卡 sustained read 不低于 600 MB/s；
- AR stall 与 R wait 相比本基线明显下降；
- 诊断证明多个物理 AXI ID/source 实际并行工作；
- 当前 8 路摄像头的 `valid_mask` 为 `0x000000FF`。

最终 16 路产品的 1.2 GB/s Gate 单独保留。由于当前 FBus 理论上限为
800 MB/s，后续仍需通过 FBus 加宽或提频完成该 Gate。

## 7. 复现入口

```bash
# 软件、reader 与 diagnostic 回归
scripts/run_ai_postprocessor_tests.sh
make -C sw all

# 修改 Chipyard 配置后重新生成本项目所用 SoC RTL
scripts/configure_taihang16_p1c2.py --apply
scripts/generate_taihang16_rtl.sh
scripts/sync_taihang16_rtl.sh

# 板端
# 启动 AI runtime 后，在串口控制台输入：w
```

## 8. P1C-2 新版 bitstream 板测（2026-09-12）

```text
AI POST bandwidth prepare bytes/iterations=2116800/256
AI POST bandwidth running with preprocess + Gemmini DMA
AI POST bandwidth PLATFORM NO-GO MBps/bytes/cycles=112/0x00000000204CC000/0x000000001CB67F8B
AI POST bandwidth stall(ar/rwait/rbp)=0x000000001CA6216C/0x000000001BB2818B/0x0000000000000000 bursts/beats/eff_permille=0x0000000000020500/0x0000000001026600/1000 max_outstanding=2 reorder/id_mask=2/0x000000FF
AI POST bandwidth verify(iter/crc/timeout/axi/flags)=256/0/0/0/0x00000000 crc(expected/observed)=0x8246D8B8/0x8246D8B8 overlap(pre/job/busy_skip/valid_mask)=5/26/0/0x000000FF
```

结论：多 ID reader 的数据正确性通过，8 个 ID 均被使用，CRC、timeout、AXI
error 和 backpressure 均无异常。吞吐约 112.49 MB/s，AR stall 占 99.78%，
R wait 占 96.46%，P1C 平台 Gate 仍为 No-Go。`busy_skip=0` 只表示本轮没有碰到
后端 coherence 检查的 busy 分支，不是并发必需条件，已从 Gate 判据移除并保留
为观测字段。

进一步检查生成 RTL 后确认，`max_outstanding=2` 反映 AXI4Fragmenter 前的一级
队列加当前请求，不能代表拆分后的 TileLink source 数。`sourceBits=7` 已生成
128 个读写 source，其中两个物理 AXI ID 组各有 32 个 read source；因此不能再
把高层数值 2 当作 source 容量未生效的证据。

下一步 P1C-3 使用同一 bitstream 扫描 64 B 到 4 KiB 的 AXI burst 粒度。串口
命令 `W` 每个点运行 16 次并输出 CRC、吞吐、stall、outstanding、reorder 和
ID mask；`w` 保留 4 KiB、256 次正式 Gate。diagnostic capability 更新为
`0x00202205`，新增 `0x5c BURST_BEATS`。

## 9. 诊断统计快照修复（2026-09-12）

板端 `W` 扫描的 64 B 点完成 16/16 次，约 207.33 MB/s，CRC 和字节/beat
计数一致；128 B 点在 12 次成功后退出，最终 CRC 相等但校验异常计数为 1。
现有软件将字节数不符也计入 `crc_mismatches`，所以该输出不能直接认定为
CRC 数据损坏。两点的 preprocess/job overlap 均为 0，不能作为并发 Gate。

代码检查发现诊断 CRC 已锁存，但字节数、请求数、beat、周期、stall 和 ID
统计直接读取诊断/PPU 共用 reader 的实时计数。PPU 在诊断完成后复用 reader
时可覆盖这些值，导致 CPU 读到不同任务的数据。

修复采用两阶段快照：

- 在诊断 `reader_done` 时保存全部 reader 计数及错误状态，防止 CRC 收尾
  期间 reader 已被 PPU 复用。
- CRC drain 完成后，统一发布 reader 快照、CRC、byte sum、nonzero 和完成
  计数。结果保持到下一次诊断完成，启动或 clear-done 不清除旧结果。
- 诊断 STATUS 的 error 位属于已发布快照，busy 位继续表示共享 reader 的
  实时状态。MMIO 地址及 capability 保持兼容。

回归覆盖诊断完成后 PPU 运行中和运行结束后的全部结果寄存器稳定性，以及
后续诊断更新快照。此改动需要重新生成并下载 bitstream 后才能修复板端行为；
尚未完成新版板测。八内部 AXI ID 的带宽优化不包含在本次修复中。

## 10. 八内部 AXI ID + 64 B 读取（2026-09-12，待合并上板）

`SlavePortParams` 新增 `fifoBits`（默认 1），`WithCustomSlavePort` 新增
`fifo_bits`（默认 1）。仅本项目设置 `fifo_bits=3, source_bits=7`：内部 ID
组从 2 增至 8，每组 8 个读 source，总计仍为 64。保留 FIFO fixer 和返回
顺序保证；不直接修改生成 RTL。配置补丁、生成和同步入口仍为：

```bash
python3 scripts/configure_taihang16_p1c2.py --apply
scripts/generate_taihang16_rtl.sh
scripts/sync_taihang16_rtl.sh
python3 scripts/run_fbus_generated_path_test.py
```

同步前由 `check_fbus_id_groups.py` 检查实际 FBus coupling 实例，确认 ID
保留低 3 bit、TL source 为 7 bit，且存在八组读计数器。

PPU 固定使用 64 B burst，与诊断 `BURST_BEATS` 设置解耦，避免 `W` 扫描
改变生产任务的读取粒度。小写 `w` 的 256 次正式测试改用 64 B；大写 `W`
仍扫描 64 B 至 4 KiB。历史 4 KiB 数值仅作为基线。

新增 `tb_fbus_generated_path`：真实生成的 AXI ID indexer、fragmenter、
user yanker、AXI-to-TL、width widget、FIFO fixer 和 buffer，连接 64-bit
模拟内存。模拟内存设置 48 拍基本延迟、部分地址额外 24 拍延迟，支持跨
source 乱序返回；逐字节验证 32 KiB 数据及帧边界。结果如下：

| 内部 ID 组 | burst | 周期 | 按 100 MHz 折算 MB/s | TL 未完成请求峰值 |
| --- | ---: | ---: | ---: | ---: |
| 2（旧 RTL） | 4096 B | 27940 | 117 | 3 |
| 2（旧 RTL） | 64 B | 14868 | 220 | 3 |
| 8（新 RTL） | 4096 B | 27940 | 117 | 3 |
| 8（新 RTL） | 64 B | 8079 | 405 | 8 |

这验证了八组并行度以及短 burst 的必要性，不是 DDR/全 SoC 性能预测，
不代表通过 600 MB/s 并发 Gate。快照修复、全部后处理回归与软件构建通过；
新版 bitstream 和板端 `W`/`w` 验证仍待完成。

## 11. FBus 加宽、动态 ID 与读写分组隔离（当前候选，待用户生成比特流）

本节取代第 10 节的八 ID 候选配置。没有生成或下载新版 bitstream。

### 最终配置

- 本目标 `FrontBusKey.beatBytes=32`，物理 FBus 从 64-bit 加宽为 256-bit，
  与外部 AXI、SBus 对齐，消除中间 `256 → 64 → 256` 转换。100 MHz 理论
  payload 上限由 800 MB/s 增至 3.2 GB/s。
- 外部 `id_bits=5`、内部 `fifo_bits=5`、`source_bits=7`：32 个独立 ID 组，
  每组保留两个 read source 的容量。相关顶层/DDR 子系统接口均改为 5-bit。
- 后处理 reader 使用 ID 0～30；ID 31 专供 preprocess 写入。FIFO fixer
  同时约束同一组的读写，仅增加读 ID 而不隔离写 ID，会在并发时再次产生
  请求通路阻塞。
- 写 CDC 桥通过 `FBUS_WRITE_ID=31` 重映射 AWID，并保存原始 3-bit AWID，
  在 B 返回时恢复给预处理器。默认 `FBUS_WRITE_ID=-1` 保持其他实例行为。
- reader 使用 64 个按序输出 slot，与 31 个请求 ID 解耦；从空闲 ID 中轮转
  分配，AR 被阻塞时保持已选 ID 稳定。RLAST 后立即释放 ID，但对应数据继续
  保存在 reorder RAM，直到前面的数据输出。修正了 ID 上界比较的位宽截断。
- reorder RAM 改为独立同步读写的扁平 block RAM，容量 256 KiB，支持诊断
  的 4 KiB burst 扫描。生产 PPU 固定 64 B，`w` 默认 64 B，`W` 保留扫描。
- 前一节的诊断统计快照修复继续保留。

### 受控吞吐与并发验证

`run_fbus_generated_path_test.py` 使用实际生成的 FBus 转换器，并包含真实
AXI channel join、并发 AXI 写事务和可配置返回模型；不是完整 DDR/Gemmini
系统仿真。按序逐字节检查完整 2,116,800 B，输出每 4 拍最多接收一个 32 B
beat，对应当前 fast diagnostic 的 800 MB/s 消费上限。

| 模型 | 周期 | MB/s @100 MHz | 完成写事务 | 性能断言 |
| --- | ---: | ---: | ---: | --- |
| 基本延迟 48 拍，部分地址加 24 拍，高 source 优先，无额外响应间隔 | 264844 | 799 | 0 | ≥600，通过 |
| 基本延迟 160 拍，部分地址加 24 拍，按最早到期请求公平服务，每个响应后让出 6 拍，并发写 | 306132 | 691 | 1034 | ≥600，通过 |
| 同样 160 拍、6 拍间隔和并发写，但始终优先最高 source | 378376 | 559 | 1935 | 仅正确性压力测试；未达 600 |

公平模型允许请求乱序返回（到期时间含地址相关延迟），但不让低优先级 source
无限延后。固定高 source 优先模型可能长时间推迟早期请求，故保留其真实低
带宽结果，不能宣称所有仲裁条件均已达标。

在 32 KiB 公平并发模型中，未隔离写 ID 时约 425 MB/s，隔离后约 666 MB/s；
完整 tensor 为上表 691 MB/s。该对比支持读写分组隔离的必要性。板端真实 DDR
仲裁、Gemmini 争用及全 SoC 时序仍必须验证，模拟结果不等于板端 Gate。

复现：

```bash
bash scripts/run_fbus_throughput_tests.sh
scripts/run_ai_postprocessor_tests.sh
make -C sw all
# 可选：仅 reader 综合与顶层 RTL elaboration，均不生成 bitstream
vivado -mode batch -source scripts/check_fbus_reader_synthesis.tcl
vivado -mode batch -source scripts/check_postprocess_elaboration.tcl
```

功能回归覆盖动态 ID 复用、reorder 占用超过未返回请求数、跨 ID 乱序及交错
响应、输出反压、非对齐/4 KiB 边界、AXI 错误、诊断快照、PPU 结果，以及
写 CDC 三个不同原始 ID 的映射/恢复（重映射和默认两种模式）。

最终检查（2026-09-12）：全部后处理功能回归通过；reader 单独综合使用
57 个 BRAM36、3143 个 LUT、2429 个寄存器，100 MHz 综合阶段最差 setup
slack 为 +5.704 ns。完整 `top_wrapper` RTL elaboration 返回
`POSTPROCESS_TOP_ELABORATION=PASS`，确认生成的 SoC 与 5-bit AXI 接口
能够集成。该检查仍有摄像头时钟重复定义等约束警告；reader 的综合 slack
不代表全 SoC 布局布线时序通过。两个 Vivado 检查应串行运行，或使用不同
工作目录，避免 `.Xil` 临时目录冲突。

600 MB/s 仅为本轮带宽 Gate。若仍完整读取 2,116,800 B，读取时间为
3.528 ms；2 ms 预算至少需要 1.0584 GB/s，且尚未计入无法重叠的其他工作。

## 12. 板端结果与软件调度修复（2026-09-14）

新版硬件实测 64 B 约 406～410 MB/s，max_outstanding=27、reorder=46、
ID mask=0x7FFFFFFF；128/256 B 约 183/179 MB/s。CRC、AXI 错误均为零，
但正式测试只完成 88/256 次，256 B 扫描只完成 14/16 次，pre/job overlap
均为零，因此并发 Gate 尚未通过。双 worker bit-exact 正确性测试通过。
固定 image025 的 PPU 平均 224,760 cycles，总耗时 476,769 cycles：
100 MHz 下分别约 2.248/4.768 ms；若 300 MHz 下周期数不变，则约
0.749/1.589 ms。用户的 2 ms 目标以未来 300 MHz 为准；DDR 等待和全系统
时序仍需在目标频率验证。

软件修复（无需重新生成 bitstream）：

- 带宽测试改为等待启动/等待完成两个状态；遇到 reader 忙重试，不结束测试。
- YOLOv5nu 诊断启动同时检查 PPU busy，避免在 PPU 描述符间隙提交被拒绝的命令。
- 首轮和后续轮次均非阻塞等待至少 1 ms，让主循环继续推进 runtime/PPU。
  等待 reader 最长 5 秒，超时报 -6；已启动命令超时报 -4。
- burst 配置在实际成功获取 reader 后、启动前写入，避免忙时配置被忽略。
- 新增 `exit(code/completed/requested/busy_retries)`：成功为 code=1，
  正式测试应完成 256/256。异常扫描显示 ABORTED。无完成快照的超时不再
  误报 CRC 错误；Gate 明确要求完成全部轮次。
- 调度等待不纳入 reader active_cycles，所以打印 MB/s 仍是读事务活跃期间
  吞吐；pre/job 是整个测试窗口内完成数，不能证明每个读事务都发生 DMA 重叠。

`bash sw/test/run_ai_postprocess_schedule_test.sh` 验证 reader/PPU 忙重试、
调度让出、完整轮次、获取超时与执行超时；runtime 回归和 `make -C sw all`
通过。输出 `sw/build/hdmi_tx_test.elf`。上板加载新 ELF，开启 runtime 后重跑
小写 w，确认 exit=1/256/256/...、CRC/timeout/AXI 均为零和 pre/job 非零。

### 软件更新后的 PPU 对齐回归

调度修复版上板仅运行 i 或 T 即报 PPU status=0x06，固定图 positions=6300、
candidates=10、nms=0；恢复调度前代码重建的对照 ELF，T 三次全部通过。
ELF 符号对比发现 activation_arenas 从 0x803c68a0（32 B 对齐）移动到
0x803c69f0（仅 16 B 对齐）。原 row_align(1) 未保证 PPU 32 B 完整拍要求，
新增状态改变链接布局后暴露了该缺陷。小写 t 的软件后处理不覆盖此问题。

已将双 worker arena 显式 aligned(64)，同步修改 generate_runtime.py。
保留调度修复的新 ELF 中地址为 0x803c6a00，两个 worker 的六个 head 地址
全部通过 64 B 对齐检查；构建、调度回归及下载前检查通过。板端 T/i/w 复验
仍待完成，尚不能宣称该版本已上板通过。

## 13. 调度与对齐修复后的完整板测（2026-09-14，当前状态）

硬件为用户生成并加载的新版 FBus；软件保留非阻塞忙重试和 1 ms 调度窗口，
双 worker activation arena 显式 64 B 对齐。当前加载文件为
`sw/build/hdmi_tx_test.elf`，不需要为这两项软件修复重新生成比特流。

### 原始日志

```text
AI POST bandwidth prepare bytes/iterations/burstB=2116800/256/64
AI POST bandwidth running with preprocess + Gemmini DMA
AI POST bandwidth PLATFORM NO-GO burstB/MBps/bytes/cycles=64/351/0x00000000204CC000/0x0000000009335258
AI POST bandwidth stall(ar/rwait/rbp)=0x00000000082FA94F/0x000000000830E284/0x0000000000000000 bursts/beats/eff_permille=0x0000000000813300/0x0000000001026600/1000 max_outstanding=28 reorder/id_mask=51/0x7FFFFFFF
AI POST bandwidth verify(iter/crc/timeout/axi/flags)=256/0/0/0/0x00000000 crc(expected/observed)=0x8246D8B8/0x8246D8B8 overlap(pre/job/busy_skip/valid_mask)=2/12/0/0x000000FF
AI POST bandwidth exit(code/completed/requested/busy_retries)=1/256/256/808
```

### 已确认的结论

- 调度修复通过本次板测：256/256 次全部完成，exit=1；808 次忙重试没有
  造成提前退出。累计读取 541,900,800 B，CRC 一致，无超时或 AXI 错误。
- 测试窗口内 preprocess 完成 2 次、job 完成 12 次，runtime 已有推进。
  这些是整个窗口的完成数，不证明每次诊断读取都与 DMA 同时发生。
- 带宽为 351 MB/s @100 MHz，低于 600 MB/s，平台 Gate 仍为 NO-GO。
- max_outstanding=28、reorder=51、ID mask=0x7FFFFFFF，说明多 ID 和
  请求 ID/重排槽解耦已工作。rbp=0、eff_permille=1000，未观察到 reader
  的 R 接收反压或有效字节利用率损失。
- AR stall 与 R wait 各约占 active_cycles 的 89%，提示下游请求接收、
  返回延迟或仲裁仍有限制；两个计数可重叠，不能相加或据此定位唯一根因。
- 之前约 410 MB/s 的测试只完成 88 次且 overlap 为零，与本次负载条件不同，
  不能直接用带宽差值认定软件修复降低了硬件吞吐。

### PPU 回归与性能证据边界

调度前重建对照 ELF 的 T 三次 PASS，核心 cycles=230348/222462/222825，
平均 hw_wall=0x74B67、软件 cycles=0xE12E46，speedup_x100=3087。
该结果属于对照 ELF。对齐修复后的当前 ELF 尚未收到单独 T 或 t 的完整
复验日志，不能把对照版 PASS 当作当前版 PPU 正确性/性能已验收。

用户最终 2 ms 目标以未来 300 MHz 为准，当前板端为 100 MHz。此前正常
版本约 47.7 万总周期，在周期数不变的假设下折算约 1.59 ms @300 MHz；
DDR 等待周期及全系统时序可能变化，不能直接按三倍预测最终性能。

### 下一步

1. 对齐修复后的当前 ELF 运行大写 T，记录 PPU 正确性、核心及总周期数。
2. 增加同一固件下独占读取与并发读取的可比测试，固定 tensor、burst 和
   迭代数，分别记录 reader active 吞吐、测试墙钟耗时及 runtime 推进量。
   此对照模式尚未实现。
3. 根据对照结果定位下游争用；目前没有足够证据继续单纯增加 ID/重排槽。
   600 MB/s Gate 与未来 300 MHz 下的 2 ms 后处理验收分别跟踪。
