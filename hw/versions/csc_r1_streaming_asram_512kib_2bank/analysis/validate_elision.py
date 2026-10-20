#!/usr/bin/env python3
"""Independent fixed-timeline deletion check for qualified whole Loads.

Delete all their SPAD writes and account for all their physical Gets. Keep
the recorded credit/ROB and read times, representing local replacement tokens.
Every real SRAM read must still see the exact recorded bytes. This is a data
equivalence model, not a faster RTL implementation or a cycle prediction.
"""
import argparse
from collections import Counter, deque
import csv
import gzip
import hashlib
import json
from pathlib import Path


class ElisionReplay:
    def __init__(self, qualified):
        self.qualified = qualified
        self.memory = bytearray(524288)
        self.tags, self.robs, self.reserved, self.transactions = {}, {}, {}, {}
        self.writes = [deque() for _ in range(8)]
        self.reads = [deque() for _ in range(8)]
        self.logical = self.sequence = 0
        self.get_bytes, self.write_bytes, self.completions = Counter(), Counter(), Counter()
        self.counts = Counter()

    def consume(self, row):
        event = row[0]
        if int(row[5]) != self.sequence:
            raise ValueError('Elision trace sequence gap')
        self.sequence += 1
        if event == 'R' and row[6] == '1':
            self.logical += 1
            self.tags[int(row[10])] = self.logical
            self.robs[int(row[22])] = self.logical
        elif event == 'G':
            self.reserved[int(row[6])] = self.tags[int(row[7])]
        elif event == 'T' and row[6] == '4':
            source, size = int(row[7]), int(row[8])
            owner = self.reserved[source - 32]
            if source in self.transactions:
                raise ValueError('Elision TL source reused')
            self.transactions[source] = [owner, max(1, (1 << size) // 32)]
            if owner in self.qualified:
                self.get_bytes[owner] += 1 << size
                self.counts['elided_gets'] += 1
        elif event == 'D' and row[8] == '1':
            source = int(row[6])
            self.transactions[source][1] -= 1
            if not self.transactions[source][1]:
                del self.transactions[source]
                del self.reserved[source - 32]
        elif event in ('A', 'W'):
            bank, address, mask, kind, tag = map(int, row[6:11])
            word = bytes.fromhex(row[11])[::-1]
            if event == 'A':
                owner = self.tags[tag] if kind != 1 else 0
                self.writes[bank].append((address, mask, kind, tag, word, owner))
            else:
                accepted = self.writes[bank].popleft()
                if accepted[:5] != (address, mask, kind, tag, word):
                    raise ValueError('Elision bank queue mismatch')
                owner = accepted[5]
                if owner in self.qualified:
                    self.write_bytes[owner] += mask.bit_count()
                    self.counts['elided_spad_commits'] += 1
                else:
                    start = (bank * 2048 + address) * 32
                    for byte in range(32):
                        if mask >> byte & 1:
                            self.memory[start + byte] = word[byte]
        elif event == 'Q':
            bank, address = map(int, row[6:])
            start = (bank * 2048 + address) * 32
            self.reads[bank].append(bytes(self.memory[start:start + 32]))
        elif event == 'V':
            bank = int(row[6])
            if self.reads[bank].popleft() != bytes.fromhex(row[7])[::-1]:
                raise ValueError('Deleting the proposed whole Load changes a real consumer read')
            self.counts['unchanged_spad_read_responses'] += 1
        elif event == 'X':
            owner = self.robs[int(row[6])]
            self.completions[owner] += 1
            self.counts['retained_original_completion_tokens'] += 1
        elif event == 'Y':
            self.counts['retained_original_credit_bytes'] += int(row[7])

    def finish(self):
        if any(self.writes) or any(self.reads) or self.transactions or self.reserved:
            raise ValueError('Incomplete elision replay')
        for logical, item in self.qualified.items():
            if (self.get_bytes[logical], self.write_bytes[logical], self.completions[logical]) != (
                    int(item['get_bytes']), int(item['spad_bytes']), 1):
                raise ValueError('Qualified whole Load does not match all Gets/writes/completion tokens')
        self.counts['qualified_whole_loads'] = len(self.qualified)
        self.counts['elided_actual_get_bytes'] = sum(self.get_bytes.values())
        self.counts['elided_actual_spad_write_bytes'] = sum(self.write_bytes.values())
        return dict(self.counts)


def validate(summary_path, qualified_path, output):
    validator_path = Path(__file__).resolve()
    validator_sha256 = hashlib.sha256(validator_path.read_bytes()).hexdigest()
    summary = json.loads(summary_path.read_text())
    if hashlib.sha256(qualified_path.read_bytes()).hexdigest() != summary['qualified_loads_sha256']:
        raise ValueError('Qualified Load set changed after the physical audit')
    with qualified_path.open() as handle:
        items = list(csv.DictReader(handle))
    results = []
    for lane in summary['lanes']:
        path = Path(lane['trace'])
        if hashlib.sha256(path.read_bytes()).hexdigest() != lane['trace_sha256']:
            raise ValueError('Physical trace changed after the audit')
        selected = {int(r['logical']): r for r in items if int(r['lane']) == lane['lane']}
        replay = ElisionReplay(selected)
        with gzip.open(path, 'rt') as handle:
            for row in csv.reader(handle):
                replay.consume(row)
        counts = replay.finish()
        if counts['elided_actual_get_bytes'] != lane['eligible_exact_get_bytes'] or counts['elided_actual_spad_write_bytes'] != lane['eligible_exact_spad_bytes']:
            raise ValueError('Independent deletion totals differ from the residency audit')
        results.append(dict(lane=lane['lane'], **counts))
    report = dict(schema=1, status='FIXED_TIMELINE_WHOLE_LOAD_ELISION_MODEL_PASS', lanes=results,
                  summary_sha256=hashlib.sha256(summary_path.read_bytes()).hexdigest(),
                  qualified_loads_sha256=summary['qualified_loads_sha256'],
                  complete_native_command_workload=summary['complete_native_command_workload'],
                  validator_source=str(validator_path), validator_sha256=validator_sha256,
                  actual_candidate_rtl=False, performance_result=False,
                  model='Delete complete qualified Load Gets and SPAD writes; retain recorded local completion/credit and consumer times')
    if hashlib.sha256(validator_path.read_bytes()).hexdigest() != validator_sha256:
        raise ValueError('Deletion validator changed during replay')
    with output.open('x') as handle:
        json.dump(report, handle, indent=2)
        handle.write('\n')
    print(report['status'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--summary', type=Path, required=True)
    parser.add_argument('--qualified', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    validate(args.summary.resolve(), args.qualified.resolve(), args.output.resolve())
