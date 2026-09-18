# PCLK/视频时序重构验证记录

## 可复现命令

```bash
./scripts/run_video_refactor_tests.sh
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source prj/build_synthesis.tcl
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source prj/build_bitstream_from_synth.tcl
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source scripts/report_video_timing.tcl -tclargs -dcp <routed.dcp> -out_dir <report-dir>
python3 scripts/summarize_video_timing.py <report-dir>
```

## P0

- `run_video_refactor_tests.sh`：实际执行，通过。
  - PCLK recovery period/CE/harmonic 自检查通过。
  - HREF line guard 自检查通过。
  - camera AXIS FIFO 行边界与 camera stream recovery 自检查通过。
  - frame manager writer handshake、AI snapshot 自检查通过。
  - 16-channel mosaic reader 自检查通过；Verilator 有 width warning，无测试失败。
- 历史 routed DCP 报告流水线：实际执行；枚举并汇总 20,800 个负 setup endpoint，与 timing summary 计数一致。逐行 slack 仅保存到 1 ps，故从舍入行重算 TNS 为 -6258.937 ns，而 Vivado summary 为 -6258.903 ns。
- 当前提交 clean synth/place/route/bitstream：实际执行，通过；`BITSTREAM_BUILD=PASS`。时序仍失败，不能把 bitstream 成功解释成签核通过。
- 当前 routed DCP timing/CDC/methodology/exception/SLR 报告流水线：实际执行，通过；完整枚举 20,800 个负 setup endpoint。
- 板测：未执行。

## 阶段验证状态

| 场景 | P0 | P1 | P2 | P3 | P4 | P5/P6 |
|---|---|---|---|---|---|---|
| 正常 PCLK/HREF 恢复 | 通过 | 通过 | 通过 | 通过（既有恢复测试 + 新事件桥参考输出） | 通过（全量回归） | P5 通过；P6 未执行 |
| disable/enable/reset/半像素 | 部分覆盖 | 通过（含半像素 disable→enable） | 通过（含 FIFO 冲洗、无旧 beat 泄漏） | 通过（fault/overflow 后丢弃并按完整帧恢复） | 通过（全量回归） | P5 通过；P6 未执行 |
| 随机 AXIS 背压/满空 | 基础用例通过 | 基础用例通过；随机压力留给 P2 | 通过（随机背压、近满、稳定性、顺序和无气泡排空） | 通过（事件 FIFO 强制溢出；临时 stream CDC 随机反压） | 通过（全量回归） | P5 通过；P6 未执行 |
| 新旧前端逐帧等价 | 不适用 | 不适用 | 不适用 | 定向参考等价通过；真实双前端长帧逐拍对比未执行 | 未执行 | 未执行 |
| DDR AW/W/B、AR/R 随机停顿 | 部分既有用例 | 未执行 | 未执行 | 未执行 | 通过（24 写 + 12×4 拍读，五通道随机停顿/延迟） | P5 回归通过；P6 未执行 |
| 16 路 + HDMI + preprocess 压力 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| routed setup/hold/pulse/CDC | 已执行，时序失败 | 已执行，setup 失败、hold/pulse 通过 | 未执行 | 未执行 | setup 失败 22，hold/pulse 通过 | P5/P6 未执行 |
| 板级压力/重启/异常恢复 | 未执行 | 未执行 | 基础点亮通过；压力/重启/异常未执行 | 基础点亮通过；压力/重启/异常未执行 | 基础点亮通过；压力/重启/异常未执行 | P5/P6 未执行 |

表中“未执行”不能解释为通过；后续只有实际运行命令并保存输出后才更新。

## P1

- `run_video_refactor_tests.sh`：实际重新执行，通过；包括 PCLK recovery、HREF guard、camera line boundary、camera stream recovery、frame manager 两项测试和 16-channel mosaic reader。
- `tb_camera_axis_cdc_line_boundary` 新增半像素 disable→enable 场景：实际执行，通过；旧半像素没有与新行像素拼接。
- clean synth/place/route/bitstream：实际执行，通过；最终 bitstream 时间为 2026-09-05 20:44:48 +0800。setup 仍失败，不能视为时序签核。
- routed 报告流水线：实际执行，通过；完整枚举 11,779 个负 setup endpoint，行级舍入 TNS 为 -2949.638 ns，Vivado summary 为 -2949.667 ns。
- DVP IOB→sync max：实际报告 88 条；43 条违反 1.5 ns、45 条满足，最差 -0.696 ns。规则覆盖报告为 88/88 endpoint，ignored report 中没有该 max-delay。
- DVP IOB→sync min：实际报告显示由 `-datapath_only` 自动 hold false path 覆盖；未把该结果记为通过。全设计 hold 为 WHS +0.010 ns、THS 0。
- methodology：实际执行；camera 相关 8 个 LUTAR-1 消除，全设计 LUTAR-1 由 30 降为 22；TIMING-13=0、TIMING-28=0、TIMING-10=1。
- 板测：未执行。

## P2（截至综合）

- `run_video_refactor_tests.sh`：实际重新执行，通过，最终输出 `VIDEO_REFACTOR_TESTS=PASS`。
- 新增 `tb_camera_axis_cdc_backpressure`：实际执行，通过；覆盖 80 beat 随机背压下的顺序/sideband、`valid && !ready` 稳定性、8/8 近满占用、连续排空无气泡，以及 disable 后旧 beat 不泄漏。
- clean top-level synthesis：实际使用 `prj/build_synthesis.tcl` 执行，通过；`SYNTH_STATUS=synth_design Complete!`、`SYNTH_PROGRESS=100%`、`SYNTHESIS_BUILD=PASS`，综合器报告 0 error、0 critical warning。
- 综合网表检查：实际执行；八路 camera CDC 层级均包含 `xpm_fifo_sync`，综合日志记录八个 `16K x 50` camera FIFO BRAM。
- placement、route、bitstream：后续由用户实际执行并成功生成 bitstream。保存的 routed timing report 生成于 2026-09-06 15:05:57 +0800；WNS -0.693 ns、TNS -1185.536 ns、setup 失败端点 8,181，WHS +0.003 ns、WPWS +0.039 ns，因此 bitstream 成功不等于时序签核。
- 板测：用户反馈基础 HDMI 点亮正常；压力、重启和异常恢复未执行。

## P3（截至综合）

- `run_video_refactor_tests.sh`：最终 RTL 修改后实际重新执行，通过，输出 `VIDEO_REFACTOR_TESTS=PASS`。
- 新增 `tb_dvp_event_bridge_assembler`：实际执行，通过；覆盖 2:1 capture/video 时钟、有序 blanking/frame/line 事件、RGB565→RGB888 参考等价、SOF/EOL 同拍 sideband、随机 pixel backpressure、8-deep FIFO 强制溢出和下一完整帧 resync；最终 `overflow=4`。
- 新增 `tb_video_stream_cdc`：实际执行，通过；覆盖 20 个 88-bit stream beat 在 150→300 等效时钟及随机反压下的顺序、全部 sideband 和 stalled payload 稳定性。
- clean top-level synthesis：最终实际使用 `prj/build_synthesis.tcl` 执行，通过；`SYNTH_STATUS=synth_design Complete!`、`SYNTH_PROGRESS=100%`、`SYNTHESIS_BUILD=PASS`，综合器最终为 0 error、0 critical warning。
- 综合级报告：实际执行 `report_cdc -details`、`report_clock_interaction`、`report_methodology` 和层次资源报告。`camera_video_clk` 为 6.664 ns，capture `mmcm_clkout0` 为 3.332 ns；双向 clock interaction 均保留为 timed/partial-false-path（XPM 内部例外），未使用 clock group 隐藏边界。全设计 CDC 报告仍含既有 SoC/MIG/HDMI/诊断 crossing 告警，不能表述为 CDC clean。
- placement、route、P3 bitstream、routed setup/hold/pulse/CDC：按用户要求未执行。
- P3 板测：用户随后完成 bitstream 和下板，反馈基础 HDMI 正常点亮；压力、重启、异常恢复和端到端性能测量未执行。

## P4

- `run_video_refactor_tests.sh`：最终 RTL/测试修改后实际重新执行，通过，输出 `VIDEO_REFACTOR_TESTS=PASS`。
- 新增 `tb_axi4_ui_cdc_mixed`：实际执行，通过；150/300 等效时钟下并发 24 个单拍写事务与 12 个四拍读事务，随机控制 AW/W/AR 接收、B/R 产生以及 video 侧 B/R 消费，检查完整 AXI 属性、ID、数据、strobe、response、last 和每通道顺序；输出 `TB_AXI4_UI_CDC_MIXED=PASS writes=24 read_beats=48`。
- 新增 `tb_multi_channel_video_dma_completion`：实际执行，通过；首帧最终 B 被延迟期间保持 channel active、禁止重新 acquire 且无完成脉冲，B 到达后才发布 done；下一错误帧也等待最终 B 后才发布 error；输出 `TB_MULTI_CHANNEL_VIDEO_DMA_COMPLETION=PASS`。
- 既有 `tb_multi_channel_frame_manager_writer_handshake` 和 `tb_multi_channel_frame_manager_ai_snapshot`：实际重新执行，通过；分别覆盖 done/error 与下一 acquire 的同拍处理，以及 display/preprocess/AI 持有 buffer 时的所有权。
- clean top-level synthesis：实际使用 `prj/build_synthesis.tcl` 执行，通过；`SYNTH_STATUS=synth_design Complete!`、`SYNTH_PROGRESS=100%`、`SYNTHESIS_BUILD=PASS`，最终 0 error、0 critical warning。资源估算为 90,274 LUT、180,082 FF、411 BRAM tile、0 URAM、15 DSP。
- 综合级报告：实际执行 `report_clocks`、`report_clock_interaction`、`report_cdc -details`、`report_methodology`、层次资源和时钟归属查询，保存在 `reports/video_timing_refactor/P4/synth/`。writer/reader/manager/preprocess 的 46,211 个层次寄存器全部由 6.664 ns `camera_video_clk` 驱动；四个 AXI bridge 明确同时含 video/UI 两域寄存器。300/150 两方向未被 clock group 隔离。
- P4 placement、route 和 bitstream：由用户实际执行并成功。routed timing 报告流水线随后实际执行，完整枚举 22 个负 setup endpoint；Vivado summary 为 WNS -0.182 ns、TNS -1.579 ns、WHS +0.009 ns、THS 0、WPWS +0.039 ns、TPWS 0。完整报告在 `reports/video_timing_refactor/P4/routed/`。
- P4 板测：用户反馈基础 HDMI 正常点亮。完整 16 capture client + HDMI + preprocess 同时压力、最大 DDR 服务空窗、真实帧率、压力/重启/异常恢复仍未执行。

## P5（截至综合）

- `run_video_refactor_tests.sh`：最终 RTL 修改后实际重新执行，通过，输出 `VIDEO_REFACTOR_TESTS=PASS`。覆盖既有 PCLK/HREF、事件 overflow/resync、随机 AXIS/AXI 背压、frame ownership 和延迟 B 完成边界；没有新增专用的“诊断关闭”板级测试。
- clean top-level synthesis：最终实际使用 `prj/build_synthesis.tcl` 执行，通过；`SYNTH_STATUS=synth_design Complete!`、`SYNTH_PROGRESS=100%`、`SYNTHESIS_BUILD=PASS`，最终 0 error、0 critical warning。综合 DCP SHA-256 为 `b50894944857b3cd68a22ecf1816c6e205809e09c8e9b1c8448342bc0f9278be`。
- 综合结构核验：四个 IOB clock-region soft pblock 分别命中 22 个 DVP sync cells；CH0–3/CH4–7 capture producer pblock 分别命中 8 个层次实例；8,832 个 snapshot 寄存器和 176 个 DVP sync/pipe 寄存器的物理 reset pin 均接 `GROUND`，活动 reset 控制连接为 0。证据在 `reports/video_timing_refactor/P5/synth/structural_proof.txt`。
- 综合级 CDC/methodology：实际执行。CDC-10=2242、CDC-11=16、CDC-13=1 仍存在，主要包括既有 SoC/MIG/IP 以及诊断 bundle crossing，不能宣称 CDC clean；P4/P5 的 synthesized methodology 均有 265 个 MIG 内部 XSDB/校准逻辑 `TIMING-17`，不是 P5 新增回归。P5 总 LUTAR-1 为 15，PCLK 相关为 0。
- P5 placement、route、bitstream、routed setup/hold/pulse/拥塞和板测：按用户要求未执行。因此只能确认 P4 的 17 条 reset-control 端点已从结构上去除目标控制网，不能在 route 前承诺最终 WNS 或确认 3 条 IOB→sync、2 条 recovery CE 路径已经通过。
