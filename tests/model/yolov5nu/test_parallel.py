from paths import HERE, source_path
"""Compare all 58 native DIM32 tile streams with the generated three-way executor."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

from generate_parallel import ABI, MODEL, function, generate


class ParallelTiles(unittest.TestCase):
    FIXED_PLANS = False

    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='yolo32-tiles-')
        out = Path(cls.tmp.name)
        params = next((HERE.parents[3] / 'hw/soc').glob(
            '*/gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h'))
        generate(out, fixed_plans=cls.FIXED_PLANS, params=params)
        header = ABI.read_text()
        native = function(header, 'static void tiled_conv(\n')
        sig = native.split(') {', 1)[0]
        argspec = [p.strip() for p in sig[sig.index('(')+1:].split(',')]
        argnames = [re.search(r'(\w+)$', p)[1] for p in argspec]
        sp_sig = function(header, 'static void sp_tiled_conv(').split(') {', 1)[0]
        parts = [p.strip() for p in sp_sig[sp_sig.index('(')+1:].split(',')]
        names = [re.search(r'(\w+)$', p)[1] for p in parts]
        generated = (out / 'include/gemmini.h').read_text()
        decl = generated[generated.index('struct yolo32_conv_args {'):generated.index('static void tiled_conv(\n')]
        captured = function(generated, 'static void tiled_conv(\n').replace('tiled_conv(', 'captured_conv(', 1)
        pre = '''
#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
typedef int8_t elem_t; typedef int32_t acc_t; typedef float acc_scale_t;
enum tiled_matmul_type_t { OS,WS,CPU };
#define _STATIC static
#define ceil_divide_int(a,b) (((a)+(b)-1)/(b))
#define DIM 32
#define BANK_NUM 8
#define BANK_ROWS 2048
#define ACC_ROWS 2048
#define WEIGHT_STATIONARY 1
#define SILU_LUT 6
#define NO_ACTIVATION 0
#define conv_cpu(...) abort()
#define gemmini_extended_config_st(...) ((void)0)
#define gemmini_extended3_config_ex(...) ((void)0)
#define gemmini_fence() assert(pass == 0)
static unsigned gemmini_pool_active_worker, pass, count[2][3];
static unsigned parallel_collecting, parallel_pending, drains;
static struct { uint64_t tile_groups, conv_groups, requests[3], overlap_samples; } parallel_stats;
static void parallel_sample_busy(void) { ++parallel_stats.overlap_samples; }
static void parallel_drain(void) { ++drains; }
static void yolo32_fail(const char *s) { puts(s); exit(23); }
static elem_t inputs[3][8000000], weights_buf[8000000], outputs[3][8000000];
static acc_t biases[1024];
'''
        pre += 'struct tile {\n' + ''.join(p+';\n' for p in parts) + '};\nstatic struct tile records[2][3][10000];\n'
        pre += sp_sig + ') {\n if(pass==1) assert(gemmini_pool_active_worker == ((count[1][0]+count[1][1]+count[1][2])%3));\n struct tile *r=&records[pass][gemmini_pool_active_worker][count[pass][gemmini_pool_active_worker]++];\n assert(count[pass][gemmini_pool_active_worker]<10000);\n'
        pre += ''.join(' r->'+n+'='+n+';\n' for n in names) + 'if(pass==1) ++parallel_stats.requests[gemmini_pool_active_worker];\n}\n'
        pre += 'struct plan {\n' + ''.join(p+';\n' for p in argspec) + '};\nstatic struct plan plan;\n'
        pre += sig.replace('tiled_conv(', 'capture_plan(') + ') {\n' + ''.join('plan.'+n+'='+n+';\n' for n in argnames) + '}\n'
        planner = function(header, 'static int tiled_conv_total_spad_rows(') + '\n' + function(header, 'static void tiled_conv_stride_auto(').replace('    tiled_conv(', '    capture_plan(') + '\n' + function(header, '_STATIC void tiled_conv_auto(')
        calls = re.findall(r'    tiled_conv_auto\(([^;]+)\);', MODEL.read_text())
        assert len(calls) == 58
        fixed_calls = re.findall(r'    tiled_conv\(([^;]+)\);', (out/'parallel_model.inc').read_text()) if cls.FIXED_PLANS else []
        if cls.FIXED_PLANS:
            assert len(fixed_calls) == 58
        main = 'int main(int argc, char **argv) {\n'
        for index, call in enumerate(calls):
            args = [a.strip() for a in call.split(',')]
            assert len(args) == 27
            args[17:21] = ['inputs[0]', 'weights_buf', 'biases', 'outputs[0]']
            main += 'tiled_conv_auto('+','.join(args)+');\n'
            main += 'memset(count,0,sizeof(count)); memset(records,0,sizeof(records)); memset(&parallel_stats,0,sizeof(parallel_stats)); drains=0; parallel_pending=parallel_collecting=0; pass=0;\n'
            for w in range(3):
                fields = {n:'plan.'+n for n in argnames}
                fields.update(input=f'inputs[{w}]', output=f'outputs[{w}]')
                callargs = ','.join(fields[n] for n in argnames)
                main += f'gemmini_pool_active_worker={w}; tiled_conv({callargs});\n'
            if cls.FIXED_PLANS:
                # Baseline records came from the original runtime planner.
                # Use the actual generated fixed call for the optimized pass.
                fixed = [a.strip() for a in fixed_calls[index].split(',')]
                assert len(fixed) == 37
                fixed[27:31] = ['inputs[0]', 'weights_buf', 'biases', 'outputs[0]']
                main += 'capture_plan('+','.join(fixed)+');\n'
            main += 'pass=1; parallel_collecting=1;\n'
            for w in range(3):
                fields = {n:'plan.'+n for n in argnames}
                fields.update(input=f'inputs[{w}]', output=f'outputs[{w}]')
                callargs = ','.join(fields[n] for n in argnames)
                main += f'gemmini_pool_active_worker={w}; captured_conv({callargs}); assert(count[1][{w}]==0);\n'
                if w == 0:
                    main += f'if(argc>1 && !strcmp(argv[1],"duplicate")) captured_conv({callargs});\n'
            main += '''
if(argc>1 && !strcmp(argv[1],"incomplete")) parallel_pending=3;
if(argc>1 && !strcmp(argv[1],"shape")) ++parallel_args[2].in_channels;
if(argc>1 && !strcmp(argv[1],"weights")) ++parallel_args[2].weights;
parallel_execute();
assert(parallel_collecting==0 && parallel_pending==0 && drains==1);
'''
            main += f'for(unsigned w=0;w<3;w++) {{ if(count[0][w]!=count[1][w] || memcmp(records[0][w],records[1][w],count[0][w]*sizeof(struct tile))) {{ printf("FAIL layer {index} worker %u\\n",w); return 1; }} assert(parallel_stats.requests[w]==parallel_stats.tile_groups); }}\n'
            main += 'assert(parallel_stats.tile_groups==count[0][0] && parallel_stats.conv_groups==1 && parallel_stats.overlap_samples==parallel_stats.tile_groups);\n'
        main += 'puts("PASS: 58 DIM32 layers; three native/group tile streams, tails, addresses, NULL reuse markers and 0/1/2 ordering"); return 0; }\n'
        src = out / 'test.c'
        src.write_text(pre + decl + native + captured + (out / 'parallel_executor.inc').read_text() + planner + main)
        cls.exe = out / 'test'
        subprocess.run(['gcc', '-O1', '-std=c11', str(src), '-o', str(cls.exe)], check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_all_58_native_tile_streams(self):
        result = subprocess.run([self.exe], check=True, capture_output=True, text=True)
        self.assertIn('PASS: 58 DIM32 layers', result.stdout)

    def test_descriptor_faults(self):
        for fault, reason in [('duplicate', 'duplicate_descriptor'), ('incomplete', 'incomplete_descriptors'),
                              ('shape', 'field_in_channels'), ('weights', 'field_weights')]:
            with self.subTest(fault=fault):
                result = subprocess.run([self.exe, fault], capture_output=True, text=True)
                self.assertEqual(result.returncode, 23)
                self.assertIn(reason, result.stdout)


class FixedParallelTiles(ParallelTiles):
    FIXED_PLANS = True


if __name__ == '__main__':
    unittest.main()
