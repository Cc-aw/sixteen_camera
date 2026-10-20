#!/usr/bin/env python3
"""Native in-place Conv output: future source writer must disable reuse."""
import argparse
import json
from pathlib import Path
import shutil

from compare_candidate import sha


def prepare(reference, output):
    identity = json.loads((reference / 'fixture.json').read_text())
    for name, digest in identity['sha256'].items():
        if sha(Path(name)) != digest:
            raise ValueError('Directed fixture changed: ' + name)
    output.mkdir(parents=True, exist_ok=False)
    shutil.copytree(reference / 'memory', output / 'memory')
    commands = []
    changed = 0
    for line in (reference / 'commands.txt').read_text().splitlines():
        row = list(map(int, line.split()))
        if row[3] == 20:
            # Native CONFIG_5: rs1=weights, rs2=output; CONFIG_6 retains
            # the distinct nonzero per-lane/frame Input from the reference.
            row[5] = 0x80004000 + row[0] * 0x100000
            changed += 1
        commands.append(row)
    if changed != 36:
        raise ValueError('Expected four native Conv packets per lane/frame')
    command_file = output / 'commands.txt'
    command_file.write_text(''.join(' '.join(map(str, r)) + '\n' for r in commands))
    result = dict(schema=1, status='NATIVE_FUTURE_SOURCE_WRITER_FIXTURE',
                  production_workload=False, performance_evidence=False,
                  lanes=3, frames=3, expected_requests_per_lane=12, expected_skips_per_lane=0,
                  hazard='Every output overwrites the next repeated Input source',
                  sha256={str(p): sha(p) for p in [reference / 'fixture.json',
                          Path(__file__).resolve(), command_file, *sorted((output / 'memory').iterdir())]})
    (output / 'fixture.json').write_text(json.dumps(result, indent=2) + '\n')
    print('CSC_FUTURE_SOURCE_WRITER_FIXTURE_COMPLETE')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.reference.resolve(), args.output.resolve())
