# C0 source audit for G0

Baseline: `hw/versions/dma_load_streaming_asram_512kib_2bank`, generated build
`abd1c8c87558c7b0`, repository HEAD `8d3aa31d8935cb000a3427638f55c5163d36bc0b`.
The baseline source and generation-context audits passed before simulation.
The current experiment has no new hardware fast path.

All Scala locations below are relative to the baseline's
`soc_shell/npu100_video/src/main/scala/gemmini/LoopConv.scala`.

1. `LoopConvLdInput` has `b`, `irow`, `icol`, `ich` iterators around lines
   452–455, with spatial/channel advancement around lines 590–617. There is no
   output-channel iterator that reloads the complete input for each output
   channel. Input loading is gated by a nonzero source around line 567.
2. `LoopConvLdWeight` has kernel/output-channel traversal and a nonzero-source
   gate around line 808. `LoopConvExecute` chooses `COMPUTE_AND_STAY_CMD` when
   `new_weights` is false around line 1080. Existing WS reuse is baseline work.
3. There are two concurrent Loop slots (line 1661). At reset, slot `i` gets
   input base `i * (max_addr / 2)` and weight end `(i + 1) * (max_addr / 2)`
   around lines 2103–2104. With 8 × 2048 rows, the default halves start at 0
   and 8192; they do not establish same-destination residency across adjacent
   slots. Explicit `a_ex_spad_id`/`b_ex_spad_id` overrides are applied at both
   load and execution interfaces around lines 1920, 1940, 1959–1960.
4. `wait_for_prev_loop` and load/execution state coordinate overlapping slots
   around lines 1764–1766 and 1915–1970. A source-address match does not prove
   those completion/consumer dependencies can be bypassed.
5. The verified C0 generation context has A1 row streaming enabled and retains
   legacy/read_coalesced/read_assembled/spad_assembled. Row grouping and reduced
   physical transactions in mode comparisons are existing A1/DMA behavior.

The full native C helper roundtrip reconstructed all 58 ordinary convolution
plans, 462 packets per worker, exactly matching the frozen packet tables. There
are already 54 packets with retained Input operands and 316 with retained Weight
operands. The inventory accounts for their null-operand semantics rather than
charging the hypothetical loads again.

Ordinary native logical spans total 15,262,933 Input bytes, 2,904,768 Weight
bytes, 57,472 Bias bytes and 8,980,800 Output bytes per worker's fixed sequence.
These values are **logical spans only**: they exclude Get alignment, conversion,
SPAD zero/mask effects and nonordinary stages. They are neither actual TL totals
nor a network cycle model. Another 20 prepared stages (224 prepared packets)
and the remaining HOST/data-service stages are inventoried separately.

These facts constrain the search but do not prove G0 PASS or NO-GO. Actual
complete-network load footprints, same physical destination, transformed values,
source versions, all intervening writers and consumer-visible lifetimes remain
necessary. Compact traces can validate the measurement/reconstruction path;
they cannot supply full-network weights or an end-to-end speedup claim.

## Full native extension

The full capture now includes all 20 prepared WS stages and the three pool5 /
two resize stages, executing the frozen C submitters and native memory-kernel
command sequence. Full C0 replay uses real RS/EX/FP16/DMA/A1/SPAD logic and
records every physical write, all SRAM reads, actual TL transactions and
Load credit/ROB completion. The source-generation map follows masked physical
Put bytes and native CPU padding; frame changes invalidate descriptors.

The absence of an output-channel iterator inside one `LoopConvLdInput` does
not eliminate input reloads between separate native packets. Full-size stages
38, 62, 109, 111, 117, 134 and 156 expose remaining same-source/same-physical-
destination input requests after existing software retention. The full
decision and per-stage CSV, rather than compact estimates, determine the gate.

Prepared WS weight reloads are a separate opportunity. They occur after
existing B reuse, not in place of the 316 already-retained ordinary packets.
Input and Weight byte savings remain separate in the report. Repeated zero
loads can be idempotent but never contribute physical Get bytes.

The actual C0 trace demonstrates that DMA credit and ROB retirement can
precede the final queued bank commit. Logical owners therefore stay attached
to accepted bank-queue entries even after a physical command ID recycles.
Cache validity starts only after full physical commit coverage and completion.

The initial source-identity enumeration has synthetic one-cycle backend
credits. Its optimistic statistics are conditional on that issue order;
they are not rigorous bounds for another schedule and do not pass G0.
The actual physical replay and independent fixed-timeline whole-Load deletion
check establish the accepted baseline data-equivalence evidence.
