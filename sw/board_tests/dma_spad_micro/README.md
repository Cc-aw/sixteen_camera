# DMA / SPAD 小 ELF：连续与非连续短行对照

复用当前候选 `2a95a4ca64390235` 的三模式 bitstream，不需要新增硬件模式。
本目录自带源码、配置、纯软件参考、构建、下载、解析和来源记录；不读取其他功能目录，
不包含网络模型或权重。当前默认加载内容约 6.4 KiB；带调试信息 ELF 约 57.3 KiB。
本工具不生成或烧写 bitstream，只下载软件。原候选 setup 时序未通过的问题仍保留。

同一个 ELF 默认执行两类测试，各模式使用相同的逻辑输入、缩放和 SPAD 初值：

| 用例 | 默认参数 | 目的 |
| --- | --- | --- |
| continuous | C=12 B，N=32，P=2，stride=12 B，scale=1 | 联合读合并与行组装 |
| strided | C=12 B，N=32，P=2，stride=64 B，scale=1 | 无跨行合并时，Group + RowAssembler 的净收益 |

每类依次对比 legacy、read_coalesced、read_assembled，每个模式正式测量 12 次、
预热 3 次。相邻轮次反转模式顺序，降低固定顺序影响。默认 lane 0、`OPS=32`：
每个样本连续提交 32 个完整 N 行 mvin，然后统一等待 lane 排空；命令之间不插入
CPU 等待。因此共 72 个正式样本（2,304 个 mvin）、18 个预热样本（576 个 mvin），
不执行完整网络或阶段扫描。
这份微基准测单 lane 装载性能，整网串行／三路并行测试仍使用原独立包。

## 构建与离线验证

工具路径在本目录的 `config.local.mk` 配置，示例见 `config.example.mk`。

```bash
cd sw/board_tests/dma_spad_micro
make all C=12 N=32 P=2 STRIDE=64 SCALE=1 OPS=32
make test preflight
```

输出 `build/dma_spad_micro.elf`，RV64GC／LP64D，入口 0x82000000。
不用 RVV 或模型数学库。所有编译依赖审计为本目录文件，工具链系统头除外。
`make preflight` 只检查 ELF、工具与配置，不打开 JTAG。

可选参数：

| 参数 | 默认 | 含义 |
| --- | ---: | --- |
| C / N / P | 12 / 32 / 2 | 输入行字节数、行数、PixelRepeater 重复数；C×P≤32 |
| STRIDE | 64 | 非连续用例的步长，必须大于 C；连续用例始终 stride=C |
| SCALE | 1 | mvin scale，编译时量化为有限 FP16，精确 bits 记录在 manifest / 日志 |
| OFFSET | 0 | 源地址在 64 B 边界内的偏移，用来检查跨 32／64 B 碎片 |
| OPS | 32 | 每个计时窗口连续提交多少个相同 mvin 命令 |
| SAMPLES / WARMUPS | 12 / 3 | 每类／模式的正式与预热样本数 |
| LANE | 0 | 单独测试哪个 Gemmini，允许 0、1、2 |

默认测 32 条命令的批次吞吐，以摊薄每批固定提交／排空轮询开销。若要复测单命令延迟：

```bash
make test OPS=1
```

每模式仍是 12 个正式样本。参数会进入源码／编译身份，改变参数必须重新构建；
使用非默认值后，后续 `make program OPS=1` 也传入同样参数，防止下载错版本。
程序默认将板上 build ID 与本地硬件来源记录严格核对。

## 周期与计数边界

每个样本按以下顺序执行：

1. 切换模式并确认空闲；将目标区域、前后保护行初始化为 0xA5。
2. 配置测试的 stride／scale／P，等待配置完成，清零计数器。
3. 读 rdcycle，连续提交 OPS 个完整 N 行 mvin，等到 lane 完全排空，再读 rdcycle。
4. 采集 external ID8～34，然后 mvout 回读完整目标区域、掩码未选中字节和保护行。
5. 对照原始逐行／逐重复的独立软件参考，检查所有输出字节、源输入与 CPU 缓冲 canary；
   检查逻辑行／字节、Get32／Get64、实际 D 字节、SPAD DMA 写次数等，最后输出 UART。

初始化、配置、计数读取、mvout、参考计算和 UART **均不在周期窗口内**。
记录的是完整批次的 CPU 提交至空闲周期，包括命令提交／空闲轮询开销；
不是只测最后一次写，也不是 CPU 本地循环时间或单独的 SRAM 端口延迟。
真实 Get 和 SPAD 写在 mvin 窗口内计数，不混入 poison 初始化或回读。

默认每个 mvin 的预期操作量如下；每个 `OPS=32` 计时窗口的计数为表中数值乘 32。
这些是操作量，不是预先承诺的周期收益：

| 用例／模式 | Get 数 | TL 返回 B | SPAD DMA 写 |
| --- | ---: | ---: | ---: |
| continuous / legacy | 36 | 1,280 | 72 |
| continuous / read_coalesced | 6 | 384 | 64 |
| continuous / read_assembled | 6 | 384 | 33 |
| strided / legacy | 32 | 1,024 | 64 |
| strided / read_coalesced | 32 | 1,024 | 64 |
| strided / read_assembled | 32 | 1,024 | 33 |

非连续用例里 read_coalesced 不满足资格，走 legacy 路径；read_assembled 仍使用
Group + RowAssembler，逐行读而不跨行合并。若其完整批次周期明显更低，就说明行组装
的收益足以覆盖本实现的 Group 收集、缓存和重放成本。即使更快，也不能将结果写成
完全独立的 RowAssembler 硬件性能。若计数下降但周期未改善，也如实保留结果。
TL 返回量不是 DDR 实测流量；微基准周期也不能直接外推整网加速比。

## 手动上板

先由操作者确保已加载上述候选 bitstream，且没有其他固件持有 Gemmini。
两个终端进入本目录：

```bash
# 终端 A：先开始录制
make uart RUN=micro_ops32_01 PORT=/dev/ttyACM0

# 终端 B：下载并启动小 ELF，不重新烧写 FPGA
make program RUN=micro_ops32_01
```

等到 `SPADM1,PASS,measured_records=72,warmup_records=18,...`，在终端 A
按 Ctrl+T 再 Q 结束串口，然后：

```bash
make analyze LOG=logs/micro_ops32_01/micro.log
```

JSON／文本报告在同一 RUN 中，包含完整批次周期、每操作均值／中位数／极值、相对
legacy 的收益和实际 Get／SPAD 写次数。解析器拒绝缺失／重复样本、错误计数、错误
模式语义、截断日志或不匹配的软件／硬件身份。host 假设备的周期标记 hardware=0，
默认不能当作板测日志解析。源码和数值测试通过不等于已取得板测性能。

本轮 BUILD 应有 `ops=32,samples=12,warmups=3`。RESULT 的 `cycles` 是完整 32 条
命令的批次周期；报告的 `cycles/op`、Get/op 和 SPAD writes/op 均已除以 32。
每批命令使用同一源和目的区域，批末回读最终完整输出；计数器另检查全部 32 条命令
的操作量。此前 `OPS=1` 的 `logs/micro_01/` 记录作为单命令基准保留，使用新的 RUN
采集本轮结果。
