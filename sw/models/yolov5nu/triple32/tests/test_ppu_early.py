"""Real independent scheduler + PPU drivers, simulated DMA/posted MMIO/PPU.

Host substitutes ucontext for the switch. QEMU runs the actual RVV switch.
This validates ownership/ordering/overlap control, not hardware numerical math.
"""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
from generate_parallel import function

TOOLCHAIN = Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin')


class EarlyPpuTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='yolo32-early-')
        root = Path(cls.tmp.name); local = root/'triple32'; local.mkdir()
        (root/'dim16_dual').mkdir()
        for name in ('independent.c', 'independent.h', 'diagnostics.h', 'task_context_config.h', 'task_switch.S',
                     'ppu.c', 'ppu.h', 'ppu_early.inc', 'ppu_head_clean.inc', 'yolo32.h'):
            shutil.copy(HERE/name, local/name)
        # Count fallback/global fences in the host model; its assert forbids
        # a global wait while another graph is running. The firmware still
        # contains real fence instructions, checked separately in its ELF.
        inc = (local/'ppu_early.inc').read_text().replace(
            '__asm__ volatile("fence" ::: "memory");', 'test_full_fence();')
        (local/'ppu_early.inc').write_text(inc)
        for name in ('yolov5nu_dim16_dual.h', 'yolov5nu_head_layout.h'):
            shutil.copy(HERE/'native'/name, local/name)
        for name in ('console.h', 'platform.h'):
            shutil.copy(HERE/name, local/name)
        (local/'mmio.h').write_text('''#include <stdint.h>
uint32_t mmio_read32(uintptr_t); void mmio_write32(uintptr_t,uint32_t);
uint64_t read_cycle(void); void test_full_fence(void); void yolo32_ppu_io_barrier(void);
#if YOLO32_PPU_ORDERED_MMIO
static inline void mmio_fence(void){yolo32_ppu_io_barrier();}
#else
static inline void mmio_fence(void){test_full_fence();}
#endif
''')
        ready = function((HERE/'model.c').read_text(), 'unsigned yolo32_independent_ready(')
        # Same host switch adapter as the existing real-scheduler tests.
        switch = (HERE/'tests/test_independent.py').read_text().split("switch = r'''",1)[1].split(
            'static void seed_vector(',1)[0]
        code = r'''
#define _XOPEN_SOURCE 700
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef __riscv
#include <ucontext.h>
#endif
#include "ppu.h"
#include "independent.h"
#include "yolo32.h"
#include "platform.h"
#include "mmio.h"
static uint64_t tick, dma_at[3], clean_at[6], receipt_at[6], release_at;
static unsigned stage[3], heads[3], accepted[3], retired[3], selected;
static uint32_t independent_accepted_base[3];
static unsigned bank,allocated[6],generation[6],producer[6],submits[3],retire_calls[3];
static uint32_t regs[256],pending_offset,pending_value;
static unsigned pending_write,barriers,clean_pending_at_enqueue,pops,record_index;
static unsigned producer_checks, queue_blocked_checks, receipt_checks;
static unsigned all_waiting_services, idle_service_reads;
static unsigned fallback_fences, request_limit[3]={2,20,60};
static uint64_t latest[3];
typedef struct { unsigned bank,stream,version,generation;uint64_t frame; } Desc;
static Desc commands[4], active_desc, results[4];
static unsigned command_count,active_core,result_count,positions;
static uint64_t core_start,core_end,read_words;
static unsigned fault, analysis;
static unsigned queue_block_armed;
#if YOLO32_PPU_HEAD_CLEAN
static uint64_t clean_head_at[6][6],head_dma_done[3][6];
static unsigned ready_heads[6],partial_publications,later_dmas,early_hardware_results;
#endif
void yolo32_fail(const char *s){puts(s);exit(42);}
void console_puts(const char *s){fputs(s,stdout);}
void console_putc(char c){putchar(c);}
void console_put_hex64(uint64_t v){printf("0x%016lX",v);}
static void hardware_step(void){
#if YOLO32_PPU_HEAD_CLEAN
 for(unsigned b=0;b<6;b++)if(allocated[b])for(unsigned h=0;h<6;h++)
   if((producer[b]&(1U<<h))&&tick>=clean_head_at[b][h])ready_heads[b]|=1U<<h;
#endif
 if(!active_core&&command_count){
   active_desc=commands[0];memmove(commands,commands+1,--command_count*sizeof(Desc));
   active_core=1;
#if YOLO32_PPU_HEAD_CLEAN
   core_start=core_end=0;positions=6300;
#else
   core_start=clean_at[active_desc.bank]+20;
   if(core_start<tick)core_start=tick+20;
   core_end=core_start+700;positions=6300;
#endif /* stale previous counters during WAIT_READY */
 }
#if YOLO32_PPU_HEAD_CLEAN
 if(active_core){
   if(!core_start&&(ready_heads[active_desc.bank]&1U)){core_start=tick;positions=0;}
   if(core_start){
     unsigned limit=(ready_heads[active_desc.bank]&4U)?6300:(ready_heads[active_desc.bank]&2U)?6000:4800;
     if(positions<limit)positions+=50;
     if(positions>limit)positions=limit;
     if(positions==6300&&ready_heads[active_desc.bank]==63&&!core_end)core_end=tick+50;
     if(fault==10&&ready_heads[active_desc.bank]==63)core_end=tick;
   }
   if(core_end&&tick>=core_end){
     for(unsigned b=0;b<6;b++)if(clean_at[b]>tick)return;
     assert(result_count<4);results[result_count++]=active_desc;
     if(!(yolo32_independent_stats()->done_mask&(1U<<active_desc.stream)))++early_hardware_results;
     allocated[active_desc.bank]=producer[active_desc.bank]=ready_heads[active_desc.bank]=0;
     active_core=0;
   }
 }
#else
 if(active_core&&tick>=core_start){
   positions=fault==5?6300:(unsigned)((tick-core_start)*6300/700);
   if(positions>6300)positions=6300;
   if(tick>=core_end){
     for(unsigned b=0;b<6;b++)if(clean_at[b]>tick)return; /* publication RELEASE guard */
     assert(result_count<4);results[result_count++]=active_desc;
     allocated[active_desc.bank]=0;active_core=0;
   }
 }
#endif
}
static void advance(void){++tick;hardware_step();}
uint64_t read_cycle(void){advance();return tick;}
static void apply_write(unsigned o,uint32_t v){
 regs[o/4]=v;
 if(o==0x1a8){bank=v;assert(bank<6);}
 if(o==0x1b0&&v==1){assert(!allocated[bank]);allocated[bank]=1;
   generation[bank]=regs[0x1ac/4];producer[bank]=0;receipt_at[bank]=clean_at[bank]=0;
#if YOLO32_PPU_HEAD_CLEAN
   ready_heads[bank]=0;memset(clean_head_at[bank],0,sizeof(clean_head_at[bank]));
#endif
 }
 if(o==0x1b0&&(v>>8)){
   unsigned w=bank/2;assert(allocated[bank]);
#if YOLO32_PPU_HEAD_CLEAN
   unsigned mask=v>>8;assert((heads[w]&mask)==mask&&!(producer[bank]&mask));
   for(unsigned h=0;h<6;h++)if(mask&(1U<<h)){assert(head_dma_done[w][h]<=tick);clean_head_at[bank][h]=tick+300;}
   if(!(yolo32_independent_stats()->done_mask&(1U<<w)))++partial_publications;
   if(tick<dma_at[w]||accepted[w]!=retired[w])++later_dmas;
#else
   assert(heads[w]==63);
   assert(retired[w]==accepted[w]&&tick>=dma_at[w]);
   assert(yolo32_independent_finished(w));
#endif
   ++producer_checks;
   producer[bank]|=v>>8;receipt_at[bank]=tick+8;clean_at[bank]=tick+300;
#if YOLO32_PPU_HEAD_CLEAN
   if(fault==10&&YOLO32_PPU_HEAD_ADMIT&&producer[bank]==63){
     ready_heads[bank]=63;for(unsigned h=0;h<6;h++)clean_head_at[bank][h]=tick;
     clean_at[bank]=tick;
   }
#endif
   if(fault==1&&!release_at)release_at=tick+1800;
 }
 if(o==0x234&&v==1){unsigned w=regs[0x20c/4];
   uint64_t frame=((uint64_t)regs[0x214/4]<<32)|regs[0x210/4];assert(frame>latest[w]);latest[w]=frame;}
 if(o==0x204&&v==1){
   unsigned w=regs[0x20c/4];assert(w<3&&bank/2==w&&allocated[bank]);
   #if YOLO32_PPU_HEAD_CLEAN
   assert((producer[bank]&1U)&&tick>=receipt_at[bank]);
   if(!YOLO32_PPU_HEAD_ADMIT)assert(producer[bank]==63&&(yolo32_independent_stats()->done_mask&(1U<<w)));
#else
   assert(producer[bank]==63&&tick>=receipt_at[bank]);
#endif
   assert(!submits[w]);
   uintptr_t base=AI_MODEL_OUTPUT0_PHYS_BASE+w*AI_MODEL_OUTPUT_ARENA_BYTES+(bank&1)*YOLOV5NU_HEAD_SLOT_STRIDE;
   assert(regs[0x104/4]==base&&regs[0x110/4]==base+YOLOV5NU_HEAD_DFL0_OFFSET);
   assert(regs[0x108/4]==base+YOLOV5NU_HEAD_CLASS1_OFFSET&&regs[0x114/4]==base+YOLOV5NU_HEAD_DFL1_OFFSET);
   assert(regs[0x10c/4]==base+YOLOV5NU_HEAD_CLASS2_OFFSET&&regs[0x118/4]==base+YOLOV5NU_HEAD_DFL2_OFFSET);
   assert(command_count<4);Desc *d=&commands[command_count++];
   *d=(Desc){bank,w,regs[0x218/4],generation[bank],((uint64_t)regs[0x214/4]<<32)|regs[0x210/4]};
   assert(d->frame==latest[w]);++submits[w];
   if(clean_at[bank]>tick)++clean_pending_at_enqueue;
 }
 if(o==0x244)record_index=v;
 if(o==0x24c&&v==1){assert(result_count&&read_words==((UINT64_C(1)<<40)-1));
   memmove(results,results+1,--result_count*sizeof(Desc));++pops;read_words=0;}
}
static void drain_write(void){if(pending_write){pending_write=0;tick+=3;apply_write(pending_offset,pending_value);}}
void mmio_write32(uintptr_t addr,uint32_t v){
 drain_write();advance();pending_offset=(unsigned)(addr-POSTPROCESS_DIAG_BASE);pending_value=v;pending_write=1;
}
uint32_t mmio_read32(uintptr_t addr){
 drain_write();advance();unsigned o=(unsigned)(addr-POSTPROCESS_DIAG_BASE);
 Desc d=result_count?results[0]:(Desc){0};
 switch(o){
 case 0x100:return 0x50505531;case 0x1a0:++barriers;return 0x50505532;
 case 0x204:return 0x50505132;case 0x238:return 0x50505232;
 case 0x1b4:return allocated[bank];case 0x1bc:return generation[bank]+(fault==8&&producer[bank]!=0);
 case 0x1b8:++receipt_checks;
#if YOLO32_PPU_HEAD_CLEAN
   return fault==4||tick<receipt_at[bank]?0:(producer[bank]<<8)|ready_heads[bank];
#else
   return fault==4||tick<receipt_at[bank]?0:producer[bank]<<8;
#endif
 case 0x208:
   if(fault==1&&YOLO32_PPU_HEAD_CLEAN&&!YOLO32_PPU_HEAD_ADMIT&&
      yolo32_independent_enabled&&yolo32_independent_stats()->done_mask&&!queue_block_armed){
      queue_block_armed=1;release_at=tick+1800;
   }
   if(fault==1&&release_at&&tick<release_at){++queue_blocked_checks;return active_core?64:0;}
   return 32|(active_core?64:0);
 case 0x224:return active_desc.stream|(active_desc.bank<<4);
 case 0x228:return (uint32_t)active_desc.frame;case 0x22c:return active_desc.frame>>32;
 case 0x230:return active_desc.version;case 0x138:return positions;
 case 0x240:
   if(yolo32_independent_enabled&&all_waiting_services&&tick<dma_at[1]&&tick<dma_at[2])++idle_service_reads;
   return result_count?1:0;
 case 0x250:return d.bank;
 case 0x254:return (d.stream+1)|(d.stream<<10)|(fault==3?1U<<14:0);
 case 0x258:return (uint32_t)d.frame;case 0x25c:return d.frame>>32;
 case 0x260:return d.version;case 0x264:return 700;
 case 0x268:return d.generation+(fault==2);
 case 0x248:assert(result_count&&record_index<40);read_words|=UINT64_C(1)<<record_index;
   return 0x11000000U+d.stream*100+record_index;
 default:return regs[o/4];
 }
}
void test_full_fence(void){assert(!yolo32_independent_enabled);drain_write();++fallback_fences;}
static uint64_t independent_status_read(unsigned w){
 advance();if(tick<dma_at[w])return 1;retired[w]=accepted[w];return 0;
}
static uint32_t independent_counter_read(unsigned w,unsigned r){return r?retired[w]:accepted[w];}
static unsigned read_worker_busy(unsigned w){return tick<dma_at[w];}
void yolo32_independent_select(unsigned w){selected=w;}
void yolo32_independent_snapshot(unsigned w){independent_accepted_base[w]=accepted[w];}
unsigned yolo32_independent_busy_mask(void){unsigned mask=0;for(unsigned w=0;w<3;w++)if(independent_status_read(w))mask|=1U<<w;return mask;}
unsigned yolo32_independent_head_mask(unsigned w){return heads[w];}
unsigned yolo32_stage(unsigned w){return stage[w];}
void yolo32_finish_hardware(unsigned w){assert(heads[w]==63&&retired[w]==accepted[w]);assert(!retire_calls[w]);++retire_calls[w];}
int yolo32_graph_poll(unsigned w,Yolo32Result *r){
 (void)r;assert(selected==w);
 if(stage[w]==request_limit[w]){yolo32_independent_wait();heads[w]=63;
   if(fault==6)assert(!yolo32_independent_finished(w)); /* must reject before FINISHED handoff */
   return YOLOV5NU_DIM16_HEAD_READY;}
 for(unsigned i=0;i<7;i++)advance(); /* complete LoopConv packet, then yield hook */
 ++accepted[w];dma_at[w]=tick+(w==2?900:180);
 yolo32_independent_arm_tail_wait(15);yolo32_independent_command_return(15);
 if(!(fault==12&&stage[w]==123))yolo32_independent_wait();
#if YOLO32_PPU_HEAD_CLEAN
 static const unsigned hs[6]={124,147,164,123,146,163};
 for(unsigned h=0;h<6;h++)if(stage[w]==hs[h]){
   yolo32_independent_head_ready(w,h);head_dma_done[w][h]=tick;heads[w]|=1U<<h;
   if(fault==11)yolo32_independent_head_ready(w,h);
 }
#endif
 ++stage[w];tick+=20;hardware_step();return YOLOV5NU_DIM16_RUNNING;
}
'''
        code += ready + '\n' + switch + r'''
static void one_batch(unsigned run){
 memset(stage,0,sizeof(stage));memset(heads,0,sizeof(heads));
 memset(submits,0,sizeof(submits));memset(retire_calls,0,sizeof(retire_calls));
 release_at=queue_block_armed=0;unsigned pop_start=pops,checks=producer_checks;
 for(unsigned w=0;w<3;w++)yolo32_ppu_begin(w,run);
 uint64_t base=read_cycle();yolo32_ppu_early_begin(base,analysis);yolo32_independent_begin(analysis);
 unsigned steps=0;
 while(!yolo32_independent_step()){assert(++steps<100000);
   if(fault==7&&yolo32_independent_stats()->done_mask==1)yolo32_ppu_graph_done(0);
   if(getenv("IDLE_ONLY")&&stage[0]==request_limit[0]&&heads[0]==63&&stage[1]<request_limit[1]){
     /* Force a long all-WAITING interval: service must run inside HOT_PATHS,
      * where main cannot call yolo32_ppu_service. Count its calls afterwards. */
     const Yolo32IndependentStats *s=yolo32_independent_stats();
     if(s->done_mask==1&&tick<dma_at[1]&&tick<dma_at[2]){
       dma_at[1]+=5000;dma_at[2]+=5000;++all_waiting_services;
     }
   }
 }
 assert(yolo32_independent_stats()->done_mask==7);
 yolo32_independent_end();
 while(!(yolo32_ppu_done(0)&&yolo32_ppu_done(1)&&yolo32_ppu_done(2))){
   yolo32_ppu_service();assert(read_cycle()-base<1000000);
 }
 drain_write();const Yolo32PpuEarlyStats *s=yolo32_ppu_early_stats();
 assert(s->published_mask==7&&s->enqueued_mask==7&&s->result_mask==7);
 #if YOLO32_PPU_HEAD_CLEAN
 assert(producer_checks>=checks+3&&producer_checks<=checks+18&&pops==pop_start+3);
 const Yolo32PpuHeadStats *hs=yolo32_ppu_head_stats();
 for(unsigned w=0;w<3;w++){
   assert(hs->published_heads[w]==63);
   assert(hs->heads[w][0].publication_cycle<s->workers[w].graph_done_cycle);
   if(YOLO32_PPU_HEAD_ADMIT)assert(s->workers[w].enqueue_cycle<s->workers[w].graph_done_cycle);
   else assert(s->workers[w].enqueue_cycle>=s->workers[w].graph_done_cycle);
   for(unsigned h=0;h<6;h++){
     assert(hs->heads[w][h].completed_cycle<=hs->heads[w][h].publication_cycle);
     assert(hs->heads[w][h].requests>0);
   }
 }
#else
 assert(producer_checks==checks+3&&pops==pop_start+3);
#endif
 assert(s->workers[0].enqueue_done_mask!=7&&s->workers[0].result_done_mask!=7);
 assert(receipt_checks>producer_checks); /* receipt is delayed after AXI B */
 if(analysis&&fault!=5)assert(s->progress_mask&1);
 else assert(!s->progress_mask);
 assert(analysis? s->service_cycles>0 : s->service_cycles==0);
 for(unsigned w=0;w<3;w++){
   const Yolo32PpuResult *r=yolo32_ppu_result(w);assert(r->count==w+1&&r->core_cycles==700);
   for(unsigned i=0;i<40;i++)assert(r->words[i/4][i%4]==0x11000000U+w*100+i);
   assert(submits[w]==1&&retire_calls[w]==1);
   if(!YOLO32_PPU_HEAD_CLEAN)assert(s->workers[w].graph_done_cycle<=s->workers[w].publication_cycle);
   if(!YOLO32_PPU_HEAD_ADMIT)assert(s->workers[w].publication_cycle<=s->workers[w].enqueue_cycle);
   assert(s->workers[w].enqueue_cycle<s->workers[w].result_cycle);
 }
#ifndef __riscv
 memset(contexts,0,sizeof(contexts));contexts_used=0;
#endif
}
int main(int argc,char **argv){
 fault=argc>1?(unsigned)atoi(argv[1]):0;analysis=argc>2?(unsigned)atoi(argv[2]):1;
#if YOLO32_PPU_HEAD_CLEAN
 for(unsigned w=0;w<3;w++)request_limit[w]=165;
#endif
 regs[0x210/4]=123;regs[0x214/4]=1; /* retained >32-bit frame expectation */
 yolo32_ppu_init();unsigned before=fallback_fences;one_batch(1);one_batch(2);
 assert(fallback_fences>before&&barriers>0);
#if YOLO32_PPU_HEAD_CLEAN
 assert(partial_publications>0&&later_dmas>0);
 if(fault==10)assert(early_hardware_results>0);
#else
 assert(clean_pending_at_enqueue>0);
#endif
 if(fault==1)assert(queue_blocked_checks>0);
 if(getenv("IDLE_ONLY"))assert(all_waiting_services>0&&idle_service_reads>0);
 /* After the overlap session, ordinary barrier behavior is restored. */
 before=fallback_fences;yolo32_ppu_io_barrier();assert(fallback_fences==before+1);
 puts("PASS: scheduler + production PPU, local DMA retirement, posted MMIO, delayed receipt, queue retry, early results, all 40 words, two batches");
 return 0;
}
'''
        (local/'test.c').write_text(code)
        cls.root, cls.local = root, local
        cls.flags = ['-std=c11', '-O2', '-Wall', '-Wextra', '-Werror',
                     '-DYOLO32_TIMEOUT_SECONDS=1',
                     '-DYOLO32_PPU_EARLY=1', '-DYOLO32_PREPARED_PACKETS=1',
                     '-DYOLO32_FIXED_PLANS=1', '-DYOLO32_FIXED_PACKETS=1',
                     '-DYOLO32_TAIL_WAIT=1', '-DYOLO32_IDLE_PRIORITY=1',
                     '-DYOLO32_HOT_PATHS=1', '-DYOLO32_SCHED_ADAPTIVE=0',
                     '-DYOLO32_CONTEXT_FULL=0', '-DYOLO32_SUBMIT_BURST=1',
                     '-I'+str(local), '-I'+str(root/'dim16_dual'),
                     '-I'+str(HERE.parents[3]/'sw/src')]
        cls.host = cls.build('host', 'gcc', ['-DYOLO32_HOST_TASKS=1'])
        cls.qemu = shutil.which('qemu-riscv64')
        gcc = TOOLCHAIN/'riscv64-unknown-linux-gnu-gcc'
        cls.riscv = cls.build('riscv', str(gcc), ['-static', '-march=rv64gcv', '-mabi=lp64d']) if cls.qemu and gcc.exists() else None
        cls.head_host={};cls.head_riscv={}
        for mode in (0,1):
            flags=['-DYOLO32_PPU_HEAD_CLEAN=1',f'-DYOLO32_PPU_HEAD_ADMIT={mode}']
            cls.head_host[mode]=cls.build(f'host-head-{mode}','gcc',['-DYOLO32_HOST_TASKS=1']+flags)
            cls.head_riscv[mode]=cls.build(f'riscv-head-{mode}',str(gcc),['-static','-march=rv64gcv','-mabi=lp64d']+flags) if cls.riscv else None

    @classmethod
    def build(cls, name, cc, extras):
        ref = HERE.parents[3]/'sw/src'
        sources = [cls.local/'independent.c', cls.local/'ppu.c', cls.local/'test.c',
                   ref/'ai/postprocess/ai_ppu_publication.c', ref/'ai/postprocess/ai_ppu_queue.c',
                   ref/'ai/runtime/ai_head_slot_queue.c']
        objects=[]
        for i, source in enumerate(sources):
            obj=cls.root/f'{name}-{i}.o'
            flags=extras+cls.flags
            if i in (3,4):flags+=['-DYOLO32_PPU_ORDERED_MMIO=1']
            result=subprocess.run([cc]+flags+['-c',str(source),'-o',str(obj)],capture_output=True,text=True)
            if result.returncode:raise AssertionError(result.stderr)
            objects.append(str(obj))
        if name.startswith('riscv'):
            obj=cls.root/'switch.o'
            subprocess.run([cc]+extras+['-DYOLO32_CONTEXT_FULL=0','-c',str(cls.local/'task_switch.S'),'-o',str(obj)],check=True,capture_output=True)
            objects.append(str(obj))
        exe=cls.root/name
        subprocess.run([cc]+extras+objects+['-o',str(exe)],check=True,capture_output=True)
        return exe

    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()

    def invoke(self, fault=0, analysis=1, riscv=False, idle=False, head=None):
        if riscv and not self.riscv:self.skipTest('RISC-V Linux compiler/QEMU unavailable')
        exe=(self.head_riscv[head] if riscv else self.head_host[head]) if head is not None else self.riscv if riscv else self.host
        cmd=[self.qemu,'-cpu','rv64,v=true,vlen=256',str(exe)] if riscv else [str(exe)]
        env=dict(os.environ,**({'IDLE_ONLY':'1'} if idle else {}))
        return subprocess.run(cmd+[str(fault),str(analysis)],capture_output=True,text=True,timeout=20,env=env)

    def test_real_drivers_with_posted_writes_and_three_different_graphs(self):
        for analysis in (0,1):
            r=self.invoke(analysis=analysis)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr)
            self.assertIn('PASS:',r.stdout)

    def test_full_queue_retries_without_republishing_or_losing_results(self):
        r=self.invoke(fault=1)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_stale_previous_positions_are_not_progress_evidence(self):
        r=self.invoke(fault=5)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_result_faults_and_missing_publication_receipt_are_rejected(self):
        for fault,reason in ((2,'ppu_result_metadata'),(3,'ppu_result_error_or_stale'),
                             (4,'ppu_publication_commit_timeout'),(6,'ppu_producer_state'),
                             (7,'ppu_graph_publish'),(8,'ppu_publication_metadata')):
            r=self.invoke(fault=fault)
            self.assertEqual(r.returncode,42,r.stdout+r.stderr)
            self.assertIn(reason,r.stdout)

    def test_ppu_is_serviced_inside_scheduler_idle_loop(self):
        r=self.invoke(idle=True)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_early_ppu_across_real_riscv_context_switches(self):
        for fault in (0,1,5):
            r=self.invoke(fault=fault,riscv=True)
            self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_head_clean_and_class0_admission_with_later_dma_in_flight(self):
        for mode in (0,1):
            for analysis in (0,1):
                for fault in (0,1):
                    with self.subTest(mode=mode,analysis=analysis,fault=fault):
                        r=self.invoke(head=mode,analysis=analysis,fault=fault)
                        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_head_completion_proof_and_duplicate_callbacks_are_checked(self):
        for mode in (0,1):
            for fault,reason in ((11,'ppu_duplicate_head'),(12,'ppu_head_completion_proof'),
                                 (4,'ppu_publication_commit_timeout'),(8,'ppu_publication_metadata')):
                r=self.invoke(head=mode,fault=fault)
                self.assertEqual(r.returncode,42,r.stdout+r.stderr)
                self.assertIn(reason,r.stdout)

    def test_class0_hardware_release_before_producer_finish_is_owned(self):
        r=self.invoke(head=1,fault=10)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)

    def test_head_variants_with_real_riscv_switches(self):
        for mode in (0,1):
            for fault in ((0,1,10) if mode else (0,1)):
                r=self.invoke(head=mode,fault=fault,riscv=True)
                self.assertEqual(r.returncode,0,r.stdout+r.stderr)


if __name__=='__main__':unittest.main()
