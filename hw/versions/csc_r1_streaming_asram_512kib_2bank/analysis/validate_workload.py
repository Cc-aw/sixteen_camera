#!/usr/bin/env python3
"""Fail closed on incomplete native graphs, missing memory kernels or lanes."""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]


def validate(directory, output):
    manifest = json.loads((directory / 'workload.json').read_text())
    commands = directory / 'native_commands.txt'
    if hashlib.sha256(commands.read_bytes()).hexdigest() != manifest['command_sha256']:
        raise ValueError('Native command digest mismatch')
    for name, digest in manifest['sources_sha256'].items():
        if hashlib.sha256((ROOT / name).read_bytes()).hexdigest() != digest:
            raise ValueError('Frozen model digest mismatch: ' + name)
    markers, counts, per_stage = defaultdict(list), defaultdict(Counter), defaultdict(Counter)
    for line in commands.read_text().splitlines():
        lane, frame, stage, funct, a, b = map(int, line.split())
        if lane not in range(3) or frame not in range(2) or stage not in range(166):
            raise ValueError('Native graph identity outside frozen scope')
        if funct == 253:
            markers[lane, frame].append(stage)
        counts[lane, frame][funct] += 1
        per_stage[lane, frame, stage][funct] += 1
    expected = {(lane, frame) for lane in range(3) for frame in range(2)}
    if set(markers) != expected or any(v != list(range(166)) for v in markers.values()):
        raise ValueError('Incomplete/duplicate native stage markers')
    result = []
    for lane, frame in sorted(expected):
        c = counts[lane, frame]
        if any(c[f] != 462 for f in (15, 16, 17, 18, 19, 20, 21)):
            raise ValueError('Missing ordinary native packet words')
        if any(c[f] != 224 for f in (8, 9, 10, 11, 12, 13)):
            raise ValueError('Missing prepared WS native packet words')
        memory = sum((per_stage[lane, frame, s] for s in (75, 76, 77, 83, 97)), Counter())
        if (memory[2], memory[3], memory[254], memory[255]) != (1944, 624, 6, 34):
            raise ValueError('Native memory kernel graph drift or missing CPU pad/fences')
        if c != counts[0, 0]:
            raise ValueError('Lane/frame operation-count mismatch')
        result.append(dict(lane=lane, frame=frame, stages=166, ordinary_packets=462,
                           prepared_packets=224, memory_mvin=1944, memory_mvout=624,
                           memory_pad_updates=6, memory_waits=34, native_words=sum(c.values())))
    report = dict(schema=1, status='WHOLE_NATIVE_WORKLOAD_COVERAGE_PASS', rows=result,
                  native_command_sha256=manifest['command_sha256'], numeric_execution=False,
                  native_stage_terminal=166, accelerator_stages=list(range(166)))
    with output.open('x') as handle:
        json.dump(report, handle, indent=2)
        handle.write('\n')
    print(report['status'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workload', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    validate(args.workload.resolve(), args.output.resolve())
