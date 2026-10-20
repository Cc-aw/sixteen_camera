# CSC-R1: simulation-first residency investigation

The current C1a prototype replaces the future-Store drain with a checked
source/output range proof; see [the optimization regression](validation/g1_store_wait/README.md).
The earlier global-drain prototype and its measurements remain immutable in
[validation/g1](validation/g1/README.md). G2/system throughput and physical
implementation require separate evidence.

Full G0 results are archived separately in [validation/g0_full](validation/g0_full/README.md).
The original compact-only checkpoint remains unchanged in [validation/g0](validation/g0/README.md).
Current full-G0 source hashes are in `manifests/G0_FULL_SOURCE_ORIGINS.json`;
`manifests/SOURCE_ORIGINS.json` retains the original compact-checkpoint identity.

This is an independent G0 analysis and experimental G1 prototype directory. The hardware baseline is
`dma_load_streaming_asram_512kib_2bank`, build `abd1c8c87558c7b0` (C0).
A switchable C1a generated-RTL prototype is implemented; see
[its design and limits](analysis/c1a_design.md). Functional and performance
acceptance require their own recorded evidence. Parent sources, existing
candidates and production `hw/soc/` are read-only inputs.

C1a commands use a new output root and the frozen full G0 build:

```sh
F="$PWD/hw/versions/csc_r1_streaming_asram_512kib_2bank"
OUT="$PWD/build/experiments/csc_r1/<new-g1-run>"
G0="$PWD/build/experiments/csc_r1/g0_full_20261019_01"
CTX="$PWD/build/experiments/dma_stream_asram/candidate_02/GENERATION_CONTEXT.json"
make -C "$F" init CSC_OUT="$OUT"
make -C "$F" candidate-prepare CSC_OUT="$OUT" DMA_CONTEXT="$CTX"
make -C "$F" candidate-build CSC_OUT="$OUT" \
  CANDIDATE_CONTEXT="$OUT/candidate/CANDIDATE_CONTEXT.json" \
  REFERENCE_BUILD="$G0/full_rtl_complete_serial"
make -C "$F" test-csc-unit CSC_OUT="$OUT"
python3 -B "$F/analysis/directed_reuse_fixture.py" \
  --reference "$G0/calibration_serial_complete" --output "$OUT/directed"
python3 -B "$F/scripts/run_candidate.py" --build "$OUT/candidate_rtl" \
  --commands "$OUT/directed/commands.txt" --memory "$OUT/directed/memory" \
  --output "$OUT/directed_on" --lanes 0,1,2 --enabled 1 --mode 2 --frames 3 --last-stage 4
```

The Store-wait regression reuses the accepted G0/G1 numerical references and
rechecks OFF cycle identity with the new build. Prepare its source-writer
fixture, then run each suite once in a new output root:

```sh
PRIOR="$PWD/build/experiments/csc_r1/g1_20261020_01"
python3 -B "$F/analysis/store_hazard_fixture.py" \
  --reference "$PRIOR/directed_fixture_03" --output "$OUT/store_hazard_fixture"
for suite in smoke regression network; do
  python3 -B "$F/scripts/test_optimized_regression.py" \
    --build "$OUT/candidate_rtl" --prior "$PRIOR" --g0 "$G0" \
    --output "$OUT" --suite "$suite"
done
```

`smoke` checks seven actual full-size reuse layers, SPAD/output bytes and all
Accumulator bytes at completed fences. `regression` checks four modes, three
lanes, three distinct frames, source/config/writer hazards, mode switching,
fault/reset and disabled event/cycle identity. `network` executes all 166
native stages on each of three independent functional lanes, then compares
every consumer/output byte and closes the physical transaction ledgers.
All three use the unchanged private functional memory service; they do not
measure shared-memory throughput. Historical source identities in
`G1_SOURCE_ORIGINS.json` describe the earlier archive; the new acceptance uses
`G1_OPT_SOURCE_ORIGINS.json`.

Run the matched `--enabled 0` control into another directory, then compare
each lane with `analysis/compare_candidate.py`. The archived G1 report lists
the complete actual matrix, mode-isolation, fault/reset, Accumulator and full
native-workload evidence. `run_candidate.py` and `run_accumulator.py` relink
only observational drivers against the checked RTL archive. Outputs refuse
existing simulation directories. No command here performs a physical build.

The adapter runs the parent test frameworks against hash-verified real RTL.
It extends SPAD collection to all three lanes and records physical TL and raw
command handshakes. It also repairs a Python indentation error in the parent's
generated ASRAM driver, only in new experiment output. Test workloads and RTL
remain unchanged. All four modes are checked against legacy for compact layers.

From the repository root, use absolute paths because make changes directory:

```sh
F="$PWD/hw/versions/csc_r1_streaming_asram_512kib_2bank"
OUT="$PWD/build/experiments/csc_r1/<new-run>"
CTX="$PWD/build/experiments/dma_stream_asram/candidate_02/GENERATION_CONTEXT.json"
make -C "$F" init CSC_OUT="$OUT"
make -C "$F" test-unit
make -C "$F" inventory CSC_OUT="$OUT"
make -C "$F" trace CSC_OUT="$OUT" DMA_CONTEXT="$CTX" MEMORY_LATENCY=1
make -C "$F" baseline-asram CSC_OUT="$OUT" DMA_CONTEXT="$CTX"
make -C "$F" baseline-fault CSC_OUT="$OUT" DMA_CONTEXT="$CTX"
make -C "$F" analyze CSC_OUT="$OUT"
make -C "$F" decide CSC_OUT="$OUT" DMA_CONTEXT="$CTX"
```

`init` refuses an existing run root. Each simulation/inventory/analysis requires a new output subdirectory and
refuses overwrites. `decide` returns exit code 2 for insufficient evidence and
writes the checkpoint decision and evidence manifest. Missing dependencies,
hash mismatch, incomplete traces and functional mismatches fail rather than
producing PASS. There are no synthesis, implementation, bitstream or board targets.

`MEMORY_LATENCY=1` is the parent's existing compact functional-test option;
the default is 7. It preserves shape, input, weights, commands and comparison
scope. The separate ASRAM/fault suites retain delay/backpressure stress. Neither
configuration provides a CSC-R1 performance result. Interrupted diagnostics
must be retained separately and excluded from accepted evidence.

The trace schema and its gaps are explicit in [trace_schema.md](analysis/trace_schema.md).
Compact shape measurements do not provide network weights, G0 PASS, candidate
speedup or full-model FPS. Same-value writes are diagnostics, not legal skips.
G1 candidate RTL and G2 cycle commands will be added only if G0 passes.

## Full native G0

The full path captures all 166 nonterminal graph stages: 58 ordinary Conv
stages, 20 prepared WS stages, three pool5 and two resize stages. Each lane/frame
contains 462 Conv packets, 224 WS packets, 1,944 memory-kernel Mvin and 624
memory-kernel Mvout. Two frames retain the native ASRAM aliases and explicitly
invalidate residency at the frame boundary. Frozen weights/bias and a full
480x640x3 deterministic input fixture initialize the functional memory.

Use a new initialized run root and a verified compact XSim trace:

```sh
make -C "$F" whole-capture CSC_OUT="$OUT"
make -C "$F" full-rtl-build CSC_OUT="$OUT" DMA_CONTEXT="$CTX"
make -C "$F" calibrate-full CSC_OUT="$OUT" COMPACT_TRACE="$COMPACT_XSIM"
make -C "$F" full-single CSC_OUT="$OUT"
make -C "$F" full-parallel CSC_OUT="$OUT"
make -C "$F" analyze-full CSC_OUT="$OUT"
make -C "$F" decide-full CSC_OUT="$OUT"
```

Set `COMPACT_XSIM` to an existing hash-verified compact XSim output directory.
The complete Gemmini closure executes real RS, EX, FP16, DMA, A1 and SPAD
memories. The private deterministic physical-memory service is functional;
it provides no shared DDR/ASRAM, CPU/RVV or PPU timing model. Each functional
lane may run in its own host process, preserving its physical address identity
and stall seed. A reused lane-0 trace is explicitly identified if it also serves
as the single-lane control. Functional cycles are not full-system FPS.

`PIPELINE_WATCHDOG=60000` uses an existing native simulation plusarg. The
default 10,000-cycle check rejects the long legal SPPF operation; an isolated
unchanged pool5 replay completes with 60,000 while all RTL assertions remain
enabled. Default-timeout failures and interrupted diagnostics are retained and
excluded from accepted comparisons.

Whole descriptors require actual prior SRAM commit, unchanged per-byte source
generations and no pending or intervening overlapping write. New candidate
commits must be individually idempotent. Credit/ROB completion alone is
insufficient: a DMA tag can recycle while the old final bank write is queued.
Zero-load opportunities save no Get bytes. Same-source/different-destination
counts are separate R2 diagnostics. An independent whole-Load deletion replay
then removes the qualified writes while retaining original local completion
and consumer times; every real SRAM read must remain byte-identical. This
fixed-timeline model establishes data equivalence, not an RTL speedup.

The preliminary `command-rtl-build` / `command-enumerate` targets use the real
unrollers with synthetic backend credits. Their optimistic source-identity
figures are conditional on that synthetic issue order. They are not legal
reuse counts, measured TL traffic or rigorous bounds for a different schedule.

See [full_trace_schema.md](analysis/full_trace_schema.md) for formats,
qualification rules and the experiment-local Xilinx primitive adaptation.
`decide-full` can mark G0 PASS only after the physical evidence meets the byte
gate. G0 PASS still leaves the final physical-prototype decision insufficient
until G1 and G2 pass. Missing whole-system hotspot evidence never becomes GO.
