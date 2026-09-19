# AI postprocessor P1A read path

## Head URAM migration P1: standalone storage and local reader

`head_uram_store.sv` implements one 1 MiB Head slot as a 256-bit simple
dual-port memory with UltraRAM inference and byte write enables. Its write
port is the future P2 AXI-router boundary; its independent synchronous read
port can sustain one 256-bit response per clock. Storage contents are not
reset, and the existing software-owned A/B slot protocol remains responsible
for preventing simultaneous producer writes and consumer reads.

`head_local_reader.sv` converts the unchanged physical `base_addr` and byte
count descriptor into the ordered stream contract already consumed by PPU1.
It uses the low 20 address bits only after an external bank selector chooses
the A/B/worker slot. It supports unaligned first and last beats, downstream
backpressure, zero-byte commands, slot-boundary checking, and one local beat
per clock when the consumer stays ready. P1 is standalone and is not yet
connected to the SoC memory AXI or PPU reader mux; Head traffic therefore
still uses DDR in the production design.

The standalone regression is part of
`scripts/run_ai_postprocessor_tests.sh`. Run
`vivado -mode batch -source scripts/check_head_uram_p1_synthesis.tcl` to
verify that a production-size slot infers exactly 32 URAM288 primitives and
meets the standalone 100 MHz synthesis timing gate.

## Head URAM migration P2: standalone AXI router

`axi4_head_uram_router.sv` owns four P1 stores for worker0/1 A/B. It decodes
the unchanged `0x32000000`, `0x32100000`, `0x32400000`, and `0x32500000`
physical windows and their bit31 CPU aliases. Head writes terminate locally
with byte strobes preserved; Head AXI reads return the same URAM contents.
Traffic outside those four 1 MiB slots, including the diagnostic gaps, is
forwarded to DDR without changing its AXI address, ID, attributes, data, or
response.

The router holds a target for the complete AW/W/B or AR/R transaction,
supports FIXED and INCR bursts up to 256 beats, and rejects a Head request
that is oversized, wrapped, or crosses a slot boundary. The separate local
read port is reserved for P3 and arbitrates against AXI Head reads. P2 remains
standalone: the production `soc_mem_axi` still connects directly to DDR and
the PPU still reads Head payload through FBus.

Run `vivado -mode batch -source scripts/check_head_uram_p2_synthesis.tcl`
to synthesize the production four-bank router and require exactly 128
URAM288 primitives plus positive standalone 100 MHz setup slack.

## Head URAM migration P3: production shadow and selectable local read

The production memory subsystem now inserts the router between `soc_mem_axi`
and DDR S00 with `SHADOW_DDR=1`. A legal Head write beat is accepted only
when both DDR and the selected URAM bank accept it. DDR remains populated and
its B response remains authoritative, so it is a live fallback rather than a
stale copy. Non-Head traffic and all AXI reads continue to DDR unchanged.

PPU1 instantiates `head_local_reader` beside the original FBus reader. The
source is latched at the start of a complete PPU command and cannot change
between its six tensors. Local URAM is the reset default. MMIO offset `0x148`
bit 0 selects the next command (`1` local, `0` FBus) only while PPU and both
readers are idle; read bits 0/1/2/3 report enable, active source, local busy,
and local error. This preserves the existing six-address descriptor ABI and
A/B ownership protocol while providing an immediate DDR/FBus fallback.
Run `vivado -mode batch -source scripts/check_head_uram_p3_synthesis.tcl`
to enforce the 128-URAM and 100 MHz gates with shadow mode enabled.

P1A connects a 33-bit, 256-bit AXI reader to the Taihang coherent FBus. The
existing preprocessor writer and the new reader use independent AXI write and
read channels through `axi4_channel_join`.

The diagnostic register bank is visible to the CPU at `0x1017_0000` and has
the following 32-bit registers:

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | ID | `0x50504431` (`PPD1`) |
| `0x04` | CAPABILITY | `0x00202205`: P1C-3 runtime burst sweep revision |
| `0x08` | CONTROL | bit 0 start, bit 1 clear done, bit 2 platform-rate CRC |
| `0x0c` | STATUS | bit 0 busy, bit 1 done, bit 2 read error |
| `0x10` | ADDR_LO | Tensor address bits 31:0 |
| `0x14` | ADDR_HI | Tensor address bit 32 |
| `0x18` | BYTES | Requested byte count |
| `0x1c` | CRC32 | Reflected CRC32 result |
| `0x20` | BYTE_SUM | Unsigned sum of tensor bytes |
| `0x24` | NONZERO | Number of nonzero bytes |
| `0x28` | BYTES_READ | Accepted payload bytes |
| `0x2c` | AR_REQUESTS | AXI read bursts issued |
| `0x30` | READ_BEATS | AXI read beats accepted |
| `0x34` | COMPLETIONS | Completed commands |
| `0x38` | ERRORS | Commands with an AXI protocol/response error |
| `0x3c` | ERROR_FLAGS | bit 0 RRESP, bit 1 RID, bit 2 RLAST |
| `0x40` | ACTIVE_CYCLES | Reader cycles from request planning through drain |
| `0x44` | AR_STALL_CYCLES | Cycles with ARVALID and no ARREADY |
| `0x48` | R_WAIT_CYCLES | Cycles ready for R data with no RVALID |
| `0x4c` | R_BACKPRESSURE | Cycles with RVALID and no RREADY |
| `0x50` | MAX_OUTSTANDING | Maximum number of issued, unfinished bursts |
| `0x54` | MAX_REORDER | Maximum number of allocated reorder slots |
| `0x58` | ACTIVE_ID_MASK | AXI IDs used by the current command |
| `0x5c` | BURST_BEATS | Maximum beats per burst; writable while idle, default 128 |

The reader accepts unaligned buffers, splits bursts at 4 KiB boundaries and
supports downstream backpressure. Eight AXI IDs own eight 4 KiB response
slots. Responses may complete across IDs in any order; a 32 KiB block-RAM
reorder store releases them in request order. The diagnostic folds one byte
per clock so its CRC does not create a 32-byte combinational path.

P1C adds a platform-rate mode which folds each 256-bit AXI beat as four
64-bit chunks. This matches the physical 64-bit FBus behind the width adapter
without putting a 256-bit CRC network on one clock path. The reader may keep
eight bursts outstanding to hide FBus/TileLink request latency. The
byte-serial mode remains available for P1A/P1B diagnostics.

The 2026-09-11 baseline board run passed all 256 correctness iterations but
measured only 118 MB/s. `MAX_OUTSTANDING` reached 2. P1C-2 now uses all eight
external AXI IDs and restores response order in the slot RAM. The regenerated
SoC keeps two physical AXI ID groups and expands the TileLink source field from
4 to 7 bits, providing 32 read sources per group and 64 total. See
[`doc/验证记录/AI_Postprocessor_P1C_Board_Validation.md`](../../../doc/验证记录/AI_Postprocessor_P1C_Board_Validation.md)
for the baseline log, calculations and board acceptance gate.

Descriptors contain device/MIG physical addresses. The diagnostic adds the
Rocket bit31 DDR alias when issuing coherent FBus reads.

Run `scripts/run_ai_postprocessor_tests.sh` for the fixed-point reference,
channel join, reader and AXI-Lite diagnostic simulations. On hardware, the
console `p` command produces a CH1 tensor and compares hardware CRC, byte sum,
nonzero count and byte count against the CPU view before recycling the arena.
The console `v` command runs 1000 producer/consumer ordering checks while
alternating and rewriting two unaligned buffers. It fences CPU stores before
each descriptor doorbell and reports the first stale or partial read.
The TinyYOLOv2 runtime also fences every completed Gemmini store and compares
the final INT8 tensor's CPU CRC against a coherent hardware readback. The `s`
command reports cumulative checks, mismatches and AXI error flags.
With the AI runtime enabled, the console `w` command reads 256 copies of a
2,116,800-byte YOLOv5-sized tensor in full-rate mode while preprocess and both
Gemmini workers continue running. It reports decimal MB/s, burst efficiency,
AR stalls, R waits, consumer backpressure, CRC mismatches, timeouts, AXI
errors, expected/observed CRC, maximum outstanding bursts, and observed
preprocess/Gemmini overlap. The current 64-bit, 100 MHz FBus platform gate is
600 MB/s for the eight-channel runtime. The final 16-channel product gate
remains 1,200 MB/s and requires widening or accelerating FBus because this
platform's theoretical payload ceiling is 800 MB/s. The final line also
reports the runtime `valid_mask`; `0x0000ffff` is required for later
16-channel signoff. A board populated with the current eight local cameras
normally reports `0x000000ff`.

The console `W` command runs a short burst-size sweep at 64, 128, 256, 512,
1024, 2048, and 4096 bytes. Each point verifies the same tensor CRC and prints
bandwidth, stalls, outstanding depth, reorder occupancy, and ID coverage. The
lowercase `w` command remains the 4096-byte, 256-iteration platform gate.

## YOLOv5nu compute frontend

`yolov5nu_class_reducer.sv` is the first production-model compute block. It
consumes the board-validated location-major `6300 x 80` INT8 sigmoid score
tensor, folds all 32 bytes of each 256-bit beat in eight four-byte cycles,
preserves the lowest class ID
on ties, and emits one best-class record per location. The frozen 0.25 score
threshold maps to raw INT8 score 34 for tensor scale 0.007530334406.

Run `scripts/run_yolov5nu_postprocess_tests.sh`. The regression transposes the
frozen hardware-aware image025 corpus into the exact board layout and compares
all 6300 positions under input bubbles and output backpressure. The expected
candidate count is 10, matching the board self-test.

## YOLOv5nu production postprocessor (PPU1)

The currently wired production path starts at the **six raw Gemmini INT8
heads** in each worker's A/B Head Slot. It reads three 80-byte/location class
heads and three 64-byte/location DFL heads from the URAM Local Reader by
default, with the existing FBus reader retained as a command-level fallback.
Model-generated ROMs perform per-head requantization and class
sigmoid; class reduction retains the first class on a tie. Candidate DFL
softmax preserves INT8 probability quantization before the 16-weight dot
product. Fixed-point box conversion feeds a streaming Top-256, stable
descending sort, class-aware IoU > 0.45 NMS, and a 10-entry result RAM.
The score threshold is raw 34 (0.25 in the model ABI); coordinates are in
the model's 640x480 input image, with Q15 scores. CPUs still schedule the
two Gemmini workers, flush the six raw heads from L2, submit one descriptor
at a time, and publish the final detection records. They skip software
head stages 165/166, Decode and NMS when PPU1 is present. The old bitstream
continues using its previous CPU fallback.

The new registers are in the existing postprocessor MMIO window, alongside
the unchanged 0x00..0x5c diagnostic. All offsets below are relative to
`POSTPROCESS_DIAG_BASE`:

| Offset | Meaning |
| --- | --- |
| 0x100 | read `0x50505531` (PPU1); write bit 0 to start |
| 0x104, 0x108, 0x10c | class raw head addresses, counts 4800/1200/300 |
| 0x110, 0x114, 0x118 | DFL raw head addresses, counts 4800/1200/300 |
| 0x11c | status: busy bit 0, done bit 1, error bit 2, reader busy bit 3 |
| 0x120, 0x124 | result index (write), result count (read) |
| 0x128..0x134 | selected 128-bit candidate, four little-endian words |
| 0x138, 0x13c, 0x140, 0x144 | class positions, threshold candidates, NMS candidates, cycles |
| 0x148 | reader select/status: bit 0 enable, bit 1 active, bit 2 local busy, bit 3 local error |

One 128-bit candidate is `{28'b0, location[12:0], class[6:0],
score_q15[15:0], y_max[15:0], x_max[15:0], y_min[15:0], x_min[15:0]}`.
Reader sharing is serialized at descriptor boundaries; a competing diagnostic
read completes before the PPU acquires the reader.

To prepare for the board test, run `./scripts/run_ai_postprocessor_tests.sh`
and `make -C sw` (ELF: `sw/build/hdmi_tx_test.elf`), then regenerate the
bitstream from `prj/sixteen_camera.xpr` using the updated HDL sources. The
startup line announces `hardware postprocess`; the first eight completed
jobs print `AI PPU worker/status/count/positions/candidates/nms/cycles`.
Expected successful status is `0x00000002`, positions `6300`, and hardware
candidate/NMS counts equal for each job. Image025's frozen post-DFL reference
has ten threshold candidates and a dog of class 23 at location 6155.

The local regression also tests the full raw-class stream and DFL units,
48 randomized DFL locations against the model's float32 reference,
image025's post-DFL dog bbox/NMS, and two six-descriptor MMIO/FBus jobs
(one empty, one positive dog-class candidate). RTL
elaboration is checked by `scripts/check_postprocess_elaboration.tcl`.
For the 100 MHz postprocessor-only synthesis timing gate, run
`vivado -mode batch -source scripts/check_yolov5nu_postprocess_synthesis.tcl`.
On the target VU13P, the standalone 100 MHz synthesized postprocessor has
worst setup slack +1.812 ns. This estimate is before full SoC placement.
Implementation timing and actual camera results require the new bitstream
and board validation. The measured 112 MB/s P1C FBus throughput remains the
separate bandwidth TODO; this functional release does not claim the eventual
16-channel 480-frame/s throughput target.
