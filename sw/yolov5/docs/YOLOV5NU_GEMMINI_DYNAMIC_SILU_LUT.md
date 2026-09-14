# YOLOv5nu Gemmini 动态 SiLU LUT

## 1. 目标

以 Stage 5D 为部署基线，将 69 个 fused INT8 SiLU 从 Rocket 标量循环迁移到
Gemmini accumulator scale/mvout 路径。第一版必须保持当前两阶段 QDQ 语义：

```text
Conv acc32
  -> 当前 Gemmini output scale、RNE 和 int8 saturation
  -> q_conv
  -> 当前层的 256-entry int8 SiLU LUT[q_conv]
  -> DMA mvout
```

验收要求不是近似 SiLU，而是对生成器现有 69 张 LUT 的全部
`69 * 256 = 17,664` 个输入 bit-exact。

## 2. 第一版范围

第一版包含：

1. 新 activation 编码 `SILU_LUT=6`，沿用现有 3-bit activation ABI。
2. Gemmini 内部一张可运行时更新的 256×8-bit active LUT。
3. 新 RoCC funct `CONFIG_SILU_LUT=26`，每条命令写 8 个连续表项。
4. 软件每层用 32 条命令加载完整 256-byte LUT。
5. LUT 查询接在 accumulator scale、RNE、clip-to-int8 之后。
6. `tiled_conv_auto(..., SILU_LUT, ...)` 通过 LoopConv 将 activation 传到 mvout。
7. 单算子 store-path smoke 和真实 `tiled_conv_auto -> loop_conv_ws` smoke。
8. YOLOv5nu 独立 hardware-LUT candidate；Stage 5D baseline 不覆盖。

第一版暂不包含：

- shadow/active 双缓冲；
- LUT 配置与前一层 Conv 重叠；
- Gemmini Conv 直接写入 Stage 5D Concat slice；
- execute-to-scratchpad 路径的 SiLU；
- 统一定点数学 SiLU。

## 3. 软件 ABI

```text
funct = 26
rs1[7:0] = base LUT index，必须为 8 的倍数，范围 0..248
rs2[63:0] = 8 个 int8 表项，little-endian 打包
```

软件接口：

```c
gemmini_config_silu_lut(const elem_t lut[256]);
```

第一版每层执行：

```c
gemmini_config_silu_lut(layer_lut); // 32 RoCC commands
gemmini_fence();                    // LUT 更新完成后才启动 Conv
tiled_conv_auto(..., SILU_LUT, ...);
gemmini_fence();
```

单 active LUT 在配置过程中会被逐块更新，因此没有前一个 Conv 与配置并行的语义。
`gemmini_fence()` 是第一版 ABI 合约的一部分。后续若增加双缓冲，必须另设 commit
语义并重新验证命令顺序。

## 4. RTL 数据路径

LUT storage 位于 Gemmini Scratchpad/AccumulatorScale 所在时钟域。配置命令走
store reservation queue，由 StoreController 产生 LUT write port。这样配置写与
CONFIG_ST/mvout 使用同一顺序域。

AccumulatorScale 中的顺序必须是：

```text
e_scaled
  -> clippedToWidthOf(int8)
  -> if act == LEAKY_RELU: fixed LeakyReLU
  -> if act == SILU_LUT: dynamic_lut[q.asUInt]
```

不能在 `e_scaled` 或 acc32 上查表，否则不再匹配当前 CPU LUT 的输入定义。

第一版用 256 个 8-bit寄存器和组合动态索引。它便于功能验证，但综合后可能形成
复制 mux 网络。完成 Verilator 后必须查看 Vivado LUT/FF、时序和 accumulator-scale
吞吐，再决定使用 LUTRAM replication、banking 或增加流水级。

## 5. 软件 lowering

当前 Stage 5D：

```text
tiled_conv_auto(..., NO_ACTIVATION, ...)
gemmini_fence()
silu_lut_i8(...)
```

hardware-LUT candidate：

```text
gemmini_config_silu_lut(yolov5nu_silu_lutN)
gemmini_fence()
tiled_conv_auto(..., SILU_LUT, ...)
gemmini_fence()
```

CPU `SILU_FUSED_LUT` 调用消失。当前软件 candidate 对8个满足单消费者、量化 scale
一致条件的 SiLU Conv 使用 `tiled_conv_stride_auto()`，直接写入 Concat slice；该路径
使用现有 V1 activation和RoCC ABI，不修改 RTL。

## 6. 验证顺序

1. Scala/Chisel elaboration 和 RTL生成。
2. 软件 LUT pack/unpack 检查全部 256 项。
3. Store-path smoke：单位矩阵将 `-128..127` 写入 accumulator，动态 LUT 使用一个
   非线性测试排列，输出逐项比较。
4. LoopConv smoke：1×1 identity Conv，确认 activation 字段 `6` 未被截断。
5. 使用 YOLOv5nu 69 张真实 LUT，逐表运行全部 256 个输入。
6. Spike 验证软件命令编码和 ELF；Spike 不验证自定义 Gemmini RTL 结果。
7. Verilator 验证真实动态 LUT RTL。
8. 全部通过后生成五图 ELF，最终上板验证 tensors、Top-10、NMS 和 cycles。

## 7. 性能预期和风险

Stage 5D 五图平均 SiLU 为 36.638M cycles，占 graph 约 60.6%。动态 LUT 理论上可
删除 CPU 对 3,561,600 个元素的完整扫描，但实际收益受以下因素限制：

- LUT 查询是否降低 accumulator scale/mvout 吞吐；
- 69 层共 2,208 条配置命令和 69 次配置 fence；
- 单 active LUT 的配置不能与 Conv 重叠；
- 8条 SiLU Conv direct-Concat 已通过两次板级 bit-exact 与性能验证；
- 组合 256:1 lookup 对 FPGA 时序和资源的影响。

第一版的优先级是 bit-exact、命令有序和 profile 可解释，不以最终性能为合入条件。

## 8. 第一版实现状态（2026-08-24）

RTL、软件 ABI、三个 smoke 和 image025模型 candidate 已实现。当前结果：

- activation 6 和 funct 26 通过 Chisel elaboration、firtool和 Verilator生成；
- Verilator store/mvout smoke：256/256 PASS；
- Verilator LoopConv smoke：256/256 PASS；
- Verilator 69张真实 YOLOv5nu LUT：17,664/17,664 PASS；
- 原 LeakyReLU store与LoopConv smoke回归 PASS；
- Spike Gemmini extension已同步到 DIM32、3-bit activation和动态 LUT；
- 完整 image025 Spike final tensors、Top-10、NMS与 Stage 5D bit-exact；
- 生成源码包含69次 LUT配置、69个 hardware-SiLU Conv、0个 CPU SiLU调用；
- 当前软件 candidate 恢复8条 SiLU Conv direct-Concat，加上1条 Add路径共9条；
- arena为846,400 bytes，两次板级输出 bit-exact；Concat均值减少239,352 cycles，
  graph均值减少132,784 cycles。

详细产物和复现命令见
`fpga/xcvu13p/tests/yolov5nu_gemmini_silu_lut/README.md`。

## 9. 独立 SoC 配置

为新 Vivado 工程建立独立 FPGA 配置：

```text
LargeGemminiRocketDspRVVSiluLUTXCVU13PConfig
```

它保留32×32 Large Gemmini、512 KiB scratchpad、128 KiB accumulator、256-bit
DMA/system bus和50 MHz目标，同时将原基线 Saturn
`VectorParams(), VLEN=128, DLEN=64` 替换为已验证配置：

```scala
new saturn.rocket.WithRocketVectorUnit(
  vLen = 256,
  dLen = 128,
  params = VectorParams.dspParams,
  useL1DCache = true)
```

对应 Verilator 配置为 `LargeGemminiRocketDspRVVSiluLUTConfig`。原
`LargeGemminiRocketRVVXCVU13PConfig` 不修改，继续对应旧比特流和历史结果。

两项精确组合 Verilator smoke 已通过：动态 LUT store-path覆盖256项；RVV smoke
报告 `vl=32`，确认 `e8,m1` 下 VLEN=256生效。新 FPGA配置也已完成 elaboration、
firtool和 XCVU13P文件列表生成，设备树包含 `zvl256b`。

## 10. Vivado工程集成和物理实现结果（2026-08-25）

新生成 RTL 已替换到：

```text
dspsiluconfig/dspsiluconfig.xpr
```

完整性检查以生成目录中的 `.top.f` 为准：612个 file-list条目加8个额外
harness/memory/blackbox文件，共620个新 SoC源。工程中旧
`LargeGemminiRocketRVVXCVU13PConfig` 引用为0，新
`LargeGemminiRocketDspRVVSiluLUTXCVU13PConfig` 引用为620。板级 wrapper、XDC、
DDR4、ILA和两个 AXI converter IP均保留。

Save As工程继承的旧 incremental checkpoint 已清除。全量综合通过，0 error、
0 critical warning。routed资源利用率约为：

| 资源 | 使用 | 比例 |
|---|---:|---:|
| CLB LUT | 约760k | 约44.0% |
| CLB register | 约240k | 约7.0% |
| BRAM tile | 307 | 11.42% |
| URAM | 16 | 1.25% |
| DSP | 394 | 3.21% |

默认 implementation可完全路由，但 `soc_clk_50m` 为 `WNS=-6.112 ns`。最差路径
96%以上为跨 SLR routing delay，因此增加独立 run：

```text
impl_congestion: Congestion_SpreadLogic_high
```

该 run 将同步域改善到 `WNS=-0.699 ns`。追加
`phys_opt_design (Post-Route) -directive AggressiveExplore` 后，最终结果为：

```text
soc_clk_50m: WNS=-0.361 ns, TNS=-42.166 ns, 186 failing endpoints
mmcm_clkout0: WNS=+0.057 ns
hold: WHS=+0.002 ns, THS=0
routing errors: 0
```

整体 WNS `-2.064 ns` 来自3个历史 `async_default` reset端点；即使将这些路径单独
处理，50 MHz SoC同步域仍未闭合。当前结论是 RTL结构完整、综合/布局/路由可行，
但不能宣称为 timing-closed bitstream。本轮按功能验证需求继续执行了 bitgen，
生成的 bitstream只用于上板功能和性能 bring-up。

已生成：

```text
dspsiluconfig/dspsiluconfig.runs/impl_congestion/xcvu13p_large_board_top.bit
113,318,504 bytes
sha256=e36cda054c00fb3161a465ec75b6af87289df0cfe9d90e3d556c40e1188d86d0
```

Vivado结果为 `Bitgen Completed Successfully`、`0 Errors`。DRC warning和
`soc_clk_50m` setup timing violation仍存在，本 bitstream不应作为正式时序闭合版本
发布。上板先执行Stage 5D baseline，再执行动态LUT smoke和完整YOLOv5nu动态LUT ELF，
用于分别隔离Saturn配置升级影响与动态LUT RTL/软件 ABI影响。

剩余关键路径集中在 `gemmini/spad/acc_scale_unit` 内的浮点 scale、round和clip组合
逻辑，不是动态256-entry LUT容量本身，也不是器件总资源不足。下一轮应优先研究
`AccumulatorScale` 流水级；若暂不改 RTL，则必须实际降低 SoC时钟，不能仅修改
时序约束。

工程自动化脚本和报告：

```text
scripts/xcvu13p_vivado_replace_soc_and_build.tcl
scripts/xcvu13p_vivado_impl_strategy.tcl
scripts/xcvu13p_vivado_postroute_physopt.tcl
scripts/xcvu13p_vivado_write_bitstream.tcl
dspsiluconfig/reports_dsp_silu/
```

## 11. V1板级功能验收结论（2026-08-25）

动态 LUT V1已完成端到端板级验收：

- store/mvout 256项 smoke重复两次，全部PASS；
- LoopConv 256项 smoke重复两次，全部PASS；
- 69张真实 YOLOv5nu LUT、17,664个输入穷举重复两次，全部PASS；
- image025完整模型重复两次，tensor checksum、Top-10和NMS与Stage 5D bit-exact；
- 全部测试以 `baremetal exit 0`结束，无trap、FAIL或mismatch。

真实表穷举输出：

```text
Gemmini YOLOv5nu dynamic SiLU LUT exhaustive smoke test
Activation SILU_LUT=6 tables=69 cases=17664
PASS: 17664/17664 real LUT cases
[baremetal exit 0x0000000000000000]
```

原始记录：

```text
fpga/xcvu13p/tests/yolov5nu_gemmini_silu_lut/exhaustive_69_luts_uart.txt
```

因此V1可以冻结为功能基线。V1定义仍是单 active 256-entry LUT、每条命令8项、每层
32条配置命令、配置和Conv串行并由 fence保证顺序。以下内容明确归入V2候选，不作为
V1遗留功能缺陷：

1. shadow/active双缓冲和原子commit；
2. 下一层LUT配置与当前Conv重叠；
3. 在保持69表全输入bit-exact前提下优化LUT存储、banking或配置带宽。
