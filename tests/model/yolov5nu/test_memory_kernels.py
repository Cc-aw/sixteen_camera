from paths import HERE, source_path
"""Production kernels + native operand macros + real scheduler on host/RVV QEMU."""
from pathlib import Path
import copy
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

from generate_parallel import generate, ABI, function
from test_fixed_plans import PARAMS
from memory_kernels import bake, EXPECTED, expected_counts
from memory_log import validate, validate_smoke
from wait_reuse_log import validate as validate_wait


class MemoryGeneration(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='yolo32-memory-generation-')
        cls.base=Path(cls.tmp.name)/'base';cls.new=Path(cls.tmp.name)/'new'
        flags=dict(fixed_plans=True,params=PARAMS,fixed_packets=True,prepared_packets=True,wait_reuse=True)
        generate(cls.base,**flags);generate(cls.new,**flags,memory_ops=True)
        cls.batch=Path(cls.tmp.name)/'batch'
        generate(cls.batch,**flags,memory_ops=True,resize_batch=True)

    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()

    def test_only_five_calls_change_and_native_tables_are_identical(self):
        model=(self.new/'parallel_model.inc').read_text()
        base=(self.base/'parallel_model.inc').read_text()
        for name in ['fixed_conv_packets.inc','prepared_packets.inc','fixed_plans.json','parallel_stages.inc','wait_reuse.json','include/gemmini.h']:
            self.assertEqual((self.base/name).read_bytes(),(self.new/name).read_bytes(),name)
        expected=json.loads((self.new/'memory_kernels.json').read_text())
        self.assertEqual(expected['expected_per_worker'],EXPECTED)
        self.assertEqual(expected['extra_batch_waits'],432)
        from fixed_plans import graph_stages
        old=graph_stages(base);new=graph_stages(model)
        self.assertEqual([s for s in old if old[s]!=new[s]],[75,76,77,83,97])
        self.assertEqual(len(re.findall(r'\byolo32_memory_pool5\(',model)),3)
        self.assertEqual(len(re.findall(r'\byolo32_memory_resize2\(',model)),2)

    def test_geometry_scale_and_missing_call_fail_closed(self):
        model=(self.base/'parallel_model.inc').read_text()
        for changed in [model.replace('5, 5, 1, 1, 2, 2, 0.05828123912f','3, 3, 1, 1, 2, 2, 0.05828123912f',1),
                        model.replace('0.05828123912f, 0.05828123912f);','0.05828123912f, 0.1f);',1),
                        model.replace('maxpool_nhwc_i8(tensor_107','missing_pool(tensor_107',1)]:
            with self.subTest(changed=changed!=model),self.assertRaises(ValueError):bake(self.new,changed)

    def test_batch_plan_preserves_graph_and_all_compute_packets(self):
        for name in ['parallel_model.inc','fixed_conv_packets.inc','prepared_packets.inc',
                     'fixed_plans.json','parallel_stages.inc','wait_reuse.json','include/gemmini.h']:
            self.assertEqual((self.new/name).read_bytes(),(self.batch/name).read_bytes(),name)
        manifest=json.loads((self.batch/'memory_kernels.json').read_text())
        self.assertEqual(manifest['expected_per_worker'],expected_counts(True))
        self.assertEqual(manifest['resize_batches_per_channel'],[15,12])
        self.assertEqual(manifest['resize_phase_waits'],10)
        self.assertEqual(manifest['extra_batch_waits'],102)


class MemoryRuntime(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='yolo32-memory-runtime-')
        root=cls.root=Path(cls.tmp.name);local=cls.local=root/'triple32';local.mkdir();(root/'dim16_dual').mkdir()
        for name in ['independent.c','independent.h','diagnostics.h','task_context_config.h','task_switch.S','yolo32.h','ppu.h',
                     'memory_kernels.h','memory_kernels_runtime.inc','memory_selftest.inc']:
            shutil.copy(source_path(name),local/name)
        for name in ['yolov5nu_dim16_dual.h','yolov5nu_head_layout.h']:
            shutil.copy(source_path('native/'+name),local/name)
        shutil.copy(ABI.parent/'gemmini_float16.h',local/'gemmini_float16.h')
        # Observe real completion-cache bits without changing production API.
        independent=local/'independent.c'
        text=independent.read_text()
        memory_submit=function(text,'void yolo32_independent_memory_submit(')
        text=text.replace(memory_submit,memory_submit.replace('unsigned w=current;',
            'unsigned w=current;\n    extern unsigned memory_dirty_calls[3]; ++memory_dirty_calls[w];',1),1)
        independent.write_text(text+'\nunsigned yolo32_test_memory_proof_clean(unsigned w) { return (completed_mask|local_complete_valid)&(1U<<w); }\n')
        (local/'mmio.h').write_text('#pragma once\n#include <stdint.h>\nextern uint64_t tick;\nstatic inline uint64_t read_cycle(void){return tick+=100;}\n')
        (local/'platform.h').write_text('#define SOC_CLOCK_HZ 1000000UL\n')
        macros=[];lines=ABI.read_text().splitlines()
        for name in ['gemmini_extended5_config_ld','gemmini_extended4_config_ld','gemmini_extended2_config_st',
                     'gemmini_extended_config_st','gemmini_extended_mvin','gemmini_extended_mvout']:
            i=[i for i,l in enumerate(lines) if l.startswith('#define '+name+'(')][-1]
            body=[lines[i]]
            while body[-1].endswith('\\'):
                i+=1;body.append(lines[i])
            macros.append('\n'.join(body))
        (local/'memory_native_macros.inc').write_text('\n'.join(macros)+'\n')
        adapter=(source_path('tests/test_independent.py')).read_text().split("switch = r'''",1)[1].split('static void seed_vector(',1)[0]
        (local/'memory_switch.inc').write_text(adapter)
        source=(source_path('tests/memory_backend.c')).read_text().replace('/* Native ABI macros inserted here by the test builder. */',
            function((source_path('model.c')).read_text(),'unsigned yolo32_independent_ready('))
        (local/'test.c').write_text(source)
        cls.flags=['-std=gnu11','-O2','-I'+str(local),'-DYOLO32_HOST_TASKS=1','-DYOLO32_CONTEXT_FULL=0',
                   '-DYOLO32_HOT_PATHS=1','-DYOLO32_SCHED_ADAPTIVE=0','-DYOLO32_SUBMIT_BURST=1',
                   '-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1','-DYOLO32_IDLE_PRIORITY=1',
                   '-DYOLO32_TAIL_WAIT=1','-DYOLO32_PREPARED_PACKETS=1','-DYOLO32_PPU_EARLY=1',
                   '-DYOLO32_PPU_HEAD_CLEAN=1','-DYOLO32_WAIT_REUSE=1','-DYOLO32_CREDIT_LIMIT=3',
                   '-DYOLO32_MEMORY_OPS=1','-DYOLO32_TIMEOUT_SECONDS=10']
        cls.host=root/'host';cls.build(['gcc'],cls.host)

    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()

    @classmethod
    def build(cls,cc,out,extra=()):
        r=subprocess.run(cc+cls.flags+[str(cls.local/'test.c'),str(cls.local/'independent.c'),*extra,'-o',str(out)],capture_output=True,text=True)
        if r.returncode:raise AssertionError(r.stderr)

    def check(self,command):
        r=subprocess.run(command,capture_output=True,text=True,timeout=45)
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertIn('PASS: private arenas',r.stdout)
        self.assertEqual(validate_smoke(r.stdout),[])
        for env,reason in [('STUCK','independent_timeout'),('INGRESS_ERROR','independent_ingress_error')]:
            r=subprocess.run(command,env=dict(os.environ,**{env:'1'}),capture_output=True,text=True,timeout=45)
            self.assertEqual(r.returncode,42,r.stderr);self.assertIn(reason,r.stderr)
        return r

    def test_host_delayed_dma_private_buffers_and_completion_cache(self):self.check([self.host])

    def test_riscv_rvv_padding_and_real_context_switch(self):
        cc=Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-linux-gnu-gcc')
        qemu=shutil.which('qemu-riscv64')
        if not cc.is_file() or not qemu:self.skipTest('RISC-V compiler/QEMU unavailable')
        out=self.root/'riscv';self.build([str(cc),'-static','-march=rv64gcv','-mabi=lp64d'],out,[str(self.local/'task_switch.S')])
        self.check([qemu,'-cpu','rv64,v=true,vlen=256',str(out)])

    def test_host_multirow_and_capped_batches_delayed_dma(self):
        for rows in (0,1,4,7,12,30):
            with self.subTest(rows=rows):
                out=self.root/f'host-batch-{rows}'
                self.build(['gcc'],out,[f'-DYOLO32_RESIZE_BATCH=1',f'-DYOLO32_RESIZE_ROWS={rows}'])
                self.check([out])

    def test_riscv_multirow_rvv_and_real_context_switch(self):
        cc=Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-linux-gnu-gcc')
        qemu=shutil.which('qemu-riscv64')
        if not cc.is_file() or not qemu:self.skipTest('RISC-V compiler/QEMU unavailable')
        for rows in (0,4):
            with self.subTest(rows=rows):
                out=self.root/f'riscv-batch-{rows}'
                self.build([str(cc),'-static','-march=rv64gcv','-mabi=lp64d'],out,
                           [str(self.local/'task_switch.S'),'-DYOLO32_RESIZE_BATCH=1',f'-DYOLO32_RESIZE_ROWS={rows}'])
                self.check([qemu,'-cpu','rv64,v=true,vlen=256',str(out)])

    def test_missing_load_or_store_phase_invalidation_is_detected(self):
        path=self.local/'memory_kernels_runtime.inc';original=path.read_text()
        resize=function(original,'static void yolo32_memory_resize2(')
        parts=resize.split('yolo32_independent_memory_submit();')
        self.assertEqual(len(parts),3)
        try:
            for phase in (0,1):
                with self.subTest(phase=phase):
                    mutant=parts[0]+('' if phase==0 else 'yolo32_independent_memory_submit();')+parts[1]+('' if phase==1 else 'yolo32_independent_memory_submit();')+parts[2]
                    path.write_text(original.replace(resize,mutant,1))
                    out=self.root/f'missing-dirty-{phase}'
                    self.build(['gcc'],out,['-DYOLO32_RESIZE_BATCH=1'])
                    r=subprocess.run([out],capture_output=True,text=True,timeout=45)
                    self.assertNotEqual(r.returncode,0)
                    self.assertIn('yolo32_test_memory_proof_clean',r.stderr)
        finally:path.write_text(original)

    def test_formal_submit_context_preserves_rvv_pool_resize_and_delayed_dma(self):
        cc=Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-linux-gnu-gcc')
        qemu=shutil.which('qemu-riscv64')
        if not cc.is_file() or not qemu:self.skipTest('RISC-V compiler/QEMU unavailable')
        path=self.local/'test.c';original=path.read_text()
        try:
            text=original.replace('analysis_enabled=repeat==0;','analysis_enabled=0;').replace(
                'yolo32_independent_begin(repeat==0)','yolo32_independent_begin(0)')
            text+='\nuint32_t yolo32_independent_credit_pending(unsigned w,uint32_t issued){(void)w;assert(!issued);return 0;}\n'
            text+='unsigned yolo32_independent_credit_status(unsigned w){(void)w;return 1;}\n'
            path.write_text(text)
            out=self.root/'riscv-formal-submit'
            extra=[str(self.local/'task_switch.S'),'-DYOLO32_RESIZE_BATCH=1',
                   '-DYOLO32_CREDIT_QUERY=1','-DYOLO32_PACKET_DISPATCH=1','-DYOLO32_SPLIT_DIAG=1','-DYOLO32_DIAGNOSTIC_BUILD=0']
            self.build([str(cc),'-static','-march=rv64gcv','-mabi=lp64d'],out,extra)
            self.check([qemu,'-cpu','rv64,v=true,vlen=256',str(out)])
        finally:path.write_text(original)

    def test_board_smoke_parser_rejects_missing_failed_or_corrupt_case(self):
        r=subprocess.run([self.host],env=dict(os.environ,SMOKE_ONLY='1'),check=True,capture_output=True,text=True)
        for s in [r.stdout.replace('mismatches=0x0000000000000000','mismatches=0x0000000000000001',1),
                  r.stdout.replace('YOLO32_MEMORY_TEST_RESULT PASS','YOLO32_MEMORY_TEST_RESULT FAIL'),
                  '\n'.join(r.stdout.splitlines()[:-1]),
                  '\n'.join(l for i,l in enumerate(r.stdout.splitlines()) if i!=5)]:
            with self.subTest(sample=s[:60]):self.assertTrue(validate_smoke(s))


class MemoryLog(unittest.TestCase):
    def example(self):
        return dict(memory_ops=1,analysis=0,memory={w:{'worker':str(w),'pad_cycles':'0',**{k:str(v) for k,v in EXPECTED.items()}} for w in range(3)})

    def test_graph_counts_and_extra_waits(self):
        validate(self.example())
        r=self.example();r['memory'][2]['mvin']='1943'
        with self.assertRaises(ValueError):validate(r)
        r=self.example();r['memory_ops']=0
        with self.assertRaises(ValueError):validate(r)
        wait=dict(memory_ops=1,wait_reuse=1,mode='independent',policy={'wait_yields':'1455'},
                  wait_reuse_stats=dict(sites_per_worker='13',merged0='13',merged1='13',merged2='13',fallback0='0',fallback1='0',fallback2='0'))
        validate_wait(wait);wait['policy']['wait_yields']='1023'
        with self.assertRaises(ValueError):validate_wait(wait)

    def test_batch_counts_and_wait_proofs_require_matching_row_limit(self):
        for rows,waits in [(0,34),(1,144),(4,56),(7,46),(12,38),(30,34)]:
            with self.subTest(rows=rows):
                r=self.example();r.update(resize_batch=1,resize_rows=rows)
                for row in r['memory'].values():row['waits']=str(waits)
                validate(r)
                r.update(wait_reuse=1,mode='independent',policy={'wait_yields':str(1023+3*waits)},
                         wait_reuse_stats=dict(sites_per_worker='13',merged0='13',merged1='13',merged2='13',fallback0='0',fallback1='0',fallback2='0'))
                validate_wait(r)
                r['memory'][0]['waits']='145'
                with self.assertRaises(ValueError):validate(r)
        for args in [(False,4),(True,-1),(True,31),(2,0)]:
            with self.subTest(args=args),self.assertRaises(ValueError):expected_counts(*args)


if __name__=='__main__':unittest.main()
