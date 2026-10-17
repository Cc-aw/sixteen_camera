#!/usr/bin/env python3
"""Strict last-session analysis for original-layout runtime DMA comparisons."""
import argparse
import hashlib
import json
from pathlib import Path

MODES=('legacy','read_coalesced','read_assembled')


def parse_long(raw, expected_build_id=None):
    lines=raw.splitlines()
    starts=[i for i,line in enumerate(lines) if line.startswith(('DMAL1,BUILD,','DMALF1,BUILD,'))]
    if not starts:raise ValueError('Missing DMA BUILD')
    lines=lines[starts[-1]:]
    first=lines[0].startswith('DMALF1,')
    prefix='DMALF1' if first else 'DMAL1'
    records=[]
    for line in lines:
        if any(marker in line for marker in (',FAIL,',',TRAP,',',DIFF,',',marker=MISMATCH')):
            raise ValueError('Firmware failure: '+line)
        if not line.startswith(prefix+',') and not (first and line.startswith('S2D1,RESULT,')):
            if prefix+',' in line:raise ValueError('Corrupt DMA record prefix')
            continue
        parts=line.split(',');fields={}
        for field in parts[2:]:
            key,separator,value=field.partition('=')
            if not separator or not key or not value or key in fields:raise ValueError('Invalid DMA field')
            fields[key]=value
        records.append((parts[1],fields))
    if not records or records[0][0]!='BUILD' or records[-1][0]!='PASS':raise ValueError('Incomplete DMA session')
    if sum(k=='BUILD' for k,f in records)!=1 or sum(k=='PASS' for k,f in records)!=1:
        raise ValueError('Duplicate DMA session markers')

    def number(fields,key):
        value=fields.get(key,'')
        if not value.isascii() or not value.isdecimal():raise ValueError('Invalid integer: '+key)
        return int(value)

    build,done=records[0][1],records[-1][1]
    for key,value in dict(schema=1,rounds=4,clock_hz=100000000,l2_kib=512,l2_banks=2).items():
        if number(build,key)!=value:raise ValueError('Wrong '+key)
    if build.get('layout')!='original':raise ValueError('Expected original layout')
    if not first and (number(build,'firmware_revision')!=2 or build.get('ppu_runs')!='monotonic'):
        raise ValueError('Expected fixed monotonic-run firmware revision 2')
    identity=number(build if first else done,'build_id')
    if not identity or (expected_build_id is not None and identity!=expected_build_id):
        raise ValueError('Hardware build identity mismatch')
    measured={};counters={};summaries={};window=None;current_result=None
    warmups=0;serial=0;phase=None;phases=[];batch=None;run_cursor=0
    for kind,fields in records[1:-1]:
        if kind=='BATCH_BEGIN' and not first:
            if batch is not None or phase is not None:raise ValueError('Overlapping batch')
            if number(fields,'run_before')!=run_cursor or number(fields,'frames')!=12:
                raise ValueError('PPU batch run regression or missing batch')
            batch=fields
            continue
        if kind=='WINDOW' and first:
            if window is not None:raise ValueError('Window without result')
            window=fields
            continue
        if kind=='RESULT':
            parent=window if first else fields
            if parent is None:raise ValueError('Unscoped first-layer result')
            mode=parent.get('mode');round_id=number(parent,'round');warmup=number(parent,'warmup')
            executor=number(parent,'parallel') if first else number(parent,'executor')-1
            if mode not in MODES or round_id not in range(4) or warmup not in (0,1):
                raise ValueError('Unknown measurement key')
            if executor not in (0,1) and not (not first and warmup and executor==-1):
                raise ValueError('Unknown executor')
            elapsed=number(fields,'batch_cycles' if first else 'cycles')
            if elapsed<=0 or number(fields,'frames')!=(3 if first else 12):raise ValueError('Inactive measurement')
            if first:
                if fields.get('profile')!='reference' or number(fields,'pack_cycles') or number(fields,'bit_exact')!=1:
                    raise ValueError('First-layer workload differs')
                if number(fields,'round')!=round_id or number(fields,'warmup')!=warmup:
                    raise ValueError('Window/result mismatch')
                if fields.get('executor')!=('parallel' if executor else 'serial'):
                    raise ValueError('Executor/result mismatch')
                if number(fields,'compared_bytes')!=3686400:raise ValueError('Incomplete first-layer comparison')
            elif number(fields,'ppu_results_bit_exact')!=1:
                raise ValueError('Model output not bit exact')
            if not first:
                if batch is None or any(fields.get(k)!=batch.get(k) for k in ('mode','round','warmup','executor')):
                    raise ValueError('Batch/result mismatch')
                if number(fields,'run_first')!=run_cursor+1 or number(fields,'run_last')!=run_cursor+12:
                    raise ValueError('PPU result run regression or reuse')
                run_cursor+=12;batch=None
            serial+=1
            current_result=(serial,mode,round_id,executor,warmup)
            if warmup:warmups+=1
            else:
                key=(mode,round_id,executor)
                if key in measured:raise ValueError('Duplicate formal result')
                measured[key]=elapsed
            window=None
        elif kind=='COUNTERS':
            if current_result is None:raise ValueError('Counters without result')
            index,mode,round_id,executor,warmup=current_result
            lane=number(fields,'lane')
            if lane not in range(3) or (index,lane) in counters:raise ValueError('Duplicate counter lane')
            if fields.get('mode')!=mode or number(fields,'round')!=round_id or number(fields,'warmup')!=warmup:
                raise ValueError('Counter window mismatch')
            if number(fields,'parallel' if first else 'executor')!=(executor if first else executor+1):
                raise ValueError('Counter executor mismatch')
            if number(fields,'actual_mode')!=MODES.index(mode):raise ValueError('Runtime mode was not applied')
            if not first and number(fields,'build_id')!=identity:raise ValueError('Per-lane hardware identity mismatch')
            values={f'c{i}':number(fields,f'c{i}') for i in range(8,35)}
            if values['c31']:raise ValueError('Hardware DMA fault')
            active=executor==1 or lane==0
            if active and (not values['c8'] or not values['c9'] or not values['c33']):
                raise ValueError('Inactive hardware counters')
            if active and mode!='legacy' and not values['c11']:raise ValueError('No optimized groups')
            if active and mode=='read_assembled' and not values['c21']:raise ValueError('No assembled writes')
            if mode!='read_assembled' and values['c21']:raise ValueError('Unexpected row assembly')
            counters[index,lane]=values
        elif kind=='SUMMARY':
            mode=fields.get('mode')
            if mode not in MODES or mode in summaries:raise ValueError('Duplicate summary')
            summaries[mode]=fields
        elif kind in ('PHASE_BEGIN','PHASE_END') and not first:
            mode=fields.get('mode')
            if kind=='PHASE_BEGIN':
                if phase is not None or batch is not None or mode not in MODES:raise ValueError('Invalid phase begin')
                if number(fields,'run_before')!=run_cursor:raise ValueError('PPU phase run regression')
                phase=mode
            else:
                if phase!=mode or mode in phases:raise ValueError('Invalid phase end')
                if number(fields,'run_last')!=run_cursor+78:raise ValueError('Incomplete PPU phase runs')
                run_cursor+=78
                phases.append(mode);phase=None
        else:raise ValueError('Unexpected DMA record: '+kind)
    expected={(m,r,e) for m in MODES for r in range(4) for e in range(2)}
    if set(measured)!=expected or set(summaries)!=set(MODES):raise ValueError('Missing formal records')
    if len(counters)!=serial*3:raise ValueError('Missing lane counters')
    if warmups!=(30 if first else 31):raise ValueError('Missing warmup records')
    if number(done,'measured_records')!=24:raise ValueError('Incorrect PASS count')
    if first:
        if number(done,'warmup_records')!=warmups or number(done,'full_output_bit_exact')!=1:
            raise ValueError('Incorrect first-layer PASS')
    elif phase is not None or batch is not None or phases!=list(MODES):raise ValueError('Incomplete phase diagnostics')
    elif number(done,'ppu_runs')!=run_cursor or run_cursor!=894:raise ValueError('Incomplete PPU run sequence')
    totals={(m,e):sum(measured[m,r,e] for r in range(4)) for m in MODES for e in range(2)}
    aggregate=[]
    for mode in MODES:
        s,p=totals[mode,0],totals[mode,1]
        expected_summary=dict(serial_cycles=s,parallel_cycles=p,scaling_x1000=s*1000//p,
            serial_gain_x1000=totals['legacy',0]*1000//s,parallel_gain_x1000=totals['legacy',1]*1000//p)
        if any(number(summaries[mode],k)!=v for k,v in expected_summary.items()):raise ValueError('Summary arithmetic mismatch')
        aggregate.append(dict(mode=mode,serial_cycles=s,parallel_cycles=p,scaling=s/p,
            efficiency=s/(3*p),serial_gain=totals['legacy',0]/s,parallel_gain=totals['legacy',1]/p))
    result=dict(status='PASS',scope='first_conv' if first else 'full_graph_ppu_results',
        build_id=f'{identity:016x}',measured_records=24,warmup_records=warmups,
        prior_sessions_ignored=len(starts)-1,aggregate=aggregate)
    if not first:result.update(firmware_revision=2,ppu_runs=run_cursor)
    return result



ABLATION_MODES=MODES+('spad_assembled',)


def parse_short(raw, expected_build_id=None):
    lines=raw.splitlines()
    starts=[i for i,line in enumerate(lines) if line.startswith('DMAL1,BUILD,')]
    if not starts:raise ValueError('Missing DMA BUILD')
    lines=lines[starts[-1]:]
    records=[]
    for line in lines:
        if any(marker in line for marker in (',FAIL,',',TRAP,',',DIFF,',',PPU_DIFF,',',CHECK_FAILED,',',marker=MISMATCH')):
            raise ValueError('Firmware failure: '+line)
        if not line.startswith(('DMAL1,','ATSOFT1,FRAME_END,')):
            if 'DMAL1,' in line:raise ValueError('Corrupt DMA record prefix')
            continue
        parts=line.split(',');fields={}
        for item in parts[2:]:
            key,sep,value=item.partition('=')
            if not sep or not key or not value or key in fields:raise ValueError('Invalid DMA field')
            fields[key]=value
        records.append((parts[1],fields))
    if not records or records[0][0]!='BUILD' or records[-1][0]!='PASS':raise ValueError('Incomplete short DMA session')
    def number(fields,key):
        value=fields.get(key,'')
        if not value.isascii() or not value.isdecimal():raise ValueError('Invalid integer: '+key)
        return int(value)
    build,done=records[0][1],records[-1][1]
    for key,value in dict(schema=2,rounds=1,executors=2,frames=12,warmup_frames=3,phase_diagnostics=0,
                          clock_hz=100000000,l2_kib=512,l2_banks=2,firmware_revision=3,failure_diagnostics=1).items():
        if number(build,key)!=value:raise ValueError('Wrong '+key)
    if build.get('suite')!='short_ablation' or build.get('layout')!='original' or build.get('ppu_runs')!='monotonic':
        raise ValueError('Wrong short-suite contract')
    count=number(build,'load_modes')
    if count not in (3,4):raise ValueError('Wrong mode count')
    modes=ABLATION_MODES[:count]
    ablation='complete' if count==4 else 'missing_spad_only'
    if build.get('ablation')!=ablation or done.get('ablation')!=ablation:raise ValueError('Wrong ablation status')
    identity=number(done,'build_id')
    if not identity or expected_build_id is not None and identity!=expected_build_id:raise ValueError('Hardware build identity mismatch')
    schedule=[('legacy',0,1,12)]
    for mode in modes:
        for executor in (1,2):schedule.extend([(mode,executor,1,3),(mode,executor,0,12)])
    batch=None;result=None;frames={};lanes=set();index=0;cursor=0;measured={};summaries={};traffic={}
    for kind,f in records[1:-1]:
        if kind=='BATCH_BEGIN':
            if batch is not None or index>=len(schedule):raise ValueError('Overlapping or extra batch')
            expected=schedule[index]
            actual=(f.get('mode'),number(f,'executor'),number(f,'warmup'),number(f,'frames'))
            if actual!=expected or number(f,'round')!=0 or number(f,'run_before')!=cursor:raise ValueError('Wrong batch schedule or run sequence')
            batch=f;result=None;frames={};lanes=set()
        elif kind=='FRAME_END':
            if batch is None or result is not None:raise ValueError('Frame outside active batch')
            frame=number(f,'frame');lane=number(f,'device')
            e=number(batch,'executor');n=number(batch,'frames')
            if frame>=n or frame in frames or lane not in range(3) or (e!=2 and lane!=0):raise ValueError('Frame/lane coverage')
            if f.get('executor')!=('direct_serial' if e==0 else 'frontend_serial' if e==1 else 'frontend_parallel'):
                raise ValueError('Frame executor mismatch')
            if number(f,'image')!=frame%3 or number(f,'host_calls')!=12 or f.get('marker')!='COMPLETE' or int(f.get('word_errors','0')):
                raise ValueError('Incomplete output comparison')
            frames[frame]=lane
        elif kind=='RESULT':
            if batch is None or result is not None:raise ValueError('Unscoped result')
            for key in ('mode','round','warmup','executor','frames'):
                if f.get(key)!=batch.get(key):raise ValueError('Batch/result mismatch')
            n=number(f,'frames');e=number(f,'executor')
            if len(frames)!=n or set(frames)!=set(range(n)):raise ValueError('Missing frame output comparisons')
            quota=[(n+2-d)//3 for d in range(3)] if e==2 else [n,0,0]
            if [list(frames.values()).count(d) for d in range(3)]!=quota:raise ValueError('Wrong frame quotas')
            if number(f,'run_first')!=cursor+1 or number(f,'run_last')!=cursor+n:raise ValueError('PPU result run regression')
            if number(f,'cycles')<=0 or number(f,'ppu_results_bit_exact')!=1 or f.get('comparison')!='legacy_direct' or f.get('scope')!='full_graph':
                raise ValueError('Wrong workload or output check')
            result=f;cursor+=n
            if not number(f,'warmup'):measured[f['mode'],e]=number(f,'cycles')
        elif kind=='COUNTERS':
            if batch is None or result is None:raise ValueError('Counters without result')
            lane=number(f,'lane');mode=batch['mode'];e=number(batch,'executor')
            if lane not in range(3) or lane in lanes:raise ValueError('Duplicate counter lane')
            for key in ('mode','round','warmup','executor'):
                if f.get(key)!=batch.get(key):raise ValueError('Counter window mismatch')
            if number(f,'build_id')!=identity or number(f,'actual_mode')!=ABLATION_MODES.index(mode) or number(f,'mode_switch_rejects'):
                raise ValueError('Wrong hardware identity or mode')
            values={f'c{i}':number(f,f'c{i}') for i in range(8,35)}
            if values['c31']:raise ValueError('DMA hardware fault')
            active=e==2 or lane==0
            if active:
                if not all(values[k] for k in ('c8','c9','c33')):raise ValueError('Inactive counters')
                if mode!='legacy' and not values['c11']:raise ValueError('No optimized groups')
                if mode in ('read_assembled','spad_assembled') and not values['c21']:raise ValueError('No assembled writes')
            if mode not in ('read_assembled','spad_assembled') and values['c21']:raise ValueError('Unexpected row assembly')
            if not active and any(values[k] for k in ('c8','c9','c22','c33')):raise ValueError('Traffic on inactive lane')
            if not number(batch,'warmup'):traffic[mode,e,lane]=values
            lanes.add(lane)
            if len(lanes)==3:batch=None;result=None;index+=1
        elif kind=='SUMMARY':
            mode=f.get('mode')
            if batch is not None or index!=len(schedule) or mode not in modes or mode in summaries:raise ValueError('Premature or duplicate summary')
            summaries[mode]=f
        else:raise ValueError('Unexpected short-suite record: '+kind)
    if batch is not None or index!=len(schedule) or set(summaries)!=set(modes):raise ValueError('Missing short-suite windows')
    expected_runs=12+30*count
    for key,value in dict(measured_records=2*count,warmup_records=2*count+1,load_modes=count,ppu_runs=expected_runs,phase_diagnostics=0,ppu_results_bit_exact=1).items():
        if number(done,key)!=value:raise ValueError('Wrong PASS '+key)
    if cursor!=expected_runs:raise ValueError('Incomplete PPU run sequence')
    aggregate=[]
    for mode in modes:
        serial,parallel=measured[mode,1],measured[mode,2]
        expected=dict(frames=12,serial_cycles=serial,parallel_cycles=parallel,scaling_x1000=serial*1000//parallel,
            serial_gain_x1000=measured['legacy',1]*1000//serial,parallel_gain_x1000=measured['legacy',2]*1000//parallel)
        if any(number(summaries[mode],k)!=v for k,v in expected.items()):raise ValueError('Summary arithmetic mismatch')
        counts=[traffic[mode,2,lane] for lane in range(3)]
        aggregate.append(dict(mode=mode,frames_per_executor=12,serial_cycles=serial,parallel_cycles=parallel,
            serial_ms_per_frame=serial/1200000,parallel_ms_per_frame=parallel/1200000,
            scaling=serial/parallel,efficiency=serial/(3*parallel),serial_gain=measured['legacy',1]/serial,
            parallel_gain=measured['legacy',2]/parallel,
            get_per_frame=sum(c['c18']+c['c19'] for c in counts)/12,
            tl_return_bytes_per_frame=sum(c['c33'] for c in counts)/12,
            spad_dma_writes_per_frame=sum(c['c22'] for c in counts)/12))
    return dict(status='PASS',scope='full_graph_ppu_results',suite='short_ablation',schema=2,
        ablation=ablation,build_id=f'{identity:016x}',firmware_revision=3,ppu_runs=cursor,
        measured_records=2*count,warmup_records=2*count+1,frames_per_executor=12,
        parallel_lane_frames=[4,4,4],prior_sessions_ignored=len(starts)-1,aggregate=aggregate)



def parse_first_short(raw, expected_build_id=None):
    lines=raw.splitlines();starts=[i for i,line in enumerate(lines) if line.startswith('DMALF1,BUILD,')]
    lines=lines[starts[-1]:]
    records=[]
    for line in lines:
        if any(k in line for k in (',FAIL,',',TRAP,',',DIFF,',',marker=MISMATCH')):raise ValueError('Firmware failure')
        if not line.startswith(('DMALF1,','S2D1,RESULT,')):
            if 'DMALF1,' in line:raise ValueError('Corrupt DMA prefix')
            continue
        fields={}
        for item in line.split(',')[2:]:
            k,sep,v=item.partition('=')
            if not sep or not k or not v or k in fields:raise ValueError('Invalid DMA field')
            fields[k]=v
        records.append((line.split(',')[1],fields))
    def number(f,k):
        v=f.get(k,'')
        if not v.isascii() or not v.isdecimal():raise ValueError('Invalid integer: '+k)
        return int(v)
    if not records or records[0][0]!='BUILD' or records[-1][0]!='PASS':raise ValueError('Incomplete first-layer session')
    build,done=records[0][1],records[-1][1]
    for k,v in dict(schema=2,frames=12,warmup_frames=3,executors=2,clock_hz=100000000,l2_kib=512,l2_banks=2).items():
        if number(build,k)!=v:raise ValueError('Wrong '+k)
    count=number(build,'modes');identity=number(build,'build_id')
    if count not in (3,4) or not identity or expected_build_id is not None and identity!=expected_build_id:
        raise ValueError('Wrong mode count or identity')
    if build.get('suite')!='short_first_ablation' or build.get('layout')!='original':raise ValueError('Wrong first-layer suite')
    modes=ABLATION_MODES[:count];ablation='complete' if count==4 else 'missing_spad_only'
    if build.get('ablation')!=ablation or done.get('ablation')!=ablation:raise ValueError('Wrong ablation status')
    schedule=[]
    for mode in modes:
        for e in (0,1):
            schedule.append((mode,e,1,0,3))
            schedule.extend((mode,e,0,b,n) for b,n in enumerate((3,3,3,3)))
    window=None;result=None;lanes=set();index=0;totals={(m,e):0 for m in modes for e in (0,1)};summaries={}
    for kind,f in records[1:-1]:
        if kind=='WINDOW':
            if window is not None or index>=len(schedule):raise ValueError('Overlapping window')
            expected=schedule[index]
            if (f.get('mode'),number(f,'parallel'),number(f,'warmup'),number(f,'round'))!=expected[:4]:raise ValueError('Wrong first-layer schedule')
            window=f;lanes=set();result=None
        elif kind=='RESULT':
            if window is None or result is not None:raise ValueError('Result without window')
            mode,e,w,b,n=schedule[index]
            if number(f,'frames')!=n or number(f,'compared_bytes')!=n*1228800 or number(f,'bit_exact')!=1 or number(f,'pack_cycles'):
                raise ValueError('Wrong first-layer output comparison')
            if f.get('profile')!='reference' or f.get('executor')!=('parallel' if e else 'serial') or number(f,'round')!=b or number(f,'warmup')!=w:
                raise ValueError('Window/result mismatch')
            if number(f,'batch_cycles')<=0:raise ValueError('Inactive measurement')
            if not w:totals[mode,e]+=number(f,'batch_cycles')
            result=f
        elif kind=='COUNTERS':
            if window is None or result is None:raise ValueError('Counters without result')
            mode,e,w,b,n=schedule[index];lane=number(f,'lane')
            if lane not in range(3) or lane in lanes:raise ValueError('Duplicate lane counters')
            for k in ('mode','parallel','warmup','round'):
                if f.get(k)!=window.get(k):raise ValueError('Counter window mismatch')
            if number(f,'actual_mode')!=ABLATION_MODES.index(mode) or number(f,'mode_switch_rejects'):raise ValueError('Mode mismatch')
            c={i:number(f,f'c{i}') for i in range(8,35)}
            if c[31]:raise ValueError('DMA hardware fault')
            active=lane<n if e else lane==0
            if active and (not c[8] or not c[9] or not c[33]):raise ValueError('Inactive counter')
            if active and mode!='legacy' and not c[11]:raise ValueError('No optimized groups')
            if active and mode in ('read_assembled','spad_assembled') and not c[21]:raise ValueError('No assembly')
            if mode not in ('read_assembled','spad_assembled') and c[21]:raise ValueError('Unexpected assembly')
            if not active and any(c[i] for i in (8,9,22,33)):raise ValueError('Inactive lane has traffic')
            lanes.add(lane)
            if len(lanes)==3:window=None;result=None;index+=1
        elif kind=='SUMMARY':
            mode=f.get('mode')
            if index!=len(schedule) or mode not in modes or mode in summaries:raise ValueError('Premature or duplicate summary')
            summaries[mode]=f
        else:raise ValueError('Unexpected first-layer record')
    if window is not None or index!=len(schedule) or set(summaries)!=set(modes):raise ValueError('Missing first-layer windows')
    for k,v in dict(measured_records=count*8,warmup_records=count*2,full_output_bit_exact=1).items():
        if number(done,k)!=v:raise ValueError('Wrong PASS '+k)
    aggregate=[]
    for mode in modes:
        serial,parallel=totals[mode,0],totals[mode,1]
        expected=dict(frames=12,serial_cycles=serial,parallel_cycles=parallel,scaling_x1000=serial*1000//parallel,
            serial_gain_x1000=totals['legacy',0]*1000//serial,parallel_gain_x1000=totals['legacy',1]*1000//parallel)
        if any(number(summaries[mode],k)!=v for k,v in expected.items()):raise ValueError('Summary arithmetic mismatch')
        aggregate.append(dict(mode=mode,frames_per_executor=12,serial_cycles=serial,parallel_cycles=parallel,
            serial_ms_per_frame=serial/1200000,parallel_ms_per_frame=parallel/1200000,
            scaling=serial/parallel,efficiency=serial/(3*parallel),serial_gain=totals['legacy',0]/serial,
            parallel_gain=totals['legacy',1]/parallel))
    return dict(status='PASS',scope='first_conv',schema=2,suite='short_first_ablation',ablation=ablation,
        build_id=f'{identity:016x}',frames_per_executor=12,measured_records=count*8,warmup_records=count*2,
        prior_sessions_ignored=len(starts)-1,aggregate=aggregate)

def parse(raw, expected_build_id=None):
    starts=[line for line in raw.splitlines() if line.startswith(('DMAL1,BUILD,','DMALF1,BUILD,'))]
    if starts and starts[-1].startswith('DMALF1,') and ',schema=2,' in starts[-1]:
        return parse_first_short(raw,expected_build_id)
    if starts and starts[-1].startswith('DMAL1,') and ',schema=2,' in starts[-1]:
        return parse_short(raw,expected_build_id)
    return parse_long(raw,expected_build_id)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('log',type=Path)
    p.add_argument('--context',type=Path,required=True)
    p.add_argument('--output',type=Path,default=Path('build/reports/dma_load.json'))
    args=p.parse_args()
    context=json.loads(args.context.read_text())
    raw=args.log.read_bytes()
    try:report=parse(raw.decode('utf-8',errors='replace'),int(context['dma_load_build_id'],16))
    except (ValueError,KeyError) as exc:p.exit(1,'DMA_LOG_FAIL: '+str(exc)+'\n')
    report.update(source=str(args.log),sha256=hashlib.sha256(raw).hexdigest())
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2)+'\n')
    for row in report['aggregate']:
        print(f'{row["mode"]}: scaling={row["scaling"]:.4f} serial_gain={row["serial_gain"]:.4f} parallel_gain={row["parallel_gain"]:.4f}')


if __name__=='__main__':main()
