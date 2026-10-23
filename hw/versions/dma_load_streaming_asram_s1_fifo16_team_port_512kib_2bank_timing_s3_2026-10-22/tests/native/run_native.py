#!/usr/bin/env python3
"""Replay an immutable fixed-image workload; retain raw tensors and cycles."""
import argparse
import csv
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'scripts'))
from common import sha


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build',type=Path,required=True)
    parser.add_argument('--workload',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--delay',type=int,default=7)
    parser.add_argument('--max-cycles',type=int,default=100000000)
    parser.add_argument('--gemmini-timeout',type=int,default=60000,
        help='RS no-issue bound; full Pool commands can exceed the RTL default10000')
    args=parser.parse_args()
    build=args.build.resolve();workload=args.workload.resolve();out=args.output.resolve()
    if ROOT/'build' not in out.parents or args.delay<0:raise ValueError('Use a fresh candidate build/ output and nonnegative delay')
    if not 1<=args.gemmini_timeout<=65535:raise ValueError('Keep the 16-bit RS watchdog enabled with a finite bound1..65535')
    manifest=json.loads((build/'build_manifest.json').read_text())
    if manifest['status']!='PASS':raise ValueError('Native build is incomplete')
    for name,digest in manifest['sha256'].items():
        if sha(Path(name))!=digest:raise ValueError('Native build input changed: '+name)
    executable=build/'obj/VS1TeamReplay'
    if sha(executable)!=manifest['executable_sha256']:raise ValueError('Native executable changed')
    capture=json.loads((workload/'workload.json').read_text())
    if capture['status']!='PASS' or not capture.get('source_snapshot'):
        raise ValueError('Use an immutable candidate source capture')
    for name,digest in capture['sha256'].items():
        if sha(workload/name)!=digest:raise ValueError('Captured workload changed: '+name)
    snapshot=workload/capture['source_snapshot']
    for name,digest in {**capture['sources_sha256'],**capture['generated_sha256']}.items():
        if sha(snapshot/name)!=digest:raise ValueError('Captured source snapshot changed: '+name)
    context=json.loads((Path(manifest['generated_output'])/'GENERATION_CONTEXT.json').read_text())
    if capture['mode']!='original' and context.get('build_parameters',{}).get('S1_DIRECT_A')!='1':
        raise ValueError('Dual tables require the DirectA32 hardware capability')
    out.mkdir(parents=True,exist_ok=False);shutil.copyfile(Path(__file__),out/'runner.py')
    command=[str(executable),str(workload/'table.txt'),str(workload/'memory.bin'),
        str(args.max_cycles),str(args.delay),str(out/'summary.txt'),str(workload/'outputs.txt'),
        '+gemmini_timeout='+str(args.gemmini_timeout)]
    evidence=dict(status='RUNNING',hardware_build_id=manifest['hardware_build_id'],mode=capture['mode'],
        image=capture['image'],storage=capture['storage'],last_stage=capture['last_stage'],
        panel_rows=capture['panel_rows'],native_shapes=True,real_fixed_inputs=True,
        logical_read_probe=('rows' if 'external_values_8;' in (build/'S1TeamReplay.sv').read_text() else 'bytes'),
        native_frontend_fifo16=True,asram_store=manifest['asram_store'],
        ddr_service=dict(delay=args.delay,queue=8,backpressure_period=11),
        gemmini_no_issue_timeout=args.gemmini_timeout,
        cpu_rvv_executed=False,ppu_executed=False,shared_l2_video=False,
        full_system_timing=False,board_validation='NOT_RUN',command=command,
        input_sha256={str(p):sha(p) for p in (executable,build/'build_manifest.json',workload/'workload.json',
            workload/'table.txt',workload/'memory.bin',workload/'outputs.txt',out/'runner.py')})
    (out/'execution.json').write_text(json.dumps(evidence,indent=2)+'\n')
    with (out/'run.log').open('w') as log:
        result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT)
    evidence['returncode']=result.returncode
    evidence['status']='VALIDATING_OUTPUTS' if result.returncode==0 else 'FAIL'
    evidence['log_sha256']=sha(out/'run.log')
    (out/'execution.json').write_text(json.dumps(evidence,indent=2)+'\n')
    if result.returncode:raise RuntimeError('Native replay failed: '+str(out/'run.log'))
    if 'S1_TEAM_REPLAY_PASS' not in (out/'summary.txt').read_text():raise ValueError('Missing replay completion')
    if capture['last_stage']>=14 and (out/'summary.txt.stage14.bin').stat().st_size!=614400:
        raise ValueError('Incomplete stage14 output')
    if capture['last_stage']>=164 and (out/'summary.txt.heads.bin').stat().st_size!=907200:
        raise ValueError('Incomplete six-head output')
    if capture['mode']=='recovery':
        tensors=[(out/f'summary.txt.stage{s}.bin').read_bytes() for s in range(14,18)]
        if any(len(t)!=614400 or t!=tensors[0] for t in tensors):
            evidence['status']='FAIL'
            (out/'execution.json').write_text(json.dumps(evidence,indent=2)+'\n')
            raise ValueError('Native original/dual/original/dual restoration mismatch')
        evidence['native_helper_restoration']='PASS: original/dual/original/dual, all 614400 bytes equal'
    with (out/'summary.txt.stages.csv').open() as handle:
        stages=[{k:int(v) for k,v in row.items()} for row in csv.DictReader(handle)]
    evidence['stage_metrics']=stages
    evidence['outputs_sha256']={p.name:sha(p) for p in out.glob('summary.txt*') if p.is_file()}
    evidence['full_graph_executed']=capture['last_stage']>=164
    evidence['status']='PASS'
    (out/'execution.json').write_text(json.dumps(evidence,indent=2)+'\n')
    print('S1_TEAM_NATIVE_REPLAY_PASS',out,flush=True)


if __name__=='__main__':main()
