#!/usr/bin/env python3
"""Actual v34 scheduler, boundary timers, MPV3 driver and reports on fake IO.

The model maths and hardware timing are not simulated. All timing is synthetic.
"""
import ast
import json
import os
from pathlib import Path
import re
import subprocess
import unittest
import sys
PROJECT=Path(__file__).resolve().parents[3]
ROOT=PROJECT/"sw/benchmarks/frontend"
OUT=PROJECT/"build/firmware/frontend-v34"
OUT.mkdir(parents=True,exist_ok=True)
sys.path.insert(0,str(ROOT/"scripts"))

from prepare import function
from analyze_log import parse, report

source=(ROOT/'src/boundary_main.c').read_text()
original=(PROJECT/'tests/model/frontend_v33/test_dispatch.py').read_text()
tree=ast.parse(original)
harness=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and
             any(isinstance(t,ast.Name) and t.id=='harness' for t in n.targets))
harness=harness.replace('@FRAME_CONSTANTS@','enum {FRAMES=12,LANES=3};')
harness=harness.replace('commands[26]','commands[10870]')
harness=harness.replace('ticks<10000000','ticks<1000000000')
harness=harness.replace('static uint64_t ticks,hw_due[3],ppu_due[3];', '''
static uint64_t ticks=200000,hw_due[3],ppu_due[3];
static volatile uint64_t irq_first_cycle,irq_count,irq_cycles;
static unsigned run_frames=FRAMES,short_window_pass;
static unsigned char activation_arenas[8],memory_pad[8],memory_intermediate[8],conv_input_scratches[8],conv_output_scratches[8];
static unsigned arg_case,selector,perf_enabled,perf_valid,perf_sequence,perf_command,perf_pending;
static uint64_t perf_live[16][32],perf_frozen[16][32],counter_begin[3],counter_snap[3];
static const unsigned client_map[3]={1,2,0};
''')
harness=harness.replace('static void text(const char *s){report_lines+=!strcmp(s,"ATSOFT1,FRAME_END,executor=");mismatch_lines+=!strcmp(s,",marker=MISMATCH\\n");}',
'''static void text(const char *s){fputs(s,stdout);}
static void number(uint64_t v){printf("%llu",(unsigned long long)v);}''')
harness=harness.replace('static void field(const char *s,uint64_t v){(void)s;(void)v;}',
                       'static void field(const char *s,uint64_t v){fputs(s,stdout);number(v);}')
harness=harness.replace('hw_state[d]=hw_host[d]<12?2:3;irq_event=1;', '''
    hw_state[d]=hw_host[d]<12?2:3;
    if(!irq_event){irq_first_cycle=ticks;irq_count++;irq_cycles+=3;}irq_event=1;''')
harness=harness.replace('static uint64_t clock_cycle(void){ticks+=17;advance();return ticks;}', '''
static void perf_advance(unsigned n){
 for(unsigned b=0;b<16;b++){
   if(perf_enabled){perf_live[b][0]+=n*(b>=9&&b<=11?3:1);if(b==5||b==6)perf_live[b][7]+=n*4;}
   perf_live[b][31]=ticks*(b>=9&&b<=11?3:1);
 }
}
static uint64_t clock_cycle(void){ticks+=17;perf_advance(17);advance();return ticks;}
''')
def replace_function(text,prefix,new):
    old=function(text,prefix)
    assert text.count(old)==1
    return text.replace(old,new)
harness=replace_function(harness,'static uint64_t gf_status(',r'''
static uint64_t gf_status(unsigned d){
 clock_cycle();unsigned st=hw_state[d];
 if(inject==1&&!injected){injected=1;return GF_FAULT;}
 uint64_t low=st==0?GF_START_READY:st==1?(GF_OWNED|GF_GEMMINI_BUSY|GF_FENCE_BUSY):st==2?(GF_OWNED|GF_HOST_WAIT):GF_DONE;
 return (UINT64_C(0x20000)<<32)|low|(st==1?(UINT64_C(2)<<16):0);
}
''')
harness=replace_function(harness,'static uint64_t gf_read(',r'''
static uint64_t gf_read(unsigned d,unsigned q,unsigned unused){
 (void)unused;clock_cycle();unsigned st=hw_state[d];
 if(q==4)return st==2?3:st==3?4:st==1?(hw_due[d]>ticks+40?1:2):0;
 if(bound[d]<0){assert(q==2);return 0;}struct Frame *f=&frames[bound[d]];
 unsigned cursor=st==3?10870:hw_host[d]*836+(st==2?835:400);
 if(q==3){assert(st==2);if(inject==2&&!injected){injected=1;return 99;}return hw_host[d]+1;}
 if(q==2)return ((uint64_t)(st==3?10870:0)<<32)|(cursor-(inject==3));
 if(q==1)return ((uint64_t)(st==3?10870:cursor)<<32)|(st==3?10478:hw_host[d]*806);
 abort();
}
''')
harness=replace_function(harness,'static uint64_t gf_launch(',r'''
static uint64_t gf_launch(unsigned d,const GfCommand *p,unsigned n,unsigned frame,unsigned timeout,int irq){
 (void)frame;(void)timeout;assert(d<(executor==2?3:1)&&irq&&bound[d]>=0&&hw_state[d]==0&&n==10870&&p==frames[bound[d]].plan->commands);
 hw_state[d]=1;hw_host[d]=0;hw_due[d]=ticks+30000+(seed+d*13+next_frame*7)%1900;return 0;
}
''')
harness=harness.replace('hw_due[d]=ticks+(1+(seed*7+d*11+tag)%23)*31;',
                        'hw_due[d]=ticks+20000+(seed*7+d*11+tag)%2300;')
harness=replace_function(harness,'static unsigned ppu_begin(',r'''
static unsigned ppu_begin(unsigned d,unsigned run){
 assert(d<(executor==2?3:1)&&run==(short_window_pass?1000+short_window_pass*FRAMES:executor*FRAMES)+current_frame+1);
 unsigned slot=slot_next[d]++%2;assert(!slot_live[d][slot]);slot_live[d][slot]=1;
 ppu_mask[d]=ppu_done[d]=0;ppu_due[d]=0;return slot;
}
''')
harness=harness.replace('static void ppu_service(void){\n  clock_cycle();',
    'static void ppu_service(void){\n  uint64_t begin=ticks;unsigned pending=ppu_due[0]||ppu_due[1]||ppu_due[2];\n  clock_cycle();')
harness=harness.replace('slot_live[d][frames[f].slot]=0;\n  }\n}',
    'slot_live[d][frames[f].slot]=0;\n  }\n  if(pending)ppu_service_cycles+=ticks-begin;\n}')
io=r'''
static uint32_t mmio_read32(uintptr_t address){
 unsigned off=address-0x02020000;clock_cycle();
 uint64_t value=0;
 if(off==0||off==4)value=arg_case==3?0:UINT64_C(0x4d50563300010000)+(arg_case==11?2:(arg_case==1||arg_case==2));
 else if(off==0x10||off==0x14){
  if(perf_pending&&!--perf_pending){
   if(perf_command==3){memset(perf_live,0,sizeof(perf_live));perf_enabled=perf_valid=0;}
   if(perf_command==1)perf_enabled=1;
   if(perf_command==2)perf_enabled=0;
   if(perf_command==4){memcpy(perf_frozen,perf_live,sizeof(perf_live));perf_valid=1;perf_sequence+=arg_case==6?2:1;}
  }
  value=(arg_case==8&&perf_sequence?0:8)|(perf_pending?1:0)|(perf_enabled?2:0)|(perf_valid?4:0);
 }else if(off==0x18||off==0x1c)value=perf_sequence;
 else if(off==0x20)value=selector+(arg_case==5);
 else if(off==0x28||off==0x2c){value=perf_frozen[selector/32][selector%32];if(arg_case==10&&off==0x2c&&selector==13*32-1)perf_sequence++;}
 else if(off==0x40)value=100000000;
 else if(off==0x48)value=300000000;
 else if(off==0x50)value=arg_case==1?14:arg_case==2||arg_case==11?16:13;
 else if(off==0x58)value=arg_case==11?4:2;
 else if(off==0x60)value=512;
 else if(off==0x68)value=32;
 return (off&4)?value>>32:value;
}
static void mmio_write32(uintptr_t address,uint32_t value){
 unsigned off=address-0x02020000;clock_cycle();
 if(off==8){assert(!perf_pending);perf_command=value;perf_pending=2;}
 else if(off==0x20){assert(value<512);selector=value;}
 else abort();
}
static void direct(const GfCommand *c){
 clock_cycle();if(perf_enabled&&(c->control>>8)==2){unsigned b=client_map[current_lane];perf_live[b][1]++;perf_live[b][4]+=64;}
}
'''
boundary=(ROOT/'src/boundary_diag.inc').read_text()
memory=(ROOT/'src/memory_diag.inc').read_text()
memory=replace_function(memory,'static uint32_t memory_counter_access(',r'''
static uint32_t memory_counter_access(unsigned lane,uint32_t config){
 assert(hw_state[lane]==0);clock_cycle();
 if(config==1)counter_begin[lane]=ticks;
 if(config==4)counter_snap[lane]=ticks-counter_begin[lane];
 return arg_case==4?0:(uint32_t)(counter_snap[lane]/(2+(config>>4&7)));
}
''')
memory=replace_function(memory,'static __attribute__((noinline)) uint32_t memory_safe_probe(',r'''
static uint32_t memory_safe_probe(unsigned off){if(arg_case==9){memory_probe_failed=1;return 0;}return mmio_read32(0x02020000+off);}
''')
functions='\n'.join(function(source,x) for x in ('static void execute_host(','static void admit(',
    'static void graph_done(','static void finish(','static void serial_batch(','static void parallel_batch(',
    'static void prepare_batch(','static const char *executor_name(','static unsigned report('))
functions=re.sub(r'__asm__ volatile\(.*?\);','((void)0);',functions,flags=re.S)

def reporting_parts():
    at=source.index('    text("YOLO32_FRONTEND,BUILD,')
    start=source.rfind('#if YOLO32_FRONTEND_DIAG',0,at);end=source.index('#endif',at)+6
    boot=source[start:end]
    start=source.index('        text("ATSOFT1,MODE,executor=")')
    marker='        text(",ppu=hardware,comparison_outside_timing=1\\n");'
    mode=source[start:source.index(marker,start)+len(marker)]
    start=source.index('    field("ATSOFT1,PERF,direct_cycles=",')
    marker='    text(",ppu_results=bit_exact,marker=ALL_COMPLETE\\n");'
    perf='#if ATSOFT_THREE_WAY\n'+source[start:source.index(marker,start)+len(marker)]
    start=source.index('    text("ATSOFT1,DIAG_COMPLETE,')
    end=source.index('    for(;;)',start)
    return boot,mode,perf,source[start:end]

boot,mode,perf,complete=reporting_parts()
main=r'''
int main(int argc,char **argv){
 arg_case=argc>1?atoi(argv[1]):0;
 seed=argc>2?atoi(argv[2]):0;
 if(setjmp(failed)){
  fprintf(stderr,"expected-or-fatal:%s\n",reason);
  const char *expected=arg_case==5?"memory_selector":arg_case==6?"memory_snapshot":arg_case==7?"counter_on_owned_lane":arg_case==8?"memory_external_reset_or_invalid_command":arg_case==10?"memory_snapshot_changed":"unexpected";
  return strcmp(reason,expected)!=0;
 }
 if(arg_case==7){hw_state[0]=1;memory_counter_begin(0,0);return 1;}
 for(unsigned d=0;d<3;d++){
  bound[d]=-1;
  for(unsigned s=0;s<2;s++)for(unsigned im=0;im<3;im++){
   struct Plan *p=&plans[d][s][im];unsigned pos=0;
   for(unsigned tag=0;tag<13;tag++){
    for(unsigned k=0;k<806;k++)p->commands[pos++]=gf_raw(2,0,0,0);
    for(unsigned k=0;k<29+(tag<3);k++)p->commands[pos++]=gf_drain();
    if(tag<12)p->commands[pos++]=gf_host(tag+1);
   }
   assert(pos==10870);p->count=pos;p->raw=10478;p->host_count=12;
   for(unsigned h=0;h<12;h++)p->hosts[h]=(struct Host){.kind=h<6?HOST_PAD:HOST_HEAD,.head=h%6,.phase=h<6?75+h/2:100+h};
  }
 }
 @BOOT@
 memory_init();memory_calibrate();
 uint64_t cycles[3];
 for(executor=0;executor<3;executor++){
  unsigned active_lanes=executor==2?3:1;
  run_frames=12;prepare_batch();memory_whole_begin(executor);batch_begin=clock_cycle();
  if(executor)parallel_batch(active_lanes);else serial_batch();
  cycles[executor]=clock_cycle()-batch_begin;memory_finish(executor,0,cycles[executor]);
  assert(completed==12&&host_calls==144);assert(!report(executor));
  boundary_report(executor);memory_counter_report(executor,0,12);
  @MODE@
 }
 @PERF@
 memory_short_passes();
 @COMPLETE@
 return 0;
}
'''
for k,v in (('BOOT',boot),('MODE',mode),('PERF',perf),('COMPLETE',complete)):main=main.replace('@'+k+'@',v)
out=OUT/'boundary_test.c';exe=OUT/'boundary_test'
out.write_text(harness+io+boundary+memory+functions+main)
subprocess.run(['cc','-O1','-g','-std=gnu11','-fsanitize=address,undefined','-DYOLO32_FRONTEND_DIAG=2',
    '-I'+str(ROOT/'include'),str(out),'-o',str(exe)],check=True)

class Boundary(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.logs={}
        for case in (*range(5),11):
            cls.logs[case]=subprocess.check_output([str(exe),str(case)],text=True,timeout=30,
                env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))
            (OUT/f'boundary_synthetic_case{case}.log').write_text(cls.logs[case])

    def test_actual_scheduler_memory_and_report(self):
        for case,text in self.logs.items():
            with self.subTest(case=case):
                errors,sessions=parse(text);self.assertEqual(errors,[])
                self.assertEqual(len(sessions),1)
                s=sessions[0];self.assertTrue(s['diagnostic_complete'])
                self.assertEqual(len(s['boundary']['rows']),468)
                self.assertEqual(len(s['memory']['windows']),0 if case==3 else 32)
                if case!=3:self.assertEqual(s['memory']['mapping'],dict(valid=1,lane0=1,lane1=2,lane2=0))
                self.assertIn('周期',report(sessions))
                self.assertEqual(sum(not g['valid'] for g in s['memory']['gemmini']),114 if case==4 else 0)

    def test_no_false_completion_from_primary_pass(self):
        text=self.logs[0];at=text.index('ATSOFT1,PASS,')
        self.assertTrue(parse(text[:text.index('\n',at)+1])[0])
        self.assertTrue(parse(text[:text.rfind('ATSOFT1,DIAG_COMPLETE,')])[0])

    def test_four_bank_abi_and_extension_decoding(self):
        errors,sessions=parse(self.logs[11]);self.assertEqual(errors,[])
        memory=sessions[0]['memory']
        self.assertEqual(memory['device']['abi'],0x4d50563300010002)
        for w in memory['windows']:
            self.assertEqual(len(w['blocks']),16)
            for block in (13,14,15):self.assertEqual(w['blocks'][block]['clock_hz'],100000000)
            for bank,block in ((2,14),(3,15)):
                self.assertEqual(w['derived'][f'l2_bank{bank}']['mshr_full_cycles'],w['blocks'][block]['c09'])
                self.assertIn('four_banks_d_accept_cycles',w['derived'][f'l2_bank{bank}'])
            self.assertEqual([c['block'] for c in w['derived']['clients']],[0,1,2,3,4,13])
            self.assertIn('bank3_requests',w['derived']['clients'][0])
        # A four-bank ABI must never accept a two-bank block count or unknown ABI.
        self.assertTrue(parse(self.logs[11].replace('blocks=16','blocks=14',1))[0])
        self.assertTrue(parse(self.logs[11].replace(f"abi={0x4d50563300010002}",'abi=1',1))[0])

    def test_missing_duplicate_and_corrupt_boundary(self):
        lines=self.logs[0].splitlines();i=next(i for i,l in enumerate(lines) if l.startswith('ATSOFT1,BOUNDARY,'))
        for changed in (lines[:i]+lines[i+1:],lines[:i]+[lines[i]]+lines[i:],
                        lines[:i]+[lines[i].replace('raw=806','raw=805')]+lines[i+1:],
                        lines[:i]+[lines[i].replace('tag=1,','tag=13,')]+lines[i+1:]):
            self.assertTrue(parse('\n'.join(changed))[0])

    def test_memory_missing_duplicate_and_bad_sequence(self):
        lines=self.logs[0].splitlines();i=next(i for i,l in enumerate(lines) if l.startswith('ATSOFT1,MEM_BLOCK,'))
        for changed in (lines[:i]+lines[i+1:],lines[:i]+[lines[i]]+lines[i:],
                        lines[:i]+[lines[i].replace('block=0,','block=1,')]+lines[i+1:]):
            self.assertTrue(parse('\n'.join(changed))[0])
        self.assertTrue(parse(self.logs[0].replace('sequence=2,','sequence=9,',1))[0])

    def test_short_pair_and_counter_faults(self):
        text=self.logs[0]
        for old,new in [('target_lane=0','target_lane=1'),('ppu_results=bit_exact','ppu_results=bad'),
                        ('short_window_pairs=13','short_window_pairs=12'),('probe_fault=0','probe_fault=1')]:
            self.assertTrue(parse(text.replace(old,new,1))[0])
        lines=text.splitlines();i=next(i for i,l in enumerate(lines) if l.startswith('ATSOFT1,GEM_COUNTER,'))
        self.assertTrue(parse('\n'.join(lines[:i]+lines[i+1:]))[0])

    def test_driver_rejects_selector_sequence_reset_and_owned_counter(self):
        for case in (5,6,7,8,10):
            subprocess.run([str(exe),str(case)],check=True,timeout=30,stdout=subprocess.DEVNULL,
                           env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))

    def test_unmapped_probe_has_explicit_missing_coverage(self):
        text=subprocess.check_output([str(exe),'9'],text=True,timeout=30,
                                     env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))
        errors,sessions=parse(text);self.assertEqual(errors,[])
        self.assertEqual(sessions[0]['memory']['device']['probe_fault'],1)
        self.assertEqual(sessions[0]['memory']['windows'],[])

    def test_asynchronous_schedule_seeds(self):
        for seed in range(1,21):
            text=subprocess.check_output([str(exe),'0',str(seed)],text=True,timeout=30,
                                         env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))
            self.assertEqual(parse(text)[0],[],seed)

    def test_preserved_v33_logs_and_mixed_boots(self):
        old=PROJECT/'tests/log/uart.log'
        if old.exists():
            text=old.read_text();self.assertEqual(parse(text)[0],[])
            self.assertEqual(parse(text+self.logs[0])[0],[])
        self.assertEqual(parse(self.logs[0][:-300]+'\n'+self.logs[1],latest=True)[0],[])

if __name__=='__main__':unittest.main(verbosity=2)
