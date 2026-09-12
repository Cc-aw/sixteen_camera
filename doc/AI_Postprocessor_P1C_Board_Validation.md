# AI Postprocessor P1C 板测记录与 P1C-2 准备

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
