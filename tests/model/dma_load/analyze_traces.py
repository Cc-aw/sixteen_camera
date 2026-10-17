#!/usr/bin/env python3
"""Close original LoadController row traces against actual TileLink Get counts."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re
from reference import Load, physical_reads


def analyze(directory):
    directory = Path(directory).resolve()
    cases = json.loads((directory/'cases.json').read_text())
    log = (directory/'result.log').read_text()
    completion=re.search(r'REAL_CLUSTER_PASS,DMA_LAYERS=8,modes=([34]),lanes=3',log)
    if not completion or re.search(r'Fatal:|Error:|Assertion failed:',log):
        raise ValueError('Incomplete or failed layer simulation')
    mode_count=int(completion.group(1))
    observed = {}
    for lane,case,mode,reads,writes,acks in re.findall(
            r'DMA_LAYER_PASS,lane=(\d+),case=(\d+),mode=(\d+),reads=(\d+),writes=(\d+),acks=(\d+)',log):
        key = tuple(map(int,(int(lane),int(case),int(mode))))
        if key in observed or writes != acks:
            raise ValueError('Duplicate result or missing store ACK')
        observed[key] = int(reads)
    if len(observed) != 24*mode_count:
        raise ValueError('Expected all eight layers, three lanes and three modes')
    results=[]
    baseline={}
    fields=('case','mode','first','last','index','rows','cmd_id','address','cols','pixels','stride','zeros')
    for lane in range(3):
        traces={}
        with (directory/f'rows_lane{lane}.csv').open() as handle:
            for values in csv.reader(handle):
                row=dict(zip(fields,map(int,values),strict=True))
                traces.setdefault((row['case'],row['mode']),[]).append(row)
        for case in range(8):
            for mode in range(mode_count):
                rows=traces[case,mode]
                normalized=[tuple(r[k] for k in fields if k not in ('mode','cmd_id')) for r in rows]
                if mode==0:baseline[lane,case]=normalized
                elif normalized!=baseline[lane,case]:raise ValueError('Original logical row stream changed')
                commands=[]
                for row in rows:
                    if row['first']:
                        if commands and not commands[-1][-1]['last']:raise ValueError('Premature command boundary')
                        commands.append([])
                    commands[-1].append(row)
                    if row['index']!=len(commands[-1])-1:raise ValueError('Row sequence error')
                gets=returned=logical=groups=zero_rows=0
                roles={}
                for command in commands:
                    r=command[0];n=len(command);c=r['cols']
                    if n!=r['rows'] or not command[-1]['last']:raise ValueError('Truncated command')
                    role='zero' if r['zeros'] else 'input' if (r['address']&0xfffff)<0x10000 else 'weight' if (r['address']&0xfffff)<0x60000 else 'bias'
                    item=roles.setdefault(role,dict(rows=0,logical_bytes=0,gets=0,returned_bytes=0))
                    item['rows']+=n
                    logical_bytes=n*c*(4 if role=='bias' else 1)
                    logical+=logical_bytes;item['logical_bytes']+=logical_bytes
                    if r['zeros']:zero_rows+=n;continue
                    eligible=(role!='bias' and 0<c<32 and r['pixels']*c<=32 and
                              (r['stride']==c and n>1 or mode in (2,3) and r['pixels']>1))
                    merged=mode in (1,2) and eligible and r['stride']==c
                    if mode!=0 and eligible:groups+=1
                    load=Load(r['address'],0,c*(4 if role=='bias' else 1),n,r['pixels'],r['stride'])
                    fragments=list(physical_reads(load,merged))
                    count=len(fragments);size=sum(f[1] for f in fragments)
                    gets+=count;returned+=size;item['gets']+=count;item['returned_bytes']+=size
                # One 32B frontend table fetch per command. LUT + two config
                # commands + seven words/tile + final DRAIN are all explicit.
                table_gets=35+7*len(cases[case]['plan']['tiles'])
                actual=observed[lane,case,mode]-table_gets
                if actual!=gets:raise ValueError(f'Get closure failed lane={lane} stage={cases[case]["stage"]} mode={mode}: {actual}!={gets}')
                results.append(dict(lane=lane,stage=cases[case]['stage'],mode=mode,logical_rows=len(rows),
                    logical_bytes=logical,zero_rows=zero_rows,commands=len(commands),optimized_read_groups=groups,
                    actual_dma_gets=actual,frontend_table_gets=table_gets,predicted_returned_bytes=returned,roles=roles))
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    report=dict(status='ROW_TRACE_GET_CLOSURE_PASS',scope='compact real layers; returned bytes predicted from observed logical addresses',
        results=results,sha256={str(p):sha(p) for p in [directory/'cases.json',directory/'result.log',*[directory/f'rows_lane{i}.csv' for i in range(3)]]})
    (directory/'trace_evidence.json').write_text(json.dumps(report,indent=2)+'\n')
    return report


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',type=Path)
    args=parser.parse_args()
    report=analyze(args.directory)
    print(report['status']+' comparisons='+str(len(report['results'])))
