# 微基准验证证据（2026-10-17）

离线阶段的范围与记录如下；后续取得的两轮板测另见文末。没有生成新比特流。

`continuous_rtl.json`／`strided_rtl.json` 与对应 `.txt` 是实际旧候选
`2a95a4ca64390235` 的三模式、三 lane 真实 Gemmini 仿真，合计 18 项、20,160 B
完整输出比较通过。`*_runner.json` 记录原始测试模板和临时派生 runner 的 SHA256。
只覆盖 case0：C=12、N=32、P=2、scale=1、地址对齐，stride 分别为 12／64。
派生 runner 仅修改测试参数和源偏移，没有修改候选 RTL 或生产导出。

这些 RTL bench 的原始计数包含 35 行 SPAD poison 初始化和额外两行零装载，
用于同时检查部分 mask、RAW 和零写。不能将其原始计数直接当成小 ELF 的计时窗口。
从 Get 扣除 35 次 poison 读取，从 SPAD 写扣除 35 次 poison 写以及零装载的
4 次（legacy/read_coalesced）或 3 次（read_assembled），得到小 ELF 对应操作量：

| 用例 | Get：legacy／coalesced／assembled | SPAD 写：legacy／coalesced／assembled |
| --- | --- | --- |
| stride=12 | 36／6／6 | 72／64／33 |
| stride=64 | 32／32／32 | 64／64／33 |

完整小 ELF 的周期仍须上板读取。host 假设备只用于真实 C 套件循环、故障注入和
严格日志校验，明确标记 hardware=0，不能当成性能证据。纯 C 数值参考另与 Python
独立的原始重复写模型逐字节比较，覆盖对齐／非对齐、正负缩放、舍入和饱和。

`offline.json` 记录初始 `OPS=1` ELF 身份、大小、命令及验证摘要。
默认值改为 `OPS=32` 后的 ELF 身份和 5 项 host 回归／下载预检结果另记在
`ops32_offline.json`；该参数更新没有重跑 RTL 或下载板卡。原始单命令 RTL 证据
保持原覆盖范围，不作为 32 条命令批次的 RTL 或性能验收。
本目录为验证产物，
不参与 ELF 的源码身份计算，避免记录自身 ELF 哈希形成循环依赖。

## 现有三模式候选板测

`OPS=1`、`OPS=32` 两轮均在硬件 `2a95a4ca64390235`、lane 0 上通过。
每轮各 72 个正式样本、18 个预热样本，完整日志顺序、批末 1,120 B 输出、
源数据、保护区及全批计数均通过严格解析。硬件和几何相同，默认参数仅改变 OPS。

| 用例／模式 | OPS=1 周期/条 | OPS=32 摊销周期/条 | OPS=32 相对 legacy 耗时 |
| --- | ---: | ---: | --- |
| continuous / legacy | 222.167 | 80.529 | 基准 |
| continuous / read_coalesced | 262.083 | 76.844 | 减少 4.576% |
| continuous / read_assembled | 229.167 | 60.323 | 减少 25.091% |
| strided / legacy | 211.083 | 68.367 | 基准 |
| strided / read_coalesced | 211.917 | 68.406 | 增加 0.057% |
| strided / read_assembled | 276.250 | 89.109 | 增加 30.339% |

连续批次联合模式吞吐为 legacy 的 1.335 倍，在同一 Group 读合并路径上加入
组装另减少 21.499% 耗时。非连续用例每条 Get 都为 32，SPAD 写从 64 降到 33，
但 Group 加组装的净收益仍为负。该实验不能解释为独立 RowAssembler 硬件性能。

`board_runs.json` 保存两轮解析、软件／硬件身份、ELF 下载回执和对照；
`evidence/ops1_board.txt`、`evidence/ops32_board.txt` 保存 UART 内容，仅将 CRLF
规范为 LF，原始与归档 SHA256 分别记录。OPS32 每批重复同一源和目的地址，
检查的是批末输出及全部命令计数，没有逐条回读中间写入。
这不是整网或 DDR 实测，亦不验收新增第四模式。原候选 setup 时序问题仍未关闭。
