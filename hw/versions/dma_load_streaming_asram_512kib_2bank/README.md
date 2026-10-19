# DMA Stream A1 + 三路私有 activation SRAM

从 `activation_sram_512kib_2bank` 的完整快照派生，合入
`dma_load_streaming_512kib_2bank` 的 A1 按行就绪重放。两个父版本保持独立。
本目录保存完整 shell/frontend/TensorIngress、ASRAM、布局与生成源码。
实际执行状态见 [validation/status.json](validation/status.json)，不继承父版本 PASS。

规格：三路 DIM32，100 MHz，512 KiB / 2 bank L2；每路 2.25 MiB、72 URAM
私有存储。地址、服务入口、保留窗口与父 ASRAM 版一致，来自
`manifests/activation_sram.json`。运行时四模式和默认 legacy 不变。
`DMA_LOAD_STREAMING` 是独立生成参数；`SOC_BUFFERED=1` 生成 A1 关闭对照。
A2 与跨命令写合并没有启用。

核心合并位于 `DmaLoadGroup.scala`、`DMA.scala`、`Scratchpad.scala` 和三个 worker
的配置传递。保留本地地址合法性、物理事务排空、最终信用保护及晚到错误语义。
错误后可以留下部分 SPAD 写，但不能发布成功完成或复用受影响上下文。

对应独立软件位于 [sw/board_tests/dma_load_streaming_asram_512kib_2bank](../../../sw/board_tests/dma_load_streaming_asram_512kib_2bank/README.md)。
生成 RTL、仿真结果与所有缓存放在私有输出，不替换 `hw/soc/`。

```sh
make check test-prepare test-software test-physical
make prepare SOC_REFERENCE=<Chipyard快照> WORKSPACE=<新目录>
make resume WORKSPACE=<准备好的目录> CANDIDATE_OUTPUT=<新输出目录>
make test-unit WORKSPACE=<依赖工作区> DMA_OUTPUT=<新输出目录>
make test-rtl WORKSPACE=<生成工作区> DMA_CONTEXT=<本版GENERATION_CONTEXT.json> DMA_OUTPUT=<新输出目录>
```

仿真必须分别报告源单元、真实 TL、URAM 原语、生成候选与三路 Gemmini 计算覆盖；
host 假设备不是 CPU/RVV 或整网 RTL 推理。布局以 ASRAM 已布线方案为起点，保留
三路 ASRAM 的 216 个原语、Head SLR2 及计算阵列 SLR0/1/3。负时序只记录，
不增加 bitstream 前的时序阻断。本阶段不构建 bitstream、不访问开发板。

联合测试入口：`make test-asram` 和 `make test-asram-fault`，显式传入
`DMA_CONTEXT=<本版上下文>`、`DMA_OUTPUT=<新结果目录>`。覆盖四种 DMA 模式、
三路、六组宽度/重复/缩放参数，以及 DDR、local、本地读/DDR 写、DDR 读/本地写。
真实 ASRAM 的初始化与结果检查都通过独立 service TL 端口，不以 DDR 字节数组代替。
测试内的地址选择和 D 仲裁仅是仿真连接；整机实际路由另由生成拓扑和范围审计验证。

`make simulation-inputs` 从对应软件包自己的冻结模型生成首层输入工作区，
`test-first` 自动使用它；代表层可传 `--native <对应软件包/model>`。
公共包只提供测试/计划生成工具，模型和固件构建不读取其他功能目录。
代表层的 `--memory-latency 1` 只缩短测试 DDR 返回延迟，不改变形状、权重、命令、
数据或比较范围；反压、延迟末事务和错误注入仍由独立的联合/源单元用例覆盖。
这些周期不能作为硬件性能结果。

合并时还限制了 Group/RowAssembler 内部动态移位的位宽：32 字节窗口之外的移位
显式饱和，避免生成 65,568～131,310 位的中间信号。覆盖全部 C=1～32 和合法 P
的 2,975 个行组装用例；数学和物理请求语义保持。

最终汇总严格证据，输出 `validation/simulation.json`：

```sh
make verify-simulation DMA_CONTEXT=<主候选上下文> \
  BUFFERED_CONTEXT=<同源码的A1关闭上下文> SIM_EVIDENCE_MAP=<结果映射JSON>
```

bitstream 入口要求该记录匹配候选身份；它是功能门禁，仍不设置 write_bitstream
前的负时序阻断。完整覆盖与实际结果见 [验证记录](validation/README.md)。
