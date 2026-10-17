#!/usr/bin/env python3
"""Strict micro-log checks; synthetic timings are never board evidence."""
import argparse
import json
from pathlib import Path
import statistics

from build import ROOT,check,sha,write
from spec import CASES,MODES,predict


def parse(raw,manifest,allow_synthetic=False):
    lines=raw.splitlines();starts=[i for i,line in enumerate(lines) if line.startswith('SPADM1,BUILD,')]
    if not starts:raise ValueError('Missing micro BUILD')
    records=[]
    for line in lines[starts[-1]:]:
        if line.startswith('SPADM1,FAIL,') or line.startswith(('SPADM1,DIFF,','SPADM1,COUNT_DIFF,')):
            raise ValueError('Micro firmware failure: '+line)
        if not line.startswith('SPADM1,'):
            if 'SPADM1,' in line:raise ValueError('Corrupt micro prefix')
            continue
        fields={}
        for item in line.split(',')[2:]:
            key,sep,value=item.partition('=')
            if not sep or not key or not value or key in fields:raise ValueError('Invalid micro field')
            fields[key]=value
        records.append((line.split(',')[1],fields))
    if records[0][0]!='BUILD' or records[-1][0]!='PASS':raise ValueError('Incomplete micro session')
    def number(f,key):
        v=f.get(key,'')
        if not v.isascii() or not v.isdecimal():raise ValueError('Invalid integer '+key)
        return int(v)
    build,done=records[0][1],records[-1][1];config=manifest['config'];params=config['case']
    expected=dict(schema=1,hardware_id=int(config['target']['hardware_build_id'],16),
        clock_hz=config['target']['clock_hz'],lane=params['lane'],samples=params['samples'],
        warmups=params['warmups'],ops=params['ops'])
    if any(number(build,k)!=v for k,v in expected.items()):raise ValueError('Wrong build/case identity')
    if build.get('package_build')!=manifest['build_id'] or build.get('suite')!='two_layout_mvin' or build.get('timing')!='cpu_issue_to_idle':
        raise ValueError('Wrong micro suite')
    hardware=number(build,'hardware')
    if hardware not in (0,1) or not hardware and not allow_synthetic:raise ValueError('Synthetic timing is not board evidence')
    capability=number(build,'capability')
    if capability>>16!=1 or capability&7!=7:raise ValueError('Missing runtime modes')
    schedule=[]
    for which in CASES:
        schedule.append(('CASE',which))
        for pass_id in range(params['samples']+params['warmups']):
            for mode in (MODES if pass_id%2==0 else MODES[::-1]):
                schedule.append(('RESULT',which,mode,
                    pass_id if pass_id<params['warmups'] else pass_id-params['warmups'],
                    int(pass_id<params['warmups'])))
    index=0;results={};summaries={};case_data={}
    for kind,f in records[1:-1]:
        if kind in ('CASE','RESULT'):
            if index>=len(schedule) or schedule[index][0]!=kind:raise ValueError('Wrong micro schedule')
            expected=schedule[index];which=expected[1]
            if f.get('case')!=which:raise ValueError('Wrong workload order')
            case=dict(params,stride=params['c'] if which=='continuous' else params['stride'])
            if kind=='CASE':
                wanted=dict(c=case['c'],n=case['n'],p=case['p'],stride=case['stride'],
                    offset=case['offset'],scale_bits=case['scale_bits'],output_bytes=(case['n']+case['p']+1)*32)
                if any(number(f,k)!=v for k,v in wanted.items()) or f.get('group_cost')!='included':
                    raise ValueError('Workload differs from compiled parameters')
                case_data[which]=case
            else:
                mode,sample,warmup=expected[2:]
                if f.get('mode')!=mode or number(f,'sample')!=sample or number(f,'warmup')!=warmup:
                    raise ValueError('Missing, duplicated or reordered trial')
                if number(f,'ops')!=params['ops'] or number(f,'cycles')<=0:raise ValueError('Inactive mvin window')
                for key,value in dict(bit_exact=1,source_unchanged=1,guards=1,
                    compared_bytes=(case['n']+case['p']+1)*32).items():
                    if number(f,key)!=value:raise ValueError('Missing full output/guard validation')
                traffic=predict(case,MODES.index(mode))
                for key in ('read_merge','assembly'):
                    if number(f,key)!=traffic[key]:raise ValueError('Wrong effective optimization')
                counters={i:number(f,'c'+str(i)) for i in range(8,35)}
                for i in (8,9,11,18,19,21,22,31,33):
                    if counters[i]!=traffic['values'][i]:raise ValueError('Traffic mismatch c'+str(i))
                if not warmup:results.setdefault((which,mode),[]).append((number(f,'cycles'),counters))
            index+=1
        elif kind=='SUMMARY':
            key=(f.get('case'),f.get('mode'))
            if index!=len(schedule) or key not in results or key in summaries:raise ValueError('Premature or duplicate summary')
            cycles=[r[0] for r in results[key]]
            baseline=sum(r[0] for r in results[key[0],'legacy'])
            expected=dict(samples=params['samples'],ops=params['ops'],total_cycles=sum(cycles),
                min_cycles=min(cycles),max_cycles=max(cycles),gain_x1000=baseline*1000//sum(cycles))
            if any(number(f,k)!=v for k,v in expected.items()):raise ValueError('Wrong summary arithmetic')
            summaries[key]=f
        else:raise ValueError('Unexpected micro record '+kind)
    if index!=len(schedule) or len(summaries)!=6:raise ValueError('Incomplete micro workloads')
    for key,value in dict(measured_records=6*params['samples'],warmup_records=6*params['warmups'],
        full_spad_bit_exact=1,source_unchanged=1,guards=1).items():
        if number(done,key)!=value:raise ValueError('Incorrect PASS '+key)
    if done.get('group_cost')!='included':raise ValueError('Wrong comparison scope')
    aggregate=[]
    for which in CASES:
        for mode in MODES:
            samples=results[which,mode];cycles=[r[0] for r in samples]
            baseline=sum(r[0] for r in results[which,'legacy'])
            counters=samples[0][1];traffic=predict(case_data[which],MODES.index(mode))
            aggregate.append(dict(case=which,mode=mode,read_merge=traffic['read_merge'],assembly=traffic['assembly'],
                samples=len(samples),ops_per_sample=params['ops'],total_cycles=sum(cycles),
                mean_cycles_per_op=statistics.mean(cycles)/params['ops'],
                median_cycles_per_op=statistics.median(cycles)/params['ops'],
                min_cycles_per_op=min(cycles)/params['ops'],max_cycles_per_op=max(cycles)/params['ops'],
                gain=baseline/sum(cycles),get_per_op=(counters[18]+counters[19])/params['ops'],
                tl_return_bytes_per_op=counters[33]/params['ops'],spad_writes_per_op=counters[22]/params['ops']))
    return dict(status='BOARD_PASS' if hardware else 'SYNTHETIC_TEST_PASS',board_evidence=bool(hardware),
        prior_sessions_ignored=len(starts)-1,software_build_id=manifest['build_id'],
        hardware_build_id=config['target']['hardware_build_id'],case=params,aggregate=aggregate,
        timing='CPU mvin issue through full lane idle, including dispatch/poll overhead; no initialization/mvout/UART.',
        interpretation='Strided read_assembled includes Group buffering/replay and RowAssembler; not independent assembler hardware.',
        ddr_traffic_measured=False)


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('log',type=Path)
    args=parser.parse_args();manifest=check();path=args.log.resolve()
    if not path.is_relative_to(ROOT):raise ValueError('Use logs inside this package')
    report=parse(path.read_text(errors='replace'),manifest)
    receipt=path.parent/'micro.load.json'
    if receipt.exists():
        loaded=json.loads(receipt.read_text())
        if loaded['build_id']!=manifest['build_id'] or loaded['elf_sha256']!=manifest['elf_sha256']:
            raise ValueError('ELF load receipt mismatch')
    report.update(source=str(path),sha256=sha(path))
    write(path.with_suffix('.json'),report)
    text=[]
    for row in report['aggregate']:
        text.append(f"{row['case']}/{row['mode']}: cycles/op={row['mean_cycles_per_op']:.2f}, "
            f"gain={row['gain']:.4f}, Get/op={row['get_per_op']:g}, SPAD writes/op={row['spad_writes_per_op']:g}")
    path.with_suffix('.txt').write_text('\n'.join(text)+'\n')
    print('\n'.join(text))


if __name__=='__main__':main()
