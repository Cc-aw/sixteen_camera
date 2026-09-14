# YOLOv5nu hardware postprocess board validation

> 当前状态（2026-09-14）：新版 FBus 已上板。软件调度与 arena 对齐修复后，
> 小写 w 完成 256/256 次，CRC/timeout/AXI 均为零，pre/job=2/12，
> 实测 351 MB/s @100 MHz，600 MB/s Gate 仍未通过。最终 2 ms 目标按
> 未来 300 MHz 验收。完整日志与待办见文末更新及 P1C 文档第 13 节。


Board: current dual-Gemmini VU13P design, 100 MHz SoC clock. The default
firmware uses the PPU1 hardware path when the postprocessor ID is present.

## Live camera run

After enabling AI input, the first eight PPU jobs all completed with status
`0x00000002`, `positions=6300`, and equal class-candidate/NMS-candidate
counts. One job reported eight candidates and one final detection. A later
`s` snapshot showed 103 batches, 518 submitted/completed/published jobs,
`stale/err=0/0`, and a CH2 box with class 61 and score 0.610. The HDMI video
appeared normal. An earlier isolated `0x00000006` PPU error has not recurred
in this 518-job run; its underlying cause remains unknown. The firmware's
former `timeout` message for a completed error job was a polling bug and has
been corrected.

## Fixed image025 comparison

With AI runtime disabled, UART command `T` runs the fixed image025 through
Gemmini once per sample, then processes the same six raw INT8 heads first with
PPU1 and then with the existing CPU fallback. It repeats three times. The
test checks PPU status, all 6300 positions, ten threshold/NMS candidates, and
the single dog detection against the software reference. All three samples
passed with score 0.858.

| Measurement | Three-sample average at 100 MHz |
| --- | ---: |
| PPU core | 529,974 cycles / 5.30 ms |
| Hardware postprocess wall time (flush + MMIO + PPU + result read) | 782,503 cycles / 7.83 ms |
| Existing CPU postprocess path | 14,754,504 cycles / 147.55 ms |
| CPU / hardware wall-time ratio | 18.86x |

The common Gemmini graph averaged 19,597,208 cycles (195.97 ms). Including
that graph, the static-image path is about 203.80 ms with PPU1 versus 343.52
ms with the CPU path, or 1.69x overall. The software fallback also computes
diagnostic checksums, so 18.86x describes the current deployed paths rather
than a pure algorithm-only speedup.

These runs establish functional operation at this board setup. Full-SoC
timing closure remains open: the routed report has WNS -8.973 ns. The measured
FBus bandwidth and the final 16-channel throughput target remain separate
work items.

## FBus optimization candidate (2026-09-12, historical pre-board state)

The current source candidate widens FBus to 256 bits, preserves 32 AXI ID
groups, reserves ID 31 for preprocess writes, and decouples 31 read IDs from
64 reorder slots. The diagnostic statistics snapshot fix is included.
Full-tensor controlled simulations reach 799 MB/s without concurrent writes
and 691 MB/s with fair arbitration and concurrent writes; an unfair
highest-source-priority stress model reaches only 559 MB/s. These are not
board measurements or a full DDR/Gemmini simulation. No new bitstream has
been generated. Configuration, validation conditions and reproduction commands
are recorded in [the P1C validation log, section 11](AI_Postprocessor_P1C_Board_Validation.md#11-fbus-加宽动态-id-与读写分组隔离当前候选待用户生成比特流).

The 600 MB/s bandwidth gate alone does not establish 2 ms postprocessing:
reading all 2,116,800 bytes at that rate takes 3.528 ms. A 2 ms full-read
budget requires at least 1.0584 GB/s before any non-overlapped work.


## 当前板端状态（2026-09-14）

FBus 256-bit、31 个读 ID 与独立写 ID 的版本已由用户上板。软件更新曾因
arena 仅保证 16 B 对齐，改变链接布局后导致 PPU status=0x06；现已在运行
源码和生成脚本中显式保证 64 B 对齐，保留带宽调度修复。

最新小写 w：64 B burst，256/256 次完整完成，exit=1，busy_retries=808；
CRC/timeout/AXI 均为零，pre/job=2/12，max_outstanding=28、reorder=51、
ID mask=0x7FFFFFFF，rbp=0，带宽 **351 MB/s @100 MHz**。调度已恢复，
**600 MB/s Gate 仍未通过**。测试窗口的任务完成数不证明逐事务 DMA 重叠。

修复前重建对照 ELF 的大写 T 三次 PASS；当前对齐修复版尚待大写 T 的
独立复验，不能将对照版结果作为当前版验收。小写 t 不覆盖硬件 PPU。
下一步先复验 T，再增加独占/并发读取对照，定位下游仲裁与返回等待。
最终 2 ms 目标以未来 300 MHz 为准；100 MHz 周期数的等比例折算仅为估计。

完整原始日志、结果解释及下一步记录在
[AI Postprocessor P1C 板测文档第 13 节](AI_Postprocessor_P1C_Board_Validation.md)。
