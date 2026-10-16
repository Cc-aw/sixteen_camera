# Head read decoupling and L2 secondary capacity

Run from the repository root:

```sh
make test-head-read-decouple
make test-l2-secondary-capacity SOC_WORKSPACE=/path/to/newly-rebuilt-chipyard
make test-head-l2-urgent SOC_WORKSPACE=/path/to/newly-rebuilt-chipyard
```

Set `HEAD_VERILATOR` in ignored `tools/config/tools.local.mk` or the environment
if the default Verilator cannot compile the interface hierarchy. This run used
Verilator 5.022; the installed 5.044 crashed internally on the optimized branch.
For the older Scala regression runners also put the chosen executable's directory
first in `PATH`. Vivado 2023.2 provides the real DIM32 frontend simulation.

`run_tests.py` drives the actual production router and Chisel-generated RTL.
The aggregate target also runs the exact production structure checker and the
production-part Head OOC synthesis/192-URAM check. Every command records its
return code, log and source fingerprint under
`build/reports/head_l2_urgent/`. A missing executable/workspace is BLOCKED;
nonzero subprocess exit propagates failure. A successful subprocess reporting
SKIP/BLOCKED does not count as PASS. All suites continue independent checks and
return nonzero if any required check fails.

| Coverage | Actual stimulus/check |
| --- | --- |
| H01 | 32 unanswered DDR reads on one ID, deeper than the 8-entry waiting FIFO |
| H02/H04 | Hold ID0 DDR; complete ID1 Head; issue ID1 DDR while ID0 Head waits |
| H03 | Old DDR / Head / new DDR on ID0; no new DDR dispatch before the switch |
| H05/H06/H07 | Head burst with upstream stalls; DDR AR overlap; whole-burst DDR cross-ID reorder; stable payload and noninterleaving |
| H08 | PPU response held across Head admission; all six banks and half selections |
| H09 | FIXED/INCR, narrow accesses, alias, slot edge, unsupported burst/size, crossing-slot error, 256 beats |
| H10 | 32 global credits; eight queued same-ID descriptors; random simultaneous acceptance/retirement and FIFO refill |
| H11 | Common reset with no ghost responses; initialized URAM data retained |
| H12 | Reads concurrent with an unrelated partial/full Head write; original write/error tests adapted to v3; shadow fallback |
| L01/L02 | Exactly 34/68 payload entries, every queue 0..101, all physical pointer bits |
| L03/L04/L05 | Per-queue reference FIFO; random push/pop/result stalls; last-element simultaneous pop/push |
| L06/L07 | Pending synchronous reads under prolonged backpressure; conservative allocation after full-pool pop |
| L08/L09 | Real dual-bank cache; observed secondary occupancy above 34; same-set/tag replacement, reload, probes and dirty flush; Tensor coherent intervention/eviction |

The optimized Head regression uses five seeds (151034..151038), each with
10,000 legal random transactions at both 512/256 and 256/256 widths. Directed
invalid Head requests run separately. A legacy 512-bit run checks 10,000 random
transactions. The progress comparison holds a DDR response for 100 cycles and
requires an early Head completion only for the optimized configuration.
`tb_head_router_progress.sv` is an optional wrapper around the same scoreboard;
pass `+PROGRESS_ONLY` when running it.

The original PPU router bench is copied into the ignored build directory and
only its DUT name/READ_DECOUPLE parameter are adapted, preserving its assertions.
The existing memory regression retains legacy global-drain timing checks.

The real RegisteredListBuffer runs both capacities, five seeds each, 20,000
random cycles per seed plus directed boundaries and full drain. Python only
orchestrates these RTL tests; it is not a substitute implementation.

For a production-geometry Head synthesis check, run Vivado from a dedicated
output directory with `-mode batch -source <repo>/tests/rtl/head_l2_urgent/head_ooc.tcl`.
It requires exactly 192 UltraRAM cells and emits utilization, timing and a DCP.
These OOC timings do not certify full-chip timing closure.
