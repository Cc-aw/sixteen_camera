#!/usr/bin/env python3
"""Strict ASRAM bring-up log acceptance, never infer board PASS from host data."""
import argparse
import itertools
import json
from pathlib import Path
from build import BUILD, check, write


def parse(text, manifest, allow_synthetic=False):
    seen_cases, seen_dma, seen_parallel, seen_holes = set(), set(), set(), set()
    build = final = None
    samples = []
    for line in text.splitlines():
        if not line.startswith('ASRAM1,'):
            continue
        parts=line.strip().split(',')
        if len(parts)<3: raise ValueError('Malformed record')
        kind=parts[1]; data={}
        for part in parts[2:]:
            key, value=part.split('=',1)
            if key in data: raise ValueError('Duplicate field')
            data[key]=value
        if final is not None: raise ValueError('Records after PASS')
        if kind in ('FAIL','TRAP'): raise ValueError('Firmware failure: '+line)
        if kind=='BEGIN': continue
        fields={'BUILD':{'schema','hardware','hardware_id','package','clock_hz'},
                'CASE':{'kind','lane','pass','bytes','cycles','match'},
                'DMA':{'lane','mode','layout','slot','route','cycles','get','put','match','denied','pending'},
                'HOLE':{'lane','slot','write','address','accepted','retired','get','put','denied',
                        'physical_reads','physical_writes','corrupt','value','match'},
                'PARALLEL':{'mode','cycles','lanes','match'},
                'PASS':{'cases','dma','parallel','denied','traps'}}
        if kind not in fields or set(data)!=fields[kind]: raise ValueError('Missing/unknown fields')
        if kind=='BUILD':
            if build is not None: raise ValueError('Duplicate BUILD')
            if data!={'schema':'2','hardware':data.get('hardware'),
                      'hardware_id':manifest['config']['target']['hardware_build_id'],
                      'package':manifest['build_id'],'clock_hz':'100000000'}:
                raise ValueError('Wrong software/hardware identity')
            if data['hardware'] not in ('0','1') or (data['hardware']=='0' and not allow_synthetic):
                raise ValueError('Synthetic data is not a board result')
            build=data; continue
        if build is None: raise ValueError('Missing BUILD')
        if kind=='CASE':
            name=data['kind']; lane=int(data['lane']); p=int(data['pass']); key=(name,lane,p)
            size={'scalar_full':0x240000,'byte_masks':19*128,'rvv_full':0x240000,'cpu_holes':4}.get(name)
            if size is None or int(data['bytes'])!=size or int(data['match'])!=1 or int(data['cycles'])<=0:
                raise ValueError('Failed memory case')
            if key in seen_cases: raise ValueError('Duplicate memory case')
            seen_cases.add(key)
        elif kind=='HOLE':
            lane,slot,store=key=tuple(int(data[k]) for k in ('lane','slot','write'))
            if key in seen_holes or lane not in range(3) or slot not in range(2) or store not in range(2):
                raise ValueError('Duplicate/unexpected hole probe')
            address=0x20000000+lane*0x400000+(0x3ffff8 if slot else 0x240000)
            expected=dict(lane=lane,slot=slot,write=store,address=address,accepted=1,retired=1,
                          get=1-store,put=store,denied=1,physical_reads=0,physical_writes=0,
                          corrupt=0,value=0,match=1)
            if {k:int(v) for k,v in data.items()}!=expected:
                raise ValueError('Hole request was not rejected without a physical operation')
            seen_holes.add(key)
        elif kind=='DMA':
            key=tuple(int(data[k]) for k in ('lane','mode','layout','slot','route'))
            if key in seen_dma: raise ValueError('Duplicate DMA case')
            if data['match']!='1' or data['denied']!='0' or data['pending']!='0' or int(data['cycles'])<=0:
                raise ValueError('DMA failed')
            route=key[-1]
            if bool(route&1)!=(int(data['get'])>0) or bool(route&2)!=(int(data['put'])>0):
                raise ValueError('ASRAM fast-path routing counters mismatch')
            seen_dma.add(key); samples.append({k:int(v) for k,v in data.items()})
        elif kind=='PARALLEL':
            mode=int(data['mode'])
            if mode in seen_parallel or data['lanes']!='7' or data['match']!='1' or int(data['cycles'])<=0:
                raise ValueError('Parallel case failed/duplicated')
            seen_parallel.add(mode)
        elif kind=='PASS': final=data
        else: raise ValueError('Unknown record: '+kind)
    expected_cases={(name,lane,p) for name in ('scalar_full','byte_masks','rvv_full','cpu_holes')
                    for lane in range(3) for p in range(2 if name=='scalar_full' else 1)}
    expected_dma=set(itertools.product(range(3),range(4),range(3),range(3),range(4)))
    if build is None or final!={'cases':'15','dma':'432','parallel':'4','denied':'12','traps':'0'}:
        raise ValueError('Missing/mismatched final summary')
    if (seen_cases!=expected_cases or seen_dma!=expected_dma or seen_parallel!=set(range(4)) or
        seen_holes!=set(itertools.product(range(3),range(2),range(2)))):
        raise ValueError('Incomplete or unexpected test matrix')
    return dict(status='BOARD_PASS' if build['hardware']=='1' else 'SYNTHETIC_TEST_PASS',
                build=build,memory_cases=15,dma_cases=432,parallel_cases=4,
                denied_hole_probes=12,expected_cpu_traps=0,
                timing_scope='diagnostic table-mvin plus mvout issue-to-idle, not model performance',
                samples=samples)


def main():
    p=argparse.ArgumentParser(description=__doc__); p.add_argument('log',type=Path); a=p.parse_args()
    archived=a.log.parent/'asram.manifest.json'
    if not archived.is_file():archived=a.log.parent/'manifest.json'
    manifest=json.loads(archived.read_text()) if archived.is_file() else check()
    result=parse(a.log.read_text(),manifest)
    write(a.log.with_suffix('.summary.json'),result)
    print('ASRAM_LOG='+result['status']+' memory=15 dma=432 parallel=4 denied=12 traps=0')


if __name__=='__main__': main()
