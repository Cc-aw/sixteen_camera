# 当前三路 MaxPool 与 TensorIngress 硬件

当前唯一交付硬件为 `triple32_v3_tensor`，默认 `make project/firmware/bitstream/program`
均使用它。配置名保持 `TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig`，
没有新增带开发目录日期或 timing 版本的并行配置。

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

## 硬件契约和变化

| 项目 | 当前配置 |
| --- | --- |
| 计算 | 1 Rocket、1 RVV、3 Gemmini32；100 MHz；三路 MaxPool 开启 |
| Gemmini | WS、INT8 输入、INT24 PE、INT32 ACC、64 路 FP16 scale/worker |
| SPAD / ACC / DMA | 每 worker 512 KiB / 256 KiB / 32 outstanding |
| LoopConv | SAFE_MAX=4，入口 permission 仍检查 queue/partial 状态 |
| L2 | 双 bank、总512 KiB；每 bank 8 ways、512 sets、32普通+2一致性 MSHR |
| L2 bank / set | A12；set bits 6–11、13–15 |
| 内侧通道 | A/B/C/D/E 各两条目 non-flow/non-pipe 寄存队列 |
| 请求队列 | 每 bank 102 个逻辑队列共享 34-entry 同步 payload RAM，窄指针，4个读响应 credit |
| L2调度 | 普通 MSHR 分4组各8个，另含2个一致性 MSHR；寄存 winner 并在提交时重验 |
| SBUS / Gemmini DMA / Tensor | 256 bit；Tensor 本地 ID5，独立 source范围512–543 |
| L2外侧 / SoC memory / DDR S00 | 512 bit / 本地ID2；S00读写各32 outstanding |
| Head | 六个1 MiB槽；512-bit写、256-bit PPU读 |
| Tensor CSR / 内存统计 CSR | `0x02012000` / `0x02020000`；MPV3 ABI1.1、14个统计块 |

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
| L2放置 | 两bank分别软引导SLR0、SLR2；无routing containment |
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
make firmware firmware-benchmark check-v26-firmware
```

工程为 `build/projects/triple32_v3_tensor/sixteen_camera.xpr`。
已检查实际SoC/DDR端口、双bank五通道寄存队列、one-hot请求选择、三路MaxPool、
Tensor端口和统计ABI1.1。局部综合覆盖改动子系统，不启动整机synth_1/impl_1。
`tools/check/check_hardware_project.tcl` 审核保存的GUI属性，并以 `-scripts_only`
生成综合/实现脚本，确认与配置一致且两个run未执行。

实际验证及局部WNS见 [最新硬件验收](../validation/latest-hardware.md)。
当前软件仍为 [v26](triple32-v26-software.md) credit-cap4 正式版；旧ABI/mock主机
测试用于协议回归，不代表仍交付旧硬件规格。

## 下一步上板

本次硬件已变更，必须重新生成并加载最新bitstream，再下载匹配的v26固件：

```bash
make bitstream
bash tools/program/download_bitstream.sh
make program PROGRAM_ARGS=--no-build
```

完整综合、实现、bitstream和开发板下载均留给用户执行。局部综合的WNS不能代表
整机布线后时序；以新run的最终setup/hold、route、bus-skew报告为准。
数值检查使用v26独立三图基准的 `M/t/a`，随后验证实时视频持续推理、排空和重启。
