# AI postprocessor P1A read path

P1A connects a 33-bit, 256-bit AXI reader to the Taihang coherent FBus. The
existing preprocessor writer and the new reader use independent AXI write and
read channels through `axi4_channel_join`.

The diagnostic register bank is visible to the CPU at `0x1017_0000` and has
the following 32-bit registers:

| Offset | Name | Description |
| --- | --- | --- |
| `0x00` | ID | `0x50504431` (`PPD1`) |
| `0x04` | CAPABILITY | Revision and 32-byte beat capability |
| `0x08` | CONTROL | bit 0 start, bit 1 clear done |
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

The reader accepts unaligned buffers, splits bursts at 4 KiB boundaries and
supports downstream backpressure. The diagnostic folds one byte per clock so
its CRC does not create a 32-byte combinational path.

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
