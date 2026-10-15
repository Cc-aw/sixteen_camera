from paths import HERE, source_path, RISCV_LINUX_CC
"""Replay every native convolution packet against full-header command recording."""
from pathlib import Path
import json
import re
import subprocess
import sys
import tempfile
import unittest

from generate_parallel import ABI, MODEL, generate
from test_fixed_plans import PARAMS


class FixedPacketsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='yolo32-packet-test-')
        out=cls.out=Path(cls.tmp.name)
        generate(out,fixed_plans=True,params=PARAMS,fixed_packets=True)
        # Full production header is the oracle, including native planner and
        # all conditional packing macros. Replace only terminal RoCC assembly.
        h=(out/'include/gemmini.h').read_text()
        h=h.replace('#include "rocc-software/src/xcustom.h"',
            '#include "rocc-software/src/xcustom.h"\n#undef ROCC_INSTRUCTION_0_R_R\n'
            '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) record(f,(uint64_t)(a),(uint64_t)(b))')
        (out/'include/gemmini.h').write_text(h)
        pre=r'''
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define YOLO32_FIXED_PLANS 1
#define YOLO32_FIXED_PACKETS 1
#define GEMMINI_POOL_RUNTIME_DISPATCH 1
#define GEMMINI_LOOPCONV_CREDIT_ADMISSION 0
#define GEMMINI_POOL_COMMAND_RETURN_HOOK(f) do { if((f)==15) packet_return(); } while(0)
static unsigned gemmini_pool_active_worker,parallel_collecting,parallel_pending;
static unsigned pass,counts[2][3],drains,hooks;
static struct {uint64_t tile_groups,conv_groups,requests[3],samples;} parallel_stats;
struct event {unsigned f;uint64_t a,b;};
static struct event records[2][3][10000];
static elem_t inputs[3][8000000],outputs[3][8000000],weights[8000000];
static acc_t biases[1024];
static void record(unsigned f,uint64_t a,uint64_t b){
 unsigned w=gemmini_pool_active_worker;assert(w<3&&counts[pass][w]<10000);
 /* The group stream must submit all seven instructions of a tile to the
  * same worker, then move to the next worker. Configuration is two per worker. */
 if(pass==1&&parallel_collecting==0&&getenv("GROUP")){
   unsigned total=counts[1][0]+counts[1][1]+counts[1][2];
   unsigned expected=total<6?total/2:((total-6)/7)%3;assert(w==expected);
 }
 records[pass][w][counts[pass][w]++]=(struct event){f,a,b};
 if(pass==1&&f==15)++parallel_stats.requests[w];
}
static void packet_return(void){++hooks;}
static void parallel_sample_busy(void){++parallel_stats.samples;}
static void parallel_drain(void){++drains;}
static void yolo32_fail(const char *s){puts(s);exit(23);}
#define gemmini_fence() abort()
#include "include/gemmini.h"
#include "fixed_plans_guard.inc"
#include "fixed_conv_packets.inc"
'''
        native=re.findall(r'    tiled_conv_auto\(([^;]+)\);',MODEL.read_text())
        fixed=re.findall(r'    yolo32_fixed_conv\(([^;]+)\);',(out/'parallel_model.inc').read_text())
        assert len(native)==len(fixed)==58
        main='int main(int argc,char **argv){ unsigned packets=0;\n'
        for index,(n,f) in enumerate(zip(native,fixed)):
            main+=' {\n'
            na=[a.strip() for a in n.split(',')]
            fa=[a.strip() for a in f.split(',')]
            assert len(na)==27 and len(fa)==5
            main+='memset(records,0,sizeof(records));memset(counts,0,sizeof(counts));memset(&parallel_stats,0,sizeof(parallel_stats));pass=0;parallel_collecting=parallel_pending=drains=hooks=0;\n'
            na[17:21]=['inputs[w]','weights','biases','outputs[w]']
            main+='for(unsigned w=0;w<3;++w){gemmini_pool_active_worker=w;tiled_conv_auto('+','.join(na)+');}\n'
            main+='pass=1;unsigned baseline_hooks=hooks;parallel_collecting=getenv("GROUP")!=NULL;\n'
            fa[1:5]=['inputs[w]','weights','biases','outputs[w]']
            main+='for(unsigned w=0;w<3;++w){gemmini_pool_active_worker=w;yolo32_fixed_conv('+','.join(fa)+');'
            main+='if(getenv("GROUP")){assert(counts[1][w]==0);if(argc>1&&!strcmp(argv[1],"duplicate"))yolo32_fixed_conv('+','.join(fa)+');}}\n'
            main+='''if(getenv("GROUP")) {
 if(argc>1&&!strcmp(argv[1],"incomplete"))parallel_pending=3;
 if(argc>1&&!strcmp(argv[1],"weights"))++fixed_parallel_args[2].weights;
 if(argc>1&&!strcmp(argv[1],"bias"))++fixed_parallel_args[2].bias;
 if(argc>1&&!strcmp(argv[1],"plan"))fixed_parallel_args[2].plan=NULL;
 parallel_execute();assert(!parallel_collecting&&!parallel_pending&&drains==1);
 assert(parallel_stats.conv_groups==1&&parallel_stats.samples==parallel_stats.tile_groups);
}
'''
            main+=f'for(unsigned w=0;w<3;++w){{if(counts[0][w]!=counts[1][w]||memcmp(records[0][w],records[1][w],counts[0][w]*sizeof(struct event))){{printf("FAIL convolution {index} worker%u\\n",w);return 1;}}packets+=(counts[1][w]-2)/7;}}\n'
            main+='assert(hooks-baseline_hooks==parallel_stats.requests[0]+parallel_stats.requests[1]+parallel_stats.requests[2]);\n'
            main+=' }\n'
        main+='assert(packets==3*469);puts("PASS: all 58 convolutions, 1407 native packets; full operands, FP16 scales, offsets, NULL reuse and packet boundaries");return 0;}\n'
        src=out/'stream.c';src.write_text(pre+main)
        flags=['-std=gnu11','-O2','-include',str(PARAMS),'-I'+str(out),'-I'+str(ABI.parent.parent),'-I'+str(ABI.parent)]
        flags+=['-I'+str(HERE.parents[3]/'sw/third_party/gemmini')]
        cls.exe=out/'stream'
        result=subprocess.run(['gcc']+flags+[str(src),'-lm','-o',str(cls.exe)],capture_output=True,text=True)
        if result.returncode:raise RuntimeError(result.stderr)

    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()

    def test_all_operands_three_independent_bases(self):
        result=subprocess.run([self.exe],check=True,capture_output=True,text=True)
        self.assertIn('PASS: all 58',result.stdout)

    def test_group_order_reuse_and_null_markers(self):
        import os
        result=subprocess.run([self.exe],env=dict(os.environ,GROUP='1'),check=True,capture_output=True,text=True)
        self.assertIn('1407 native packets',result.stdout)

    def test_descriptor_faults(self):
        import os
        for fault,reason in [('duplicate','duplicate_descriptor'),('incomplete','incomplete_descriptors'),
                             ('weights','field_weights'),('bias','field_bias'),('plan','packet_plan')]:
            with self.subTest(fault=fault):
                r=subprocess.run([self.exe,fault],env=dict(os.environ,GROUP='1'),capture_output=True,text=True)
                self.assertEqual(r.returncode,23)
                self.assertIn(reason,r.stdout)

    def test_reproducible_packets_and_runtime_excludes_dynamic_tile_planning(self):
        out=self.out
        names=['parallel_model.inc','fixed_plans_guard.inc','fixed_plans.json','fixed_conv_packets.inc','parallel_executor.inc']
        before={n:(out/n).read_bytes() for n in names}
        generate(out,fixed_plans=True,params=PARAMS,fixed_packets=True)
        self.assertEqual(before,{n:(out/n).read_bytes() for n in names})
        manifest=json.loads((out/'fixed_plans.json').read_text())
        self.assertEqual(manifest['packet_table_bytes'],37520)
        self.assertEqual(sum(len(p['tiles']) for p in manifest['fixed_packets'].values()),469)
        model=(out/'parallel_model.inc').read_text()
        self.assertNotIn('    tiled_conv(',model)
        self.assertNotIn('    tiled_conv_auto(',model)
        with self.assertRaises(ValueError):generate(out,fixed_packets=True)


if __name__=='__main__':unittest.main()
