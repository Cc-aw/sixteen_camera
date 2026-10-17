#!/usr/bin/env python3
"""Validate local three-way frontend UART captures and report cycles only."""
import argparse
import json
from pathlib import Path
from statistics import median

MODES=('direct_serial','frontend_serial','frontend_parallel')
BUILD={'schema','version','diagnostics','frames','modes','clock_hz','control_abi',
       'entries_per_frame','raw_per_frame','drains_per_frame','hosts_per_frame','ppu'}
FRAME={'executor','frame','device','image','slot','begin_cycles','end_cycles',
       'frame_cycles','host_calls','marker'}
MODE={'executor','frames','devices','cycles','device0_frames','device1_frames','device2_frames',
      'launches','host_calls','cpu_pad_cycles','irqs','irq_body_cycles','triple_samples',
      'busy_samples','diagnostics','ppu','comparison_outside_timing'}
DIAG={'host_service_cycles','head_publish_cycles','ppu_service_cycles','host_max_cycles',
      'host_max_kind','host_max_phase'}
PERF={'direct_cycles','frontend_single_cycles','frontend_parallel_cycles',
      'direct_to_single_x1000','frontend_scaling_x1000','direct_to_parallel_x1000'}
PASS={'modes','frames_per_mode','direct_vs_frontend_single','direct_vs_frontend_parallel',
      'device0_frames','device1_frames','device2_frames','ppu','pad_hosts_per_frame',
      'head_hosts_per_frame','independent_accuracy','ppu_results','marker'}
TEXT={'executor','marker','ppu','direct_vs_frontend_single','direct_vs_frontend_parallel',
      'independent_accuracy','ppu_results'}

def decode(line):
    parts=line.split(',')
    if len(parts)<3:raise ValueError('record has no fields')
    row={}
    for token in parts[2:]:
        k,sep,v=token.partition('=')
        if not sep or not k or not v or k in row:raise ValueError('invalid/duplicate field '+token)
        if k in TEXT:row[k]=v
        else:
            if not v.isdecimal():raise ValueError('invalid integer '+token)
            n=int(v)
            if n>=2**64:raise ValueError('integer outside uint64 '+token)
            row[k]=n
    return parts[0],parts[1],row

def require(condition,message):
    if not condition:raise ValueError(message)

def lifetime(mode):
    """Software frame ownership intervals, including HOST and PPU waits."""
    cycles=mode['summary']['cycles']
    events={0:0,cycles:0}
    lanes={d:[] for d in range(mode['summary']['devices'])}
    for f in mode['frames']:
        a,b=f['begin_cycles'],f['end_cycles']
        events[a]=events.get(a,0)+1;events[b]=events.get(b,0)-1
        lanes[f['device']].append(f)
    spans=[0,0,0,0];previous=active=0
    for at,delta in sorted(events.items()):
        spans[active]+=at-previous
        active+=delta;previous=at
        require(0<=active<=3,'invalid interval concurrency')
    require(active==0 and sum(spans)==cycles,'interval partition does not close')
    per_lane=[]
    for d,fs in lanes.items():
        fs.sort(key=lambda f:f['begin_cycles'])
        gaps=[fs[i]['begin_cycles']-fs[i-1]['end_cycles'] for i in range(1,len(fs))]
        per_lane.append(dict(device=d,frames=len(fs),first_begin_cycles=fs[0]['begin_cycles'],
            last_end_cycles=fs[-1]['end_cycles'],lifetime_cycles=sum(f['frame_cycles'] for f in fs),
            observed_refill_gap_cycles=sum(gaps),observed_refill_gap_max=max(gaps,default=0),
            final_tail_cycles=cycles-fs[-1]['end_cycles']))
    require(sum(x['lifetime_cycles'] for x in per_lane)==sum(i*spans[i] for i in range(4)),
            'lifetime/concurrency integrals differ')
    result=dict(ownership_overlap_cycles=spans,lanes=per_lane,
        frame_lifetime_median=median(f['frame_cycles'] for f in mode['frames']))
    if mode['summary']['diagnostics']:
        result['graph_lifetime_median']=median(f['graph_done_cycles']-f['begin_cycles'] for f in mode['frames'])
        result['post_graph_lifetime_median']=median(f['end_cycles']-f['graph_done_cycles'] for f in mode['frames'])
    return result

def validate_mode(build,row,frames,index):
    diag=build['diagnostics'];name=MODES[index];lanes=3 if index==2 else 1
    require(set(row)==MODE|(DIAG if diag else set()),'mode schema differs')
    require(row['executor']==name and row['frames']==12 and row['devices']==lanes and
            row['diagnostics']==diag and row['ppu']=='hardware' and row['comparison_outside_timing']==1,
            'mode configuration differs')
    require(row['cycles']>0 and len(frames)==12,'missing frames or mode cycles')
    require(row['launches']==(12 if index else 0) and row['host_calls']==144,'incomplete native work')
    require(0<row['cpu_pad_cycles']<row['cycles'],'missing padding accounting')
    require(0<=row['triple_samples']<=row['busy_samples'],'invalid busy sampling counts')
    require(row['irq_body_cycles']<=row['cycles'],'invalid IRQ timing')
    if index==0:
        require(not any(row[k] for k in ('irqs','irq_body_cycles','busy_samples','triple_samples')),
                'direct mode unexpectedly uses frontend events')
    else:require(row['irqs']>0 and row['busy_samples']>0,'missing frontend event/sampling evidence')
    if lanes==1:require(row['triple_samples']==0,'single lane reports triple busy')
    counts=[0,0,0];last=[0,0,0]
    for i,f in enumerate(frames):
        require(set(f)==FRAME|({'graph_done_cycles'} if diag else set()),'frame schema differs')
        require(f['executor']==name and f['frame']==i and f['image']==i%3 and
                f['marker']=='COMPLETE' and f['host_calls']==12,'incomplete/misassigned frame')
        d=f['device']
        require(d<lanes and f['slot'] in (0,1),'invalid device or Head slot')
        a,b=f['begin_cycles'],f['end_cycles']
        require(0<a<b<=row['cycles'] and f['frame_cycles']==b-a and a>=last[d],
                'invalid/overlapping frame lifetime')
        if diag:require(a<f['graph_done_cycles']<b,'invalid graph completion event')
        counts[d]+=1;last[d]=b
    expected=[12//lanes if d<lanes else 0 for d in range(3)]
    require(counts==expected and counts==[row[f'device{d}_frames'] for d in range(3)],'unbalanced lane work')
    if diag:
        require(0<row['head_publish_cycles']<=row['host_service_cycles']<=row['cycles'] and
                row['cpu_pad_cycles']<=row['host_service_cycles'] and
                0<row['ppu_service_cycles']<=row['cycles'] and
                0<row['host_max_cycles']<=row['host_service_cycles'] and
                row['host_max_kind'] in (1,2) and row['host_max_phase']<165,'invalid diagnostic accounting')
    result=dict(summary=row,frames=list(frames))
    result['derived']=lifetime(result)
    return result

def parse(text,latest=False):
    if 'YOLO32_FRONTEND,BUILD,schema=2,version=34,' in text:
        from analyze_boundary_log import parse_boundary
        return parse_boundary(text,latest)
    lines=text.splitlines()
    if latest:
        boots=[i for i,l in enumerate(lines) if l.strip().startswith('YOLO32_FRONTEND,BUILD,')]
        if boots:lines=lines[boots[-1]:]
    sessions=[];errors=[];session=None;frames=[]
    for lineno,line in enumerate(lines,1):
        line=line.strip()
        if not line.startswith(('YOLO32_FRONTEND,','ATSOFT1,')):continue
        try:
            family,kind,row=decode(line)
            if family=='YOLO32_FRONTEND' and kind=='BUILD':
                if session is not None:require(session['complete'],'previous boot is incomplete')
                require(set(row)==BUILD,'invalid build schema')
                require(all(row[k]==v for k,v in dict(schema=1,version=33,frames=12,modes=3,
                    clock_hz=100000000,control_abi=131072,entries_per_frame=10870,
                    raw_per_frame=10478,drains_per_frame=380,hosts_per_frame=12,ppu='hardware').items())
                    and row['diagnostics'] in (0,1),'unsupported frontend configuration')
                session=dict(build=row,modes=[],complete=False);sessions.append(session);frames=[]
                continue
            require(family=='ATSOFT1' and session is not None and not session['complete'],
                    'record outside an active local frontend session')
            require(kind not in ('FAIL','TRAP','DIAG'),'firmware failure '+kind)
            if kind=='FRAME_END':
                require('perf' not in session and len(session['modes'])<3 and len(frames)<12,'extra frame')
                require(row.get('frame')==len(frames) and row.get('executor')==MODES[len(session['modes'])],
                        'frame order differs')
                frames.append(row)
            elif kind=='MODE':
                require('perf' not in session and len(session['modes'])<3,'extra mode')
                result=validate_mode(session['build'],row,frames,len(session['modes']))
                session['modes'].append(result);frames=[]
            elif kind=='PERF':
                require(set(row)==PERF and len(session['modes'])==3 and not frames and 'perf' not in session,
                        'missing/duplicate performance summary')
                a,b,c=[m['summary']['cycles'] for m in session['modes']]
                require([row[k] for k in ('direct_cycles','frontend_single_cycles','frontend_parallel_cycles')]==[a,b,c],
                        'performance cycles differ from mode summaries')
                require(row['direct_to_single_x1000']==a*1000//b and row['frontend_scaling_x1000']==b*1000//c and
                        row['direct_to_parallel_x1000']==a*1000//c,'speedup arithmetic differs')
                session['perf']=row
                session['ratios']=dict(direct_to_single=a/b,frontend_scaling=b/c,direct_to_parallel=a/c,
                    average_parallel_frame_cycles=c/12,target_2p8_parallel_max=a*5//14,
                    remaining_to_2p8=max(0,c-a*5//14))
            elif kind=='PASS':
                require(set(row)==PASS and 'perf' in session and not frames,'incomplete final result')
                expected=dict(modes=3,frames_per_mode=12,direct_vs_frontend_single='bit_exact',
                    direct_vs_frontend_parallel='bit_exact',device0_frames=4,device1_frames=4,device2_frames=4,
                    ppu='hardware',pad_hosts_per_frame=6,head_hosts_per_frame=6,
                    independent_accuracy='not_proven',ppu_results='bit_exact',marker='ALL_COMPLETE')
                require(row==expected,'invalid final consistency result')
                session['complete']=True
            else:raise ValueError('unknown frontend record '+kind)
        except (ValueError,KeyError,IndexError,TypeError) as error:
            errors.append(f'line {lineno}: {error}')
    if not sessions:errors.append('no local frontend build record')
    if session is not None and (not session['complete'] or frames):errors.append('truncated frontend session')
    return errors,sessions

def report(sessions):
    lines=[]
    for i,s in enumerate(sessions,1):
        lines.append(f"会话 {i}，diagnostics={s['build']['diagnostics']}；每组 12 帧，单位为周期。")
        for m in s['modes']:
            r=m['summary'];d=m['derived']
            lines.append(f"  {r['executor']}: 整组={r['cycles']:,}，帧生命周期中位数={d['frame_lifetime_median']:,.1f}；HOST={r['host_calls']}，CPU 填充={r['cpu_pad_cycles']:,}，IRQ 函数体={r['irq_body_cycles']:,}。")
            if r['diagnostics']:
                lines.append(f"    图生命周期中位数={d['graph_lifetime_median']:,.1f}，图完成后生命周期中位数={d['post_graph_lifetime_median']:,.1f}；HOST 服务={r['host_service_cycles']:,}，其中 Head 发布={r['head_publish_cycles']:,}；PPU 服务={r['ppu_service_cycles']:,}。")
                lines.append(f"    最长 HOST 服务={r['host_max_cycles']:,}，kind={r['host_max_kind']}，stage={r['host_max_phase']}。")
            if r['executor']=='frontend_parallel':
                lines.append('    同时拥有 0/1/2/3 个帧的周期='+','.join(f'{v:,}' for v in d['ownership_overlap_cycles']))
                lines.append(f"    三路硬件 busy 条件样本={r['triple_samples']}/{r['busy_samples']}；稀疏采样，不是连续计算利用率。")
                for lane in d['lanes']:
                    lines.append(f"    通道 {lane['device']}: 帧数={lane['frames']}，观测续帧间隙合计={lane['observed_refill_gap_cycles']:,}，最长={lane['observed_refill_gap_max']:,}。")
        r=s['ratios']
        lines.append(f"  CPU 直接/单前端={r['direct_to_single']:.6f}；单前端/三前端={r['frontend_scaling']:.6f}；CPU 直接/三前端={r['direct_to_parallel']:.6f}。")
        lines.append(f"  三前端平均每帧吞吐口径={r['average_parallel_frame_cycles']:,.2f} 周期；达到相对 CPU 直接路径 2.8 倍仍需减少={r['remaining_to_2p8']:,} 周期。")
    for s in sessions:
        if s['build'].get('version')==34:
            from analyze_boundary_log import boundary_report
            lines.extend(boundary_report(s))
    lines.append('生命周期包含 HOST 和 PPU 等待；Head 发布、填充、IRQ 等统计可能包含阻塞或相互重叠，不能相加为可节省周期。正式和诊断结果分别比较。')
    lines.append('本轮不输出原始 Head 或全部 PPU 字；一致性由固件内部逐帧比较检测数及 40 个 PPU 字确认，独立检测精度未验证。')
    return '\n'.join(lines)

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('log',type=Path)
    p.add_argument('--latest',action='store_true')
    p.add_argument('--json',type=Path)
    p.add_argument('--report',type=Path)
    args=p.parse_args()
    errors,sessions=parse(args.log.read_text(errors='replace'),args.latest)
    if args.json:args.json.write_text(json.dumps(dict(valid=not errors,errors=errors,sessions=sessions),indent=2)+'\n')
    output='\n'.join('FAIL: '+e for e in errors) if errors else report(sessions)
    output+='\nYOLO32_FRONTEND_LOG_CHECK='+('FAIL' if errors else 'PASS')+'\n'
    if args.report:args.report.write_text(output)
    print(output,end='')
    return bool(errors)

if __name__=='__main__':
    raise SystemExit(main())
