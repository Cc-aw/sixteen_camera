# 0918 timing flow for the three-worker video project

入口（在当前项目根目录运行）：

```bash
bash scripts/build_triple64_video_bitstream.sh --check
bash scripts/build_triple64_video_bitstream.sh
```

`--check` 只检查 Vivado 版本、生产 manifest 和生成 RTL 的视频/FBus 接口。
正式运行依次执行完整综合、优化、布局、布线、候选回退、hold 修复和 bitstream。
结果目录默认 `build/bitstream_0918_video/<时间戳_PID>/`，不覆盖旧结果。
这条流程直接实现 `synth_opt.dcp`，不使用项目中的旧 `impl_1` 结果。

```bash
export RESULTS_DIR="$PWD/build/video_0918_$(date +%Y%m%d_%H%M%S)"
FINAL_JOBS=8 FINAL_THREADS=8 ROUTE_THREADS=4 \
  bash scripts/build_triple64_video_bitstream.sh
```

正常输出：`$RESULTS_DIR/video_100m_3x64_0918.bit`。
如果 setup 未通过但布线合法且 hold 干净，按此前允许首版 setup 小违例的要求，
仍输出 `video_100m_3x64_0918_setup_violated.bit`，同时 `TARGET_MET=0`。
脚本中的 BUILD=PASS 只表示 bit 已生成；时序结论看 `final_status.txt` 的 TARGET_MET。
设 `BIT_REQUIRE_TARGET=1` 时，未达到原版严格目标会返回退出码 5，已生成的 bit 仍保留。
布线不合法或 hold 不干净时不生成 bit。保留 Vivado 默认 DRC，不降低 DRC 严重级别。

生成后指定新路径下载，避免误用原 `impl_1/top_wrapper.bit`：

```bash
bash scripts/download_bitstream.sh --bitstream "$RESULTS_DIR/video_100m_3x64_0918.bit"
bash scripts/download_triple64_video.sh
```

若生成的是 `_setup_violated.bit`，使用实际输出文件名。这里不自动连接开发板。

## 与实际成功版本的对应关系

原目录：`/home/zw/0918/npu-zw-100-timing`。
已核对 `results-100m-0918/implementation.log`、`synth.log` 和 `final_status.txt`：
原版 WNS/TNS/WHS/THS 为 `0.005 / 0.000 / 0.009 / 0.000 ns`，route 合法。
`baseline_sources.json` 记录原脚本路径和移植前 SHA256。

| 阶段 | 采用的 0918 策略 |
| --- | --- |
| 综合 | `Flow_PerfOptimized_high`、global retiming、fanout_limit 64、rebuilt hierarchy |
| 逻辑优化 | `opt_design -directive ExploreWithRemap` |
| DSP 布局 | 四个 SLR 为 56/24/56/56 行，仅 DSP hard pblock，逻辑保持自由 |
| placement | `SSI_SpreadLogic_high` |
| pre-route phys_opt | `AggressiveFanoutOpt` → `AlternateFlowWithRetiming` → `AggressiveExplore` |
| route | `Default -tns_cleanup`，不换其他 route directive |
| post-route | 独立尝试 AggressiveExplore、routing/critical-pin/critical-cell 优化；变差回退 |
| hold | sll_reg_hold_fix → aggressive_hold_fix，必要时再次 Default route |
| 严格时序目标 | WNS > 0、TNS = 0、WHS ≥ 0、THS = 0、无 hold 失败端点 |

原版成功日志中 retiming 的那轮 phys_opt 因当时 WNS 已非负而被 Vivado 跳过，
不能据此声称每一轮都实际改动了网表。本流程保留原命令及其自动判断。

## 视频工程适配

- 使用现有 `prj/sixteen_camera.xpr` 和 `setup_vivado.tcl`，保留视频、HDMI、DDR、
  摄像头引脚与 CDC 约束；不加载 standalone wrapper 的 DDR/reset 时序例外。
- 禁用旧 incremental DCP，每次重新综合。不要与其他直接操作同一 `.xpr` 的 Vivado
  构建并行；入口之间通过 `flock` 互斥。
- 原 DSP 行分配不变；一次查询 DSP 集合，避免针对 1536 个 tile 重复扫描整个视频设计。
  校验每 tile 4/8 DSP、每行 48 DSP、三个 mesh 共 9216 DSP。
  额外视频 DSP 不计入 mesh 检查。
- 从实际 RocketTile clock pin 检查 10 ns 周期，不再假设全工程只有一个 100 MHz 时钟。
  保留三个 Scratchpad 的 SLR0/SLR2/SLR3 Scala hint 检查。
- 保留原逐 SLR 资源告警；可用 `RESOURCE_GATE=enforce` 改为提前中止。
- 保存各阶段 DCP/时序/布线报告，最终额外输出 DRC、bus skew、clock interaction 和
  check_timing 报告。当前工程原有告警见 `doc/three_worker_video.md`。

## 脚本验证

```bash
tclsh scripts/npu0918_video/test_flow.tcl
bash scripts/build_triple64_video_bitstream.sh --check
```

覆盖原时序候选比较/回退判据、9216 DSP 的分配计数、错误时钟及缺失 DSP 的拒绝。
还使用 Vivado 2023.2 仅配置综合 run 验证属性接受情况，未启动本轮完整综合/布线。
增加视频与六槽后，原来的 +0.005 ns 结果不能视为新工程的时序保证。
