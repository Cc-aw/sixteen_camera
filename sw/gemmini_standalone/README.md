# Standalone triple64 Gemmini diagnostic

Build: `bash scripts/build_gemmini_standalone.sh`
Download: `bash scripts/download_gemmini_standalone.sh`
Build and download: `bash scripts/download_gemmini_standalone.sh --build`
Check without connecting: `bash scripts/download_gemmini_standalone.sh --check`

ELF: `sw/build/gemmini_standalone/test.elf`; entry at 0x82000000.
Uses the generated DIM64 parameters, 0918 software ABI, existing bare-metal
startup and 100 MHz/115200 UART. No video initialization, YOLO weights/runtime,
PPU, HDMI driver, or vendor BSP is linked. Existing autonomous FPGA video
logic is not disabled by this ELF.

After a stalled accelerator, reprogram the same bitstream before downloading
this ELF to ensure a fresh accelerator state. No new bitstream is required.

UART keys:
- `0`, `1`, `2`: one worker's DDR/scratchpad DMA round trip, followed by a
  weight-stationary 64x64 signed-int8 matrix multiplication checked against a
  CPU reference for every element.
- `a`: run those basic tests sequentially on all three workers.
- `c`, `d`, `e`: independently test the response-producing counter-reset
  instruction (funct 126) for workers 0, 1, 2. Basic tests do not use counters.
- `h`: help.

Worker opcode mapping: custom3/custom2/custom1; busy CSRs: 7c2/7c3/7ca.
Each operation prints BEGIN/RETURNED. RETURNED means instruction submission
returned, not that DMA/compute completed. Busy polling and a fence precede
result checking. Busy polling has a 10-second timeout; a CPU stalled inside
an instruction/fence cannot execute that software timeout. Commands are
synchronous. After a stall or timeout, reset before retrying. Trap output
includes cause, PC and tval. Keep the last complete log to identify the step.

This is a basic serial hardware diagnostic, not a LoopConv, RVV, concurrent
workers, model accuracy or full video inference test. Compile/download checks
are performed on the host; PASS requires running on the board.

## v2: counters and first-layer-shaped convolution

- `C` / `D` / `E`: reset, configure the same six events as the video firmware,
  snapshot and read counters for workers 0/1/2. PASS means commands returned;
  it does not certify event counts under load.
- `f` / `g` / `j`: small convolution for workers 0/1/2: 16x20x3 to 8x10x16.
- `k` / `l` / `m`: full-size convolution: 480x640x3 to 240x320x16.

Both convolution sizes use the first YOLO layer's kernel 6, stride 2,
input/kernel dilation 1, padding 2, output channels 16, no pooling, WS, and
SILU_LUT hardware mode. Inputs, sparse weights, biases and LUT are synthetic:
scale is 1 and the test LUT maps signed x to x/2, not the model's actual SiLU
quantization. Every output is checked against an independent sparse CPU
reference. This validates the LUT lookup path without conflating model data
and quantization. It does not yet run real YOLO weights or RVV operators.

Credit admission and per-worker CSR mappings match video firmware. A 10-second
credit timeout prints status and halts; it does not bypass credit protection.
ROCC_SUBMIT prints the first 64 commands and then every 256th (before issue).
Instrumentation changes command pacing, so passing this test is not proof of
normal-speed concurrent inference or timing closure.

Suggested order: `C`, `f`, `k`, then `D`, `g`, `l`, then `E`, `j`, `m`.
Download the rebuilt ELF with the existing download script. The banner must
say v2. Send the last log if any step fails or stops making progress.

## v3: remove command trace blind spot

The v2 trace stopped printing every command after count 0x40. That final line
alone did not identify the stalled instruction. v3 prints ROCC_SUBMIT and
ROCC_RETURN for every instruction while convolution tracing is enabled, plus
CREDIT_GRANTED and INTERNAL_FENCE_BEGIN/DONE. SUBMIT is before instruction
issue, RETURN is after it. A new optional no-op-by-default return hook in the
0918 ABI header enables this instrumentation only for the standalone image.
The existing credit timeout remains enabled. The increased UART output slows
submission; compare behavior with v2 rather than treating success as proof of
normal-speed operation. Reprogram the same bitstream after a stall, download
v3, repeat f then k, and retain the final log lines.

## v4: single-outstanding comparison and progress snapshots

A board run of k timed out with status 0x0a11 (busy, four outstanding,
queue count two, running-slot count two, cannot submit). This is an admission
wait timeout, not proof that the final RoCC instruction failed to return.

Both v4 ELFs preserve the same buffers, convolution and oracle. The serial
variant only changes the software outstanding limit from four to one; it
keeps hardware credit protection. It is a diagnostic comparison, not a
production fix. Both print the selected limit at startup. Credit timeouts
also print status/accepted/retired three times, one second apart.

Build/download the one-outstanding version:

```bash
STANDALONE_CREDIT_LIMIT=1 bash scripts/build_gemmini_standalone.sh
STANDALONE_CREDIT_LIMIT=1 bash scripts/download_gemmini_standalone.sh
```

It is stored separately at sw/build/gemmini_standalone_serial/test.elf.
The default limit-four ELF stays at sw/build/gemmini_standalone/test.elf.
After resetting accelerator state, run f then k. Serial PASS with limit-four
failure implicates overlap-sensitive behavior but does not establish whether
that is queue logic, resource reuse, memory behavior or physical timing.

## v5: weight-reuse comparison and raw task arguments

The limit-one board test stalled with accepted=4, retired=3 and status=0x0407
unchanged across three samples. Decode: one running, one outstanding, no queued
requests; hardware can_submit is set, but the deliberate software limit-one
policy waits for the current task to retire. This does not establish a credit
counter bug. k initializes its own data and does not require f first.

v5 adds raw rs1/rs2 logs for LoopConv commands. A separate comparison disables
only the existing convolution B/weight reuse optimization (reload weights
rather than passing NULL and a fixed reusable scratchpad ID). Credit limit,
geometry and oracle are unchanged. It is a diagnostic, not a proven fix.

```bash
STANDALONE_CREDIT_LIMIT=1 STANDALONE_DISABLE_B_REUSE=1 bash scripts/build_gemmini_standalone.sh
STANDALONE_CREDIT_LIMIT=1 STANDALONE_DISABLE_B_REUSE=1 bash scripts/download_gemmini_standalone.sh
```

After resetting the accelerator, verify v5, CREDIT_LIMIT=1 and DISABLE_B_REUSE=1,
then run k directly. If stalled, preserve the last complete seven-command task
(CONFIG 0x10..0x15, launch 0x0f) including LOOPCONV_ARGS and timeout snapshots.
The serial variant with reuse enabled is also built separately for comparison.
