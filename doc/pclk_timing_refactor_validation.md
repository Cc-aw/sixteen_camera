# PCLK/视频时序重构验证记录

## 可复现命令

```bash
./scripts/run_video_refactor_tests.sh
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source prj/build_bitstream.tcl
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source scripts/report_video_timing.tcl -tclargs -dcp <routed.dcp> -out_dir <report-dir>
python3 scripts/summarize_video_timing.py <report-dir>/negative_endpoints.tsv <report-dir>/negative_summary.json
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
| 正常 PCLK/HREF 恢复 | 通过 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| disable/enable/reset/半像素 | 部分覆盖 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 随机 AXIS 背压/满空 | 基础用例通过 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 新旧前端逐帧等价 | 不适用 | 不适用 | 不适用 | 未执行 | 未执行 | 未执行 |
| DDR AW/W/B、AR/R 随机停顿 | 部分既有用例 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 16 路 + HDMI + preprocess 压力 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| routed setup/hold/pulse/CDC | 已执行，时序失败 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |
| 板级压力/重启/异常恢复 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 | 未执行 |

表中“未执行”不能解释为通过；后续只有实际运行命令并保存输出后才更新。
