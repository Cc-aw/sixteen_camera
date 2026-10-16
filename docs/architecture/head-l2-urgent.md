# Current Head / L2: S1 controllers, 1 MiB four-bank geometry

The subsequent [four-bank implementation plan](l2-1mib-4bank-implementation.md)
expands the restored S1 baseline from 512 KiB/two banks to 1 MiB/four banks.
Head, TensorIngress and DDR settings below are retained. The two-bank profile
and its ABI1.1 remain available as an explicit private generation fallback.

The user superseded the H1/L1 candidate on 2026-10-16 and requested the Head and
L2 from this reference bitstream:

```text
/mnt/data/sunys/sixteen_camera_3x32_100mhz_memory_parallel_v3_maxpool_timing_s1_2026-10-14/prj/sixteen_camera.runs/impl_frontend/top_wrapper.bit
```

The user explicitly retained the current TensorIngress and DDR configuration.
The production product remains `triple32_v3_tensor`, with one generated SoC
export. This restores the specified Head/L2 behavior; the retained Tensor port,
statistics integration and DDR register slice mean the entire design is not a
copy of the S1 bitstream.

The production Head router and bridge are copied from S1 with module names
changed to `axi4_head_uram_router_v3` and `postprocess_memory_bridge_v3` for the
existing integration. There are no other transformations. H1's per-ID request
FIFOs, destination-owner counters, AR stage and added R FIFOs are removed. DDR
reads and writes remain independently pipelined, with the original 32 DDR
outstanding capability. Switching to a local Head slot drains that direction's
DDR responses first, as S1 did. The six shared Head stores, local 256-bit PPU
port, 512-bit SoC port, error behavior and shadow option remain the S1 behavior.
`current.json` records `head_read_decouple=false`.

L2 uses the S1 `Scheduler.scala`, `MSHR.scala`, `ListBuffer.scala`,
`Parameters.scala`, `Configs.scala` and `SinkD.scala` byte for byte. It restores:

* A shared 34-entry payload pool per bank with 102 logical queues, register
  payload slots, one-hot front pointers and combinational `fastPeek`.
* The S1 combinational round-robin MSHR arbiter and direct retirement/refill,
  including S1's own directory/repeat rules and nested coherence interlocks.
* S1 interior/exterior buffer settings, including registered outer A/D queues.

The 68-entry synchronous pool, four response-credit queue, reload-wait machinery,
safe prefetch, registered grouped candidate preparation and outer data-only flow
are removed. `RegisteredListBuffer.scala` is removed from the production source
closure. `current.json` records `l2_implementation=s1_combinational` and
`l2_secondary_entries=34`.

Across the inclusive-cache source package, only `InclusiveCache.scala` differs
from S1. Its existing adaptation classifies the retained Tensor client and wires
statistics ABI1.2 events for four banks; it does not replace the restored controller algorithm.
The SoC has 32 ordinary + 2 coherence MSHRs per bank, four banks, 1 MiB,
8 ways, 512 sets per bank, 64-byte lines and bank A13:A12. Sets use A6:A11 and
A14:A16; the complete bank/set period is 128 KiB. Memory remains 512-bit/ID2,
Tensor 256-bit/ID5, three Gemmini DIM32 workers and target 100 MHz. Frontend ABI2,
model and golden results are unchanged by this task.

DDR refers to the external memory interface. Its AXI register slice remains
mode 1 (FULL), as the user requested; the reference S1 used mode 7 (LIGHT).
TensorIngress retains its dedicated coherent SBUS write path. Restoring Head/L2
does not establish board performance or routed timing for this combination.

The official Scala/Chisel generator and memory mapping scripts produce the sole
RTL export. Atomic staging preserves a complete generation context. The source
checker requires the actual 34-entry fast-peek pool, old arbiter, absence of H1
and registered-pool machinery, selected bank geometry and retained interfaces.

`build/reports/s1_restore/source_restore.json` identifies each donor file, source
and normalized hashes, retained DDR/Tensor files, and the final generated export.
The rejected candidate is archived under
`build/reports/s1_restore/rejected_candidate/`; its prior implementation was
stopped before synthesis completed. Earlier H1/L1 patches, reports and bitstream
remain historical evidence and must not be presented as the restored build.

The [validation record](../validation/head-l2-urgent.md) records actual tests,
comparison scope and the replacement full implementation state. No FPGA or
firmware download is part of this restoration.

The restored baseline was saved without launching full implementation, per the
user's final instruction. Local Head/L2 synthesis and simulation evidence is
kept with the snapshot; full-design timing and a restored-version bitstream have
not been produced for that restored snapshot. The subsequent four-bank work
includes the full bitstream flow at the user's request, with this turn monitoring
until synthesis ends; its actual evidence is recorded in `docs/validation/l2-1mib-4bank.json`.
