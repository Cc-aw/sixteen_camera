#!/usr/bin/env python3
"""Exercise the actual board dispatch functions with delayed fake devices.

This tests software ordering, not accelerator arithmetic or RTL timing.
"""
from pathlib import Path
import sys
PROJECT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT / 'sw/benchmarks/frontend/scripts'))
sys.path.insert(0, str(PROJECT / 'tools/analyze/frontend'))

import re
import os
import subprocess
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
from prepare import function, ROOT, OUT

source=(ROOT/'src/main.c').read_text()
functions='\n'.join(function(source,begin) for begin in (
    'static void execute_host(', 'static void admit(', 'static void graph_done(',
    'static void finish(', 'static void parallel_batch(',
    'static const char *executor_name(', 'static unsigned report('))
functions=re.sub(r'__asm__ volatile\(.*?\);','((void)0);',functions,flags=re.S)
harness=r'''
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <assert.h>
#include "gemmini_frontend.h"
#define ATSOFT_THREE_WAY 1
@FRAME_CONSTANTS@
enum {HOST_PAD=1,HOST_HEAD=2};
struct Host {unsigned kind,phase,head;const int8_t *src;int8_t *dst;int h,w,c;};
struct Plan {GfCommand commands[26];struct Host hosts[12];unsigned count,host_count,raw;};
struct Frame {unsigned device,image,slot,host_next,state;struct Plan *plan;uint64_t begin,end,graph_end;};
struct PpuResult {unsigned count,words[10][4];};
static struct Plan plans[3][2][3];
static struct Frame frames[FRAMES];
static struct PpuResult output[3][FRAMES],ppu_result[3];
static unsigned ppu_done[3],use[3],next_frame,completed,held_events,rr,irq_event;
static unsigned current_phase,current_lane,current_frame,executor,active_lanes;
static int bound[3];
static uint64_t batch_begin,launches,host_calls,pad_cycles,triple_samples,busy_samples,last_sample;
static uint64_t host_service_cycles,head_publish_cycles,ppu_service_cycles,host_max_cycles;
static unsigned host_max_kind,host_max_phase;
static unsigned seed,slot_next[3],hw_host[3],hw_state[3],ppu_mask[3],cpu_busy;
static unsigned slot_live[3][2],hosts_seen[FRAMES],injected,inject;
static uint64_t ticks,hw_due[3],ppu_due[3];
static jmp_buf failed;static const char *reason;
static unsigned report_lines,mismatch_lines;
static void text(const char *s){report_lines+=!strcmp(s,"ATSOFT1,FRAME_END,executor=");mismatch_lines+=!strcmp(s,",marker=MISMATCH\n");}
static void field(const char *s,uint64_t v){(void)s;(void)v;}
static void at_fail(const char *s,uint64_t v) __attribute__((noreturn));
static void at_fail(const char *s,uint64_t v){(void)v;reason=s;longjmp(failed,1);}
static void require(uint64_t v,const char *s){if(v)at_fail(s,v);}
static void advance(void){
  for(unsigned d=0;d<3;d++)if(hw_state[d]==1&&ticks>=hw_due[d]){
    hw_state[d]=hw_host[d]<12?2:3;irq_event=1;
  }
}
static uint64_t clock_cycle(void){ticks+=17;advance();return ticks;}
static unsigned gf_pending(void){clock_cycle();unsigned m=0;for(unsigned d=0;d<3;d++)if(hw_state[d]>=2)m|=1U<<d;return m;}
static uint64_t gf_status(unsigned d){assert(bound[d]>=0);if(inject==1&&!injected){injected=1;return GF_FAULT;}return hw_state[d]==2?GF_HOST_WAIT:GF_DONE;}
static uint64_t gf_read(unsigned d,unsigned q,unsigned unused){
  (void)unused;struct Frame *f=&frames[bound[d]];
  if(q==3){assert(hw_state[d]==2);if(inject==2&&!injected){injected=1;return 99;}return hw_host[d]+1;}
  if(q==2)return ((uint64_t)f->plan->count<<32)|(f->plan->count-(inject==3));
  if(q==1)return ((uint64_t)f->plan->count<<32)|f->plan->raw;
  abort();
}
static uint64_t gf_ack(unsigned d,uint64_t a,uint64_t b){(void)a;(void)b;assert(hw_state[d]==3&&hw_host[d]==12);hw_state[d]=0;return 0;}
static void gf_publish(void){clock_cycle();}
static uint64_t gf_launch(unsigned d,const GfCommand *p,unsigned n,unsigned frame,unsigned timeout,int irq){
  (void)frame;(void)timeout;assert(d<active_lanes&&irq&&bound[d]>=0&&hw_state[d]==0&&n==26&&p==frames[bound[d]].plan->commands);
  hw_state[d]=1;hw_host[d]=0;hw_due[d]=ticks+(1+(seed+d*13+next_frame*7)%19)*21;return 0;
}
static uint64_t gf_resume(unsigned d,unsigned tag,unsigned unused){
  (void)unused;assert(hw_state[d]==2&&tag==hw_host[d]+1&&frames[bound[d]].host_next==tag);
  hosts_seen[bound[d]]++;hw_host[d]++;hw_state[d]=1;hw_due[d]=ticks+(1+(seed*7+d*11+tag)%23)*31;return 0;
}
static uint64_t gf_global_read(unsigned q){assert(q==1);unsigned m=0;for(unsigned d=0;d<3;d++)if(hw_state[d]==1)m|=1U<<d;return m<<8;}
static void memory_pad_input(const int8_t *a,int8_t *b,int h,int w,int c){
  (void)a;(void)b;(void)h;(void)w;(void)c;assert(!cpu_busy);cpu_busy=1;ticks+=1000+(seed%11)*41;advance();cpu_busy=0;
}
static unsigned ppu_begin(unsigned d,unsigned run){
  assert(d<active_lanes&&run==executor*FRAMES+current_frame+1);
  unsigned slot=slot_next[d]++%2;assert(!slot_live[d][slot]);slot_live[d][slot]=1;
  ppu_mask[d]=ppu_done[d]=0;ppu_due[d]=0;return slot;
}
static void ppu_head(unsigned d,unsigned h){assert(h<6&&!(ppu_mask[d]&(1U<<h)));ppu_mask[d]|=1U<<h;}
static void ppu_graph_done(unsigned d){assert(ppu_mask[d]==63&&hw_state[d]==0);ppu_due[d]=ticks+50+(seed+d*11)%17*100;}
static void ppu_service(void){
  clock_cycle();for(unsigned d=0;d<3;d++)if(ppu_due[d]&&ticks>=ppu_due[d]){
    assert(bound[d]>=0);unsigned f=bound[d];ppu_due[d]=0;ppu_done[d]=1;ppu_result[d].count=f%3+1;
    slot_live[d][frames[f].slot]=0;
  }
}
static void watchdog(void){assert(ticks<10000000);clock_cycle();}
'''
tail=r'''
int main(void){
 for(active_lanes=1;active_lanes<=3;active_lanes+=2)
 for(seed=0;seed<100;seed++)for(inject=0;inject<4;inject++){
  executor=active_lanes==1?1:2;
  memset(plans,0,sizeof(plans));memset(frames,0,sizeof(frames));memset(output,0,sizeof(output));memset(use,0,sizeof(use));
  memset(slot_live,0,sizeof(slot_live));memset(slot_next,0,sizeof(slot_next));memset(hw_state,0,sizeof(hw_state));
  memset(ppu_done,0,sizeof(ppu_done));memset(ppu_due,0,sizeof(ppu_due));memset(hosts_seen,0,sizeof(hosts_seen));
  ticks=next_frame=completed=held_events=rr=irq_event=launches=host_calls=pad_cycles=triple_samples=last_sample=injected=0;
  busy_samples=host_service_cycles=head_publish_cycles=ppu_service_cycles=host_max_cycles=0;
  host_max_kind=host_max_phase=0;
  for(unsigned d=0;d<3;d++){bound[d]=-1;for(unsigned s=0;s<2;s++)for(unsigned i=0;i<3;i++){
    struct Plan *p=&plans[d][s][i];p->count=26;p->raw=14;p->host_count=12;
    for(unsigned h=0;h<12;h++)p->hosts[h]=(struct Host){.kind=h<6?HOST_PAD:HOST_HEAD,.head=h%6};
  }}
  if(!setjmp(failed)){
    parallel_batch(active_lanes);assert(!inject);assert(completed==FRAMES&&launches==FRAMES&&host_calls==FRAMES*12);
    for(unsigned d=0;d<LANES;d++)assert(use[d]==(d<active_lanes?FRAMES/active_lanes:0)&&bound[d]<0);
    for(unsigned f=0;f<FRAMES;f++)assert(frames[f].state==3&&frames[f].device<active_lanes&&hosts_seen[f]==12&&output[executor][f].count==f%3+1);
#if YOLO32_FRONTEND_DIAG
    assert(host_service_cycles>=pad_cycles&&head_publish_cycles>0&&host_max_cycles>0);
    for(unsigned f=0;f<FRAMES;f++)assert(frames[f].begin<frames[f].graph_end&&frames[f].graph_end<frames[f].end);
#else
    assert(!host_service_cycles&&!head_publish_cycles&&!host_max_cycles);
#endif
  }else{assert(inject&&completed<FRAMES);assert(!strcmp(reason,inject==1?"frontend_fault":inject==2?"host_sequence":"frontend_incomplete"));}
 }
 memset(output,0,sizeof(output));
 for(unsigned f=0;f<FRAMES;f++){
   output[0][f].count=f%3;
   for(unsigned i=0;i<10;i++)for(unsigned j=0;j<4;j++)output[0][f].words[i][j]=f*40+i*4+j;
 }
 for(unsigned mode=1;mode<3;mode++){
   memcpy(output[mode],output[0],sizeof(output[0]));
   report_lines=mismatch_lines=0;assert(report(mode)==0&&report_lines==FRAMES&&!mismatch_lines);
   for(unsigned i=0;i<10;i++)for(unsigned j=0;j<4;j++){
     output[mode][5].words[i][j]^=1;report_lines=mismatch_lines=0;
     assert(report(mode)==1&&report_lines==FRAMES&&mismatch_lines==1);output[mode][5].words[i][j]^=1;
   }
   output[mode][8].count++;assert(report(mode)==1);output[mode][8].count--;
 }
 assert(!strcmp(executor_name(0),"direct_serial")&&!strcmp(executor_name(1),"frontend_serial")&&!strcmp(executor_name(2),"frontend_parallel"));
 puts("ATSOFT1,DISPATCH_PASS,seeds=100,lane_counts=1+3,balanced_allocation=1,coalesced_events=1,host_pause_resume=1,ppu_delay=1,slot_reuse=1,fault_cases=600");
 puts("ATSOFT1,REPORT_PASS,frontend_modes=2,result_words=all40,count_checked=1,mismatch_detected=1");
}
'''
harness=harness.replace('@FRAME_CONSTANTS@',re.search(r'enum \{ FRAMES=.*?\};',source).group())
out=OUT/'dispatch_test.c';out.write_text(harness+functions+tail)
exe=OUT/'dispatch_test'
for diagnostic in (0,1):
    subprocess.run(['cc','-O1','-g','-std=gnu11','-fsanitize=address,undefined',
        f'-DYOLO32_FRONTEND_DIAG={diagnostic}','-I'+str(ROOT/'include'),str(out),'-o',str(exe)],check=True)
    subprocess.run([str(exe)],check=True,timeout=30,env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))
