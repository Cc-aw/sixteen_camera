#!/usr/bin/env python3
"""Compare checked simulations without labeling them whole-model speedups."""
import argparse
import datetime
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def key(row):
    return tuple(row[name] for name in ('requests', 'window', 'delay', 'stalls', 'seed', 'case'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', type=Path, nargs='+', required=True)
    parser.add_argument('--before', type=Path, nargs='+', required=True)
    parser.add_argument('--candidate', type=Path, nargs='+', required=True)
    parser.add_argument('--head-before', type=Path, required=True)
    parser.add_argument('--head-candidate', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--require-reference-target', action='store_true',
                        help='Require every scenario to match S1 within two startup/tail clocks')
    parser.add_argument('--head-latency-budget', action='store_true',
                        help='Compare reference/before/candidate with calibrated Head delay offsets 0/3/2')
    parser.add_argument('--integrated-memory-path', action='store_true',
                        help='Use actual L2/CacheCork/MemoryBus/Head/AXI results instead of an endpoint delay model')
    parser.add_argument('--candidate-head-mode', type=int, choices=(0, 1), default=1,
                        help='0 for the restored S1 Head; 1 for an H1 candidate')
    args = parser.parse_args()
    assert not (args.integrated_memory_path and args.head_latency_budget)
    evidence = {}
    datasets = []
    workload_hashes = set()
    active_banks = set()
    for dataset, paths in enumerate((args.reference, args.before, args.candidate)):
        rows = {}
        for path in paths:
            data = json.loads(path.read_text())
            evidence[str(path)] = sha(path)
            workload_hashes.add(data['workload_sha256'])
            if args.integrated_memory_path:
                assert data['read_decouple'] == (0, 1, args.candidate_head_mode)[dataset]
                assert data['DDR_PHY_AND_REGISTER_SLICE'] == 'NOT_MODELED'
                manifest_path = path.parent / 'compiled_sources.json'
                assert sha(manifest_path) == data['compiled_sources_sha256']
                bench_path = path.parent / 'tb_memory_path.sv'
                assert sha(bench_path) == data['bench_sha256']
                inferred_banks = len(re.findall(r'^InclusiveCacheBankScheduler dut\d*\(', bench_path.read_text(), re.M))
                assert inferred_banks in (1, 2)
                assert data.get('active_banks', inferred_banks) == inferred_banks
                active_banks.add(inferred_banks)
                evidence[str(manifest_path)] = sha(manifest_path)
                evidence[str(bench_path)] = sha(bench_path)
            else:
                assert data['clean_ack_delay'] == 0, 'Use like-for-like CacheCork endpoint results'
            expected_offset = (0, 3, 2)[dataset] if args.head_latency_budget else 0
            assert data.get('extra_memory_latency', 0) == expected_offset, 'Mixed delay-model modes'
            for row in data['results']:
                assert key(row) not in rows, 'Duplicate scenario'
                rows[key(row)] = row
        datasets.append(rows)
    assert len(workload_hashes) == 1 and all(set(rows) == set(datasets[0]) for rows in datasets)
    assert not args.integrated_memory_path or len(active_banks) == 1, 'Mixed bank counts'
    compared = []
    for index in sorted(datasets[0]):
        old, before, current = (data[index] for data in datasets)
        row = dict(current, reference_cycles=old['cycles'], before_cycles=before['cycles'],
                   extra_cycles_vs_reference=current['cycles'] - old['cycles'],
                   cycle_increase_percent=100 * (current['cycles'] / old['cycles'] - 1),
                   reduction_vs_before_percent=100 * (1 - current['cycles'] / before['cycles']),
                   reference_with_two_startup_cycles=current['cycles'] <= old['cycles'] + 2)
        compared.append(row)
    # A fixed two-cycle fill/tail cost is separately visible at 512 and 4096
    # requests. Do not hide growing cold-miss or backpressure differences.
    hot = [row for row in compared if row['case'] != 2]
    assert all(row['reference_with_two_startup_cycles'] for row in hot), 'Hot-read throughput regression'
    if args.require_reference_target:
        assert all(row['reference_with_two_startup_cycles'] for row in compared), 'Reference target not met in all scenarios'
    head_before = json.loads(args.head_before.read_text())
    head_current = json.loads(args.head_candidate.read_text())
    expected_head_latency = 2 if args.candidate_head_mode else 0
    assert head_before['expected_extra_latency'] == 3 and head_current['expected_extra_latency'] == expected_head_latency
    assert head_current['router_sha256'] == sha(ROOT / 'hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv'), 'Head result is not current RTL'
    for path in (args.head_before, args.head_candidate):
        evidence[str(path)] = sha(path)
    product = json.loads((ROOT / 'hw/manifests/current.json').read_text())
    context_path = ROOT / product['soc_directory'] / 'GENERATION_CONTEXT.json'
    context = json.loads(context_path.read_text())
    rtl = ROOT / product['collateral_directory']
    for name, expected in context['final_rtl_sha256'].items():
        assert sha(rtl / name) == expected, 'Changed generated RTL: ' + name
    compiled_path = args.candidate[0].parent / 'compiled_sources.json'
    for path in args.candidate:
        compiled = json.loads((path.parent / 'compiled_sources.json').read_text())
        for name, expected in compiled['rtl_sha256'].items():
            assert context['final_rtl_sha256'][name] == expected, 'Simulation is not current RTL: ' + name
    report = dict(updated_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                  baseline_commit='f0da4cc', evidence_sha256=evidence,
                  generation_context_sha256=sha(context_path), compiled_sources_sha256=sha(compiled_path),
                  functional_simulations='PASS', hot_throughput_target='PASS_WITH_AT_MOST_TWO_STARTUP_CYCLES',
                  all_scenarios_match_reference=all(row['reference_with_two_startup_cycles'] for row in compared),
                  cold_scenarios_slower=[row for row in compared if row['case'] == 2 and not row['reference_with_two_startup_cycles']],
                  h1_isolated_read_extra_cycles_before=3, h1_isolated_read_extra_cycles_after=expected_head_latency,
                  candidate_head_mode=args.candidate_head_mode,
                  h1_registered_ar_and_r_boundaries='PRESERVED' if args.candidate_head_mode else 'REMOVED_WITH_S1_RESTORE', results=compared,
                  comparison_model='ACTUAL_MEMORY_PATH_RTL' if args.integrated_memory_path else
                      ('CALIBRATED_HEAD_DELAY' if args.head_latency_budget else 'ISOLATED_L2'),
                  active_banks=next(iter(active_banks)) if active_banks else 1,
                  INTEGRATED_HEAD_L2_AXI_SIMULATION='PASS' if args.integrated_memory_path else 'NOT_RUN',
                  DDR_PHY_AND_REGISTER_SLICE='NOT_MODELED',
                  V33_FULL_MODEL_SIMULATION='NOT_RUN', BOARD_PERFORMANCE='NOT_RUN_FOR_OPTIMIZATION',
                  SPEEDUP='NOT_CLAIMED', BITSTREAM='NOT_GENERATED_FOR_OPTIMIZATION')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f'MEMORY_PERFORMANCE_COMPARISON=PASS scenarios={len(compared)} hot_target=PASS '
          f'all_reference_cases_matched={report["all_scenarios_match_reference"]} report={args.output}')


if __name__ == '__main__':
    main()
