# MyBoard Gemmini / Large Gemmini Handoff

Last updated: 2026-07-08.

This note records the current normal Gemmini and Large Gemmini status for the VU13P/MyBoard flow. The board is debugged through JTAG/OpenOCD/GDB. UART is being added to the Large config, but tests below must still work without UART by reading DDR status blocks from GDB.

## 1. Current Source State

Main MyBoard files:

```text
fpga/src/main/scala/myboard/Configs.scala
fpga/src/main/scala/myboard/IOBinders.scala
fpga/src/main/scala/myboard/TestHarness.scala
```

Important test programs:

```text
tests/cpu-smoke.c
tests/ddr-memtest.c
tests/gemmini-smoke.c
tests/gemmini-tile.c
tests/gemmini-video-conv.c
tests/gemmini-video-conv-1080p.c
```

Normal working Gemmini config:

```text
CONFIG=GemminiRocketMyBoardConfig
DDR size: 4 GiB
DDR AXI data width: 128 bits
CPU: single RV64 Rocket
UART: disabled
Debug: JTAG/BSCAN tunnel
```

New second-stage Large config:

```text
CONFIG=LargeGemminiRocketMyBoardConfig
DDR size: 4 GiB
DDR AXI data width: 256 bits
CPU: single RV64 Rocket
UART: enabled at 0x10020000, 115200 baud
Configured frequency: 100 MHz
Gemmini mesh: 32 x 32
Gemmini scratchpad: 512 KiB
Gemmini accumulator: 128 KiB
Gemmini DMA bus width: 256 bits
Gemmini dma_maxbytes: 64
Debug: JTAG/BSCAN tunnel
```

The Large config added:

```text
WithMyBoardUARTTweaks
WithMyBoardUARTPunchthrough
WithMyBoardUARTPassthrough
LargeGemminiRocketMyBoardConfig
MyBoardGemminiConfigs.largeConfig
```

Important UART note: `WithUART(...) ++ WithNoUART ++ AbstractConfig` is intentional. It clears the default UART from `AbstractConfig` while keeping the explicitly added UART at `0x10020000`. This fixed the earlier address-overlap error:

```text
Ports cannot overlap: AddressSet(0x10020000, 0xfff) AddressSet(0x10020000, 0xfff)
```

Vivado UART note: `SimUART.v` and `SimUART.cc` are simulation-only files from Chipyard/testchipip. Do not add them to the Vivado synthesis project. The MyBoard Large config now uses `WithMyBoardUARTPassthrough` so the UART becomes a real FPGA top-level port instead of being connected to the default simulation UART adapter.

## 2. Large Gemmini Generation Status

Generation command:

```bash
cd /home/wzr/chipyard/fpga
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR=/tmp \
  make SUB_PROJECT=myboard CONFIG=LargeGemminiRocketMyBoardConfig verilog \
  2>&1 | tee large-gemmini-myboard-verilog.log
```

Current local state:

```text
Generated directory exists:
fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.LargeGemminiRocketMyBoardConfig/

Only chisel.log was observed there.
No complete .fir/.sv was confirmed yet.
```

The observed `chisel.log` tail reached successful hardware elaboration warnings only:

```text
unified shared memory size: 2048x32x8
There were 2 warning(s) during hardware elaboration.
```

However, a complete Verilog generation has not yet been confirmed. If make fails, inspect the real cause with:

```bash
cd /home/wzr/chipyard
rg -n "Exception|Caused by|requirement failed|Error|error|Ports cannot|AddressSet|Fatal|Assertion" \
  fpga/large-gemmini-myboard-verilog.log \
  fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.LargeGemminiRocketMyBoardConfig/*.log
tail -260 fpga/large-gemmini-myboard-verilog.log
```

If the log shows:

```text
bad constant pool index
scala 2.12.17
```

then it is a Java/SBT compatibility problem, not a SoC design problem. Use Java 17 or Java 11 instead of Java 21, then rerun make.

Check Java:

```bash
java -version
```

## 3. After Large Verilog Generation Succeeds

Confirm the generated top-level before changing Vivado:

```bash
cd /home/wzr/chipyard
rg -n "axi4_mem_0|uart|aw_addr|ar_addr|w_data|w_strb|r_data|aw_id|ar_id|b_id|r_id" \
  fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.LargeGemminiRocketMyBoardConfig \
  -g '*.sv' -g '*.v' -g '*.fir'
```

Expected Large properties:

```text
AXI W/R data: 256 bits
AXI WSTRB: 32 bits
DDR address: likely 33-bit SoC physical address for 4 GiB memory window
UART top-level port: uart_0 or equivalent generated punchthrough name
No SimUART.v in synthesis sources
```

Do not guess the AXI ID width. Inspect the generated SV/FIR and match the Vivado BD to that width or explicitly adapt it in `top_wrapper.sv`.

Vivado updates needed for Large:

```text
S00_AXI DATA_WIDTH = 256
S00_AXI WSTRB width = 32
S00_AXI ADDR_WIDTH = 32 for DDR offset side
S00_AXI ID_WIDTH = inspect generated top before deciding
UART RX/TX ports may be exposed now, but can remain unconnected/commented until the adapter arrives
```

For 4 GiB DDR, keep the existing high-bit address remap idea:

```verilog
bd_awaddr = {axi4_mem_aw_addr[32], axi4_mem_aw_addr[30:0]};
bd_araddr = {axi4_mem_ar_addr[32], axi4_mem_ar_addr[30:0]};
```

This maps CPU physical DDR window `0x80000000..0x17fffffff` into BD/MIG offset `0x00000000..0xffffffff`.

Clock note: setting the Chipyard config to 100 MHz does not by itself create a physical 100 MHz board clock. The Vivado clocking path must actually feed the SoC with 100 MHz, or the design is only described as 100 MHz while physically running at another rate.

## 4. Build Test ELFs

From Chipyard root:

```bash
cd /home/wzr/chipyard
source env.sh
mkdir -p tests/build
```

CPU smoke:

```bash
riscv64-unknown-elf-gcc -std=gnu99 -O2 -Wall -Wextra \
  -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns \
  -march=rv64imafd -mabi=lp64d -mcmodel=medany -specs=htif_nano.specs \
  -static -T tests/htif.ld tests/cpu-smoke.c \
  -o tests/build/cpu-smoke.riscv
```

DDR memtest:

```bash
riscv64-unknown-elf-gcc -std=gnu99 -O2 -Wall -Wextra \
  -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns \
  -march=rv64imafd -mabi=lp64d -mcmodel=medany -specs=htif_nano.specs \
  -static -T tests/htif.ld tests/ddr-memtest.c \
  -o tests/build/ddr-memtest.riscv
```

Gemmini smoke:

```bash
riscv64-unknown-elf-gcc -std=gnu99 -O2 -Wall -Wextra \
  -fno-common -fno-builtin-printf -ffast-math -fno-tree-loop-distribute-patterns \
  -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable -Wno-sign-compare \
  -march=rv64imafd -mabi=lp64d -mcmodel=medany -specs=htif_nano.specs \
  -I/home/wzr/chipyard/generators/gemmini/software/gemmini-rocc-tests \
  -static -T tests/htif.ld tests/gemmini-smoke.c \
  -o tests/build/gemmini-smoke.riscv
```

Gemmini tile:

```bash
riscv64-unknown-elf-gcc -std=gnu99 -O2 -Wall -Wextra \
  -fno-common -fno-builtin-printf -ffast-math -fno-tree-loop-distribute-patterns \
  -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable -Wno-sign-compare \
  -march=rv64imafd -mabi=lp64d -mcmodel=medany -specs=htif_nano.specs \
  -I/home/wzr/chipyard/generators/gemmini/software/gemmini-rocc-tests \
  -static -T tests/htif.ld tests/gemmini-tile.c \
  -o tests/build/gemmini-tile.riscv
```

Video conv 64x64:

```bash
riscv64-unknown-elf-gcc -std=gnu99 -O2 -Wall -Wextra \
  -fno-common -fno-builtin-printf -ffast-math -fno-tree-loop-distribute-patterns \
  -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable -Wno-sign-compare \
  -march=rv64imafd -mabi=lp64d -mcmodel=medany -specs=htif_nano.specs \
  -I/home/wzr/chipyard/generators/gemmini/software/gemmini-rocc-tests \
  -static -T tests/htif.ld tests/gemmini-video-conv.c \
  -o tests/build/gemmini-video-conv.riscv
```

1080p experiment:

```bash
riscv64-unknown-elf-gcc -std=gnu99 -O2 -Wall -Wextra \
  -fno-common -fno-builtin-printf -ffast-math -fno-tree-loop-distribute-patterns \
  -Wno-unused-function -Wno-unused-parameter -Wno-unused-variable -Wno-sign-compare \
  -march=rv64imafd -mabi=lp64d -mcmodel=medany -specs=htif_nano.specs \
  -I/home/wzr/chipyard/generators/gemmini/software/gemmini-rocc-tests \
  -static -T tests/htif.ld tests/gemmini-video-conv-1080p.c \
  -o tests/build/gemmini-video-conv-1080p.riscv
```

If a warning appears:

```text
LOAD segment with RWX permissions
```

it can be ignored for these bare-metal debug ELFs.

## 5. OpenOCD / GDB Flow

Start OpenOCD:

```bash
cd /home/wzr/chipyard
source env.sh
/home/wzr/riscv-openocd/src/openocd \
  -f fpga/src/main/resources/myboard/openocd-bscan.cfg
```

Start GDB in another terminal:

```bash
cd /home/wzr/chipyard
source env.sh
riscv64-unknown-elf-gdb tests/build/<test>.riscv
```

Inside GDB:

```gdb
target extended-remote localhost:3333
monitor reset halt
load
set $pc = 0x80000000
continue
```

Stop the program and inspect status:

```gdb
Ctrl-C
x/24wx &<status_symbol>
```

Correct GDB exit:

```gdb
monitor reset halt
disconnect
quit
```

If the core cannot halt:

```text
Unable to halt
Could not read registers; remote failure reply 'E0E'
```

then close GDB, kill/restart OpenOCD, and redownload/reset the bitstream if needed:

```bash
pkill -f riscv-openocd
```

## 6. Normal Gemmini Test Plan

Use this sequence for the already working `GemminiRocketMyBoardConfig` after every new bitstream or Vivado wrapper change.

### 6.1 CPU Smoke

ELF:

```text
tests/build/cpu-smoke.riscv
```

GDB status:

```gdb
x/12wx &cpu_status
```

Pass condition:

```text
word0 = 0x43505554
word1 = 0x000000ff
```

### 6.2 DDR Memtest

ELF:

```text
tests/build/ddr-memtest.riscv
```

GDB status:

```gdb
x/16wx &ddr_status
```

Pass condition:

```text
word0 = 0x44525453
word1 = 0x000000ff
```

This test should include low DDR and high DDR probes. For the normal current MyBoard design, high probes already passed before at 4 GiB mapping.

### 6.3 Gemmini Smoke

ELF:

```text
tests/build/gemmini-smoke.riscv
```

GDB status:

```gdb
x/12wx &gemmini_status
```

Pass condition:

```text
word0 = 0x47454d54
word1 = 0x000000ff
```

### 6.4 Gemmini Tile

ELF:

```text
tests/build/gemmini-tile.riscv
```

GDB status:

```gdb
x/16wx &gemmini_tile_status
```

Pass condition:

```text
word0 = 0x474d544c
word1 = 0x000000ff
matmul_cycles != 0
conv_cycles != 0
```

Known previous passing normal-Gemmini result:

```text
magic          = 0x474d544c
state          = 0xff
matmul_cycles  = 0x1ad7 = 6871
conv_cycles    = 0x3497 = 13463
```

### 6.5 Video Conv 64x64

ELF:

```text
tests/build/gemmini-video-conv.riscv
```

GDB status:

```gdb
x/24wx &video_conv_status
```

Pass condition:

```text
word0 = 0x56434f4e
word1 = 0x000000ff
conv_cycles != 0
verify should pass
```

Known previous passing normal-Gemmini result:

```text
magic         = 0x56434f4e
state         = 0xff
init_cycles   = 105493
conv_cycles   = 48147
verify_cycles = 56026395
```

At 50 MHz, `48147` conv cycles is about:

```text
0.963 ms
```

### 6.6 1080p Experiment

ELF:

```text
tests/build/gemmini-video-conv-1080p.riscv
```

This is not a first-pass regression test. Run it only after CPU, DDR, Gemmini smoke, tile, and 64x64 video conv pass.

The earlier full-1080p `tiled_conv_auto` version ran longer than 2.5 minutes and could not be halted cleanly. Treat the 1080p test as experimental until its progress/status fields show it is making forward progress.

## 7. Large Gemmini Test Plan

Use the same functional order as normal Gemmini, but add generated-interface and Vivado checks first.

### 7.1 Static Interface Check

Before synthesis:

```bash
cd /home/wzr/chipyard
rg -n "axi4_mem_0|uart|w_data|w_strb|r_data|aw_addr|ar_addr|aw_id|ar_id" \
  fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.LargeGemminiRocketMyBoardConfig \
  -g '*.sv' -g '*.v' -g '*.fir'
```

Confirm:

```text
DDR data path is 256 bits.
WSTRB is 32 bits.
Address mapping still covers 4 GiB.
UART ports are present or intentionally tied off in Vivado.
ID width is matched between generated RTL and BD/top wrapper.
```

### 7.2 Vivado Smoke

After synthesis/implementation and bitstream download:

```text
OpenOCD can examine the target.
GDB can halt the hart.
GDB can load an ELF into DDR.
```

Do not start with Gemmini. Start with CPU and DDR.

### 7.3 CPU Smoke

Run:

```text
tests/build/cpu-smoke.riscv
```

Inspect:

```gdb
x/12wx &cpu_status
```

Required:

```text
word1 = 0xff
```

### 7.4 DDR Memtest

Run:

```text
tests/build/ddr-memtest.riscv
```

Inspect:

```gdb
x/16wx &ddr_status
```

Required:

```text
word1 = 0xff
low DDR passes
high DDR probes pass
```

If high DDR fails, first inspect the 33-bit SoC address to 32-bit BD address remap and BD address window.

### 7.5 Gemmini Smoke

Run:

```text
tests/build/gemmini-smoke.riscv
```

Inspect:

```gdb
x/12wx &gemmini_status
```

Required:

```text
word1 = 0xff
```

If this fails but CPU/DDR pass, the likely area is RoCC/Gemmini integration, Gemmini parameter/header mismatch, or larger Gemmini timing/implementation issue.

### 7.6 Gemmini Tile

Run:

```text
tests/build/gemmini-tile.riscv
```

Inspect:

```gdb
x/16wx &gemmini_tile_status
```

Required:

```text
word1 = 0xff
matmul_cycles != 0
conv_cycles != 0
```

Large Gemmini should show different cycle counts from normal Gemmini. The exact value is not the pass criterion; correctness is.

### 7.7 Video Conv 64x64

Run:

```text
tests/build/gemmini-video-conv.riscv
```

Inspect:

```gdb
x/24wx &video_conv_status
```

Required:

```text
word1 = 0xff
conv_cycles != 0
verify passes
```

At 100 MHz, wall-clock time in milliseconds is:

```text
cycles / 100000
```

For example, 48147 cycles at 100 MHz is about:

```text
0.481 ms
```

### 7.8 1080p and ResNet

Run only after all smaller tests pass. The target is not Linux; adapt the Gemmini software to bare-metal status blocks first.

Existing full ResNet-50 source is under:

```text
generators/gemmini/software/gemmini-rocc-tests/imagenet/resnet50.c
generators/gemmini/software/gemmini-rocc-tests/imagenet/resnet50_params.h
generators/gemmini/software/gemmini-rocc-tests/imagenet/images.h
```

This code expects ImageNet-style 224x224 RGB input tensors, not raw 1080p RGB888 frames directly. A real video pipeline still needs resize/crop/layout/quantization before ResNet.

## 8. Pass/Fail Rule

For both normal Gemmini and Large Gemmini, do not treat a larger AI test as meaningful until these are true in order:

```text
1. OpenOCD can examine and halt the hart.
2. GDB can load an ELF into DDR.
3. CPU smoke passes.
4. DDR memtest passes, including high DDR probes.
5. Gemmini smoke passes.
6. Gemmini tile test passes.
7. 64x64 video conv passes.
8. Only then run 1080p or ResNet-derived tests.
```

If a later test fails, return to the previous passing level and do not change multiple variables at once.

## 9. 2026-07-08 Large Gemmini Matmul Debug State

### 9.1 User Preferences / Operating Notes

- User runs OpenOCD/GDB manually.
- Do not run `git status`; this repository is large and the command can hang.
- Use targeted `rg`, `sed`, `nm`, `objdump`, and `ls`.
- Current board flow should generate MyBoard FPGA RTL from `fpga/`, not `sims/verilator/`.

Correct Large MyBoard Verilog generation command:

```bash
cd /home/wzr/chipyard/fpga
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR=/tmp \
  make SUB_PROJECT=myboard CONFIG=LargeGemminiRocketMyBoardConfig verilog
```

Do not use `sims/verilator` for `LargeGemminiRocketMyBoardConfig`; that defaults
to `CONFIG_PACKAGE=chipyard` and fails because the config is in
`chipyard.fpga.myboard`.

### 9.2 Known Passing State Before Matmul Investigation

Normal `GemminiRocketMyBoardConfig` baseline:

```text
CPU smoke PASS
DDR memtest PASS
Gemmini smoke PASS
Gemmini tile PASS
64x64 video conv PASS
```

Large `LargeGemminiRocketMyBoardConfig` observations:

```text
manual 32x32 Gemmini block PASS
64x64 direct conv / ResNet smoke PASS
generic matmul / tiled_matmul / LOOP_WS paths can hang
```

Important passing manual test:

```text
tests/build/gemmini-manual-block-large.riscv
manual_status = 0x80001300
manual_done_breakpoint = 0x80000558
state = 0xff
fail_code = 0xffffffff
DIM = 0x20
```

### 9.3 RTL Changes Made

#### LoopMatmul fixes

File:

```text
generators/gemmini/src/main/scala/gemmini/LoopMatmul.scala
```

Fixes applied:

```scala
// LdB row padding condition
row_iterator === max_row_iterator-1.U

// Execute B-load ahead condition
io.ld_kb === k && io.ld_j > j
```

Rationale:

- `LoopMatmulLdB` previously compared `max_row_iterator === max_row_iterator-1.U`,
  which is effectively never true.
- `LoopMatmulExecute` previously used `io.ld_ka === k` when judging B-load
  progress. It should use `io.ld_kb === k`.

These fixes were confirmed present in regenerated FPGA Verilog:

```text
fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.LargeGemminiRocketMyBoardConfig/gen-collateral/LoopMatmulExecute.sv
```

However, after this fix, `gemmini-matmul-sweep-large-fixed.riscv` still hung
before `sweep_after_1024_breakpoint`, so this was not the only issue.

#### DMACommandTracker candidate hardware fix

File:

```text
generators/gemmini/src/main/scala/gemmini/DMACommandTracker.scala
```

Change:

- Reworked tracker update into single next-state path.
- Completion slot can be reused in the same cycle.
- Merges `request_returned`, `cmd_completed`, and `alloc` without multiple
  independent writes fighting on the same `cmds(i)` registers.

Rationale:

The old tracker had separate `when` blocks writing the same command entry fields
for allocation, response return, and completion. In high-throughput Large
Gemmini runs, same-cycle complete/reuse can plausibly corrupt tracker state or
lose a completion. This would leave ReservationStation dependencies stuck.

This is a candidate RTL fix. It has not yet been validated on FPGA. Regenerate
Verilog and rebuild bitstream before testing it.

If a later bitstream was already built after this source change, confirm that
the generated collateral timestamp/content actually includes this tracker
change before interpreting new hangs. If it is included and the safe matmul
still hangs, then this fix is insufficient rather than wrong proof that the
tracker was not involved.

2026-07-08 follow-up:

The first `next_cmds` implementation caused firtool to fail with a combinational
cycle in `DMACommandTracker`:

```text
detected combinational cycle in a FIRRTL module, sample path:
DMACommandTracker.{_next_cmds_bytes_left_T <- ... <- next_cmds_0_bytes_left ...}
```

Root cause: `WireInit(cmds)` plus dynamic indexed reads/writes of
`next_cmds(cmd_id)` made the next-state wire read back through itself after
FIRRTL lowering.

Fix applied:

```text
generators/gemmini/src/main/scala/gemmini/DMACommandTracker.scala
```

The tracker now computes each entry's next state from `cmds(i)` only, using
per-entry `request_hit`, `complete_hit`, and `alloc_hit` signals. It no longer
reads from `next_cmds` while assigning `next_cmds`.

Validation:

```text
make SUB_PROJECT=myboard CONFIG=LargeGemminiRocketMyBoardConfig verilog
completed successfully from fpga/.

New generated files are under:
fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.LargeGemminiRocketMyBoardConfig/gen-collateral/

DMACommandTracker.sv and DMACommandTracker_1.sv were regenerated.
firtool.log no longer reports a combinational cycle.
```

The make output may still show two Chipyard helper errors marked as ignored:

```text
cp: missing destination file operand
make: [Makefile:137: .../sim_files.f] Error 1 (ignored)
make: [.../common.mk:288: ...top.mems.conf] Error 1 (ignored)
```

These are not the fatal firtool error. In the successful run, Verilog collateral,
file lists, and memory wrapper files continued to be produced after those
ignored messages.

### 9.4 Safe Matmul Test Added

File:

```text
tests/gemmini-safe-matmul-sweep.c
```

Built ELF:

```text
tests/build/gemmini-safe-matmul-sweep-large.riscv
```

Purpose:

- Avoid `tiled_matmul` and `LOOP_WS`.
- Use explicit low-level Gemmini commands:

```text
mvin -> preload -> compute -> mvout
```

- Add GDB-visible progress breakpoints/status block.
- Used to distinguish software tiler/CISC problems from lower Gemmini
  load/execute/store/RS problems.

Current latest symbols after adding init/pack breakpoints:

```text
safe_status = 0x80001840
safe_after_init_breakpoint = 0x80000a60
safe_after_pack_breakpoint = 0x80000a64
safe_after_first_preload_breakpoint = 0x80000a68
safe_after_first_k_breakpoint = 0x80000a6c
safe_after_first_block_breakpoint = 0x80000a5c
safe_after_second_block_breakpoint = 0x80000a80
safe_done_breakpoint = 0x80000a84
```

Observed progression during experiments:

```text
original safe version:
  first K block passed
  second K block A mvin could hang

packed-panel version:
  first 32x32 output block passed
  second output block passed after C double-buffering
  later blocks still failed to reach safe_done_breakpoint

fully prepacked version:
  did not reach first block in the last quick run
  needs init/pack/preload breakpoints checked before drawing conclusions
```

Important caveat:

```text
gemmini_fence() in gemmini.h is only a normal RISC-V fence instruction.
It is not a guaranteed Gemmini-completion wait.
```

This matters for tests that reuse CPU buffers as DMA sources. A single shared
packed panel buffer can be overwritten by the CPU before Gemmini DMA has
finished reading it. The fully prepacked version was added to avoid that
software-side race.

### 9.5 Current Interpretation

Most likely issue class:

```text
Large Gemmini multi-command load/execute/store dependency or DMA completion
tracking issue.
```

Evidence:

- Single manual 32x32 block passes.
- First packed safe output block can pass.
- Multiple consecutive blocks can hang.
- Generic `tiled_matmul` / `LOOP_WS` hangs.
- Direct convolution path can pass, so Gemmini is not entirely absent/broken.

Do not over-interpret the safe software tests alone; some earlier versions had
software-side synchronization hazards because `gemmini_fence()` is not a full
Gemmini completion wait.

### 9.6 Recommended Next Steps

1. Regenerate Verilog after the `DMACommandTracker.scala` fix.

```bash
cd /home/wzr/chipyard/fpga
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR=/tmp \
  make SUB_PROJECT=myboard CONFIG=LargeGemminiRocketMyBoardConfig verilog
```

2. Rebuild/download the Large bitstream.

3. Re-test minimal baseline first:

```gdb
file tests/build/gemmini-manual-block-large.riscv
load
set $pc = 0x80000000
delete breakpoints
b manual_done_breakpoint
continue
x/24wx &manual_status
```

4. Then test the safe matmul with early breakpoints:

```gdb
file tests/build/gemmini-safe-matmul-sweep-large.riscv
load
set $pc = 0x80000000
delete breakpoints
b safe_after_init_breakpoint
b safe_after_pack_breakpoint
b safe_after_first_preload_breakpoint
b safe_after_first_k_breakpoint
b safe_after_first_block_breakpoint
b safe_after_second_block_breakpoint
b safe_done_breakpoint
continue
```

When stopped or hung after Ctrl-C:

```gdb
x/26wx &safe_status
```

Status state meanings:

```text
0x08 = init_matrices stage
0x09 = pack_panels stage
0x10 = before Gemmini matmul body
0x20 = K-block compute body
0x30 = mvout stage
0xff = done
0xee = software fail
```

5. When UART adapter arrives, add MMIO UART progress prints to the safe test.
The Large config includes UART at:

```text
0x10020000
baudrate 115200
```

UART prints will simplify software progress tracking, but they will not replace
ILA if Gemmini/RoCC itself deadlocks.

6. If the `DMACommandTracker` fix does not help, add ILA/dontTouch probes for:

```text
ReservationStation utilization_ld_q / utilization_st_q / utilization_ex_q
ReservationStation packed_deps / min_pop_count
LoadController control_state / cmd_tracker busy / completed
StoreController control_state / cmd_tracker busy / completed
ExecuteController control_state / pending_completed_rob_ids / completed
```

### 9.7 Tomorrow Continue Here

Current stopping point:

```text
Large Gemmini still has intermittent/reproducible hangs on multi-block matmul
style tests. Basic RoCC/Gemmini operation is proven by the manual 32x32 block.
The bug should now be treated primarily as an RTL/hardware progress issue,
not as a missing Gemmini feature or simple software compile problem.
```

Do not spend more time trying random software variants before checking whether
the current bitstream really contains the latest RTL edits. First confirm the
Verilog/bitstream provenance:

```bash
cd /home/wzr/chipyard
rg -n "module DMACommandTracker|complete_fire|bytes_left" \
  fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.LargeGemminiRocketMyBoardConfig \
  -g '*DMACommandTracker*.sv'
```

If the generated Verilog is older than the latest `DMACommandTracker.scala`
change, regenerate from `fpga/` and rebuild the Vivado bitstream:

```bash
cd /home/wzr/chipyard/fpga
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR=/tmp \
  make SUB_PROJECT=myboard CONFIG=LargeGemminiRocketMyBoardConfig verilog
```

After programming the board, use this minimal order:

```text
1. Run manual block: proves CPU, DDR load, RoCC command path, one Gemmini block.
2. Run safe matmul only to locate the first stuck phase.
3. If it hangs again, stop software changes and add ILA/dontTouch probes.
```

Suggested GDB commands for the safe test:

```gdb
file tests/build/gemmini-safe-matmul-sweep-large.riscv
load
set $pc = 0x80000000
delete breakpoints
b safe_after_init_breakpoint
b safe_after_pack_breakpoint
b safe_after_first_preload_breakpoint
b safe_after_first_k_breakpoint
b safe_before_first_mvout_breakpoint
b safe_after_first_block_breakpoint
b safe_after_second_a_breakpoint
b safe_after_second_b_breakpoint
b safe_after_second_k_breakpoint
b safe_after_second_block_breakpoint
b safe_done_breakpoint
continue
```

When it stops or must be interrupted:

```gdb
x/26wx &safe_status
```

UART adapter note for tomorrow:

```text
Large config UART: 0x10020000, 115200 baud.
UART progress prints are useful for seeing software phase transitions without
GDB breakpoints, especially before/after mvin, compute, and mvout. If the core
deadlocks inside Gemmini/RoCC, UART will also stop; that is still useful
evidence, but the final root cause will likely need ILA signals.
```
