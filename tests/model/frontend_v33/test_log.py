#!/usr/bin/env python3
"""Exercise strict UART accounting and the actual C reporting statements.

Synthetic timing/results verify the reporting contract, not accelerator math.
"""
import copy
from pathlib import Path
import sys
PROJECT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT / 'sw/benchmarks/frontend/scripts'))
sys.path.insert(0, str(PROJECT / 'tools/analyze/frontend'))

import subprocess
import tempfile
import unittest

from analyze_log import parse, report
from prepare import ROOT, function

def record(family,kind,**values):
    return family+','+kind+','+','.join(f'{k}={v}' for k,v in values.items())

def fixture(diagnostic=0):
    lines=[record('YOLO32_FRONTEND','BUILD',schema=1,version=33,diagnostics=diagnostic,
        frames=12,modes=3,clock_hz=100000000,control_abi=131072,entries_per_frame=10870,
        raw_per_frame=10478,drains_per_frame=380,hosts_per_frame=12,ppu='hardware')]
    names=('direct_serial','frontend_serial','frontend_parallel')
    cycles=(1200000,1320000,500000)
    for index,name in enumerate(names):
        lanes=3 if index==2 else 1
        for f in range(12):
            device=f%3 if lanes==3 else 0
            begin=100+(f//3*100000+device*50 if lanes==3 else f*(100000 if index else 90000))
            duration=80000 if lanes==3 else 70000 if index else 60000
            row=dict(executor=name,frame=f,device=device,image=f%3,slot=(f//lanes)%2,
                begin_cycles=begin,end_cycles=begin+duration,frame_cycles=duration,host_calls=12,marker='COMPLETE')
            if diagnostic:row['graph_done_cycles']=begin+duration*3//4
            lines.append(record('ATSOFT1','FRAME_END',**row))
        row=dict(executor=name,frames=12,devices=lanes,cycles=cycles[index],
            device0_frames=12 if lanes==1 else 4,device1_frames=0 if lanes==1 else 4,
            device2_frames=0 if lanes==1 else 4,launches=12 if index else 0,host_calls=144,
            cpu_pad_cycles=1200,irqs=80 if index else 0,irq_body_cycles=16000 if index else 0,
            triple_samples=4 if lanes==3 else 0,busy_samples=cycles[index]//100000 if index else 0,
            diagnostics=diagnostic,ppu='hardware',comparison_outside_timing=1)
        if diagnostic:row.update(host_service_cycles=5000,head_publish_cycles=2000,
            ppu_service_cycles=3000,host_max_cycles=100,host_max_kind=1,host_max_phase=74)
        lines.append(record('ATSOFT1','MODE',**row))
    a,b,c=cycles
    lines.append(record('ATSOFT1','PERF',direct_cycles=a,frontend_single_cycles=b,
        frontend_parallel_cycles=c,direct_to_single_x1000=a*1000//b,
        frontend_scaling_x1000=b*1000//c,direct_to_parallel_x1000=a*1000//c))
    lines.append(record('ATSOFT1','PASS',modes=3,frames_per_mode=12,
        direct_vs_frontend_single='bit_exact',direct_vs_frontend_parallel='bit_exact',
        device0_frames=4,device1_frames=4,device2_frames=4,ppu='hardware',pad_hosts_per_frame=6,
        head_hosts_per_frame=6,independent_accuracy='not_proven',ppu_results='bit_exact',marker='ALL_COMPLETE'))
    return '\n'.join(lines)+'\n'

class Contract(unittest.TestCase):
    def test_complete_formal_and_diag(self):
        for diag in (0,1):
            with self.subTest(diagnostics=diag):
                errors,sessions=parse(fixture(diag));self.assertEqual(errors,[])
                self.assertEqual(sessions[0]['ratios']['direct_to_parallel'],2.4)
                self.assertEqual(sessions[0]['ratios']['frontend_scaling'],2.64)
                self.assertIn('周期',report(sessions))

    def test_interval_integral_and_refill(self):
        errors,sessions=parse(fixture());self.assertEqual(errors,[])
        mode=sessions[0]['modes'][2];d=mode['derived']
        self.assertEqual(sum(d['ownership_overlap_cycles']),500000)
        self.assertEqual(sum(i*v for i,v in enumerate(d['ownership_overlap_cycles'])),12*80000)
        self.assertEqual(d['ownership_overlap_cycles'][3],319600)
        self.assertEqual([l['observed_refill_gap_cycles'] for l in d['lanes']],[60000]*3)

    def test_missing_duplicate_and_truncated(self):
        lines=fixture().splitlines()
        for changed in (lines[:8]+lines[9:],lines[:3]+[lines[2]]+lines[3:],lines[:-1],lines[:-14]):
            with self.subTest(lines=len(changed)):self.assertTrue(parse('\n'.join(changed))[0])

    def test_corrupt_fields_and_false_success(self):
        text=fixture()
        mutations=[
            ('schema=1','schema=2'),('version=33','version=32'),('control_abi=131072','control_abi=0'),
            ('host_calls=12,marker','host_calls=11,marker'),('image=0','image=2'),('slot=0','slot=2'),
            ('begin_cycles=100','begin_cycles=70000'),('frame_cycles=60000','frame_cycles=60001'),
            ('device1_frames=4','device1_frames=5'),('launches=12','launches=11'),
            ('triple_samples=4','triple_samples=9999'),('direct_to_parallel_x1000=2400','direct_to_parallel_x1000=2401'),
            ('marker=COMPLETE','marker=MISMATCH'),('ppu_results=bit_exact','ppu_results=unverified'),
            ('frames_per_mode=12','frames_per_mode=11'),('comparison_outside_timing=1','comparison_outside_timing=0'),
        ]
        for a,b in mutations:
            with self.subTest(field=a):
                self.assertIn(a,text);self.assertTrue(parse(text.replace(a,b,1))[0])

    def test_unbalanced_or_overlap(self):
        lines=fixture().splitlines()
        i=next(i for i,l in enumerate(lines) if 'FRAME_END,executor=frontend_parallel,frame=1,' in l)
        lines[i]=lines[i].replace('device=1','device=0')
        self.assertTrue(parse('\n'.join(lines))[0])

    def test_diag_contract(self):
        text=fixture(1)
        for a,b in [('graph_done_cycles=45100','graph_done_cycles=90000'),
                    ('host_service_cycles=5000','host_service_cycles=100'),
                    ('host_max_kind=1','host_max_kind=3'),('host_max_phase=74','host_max_phase=165')]:
            with self.subTest(field=a):
                self.assertIn(a,text);self.assertTrue(parse(text.replace(a,b,1))[0])
        self.assertTrue(parse(text.replace('diagnostics=1','diagnostics=0',1))[0])

    def test_duplicate_and_unknown_fields(self):
        for suffix in (',frame=0',',word_errors=1',',unexpected=1'):
            lines=fixture().splitlines();lines[1]+=suffix
            self.assertTrue(parse('\n'.join(lines))[0])

    def test_firmware_failure_and_old_logs(self):
        self.assertTrue(parse(fixture()+'ATSOFT1,FAIL,reason=bad,value=1\n')[0])
        self.assertTrue(parse('ATSOFT1,PASS,marker=ALL_COMPLETE\n')[0])

    def test_multiple_boots_keep_diagnostics_separate(self):
        errors,sessions=parse(fixture()+fixture(1));self.assertEqual(errors,[])
        self.assertEqual([s['build']['diagnostics'] for s in sessions],[0,1])
        errors,sessions=parse('\n'.join(fixture().splitlines()[:-1])+'\n'+fixture(1),latest=True)
        self.assertEqual(errors,[]);self.assertEqual(len(sessions),1)

    def test_real_c_report_and_summaries(self):
        source=(ROOT/'src/main.c').read_text()
        funcs='\n'.join(function(source,k) for k in ('static const char *executor_name(', 'static unsigned report('))
        at=source.index('    text("YOLO32_FRONTEND,BUILD,')
        header_start=source.rfind('#if YOLO32_FRONTEND_DIAG',0,at)
        header_end=source.index('#endif',at)+len('#endif')
        boot=source[header_start:header_end]
        mode_start=source.index('        text("ATSOFT1,MODE,executor=")')
        end_marker='        text(",ppu=hardware,comparison_outside_timing=1\\n");'
        mode_end=source.index(end_marker,mode_start)+len(end_marker)
        mode=source[mode_start:mode_end]
        perf_start=source.index('    field("ATSOFT1,PERF,direct_cycles=",')
        pass_end='    text(",ppu_results=bit_exact,marker=ALL_COMPLETE\\n");'
        perf_end=source.index(pass_end,perf_start)+len(pass_end)
        perf='#if ATSOFT_THREE_WAY\n'+source[perf_start:perf_end]
        harness=r'''
#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>
enum {FRAMES=12};
struct Frame {unsigned device,image,slot,host_next,state;void *plan;uint64_t begin,end,graph_end;};
struct PpuResult {unsigned count,words[10][4];};
static struct Frame frames[FRAMES];
static struct PpuResult output[3][FRAMES];
static unsigned executor,use[3];
static uint64_t batch_begin=100000000,launches,host_calls,pad_cycles,irq_count,irq_cycles,triple_samples,busy_samples;
static uint64_t host_service_cycles=5000,head_publish_cycles=2000,ppu_service_cycles=3000,host_max_cycles=100;
static unsigned host_max_kind=1,host_max_phase=74;
static void text(const char *s){fputs(s,stdout);}
static void field(const char *s,uint64_t v){printf("%s%" PRIu64,s,v);}
'''
        body=r'''
uint64_t cycles[3]={1200000,1320000,500000};
for(executor=0;executor<3;executor++){
 unsigned active_lanes=executor==2?3:1;
 for(unsigned d=0;d<3;d++)use[d]=d<active_lanes?12/active_lanes:0;
 launches=executor?12:0;host_calls=144;pad_cycles=1200;
 irq_count=executor?80:0;irq_cycles=executor?16000:0;
 triple_samples=executor==2?4:0;busy_samples=executor?cycles[executor]/100000:0;
 for(unsigned f=0;f<12;f++){
  unsigned d=active_lanes==3?f%3:0;
  uint64_t begin=100+(active_lanes==3?f/3*100000+d*50:f*(executor?100000:90000));
  uint64_t duration=active_lanes==3?80000:executor?70000:60000;
  frames[f]=(struct Frame){.device=d,.image=f%3,.slot=(f/active_lanes)%2,.host_next=12,
    .begin=batch_begin+begin,.end=batch_begin+begin+duration,.graph_end=batch_begin+begin+duration*3/4};
 }
 if(report(executor))return 1;
@MODE@
}
@PERF@
return 0;
'''.replace('@MODE@',mode).replace('@PERF@',perf)
        with tempfile.TemporaryDirectory(prefix='yolo32_frontend_report_') as temp:
            path=Path(temp);c=path/'report.c';exe=path/'report'
            c.write_text(harness+funcs+'\nint main(void){\n'+boot+'\n'+body+'}\n')
            for diag in (0,1):
                subprocess.run(['cc','-std=c11','-DATSOFT_THREE_WAY=1',f'-DYOLO32_FRONTEND_DIAG={diag}',str(c),'-o',str(exe)],check=True)
                text=subprocess.check_output([str(exe)],text=True)
                errors,sessions=parse(text)
                self.assertEqual(errors,[])
                self.assertEqual(len(sessions[0]['modes'][2]['frames']),12)
                self.assertEqual(sessions[0]['build']['diagnostics'],diag)

if __name__=='__main__':
    unittest.main(verbosity=2)
