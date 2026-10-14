"""Run the production scheduler, native scoped fence and completion predicate.
Host ucontext models only the switch; QEMU also executes task_switch.S with RVV.
No Gemmini/PPU numerical hardware is simulated.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
from generate_parallel import ABI, MODEL, generate, function, tail_wait_annotations

TOOLCHAIN = Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin')


class IndependentTasks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='yolo32-independent-')
        root = Path(cls.tmp.name)
        local = root/'triple32'
        local.mkdir()
        (root/'dim16_dual').mkdir()
        for name in ('independent.c', 'independent.h', 'diagnostics.h', 'task_context_config.h', 'yolo32.h', 'task_switch.S', 'ppu.h'):
            shutil.copy(HERE/name, local/name)
        for name in ('yolov5nu_dim16_dual.h', 'yolov5nu_head_layout.h'):
            shutil.copy(HERE/'native'/name, local/name)
        (local/'mmio.h').write_text('#include <stdint.h>\nextern uint64_t tick;\nstatic inline uint64_t read_cycle(void){return ++tick;}\n')
        (local/'platform.h').write_text('#define SOC_CLOCK_HZ 1000000UL\n')
        generate(root/'generated')
        fence = function((root/'generated/parallel_model.inc').read_text(), 'static inline void yolo_profile_fence(')
        fence = fence.replace('asm volatile("fence" ::: "memory");', 'full_fence();')
        model = (HERE/'model.c').read_text()
        ready = function(model, 'unsigned yolo32_independent_ready(')
        pre = r'''
#define _XOPEN_SOURCE 700
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#ifndef __riscv
#include <ucontext.h>
#endif
#include "independent.h"
#include "yolo32.h"
uint64_t tick;
static unsigned selected, stage[3], heads[3], accepted[3], retired[3];
static uint32_t independent_accepted_base[3];
static uint64_t ready_at[3];
static unsigned full_fences, count[3], expected_count[3], saw_early_finish;
static struct { unsigned funct; uint64_t a,b; } commands[3][512], expected[3][512];
static struct { uint64_t fence_cycles; } frame_profiles[3];
#define gemmini_pool_active_worker selected
static uint64_t yolo_frame_profile_clock(void){return ++tick;}
void yolo32_fail(const char *s){fprintf(stderr,"FAIL: %s\n",s);exit(42);}
static void select_worker_memory(unsigned w){selected=w;}
void yolo32_independent_select(unsigned w){
 select_worker_memory(w);
#ifdef __riscv
 /* The light path must tolerate vector registers/configuration clobbered by
  * another C task. Full mode restores its saved state after this poison. */
 uintptr_t n=7, x=99;
 __asm__ volatile("vsetvli zero,%0,e16,m2,ta,ma\n\tvmv.v.x v0,%1\n\tvmv.v.x v8,%1\n\tvmv.v.x v16,%1\n\tvmv.v.x v24,%1"
   ::"r"(n),"r"(x):"v0","v8","v16","v24","memory");
#endif
}
static uint64_t independent_status_read(unsigned w){
 if(yolo32_independent_enabled&&getenv("STUCK")&&w==0)return 1;
 if(yolo32_independent_enabled&&getenv("INGRESS_ERROR")&&w==0)return 0xc000;
 if(tick<ready_at[w])return 1;
 retired[w]=accepted[w];return 0;
}
static uint32_t independent_counter_read(unsigned w,unsigned r){return r?retired[w]:accepted[w];}
static unsigned read_worker_busy(unsigned w){return independent_status_read(w)&1U;}
void yolo32_independent_snapshot(unsigned w){independent_accepted_base[w]=accepted[w];}
unsigned yolo32_independent_busy_mask(void){unsigned m=0;for(unsigned w=0;w<3;w++)if(independent_status_read(w)&1)m|=1U<<w;return m;}
unsigned yolo32_independent_head_mask(unsigned w){return heads[w];}
unsigned yolo32_stage(unsigned w){return stage[w];}
static void full_fence(void){
 assert(!yolo32_independent_enabled);++full_fences;
 for(unsigned w=0;w<3;w++){if(tick<ready_at[w])tick=ready_at[w];retired[w]=accepted[w];}
}
'''
        switch = r'''
#ifndef __riscv
static struct { Yolo32TaskContext *key;ucontext_t uc;unsigned initialized; } contexts[4];
static unsigned contexts_used;
static __attribute__((noinline)) unsigned context_index(Yolo32TaskContext *c){
 for(unsigned i=0;i<contexts_used;i++)if(contexts[i].key==c)return i;
 assert(contexts_used<4);unsigned i=contexts_used++;contexts[i].key=c;return i;
}
void yolo32_task_switch(Yolo32TaskContext *from,const Yolo32TaskContext *to){
 unsigned f=context_index(from),t=context_index((Yolo32TaskContext *)to);
 if(!contexts[t].initialized){
   assert(to->ra);getcontext(&contexts[t].uc);contexts[t].uc.uc_link=NULL;
   contexts[t].uc.uc_stack.ss_sp=(void *)(to->sp-16384+64);
   contexts[t].uc.uc_stack.ss_size=16384-64;
   makecontext(&contexts[t].uc,(void (*)(void))to->ra,0);contexts[t].initialized=1;
 }
 contexts[f].initialized=1;uintptr_t stack_marker=0;from->sp=(uintptr_t)&stack_marker;
 if(getenv("BAD_STACK")&&from->ra)from->sp=0;
 if(getenv("BAD_GUARD")&&from->ra)((unsigned char *)contexts[f].uc.uc_stack.ss_sp)[-1]=0;
 swapcontext(&contexts[f].uc,&contexts[t].uc);
}
#endif
static void seed_vector(unsigned w){
#ifdef __riscv
 uintptr_t n=256,x=11+w,y=21+w,z=31+w,q=41+w;
 __asm__ volatile("vsetvli zero,%0,e8,m8,ta,ma\n\tvmv.v.x v0,%1\n\tvmv.v.x v8,%2\n\tvmv.v.x v16,%3\n\tvmv.v.x v24,%4"
  ::"r"(n),"r"(x),"r"(y),"r"(z),"r"(q):"v0","v8","v16","v24","memory");
 n=19;uintptr_t vc=5+w,fc=(w<<5)|16U;
 __asm__ volatile("vsetvli zero,%0,e8,m1,ta,ma\n\tcsrw vcsr,%1\n\tcsrw fcsr,%2"::"r"(n),"r"(vc),"r"(fc):"memory");
#else
 (void)w;
#endif
}
static void check_vector(unsigned w){
#ifdef __riscv
 uintptr_t vc,fc;
 __asm__ volatile("csrr %0,vcsr\n\tcsrr %1,fcsr":"=r"(vc),"=r"(fc));
 assert(vc==5+w&&fc==((w<<5)|16U));
#if YOLO32_CONTEXT_FULL
 uint8_t bytes[1024] __attribute__((aligned(16)));uintptr_t vl,vt;
 __asm__ volatile("csrr %0,vl\n\tcsrr %1,vtype":"=r"(vl),"=r"(vt));
 assert(vl==19&&vt==0xc0);
 uintptr_t p=(uintptr_t)bytes;
 __asm__ volatile("vs8r.v v0,(%0)\n\taddi %0,%0,256\n\tvs8r.v v8,(%0)\n\taddi %0,%0,256\n\tvs8r.v v16,(%0)\n\taddi %0,%0,256\n\tvs8r.v v24,(%0)\n\tcsrr zero,vl":"+r"(p)::"memory");
 for(unsigned i=0;i<1024;i++)assert(bytes[i]==11+w+(i/256)*10);
#endif
#else
 (void)w;
#endif
}
/* Real production backbone RVV kernels. Each call must establish its own
 * configuration; buffers, not vector registers, carry data across stages. */
#ifdef __riscv
#include "yolov5nu_stage3_rvv.h"
#include "yolov5nu_stage4_rvv.h"
#endif
static void cpu_vectors(unsigned w){
#ifdef __riscv
 int8_t src[257],out[257],table[256];
 for(unsigned i=0;i<257;i++)src[i]=(int8_t)((i+17*w)%201-100);
 for(unsigned i=0;i<256;i++)table[i]=(int8_t)(i^0x55U);
 yolov5nu_rvv_copy_i8(src,out,257);assert(!memcmp(src,out,257));
 yolov5nu_rvv_requant_i8(src,out,257,1.0f);assert(!memcmp(src,out,257));
 yolov5nu_rvv_sigmoid_lut_i8(src,out,257,table);
 for(unsigned i=0;i<257;i++)assert(out[i]==table[(uint8_t)src[i]]);
 yolov5nu_rvv_add_fixed_i8(src,src,out,257,1<<21,1<<21);
 assert(!memcmp(src,out,257));
#else
 (void)w;
#endif
}
static void record(unsigned funct,uint64_t a,uint64_t b){
 unsigned w=selected;assert(count[w]<512);
 commands[w][count[w]].funct=funct;commands[w][count[w]].a=a;commands[w][count[w]].b=b;++count[w];
}
static void packet(unsigned funct,unsigned tile){
 unsigned w=selected;
#ifdef __riscv
 register double local __asm__("fs0")=1.25*(w+1)+tile;
 __asm__ volatile("":"+f"(local));
#else
 double local=1.25*(w+1)+tile;
#endif
 /* A whole packet is emitted before the hook. No task can see half a packet. */
 for(unsigned i=0;i<(funct==15?7U:6U);i++)record(i+funct,1000*w+tile,200+i);
 if(funct==15)++accepted[w];
 ready_at[w]=tick+(getenv("BURST_PROBE")?(w==0?6000U:1000U):(w==0?1000U:30U));
 seed_vector(w);
 if(getenv("LATENCY_PROBE")||getenv("LATENCY_FAST")||getenv("LATENCY_CONFIG")){
   unsigned measured=funct==15?15:11;
   uint64_t elapsed=getenv("LATENCY_FAST")?1:
     getenv("LATENCY_CONFIG")?(funct==8?30:1):(tile==0?25:tile==1?10:1);
   /* Match production: an elapsed hook never changes tasks mid-packet. */
   unsigned resumes_before=(unsigned)yolo32_independent_stats()->resumes[w];
   yolo32_independent_command_elapsed(measured,elapsed);
   assert(selected==w&&(unsigned)yolo32_independent_stats()->resumes[w]==resumes_before);
 }
 yolo32_independent_command_return(funct);
#ifdef __riscv
 __asm__ volatile("":"+f"(local));
#endif
 check_vector(w);
 assert(selected==w&&local==1.25*(w+1)+tile);
}
int yolo32_graph_poll(unsigned w,Yolo32Result *r){
 (void)r;assert(selected==w);
 if(getenv("BURST_PROBE")){
   if(stage[w]==0){for(unsigned t=0;t<6;t++)packet(15,t);stage[w]=165;return YOLOV5NU_DIM16_RUNNING;}
   yolo_profile_fence();heads[w]=63;stage[w]=167;
   if(yolo32_independent_enabled&&w!=0&&stage[0]<167)saw_early_finish=1;
   return YOLOV5NU_DIM16_HEAD_READY;
 }
 if(stage[w]==0){
   /* Ordinary convolution: independent native tile stream. */
   record(26,100+w,0);yolo_profile_fence();
   for(unsigned tile=0;tile<3;tile++)packet(15,tile);
   yolo_profile_fence();stage[w]++;return YOLOV5NU_DIM16_RUNNING;
 }
 if(stage[w]==1){record(100,55+w,0);cpu_vectors(w);if(getenv("CPU_SLOW"))tick+=25000;stage[w]++;return YOLOV5NU_DIM16_RUNNING;}
 if(stage[w]==2){
   /* Two-consumer Split-K: preserve scale, LUT and A=NULL reuse boundaries. */
   for(unsigned tile=0;tile<2;tile++)for(unsigned part=0;part<4;part++){
     assert(!(independent_status_read(w)&1));record(0,part<2?10:20,part&1);
     packet(8,10+tile*4+part);yolo_profile_fence();
     if(part&1){record(26,200+part,0);yolo_profile_fence();}
   }
   /* Residual add also yields a complete LoopWS and waits only for itself. */
   packet(8,99);yolo_profile_fence();
   for(unsigned h=0;h<6;h++)heads[w]|=1U<<h;
   stage[w]=165;return YOLOV5NU_DIM16_RUNNING;
 }
 assert(stage[w]==165);yolo_profile_fence();stage[w]=167;
 if(yolo32_independent_enabled&&w!=0&&stage[0]<167)saw_early_finish=1;
 return YOLOV5NU_DIM16_HEAD_READY;
}
static void reset(void){
 memset(stage,0,sizeof(stage));memset(heads,0,sizeof(heads));memset(count,0,sizeof(count));
 memset(ready_at,0,sizeof(ready_at));
 for(unsigned w=0;w<3;w++)accepted[w]=retired[w]=UINT32_MAX-1U;
#ifndef __riscv
 memset(contexts,0,sizeof(contexts));contexts_used=0;
#endif
}
int main(void){
 Yolo32Result r;
 reset();for(unsigned w=0;w<3;w++){selected=w;while(yolo32_graph_poll(w,&r)!=YOLOV5NU_DIM16_HEAD_READY){}}
 memcpy(expected,commands,sizeof(expected));memcpy(expected_count,count,sizeof(count));
 for(unsigned repeat=0;repeat<2;repeat++){
   reset();full_fences=0;saw_early_finish=0;
   yolo32_independent_begin(repeat==0);
   while(!yolo32_independent_step()){}
   yolo32_independent_end();
   assert(!full_fences&&saw_early_finish);
   const Yolo32IndependentStats *s=yolo32_independent_stats();
   assert(s->done_mask==7);
   assert(s->command_yields+s->stage_yields==s->bootstrap_yields+s->idle_yields+s->packet_yields+s->time_yields+s->pressure_yields);
   assert(s->resumes[0]+s->resumes[1]+s->resumes[2]==s->command_yields+s->stage_yields+s->wait_yields+3);
   if(getenv("BURST_PROBE")){
     if(!getenv("LATENCY_PROBE")){
       assert(s->packet_yields>0&&s->max_quantum_packets==YOLO32_SUBMIT_BURST);
       if(YOLO32_SUBMIT_BURST>1)assert(s->command_kept>0);else assert(!s->command_kept);
     }
     assert(s->command_kept+s->command_yields==18);
   }else assert(s->stage_kept>0&&s->no_peer>0);
   if((YOLO32_SCHED_ADAPTIVE||YOLO32_HOT_PATHS)&&!getenv("BURST_PROBE"))assert(s->cached_ready_hits>0);
   if(!YOLO32_SCHED_ADAPTIVE){assert(!s->feedback_commands&&!s->pressure_yields);if(!YOLO32_HOT_PATHS)assert(!s->cached_ready_hits);}
   if(getenv("CPU_SLOW"))assert(s->time_yields>0);
   if(getenv("LATENCY_PROBE")){
     assert(s->feedback_commands==18&&s->slow_dispatches==3);
     assert(s->burst_reductions==3&&s->burst_recoveries==3&&s->pressure_yields>=3);
     assert(s->dispatch_max_cycles==25);
   }
   if(getenv("LATENCY_FAST")){
     assert(s->feedback_commands==18&&!s->slow_dispatches&&!s->pressure_yields);
     assert(!s->burst_reductions&&!s->burst_recoveries&&s->max_quantum_packets==2);
   }
   if(getenv("LATENCY_CONFIG")){
     assert(s->feedback_commands==36&&s->slow_dispatches==27);
     assert(s->dispatch_max_cycles==30&&s->burst_reductions>0);
   }
   if(!repeat&&!getenv("BURST_PROBE")&&!getenv("CPU_SLOW"))
      assert(s->ahead_submissions&&s->triple_overlap_samples&&s->busy_mask_seen==7);
   if(repeat)assert(!s->ahead_submissions&&!s->overlap_samples&&!s->busy_mask_seen);
   uint64_t wall=0;
   for(unsigned w=0;w<3;w++)wall+=s->task_wall_cycles[w];
   if(!repeat){
      assert(s->step_cycles==s->scheduler_cycles+wall&&s->ready_checks>=s->ready_blocked);
      assert(s->idle_scheduler_cycles+s->active_scheduler_cycles==s->scheduler_cycles);
      if(YOLO32_HOT_PATHS)assert(s->scheduler_steps==s->resumes[0]+s->resumes[1]+s->resumes[2]);
#ifdef __riscv
      assert(s->switch_cycles>0&&s->switch_count==2*(s->resumes[0]+s->resumes[1]+s->resumes[2]));
#endif
      for(unsigned w=0;w<3;w++)for(unsigned st=0;st<165;st++){
         const Yolo32TaskStage *p=yolo32_independent_stage(w,st);assert(p->cpu_cycles<=p->span_cycles);
      }
   }else assert(!s->step_cycles&&!wall&&!s->switch_cycles&&!s->switch_count);
   for(unsigned w=0;w<3;w++){
      assert(s->conv_requests[w]==(getenv("BURST_PROBE")?6U:3U)&&s->matmul_requests[w]==(getenv("BURST_PROBE")?0U:9U));
      assert(count[w]==expected_count[w]&&!memcmp(commands[w],expected[w],count[w]*sizeof(commands[w][0])));
      assert(heads[w]==63&&stage[w]==167);
   }
 }
 puts("PASS: native order, local fences, slow worker, cross-layer progress, wraparound, independent restart and FP/RVV switch");return 0;
}
'''
        (local/'test.c').write_text(pre + ready + fence + switch)
        args = ['-std=gnu11', '-O2', '-fno-tree-vectorize', '-Wall', '-Wextra', '-Werror',
                '-DYOLO32_QUANTUM_US=20000', '-DYOLO32_CONTEXT_FULL=1',
                '-DYOLO32_HOST_TASKS', '-DYOLOV5NU_DIM16_WORKER_COUNT=3U', '-DYOLO32_TIMEOUT_SECONDS=1']
        cls.host = root/'host-test'
        subprocess.run(['gcc']+args+[str(local/'independent.c'), str(local/'test.c'), '-o', str(cls.host)],
                       check=True, capture_output=True)
        cls.local, cls.root, cls.args = local, root, args
        cls.qemu = shutil.which('qemu-riscv64')
        cls.riscv = root/'riscv-test'
        cls.riscv_light = root/'riscv-light-test'
        cls.riscv_available = cls.qemu and (TOOLCHAIN/'riscv64-unknown-linux-gnu-gcc').exists()
        if cls.riscv_available:
            includes = ['-I'+str(HERE.parents[3]/'sw/third_party/gemmini_v3/include')]
            for full,exe in ((1,cls.riscv),(0,cls.riscv_light)):
                flags=[a.replace('YOLO32_CONTEXT_FULL=1',f'YOLO32_CONTEXT_FULL={full}') for a in args]
                subprocess.run([str(TOOLCHAIN/'riscv64-unknown-linux-gnu-gcc'), '-static', '-march=rv64gcv', '-mabi=lp64d']+
                               flags+includes+[str(local/'independent.c'), str(local/'test.c'), str(local/'task_switch.S'), '-o', str(exe)],
                               check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls): cls.tmp.cleanup()

    def test_production_scheduler_and_scoped_dependencies(self):
        result = subprocess.run([self.host], check=True, capture_output=True, text=True, timeout=15)
        self.assertIn('PASS: native order', result.stdout)

    def test_two_packet_quanta_and_cpu_time_budget(self):
        for mode in ('BURST_PROBE', 'CPU_SLOW'):
            with self.subTest(mode=mode):
                result = subprocess.run([self.host], env=dict(os.environ, **{mode:'1'}),
                                        check=True, capture_output=True, text=True, timeout=15)
                self.assertIn('PASS: native order', result.stdout)

    def test_latency_feedback_hysteresis_and_loopws_configuration(self):
        for mode in ('LATENCY_PROBE', 'LATENCY_FAST', 'LATENCY_CONFIG'):
            with self.subTest(mode=mode):
                env=dict(os.environ, **{mode:'1'})
                if mode!='LATENCY_CONFIG': env['BURST_PROBE']='1'
                result=subprocess.run([self.host],env=env,check=True,capture_output=True,text=True,timeout=15)
                self.assertIn('PASS: native order',result.stdout)

    def test_fixed_policy_control_keeps_original_budgets(self):
        exe=self.root/'fixed-test'
        subprocess.run(['gcc']+self.args+['-DYOLO32_SCHED_ADAPTIVE=0',
            str(self.local/'independent.c'),str(self.local/'test.c'),'-o',str(exe)],check=True,capture_output=True)
        for mode in (None,'BURST_PROBE','CPU_SLOW'):
            with self.subTest(mode=mode):
                env=dict(os.environ,**({mode:'1'} if mode else {}))
                result=subprocess.run([exe],env=env,check=True,capture_output=True,text=True,timeout=15)
                self.assertIn('PASS: native order',result.stdout)

    def test_fixed_single_packet_host_and_real_light_context(self):
        self.check_fixed_single_packet(0)

    def test_fast_paths_local_completion_restart_and_timeout(self):
        self.check_fixed_single_packet(1)

    def check_fixed_single_packet(self, hot_paths):
        args=[a.replace('YOLO32_CONTEXT_FULL=1','YOLO32_CONTEXT_FULL=0') for a in self.args]
        args+=['-DYOLO32_SCHED_ADAPTIVE=0','-DYOLO32_SUBMIT_BURST=1',f'-DYOLO32_HOT_PATHS={hot_paths}']
        sources=[str(self.local/'independent.c'),str(self.local/'test.c')]
        host=self.root/'single-packet-test'
        subprocess.run(['gcc']+args+sources+['-o',str(host)],check=True,capture_output=True)
        executables=[[host]]
        if self.riscv_available:
            riscv=self.root/'single-packet-riscv-test'
            include='-I'+str(HERE.parents[3]/'sw/third_party/gemmini_v3/include')
            subprocess.run([str(TOOLCHAIN/'riscv64-unknown-linux-gnu-gcc'),'-static','-march=rv64gcv','-mabi=lp64d']+
                args+[include]+sources+[str(self.local/'task_switch.S'),'-o',str(riscv)],check=True,capture_output=True)
            executables.append([self.qemu,'-cpu','rv64,v=true,vlen=256',riscv])
        for exe in executables:
            for mode in (None,'BURST_PROBE','CPU_SLOW'):
                with self.subTest(executable=exe[-1],mode=mode):
                    result=subprocess.run(exe,env=dict(os.environ,**({mode:'1'} if mode else {})),
                        check=True,capture_output=True,text=True,timeout=30)
                    self.assertIn('PASS: native order',result.stdout)
            if hot_paths:
                failures=[('STUCK','independent_timeout'),('INGRESS_ERROR','independent_ingress_error')]
                if len(exe)==1:
                    failures += [('BAD_STACK','independent_stack_pointer'),('BAD_GUARD','independent_stack_overflow')]
                for failure,reason in failures:
                    with self.subTest(executable=exe[-1],failure=failure):
                        result=subprocess.run(exe,env=dict(os.environ,**{failure:'1'}),
                            capture_output=True,text=True,timeout=30)
                        self.assertEqual(result.returncode,42)
                        self.assertIn(reason,result.stderr)

    def test_idle_peer_precedes_burst_but_requires_a_runnable_task(self):
        src=self.local/'idle-choice.c'
        src.write_text(r'''
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include "independent.c"
uint64_t tick;
static unsigned observed_busy, observed_ready, switches, busy_reads;
void yolo32_fail(const char *s){fprintf(stderr,"%s\n",s);exit(42);}
void yolo32_independent_select(unsigned w){(void)w;}
void yolo32_independent_snapshot(unsigned w){(void)w;}
unsigned yolo32_independent_ready(unsigned w,uint32_t n){(void)n;return !!(observed_ready&(1U<<w));}
unsigned yolo32_independent_busy_mask(void){++busy_reads;return observed_busy;}
unsigned yolo32_independent_head_mask(unsigned w){(void)w;return 63;}
unsigned yolo32_stage(unsigned w){(void)w;return 0;}
int yolo32_graph_poll(unsigned w,Yolo32Result *r){(void)w;(void)r;return YOLOV5NU_DIM16_HEAD_READY;}
void yolo32_task_switch(Yolo32TaskContext *from,const Yolo32TaskContext *to){
 assert(from==&tasks[0].context&&to==&scheduler);++switches;
}
static void reset_choice(void){
 memset(tasks,0,sizeof(tasks));memset(&stats,0,sizeof(stats));
 current=0;next_worker=1;primed_mask=7;completed_mask=0;profiling=0;
 tasks[0].packets=1;tasks[0].policy_start=tick;
 observed_busy=7;observed_ready=switches=busy_reads=0;yolo32_independent_enabled=1;
}
int main(void){
 /* The first round-robin peer is busy, while the second can feed idle hardware. */
 reset_choice();observed_busy=3;maybe_yield(1);
 assert(switches==1);
 if(YOLO32_IDLE_PRIORITY)assert(next_worker==2&&stats.idle_yields==1&&!stats.packet_yields);
 else assert(next_worker==1&&stats.packet_yields==1&&!stats.idle_yields);
 /* First packets still bootstrap the unprimed worker before applying preference. */
 reset_choice();primed_mask=5;observed_busy=3;maybe_yield(1);
 assert(next_worker==1&&stats.bootstrap_yields==1);
 /* Busy means a preference, not admission: all busy workers remain runnable. */
 reset_choice();maybe_yield(1);assert(switches==1&&next_worker==1&&stats.packet_yields==1);
 /* An idle indication cannot resume a dependency whose completion is unproven. */
 reset_choice();observed_busy=3;tasks[2].state=WAITING;maybe_yield(1);
 assert(switches==1&&next_worker==1&&!stats.idle_yields);
 reset_choice();observed_busy=3;observed_ready=4;tasks[2].state=WAITING;maybe_yield(1);
 assert(switches==1&&next_worker==(YOLO32_IDLE_PRIORITY?2U:1U));
 /* No eligible peer keeps the current task and avoids a busy survey. */
 reset_choice();tasks[1].state=tasks[2].state=WAITING;maybe_yield(1);
 assert(!switches&&!busy_reads&&stats.no_peer==1&&stats.command_kept==1);
 /* Ties preserve the rotating start rather than always selecting worker 1. */
 reset_choice();observed_busy=1;next_worker=2;maybe_yield(1);assert(next_worker==2);
 puts("PASS: idle selection, bootstrap, completion filtering, busy fallback and rotating ties");
}
''')
        for idle in (0,1):
            exe=self.root/f'idle-choice-{idle}'
            args=self.args+['-DYOLO32_SCHED_ADAPTIVE=0','-DYOLO32_SUBMIT_BURST=1',
                            '-DYOLO32_HOT_PATHS=1',f'-DYOLO32_IDLE_PRIORITY={idle}']
            subprocess.run(['gcc']+args+[str(src),'-o',str(exe)],check=True,capture_output=True)
            r=subprocess.run([exe],check=True,capture_output=True,text=True,timeout=15)
            self.assertIn('PASS: idle selection',r.stdout)

    def test_tail_wait_merge_keeps_ingress_handoff_and_rejects_bad_annotations(self):
        source=(self.local/'test.c').read_text()
        source=source.replace('for(unsigned tile=0;tile<3;tile++)packet(15,tile);',
            'for(unsigned tile=0;tile<3;tile++){if(tile==2)yolo32_independent_arm_tail_wait(15);packet(15,tile);}')
        source=source.replace('packet(8,10+tile*4+part);yolo_profile_fence();',
            'yolo32_independent_arm_tail_wait(8);packet(8,10+tile*4+part);yolo_profile_fence();')
        source=source.replace('packet(8,99);yolo_profile_fence();',
            'yolo32_independent_arm_tail_wait(8);packet(8,99);yolo_profile_fence();')
        source=source.replace('assert(s->done_mask==7);',
            'assert(s->done_mask==7);assert(s->tail_deferred==30&&s->tail_wait_merges==30);'
            'assert(s->tail_conv_merges==3&&s->tail_ws_merges==27);')
        marker=' if(stage[w]==0){\n   /* Ordinary convolution:'
        faults=r'''
 if(stage[w]==0&&w==0&&yolo32_independent_enabled&&getenv("TAIL_FAULT")){
   const char *fault=getenv("TAIL_FAULT");
   if(!strcmp(fault,"kind"))yolo32_independent_arm_tail_wait(99);
   yolo32_independent_arm_tail_wait(15);
   if(!strcmp(fault,"rearm"))yolo32_independent_arm_tail_wait(15);
   if(!strcmp(fault,"packet"))yolo_profile_fence();
   if(!strcmp(fault,"wrong"))packet(8,1);
   packet(15,1);
   if(!strcmp(fault,"wait"))packet(15,2);
   if(!strcmp(fault,"end")){heads[w]=63;stage[w]=167;return YOLOV5NU_DIM16_HEAD_READY;}
   abort();
 }
'''
        self.assertIn(marker,source)
        source=source.replace(marker,faults+marker)
        src=self.local/'tail-test.c';src.write_text(source)
        args=[a.replace('YOLO32_CONTEXT_FULL=1','YOLO32_CONTEXT_FULL=0') for a in self.args]
        args+=['-DYOLO32_SCHED_ADAPTIVE=0','-DYOLO32_SUBMIT_BURST=1','-DYOLO32_HOT_PATHS=1',
               '-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1','-DYOLO32_TAIL_WAIT=1']
        exe=self.root/'tail-test'
        subprocess.run(['gcc']+args+[str(self.local/'independent.c'),str(src),'-o',str(exe)],check=True,capture_output=True)
        r=subprocess.run([exe],check=True,capture_output=True,text=True,timeout=15)
        self.assertIn('PASS: native order',r.stdout)
        for fault,reason in [('kind','tail_packet_kind'),('rearm','tail_packet_rearmed'),
                             ('packet','tail_packet_missing'),('wrong','tail_packet_kind'),
                             ('wait','tail_wait_missing'),('end','tail_wait_incomplete')]:
            with self.subTest(fault=fault):
                r=subprocess.run([exe],env=dict(os.environ,TAIL_FAULT=fault),capture_output=True,text=True,timeout=15)
                self.assertEqual(r.returncode,42)
                self.assertIn(reason,r.stderr)

    def test_full_native_rocc_streams_conv_splitk_and_resadd(self):
        self.exercise_full_native_rocc_streams(False)

    def test_fixed_packet_streams_across_task_switches(self):
        self.exercise_full_native_rocc_streams(True)

    def test_prepared_ws_and_luts_across_real_task_switches(self):
        self.exercise_full_native_rocc_streams(True,True)

    def test_early_ppu_scheduler_preserves_full_native_packets(self):
        self.exercise_full_native_rocc_streams(True,True,True)

    def test_head_clean_scheduler_preserves_full_native_packets(self):
        self.exercise_full_native_rocc_streams(True,True,True,True)

    def exercise_full_native_rocc_streams(self, fixed_packets, prepared=False, early=False, head_clean=False):
        # Use the real DIM32 header, FP16 packer and native GPU helpers. Only
        # the terminal RoCC instruction is replaced with a command recorder.
        out = self.root/'native'; (out/'include').mkdir(parents=True, exist_ok=True)
        generated=self.root/'generated'
        if fixed_packets:
            generated=self.root/'packet_generated'
            params=next(HERE.parents[3].glob('hw/soc/*/gen-collateral/include/gemmini_params*custom3*'))
            generate(generated,fixed_plans=True,params=params,fixed_packets=True,prepared_packets=prepared)
        header = (generated/'include/gemmini.h').read_text()
        header = header.replace('#include "rocc-software/src/xcustom.h"',
            '#include "rocc-software/src/xcustom.h"\n#undef ROCC_INSTRUCTION_0_R_R\n'
            '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) native_record((f),(uint64_t)(a),(uint64_t)(b))')
        (out/'include/gemmini.h').write_text(header)
        source = (self.local/'test.c').read_text().replace('[512]', '[10000]').replace('count[w]<512', 'count[w]<10000')
        old_poll = function(source, 'int yolo32_graph_poll(')
        source = source.replace('s->conv_requests[w]==(getenv("BURST_PROBE")?6U:3U)&&s->matmul_requests[w]==(getenv("BURST_PROBE")?0U:9U)',
            's->conv_requests[w]>0&&s->matmul_requests[w]>0')
        # The native helpers have no dummy vector seeds. RVV restoration is
        # exercised separately by the assembly test above.
        gpu = r'''
static unsigned parallel_collecting, parallel_pending;
static unsigned timed_commands;
static void native_record(unsigned f,uint64_t a,uint64_t b){
 unsigned w=selected;record(f,a,b);
 if(yolo32_task_switch_profile||(YOLO32_SCHED_ADAPTIVE&&yolo32_independent_enabled&&(f==15||f==11)))tick+=f==15?50:2;
 if(f==15)++accepted[w];
 if(f==15||f==8)ready_at[w]=tick+(w==0?1000U:300U);
}
#define gemmini_fence() yolo_profile_fence()
#define GEMMINI_LOOPCONV_CREDIT_ADMISSION 0
#define GEMMINI_POOL_RUNTIME_DISPATCH 1
static unsigned return_hooks;
static void native_return_hook(unsigned f){if(YOLO32_HOT_PATHS)assert(f==15||f==8);++return_hooks;yolo32_independent_command_return(f);}
static void native_elapsed(unsigned f,uint64_t start){
 if(!yolo32_task_switch_profile&&!(YOLO32_SCHED_ADAPTIVE&&yolo32_independent_enabled&&(f==15||f==11)))return;
 uint64_t elapsed=++tick-start;
 /* A return hook that yields before timing ends would include another task's
  * clock advances and fail this exact artificial-instruction-latency check. */
 assert(elapsed==(f==15?51U:3U));++timed_commands;
 yolo32_independent_command_elapsed(f,elapsed);
}
#define GEMMINI_POOL_COMMAND_CLOCK(f) ((yolo32_task_switch_profile||(YOLO32_SCHED_ADAPTIVE&&yolo32_independent_enabled&&((f)==15||(f)==11)))?++tick:UINT64_C(0))
#define GEMMINI_POOL_COMMAND_ELAPSED(f,start) native_elapsed(f,start)
PRODUCTION_RETURN_HOOK
#include "include/gemmini.h"
static elem_t input_buf[3][8000000],output_buf[3][8000000],weights_buf[8000000],lut0[256],lut1[256];
static acc_t biases[1024];
'''
        production = (HERE/'model.c').read_text()
        hook = production[production.index('#if YOLO32_SUPPLY_DIAG'):production.index('static unsigned parallel_mode')]
        gpu = gpu.replace('PRODUCTION_RETURN_HOOK',hook.replace('yolo32_independent_command_return','native_return_hook'))
        if fixed_packets:
            gpu += '''
static struct { uint64_t tile_groups,conv_groups; } parallel_stats;
static void parallel_sample_busy(void) {}
static void parallel_drain(void) { full_fence(); }
#include "fixed_conv_packets.inc"
'''
        if prepared:
            gpu += '#include "prepared_packets.inc"\n'
        original = MODEL.read_text()
        if fixed_packets:
            original = tail_wait_annotations(original)
        for name in ('add_gemmini_resadd_strided_i8', 'add_gemmini_shared_resadd_i8',
                     'gemmini_splitk_1x1_two_slice_i8', 'gemmini_splitk_1x1_two_slice_i8_spad_reuse',
                     'gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8', 'gemmini_splitk_1x1_multi_slice_i8'):
            begin = 'static void '+name+'('
            # Skip the one forward declaration of the strided add helper.
            pos = original.index(begin)
            if original.find(';', pos) < original.find('{', pos): pos = original.index(begin, pos+len(begin))
            gpu += function(original[pos:], begin)+'\n'
        gpu += 'int yolo32_graph_poll(unsigned w,Yolo32Result *r){(void)r;assert(selected==w);switch(stage[w]){\n'
        calls = re.findall(r'    tiled_conv_auto\(([^;]+)\);', original)
        if fixed_packets:
            calls = re.findall(r'    yolo32_fixed_conv\(([^;]+)\);', (generated/'parallel_model.inc').read_text())
        self.assertEqual(len(calls), 58)
        for s, call in enumerate(calls):
            args = [a.strip() for a in call.split(',')]
            if fixed_packets:
                args[1:5] = ['input_buf[w]', 'weights_buf', 'biases', 'output_buf[w]']
            else:
                args[17:21] = ['input_buf[w]', 'weights_buf', 'biases', 'output_buf[w]']
            conv='yolo32_fixed_conv' if fixed_packets else 'tiled_conv_auto'
            lut='yolo32_packed_silu_lut(packed_silu_luts[0])' if prepared else 'gemmini_config_silu_lut(lut0)'
            gpu += f'case {s}:{lut};gemmini_fence();{conv}('+','.join(args)+');gemmini_fence();break;\n'
        if prepared:
            import json
            manifest=json.loads((generated/'fixed_plans.json').read_text())
            bases=['input_buf[w]','input_buf[w]+10000','input_buf[w]+20000','input_buf[w]+30000',
                   'weights_buf','weights_buf+100000','biases','biases+512','output_buf[w]','output_buf[w]+300000']
            for s,(original_stage,plan) in enumerate(manifest['prepared_ws'].items(),58):
                bound=[base if original!='NULL' else 'NULL' for base,original in zip(bases,plan['bases'])]
                gpu += f'case {s}:yolo32_prepared_ws(&prepared_ws_plan_{original_stage},(const void *const[10]){{'+','.join(bound)+'});break;\n'
        else:
            gpu += r'''
case 58:gemmini_splitk_1x1_two_slice_i8(input_buf[w],input_buf[w]+1000,weights_buf,biases,output_buf[w],3000,32,64,.12f,.17f,.19f,SILU_LUT,.08f);break;
case 59:gemmini_splitk_1x1_two_slice_i8_spad_reuse(input_buf[w],input_buf[w]+1000,weights_buf,biases,output_buf[w],3000,32,64,.12f,.17f,.19f,SILU_LUT,.08f,false);
 gemmini_splitk_1x1_two_slice_i8_spad_reuse(input_buf[w],input_buf[w]+1000,weights_buf+4096,biases,output_buf[w]+200000,3000,32,64,.12f,.17f,.19f,SILU_LUT,.08f,true);break;
case 60:gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(input_buf[w],input_buf[w]+1000,weights_buf,biases,output_buf[w],lut0,32,.08f,weights_buf+4096,biases,output_buf[w]+200000,lut1,64,.09f,3000,32,.12f,.17f,.19f,SILU_LUT);break;
case 61:{const elem_t *in[]={input_buf[w],input_buf[w]+1000,input_buf[w]+2000,input_buf[w]+3000};int ch[]={32,16,32,16};float scales[]={.12f,.17f,.12f,.17f};
 gemmini_splitk_1x1_multi_slice_i8(in,ch,scales,4,weights_buf,biases,output_buf[w],3000,64,.19f,SILU_LUT,.08f);break;}
case 62:add_gemmini_resadd_strided_i8(input_buf[w],input_buf[w]+1000,output_buf[w],3000,33,65,.12f,.17f);break;
case 63:add_gemmini_shared_resadd_i8(input_buf[w],input_buf[w]+1000,output_buf[w],3000,33,.08f);break;
'''
        gpu += r'''
default:gemmini_fence();heads[w]=63;stage[w]=167;
 if(yolo32_independent_enabled&&w!=0&&stage[0]<167)saw_early_finish=1;return YOLOV5NU_DIM16_HEAD_READY;
}stage[w]++;return YOLOV5NU_DIM16_RUNNING;}
'''
        source = source.replace(old_poll, gpu)
        if early:
            source += '''
void yolo32_ppu_early_service(void){
 const Yolo32IndependentStats *s=yolo32_independent_stats();
 for(unsigned w=0;w<3;w++)if(s->done_mask&(1U<<w)){
   assert(s->graph_done_cycle[w]);assert(yolo32_independent_finished(w));
 }
}
'''
        source = source.replace('puts("PASS: native order', 'assert(timed_commands>0);puts("PASS: native order')
        source = source.replace('yolo32_independent_begin(repeat==0);',
            'unsigned hook_start=return_hooks;yolo32_independent_begin(repeat==0);')
        source = source.replace('assert(s->done_mask==7);',
            'assert(s->done_mask==7);\n'
            'if(YOLO32_TAIL_WAIT){assert(s->tail_conv_merges==3*58&&s->tail_ws_merges>0);'
            'assert(s->tail_deferred==s->tail_wait_merges&&s->tail_wait_merges==s->tail_conv_merges+s->tail_ws_merges);}'
            'else assert(!s->tail_deferred&&!s->tail_wait_merges);\n'
            'if(YOLO32_HOT_PATHS)assert(return_hooks-hook_start=='
            's->conv_requests[0]+s->conv_requests[1]+s->conv_requests[2]+'
            's->matmul_requests[0]+s->matmul_requests[1]+s->matmul_requests[2]);')
        source = source.replace('if(getenv("CPU_SLOW"))assert(s->time_yields>0);',
            'if(getenv("CPU_SLOW"))assert(s->time_yields>0);\n'
            'if(YOLO32_SCHED_ADAPTIVE)assert(s->feedback_commands==s->conv_requests[0]+s->conv_requests[1]+s->conv_requests[2]+s->matmul_requests[0]+s->matmul_requests[1]+s->matmul_requests[2]);else assert(!s->feedback_commands);')
        src = out/'native.c';src.write_text(source)
        params = next(HERE.parents[3].glob('hw/soc/*/gen-collateral/include/gemmini_params*custom3*'))
        exe = out/'native-test'
        args = [a.replace('YOLO32_TIMEOUT_SECONDS=1', 'YOLO32_TIMEOUT_SECONDS=20') for a in self.args]
        flags = ['-Wno-unused-function','-Wno-unused-parameter','-Wno-unused-variable',
                       '-Wno-sign-compare','-Wno-misleading-indentation', '-include',str(params), '-I'+str(out),
                       '-I'+str(self.local),'-I'+str(ABI.parent.parent),'-I'+str(ABI.parent),
                       '-I'+str(HERE.parents[3]/'sw/third_party/gemmini_v3/include'),
                       '-I'+str(HERE.parents[3]/'sw/third_party/gemmini_v3')]
        if fixed_packets:
            flags += ['-I'+str(generated), '-DYOLO32_FIXED_PLANS=1', '-DYOLO32_FIXED_PACKETS=1']
        if prepared:
            flags += ['-DYOLO32_PREPARED_PACKETS=1']
        if early:
            flags += ['-DYOLO32_PPU_EARLY=1']
        if head_clean:
            flags += ['-DYOLO32_PPU_HEAD_CLEAN=1']
        sources = [str(self.local/'independent.c'),str(src)]
        subprocess.run(['gcc']+args+flags+sources+['-lm','-o',str(exe)],check=True,capture_output=True)
        result = subprocess.run([exe],check=True,capture_output=True,text=True,timeout=30)
        self.assertIn('PASS: native order',result.stdout)
        if fixed_packets:
            for idle,tail in ((1,0),(0,1),(1,1)):
                mode_args = [a.replace('YOLO32_CONTEXT_FULL=1','YOLO32_CONTEXT_FULL=0') for a in args]
                mode_args += ['-DYOLO32_SCHED_ADAPTIVE=0','-DYOLO32_SUBMIT_BURST=1','-DYOLO32_HOT_PATHS=1',
                              f'-DYOLO32_IDLE_PRIORITY={idle}',f'-DYOLO32_TAIL_WAIT={tail}']
                subprocess.run(['gcc']+mode_args+flags+sources+['-lm','-o',str(exe)],check=True,capture_output=True)
                result=subprocess.run([exe],check=True,capture_output=True,text=True,timeout=30)
                self.assertIn('PASS: native order',result.stdout)
        if self.riscv_available:
            exe = out/'native-riscv-test'
            switch_obj = out/'native-task-switch.o'
            modes=[(1,1,2,0,0,0),(0,1,2,0,0,0),(0,0,1,0,0,0),(0,0,1,1,0,0)]
            if fixed_packets: modes += [(0,0,1,1,1,0),(0,0,1,1,0,1),(0,0,1,1,1,1)]
            if prepared: modes=[(0,0,1,1,1,1)]
            for full,adaptive,burst,hot,idle,tail in modes:
                with self.subTest(context='full' if full else 'light',adaptive=adaptive,burst=burst,hot_paths=hot,idle_priority=idle,tail_wait=tail):
                    mode_args=[a.replace('YOLO32_CONTEXT_FULL=1',f'YOLO32_CONTEXT_FULL={full}') for a in args]
                    mode_args += [f'-DYOLO32_SCHED_ADAPTIVE={adaptive}',f'-DYOLO32_SUBMIT_BURST={burst}',f'-DYOLO32_HOT_PATHS={hot}',
                                  f'-DYOLO32_IDLE_PRIORITY={idle}',f'-DYOLO32_TAIL_WAIT={tail}']
                    subprocess.run([str(TOOLCHAIN/'riscv64-unknown-linux-gnu-gcc'),
                                   '-march=rv64gcv','-mabi=lp64d',f'-DYOLO32_CONTEXT_FULL={full}',
                                   '-c',str(self.local/'task_switch.S'),'-o',str(switch_obj)],check=True,capture_output=True)
                    subprocess.run([str(TOOLCHAIN/'riscv64-unknown-linux-gnu-gcc'),'-static','-march=rv64gcv','-mabi=lp64d']+
                                   mode_args+flags+sources+[str(switch_obj),'-lm','-o',str(exe)],check=True,capture_output=True)
                    result = subprocess.run([self.qemu,'-cpu','rv64,v=true,vlen=256',exe],check=True,capture_output=True,text=True,timeout=30)
                    self.assertIn('PASS: native order',result.stdout)

    def test_completion_covers_ingress_retirement_and_writer(self):
        ready = function((HERE/'model.c').read_text(), 'unsigned yolo32_independent_ready(')
        pre = r'''
#include <stdint.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
static uint32_t independent_accepted_base[3]={UINT32_MAX,UINT32_MAX,UINT32_MAX};
static unsigned selected=2, status, accepted=1,retired=1,writer_busy;
static uint64_t independent_status_read(unsigned w){assert(w<3);return status;}
static uint32_t independent_counter_read(unsigned w,unsigned r){assert(w<3);return r?retired:accepted;}
static unsigned read_worker_busy(unsigned w){assert(w<3);return writer_busy;}
static void yolo32_fail(const char *s){puts(s);exit(42);}
'''
        main = r'''
int main(int argc,char **argv){
 if(argc>1){status=(unsigned)strtoul(argv[1],0,0);yolo32_independent_ready(0,2);return 1;}
 unsigned pending[]={1,4,0x100,0x400,0x1000};
 for(unsigned w=0;w<3;w++){
   status=0;assert(yolo32_independent_ready(w,2));assert(selected==2);
   for(unsigned i=0;i<5;i++){status=pending[i];assert(!yolo32_independent_ready(w,2));}
   status=0;accepted=0;assert(!yolo32_independent_ready(w,2));accepted=1;
   retired=0;assert(!yolo32_independent_ready(w,2));retired=1;
   writer_busy=1;assert(!yolo32_independent_ready(w,2));writer_busy=0;
 }return 0;}
'''
        src=self.root/'completion.c';src.write_text(pre+ready+main);exe=self.root/'completion'
        subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror',str(src),'-o',str(exe)],check=True,capture_output=True)
        subprocess.run([exe],check=True,capture_output=True)
        for status in ('0x4000','0x8000'):
            result=subprocess.run([exe,status],capture_output=True,text=True)
            self.assertEqual(result.returncode,42)
            self.assertIn('independent_ingress_error',result.stdout)

    def test_real_riscv_vector_context_switch(self):
        if not self.riscv_available: self.skipTest('RISC-V Linux compiler/QEMU unavailable')
        result = subprocess.run([self.qemu, '-cpu', 'rv64,v=true,vlen=256', self.riscv],
                                check=True, capture_output=True, text=True, timeout=30)
        self.assertIn('FP/RVV switch', result.stdout)

    def test_real_riscv_light_context_and_reinitialized_rvv_kernels(self):
        if not self.riscv_available: self.skipTest('RISC-V Linux compiler/QEMU unavailable')
        for mode in (None, 'BURST_PROBE', 'CPU_SLOW', 'LATENCY_PROBE', 'LATENCY_FAST', 'LATENCY_CONFIG'):
            with self.subTest(mode=mode):
                env=dict(os.environ, **({mode:'1'} if mode else {}))
                if mode in ('LATENCY_PROBE','LATENCY_FAST'): env['BURST_PROBE']='1'
                result = subprocess.run([self.qemu, '-cpu', 'rv64,v=true,vlen=256', self.riscv_light],
                                        env=env,check=True,capture_output=True,text=True,timeout=30)
                self.assertIn('FP/RVV switch',result.stdout)

    def test_light_assembly_does_not_access_vector_storage(self):
        if not self.riscv_available: self.skipTest('RISC-V Linux compiler/QEMU unavailable')
        # Put the vector save area in an inaccessible page. A light switch must
        # still round-trip stack/FP/VCSR correctly without touching that page.
        src=self.root/'light-guard.c'
        src.write_text(r'''
#define _GNU_SOURCE
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include "independent.h"
unsigned yolo32_task_switch_profile=1;
volatile uint64_t yolo32_task_switch_cycles,yolo32_task_switch_count;
static Yolo32TaskContext *main_ctx,*worker_ctx;
static uint8_t stack[16384] __attribute__((aligned(16)));
static unsigned done;
static Yolo32TaskContext *guarded(void){
 long n=sysconf(_SC_PAGESIZE);assert(n>=4096);
 uint8_t *p=mmap(NULL,2*n,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 assert(p!=MAP_FAILED);assert(!mprotect(p+n,n,PROT_NONE));
 Yolo32TaskContext *c=(void *)(p+n-240);memset(c,0,240);return c;
}
static void worker(void){
 register double hold __asm__("fs11")=11.25;
 __asm__ volatile("":"+f"(hold));
 __asm__ volatile("csrwi vcsr,3\n\tcsrwi fcsr,16":::"memory");
 yolo32_task_switch(worker_ctx,main_ctx);
 __asm__ volatile("":"+f"(hold));assert(hold==11.25);
 uintptr_t v,f;
 __asm__ volatile("csrr %0,vcsr\n\tcsrr %1,fcsr":"=r"(v),"=r"(f));
 assert(v==3&&f==16);done=1;yolo32_task_switch(worker_ctx,main_ctx);abort();
}
int main(void){
 main_ctx=guarded();worker_ctx=guarded();
 worker_ctx->ra=(uintptr_t)worker;worker_ctx->sp=(uintptr_t)(stack+sizeof(stack));
 __asm__ volatile("csrwi vcsr,0\n\tcsrwi fcsr,0":::"memory");
 yolo32_task_switch(main_ctx,worker_ctx);assert(!done);
 __asm__ volatile("csrwi vcsr,7\n\tcsrwi fcsr,1":::"memory");
 yolo32_task_switch(main_ctx,worker_ctx);assert(done);
 uintptr_t v,f;
 __asm__ volatile("csrr %0,vcsr\n\tcsrr %1,fcsr":"=r"(v),"=r"(f));assert(v==7&&f==1);
 assert(yolo32_task_switch_count==4&&yolo32_task_switch_cycles>0);
 puts("PASS: guarded vector storage, stack, FP, FCSR and VCSR");return 0;
}
''')
        exe=self.root/'light-guard'
        subprocess.run([str(TOOLCHAIN/'riscv64-unknown-linux-gnu-gcc'),'-static','-O2',
                        '-march=rv64gcv','-mabi=lp64d','-DYOLO32_CONTEXT_FULL=0',
                        '-I'+str(self.local),str(src),str(self.local/'task_switch.S'),'-o',str(exe)],
                       check=True,capture_output=True)
        result=subprocess.run([self.qemu,'-cpu','rv64,v=true,vlen=256',exe],
                              check=True,capture_output=True,text=True,timeout=30)
        self.assertIn('PASS: guarded vector storage',result.stdout)

    def test_timeout_ingress_error_and_stack_guard(self):
        for fault, reason in [('STUCK', 'independent_timeout'), ('INGRESS_ERROR', 'independent_ingress_error'),
                              ('BAD_STACK', 'independent_stack_pointer')]:
            with self.subTest(fault=fault):
                result = subprocess.run([self.host], env=dict(os.environ, **{fault:'1'}), capture_output=True, text=True, timeout=15)
                self.assertEqual(result.returncode, 42, result.stderr)
                self.assertIn(reason, result.stderr)


if __name__ == '__main__': unittest.main()
