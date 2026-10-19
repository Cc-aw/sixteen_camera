# A1 流式版本验证记录

实验目录为 `build/experiments/dma_load/streaming_20261017/`；实时状态见
[status.json](status.json)。生成来源及所有源码由版本内清单固定，实验结果和 Vivado
缓存保留在忽略的 `build/` 中。生产导出与父版本未替换。

**最终构建结果：功能仿真和综合通过，布线 DRC 失败，未生成比特流。**
构建于北京时间 2026-10-18 15:02 失败退出（UTC `2026-10-18T07:02:12Z`）。
`write_bitstream` 前置 DRC 报 `RTSTAT-1`：以下一条网络未布线，Bitgen 未执行：

```text
u_control_soc/u_rocket/chiptop0/system/tile_prci_domain/element_reset_domain_rockettile/applyOrElse/counters/counterfile/counters_5_reg[16]_i_1_n_17
```

实现日志最后一次物理优化汇总为 WNS `-5.239 ns`，时序也未满足；这不是完整布线
成功或时序收敛的结果。时序优化继续按用户安排由另一工作线处理，本次提交记录失败，
未重启构建。最终状态与日志哈希见 [implementation_failure.json](implementation_failure.json)；
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
保存。用户要求监听至综合结束，其后的实现/bitstream 由监督进程继续推进。

本次没有连接或下载开发板。综合完成、bitstream 生成和时序满足分别报告。
