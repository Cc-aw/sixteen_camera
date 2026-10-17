# DMA 短请求合并／行组装独立板测

本目录针对 **512 KiB／2 bank** 的三模式 DMA 候选，硬件 build ID 为
`2a95a4ca64390235`。源码、模型、三幅输入、参数头、构建、下载和日志解析均在
本目录内；可整目录复制使用，构建不读取其他功能目录或 Git。复制来源及原始
文件 SHA256 记录在 `SOURCE_ORIGINS.json`，当前构建身份见 `build/manifest.json`。

本包修复整网诊断的 PPU 帧编号回退：每次提交从同一会话序列分配新的 run，
不会在切换 DMA 模式、executor、预热、正式轮次或分段诊断时重置。
frame/version 溢出会明确失败，保留原有 stale、slot、generation 和完整输出校验。
仅修改软件，继续使用原比特流，不需要重新综合或实现。

当前比特流已经生成，但 **setup 时序未通过**：SoC 最坏 WNS 为 −1.467 ns，
DDR UI 最坏 WNS 为 −0.837 ns。原首层板测三模式输出通过；原整网还出现过
一次 legacy 并行输出差异，不能用本次编号修复宣称该问题已解决。
独立包整网主测量已有板测数据，完整套件仍未通过，离线测试不能代替板测。

2026-10-17 的 `logs/model_fix_01/` 已验证编号连续：legacy 基准、单路、三路及
read_coalesced 单路走完 1～48；随后 read_coalesced 三路预热的 frame 2、lane 2、
image 2、slot 0 出现 10 处 PPU 输出差异。没有旧的状态 2，尚未开始正式测量或
read_assembled 整网测试。该次数值错误仍未定位，不能仅凭现有证据归因于新 DMA
逻辑或时序。原日志、软件 manifest 与失败分析保存在该 RUN 内。

后续诊断 ELF 的 BUILD 增加 `failure_diagnostics=1`。发现输出不同时，会打印
每个差异的 expected/actual、结果数量，以及失败批次三 lane 的 DMA 计数和
HOST 边界，再停止并保留 FAIL；报告与计数读取均在工作负载计时结束后。
`PPU_DIFF` 的 word 0～39 是结果字，word 40 是检测数量，完整比较范围不缩减。
最终 FAIL 的 frame/lane 指向首个错误帧。最新板测未触发失败分支，差异报告路径
目前只有离线故障注入验证。

2026-10-17 的 `logs/model_fix_02/` 使用软件 build ID
`948445d3346117461547e176546768ad5fe06b6fab07727324eb85ff9fab2f7c`。
主测量完成 run 1～660，并输出三模式四轮汇总；随后在 read_coalesced 分段诊断
期间断电，没有最终 PASS。串口还缺少 read_coalesced 第 2 轮（从 0 编号）
串行／并行两个正式窗口。该日志未出现 FAIL／TRAP／PPU_DIFF，但不能记为套件通过。

| 模式 | 串行 ms/帧 | 三路并行 ms/帧（吞吐摊销） | 并行加速比 |
| --- | ---: | ---: | ---: |
| legacy | 92.536 | 36.339 | 2.546× |
| read_coalesced | 96.647 | 36.968 | 2.614× |
| read_assembled | 79.262 | 31.253 | 2.536× |

按 100MHz、每模式／executor 共 48 帧计算。legacy 与联合组装的四轮正式记录
齐全，联合组装并行收益为 1.163×，每帧摊销减少 5.085ms；并行数不是单帧延迟。
计数器显示 Get、TL 返回字节、SPAD DMA 写分别减少 40.791%、30.212%、59.625%，
不代表 DDR 实测流量。完整原始日志和部分分析保存在该 RUN 内；缺日志、断电、
已有偶发错误和未满足时序仍阻止完整验收。默认继续保持 legacy。

## 当前默认：每项 12 帧短测

首层和整网都按每种硬件模式、每种 executor **正式测量 12 帧**，串行／三路并行
使用相同输入和比较范围。并行三 lane 各 4 帧；每项正式计时前另外预热 3 帧。
整网先用 legacy direct 跑 12 帧建立 PPU 基准，不计入正式周期。
默认跳过之前的逐阶段扫描，成功时只输出逐帧完成、批次周期和 DMA 计数；失败时
仍保留全部逐字差异、计数快照和 HOST 边界。首层每窗口完整比较 3,686,400 B。

| 硬件 | 正式测量 | 额外整网基准／预热 | 整网 PPU 提交总数 |
| --- | ---: | ---: | ---: |
| 当前三模式比特流 | 3 模式 × 2 executor × 12 = 72 帧 | 12 + 18 = 30 帧 | 102 |
| 后续四模式比特流 | 4 模式 × 2 executor × 12 = 96 帧 | 12 + 24 = 36 帧 | 132 |

新日志是 `schema=2`，整网为 `firmware_revision=3,suite=short_ablation`。
固定模式 ID：0=legacy、1=read_coalesced、2=read_assembled、3=spad_assembled。
前三项沿用原含义；第四项关闭跨逻辑行的 TL 合并，保留命令收集、返回缓冲和 SPAD
行组装，控制变量为“是否跨行合并请求”。它不代表完全绕过分组缓冲的另一种微架构。

**本目录的硬件副本仍是旧三模式**，能力为 `0x10007`，因此当前软件只跑三模式并输出
`ablation=missing_spad_only`，不能据此宣称完成了 SPAD-only 对照。新 RTL 支持能力
`0x1000f`，但本轮只做离线验证，不生成或下载新比特流，也不替换本地硬件身份记录。
未来新候选完成后，需连同比特流、生成上下文和来源清单一起建立匹配的软件包身份。

`make all DMA_ABLATION=1` 可构建要求四模式的固件；旧硬件会明确失败
`dma_spad_only_requires_new_bitstream`。默认 `DMA_ABLATION=0` 接受旧三模式，
可立即用于现有硬件的 12 帧短测。只有 12 帧的一个批次，适合筛查明显收益，不作为
多轮波动分布或长期稳定性结论。吞吐摊销毫秒／帧仍不能当成单帧延迟。

## 文件与两个程序

| 路径 | 内容 |
| --- | --- |
| `src/`、`include/` | 本地诊断入口、PPU 编号、调度、启动及中断代码 |
| `model/` | 固定模型、输入和首层计划；`scripts/prepare.py` 仅从本地生成适配代码 |
| `hardware/` | 本次比特流副本、生成记录、参数头、L2 几何与目标身份 |
| `scripts/`、`program/` | 本地构建审计、UART 分析和下载工具 |
| `tests/` | 完整测试循环的假设备编号回归、溢出及日志破坏检查 |
| `build/yolov5_dma_load_first.elf` | 首层按能力选择三／四模式，各 executor 正式 12 帧 |
| `build/yolov5_dma_load_model.elf` | 整网按能力选择三／四模式，各 executor 正式 12 帧 |

模型、指令计划、布局、Head 地址及数值比较范围保持原诊断契约。首层每窗口比较
完整 3,686,400 B 输出；整网逐帧比较最终 PPU 的数量和 40 个结果字，不宣称所有
中间激活或独立黄金检测精度通过。

## 离线准备

进入本目录，工具路径只在本地 `config.local.mk` 配置。若已配置，保留已有文件。

```bash
cp config.example.mk config.local.mk
# 编辑 CROSS、VIVADO_BIN、OPENOCD_BIN、GDB_BIN、GDB_PYTHONHOME、BOARD_JTAG_SERIAL
make all
make test
make preflight
```

需要 Python 3.10+、host C、RV64GCV／LP64D 工具链、Vivado 2023.2、OpenOCD／GDB；
串口记录使用 `tio`，可配置 `TIO_BIN`。上面命令均不会连接板卡。审计检查两份 ELF
身份、真实模式切换指令、IRQ 不修改 RVV、地址范围和编译依赖均在包内。
修改输入后重新 `make all`；`make check` 检查现有产物是否仍匹配。

`build/`、`logs/`、`config.local.mk` 和 `hardware/*.bit` 不进入 Git。
给别人使用时复制整个目录，并保留比特流和 ELF；只有 Git 源码副本时，还需将
匹配 SHA256 的比特流复制为 `hardware/top_wrapper.bit`。

## 在现有比特流上重测整网

已加载本次 `2a95a4ca64390235` 候选且硬件处于空闲时，直接下载新的整网 ELF。
上次发生 FAIL／TRAP 或中断运行后，先重新下载本包比特流，清除残留状态：

```bash
make program-bitstream RUN=bit_01
```

下载入口与 `l2_1m_4bank` 使用同一套临时 `hw_server` 实现，独立副本保存在本包。
脚本选择空闲本地端口，按 `BOARD_JTAG_SERIAL` 选择开发板，结束或失败后关闭
自己启动的服务。Digilent IPC 兼容库只加载到该服务进程；无需修改系统设置或
`/tmp` 共享文件。`make all` 会构建并审计本包的兼容库。详细诊断保存在同一 RUN
的 `hw_server.log`、`digilent_adept.log` 和 `vivado_program.log`。
`make preflight` 只检查路径和产物，不启动服务或连接开发板。

2026-10-17 修正服务清理：Vivado 的启动脚本还会产生 loader 和实际服务子进程，
仅终止启动 PID 会留下持有 JTAG 的孤儿 `hw_server`，导致下一次出现
`Labtoolstcl 44-494 / may be locked by another hw_server`。现在服务使用独立进程组，
成功、失败或中断后均清理整个所属进程组；不会清理其他用户的服务。
已有残留需先确认其用户、命令行和 RUN 日志后单独停止，不要使用全局 `pkill`。

两个终端均进入本目录。先在终端 A 开始串口记录，115200、8N1、无流控：

```bash
make uart TEST=model RUN=model_01 PORT=/dev/ttyACM0
```

然后在终端 B 下载新软件；这一步不会重新烧写 FPGA：

```bash
make program-model RUN=model_01
```

程序自动运行。整网 BUILD 应有 `schema=2,firmware_revision=3,frames=12`。
`BATCH_BEGIN` 输出模式、executor、当前批次帧数和 `run_before`，RESULT 输出
`run_first/run_last`。当前三模式应出现：

```text
DMAL1,PASS,...,measured_records=6,warmup_records=7,load_modes=3,...,ablation=missing_spad_only,ppu_runs=102
```

未来四模式对应 `measured_records=8,warmup_records=9,load_modes=4`、
`ablation=complete,ppu_runs=132`，无需再执行逐阶段扫描。

仅看到 RESULT 或 SUMMARY 不算完整结束。录制到最终 PASS 后，在终端 A
按 Ctrl+T 再 Q 退出，然后解析：

```bash
make analyze LOG=logs/model_01/model.log
```

解析检查硬件和软件身份、模式回读、全部计数器、每项 12 帧完整输出、编号连续性和
最终 102／132 次提交；拒绝 FAIL、输出差异和截断日志。旧 schema=1 的严格解析仍保留，
不会将旧四轮日志或缺失第四模式的运行冒充为新四模式完整对照。结果与 JSON／文本报告
留在同一个 `logs/<RUN>/`；`scaling` 是串行／三路并行加速比，`serial_gain` 和
`parallel_gain` 是相对 legacy 的收益，大于 1 表示变快。计数器是 Gemmini 总线
口径，不把返回字节直接当成 DDR 流量。

## 首层重测

使用新的 RUN，同样先开串口再下载：

```bash
# 终端 A
make uart TEST=first RUN=first_01 PORT=/dev/ttyACM0
# 终端 B
make program-first RUN=first_01
# 录制到 DMALF1,PASS 并结束串口后
make analyze LOG=logs/first_01/first.log
```

两份 ELF 都按能力位图在同一 bitstream 内切换模式：旧硬件为 legacy、read_coalesced、
read_assembled；未来四模式硬件再加入 spad_assembled，不为各模式分别烧写。下载回执只证明主机执行过下载，不能冒充板上可读的
bitstream SHA256；软件另外核对硬件 build ID。
