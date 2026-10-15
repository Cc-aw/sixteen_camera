#!/usr/bin/env python3
"""Run the actual PPU adapter and native slot/publication/queue drivers."""
from pathlib import Path
import sys
PROJECT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(PROJECT / 'sw/benchmarks/frontend/scripts'))
sys.path.insert(0, str(PROJECT / 'tools/analyze/frontend'))

import os
import subprocess
from prepare import ROOT as root, OUT, SNAP
out=OUT/'ppu_test';out.mkdir(exist_ok=True)
(out/'mmio.h').write_text('''#ifndef TEST_MMIO_H
#define TEST_MMIO_H
#include <stdint.h>
uint32_t fake_read(uintptr_t);
void fake_write(uintptr_t,uint32_t);
void at_io_commit(void);
static inline uint32_t mmio_read32(uintptr_t a){return fake_read(a);}
static inline void mmio_write32(uintptr_t a,uint32_t v){fake_write(a,v);}
static inline void mmio_fence(void){at_io_commit();}
#endif
''')
code=r'''
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <setjmp.h>
#include "platform/platform.h"
static uint64_t tick,ppu_service_cycles;static unsigned inject,selected,generation,enabled,word_select,rd,wr;
static unsigned allocated[6],gens[6],masks[6],regs[0x300/4];
struct R {unsigned bank,gen,count,stream,version,status;uint64_t frame,due;};
static struct R pending[64];
static jmp_buf fail;static const char *reason;
static void at_fail(const char *s,uint64_t v) __attribute__((noreturn));
static void at_fail(const char *s,uint64_t v){(void)v;reason=s;longjmp(fail,1);}
static uint64_t clock_cycle(void){return ++tick;}
static uintptr_t head_address(unsigned d,unsigned s){return 0xb2000000UL+d*0x400000UL+s*0x100000UL;}
#include "ppu.inc"
uint32_t fake_read(uintptr_t a){
 unsigned o=a-POSTPROCESS_DIAG_BASE;assert(o<sizeof(regs)&&!(o&3));tick++;
 struct R *r=&pending[rd];
 switch(o){
 case 0x100:return 0x50505531;case 0x1a0:return 0x50505532;case 0x238:return 0x50505232;
 case 0x200:return enabled;case 0x204:return 0x50505132;case 0x208:return (wr-rd<8)?32:0;
 case 0x1b4:return allocated[selected];case 0x1bc:return gens[selected];
 case 0x1b8:return masks[selected]|(masks[selected]<<8);
 case 0x240:return rd<wr&&tick>=r->due;
 case 0x250:return r->bank;case 0x268:return r->gen;
 case 0x254:return r->count|(r->stream<<10)|(r->status<<14);
 case 0x258:return r->frame;case 0x25c:return r->frame>>32;
 case 0x260:return r->version;case 0x264:return 99;
 case 0x248:return word_select<4*r->count ? (r->version*100+word_select) : 0;
 default:return regs[o/4];
 }
}
void fake_write(uintptr_t a,uint32_t v){
 unsigned o=a-POSTPROCESS_DIAG_BASE;assert(o<sizeof(regs)&&!(o&3));regs[o/4]=v;tick++;
 switch(o){
 case 0x200:enabled=v&1;break;
 case 0x1a8:assert(v<6);selected=v;break;
 case 0x1ac:generation=v;break;
 case 0x1b0:
   if(v==1){assert(!allocated[selected]);allocated[selected]=1;gens[selected]=generation;masks[selected]=0;}
   else if(v&0x3f00){assert(allocated[selected]&&gens[selected]==generation);masks[selected]|=(v>>8)&63;}
   else abort();break;
 case 0x204:
   assert(v==1&&wr<64&&allocated[selected]&&masks[selected]==63);
   pending[wr++]=(struct R){.bank=selected,.gen=gens[selected]+(inject==1),.count=inject==3?11:1+regs[0x20c/4]%3,
      .stream=regs[0x20c/4],.frame=((uint64_t)regs[0x214/4]<<32)|regs[0x210/4],
      .version=regs[0x218/4]+(inject==2),.status=inject==4,.due=tick+100};break;
 case 0x244:word_select=v;break;
 case 0x24c:
   if(v){assert(rd<wr);allocated[pending[rd].bank]=0;rd++;}break;
 default:break;
 }
}
int main(void){
 for(inject=0;inject<6;inject++){
  memset(regs,0,sizeof(regs));memset(allocated,0,sizeof(allocated));memset(gens,0,sizeof(gens));memset(masks,0,sizeof(masks));
  memset(ppu_done,0,sizeof(ppu_done));memset(ppu_result,0,sizeof(ppu_result));
  selected=generation=enabled=word_select=rd=wr=ppu_pending_mask=0;tick=100;ppu_service_cycles=0;
  if(!setjmp(fail)){
   ppu_init();
   /* Keep one PPU/slot initialization across the actual three-mode order. */
   for(unsigned mode=0;mode<3;mode++){
    unsigned lanes=mode==2?3:1;
    for(unsigned batch=0;batch<12/lanes;batch++){
    for(unsigned d=0;d<lanes;d++){
      unsigned s=ppu_begin(d,mode*12+batch*lanes+d+1);assert(s==batch%2);
      const unsigned order[]={3,0,4,1,5,2};
      for(unsigned h=0;h<6;h++)ppu_head(d,order[h]);
      if(inject==5)ppu_head(d,2);
      ppu_graph_done(d);
    }
    unsigned limit=0;while(!(ppu_done[0]&&(lanes==1||(ppu_done[1]&&ppu_done[2])))){ppu_service();assert(++limit<1000);}
    for(unsigned d=0;d<lanes;d++){
      assert(ppu_result[d].count==d+1);
      for(unsigned i=0;i<10;i++)for(unsigned j=0;j<4;j++){
        unsigned expected=i<d+1?(mode*12+batch*lanes+d+1)*100+i*4+j:0;
        assert(ppu_result[d].words[i][j]==expected);
      }
    }
    }
   }
   assert(!inject&&rd==36&&wr==36);
#if YOLO32_FRONTEND_DIAG
   assert(ppu_service_cycles>0);
#else
   assert(ppu_service_cycles==0);
#endif
  }else{
   assert(inject);assert(!strcmp(reason,inject==5?"head_ownership":"ppu_result_metadata_or_error"));
  }
 }
 puts("ATSOFT1,PPU_CHECK_PASS,native_drivers=1,frames=36,mode_sequence=single+single+triple,ping_pong=1,head_publication=1,result_words=all40,fault_cases=5");
}
'''
(out/'test.c').write_text(code)
native=SNAP
cmd=['cc','-O1','-g','-std=gnu11','-fsanitize=address,undefined','-I'+str(out),'-I'+str(root/'src'),'-I'+str(native),
 str(out/'test.c'),str(native/'ai/postprocess/ai_ppu_publication.c'),str(native/'ai/postprocess/ai_ppu_queue.c'),
 str(native/'ai/runtime/ai_head_slot_queue.c'),'-o',str(out/'test')]
for diagnostic in (0,1):
    subprocess.run(cmd+[f'-DYOLO32_FRONTEND_DIAG={diagnostic}'],check=True)
    subprocess.run([str(out/'test')],check=True,timeout=30,env=dict(os.environ,ASAN_OPTIONS='detect_leaks=0'))
