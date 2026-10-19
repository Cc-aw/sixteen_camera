# DMA/SPAD 按逻辑行就绪的流式重放版本

本版本以 [dma_load_512kib_2bank](../dma_load_512kib_2bank/README.md) 为固定父版本，
保存实际源码副本，按[流水优化与写合并方案](../../../docs/architecture/gemmini-dma-load-streaming-and-write-combining.md)
实施。父版本及生产 `hw/soc/` 导出保持独立。父版本是四模式源码基线，不代表新四模式候选已经完成整合验收。

A1 保留整命令描述符收集和两个 1 KiB 上下文，使用字节有效位判断 head 下一行是否
就绪。后部事务返回与前部逻辑行恢复、缩放和 SPAD 写入可以重叠。实际事务结束标记
随 Reader 返回队列传递，终止信用同时检查事务排空、全部行重放及下游最终写 token。
晚到错误允许留下部分写入，但阻止整命令成功完成，保持 fault/busy 至协调复位。

硬件规格保持 512 KiB / 2 bank S1 L2、三路 DIM32、原 Reader/source 额度与 bank 仲裁。
运行时模式 0/1/2/3 分别为 legacy、read_coalesced、read_assembled、spad_assembled，
复位默认 legacy；能力仍为 `0x1000f`。流水是独立 elaboration 参数
`dma_load_streaming_enable`，不占用运行时模式。A2 和跨命令写合并尚未启用；
后者必须先通过真实 trace 与有限窗口分析的投入门槛。全芯片时序优化由另一工作线负责。

| 路径 | 内容 |
| --- | --- |
| [soc_shell/](soc_shell/) | 本版 Gemmini、Rocket/L2、MPV3 和视频 shell |
| [command_frontend/](command_frontend/) | 本版前端及最终 Configs.scala 覆盖 |
| [tensor_ingress/](tensor_ingress/) | 本版 TensorIngress 副本 |
| [scripts/build_soc.py](scripts/build_soc.py) | 私有工作区准备与完整 SoC RTL 生成 |
| [scripts/run_dma_load_tests.py](scripts/run_dma_load_tests.py) | 重编译全部本地 Gemmini 源码、组/Reader/流式单元及真实候选整合回归 |
| [tests/](tests/) | 本版测试台与 SPAD runner；其余公共整合测试复用仓库 |
| [manifests/SOURCE_ORIGINS.json](manifests/SOURCE_ORIGINS.json) | 父版本、每个文件的父版本及本地 SHA256 |
| [manifests/artifacts.json](manifests/artifacts.json) | 配置、父版本和历史产物追溯 |
| [validation/status.json](validation/status.json) | 当前实现及实际验证状态 |

从本目录执行：

```sh
make check
make test
make prepare SOC_REFERENCE=/home/wzr/chipyard WORKSPACE=/tmp/dma_streaming_chipyard
make resume WORKSPACE=/tmp/dma_streaming_chipyard CANDIDATE_OUTPUT=<新的候选目录>
make check-rtl DMA_CONTEXT=<候选目录>/GENERATION_CONTEXT.json
make test-unit WORKSPACE=<带依赖的工作区> DMA_OUTPUT=<新的结果目录>
make test-rtl WORKSPACE=<生成候选的工作区> DMA_CONTEXT=<候选目录>/GENERATION_CONTEXT.json DMA_OUTPUT=<新的结果目录>
```

后续修改位于本目录的 DmaLoadGroup.scala、DMA.scala、Scratchpad.scala 及对应测试。
审核修改后用 `python3 -B scripts/refresh_origins.py` 更新开发版本清单，再执行检查。
完整 SoC 编译使用本地 shell/frontend/TensorIngress，不读取父目录或公共源码作为覆盖。
单元编译包括新的 DMA/bundle 定义及调用者，防止旧依赖 jar 掩盖接口变化。

实验输出放入 `build/experiments/dma_load/streaming_<run>/`。功能仿真全部通过后再生成
比特流；不以旧候选或源码单元 PASS 替代新候选验收。生成 bitstream 与时序满足分别记录。
现有旧三模式 bitstream 及软件身份 `2a95a4ca64390235` 只用于历史对照。

软件诊断位于 [software/](software/)，从已修复 PPU run 编号的独立包复制，保留四模式
能力检查、每项正式 12 帧和 schema=2 日志。`make firmware RUN_DIR=<实验目录>` 使用
新上下文构建并审计两份 ELF；此步骤不需要已有 bitstream，也不访问开发板。
软件参数头逐字节核对本候选生成头，模型及参考计划继续冻结。

`make soc ... SOC_BUFFERED=1` 或生成器的 `--buffered` 在相同 Scala/配置上关闭 A1，
用于保持相同四模式、Get、D 字节和写入工作量的流水对照，输出必须用独立目录。

B0/B1 可用 `tests/test_layers.py --trace --rtl <RTL> --output <新目录>` 采集真实访问。
探针只存在于仿真测试台：明确初始化 SRAM 并保存完整起始快照，记录 bank 接受与
物理提交、读意图与读数据、单调命令身份、信用和排空边界；按 c22 闭合真实写数。
`scripts/analyze_combining.py` 扫描每 bank 1/2/4/8 项和 0/4/8/16/32 周期，验证
每次读取、命令账本及最终 SRAM。当前分析是有限窗口机会模型，未建模闭环延迟，
紧凑层不能替代全网加权证据；不满足投入门槛时维持 `DEFER_B2`。

整体功能证据与软件审计齐全后，`make verify-functional` 生成构建门禁；
`make bitstream` 必须先经过此门禁，才调用仓库监督式 Vivado 构建入口。
时序检查由用户指定的另一工作线负责，门禁明确记录 `DELEGATED_BY_USER`，
不伪造 OOC PASS；整机实现仍保存实际 routed 时序及是否满足约束的结果。
