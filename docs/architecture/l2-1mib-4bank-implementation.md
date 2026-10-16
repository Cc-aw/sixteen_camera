# S1 L2: 1 MiB, four-bank implementation plan

Requested on 2026-10-16. Implementation starts from saved commit
`2326f08390f96cebfbb66fbb2afe14a3691fca7a`. The user authorized implementation
after reviewing this plan. The subsequent instruction authorizes full-system
synthesis after the changes and monitoring until synthesis ends. The user then
clarified that the complete flow must continue through bitstream generation,
while this turn only monitors until synthesis ends. Subsystem simulation, RTL
regeneration and local synthesis are included. FPGA/ELF programming is not included.

## Configuration and boundaries

| Parameter | Baseline | Candidate |
| --- | --- | --- |
| Total data capacity | 512 KiB | 1 MiB |
| Banks | 2 | 4 |
| Capacity per bank | 256 KiB | 256 KiB |
| Ways / sets per bank | 8 / 512 | 8 / 512 |
| Line size | 64 bytes | 64 bytes |
| Bank bits / mask | A12 / 0x1000 | A13:A12 / 0x3000 |
| Ordinary / coherence MSHRs per bank | 32 / 2 | 32 / 2 |
| Secondary entries / logical queues per bank | 34 / 102 | 34 / 102 |
| Target frequency | 100 MHz | 100 MHz |

Keep the restored S1 scheduler, MSHR, fast-peek register payload pool, coherence
interlocks and buffer placement. Keep the current Head, TensorIngress, DDR mode
1 register slice, 512-bit/ID2 memory exit, 256-bit/ID5 Tensor port, three DIM32
workers, frontend ABI2, PPU protocol and model arithmetic.

For addresses actually seen by L2, the candidate mapping is:

```text
bank = (address >> 12) & 3
set = ((address >> 6) & 63) | (((address >> 14) & 7) << 6)
```

The complete bank/set period becomes 128 KiB. Generated `l2.json` and decoded
RTL, including restored Probe/writeback/refill addresses, are authoritative.

## Implementation sequence

1. Freeze the baseline RTL, generation context, effective sources and relevant
   existing worktree files. Preserve an explicit two-bank generation profile.
   Candidate artifacts live under `build/`; promote only one complete official
   SoC export. The historical S1 bitstream has different Tensor/DDR settings and
   is not the primary expansion comparison.
2. Parameterize `WithMemoryParallelV3` for two/four banks. Keep 512 sets and eight
   ways per bank. Regenerate BankBinder, SBUS, CacheCork, MemoryBus and internal
   source/sink ID allocation through Chisel/Diplomacy. Check address coverage,
   response ownership and unchanged external interfaces. Do not hand-copy banks
   into generated RTL.
3. Extend performance ABI1.1 to ABI1.2 for the four-bank profile. Keep blocks
   0..13; add bank2/bank3 as blocks 14/15. Keep client bank0/bank1 request slots
   11/12 and completed-D slot13; add client bank2/bank3 slots14/15. Preserve L2
   slot19's bank0-and-bank1 simultaneous-return meaning; append wider concurrency
   counters. Report mask0x3000, capacity1048576, bank count4 and block count16.
   The existing nine-bit selector covers all 512 entries. Verify peak masks,
   reset, commands, snapshots, frozen reads and external block forwarding. Update
   register documentation and parsers. Two-bank fallback retains ABI1.1.
4. Adapt the existing SW-P3 geometry dependencies without discarding its pending
   changes. Read geometry from hardware metadata. Support the old 64 KiB/1024
   colors and new 128 KiB/2048 colors, including storage padding, alignment,
   bounds, scoring and ELF address audits. Keep the initial hardware comparison
   at one common ELF and fixed layout; geometry-specific layout selection is a
   separate comparison.
5. Parameterize coherence/cache/Tensor tests and run both bank counts. Cover all
   banks, partial writes, dirty eviction, CPU ownership, Probe/ReleaseData,
   address-directed flush, Tensor visibility, simultaneous traffic and randomized
   backpressure. Same-bank/same-set tags are separated by 128 KiB in the new
   profile; enlarge test RAM accordingly. Provide at least four independent
   clients for four-bank parallel-service assertions. Exercise each 34-entry
   secondary pool and 32 ordinary MSHRs. Add a 768 KiB uniformly distributed
   working set to demonstrate usable capacity above the baseline.
6. Extend performance comparison to real generated four-bank routing and return
   arbitration, including L2 -> CacheCork -> MemoryBus -> Head. Replay identical
   requests, seeds, memory latency and stalls. Include hits, cold misses, bank
   contention, same-set conflicts, read/write mixtures and capacity thresholds.
   Record cycles, latency, bank distribution, refill/writeback, occupancy and
   stalls. Preserve single-bank hit pipeline depth. Explain regressions rather
   than requiring all changed-bank workloads to be cycle-identical.
7. Run local synthesis of L2 and affected buses, checking inferred memories,
   resources, unresolved cells, combinational paths and 100 MHz timing. Report
   these as local estimates only. Run full-system `synth_1` and its IP dependencies
   in the isolated candidate project, retaining status, logs and checkpoint.
   Automatically continue `impl_1` through `write_bitstream` with the same part,
   clocks and constraints. Monitor this turn until synthesis ends; retain durable
   implementation state, routed setup/hold, DRC, utilization and artifact hashes.
8. Deliver source changes, one regenerated official RTL export, provenance,
   two/four-bank validation and performance records, local synthesis evidence
   and a reproducible fallback. Mark whole-ELF simulation, board measurements,
   placement/routing and bitstream generation as not run unless executed.

## Acceptance and reporting

The four generated banks must provide exactly 1048576 data bytes, 8 ways and
512 sets each, with disjoint bank decode and unchanged functional protocols.
All correctness and progress tests must pass. Counter semantics must match the
published ABI, including the new banks. Neither full-system timing nor board
speedup follows from local synthesis or synthetic traffic results.

Capacity and bank parallelism can reduce misses/contention, but the shared DDR
exit, upstream ports and Head's existing outstanding ceiling remain limits.
No fixed speedup or doubled throughput is an acceptance claim.

The baseline snapshot and implementation evidence are recorded in
`build/reports/l2_1m_4bank/`. The portable validation record will identify actual
completed checks, limitations, generation hashes and fallback commands.
