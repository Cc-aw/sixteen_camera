# Interpreting the full G0 evidence

Use the accepted full decision and per-stage CSV for counts and thresholds.
An opportunity is an actually issued whole Load whose processed bytes already
occupy the same physical SPAD locations, with unchanged source generations,
complete previous bank writes/credit/ROB retirement and no overlapping writer.
The independent deletion replay preserves every real SRAM read at the recorded
times. Its replacement completion tokens retain their original times, so it
does not demonstrate a faster controller or a throughput improvement.

## Candidate scope

The remaining Input reuse is across native packet boundaries. Existing reuse
inside a LoopConv, 54 retained ordinary Input packets, 316 retained ordinary
Weight packets and A1 request grouping are already included in C0.

Prioritize C1a Input exact reuse when its independent whole-network byte
fraction clears the gate. Weight reuse can be evaluated as a separate C1b
branch; do not charge the same saved Get twice or combine branches to hide
that a simpler Input-only prototype already meets the investigation threshold.

A tiny ordinary Mvin LRU is not established by this analysis. Real examples
span tens or hundreds of intervening Mvin commands. A minimal prototype should
first investigate a descriptor for each physical Input tile / Loop slot,
using the actual derived load layout and source/target geometry. It must prove
how many of the measured individual whole-Load opportunities that compact
representation covers. The offline unbounded catalogue is an opportunity
model, not an area estimate or a claim that two arbitrary Mvin entries suffice.

Only complete same-destination loads can be omitted. No source relocation,
operand remapping, partial-row omission, larger SPAD or new weight SRAM is
justified by G0. Same-source/different-destination and partial source overlap
are separately labelled R2 diagnostics.

## Required prototype invariants

- Match source physical bytes/generation, derived layout, scale, format, target
  bank/rows and valid byte masks; a hash alone is insufficient.
- Admit a descriptor only after all real bank commits, not TL return or the
  last DMA credit. Reject all pending overlapping writers.
- Invalidate on every overlapping DMA, zero, EX or other writer, including
  numerically equal writes. Check both Loop slots and physical address overrides.
- Keep HOST/DRAIN/FRAME/reset/fault boundaries conservative. Source-output
  aliases require write-range invalidation or a proved disjoint region.
- Preserve higher-level load/ROB/loop credits with an explicit replacement
  completion path. Do not allocate a DMA tag and discard its transaction.
- Preserve an exact disabled fallback and the four existing DMA modes.

## What remains after G0

G1 must validate the real bypass, earlier completions, complete numerical
outputs, faults, reset, pending bank arbitration and bounded descriptor
coverage. G2 must run matched C0/C1a cycle comparisons with realistic delay,
backpressure and shared-memory contention. CPU/RVV and PPU costs are absent
from the functional memory service; no whole-system FPS or throughput lower
bound is available here. The historical ASRAM parent FPS and timing are not
measurements of this merged C0 or a CSC-R1 candidate.

G0 PASS supports a minimal simulation prototype. It does not support a new
bitstream, a physical timing claim or a claim that the byte fraction becomes
the same percentage of throughput improvement.
