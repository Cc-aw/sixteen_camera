# YOLOv5nu hardware postprocess board validation

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
