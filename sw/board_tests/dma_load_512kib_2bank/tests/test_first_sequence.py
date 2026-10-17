#!/usr/bin/env python3
"""Execute the real first-layer suite loops with fake computation and counters."""
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from prepare import function
from analyze_dma_load import parse

HARNESS=r'''
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "dma_load_suite.h"
#define DMA_LOAD_EXPECTED_BUILD_ID UINT64_C(0x12345678)
#define DMA_BOARD_BUILD_ID "synthetic-first-sequence"
#define GF_DIRECT(...) ((void)0)
#ifndef TEST_CAPABILITY
#define TEST_CAPABILITY UINT64_C(0x1000f)
#endif
enum {LANES=3,OUTPUT_BYTES=1228800};
static const uint64_t dma_expected_build_id=DMA_LOAD_EXPECTED_BUILD_ID;
static unsigned dma_first_mode_count,current_mode,current_round,first_run_frames=3;
#define dma_first_modes dma_modes
static struct {unsigned char before[64],data[OUTPUT_BYTES],after[64];} gold[3],outputs[3];
static unsigned selected[3],last_parallel,last_count;
static void text(const char *s){fputs(s,stdout);}
static void number(uint64_t v){printf("%llu",(unsigned long long)v);}
static void field(const char *k,uint64_t v){text(k);number(v);}
static void fail(const char *s,uint64_t v){fprintf(stderr,"FAIL=%s,%llu\n",s,(unsigned long long)v);exit(1);}
static uint64_t gf_read(unsigned lane,unsigned q,unsigned unused){(void)lane;(void)unused;return q==7?TEST_CAPABILITY:q==8?current_mode:q==10?dma_expected_build_id:0;}
static void dma_first_select(unsigned mode){assert(mode<dma_first_mode_count);current_mode=mode;}
static void gf_publish(void){}
static void lut(unsigned lane){(void)lane;}
static void build(unsigned p,unsigned job,unsigned image,void *target){(void)p;(void)job;(void)image;(void)target;}
static void launch(unsigned p,unsigned job,unsigned lane){(void)p;(void)job;(void)lane;}
static void wait_lanes(unsigned mask){(void)mask;}
static void guards(void *before,void *after){(void)before;(void)after;}
static uint64_t counter(unsigned lane,unsigned config){
    if(config&UINT32_C(0x80000000)){selected[lane]=(config>>12)&127;return 0;}
    if(config==2)return 0;
    assert(config==0);
    if(last_parallel?lane>=last_count:lane!=0)return 0;
    unsigned id=selected[lane];
    if(id==31)return 0;
    if(id==11)return current_mode!=0;
    if(id==21)return current_mode>=2;
    return id==8||id==9||id==18||id==22||id==33?1:0;
}
static uint64_t run(unsigned p,unsigned parallel,unsigned round,unsigned warmup){
    assert(p==0 && first_run_frames==3);
    last_parallel=parallel;last_count=first_run_frames;
    uint64_t cycles=first_run_frames*(parallel?400:1000)/(current_mode+1);
    text("S2D1,RESULT,profile=reference,executor=");text(parallel?"parallel":"serial");
    field(",round=",round);field(",warmup=",warmup);field(",batch_cycles=",cycles);
    field(",frames=",first_run_frames);field(",compared_bytes=",first_run_frames*OUTPUT_BYTES);
    text(",pack_cycles=0,bit_exact=1\n");return cycles;
}
@RUN@
int main(void){
@MAIN@
    return 0;
}
'''

class FirstSequence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source=(ROOT/'src/dma_load_first_main.c').read_text()
        main=source[source.index('    uint64_t capability='):source.index('    for(;;)__asm__')]
        cls.code=HARNESS.replace('@RUN@',function(source,'static uint64_t dma_first_run(')).replace('@MAIN@',main)
        cls.out=ROOT/'build/tests';cls.out.mkdir(exist_ok=True,parents=True)

    def execute(self,count):
        src=self.out/f'first_sequence_{count}.c';exe=src.with_suffix('')
        src.write_text(('#define TEST_CAPABILITY UINT64_C(0x10007)\n' if count==3 else '')+self.code)
        subprocess.run([os.environ.get('HOST_CC','cc'),'-std=gnu11','-O2','-Wall','-Wextra','-Werror',
            '-I'+str(ROOT/'include'),str(src),'-o',str(exe)],check=True)
        return subprocess.check_output([str(exe)],text=True,timeout=10)

    def test_exact_twelve_frames_three_and_four_modes(self):
        for count in (3,4):
            raw=self.execute(count);result=parse(raw,0x12345678)
            self.assertEqual(result['frames_per_executor'],12)
            self.assertEqual(result['measured_records'],count*8)
            self.assertEqual(result['ablation'],'complete' if count==4 else 'missing_spad_only')
            self.assertEqual(len(result['aggregate']),count)
            with self.assertRaises(ValueError):parse(raw.replace(',frames=3,',',frames=2,',1))
            rows=raw.splitlines();at=next(i for i,r in enumerate(rows) if ',COUNTERS,' in r)
            with self.assertRaises(ValueError):parse('\n'.join(rows[:at]+rows[at+1:]))
            with self.assertRaises(ValueError):parse(raw[:raw.rfind('DMALF1,PASS,')])

if __name__=='__main__':unittest.main(verbosity=2)
