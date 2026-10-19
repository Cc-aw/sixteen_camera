#!/usr/bin/env python3
"""Compare identical-work buffered/A1 RTL microbatches, never board timings."""
import argparse
import hashlib
import json
from pathlib import Path
import re


def read(directory):
    log=(directory/'result.log').read_text()
    if 'REAL_CLUSTER_PASS,DMA_SPAD=1,modes=4,lanes=3' not in log or re.search(r'Fatal:|Error:|Assertion failed:',log):
        raise ValueError('Incomplete micro simulation')
    records={}
    for line in log.splitlines():
        if 'DMA_MICRO_RTL_PASS,' not in line:
            continue
        values={name:int(value) for name,value in re.findall(r'(\w+)=(\d+)',line)}
        key=(values['lane'],values['mode'],values['case'])
        if key in records:
            raise ValueError('Duplicate micro sample')
        records[key]=values
    traffic={tuple(map(int,(lane,mode,case))):(int(writes),int(gets)) for lane,case,mode,writes,gets in re.findall(
        r'DMA_SPAD_PASS,lane=(\d),case=(\d),mode=(\d),[^\n]*?sram_writes=(\d+),dma_gets=(\d+)',log)}
    expected={(lane,mode,case) for lane in range(3) for mode in range(4) for case in range(4)}
    if set(records)!=expected or set(traffic)!=expected:
        raise ValueError('Missing modes, lanes, or OPS/stride combinations')
    return records,traffic


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--buffered',type=Path,required=True)
    parser.add_argument('--streaming',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    baseline,baseline_traffic=read(args.buffered)
    streaming,streaming_traffic=read(args.streaming)
    if baseline_traffic!=streaming_traffic:
        raise ValueError('A1 changed actual Get or SPAD write work')
    results=[]
    for key in sorted(baseline):
        a,b=baseline[key],streaming[key]
        if any(a[name]!=b[name] for name in ('stride','ops')):
            raise ValueError('Different micro workloads')
        if key[1]==0 and a['cycles']!=b['cycles']:
            raise ValueError('Legacy control cycles changed')
        results.append(dict(lane=key[0],mode=key[1],case=key[2],stride=a['stride'],ops=a['ops'],
            buffered_cycles=a['cycles'],streaming_cycles=b['cycles'],
            buffered_cycles_per_op=a['cycles']/a['ops'],streaming_cycles_per_op=b['cycles']/b['ops'],
            speedup=a['cycles']/b['cycles'],sram_writes=baseline_traffic[key][0],gets=baseline_traffic[key][1]))
    contexts=[]
    rtl_inputs=[]
    for directory,enabled in ((args.buffered,False),(args.streaming,True)):
        prj=(directory/'simulation.prj').read_text()
        files=[Path(name) for name in re.findall(r'^sv work "([^\"]+)"$',prj,re.M)]
        workers=[path for path in files if path.name=='Gemmini.sv']
        if len(workers)!=1:raise ValueError('Missing real worker in micro simulation')
        context_path=workers[0].parent.parent/'GENERATION_CONTEXT.json'
        context=json.loads(context_path.read_text())
        if context.get('dma_load_streaming_enable')!=enabled:raise ValueError('Wrong pipeline control')
        for path in files:
            if path.parent==workers[0].parent and hashlib.sha256(path.read_bytes()).hexdigest()!=context['final_rtl_sha256'][path.name]:
                raise ValueError('Micro candidate source changed')
        contexts.append(context)
        rtl_inputs.extend([context_path,*files])
    if contexts[0]['effective_scala']!=contexts[1]['effective_scala']:
        raise ValueError('Pipeline controls have different Scala source snapshots')
    inputs=[directory/name for directory in (args.buffered,args.streaming)
            for name in ('result.log','MemoryLane.sv','tb_real_cluster.sv','simulation.prj','run.py')]+rtl_inputs
    inputs.extend(path for directory in (args.buffered,args.streaming)
                  for path in directory.rglob('*')
                  if path.is_file() and path.suffix in ('.svh','.vh','.mem','.hex'))
    report=dict(status='RTL_MICRO_COMPARISON_PASS',hardware_executed=False,
        streaming_build_id=contexts[1]['dma_load_build_id'],buffered_build_id=contexts[0]['dma_load_build_id'],
        scope='Real three-lane RTL, first accepted input load row through lane drain; simulated frontend/memory pressure; not CPU submission or board timing',
        memory_profile='7+lane*3 cycle responses; selected addresses 0x1080/0x1180 delayed 200 cycles, identical in both controls',
        repeated_source_and_destination=True,return_bytes='Not sampled by this timing harness',
        results=results,sha256={str(path.resolve()):hashlib.sha256(path.read_bytes()).hexdigest() for path in inputs})
    args.output.write_text(json.dumps(report,indent=2)+'\n')
    print('RTL_MICRO_COMPARISON_PASS cases=4 modes=4 lanes=3 Get_and_SRAM_work=identical')


if __name__=='__main__':
    main()
