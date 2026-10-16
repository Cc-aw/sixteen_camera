# Head / L2 urgent candidate

Baseline: `3440bc10a15467f7ba42bb2ffac21a343e1956d6`, product
`triple32_v3_tensor`. The source implementation specification is
[sixteen_camera_Head_L2_urgent_codex_implementation.md](sixteen_camera_Head_L2_urgent_codex_implementation.md).

Production `postprocess_memory_bridge_v3` explicitly enables `READ_DECOUPLE=1`,
`READ_QUEUE_DEPTH_PER_ID=8`, `READ_ACCEPT_LIMIT=32`. `SHADOW_DDR=1` or
`READ_DECOUPLE=0` selects the original read implementation at elaboration.
Write control and all six Head stores are shared, without duplicated payload RAM.

The new `head_read_decoupler`, in the router's existing SV source file, stores
complete AR descriptors in one FIFO per external AXI ID. Round-robin dispatch
advances only on reservation. Each ID can own only one destination while its
issued count is nonzero. Reservation happens before the DDR AR register can
stall, and ownership retires only on upstream RLAST handshake. Queued requests
are ordered by their ID FIFO. The DDR register can sustain one address per cycle;
a single ID can consume all 32 outstanding credits while its FIFO drains.

Head execution and DDR address issue operate independently. DDR and Head each
have a two-beat return FIFO with occupancy-based input ready. R arbitration locks
on first VALID presentation, including a stalled presentation, through upstream
RLAST. It never locks a source that has no response. Global acceptance credit
includes every queued, reserved, executing and buffered transaction.

An accepted PPU request retains bank/half ownership until its response is
consumed. The Head executor cannot reserve while that PPU request is outstanding.
An eligible Head dispatch blocks a simultaneous new PPU request; a Head waiting
only for its ID's DDR owner does not claim RAM. During AXI execution, the executor
retains bank/address ownership through the final URAM-to-FIFO transfer. The
store's one-response register retains an irrevocable synchronous read when the
Head FIFO is full; no new read can overwrite it. PPU can resume once that final
transfer completes, while AXI target credit remains held until upstream retirement.
Errors use the same local response FIFO and preserve the requested beat count.

L2 adds trailing `secondaryEntries: Option[Int] = None` fields to
`InclusiveCacheParams` and `InclusiveCacheMicroParameters`. V3 sets `Some(68)`;
other configurations retain the previous derived default. The new overlay
`Parameters.scala` is based on the frozen reference, which remains unchanged.
`memCycles=64`, 32+2 MSHRs, 102 logical queues, four response credits, synchronous
payload RAM, scheduler/winner/reload logic and set ownership are unchanged.
The production checker reads one exact capacity from `current.json`; it checks
real scheduler instances, memory depth, entry pointers and pending response credit.

Two banks still provide 512 KiB total, 8 ways/bank, 512 sets/bank, 64-byte lines,
bank A12 and the existing set mapping. SoC memory stays 512-bit/ID2, Tensor
256-bit/ID5, Gemmini 3×DIM32, target 100 MHz, MPV3 ABI1.1 and frontend ABI2.
Model, golden results, V33 plan/input and realtime firmware compatibility stay
unchanged. Legacy counter event definitions and CLEAR/STOP behavior are preserved.

Independent rollback:

* H1: change production bridge `.READ_DECOUPLE(1'b1)` to `1'b0` and set
  `current.json`'s `head_read_decouple=false`, then rebuild hardware. L2 can
  remain at 68. The checker requires the exact setting in the product manifest.
* L1: set V3 `secondaryEntries=Some(34)` and `current.json`'s
  `l2_secondary_entries=34`, update the changed Scala import digest, and regenerate
  in another fresh private workspace. The checker then requires exactly 34;
  do not replace generated RTL by hand. H1 can remain enabled.

Functional source patches are saved separately under
`build/reports/head_l2_urgent/patches/`; apply the corresponding patch in reverse
only to unchanged candidate sources, then refresh provenance and rebuild. They
exclude generated RTL because source rollback must be followed by elaboration.
No production Config or SoC export was duplicated.

The user requested one complete implementation launch and observation only
through synthesis completion. The standard locked bitstream flow continues
implementation automatically after synthesis. Final place/route/timing and any
bitstream remain unverified until that background flow finishes. See the
[validation record](../validation/head-l2-urgent.md) for actual status.
