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
| 正常 PCLK/HREF 恢复 | 通过 | 通过 | 通过 | 通过（既有恢复测试 + 新事件桥参考输出） | 未执行 | 未执行 |
| disable/enable/reset/半像素 | 部分覆盖 | 通过（含半像素 disable→enable） | 通过（含 FIFO 冲洗、无旧 beat 泄漏） | 通过（fault/overflow 后丢弃并按完整帧恢复） | 未执行 | 未执行 |
| 随机 AXIS 背压/满空 | 基础用例通过 | 基础用例通过；随机压力留给 P2 | 通过（随机背压、近满、稳定性、顺序和无气泡排空） | 通过（事件 FIFO 强制溢出；临时 stream CDC 随机反压） | 未执行 | 未执行 |
| 新旧前端逐帧等价 | 不适用 | 不适用 | 不适用 | 定向参考等价通过；真实双前端长帧逐拍对比未执行 | 未执行 | 未执行 |
| DDR AW/W/B、AR/R 随机停顿 | 部分既有用例 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 16 路 + HDMI + preprocess 压力 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| routed setup/hold/pulse/CDC | 已执行，时序失败 | 已执行，setup 失败、hold/pulse 通过 | 未执行 | 未执行 | 未执行 | 未执行 |
| 板级压力/重启/异常恢复 | 未执行 | 未执行 | 基础点亮通过；压力/重启/异常未执行 | 未执行 | 未执行 | 未执行 |

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
- P3 板测：未执行。
