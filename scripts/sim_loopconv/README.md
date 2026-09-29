> 2026-09-29 更新：EX 修正已落实到当前 Scala，已重新生成生产 RTL，并恢复 ABI v9 诊断。当前回归使用 `run_gemmini.sh`，随后运行 `run_rtl_handshake_regression.sh`。`run_handshake_experiment.sh` 是此前针对旧 RTL 的补丁实验，不再适用于新生成 RTL。详见 [修复与诊断说明](rtl_fix_diagnostics_v9.md)。

# Existing-RTL LoopConv retirement simulation

Run from any directory: `bash scripts/sim_loopconv/run.sh`.
Requires gcc, Verilator and a C++ compiler. All products/logs are under
`build/sim_loopconv`; no Scala/production RTL/bitstream is regenerated.

`capture.c` runs the **actual 0918 software tiler and generated DIM64 header**
on the host, replacing only RoCC emission with a text sink and removing
hardware credit polling/fences. Small 16x20 input generates one request; the
480x640 first-layer-shaped input generates 150 requests. Addresses are fixed
simulation fixture addresses, not the board ELF's exact addresses. Weight
reuse is enabled as in the original failing image. The simulator admits one
request at a time, matching the failing single-outstanding experiment.

The original `run.sh` uses two levels of checked-in triple64 SystemVerilog:
1. LoopConv and all of its generated children, with delayed command completion.
2. LoopConv plus the real ReservationStation, with controller issue backpressure
   and delayed ROB-ID completion. Load/store config commands complete on issue;
   other completions are supplied by the model.

Those two levels do NOT instantiate actual load/execute/store controllers, Scratchpad,
TLB/DMA, memory, accelerator datapath, Rocket/LazyRoCC ingress or routed timing.
The one-at-a-time C++ ingress feeds complete configuration packets directly to
LoopConv. PASS means retirement/control liveness under the modeled downstream
responses, not end-to-end inference correctness or board timing closure.

Observed 2026-09-29: both test levels pass small and full cases at completion
latencies 8/100/1000 cycles and ready-stall periods 0/13/31 (12 cases).
Full LoopConv+RS cases retire all 150 tasks, including task four:
- latency 8, no stalls: 32417 cycles;
- latency 100, stall period 13: 129041 cycles;
- latency 1000, stall period 31: 1222447 cycles.

A **deliberate fault injection** withholds load completions after accepting
request four. The harness correctly times out with submitted=4, retired=3:
ld_utilization=16, head slot1 ld_input_completed=0, ex_completed=0,
st_completed=0. The input generator is overloaded and execution waits for
loads. This validates diagnostic visibility and shows one way the symptom can
occur. It is NOT evidence that the board has that specific fault. Only this
injection extends the existing gemmini_timeout plusarg to let the harness
print internal state before the RS assertion; normal runs keep the default.

Additional simulation levels (run separately with `bash scripts/sim_loopconv/<script>`):

| Script | Actual generated RTL included | Modeled boundary |
| --- | --- | --- |
| `run_controllers.sh` | LoopConv, RS, load/store/execute controllers, mesh | Scratchpad responses and DMA responses |
| `run_gemmini.sh` | Complete worker-0 Gemmini, including Scratchpad, DMA, accumulators, scaling and SiLU BRAM | Direct RoCC command input and external TileLink memory |
| `run_ingress.sh` | Same complete Gemmini plus `RegisteredIngressAtomicReserve` from the generated SoC | Input of the LazyRoCC ingress and external TileLink memory |

The controller test returns zero Scratchpad data; its PASS checks progress only.
Observed: small case retires 1 task in 3032 cycles; full case retires all 150 in
799378 cycles. Both use DMA response latency 8, without injected stalls.

The complete-Gemmini tests use the standalone ELF's synthetic input, sparse
weights, biases and signed `x/2` test LUT. The LUT is programmed via real RoCC
commands, and **every output byte** is checked against an independent convolution
reference (1280 small, 1228800 full). Retirement alone is not a PASS: the driver
also drains busy and outstanding memory responses before comparing outputs.
The direct-ingress acceptance pulse is synthetic only in `run_gemmini.sh`;
`run_ingress.sh` wires the real ingress acceptance/queue/partial signals to
Gemmini. Both admit one complete convolution request at a time.

These tests use Vivado 2023.2's `xeclib/RAMB36E2.v` functional model at the path
in `prepare_gemmini.py`, with Verilator `--no-timing`. They require that Vivado
installation. Unconnected cascade/ECC outputs and internal primitive-model
latch/multiple-driver warnings are retained in the build log.

The TileLink model implements Get and Put with byte masks and multibeat data,
fixed response delay and optional A-channel backpressure. It returns responses
in order, without errors. It is **not** the SoC interconnect, DDR controller,
CPU cache, Rocket pipeline/replay, three concurrent workers or routed timing.
Fixture buffer addresses also differ from the board ELF. Passing these tests
therefore cannot establish that the FPGA is free of the reported stall.

Complete-Gemmini observations (2026-09-29):

- Small direct-input case: all 1280 output bytes pass; 6986 cycles. With memory
  delay 100 and A-channel stall period 13, all outputs also pass (12554 cycles).
- Small real-ingress case: all 1280 outputs pass; 6992 cycles.
- Full direct-input case: all 150 tasks retire (last retirement at cycle
  3038205), **but output checking FAILS: 902481 mismatched bytes**. This is not
  a successful convolution and not a reproduction of the board retirement hang.
- Full real-ingress case: all 150 tasks also retire (last at cycle 3039106),
  with the same 902481 mismatch count and first five mismatch values. Actual
  ingress therefore does not reproduce the retirement stall in this environment.
- Isolating the first full-size task already reproduces output mismatch:
  8192 bytes written, no repeated byte writes, 3570 mismatches. No subsequent
  task is necessary to trigger this discrepancy. The simulation model versus
  RTL origin of this discrepancy is not yet established.
- The isolated first task with memory delay 100/stall period 13 still retires,
  but has 1024 mismatches instead of 3570 (same 8192-byte coverage, no repeated
  writes). This response-schedule dependence merits investigation of both the
  harness protocol and RTL data/dependency handshakes; it does not by itself
  identify the board fault.

Reproduce the isolated first-task test after building `run_gemmini.sh`:

```sh
build/sim_loopconv/obj_gemmini/VGemminiTest \
  build/sim_loopconv/commands_gemmini_480.txt 8 0 1
```

Arguments after the command file are memory latency, A-channel stall period,
and optional request limit (0 means all). Limited runs check only written
output bytes and explicitly report partial coverage. Normal runs require
complete output coverage. The driver saves output bytes beside the command
file as `<command-file>.output.bin`; repeated runs overwrite that dump.
Numerical mismatches exit with code 7, so the run scripts intentionally return
failure for the currently failing full case. Detailed logs remain in `build`.

## Numerical-error isolation and handshake experiment

`+trace_internal` enables handshake-qualified traces at LoopConv/controller
commands, Scratchpad banks, mesh operand inputs, actual mesh row advances,
mesh results, accumulator writes and accumulator reads. Diagnostic scripts
`analyze_scratchpad.py`, `analyze_mesh_steps.py` and `analyze_accumulator.py`
are specific to the **first 8x64 output tile of the full fixture**. Its padded
input allocation is 21x133, including an unused trailing row and column.

Observed on the original RTL for both memory schedules:

- Scratchpad writes and responses match the independent fixture values.
  Bank responses also match a shadow memory updated on every masked write.
- Execute command sequences and per-bank read address sequences are identical.
- Actual mesh input A values are correct for all 3136 row advances (the
  initial preload plus 48 matrix operations).
- Weight input D becomes misaligned. For delay100/stall13, the nonzero
  coefficient for kernel row5 enters at row **56 instead of 55** (zero-based),
  selecting input channel1 instead of channel2 for output channels5 and11.
  For delay8/stall0, kernel rows3/4/5 enter two rows late.
- Mesh results exactly match the contributions handed to the accumulator;
  accumulator reads equal the sum of the accepted writes. The wrong values
  therefore originate before accumulation, activation and DMA writeback.

The suspicious boundary is `ExecuteController.scala` around lines850–916:
the A/B/D handshakes can complete independently, while read responses are
popped only under `mesh_cntl_signals_q.io.deq.fire` and a same-cycle operand
handshake. A response accepted early by the mesh can remain unconsumed when
the shared control token waits for another operand. Using `!mesh.ready` as
an implicit acknowledgement does not track that token's operand consumption.

`bash scripts/sim_loopconv/run_handshake_experiment.sh` reproduces an A/B
experiment. It copies `ExecuteController.sv` into `build` and changes only
that copy to:

1. Remember each control token's already accepted A/B/D operands and prevent
   them from being sent again.
2. Consume the supplying read response at its own operand handshake.
3. Gate first-row operand acceptance until the mesh request can be admitted.

After this change, both isolated first-task schedules have all **8192 output
bytes correct**; the slow-schedule weight coefficient enters row55 as expected,
all mesh contributions pass, and all accumulator values pass. The small case
also retains its 1280-byte PASS. This establishes an actionable RTL handshake
defect behind the numerical-error reproduction. The FPGA's accepted4/retired3
stall has **not** been reproduced or proven to share this cause.

Full delay8/stall0 experiment subsequently passed: submitted=150, retired=150,
2995894 cycles, all 1228800 output bytes correct, zero unwritten or repeated
output bytes (`build/sim_loopconv/handshake_full.log`).

The experiment does not modify production Scala, checked-in generated RTL or
the FPGA bitstream. Its generated-SV patch deliberately asserts exact patterns
and counts; it must be reviewed if the generated source changes.

Debug interface audit:
- /home/wzr/chipyard/generators/gemmini/src/main/scala/gemmini/Controller.scala
  contains the 64-page deadlock debug CSR window covering LoopConv (pages1-9),
  RS (10-29), Scratchpad (30-41), completion events and further pages.
- The transplanted soc_shell/npu100_video Controller.scala does not include
  that implementation. The checked-in triple64 Gemmini.sv exposes only four
  CSR data ports: busy/status/accepted/retired; no deadlock debug window.
- LazyRoCC's ingress debug bus alone does not expose internal stage state.
  Restoring board observability requires porting the internal debug producers,
  Controller CSR window and non-conflicting per-worker CSR configuration.
