"""Run the real suite/batch/reset/report loops with explicit host fake devices."""
import json
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from prepare_yolo import function
from analyze_yolo import parse

HARNESS=r'''
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "build_config.h"
#include "ppu_run_sequence.h"
#define YOLO32_FRONTEND_DIAG 2
#define ATSOFT_THREE_WAY 1
enum {FRAMES=12,DMA_FIRST_COUNTER=8,DMA_LAST_COUNTER=34};
struct PpuResult {uint32_t count,words[10][4];};
struct Frame {unsigned device,image,slot,host_next;uint64_t begin,end,graph_end;};
static struct PpuResult output[3][FRAMES],reference_output[FRAMES];
static struct Frame frames[FRAMES];
static unsigned storage_profile,reference_ready,suite_round,suite_mode,suite_warmup,batch_sequence,executor;
static uint32_t ppu_run_sequence;
static unsigned run_frames=FRAMES,completed,host_calls,launches,use[3],memory_available=1;
static unsigned held_events,rr,irq_event,next_frame,current_frame,current_lane,current_phase;
static int bound[3];
static uint64_t batch_begin,pad_cycles,triple_samples,busy_samples,last_sample,irq_count,irq_cycles,irq_first_cycle;
static uint64_t host_service_cycles,head_publish_cycles,ppu_service_cycles,host_max_cycles;
static unsigned host_max_kind,host_max_phase;
static unsigned char memory_pad[1],memory_intermediate[1],conv_input_scratches[1],conv_output_scratches[1];
static unsigned char boundary_frames[1],memory_frames[1];
static uint64_t memory_abi=UINT64_C(0x4d50563300010001),ticks=1;
static unsigned dma_load_whole_window;
static uint64_t local_counts[3][2][20];static uint32_t gemmini_counts[3][35];
static unsigned hardware_mode;
static unsigned pad_checks[FRAMES],pad_bytes[FRAMES],head_checks[FRAMES];
static const unsigned YOLOV5NU_HEAD_PAYLOAD_BYTES=907200;
static uint64_t clock_cycle(void){return ++ticks;}
static void text(const char *s){fputs(s,stdout);}
static void number(uint64_t n){printf("%llu",(unsigned long long)n);}
static void field(const char *s,uint64_t n){text(s);number(n);}
@FAIL@
static void gf_publish(void){}
static uint64_t gf_read(unsigned lane,unsigned query,unsigned x){(void)lane;(void)x;return query==8?hardware_mode:0;}
static const char *storage_name(unsigned p){return p?"local_arena":"ddr_arena";}
static void yolo_fill_arenas(unsigned char c){(void)c;}
static void yolo_check_guards(void){}
static void memory_init(void){}
static void ppu_init(void){ppu_run_sequence=0;}
static void select_mode(unsigned mode){hardware_mode=mode;}
static void prepare_profile(unsigned profile){
    storage_profile=profile;
    text("ASRY1,PROFILE,storage=");text(storage_name(profile));field(",round=",suite_round);
    text(",prepare_cycles=1,plan_hash=42,tables=18,entries=10870,raw=10478,hosts=12,arena_bytes=2217600\n");
}
static void count_begin(void){memset(local_counts,0,sizeof(local_counts));memset(gemmini_counts,0,sizeof(gemmini_counts));}
static void count_end(unsigned active){
    for(unsigned lane=0;lane<active;lane++){
        gemmini_counts[lane][8]=12;gemmini_counts[lane][9]=12;
        if(storage_profile)for(unsigned port=0;port<2;port++){
            uint64_t *c=local_counts[lane][port];c[2]=12;c[3]=port==0?12:0;c[0]=c[1]=c[2]+c[3];
            c[12]=c[2];c[13]=c[3];c[18]=1;c[19]=1;
        }
    }
}
@PREPARE@
@REPORT@
static void boundary_report(unsigned e){(void)e;}
static void fake_frames(unsigned active){
    for(unsigned f=0;f<run_frames;f++){
        uint32_t run;
        if(ppu_run_next(&ppu_run_sequence,100,&run))at_fail("ppu_run_overflow",f);
        unsigned lane=f%active;use[lane]++;host_calls+=12;completed++;launches+=executor!=0;
        frames[f]=(struct Frame){.device=lane,.image=f%3,.slot=(f/active)%2,.host_next=12,
                                .begin=clock_cycle(),.end=clock_cycle(),.graph_end=clock_cycle()};
        output[executor][f].count=f%3+1;
        for(unsigned w=0;w<40;w++)output[executor][f].words[w/4][w%4]=(f%3)*40+w;
        if(getenv("FAKE_YOLO_DATA")&&storage_profile&&suite_mode==1&&executor==2)
            output[executor][f].words[9][3]^=1;
        pad_checks[f]=6;pad_bytes[f]=230400;head_checks[f]=1;
    }
}
static void serial_batch(void){fake_frames(1);}
static void parallel_batch(unsigned active){fake_frames(active);}
@BATCH@
int main(void){
@SUITE@
    return 0;
}
'''


class YoloSequence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        boundary=(ROOT/'src/yolo_boundary.c').read_text();main=(ROOT/'src/yolov5_asram_main.c').read_text()
        cls.code=HARNESS.replace('@FAIL@',function(boundary,'static void at_fail(const char *s,uint64_t v) {'))
        cls.code=cls.code.replace('@PREPARE@',function(boundary,'static void prepare_batch(void) {'))
        cls.code=cls.code.replace('@REPORT@',function(boundary,'static const char *executor_name(')+'\n'+function(boundary,'static unsigned report('))
        cls.code=cls.code.replace('@BATCH@','\n'.join(function(main,prefix) for prefix in
            ('static void batch_fields(', 'static void report_counts(', 'static uint64_t run_batch(')))
        body=main[main.index('    text("ASRY1,BUILD'):main.index('    for(;;)__asm__')]
        cls.code=cls.code.replace('@SUITE@',body.replace('schema=1,hardware=1','schema=1,hardware=0',1))
        cls.out=ROOT/'build/tests';cls.out.mkdir(parents=True,exist_ok=True)
        cls.manifest=json.loads((ROOT/'build/yolo_manifest.json').read_text())

    def execute(self,rounds=1,diagnostic=0,code=None,**env):
        stem='yolo_sequence_'+str(rounds)+'_'+str(diagnostic)
        source=self.out/(stem+'.c');source.write_text(code or self.code);exe=self.out/stem
        subprocess.run([os.environ.get('HOST_CC','cc'),'-std=gnu11','-O2','-Wall','-Wextra',
                        '-Werror','-Wno-unused-variable','-Wno-unused-function','-Wno-unused-parameter',
                        '-DYOLO_ROUNDS='+str(rounds),'-DYOLO_DIAGNOSTIC='+str(diagnostic),
                        '-I'+str(ROOT/'include'),'-I'+str(ROOT/'build/generated'),
                        str(source),'-o',str(exe)],check=True)
        return subprocess.run([str(exe)],capture_output=True,text=True,timeout=20,env=dict(os.environ,**env))

    def test_real_suite_two_profiles_four_modes_three_executors(self):
        for rounds,diagnostic in ((1,0),(2,0),(1,1)):
            with self.subTest(rounds=rounds,diagnostic=diagnostic):
                result=self.execute(rounds,diagnostic)
                self.assertEqual(result.returncode,0,result.stdout[-1000:]+result.stderr)
                parsed=parse(result.stdout,self.manifest,allow_synthetic=True)
                self.assertEqual(parsed['ppu_runs'],12+360*rounds)
                self.assertEqual(parsed['measured_records'],24*rounds)
                self.assertEqual(parsed['status'],'SYNTHETIC_TEST_PASS')
                self.assertEqual(parsed['performance'],'DIAGNOSTIC_ONLY' if diagnostic else 'MEASURED_SAME_BITSTREAM')
                with self.assertRaises(ValueError):parse(result.stdout,self.manifest)
                if rounds==1 and not diagnostic:
                    (self.out/'yolo_sequence_synthetic.log').write_text(result.stdout)

    def test_corruption_and_old_run_reset_cannot_pass(self):
        result=self.execute(FAKE_YOLO_DATA='1')
        self.assertEqual(result.returncode,1)
        self.assertIn('ATSOFT1,PPU_DIFF',result.stdout)
        self.assertNotIn('ASRY1,PASS',result.stdout)
        with self.assertRaises(ValueError):parse(result.stdout,self.manifest,allow_synthetic=True)
        result=self.execute(code=self.code.replace('static void prepare_batch(void) {',
                            'static void prepare_batch(void) { ppu_run_sequence=0;'))
        self.assertEqual(result.returncode,1)
        self.assertNotIn('ASRY1,PASS',result.stdout)

    def test_parser_rejects_missing_frames_counters_profiles_and_truncation(self):
        result=self.execute();self.assertEqual(result.returncode,0)
        rows=result.stdout.splitlines()
        for prefix in ('ATSOFT1,FRAME_END,','ASRY1,ASRAM,','ASRY1,DMA,','ASRY1,PROFILE,'):
            i=next(i for i,line in enumerate(rows) if line.startswith(prefix))
            for broken in ('\n'.join(rows[:i]+rows[i+1:]),'\n'.join(rows[:i]+[rows[i]]+rows[i:])):
                with self.assertRaises(ValueError):parse(broken,self.manifest,allow_synthetic=True)
        for broken in (result.stdout[:result.stdout.rfind('ASRY1,PASS,')],
                       result.stdout.replace(',run_before=12\n',',run_before=0\n',1),
                       result.stdout.replace(',c15=0,',',c15=1,',1),
                       result.stdout.replace('hardware_id='+self.manifest['config']['target']['hardware_build_id'],'hardware_id=0000000000000001',1),
                       result.stdout.replace('diagnostic=0','diagnostic=1',1),
                       result.stdout.replace('ppu_runs=372','ppu_runs=371')):
            self.assertNotEqual(broken,result.stdout,'Fault injection did not modify the log')
            with self.assertRaises(ValueError):parse(broken,self.manifest,allow_synthetic=True)


if __name__=='__main__':unittest.main()
