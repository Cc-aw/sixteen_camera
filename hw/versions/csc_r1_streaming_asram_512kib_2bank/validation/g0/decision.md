# CSC-R1 baseline simulation checkpoint

**Decision: INSUFFICIENT_EVIDENCE. G0 has not passed; no candidate RTL is enabled.**

C0 build `abd1c8c87558c7b0`; repository `8d3aa31d8935cb000a3427638f55c5163d36bc0b`.

## Evidence

- layers: PASS
- asram: PASS
- fault: PASS
- Native roundtrip: 58 ordinary stages, 462 packets/worker; 20 prepared stage inventories.
- Compact trace: 1914 Mvin commands; 1380864 actual TL Get bytes; three lanes, eight stages, read_assembled.
- Same-value-at-commit diagnostic: 64485 bytes. This is not a legal whole-command skip count.
- Stable value-at-issue diagnostic: 84 commands across three lanes. Source epochs and native dependencies remain unproven; this is not a count of eligible skips.

## Scope and decision

Existing LoopConv Input loading has no output-channel iterator. Weight COMPUTE_AND_STAY, native null-operand retention and A1 row grouping are baseline reuse. None is credited to CSC-R1.

Compact layers preserve native channels/weights/packing but shrink spatial dimensions. Their deterministic synthetic inputs do not replay native interstage producer dependencies. The ASRAM matrix exercises real generated TL controllers and vendor URAM primitives. These runs do not execute whole-SoC CPU/RVV or the complete model.

The parent ASRAM driver initially failed before simulation due to generated Python indentation. The experiment adapter fixes only the generated driver; the failed attempt is retained.

Input/Weight exact-resident counts, full-network TL/SPAD totals and legal saved bytes are unmeasured. Candidate cycle reductions, FPS, timing and resource changes are unmeasured. Candidate correctness, new bank conflicts and deadlock behavior have not been assessed.

## Remaining evidence

- Full-size full-network emitted Mvin/SPAD/EX trace and physical source-generation lifetimes
- Single-lane lifecycle trace and native prepared-WS/HOST/Head/PPU boundaries
- Legal whole-command exact-resident opportunities and full-network actual DMA denominator
- Candidate RTL correctness and same-workload cycle A/B (conditional on G0 PASS)

Physical implementation is not justified by this checkpoint. No synthesis, implementation, bitstream generation or board access was performed.
