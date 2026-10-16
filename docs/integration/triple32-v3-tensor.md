# 当前三路 MaxPool 与 TensorIngress 硬件

当前唯一交付硬件为 `triple32_v3_tensor`，默认 `make project/bitstream` 使用它。
实时 Runtime 待前端适配，`make firmware` 的 ABI 阻断保持有效。配置名保持 `TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig`，
正式导出仍只有一份；两 bank 回退配置只生成到私有候选目录。

2026-10-14 移入开发目录
`/mnt/data/sunys/sixteen_camera_3x32_100mhz_memory_parallel_v3_maxpool_timing_v3_2026-10-13`
的 MaxPool / MemoryParallelV3 / timing 策略，在源码层合并本工程的专用 TensorIngress，
从私有 Chipyard 工作区完整编译并重新生成 SoC。旧 single4、dual16、Linux 及旧
TensorIngress 导出已退出 `hw/soc/`，对应固件/生成入口也已退休。历史实现由 Git 保存，
原本地工程和固件产物备份在忽略的 `build/ports/latest-hardware/baseline/`。

2026-10-15 继续移入 Oct07 开发目录内独立的
`soc_shell/memory_parallel_v3_timing_repair` 修复：寄存仲裁身份、同步共享请求池、
保留 set 所有权的同步 refill，以及 DDR 五通道 mode1 FWD/REV 切片和 SLR0
布局引导。配置名、三路 MaxPool、TensorIngress 和内存统计 ABI1.1 保持兼容。
实现和验证记录见 [V3 时序修复](../validation/v3-timing-repair.md)。

2026-10-16 已撤回 H1／同步池候选，恢复指定 S1 的 Head、组合调度器和 34-entry
请求池，保留 TensorIngress 和 DDR mode1。随后按
[1 MiB／四 bank 计划](../architecture/l2-1mib-4bank-implementation.md) 扩容：
每 bank 仍为 256 KiB，四 bank 共 1 MiB，性能统计扩展为 ABI1.2。
按后续指令启动完整流程至比特流生成，本轮监听到整机综合结束；后续实现状态
单独记录，产物是否生成以及时序是否通过以实际运行记录为准。

## 硬件契约和变化

| 项目 | 当前配置 |
| --- | --- |
| 计算 | 1 Rocket、1 RVV、3 Gemmini32；100 MHz；三路 MaxPool 开启 |
| Gemmini | WS、INT8 输入、INT24 PE、INT32 ACC、64 路 FP16 scale/worker |
| SPAD / ACC / DMA | 每 worker 512 KiB / 256 KiB / 32 outstanding |
| LoopConv | SAFE_MAX=4，入口 permission 仍检查 queue/partial 状态 |
| L2 | 四 bank、总1 MiB；每 bank 8 ways、512 sets、32普通+2一致性 MSHR |
| L2 bank / set | A13:A12；set bits 6–11、14–16；bank/set 周期128 KiB |
| 内侧通道 | A/B/C/D/E 各两条目 non-flow/non-pipe 寄存队列 |
| 请求队列 | 每 bank 102 个逻辑队列共享 34-entry 寄存 payload 池，组合 fastPeek |
| L2调度 | S1 组合 round-robin、原目录/repeat规则、直接 retire/refill；每 bank 32+2 MSHR |
| SBUS / Gemmini DMA / Tensor | 256 bit；Tensor 本地 ID5，独立 source范围512–543 |
| L2外侧 / SoC memory / DDR S00 | 512 bit / 本地ID2；S00读写各32 outstanding |
| Head | 六个1 MiB槽；512-bit AXI、256-bit PPU读；S1 读写分别流水、DDR outstanding32、切换本地槽前按方向排空 |
| Tensor CSR / 内存统计 CSR | `0x02012000` / `0x02020000`；MPV3 ABI1.2、16个统计块，原0–13编号保留 |

Tensor 收齐两拍后以 `PutFullData(size=6)` 写入 L2 上游；冷行整行覆盖不读取旧
DDR 数据。保持独立 AW/W/B CDC、局部完成协议和统计块13。板级新增流水边界：
Tensor 输入完整记录、显示 tile/地址/burst 计划、DVP 事件接收/写FIFO、MIG 返回
两条目队列。相机 capture/reset 五组本地寄存器降低扇出；内存统计增加本地 reset
同步释放。DVP almost-full 为尚未写入FIFO的寄存事件预留一条目。

保留本工程 `ctx_active && ctx_bad` 的坏帧退役条件与 `ctx_bad` 清除，避免导入
开发目录中较旧的退役逻辑。FBus 写 CDC 继续使用 `RELATED_CLOCKS=0`；视频/UI
相关时钟和 Tensor 完成语义不变。流水级增加首拍或 burst 准备延迟，不宣称吞吐提升。

## 生成入口

```bash
python3 tools/soc/build_triple32_v3_tensor.py \
  --reference /path/to/compatible/chipyard \
  --workspace /tmp/new-triple32-chipyard
python3 tools/soc/build_triple32_v3_tensor.py \
  --workspace /tmp/new-triple32-chipyard --emit-core-only
make check
```

`hw/soc/source/shell/npu100_video` 保存 Gemmini/Saturn/FPGA 源码；
`memory_parallel_v3` 保存最新 cache/配置覆盖；`reference` 是构建需要的冻结依赖。
`LATEST_HARDWARE_IMPORT.json` 记录开发来源、适配哈希、保留项和实现策略，
`IMPORT_MANIFEST.json` 与依赖检查校验当前 shell。生成输出只保留当前一份
`hw/soc/<配置>/`。旧导出在替换前移入忽略的 `build/soc_backups/`。

准备工作区后依次恢复冻结依赖、安装最新覆盖和 TensorIngress、正常 SBT 编译、
elaboration、原有 RAM 推断处理与结构检查。源功能修改不通过 RTL 文本补丁实现。
`--resume` / `--emit-core-only` 会检查工作区的实际覆盖源码；旧 shell 的工作区会
被拒绝，避免用旧 MaxPool/缓存逻辑再生成。重新准备工作区即可更新源码。
环境为 Chisel6 / Scala2.13.16、Java/SBT、firtool；Vivado为2023.2。

`GENERATION_CONTEXT.json` 记录 build.sbt、准备工作区的 Scala 源快照、处理前后
RTL 哈希。Scala 快照包含未被本配置使用的依赖文件；编译闭包由 build.sbt 的
source filters 决定，不能将快照文件数量当作编译数量。

## 综合与布局布线策略

GUI 和批处理共用 `tools/build/triple32_v3/run_settings.tcl`：

| 步骤 | 策略 |
| --- | --- |
| synthesis | Flow_PerfOptimized_high / PerformanceOptimized；retiming on、sharing off、SHREG_MIN_SIZE5 |
| optimization | ExploreWithRemap；pre_opt 应用精确 CDC/reset 约束 |
| placement | Performance_SpreadSLLs / SSI_SpreadLogic_high |
| pre/post-route physical optimization | AggressiveExplore |
| routing | AlternateCLBRouting、`-tns_cleanup` |
| post-route追加优化 | WNS<0时第二次 AggressiveExplore |
| mesh放置 | DSP硬pblock：SLR0、SLR1、SLR3；第三路queue/RS软引导SLR3 |
| L2放置 | bank0/1/2/3分别软引导SLR0/2/1/3；无routing containment，尚未进行整机布局验证 |
| DDR边界 | 五通道 REG_*=1 FWD/REV；crossbar和最终slice软引导SLR0 |

`placement_timing_repair.tcl` 先调用原 mesh/L2 放置，再设置 DDR 局部性；不新增
时序例外或降低时钟。旧 BD 通过 `make project` 自动将五通道 mode7 更新为
mode1，再 validate / regenerate；S00 仍为512 bit、ID2、读写各32 outstanding。

reset例外只针对已实现同步器的首级D或异步assert引脚，第二级D和业务路径继续
参与时序；统计mailbox保留有限max-delay与逐bank bus-skew约束，没有整域false-path。
最终报告同时保留 setup/hold、route status 和 bus-skew。开发目录本版尚无新的
整机实现成绩；其README中的 timing_v2 WNS/TNS不是本版结果。

## 验证和当前工程

```bash
make project
make test-video-pipeline test-video test-tensor test-memory-v3 test-ppu test-software
python3 tests/rtl/run_memory_v3_tensor_cache_test.py --workspace /tmp/new-triple32-chipyard
make test-tensor-ingress
python3 tools/check/run_triple32_v3_tensor_ooc.py \
  --targets l2 pool-store pool-dma tensor --output build/reports/new_soc_ooc
python3 tools/check/run_video_pipeline_ooc.py --output build/reports/new_video_ooc
make check-deps
make test-v33
```

工程为 `build/projects/triple32_v3_tensor/sixteen_camera.xpr`。
已检查四 bank 的实际 SoC 端口、五通道寄存队列、S1请求池、三路MaxPool、
Tensor端口和统计ABI1.2。两／四 bank 的一致性与统计回归、生成互连访存仿真和
局部综合的实际证据见 [四 bank 验证记录](../validation/l2-1mib-4bank.json)。
整机综合使用独立工程 `build/projects/l2_1m_4bank_candidate/sixteen_camera.xpr`，
状态、日志和综合产物见 `build/reports/l2_1m_4bank/full_synthesis/`。
流程先运行 IP 综合及整机 `synth_1`，完成后自动接续 `impl_1` 到
`write_bitstream`。后续状态见 `build/reports/l2_1m_4bank/full_implementation/state.json`。
`tools/check/check_hardware_project.tcl` 审核保存的GUI属性，并以 `-scripts_only`
生成综合/实现脚本；该审核在本轮整机综合启动前完成，当时两个run均未执行。

实际验证及局部WNS见 [最新硬件验收](../validation/latest-hardware.md)。
当前软件仍为 [v26](triple32-v26-software.md) credit-cap4 正式版；旧ABI/mock主机
测试用于协议回归，不代表仍交付旧硬件规格。

## 当前候选验收边界

四 bank 的自动验证和重新生成来源见
[四 bank 验证记录](../validation/l2-1mib-4bank.json)。历史 Head/L2 候选状态保留在
[Head/L2 验证记录](../validation/head-l2-urgent.md)。本轮不下载 FPGA、固件或 Flash。
V33 独立基准保持现有模型、输入、计划表和 ABI；实时 v26 Runtime 仍待适配。

局部综合 WNS 不能代表整机布线后时序。完整实现的 setup/hold、route、CDC、
bus-skew 与 bitstream 在后续完整实现完成后才可验收；未执行新的板测，
`BOARD_RUN=NOT_RUN`、`MODEL_THROUGHPUT=NOT_MEASURED`，不宣称整网性能提升。

两 bank 回退生成（不替换正式导出）：

```bash
python3 tools/soc/build_triple32_v3_tensor.py --workspace /tmp/new-triple32-chipyard \
  --resume --l2-banks 2 --no-export
```
