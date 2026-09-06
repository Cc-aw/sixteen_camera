# PCLK/视频时序重构阶段结果

实施状态：P0、P1 完成；P2 已完成 RTL、功能回归、用户侧 bitstream 和基础点亮，但 routed setup 仍未收敛；P3 已完成 RTL、功能回归、综合、用户侧 bitstream 和基础点亮；P4 已完成 RTL、功能回归、综合及综合级 CDC/时钟/资源核验，布局布线、bitstream 和板测未执行；P5～P6 未开始。

## Timing 对比

| 指标 | 原报告/历史 DCP | 本轮核验基线 | P1 | P2 | P3 | P4 | P5/P6 |
|---|---:|---:|---:|---:|---:|---:|---:|
| WNS / ns | -1.291 | -1.291 | -0.698 | -0.693 | 未执行 | 未执行 | 未执行 |
| TNS / ns | -6258.903 | -6258.903 | -2949.667 | -1185.536 | 未执行 | 未执行 | 未执行 |
| setup 失败端点 | 20,800 | 20,800 | 11,779 | 8,181 | 未执行 | 未执行 | 未执行 |
| WHS / ns | +0.003 | +0.003 | +0.010 | +0.003 | 未执行 | 未执行 | 未执行 |
| WPWS / ns | +0.039 | +0.039 | +0.039 | +0.039 | 未执行 | 未执行 | 未执行 |
| PCLK 相关 LUTAR-1 | 8 | 8（总计 30） | 0（总计 22） | 未执行 | 未执行 | 未执行 | 未执行 |
| reader 失败端点 | 6,668 | 6,668 | 5,808 | 未执行 | 未执行 | 未执行 | 未执行 |
| camera FIFO 失败端点 | 1,153 | 1,153 | 420 | 未执行 | 未执行 | 未执行 | 未执行 |

## 功能、资源和性能

| 指标 | P0 | P1 | P2 | P3 | P4 | P5/P6 |
|---|---|---|---|---|---|---|
| 既有自检查回归 | 通过 | 通过 | 通过（含 P2 随机背压用例） | 通过（含事件桥/assembler 和临时 writer CDC） | 通过（含混合 AXI CDC 随机压力、延迟 B/帧发布测试） | 未执行 |
| LUT/FF/BRAM/URAM/DSP | 122,305 / 223,485 / 424.5 / 0 / 18 | 121,740 / 223,525 / 424.5 / 0 / 18 | 综合估算 84,740 / 169,406 / 374 / 0 / 15 | 综合估算 88,996 / 175,305 / 394 / 0 / 15；实现未执行 | 综合估算 90,274 / 180,082 / 411 / 0 / 15；实现未执行 | 未执行 |
| 300 MHz 自定义逻辑 | 已纳入层次/SLR 报告；独立精确计数待 P3 对比 | 仍是主要失败域；待 P3 迁移 | camera FIFO 已为同钟同步结构 | 每路 capture frontend 约 4,091 LUT/12,361 FF；像素 assembler + camera FIFO + stream 已在 150 MHz，约 359 LUT/912 FF/22 BRAM | writer/reader/manager/preprocess 分别有 6,506/18,085/19,682/1,938 个寄存器全部在 150 MHz；300 MHz 侧仅保留 AXI 队列端及 capture | 未执行 |
| 最大 FIFO 占用/服务空窗 | 未测 | 未执行 | 小深度测试 FIFO 达 8/8；全深度服务空窗未测 | 8-deep 事件测试 FIFO 强制溢出并恢复；综合深度 1024，板级服务空窗未测 | AXI 测试采用 command 16/data 32/response 16；生产深度 command 32/data 512/response 32；全系统最大服务空窗仍未测 | 未执行 |
| 输入/写入/显示有效帧率 | 未测 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 丢帧/错误帧发布数量 | 未测 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 板测 | 未执行 | 未执行 | 基础 HDMI 点亮通过（用户反馈）；压力未执行 | 基础 HDMI 点亮通过（用户反馈）；压力未执行 | 未执行 | 未执行 |

## 报告位置

- 历史对照：`reports/video_timing_refactor/P0/reported_baseline/`。
- 工程清单：`reports/video_timing_refactor/P0/project_inventory/`。
- 当前 clean rebuild：`reports/video_timing_refactor/P0/current_worktree_baseline/`；DCP SHA-256 `0f2eff178e50a04467e7348b51116d5084c65a87ef7331065981addc526f7b15`。
- P1：`reports/video_timing_refactor/P1/reset_enable_constraints/`；DCP SHA-256 `513acc22eac1bb124bf001fd34b5338840fe6839ea401b0c9ac53e2cea57c2c1`，bitstream SHA-256 `a54a55f351c3469939f3c1ff080dfd06afca9fc1febab7c0eb4bbabcc6486bd8`。
- P2 综合 DCP（随后已被 P3 综合覆盖）：生成于 2026-09-06 14:19:31 +0800，SHA-256 `024c3bc8ac2881a554e9c13073283f6c3dea8e5360aa3193d4cadb5ad6e2c5c4`。在该综合阶段结束时实现尚未执行；随后用户完成 P2 bitstream，见下一项。
- P2 用户侧 routed timing：`prj/timing_summary.rpt`，生成于 2026-09-06 15:05:57 +0800。用户报告 bitstream 成功及基础 HDMI 点亮正常；bitstream 文件未纳入 Git/本阶段报告清单。
- P3 综合 DCP：`prj/sixteen_camera.runs/synth_1/top_wrapper.dcp`，生成于 2026-09-06 15:56:09 +0800，SHA-256 `758f8fd97e438211acdad10196e615cc6ed71f93c47fd5b436365256be10a05d`。综合级报告位于 `reports/video_timing_refactor/P3/synth/`；P3 routed DCP、时序报告和 bitstream 未执行。
- P3 后续由用户完成 bitstream 和下板，用户反馈基础 HDMI 正常点亮；该 routed/bitstream 构建不是本次代理执行，未保存 P3 routed timing 分类，压力、重启及异常恢复未执行。
- P4 综合 DCP：`prj/sixteen_camera.runs/synth_1/top_wrapper.dcp`，生成于 2026-09-06 17:00:16 +0800，SHA-256 `cdde073837a2e37bf0f7c8952d40ede85129b20ff283b1a5babb2203b3588c8a`。综合级报告位于 `reports/video_timing_refactor/P4/synth/`；P4 placement、route、bitstream 和板测未执行。

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
- 随后用户侧 bitstream 构建成功且基础 HDMI 点亮正常。保存的 routed timing 为 WNS -0.693 ns、TNS -1185.536 ns、8,181 个失败端点，因此仍未完成 routed 时序签核；压力/重启/异常板测未执行。

## P3 结论（截至综合）

- 用 `BUFGCE_DIV` 从 MIG UI/capture 的 3.332 ns 时钟产生真实 6.664 ns video 域。DVP 采样、PCLK 恢复和过滤仍在 300 MHz；RGB 拼接、像素扩展、camera FIFO 和 stream 封装迁入 150 MHz。
- 每路新增 capture→video 有序事件 FIFO、独立 fault 通道和 overflow 后按完整帧 resync；P4 前用临时 150→300 完整 stream FIFO 接回旧 writer。未把 P2 同步 FIFO 直接跨域使用。
- 最终功能回归与 clean synthesis 均实际通过。综合网表层次中每路事件桥约 238～240 LUT/358 FF/0.5 BRAM，临时 writer bridge 约 232～235 LUT/318 FF/2 BRAM；新增临时双向 CDC 使 P3 综合资源高于 P2，P4 应删除回程桥。
- 300/150 clock interaction 保持真实计时；仅沿用 XPM/复位同步器内部合法例外，没有添加 clock group 或扩大 false path。全设计综合 CDC 仍报告既有问题（含 CDC-10/11/13），需要 P5/既有 IP 分项审计，不能宣称 CDC clean。
- P3 的 bitstream 和基础板级点亮随后由用户完成并通过；压力/重启/异常板测及可归档的 routed timing 分类仍未执行，不能据此宣称物理时序已经签核。

## P4 结论（截至综合）

- frame manager、capture writer、display reader/overlay 和 batch preprocess 高层逻辑整体迁入 150 MHz video 域；P3 的八路 camera 150→300 临时回程 FIFO 已删除。八路 HDMI capture stream 使用 300→150 完整 stream FIFO 后与 camera stream 在同一 video 域汇合。
- 根据真实的 256-bit、ID3 S01/S02 AXI 接口，在 video↔MIG UI 边界增加四条专用队列桥：writer AW/W/B、reader AR/R、preprocess read AR/R、preprocess write AW/W/B。各 AXI channel 独立保序，地址、ID、burst 属性、payload、strobe、last 和 response 原子跨域；没有修改 MIG/BD 参数或非 Gemmini SoC。
- 混合 CDC 测试并发发送 24 次写和 12 个四拍读 burst，在 AW/W/B/AR/R 随机停顿及延迟返回下通过，未发现顺序、ID、last 或数据错配。新增 writer 定向测试证明最终 B 返回前不产生 `frame_done/frame_error`、不重新申请同一通道 buffer，并在延迟 B 后分别正确发布完整帧或错误帧。
- 既有 frame-manager writer handshake 和 AI snapshot 用例继续通过，覆盖 error/done 与下一次 acquire 同拍以及 reader/preprocess 持有槽位时的所有权。生产 reader 仍在发 AR 前为整个 burst 预留本地返回 FIFO 空间；新增 UI response FIFO 只增加吸收能力，不替代该预约不变量。
- clean synthesis 实际通过，0 error、0 critical warning。综合层次证明高层四模块的寄存器全部属于 `camera_video_clk`；四个 UI bridge 才跨 `camera_video_clk`/`mmcm_clkout0`。两时钟方向仍为真实 timed/partial-false-path，没有添加 clock group 或扩大 false path。
- 全设计综合 CDC 仍含既有 CDC-10/11/13 等问题，留到 P5 分类清理，不能宣称 CDC clean。生产深度下的最大 DDR 服务空窗、端到端帧率和完整 16-client+HDMI+preprocess 并发压力尚未测量；P4 placement、route、bitstream 和板测均未执行。

## 回滚索引

每个 P 阶段使用独立 Git commit。P0/P1/P2/P3 回滚点分别为 `ffe513c`、`32e8779`、`ed19ee7`、`9e4f9f0`；P4 回滚点见本阶段提交。不会提交 routed DCP、bitstream、综合报告或 Vivado 临时目录，大文件由路径、mtime 和 SHA-256 关联。
