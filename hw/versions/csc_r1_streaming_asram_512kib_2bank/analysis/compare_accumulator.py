#!/usr/bin/env python3
"""Compare all four actual Accumulator RAMs byte-for-byte at native fences."""
import argparse
import json
from pathlib import Path
import sys

from compare_candidate import same_bytes, sha


def compare(baseline,candidate,output):
    if sys.byteorder!='little': raise ValueError('Snapshot driver requires the recorded little-endian host')
    left=json.loads((baseline/'execution_manifest.json').read_text())
    right=json.loads((candidate/'execution_manifest.json').read_text())
    for directory,identity in ((baseline,left),(candidate,right)):
        if json.loads((directory/'execution_result.json').read_text())['status']!='PASS':
            raise ValueError('Incomplete Accumulator run')
        for name,digest in identity['sha256'].items():
            if sha(Path(name))!=digest: raise ValueError('Accumulator input changed: '+name)
    for key in ('mode','lanes','frames','expected_snapshots','accumulator_bytes_per_snapshot'):
        if left[key]!=right[key]: raise ValueError('Unmatched Accumulator cases: '+key)
    if left['csc_enabled'] or not right['csc_enabled']: raise ValueError('Expected CSC OFF/ON')
    results=[]
    for lane in left['lanes']:
        a=baseline/f'lane{lane}/accumulator.bin'
        b=candidate/f'lane{lane}/accumulator.bin'
        record=same_bytes(a,b)
        record.update(lane=lane,snapshots=left['expected_snapshots'][str(lane)],
            accumulator_payload_bytes=left['expected_snapshots'][str(lane)]*262144)
        if not record['equal']:
            offset=record['first_different_byte']
            record['snapshot_index']=offset//262156
            record['offset_in_snapshot']=offset%262156
        results.append(record)
    passed=all(r['equal'] for r in results)
    output.parent.mkdir(parents=True,exist_ok=True)
    sources=[Path(__file__).resolve(),Path(__file__).resolve().with_name('compare_candidate.py'),
        baseline/'execution_manifest.json',candidate/'execution_manifest.json']
    sources += [directory/f'lane{lane}/accumulator.bin' for directory in (baseline,candidate) for lane in left['lanes']]
    result=dict(schema=1,status='PASS' if passed else 'FAIL',
        scope='All physical Accumulator bytes at every completed native fence',
        accumulator_banks=4,rows_per_bank=512,bits_per_row=1024,lanes=results,
        bytes_compared=sum(r['accumulator_payload_bytes'] for r in results),
        sha256={str(p):sha(p) for p in sources})
    output.write_text(json.dumps(result,indent=2)+'\n')
    if not passed: raise ValueError('Accumulator bytes differ; inspect '+str(output))
    print('CSC_ACCUMULATOR_BYTE_COMPARISON_PASS',result['bytes_compared'])


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline',type=Path,required=True)
    parser.add_argument('--candidate',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    compare(args.baseline.resolve(),args.candidate.resolve(),args.output.resolve())
