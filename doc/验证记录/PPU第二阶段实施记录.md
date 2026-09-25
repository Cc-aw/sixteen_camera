# PPU 第二阶段实施记录

实施依据：[第二阶段方案](../架构设计/sixteen_camera_YOLOv5nu_PPU第二阶段优化实施方案.md)。
起始提交：`60c5cec`。每阶段先通过仿真门禁再进入下一阶段；全部完成后启动整机 bitstream 构建。

## P0：分阶段计数

新增独立 `ppu_perf_counters`，事件先寄存再进入计数器，不反馈到控制 FSM。
MMIO `0x100..0x14c` 保持原义，新增 18 个 32 位只读寄存器，从 `0x150` 连续至 `0x194`：

| 索引 | 名称 | 口径 |
| --- | --- | --- |
| 0 | total | busy 周期 |
| 1 | class_read | Class stream 握手拍数 |
| 2 | class_compute | Class fold 实际推进拍数 |
| 3 | class_stall | Class 输入有效但未 ready |
| 4 | cutoff | histogram cutoff 扫描周期 |
| 5 | dfl_scan | 稀疏位置扫描周期 |
| 6 | dfl_read | DFL stream 握手拍数 |
| 7 | dfl_compute | DFL busy 周期 |
| 8 | sort | 排序阶段周期 |
| 9 | nms | NMS 阶段周期 |
| 10 | result | 结果输出有效周期 |
| 11 | candidates | DFL 启动次数 |
| 12 | hist_clear | histogram 清零周期 |
| 13 | dfl_backpressure | DFL 结果有效且下游未 ready |
| 14 | class_candidates | Class 阈值筛选通过的位置数 |
| 15 | reader_wait | reader busy、下游 ready、输入无效 |
| 16 | reader_command_gap | 等待读命令发出的周期 |
| 17 | max_candidates | reset 以来最大 DFL 候选数 |

计数项可重叠，不能相加作为 total。完成后一个时钟计数收敛；下一次接受命令时清零，最大候选数保留到 reset。串口 `P` 输出 `PPU_PROFILE`。

P0 完整 `run_ai_postprocessor_tests.sh`（含 `run_yolov5nu_postprocess_tests.sh`）通过；单 4×4 固件通过 `-Werror` 构建。

| 仿真输入 | total | class_compute | dfl_compute | sort | nms |
| --- | ---: | ---: | ---: | ---: | ---: |
| image025 Class + 零 DFL 输入 | 73975 | 63000 | 4160 | 53 | 31 |
| 256 候选 | 185405 | 63000 | 106496 | 3347 | 4202 |
| 空候选 | 69662 | 63000 | 0 | 0 | 1 |

上述为 testbench 理想读响应模型，不等同板端耗时。独立 image025 解码、随机 DFL 和 128 图 NMS corpus 同时通过。

## Core 阶段结果

每个下列阶段完整 `run_ai_postprocessor_tests.sh` 均通过，包含 image025、随机 DFL、128 图 NMS corpus、空/密集整链与此前专项测试。详细计数见 [CSV](ppu_phase2_profile.csv)。

| 阶段 | 修改 | 普通用例 total | dense256 total | 100 MHz OOC WNS |
| --- | --- | ---: | ---: | ---: |
| P0 | 计数 | 73975 | 185405 | +1.195 ns |
| P1 | 16B 比较树 | 42479 | 153909 | +0.831 ns |
| P2 | 稳定分桶，独立 NMS | 42541 | 151169 | +0.626 ns |
| P3 | 精确 LUT + 4 级 BBox + 网格扫描状态 | 42581 | 152193 | +0.835 ns |
| P4 | 面积预计算、II=1 IoU 流水 | 42578 | 150176 | +0.830 ns |
| P5 | 4-edge DFL | 39458 | 70304 | +0.836 ns |
| P5 divider | 7 级精确 restoring divider | 38978 | 58016 | +1.563 ns |
| P1.5 | 32B Class 分组流水 | 23230 | 42268 | +0.895 ns |

P2 专项检查 0/1/255/256 候选、同分稳定顺序、IoU 等于/低于/高于阈值及反压。小候选分桶有固定扫描开销，dense256 排序由 3347 降至 606 拍。
P3 比较全部 6300 位置及 256 种 score/signed distance；输出与保留的组合 BBox 参考逐位一致。
P4 dense256 NMS 由 4202 降至 2184 拍，内部增加面积字段，外部 128 位结果 ABI 保持。
P5 每位置 416→104 拍，独立 divider 阶段再降至 56 拍。4096 组除法对照覆盖 nearest-even 舍入与输入空拍。
P1.5 Class fold 31500→15750 拍，理想 reader 无 Class 输入反压；保留 `CLASS_FOLD_BYTES=16` 回退参数。16B 和 32B 均覆盖阈值、同分、全 -128、跨位置边界和输出反压。

`build/ppu_phase2/` 保存原始日志与缓存，不提交。`run_ppu_stage_synthesis.py` 在启动 Vivado 前冻结该阶段 RTL 并记录 SHA，避免后续阶段修改污染综合输入。

## P6 / P6.5：硬件发布与 Head 重叠

缓存中仍可能保留 Gemmini 的脏 Head 数据，因此单看下游 AXI outstanding 不能替代 flush。
新增硬件发布引擎逐缓存行访问实际 L2 Flush64 控制端口（`0x02010200`），只在该行完成应答后推进。
这是把缓存清理和完成确认交给硬件，并非宣称 Head 数据已经绕过缓存。软件不再循环清理 907200 B。
发布引擎与 tensor 写通道按完整写事务仲裁，使用独立 AXI ID；四个 worker/slot bank 记录独立 generation、producer mask、READY mask、fault 和读取所有权。

验证包括：延迟/乱序 B、最后 W 与 B 间隔、全部四 bank 六 Head、generation wrap、abort/error/reset、实际生成的 InclusiveCacheControl 完成语义，以及真实 Head URAM + Local Reader + PPU 集成。
完整 payload 共 14175 条缓存行，仿真在无 CPU flush 下处理 6300 个位置。

P6.5 在六个最终 raw convolution 的 Gemmini fence 后分别发布 Head；Class0 回调提前提交 PPU。
PPU 逐 Head 等待 READY，读到未发布 Head 前暂停；异常先排空 reader，再复位内部流水并返回错误。
软件 slot 增加 producer_complete，防止提前完成的消费者复用仍在生产的 slot。
重叠仿真检查 Class0 已完成而 Class1 尚未发布，并覆盖此边界的 abort。
P6、P6.5 完整回归、单 4×4 ELF 构建和 100 MHz OOC 综合通过。

## P7：描述符 FIFO

独立 `ppu_descriptor_fifo`（深度 4）、`ppu_command_queue`、`ppu_queue_csr`，保存六个地址、worker/slot bank、发布 generation、stream、64 位 frame、frame version、flags。
严格 FIFO 顺序；满时拒绝 doorbell 并累加 rejected，不覆盖旧项。执行期间修改配置寄存器不会改变已入队任务。
硬件完成记录被结果通路接收前不启动下一个任务。软件允许多个 Head slot 同时处于 PROCESSING，并按完成记录的 bank/generation/frame/version 校验归还。
队列专项、实际 URAM 集成、完整回归通过；100 MHz OOC WNS **+9.092 ns**。

## P8：结果 FIFO、结果管理与 Overlay

独立 result capture 将 10 × 128 位结果和任务元数据整体保存，再交给深度 4 的结果 FIFO。
硬件 result manager 按最新期望 stream/frame/version 校验，过期结果只产生观察记录，不更新 Overlay。
正常、零检测和最多 8 框的显示提交直接进入 CPU 时钟域的 Overlay mailbox，复用原有视频 CDC；CPU overlay 配置使用独立 shadow buffer。
四路拼接坐标映射、向下/向上取整、COCO 名称和百分比分数与软件一致。标签覆盖全部 65536 种输入 score、80 类及 unknown。

独立观察 FIFO 深度 4，CPU 不读或 Overlay 慢时逐级反压，绝不覆盖未消费结果。
正常固件仅取完成元数据；逐检测 MMIO 不再位于显示发布路径。串口显示检测数及 `(hardware overlay)`，完整检测仍可通过观察 FIFO 的索引窗口读取。
软件 `AiDetectionResult.flags` 区分硬件已发布、仅元数据、stale；旧 PPU1/非 YOLOv5nu 路径保留原流程。

首次结果路径综合 WNS -1.211 ns，路径为宽结果选择→score 百分比→标签拼接。
将单框选择寄存、score 两级计算、百分比后缀 ROM 与输出保存分开后，100 MHz OOC WNS **+7.419 ns**，使用 **6580 LUT / 4882 FF / 0.5 BRAM36 / 0 DSP / 0 URAM**。
PPU core 最后一次 OOC（P6.5）WNS **+0.969 ns**；发布管理/写仲裁 OOC WNS **+7.665 ns**。
这些是独立综合估计，不代表整机布局布线结果或 300 MHz 验收。

### 新增 CSR（相对 POSTPROCESS_DIAG_BASE）

| 偏移 | 用途 |
| --- | --- |
| 0x1a0 | publication ID `PPU2` |
| 0x1a4 / 0x1a8 / 0x1ac | publication enable / bank / generation |
| 0x1b0 | allocate bit0、manual release bit1、abort bit2、publish mask[13:8] |
| 0x1b4 / 0x1b8 / 0x1bc | slot 状态、producer/READY mask、已分配 generation |
| 0x1d4 / 0x1d8 / 0x1dc | rejected、清理 cycles、清理完成行数 |
| 0x200 / 0x204 | queue enable / enqueue bit0（读回 `PPQ2`） |
| 0x208 | queued[2:0]、admission ready bit5、active bit6、completion bit7 |
| 0x20c / 0x210 / 0x214 / 0x218 / 0x21c | stream / frame lo / frame hi / version / flags |
| 0x220 | descriptor rejected count |
| 0x224..0x230 | 当前执行任务元数据 |
| 0x234 | 写 bit0 更新期望 stream/frame/version（取上述配置值） |
| 0x238 | result path ID `PPR2` |
| 0x240 | observation valid bit0、observation count[5:3]、result count[8:6]、observation enable bit9 |
| 0x244 / 0x248 | 完整观察记录的 32 位 word index（0..48）/ data |
| 0x24c | pop bit0；观察队列空时 bit1=1 关闭观察，bit1=0 开启 |
| 0x250 / 0x254 | bank / count[5:0]、stream[13:10]、status[17:14] |
| 0x258 / 0x25c / 0x260 / 0x264 / 0x268 | frame lo / frame hi / version / core cycles / generation |
| 0x26c / 0x270 | 硬件 Overlay 发布 / stale 或错误记录数 |

Status bit0 为 core/publication error，bit1 为未发布（stale/error）。
完整记录：bits[1279:0] 为 10 个原有 detection ABI，count[1285:1280]、cycles[1343:1312]、status[1375:1344]、bank[1377:1376]、generation[1409:1378]、stream[1413:1410]、frame[1477:1414]、version[1509:1478]、flags[1541:1510]。
队列开启后仍允许在队列空闲时运行原 `0x100` 诊断命令。

### 验证入口

```bash
PPU_TEST_CACHE="$PWD/build/ppu_phase2/cache" scripts/run_ai_postprocessor_tests.sh
scripts/run_ppu_video_tests.sh
bash sw/test/run_ai_ppu_queue_test.sh
python3 scripts/build_single4_video_yolov5nu.py --output sw/build/gemmini_single4_video_ppu_phase2.elf
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source scripts/build_ppu_phase2_bitstream.tcl
```

单 4×4 ELF 独立输出，原双 16 配置不变。板测尚未执行；固定 image025/corpus/live camera 和整机 routed timing 留待新 bitstream 完成后的上板验收。

整机 RTL elaboration 已通过。额外四任务实际 URAM 集成仿真覆盖 worker0/1 的 A/B slot 共 24 个 Head：56700 条缓存行、25200 个 Class 位置，完成次序、frame/generation、零结果 Overlay 和所有权释放一致。
视频控制桥专项覆盖 CPU 连续提交后再接收硬件提交，验证原子 mailbox/CDC；软件 head-slot、队列驱动、postprocess scheduler、batch runtime、stream runtime 测试通过。
新 ELF：`sw/build/gemmini_single4_video_ppu_phase2.elf`，SHA256 `589f6a2e593c176afbc80ee92209b03d7c883438a72541b42143ed92947ad51f`。
下载该文件时显式指定：

```bash
ELF_FILE=sw/build/gemmini_single4_video_ppu_phase2.elf bash scripts/download_single4_video.sh
```

各阶段独立综合资源与 WNS：[综合记录 CSV](ppu_phase2_synthesis.csv)。最后完整回归日志为 `build/ppu_phase2/P8_final.log`，已通过含 legacy 兼容与四任务集成的全部用例。

P6.5 提前启动后，`total/cycles` 包含等待后续 Head READY 的时间；`reader_command_gap` 也会计入该等待。比较纯 core 性能时使用已全部 READY 的固定输入测试，实时流则同时观察各阶段计数与 graph-to-result wall time，不能将生产者等待误判为算法退化。

## 整机构建交接

2026-09-24：`synth_1` 成功完成，已生成 `top_wrapper.dcp`。
完整综合日志为 0 errors、200 critical warnings；这 200 条与上一版 `/tmp/sixteen_nms_bitstream_build.log` 逐行比对全部相同，来自既有视频 AXI 未用通道的重复驱动，没有新增 critical warning。
构建主日志已输出 `PPU_PHASE2_SYNTHESIS=PASS` 和 `PPU_PHASE2_IMPLEMENTATION=STARTED`。
按用户要求，监听至此结束；同一 Vivado 流程继续执行 `impl_1` 至 `write_bitstream`。

日志：`build/ppu_phase2/final/bitstream.console`。
硬件构建源码校验清单：`build/ppu_phase2/final/sources.sha256`（另包含配套固件最终源码）。
原 bitstream 备份：`build/ppu_phase2/final/pre_phase2_top_wrapper.bit`。
本阶段尚未进行板测，也未宣称整机 routed timing 已通过。
