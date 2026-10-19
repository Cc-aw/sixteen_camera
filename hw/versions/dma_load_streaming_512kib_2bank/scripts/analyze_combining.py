#!/usr/bin/env python3
"""Validate a real SPAD trace and scan finite, conservative combining windows.

This is an offline opportunity model. It preserves baseline commit timing for
bypass writes and checks every read. It does not predict closed-loop cycles.
"""
import argparse
from collections import Counter, defaultdict, deque
import csv
import gzip
import hashlib
import json
from pathlib import Path

FIELDS = ('seq', 'cycle', 'event', 'epoch', 'mode', 'stage', 'bank', 'row', 'mask', 'data', 'cmd', 'aux')


def load_trace(path):
    opener = gzip.open if path.suffix == '.gz' else open
    records = []
    with opener(path, 'rt') as source:
        for number, values in enumerate(csv.reader(source)):
            if len(values) != len(FIELDS):
                raise ValueError('Truncated trace row: ' + str(number))
            row = dict(zip(FIELDS, values))
            for name in FIELDS:
                if name not in ('event', 'data', 'mask'):
                    row[name] = int(row[name])
            if row['seq'] != number:
                raise ValueError('Missing/duplicate/reordered event')
            if records and row['cycle'] < records[-1]['cycle']:
                raise ValueError('Trace cycle moved backwards')
            row['mask'] = int(row['mask'], 16)
            # Unselected payload bytes may be X. Selected bytes must be known.
            raw = row['data'].zfill(64)
            if len(raw) != 64:
                raise ValueError('Wrong payload width')
            payload = bytearray(32)
            for byte in range(32):
                part = raw[62 - 2 * byte:64 - 2 * byte]
                if row['mask'] & (1 << byte):
                    payload[byte] = int(part, 16)
            row['data'] = bytes(payload)
            records.append(row)
    if not records or records[0]['event'] != 'BEGIN' or records[-1]['event'] != 'END':
        raise ValueError('Missing trace BEGIN/END')
    return records


def masked(old, new, mask):
    return bytes(new[i] if mask >> i & 1 else old[i] for i in range(32))


def analyze(records, capacity, age, require_snapshot=True):
    golden, candidate = {}, {}
    pending = defaultdict(deque)
    windows = defaultdict(list)
    intents = defaultdict(set)
    reads, commands = {}, {}
    reasons = Counter()
    baseline_dma = candidate_dma = saved = cross = boundaries = read_count = 0
    stage_counts = defaultdict(Counter)

    def flush(bank, reason):
        nonlocal candidate_dma
        entries = windows[bank]
        for item in entries:
            key = (bank, item['row'])
            candidate[key] = masked(candidate[key], item['data'], item['mask'])
            candidate_dma += 1
        if entries:
            reasons[reason] += len(entries)
        entries.clear()

    for row in records:
        event, bank, cycle = row['event'], row['bank'], row['cycle']
        if windows[bank] and cycle - windows[bank][0]['born'] >= age:
            flush(bank, 'age')
        # Other banks must also age without a new write to those banks.
        for other in list(windows):
            if other != bank and windows[other] and cycle - windows[other][0]['born'] >= age:
                flush(other, 'age')
        key = (bank, row['row'])
        if event == 'BEGIN':
            continue
        if event == 'SNAPSHOT':
            if key in golden or row['mask'] != 0xffffffff:
                raise ValueError('Duplicate/incomplete snapshot')
            golden[key] = candidate[key] = row['data']
        elif event == 'LOAD_ACCEPT':
            if row['cmd'] in commands or row['aux'] <= 0:
                raise ValueError('Command identity reused')
            commands[row['cmd']] = row['aux']
        elif event == 'LOAD_CREDIT':
            if row['cmd'] not in commands or row['aux'] <= 0:
                raise ValueError('Credit has no live owner')
            commands[row['cmd']] -= row['aux']
            if commands[row['cmd']] < 0:
                raise ValueError('Excess command credit')
        elif event == 'CMD_COMPLETE':
            if commands.get(row['cmd']) != 0:
                raise ValueError('Premature/duplicate command completion')
            del commands[row['cmd']]
        elif event == 'READ_INTENT':
            flush(bank, 'read_intent')
            if row['cmd'] in intents[bank]:
                raise ValueError('Duplicate read intent')
            intents[bank].add(row['cmd'])
        elif event == 'BANK_ACCEPT':
            if key not in golden:
                raise ValueError('Write outside known snapshot')
            eligible = (row['aux'] == 0 and row['cmd'] >= 0 and row['mode'] in (2, 3) and
                        not intents[bank] and not any(not item['eligible'] for item in pending[bank]))
            pending[bank].append(dict(row=row, eligible=eligible))
            if not eligible:
                flush(bank, 'external_write_or_read_wait')
                continue
            hit = next((item for item in windows[bank] if item['row'] == row['row']), None)
            if hit is not None:
                hit['data'] = masked(hit['data'], row['data'], row['mask'])
                hit['mask'] |= row['mask']
                saved += 1
                cross += hit['last_cmd'] != row['cmd']
                hit['last_cmd'] = row['cmd']
                stage_counts[row['stage']]['saved_writes'] += 1
            else:
                if len(windows[bank]) == capacity:
                    flush(bank, 'capacity')
                windows[bank].append(dict(row=row['row'], data=row['data'], mask=row['mask'],
                                          born=cycle, last_cmd=row['cmd']))
            if age == 0:
                flush(bank, 'age')
        elif event == 'BANK_COMMIT':
            if not pending[bank]:
                raise ValueError('Physical commit has no accepted owner')
            item = pending[bank].popleft()
            accepted = item['row']
            if any(accepted[name] != row[name] for name in ('row', 'mask', 'data', 'cmd', 'aux')):
                raise ValueError('Accepted/committed write differs')
            golden[key] = masked(golden[key], row['data'], row['mask'])
            if row['aux'] != 1:
                baseline_dma += 1
                stage_counts[row['stage']]['baseline_dma_writes'] += 1
            if not item['eligible']:
                candidate[key] = masked(candidate[key], row['data'], row['mask'])
                candidate_dma += row['aux'] != 1
        elif event == 'READ_ACCEPT':
            if row['cmd'] not in intents[bank] or row['cmd'] in reads:
                raise ValueError('Read lacks intent or reused ID')
            flush(bank, 'read_accept')
            if golden[key] != candidate[key]:
                raise ValueError('Combining changed a read observation')
            reads[row['cmd']] = golden[key]
            intents[bank].remove(row['cmd'])
        elif event == 'READ_DATA':
            if reads.pop(row['cmd'], None) != row['data']:
                raise ValueError('Actual SRAM read differs from accepted snapshot')
            read_count += 1
        elif event in ('BOUNDARY', 'END'):
            for other in list(windows):
                flush(other, 'boundary')
            if any(pending.values()) or any(intents.values()) or reads or commands:
                raise ValueError('Boundary before complete drain')
            if golden != candidate:
                raise ValueError('Boundary/final SPAD differs')
            if event == 'BOUNDARY':
                expected = sum(v['baseline_dma_writes'] for v in stage_counts.values())
                prior = sum(r['aux'] for r in records[:row['seq']] if r['event'] == 'BOUNDARY')
                if expected - prior != row['aux']:
                    raise ValueError('Physical DMA writes do not close against c22')
                boundaries += 1
        elif event != 'DMA_CANDIDATE':
            raise ValueError('Unknown event: ' + event)
    if require_snapshot and len(golden) != 8 * 2048:
        raise ValueError('Expected complete eight-bank SPAD snapshot')
    if baseline_dma - candidate_dma != saved:
        raise ValueError('Saved-write arithmetic does not close')
    return dict(capacity_per_bank=capacity, max_age_cycles=age, correctness='PASS',
                baseline_dma_writes=baseline_dma, candidate_dma_writes=candidate_dma,
                saved_writes=saved, saved_writes_pct=100 * saved / max(1, baseline_dma),
                cross_cmd_saved_writes=cross, read_observations=read_count, boundaries=boundaries,
                flush_reasons=dict(reasons), per_stage=dict(stage_counts),
                extra_latency='NOT_MODELED', closed_loop_cycles='NOT_MEASURED')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('trace', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    records = load_trace(args.trace)
    results = []
    for capacity in (1, 2, 4, 8):
        for age in (0, 4, 8, 16, 32):
            results.append(analyze(records, capacity, age))
    report = dict(status='FINITE_WINDOW_ANALYSIS_PASS', trace_sha256=hashlib.sha256(args.trace.read_bytes()).hexdigest(),
                  scope='Compact representative layers; offline opportunity model, not full-network weighting or performance',
                  results=results, decision='DEFER_B2',
                  reason='No full-network weighted evidence or closed-loop cycle evidence to satisfy the hardware investment gate')
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print('FINITE_WINDOW_ANALYSIS_PASS configurations=20 B2=DEFER')


if __name__ == '__main__':
    main()
