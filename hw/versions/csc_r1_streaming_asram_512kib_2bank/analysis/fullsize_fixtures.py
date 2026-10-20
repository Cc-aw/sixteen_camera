#!/usr/bin/env python3
"""Extract actual C0 stage-start physical memory for full-size C1a cases.

All stages retain their native commands and shapes. Intermediate activations
come from the accepted whole-network C0 stores, not zero-filled stand-ins.
"""
import argparse
import gzip
import json
from pathlib import Path
import shutil
import struct

from compare_candidate import sha


def extract(run, out, stages):
    trace = run / 'full_complete_lanes/lane0/full_lane0.csv.gz'
    memory = run / 'functional_memory.bin'
    commands = run / 'workload_05/native_commands.txt'
    evidence = json.loads((run / 'parallel_residency/opportunity_summary.json').read_text())
    lane = evidence['lanes'][0]
    # The full accepted audit binds the raw physical event stream.
    raw_hashes = lane.get('trace_sha256', {})
    if isinstance(raw_hashes, str):
        expected = raw_hashes
    else:
        expected = raw_hashes.get(str(trace.resolve()))
    if expected is None:
        raise ValueError('Missing accepted raw trace SHA; do not use an unaudited fixture')
    if sha(trace) != expected:
        raise ValueError('Accepted C0 trace changed')
    out.mkdir(parents=True, exist_ok=False)
    images = out / 'memory'
    images.mkdir()
    pages, changed = {}, set()

    def put(address, value):
        pages.setdefault(address >> 12, bytearray(4096))[address & 4095] = value
        changed.add(address >> 12)

    def get(address):
        return pages.get(address >> 12, bytes(4096))[address & 4095]

    with memory.open('rb') as source:
        while header := source.read(12):
            address, size = struct.unpack('<QI', header)
            data = source.read(size)
            if len(data) != size:
                raise ValueError('Truncated physical image')
            for offset, value in enumerate(data):
                put(address + offset, value)
    changed.clear()
    selected, put_beat = [], 0
    with gzip.open(trace, 'rb') as source:
        for line in source:
            if line[:2] == b'B,':
                row = line.split(b',')
                if int(row[3]) != 0:
                    break
                stage, kind, a, b = map(int, row[4:5] + row[6:9])
                if kind == 253 and stage in stages:
                    target = images / f'lane0_stage{stage}.bin'
                    shutil.copyfile(memory, target)
                    with target.open('ab') as dest:
                        for page in sorted(changed):
                            dest.write(struct.pack('<QI', page << 12, 4096) + pages[page])
                    selected.append(stage)
                elif kind == 254 and a and b:
                    if stage not in (75, 76, 77):
                        raise ValueError('Unknown HOST padding service')
                    for offset in range(17*22*128):
                        put(b + offset, 128)
                    for y in range(15):
                        for offset in range(20*128):
                            put(b + (y+1)*22*128+128+offset, get(a + y*20*128+offset))
            elif line[:2] == b'T,':
                row = line.split(b',')
                opcode, _, size, address, mask = map(int, row[6:11])
                if opcode <= 1:
                    data = int(row[11], 16).to_bytes(32, 'little')
                    base = (address & ~31) + 32*put_beat
                    for byte, value in enumerate(data):
                        if mask >> byte & 1:
                            put(base + byte, value)
                    put_beat = 0 if size <= 5 else (put_beat+1) % 2
    if sorted(selected) != sorted(stages):
        raise ValueError('Missing stage snapshots: ' + str(selected))
    lines = []
    for line in commands.read_text().splitlines():
        lane, frame, stage, *_ = map(int, line.split())
        if lane == 0 and frame == 0 and stage in stages:
            lines.append(line)
    command_file = out / 'commands.txt'
    command_file.write_text('\n'.join(lines) + '\n')
    manifest = dict(schema=1, status='ACTUAL_C0_FULLSIZE_FIXTURES', stages=selected,
                    source='Frozen whole-network C0 parameters, actual TL stores and native HOST padding',
                    shapes_scaled=False, intermediate_activations_zero_filled=False,
                    sha256={str(p): sha(p) for p in (trace, memory, commands, command_file,
                                                   Path(__file__).resolve(), *sorted(images.iterdir()))})
    (out / 'fixtures.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('CSC_FULLSIZE_FIXTURES_COMPLETE', selected)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--g0-run', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--stages', default='38,62,109,111,117,134,156')
    args = parser.parse_args()
    extract(args.g0_run.resolve(), args.output.resolve(), list(map(int, args.stages.split(','))))
