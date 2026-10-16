# Head / L2 urgent validation — 2026-10-15

Actual baseline: `3440bc10a15467f7ba42bb2ffac21a343e1956d6`, matching the task
specification. The supplied implementation specification was initially untracked
and remains intact. Changes are delivered in the working tree; no unrelated
source changes, board downloads or flash writes were performed.

H1 is enabled in the production bridge (`READ_DECOUPLE=1`, per-ID waiting
FIFO=8, total acceptance credit=32). L1 is enabled with 68 shared secondary entries
per bank. MSHRs remain 32+2/bank, logical queues 102, response credit four,
512 KiB/2 banks, target 100 MHz, MPV3 ABI1.1 and frontend ABI2.

| Executed check | Result / evidence |
| --- | --- |
| `make test-head-read-decouple` | PASS: 512/256 and 256/256, five seeds each × 10,000 random requests; 512 legacy × 10,000; directed H01–H12 and v3 shadow compatibility |
| Head deterministic progress comparison | PASS: optimized Head completes while ID0 DDR is held; legacy early completions=0, optimized=1 |
| `make test-l2-secondary-capacity SOC_WORKSPACE=...` | PASS: actual 34/68 RegisteredListBuffer, 102 queues, five seeds each × 20,000 random cycles; all results drained and checked |
| Real dual-bank cache capacity observation | PASS: secondary peak=68, 96 same-set requests, cycles=2530, probes=2; all expected returns checked |
| `make test-memory-v3` | PASS: legacy Head width/local-port, 32-outstanding and statistics regressions preserved |
| `make test-cache` | PASS: regenerated production L2 control test |
| `make test-ppu` | PASS: original publication suite |
| `make test-tensor-ingress SOC_WORKSPACE=...` | PASS: explicit 68-entry dual-bank harness; tensor_overlap=72, probes=2, dirty flush/eviction; cycles=3374 |
| `make test-v3-timing-repair SOC_WORKSPACE=...` | PASS: original pool/cache/vendor DDR-slice tests; modes 7 and 1 |
| `make test-frontend SOC_WORKSPACE=...` | PASS: Chisel cycle equivalence, widths, real three DIM32 Gemminis, matmul/conv/SILU, write acknowledgement and IRQ isolation |
| `make test-v33` | PASS: ELF/manifest, native plan comparison, sanitizer dispatch, PPU lifecycle and log contracts; no hardware accessed |
| `make check-deps` | PASS after synchronizing only changed source/import digests |
| Generated-RTL structure / hash audit | PASS: 784 generated collateral files, exact e68 memory and scheduler, 7-bit entry pointers, four credits including pending read, original cache geometry and ABI |
| Head OOC synthesis on production part | PASS: xcvu13p-fhga2104-2-i, 192 URAM, 4248 LUT, 4036 FF; reports/DCP in `build/reports/head_l2_urgent/head_ooc_board/`; full-chip timing unverified |
| H1/L1 reverse patch checks | PASS: independent functional source patches; source rollback requires manifest refresh and hardware rebuild |

Full logs, exact commands, exit codes and source fingerprints are in
`build/reports/head_l2_urgent/validation_results.json` and
`validation_summary.txt`. Initial failed attempts are retained beside final
logs. The final validation records identify the successful commands.

The private workspace was rebuilt from the complete reference, with the frozen
reference restored before V3 overlay and command frontend integration:

```sh
python3 tools/soc/build_triple32_v3_tensor.py \
  --reference /home/wzr/chipyard \
  --workspace /tmp/sixteen-camera-head-l2-urgent-chipyard
```

This rebuilt Scala and elaborated RTL; neither old `--resume` assembly nor manual
RTL modification supplied the capacity change. Generation context and effective
Scala hashes are in the sole production SoC directory and
`hw/soc/source/shell/V3_EFFECTIVE_SCALA.sha256`. The detailed delivery manifest is
`build/reports/head_l2_urgent/implementation_manifest.json`; it records source,
Scala, parameter-header, generated RTL, test and patch digests.

Local environment issues were resolved without relaxing checks:

* Installed Verilator 5.044 crashed internally on the optimized interface
  hierarchy. Installed 5.022 compiled and passed the complete Head regression.
  `HEAD_VERILATOR` in ignored local tool configuration selects it.
* The Conda C compiler's sanitizer runtime crashed in the V33 dispatch test.
  Retrying with system `cc` but Conda `ld` exposed a linker ABI mismatch. A local
  `/tmp/head-l2-urgent-tools/cc` wrapper executes `/usr/bin/cc` with
  `PATH=/usr/bin:/bin`, preserving ASan/UBSan and all tests. Both diagnostic modes
  then passed. Software source, plans, inputs and golden values were not changed.
* The source checker detected three stale imported digests. Updated only those
  entries in `LATEST_HARDWARE_IMPORT.json`, retaining original donor hashes and
  annotating the local candidate. Frozen reference files were unchanged.
* Existing generated L2 tests report narrow-index warnings at Scheduler.scala
  lines 351–352; the original MSHR ownership algorithm was retained. Assertions,
  same-set stress, probes, dirty writeback and reload checks passed.

The complete implementation command is:

```sh
python3 tools/build/launch_head_l2_urgent.py
# supervisor runs the existing locked make bitstream flow
python3 tools/build/launch_head_l2_urgent.py --status
```

It uses the existing project, IP reconstruction, SLR/pblock and timing strategies.
No frequency reduction or new false-path exception was introduced. Separate
manual `make project` / `make elaborate` stages were not run: project preparation
and synthesis are part of the single complete build requested by the user.

The live build state is `build/reports/head_l2_urgent/implementation_state.json`,
with console output in `logs/full_implementation.log`. The active full-flow
Vivado report directory is
`build/bitstream/triple32_v3_tensor/20261015_222657_12/`.
The user requested monitoring only through synthesis completion; placement,
route, final setup/hold, CDC/bus-skew and bitstream acceptance require completion
of the continuing full flow. They must not be inferred from local synthesis.

Independent functional patches:

```text
build/reports/head_l2_urgent/patches/H1.patch
build/reports/head_l2_urgent/patches/L1.patch
```

See [architecture / rollback](../architecture/head-l2-urgent.md) for exact
parameter, checker and manifest restoration steps. Both patches exclude generated
RTL; regenerating after source rollback is mandatory.

```text
BOARD_RUN=NOT_RUN
MODEL_THROUGHPUT=NOT_MEASURED
SPEEDUP_2P8_OR_3P0=NOT_CLAIMED
```

## Synthesis handoff

Full top synthesis completed at `2026-10-15T15:10:11.900603+00:00`: **PASS**, 0 errors, 0 critical warnings, 960 warnings; `synth_design` elapsed 32m51s. The DCP was fully written and the synthesis run exited normally.

The archived candidate is `build/reports/head_l2_urgent/candidate/top_wrapper.dcp`, SHA256 `0a1192684efd2a34793575a95768d030e7e3178a4037dc03532d477278bb23dc`. Its utilization report and synthesis log are beside it.

Synthesis utilization (before placement/route): CLB LUTs=829425, CLB Registers=818230, Block RAM Tile=1435, URAM=372, DSPs=2999. These are synthesis counts, not final routed utilization or timing acceptance.

The same complete bitstream build remains running. Route/final setup-hold/CDC/bus-skew validation is **NOT_RUN at handoff**, with no new candidate bitstream generated yet. Monitoring stopped after synthesis as requested; the background build was not terminated.

## 2026-10-16 routed export continuation

The original complete run failed in `postroute_timing_close.tcl` because an implementation child process had no `impl_1` run object. The hook now writes reports under its current run directory and checks for missing timing paths explicitly. `tests/tools/test_postroute_hook.py` passed with no project/run API objects; the original conditional optimization policy remains unchanged.

The user explicitly requested no timing repair and direct continuation. No RTL or Scala source was changed. A new export opens the saved `top_wrapper_routed.dcp` directly, without synthesis, placement, routing, additional physical optimization, DRC severity overrides or new timing exceptions. The old failed run and its logs remain intact.

The saved checkpoint precedes the lost post-route optimization state: its routed WNS is -2.046 ns and TNS -25294.131 ns (rather than the later unsaved -1.784 ns). The independent export is recorded in `implementation_state.json` and a new `resume_routed_*` artifact directory; it is not a timing-approved candidate.

Reproduction:

```sh
python3 tools/build/resume_head_l2_bitstream.py --vivado /mnt/data/Vivado/Vivado/2023.2/bin/vivado
python3 tests/tools/test_postroute_hook.py
```

Routed export finished successfully at `2026-10-16T01:08:50.927081+00:00`. Bitstream: `build/bitstream/triple32_v3_tensor/resume_routed_20261016_085128_446620/video_triple32_v3_tensor_timing_unmet.bit` (113318492 bytes), SHA256 `a5a828aa318e05e1d1fa6f1b5954f3175aa0777abfd447c920f00afdc44091ed`. Vivado exit=0, write_bitstream DRC errors=0; routing errors=0.

Status: **BITSTREAM_TIMING_UNMET**. WNS=-2.046 ns, TNS=-25294.131 ns, WHS=0.002 ns, THS=0.0 ns. Bus-skew constraints reported=107, failures=0, worst slack=1.636 ns. This export did not repair or waive timing; no bitstream/firmware download or Flash write was performed.

The Vivado project’s original failed implementation-run marker is retained as historical evidence; the independent routed export’s status/logs above identify the generated file. `routed_export_summary.json` records report hashes, checkpoint identity and bitstream SHA256.

## 2026-10-16 user-supplied board comparison: performance regression

After the export and commit `f0da4cc`, the user supplied
`build/reports/v33/board/comparison_sessions.txt` and its companion JSON,
reporting the same ELF on the old and new bitstreams. The user confirmed that
the slower bitstream is new: session 1 is new, session 2 is old. Both sessions
have identical V33 build headers, diagnostics=0, 12 frames per mode, 144 HOST
calls, and pass the log consistency checks. The logs do not contain bitstream
or ELF digests; artifact identity and ELF equality are user-reported.

| Mode | Old cycles | New cycles | Extra cycles | Cycle increase |
| --- | ---: | ---: | ---: | ---: |
| direct_serial | 112,647,754 | 114,332,552 | 1,684,798 | 1.496% |
| frontend_serial | 110,990,867 | 112,666,357 | 1,675,490 | 1.510% |
| frontend_parallel | 43,581,680 | 45,695,489 | 2,113,809 | 4.850% |

Parallel throughput decreases by 4.626% (the reciprocal of the cycle ratio).
Direct-to-parallel scaling falls from 2.584750x to 2.502053x. All 12 serial
frame lifetimes in the new session exceed all corresponding old-session
lifetimes; this is not just one slow first frame. Parallel observed refill gaps
sum to 868 cycles new versus 863 old, and IRQ body time is 5,711 versus 5,276
cycles. These small changes do not explain the 2,113,809-cycle group difference.
CPU padding rises from 588,194 to 889,176 cycles in parallel, and about 27% in
both serial modes. These service times can overlap frame execution and are not
additive savings. Frame ownership overlap and sparse busy samples are not
continuous compute utilization.

A new router-only offline comparison exercised the actual production router
with `READ_DECOUPLE=0/1`, 512-bit data, two-bit IDs, and identical synthetic DDR
return delays. Each run checked all 640 responses / 1,408 beats using the
existing data/order scoreboard. With no response backpressure, 128 isolated
single-beat reads had the following upstream AR-to-RLAST latency:

| Synthetic endpoint delay | Legacy latency | H1 latency | Extra cycles |
| --- | ---: | ---: | ---: |
| 0 | 1 | 4 | 3 |
| 16 | 17 | 20 | 3 |
| 64 | 65 | 68 | 3 |

H1 adds two forward request stages (enqueue/dispatch and DDR AR register) and
one return FIFO stage even to ordinary DDR-only reads. This is a demonstrated
latency cost, not a demonstrated explanation of the entire board regression.
Pipelined one/four-beat traffic also completed correctly; the synthetic producer
issues at most one request per two cycles, so this experiment does not measure
peak AR bandwidth. Reproduce from the repository root with
`python3 build/reports/head_l2_urgent/board_regression_probe/run_probe.py`.
The generated bench, compile/run logs, `probe_results.json`, and the board
comparison with input SHA256 are in that same directory.

The earlier regressions proved ordering, cross-ID progress and usable secondary
capacity, but did not enforce DDR latency against legacy. This missing comparison
is material to evaluating H1. H1's fixed cost is the first confirmed issue to
investigate; the contribution of L1=68, shared-resource contention and Head wait
is not isolated by these diagnostics=0 sessions. No H1-only/L1-only board result
is available. The candidate remains timing-unmet (WNS=-2.046 ns); negative slack
does not itself establish the cause of a cycle-count increase or imply automatic
clock reduction.

Current performance evidence is **USER_BOARD_REGRESSION**, superseding the
earlier synthesis/export handoff's NOT_RUN/NOT_MEASURED status for user-supplied
V33 timing only. Cross-mode consistency passes within each boot; independent
accuracy and cross-bitstream output equality are not established by the summary.
No new hardware/firmware build, FPGA download, timing repair or performance fix
was performed during this analysis. No speedup is claimed.

## 2026-10-16 comparison with the specified S1 frontend bitstream

The user requested comparison with
`/mnt/data/sunys/sixteen_camera_3x32_100mhz_memory_parallel_v3_maxpool_timing_s1_2026-10-14/prj/sixteen_camera.runs/impl_frontend/top_wrapper.bit`.
Its recomputed SHA256 is
`0bfaf3edb45f738f6ee1ade4409f20b862896cd01e638e78c622dd032ab07229`,
matching the existing command-frontend import manifest. The current bitstream
SHA256 remains
`a5a828aa318e05e1d1fa6f1b5954f3175aa0777abfd447c920f00afdc44091ed`.
Both files are 113,318,492 bytes and identify Vivado 2023.2 and
`xcvu13p-fhga2104-2-i`. Equal file size does not mean equal hardware.

The comparison checked the donor's actual `synth_frontend/top_wrapper.tcl`
inputs, generated RTL, source Scala, generated DDR block design/IP wrappers,
constraints and implementation/export logs. This is source/provenance inspection,
not formal equivalence between routed netlists.

| Area | Specified S1 frontend hardware | Current hardware |
| --- | --- | --- |
| Command frontend | Three autonomous lanes | Cluster/engine/memory mux/TL generated RTL byte-identical |
| Gemmini | Three DIM32 engines, MaxPool and existing arithmetic | Three Gemmini core files, checked execute/load/store/mesh RTL and all three parameter headers byte-identical |
| Head reads | Global DDR drain before local Head; original DDR path | H1 per-ID queue/ownership, registered DDR AR, separate two-beat return FIFOs |
| L2 secondary capacity | 34 entries per bank | L1: 68 entries per bank |
| L2 secondary/reload implementation | `ListBuffer_QueuedRequest_q102_e34_fast`, combinational peek and direct reload/bypass | `RegisteredListBuffer_q102_e68`, synchronous payload/result channel, reserved reload ownership and directory reread |
| L2 scheduling | Combinational round-robin winner | Registered, grouped round-robin winner with live revalidation |
| Tensor producer ingress | Existing shared FBus path | Dedicated Tensor AXI ingress into SBUS; publication retains FBus |
| TL source encoding | L2 inner source width 9 bits; SBUS crossbar has 5 inputs | Width 10 bits; SBUS crossbar has 6 inputs due to TensorIngress |
| DDR final register slice | All five `C_REG_CONFIG_* = 7` (LIGHT_WT) | All five `C_REG_CONFIG_* = 1` (fully registered) |
| Implementation state exported | `top_wrapper_postroute_physopt.dcp` | Saved `top_wrapper_routed.dcp`, before subsequent unsaved physical optimization |
| Setup slack | WNS -1.990 ns | WNS -2.046 ns; both builds fail timing |

L2 geometry, bank selection A12, 32+2 MSHRs per bank, 102 queues, 100 MHz SoC,
512-bit/ID2 external memory and DDR4 memory-part/width/period settings remain
the same. After stripping generated metadata, the DDR BD's functional parameter
differences are the five register-slice mode changes; it also adds S00 clock's
associated-reset annotation. The register modes were verified in both generated
synthesis wrappers, not just reconstruction Tcl. The vendor RTL identifies mode
7 as a one-stage lightweight slice with bubble cycles and mode 1 as fully
registered; neither parameter value alone predicts whole-model performance.

Several differences predate H1/L1. Comparing Git baseline `3440bc1` confirms
that its Head router and bridge match S1 after module renaming, while its L2
registered scheduler and DDR mode-1 reconstruction script already match current
sources. TensorIngress, memory-performance extension and video/CDC changes also
predate H1/L1. Additional handwritten changes include HDMI demux timing,
Tensor DMA error cleanup and asynchronous Tensor write CDC. Three PPU lookup
files differ only in generation-path comments. Five of the six board XDC files
are byte-identical; `clk.xdc` differs in camera placement guides, reset first-stage
exceptions and Tensor CDC coverage. Current DDR locality uses the shared V3
placement hook rather than S1's hard slice-only pblock.

Therefore, if this S1 file is the old board-test bitstream, the comparison is
**not an H1/L1-only experiment**. The router probe's +3-cycle result remains a
valid isolated H1 observation, but the board regression cannot be assigned to
H1/L1 alone. The registered L2 scheduler/reload path, Tensor/SBUS topology and
DDR slice differences must be included in subsequent attribution.

Machine-readable file/hash comparisons and focused diffs are retained in
`build/reports/head_l2_urgent/s1_comparison/`: `bitstreams.json`,
`source_comparison.json`, `unchanged_core_checks.json`,
`baseline_classification.json`, `ddr_bd_differences.json`, `evidence_hashes.json`
and the Scala/RTL/XDC diff files. No hardware source was changed or rebuilt for
this comparison.


## Earlier performance checkpoint: group_live (superseded, 2026-10-16)

The comparison now runs actual S1 generated L2 RTL, the `f0da4cc` generated
L2 snapshot, and the optimized sole production export against the same checked
workload. Test sources and reproduction commands are in
[`tests/rtl/performance/README.md`](../../tests/rtl/performance/README.md).
Raw logs, compiled source digests and JSON are retained under
`build/reports/hardware_performance/`. The selected candidate is `group_live_cork`;
`comparison.json` verifies that its compiled RTL hashes match the current
`GENERATION_CONTEXT.json`. It checks 64 matching L2 scenarios: 32 with 512
requests and 32 with 4096. All scoreboards pass; 57/64 cases match or beat S1
within a separately reported two-cycle startup/tail allowance. All hot cases
meet that allowance. **Not all cold cases have caught up with S1.**

Representative elapsed clocks (lower is faster):

| Workload | S1 reference | Before optimization | Selected candidate |
|---|---:|---:|---:|
| 512 serial hot reads, window 1, delay 32 | 4609 | 5121 | 4609 |
| 512 independent hot reads, window 24, delay 32 | 1031 | 1543 | 1031 |
| 512 same-set hot reads, window 24, delay 32 | 1031 | 3076 | 1033 |
| 4096 same-set hot reads, window 24, delay 32 | 8199 | 24580 | 8201 |
| 512 cold reads, window 24, delay 32 | 1490 | 1817 | 1457 |
| 4096 cold reads, window 24, delay 32 | 13802 | 18639 | 13849 |
| 4096 cold reads, window 24, delay 64, stalls, seed 151034 | 15652 | 20085 | 16734 |
| 4096 cold reads, window 96, delay 64, stalls, seed 151034 | 16449 | 20661 | 15380 |

The remaining window-24 cold-read differences are 2.78–3.98% at 512 requests
and 6.43–8.32% at 4096 with random stalls. Even the unstalled 4096-request cold
case remains 47 clocks (0.34%) behind S1. Window-96 long cold tests are faster
for all three seeds. These are subsystem cycle counts, not measured V33 speedups.

The remaining cold window-24 case also helps separate the causes: all three
versions execute 9597 scheduling events and reach zero secondary-pool occupancy
in the 4096-request, delay-64, seed-151034 run. Thus that particular remaining
gap does not come from secondary reloads. Cycles with live eligible work but no
selection fall from 6044 before optimization to 1279 in the candidate (S1: zero).
Registered candidate selection and arbitration/backpressure ordering remain
relevant. Bubble counts cannot simply be added to elapsed-time differences:
the window-96 candidate still has 3158 such cycles while finishing faster than
S1 because other work overlaps them.

The L2 endpoint answers clean ReleaseAck locally, as production TLCacheCork does.
Earlier delayed-ReleaseAck experiments remain in the report tree as pressure
models and are not mixed into this comparison. One bank, synthetic memory
latency, read-only requests and controlled source windows do not model the full
DDR controller, both-bank interference, CPU/Gemmini execution or routed timing.
The S1 RTL is from the dated directory audited above; the `before_cork` snapshot
is the pre-optimization committed export. Workload hashes must match across all
three comparisons, and binary reuse is refused after source changes.

The selected implementation preserves synchronous secondary payload storage,
68 physical entries, 102 logical queues, four response credits, 32+2 MSHRs,
registered candidate identities, set ownership, nested coherence interlocks and
directory validation. Safe ordinary-Get descriptor prefetch overlaps RAM read
with owner execution. Per-queue prefetch ownership, oldest eligible result
selection and a reserved urgent credit prevent speculative work from blocking
independent or higher-priority coherence progress. Prepared grouped arbitration
choices are revalidated against live resources. Refills still set `repeat=false`
and re-read the directory; no metadata reuse bypass was added.

H1 now sends an eligible just-accepted DDR AR directly into the existing AR
register, preserving buffered-request priority, target ownership and upstream
credit retirement. Isolated DDR reads incur **2 extra clocks** over
`READ_DECOUPLE=0`, down from 3; the registered AR/R boundaries remain. Endpoint
delays 0/16/64 and four traffic patterns pass response scoreboards for both
modes (896 transactions, 1664 beats per run). At delay 64, continuous single-beat
reads take 576 clocks versus 584 before optimization and 560 in legacy mode.
The source hashes are in `head_before/results.json` and `head_final/results.json`.

Verification of the selected final sources:

* `head_regression.log`: full Head ordering/backpressure/ownership regression,
  five random seeds, 512/256-bit configurations, legacy and shadow modes: PASS.
* `coherence_group_live.log`: 34/68-entry randomized pool tests, five seeds each,
  four-credit and eligibility/stability tests, real dual-bank coherent cache:
  PASS. Cache test reaches 68 secondary entries, exercises 96 same-set requests,
  probes, dirty flush and dirty ReleaseData concurrent with queued reads.
* `tensor_final.log`: TensorIngress protocol and real L2/CPU overlap, dirty
  eviction/flush and probes: PASS (`cycles=3001`, `tensor_overlap=64`).
* `regenerate_group_live.log`: official Scala/Chisel generation, memory mapping,
  sole export refresh and structural checks: PASS. Generated RTL was not patched
  by hand. `structure_final.log` and `check_final.log`: PASS.
* `ooc/head/result.txt`: actual Head synthesis PASS, WNS +6.515 ns.
  `ooc_group_live/l2/result.txt`: actual final L2 synthesis PASS, WNS +0.115 ns,
  hold +0.064 ns. These are unplaced subsystem estimates, not full-design timing.
* `check_deps.log`: FAIL on the separately modified
  `sw/benchmarks/frontend/scripts/prepare.py` source digest. Hardware import
  digests are refreshed; the unrelated software edit was retained. No dependency
  check success is claimed for that whole-workspace run.
  `hardware_provenance.json` separately verifies all 170 hardware import records
  and all 782 generated export files: PASS.

During test development, an initial dirty-ReleaseData test released a CPU line
that its warm-up had already evicted. The retained failing log is not a hardware
regression result. The corrected test first verifies both lines remain resident
and the CPU owns the released dirty line; it passes on the final candidate.
Exploratory schedulers and their synthesis/performance logs remain separate from
the selected `group_live_cork` result.

Independent Head/L2 source rollback patches are in
`build/reports/hardware_performance/patches/`. The original H1 enable and L2
34-entry capacity fallbacks remain available as documented in the architecture
record. Source rollback requires refreshing provenance and regenerating L2 RTL.
`candidate_manifest.json` hashes the selected test results, source rollback
patches, test sources and generation context; `comparison.csv` gives all cycle
comparisons in tabular form.

The complete standard `make bitstream` flow was launched at
`2026-10-16T02:52:32Z` (10:52:32 local). Its independent state, input hashes and
log are in `build/reports/hardware_performance/full_implementation/`;
the earlier `head_l2_urgent/implementation_state.json` and exported bitstream
remain historical evidence. Monitoring stops at synthesis completion; the flow
then continues implementation automatically. Full routed timing, a bitstream
for this optimization, board validation and full-model V33 performance are
**NOT VERIFIED / NOT MEASURED** at launch. The earlier bitstream does not contain
these optimizations and must not be relabeled as the new candidate.

The user subsequently requested completing the remaining optimizations before
full synthesis. That launch was interrupted (exit 130) before synthesis
completion; the build lock was released. Its state is `STOPPED_BY_USER`, not a
synthesis pass. Further scheduler experiments precede any replacement full
implementation launch. The results above remain the measured `group_live_cork`
checkpoint, rather than validation of subsequent source edits.

## Final optimization candidate (2026-10-16)

This section supersedes the `group_live` checkpoint above. Final source selection
is `owner_candidates`: synchronous safe secondary prefetch, two-owner registered
identity preparation with live global cyclic arbitration, Head direct-to-AR
registration, and V3 outer A/data-D empty-queue flow. Control D acknowledgements
remain registered. All five inner buffers, the vendor mode-1 DDR slice, Head
AR/R register boundaries, acceptance limit 32, per-ID ownership through upstream
RLAST, and directory re-read on refill remain in place. No capacity, MSHR count,
ID width, cache geometry, firmware ABI, model or golden result was changed by
this optimization.

The final performance evidence adds the **actual** generated L2 scheduler,
TLCacheCork, MemoryBus, TLToAXI4, AXI4IdIndexer, AXI4UserYanker and Head router to a
checked synthetic AXI memory. Single-bank comparisons contain 32 scenarios at
each of 512/4096 requests. Two-bank comparisons contain 40 scenarios at 512 and
176 at 4096, including 20 seeds for stalled windows 24/96 and unstalled shared
credit saturation at delays 64/128. Every returned source/data/beat is checked.
Bank A12 restoration matches the production wrapper; the upstream two-beat
response arbiter is a common test harness component. PPU/local Head traffic is
inactive in this read-only comparison. Separate Head/coherence/Tensor tests
exercise the remaining protocol paths.

Representative actual-path cycles, **4096 requests**, lower is faster:

| Banks / workload | S1 | Before (`f0da4cc`) | Final |
| --- | ---: | ---: | ---: |
| One / isolated hot reads | 36865 | 40961 | 36865 |
| One / isolated cold reads | 185726 | 206206 | 185726 |
| One / same-set hot reads, window 24 | 8199 | 24580 | 8201 |
| One / cold, window 24, delay 64, stalls, seed 151036 | 15707 | 20134 | 15772 |
| Two / isolated cold reads | 184969 | 205449 | 184969 |
| Two / same-set hot reads, window 24 | 8199 | 8200 | 8199 |
| Two / cold, window 24, delay 64, stalls, seed 151036 | 13673 | 14612 | 13670 |
| Two / cold, window 96, delay 64, no stalls | 8521 | 9514 | 8775 |
| Two / cold, window 96, delay 128, no stalls | 16713 | 17099 | 16980 |

Hot throughput matches S1 within at most two fill/tail clocks in the single-bank
cases and exactly in the two-bank cases. All final actual-path scenarios record
zero cycles with eligible work but no selection. The worst long single-bank
cold residual is **65 clocks / 0.414%**. Across 20 seeds, the worst long two-bank
stalled residual is **37 clocks / 0.272%**. Two-bank unstalled saturation still
costs **254 clocks / 2.981%** at delay 64 and **267 clocks / 1.598%** at delay 128.
Thus the target of matching S1 in every scenario is **NOT MET**.

A separate same-L2 Head fallback comparison locates most saturation cost in H1:
at delay 64, old S1 takes 8521 clocks, final L2 with legacy Head takes 8519, and
H1 takes 8775. At delay 128 these are 16713, 16723 and 16980. That fallback was
measured before the identity-preparation change; the final H1 cycle results are
identical for these cases. The remaining saturated difference is consistent with
H1 holding its 32 total credits across mandatory AR/R registers until upstream
RLAST. Raising credit limits, retiring ownership early or bypassing those
registers was not used to meet a benchmark. The independent legacy fallback is
retained, with its original cross-ID blocking behavior.

The isolated L2 endpoint remains a separate experiment: its worst long cold
residual is 252 clocks / 1.610%. Its cycle counts and the earlier calibrated
Head-delay model must not be substituted for the actual-path results. No test
executes the V33 ELF, three active Gemminis or the complete DDR controller/PHY;
the actual-path model also omits the vendor register slice. No simulated result
establishes recovered V33 board speed or output accuracy.

Final functional checks:

* `coherence_owner_candidates.log`: 34/68-entry randomized pool tests and real
  dual-bank coherent cache PASS. The cache reaches 68 secondary entries and
  checks 96 same-set requests, probes, dirty flush, and a legal dirty ReleaseData
  concurrent with prefetched reads (`cycles=2071`, `probes=3`).
* `tensor_owner_candidates.log`: real Tensor/L2/CPU overlap, probes, dirty flush
  and dirty eviction PASS (`cycles=2874`, `tensor_overlap=64`, `probes=2`).
* `head_regression.log` and `head_final/results.json`: actual current Head
  ordering/backpressure/ownership, legacy/shadow and latency comparisons PASS.
  H1's isolated overhead is 2 clocks, versus 3 before optimization.
* `owner_candidates_performance.log`: isolated L2 and actual one/two-bank
  scoreboards PASS. `final_l2/` and `final_memory_path_banks1/2/` preserve inputs,
  hashes, run logs and JSON results. Extended baseline logs/results are kept in
  `memory_path_s1_banks2/` and `memory_path_before_banks2/`.

During harness development, both old and new two-bank runs first failed because
the harness omitted the parent wrapper's bank-1 A12 restoration. The corrected
connection passes on both; this was a harness error, not evidence of a hardware
regression. A later metadata-publication error and a trial compilation concurrent
with private regeneration were corrected before final runs. Compile identities
are now published only after success, and actual-path/OOC sources are frozen
before compilation. Failed trials are not counted as validation passes.

The original 10:52 full-flow launch remains `STOPPED_BY_USER`. The replacement
complete flow will have its own report directory; its actual launch/synthesis
status is recorded below. The original bitstream contains none of these
performance changes and remains a separate timing-unmet historical artifact.

Final export and audit PASS: 782 generated collateral files, 173 hardware import
records and 423 frozen-reference records. All compared candidate module hashes
match the sole production `GENERATION_CONTEXT.json`. Evidence is
`hardware_provenance_final.json`, `comparison_final_l2.json`,
`comparison_final_memory_path_banks1.json`,
`comparison_final_memory_path_banks2.json`, and `comparison_final.csv`, all under
`build/reports/hardware_performance/`. The candidate manifest hashes the selected
results, inputs, rollback patches and OOC artifacts. Both independent reverse
patch checks pass.

Final L2 OOC synthesis PASS, **WNS -0.087 ns / timing not met**. The earlier
return-handshake predictor measured -0.170 ns with the same outer data flow;
the pre-outer-flow flat candidate measured -0.613 ns. These are unplaced local
estimates and do not establish full-chip timing. No new timing exception or
frequency reduction was introduced. Head's unchanged final source retains its
previous OOC pass and 192-URAM inference evidence.

`make check` and final generated cache-control simulation PASS. Whole-workspace
`make check-deps` FAILS only on the separately edited
`sw/benchmarks/frontend/scripts/prepare.py` import digest; this task did not
modify or revert that software work. Hardware-only provenance passes separately.
The pre-existing realtime Runtime adaptation remains pending. Full V33/Gemmini
workload simulation, post-optimization board measurements, final routing/timing
and the new bitstream are **NOT RUN / NOT YET VERIFIED** at launch.

The replacement **complete** `make bitstream` flow started at
`2026-10-16T05:59:36.038148Z` (13:59:36 local):

```sh
python3 tools/build/launch_head_l2_urgent.py \
  --report-dir build/reports/hardware_performance/full_implementation_final
python3 tools/build/launch_head_l2_urgent.py \
  --report-dir build/reports/hardware_performance/full_implementation_final --status
```

That directory preserves `input_manifest.json`,
`candidate_manifest_at_launch.json`, `implementation_state.json` and
`logs/full_implementation.log`. It uses the existing locked full flow, including
project/IP preparation, top synthesis, placement, routing and bitstream export.
There are no manual staged full-build invocations. Monitoring is limited to top
synthesis completion as requested; the same process continues implementation.
No FPGA/firmware programming or flash write was performed.

## S1 Head/L2 restoration — current selection (2026-10-16)

The user rejected the optimized L2 candidate and selected the Head/L2 from the
specified S1 bitstream. Subsequent clarification explicitly retained current
TensorIngress and DDR. This supersedes the optimization candidate above.
`full_implementation_final/implementation_state.json` is `STOPPED_BY_USER`,
exit 130, before top synthesis completion. It is not a synthesis pass.

Production Head and bridge now match the S1 sources after module renaming only.
The six L2 controller/pool/configuration source files match the donor's effective
Chipyard workspace byte for byte. Only the existing Tensor client statistics
adaptation in `InclusiveCache.scala` remains different across that source
package. The 34-entry combinational fast-peek pool, round-robin arbitration and
S1 direct reload are restored. H1, synchronous 68-entry storage, response-credit
machinery, prefetch and the new outer data-flow path are removed.

The sole production export was regenerated and checked: **784 collateral
files**, 34-entry pool, 102 queues, 32+2 MSHRs per bank, 2 banks / 512 KiB,
512-bit/ID2 memory, 256-bit/ID5 Tensor, three DIM32 workers and statistics ABI1.1.
TensorIngress and 19 recorded handwritten DDR/Tensor/constraint/build-boundary
files retain their prior hashes. DDR remains mode 1, unlike S1's mode 7.
The resulting whole design therefore has those explicitly retained differences
from the reference bitstream.

New evidence is under `build/reports/s1_restore/`:

* `source_restore.json`: exact source donor mapping, transformations, package
  comparison and generated export hashes. Rejected sources are archived there.
* `head_regression/`: actual S1 Head, 512/256-bit modes, five seeds each with
  10,000 random requests, ordering/backpressure, legacy progress and shadow tests
  PASS. `head_latency.log`: isolated AR-to-RLAST latency is delay+1 at delays
  0/16/64; the extra two H1 clocks are removed. Every probe checks 896 responses /
  1664 beats. Continuous 256-read delay-64 traffic takes 560 clocks.
* `coherence.log`: restored 34-entry pool, 102 queues, five seeds × 20,000 random
  cycles, conservative full-pop and last-pop/push checks PASS. Real dual-bank
  cache coherence, legal dirty ReleaseData concurrent with same-set queued reads,
  probes, flush and eviction PASS.
* `tensor.log`: retained TensorIngress with restored real L2/CPU coherence PASS
  (`cycles=3000`, `tensor_overlap=64`, `probes=2`, dirty flush/eviction checked).
* `memory_ppu.log`: memory-v3 and publication regressions PASS.
* `check_cache.log`: production manifest and generated cache-control simulation
  PASS. `check_deps.log`: whole-workspace check still reports the separately
  edited `sw/benchmarks/frontend/scripts/prepare.py` import digest; that software
  work is preserved.

These results do not establish board speed, full V33 model output accuracy or
routed timing. Actual-path comparisons, local synthesis and the new complete
build are recorded below after completion; the earlier candidate's numbers are
not results for this restored design.

The restored actual-path and isolated-L2 comparisons now pass the strict S1
reference target. **All 344 compared scenarios are cycle-exact with S1**, with
zero extra cycles: 64 isolated-L2 scenarios, 64 single-bank actual-path scenarios,
and 216 dual-bank actual-path scenarios. The last group includes 20 seeds and
both unstalled credit-saturation cases. Each workload checks all response data,
source IDs and beat counts. Reproduction uses the performance runners with
`--read-decouple 0` and the comparison reporter with `--candidate-head-mode 0
--require-reference-target`. Reports are `comparison_l2.json` and
`comparison_memory_path_banks1/2.json` in `build/reports/s1_restore/`.

This exact agreement applies to those checked synthetic workloads. The actual
path omits the DDR controller/PHY and vendor register slice, and does not execute
an ELF or a complete V33/Gemmini model. The explicitly retained DDR mode 1 and
TensorIngress can still distinguish this design from the full S1 hardware on the
board. No restored-design board throughput claim is made.

The restored local synthesis results are **PASS**: L2 WNS **+1.580 ns**;
Head WNS **+7.345 ns**, with **192 URAM** inferred. These are out-of-context
100 MHz estimates, not routed full-design timing. Reports, frozen source
snapshots and DCPs are archived under `build/reports/s1_restore/ooc/`.

The user then explicitly requested **saving this version without starting full
implementation**. No full synthesis/implementation was launched for the restored
version. `build/reports/s1_restore/implementation_state.json` records
`NOT_STARTED_AT_USER_REQUEST`. There is no new bitstream for this version.
The portable machine-readable record is
[s1-head-l2-restore.json](s1-head-l2-restore.json); local full logs and candidate
manifest are `build/reports/s1_restore/saved_version_manifest.json` and adjacent
files. The two rejected optimization build records remain stopped historical
runs, and the original timing-unmet bitstream is unchanged.
