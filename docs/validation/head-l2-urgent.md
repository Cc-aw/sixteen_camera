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
