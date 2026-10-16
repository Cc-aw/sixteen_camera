#!/usr/bin/env python3
"""Real SW-P3 dispatcher under fake-device interleavings, plus manifest tests.

Fake devices prove protocol ordering only, never convolution arithmetic.
"""
import ast
import copy
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import unittest

PROJECT=Path(__file__).resolve().parents[3]
ROOT=PROJECT/'sw/benchmarks/frontend'
OUT=Path(os.environ.get('FRONTEND_BUILD',PROJECT/'build/firmware/sw-p3'))
sys.path.insert(0,str(ROOT/'scripts'))
from parallel_cache_plan import function,metrics,semantic,spans,lines,field,NULL,sha
from analyze_parallel_cache import parse,InvalidLog


def dispatch():
    tree=ast.parse((PROJECT/'tests/model/frontend_v33/test_dispatch.py').read_text())
    strings={n.targets[0].id:ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and isinstance(n.value,ast.Constant) and isinstance(n.value.value,str)}
    harness,tail=strings['harness'],strings['tail']
    source=(OUT/'generated/sw_p3_main.c').read_text()
    functions='\n'.join(function(source,s) for s in (
        'static void execute_host(', 'static void admit(', 'static void graph_done(',
        'static void finish(', 'static unsigned sw_p3_serial_busy(', 'static void parallel_batch(',
        'static const char *executor_name(', 'static unsigned report('))
    functions=re.sub(r'__asm__ volatile\(.*?\);','((void)0);',functions,flags=re.S)
    harness=harness.replace('@FRAME_CONSTANTS@',re.search(r'enum \{ FRAMES=.*?\};',source)[0])
    harness=harness.replace('static unsigned seed,', 'static unsigned sw_p3_run_id,sw_p3_serial_lane,sw_p3_matched,sw_p3_replay_lane[FRAMES];\nstatic unsigned sw_p3_serial_device(unsigned f){return sw_p3_matched?sw_p3_replay_lane[f]:sw_p3_serial_lane;}\n#include "parallel_cache_gate.inc"\nstatic unsigned enabled,serial_case;\nstatic unsigned seed,')
    harness=harness.replace('assert(d<active_lanes&&irq&&', 'assert((active_lanes==3||d==sw_p3_serial_device(bound[d]))&&irq&&')
    harness=harness.replace('assert(d<active_lanes&&run==executor*FRAMES+current_frame+1);','assert(run==sw_p3_run_id&&run>0);')
    tail=tail.replace('for(seed=0;', 'for(enabled=0;enabled<2;enabled++)\n for(seed=0;')
    tail=tail.replace('for(seed=0;', 'for(serial_case=0;serial_case<(active_lanes==1?4:1);serial_case++)\n for(seed=0;')
    tail=tail.replace('  executor=active_lanes==1?1:2;', '  sw_p3_serial_lane=serial_case<3?serial_case:0;sw_p3_matched=serial_case==3;for(unsigned f=0;f<FRAMES;f++)sw_p3_replay_lane[f]=f%3;\n  sw_p3_gate_reset();sw_p3_gate_enabled=enabled;\n  executor=active_lanes==1?1:2;')
    tail=tail.replace('d<active_lanes?FRAMES/active_lanes:0', '(active_lanes==3||sw_p3_matched)?FRAMES/3:(d==sw_p3_serial_lane?FRAMES:0)')
    tail=tail.replace('frames[f].device<active_lanes', '(active_lanes==3||frames[f].device==sw_p3_serial_device(f))')
    # Original source assertions still verify exactly one HOST/RESUME per tag.
    # Explicit gate unit tests cover timeout under three eligible intervals.
    tail=tail.replace(' memset(output,0,sizeof(output));\n for(unsigned f=',r'''
 sw_p3_gate_reset();sw_p3_gate_enabled=1;
 sw_p3_gate_served(0,7,0);assert(sw_p3_gate_ready(0,1));sw_p3_gate_resumed(0,1);
 sw_p3_gate_served(1,9,2);sw_p3_gate_resumed(1,3);
 sw_p3_gate_served(2,7,4);assert(!sw_p3_gate_ready(2,16003));assert(sw_p3_gate_ready(2,16004));
 sw_p3_gate_resumed(2,16004);assert(sw_p3_gate_active()==3&&sw_p3_gate_timeouts==1&&sw_p3_gate_peak==3);
 sw_p3_gate_observed(0,8);sw_p3_gate_observed(1,10);sw_p3_gate_observed(2,8);assert(!sw_p3_gate_active());
 sw_p3_gate_reset();for(unsigned d=0;d<3;d++)assert(!sw_p3_gate[d].pending&&!sw_p3_gate[d].active);
 memset(output,0,sizeof(output));
 for(unsigned f=''')
    tail=tail.replace('ATSOFT1,DISPATCH_PASS,seeds=100', 'SWP3_DISPATCH_PASS,seeds=100,solo_lanes=0+1+2,matched=1,gate=off+on').replace('fault_cases=600','fault_cases=3000_per_diagnostic')
    src=OUT/'sw_p3_dispatch_test.c';src.write_text(harness+functions+tail)
    exe=OUT/'sw_p3_dispatch_test'
    for diagnostic in (0,1):
        subprocess.run(['cc','-std=gnu11','-O1','-g','-Wall','-Wextra','-Werror','-Wno-unused-variable',
            '-Wno-unused-function','-fsanitize=address,undefined',f'-DYOLO32_FRONTEND_DIAG={diagnostic}',
            '-I'+str(ROOT/'include'),'-I'+str(ROOT/'src'),str(src),'-o',str(exe)],check=True)
        subprocess.run([str(exe)],check=True,timeout=60,env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))


def check_packet_coverage(shape,tile,plan):
    """Independent coordinate/address/reduction/reuse verifier (no packing)."""
    s=shape;ib,ir,ix,ic,ikr,ikc,iki=tile
    coords=[(b,y,x,c,kr,kc,ki) for b in range(0,s['batch'],ib)
        for y in range(0,s['oh'],ir) for x in range(0,s['ow'],ix)
        for c in range(0,s['oc'],ic) for kr in range(0,s['kernel'],ikr)
        for kc in range(0,s['kernel'],ikc) for ki in range(0,s['ic'],iki)]
    assert len(coords)==len(plan['tiles'])
    ceil=lambda x,y:(x+y-1)//y
    b_reuse=ceil(s['ic'],iki)*ceil(s['oc'],ic)*ceil(s['kernel'],ikr)*ceil(s['kernel'],ikc)<=2
    a_reuse=ceil(s['ic'],iki)*ceil(s['kernel'],ikr)*ceil(s['kernel'],ikc)*ceil(s['batch'],ib)*ceil(s['oh'],ir)*ceil(s['ow'],ix)<=2
    for pos,p in zip(coords,plan['tiles']):
        b,y,x,c,kr,kc,ki=pos;g=p['geometry'];offsets=p['offsets']
        dims=[min(ib,s['batch']-b),min(ir,s['oh']-y),min(ix,s['ow']-x),min(ic,s['oc']-c)]
        assert [field(g[1],shift) for shift in (48,32,16,0)]==dims
        assert [field(g[2],shift) for shift in (48,32,16)]==[min(ikr,s['kernel']-kr),min(ikc,s['kernel']-kc),min(iki,s['ic']-ki)]
        final=kr+ikr>=s['kernel'] and kc+ikc>=s['kernel'] and ki+iki>=s['ic']
        output=((b*s['oh']+y)*s['ow']+x)*s['ostride']+c
        assert offsets[1]==(output if final else NULL)
        assert offsets[2]==(4*c if kr+kc+ki==0 else NULL)
        weight=((kr*s['kernel']+kc)*s['ic']+ki)*s['wstride']+c
        assert offsets[0]==(NULL if b_reuse and b+y+x>0 else weight)
        iy=y*s['stride']+kr*s['dilation']-s['pad'];ix0=x*s['stride']+kc*s['dilation']-s['pad']
        input_off=((b*s['ih']+max(0,iy))*s['iw']+max(0,ix0))*s['istride']+ki
        assert offsets[3]==(NULL if a_reuse and c>0 else input_off)
        assert field(g[2],0)==max(0,-ix0) and field(g[3],32)==max(0,-iy)
        a_id=(1 if b+y+x+kr+kc+ki==0 else 2) if a_reuse else 0
        b_id=(1 if ki+c+kr+kc==0 else 2) if b_reuse else 0
        assert field(p['launch'][0],18,2)==a_id and field(p['launch'][0],16,2)==b_id
        assert field(g[4],48)==dims[1] and field(g[5],0)==dims[2]
        assert [field(g[5],shift) for shift in (48,32,16)]==[s['istride'],s['wstride'],s['ostride']]
        for role,n in [('input',s['batch']*s['ih']*s['iw']*s['istride']),
                       ('weight',s['kernel']**2*s['ic']*s['wstride']),('bias',4*s['oc']),
                       ('output',s['batch']*s['oh']*s['ow']*s['ostride'])]:
            assert all(0<=off and off+size<=n for off,size in spans(s,p,role)),(pos,role)


class Contract(unittest.TestCase):
    def test_all_native_and_candidate_coverage(self):
        desc=json.loads((OUT/'generated/plan_description.json').read_text())
        report=json.loads((OUT/'generated/tiling_manifest.json').read_text())
        packed=json.loads((OUT/'generated/candidate_packets.json').read_text())
        for stage in desc['stages']:
            sid=stage['stage_id'];check_packet_coverage(stage['shape'],stage['tile'],packed[f'{sid}:0'])
            entry=next(r for r in report['stages'] if r['stage_id']==sid)
            for candidate in entry['candidates']:
                if candidate['status']=='REJECTED_CAPACITY':continue
                check_packet_coverage(stage['shape'],candidate['tile'],packed[f'{sid}:{candidate["candidate_id"]}'])
        # Fail closed on actual omissions, overwritten output and NULL misuse.
        st=next(s for s in desc['stages'] if s['stage_id']==0);p=packed['0:0']
        for field_name,value in [('offsets',NULL),('geometry',0)]:
            broken=copy.deepcopy(p);broken['tiles'][0][field_name][1]=value
            with self.assertRaises(AssertionError):check_packet_coverage(st['shape'],st['tile'],broken)

    def test_three_mode_build_guard(self):
        source=(OUT/'generated/sw_p3_main.c').read_text()
        guard=re.search(r'#ifndef ATSOFT_THREE_WAY.*?#endif',source,re.S)[0]
        mode=re.search(r'enum \{ MODES=.*?_Static_assert\(MODES==3,[^;]+;',source,re.S)[0]
        code=guard+'\n'+mode+'\n'
        for flags,expected in [([],0),(['-DATSOFT_THREE_WAY=1'],0),(['-DATSOFT_THREE_WAY=0'],1)]:
            result=subprocess.run(['cc','-std=c11','-x','c','-fsyntax-only',*flags,'-'],input=code,text=True,capture_output=True)
            self.assertEqual(result.returncode!=0,bool(expected),result.stderr)

    def test_readonly_half_line_and_shared_dedup(self):
        from parallel_cache_verify import histograms
        name=re.findall(r'\{(\w+),sizeof',(OUT/'generated/constants.inc').read_text())[0]
        windows=[dict(groups={(0,'constant',0):{(0,64)},(1,'constant',0):{(0,64)}})]
        hist,private=histograms(windows,{name:(0x82000020,64)})
        self.assertEqual(int(hist.sum()),2)
        self.assertEqual(int(private.sum()),0)
        self.assertEqual(int(hist[0,0]),1);self.assertEqual(int(hist[0,1]),1)

    def test_layout_all18_and_guard_failure(self):
        a=json.loads((OUT/'reference_plan.txt.inventory.json').read_text())
        b=json.loads((OUT/'layout_plan.txt.inventory.json').read_text())
        self.assertEqual(a['tables'],b['tables']);self.assertEqual(len(b['tables']),18)
        layout=json.loads((OUT/'layout_manifest.json').read_text())
        self.assertLessEqual(tuple(layout['candidate_score']),tuple(layout['baseline_score']))
        self.assertEqual(len(layout['views']),15)
        # Compile the real layout functions with small stand-ins, corrupt a
        # guard, and verify the real checker detects it in both profiles.
        code='''#include <stdint.h>\n#include <stdlib.h>\n#include <string.h>\n#include <assert.h>\n#include <setjmp.h>\n#define YOLOV5NU_CONV_INPUT_SCRATCH 1228800\n#define YOLOV5NU_CONV_OUTPUT_SCRATCH 1228800\ntypedef int8_t elem_t;\nstatic jmp_buf failed;\nstatic void at_fail(const char *s,uint64_t n){(void)s;(void)n;longjmp(failed,1);}\n#include "sw_p3_storage.inc"\n#include "parallel_cache_layout.inc"\nint main(void){for(unsigned profile=0;profile<2;profile++){sw_p3_set_layout(profile);sw_p3_tensor_fill(23);sw_p3_guards_check();activation_arenas[0][-1]=0;if(!setjmp(failed)){sw_p3_guards_check();assert(0);}sw_p3_set_layout(profile);sw_p3_guards_check();}return 0;}\n'''
        src=OUT/'sw_p3_layout_test.c';src.write_text(code);exe=OUT/'sw_p3_layout_test'
        subprocess.run(['cc','-std=gnu11','-O1','-fsanitize=address,undefined','-I'+str(ROOT/'src'),'-I'+str(OUT/'generated'),str(src),'-o',str(exe)],check=True)
        subprocess.run([str(exe)],check=True,env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))

    def test_parser_complete_suite_and_mutations(self):
        text=synthetic_log();r=parse(text)
        self.assertEqual((r['runs'],r['frames']),(48,576))
        for old,new in [('result40=PASS','result40=FAIL'),('run_id=12,','run_id=1,'),
                        ('host_calls=144','host_calls=143'),('end=20','end=9999999'),
                        ('matched=1','matched=2'),('scaling_x1000=2500','scaling_x1000=3000'),
                        ('marker=ALL_COMPLETE','marker=INCOMPLETE')]:
            with self.subTest(old=old),self.assertRaises((InvalidLog,KeyError)):
                parse(text.replace(old,new,1))
        with self.assertRaises(InvalidLog):parse(text+'\nSWP3,FAIL,reason=test')
        with self.assertRaises(InvalidLog):parse(text,{'input_sha256':'wrong'})


def synthetic_log():
    out=['SWP3,BUILD,schema=1,frames=12,profiles=4,passes=2', 'SWP3,IDENTITY,input_sha256=test,model_sha256=model,reference_plan_sha256=ref,plan_sha256=candidate,frozen_lock_sha256=frozen,layout_sha256=layout']
    run=0;names=['reference','layout','cache_plan','cache_plan_gate']
    for p in range(2):
        for profile in (range(4) if p==0 else reversed(range(4))):
            out.append(f'SWP3,PROFILE,pass={p},id={profile},name={names[profile]},plan_hash={"ref" if profile<2 else "candidate"}')
            for mode,lane,matched in [(0,0,0),(1,0,0),(2,0,0),(1,1,0),(1,2,0),(1,0,1)]:
                cycles=400 if mode==2 else 1000;run+=12;devices=[4,4,4] if mode==2 or matched else [12 if d==lane else 0 for d in range(3)]
                key=f'pass={p},profile={profile},mode={mode},serial_lane={lane},matched={matched}'
                out.append(f'SWP3,RUN,{key},cycles={cycles},frames=12,run_id={run},host_calls=144,launches={0 if mode==0 else 12},'+','.join(f'device{d}_frames={v}' for d,v in enumerate(devices))+',result40=PASS,cache=warm_order_controlled')
                for f in range(12):
                    begin=(f//3 if mode==2 else f)*21
                    out.append(f'SWP3,FRAME,{key},frame={f},lane={f%3 if mode==2 or matched else lane},image={f%3},begin={begin},end={begin+20}')
            out.append(f'SWP3,METRIC,pass={p},profile={profile},serial=1000,parallel=400,scaling_x1000=2500,efficiency_x1000=833')
    out.append('SWP3,PASS,marker=ALL_COMPLETE,result40=bit_exact')
    return '\n'.join(out)


def main():
    results=[]
    def run(name,cmd):
        log=OUT/(name+'.log');completed=subprocess.run(cmd,capture_output=True,text=True)
        log.write_text(completed.stdout+completed.stderr)
        results.append(dict(name=name,status='PASS' if completed.returncode==0 else 'FAIL',command=cmd,log=str(log.relative_to(PROJECT))))
        print(name,results[-1]['status'])
        if completed.returncode:print(log.read_text());return False
        return True
    ok=run('sw_p3_contract',[sys.executable,'-B',__file__,'--unit'])
    ok=run('sw_p3_dispatch',[sys.executable,'-B',__file__,'--dispatch']) and ok
    ok=run('sw_p3_suite',[sys.executable,'-B',str(Path(__file__).with_name('test_suite.py'))]) and ok
    ok=run('sw_p3_ppu',[sys.executable,'-B',str(PROJECT/'tests/model/frontend_v33/test_ppu.py')]) and ok
    e=OUT/'tiling_numerical_evidence.json'
    selected=json.loads((OUT/'tiling_manifest.json').read_text())['enabled_changed_stages']
    if e.exists() and selected:
        results.append(dict(name='alternative_tiling_real_arithmetic',status='PASS',evidence=json.loads(e.read_text()),enabled_stages=selected))
        ok=run('sw_p3_native_cpu_reference',[sys.executable,'-B',str(Path(__file__).with_name('test_cpu_reference.py'))]) and ok
    else:
        results.append(dict(name='alternative_tiling_real_arithmetic',status='BLOCKED',evidence=json.loads(e.read_text()) if e.exists() else None,reason='No candidate layer enabled without full-layer real arithmetic evidence'))
        if (PROJECT/'build/sim/sw_p3_tiling_compact/gold0.hex').exists():
            ok=run('sw_p3_native_cpu_reference',[sys.executable,'-B',str(Path(__file__).with_name('test_cpu_reference.py'))]) and ok
    results.append(dict(name='board_performance',status='BLOCKED',reason='No board programming or measurement requested/executed'))
    (OUT/'verification.json').write_text(json.dumps(dict(schema=1,tests=results,offline_protocol='FUNCTIONAL_PASS' if ok else 'FAIL',numerical_coverage='HOST padding; stage18 native CPU + real DIM32 if enabled; full-model board accuracy not executed'),indent=2)+'\n')
    raise SystemExit(0 if ok else 1)

if __name__=='__main__':
    if '--unit' in sys.argv:unittest.main(argv=[sys.argv[0]])
    elif '--dispatch' in sys.argv:dispatch()
    else:main()
