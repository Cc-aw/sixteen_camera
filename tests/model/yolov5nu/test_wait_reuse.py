from paths import HERE, source_path, RISCV_LINUX_CC
"""Prove static adjacency and exercise real scheduler completion/restart paths."""
from pathlib import Path
import copy
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

from generate_parallel import generate, function
from wait_reuse import annotate, STAGES, SITES_PER_WORKER, BASELINE_WAITS
from wait_reuse_log import validate
from test_fixed_plans import PARAMS


class WaitReuseGeneration(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='yolo32-wait-generation-')
        cls.root = Path(cls.tmp.name)
        generate(cls.root, fixed_plans=True, params=PARAMS,
                 fixed_packets=True, prepared_packets=True)
        cls.model = (cls.root/'parallel_model.inc').read_text()
        cls.plans = json.loads((cls.root/'fixed_plans.json').read_text())['prepared_ws']

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_only_thirteen_adjacent_caller_waits_change(self):
        model, sites = annotate(self.model, self.plans)
        self.assertEqual([s['stage'] for s in sites], list(STAGES))
        self.assertEqual(model.count('yolo32_reused_fence('), SITES_PER_WORKER)
        restored = model
        for stage in STAGES:
            restored = restored.replace(f'yolo32_reused_fence({stage}U);', 'gemmini_fence();')
        self.assertEqual(restored, self.model)
        # This leaves every actual native packet, helper wait and head callback unchanged.

    def test_intervening_command_or_branch_rejects_generation(self):
        marker = 'yolo32_prepared_ws(&prepared_ws_plan_14,'
        start = self.model.index(marker)
        end = self.model.index('gemmini_fence();', start)
        for injected in ('gemmini_flush(0);\n', 'yolo32_packed_silu_lut(packed_silu_luts[0]);\n',
                         'if (analysis_enabled) '):
            altered = self.model[:end] + injected + self.model[end:]
            with self.subTest(injected=injected), self.assertRaises(ValueError):
                annotate(altered, self.plans)

    def test_missing_final_helper_completion_rejects_generation(self):
        plans = copy.deepcopy(self.plans)
        plans['14']['steps'][-1] = [0, 0]
        with self.assertRaises(ValueError):
            annotate(self.model, plans)

    def test_conditional_helper_is_not_treated_as_unconditional_completion(self):
        altered=self.model.replace('yolo32_prepared_ws(&prepared_ws_plan_14,',
                                   'if (analysis_enabled) yolo32_prepared_ws(&prepared_ws_plan_14,',1)
        with self.assertRaises(ValueError):
            annotate(altered,self.plans)

    def test_new_build_keeps_all_shared_command_tables_equal(self):
        out = self.root/'enabled'
        generate(out, fixed_plans=True, params=PARAMS, fixed_packets=True,
                 prepared_packets=True, wait_reuse=True)
        for name in ('fixed_plans.json', 'fixed_conv_packets.inc', 'prepared_packets.inc',
                     'parallel_executor.inc', 'parallel_stages.inc', 'include/gemmini.h'):
            self.assertEqual((out/name).read_bytes(), (self.root/name).read_bytes(), name)
        manifest = json.loads((out/'wait_reuse.json').read_text())
        self.assertEqual(manifest['expected_batch_waits'], 1023)
        self.assertEqual(manifest['sites_per_worker'], 13)


class WaitReuseLog(unittest.TestCase):
    def example(self):
        return dict(wait_reuse=1, mode='independent', policy=dict(wait_yields='1023'),
                    wait_reuse_stats=dict(sites_per_worker='13', merged0='13', merged1='13',
                                          merged2='13', fallback0='0', fallback1='0', fallback2='0'))

    def test_exact_sites_and_wait_accounting(self):
        validate(self.example())
        for key, value in (('merged0', '12'), ('fallback2', '1'), ('sites_per_worker', '14')):
            example = self.example()
            example['wait_reuse_stats'][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate(example)
        example = self.example(); example['policy']['wait_yields'] = str(BASELINE_WAITS)
        with self.assertRaises(ValueError):
            validate(example)

    def test_missing_disabled_and_other_mode_records_rejected(self):
        for change in ({'wait_reuse': 0}, {'mode': 'forward'}, {'wait_reuse_stats': None}):
            example = self.example(); example.update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                validate(example)


class WaitReuseRuntime(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='yolo32-wait-runtime-')
        root = cls.root = Path(cls.tmp.name)
        local = root/'triple32'; local.mkdir(); (root/'dim16_dual').mkdir()
        for name in ('independent.c', 'independent.h', 'diagnostics.h', 'task_context_config.h', 'task_switch.S', 'yolo32.h', 'ppu.h'):
            shutil.copy(source_path(name), local/name)
        for name in ('yolov5nu_dim16_dual.h', 'yolov5nu_head_layout.h'):
            shutil.copy(source_path('native/'+name), local/name)
        (local/'mmio.h').write_text('#include <stdint.h>\nextern uint64_t tick;\nstatic inline uint64_t read_cycle(void){return ++tick;}\n')
        (local/'platform.h').write_text('#define SOC_CLOCK_HZ 1000000UL\n')
        adapter = (source_path('tests/test_independent.py')).read_text().split("switch = r'''", 1)[1].split('static void seed_vector(', 1)[0]
        ready = function((source_path('model.c')).read_text(), 'unsigned yolo32_independent_ready(')
        reused_fence = function((source_path('model.c')).read_text(), 'static void yolo32_reused_fence(unsigned stage) {')
        pre = r'''
#define _XOPEN_SOURCE 700
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef __riscv
#include <ucontext.h>
#endif
#include "independent.h"
#include "yolo32.h"
#include "mmio.h"
uint64_t tick;
static unsigned selected, stages[3], heads[3], accepted[3], retired[3], probes, full_fences;
static uint32_t independent_accepted_base[3];
static uint64_t dma_at[3];
void yolo32_fail(const char *s){fprintf(stderr,"%s\n",s);exit(42);}
unsigned yolo32_stage(unsigned w){return stages[w];}
void yolo32_independent_select(unsigned w){selected=w;}
void yolo32_independent_snapshot(unsigned w){independent_accepted_base[w]=accepted[w];}
unsigned yolo32_independent_head_mask(unsigned w){return heads[w];}
void yolo32_ppu_early_service(void){}
static uint64_t independent_status_read(unsigned w){
 ++probes;
 if(getenv("INGRESS_ERROR")&&w==0)return 0xc000;
 if((getenv("STUCK")&&w==0)||tick<dma_at[w])return 0x10;
 retired[w]=accepted[w];return 0;
}
static uint32_t independent_counter_read(unsigned w,unsigned r){return r?retired[w]:accepted[w];}
/* Weak busy=0 alone never proves the outstanding DMA has completed. */
static unsigned read_worker_busy(unsigned w){(void)w;return 0;}
unsigned yolo32_independent_busy_mask(void){unsigned m=0;for(unsigned w=0;w<3;w++)if(tick<dma_at[w])m|=1U<<w;return m;}
static void yolo32_model_fence(void){if(yolo32_independent_enabled)yolo32_independent_wait();else ++full_fences;}
'''
        body = r'''
static void issue(unsigned f){
 unsigned w=selected;
 yolo32_independent_arm_tail_wait(f);
 if(f==15)++accepted[w];
 dma_at[w]=tick+100+20*w;
 yolo32_independent_command_return(f);
 assert(selected==w);
}
int yolo32_graph_poll(unsigned w,Yolo32Result *r){
 (void)r;assert(selected==w);
 if(stages[w]==14){
   if(getenv("WRONG_STAGE"))yolo32_independent_try_reuse_wait(33);
   assert(!yolo32_independent_try_reuse_wait(14));
   for(unsigned k=0;k<3;k++){
     issue(k==2?15:8);
     assert(!yolo32_independent_try_reuse_wait(14));
     yolo32_model_fence();
     assert(tick>=dma_at[w]&&retired[w]==accepted[w]);
     const Yolo32IndependentStats *s=yolo32_independent_stats();
     uint64_t waits=s->wait_yields,resumes=s->resumes[w];unsigned reads=probes;
     yolo32_reused_fence(14);
     assert(probes==reads&&s->wait_yields==waits&&s->resumes[w]==resumes);
   }
   stages[w]=165;heads[w]=63;return YOLOV5NU_DIM16_RUNNING;
 }
 assert(stages[w]==165);yolo32_model_fence();stages[w]=167;return YOLOV5NU_DIM16_HEAD_READY;
}
int main(void){
 yolo32_reused_fence(14);assert(full_fences==1);
 for(unsigned repeat=0;repeat<2;repeat++){
   memset(dma_at,0,sizeof(dma_at));memset(heads,0,sizeof(heads));
   for(unsigned w=0;w<3;w++){stages[w]=14;accepted[w]=retired[w]=UINT32_MAX;}
#ifndef __riscv
   memset(contexts,0,sizeof(contexts));contexts_used=0;
#endif
   yolo32_independent_begin(repeat==0);
   while(!yolo32_independent_step()){}
   yolo32_independent_end();
   const Yolo32IndependentStats *s=yolo32_independent_stats();
   for(unsigned w=0;w<3;w++){
     assert(s->wait_reused[w]==3&&s->wait_reuse_fallbacks[w]==4);
     assert(s->conv_requests[w]==1&&s->matmul_requests[w]==2);
   }
   assert(s->wait_yields==12&&s->tail_deferred==9&&s->tail_wait_merges==9);
 }
 puts("PASS: real scheduler; complete DMA; WS/Conv invalidation; no repeated probes/switches; restart; serial fallback");return 0;
}
'''
        (local/'test.c').write_text(pre+ready+adapter+reused_fence+body)
        flags=['-std=gnu11', '-O2', '-I'+str(local), '-DYOLO32_HOST_TASKS=1',
               '-DYOLO32_CONTEXT_FULL=0', '-DYOLO32_HOT_PATHS=1', '-DYOLO32_SCHED_ADAPTIVE=0',
               '-DYOLO32_SUBMIT_BURST=1', '-DYOLO32_FIXED_PLANS=1', '-DYOLO32_FIXED_PACKETS=1',
               '-DYOLO32_TAIL_WAIT=1', '-DYOLO32_PREPARED_PACKETS=1', '-DYOLO32_PPU_EARLY=1',
               '-DYOLO32_PPU_HEAD_CLEAN=1', '-DYOLO32_WAIT_REUSE=1', '-DYOLO32_TIMEOUT_SECONDS=1']
        cls.local=local; cls.flags=flags
        cls.host=root/'host'
        subprocess.run(['gcc']+flags+[str(local/'test.c'), str(local/'independent.c'), '-o', str(cls.host)], check=True, capture_output=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def check_executable(self, command):
        result=subprocess.run(command, check=True, capture_output=True, text=True, timeout=30)
        self.assertIn('PASS: real scheduler',result.stdout)
        for mode, reason in (('STUCK','independent_timeout'), ('INGRESS_ERROR','independent_ingress_error'),
                             ('WRONG_STAGE','wait_reuse_stage')):
            result=subprocess.run(command, env=dict(os.environ, **{mode:'1'}), capture_output=True, text=True, timeout=30)
            self.assertEqual(result.returncode,42, result.stderr)
            self.assertIn(reason,result.stderr)

    def test_host_dma_proof_restart_and_errors(self):
        self.check_executable([self.host])

    def test_actual_riscv_switch_with_wait_reuse(self):
        compiler=RISCV_LINUX_CC
        qemu=shutil.which('qemu-riscv64')
        if not compiler.exists() or not qemu:
            self.skipTest('RISC-V Linux compiler/QEMU unavailable')
        exe=self.root/'riscv'
        subprocess.run([compiler,'-static','-march=rv64gcv','-mabi=lp64d']+self.flags+
                       [str(self.local/'test.c'),str(self.local/'independent.c'),str(self.local/'task_switch.S'),'-o',str(exe)],check=True,capture_output=True)
        self.check_executable([qemu,'-cpu','rv64,v=true,vlen=256',exe])


if __name__=='__main__':
    unittest.main()
