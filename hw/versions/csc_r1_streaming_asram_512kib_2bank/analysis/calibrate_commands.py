#!/usr/bin/env python3
"""Compare real XSim compact requests with independently replayed C0 unrollers."""
import argparse
from collections import Counter
import csv
import gzip
import hashlib
import json
from pathlib import Path
import subprocess


def commands(cases, luts=None):
    for lane in range(3):
        base = 0x80000000 + lane * 0x100000
        for mode in range(4):
            for stage, case in enumerate(cases):
                yield lane, mode, stage, 253, 0, 0
                if luts is not None:
                    for word, value in enumerate(luts[case['conv'] * 32:(case['conv'] + 1) * 32]):
                        yield lane, mode, stage, 26, word * 8, value
                plan = case['plan']
                c = plan['config']
                for f, a, b in ((0, c[0], c[1]), (0, c[2], c[3])):
                    yield lane, mode, stage, f, a, b
                for packet in plan['tiles']:
                    yield lane, mode, stage, 16, c[4], c[5]
                    for k in range(3):
                        yield lane, mode, stage, 17 + k, *packet['geometry'][2*k:2*k+2]
                    bases = (0x10000, 0x70000, 0x60000, 0x4000)
                    addresses = [0 if off == 0xffffffff else base + off + bases[j]
                                 for j, off in enumerate(packet['offsets'])]
                    yield lane, mode, stage, 20, *addresses[:2]
                    yield lane, mode, stage, 21, *addresses[2:]
                    yield lane, mode, stage, 15, *packet['launch']
                yield lane, mode, stage, 255, 0, 0


def calibrate(compact, executable, out):
    out.mkdir(parents=True, exist_ok=False)
    reference_manifest = json.loads((compact / 'trace_manifest.json').read_text())
    for name, expected in reference_manifest['traces'].items():
        if hashlib.sha256((compact / name).read_bytes()).hexdigest() != expected:
            raise ValueError('Reference XSim trace hash mismatch: ' + name)
    cases = json.loads((compact / 'cases.json').read_text())
    command = out / 'compact_commands.txt'
    command.write_text(''.join(' '.join(map(str, row)) + '\n' for row in commands(cases)))
    subprocess.run([str(executable), str(command), str(out / 'enumerated'), '3'], check=True)
    checks = []
    for lane in range(3):
        reference_rows, observed_rows = Counter(), Counter()
        reference_commands, observed_commands = Counter(), Counter()
        with (compact / f'rows_lane{lane}.csv').open() as handle:
            for row in csv.reader(handle):
                v = list(map(int, row))
                if v[1] == 2:
                    reference_rows[(v[0], *v[2:6], *v[7:])] += 1
        with (compact / f'spad_events_lane{lane}.csv').open() as handle:
            for row in csv.reader(handle):
                if row[2] != 'LOAD_ACCEPT':
                    continue
                n = int(row[9], 16)
                scale = n & 65535
                stride = n >> 16 & ((1 << 40) - 1)
                pixels = n >> 56 & 255
                rows = n >> 64 & 63
                cols = n >> 70 & 65535
                dest = n >> 86 & 0xffffffff
                source = n >> 118 & ((1 << 40) - 1)
                reference_commands[(int(row[5]), source, dest, cols, rows, pixels, stride, scale)] += 1
        with gzip.open(out / f'enumerated/commands_lane{lane}.csv.gz', 'rt') as handle:
            for row in csv.reader(handle):
                if row[0] != 'R':
                    continue
                v = list(map(int, row[1:]))
                if v[2] != 2:
                    continue
                observed_rows[(v[3], *v[5:9], v[10], v[13], v[19], v[20], v[17])] += 1
                if v[5]:
                    observed_commands[(v[3], v[10], v[11], v[13], v[8], v[19], v[20], v[15])] += 1
        check = dict(lane=lane, row_multiset_equal=reference_rows == observed_rows,
                     full_load_descriptor_multiset_equal=reference_commands == observed_commands,
                     reference_rows=reference_rows.total(), observed_rows=observed_rows.total(),
                     reference_loads=reference_commands.total(), observed_loads=observed_commands.total())
        if not check['row_multiset_equal'] or not check['full_load_descriptor_multiset_equal']:
            check['missing_examples'] = list((reference_commands - observed_commands).items())[:5]
            check['extra_examples'] = list((observed_commands - reference_commands).items())[:5]
        checks.append(check)
    result = dict(schema=1, status='COMPACT_COMMAND_CALIBRATION_PASS' if all(
        c['row_multiset_equal'] and c['full_load_descriptor_multiset_equal'] for c in checks) else 'FAIL',
        scope='Eight compact stages, three lanes, mode 2; addresses/layout/scale, not whole-network lifetimes',
        checks=checks, executable_sha256=hashlib.sha256(executable.read_bytes()).hexdigest(),
        compact_manifest_sha256=hashlib.sha256((compact / 'trace_manifest.json').read_bytes()).hexdigest())
    (out / 'calibration.json').write_text(json.dumps(result, indent=2) + '\n')
    if result['status'] != 'COMPACT_COMMAND_CALIBRATION_PASS':
        raise ValueError(json.dumps(checks))
    print(result['status'])


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compact', type=Path, required=True)
    parser.add_argument('--executable', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    calibrate(args.compact.resolve(), args.executable.resolve(), args.output.resolve())
