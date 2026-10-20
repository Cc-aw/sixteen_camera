#!/usr/bin/env python3
"""Prepare/compare complete first-frame C0 numerical evidence for G1."""
import argparse
import json
from pathlib import Path
import sys

FEATURE=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(FEATURE/'analysis'))
from compare_candidate import normalize, same_bytes, sha


def prepare(g0,output,lane):
    summary_path=g0/'parallel_residency/opportunity_summary.json'
    summary=json.loads(summary_path.read_text())
    accepted=next(item for item in summary['lanes'] if item['lane']==lane)
    trace=Path(accepted['trace'])
    if sha(trace)!=accepted['trace_sha256']: raise ValueError('Accepted C0 trace changed')
    output.mkdir(parents=True,exist_ok=False)
    counts=normalize(trace,output/'normalized',frames=1)
    required={'reads':'accepted_spad_reads','commits':'physical_spad_commits','get_bytes':'all_tl_get_bytes'}
    for count,key in required.items():
        if 2*counts[count]!=accepted[key]: raise ValueError('Incomplete C0 first frame: '+key)
    if counts['stores']<=0: raise ValueError('No output stores in C0')
    files=sorted((output/'normalized').iterdir())
    result=dict(schema=1,status='PASS',lane=lane,frames=1,counts=counts,
        accepted_raw_trace=str(trace),accepted_raw_trace_sha256=accepted['trace_sha256'],
        sha256={str(p):sha(p) for p in [summary_path,Path(__file__).resolve(),FEATURE/'analysis/compare_candidate.py',*files]})
    (output/'reference.json').write_text(json.dumps(result,indent=2)+'\n')
    print('CSC_FULL_C0_FRAME_REFERENCE_PASS',lane,counts)


def compare(reference,candidate,output):
    identity=json.loads((reference/'reference.json').read_text())
    for name,digest in identity['sha256'].items():
        if sha(Path(name))!=digest: raise ValueError('Prepared reference changed: '+name)
    output.mkdir(parents=True,exist_ok=False)
    counts=normalize(candidate,output/'normalized',frames=1)
    names=[p.name for p in (reference/'normalized').iterdir()]
    comparisons={name:same_bytes(reference/'normalized'/name,output/'normalized'/name) for name in sorted(names)}
    passed=all(value['equal'] for value in comparisons.values())
    passed &= counts['reads']==identity['counts']['reads'] and counts['stores']==identity['counts']['stores']
    passed &= counts['tiles']==462 and counts['skipped']>0 and counts['skipped']==counts['completions']
    result=dict(schema=1,status='PASS' if passed else 'FAIL',lane=identity['lane'],frames=1,
        complete_native_stages=166,baseline=identity['counts'],candidate=counts,comparisons=comparisons,
        accumulator_internal_trace=False,full_system_performance_model=False,
        sha256={str(p):sha(p) for p in [reference/'reference.json',candidate,Path(__file__).resolve(),FEATURE/'analysis/compare_candidate.py']})
    (output/'comparison.json').write_text(json.dumps(result,indent=2)+'\n')
    if not passed: raise ValueError('Full C1a comparison failed; inspect '+str(output/'comparison.json'))
    print('CSC_FULL_C1A_FRAME_NUMERICAL_PASS',identity['lane'],counts)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='action',required=True)
    prep=sub.add_parser('prepare')
    prep.add_argument('--g0',type=Path,required=True)
    prep.add_argument('--lane',type=int,choices=(0,1,2),required=True)
    prep.add_argument('--output',type=Path,required=True)
    comp=sub.add_parser('compare')
    comp.add_argument('--reference',type=Path,required=True)
    comp.add_argument('--candidate',type=Path,required=True)
    comp.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    if args.action=='prepare': prepare(args.g0.resolve(),args.output.resolve(),args.lane)
    else: compare(args.reference.resolve(),args.candidate.resolve(),args.output.resolve())
