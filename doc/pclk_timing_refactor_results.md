# PCLK/视频时序重构阶段结果

实施状态：P0、P1 完成；P2 已完成 RTL、功能回归和综合，布局布线/bitstream/routed 时序对比按用户要求留待后续执行；P3～P6 未开始。

## Timing 对比

| 指标 | 原报告/历史 DCP | 本轮核验基线 | P1 | P2 | P3 | P4 | P5/P6 |
|---|---:|---:|---:|---:|---:|---:|---:|
| WNS / ns | -1.291 | -1.291 | -0.698 | 未执行 | 未执行 | 未执行 | 未执行 |
| TNS / ns | -6258.903 | -6258.903 | -2949.667 | 未执行 | 未执行 | 未执行 | 未执行 |
| setup 失败端点 | 20,800 | 20,800 | 11,779 | 未执行 | 未执行 | 未执行 | 未执行 |
| WHS / ns | +0.003 | +0.003 | +0.010 | 未执行 | 未执行 | 未执行 | 未执行 |
| WPWS / ns | +0.039 | +0.039 | +0.039 | 未执行 | 未执行 | 未执行 | 未执行 |
| PCLK 相关 LUTAR-1 | 8 | 8（总计 30） | 0（总计 22） | 未执行 | 未执行 | 未执行 | 未执行 |
| reader 失败端点 | 6,668 | 6,668 | 5,808 | 未执行 | 未执行 | 未执行 | 未执行 |
| camera FIFO 失败端点 | 1,153 | 1,153 | 420 | 未执行 | 未执行 | 未执行 | 未执行 |

## 功能、资源和性能

| 指标 | P0 | P1 | P2 | P3 | P4 | P5/P6 |
|---|---|---|---|---|---|---|
| 既有自检查回归 | 通过 | 通过 | 通过（含 P2 随机背压用例） | 未执行 | 未执行 | 未执行 |
| LUT/FF/BRAM/URAM/DSP | 122,305 / 223,485 / 424.5 / 0 / 18 | 121,740 / 223,525 / 424.5 / 0 / 18 | 综合估算 84,740 / 169,406 / 374 / 0 / 15；实现未执行，不与前两列实现值直接对比 | 未执行 | 未执行 | 未执行 |
| 300 MHz 自定义逻辑 | 已纳入层次/SLR 报告；独立精确计数待 P3 对比 | 仍是主要失败域；待 P3 迁移 | camera FIFO 已为同钟同步结构；routed 分布未执行 | 未执行 | 未执行 | 未执行 |
| 最大 FIFO 占用/服务空窗 | 未测 | 未执行 | 小深度测试 FIFO 达 8/8；全深度服务空窗未测 | 未执行 | 未执行 | 未执行 |
| 输入/写入/显示有效帧率 | 未测 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 丢帧/错误帧发布数量 | 未测 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 板测 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |

## 报告位置

- 历史对照：`reports/video_timing_refactor/P0/reported_baseline/`。
- 工程清单：`reports/video_timing_refactor/P0/project_inventory/`。
- 当前 clean rebuild：`reports/video_timing_refactor/P0/current_worktree_baseline/`；DCP SHA-256 `0f2eff178e50a04467e7348b51116d5084c65a87ef7331065981addc526f7b15`。
- P1：`reports/video_timing_refactor/P1/reset_enable_constraints/`；DCP SHA-256 `513acc22eac1bb124bf001fd34b5338840fe6839ea401b0c9ac53e2cea57c2c1`，bitstream SHA-256 `a54a55f351c3469939f3c1ff080dfd06afca9fc1febab7c0eb4bbabcc6486bd8`。
- P2 综合 DCP：`prj/sixteen_camera.runs/synth_1/top_wrapper.dcp`，生成于 2026-09-06 14:19:31 +0800，SHA-256 `024c3bc8ac2881a554e9c13073283f6c3dea8e5360aa3193d4cadb5ad6e2c5c4`。P2 routed DCP、时序报告和 bitstream 未生成。

## P1 结论

- 运行时 `capture_enable` 已与域级 reset 分离；八路 `camera_axis_cdc` 不再由 LUT 组合逻辑驱动异步 CLR。disable 会同步清除半像素状态，并用本地寄存、延长的 FIFO reset 冲洗旧 beat。
- IOB→sync 的旧 endpoint false path 已删除。1.5 ns datapath-only 规则改用 88 个合法寄存器 cell 起止点，覆盖 88 个实际 endpoint；43 条未满足、45 条满足，最差为 -0.696 ns。没有新增或扩大 false path。
- Vivado 2023.2 会为 `set_max_delay -datapath_only` 自动建立同路径的内部 hold false path；专用 min 报告因此显示 `Slack: inf / Timing Exception: False Path`。这是本阶段实际核验结果，不把它写成 min 已通过；全设计普通 hold 分析为 WHS +0.010 ns、THS 0。
- `TIMING-13` 路径分段和 `TIMING-28` 自动时钟名告警均已消除。`TIMING-10` 仍为 1 项，来源是生成的 Rocket SoC synchronizer，而不是本阶段新增摄像头 crossing；本阶段不修改生成 SoC RTL。
- routed 时序仍未收敛。与 P0 相比，WNS 改善 0.593 ns、TNS 改善 3309.236 ns、失败端点减少 9,021；真正的 300 MHz 结构性问题留给 P2～P5。

## P2 结论（截至综合）

- `camera_axis_cdc` 已按当前真实的 `camera_clk == ddr_clk == MIG UI clock` 结构，从 `xpm_fifo_async` 改为 `xpm_fifo_sync`，FIFO 深度和 50-bit beat 格式不变。综合网表中八路均出现 `xpm_fifo_sync`，每路存储器被识别为 `16K x 50` BRAM。
- FIFO 后增加两个本地寄存预取槽。BRAM `rd_en` 只取决于 FIFO empty/reset-busy 和本地 skid 占用，不再组合依赖远端 `m_axis.tready`；AXIS 输出在停顿期间保持稳定，并维持连续排空时每周期一个 beat。
- 顶层 clean synthesis 实际通过：`SYNTHESIS_BUILD=PASS`，100%，0 error、0 critical warning。删除了 Vivado 2023.2 不支持且数值为 0 的 `set_min_delay -datapath_only`，没有新增或扩大 false path。
- 按用户要求未执行 P2 placement、route、bitstream、routed setup/hold/pulse/CDC 对比和板测，因此 P2 尚未完成 routed 时序签核。

## 回滚索引

每个 P 阶段使用独立 Git commit。P0 回滚点为 `ffe513c`；P1 回滚点见本阶段提交。不会提交 routed DCP、bitstream 或 Vivado 临时目录，大文件由 report manifest 的绝对路径、mtime 和 SHA-256 关联。
