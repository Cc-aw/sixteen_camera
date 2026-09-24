# FBus DDR AXI Crossbar outstanding 优化与仿真记录

日期：2026-09-24

## 1. 目的

检查并解除 FBus 数据进入 DDR 前的 AXI Crossbar 单笔接收限制。修改前，
`S00_AXI` 的读写 outstanding 均为 1；即使上游 FBus reader、writer 和
AXI4ToTL 能并行发出多笔请求，Crossbar 仍会把该入口压回到 single-issue。

本次只修改 DDR Block Design 中 S00/FBus 入口的接收深度，不修改 TileLink、
AXI4ToTL、FBus reader 或 Tensor writer 的功能 RTL。

## 2. 修改内容

| 文件 | 修改 |
| --- | --- |
| `prj/create_design_1.tcl` | S00 `NUM_READ_OUTSTANDING` 和 `NUM_WRITE_OUTSTANDING` 从 1 改为 8，保证重建 Block Design 时配置不丢失。 |
| `prj/sixteen_camera.srcs/sources_1/bd/design_1/design_1.bd` | Vivado Block Design 的 S00 读写 outstanding 从 1 改为 8。 |
| `design_1_xbar_0.xci` | Vivado 自动传播为 `S00_READ_ACCEPTANCE=8`、`S00_WRITE_ACCEPTANCE=8`；M00 read/write issuing 保持 8。 |
| `design_1_auto_us_0.xci` | Vivado 自动把 S00 路径 256-to-512 bit upsizer 的接口 outstanding 元数据传播为 8。 |
| `design_1_auto_cc_0.xci` | Vivado 自动把 S00 路径 100-to-300 MHz clock converter 的接口 outstanding 元数据传播为 8。 |
| `prj/update_s00_outstanding.tcl` | 新增幂等更新脚本：打开工程、修改参数、校验 BD、重新生成 target，并核对结果。 |
| `sim/tb_ddr_axi_crossbar_throughput.sv` | 新增真实 Xilinx AXI Crossbar RTL 的 acceptance=1/8 A/B 测试台。 |
| `scripts/run_ddr_axi_crossbar_throughput_test.py` | 新增 Vivado RTL 编译、六组读写测试和带宽汇总脚本。 |

这些 `.xci` 和生成 RTL 的变化由 Vivado 2023.2 重新生成，不是手工改写生成产物。

生成 RTL 已核对为：

```verilog
.C_S_AXI_WRITE_ACCEPTANCE(96'H000000010000000800000008),
.C_S_AXI_READ_ACCEPTANCE (96'H000000080000000100000008),
.C_M_AXI_WRITE_ISSUING   (32'H00000008),
.C_M_AXI_READ_ISSUING    (32'H00000008),
```

## 3. Crossbar A/B 仿真条件

- 被测对象：Vivado 2023.2 的真实 `axi_crossbar_v2_1_30_axi_crossbar` RTL。
- 拓扑：3 个 slave、1 个 master，与工程 DDR Crossbar 一致。
- Crossbar 数据宽度/时钟：512 bit、300 MHz。
- 请求大小：每笔 64 B。
- M00 read/write issuing：8。
- A/B变量：S00 read/write acceptance 为 1 或 8。
- 每组事务数：4096。
- 下游固定响应延迟：51 个 300 MHz 周期。
- 51周期模型使旧配置得到约349 MB/s，与历史板测约351 MB/s相差约0.5%。
- 带宽按十进制 MB/s 计算。

测试台提供两种上游供给速率：

- `source_period=24`：每24个300 MHz周期提供64 B，等效64-bit x 100 MHz。
- `source_period=6`：每6个300 MHz周期提供64 B，等效256-bit x 100 MHz。

## 4. 主要结果

### 4.1 等效旧64-bit x 100 MHz路径

| 模式 | acceptance=1 | acceptance=8 | 提升 |
| --- | ---: | ---: | ---: |
| 只读 | 349.092 MB/s | 738.267 MB/s | 2.115x |
| 只写 | 349.094 MB/s | 710.944 MB/s | 2.037x |
| 读写并发总和 | 698.185 MB/s | 1421.875 MB/s | 2.037x |

单向读写结果已接近64-bit x 100 MHz的800 MB/s理论 payload 上限。该供给速率下，
实际观测到的在途峰值从1提高到2；因为上游每24周期才提供一笔请求，不需要占满8个槽
即可覆盖51周期响应延迟。

### 4.2 等效当前256-bit x 100 MHz接口供给能力

| 模式 | acceptance=1 | acceptance=8 | 提升 |
| --- | ---: | ---: | ---: |
| 只读 | 349.092 MB/s | 2396.636 MB/s | 6.865x |
| 只写 | 349.094 MB/s | 2130.790 MB/s | 6.104x |
| 读写并发总和 | 698.185 MB/s | 4261.465 MB/s | 6.104x |

这组数据表示 Crossbar 局部能力，不表示真实 DDR 或旧64-bit FBus 能达到2 GB/s以上。

### 4.3 延迟敏感性

独立样本结果（42和54周期为1024笔，48周期为4096笔）：

| 固定响应延迟 | 旧读 | 新读 | 旧写 | 新写 |
| ---: | ---: | ---: | ---: | ---: |
| 42周期 | 417.400 | 2389.209 | 417.409 | 2125.262 |
| 48周期 | 约369.23 | 约2396.86 | 约369.23 | 约2130.96 |
| 54周期 | 331.040 | 2385.730 | 331.046 | 2122.509 |

单位均为 MB/s。结果说明 single-issue 配置会让带宽随响应延迟直接下降；8笔接收可用
多笔在途请求覆盖延迟，因此在42至54周期范围内保持约2.1至2.4 GB/s的Crossbar局部吞吐。

## 5. 回归结果

- 生成FBus读路径：`PASS`，64 B burst，`peak_TL_requests=30`，799 MB/s @ 100 MHz。
- 写CDC顺序测试：`PASS`，AW/W/B各8笔，`max_outstanding=8`，乱序B在上游恢复顺序。
- Tensor admission测试：`PASS`。
- 生成AXI4ToTL写路径：`PASS`，32个写ID；2-beat burst为1206 MB/s，峰值32笔TL请求。
- Tensor writer组合回归：`TENSOR_WRITE_OPTIMIZATION_TESTS=PASS`。
- `git diff --check`：通过。

生成AXI4ToTL写路径的现有扫描还显示：64/16/4-beat burst分别仅约40/44/76 MB/s，
而2-beat burst约1206 MB/s。这说明长AXI burst在当前AXI4ToTL转换路径中仍有独立的
串行化或阻塞行为。Crossbar acceptance=8解除了DDR入口的single-issue限制，但不能单独
修复AXI4ToTL长burst机制；生产写策略仍应使用已经验证的短burst加多ID/多outstanding。

## 6. 结论和边界

本次仿真已证明：DDR AXI Crossbar 的 `S00_READ_ACCEPTANCE=1` 和
`S00_WRITE_ACCEPTANCE=1` 是明确的内部限速点。改为8后，在等效旧64-bit x 100 MHz条件下，
固定延迟模型中的单向带宽从约349 MB/s提高到读738 MB/s、写711 MB/s。

这不是新bitstream板测数据。测试没有完整建模MIG刷新、DDR bank冲突、其他master竞争、
时钟转换FIFO和板级时序。要确认真实结果，仍需完成综合、实现、生成新bitstream，并在
同一地址、长度、cache维护方式和系统负载下重新板测。读写并发总和使用独立响应模型，
不能视为共享DDR的可持续总带宽。

## 7. 复现命令

```bash
python3 scripts/run_ddr_axi_crossbar_throughput_test.py \
  --transactions 4096 --latency 51 --source-period 24

python3 scripts/run_ddr_axi_crossbar_throughput_test.py \
  --transactions 4096 --latency 51 --source-period 6
```

现有FBus回归需要Verilator 5.x。本机可使用
`tny_data/chipyard/.conda-env/bin/verilator`。
