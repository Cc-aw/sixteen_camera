# A1 流式版本验证记录

实验目录为 `build/experiments/dma_load/streaming_20261017/`；实时状态见
[status.json](status.json)。生成来源及所有源码由版本内清单固定，实验结果和 Vivado
缓存保留在忽略的 `build/` 中。生产导出与父版本未替换。

**当前结果：首层和整网四模式板测均通过；时序未收敛。**
整网日志为 `board/logs/model_02/model.log`，已执行
`make -C hw/versions/dma_load_streaming_512kib_2bank/validation/board analyze TEST=model RUN=model_02`。
四模式各执行单路串行和三路并行，每组正式 12 帧、预热 3 帧；另有 12 帧 direct legacy
参考，共 132 次 PPU 运行。运行编号连续、全部帧完成，整网 PPU 输出与 direct legacy
参考逐项一致；51 条三路计数记录中的 DMA fault 与模式切换拒绝均为 0。
每个并行正式批次三路各完成 4 帧。硬件身份、软件身份和产物哈希均核对通过，
详见 [board_full_graph.json](board_full_graph.json)。

整网每帧耗时（100 MHz；并行为批次按帧数摊销，不是单帧延迟）：

| 模式 | 串行 ms/帧 | 三路并行摊销 ms/帧 | 并行相对 legacy 加速 |
| --- | ---: | ---: | ---: |
| legacy | 92.592 | 36.346 | 1.000× |
| read_coalesced | 94.728 | 36.289 | 1.002× |
| read_assembled | 77.985 | 30.963 | 1.174× |
| spad_assembled | 82.315 | 32.799 | 1.108× |

联合模式的整网三路合计吞吐约 32.30 帧/秒，相对 legacy 提升约 17.4%；仅读合并
基本持平。本次使用三张固定输入图像重复执行，每模式/执行器只有一个正式批次；
不能据此推广到任意输入、长期稳定性或独立 A1 流式增益。输出验收范围为整网 PPU
结果，不是所有中间张量逐字节比较。首层与本轮整网功能验证通过后，时序优化仍交由
另一工作线，WNS -5.403 ns 的状态保持未通过。

**联合模式与上一硬件版本比较：**
旧硬件为 `2a95a4ca64390235`，新硬件为 `180342787f3e6dac`，均为 100 MHz、
512 KiB/two-bank、三路 DIM32。两份诊断包的 46 项模型/输入文件和三份 Gemmini
参数头逐字节相同。以下均比较 `read_assembled`；吞吐提升按旧耗时/新耗时减一计算：

| 测试 | 上一版 ms/帧 | 新版 ms/帧 | 吞吐提升 |
| --- | ---: | ---: | ---: |
| 首层串行 | 10.318 | 9.320 | 10.70% |
| 首层三路并行摊销 | 3.598 | 3.307 | 8.78% |
| 整网串行 | 79.262 | 77.985 | 1.64% |
| 整网三路并行摊销 | 31.253 | 30.963 | 0.94% |

旧整网联合模式四轮正式结果完整，原始周期之和与汇总相符，但整个旧套件因随后断电
没有最终 PASS。旧整网每执行器 48 帧，新版目前只有 12 帧；软件流程和预热次数也有
差异，属于已有板测数据的观察比较，不能单独证明 A1 的净收益。整网并行每帧减少
约 0.290 ms，耗时下降 0.929%，吞吐提升 0.938%；不是相对上一版提升 17.4%。
后者是新版本内联合模式对 legacy 的提升。完整数据与哈希见
[board_version_comparison.json](board_version_comparison.json)。

**首层板测结果：**
板测日志为 `board/logs/streaming_02/first.log`，已执行
`make -C hw/versions/dma_load_streaming_512kib_2bank/validation/board analyze TEST=first RUN=streaming_02`，
产物与软件身份、32 个正式窗口及 8 个预热窗口、逐字节完整输出、120 条三路计数记录
均通过；DMA fault 与模式切换拒绝均为 0。共 96 个正式帧、24 个预热帧。
详见 [board_first_layer.json](board_first_layer.json)。

按 100 MHz 换算每帧耗时；并行列为整个批次按帧数摊销的耗时，不是单帧延迟：

| 模式 | 串行 ms/帧 | 三路并行摊销 ms/帧 | 并行相对 legacy 加速 |
| --- | ---: | ---: | ---: |
| legacy | 23.865 | 8.414 | 1.000× |
| read_coalesced | 25.135 | 8.492 | 0.991× |
| read_assembled | 9.320 | 3.307 | 2.544× |
| spad_assembled | 12.860 | 4.849 | 1.735× |

本次是同一流式比特流内四模式的首层对比，尚未进行关闭流式的硬件板测对照，
因此不将上述加速倍数归因为 A1 的独立增益。首层与整网验收分别记录，均不替代时序收敛。

**比特流生成结果：布线完整，Bitgen DRC 通过，时序未收敛。**
北京时间 2026-10-19 09:16 完成。流式候选仍为 `180342787f3e6dac`，RTL 和软件
ABI 未改动；本次复用 `top_wrapper_routed.dcp`，跳过随后导致一条网络断线的两次
post-route `phys_opt_design`。原失败项目及检查点保留。恢复流程使用共享实现锁、
新输出目录、输入哈希核对和原生 Bitgen DRC，未降低 DRC 严重级别。

产物：`build/experiments/dma_load/streaming_20261017/bitstream_recovery_routed_20261019/dma_load_streaming.bit`
（113,318,492 字节），SHA256：

```text
858d20164a05feb9fdf64b4e8234d3daaaecceb63ffbb185ca73271258cdb7e0
```

1,826,222 条可布线网络全部连通，routing errors 为 0。常规 DRC 只有 5,267 项
Warning；Bitgen 前置 DRC 为 0 Errors / 5,177 Warnings。实际 WNS `-5.403 ns`，
136,886 个 setup 违例端点；WHS `0.000 ns`、WPWS `0.039 ns`，hold/pulse 违例端点为 0。
因此生成状态为 `BITSTREAM_TIMING_UNMET`，不能据此记为时序通过；后续板测结果独立记录。
原始检查点、生成脚本和全部 745 项功能验证输入生成前后哈希一致。
详细产物与证据哈希见 [bitstream_recovery.json](bitstream_recovery.json)。

配套诊断 ELF 为同一实验目录 `firmware/yolov5_dma_load_first.elf` 和
`firmware/yolov5_dma_load_model.elf`，仍绑定上述硬件身份，SHA256 已重新核对。
`bitstream_recovery_routed_20261019/SHA256SUMS` 提供 bitstream 与两份 ELF 的校验值。
用户自行下载验证后，再交另一工作线优化时序。比特流生成过程中未连接或下载开发板。

统一下板入口见 [board/README.md](board/README.md)：进入 `board/` 后使用
`make preflight`、`make program-bitstream`、`make program-first`／`make program-model`、
`make uart TEST=first RUN=streaming_01` 和 `make analyze TEST=first RUN=streaming_01`。
此入口直接使用上述已审计产物，日志保存在该目录的 `logs/<RUN>/`。

恢复命令（输出目录必须不存在；可先追加 `--check` 预检）：

```sh
python3 tools/build/recover_dma_load_bitstream.py \
  --context build/experiments/dma_load/streaming_20261017/candidate/GENERATION_CONTEXT.json \
  --verification build/experiments/dma_load/streaming_20261017/verification.json \
  --source-report-dir build/experiments/dma_load/streaming_20261017/bitstream \
  --report-dir build/experiments/dma_load/streaming_20261017/bitstream_recovery_routed_20261019
```

**首次完整构建（历史）：功能仿真和综合通过，post-route 优化后布线 DRC 失败。**
构建于北京时间 2026-10-18 15:02 失败退出（UTC `2026-10-18T07:02:12Z`）。
`write_bitstream` 前置 DRC 报 `RTSTAT-1`：以下一条网络未布线，Bitgen 未执行：

```text
u_control_soc/u_rocket/chiptop0/system/tile_prci_domain/element_reset_domain_rockettile/applyOrElse/counters/counterfile/counters_5_reg[16]_i_1_n_17
```

实现日志最后一次物理优化汇总为 WNS `-5.239 ns`，时序也未满足；这不是完整布线
成功或时序收敛的结果。该次失败状态与日志哈希见
[implementation_failure.json](implementation_failure.json)；
`synthesis_handoff.json` 仅保留当时综合完成、排队实现的历史快照。
本地详细日志为实验目录的 `bitstream/console.log`、
`bitstream/project/sixteen_camera.runs/impl_1/runme.log`，检查点仍保留在实验目录。

流式候选 `180342787f3e6dac`，同源码关闭流水的对照候选
`5ff7f5c7e590cb26`。二者保持四种模式、512 KiB/two-bank L2 和三路 DIM32。
最终工具与来源清单重新生成的 820 个 RTL/参数头文件与被测文件逐字节相同，
证明保存在 `provenance/reproduction.json`，初次生成上下文另存归档。

| 证据 | 实验子目录 | 检查内容 |
| --- | --- | --- |
| Scala 单元 | `units_final2/` | 本地全量 Gemmini 源码；规划、组装、队列、ABI、Reader 一请求一事务；36 项流水/缓冲/错误定向用例 |
| 首层 | `acceptance/first/` | 四模式、三路实际 RTL；原布局与 S2D 参考、完整输出 |
| 代表层 | `acceptance/layers/` | stage 0/2/4/5/8/10/59/132，四模式、三路；逐字节 legacy 参考及行/Get 闭合 |
| SPAD | `acceptance/spad_03/` | 六组参数、四模式、三路；poison/RAW/零命令/NaN/保护字节；18 项末事务返回前实际 SRAM 写证明 |
| 缓冲 SPAD 对照 | `buffered_spad/` | 同一参数矩阵；末事务返回前无提前重放/实际 SRAM 写 |
| 晚到错误 | `acceptance/fault_final/` | denied/corrupt 各自位于本次命令新产生的部分写之后；无成功完成、sticky fault、模式拒绝、协调复位恢复 |
| 仲裁 | `acceptance/memory/` | 实际生成 mux 的 33-bit 地址、64 sources、source 31、7-bit sink |
| 微基准 | `micro_streaming/`、`micro_buffered/` | C12/N32/P2，stride 12/64 × OPS 1/32 × 四模式 × 三路；完整回读和相同 Get/实际 SRAM 写 |
| B0/B1 | `trace_layers_final/`、`combining_report.json` | 已知 SRAM 快照、真实读/写/命令事件；每 bank 1/2/4/8 项 × age 0/4/8/16/32，逐次读与最终 SRAM 一致、c22 闭合 |
| 诊断 ELF | `firmware/` | 四模式/schema 2、12 帧正式计划；硬件身份、参数头、两份 ELF 和 native/adapted 计划审计 |

微基准周期从首行输入握手至批次信用与 lane 排空，排除 poison/回读；使用固定仿真
内存响应压力，包含指定地址额外 200 周期延迟。它用于相同工作量的局部流水对照，
没有 CPU 提交开销，不能替代板测周期。该计时探针未采样实际 D 字节，结论据此限定。

mode 2 非连续 OPS32 中，三路批次分别为流式 `31842/37196/45146` 周期，
缓冲 `31874/37228/45178` 周期，每批只节省 32 周期。单命令也约节省 32 周期；
本地压力模型下主要降低首条延迟，没有显示明显的持续吞吐改善。这不等于通过了
板上性能验收；两个 Group 原有的跨命令重叠会隐藏许多命令内等待。

代表层沿用真实通道数、权重、步幅、缩放和计划，缩小空间尺寸；没有执行整网。
B1 是固定时间戳的有限窗口机会分析，没有闭环延迟或全网加权证据；B2 投入门槛
未满足，因此保持关闭。A2 继续保留收齐描述符再发读的规则。

`verification.json` 只有在全部必需证据通过且输入哈希一致时才生成
`READY_FOR_BITSTREAM`。完整 Vivado 流程随后使用私有项目，由监督进程依次推进 IP
综合、整机综合、实现和 bitstream；共享资源锁只串行化整机实现。
时序优化按用户安排交由另一工作线，未将其伪记为通过；实际 routed 时序由完整构建
保存。首次完整构建按用户要求监听至综合结束，监督进程继续执行后失败。
本次恢复生成按新要求持续监控至 Bitgen 成功及输入完整性核对结束。

后续下板入口排障已只读识别到 JTAG 下载器和 `xcvu13p_0`，修复记录见
[board/jtag_validation.json](board/jtag_validation.json)；该检查未烧写或启动软件。
综合完成、bitstream 生成、时序满足和板上功能验证分别报告。
