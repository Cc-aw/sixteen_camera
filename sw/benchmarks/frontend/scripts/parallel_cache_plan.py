#!/usr/bin/env python3
"""SW-P3 frozen-native plan inventory and bounded spatial tile derivation.

All instruction packing is done by the frozen C helpers. Decoded semantics must
round trip to every frozen packet before any candidate is considered.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import shlex
import struct
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT.parents[2]
sys.path.insert(0, str(PROJECT / 'sw/models/yolov5nu/codegen'))
from fixed_packets import native_program
from fixed_plans import function

BUFFERS = [('activation_arenas', 2217600), ('conv_input_scratches', 1228800),
           ('conv_output_scratches', 1228800), ('memory_pad', 17*22*128),
           ('memory_intermediate', 15*20*128)]
sys.path.insert(0, str(PROJECT / 'tools/soc'))
from l2_geometry import current_geometry
GEOMETRY = current_geometry(PROJECT)
PERIOD = GEOMETRY.period_bytes
COLORS = GEOMETRY.colors
NULL = 0xffffffff


def sha(value):
    return hashlib.sha256(value if isinstance(value, bytes) else
                          json.dumps(value, sort_keys=True).encode()).hexdigest()


def save(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + '\n')


def field(word, shift, bits=16):
    return (word >> shift) & ((1 << bits)-1)


def semantic(plan):
    c, p = plan['config'], plan['tiles'][0]
    g, launch = p['geometry'], p['launch']
    a, b = c[4:6]
    return dict(batch=field(a,0), ih=field(a,16), iw=field(g[3],0),
                ic=field(a,32), oc=field(a,48), oh=field(b,0), ow=field(b,32),
                stride=field(b,48,8), pad=field(b,56,8), kernel=field(g[0],48),
                dilation=field(g[4],0,10), istride=field(g[5],48),
                wstride=field(g[5],32), ostride=field(g[5],16),
                act=field(c[0],2,3), scale_bits=field(c[1],32),
                flags=launch[0]&255, mode=launch[1])


def native_args(s, tile):
    # Only native NHWC, unpooled, nondilated inputs are in this frozen graph.
    if s['flags'] or s['mode'] & 7 != 1:
        raise ValueError('Unsupported convolution transformation')
    scale = struct.unpack('<e', struct.pack('<H', s['scale_bits']))[0]
    a = [s[k] for k in ('batch','ih','iw','ic','oc','oh','ow','stride')]
    a += [1, s['dilation'], s['pad'], s['kernel']]
    a += [s[k] for k in ('istride','wstride','ostride')]
    a += [0]*5 + list(tile)
    return ','.join(map(str,a)) + ',inputs,weights,biases,outputs,' + str(s['act']) + ',' + float(scale).hex() + 'f,1,0,0,WS'


def regenerate(snap, requests, out):
    """Compile once; execute actual native loops, SP capacity helper and packer."""
    h = (snap/'include/gemmini.h').read_text()
    # Frozen header retains an unused old cooperative descriptor path.
    h = h.replace(function(h, '    if (parallel_collecting) {'), '')
    code = native_program(h, snap/'include/gemmini_params.h')
    code += r'''
static unsigned stage, candidate;
static elem_t inputs[8000000],weights[8000000],outputs[8000000];
static acc_t biases[1024];
static uint64_t offset(uint64_t p,const void *base) {
    if(!p)return UINT32_MAX;
    assert(p >= (uintptr_t)base && p-(uintptr_t)base < 8000000);
    return p-(uintptr_t)base;
}
static void record(unsigned f,uint64_t a,uint64_t b) {
    if(f==20){a=offset(a,weights);b=offset(b,outputs);}
    if(f==21){a=offset(a,biases);b=offset(b,inputs);}
    printf("%u %u %u %llu %llu\n",stage,candidate,f,(unsigned long long)a,(unsigned long long)b);
}
int main(void) {
'''
    for stage, idx, s, tile in requests:
        args = native_args(s,tile)
        sp_args = [s['stride'],1,s['dilation'],0,0,0] + list(tile) + [1,1]
        helper = ','.join(map(str,sp_args))
        code += f'''stage={stage};candidate={idx};
if(tiled_conv_total_spad_rows(false,{helper})<=BANK_NUM*BANK_ROWS/2 &&
   tiled_conv_total_spad_rows(true,{helper})<=ACC_ROWS/2) {{
    printf("C %u %u %d %d\\n",stage,candidate,
        tiled_conv_total_spad_rows(false,{helper}),tiled_conv_total_spad_rows(true,{helper}));
    tiled_conv({args});
}}
'''
    code += 'return 0;}\n'
    src, exe = out/'native_candidates.c', out/'native_candidates'
    src.write_text(code)
    subprocess.run(shlex.split(os.environ.get('HOST_CC','cc')) +
                   ['-O2','-std=gnu11',str(src),'-o',str(exe)],check=True)
    result = subprocess.run([str(exe)],check=True,capture_output=True,text=True)
    (out/'native_candidates.txt').write_text(result.stdout)
    streams, capacities = {}, {}
    for line in result.stdout.splitlines():
        if line.startswith('C '):
            _, stage, idx, spad, acc = line.split()
            capacities[int(stage),int(idx)] = dict(spad_rows=int(spad),acc_rows=int(acc))
            streams[int(stage),int(idx)] = []
        else:
            stage,idx,f,a,b = map(int,line.split())
            streams[stage,idx].append([f,a,b])
    packed = {}
    for key, events in streams.items():
        if [e[0] for e in events[:2]] != [0,0] or (len(events)-2)%7:
            raise ValueError('Unexpected native stream')
        tiles = []
        for start in range(2,len(events),7):
            p = events[start:start+7]
            if [e[0] for e in p] != [16,17,18,19,20,21,15]:
                raise ValueError('Native packet ordering')
            if p[0][1:] != events[2][1:]:
                raise ValueError('Inconsistent layer bounds')
            tiles.append(dict(geometry=sum((e[1:] for e in p[1:4]),[]),
                              offsets=p[4][1:]+p[5][1:], launch=p[6][1:]))
        packed[key] = dict(config=events[0][1:]+events[1][1:]+events[2][1:],tiles=tiles)
    return packed, capacities


def spans(s, packet, role, include_reuse=False):
    """Exact nontransposed DDR byte spans for one decoded native packet.

    NULL operands issue no load/store. Reused B/A is handled by the window
    builder, retaining the last loaded operand for the matching SPAD id.
    """
    g, offsets = packet['geometry'], packet['offsets']
    offset = offsets[{'weight':0,'output':1,'bias':2,'input':3}[role]]
    if offset == NULL:
        return []
    nb, nr, nc, nch = [field(g[1],b) for b in (48,32,16,0)]
    kr,kc,ki = [field(g[2],b) for b in (48,32,16)]
    if role == 'bias':
        return [(offset,4*nch)]
    if role == 'weight':
        return [(offset+((y*s['kernel']+x)*s['ic']+ch)*s['wstride'],nch)
                for y in range(kr) for x in range(kc) for ch in range(ki)]
    if role == 'input':
        rows = (field(g[4],48)*s['stride'] + (kr-1)*s['dilation'] -
                field(g[3],32) - field(g[3],24,8))
        cols = (field(g[5],0)*s['stride'] + (kc-1)*s['dilation'] -
                field(g[2],0) - field(g[3],48))
        if s['istride'] == ki:
            return [(offset+((b*s['ih']+y)*s['iw'])*s['istride'],cols*ki)
                    for b in range(nb) for y in range(rows)]
        return [(offset+((b*s['ih']+y)*s['iw']+x)*s['istride'],ki)
                for b in range(nb) for y in range(rows) for x in range(cols)]
    if s['ostride'] == nch:
        return [(offset+((b*s['oh']+y)*s['ow'])*s['ostride'],nc*nch)
                for b in range(nb) for y in range(nr)]
    return [(offset+((b*s['oh']+y)*s['ow']+x)*s['ostride'],nch)
            for b in range(nb) for y in range(nr) for x in range(nc)]


def lines(ranges, base=0):
    result = set()
    for off,n in ranges:
        if n:
            result.update(range((base+off)//64,(base+off+n-1)//64+1))
    return result


def metrics(s, plan):
    result = dict(packets=len(plan['tiles']),raw=2+7*len(plan['tiles']),
                  logical_payload=0,line_touches=0,partial_output_spans=0,
                  peak_packet_lines=0,padded_macs=0,input_halo_retouch_lines=0)
    previous = set()
    for role in ('input','weight','bias','output'):
        nbytes, nlines = 0,0
        for p in plan['tiles']:
            ranges = spans(s,p,role)
            ls = lines(ranges)
            nbytes += sum(n for _,n in ranges);nlines += len(ls)
            if role == 'input':
                result['input_halo_retouch_lines'] += len(ls & previous);previous=ls
            if role == 'output':
                result['partial_output_spans'] += sum(bool(off%64 or n%64) for off,n in ranges)
        result[role+'_bytes'] = nbytes
        result[role+'_line_touches'] = nlines
        result['logical_payload'] += nbytes;result['line_touches'] += nlines
    for p in plan['tiles']:
        g=p['geometry']; nb,nr,nc,oc=[field(g[1],b) for b in (48,32,16,0)]
        kr,kc,ic=[field(g[2],b) for b in (48,32,16)]
        # Padding to DIM in channel dimensions is a work proxy, not cycles.
        result['padded_macs'] += nb*nr*nc*kr*kc*((ic+31)//32*32)*((oc+31)//32*32)
        role_lines={r:len(lines(spans(s,p,r))) for r in ('input','weight','bias','output')}
        result['three_lane_private_plus_shared_peak_lines_proxy']=max(result.get('three_lane_private_plus_shared_peak_lines_proxy',0),3*(role_lines['input']+role_lines['output'])+role_lines['weight']+role_lines['bias'])
        result['peak_packet_lines'] = max(result['peak_packet_lines'],
            sum(len(lines(spans(s,p,r))) for r in ('input','weight','bias','output')))
    return result


def derive(snap, gen):
    frozen=json.loads((snap/'fixed_plans.json').read_text())
    model=(snap/'parallel_model.inc').read_text()
    stages=[];requests=[]
    aliases={name:int(offset) for name,offset in re.findall(r'#define (tensor_\d+) \(activation_arena \+ (\d+)\)',model)}
    for stage in sorted(map(int,frozen['fixed_packets'])):
        key=str(stage);p=frozen['fixed_packets'][key];s=semantic(p)
        tile=frozen['ordinary'][key]['tile']
        requests.append((stage,0,s,tile))
        # Fixed, bounded spatial search; K and output-channel partition unchanged.
        options={(r,c) for r in (max(1,tile[1]//2),tile[1],min(s['oh'],tile[1]*2),s['oh'])
                 for c in (max(1,tile[2]//2),tile[2],min(s['ow'],tile[2]*2),s['ow'])}
        for idx,(r,c) in enumerate(sorted(options-{(tile[1],tile[2])}),1):
            if stage<=74 or 78<=stage<=123 or stage in (124,146,147,163,164):
                requests.append((stage,idx,s,[tile[0],r,c,*tile[3:]]))
        binding=int(re.search(r'&conv_packet_plan_'+key+r',&batch_conv_bindings\[worker_id\]\[(\d+)\]',model)[1])
        tensor_ids={role:re.findall(r'batch_conv_bindings\[worker\]\['+str(binding)+r'\]\.'+role+r'=([^;]+);',model) for role in ('input','weights','bias','output')}
        stages.append(dict(logical_tensor_id=tensor_ids,head_id=next(iter(re.findall(r'yolo32_publish_head\(worker_id, (\d)\)',model.split('    case '+str(stage)+'U:')[1].split('    case ')[0])),None),stage_id=stage,op_kind='ordinary_conv',binding=binding,
                           shape=s,physical_stride={k:s[k] for k in ('istride','wstride','ostride')},
                           tile=tile,packet_count=len(p['tiles']),config=p['config'],
                           packets=p['tiles'],original_plan_hash=sha(p),candidate_plan_hash=sha(p),
                           spad_rows=frozen['ordinary'][key]['spad_rows'],
                           acc_rows=frozen['ordinary'][key]['acc_rows'],
                           null_semantics='UINT32_MAX: retain native B/A reuse or partial accumulation',
                           priority_region='tag1' if stage<=74 else 'tag7' if 78<=stage<=123 else 'secondary'))
    packed,capacities=regenerate(snap,requests,gen)
    report=[]
    for entry in stages:
        stage=entry['stage_id'];p=frozen['fixed_packets'][str(stage)];s=entry['shape']
        if packed.get((stage,0)) != p:
            raise ValueError(f'Frozen native roundtrip differs at stage {stage}')
        before=metrics(s,p);candidates=[]
        for st,idx,_,tile in requests:
            if st!=stage or not idx:continue
            key=st,idx
            if key not in packed:
                candidates.append(dict(tile=tile,status='REJECTED_CAPACITY'));continue
            m=metrics(s,packed[key]);reason='NO_STATIC_ADVANTAGE'
            if m['logical_payload']<=before['logical_payload'] and m['padded_macs']<=before['padded_macs'] and m['raw']<=before['raw']*1.05 and (m['line_touches'],m['peak_packet_lines']) < (before['line_touches'],before['peak_packet_lines']):
                reason='BLOCKED_NUMERICAL_VALIDATION'
            candidates.append(dict(candidate_id=idx,tile=tile,metrics=m,**capacities[key],
                                   plan_hash=sha(packed[key]),status=reason))
        report.append(dict(stage_id=stage,priority_region=entry['priority_region'],
                           baseline_tile=entry['tile'],baseline_metrics=before,candidates=candidates,
                           selected_tile=entry['tile'],changed=False,
                           reason='RETAIN_BASELINE_PENDING_NUMERICAL_PROOF' if any(c['status'].startswith('BLOCKED') for c in candidates) else 'NO_PROVEN_ADVANTAGE'))
    report.sort(key=lambda e:(e['priority_region']!='tag1',-e['baseline_metrics']['line_touches'],e['stage_id']))
    save(gen/'tiling_manifest.json',dict(schema=1,metric='static bytes/lines/work proxies; not cycles',
         enabled_changed_stages=[],max_changed_stages=6,raw_growth_limit_percent=5,
         native_roundtrip_stages=58,stages=report,
         numerical_validation='BLOCKED: generated alternative geometries have no executed arithmetic proof; none enabled'))
    save(gen/'candidate_packets.json',{f'{s}:{i}':p for (s,i),p in packed.items()})
    save(gen/'plan_description.json',dict(schema=1,stages=stages,buffers=[dict(arena_class=n,logical_bytes=c,alignment=64) for n,c in BUFFERS],
         ordinary_coverage=58,tensor_alias_offsets=aliases,other_operations='all RAW/DRAIN/HOST and phase IDs exported by host inventory',
         original_plan_hash=sha(frozen['fixed_packets']),candidate_plan_hash=sha(frozen['fixed_packets'])))
    return stages


def storage_declarations():
    text='/* SW-P3 storage is identical for every runtime profile. */\n'
    text+=f'#define SW_P3_L2_PERIOD {PERIOD}u\n'
    for name,cap in BUFFERS:
        text+=f'static elem_t {name}_storage[3*({cap}+{PERIOD}+128)] __attribute__((aligned({PERIOD})));\n'
        text+=f'static elem_t *{name}[3] = {{'+','.join(f'{name}_storage+64+{lane}*{cap}' for lane in range(3))+'};\n'
    return text


def adapt_graph(code):
    # Memory declarations live in a separate include and are removed there.
    for name,cap in BUFFERS[:3]:
        code,n=re.subn(r'static elem_t '+name+r'\[[^;]+;', '',code,count=1)
        if n!=1:raise ValueError('Missing storage declaration '+name)
    anchor='#include "fixed_plans_guard.inc"'
    if code.count(anchor)!=1:raise ValueError('Graph storage include anchor')
    return code.replace(anchor,'#include "sw_p3_storage.inc"\n'+anchor,1).replace('#include "software_batch_packets.inc"','#include "sw_p3_tiling.inc"\n#include "software_batch_packets.inc"')


def adapt_main(source):
    """Keep V33 source and all its strict invariants; derive a separate adapter."""
    from prepare import once
    source=once(source,'#include "config.h"','#include "config.h"\n#include "parallel_cache_config.h"')
    source=once(source,'#define ATSOFT_THREE_WAY 0','#define ATSOFT_THREE_WAY 1')
    source=once(source,'enum { MODES=ATSOFT_THREE_WAY?3:2 };','enum { MODES=ATSOFT_THREE_WAY?3:2 };\n_Static_assert(MODES==3,"SW-P3 requires three complete result buffers");')
    source=once(source,'static void at_fail(const char *s,uint64_t v) __attribute__((noreturn));', '#ifdef __riscv\nstatic void sw_p3_gate_reset(void);\n#endif\nstatic void at_fail(const char *s,uint64_t v) __attribute__((noreturn));')
    source=once(source,'static void at_fail(const char *s,uint64_t v) {', 'static void at_fail(const char *s,uint64_t v) {\n#ifdef __riscv\n    sw_p3_gate_reset();\n#endif')
    source=source.replace('#include "graph.inc"','#include "graph.inc"\n#include "parallel_cache_layout.inc"')
    source=once(source,'    yolo32_batch_bind_start(lane);planning=1;', '    yolo32_batch_bind_start(lane);current_phase=0;planning=1;')
    source=once(source,'static struct Plan *recording;', 'static unsigned sw_p3_phase_ids[MAX_COMMANDS];\nstatic struct Plan *recording;')
    source=once(source,'    recording->commands[recording->count++]=c;',
                '    sw_p3_phase_ids[recording->count]=current_phase;\n    recording->commands[recording->count++]=c;')
    for name,cap in BUFFERS:
        source=source.replace(f'sizeof({name}[lane])',str(cap))
    source=once(source,function(source,'static void tensor_fill('),
                'static void tensor_fill(unsigned char value) { sw_p3_tensor_fill(value); }')
    source=once(source,function(source,'static uint64_t tensor_hash('),
                'static uint64_t tensor_hash(void) { return sw_p3_tensor_hash(); }')
    for name,cap in BUFFERS:
        source=source.replace(f'memset({name},0,sizeof({name}));','')
    source=once(source,'static void prepare_batch(void) {',
                'static void prepare_batch(void) {\n    sw_p3_tensor_fill(0); sw_p3_gate_reset();')
    source=once(source,'t->slot=ppu_begin(d,executor*FRAMES+f+1);',
                't->slot=ppu_begin(d,++sw_p3_run_id);')
    source=once(source,'struct Frame {unsigned device',
                '#include "parallel_cache_gate.inc"\nstatic unsigned sw_p3_run_id,sw_p3_serial_lane,sw_p3_matched,sw_p3_replay_lane[FRAMES];\nstatic unsigned sw_p3_serial_device(unsigned);\nstruct Frame {unsigned device')
    source=once(source,'            gf_publish();execute_host(f,tag);gf_publish();require(gf_resume(d,tag,0),"resume");',
                '''            if(sw_p3_gate[d].pending&&(sw_p3_gate[d].tag!=tag||sw_p3_gate[d].frame!=f))at_fail("sw_p3_pending_identity",tag);
            if(!sw_p3_gate[d].pending) {
                sw_p3_gate_observed(d,tag);
                gf_publish();execute_host(f,tag);gf_publish();
                sw_p3_gate_served(d,tag,clock_cycle());
            }
            if(!sw_p3_gate_ready(d,clock_cycle()))continue;
            require(gf_resume(d,tag,0),"resume");
            sw_p3_gate_resumed(d,clock_cycle());''')
    source=once(source,'static void parallel_batch(unsigned active_lanes) {',
                'static unsigned sw_p3_serial_busy(void) { for(unsigned d=0;d<3;d++)if(bound[d]>=0)return 1;return 0; }\nstatic void parallel_batch(unsigned active_lanes) {')
    source=once(source,'d<active_lanes&&bound[d]<0&&next_frame<FRAMES&&use[d]<FRAMES/active_lanes',
                'bound[d]<0&&next_frame<FRAMES&&(active_lanes==3?use[d]<FRAMES/3:(d==sw_p3_serial_device(next_frame)&&!sw_p3_serial_busy()))')
    # Pending HOSTs remain software-held; they cannot be served twice. Hardware
    # pending remains asserted until RESUME. Existing IRQ mask protocol remains.
    source=once(source,'    tensor_fill(0x35);uint64_t before=tensor_hash();',
                '    unsigned profile=argc>2?(unsigned)strtoul(argv[2],NULL,10):0;\n    sw_p3_tiling_enabled=profile>=2;sw_p3_set_layout(profile!=0);\n    tensor_fill(0x35);uint64_t before=tensor_hash();')
    source=once(source,'    if(argc==2) {','    sw_p3_guards_check();\n    if(argc>=2) {')
    source=once(source,'        fclose(out);',
                '        fclose(out);\n        sw_p3_dump_inventory(argv[1]);')
    start=source.index('#else\n    ppu_init();uint64_t cycles[MODES];')
    source=source[:start]+'#else\n    return sw_p3_suite();\n#endif\n}\n'
    source=once(source,'int main(int argc,char **argv) {',
                '#include "parallel_cache_suite.inc"\nint main(int argc,char **argv) {')
    # Suite has its own schema. V33 ELF checks and log parser stay unchanged.
    a=source.index('#if YOLO32_FRONTEND_DIAG\n    text("YOLO32_FRONTEND,BUILD,')
    b=source.index('    uint64_t vlenb;',a)
    source=source[:a]+source[b:]
    source=source.replace('recording->conv!=462','recording->conv!=(sw_p3_tiling_enabled?SW_P3_CONV_COUNT:462)')
    source=source.replace('plans[0][0][0].count!=10870||plans[0][0][0].raw!=10478',
                          'plans[0][0][0].count!=(sw_p3_tiling_enabled?SW_P3_ENTRY_COUNT:10870)||plans[0][0][0].raw!=(sw_p3_tiling_enabled?SW_P3_RAW_COUNT:10478)')
    source=source.replace('text(",conv=462,ws=224,pad_hosts=6,head_hosts=6,owned_operands=1,hardware_executed=0\\n");',
                          'field(",conv=",plans[0][0][0].conv);text(",ws=224,pad_hosts=6,head_hosts=6,owned_operands=1,hardware_executed=0\\n");')
    return source


def prepare_candidate(snap,gen):
    derive(snap,gen)
    select_verified_tiling(gen)
    (gen/'sw_p3_storage.inc').write_text(storage_declarations())
    for n in ('graph.inc','native_graph.inc'):
        (gen/n).write_text(adapt_graph((gen/n).read_text()))
    memory=(gen/'memory_kernels_runtime.inc').read_text()
    for name,_ in BUFFERS[3:]:
        memory,n=re.subn(r'static elem_t '+name+r'\[[^;]+;','',memory,count=1)
        if n!=1:raise ValueError('Missing memory storage '+name)
    (gen/'memory_kernels_runtime.inc').write_text(memory)
    (gen/'sw_p3_main.c').write_text(adapt_main((ROOT/'src/main.c').read_text()))
    (gen/'sw_p3_layout_offsets.inc').write_text('static const volatile unsigned sw_p3_offsets[5][3] = {{0}};\nstatic const volatile unsigned sw_p3_layout_enabled=0;\n')
    save(gen/'sw_p3_provenance.json',dict(schema=1,source_commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=PROJECT,text=True).strip(),
         frozen_lock_sha256=sha((PROJECT/'sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json').read_bytes()),
         hardware_abi_changed=False,model_changed=False,head_gate_default=False,board_performance='NOT_MEASURED'))
    finalize_candidate_manifest(gen)



def select_verified_tiling(gen):
    """Only an executed full-layer numerical result can enable the shortlist.

    This first bounded implementation promotes at most stage18. Other static
    candidates remain individually reported and retain their frozen plans.
    """
    report=json.loads((gen/'tiling_manifest.json').read_text())
    description=json.loads((gen/'plan_description.json').read_text())
    packed=json.loads((gen/'candidate_packets.json').read_text())
    evidence_path=gen.parent/'tiling_numerical_evidence.json'
    selected=[]
    if evidence_path.exists():
        e=json.loads(evidence_path.read_text());key=f'{e.get("stage_id",0)}:{e.get("candidate_id",0)}'
        checker=PROJECT/'tests/model/frontend_parallel_cache/test_real_tiling.py'
        if (e.get('status')=='FUNCTIONAL_PASS' and e['stage_id']==18 and
            e['candidate_plan_hash']==sha(packed[key]) and
            e['checker_sha256']==sha(checker.read_bytes()) and
            e['hardware_files_sha256']==sha((PROJECT/'hw/manifests/current.json').read_bytes()) and
            (PROJECT/e.get('generation_context','')).is_file() and sha((PROJECT/e['generation_context']).read_bytes())==e.get('generation_context_sha256') and
            (PROJECT/e['rtl_log']).is_file() and e['rtl_log_sha256']==sha((PROJECT/e['rtl_log']).read_bytes()) and
            all((PROJECT/name).is_file() and sha((PROJECT/name).read_bytes())==digest for name,digest in e.get('rtl_sources',{}).items()) and
            (gen.parent/'native_cpu_reference.json').exists() and
            json.loads((gen.parent/'native_cpu_reference.json').read_text()).get('checker_sha256')==sha((PROJECT/'tests/model/frontend_parallel_cache/test_cpu_reference.py').read_bytes())):
            stage=next(s for s in report['stages'] if s['stage_id']==18)
            candidate=next(c for c in stage['candidates'] if c.get('candidate_id')==e['candidate_id'])
            if candidate['status']!='BLOCKED_NUMERICAL_VALIDATION':raise ValueError('Evidence for ineligible static candidate')
            selected=[(18,candidate['candidate_id'])]
            stage.update(changed=True,selected_tile=candidate['tile'],reason='FULL_LAYER_REAL_DIM32_NUMERICAL_PASS')
            candidate['status']='SELECTED_FUNCTIONAL_PASS'
            report['enabled_changed_stages']=[18];report['numerical_validation']=e
    declarations=['static unsigned sw_p3_tiling_enabled;']
    delta=0
    for sid,idx in selected:
        p=packed[f'{sid}:{idx}'];base=packed[f'{sid}:0'];delta+=len(p['tiles'])-len(base['tiles'])
        def words(values,typ):return '{'+','.join(f'UINT{typ}_C({v})' for v in values)+'}'
        declarations.append(f'static const struct yolo32_conv_packet sw_p3_packets_{sid}[] = {{'+','.join(
            '{'+words(t['geometry'],64)+','+words(t['offsets'],32)+','+words(t['launch'],64)+'}' for t in p['tiles'])+'};')
        declarations.append(f'static const struct yolo32_conv_packet_plan sw_p3_plan_{sid} = {{'+words(p['config'],64)+f',{len(p["tiles"])},sw_p3_packets_{sid}'+'};')
        desc=next(s for s in description['stages'] if s['stage_id']==sid)
        desc['candidate_plan_hash']=sha(p);desc['selected_tile']=next(s for s in report['stages'] if s['stage_id']==sid)['selected_tile']
    declarations.append('static const struct yolo32_conv_packet_plan *sw_p3_select_tiling(const struct yolo32_conv_packet_plan *p) {')
    for sid,_ in selected:declarations.append(f'if(sw_p3_tiling_enabled && p==&conv_packet_plan_{sid})return &sw_p3_plan_{sid};')
    declarations.append('return p;}')
    declarations.append('enum {SW_P3_CONV_COUNT=%d,SW_P3_ENTRY_COUNT=%d,SW_P3_RAW_COUNT=%d};' % (462+delta,10870+7*delta,10478+7*delta))
    (gen/'sw_p3_tiling.inc').write_text('\n'.join(declarations)+'\n')
    chosen={str(s['stage_id']):packed[f'{s["stage_id"]}:0'] for s in description['stages']}
    for sid,idx in selected:chosen[str(sid)]=packed[f'{sid}:{idx}']
    description['candidate_plan_hash']=sha(chosen)
    save(gen/'tiling_manifest.json',report);save(gen/'plan_description.json',description)
    software=(gen/'software_batch_packets.inc').read_text()
    signature='        const struct yolo32_conv_binding *b) {'
    if software.count(signature)!=1:raise ValueError('Bound convolution anchor')
    software=software.replace(signature,signature+'\n    plan=sw_p3_select_tiling(plan);',1)
    (gen/'software_batch_packets.inc').write_text(software)


def finalize_candidate_manifest(gen):
    manifest=json.loads((gen/'manifest.json').read_text())
    if manifest.get('firmware')!='SW-P3':
        manifest['upstream_firmware']=manifest['firmware']
        manifest['upstream_graph_sha256']=manifest['graph_sha256']
    tiling=json.loads((gen/'tiling_manifest.json').read_text())
    manifest.update(firmware='SW-P3',graph_sha256=sha((gen/'graph.inc').read_bytes()),
        profiles=['reference','layout','cache_plan','cache_plan_gate'],
        tiling_changed_stages=tiling['enabled_changed_stages'],head_gate_default=False,
        baseline_ordinary_conv_packets=462,
        candidate_ordinary_conv_packets=sum(s['baseline_metrics']['packets'] if not s['changed'] else next(c['metrics']['packets'] for c in s['candidates'] if c['status']=='SELECTED_FUNCTIONAL_PASS') for s in tiling['stages']))
    manifest.pop('ordinary_conv_packets',None)
    manifest['ordinary_conv_packets_by_profile']={name:(manifest['candidate_ordinary_conv_packets'] if name in ('cache_plan','cache_plan_gate') else 462) for name in manifest['profiles']}
    manifest['retained']='native arithmetic, B reuse, FP16, LUT, MaxPool/Resize, DRAIN/HOST and Head/PPU lifecycle'
    save(gen/'manifest.json',manifest)
