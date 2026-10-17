#!/usr/bin/env python3
"""Strict v34 boundary and full-chain memory diagnostics, cycles only.

Used by analyze_log.py. Raw counter snapshots are retained without treating
sequential queries, sparse samples or different clock domains as exact idle.
"""
from collections import defaultdict
from statistics import mean

from analyze_log import BUILD, MODES, parse as base_parse, require

BOUNDARY=set('executor frame device image tag phase kind raw barriers start_cycles ready_lo_cycles pending_cycles seen_cycles cpu_begin_cycles cpu_end_cycles resume_begin_cycles resume_end_cycles irq_hint_cycles launch_begin_cycles launch_end_cycles samples run drain host done other transition run_empty run_idle_empty drain_busy drain_idle drain_barrier drain_host drain_finish cursor_max fetched_max issued_max fifo_max cursor_hold_min_cycles probe_query_cycles direct_fence_calls direct_fence_cycles'.split())
DEVICE=set('available probe_fault abi blocks status soc_hz ddr_hz base slots mapping'.split())
WINDOW=set('executor id pass kind target_tag sequence blocks cpu_span_cycles batch_cycles cpu_begin_cycles cpu_end_cycles setup_cycles stop_cycles snapshot_cycles read_cycles'.split())|{f'{end}_{what}{d}' for end in ('start','end') for what in ('cursor','state') for d in range(3)}
GEM=set('executor pass frame device image valid config_cycles capture_cycles rs_active load_dma_wait load_spad_wait exec_active store_dma_wait store_spad_wait'.split())
PAIR=set('executor pass target_tag target_frame target_lane image frames cycles ppu_results'.split())
COMPLETE=set('version boundary_records short_window_pairs memory_available marker'.split())
COUNTERS=('rs_active','load_dma_wait','load_spad_wait','exec_active','store_dma_wait','store_spad_wait')
TEXT={'executor','mapping','marker','ppu_results','ppu','direct_vs_frontend_single','direct_vs_frontend_parallel','independent_accuracy'}

def decode(line):
    family,kind,*tokens=line.strip().split(',')
    require(family in ('YOLO32_FRONTEND','ATSOFT1'),'invalid diagnostic family')
    row={}
    for token in tokens:
        k,sep,v=token.partition('=')
        require(sep and k and v and k not in row,'invalid/duplicate field '+token)
        if k in TEXT:row[k]=v
        else:
            require(v.isdecimal() and int(v)<2**64,'invalid integer '+token)
            row[k]=int(v)
    return family,kind,row

def encode(family,kind,row):
    return family+','+kind+','+','.join(f'{k}={v}' for k,v in row.items())

def validate_boundaries(session,rows):
    require(len(rows)==468,'missing/extra boundary records')
    by={};plans={};derived=[]
    for row in rows:
        require(set(row)==BOUNDARY,'boundary schema differs')
        key=(row['executor'],row['frame'],row['tag'])
        require(key not in by,'duplicate boundary')
        by[key]=row
    for mode in session['modes']:
        name=mode['summary']['executor'];costs=defaultdict(int);groups=defaultdict(list)
        for f in mode['frames']:
            previous=f['begin_cycles'];raw=barriers=pad=head=0
            for tag in range(1,14):
                row=by.get((name,f['frame'],tag));require(row is not None,'missing boundary')
                require(row['device']==f['device'] and row['image']==f['image'],'boundary frame binding differs')
                require(row['start_cycles']==previous,'boundary intervals do not join')
                seen=row['seen_cycles'];lo=row['ready_lo_cycles'];pending=row['pending_cycles']
                require(0<lo<=seen and previous<=seen<=f['graph_done_cycles'],'invalid boundary observation')
                signature=tuple(row[k] for k in ('phase','kind','raw','barriers'))
                if tag in plans:require(plans[tag]==signature,'model boundary plan differs')
                else:plans[tag]=signature
                raw+=row['raw'];barriers+=row['barriers']
                if tag==1:
                    require(f['begin_cycles']<=row['launch_begin_cycles']<=row['launch_end_cycles']<=seen,'invalid launch timestamps')
                else:require(not row['launch_begin_cycles'] and not row['launch_end_cycles'],'extra launch timestamps')
                require(row['samples']==sum(row[k] for k in ('run','drain','host','done','other','transition')),'sample partition differs')
                require(0<=row['run_idle_empty']<=row['run_empty']<=row['run'] and
                        row['drain_busy']+row['drain_idle']==row['drain'] and
                        row['drain_barrier']+row['drain_host']+row['drain_finish']==row['drain'],'invalid sample subcounts')
                require(row['cursor_max']<=10870 and row['fetched_max']<=10870 and row['issued_max']<=10478,'invalid sampled cursors')
                require(row['cursor_hold_min_cycles']<=f['graph_done_cycles']-previous,'invalid cursor hold window')
                if name=='direct_serial':
                    require(not pending and not row['irq_hint_cycles'] and not row['samples'] and not row['probe_query_cycles'],'direct path has autonomous events')
                    require(row['direct_fence_calls']>0 and row['direct_fence_cycles']>0,'missing direct fence accounting')
                else:
                    require(pending>0 and pending<=f['graph_done_cycles'],'missing pending observation')
                    require(not row['direct_fence_calls'] and not row['direct_fence_cycles'],'frontend executes CPU fences')
                if row['irq_hint_cycles']:require(lo<=row['irq_hint_cycles']<=pending,'invalid shared IRQ hint')
                if tag<13:
                    a,b,c,d=[row[k] for k in ('cpu_begin_cycles','cpu_end_cycles','resume_begin_cycles','resume_end_cycles')]
                    require(seen<=a<b<=c<d<=f['graph_done_cycles'],'invalid HOST service/resume timestamps')
                    require(not pending or pending<=a,'pending observed after service')
                    require(row['kind'] in (1,2) and row['phase']<165,'invalid HOST kind/stage')
                    if tag>1:require(row['phase']>=plans[tag-1][0],'stage order regresses')
                    pad+=row['kind']==1;head+=row['kind']==2
                    costs['graph_to_seen_cycles']+=seen-previous
                    costs['observed_queue_cycles']+=a-seen
                    costs['cpu_service_cycles']+=b-a
                    costs['post_service_cycles']+=c-b
                    costs['resume_call_cycles']+=d-c
                    if name!='direct_serial':
                        costs['host_wait_lower_cycles']+=c-seen
                        costs['host_wait_upper_cycles']+=d-lo
                    previous=d
                    value=dict(row,span_to_seen_cycles=seen-row['start_cycles'],
                               observed_queue_cycles=a-seen,cpu_service_cycles=b-a,
                               post_service_cycles=c-b,resume_call_cycles=d-c)
                else:
                    require(row['kind']==0 and row['phase']==165 and
                            not any(row[k] for k in ('cpu_begin_cycles','cpu_end_cycles','resume_begin_cycles','resume_end_cycles')),'invalid graph tail')
                    costs['tail_cycles']+=f['graph_done_cycles']-previous
                    previous=f['graph_done_cycles']
                    value=dict(row,span_to_seen_cycles=seen-row['start_cycles'])
                for k in ('samples','run','drain','host','done','other','transition','run_empty','run_idle_empty','drain_busy','drain_idle','probe_query_cycles','direct_fence_calls','direct_fence_cycles'):
                    costs[k]+=row[k]
                groups[(row['device'],row['image'],tag)].append(value)
            require(raw==10478 and barriers==380 and pad==head==6,'incomplete per-frame native work')
        expected=sum(f['graph_done_cycles']-f['begin_cycles'] for f in mode['frames'])
        require(sum(costs[k] for k in ('graph_to_seen_cycles','observed_queue_cycles','cpu_service_cycles','post_service_cycles','resume_call_cycles','tail_cycles'))==expected,'graph-time partition differs')
        require(costs['cpu_service_cycles']==mode['summary']['host_service_cycles'],'HOST summary does not match boundary timers')
        derived.append(dict(executor=name,totals=dict(costs),groups=[dict(device=d,image=i,tag=t,samples=len(values),
            phase=values[0]['phase'],kind=values[0]['kind'],
            mean_span_to_seen_cycles=mean(v['span_to_seen_cycles'] for v in values),
            mean_observed_queue_cycles=mean(v.get('observed_queue_cycles',0) for v in values),
            mean_cpu_service_cycles=mean(v.get('cpu_service_cycles',0) for v in values),
            mean_resume_call_cycles=mean(v.get('resume_call_cycles',0) for v in values),
            state_samples={k:sum(v[k] for v in values) for k in ('samples','run','drain','host','run_idle_empty','drain_idle')})
            for (d,i,t),values in sorted(groups.items())]))
    s={(x['device'],x['image'],x['tag']):x for x in derived[1]['groups']}
    changes=[]
    for p in derived[2]['groups']:
        key=(p['device'],p['image'],p['tag'])
        if key in s:
            a=s[key];changes.append(dict(device=key[0],image=key[1],tag=key[2],phase=p['phase'],
                serial_count=a['samples'],parallel_count=p['samples'],
                serial_mean_cycles=a['mean_span_to_seen_cycles'],parallel_mean_cycles=p['mean_span_to_seen_cycles'],
                increase_cycles=p['mean_span_to_seen_cycles']-a['mean_span_to_seen_cycles']))
    return dict(modes=derived,matched_interval_changes=sorted(changes,key=lambda x:x['increase_cycles'],reverse=True))

def window_metrics(window, four_banks=False, tensor=False):
    blocks=window['blocks'];result={}
    result['clients']=[]
    for b in (list(range(5))+([13] if tensor else [])):
        c=blocks[b]
        result['clients'].append(dict(block=b,enabled_cycles=c['c00'],requests=c['c01'],
            read_requests=c['c02'],write_requests=c['c03'],read_request_bytes=c['c04'],
            accepted_a_data_bytes=c['c05'],a_stall_bank_cycles=c['c06'],accepted_d_data_bytes=c['c07'],
            d_stall_bank_cycles=c['c08'],accepted_c_beats=c['c09'],c_stall_bank_cycles=c['c10'],
            bank0_requests=c['c11'],bank1_requests=c['c12'],completed_d_messages=c['c13']))
        if four_banks:
            result['clients'][-1].update(bank2_requests=c['c14'],bank3_requests=c['c15'])
    for b in ((5,6,14,15) if four_banks else (5,6)):
        c=blocks[b];n=c['c00']
        result[f'l2_bank{b-5 if b<7 else b-12}']=dict(enabled_cycles=n,requests=c['c01'],
            accepted_d_beats=c['c02'],d_stall_cycles=c['c03'],directory_lookups=c['c04'],
            directory_hits=c['c05'],directory_misses=c['c06'],mshr_average=c['c07']/n if n else None,
            coherence_mshr_average=c['c08']/n if n else None,mshr_peak=c['c11'],mshr_full_cycles=c['c09'],
            scheduler_stall_cycles=c['c10'],secondary_queue_enqueues=c['c12'],secondary_queue_stall_cycles=c['c13'],
            refill_bytes=c['c14'],writeback_bytes=c['c15'],outer_a_stall_cycles=c['c16'],
            outer_d_stall_cycles=c['c17'],inner_a_stall_cycles=c['c18'],both_banks_d_accept_cycles=c['c19'])
        if four_banks:
            result[f'l2_bank{b-5 if b<7 else b-12}'].update(
                at_least_two_banks_d_accept_cycles=c['c20'],
                at_least_three_banks_d_accept_cycles=c['c21'],four_banks_d_accept_cycles=c['c22'])
    for b,name in ((7,'before_head'),(8,'ddr_s00'),(9,'mig'),(10,'video'),(11,'idle_s02')):
        c=blocks[b];n=c['c00']
        result[name]=dict(enabled_cycles=n,clock_hz=c['clock_hz'],read_request_bytes=c['c06'],write_data_bytes=c['c07'],
            ar_accepts=c['c01'],aw_accepts=c['c02'],r_beats=c['c03'],w_beats=c['c04'],b_accepts=c['c05'],
            ar_stall_cycles=c['c08'],aw_stall_cycles=c['c09'],r_stall_cycles=c['c10'],w_stall_cycles=c['c11'],b_stall_cycles=c['c12'],
            read_inflight_average=c['c13']/n if n else None,read_inflight_peak=c['c15'],
            write_inflight_average=c['c14']/n if n else None,write_inflight_peak=c['c16'],
            accepted_rlasts=c['c17'],occupied_r_bus_bytes=c['c18'],r_handshake_density=c['c03']/n if n else None)
    c=blocks[12]
    result['head']=dict(enabled_cycles=c['c00'],head_aw=c['c01'],head_ar=c['c02'],ddr_read_drain_cycles=c['c04'],
        ddr_write_drain_cycles=c['c03'],local_read_requests=c['c05'],local_read_responses=c['c06'],
        local_request_stall_cycles=c['c08'],local_response_stall_cycles=c['c07'])
    return result

def validate_memory(device,mapping,windows,pairs,gems,session):
    require(device is not None and set(device)==DEVICE,'missing/invalid memory device record')
    require(device['available'] in (0,1) and device['probe_fault'] in (0,1) and device['base']==0x02020000 and
            device['slots']==32 and device['mapping']=='calibrated_when_available','invalid memory metadata')
    available=device['available']
    if available:
        require(not device['probe_fault'] and device['status']&8 and not device['status']&17 and
            ((device['abi']==0x4d50563300010000 and device['blocks']==13) or
             (device['abi']==0x4d50563300010001 and device['blocks'] in (14,16)) or
             (device['abi']==0x4d50563300010002 and device['blocks']==16)) and
            device['soc_hz']==100000000 and device['ddr_hz']==300000000,'unsupported memory ABI')
        require(mapping is not None and set(mapping)=={'valid','lane0','lane1','lane2'} and mapping['valid'] in (0,1),'missing client mapping')
        if mapping['valid']:require(sorted(mapping[f'lane{d}'] for d in range(3))==[0,1,2],'invalid client permutation')
        expected=[(0,0,d,'direct_serial') for d in range(3)]+[(1,0,0,n) for n in MODES]
        expected += [(2,(tag-1)*2+mode,tag,MODES[mode]) for tag in range(1,14) for mode in (1,2)]
        require(len(windows)==len(expected) and len(pairs)==26,'missing/extra memory windows or pairs')
        for index,(w,key) in enumerate(zip(windows,expected),1):
            r=w['summary'];require(set(r)==WINDOW,'memory window schema differs')
            require(r['id']==index and (r['kind'],r['pass'],r['target_tag'],r['executor'])==key,'memory window order differs')
            require(r['blocks']==device['blocks'] and r['cpu_span_cycles']>0 and r['batch_cycles']>0 and
                    all(r[k]>0 for k in ('setup_cycles','stop_cycles','snapshot_cycles','read_cycles')),'missing memory window timing')
            require(r['cpu_end_cycles']-r['cpu_begin_cycles']==r['cpu_span_cycles'] and
                all(r[f'{end}_state{d}']<=6 for end in ('start','end') for d in range(3)),'invalid memory context')
            if index>1:require(r['sequence']==(windows[index-2]['summary']['sequence']+1)%2**32,'memory sequence differs')
            require(len(w['blocks'])==device['blocks'],'missing/extra counter blocks')
            for b,c in enumerate(w['blocks']):
                require(set(c)=={'id','block','clock_hz'}|{f'c{i:02d}' for i in range(32)},'counter block schema differs')
                hz=device['ddr_hz'] if 9<=b<=11 else device['soc_hz'] if b<=12 or device['abi']==0x4d50563300010002 or (device['blocks']==14 and b==13) else 0
                require(c['id']==index and c['block']==b and c['clock_hz']==hz and
                        (b>=13 or c['c00']>0),'invalid counter block')
            w['derived']=window_metrics(w, device['abi']==0x4d50563300010002,
                device['abi']==0x4d50563300010002 or device['blocks']==14)
        for i,p in enumerate(pairs,1):
            require(set(p)==PAIR and p['pass']==i and p['target_tag']==(i-1)//2+1 and
                p['executor']==MODES[1+(i-1)%2] and p['target_frame']==p['target_lane']==p['image']==0 and
                p['frames']==3 and p['ppu_results']=='bit_exact','invalid matched memory pair')
            w=windows[5+i]['summary'];require(p['cycles']==w['batch_cycles'],'memory pair batch cycles differ')
    else:require(not windows and not pairs and mapping is None,'unavailable memory reports snapshots')
    keys=set();expected_gems=36+(78 if available else 0)
    require(len(gems)==expected_gems,'missing/extra Gemmini counter records')
    for g in gems:
        require(set(g)==GEM and g['valid'] in (0,1) and g['config_cycles']>0 and g['capture_cycles']>0,'invalid Gemmini counters')
        key=(g['executor'],g['pass'],g['frame']);require(key not in keys,'duplicate Gemmini counters');keys.add(key)
        if not g['pass']:
            require(g['executor'] in MODES and g['frame']<12,'invalid primary Gemmini counter frame')
            f=session['modes'][MODES.index(g['executor'])]['frames'][g['frame']]
            require(g['device']==f['device'] and g['image']==f['image'],'counter frame binding differs')
        else:
            require(available and 1<=g['pass']<=26 and g['frame']<3 and
                g['executor']==MODES[1+(g['pass']-1)%2] and
                g['device']==(g['frame'] if g['pass']%2==0 else 0) and g['image']==g['frame'],'invalid short-pass Gemmini counters')
        require(all(g[k]<2**32 for k in COUNTERS) and g['valid']==int(g['rs_active']>0 and g['exec_active']>0),'invalid counter validity/width')
    grouped=defaultdict(list)
    for g in gems:
        if not g['pass']:grouped[(g['executor'],g['device'],g['image'])].append(g)
    matched=[]
    for (executor,d,image),parallel in grouped.items():
        if executor!='frontend_parallel':continue
        serial=grouped.get(('frontend_serial',d,image),[])
        if not serial:continue
        valid=all(g['valid'] for g in serial+parallel)
        matched.append(dict(device=d,image=image,serial_frames=len(serial),parallel_frames=len(parallel),valid=valid,
            counters={k:dict(serial_mean=mean(g[k] for g in serial),parallel_mean=mean(g[k] for g in parallel),
                increase=mean(g[k] for g in parallel)-mean(g[k] for g in serial)) if valid else None for k in COUNTERS}))
    return dict(device=device,mapping=mapping,windows=windows,pairs=pairs,gemmini=gems,matched_frame_counters=matched)

def parse_one(lines):
    errors=[];legacy=[];rows=[];gems=[];pairs=[];windows=[];device=mapping=complete=current=None;build=None
    primary_done=False
    try:
        for lineno,line in enumerate(lines,1):
            if not line.strip().startswith(('YOLO32_FRONTEND,','ATSOFT1,')):continue
            # Failure records contain textual reasons, not the numeric schema
            # used by measurements. Keep the real firmware reason in errors.
            event=line.strip().split(',')[1]
            if event in ('FAIL','TRAP','DIAG','PPU_DIFF'):
                raise ValueError('firmware failure: '+line.strip())
            family,kind,r=decode(line)
            require(complete is None,'record after diagnostic completion')
            if kind in ('FAIL','TRAP','DIAG'):raise ValueError('firmware failure '+kind)
            if current is not None:require(kind in ('MEM_BLOCK','MEM_END'),'interrupted memory snapshot')
            if kind=='BUILD':
                require(build is None,'duplicate diagnostic build')
                build=r
                require(set(r)==BUILD|{'boundaries_per_frame','sample_period_cycles','state_query'} and
                        r['schema']==2 and r['version']==34 and r['diagnostics']==2 and
                        r['boundaries_per_frame']==13 and r['sample_period_cycles']==100000 and r['state_query']==4,'invalid v34 build')
                normalized={k:v for k,v in r.items() if k in BUILD};normalized.update(schema=1,version=33,diagnostics=1)
                legacy.append(encode('YOLO32_FRONTEND','BUILD',normalized))
            elif kind in ('FRAME_END','MODE','PERF','PASS'):
                require(build is not None and not primary_done,'primary record outside comparison')
                if kind=='MODE':
                    require(r.get('diagnostics')==2,'mode is not boundary diagnostics');r=dict(r,diagnostics=1)
                legacy.append(encode(family,kind,r));primary_done=kind=='PASS'
            elif kind=='BOUNDARY':rows.append(r)
            elif kind=='GEM_COUNTER':gems.append(r)
            elif kind=='MEM_PAIR':
                require(primary_done,'short window precedes primary PASS');pairs.append(r)
            elif kind=='MEM_DEVICE':require(device is None,'duplicate memory device');device=r
            elif kind=='MEM_MAPPING':require(mapping is None,'duplicate client mapping');mapping=r
            elif kind=='MEM_WINDOW':
                require(current is None,'nested snapshot');current=dict(summary=r,blocks=[])
            elif kind=='MEM_BLOCK':
                require(current is not None,'counter block outside snapshot');current['blocks'].append(r)
            elif kind=='MEM_END':
                require(current is not None and r==dict(id=current['summary']['id'],valid=1),'invalid snapshot end')
                windows.append(current);current=None
            elif kind=='DIAG_COMPLETE':complete=r
            else:raise ValueError('unknown diagnostic record '+kind)
        require(current is None,'truncated memory snapshot')
        require(complete is not None and set(complete)==COMPLETE and complete['version']==34 and
                complete['boundary_records']==468 and complete['marker']=='ALL_DIAGNOSTICS_COMPLETE','missing/invalid final diagnostic marker')
        base_errors,sessions=base_parse('\n'.join(legacy))
        require(not base_errors,'; '.join(base_errors));require(len(sessions)==1,'invalid primary session')
        session=sessions[0]
        session['boundary']=dict(rows=rows,derived=validate_boundaries(session,rows))
        session['memory']=validate_memory(device,mapping,windows,pairs,gems,session)
        require(complete['memory_available']==device['available'] and complete['short_window_pairs']==(13 if device['available'] else 0),'diagnostic coverage differs')
        session['build']=build
        for m in session['modes']:m['summary']['diagnostics']=2
        session['diagnostic_complete']=True
        return [],session
    except (ValueError,KeyError,IndexError,TypeError) as e:
        errors.append(f'v34 line {locals().get("lineno",0)}: {e}')
        return errors,None

def parse_boundary(text,latest=False):
    lines=text.splitlines();boots=[i for i,l in enumerate(lines) if l.strip().startswith('YOLO32_FRONTEND,BUILD,')]
    if not boots:return ['no frontend build record'],[]
    if latest:boots=boots[-1:]
    errors=[];sessions=[]
    if not latest and any(l.strip().startswith('ATSOFT1,') for l in lines[:boots[0]]):
        errors.append('diagnostic record before first build')
    for j,start in enumerate(boots):
        end=boots[j+1] if j+1<len(boots) else len(lines);part=lines[start:end]
        if 'schema=2,version=34,' in part[0]:es,s=parse_one(part);ss=[s] if s else []
        else:es,ss=base_parse('\n'.join(part))
        errors.extend(es);sessions.extend(ss)
    return errors,sessions

def boundary_report(session):
    lines=['v34 分段诊断：计时为软件观察，状态为稀疏采样。']
    for mode in session['boundary']['derived']['modes']:
        t=mode['totals']
        lines.append(f"  {mode['executor']}: HOST确认后排队={t['observed_queue_cycles']:,}，CPU回调={t['cpu_service_cycles']:,}，回调后准备={t['post_service_cycles']:,}，恢复调用={t['resume_call_cycles']:,}。")
        if mode['executor']!='direct_serial':
            lines.append(f"    HOST真实停顿的逐事件累加观测范围=[{t['host_wait_lower_cycles']:,},{t['host_wait_upper_cycles']:,}]；并行事件可重叠，不能当作整组可节省周期。")
            lines.append(f"    样本={t['samples']}，RUN/DRAIN/HOST={t['run']}/{t['drain']}/{t['host']}，RUN且FIFO空且Gemmini不busy候选={t['run_idle_empty']}，DRAIN且Gemmini不busy候选={t['drain_idle']}，查询调用累计={t['probe_query_cycles']:,}。")
    lines.append('  同一device、同一图片的分段延长前五项：')
    for c in session['boundary']['derived']['matched_interval_changes'][:5]:
        lines.append(f"    device={c['device']} image={c['image']} tag={c['tag']} stage={c['phase']}：单路均值={c['serial_mean_cycles']:,.2f}，三路均值={c['parallel_mean_cycles']:,.2f}，增加={c['increase_cycles']:,.2f}；样本={c['serial_count']}/{c['parallel_count']}。")
    memory=session['memory'];device=memory['device']
    if not device['available']:
        lines.append(f"  MPV3不可用：ABI={device['abi']:#018x}，blocks={device['blocks']}，status={device['status']}，probe_fault={device['probe_fault']}；访存链路数据缺失，不能按零等待解释。")
    else:
        lines.append(f"  MPV3完整快照={len(memory['windows'])}，每份{device['blocks']}块×32槽；包含3次映射校准、3次整组窗口和13对分段窗口。")
        lines.append(f"  客户端映射有效={memory['mapping']['valid']}；lane0/1/2={memory['mapping']['lane0']}/{memory['mapping']['lane1']}/{memory['mapping']['lane2']}。")
        lines.append('  同图025、lane0分段窗口：CPU跨度；Head DDR读排空；各L2 bank MSHR全满（单路 -> 三路）。')
        ws=[w for w in memory['windows'] if w['summary']['kind']==2]
        phases={r['tag']:r['phase'] for r in session['boundary']['rows'] if r['executor']=='frontend_serial' and r['frame']==0}
        for a,b in zip(ws[::2],ws[1::2]):
            x,y=a['derived'],b['derived']
            tag=a['summary']['target_tag']
            banks=range(4 if device['abi']==0x4d50563300010002 else 2)
            mshr=lambda values:'/'.join(f"{values[f'l2_bank{i}']['mshr_full_cycles']:,}" for i in banks)
            lines.append(f"    tag={tag} stage_end={phases[tag]}: span {a['summary']['cpu_span_cycles']:,}->{b['summary']['cpu_span_cycles']:,}；Head {x['head']['ddr_read_drain_cycles']:,}->{y['head']['ddr_read_drain_cycles']:,}；MSHR {mshr(x)}->{mshr(y)}。")
    invalid=sum(not g['valid'] for g in memory['gemmini'])
    lines.append(f"  Gemmini六项计数记录={len(memory['gemmini'])}，无效={invalid}；在通道未被前端持有时配置和读取。")
    for matched in memory['matched_frame_counters']:
        lines.append(f"    同图逐帧事件对照 device={matched['device']} image={matched['image']}，有效={matched['valid']}，单路/三路样本={matched['serial_frames']}/{matched['parallel_frames']}：")
        if matched['valid']:
            for k,v in matched['counters'].items():
                lines.append(f"      {k}: {v['serial_mean']:,.2f}->{v['parallel_mean']:,.2f}，增量={v['increase']:+,.2f}。")
    lines.append('  MPV3原始所有槽及L2/AXI/MIG/Head派生量保存在JSON；未知扩展块保留原始值。')
    lines.append('  100/300 MHz域的周期分别解释；R握手密度不是DDR带宽利用率。分段启停、采样与诊断指令会扰动执行，吞吐成绩沿用正式版。')
    return lines
