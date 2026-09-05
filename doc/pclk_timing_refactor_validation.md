# PCLK/视频时序重构验证记录

## 可复现命令

```bash
./scripts/run_video_refactor_tests.sh
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source prj/build_bitstream.tcl
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
| 正常 PCLK/HREF 恢复 | 通过 | 通过 | 未执行 | 未执行 | 未执行 | 未执行 |
| disable/enable/reset/半像素 | 部分覆盖 | 通过（含半像素 disable→enable） | 未执行 | 未执行 | 未执行 | 未执行 |
| 随机 AXIS 背压/满空 | 基础用例通过 | 基础用例通过；随机压力留给 P2 | 未执行 | 未执行 | 未执行 | 未执行 |
| 新旧前端逐帧等价 | 不适用 | 不适用 | 不适用 | 未执行 | 未执行 | 未执行 |
| DDR AW/W/B、AR/R 随机停顿 | 部分既有用例 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 16 路 + HDMI + preprocess 压力 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| routed setup/hold/pulse/CDC | 已执行，时序失败 | 已执行，setup 失败、hold/pulse 通过 | 未执行 | 未执行 | 未执行 | 未执行 |
| 板级压力/重启/异常恢复 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |

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
