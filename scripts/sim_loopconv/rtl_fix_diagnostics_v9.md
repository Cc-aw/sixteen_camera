# EX 握手修正与 triple64 诊断 ABI v9

## RTL 修改

当前 overlay 的 ExecuteController 对 A/B/D 分别保存 `sentA/B/D`：每个操作数只允许握手一次，其 SRAM/ACC 响应在该次握手释放；整个 control token 满足所有必要操作数后才出队。首拍操作数仍按已验证实验受 req.ready 门控。保留 TimingResultQueue、写缓冲、futureRows、原有容量、权重复用与 request-retire 条件。

恢复 twoGemmini 的 LoopConv、RS、LD/ST/EX、DMA Reader/Writer、AccumulatorScale 内部诊断；Scale 保留当前 FP16 和 BRAM SiLU，只恢复被动的发射/返回身份、完成 mask、首次异常观测。所有诊断不驱动功能 ready/valid。未开启会丢命令的 debug escape。

## CSR

| 软件 worker / opcode | control | status | select | data |
| --- | --- | --- | --- | --- |
| 0 / custom3 | 0x7d0 | 0x7d1 | 0x7d2 | 0x7d3 |
| 1 / custom2 | 0x7d4 | 0x7d5 | 0x7d6 | 0x7d7 |
| 2 / custom1 | 0x7d8 | 0x7d9 | 0x7da | 0x7db |

control.bit0=冻结，bit1=解除冻结（同时写时 clear 优先）。select 为页号 0–79，越界读 0。status.bit0=frozen，[8:1]=80，[16:9]=9，bit17=automatic。page0=0x4442475f00090050。只有 control/select 的六个 CSR 写被允许绕过 RoCC busy-fence；其他 CSR/指令语义不变。不要在 CSR 读写之间插入等待 Gemmini idle 的 fence。

自动冻结：入口持续阻塞达 2^26 拍，或者 outstanding 非零且 command 展开/接受/退休/RS completion 连续 2^26 拍无进展。100MHz 约 0.671 秒。自动冻结仅保存现场，不清除任务。已自动冻结时软件不要再次手动冻结，以免覆盖首次现场。Scale 首次异常 sticky 仅硬件 reset 清除，外层 clear 不清它。

若 CPU 已阻塞在无法返回的 RoCC 指令，自动快照仍会保存，但本接口不会丢弃指令来让 CPU 返回；软件可运行的 credit 超时路径能直接读取。仿真也可直接查看 CSR 输出。

## 页表

原 ABI v8 的 1–63 页保留布局；未使用的 RS entry 页可能为零。

| 页 | 含义 |
| --- | --- |
| 1–9 | LoopConv 两个 slot、请求序号、五个子生成器、started/completed、utilization |
| 10–29 | RS issue/completion、entry 生命周期和占用 |
| 30–37 | DMA Reader/Writer 事务和总线握手 |
| 38–41 | Scale 活性、entry、发射/完成元素数 |
| 42 | EX/LD/ST 到 RS 的 completion 仲裁 |
| 43–47 | 请求计数、busy、入口及命令链 |
| 48–51 | LD/ST/EX 详细阻塞与身份 |
| 52 | EX/LD/ST/仲裁出口最后 tag 和低 8 位 completion 计数 |
| 53–58 | RS 被阻塞 entry 的身份和完整依赖 mask |
| 59–63 | Scale head fired/completed mask、首次异常 reason/tag/lane mask/cycle |
| 64 | [63:48]futureRows、[47:32]results.count、[31:24]receivedRows、[23:16]rowIndex、[15:8]completionId；bit6 completionPending、5 writeback_idle、4 selectedReady、3 capturedValid、2 reserve、1 releaseRows非零、0 issuePermit |
| 65 | [31:24]writes.count、[23:16]writeTags头ROB；bit14/13/12 sentA/B/D，11/10/9 dataA/B/D_valid，8 first，7/6/5 a/b/d_fire，4 control出队，3 writeTags有效，2 writes有效，1 writes可出队，0 results有效 |
| 66 | 高32位 mesh last次数；低32位 writes last出队次数 |
| 67 | 高32位写回完成次数；低32位EX全部completion次数 |
| 68 | 从高到低各8位：write_norm/scale/issue 队列数量、scaleInput数量、scaleOutput数量、mvinWriteBuffer数量、zeroWriteBuffer数量；低8位中的bit5/4为scaleInput入/出，3/2为scaleOutput入/出，1 writer接收请求，0 writeback_idle |
| 69 | [47:32]EX pending bank mask，[31:16]SPAD read hazard，[15:0]ACC read hazard |
| 70 | 高32位Scale输入接受次数；低32位Scale输出消费次数 |
| 71 | 高32位DMA read响应次数；低32位DMA write响应次数 |
| 72 | 高32位Controller无进展周期；低32位原LoopConv status |
| 73–74 | 完整64位accepted/retired计数 |
| 75 | bit9/8派生流水输入/输出valid；bit7..4 slot1的deriving/pending/configured/running；bit3..0 slot0同字段 |
| 76–77 | LD/ST DMA tracker：[63:48]valid mask、[47:40]首个有效slot ID、[39:32]ROB tag、[31:8]bytes_left；bit6 busy、5 alloc.valid、4 alloc.ready、3 returned.valid、2 completion.valid、1 completion.ready、0 completion.fire |
| 78–79 | 保留，零 |

tracker valid mask 为零或相关队列 valid=0 时，对应 payload/tag 字段无意义。计数均允许自然回绕。

定位顺序：页1–9识别最后 slot 缺哪类完成 → 页53–58查具体ROB依赖 → 页48–51/76–77看控制器与tracker → 页64–71定位新增流水；若ST等Scale，查38–41及59–63。

## 生成与运行

源仍来自本项目 overlay，同步到 `/tmp/npu100-video-chipyard` 后通过 TaihangSoC 生成；原 `/home/wzr/chipyard` 不改。生成脚本验证后自动导出到 `generated/soc/...PackedInference100MHzConfig/gen-collateral`，旧输出放在 `generated/soc-backups`。

用户自行构建比特流（必须重新综合，不复用旧 DCP）：

```bash
env -u RESUME_SYNTH_DCP bash scripts/build_triple64_video_bitstream.sh
```

新比特流烧入后，可编译带诊断的独立测试 ELF（旧比特流不要使用此开关）：

```bash
STANDALONE_INTERNAL_DIAGNOSTICS=1 bash scripts/build_gemmini_standalone.sh
```

输出目录后缀为 `_diag9`，不会覆盖原无内部CSR读取版本。credit/busy超时时自动打印80页；保持原k等测试命令。本次不启动比特流构建或下板。

保存串口输出后，可运行 `python3 scripts/sim_loopconv/decode_internal_snapshot.py uart.log`，列出 slot 未完成子任务、LD/ST 剩余字节、EX 写回等待与 Scale 异常。下载新诊断 ELF 时同样传 `STANDALONE_INTERNAL_DIAGNOSTICS=1` 给 `scripts/download_gemmini_standalone.sh`；本轮仅构建，没有执行下载。

Scale 首次异常页61的 reason 位：[0]仲裁→arbOut身份/valid不一致，[1]固定延迟流水输出不一致，[2]返回owner/index/issued异常，[3]completion事件未落入mask，[4]issue事件未落入mask，[5]全部发射后超期仍缺完成。诊断只报告观察到的违例，必须结合页59/60/62/63解读。

## 本轮验证记录

- Scala 编译、100MHz triple64 配置检查通过；LazyRoCC replay 六个场景通过。
- 新 Taihang RTL 展开/生成、三 worker 结构、FBus ID 分组、比特流预检查通过。
- 当前全部 Gemmini Scala 文件哈希与导出 EFFECTIVE_SCALA.sha256 一致。
- 新生成 RTL 小卷积：1,280 输出正确；首 tile 在 8/0 和 100/13 内存延迟/反压条件下各 8,192 输出正确，逐级 SRAM/mesh/ACC 检查通过。
- 仿真检查 80 页快照在 busy=1 时冻结后不变、clear 恢复、越界读零；注入达到阈值的入口诊断 sideband 验证自动冻结和 sticky，不修改功能命令。
- 小卷积、首 tile 和完整卷积均无 Scale first-fault。完整卷积 150 个任务全部退休，1,228,800 输出逐元素正确，无漏写/重复写（build/sim_loopconv/480_gemmini.log）。
- 带 ABI9 超时导出的独立 ELF 已编译到 sw/build/gemmini_standalone_diag9/test.elf，没有下载。

日志在 build/sim_loopconv，生成日志保存在 /tmp/npu_diag_generate5.log。仿真为单 Gemmini 完整数据路径加模拟 TileLink 内存，尚不等于三 worker/视频并发板测或布局布线时序验证。

## 2026-09-29 布线结果补充

用户随后执行完整比特流构建，运行目录为 `build/bitstream_0918_video/20260929_111031_2957439`。
综合和布局完成，但 18:33 因 `0918 Default route is not legal` 退出，没有生成 bit。
布线报告为 17,984 条网络资源冲突、13,067 处节点重叠；WNS=-6.155ns，TNS=-75756.734ns。
与前次成功出 bit 的布局报告相比，LUT 从 1,146,840 增至 1,188,272，SLR2 LUT 占用从 62.61% 增至 81.40%。
新增集中快照和逐 lane 检查是拥塞的重要嫌疑，但尚未通过关闭诊断的对照构建确认唯一归因。
本提交保存该功能修复与诊断基线，不代表时序收敛或可成功出 bit；后续应缩减、分散诊断并重新评估物理实现。
