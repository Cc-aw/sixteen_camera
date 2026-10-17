#!/usr/bin/env python3
"""Strict last-session analysis for original-layout runtime DMA comparisons."""
import argparse
import hashlib
import json
from pathlib import Path

MODES=('legacy','read_coalesced','read_assembled')


def parse(raw, expected_build_id=None):
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
