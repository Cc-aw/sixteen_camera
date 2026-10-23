#!/usr/bin/env python3
"""Require complete tensors before reporting native numerical/performance A/B."""
import argparse
import csv
import json
from pathlib import Path
import re
import sys
import time

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
from common import sha


def load(directory,full=False):
    path=ROOT/'build'/directory
    summary=path/'summary.txt'
    if 'S1_TEAM_REPLAY_PASS' not in summary.read_text():raise ValueError('Incomplete replay: '+directory)
    execution=path/'execution.json'
    if execution.exists() and json.loads(execution.read_text())['status']!='PASS':
        raise ValueError('Replay not signed off: '+directory)
    tensors={}
    for p in path.glob('summary.txt.*.bin'):
        name=p.name.removeprefix('summary.txt.').removesuffix('.bin')
        if name.startswith('stage') or (full and name=='heads'):
            data=p.read_bytes();expected=907200 if name=='heads' else 614400
            if len(data)!=expected:raise ValueError('Incomplete tensor: '+str(p))
            tensors[name]=dict(bytes=len(data),sha256=sha(p))
    if 'stage14' not in tensors or (full and 'heads' not in tensors):raise ValueError('Missing full tensor')
    stages={int(row['stage']):{k:int(v) for k,v in row.items()}
        for row in csv.DictReader((path/'summary.txt.stages.csv').open())}
    metrics={k:int(v) for k,v in re.findall(r'(\w+)=(\d+)',summary.read_text())}
    return dict(directory=directory,tensors=tensors,stages=stages,metrics=metrics,
        evidence_sha256={str(p.relative_to(ROOT)):sha(p) for p in
            [summary,path/'summary.txt.stages.csv',*([execution] if execution.exists() else [])]})


def equal(a,b,name):
    if a['tensors'][name]!=b['tensors'][name]:
        raise ValueError(f'Tensor mismatch: {a["directory"]} / {b["directory"]} / {name}')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'validation/native_matrix.json')
    args=parser.parse_args()
    # The delivered software defaults to the original helper on F2 hardware.
    # Require its complete three-image execution as well as the F0 reference.
    default_cases=[f'native_f2_original_image{i}_full_03' for i in ('025','036','142')]
    announced=False
    while True:
        states=[json.loads((ROOT/'build'/name/'execution.json').read_text())['status'] for name in default_cases]
        if 'FAIL' in states:raise ValueError('F2 original-helper full graph failed')
        if all(s=='PASS' for s in states):break
        if not announced:
            print('WAITING_FOR_F2_ORIGINAL_THREE_IMAGE_FULL_GRAPH',flush=True);announced=True
        time.sleep(5)
    graphs=[]
    for image,reference,candidate in (
        ('025','native_f0_image025_full_03','native_f2_image025_full_03'),
        ('036','native_original_image036_full_03','native_dual_image036_full_03'),
        ('142','native_original_image142_full_03','native_dual_image142_full_03')):
        a=load(reference,True);b=load(candidate,True)
        equal(a,b,'stage14');equal(a,b,'heads')
        default=load(f'native_f2_original_image{image}_full_03',True)
        equal(a,default,'stage14');equal(a,default,'heads')
        graphs.append(dict(image=image,reference=a,candidate=b,same_hardware_original=default,
            stage14_differing_bytes=0,raw_head_differing_bytes=0,
            same_hardware_frontend_cycle_reduction=1-b['metrics']['cycles']/default['metrics']['cycles'],
            frontend_cycle_reduction=1-b['metrics']['cycles']/a['metrics']['cycles']))
    reference=load('native_prefix_original_01');candidate=load('native_prefix_dual_01')
    equal(reference,candidate,'stage14')
    matrix=[]
    for directory in ('native_image025_dual_ddr_p512_d7_02',
        'native_image025_original_asram_p1024_d7_02','native_image025_dual_asram_p1024_d7_02',
        'native_image025_original_ddr_p1024_d64_02','native_image025_dual_ddr_p1024_d64_02',
        'native_image025_recovery_ddr_p1024_d7_02'):
        case=load(directory);equal(reference,case,'stage14')
        if 'recovery' in directory:
            for s in range(15,18):
                if case['tensors'].get(f'stage{s}')!=reference['tensors']['stage14']:
                    raise ValueError('Recovery/warm tensor mismatch')
        matrix.append(case)
    original_high=next(c for c in matrix if 'original_ddr' in c['directory'])
    dual_high=next(c for c in matrix if 'dual_ddr_p1024_d64' in c['directory'])
    high_delta=1-dual_high['stages'][14]['cycles']/original_high['stages'][14]['cycles']
    decision='none' if high_delta<=0 else 'model2 eligible in tested DDR models; system timing still unmeasured'
    result=dict(status='PASS',graphs=graphs,low_delay_same_hardware=dict(reference=reference,candidate=candidate),
        matrix=matrix,high_delay_stage14_cycle_reduction=high_delta,
        software_default='none',default_rationale=decision,
        full_system_timing=False,shared_l2_cpu_rvv_video=False,board_validation='NOT_RUN',
        legacy_probe_correction='native_f0_01/native_f2_01 logical_read_bytes column probes logical ROWS (event8); native_f2_02 probes bytes (event9).',
        metrics_scope='Actual FIFO16 frontend and Gemmini execution. Functional DDR service and zero-cycle HOST padding; no board FPS claim.')
    args.output.write_text(json.dumps(result,indent=2)+'\n')
    print('S1_NATIVE_MATRIX_PASS graphs=3 stage14_bytes_per_image=614400 raw_head_bytes_per_image=907200',flush=True)


if __name__=='__main__':main()
