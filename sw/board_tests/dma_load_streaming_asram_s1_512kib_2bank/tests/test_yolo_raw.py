"""Inject errors at the end of the real Head/PAD byte comparator's range."""
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from prepare_yolo import function

HARNESS=r'''
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
static unsigned reference_ready,current_frame=2,current_lane=1;
static void text(const char *s){fputs(s,stdout);}
static void field(const char *s,uint64_t n){printf("%s%llu",s,(unsigned long long)n);}
static void at_fail(const char *reason,uint64_t value){printf("FAIL=%s value=%llu\n",reason,(unsigned long long)value);exit(1);}
@COMPARE@
int main(int argc,char **argv){
    unsigned fault=argc>1?(unsigned)atoi(argv[1]):0,ready=0;
    static uint8_t actual[907200],gold[907200];
    size_t bytes=fault==2?38400:907200;
    for(size_t i=0;i<bytes;i++)actual[i]=(uint8_t)(i*37+19);
    if(fault==3)reference_ready=1;
    diagnostic_compare(actual,gold,bytes,&ready,fault==2?"raw_pad_mismatch":"raw_head_mismatch");
    if(!ready||memcmp(actual,gold,bytes))return 10;
    reference_ready=1;
    if(fault==1||fault==2)actual[bytes-1]^=1;
    diagnostic_compare(actual,gold,bytes,&ready,fault==2?"raw_pad_mismatch":"raw_head_mismatch");
    puts("RAW_COMPARATOR_HOST_PASS");return 0;
}
'''


class RawComparison(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source=(ROOT/'src/yolov5_asram_main.c').read_text()
        out=ROOT/'build/tests';out.mkdir(parents=True,exist_ok=True)
        path=out/'yolo_raw.c';path.write_text(HARNESS.replace('@COMPARE@',function(source,'static void diagnostic_compare(')))
        cls.exe=out/'yolo_raw'
        subprocess.run([os.environ.get('HOST_CC','cc'),'-std=c11','-O2','-Wall','-Wextra','-Werror',str(path),'-o',str(cls.exe)],check=True)

    def test_frozen_golden_full_tail_and_missing_reference(self):
        good=subprocess.run([str(self.exe),'0'],capture_output=True,text=True)
        self.assertEqual(good.returncode,0,good.stdout+good.stderr)
        for fault,marker in ((1,'offset=907199'),(2,'offset=38399'),(3,'missing_raw_golden')):
            with self.subTest(fault=fault):
                result=subprocess.run([str(self.exe),str(fault)],capture_output=True,text=True)
                self.assertEqual(result.returncode,1,result.stdout+result.stderr)
                self.assertIn(marker,result.stdout)
                self.assertNotIn('RAW_COMPARATOR_HOST_PASS',result.stdout)


if __name__=='__main__':unittest.main()
