#!/usr/bin/env python3
"""Byte-exact C0/C1a comparison of actual SRAM consumers and all TL stores.

The comparison intentionally discards event times. Functional-memory cycles
are recorded elsewhere and are not a G2/system throughput result.
"""
import argparse
from collections import deque
from contextlib import ExitStack
import csv
import gzip
import hashlib
import json
from pathlib import Path
import struct


def sha(path):
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1048576), b''):
            digest.update(block)
    return digest.hexdigest()


def normalize(path, out, frames=None):
    out.mkdir(parents=True, exist_ok=False)
    with ExitStack() as stack:
        files = [stack.enter_context((out / f'reads_bank{b}.bin').open('wb')) for b in range(8)]
        stores = stack.enter_context((out / 'stores.bin').open('wb'))
        return _normalize(path, out, files, stores, frames)


def _normalize(path, out, files, stores, frames):
    memory = bytearray(524288)
    reads = [deque() for _ in range(8)]
    counts = dict(reads=0, stores=0, commits=0, tiles=0, skipped=0, completions=0, get_bytes=0)
    put_beat = 0
    with gzip.open(path, 'rt') as source:
        for r in csv.reader(source):
            if frames is not None and int(r[3]) >= frames:
                break
            event = r[0]
            if event == 'W':
                bank, row, mask = map(int, r[6:9])
                data = int(r[11], 16).to_bytes(32, 'little')
                offset = bank * 65536 + row * 32
                for byte in range(32):
                    if mask >> byte & 1:
                        memory[offset + byte] = data[byte]
                counts['commits'] += 1
            elif event == 'Q':
                bank, row = map(int, r[6:8])
                offset = bank * 65536 + row * 32
                reads[bank].append((int(r[3]), row, bytes(memory[offset:offset + 32])))
            elif event == 'V':
                bank = int(r[6])
                if not reads[bank]:
                    raise ValueError('Read response without accepted request')
                frame, row, expected = reads[bank].popleft()
                data = int(r[7], 16).to_bytes(32, 'little')
                if data != expected:
                    raise ValueError(f'Physical SRAM response mismatch {path}:{r[1]} bank {bank} row {row}')
                files[bank].write(struct.pack('<IH', frame, row) + data)
                counts['reads'] += 1
            elif event == 'T':
                opcode, _, size, address, mask = map(int, r[6:11])
                if opcode == 4:
                    counts['get_bytes'] += 1 << size
                elif opcode <= 1:
                    data = int(r[11], 16).to_bytes(32, 'little')
                    selected = bytes(data[i] if mask >> i & 1 else 0 for i in range(32))
                    stores.write(struct.pack('<IQI', int(r[3]), (address & ~31) + 32*put_beat, mask) + selected)
                    counts['stores'] += 1
                    put_beat = 0 if size <= 5 else (put_beat + 1) % 2
            elif event == 'K':
                counts['tiles'] += 1
                counts['skipped'] += int(r[6])
            elif event == 'N':
                counts['completions'] += 1
    if any(reads) or put_beat:
        raise ValueError('Incomplete read/Put ledger')
    if counts['skipped'] != counts['completions']:
        raise ValueError('Replacement completion ledger mismatch')
    (out / 'final_spad.bin').write_bytes(memory)
    return counts


def same_bytes(a, b):
    offset = 0
    with a.open('rb') as left, b.open('rb') as right:
        while True:
            x, y = left.read(1048576), right.read(1048576)
            if x != y:
                first = next((i for i, (p, q) in enumerate(zip(x, y)) if p != q), min(len(x), len(y)))
                return dict(equal=False, first_different_byte=offset+first, left_size=a.stat().st_size,
                            right_size=b.stat().st_size)
            if not x:
                return dict(equal=True, bytes_compared=offset)
            offset += len(x)


def compare(baseline, candidate, output, frames=None):
    output.mkdir(parents=True, exist_ok=False)
    left = normalize(baseline, output / 'baseline', frames)
    right = normalize(candidate, output / 'candidate', frames)
    comparison = {name: same_bytes(output / 'baseline' / name, output / 'candidate' / name)
                  for name in ['stores.bin', 'final_spad.bin', *[f'reads_bank{b}.bin' for b in range(8)]]}
    passed = all(r['equal'] for r in comparison.values())
    result = dict(schema=1, status='PASS' if passed else 'FAIL',
                  scope='All physical SPAD read responses, final SPAD bytes, and every masked TL Put byte',
                  accumulator_internal_trace=False, full_system_performance_model=False, frames=frames,
                  baseline=left, candidate=right, comparisons=comparison,
                  sha256={str(p): sha(p) for p in (baseline, candidate, Path(__file__).resolve())})
    (output / 'comparison.json').write_text(json.dumps(result, indent=2) + '\n')
    print('CSC_C1A_NUMERICAL_' + result['status'], json.dumps(dict(baseline=left, candidate=right)))
    if not passed:
        raise ValueError('Candidate differs from C0; inspect comparison.json')
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--frames', type=int)
    args = parser.parse_args()
    compare(args.baseline.resolve(), args.candidate.resolve(), args.output.resolve(), args.frames)
