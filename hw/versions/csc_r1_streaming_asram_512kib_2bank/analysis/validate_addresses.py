#!/usr/bin/env python3
"""Check that relocated native DMA sources reference declared physical objects."""
import argparse
from collections import Counter
import csv
import gzip
import hashlib
import json
from pathlib import Path


def validate(trace, workload, output, lane=0):
    model = json.loads(workload.read_text())
    ranges = [(v['base'], v['base'] + v['bytes'], 'weight' if v['kind'] == 'elem_t' else 'bias')
              for v in model['weight_symbols'].values()]
    ranges += [(0x20000000 + lane*0x400000, 0x20240000 + lane*0x400000, 'private_asram'),
               (0x98000000 + lane*0x1000000, 0x98400000 + lane*0x1000000, 'conv_scratch'),
               (0x98400000 + lane*0x1000000, 0x98400000 + lane*0x1000000 + 17*22*128, 'pool_pad'),
               (0x98410000 + lane*0x1000000, 0x98410000 + lane*0x1000000 + 15*20*128, 'pool_mid'),
               (0xb0000000 + lane*0x1000000, 0xb0000000 + lane*0x1000000 + 480*640*3, 'input')]
    counts, rows = Counter(), 0
    with gzip.open(trace, 'rt') as handle:
        for row in csv.reader(handle):
            if row[0] != 'R':
                continue
            v = list(map(int, row[1:]))
            if v[1] != lane:
                raise ValueError('Wrong lane')
            rows += 1
            if v[17]:
                counts['zero_rows'] += 1
                continue
            address, length = v[10], v[13] * (4 if v[16] else 1)
            matches = [kind for start, end, kind in ranges if start <= address and address + length <= end]
            if len(matches) != 1:
                raise ValueError(f'Undeclared/ambiguous native source address 0x{address:x}, bytes={length}, stage={v[3]}')
            counts[matches[0] + '_rows'] += 1
    report = dict(schema=1, status='DECLARED_NATIVE_PHYSICAL_SOURCES_PASS', lane=lane, dma_rows=rows,
                  counts=dict(counts), metric='Logical row source ranges, not TL traffic or numerical oracle',
                  trace_sha256=hashlib.sha256(trace.read_bytes()).hexdigest(),
                  workload_sha256=hashlib.sha256(workload.read_bytes()).hexdigest())
    with output.open('x') as handle:
        json.dump(report, handle, indent=2)
        handle.write('\n')
    print(report['status'], rows)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--trace', type=Path, required=True)
    parser.add_argument('--workload', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--lane', type=int, default=0)
    args = parser.parse_args()
    validate(args.trace.resolve(), args.workload.resolve(), args.output.resolve(), args.lane)
