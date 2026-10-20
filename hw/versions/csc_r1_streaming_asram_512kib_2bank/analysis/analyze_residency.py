#!/usr/bin/env python3
"""Check real trace ledgers and report diagnostics without promoting G0."""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
from trace_lifecycle import reconstruct


def physical_traffic(path):
    pending = {}
    stats = {}
    expected_seq = 0
    last_cycle = -1
    with path.open() as handle:
        for row in csv.reader(handle):
            seq, cycle, stage, mode, packet = map(int, row[:5])
            if seq != expected_seq or mode != 2 or cycle < last_cycle:
                raise ValueError('Lifecycle sequence gap or wrong mode')
            expected_seq += 1
            last_cycle = cycle
            count = stats.setdefault(stage, Counter())
            kind = row[5]
            if kind == 'CMD':
                f = int(row[6])
                count['loop_starts' if f == 15 else 'loop_config_words' if 16 <= f <= 21 else 'other_commands'] += 1
                continue
            opcode, source, size = map(int, row[6:9])
            if kind == 'TL_A':
                if opcode == 4:
                    if source in pending:
                        raise ValueError('TL source reused before response')
                    pending[source] = dict(opcode=4, size=size, beats=max(1, (1 << size) // 32), stage=stage, remaining_a=0)
                    count['tl_gets'] += 1
                    count['tl_get_bytes'] += 1 << size
                    # This workload uses the parent's explicit 1 MiB DDR lane
                    # arenas: input at 0x4000, weights at 0x10000, bias 0x60000.
                    offset = int(row[9], 16) & 0xfffff
                    role = 'input' if offset < 0x10000 else 'weight' if offset < 0x60000 else 'bias' if offset < 0x70000 else 'other'
                    count[role + '_tl_gets'] += 1
                    count[role + '_tl_get_bytes'] += 1 << size
                elif opcode in (0, 1):
                    if source not in pending:
                        pending[source] = dict(opcode=opcode, size=size, beats=1, stage=stage,
                                               remaining_a=max(1, (1 << size) // 32) - 1)
                        count['tl_puts'] += 1
                    else:
                        transaction = pending[source]
                        if (transaction['opcode'], transaction['size']) != (opcode, size) or not transaction['remaining_a']:
                            raise ValueError('Put source reused or malformed continuation')
                        transaction['remaining_a'] -= 1
                else:
                    raise ValueError('Unexpected TL A opcode')
            elif kind == 'TL_D':
                if int(row[9]) or int(row[10]):
                    raise ValueError('Denied/corrupt in functional trace')
                if source not in pending:
                    raise ValueError('Unknown TL response source')
                transaction = pending[source]
                if transaction['remaining_a']:
                    raise ValueError('Put acknowledged before last A beat')
                if size != transaction['size'] or opcode != (1 if transaction['opcode'] == 4 else 0):
                    raise ValueError('TL response size/opcode mismatch')
                transaction['beats'] -= 1
                count['tl_d_beats'] += 1
                if transaction['beats'] == 0:
                    del pending[source]
            else:
                raise ValueError('Unknown lifecycle event')
    if pending:
        raise ValueError('Unreturned TL transactions')
    return stats


def analyze(directory, out):
    manifest = json.loads((directory / 'trace_manifest.json').read_text())
    for name, expected in manifest['traces'].items():
        if hashlib.sha256((directory / name).read_bytes()).hexdigest() != expected:
            raise ValueError('Trace hash mismatch: ' + name)
    out.mkdir(parents=True, exist_ok=False)
    cases = json.loads((directory / 'cases.json').read_text())
    closure = json.loads((directory / 'trace_evidence.json').read_text())
    if closure['status'] != 'ROW_TRACE_GET_CLOSURE_PASS':
        raise ValueError('Missing four-mode logical-row/Get closure')
    predicted = {(r['lane'], r['stage']): r for r in closure['results'] if r['mode'] == 2}
    rows = []
    examples, invalidations = [], []
    all_loads = all_gets = all_get_bytes = all_spad_bytes = same_value_bytes = 0
    for lane in range(3):
        trace = reconstruct(directory / f'spad_events_lane{lane}.csv')
        traffic = physical_traffic(directory / f'lifecycle_lane{lane}.csv')
        accepted_commands = []
        with (directory / f'rows_lane{lane}.csv').open() as handle:
            for raw in csv.reader(handle):
                if len(raw) != 12:
                    raise ValueError('Malformed accepted-row trace')
                values = list(map(int, raw))
                if values[1] == 2 and values[2]:
                    accepted_commands.append(values)
        if len(accepted_commands) != len(trace.loads):
            raise ValueError('First accepted row/logical load count mismatch')
        roles = {}
        for command_seq, command in trace.loads.items():
            raw = accepted_commands[command_seq - 1]
            if raw[0] != command['stage']:
                raise ValueError('Accepted-row stage attribution mismatch')
            offset = raw[7] & 0xfffff
            role = 'zero' if raw[11] else 'input' if offset < 0x10000 else 'weight' if offset < 0x60000 else 'bias'
            roles[command_seq] = role
            trace.by_stage[command['stage']][role + '_mvin_commands'] += 1
        if trace.counts['BOUNDARY'] != 8:
            raise ValueError('Missing representative stage')
        for command_seq, command in trace.loads.items():
            item = dict(lane=lane, stage_id=cases[command['stage']]['stage'], command_seq=command_seq,
                        issue_event_seq=command['seq'], role=roles[command_seq], dma_spad_bytes=command['write_bytes'])
            if command['stable_value_residency_diagnostic']:
                examples.append(dict(item, status='VALUE_ONLY_SOURCE_EPOCH_UNPROVEN', eligible_exact=None))
            reasons = []
            if not command['write_bytes']:
                reasons.append('NO_DMA_SPAD_FOOTPRINT')
            else:
                if not command['all_written_values_resident_at_issue']:
                    reasons.append('VALUE_DIFFERS_AT_ISSUE')
                if command['intervening_other_writer']:
                    reasons.append('INTERVENING_OTHER_WRITER')
            reasons.append('SOURCE_EPOCH_AND_NATIVE_DEPENDENCIES_UNPROVEN')
            invalidations.append(dict(item, reasons=';'.join(reasons)))
        for case, counts in sorted(trace.by_stage.items()):
            expected = predicted[lane, cases[case]['stage']]
            if (traffic[case]['tl_gets'], traffic[case]['tl_get_bytes']) != (
                    expected['actual_dma_gets'], expected['predicted_returned_bytes']):
                raise ValueError('Physical TL Get count/bytes differ from accepted-row model')
            for role in ('input', 'weight', 'bias', 'zero'):
                model_role = expected['roles'].get(role, {})
                if (traffic[case][role + '_tl_gets'], traffic[case][role + '_tl_get_bytes']) != (
                        model_role.get('gets', 0), model_role.get('returned_bytes', 0)):
                    raise ValueError('Physical role attribution differs from accepted-row model')
            if traffic[case]['other_tl_gets']:
                raise ValueError('Unclassified physical Get in compact DDR fixture')
            loads = [c for c in trace.loads.values() if c['stage'] == case]
            physically_equal = sum(c['dma_writes'] > 0 and c['write_bytes'] == c['equal_bytes'] for c in loads)
            stable_at_issue = sum(c['stable_value_residency_diagnostic'] for c in loads)
            row = dict(lane=lane, stage_id=cases[case]['stage'], all_mvin_commands=len(loads),
                       committed_spad_bytes=counts['committed_spad_bytes'], dma_spad_bytes=counts['dma_spad_bytes'],
                       same_value_bytes_at_commit=counts['same_value_spad_bytes'],
                       loads_all_spad_bytes_equal_at_commit=physically_equal,
                       loads_value_resident_at_issue_without_intervening_writer=stable_at_issue,
                       **{role + '_mvin_commands': counts[role + '_mvin_commands'] for role in ('input', 'weight', 'bias', 'zero')},
                       checked_read_responses=counts['READ_DATA'], **dict(traffic[case]))
            rows.append(row)
            all_loads += len(loads)
            all_gets += row['tl_gets']
            all_get_bytes += row['tl_get_bytes']
            all_spad_bytes += row['committed_spad_bytes']
            same_value_bytes += row['same_value_bytes_at_commit']
    fields = sorted({key for row in rows for key in row})
    with (out / 'per_stage_opportunity.csv').open('w') as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)
    for filename, records, fields in (
            ('candidate_examples.csv', examples, ['lane', 'stage_id', 'command_seq', 'issue_event_seq', 'role', 'dma_spad_bytes', 'status', 'eligible_exact']),
            ('lifetime_invalidation.csv', invalidations, ['lane', 'stage_id', 'command_seq', 'issue_event_seq', 'role', 'dma_spad_bytes', 'reasons'])):
        with (out / filename).open('w') as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(records)
    result = dict(schema=1, status='COMPACT_TRACE_LIFECYCLE_PASS', g0_status='INSUFFICIENT_EVIDENCE',
                  coverage_by_stage=[c['stage'] for c in cases], lanes=3, runtime_mode='read_assembled',
                  full_network_workload=False, all_mvin_commands=all_loads,
                  all_tl_get_requests=all_gets, all_tl_get_bytes=all_get_bytes,
                  converted_spad_write_bytes=all_spad_bytes, same_value_bytes_at_commit=same_value_bytes,
                  loads_value_resident_at_issue_without_intervening_writer=sum(
                      r['loads_value_resident_at_issue_without_intervening_writer'] for r in rows),
                  eligible_exact_mvin_commands=None, eligible_exact_get_bytes=None, eligible_exact_spad_bytes=None,
                  exact_resident=None, same_source_diff_destination=None, sliding_window_overlap=None,
                  input_vs_weight={role: dict(tl_gets=sum(r.get(role + '_tl_gets', 0) for r in rows),
                                              tl_get_bytes=sum(r.get(role + '_tl_get_bytes', 0) for r in rows),
                                              mvin_commands=sum(r[role + '_mvin_commands'] for r in rows),
                                              eligible_exact_get_bytes=None)
                                   for role in ('input', 'weight', 'bias', 'zero')},
                  existing_reuse_accounted='Native packet roundtrip and four-mode row/Get closure; no CSC-R1 credit for A1/B reuse',
                  limitations=[
                      'Same-value bytes at COMMIT are diagnostics, not safe whole-command skips at ISSUE',
                      'Value residency at ISSUE also remains diagnostic without source epochs, conversion and dependency proofs',
                      'Compact DDR fixtures are not full-size network traffic or timing weights',
                      'Stages use synthetic deterministic inputs, not outputs produced by preceding native network stages',
                      'Byte-value coincidence does not establish source epoch/format/dependency equivalence',
                      'HOST/PAD, full-model frames, single-lane trace and Head/PPU remain uncovered'],
                  no_go_reason=None)
    (out / 'opportunity_summary.json').write_text(json.dumps(result, indent=2) + '\n')
    print(result['status'], 'lanes=3 stages=8', 'loads=', all_loads, 'Get_bytes=', all_get_bytes)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--trace', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    analyze(args.trace.resolve(), args.output.resolve())
