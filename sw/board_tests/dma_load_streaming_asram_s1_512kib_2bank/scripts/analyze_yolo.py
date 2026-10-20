#!/usr/bin/env python3
"""Accept complete same-bitstream YOLO DDR/local comparison logs."""
import argparse
import itertools
import re
from pathlib import Path

from build import write
from build_yolo import check


def parse(raw, manifest, allow_synthetic=False):
    build = final = group = None
    results, summaries, profiles, workspaces = {}, {}, [], []
    groups = []
    sequence = runs = 0

    def finish_batch():
        nonlocal group
        if group is None:
            return
        start = group['start']; count = int(start['frames']); active = 3 if start['executor']=='2' else 1
        if (group['result'] is None or group['timing'] is None or set(group['frames'])!=set(range(count)) or
            set(group['asram'])!=set(itertools.product(range(3),range(2))) or set(group['dma'])!=set(range(3))):
            raise ValueError('Incomplete frame/counter matrix')
        quotas = [0,0,0]
        for f, data in group['frames'].items():
            lane=int(data['device']);quotas[lane]+=1
            if (int(data['image'])!=f%3 or int(data['host_calls'])!=12 or
                data['marker']!='COMPLETE' or int(data['slot']) not in (0,1)):
                raise ValueError('Frame output/ownership mismatch')
        if quotas!=[count//active if lane<active else 0 for lane in range(3)]:
            raise ValueError('Unequal frame allocation')
        diagnostic=int(build['diagnostic'])
        if set(group['raw'])!=(set(range(count)) if diagnostic else set()):
            raise ValueError('Raw diagnostic coverage missing/unexpected')
        for (lane,port), data in group['asram'].items():
            c=[int(data['c'+str(i)]) for i in range(20)]
            if min(c)<0 or c[0]!=c[1] or c[0]!=sum(c[2:5]) or c[15] or c[16] or data['pending']!='0':
                raise ValueError('ASRAM errors/incomplete requests')
            local=start['storage']=='local_arena' and lane<active
            if not local and any(c[i] for i in (0,1,2,3,4,12,13)):
                raise ValueError('DDR/idle lane incorrectly used ASRAM')
            if local and (not c[2] or (port==0 and not sum(c[3:5]))):
                raise ValueError('Local arena route was not exercised')
        for lane,data in group['dma'].items():
            if data['actual_mode']!=start['mode'] or data['mode_rejects']!='0':
                raise ValueError('DMA mode mismatch/rejection')
            if not all('c'+str(i) in data for i in range(8,35)):
                raise ValueError('Missing Gemmini counters')
        groups.append(group)
        group=None

    context={'sequence','round','storage','mode','executor','warmup'}
    for line in raw.splitlines():
        if line.startswith(('ATSOFT1,FAIL,','ATSOFT1,TRAP,','ATSOFT1,PPU_DIFF,','ASRY1,DIFF,')):
            raise ValueError('Inference failure: '+line)
        if not line.startswith(('ASRY1,','ATSOFT1,FRAME_END,')):
            continue
        if final is not None:
            raise ValueError('Records after PASS')
        fields=line.strip().split(',');kind=fields[1];data={}
        for item in fields[2:]:
            key,value=item.split('=',1)
            if key in data:raise ValueError('Duplicate log field')
            data[key]=value
        if kind=='BUILD':
            if build is not None:raise ValueError('Duplicate BUILD')
            target=manifest['config']['target']
            required=dict(schema='1',hardware_id=target['hardware_build_id'],package=manifest['build_id'],
                frames='12',warmup_frames='3',modes='1',profiles='2',executors='3',
                clock_hz='100000000',layout='original',ppu_runs='monotonic')
            if any(data.get(k)!=v for k,v in required.items()) or set(data)!=set(required)|{'hardware','diagnostic','rounds'}:
                raise ValueError('Wrong YOLO software/hardware contract')
            if data['hardware'] not in ('0','1') or (data['hardware']=='0' and not allow_synthetic):
                raise ValueError('Synthetic log is not board evidence')
            if int(data['rounds']) not in (1,2,3) or data['diagnostic'] not in ('0','1'):
                raise ValueError('Bad round/diagnostic selection')
            build=data
            expected=[(0,'ddr_arena',2,0,1,12)]
            for rnd in range(int(data['rounds'])):
                for order in range(2):
                    profile=('ddr_arena','local_arena')[order^(rnd&1)]
                    expected.extend((rnd,profile,mode,e,w,3 if w else 12)
                                    for mode in (2,) for e in range(3) for w in (1,0))
            continue
        if build is None:raise ValueError('Missing BUILD')
        if kind=='PROFILE':
            if (data.get('storage') not in ('ddr_arena','local_arena') or data.get('tables')!='18' or
                data.get('entries')!='10870' or data.get('raw')!='10478' or data.get('hosts')!='12' or
                data.get('arena_bytes')!='2217600' or int(data.get('prepare_cycles','0'))<=0):
                raise ValueError('Wrong model plan/profile')
            profiles.append(data)
        elif kind=='BATCH_BEGIN':
            finish_batch();sequence+=1
            if set(data)!=context|{'frames','run_before'}:raise ValueError('Bad batch fields')
            key=(int(data['round']),data['storage'],int(data['mode']),int(data['executor']),int(data['warmup']),int(data['frames']))
            if sequence>len(expected) or key!=expected[sequence-1] or int(data['sequence'])!=sequence or int(data['run_before'])!=runs:
                raise ValueError('Unexpected batch order or PPU run reset')
            group=dict(start=data,frames={},asram={},dma={},raw={},result=None,timing=None)
        elif kind=='WORKSPACE':
            option=re.search(r'(?:^|\s)-DYOLO_SPPF_ASRAM=([01])(?:\s|$)',manifest['config']['yolo_flags'])
            if option is None:raise ValueError('Missing SPPF storage build option')
            local=str(int(data.get('storage')=='local_arena' and option[1]=='1'))
            if (set(data)!={'storage','round','sppf_local','pad_bytes','intermediate_bytes','local_end'} or
                data['sppf_local']!=local or data['pad_bytes']!='47872' or
                data['intermediate_bytes']!='38400' or data['local_end']!='2304000'):
                raise ValueError('Wrong SPPF workspace binding')
            workspaces.append(data)
        elif kind in ('FRAME_END','ASRAM','DMA','RAW_CHECK','RESULT','TIMING'):
            if group is None:raise ValueError('Record outside batch')
            start=group['start']
            if kind!='FRAME_END' and any(data.get(k)!=start[k] for k in context):
                raise ValueError('Mixed batch context')
            if kind=='FRAME_END':
                if data.get('executor')!=('direct_serial','frontend_serial','frontend_parallel')[int(start['executor'])]:
                    raise ValueError('Wrong frame executor')
                frame=int(data['frame']);lane=int(data['device'])
                if lane not in range(3) or frame in group['frames']:raise ValueError('Bad/duplicate frame')
                group['frames'][frame]=data
            elif kind=='ASRAM':
                if set(data)!=context|{'lane','port','pending'}|{'c'+str(i) for i in range(20)}:
                    raise ValueError('Missing/unknown ASRAM counter fields')
                key=int(data['lane']),int(data['port'])
                if key in group['asram']:raise ValueError('Duplicate ASRAM counters')
                group['asram'][key]=data
            elif kind=='DMA':
                key=int(data['lane'])
                if set(data)!=context|{'lane','actual_mode','mode_rejects'}|{'c'+str(i) for i in range(8,35)}:
                    raise ValueError('Missing/unknown DMA counter fields')
                if key in group['dma']:raise ValueError('Duplicate DMA counters')
                group['dma'][key]=data
            elif kind=='RAW_CHECK':
                frame=int(data['frame'])
                if (frame in group['raw'] or int(data['head_bytes'])!=907200 or
                    int(data['pad_bytes'])!=230400 or data['match']!='1'):
                    raise ValueError('Incomplete raw Head/intermediate comparison')
                group['raw'][frame]=data
            elif kind=='TIMING':
                if (group['timing'] is not None or
                    set(data)!=context|{'pad_cycles','host_cycles','head_publish_cycles'} or
                    any(int(data[k])<0 for k in ('pad_cycles','host_cycles','head_publish_cycles')) or
                    int(data['host_cycles'])<int(data['head_publish_cycles'])):
                    raise ValueError('Bad/duplicate timing record')
                group['timing']=data
            elif kind=='RESULT':
                if group['result'] is not None or set(data)!=context|{'frames','cycles','run_first','run_last','ppu_bit_exact','guards'}:
                    raise ValueError('Bad/duplicate RESULT')
                count=int(start['frames'])
                if (data['frames']!=start['frames'] or int(data['run_first'])!=runs+1 or
                    int(data['run_last'])!=runs+count or int(data['cycles'])<=0 or
                    data['ppu_bit_exact']!='1' or data['guards']!='1'):
                    raise ValueError('Batch incomplete/mismatched')
                runs+=count;group['result']=data
                if start['warmup']=='0':
                    key=int(start['round']),start['storage'],int(start['mode']),int(start['executor'])
                    if key in results:raise ValueError('Duplicate measurement')
                    results[key]=int(data['cycles'])
        elif kind=='SUMMARY':
            finish_batch()
            if set(data)!={'round','mode','executor','ddr_cycles','local_cycles','gain_x1000'}:raise ValueError('Bad summary fields')
            key=int(data['round']),int(data['mode']),int(data['executor'])
            if key in summaries:raise ValueError('Duplicate summary')
            rnd,mode,e=key
            ddr=results.get((rnd,'ddr_arena',mode,e));local=results.get((rnd,'local_arena',mode,e))
            if not ddr or not local or int(data['ddr_cycles'])!=ddr or int(data['local_cycles'])!=local or int(data['gain_x1000'])!=ddr*1000//local:
                raise ValueError('Summary disagrees with measurement')
            summaries[key]=data
        elif kind=='PASS':
            finish_batch();rounds=int(build['rounds'])
            if data!=dict(rounds=str(rounds),diagnostic=build['diagnostic'],measured_records=str(6*rounds),
                          warmup_records=str(6*rounds+1),ppu_runs=str(12+90*rounds),ppu_bit_exact='1',guards='1'):
                raise ValueError('Bad final summary')
            final=data
        else:raise ValueError('Unknown YOLO record: '+kind)
    if (build is None or final is None or sequence!=len(expected) or len(results)!=6*int(build['rounds']) or
        set(summaries)!=set(itertools.product(range(int(build['rounds'])),(2,),range(3)))):
        raise ValueError('Truncated/incomplete YOLO suite')
    wanted_profiles=[(0,'ddr_arena')]+[(rnd,('ddr_arena','local_arena')[order^(rnd&1)])
                                         for rnd in range(int(build['rounds'])) for order in range(2)]
    if ([(int(p['round']),p['storage']) for p in profiles]!=wanted_profiles or
        [(int(p['round']),p['storage']) for p in workspaces]!=wanted_profiles or
        len({p['plan_hash'] for p in profiles})!=1):
        raise ValueError('Missing profile rebind or changed normalized plans')
    return dict(status='SYNTHETIC_TEST_PASS' if build['hardware']=='0' else 'BOARD_PASS',build=build,
                ppu_runs=runs,measured_records=len(results),warmup_records=len(groups)-len(results),
                comparison='DDR legacy direct PPU count and all 40 result words',
                raw_head_bytes=907200 if build['diagnostic']=='1' else 0,
                performance='DIAGNOSTIC_ONLY' if build['diagnostic']=='1' else 'MEASURED_SAME_BITSTREAM',
                independent_accuracy='NOT_PROVEN',summaries=list(summaries.values()),
                workspaces=workspaces,
                measurements=[dict(g['result'],**{k:g['timing'][k] for k in
                    ('pad_cycles','host_cycles','head_publish_cycles')})
                    for g in groups if g['start']['warmup']=='0'])


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('log',type=Path);args=p.parse_args()
    manifest_path=args.log.parent/(args.log.stem+'.manifest.json')
    if manifest_path.is_file():
        import json
        manifest=json.loads(manifest_path.read_text())
    else:manifest=check()
    result=parse(args.log.read_text(),manifest)
    write(args.log.with_suffix('.summary.json'),result)
    print('YOLO_ASRAM_LOG='+result['status']+' ppu_runs='+str(result['ppu_runs'])+' performance='+result['performance'])


if __name__=='__main__':main()
