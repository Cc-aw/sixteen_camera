#!/usr/bin/env python3
"""Execute the real suite loops and allocation functions with fake devices.

No Gemmini arithmetic, hardware timing, or board performance is simulated.
"""
import os
from pathlib import Path
import resource
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from prepare import function
from analyze_dma_load import parse


HARNESS = r'''
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "platform/platform.h"
#include "ai/postprocess/ai_ppu_queue.h"
#include "ppu_run_sequence.h"
#define DMA_BOARD_BUILD_ID "synthetic-sequence-test"
#define DMA_ROUNDS 4
#define DMA_FIRST_COUNTER 8
#define DMA_LAST_COUNTER 34
#define YOLO32_FRONTEND_DIAG 2
enum {FRAMES=12,LANES=3};
struct Plan {unsigned ignored;};
struct Frame {unsigned device,image,slot,host_next,state;struct Plan *plan;uint64_t begin,end,graph_end;};
struct PpuResult {uint32_t count,words[10][4];};
static struct Plan plans[3][2][3];
static struct Frame frames[FRAMES];
static struct PpuResult output[3][FRAMES],ppu_result[3];
static AiHeadSlotQueue ppu_queue;
static unsigned ppu_keys[3],ppu_done[3],ppu_heads[3];
static uint64_t ppu_frame_base;
static uint32_t ppu_run_sequence;
static unsigned current_frame,current_lane,current_phase,executor,current_mode;
static unsigned use[3],next_frame,completed,held_events,rr,irq_event;
static unsigned run_frames=FRAMES,short_window_pass,memory_kind,memory_target;
static int bound[3];
static uint64_t batch_begin,launches,host_calls,pad_cycles,triple_samples,busy_samples,last_sample,irq_count,irq_cycles;
static uint64_t irq_first_cycle,host_service_cycles,head_publish_cycles,ppu_service_cycles,host_max_cycles;
static unsigned host_max_kind,host_max_phase,memory_available,dma_load_whole_window;
static uint64_t memory_abi,dma_identity,ticks=1000000,last_frame[3];
static uint32_t last_version[3],issued;
static const uint64_t dma_expected_build_id=UINT64_C(0x12345678);
static uint32_t dma_counts[LANES][35];
static const char *const dma_modes[3]={"legacy","read_coalesced","read_assembled"};
static unsigned char activation_arenas[1],memory_pad[1],memory_intermediate[1];
static unsigned char conv_input_scratches[1],conv_output_scratches[1],boundary_frames[1],memory_frames[1];
static uint64_t clock_cycle(void){return ++ticks;}
static void text(const char *s){fputs(s,stdout);}
static void number(uint64_t n){printf("%llu",(unsigned long long)n);}
static void field(const char *s,uint64_t n){text(s);number(n);}
static void at_fail(const char *s,uint64_t n){fprintf(stderr,"TEST_FAIL=%s value=%llu frame=%u lane=%u\n",s,(unsigned long long)n,current_frame,current_lane);exit(1);}
static void gf_publish(void){}
static uint64_t gf_read(unsigned d,unsigned q,unsigned x){(void)d;(void)x;return q==8?current_mode:q==10?dma_expected_build_id:0;}
static void dma_select(unsigned mode){assert(mode<3);current_mode=mode;}
static void prepare_model(void){}
static void memory_init(void){memory_available=1;memory_abi=UINT64_C(0x4d50563300010001);}
static uint32_t pget(unsigned o){return o==0x100?UINT32_C(0x50505531):o==0x148?1:0;}
static void pput(unsigned o,uint32_t v){(void)o;(void)v;}
int ai_ppu_publication_available(void){return 1;}
int ai_ppu_publication_begin(uintptr_t base){(void)base;return 1;}
int ai_ppu_queue_init(void){return 1;}
int ai_ppu_queue_peek(AiPpuQueueResult *r){(void)r;return 0;}
void ai_ppu_queue_pop(void){}
void ai_ppu_queue_expect(uint32_t d,uint64_t frame,uint32_t version){
    assert(d<3 && frame>last_frame[d] && version>last_version[d]);
    assert(version==issued+1 && frame==ppu_frame_base+version);
    last_frame[d]=frame;last_version[d]=version;issued++;
}
static uintptr_t head_address(unsigned d,unsigned slot){
    return AI_DDR_CPU_ALIAS(AI_MODEL_OUTPUT0_PHYS_BASE+d*AI_MODEL_OUTPUT_ARENA_BYTES+slot*YOLOV5NU_HEAD_SLOT_STRIDE);
}
static void memory_counter_begin(unsigned f,unsigned d){(void)f;(void)d;}
static unsigned report(unsigned e){(void)e;return 0;}
static void boundary_report(unsigned e){(void)e;puts("SYNTHETIC_BOUNDARY_REPORT");}
static void memory_finish(unsigned e,unsigned p,uint64_t c){(void)e;(void)p;(void)c;}
static void memory_counter_report(unsigned e,unsigned p,unsigned c){(void)e;(void)p;(void)c;}
static const char *executor_name(unsigned e){return e==1?"frontend_serial":"frontend_parallel";}
static void dma_count_begin(void){memset(dma_counts,0,sizeof(dma_counts));}
static void dma_count_end(void){
    for(unsigned d=0;d<3;d++)if(d==0||executor==2){
        dma_counts[d][8]=1;dma_counts[d][9]=1;dma_counts[d][33]=32;
        dma_counts[d][11]=current_mode!=0;dma_counts[d][21]=current_mode==2;
    }
}
@ALLOCATION@
@PREPARE@
static void parallel_batch(unsigned n){
    for(unsigned f=0;f<run_frames;f++){
        unsigned d=f%n;admit(f,d);
        assert(ai_head_slot_release_writing(&ppu_queue,ppu_keys[d])==0);
        bound[d]=-1;completed++;host_calls+=12;launches++;
    }
}
static void serial_batch(void){parallel_batch(1);}
@BATCH@
@PHASE@
static int tested_suite(void){
    int argc=0;char **argv=0;
@SUITE@
    assert(ppu_run_sequence==894 && issued==894);
    return 0;
}
int main(void){
    tested_suite();
    uint32_t last=UINT32_MAX,out=77;
    assert(ppu_run_next(&last,0,&out)==-1 && last==UINT32_MAX && out==77);
    last=0;
    assert(ppu_run_next(&last,UINT64_MAX,&out)==-1 && last==0 && out==77);
    assert(ppu_run_next(&last,UINT64_MAX-1,&out)==0 && last==1 && out==1);
    assert(ppu_run_next(&last,UINT64_MAX-1,&out)==-1 && last==1 && out==1);
    assert(ppu_run_next(NULL,0,&out)==-1);
    assert(ppu_run_next(&last,0,NULL)==-1);
    puts("HOST_SEQUENCE=PASS runs=894 overflow=checked synthetic_only=1");
    return 0;
}
'''


class Sequence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source=(ROOT/'src/boundary_main.c').read_text()
        ppu=(ROOT/'src/ppu.inc').read_text()
        main=(ROOT/'src/dma_load_model_main.c').read_text()
        phase=(ROOT/'src/memory_diag.inc').read_text()
        allocation='\n'.join(function(ppu, prefix) for prefix in
            ('static uint64_t pframe(', 'static void ppu_init(', 'static unsigned ppu_begin('))
        allocation+='\n'+function(source,'static void admit(')
        body=main[main.index('    (void)argc;(void)argv;'):main.index('    for(;;)__asm__')]
        body=body.replace('    volatile uint32_t *uart=(volatile uint32_t *)AT_UART_BASE;\n    uart[2]=1;uart[4]=0;uart[6]=867;\n','')
        cls.code=HARNESS.replace('@ALLOCATION@',allocation).replace('@PREPARE@',function(source,'static void prepare_batch(void) {'))
        cls.code=cls.code.replace('@BATCH@',function(main,'static void dma_report_counters(')+'\n'+function(main,'static uint64_t dma_batch('))
        cls.code=cls.code.replace('@PHASE@',function(phase,'static void memory_short_passes(')).replace('@SUITE@',body)
        cls.directory=ROOT/'build/tests';cls.directory.mkdir(parents=True,exist_ok=True)

    def compile_run(self,name,code):
        src=self.directory/(name+'.c');exe=self.directory/name;src.write_text(code)
        subprocess.run([os.environ.get('HOST_CC','cc'),'-std=gnu11','-O2','-Wall','-Wextra','-Werror',
                        '-Wno-unused-variable','-Wno-unused-parameter',
                        '-I'+str(ROOT/'include'),'-I'+str(ROOT/'model'),str(src),
                        str(ROOT/'model/ai/runtime/ai_head_slot_queue.c'),'-o',str(exe)],check=True)
        def disable_core():
            resource.setrlimit(resource.RLIMIT_CORE,(0,0))
        return subprocess.run([str(exe)],text=True,capture_output=True,timeout=20,preexec_fn=disable_core)

    def test_actual_whole_suite_and_overflow(self):
        result=self.compile_run('sequence',self.code)
        self.assertEqual(result.returncode,0,result.stderr)
        (self.directory/'model_sequence_synthetic.log').write_text(result.stdout)
        parsed=parse(result.stdout,0x12345678)
        self.assertEqual(parsed['ppu_runs'],894)
        self.assertEqual(parsed['measured_records'],24)
        self.assertIn('HOST_SEQUENCE=PASS',result.stdout)

    def test_batch_reset_negative_control(self):
        # Reintroduce the old executor-based sequence at each batch boundary.
        code=self.code.replace('static void prepare_batch(void) {',
             'static void prepare_batch(void) { ppu_run_sequence=executor*FRAMES;')
        result=self.compile_run('sequence_old_reset',code)
        self.assertNotEqual(result.returncode,0)
        self.assertIn('frame>last_frame[d]',result.stderr)

    def test_failed_batch_keeps_counters_and_actual_frame(self):
        code=self.code.replace('static unsigned report(unsigned e){(void)e;return 0;}',
             'static unsigned report(unsigned e){if(current_mode==1&&e==2){current_frame=2;current_lane=2;return 1;}return 0;}')
        result=self.compile_run('sequence_output_fault',code)
        self.assertEqual(result.returncode,1)
        self.assertIn('frame=2 lane=2',result.stderr)
        diagnostic=result.stdout.split('DMAL1,CHECK_FAILED,',1)[1]
        self.assertIn('mode=read_coalesced',diagnostic)
        self.assertIn('run_first=49,run_last=60',diagnostic)
        counters=[line for line in diagnostic.splitlines() if line.startswith('DMAL1,COUNTERS,')]
        self.assertEqual(len(counters),3)
        for lane,line in enumerate(counters):
            self.assertIn('lane='+str(lane)+',',line)
            self.assertIn('actual_mode=1',line)
        self.assertIn('SYNTHETIC_BOUNDARY_REPORT',result.stdout.split('DMAL1,BATCH_BEGIN,mode=read_coalesced,round=0,warmup=1,executor=2,')[1])
        self.assertNotIn('DMAL1,RESULT,mode=read_coalesced,round=0,warmup=1,executor=2,',result.stdout)


if __name__=='__main__':
    unittest.main(verbosity=2)
