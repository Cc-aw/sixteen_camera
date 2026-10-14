"""Compare all remaining WS stages and LUT uploads to the full native ABI."""
from pathlib import Path
import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(HERE))
from generate_parallel import ABI, MODEL, generate
from prepared_packets import stage_calls, lut_declarations, PARAM_SOURCE
from fixed_plans import function
from test_fixed_plans import PARAMS


class PreparedPacketsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='yolo32-prepared-test-')
        out=cls.out=Path(cls.tmp.name)
        generate(out,fixed_plans=True,params=PARAMS,fixed_packets=True,prepared_packets=True)
        header=(out/'include/gemmini.h').read_text().replace('#include "rocc-software/src/xcustom.h"',
            '#include "rocc-software/src/xcustom.h"\n#undef ROCC_INSTRUCTION_0_R_R\n'
            '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) record(f,(uint64_t)(a),(uint64_t)(b))')
        (out/'include/gemmini.h').write_text(header)
        native=MODEL.read_text()
        calls=stage_calls(native)
        luts=lut_declarations(PARAM_SOURCE.read_text())
        pre=r'''
#include <assert.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define YOLO32_FIXED_PLANS 1
#define YOLO32_FIXED_PACKETS 1
#define YOLO32_PREPARED_PACKETS 1
#define YOLO32_TAIL_WAIT 1
#define GEMMINI_POOL_RUNTIME_DISPATCH 1
#define GEMMINI_LOOPCONV_CREDIT_ADMISSION 0
static unsigned pass,counts[2],gemmini_pool_active_worker,parallel_collecting,parallel_pending;
static unsigned packet_at,packets[2],arms,merges,armed,tail_returned;
static unsigned yolo32_independent_enabled;
struct event{unsigned f;uint64_t a,b;};
static struct event events[2][4096];
static void record(unsigned f,uint64_t a,uint64_t b){
  assert(counts[pass]<4096);
  if(tail_returned){assert(f==255);tail_returned=0;++merges;}
  if(f==9){assert(!packet_at);packet_at=1;}
  else if(packet_at){
    static const unsigned sequence[]={9,10,11,12,13,8};
    assert(f==sequence[packet_at]);
    if(++packet_at==6){packet_at=0;++packets[pass];}
  }
  events[pass][counts[pass]++]=(struct event){f,a,b};
}
static void returned(unsigned f){
  if(f==8&&armed){assert(!packet_at);armed=0;tail_returned=1;}
}
static void yolo32_independent_arm_tail_wait(unsigned f){
  assert(pass==1&&yolo32_independent_enabled&&f==8&&!armed&&!tail_returned&&!packet_at);armed=1;++arms;
}
static void yolo32_fail(const char *reason){fprintf(stderr,"%s\n",reason);exit(23);}
#define GEMMINI_POOL_COMMAND_RETURN_HOOK(f) returned(f)
#define gemmini_fence() record(255,0,0)
#include "include/gemmini.h"
#include "fixed_plans_guard.inc"
#include "prepared_packets.inc"
static elem_t inputs[3][4][2000000],outputs[3][2][2000000],weights[2][1000000];
static acc_t biases[2][1024];
'''
        pre += ''.join(luts.values())
        for name in sorted({p['helper'] for p in calls.values()}):
            pre += function(native,'static void '+name+'(')+'\n'
        main='int main(int argc,char **argv){(void)argv;\n'
        main+='if(argc>1){const struct yolo32_prepared_ws_step s={99,0};const struct yolo32_prepared_ws_plan p={1,&s};yolo32_prepared_ws(&p,(const void *const[10]){0});return 1;}\n'
        names=sorted(luts,key=lambda n:int(n.removeprefix('yolov5nu_silu_lut')))
        for i,name in enumerate(names):
            main+='memset(events,0,sizeof(events));memset(counts,0,sizeof(counts));pass=0;'
            main+=f'gemmini_config_silu_lut({name});pass=1;yolo32_packed_silu_lut(packed_silu_luts[{i}]);'
            main+='assert(counts[0]==32&&counts[1]==32&&!memcmp(events[0],events[1],32*sizeof(struct event)));\n'
        for stage,p in calls.items():
            args=p['args'].copy()
            args=[re.sub(r'inputs\[(\d+)\]',r'inputs[w][\1]',a).replace('outputs[0]','dst0').replace('outputs[1]','outputs[w][1]') for a in args]
            bases=['inputs[w][0]','inputs[w][1]','inputs[w][2]','inputs[w][3]',
                   'weights[0]','weights[1]','biases[0]','biases[1]','dst0','outputs[w][1]']
            bases=[base if original!='NULL' else 'NULL' for base,original in zip(bases,p['bases'])]
            arrays=re.sub(r'inputs\[(\d+)\]',r'inputs[w][\1]',p['arrays'])
            main+='for(unsigned w=0;w<3;++w)for(unsigned alias=0;alias<2;++alias){\n'
            main+='elem_t *dst0=alias?inputs[w][0]:outputs[w][0];\n'+arrays
            main+='memset(events,0,sizeof(events));memset(counts,0,sizeof(counts));pass=0;yolo32_independent_enabled=0;\n'
            main+=p['helper']+'('+','.join(args)+');pass=1;yolo32_independent_enabled=1;\n'
            main+=f'yolo32_prepared_ws(&prepared_ws_plan_{stage},(const void *const[10]){{'+','.join(bases)+'});\n'
            main+=f'if(counts[0]!=counts[1]||memcmp(events[0],events[1],counts[0]*sizeof(struct event))){{fprintf(stderr,"stream mismatch stage {stage} worker %u alias %u\\n",w,alias);return 1;}}\n'
            main+='assert(!packet_at&&!armed&&!tail_returned);}\n'
        main+='assert(packets[0]==3*2*224&&packets[1]==packets[0]);assert(arms==3*2*191&&arms==merges);\n'
        main+='puts("PASS: all20 WS stages, full commands/FP16/scales/NULL/reuse/fences, three bases, aliased outputs, all69 SiLU tables");return 0;}\n'
        (out/'stream.c').write_text(pre+main)
        flags=['-std=gnu11','-O2','-include',str(PARAMS),'-I'+str(out),
               '-I'+str(ABI.parent.parent),'-I'+str(ABI.parent),
               '-I'+str(HERE.parents[3]/'sw/third_party/gemmini_v3')]
        cls.flags=flags
        cls.exe=out/'stream'
        r=subprocess.run(['gcc']+flags+[str(out/'stream.c'),'-lm','-o',str(cls.exe)],capture_output=True,text=True)
        if r.returncode:raise RuntimeError(r.stderr)

    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()

    def test_all_ws_operands_fences_aliases_and_lut_bytes(self):
        r=subprocess.run([self.exe],check=True,capture_output=True,text=True)
        self.assertIn('PASS: all20 WS stages',r.stdout)

    def test_invalid_generated_step_is_rejected(self):
        r=subprocess.run([self.exe,'bad-step'],capture_output=True,text=True)
        self.assertEqual(r.returncode,23)
        self.assertIn('prepared_ws_step',r.stderr)

    def test_real_riscv_native_fp16_stream_matches_host_generated_tables(self):
        compiler=Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-linux-gnu-gcc')
        qemu=shutil.which('qemu-riscv64')
        if not qemu or not compiler.exists():self.skipTest('RISC-V compiler/QEMU unavailable')
        exe=self.out/'stream-riscv'
        r=subprocess.run([str(compiler),'-static','-march=rv64gcv','-mabi=lp64d']+self.flags+
            [str(self.out/'stream.c'),'-lm','-o',str(exe)],capture_output=True,text=True)
        self.assertEqual(r.returncode,0,r.stderr)
        r=subprocess.run([qemu,'-cpu','rv64,v=true,vlen=256',str(exe)],check=True,capture_output=True,text=True,timeout=30)
        self.assertIn('PASS: all20 WS stages',r.stdout)

    def test_reproducible_tables_and_runtime_removes_native_preparation(self):
        names=['prepared_packets.inc','parallel_model.inc','fixed_plans_guard.inc','fixed_plans.json']
        before={n:(self.out/n).read_bytes() for n in names}
        generate(self.out,fixed_plans=True,params=PARAMS,fixed_packets=True,prepared_packets=True)
        self.assertEqual(before,{n:(self.out/n).read_bytes() for n in names})
        manifest=json.loads((self.out/'fixed_plans.json').read_text())
        self.assertEqual(len(manifest['prepared_ws']),20)
        self.assertEqual(len(manifest['prepared_ws_packets']),224)
        self.assertEqual(len(manifest['packed_silu_luts']),69)
        model=(self.out/'parallel_model.inc').read_text()
        poll=function(model,'int yolov5nu_dim16_worker_poll(')
        self.assertEqual(poll.count('yolo32_prepared_ws('),20)
        self.assertNotRegex(poll,r'\b(?:gemmini_splitk_\w+|add_gemmini_\w+|gemmini_config_silu_lut)\(')
        runtime=(HERE/'prepared_packets_runtime.inc').read_text()
        self.assertNotIn('float',runtime)
        self.assertNotIn('scale_t_to',runtime)
        self.assertNotIn('ceil_divide',runtime)
        with self.assertRaises(ValueError):generate(self.out,prepared_packets=True)


if __name__=='__main__':unittest.main()
