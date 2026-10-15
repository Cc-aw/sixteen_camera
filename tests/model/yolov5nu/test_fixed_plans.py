from paths import HERE, source_path
"""Compare native/fixed Split-K operands and dependencies for the whole graph."""
from pathlib import Path
import json
import re
import subprocess
import sys
import tempfile
import unittest

from generate_parallel import ABI, MODEL, function, generate
from fixed_plans import graph_stages, hardware_parameters

PARAMS = next((HERE.parents[3] / 'hw/soc').glob(
    '*/gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h'))


class FixedPlansTests(unittest.TestCase):
    def test_splitk_all_operands_scales_reuse_and_fence_order(self):
        self.check_splitk_streams(False)

    def test_tail_annotations_all_thirteen_splitk_stages_keep_fence_order(self):
        self.check_splitk_streams(True)

    def check_splitk_streams(self, scheduled):
        with tempfile.TemporaryDirectory(prefix='yolo32-fixed-stream-') as tmp:
            out = Path(tmp)
            generate(out, fixed_plans=True, params=PARAMS, fixed_packets=scheduled)
            native = MODEL.read_text()
            fixed = (out/'parallel_model.inc').read_text()
            manifest = json.loads((out/'fixed_plans.json').read_text())
            self.assertEqual(len(manifest['ordinary']), 58)
            self.assertEqual(len(manifest['splitk']), 13)
            self.assertEqual(manifest['ordinary_packets_per_worker'], 469)
            stages = graph_stages(native)
            sp = function(ABI.read_text(), 'static void sp_tiled_matmul_ws(')
            sig = sp.split(') {', 1)[0]
            specs = [x.strip() for x in sig[sig.index('(')+1:].split(',')]
            names = [re.search(r'(\w+)$', x)[1] for x in specs]
            payload = [f'bits({n})' if 'scale' in n else f'(uint64_t)(uintptr_t){n}' for n in names]
            stub = sig + ') { record(1, (uint64_t[]){' + ','.join(payload) + '}, ' + str(len(names)) + '); }\n'
            declarations = fixed[fixed.index('struct yolo32_splitk_tile {'):fixed.index('#if DIM !=')]
            pre = r'''
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
typedef int8_t elem_t; typedef int32_t acc_t;
typedef float scale_t; typedef float scale_acc_t;
#define DIM 32
#define ACC_ROWS 2048
#define WS 1
#define SILU_LUT 6
#define MVIN_SCALE_IDENTITY 1.0f
static unsigned pass, counts[2];
static struct event { unsigned kind; uint64_t values[32]; } events[2][4096];
static uint64_t bits(float x) { uint32_t b; memcpy(&b,&x,4); return b; }
static void record(unsigned kind,const uint64_t *p,unsigned n) {
  assert(counts[pass]<4096 && n<=32);
  struct event *e=&events[pass][counts[pass]++]; e->kind=kind;
  if(n) memcpy(e->values,p,n*sizeof(*p));
}
#define gemmini_extended_config_ex(a,b,c,d,e,f) record(2,(uint64_t[]){a,b,c,d,e,f},6)
#define gemmini_extended_config_st(a,b,c) record(3,(uint64_t[]){a,b,bits(c)},3)
#define gemmini_extended3_config_ld(a,b,c,d) record(4,(uint64_t[]){a,bits(b),c,d},4)
#define gemmini_fence() record(5,NULL,0)
static void gemmini_config_silu_lut(const elem_t *p) {record(6,(uint64_t[]){(uintptr_t)p},1);}
static elem_t inputs[4][4000000],weights0[1000000],weights1[1000000],outputs0[4000000],outputs1[4000000];
static acc_t biases0[512],biases1[512]; static elem_t lut0[256],lut1[256];
'''
            if scheduled:
                pre += '''
#define YOLO32_TAIL_WAIT 1
static unsigned yolo32_independent_enabled=1, pending_tail, tail_arms;
static void yolo32_independent_arm_tail_wait(unsigned f){assert(f==8&&!pending_tail);pending_tail=f;++tail_arms;}
'''
                stub=stub.replace('record(1,',
                    'if(pass){assert(pending_tail==8);pending_tail=0;}record(1,')
            helpers = sorted({p['helper'] for p in manifest['splitk'].values()})
            code = pre + declarations + stub
            for name in helpers:
                code += function(native, 'static void '+name+'(').replace(name+'(', 'native_'+name+'(', 1) + '\n'
                code += function(fixed, 'static void '+name+'(').replace(name+'(', 'fixed_'+name+'(', 1) + '\n'
            main = 'int main(void) {\n'
            for stage, plan in manifest['splitk'].items():
                stage = int(stage)
                match = re.search(r'\b(gemmini_splitk_\w+)\(([^;]+)\);', stages[stage])
                name, args = match[1], [x.strip() for x in match[2].split(',')]
                if 'two_consumer' in name:
                    replace = {0:'inputs[0]',1:'inputs[1]',2:'weights0',3:'biases0',4:'outputs0',5:'lut0',
                               8:'weights1',9:'biases1',10:'outputs1',11:'lut1'}
                elif 'multi_slice' in name:
                    replace = {0:'source_inputs',1:'channels',2:'scales',4:'weights0',5:'biases0',6:'outputs0'}
                    main += '{ const elem_t *source_inputs[]={inputs[0],inputs[1],inputs[2],inputs[3]};\n'
                    for index, kind, var in [(1,'int','channels'),(2,'float','scales')]:
                        array = re.search(r'const '+kind+' '+args[index]+r'\[\] = \{([^}]+)\}', stages[stage])
                        main += f'const {kind} {var}[]={{'+array[1]+'};\n'
                else:
                    replace = {0:'inputs[0]',1:'inputs[1]',2:'weights0',3:'biases0',4:'outputs0'}
                args = [replace.get(i,a) for i,a in enumerate(args)]
                # Three separate inputs/base addresses exercise worker relocation.
                main += 'for(unsigned worker=0;worker<3;++worker) {\n'
                main += 'memset(counts,0,sizeof(counts)); memset(events,0,sizeof(events)); pass=0;\n'
                args = [a.replace('inputs[0]', 'inputs[worker]').replace('inputs[1]', 'inputs[(worker+1)%4]') for a in args]
                main += 'native_'+name+'('+','.join(args)+'); pass=1;\n'
                main += 'fixed_'+name+'('+','.join(args)+f',&splitk_plan_{stage});\n'
                main += f'if(counts[0]!=counts[1] || memcmp(events[0],events[1],counts[0]*sizeof(struct event))) {{printf("FAIL stage{stage} worker%u\\n",worker); return 1;}}\n'
                main += 'unsigned packets=0; for(unsigned i=0;i<counts[1];++i) packets+=events[1][i].kind==1;\n'
                main += f'assert(packets=={plan["packets"]});\n'
                main += '}\n'
                if 'multi_slice' in name:
                    main += '}\n'
            if scheduled: main += 'assert(tail_arms==3*184&&!pending_tail);\n'
            main += 'puts("PASS: all13 Split-K stages, operands/scales/NULL reuse/fence order"); return 0;}\n'
            src, exe = out/'test.c', out/'test'
            src.write_text(code + main)
            subprocess.run(['gcc','-O1','-std=c11',str(src),'-o',str(exe)],check=True,capture_output=True)
            result = subprocess.run([str(exe)],check=True,capture_output=True,text=True)
            self.assertIn('PASS: all13 Split-K',result.stdout)

    def test_reproducible_generation_and_parameter_mismatch_guard(self):
        with tempfile.TemporaryDirectory(prefix='yolo32-fixed-repro-') as tmp:
            out = Path(tmp)
            generate(out, fixed_plans=True, params=PARAMS)
            before = {p.name:p.read_bytes() for p in out.glob('*.*')}
            generate(out, fixed_plans=True, params=PARAMS)
            self.assertEqual(before,{p.name:p.read_bytes() for p in out.glob('*.*')})
            guard = (out/'fixed_plans_guard.inc').read_text()
            for dim in [32,64]:
                src = out/'guard.c'
                src.write_text(f'#define DIM {dim}\n#define BANK_NUM 8\n#define BANK_ROWS 2048\n#define ACC_ROWS 2048\n#define YOLO32_FIXED_PLANS 1\n'+guard)
                result = subprocess.run(['gcc','-std=c11','-c',str(src),'-o',str(out/'guard.o')],capture_output=True)
                self.assertEqual(result.returncode==0,dim==32)
            invalid = out/'params.h'
            invalid.write_text(PARAMS.read_text().replace('#define DIM 32','#define DIM 64'))
            with self.assertRaises(ValueError): hardware_parameters(invalid)


if __name__ == '__main__':
    unittest.main()
