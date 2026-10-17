#!/usr/bin/env python3
"""Exercise the actual C result reporter with controlled output corruption."""
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from prepare import function


HARNESS=r'''
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
enum {FRAMES=12,ATSOFT_THREE_WAY=1};
#define YOLO32_FRONTEND_DIAG 2
struct PpuResult {uint32_t count,words[10][4];};
struct Frame {unsigned device,image,slot,host_next;uint64_t begin,end,graph_end;};
static struct PpuResult output[3][FRAMES];
static struct Frame frames[FRAMES];
static unsigned current_frame=11,current_lane=0;
static uint64_t batch_begin;
static void text(const char *s){fputs(s,stdout);}
static void field(const char *s,uint64_t n){printf("%s%llu",s,(unsigned long long)n);}
@REPORT@
int main(int argc,char **argv){
    unsigned fault=argc>1?(unsigned)atoi(argv[1]):0;
    for(unsigned f=0;f<FRAMES;f++){
        frames[f].device=f%3;frames[f].image=f%3;frames[f].slot=(f/3)%2;
        output[0][f].count=3;
        for(unsigned w=0;w<12;w++)output[0][f].words[w/4][w%4]=100+f*40+w;
    }
    memcpy(output[2],output[0],sizeof(output[0]));
    if(fault==1)output[2][2].words[3][1]^=1;
    if(fault==2)output[2][2].count++;
    if(fault==3)output[2][2].words[9][3]=99;
    if(fault==4){output[2][2].count++;output[2][8].words[0][0]^=1;}
    unsigned bad=report(2);
    printf("REPORT_BAD=%u FRAME=%u LANE=%u\n",bad,current_frame,current_lane);
    return 0;
}
'''


class Report(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source=(ROOT/'src/boundary_main.c').read_text()
        code=HARNESS.replace('@REPORT@',function(source,'static const char *executor_name(')+'\n'+function(source,'static unsigned report('))
        path=ROOT/'build/tests/report.c';path.parent.mkdir(exist_ok=True,parents=True);path.write_text(code)
        cls.exe=path.with_suffix('')
        subprocess.run([os.environ.get('HOST_CC','cc'),'-std=gnu11','-O2','-Wall','-Wextra','-Werror',str(path),'-o',str(cls.exe)],check=True)

    def run_fault(self,fault):
        return subprocess.check_output([str(self.exe),str(fault)],text=True)

    def test_matching_results(self):
        raw=self.run_fault(0)
        self.assertIn('REPORT_BAD=0',raw)
        self.assertNotIn('PPU_DIFF',raw)

    def test_word_count_and_tail_are_all_checked(self):
        for fault,word in [(1,13),(2,40),(3,39)]:
            with self.subTest(fault=fault):
                raw=self.run_fault(fault)
                self.assertIn('REPORT_BAD=1 FRAME=2 LANE=2',raw)
                diff=[line for line in raw.splitlines() if line.startswith('ATSOFT1,PPU_DIFF,')]
                self.assertEqual(len(diff),1)
                self.assertIn('frame=2,device=2,image=2,slot=0,word='+str(word)+',',diff[0])
                self.assertIn('expected_count=3',diff[0])

    def test_multiple_bad_frames_keep_first_context(self):
        raw=self.run_fault(4)
        self.assertIn('REPORT_BAD=2 FRAME=2 LANE=2',raw)
        self.assertEqual(raw.count('ATSOFT1,PPU_DIFF,'),2)


if __name__=='__main__':
    unittest.main(verbosity=2)
