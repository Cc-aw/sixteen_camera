# Gemmini 短读合并和 SPAD 行组装验证

日期：2026-10-17。功能回归、代表层请求闭合、OOC 和完整芯片综合通过，bitstream 已生成，但完整布局布线 setup 时序未通过。首层板测通过；独立软件包的最新整网运行完成了主测量，随后在分段诊断期间由用户断电，日志还缺失两个正式窗口，不能记为完整板测 PASS。默认保持 `legacy`。

方案及完整操作入口见 [架构文档](../architecture/gemmini-dma-load-coalescing.md)。

## 候选身份

- 独立输出根：`build/experiments/dma_load/512kib_2bank_runtime_20261016/`。
- RTL：`candidate/gen-collateral/`；来源：`candidate/GENERATION_CONTEXT.json`。
- 硬件构建标识：`2a95a4ca64390235`，frontend 查询 10 可读。
- S1 L2：512 KiB、2 bank、512 set/bank、8 way、64B line，MPV3 ABI 1.1。
- 三个真实 DIM32 Gemmini，共享原 Reader/source 分配器和原缩放器。
- 同一份 RTL 支持三种运行时模式：`legacy / read_coalesced / read_assembled`，复位默认 `legacy`。
- 原生产 `hw/soc` 导出未替换。其他构建标识的原型结果不计入本候选验收。

## 已通过的功能检查

| 检查 | 结果与范围 | 实验目录 |
| --- | --- | --- |
| 独立参考及日志分析器 | 7 项 Python 测试；合成日志不作为板测 | `tests/model/dma_load/` |
| 读计划 RTL | 3,520 组 C/N/64B 余数组合、区域末端及高地址旁路 | `final_units_03/` |
| 行组装 RTL | 650 组宽度/行数/重复数/半区组合、poison、尾部及反压 | `final_units_03/` |
| 分组与 Reader RTL | 两上下文、10 个混合命令、ID 复用、乱序返回、高地址位、denied/corrupt、无 owner 错误 | `final_units_03/` |
| 有序 bank 队列 | 1,600 周期独立顺序账本；部分 mask、EX/DMA/零写、RAW/WAW、非空排空观测 | `final_units_03/` |
| 计数器与模式控制 | external ID8～34、snapshot 释放；三模式往返、能力/身份回读、busy/fault/非法值/所有权/竞争拒绝 | `final_units_03/` |
| 原始首层 | 三 lane、三模式，比较 9,216B；16×16 缩小空间、真实权重/FP16/SiLU，完整输出与 legacy 及等价 folded 计算一致；另检查 matmul、HOST、ACK、IRQ | `final_first/` |
| 代表层 | stage 0、2、4、5、8、10、59、132，三模式×三 lane，72 项完整输出比较与逐行请求/Get 闭合 | `final_layers/` |
| 参数化真实 SPAD | 六参数×三模式×三 lane，54 项，比较 53,856B；零填充、poison、RAW、非单位缩放、饱和及 NaN | `final_spad/` |
| 真实错误恢复 | denied/corrupt 均保持 busy/fault，不产生 DONE，拒绝切换；协调复位后重新完成装载回读 | `final_fault_02/` |
| 候选内存 mux | 33 位地址、64 个 ID、source31 冲突、多拍、反压和零延迟 | `final_memory/` |
| 原 frontend 回归 | engine/cluster/memory 与冻结 v5 逐周期等价 | `build/sim/command_frontend/equivalence/` |
| 统一验收入口 | 显式候选路径、源码身份、真实 RTL 闭包、全部功能与日志哈希复核通过 | `final_acceptance/` |
| 诊断固件 | 首层及整网 ELF 编译、身份/指令审计、下载前离线检查通过 | `build/firmware/dma-load-2bank/` |

参数化回归最初在 legacy 首次非单位缩放时遇到 X 状态，根因为 Chisel `RRArbiter` 有意不复位的 `lastGrant` 没有仿真初值。最终参数回归启用生成器自带的 `RANDOMIZE_REG_INIT`；只提供仿真初值，不修改综合 RTL 或强制有效状态。

## 实际操作量

下表为独立 mvin→FP16 scale→SPAD→mvout 回归中的每 lane 计数。包含目标区域的 poison 初始化和独立零填充，不代表完整首层或整网周期。

| C / N / P / stride / scale | SRAM 写：legacy / 合并读 / 联合组装 | DMA Get：legacy / 合并读 / 联合组装 |
| --- | --- | --- |
| 3 / 32 / 6 / 3 / 1 | 255 / 243 / 83 | 73 / 42 / 42 |
| 1 / 2 / 32 / 1 / 1 | 163 / 163 / 101 | 37 / 37 / 37 |
| 8 / 32 / 4 / 8 / 2 | 189 / 173 / 77 | 73 / 42 / 42 |
| 12 / 32 / 2 / 12 / 1 | 115 / 103 / 71 | 73 / 42 / 42 |
| 16 / 32 / 2 / 16 / 2 | 119 / 103 / 71 | 75 / 44 / 44 |
| 12 / 3 / 2 / 32 / NaN | 20 / 20 / 13 | 11 / 11 / 11 |

SRAM 写从真实 bank fire 按并行 bank 求和；Get 从 Gemmini TL A 握手计数，不含 frontend 取表。未选中字节及全部目标输出均检查。NaN 有效样本与 legacy 比较，真实零填充独立检查为零。

## 独立时序

Vivado 2023.2，VU13P `-2-i`，时钟 10ns，输入/输出延迟各 1ns，运行时模式端口保持可变。

| 模块 | WNS/ns | WHS/ns | WPWS/ns |
| --- | ---: | ---: | ---: |
| DmaLoadGroup | 0.699 | 0.022 | 4.468 |
| DmaLoadRowAssembler | 1.427 | 0.049 | 4.468 |
| StreamReader | 3.070 | 0.041 | 4.468 |

三个模块 setup/hold/pulse 失败端点均为零，报告位于 `final_ooc/<模块>/timing.rpt`。下文完整芯片布局布线结果仍有 setup 失败，模块 OOC 通过不能代替整机时序通过。

完整芯片综合 `synth_1=100%`，0 errors、0 critical warnings；checkpoint SHA256 为 `a46fb2bbe6658e5254f5b16ee48ae7ce9c8557f9d25f2f38524a068000af1774`。823 个候选 RTL 文件在交付时再次核验，报告确认三组 Group 和三组 Assembler 均保留，输入哈希没有漂移。机器记录见 [验证 JSON](gemmini-dma-load-coalescing.json)。

综合后资源为 935,672 LUT、897,100 FF、995 RAMB36、949 RAMB18、372 URAM、3,029 DSP。未布局布线的时序估计为 WNS=-1.142ns、WHS=-4.615ns、WPWS=-0.139ns；最终 routed 结果见下文。

## 代表层实际读取

各模式保持相同的逻辑行、地址、权重及通道 tiling。下表为每 lane 的实际 Gemmini DMA Get，已经扣除 frontend 取表；返回字节按采集到的地址及请求大小预测，经 Get 数闭合校准，不是 DDR 实测字节。

| stage | Get：legacy / 合并读 / 联合组装 | 返回字节：legacy / 合并读 / 联合组装 |
| --- | --- | --- |
| 0 | 380 / 86 / 86 | 12,672 / 3,840 / 3,840 |
| 2 | 164 / 152 / 152 | 5,376 / 5,120 / 5,120 |
| 4、5 | 52 / 28 / 28 | 1,792 / 1,280 / 1,280 |
| 8 | 36 / 12 / 12 | 1,280 / 768 / 768 |
| 10 | 164 / 44 / 44 | 5,376 / 2,816 / 2,816 |
| 59 | 6,940 / 6,940 / 6,940 | 296,576 / 296,576 / 296,576 |
| 132 | 3,476 / 3,476 / 3,476 | 148,608 / 148,608 / 148,608 |

空间尺寸缩小，以上是功能及访存结构验证，不是完整尺寸逐层性能或整网板测加速比。

## 完整构建与最终时序

完整流程于北京时间 2026-10-16 22:53 启动，2026-10-17 09:43 完成。
`bitstream/state.json` 为 `phase=COMPLETE`、`build_state=BITSTREAM_TIMING_UNMET`，
Vivado 退出码为 0。实际生成 `bitstream/dma_load_512kib_2bank.bit`，
大小为 113,318,492 B，SHA256 为
`e930cc0674b0f8756a5e7ecb63aa9d769d824cdca068911d0f180ef3a2efd25c`。

最终 routed WNS=-1.467ns、WHS=0.001ns、WPWS=0.039ns，setup 失败端点
59,075 个，hold/pulse 失败端点均为零。SoC 100MHz 最坏路径位于 L2
`mshrs_28/w_pprobeack_reg` 到 `sourceD/s3_bypass_data_REG_1_reg[126]`；
DDR UI 时钟域最坏 WNS=-0.837ns。成功写出 bitstream 不代表硬件时序通过，
也不能据此排除板测中偶发数值错误与时序有关。

原生产 `hw/soc` 的 1 MiB／4 bank 导出没有替换，本候选仍为私有实验。
完整时序报告留在实验目录；本记录及 JSON 保存构建身份、最终状态和结果哈希。

## 首层与整网板测

首层原始 UART 为 `tests/log/dma_load_first.log`，包含终止 PASS、24 个正式
窗口，每种模式／executor 四轮共 12 帧，完整输出比较通过。legacy 串行／并行
分别为 28,633,286／10,091,916 周期，联合组装为 12,381,065／4,317,150 周期。
联合组装相对 legacy 的串行／并行收益分别为 2.313×／2.338×，
联合组装自身的三路并行加速比为 2.868×。

整网使用 [`sw/board_tests/dma_load_512kib_2bank/`](../../sw/board_tests/dma_load_512kib_2bank/README.md)
独立包。该包修复跨模式、预热和轮次复用 PPU frame/version 的问题，保持单会话
run 单调递增，完整流程预期 894 次 PPU 提交。下载脚本采用独立临时 hw_server，
保留目标序列号选择、局部 Digilent IPC 兼容和失败日志；不改系统 IPC 文件。

最新 `logs/model_fix_02/model.log` 对应软件 build ID
`948445d3346117461547e176546768ad5fe06b6fab07727324eb85ff9fab2f7c`，
硬件身份及 ELF 下载凭据匹配。主测量走完 run 1～660，三模式 SUMMARY 已输出；
legacy 分段诊断完成 26 对，read_coalesced 完成 20 对后断电。没有终止 PASS，
也没有 FAIL/TRAP/PPU_DIFF；日志中另缺失 read_coalesced 第 2 轮（从 0 编号）的
串行／并行两个正式窗口，因此仅有 22／24 个正式详细窗口。

以下是固件输出的四轮 SUMMARY；每个模式／executor 共 48 帧，按 100MHz 换算。
“并行 ms/帧”是总批次耗时除以总帧数，属于吞吐摊销，不能当作单帧延迟。
legacy 和联合组装的八个正式窗口各自齐全，详细周期之和与 SUMMARY 一致；
read_coalesced SUMMARY 有四轮，但详细记录只能复核其中三轮。

| 模式 | 串行周期 | 并行周期 | 串行 ms/帧 | 并行 ms/帧 | 三路并行加速比 |
| --- | ---: | ---: | ---: | ---: | ---: |
| legacy | 444,170,772 | 174,425,365 | 92.536 | 36.339 | 2.546× |
| read_coalesced | 463,906,439 | 177,448,390 | 96.647 | 36.968 | 2.614× |
| read_assembled | 380,458,596 | 150,014,982 | 79.262 | 31.253 | 2.536× |

联合组装整网串行收益 1.167×，并行收益 1.163×；并行每帧摊销减少
5.085ms（耗时降低 13.995%）。单独合并读的并行耗时增加 1.733%。
legacy／联合组装并行轮间极差分别约 0.389%／0.412%。

按可完整复核的并行正式窗口、三 lane 求和后除以帧数：

| 模式 | 可复核帧数 | Get/帧 | 实际 TL D 返回 B/帧 | SPAD DMA 写/帧 |
| --- | ---: | ---: | ---: | ---: |
| legacy | 48 | 1,087,678 | 42,351,968 | 3,135,706 |
| read_coalesced | 36 | 643,998 | 29,556,736 | 3,073,906 |
| read_assembled | 48 | 643,998 | 29,556,736 | 1,266,034 |

联合组装 Get 减少 40.791%，TL 返回字节减少 30.212%，SPAD DMA 写减少
59.625%。合并读与联合组装的读取量相同，整网加速主要与减少 SPAD 写操作相伴；
这些是 Gemmini TL/SPAD 计数，不能直接称为 DDR 实测流量。
输出正确性范围为相对内部 legacy direct 基准的最终 PPU 结果，未证明每个
中间激活或独立黄金检测精度。完整摘要、原日志哈希和缺口见
[板测记录 JSON](gemmini-dma-load-coalescing-board.json)。

## 已知失败与提交前检查

原共享诊断出现过 legacy 并行数值差异，以及跨模式编号回退引起的 PPU 状态 2。
独立包 `model_fix_01` 编号 1～60 连续，仍在 read_coalesced 并行预热的
frame 2／lane 2／image 2／slot 0 出现 10 处结果差异，未进入正式测量。
编号修复不等于偶发数值错误已经修复。后续 ELF 增加逐字 expected/actual、
首个错误 frame/lane、失败批次计数和 HOST 边界打印，保留完整比较及 FAIL。
最新不完整运行没有复现错误，仍不足以关闭该问题。

提交前重新运行 `make check`、独立包 `make test check preflight`、
`python3 -B -m unittest discover -s tests/model/dma_load -p 'test_*.py'`：
生产清单检查通过，独立包 17 项测试、native/adapted 计划等价、ELF 审计和离线
下载检查通过，参考／日志测试 7 项通过。这些检查没有连接开发板。
完整 RTL/OOC 结果为本文件上表所列的先前实际运行，本次提交未重新执行长回归。

尚待完整串口记录的整网套件通过、偶发数值错误定位、全芯片时序收敛，以及
视频/Tensor 并发压力系统验收。候选默认保持 `legacy`。
