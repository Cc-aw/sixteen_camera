# Head and L2 cycle comparisons

Current production selection is the restored S1 Head/L2. TensorIngress and DDR
mode 1 remain current. The earlier H1/synchronous-pool results are historical.
`build/reports/s1_restore/` contains the active restoration evidence.

Run from the repository root. These tests instantiate real router/generated L2
RTL and check every returned beat. They are subsystem workloads, not a V33 ELF,
Gemmini, MIG, or board performance model.

```sh
HEAD_VERILATOR=/path/to/verilator make test-head-performance
make test-l2-performance PERF_RTL=/path/to/reference/gen-collateral
make test-l2-performance PERF_COUNT=4096
```

For a repeatable three-way comparison, use separate output directories:

```sh
python3 tests/rtl/performance/run_l2_compare.py --rtl /path/to/reference/gen-collateral --output build/perf/reference
python3 tests/rtl/performance/run_l2_compare.py --rtl /path/to/before/gen-collateral --output build/perf/before
python3 tests/rtl/performance/run_l2_compare.py --output build/perf/candidate
python3 tests/rtl/performance/run_l2_compare.py --output build/perf/candidate --reuse --count 4096
```

Repeat the final command for both reference directories, supplying their original
`--rtl` arguments. `--reuse` rejects changed RTL or testbench hashes. Supply
`--verilator /path/to/verilator` when the default tool is unsuitable. Outputs
include compile logs, individual run logs, source hashes and JSON cycle counts.

L2 uses one production bank, 64-byte Gets, a 256-bit inner port and a 512-bit
outer endpoint. The wrapper adapts only the reference/current source-ID width.
Each case resets, waits for directory initialization, and warms its working set.
Cases are 64 hot lines, four hot tags in one set, cold streaming, and hot groups
of three requests to one tag. Request windows are 1, 24 and 96; fixed endpoint
delays are 32/64 clocks; three seeds inject independent channel stalls. Inner
requests arrive at most once per two clocks, matching the two-beat response
bandwidth. Sources cannot be reused before the response retires. The scoreboard
checks source, address-derived data, beat count, opcode and completion.

By default, clean ReleaseAck is answered locally, as in the production
TLCacheCork. `--clean-ack-delay 1` instead puts that acknowledgement behind the
delayed memory queue: this is a separate pressure test, not the default production
connection. Do not combine results from the two endpoint modes.

Head detects whether the supplied router has an H1 switch. Current restored
S1 RTL runs only legacy mode, with zero extra clocks over S1. Each delay-0/16/64
configuration checks 896 transactions / 1664 beats using isolated reads,
pipelined reads, four-beat bursts and continuous addresses. A frozen H1 router
can still be compared in both modes; `f0da4cc` needs `--extra-latency 3`.

The protocol/coherence regressions remain separate:

```sh
make test-head-read-decouple
python3 tests/rtl/run_v3_timing_repair_tests.py --workspace /path/to/rebuilt-chipyard --targets pool cache --output build/sim/perf-coherence
make test-tensor-ingress SOC_WORKSPACE=/path/to/rebuilt-chipyard
```

The Scala cache regression includes dirty CPU ownership, probes, GrantAck,
flush, eviction, and ReleaseData concurrent with queued same-set reads. The pool
regression follows the production manifest. The restored S1 test checks 34
shared entries, 102 queues, fast-peek data, full-pool rejection, high logical
indices and simultaneous last-pop/push with five randomized seeds.
Board speed and full routed timing require separate evidence.

The integrated comparison uses actual generated bank schedulers, the two-port
`TLCacheCork`, `MemoryBus` (including TLToAXI4, IDIndexer and UserYanker), and the
actual Head router. The synthetic upstream source and checked AXI memory remain
shared across versions. Two-bank mode restores outer bank A12 just as the
production InclusiveCache wrapper does and uses a common two-beat response
arbiter. It does not instantiate the CPU, Gemminis, TensorIngress or SystemBus.
The data endpoint models one 64-byte AXI read beat, not a MIG/PHY, DDR refresh or
the vendor register slice. Writes, probes and dirty releases are exercised by
the separate protocol/coherence regressions above.

```sh
# BASE contains the isolated comparison and its exact compiled-source hashes.
# Use /tmp for native build output when the repository filesystem has slow I/O.
python3 tests/rtl/performance/run_memory_path_compare.py --base /path/to/reference-l2 --read-decouple 0 --banks 2 --output /tmp/path-reference
python3 tests/rtl/performance/run_memory_path_compare.py --base /path/to/candidate-l2 --read-decouple 0 --banks 2 --output /tmp/path-candidate
python3 tests/rtl/performance/run_memory_path_compare.py --base /path/to/candidate-l2 --read-decouple 0 --banks 2 --output /tmp/path-candidate --reuse --count 4096 --extra-seeds 151037 151038
```

Repeat the last command for reference and pre-optimization inputs, with their
respective router and `--read-decouple` setting. `--router` selects a frozen
pre-optimization router. Default random seeds are 151034–151036. Two-bank mode
adds unstalled window-96 tests at delay 64/128 to expose the shared 32-transaction
DDR outstanding ceiling. Extra seeds add stalled window-24/96 cases and save a separate
`results_count4096_extended.json`. Every scenario checks every returned beat;
latency, window, source reuse rules and seed must match in a comparison.

`run_latency_budget.py` is a separate calibrated endpoint-delay experiment.
It does not replace the actual memory-path comparison or model Head credits.
`tools/check/report_memory_performance.py --integrated-memory-path
--candidate-head-mode 0` checks like
workloads, source manifests and the final production generation hashes before
reporting integrated cycle differences. `--require-reference-target` fails if
any case exceeds the reference by more than two fill/tail clocks; a functional
PASS alone never means every performance target passed.


## Four-bank expansion and generated routing

`run_banked_memory_compare.py` is the current two/four-bank comparison. It
instantiates the generated SystemBus, CoherenceManagerWrapper (TLJbar, complete
L2 and CacheCork), MemoryBus and current S1 Head. There is no handwritten bank
routing or D-response arbiter. Synthetic traffic enters the three production
Gemmini DMA ports; four-client cases also use the CPU port. The checked AXI
endpoint supports full-line reads, dirty writebacks, independent AW/W/B,
latency and backpressure. It is not a DDR controller/PHY/register-slice model.
No ELF or Gemmini arithmetic is executed.

```bash
python3 tests/rtl/performance/run_banked_memory_compare.py \
  --rtl /path/to/saved-two-bank/gen-collateral --output /tmp/l2-two-bank
python3 tests/rtl/performance/run_banked_memory_compare.py --output /tmp/l2-four-bank
python3 tools/check/report_l2_bank_expansion.py \
  --baseline /tmp/l2-two-bank/results.json --candidate /tmp/l2-four-bank/results.json \
  --output build/reports/l2_1m_4bank/comparison.json
```

Defaults cover 72 cases per design: one/three/four clients, latency16/128,
backpressure in the longer-latency configuration, two seeds and six workloads:
hot distributed lines, hot same-bank lines, cold stream, 768 KiB and 1280 KiB
capacity working sets, and mixed full-line reads/writes with dirty replacement.
Capacity cases use four equal warm passes before measurement; replacement can
still cause misses. Report all cycles and traffic, including slower scenarios.
Both designs receive identical physical addresses and operations. This does
not establish a YOLO/ELF or board speedup.

The older `run_memory_path_compare.py` models one/two banks and rejects the
four-bank export. Isolated `l2_workload.svh` now uses 128 KiB tag spacing and
16 KiB cold-stream spacing so all requests remain in bank0 under both profiles.
Historical results retain their original frozen source/workload identities;
do not mix them with newly generated workloads.
