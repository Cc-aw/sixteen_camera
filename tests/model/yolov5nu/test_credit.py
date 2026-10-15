from paths import HERE, source_path, RISCV_LINUX_CC
"""Real scheduler + packet emitter with delayed ingress/retirement, on host and RVV QEMU."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

from generate_parallel import function
from credit_log import validate


class CooperativeCredit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='yolo32-credit-')
        root = cls.root = Path(cls.tmp.name)
        local = cls.local = root/'triple32'
        local.mkdir(); (root/'dim16_dual').mkdir()
        for name in ('independent.c','independent.h', 'diagnostics.h','task_context_config.h','task_switch.S','yolo32.h','ppu.h'):
            shutil.copy(source_path(name),local/name)
        for name in ('yolov5nu_dim16_dual.h','yolov5nu_head_layout.h'):
            shutil.copy(source_path('native/'+name),local/name)
        (local/'mmio.h').write_text('#include <stdint.h>\nextern uint64_t tick;\nstatic inline uint64_t read_cycle(void){return ++tick;}\n')
        (local/'platform.h').write_text('#define SOC_CLOCK_HZ 1000000UL\n')
        adapter = (source_path('tests/test_independent.py')).read_text().split("switch = r'''",1)[1].split('static void seed_vector(',1)[0]
        model = (source_path('model.c')).read_text()
        ready = function(model,'unsigned yolo32_independent_ready(')
        credit = function(model,'unsigned yolo32_independent_credit_ready(')
        submit = function((source_path('fixed_packets_runtime.inc')).read_text(),'static inline void yolo32_packet_submit(')
        pre = r'''
#define _XOPEN_SOURCE 700
#include <assert.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#ifndef __riscv
#include <ucontext.h>
#endif
#include "independent.h"
#include "yolo32.h"
#include "mmio.h"
uint64_t tick;
static unsigned selected,stage[3],heads[3],posted[3],accepted_n[3],retired_n[3],packet_progress;
static uint32_t independent_accepted_base[3],counter_base[3];
static uint64_t accept_at[3][9],retire_at[3][9],dma_at[3];
static unsigned saw_peer_progress,saw_capacity_while_busy,max_observed;
struct command { unsigned f; uint64_t a,b; };
static struct command commands[3][100],expected[3][100];
static unsigned counts[3],expected_counts[3];
void yolo32_fail(const char *s){fprintf(stderr,"%s\n",s);exit(42);}
unsigned yolo32_stage(unsigned w){return stage[w];}
void yolo32_independent_select(unsigned w){assert(!packet_progress);selected=w;}
void yolo32_independent_snapshot(unsigned w){independent_accepted_base[w]=counter_base[w];}
unsigned yolo32_independent_head_mask(unsigned w){return heads[w];}
void yolo32_ppu_early_service(void){}
static void advance(unsigned w){
 while(accepted_n[w]<posted[w]&&tick>=accept_at[w][accepted_n[w]])++accepted_n[w];
 while(retired_n[w]<accepted_n[w]&&tick>=retire_at[w][retired_n[w]])++retired_n[w];
}
static uint32_t independent_counter_read(unsigned w,unsigned retired){
 advance(w);
 if(retired&&getenv("BAD_RETIRED"))return counter_base[w]+posted[w]+1U;
 return counter_base[w]+(retired?retired_n[w]:accepted_n[w]);
}
static uint64_t independent_status_read(unsigned w){
 advance(w);
 if(getenv("INGRESS_ERROR")&&w==0)return 0xc000;
 if(getenv("STUCK")&&w==0)return 0;
 if(getenv("PARTIAL_STUCK")&&w==0)return 0x1000;
 /* No space for worker0 initially: it must yield so worker1 can advance. */
 if(w==0&&!posted[w]&&posted[1]<2)return 0;
 uint64_t status=accepted_n[w]-retired_n[w]<4?2:0;
 if(posted[w]>retired_n[w])status|=1;
 if(tick<dma_at[w])status|=0x10;
 return status;
}
/* busy=0 alone is deliberately weaker than the full dependency predicate. */
static unsigned read_worker_busy(unsigned w){(void)w;return 0;}
unsigned yolo32_independent_busy_mask(void){
 unsigned m=0;for(unsigned w=0;w<3;w++){advance(w);if(posted[w]>retired_n[w]||tick<dma_at[w])m|=1U<<w;}return m;
}
static void emit(unsigned f,uint64_t a,uint64_t b){
 unsigned w=selected;assert(counts[w]<100);commands[w][counts[w]++]=(struct command){f,a,b};
 if(f>=16&&f<=21){assert(f==16+packet_progress);++packet_progress;}
 if(f==15){
   assert(packet_progress==6);packet_progress=0;
   if(yolo32_independent_enabled){
     advance(w);assert(posted[w]-retired_n[w]<3);
     if(w==0&&!posted[w]){assert(posted[1]>=2);saw_peer_progress=1;}
     if(posted[w]>retired_n[w])saw_capacity_while_busy=1;
     unsigned n=posted[w]++;
     /* Accepted lags CPU issue; three posted packets can precede any accept. */
     accept_at[w][n]=tick+100;retire_at[w][n]=tick+700+20*w;
     dma_at[w]=retire_at[w][n]+60;
     unsigned pending=posted[w]-retired_n[w];if(pending>max_observed)max_observed=pending;
   }
 }
 if(f==8&&yolo32_independent_enabled)dma_at[w]=tick+100;
 yolo32_independent_command_return(f);
 assert(selected==w);
}
#define ROCC_INSTRUCTION_RS1_RS2(x,a,b,f) emit(f,(uint64_t)(a),(uint64_t)(b))
#define XCUSTOM_ACC 3
typedef int8_t elem_t;
typedef int32_t acc_t;
struct yolo32_conv_packet_plan {uint64_t config[6];};
struct yolo32_conv_packet {uint64_t geometry[6],launch[2];uint32_t offsets[4];};
static inline uint64_t yolo32_packet_address(const void *b,uint32_t o){return o==UINT32_MAX?0:(uintptr_t)b+o;}
'''
        body = r'''
static void conv(unsigned tile){
 const struct yolo32_conv_packet_plan plan={{1,2,3,4,5,6}};
 const struct yolo32_conv_packet p={{101,102,103,104,105,106},{7,8},{tile,2*tile,UINT32_MAX,4*tile}};
 uintptr_t base=10000*(selected+1);
 yolo32_packet_submit(&plan,&p,(const int8_t *)(base+100),(const int8_t *)(base+200),
                     (const int32_t *)(base+300),(int8_t *)(base+400));
}
static void ws(void){
 unsigned w=selected;
 for(unsigned f=9;f<=13;f++)emit(f,500+w,600+f);
 emit(8,1,0);
}
int yolo32_graph_poll(unsigned w,Yolo32Result *r){
 (void)r;assert(selected==w);
 if(stage[w]==14){
   for(unsigned n=0;n<9;n++){
     if(n==8)yolo32_independent_arm_tail_wait(15);
     conv(n);
   }
   yolo32_independent_wait();
   assert(retired_n[w]==posted[w]&&tick>=dma_at[w]);
   ws();yolo32_independent_wait();assert(tick>=dma_at[w]);
   stage[w]=165;heads[w]=63;return YOLOV5NU_DIM16_RUNNING;
 }
 assert(stage[w]==165);yolo32_independent_wait();stage[w]=167;return YOLOV5NU_DIM16_HEAD_READY;
}
int main(void){
 /* Serial bypass preserves all operands and emits no credit probes. */
 for(unsigned w=0;w<3;w++){
   selected=w;for(unsigned n=0;n<9;n++)conv(n);ws();
   memcpy(expected[w],commands[w],sizeof(expected[w]));expected_counts[w]=counts[w];
 }
 for(unsigned repeat=0;repeat<2;repeat++){
   tick=0;max_observed=saw_peer_progress=saw_capacity_while_busy=0;
   memset(posted,0,sizeof(posted));memset(accepted_n,0,sizeof(accepted_n));memset(retired_n,0,sizeof(retired_n));
   memset(dma_at,0,sizeof(dma_at));memset(counts,0,sizeof(counts));memset(heads,0,sizeof(heads));
   for(unsigned w=0;w<3;w++){stage[w]=14;counter_base[w]=UINT32_MAX-4U;}
#ifndef __riscv
   memset(contexts,0,sizeof(contexts));contexts_used=0;
#endif
   yolo32_independent_begin(repeat==0);
   while(!yolo32_independent_step()){}
   yolo32_independent_end();
   const Yolo32IndependentStats *s=yolo32_independent_stats();
   assert(max_observed==3&&saw_peer_progress&&saw_capacity_while_busy);
   for(unsigned w=0;w<3;w++){
     assert(s->conv_requests[w]==9&&s->matmul_requests[w]==1);
     assert(s->credit_admitted[w]==9&&s->credit_max_pending[w]==3);
     assert(s->credit_yields[w]>0&&s->credit_resumes[w]==s->credit_yields[w]);
     assert(s->credit_checks[w]>=9+s->credit_blocked[w]);
     assert(s->credit_blocked[w]>=s->credit_yields[w]);
     assert(repeat?s->credit_check_cycles[w]==0:s->credit_check_cycles[w]>0);
     assert(repeat?s->credit_wait_cycles[w]==0:s->credit_wait_cycles[w]>0);
     assert(counts[w]==expected_counts[w]);
     for(unsigned n=0;n<counts[w];n++)assert(commands[w][n].f==expected[w][n].f&&commands[w][n].a==expected[w][n].a&&commands[w][n].b==expected[w][n].b);
   }
   uint64_t resumes=s->resumes[0]+s->resumes[1]+s->resumes[2];
   uint64_t credit_yields=s->credit_yields[0]+s->credit_yields[1]+s->credit_yields[2];
   assert(resumes==s->command_yields+s->stage_yields+s->wait_yields+credit_yields+3);
 }
 puts("PASS: credit=3; peer progresses; delayed accept; counter wrap; busy pipeline; complete packets/operands; DMA dependency; restart");return 0;
}
'''
        (local/'test.c').write_text(pre+ready+credit+adapter+submit+body)
        cls.flags=['-std=gnu11','-O2','-I'+str(local),'-DYOLO32_HOST_TASKS=1',
                   '-DYOLO32_CONTEXT_FULL=0','-DYOLO32_HOT_PATHS=1','-DYOLO32_SCHED_ADAPTIVE=0',
                   '-DYOLO32_SUBMIT_BURST=1','-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1',
                   '-DYOLO32_IDLE_PRIORITY=1','-DYOLO32_TAIL_WAIT=1','-DYOLO32_PREPARED_PACKETS=1',
                   '-DYOLO32_PPU_EARLY=1','-DYOLO32_PPU_HEAD_CLEAN=1','-DYOLO32_WAIT_REUSE=1',
                   '-DYOLO32_CREDIT_LIMIT=3','-DYOLO32_TIMEOUT_SECONDS=1']
        cls.host=root/'host'
        subprocess.run(['gcc']+cls.flags+[str(local/'test.c'),str(local/'independent.c'),'-o',str(cls.host)],check=True,capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def check_executable(self, command):
        result=subprocess.run(command,check=True,capture_output=True,text=True,timeout=30)
        self.assertIn('PASS: credit=3',result.stdout)
        for mode,reason in (('STUCK','independent_timeout'),('PARTIAL_STUCK','independent_timeout'),
                            ('INGRESS_ERROR','independent_ingress_error'),('BAD_RETIRED','credit_retired_or_budget')):
            result=subprocess.run(command,env=dict(os.environ,**{mode:'1'}),capture_output=True,text=True,timeout=30)
            self.assertEqual(result.returncode,42,result.stderr)
            self.assertIn(reason,result.stderr)

    def test_host_capacity_wait_delayed_accept_and_restart(self):
        self.check_executable([self.host])

    def test_actual_riscv_switch_preserves_credit_packet(self):
        cc=RISCV_LINUX_CC
        qemu=shutil.which('qemu-riscv64')
        if not cc.exists() or not qemu:self.skipTest('RISC-V compiler/QEMU unavailable')
        exe=self.root/'riscv'
        subprocess.run([cc,'-static','-march=rv64gcv','-mabi=lp64d']+self.flags+
                       [str(self.local/'test.c'),str(self.local/'independent.c'),str(self.local/'task_switch.S'),'-o',str(exe)],check=True,capture_output=True)
        self.check_executable([qemu,'-cpu','rv64,v=true,vlen=256',exe])


class CreditLog(unittest.TestCase):
    def example(self):
        return dict(credit_limit=3,mode='independent',analysis=1,graph=1000,
                    independent={f'requests{w}':'9' for w in range(3)},
                    credit={w:dict(worker=str(w),limit='3',admitted='9',checks='15',blocked='2',
                                   yields='1',resumes='1',max_pending='3',wait_cycles='10',check_cycles='5') for w in range(3)})

    def test_capacity_accounting_and_legal_zero_wait(self):
        validate(self.example())
        r=self.example()
        for row in r['credit'].values():row.update(yields='0',resumes='0',wait_cycles='0')
        validate(r)
        for key,value in (('admitted','8'),('max_pending','4'),('checks','10'),('resumes','2'),('check_cycles','0')):
            r=self.example();r['credit'][1][key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):validate(r)

    def test_records_required_and_disabled_modes_reject(self):
        for change in ({'credit_limit':0},{'mode':'forward'},{'credit':{}},{'analysis':0}):
            r=self.example();r.update(change)
            with self.subTest(change=change),self.assertRaises(ValueError):validate(r)


if __name__=='__main__':unittest.main()
