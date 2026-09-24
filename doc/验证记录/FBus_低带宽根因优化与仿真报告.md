# FBus 低带宽根因、优化修改与仿真报告

日期：2026-09-24

## 1. 结论

师兄提出的“64-bit、100 MHz FBus 实测读写带宽偏低”不是单一位宽问题。当前源码中确认了两个相互独立的限速点：

1. SoC FBus 的生成路径为 `AXI4IdIndexer -> AXI4Fragmenter -> AXI4UserYanker -> AXI4ToTL -> TLFIFOFixer -> TileLink`。长 AXI 写 burst 虽会拆成 64 B TileLink 请求，但 AXI W 通道仍被同一个长 burst 占用，生成路径中只能维持约 2 个 TL 写请求在途。
2. FBus 离开 SoC 后进入 DDR 的 AXI Crossbar S00 入口原来只有 `READ_ACCEPTANCE=1`、`WRITE_ACCEPTANCE=1`，会再次把已经并行化的请求压成 single-issue。

对应修改已经完成并通过受控仿真：

- Tensor writer 继续使用 2 beat x 32 B，即每笔 64 B AXI burst。
- 写 CDC 使用 14 个物理 AXI ID，ID 18..31，形成真正的多 outstanding。
- reader 使用 ID 0..17，读写 ID 完全隔离。
- DDR AXI Crossbar 的 S00 读写 acceptance 从 1 提高到 8。

在 160 个 100 MHz 周期的合成响应延迟下，生成 `AXI4ToTL` 写路径的 2-beat 写带宽由单 ID 的约 37 MB/s 提高到 14 ID 的 529 MB/s，TL 峰值在途请求由 1 提高到 14。该数字证明转换路径并发优化有效，但不是板上 DDR 实测值。

2026-09-24 又完成了生产形态并发矩阵。该测试同时运行 64 KiB reader 和 64 KiB writer，固定使用 64 B 请求，经过真实生成的 `AXI4ToTL + TLFIFOFixer`，并使用 18-cycle 合成共享响应模型：

- acceptance=1 时，三种读写 ID 分区均约为读 304 MB/s、写 304 MB/s；
- acceptance=8 时，16/16、18/14、20/12 三种无重叠分区均约为读 1275 MB/s、写 1274 MB/s；
- acceptance=8 但恢复读写共享 ID 时，读写降为约 903/902 MB/s；
- 18/14 分区仅观察到 3 个 `TLFIFOFixer` stall 周期，共享 ID 则观察到 3263 个。

所以当前生产方案的 SoC 内部结论是：每 ID 两个 source 槽并未限制多 ID 生产流量；共享 ID 会触发 `TLFIFOFixer` 排序阻塞，但 0..17/18..31 分区已经绕开该限制。没有证据支持修改通用 `ToTL.scala` 或删除 `TLFIFOFixer`。

## 2. 检查范围与配置

### 2.1 当前 Taihang SoC 配置

已安装并核对 `soc_shell/taihang16_soc_source_payload.tar.gz` 中的匹配源码。当前 Taihang 配置已经是：

```text
data_width = 256
id_bits    = 5
source_bits = 7
fifo_bits   = 5
```

匹配版本为：

```text
Chipyard   0acc1e1de2d3284bcd4d876956932a013ffe1949
Gemmini    8c3f9923a44a2fe2c7930587be297d6d4f8c09ca
Rocket-Chip 55bcad0f59436de98ea510334121de8546b9e9d7
SOURCE_CONFIG_VERIFY=PASS
```

因此本轮不需要修改 Chipyard/Taihang Scala 配置，也没有手工修改 `rtl/soc/.../gen-collateral`。生产 RTL 的 ID 分配修改位于 `sixteen_camera`，Crossbar 修改位于 Vivado Block Design 工程。

### 2.2 理论边界

若板上实际 bitstream 的物理 FBus 确实是 64-bit x 100 MHz，则单向理论 payload 上限为：

```text
64 bit / 8 x 100 MHz = 800 MB/s
```

此前约 351 MB/s 的板测结果只达到理论值的约 44%。它符合“单笔请求等待较长响应后才能发下一笔”的延迟受限特征，而不是总线每周期持续传输的带宽特征。

## 3. 根因分析

### 3.1 为什么长 burst 没有带来高吞吐

生成的 `AXI4Fragmenter` 会把较长 AXI burst 拆成 64 B TileLink 请求，但 AXI4 的 W 通道没有 WID，长 burst 的全部 W beat 必须连续属于当前 AW。下一个不同 ID 的 AW 即使可以排队，其 W 数据也不能越过当前 burst。

因此 64-beat、16-beat 或 4-beat AXI burst 都不能有效填满多个 ID 的并发窗口。使用 2-beat burst 时，一笔 AXI burst恰好等于一个 64 B TileLink/cache-line 请求，writer 才能快速切换到下一个 AXI ID。

160-cycle 响应延迟下的实际扫描结果为：

| AXI burst | 14 ID 带宽 | TL 峰值在途请求 |
| ---: | ---: | ---: |
| 64 beat / 2048 B | 40 MB/s | 2 |
| 16 beat / 512 B | 44 MB/s | 2 |
| 4 beat / 128 B | 76 MB/s | 2 |
| 2 beat / 64 B | 529 MB/s | 14 |

所以优化策略不是简单地“增大 burst”，而是将 AXI burst 对齐到内部 64 B TileLink transaction，再跨 ID 并行。

### 3.2 为什么读写 ID 必须分区

`AXI4ToTL` 产生 7-bit TileLink source，而生成的 `TLFIFOFixer_2` 使用 `source[6:2]` 作为 FIFO 排序组。这 5 bit 对应 AXI ID。source 的低位即使包含读写方向/事务槽信息，也不会建立独立的 FIFO 排序域。

因此读和写若使用相同 AXI ID，仍可能被 `TLFIFOFixer` 放入同一排序组并相互阻塞。原先“方向位能够隔离读写”的假设不成立。

当前分区为：

```text
reader: ID 0..17，共18个
writer: ID 18..31，共14个
```

### 3.3 为什么 DDR Crossbar acceptance=1 也会限速

S00 是 FBus 进入 DDR 子系统的入口。`S00_READ_ACCEPTANCE=1` 和 `S00_WRITE_ACCEPTANCE=1` 表示该入口每个方向最多只接收一笔尚未完成的事务。即使上游 reader、writer 和 TileLink 转换器已经产生多笔请求，Crossbar 也会通过 ready 反压把入口压回一笔在途。

该限制属于 SoC 外部的 Vivado AXI/DDR 接入，不属于 TileLink，也不属于 `AXI4ToTL` 本身。

### 3.4 AXI4ToTL source 槽与 TLFIFOFixer 的责任边界

当前 Taihang 配置的 `source_bits=7`、`fifo_bits=5` 使 `AXI4UserYanker` 设置：

```text
maxFlight = 1 << (source_bits - fifo_bits - 1) = 2
```

`AXI4ToTL` 为每个 AXI ID 生成独立的读写 source，编码为：

```text
read source  = {axi_id, transaction_slot, 1'b0}
write source = {axi_id, transaction_slot, 1'b1}
```

因此每个 AXI ID 最多有两个读槽和两个写槽。当前 reader 与 writer 自身每个物理 ID 最多保持一笔请求，生产并行度来自多个 AXI ID，所以两槽上限没有被打满，也不是当前吞吐瓶颈。单纯把 `source_bits` 从 7 增大并不会改善当前生产流量。

`TLFIFOFixer` 以 `source[6:2]`，即原 AXI ID，建立排序组。同一 ID 的读写即使 direction bit 不同，跨不同 FIFO 域时仍会互相等待。生产并发测试直接观测到：

| ID 方式 | Fixer stall 周期 | 读带宽 | 写带宽 |
| --- | ---: | ---: | ---: |
| 18读/14写，无重叠 | 3 | 1275 MB/s | 1274 MB/s |
| 读写共享 ID | 3263 | 903 MB/s | 902 MB/s |

这说明共享 ID 场景的内部限制来自 `TLFIFOFixer` 排序域，而不是 source 总数不足。`TLFIFOFixer` 不能直接删除，因为 `AXI4ToTL` 没有用于恢复同 ID AXI 响应顺序的完整 reorder buffer；放宽它可能产生 AXI 协议错误。当前正确方案是保持读写 ID 分区。

## 4. 生产代码修改

| 文件 | 修改目的与内容 |
| --- | --- |
| `rtl/bus/axi4_write_cdc.sv` | allocation pointer 在 `FBUS_WRITE_ID_COUNT-1` 显式回绕；取消 ID 数必须为 2 的幂的限制，使 14 个写 ID 可以正确循环使用。保留 AW 顺序分配、B 乱序接收和上游顺序退休。 |
| `rtl/memory/tensor_memory_bridge.sv` | writer 从重叠的 ID 0..31 改为独占 ID 18..31，`FBUS_WRITE_ID=18`、`FBUS_WRITE_ID_COUNT=14`。 |
| `rtl/ai/postprocess/postprocess_read_diagnostic.sv` | reader 从 ID 0..30 改为 ID 0..17，避免与 writer 的 `TLFIFOFixer` 排序组重叠。reader 数据通路和算法未修改。 |
| `prj/create_design_1.tcl` | S00 `NUM_READ_OUTSTANDING`、`NUM_WRITE_OUTSTANDING` 从 1 改为 8，确保重建 BD 时配置不丢失。 |
| `prj/.../design_1.bd` | 工程中的 S00 读写 outstanding 同步改为 8。 |
| `prj/.../design_1_xbar_0.xci` | Vivado 生成结果更新为 `S00_READ_ACCEPTANCE=8`、`S00_WRITE_ACCEPTANCE=8`。 |
| `prj/.../design_1_auto_us_0.xci` | Vivado 传播 256-to-512 bit upsizer 的 outstanding 接口元数据。 |
| `prj/.../design_1_auto_cc_0.xci` | Vivado 传播 100-to-300 MHz clock converter 的 outstanding 接口元数据。 |

Tensor DMA 的生产默认值在修改前已经是：

```systemverilog
BASE_BURST_BEATS = 2
MAX_BURST_BEATS = 2
WRITE_OUTSTANDING = 32
```

因此本轮没有再修改 Tensor DMA 的 burst scheduler，而是让后级 CDC 和 ID 规划真正承载这些并发请求。

## 5. 新增和调整的验证代码

| 文件 | 用途 |
| --- | --- |
| `sim/tb_axi4_write_cdc_nonpower.sv` | 验证 14 个非 2 次幂 ID 的循环分配、乱序 B 响应和顺序退休。 |
| `sim/tb_fbus_generated_write_path.sv` | 对真实生成 `AXI4ToTL` 依赖闭包扫描 64/16/4/2-beat burst 和不同 ID 数。 |
| `sim/tb_fbus_generated_path.sv` | 使用真实 writer CDC，并发产生 reader 0..17 与 writer 18..31 请求。 |
| `sim/tb_fbus_read_engine.sv` | 参数化读 ID 数并加强跨 ID 乱序响应检查。 |
| `sim/tb_ddr_axi_crossbar_throughput.sv` | 对真实 Xilinx AXI Crossbar RTL 做 acceptance=1/8 A/B 测试。 |
| `sim/tb_fbus_production_concurrency.sv` | 同时产生固定容量的 64 B 读写流量，经过真实生成的 AXI4ToTL/TLFIFOFixer，并检查数据、RID/BID、RLAST、RRESP/BRESP、死锁、ID 重叠和内部 fixer stall。 |
| `scripts/run_fbus_generated_write_path_test.py` | 自动提取当前 collateral 宽度并运行写路径扫描。 |
| `scripts/run_fbus_generated_path_test.py` | 自动运行当前 collateral 的读写并发路径测试。 |
| `scripts/run_tensor_write_optimization_tests.sh` | 汇总 writer CDC、14 ID、Tensor admission 和生成写路径回归。 |
| `scripts/run_ddr_axi_crossbar_throughput_test.py` | 自动运行 Crossbar A/B 测试并计算带宽。 |
| `scripts/run_fbus_production_concurrency_matrix.py` | 自动运行 16/16、18/14、20/12、共享 ID 与 acceptance=1/8 的八组生产并发矩阵。 |

## 6. 仿真条件和结果

### 6.1 Writer CDC 功能验证

```text
WRITE_ORDER_PASS AW=8 W=8 B=8 max_outstanding=8
AXI4_WRITE_CDC_NONPOWER=PASS transactions=28 max=14 mask=fffc0000
```

结果表明：14 个物理写 ID 均被使用，B 响应允许跨 ID 乱序到达，上游响应仍按原请求顺序返回。

### 6.2 真实生成 AXI4ToTL 写路径 A/B

共同条件：

- 当前工程的真实生成 collateral；
- FBus AXI 数据宽度 256 bit，ID 宽度 5 bit；
- 每组传输 256 KiB；
- 合成 TileLink responder 固定延迟 160 个 100 MHz 周期；
- 带宽按 `bytes * 100 MHz / cycles` 计算。

2-beat/64 B 写的对比结果：

| 模式 | 带宽 | TL 峰值在途请求 |
| --- | ---: | ---: |
| 单写 ID 基线 | 37 MB/s | 1 |
| 14 写 ID 优化 | 529 MB/s | 14 |

仿真提升为约 14.3 倍。单 ID 理论近似为 `64 B / 160 cycle x 100 MHz = 40 MB/s`，与仿真的 37 MB/s 一致，额外差异来自 AXI/TL 握手和边界开销。

### 6.3 读写并发生成路径

条件：64 KiB reader、160-cycle responder、64 B read burst、reader ID 0..17、writer ID 18..31、公平读写响应。

```text
FBUS_WRITES issued=802 completed=772 max=14 mask=fffc0000
FBUS_PATH burstB=64 cycles=9752 peak_TL_requests=32 MBps_at_100MHz=672
TB_FBUS_GENERATED_PATH=PASS
```

这里的 672 MB/s 是测试期间 reader 数据流的受控仿真吞吐；同时 writer 持续产生流量并填满 14 个 outstanding。它证明 ID 分区后读写可以同时前进，不代表共享真实 DDR 时读写都能各自持续达到该数字。

### 6.4 Tensor writer 回归

```text
WRITE_ORDER_PASS
AXI4_WRITE_CDC_NONPOWER=PASS
TENSOR_ADMISSION_PASS
TB_FBUS_GENERATED_WRITE_PATH=PASS
TENSOR_WRITE_OPTIMIZATION_TESTS=PASS
```

### 6.5 DDR Crossbar A/B

Crossbar 专项测试使用 512-bit、300 MHz 的真实 Xilinx Crossbar RTL、每笔 64 B、固定 51-cycle 下游响应，并以每 24 个 300 MHz 周期提供一笔请求来模拟 64-bit x 100 MHz 上游能力：

| 模式 | acceptance=1 | acceptance=8 | 提升 |
| --- | ---: | ---: | ---: |
| 只读 | 349.092 MB/s | 738.267 MB/s | 2.115x |
| 只写 | 349.094 MB/s | 710.944 MB/s | 2.037x |

详细模型、并发结果和延迟扫描见 `doc/验证记录/FBus_DDR_AXI_Crossbar_outstanding优化仿真.md`。

### 6.6 Reader 与后处理完整回归

```text
TB_AXI4_CHANNEL_JOIN=PASS
AXI4_WRITE_CDC_MULTI_OUTSTANDING=PASS
tb_axi4_write_cdc_stress PASS transactions=256
TB_FBUS_READ_ENGINE=PASS requests=539
HEAD_URAM_LOCAL_READER=PASS
AXI4_HEAD_URAM_ROUTER=PASS
TB_POSTPROCESS_READ_DIAGNOSTIC=PASS crc=101ee720
NMS corpus images=128 float_vs_pixel_mismatches=0
AI_POSTPROCESSOR_TESTS=PASS
```

这组回归确认 reader ID 数改为 18 后，读请求切分、跨 ID 乱序恢复、诊断 CRC 和 YOLOv5nu 后处理功能均未回归。

### 6.7 生产读写并发八组矩阵

共同条件：

- 真实生成的 `AXI4IdIndexer -> AXI4Fragmenter -> AXI4UserYanker -> AXI4ToTL -> TLFIFOFixer -> TLBuffer`；
- AXI/TL 数据宽度 256 bit，100 MHz 计数基准；
- 读 64 KiB、写 64 KiB，每笔均为 64 B；
- 合成 responder 固定 18-cycle 首响应延迟；
- 读写各自 acceptance=1 或 8，返回共用一个 TileLink D 通道；
- 带宽从各方向启动到该方向最后响应分别计算。

| ID 分配 | Acceptance | 读 MB/s | 写 MB/s | TL 峰值（读+写） | 结果 |
| --- | ---: | ---: | ---: | ---: | --- |
| 16读 / 16写 | 1 | 304 | 304 | 2（1+1） | PASS |
| 16读 / 16写 | 8 | 1275 | 1274 | 16（8+8） | PASS |
| 18读 / 14写 | 1 | 304 | 304 | 2（1+1） | PASS |
| 18读 / 14写 | 8 | 1275 | 1274 | 16（8+8） | PASS |
| 20读 / 12写 | 1 | 304 | 304 | 2（1+1） | PASS |
| 20读 / 12写 | 8 | 1275 | 1274 | 16（8+8） | PASS |
| 读写共享 ID | 1 | 301 | 300 | 2（1+1） | PASS |
| 读写共享 ID | 8 | 903 | 902 | 16（8+8） | PASS |

acceptance=8 的三种无重叠方案均超过验收线：写 442 MB/s、读 435 MB/s。所有组均完成 RID/BID、RLAST、RRESP/BRESP、数据内容、最终 outstanding 清零和无死锁检查。这里超过 800 MB/s 的数值并不与“旧 64-bit x 100 MHz 理论上限 800 MB/s”矛盾，因为当前生成 collateral 和该仿真模型是 256-bit 路径；这些数字用于比较转换器行为，不可作为旧 bitstream 的物理带宽。

## 7. 已解决与尚未证明的边界

已经由仿真证明：

- writer CDC 能正确使用 14 个非 2 次幂 ID；
- 2-beat/64 B burst 能绕开长 burst 在 AXI4ToTL 写路径中的串行化；
- 读写 ID 分区不会重叠，并能在生成路径中并发前进；
- Crossbar S00 acceptance=1 是独立限速点，改为 8 后局部吞吐显著提高；
- 完整 16/16、18/14、20/12、共享 ID x acceptance=1/8 矩阵无死锁且协议检查通过；
- 多 ID 分区时 `AXI4ToTL` 的每 ID 两 source 槽不是生产瓶颈；
- 共享 ID 的额外损失来自 `TLFIFOFixer` 同 ID 排序域，18/14 分区已将该 stall 从 3263 周期降到 3 周期；
- 相关 writer、reader 和后处理功能回归通过。

本轮没有修改 Chipyard 的 `ToTL.scala`、`FIFOFixer.scala` 或 Taihang FBus 节点配置，也没有重新生成 collateral。原因不是遗漏，而是 A/B 结果表明当前 SoC 内部机制在读写 ID 正确分区后已经超过吞吐门槛。若强行删除 fixer，必须先新增按 AXI ID 恢复响应顺序的 reorder 机制，否则会违反 AXI 同 ID 有序要求。

尚未由仿真替代证明：

- 新配置在 FPGA 板上的实际 DDR 可持续带宽；
- MIG refresh、bank conflict、S01/S02 竞争、完整 clock-converter FIFO 和布局布线时序造成的损耗；
- 当前板上 bitstream 是否已经包含本报告全部修改。

因此准确表述是“RTL/生成路径/Crossbar 仿真问题已解决”，不能表述为“板级低带宽已经解决”。板级闭环必须生成并下载包含下列四项的新 bitstream：

1. 当前 Taihang 256-bit collateral；
2. reader 0..17、writer 18..31 的 ID 分区；
3. Tensor 2-beat/64 B burst 和 14-ID writer CDC；
4. DDR Crossbar S00 read/write acceptance=8。

## 8. 复现命令

本机系统默认 Verilator 4.038 不支持 `--binary`。需要将 Chipyard 环境中的 Verilator 5.x 放在 PATH 前面：

```bash
export PATH=/media/tsmc/6a3f28f3-1a75-4d55-baf2-a6aa8be84a59/tny_data/chipyard/.conda-env/bin:$PATH

python3 scripts/run_fbus_generated_write_path_test.py \
  --latency 160 --ids 1 --bytes 262144

python3 scripts/run_fbus_generated_write_path_test.py \
  --latency 160 --ids 14 --bytes 262144

python3 scripts/run_fbus_generated_path_test.py \
  --latency 160 --bytes 65536 --write-traffic --fair-memory --short-only

python3 scripts/run_fbus_production_concurrency_matrix.py

bash scripts/run_tensor_write_optimization_tests.sh
```

Crossbar 专项测试需要 Vivado 2023.2：

```bash
python3 scripts/run_ddr_axi_crossbar_throughput_test.py \
  --transactions 4096 --latency 51 --source-period 24
```
