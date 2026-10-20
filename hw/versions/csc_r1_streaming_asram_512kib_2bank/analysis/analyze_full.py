#!/usr/bin/env python3
"""Validate full-Gemmini traces and report qualified baseline opportunities."""
import argparse
from collections import Counter
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re

from full_lifecycle import FullLedger


def analyze(trace, log, workload, out, frames=2, stages=166, lanes=3, zero_owners=False):
    out.mkdir(parents=True, exist_ok=False)
    source_paths = [Path(__file__).resolve(), Path(__file__).with_name('full_lifecycle.py').resolve()]
    analyzer_sources = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}
    model = json.loads(workload.read_text())
    weights = [(x['base'], x['base'] + x['bytes']) for x in model['weight_symbols'].values() if x['kind'] == 'elem_t']
    biases = [(x['base'], x['base'] + x['bytes']) for x in model['weight_symbols'].values() if x['kind'] == 'acc_t']
    text = log.read_text()
    records = re.findall(r'FULL_GEMMINI_RTL_PASS lane=(\d+) native_words=(\d+) dma_rows=(\d+) real_gets=(\d+) real_get_bytes=(\d+) physical_commits=(\d+) accepted_spad_reads=(\d+)', text)
    if len(records) != lanes or {int(r[0]) for r in records} != set(range(lanes)):
        raise ValueError('Missing full functional completion markers')
    mandatory = ('all_mvin_commands', 'eligible_exact_mvin_commands', 'all_tl_get_requests',
                 'all_tl_get_bytes', 'eligible_exact_get_bytes', 'converted_spad_write_bytes',
                 'eligible_exact_spad_bytes', 'eligible_exact_zero_commands',
                 'input_mvin_commands', 'weight_mvin_commands', 'bias_mvin_commands', 'zero_mvin_commands',
                 'input_tl_get_bytes', 'weight_tl_get_bytes', 'bias_tl_get_bytes',
                 'input_eligible_exact_get_bytes', 'weight_eligible_exact_get_bytes',
                 'same_source_diff_destination_commands', 'ex_spad_write_bytes',
                 'dma_spad_write_bytes', 'zero_spad_write_bytes')
    totals, lane_results, stage_rows, examples, invalidations = Counter(dict.fromkeys(mandatory, 0)), [], [], [], Counter()
    qualified = []
    for lane in range(lanes):
        ledger = FullLedger(weights, zero_owners=zero_owners, biases=biases)
        file = trace / f'full_lane{lane}.csv.gz'
        with gzip.open(file, 'rt') as handle:
            for row in csv.reader(handle):
                if int(row[2]) != lane:
                    raise ValueError('Cross-lane trace contamination')
                ledger.consume(row)
        ledger.check_end()
        if ledger.stages != {(f, s) for f in range(frames) for s in range(stages)}:
            raise ValueError('Incomplete frame/stage coverage')
        sums = Counter(dict.fromkeys(mandatory, 0))
        for (frame, stage), stats in sorted(ledger.stats.items()):
            sums.update(stats)
            stage_rows.append(dict(lane=lane, frame=frame, stage=stage, **{**dict.fromkeys(mandatory, 0), **stats}))
        record = next(r for r in records if int(r[0]) == lane)
        fields = ['native_words', 'dma_rows', 'all_tl_get_requests', 'all_tl_get_bytes', 'physical_spad_commits', 'accepted_spad_reads']
        if [sums[k] for k in fields] != list(map(int, record[1:])):
            raise ValueError('Independent simulator/trace count mismatch')
        if sums['completed_mvin_commands'] != sums['all_mvin_commands']:
            raise ValueError('Not every Load completed physical residency checks')
        if sum(sums[role + '_mvin_commands'] for role in ('input', 'weight', 'bias', 'zero')) != sums['all_mvin_commands']:
            raise ValueError('Mvin role accounting is not an exact partition')
        if sum(sums[role + '_tl_get_bytes'] for role in ('input', 'weight', 'bias')) != sums['all_tl_get_bytes']:
            raise ValueError('Physical TL byte roles are not an exact partition')
        totals.update(sums)
        invalidations.update(ledger.invalidations)
        examples.extend(dict(lane=lane, **x) for x in ledger.examples)
        qualified.extend(dict(lane=lane, **x) for x in ledger.qualified)
        lane_results.append(dict(lane=lane, **sums, trace=str(file.resolve()), trace_sha256=hashlib.sha256(file.read_bytes()).hexdigest()))
    def table(name, rows, default_fields=()):
        fields = list(dict.fromkeys(k for row in rows for k in row)) or list(default_fields)
        with (out / name).open('w') as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
    table('per_stage_opportunity.csv', stage_rows)
    table('candidate_examples.csv', examples, ('lane', 'frame', 'stage', 'command', 'previous_command', 'source', 'destination_row', 'get_bytes', 'spad_bytes', 'role'))
    table('qualified_loads.csv', qualified, ('lane', 'frame', 'stage', 'logical', 'previous_command', 'role', 'get_bytes', 'spad_bytes', 'accept_cycle', 'full_commit_cycle'))
    table('invalidation_reasons.csv', [dict(reason=k, count=v) for k, v in sorted(invalidations.items())])
    full = frames >= 2 and stages == 166
    fraction = totals['eligible_exact_get_bytes'] / totals['all_tl_get_bytes'] if totals['all_tl_get_bytes'] else 0
    result = dict(schema=1, status='FULL_RTL_LIFECYCLE_PASS' if full else 'PARTIAL_SCOPE_RTL_LIFECYCLE_PASS',
                  **{key: totals[key] for key in mandatory},
                  complete_native_command_workload=full, full_system_performance_model=False,
                  three_lane_coverage=lanes == 3,
                  zero_write_ownership_proven=zero_owners,
                  g0_byte_gate_demonstrated=full and fraction >= 0.05,
                  eligible_exact_bytes_fraction=fraction, lanes=lane_results, totals=dict(totals),
                  input_vs_weight={role: {metric: totals[role + '_' + metric] for metric in
                                    ('mvin_commands', 'tl_get_bytes', 'eligible_exact_get_bytes')} for role in ('input', 'weight', 'bias')},
                  coverage_by_stage=list(range(stages)), existing_reuse_accounted=True,
                  exact_resident=dict(commands=totals['eligible_exact_mvin_commands'],
                                      actual_get_bytes=totals['eligible_exact_get_bytes']),
                  same_source_diff_destination=dict(commands=totals['same_source_diff_destination_commands'], r1_eligible=False),
                  sliding_window_overlap=None,
                  sliding_window_overlap_scope='Separate synthetic-order source-identity diagnostic; not measured safe R1 reuse',
                  no_go_reason=None if full and fraction >= 0.05 else 'BYTE_GATE_NOT_MET_OR_SCOPE_INCOMPLETE; WHOLE_SYSTEM_HOTSPOT_GATE_UNPROVEN',
                  analysis_sources_sha256=analyzer_sources,
                  qualified_loads_sha256=hashlib.sha256((out / 'qualified_loads.csv').read_bytes()).hexdigest(),
                  descriptor_policy='Unbounded whole-load descriptors; any overlapping writer invalidates; source versions per physical byte; frame switch invalidates',
                  limitations=['Functional direct physical memory service, no shared DDR/ASRAM timing',
                               'Head output service is a boundary; PPU execution excluded',
                               'Numerical network oracle and hypothetical skip completion require G1'])
    if any(hashlib.sha256(Path(p).read_bytes()).hexdigest() != h for p, h in analyzer_sources.items()):
        raise ValueError('Analyzer source changed while processing the trace')
    (out / 'opportunity_summary.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result['status'], 'qualified_read_fraction=', fraction)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--trace', type=Path, required=True)
    parser.add_argument('--log', type=Path, required=True)
    parser.add_argument('--workload', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--frames', type=int, default=2)
    parser.add_argument('--stages', type=int, default=166)
    parser.add_argument('--lanes', type=int, default=3)
    parser.add_argument('--zero-owners', action='store_true', help='Require the corrected real zeroWriteBuffer owner probe')
    args = parser.parse_args()
    analyze(args.trace, args.log, args.workload, args.output, args.frames, args.stages, args.lanes, args.zero_owners)
