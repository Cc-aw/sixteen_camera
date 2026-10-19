# 512 KiB / 2 bank DMA 基线的 ASRAM 布局调整

参考实际已布线的 DMA 优化版本 `2a95a4ca64390235`：
`build/experiments/dma_load/512kib_2bank_runtime_20261016/bitstream/`。
不使用 1 MiB / 4 bank 版本。原始 routed checkpoint、时序和资源报告保持不变。
读取及复核输出在 `build/experiments/activation_sram/512kib_2bank/physical_plan/`。

原版最终 WNS −1.467 ns，WHS +0.001 ns，WPWS +0.039 ns。
100 MHz 主时钟最坏路径在 L2 bank0，29 级逻辑，数据延迟 11.338 ns，
其中布线 8.504 ns。起止数据寄存器位于 SLR0，不能把报告中时钟路径的
SLR crossing 当成数据跨 SLR。
DDR 300.12 MHz 写握手最坏 slack −0.837 ns：M00 slice 的源寄存器在
`SLICE_X67Y181`（X2Y3），MIG AXI write packer 的目标在
`SLICE_X120Y134`（X4Y2），均属 SLR0。
150 MHz 视频域最坏 slack −0.033 ns；复位/使能决定逻辑存在 SLR1→2→1 绕行。
这些数字来自最终布线，不能用 ASRAM 单 bank OOC 的正 slack 代替。

原版 placed 报告显示 SLR0/1/2/3 的 CLB 占用为
87.33% / 99.00% / 72.96% / 65.19%，URAM 为 124 / 188 / 0 / 60。
因此增加 ASRAM 前先释放 SLR0/1 的 Head URAM，并引导 L2 bank0 离开 DDR 侧。

| 对象 | 新约束 | 目的 |
| --- | --- | --- |
| 三路 Gemmini mesh DSP | 保留 768 块/路，硬约束 SLR0/1/3 | 延续 DMA 基线的计算阵列位置 |
| ASRAM 72 URAM/路 | 硬约束 SLR0/1/3；控制器同区软约束 | 本路 DMA 与实际存储靠近，216 块原语必须存在 |
| Head 192 URAM | 硬约束 SLR2；router 逻辑软约束 SLR2 | 使用基线未占用的 SLR2 URAM，降低与 ASRAM 的竞争 |
| 两个 L2 bank | SLR2 软约束 | 释放 DDR 侧 SLR0，并允许 placer 根据拥塞和时序调整 |
| DDR crossbar | SLR0 软约束 | 保留 DDR 侧局部性 |
| 最终 M00 register slice | X4Y2:X5Y2 软约束 | 靠近实际 MIG AXI 写 packer，缩短高扇出 valid/CE 路径 |
| 八路 camera stream | CH1–4 SLR2、CH5–8 SLR1 软约束 | 与已有 recovery/event producer 靠近，减少视频使能路径绕行 |

URAM 目标预算为 SLR0/1/2/3 = **132 / 132 / 192 / 132**，合计 588，
每区容量 320。此数为基线 372 + 新增 216，属于布局目标，实际位置以新整机
布线报告为准。未将整个 RocketTile/Gemmini/DDR PHY 锁入硬 pblock，未限制布线。
没有降低 100/150/300 MHz 时钟，也没有增加 false path、multicycle 或放宽延迟。
L2 的 29 级组合逻辑仍需在整机新报告中复核，布局调整本身不能证明时序收敛。

`run_settings.tcl` 是本版实际的综合/实现设置。
`placement.tcl` 接入 `STEPS.PLACE_DESIGN.TCL.PRE`，先保留基线 mesh 约束，
再替换 L2/Head/DDR/video 引导并约束 ASRAM。
`base/` 保存所复用基线 Tcl 的实际副本；CDC 两个 hook 沿用公共约束并记录构建散列。
最终 post-route 报告及必要的第二次物理优化沿用基线策略。
**不设置写 bitstream 前的时序阻断**；负 slack 照实保留，便于上板验证。

检查入口：

每个 Vivado 进程使用独立工作目录，避免并行进程的 `.Xil` 临时文件重名。

```sh
python3 -B hw/versions/activation_sram_512kib_2bank/tests/test_physical_provenance.py
vivado -mode batch -source hw/versions/activation_sram_512kib_2bank/constraints/validate_baseline.tcl \
  -tclargs <DMA_baseline_routed.dcp> <新的报告目录>
vivado -mode batch -source hw/versions/activation_sram_512kib_2bank/constraints/validate_activation.tcl \
  -tclargs <新的报告目录>
```

基线 replay 只检查真实层级选择及 pblock 应用，不重新 place/route 或保存 checkpoint。
ASRAM fixture 使用 216 块实际 URAM 原语，只验证三路约束选择及缺 bank/缺原语拒绝；
不冒充三路 TL/SoC 功能或全芯片时序验收。整机 bitstream 通过本版
`scripts/launch_bitstream.py` 启动，`state.json` 单列综合结果和后续实现状态。

本次启动前验证：真实 DMA routed checkpoint 的层级/pblock replay 通过；
`physical_plan/activation_replay_04/activation_replay.txt` 验证三路实际 216 块
URAM，最终 `IS_SOFT=0`，目标依次 SLR0/1/3，缺 bank 和缺原语均正确拒绝。
设置 `IS_SOFT` 必须在 `add_cells_to_pblock` 后，防止 Vivado 加入成员时恢复默认软属性。
来源兼容性四项测试、私有 RTL 审计及生产 manifest 检查通过。
