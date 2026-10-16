#!/usr/bin/env python3
"""ELF-bound SW-P3 layout search and fail-closed structural audit.

The objective is an active-window distinct-tag pressure proxy, never cycles.
All DDR objects here use the executable's cached CPU/L2 addresses unchanged;
fixed Head routing is excluded. No global bit31 alias conversion is performed.
"""
import argparse
from collections import defaultdict
import json
from itertools import groupby
from functools import lru_cache
import os
from pathlib import Path
import re
import shlex
import subprocess
import numpy as np
from parallel_cache_plan import ROOT,PROJECT,BUFFERS,PERIOD,COLORS,GEOMETRY,sha,save,spans,lines

OUT=Path(os.environ.get('FRONTEND_BUILD',PROJECT/'build/firmware/sw-p3'))
GEN=OUT/'generated'
ELF=OUT/'yolov5_sw_p3_suite_12.elf'
CROSS=os.environ.get('CROSS') or os.environ.get('TOOLCHAIN') or 'riscv64-unknown-elf-'


def nm():
    result={}
    for line in subprocess.check_output([CROSS+'nm','-S',str(ELF)],text=True).splitlines():
        m=re.fullmatch(r'([0-9a-f]+) ([0-9a-f]+) \w (.+)',line)
        if m:result[m[3]]=(int(m[1],16),int(m[2],16))
    return result


def identity():
    frozen=OUT/'native'
    plan=json.loads((GEN/'plan_description.json').read_text())
    ident=dict(reference_plan_sha256=plan['original_plan_hash'],input_sha256=sha((frozen/'inputs.c').read_bytes()),
               model_sha256=sha((frozen/'parallel_model.inc').read_bytes()),
               plan_sha256=plan['candidate_plan_hash'],
               frozen_lock_sha256=sha((PROJECT/'sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json').read_bytes()))
    layout_path=OUT/'layout_manifest.json'
    layout=json.loads(layout_path.read_text()) if layout_path.exists() else {}
    ident['layout_sha256']=sha(dict(parameters_sha256=sha((GEN/'sw_p3_layout_offsets.inc').read_bytes()),views=layout.get('views',[]),actual_symbols=layout.get('scored_symbols',{}),l2_geometry=GEOMETRY.describe()))
    save(GEN/'identity.json',ident)
    payload=','.join(f'{k}={v}' for k,v in ident.items())
    (GEN/'sw_p3_identity.inc').write_text('#define SW_P3_IDENTITY '+json.dumps(payload)+'\n'+
        '#define SW_P3_REFERENCE_PLAN_SHA '+json.dumps(plan['original_plan_hash'])+'\n'+
        '#define SW_P3_CANDIDATE_PLAN_SHA '+json.dumps(plan['candidate_plan_hash'])+'\n')


def encoded(value):
    value=int(value,16) if isinstance(value,str) else value
    if not value:return None
    if value>>63:return ('private',(value>>40)&0xff,value&((1<<40)-1))
    if value>>62:return ('input',0,value&((1<<40)-1))
    if value>>61:return ('constant',(value>>40)&0xff,value&((1<<40)-1))
    raise ValueError('Unnormalized operand')


@lru_cache(maxsize=1)
def constant_names():
    return re.findall(r'\{(\w+),sizeof', (GEN/'constants.inc').read_text())


def actual(ref, lane, image, symbols, offsets=None):
    kind,k,off=ref
    if kind=='private':
        if k==5:return None  # Dedicated Head path; immutable ABI, not scored.
        name,cap=BUFFERS[k];base=symbols[name+'_storage'][0]+64
        if offsets is None:return base+lane*cap+off
        return base+lane*(cap+PERIOD+128)+int(offsets[k][lane])+off
    if kind=='input':return symbols['yolo32_inputs'][0]+image*921600+off
    constants=constant_names()
    return symbols[constants[k]][0]+off


def make_windows(inventory,description):
    """Potential traffic of two consecutive packets at several relative lags.

    Record exact line sets per logical arena first, preserving tensor aliases.
    Shared weight/bias physical lines are deduplicated after relocation.
    """
    tables=inventory['tables'];t=next(t for t in tables if t['lane']==0 and t['slot']==0 and t['image']==0)
    windows=[]
    for stage in description['stages']:
        packets=stage['packets'];n=len(packets)
        bases=list(map(encoded,t['bindings'][stage['binding']]))
        for start in sorted({0,n//2,max(0,n-2)}):
            for lag in ((0,0,0),(0,1,2),(0,-1,-2)):
                groups=defaultdict(set)
                for d in range(3):
                    first=max(0,min(n-1,start+lag[d]))
                    for p in packets[first:first+2]:
                        for role,idx in (('input',0),('weight',1),('bias',2),('output',3)):
                            base=bases[idx]
                            if base is None or base[0]=='private' and base[1]==5:continue
                            for off,size in spans(stage['shape'],p,role):
                                kind,k,logical=base
                                if kind=='private':
                                    groups[d,kind,k].update(range((logical+off)//64,(logical+off+size-1)//64+1))
                                else:
                                    groups[d,kind,k].add((logical+off,size))
                windows.append(dict(stage_id=stage['stage_id'],start=start,lag=lag,groups=groups))
    # PAD is followed by native pool traffic on pad/intermediate buffers.
    # Add only the actual tensor extents for these boundaries, not whole arenas.
    for host in t['hosts']:
        kind,phase,_,h,w,c,src,dst=host
        if kind!=1:continue
        groups=defaultdict(set)
        for d in range(3):
            for ptr,n in ((src,h*w*c),(dst,(h+2)*(w+2)*c)):
                ref=encoded(ptr)
                if ref is None:continue
                kind,k,off=ref
                if kind=='private':groups[d,kind,k].update(range(off//64,(off+n-1)//64+1))
                else:groups[d,kind,k].add((off,n))
            groups[d,'private',4].update(range(15*20*128//64))
        windows.append(dict(stage_id=phase,start=0,lag=(0,0,0),groups=groups))
    return windows


def histograms(windows,symbols,offsets=None):
    total=np.zeros((len(windows),COLORS),dtype=np.int32)
    components=np.zeros((5,3,len(windows),COLORS),dtype=np.int32)
    for wi,w in enumerate(windows):
        shared=set()
        for (d,kind,k),logical_lines in w['groups'].items():
            base=actual((kind,k,0),d,d,symbols,offsets)
            if base is None:continue
            physical={base//64+line for line in logical_lines} if kind=='private' else lines(logical_lines,base)
            if kind=='private':
                h=np.bincount([line%COLORS for line in physical],minlength=COLORS)
                components[k,d,wi]=h;total[wi]+=h
            else:shared.update(physical)
        total[wi]+=np.bincount([line%COLORS for line in shared],minlength=COLORS)
    return total,components


def score(hist):
    overflow=np.maximum(hist-8,0).astype(np.int64)
    return (int(np.sum(overflow*overflow)),int(np.max(hist)),int(np.sum(overflow)))


def view_records(symbols,offsets,enabled):
    records=[]
    for k,(name,cap) in enumerate(BUFFERS):
        storage,n=symbols[name+'_storage']
        for lane in range(3):
            baseline=storage+64+lane*cap
            candidate=storage+64+lane*(cap+PERIOD+128)+int(offsets[k][lane]) if enabled else baseline
            assert storage%PERIOD==0 and baseline%64==candidate%64==0
            assert storage<=candidate-64 and candidate+cap+64<=storage+n
            records.append(dict(arena_class=name,lane=lane,logical_capacity=cap,storage_base=storage,storage_bytes=n,
                reference_base=baseline,candidate_base=candidate,padding=int(offsets[k][lane]) if enabled else 0,
                reference_bank=GEOMETRY.bank(baseline),candidate_bank=GEOMETRY.bank(candidate),
                reference_set=GEOMETRY.set_index(baseline),
                candidate_set=GEOMETRY.set_index(candidate)))
    for key in ('reference_base','candidate_base'):
        for i,a in enumerate(records):
            for b in records[i+1:]:
                assert not (a[key]<b[key]+b['logical_capacity'] and b[key]<a[key]+a['logical_capacity'])
    return records


def search():
    symbols=nm();inventory=json.loads((OUT/'reference_plan.txt.inventory.json').read_text())
    description=json.loads((GEN/'plan_description.json').read_text())
    windows=make_windows(inventory,description)
    reference,reference_parts=histograms(windows,symbols)
    offsets=np.zeros((5,3),dtype=np.int64)
    for k,(_,cap) in enumerate(BUFFERS):
        for d in range(3):offsets[k,d]=(-d*(PERIOD+128))%PERIOD
    total,parts=histograms(windows,symbols,offsets)
    assert np.array_equal(reference,total),'Reference colors must be a mandatory search seed'
    # Bounded deterministic coordinate descent, every 64B residue in the generated bank/set
    # period. Optimize all windows, process residues in chunks to bound memory.
    trace=[]
    for iteration in range(2 if os.environ.get('SW_P3_MODE','reference')=='compare' else 0):
        changed=False
        for k in range(5):
            for d in range(3):
                component=parts[k,d]
                if not component.any():continue
                active=component.any(axis=1)
                rest=total-component;small=component[active];small_rest=rest[active]
                outside=score(total[~active]) if (~active).any() else (0,0,0)
                best=score(total);best_delta=0
                for delta in range(1,COLORS):
                    local=score(small_rest+np.roll(small,delta,axis=1))
                    s=(local[0]+outside[0],max(local[1],outside[1]),local[2]+outside[2])
                    if s<best:best=s;best_delta=delta
                if best_delta:
                    total=rest+np.roll(component,best_delta,axis=1)
                    parts[k,d]=np.roll(component,best_delta,axis=1)
                    offsets[k,d]=(offsets[k,d]+64*best_delta)%PERIOD
                    trace.append(dict(iteration=iteration,buffer=k,lane=d,offset=int(offsets[k,d]),score=best))
                    changed=True
        if not changed:break
    enabled=score(total)<score(reference)
    if not enabled:offsets[:]=0;total=reference
    text='static const volatile unsigned sw_p3_offsets[5][3] = {'+','.join('{'+','.join(map(str,row))+'}' for row in offsets)+'};\n'
    text+=f'static const volatile unsigned sw_p3_layout_enabled={int(enabled)};\n'
    (GEN/'sw_p3_layout_offsets.inc').write_text(text)
    report=dict(schema=1,status='ENABLED' if enabled else 'NO_BETTER_LAYOUT',seed='reference_colors',l2_geometry=GEOMETRY.describe(),
        address_space='ELF cached CPU/L2 addresses, unchanged; dedicated Head excluded',
        metric='distinct active-window tags per bank/set; squared overflow beyond 8 ways; not cycles',
        scored_symbols={k:list(v) for k,v in symbols.items() if k in ['yolo32_inputs']+[n+'_storage' for n,_ in BUFFERS]+constant_names()},
        window_packets=2,lane_lags=[[0,0,0],[0,1,2],[0,-1,-2]],
        baseline_score=score(reference),candidate_score=score(total),trace=trace,
        offsets=offsets.tolist(),views=view_records(symbols,offsets,enabled),
        extra_storage_bytes=sum(3*(PERIOD+128) for _ in BUFFERS),
        storage_span_gap_bytes=max(symbols[n+'_storage'][0]+symbols[n+'_storage'][1] for n,_ in BUFFERS)-min(symbols[n+'_storage'][0] for n,_ in BUFFERS)-sum(symbols[n+'_storage'][1] for n,_ in BUFFERS),
        per_lane_reference_scores=[score(reference-reference_parts.sum(axis=(0,1))+reference_parts[:,d].sum(axis=0)) for d in range(3)],
        per_lane_candidate_scores=[score(total-parts.sum(axis=(0,1))+parts[:,d].sum(axis=0)) for d in range(3)] if enabled else [score(reference-reference_parts.sum(axis=(0,1))+reference_parts[:,d].sum(axis=0)) for d in range(3)],
        windows=[dict(stage_id=w['stage_id'],start=w['start'],lag=w['lag'],
                      reference_score=score(reference[i:i+1]),candidate_score=score(total[i:i+1]),
                      reference_banks=[int(reference[i,[(j>>6)&(GEOMETRY.banks-1)==b for j in range(COLORS)]].sum()) for b in range(GEOMETRY.banks)],
                      candidate_banks=[int(total[i,[(j>>6)&(GEOMETRY.banks-1)==b for j in range(COLORS)]].sum()) for b in range(GEOMETRY.banks)]) for i,w in enumerate(windows)],
        elf_sha256=None,board_performance='NOT_MEASURED')
    save(OUT/'layout_manifest.json',report)
    print('SW_P3_LAYOUT='+report['status']+' score='+str(report['candidate_score']))


def audit(record=False,offline=False):
    if not record:
        saved=json.loads((OUT/'sw_p3_manifest.json').read_text())
        assert saved.get('hardware_binding')=='PASS','Hardware export binding is BLOCKED; rebuild against a complete export before download'
        for filename,digest in saved['files'].items():
            assert sha((PROJECT/filename).read_bytes())==digest,'Stale/tampered artifact: '+filename
        for filename,digest in saved['hardware_files'].items():
            assert sha((PROJECT/filename).read_bytes())==digest,'Hardware provenance changed: '+filename
    symbols=nm();assert symbols['output'][1]==3*12*164,'Three complete PPU result arrays are required'
    layout=json.loads((OUT/'layout_manifest.json').read_text())
    assert layout.get('l2_geometry')==GEOMETRY.describe(),'Layout was generated for a different L2 geometry; rebuild SW-P3'
    offsets=np.array(layout['offsets']);records=view_records(symbols,offsets,layout['status']=='ENABLED')
    assert records==layout['views'],'Relink changed scored storage addresses'
    assert all(list(symbols[k])==v for k,v in layout['scored_symbols'].items()),'Relink moved scored readonly objects'
    a=json.loads((OUT/'reference_plan.txt.inventory.json').read_text())
    b=json.loads((OUT/'layout_plan.txt.inventory.json').read_text())
    assert len(a['tables'])==len(b['tables'])==18
    assert a['tables']==b['tables'],'S1 commands/HOST/aliases differ after normalization'
    assert (OUT/'reference_plan.txt').read_bytes()==(OUT/'layout_plan.txt').read_bytes()
    # Compare with the independent frozen V33 oracle, without relaxing its checks.
    baseline=PROJECT/'build/firmware/frontend/native_plan.txt'
    if not baseline.exists():raise ValueError('Run make test-v33 before SW-P3 audit')
    assert baseline.read_bytes()==(OUT/'reference_plan.txt').read_bytes(),'V33 semantic baseline mismatch'
    dis=subprocess.check_output([CROSS+'objdump','-d',str(ELF)],text=True)
    header=subprocess.check_output([CROSS+'readelf','-hW',str(ELF)],text=True)
    assert '0x82000000' in header
    routes=defaultdict(set)
    for word in re.findall(r'^\s*[0-9a-f]+:\s+([0-9a-f]{8})\s',dis,re.M):
        value=int(word,16);op=value&127
        if op in (0x0b,0x2b,0x5b,0x7b):routes[op].add(value>>25)
        if op==0x73:assert not 0x7c0<=value>>20<=0x7cf,'Old scheduling CSR'
    assert routes[0x0b]==set(range(22))|{26}
    assert not routes[0x2b] and not routes[0x5b]
    assert routes[0x7b] == {lane*32+op for lane in range(3) for op in range(6)}|{99}
    for line in subprocess.check_output([CROSS+'readelf','-lW',str(ELF)],text=True).splitlines():
        if line.strip().startswith('LOAD '):
            f=line.split();addr=int(f[3],16);n=int(f[5],16)
            assert 0x82000000<=addr and addr+n<=0xa0000000
    strings=subprocess.check_output([CROSS+'strings',str(ELF)],text=True)
    build_mode=os.environ.get('SW_P3_MODE','reference')
    assert 'SWP3,MODE,build='+build_mode in strings,'ELF build mode differs from requested mode'
    identity_line=next(line for line in (GEN/'sw_p3_identity.inc').read_text().splitlines() if line.startswith('#define SW_P3_IDENTITY '))
    assert json.loads(identity_line.split(' ',2)[2]) in strings,'ELF input/model/plan/layout identity is stale'
    for marker in ('SWP3,BUILD,schema=1','SWP3,PASS,schema=1','memory_pad_input','ai_ppu_publication_publish'):
        assert marker in strings
    lock=json.loads((PROJECT/'sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json').read_text())
    for item in lock['sources']:
        assert sha((PROJECT/item['path']).read_bytes())==item['sha256']
        assert sha((OUT/'native'/item['snapshot']).read_bytes())==item['sha256']
    layout['elf_sha256']=sha(ELF.read_bytes())
    if record:save(OUT/'layout_manifest.json',layout)
    product=json.loads((PROJECT/'hw/manifests/current.json').read_text())
    if record:export_inventory(a,symbols)
    sources=[p for folder in ('src','include','scripts') for p in (ROOT/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
    sources+=[ROOT/'sw-p3.mk',ROOT/'Makefile',ROOT/'download-sw-p3.sh',PROJECT/'Makefile']
    sources += [PROJECT/name for name in ('sw/models/yolov5nu/codegen/fixed_packets.py','sw/models/yolov5nu/codegen/fixed_plans.py','sw/third_party/gemmini/include/gemmini_float16.h','tools/soc/l2_geometry.py')]
    sources += list((GEN/'include').glob('*.h'))
    sources += list((GEN).glob('*.inc'))+list(GEN.glob('*.c'))+list(GEN.glob('*.json'))
    artifacts=[ELF,ELF.with_suffix('.map'),ELF.with_suffix('.dis'),PROJECT/'build/firmware/frontend/yolov5_three_way_12.elf']
    artifacts+=[OUT/'plan_inventory.json',OUT/'layout_manifest.json',OUT/'reference_plan.txt',OUT/'layout_plan.txt',OUT/'cache_plan.txt']
    if (OUT/'tiling_numerical_evidence.json').exists():artifacts.append(OUT/'tiling_numerical_evidence.json')
    compiler=subprocess.check_output([CROSS+'gcc','--version'],text=True).splitlines()[0]
    hardware_paths=['hw/manifests/current.json',product['generation_context']]+product['parameter_headers']
    missing=[name for name in hardware_paths if not (PROJECT/name).is_file()]
    if missing and not offline:
        raise ValueError('Incomplete current hardware export: '+', '.join(missing))
    host_compiler=subprocess.check_output(shlex.split(os.environ.get('HOST_CC','cc'))+['--version'],text=True).splitlines()[0]
    manifest=dict(host_compiler=host_compiler,host_check_optimization=os.environ.get('SW_P3_HOST_CHECK_OPT','-O2'),hardware_binding='BLOCKED' if missing else 'PASS',missing_hardware_files=missing,
         abi_source='cached V33-compatible generated headers' if missing else 'current product headers',schema=1,firmware='SW-P3',compiler=compiler,default_profile='reference',build_mode=os.environ.get('SW_P3_MODE','reference'),profiles=['reference','layout','cache_plan','cache_plan_gate'] if os.environ.get('SW_P3_MODE','reference')=='compare' else ['reference'],
         tiling_changed_stages=json.loads((GEN/'tiling_manifest.json').read_text())['enabled_changed_stages'],gate_default='OFF',hardware_abi_changed=False,model_changed=False,
         hardware_identity='download manifest declaration; no on-board fingerprint',soc_config=product['soc_config'],
         hardware_files={p:sha((PROJECT/p).read_bytes()) for p in hardware_paths if (PROJECT/p).is_file()},
         files={str(p.relative_to(PROJECT)):sha(p.read_bytes()) for p in sorted(set(sources+artifacts+list((PROJECT/'tests/model/frontend_parallel_cache').glob('*.py'))))},
         structural='STRUCTURAL_PASS',numerical=json.loads((GEN/'tiling_manifest.json').read_text())['numerical_validation'],
         board_performance='NOT_MEASURED')
    verify_tiling_contract(a)
    if record:
        save(OUT/'sw_p3_manifest.json',manifest)
        save(OUT/'tiling_manifest.json',json.loads((GEN/'tiling_manifest.json').read_text()))
    print('SW_P3_STRUCTURAL=PASS tables=18 V33_normalized=identical HARDWARE_BINDING='+manifest['hardware_binding']+' ELF='+layout['elf_sha256'])




def export_inventory(reference,symbols):
    description=json.loads((GEN/'plan_description.json').read_text())
    table=reference['tables'][0];ordinary={s['stage_id']:s for s in description['stages']}
    memory={s['stage']:s for s in json.loads((OUT/'native/memory_kernels.json').read_text())['stages']}
    splitk=json.loads((OUT/'native/fixed_plans.json').read_text())['splitk']
    result=[]
    for phase in range(166):
        commands=[c for c in table['commands'] if c[0]==phase]
        raw=[c for c in commands if int(c[1],16)&255==0]
        hosts=[h for h in table['hosts'] if h[1]==phase]
        stage=ordinary.get(phase)
        kind='ordinary_conv' if stage else memory[phase]['kind'] if phase in memory else 'ws' if any(int(c[1],16)>>8==8 for c in raw) else 'control_or_alias'
        ranges=[]
        if stage:
            bindings=table['bindings'][stage['binding']]
            for role,idx in [('input',0),('weight',1),('bias',2),('output',3)]:
                ref=encoded(bindings[idx]);segments=[r for packet in stage['packets'] for r in spans(stage['shape'],packet,role)]
                if not segments:continue
                low=min(o for o,n in segments);high=max(o+n for o,n in segments)
                base=actual(ref,0,0,symbols)
                ranges.append(dict(role=role,access='write' if role=='output' else 'read',logical_tensor_id=stage['logical_tensor_id'].get('weights' if role=='weight' else role),
                    arena_class=ref[0],arena_index=ref[1],logical_offset=ref[2]+low,logical_bytes=high-low,
                    address=None if base is None else base+low,range_kind='bounding interval of exact strided packet spans'))
        result.append(dict(stage_id=phase,op_kind=kind,shape=stage['shape'] if stage else memory.get(phase,splitk.get(str(phase),{})),
            physical_stride=stage['physical_stride'] if stage else [c[2:4] for c in raw if int(c[1],16)>>8 in (12,13)],
            packet_count=sum(int(c[1],16)>>8 in (8,15) for c in raw),raw_count=len(raw),
            drain_count=sum(int(c[1],16)&255==1 for c in commands),hosts=hosts,read_write_ranges=ranges,
            spad_acc=({k:stage[k] for k in ('spad_rows','acc_rows')} if stage else splitk.get(str(phase))),
            native_commands=commands,original_plan_hash=stage['original_plan_hash'] if stage else sha(commands),
            candidate_plan_hash=stage['candidate_plan_hash'] if stage else sha(commands)))
    save(OUT/'plan_inventory.json',dict(schema=1,source='captured frozen-reference plan, symbols from final suite ELF',
        stages=result,tensor_alias_offsets=description['tensor_alias_offsets'],alignment=64,
        shared_weights=True,head_fixed=True,all18_tables_normalized_identical=True))


def verify_tiling_contract(reference):
    candidate=json.loads((OUT/'cache_plan.txt.inventory.json').read_text())
    report=json.loads((GEN/'tiling_manifest.json').read_text())
    description=json.loads((GEN/'plan_description.json').read_text())
    packed=json.loads((GEN/'candidate_packets.json').read_text())
    changed=report['enabled_changed_stages']
    assert len(changed)<=6
    assert len(candidate['tables'])==18
    for before,after in zip(reference['tables'],candidate['tables']):
        assert before['hosts']==after['hosts'] and before['bindings']==after['bindings']
        expected=[]
        for phase,group in groupby(before['commands'],key=lambda c:c[0]):
            commands=list(group)
            if phase not in changed:
                expected+=commands;continue
            stage=next(s for s in description['stages'] if s['stage_id']==phase)
            choice=next(s for s in report['stages'] if s['stage_id']==phase)
            tile=next(c for c in choice['candidates'] if c['status']=='SELECTED_FUNCTIONAL_PASS')
            plan=packed[f'{phase}:{tile["candidate_id"]}']
            # Independent full-coordinate proof is reused by offline contracts.
            import sys
            sys.path.insert(0,str(PROJECT/'tests/model/frontend_parallel_cache'))
            from run_tests import check_packet_coverage
            check_packet_coverage(stage['shape'],tile['tile'],plan)
            assert plan['config']==stage['config']
            starts=[i for i,c in enumerate(commands) if int(c[1],16)==(16<<8)]
            ends=[i for i,c in enumerate(commands) if int(c[1],16)==(15<<8)]
            assert starts and ends
            expected+=commands[:starts[0]]
            bases=[int(v,16) for v in before['bindings'][stage['binding']]]
            address=lambda b,o:0 if o==0xffffffff else b+o
            for packet in plan['tiles']:
                values=[(16,*plan['config'][4:6])]
                values += [(17+i,*packet['geometry'][i*2:i*2+2]) for i in range(3)]
                offsets=packet['offsets']
                values += [(20,address(bases[1],offsets[0]),address(bases[3],offsets[1])),
                           (21,address(bases[2],offsets[2]),address(bases[0],offsets[3])),
                           (15,*packet['launch'])]
                expected += [[phase,f'{f<<8:016x}',f'{a:016x}',f'{b:016x}','0000000000000000'] for f,a,b in values]
            expected+=commands[ends[-1]+1:]
        assert expected==after['commands'],'S2 native semantic stream mismatch'
        raw=lambda t:sum(int(c[1],16)&255==0 for c in t['commands'])
        drains=lambda t:sum(int(c[1],16)&255==1 for c in t['commands'])
        assert raw(after)<=raw(before)*1.05 and drains(after)==drains(before)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--identity',action='store_true');p.add_argument('--search',action='store_true');p.add_argument('--audit',action='store_true');p.add_argument('--record',action='store_true');p.add_argument('--offline-record',action='store_true')
    args=p.parse_args()
    if args.identity:identity()
    if args.search:search()
    if args.audit:audit()
    if args.record:audit(record=True)
    if args.offline_record:audit(record=True,offline=True)

if __name__=='__main__':main()
