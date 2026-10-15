from paths import HERE, source_path
"""Four-slot scheduler, sparse observer, real main and strict log contracts."""
from pathlib import Path
import os
import shutil
import subprocess
import unittest

import test_submit_optimizations as submit_tests
import test_benchmark_main as main_tests
from generate_parallel import function
from analyze_log import parse
from capacity_log import validate as validate_capacity

class CapacityRuntime(submit_tests.FormalQueryRuntime):
    limit=3

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        for name in ('capacity_observer.h','capacity_observer.c'):
            shutil.copy(source_path(name),cls.local/name)
        p=cls.local/'mmio.h';p.write_text('#pragma once\n'+p.read_text())
        (cls.local/'console.h').write_text('void console_puts(const char*); void console_putc(char); void console_put_hex64(unsigned long);\n')
        p=cls.local/'test.c';s=p.read_text()
        s=s.replace('#include "mmio.h"','#include "mmio.h"\n#include "capacity_observer.h"\n'
            'void console_puts(const char*s){fputs(s,stdout);} void console_putc(char c){putchar(c);}\n'
            'void console_put_hex64(unsigned long x){printf("0x%016lx",x);}\n',1)
        s=s.replace('posted[w]-retired_n[w]<3','posted[w]-retired_n[w]<YOLO32_CREDIT_LIMIT')
        s=s.replace('posted[w]-retired_n[w]==3','posted[w]-retired_n[w]==YOLO32_CREDIT_LIMIT')
        s=s.replace('max_observed==3','max_observed==YOLO32_CREDIT_LIMIT')
        s=s.replace('credit_max_pending[w]==3','credit_max_pending[w]==YOLO32_CREDIT_LIMIT')
        s=s.replace(' yolo32_packet_submit(&plan,&p,',' yolo32_capacity_prepare(selected,14,tile<8);\n yolo32_packet_submit(&plan,&p,',1)
        s=s.replace('yolo32_independent_begin(0);','yolo32_capacity_configure(repeat?64:16);\n   yolo32_independent_begin(0);',1)
        callback=function((source_path('model.c')).read_text(),'uint64_t yolo32_capacity_status(')
        s=s.replace('unsigned yolo32_independent_ready(',callback+'\nunsigned yolo32_independent_ready(',1)
        s=s.replace('assert(s->conv_requests[w]==9',r'''
     const Yolo32CapacityStats *c=yolo32_capacity_stats(w);
     assert(c->submitted==9&&c->queries==s->credit_checks[w]);
     assert(c->probes==(c->queries+(repeat?64:16)-1)/(repeat?64:16)+1);
     uint64_t samples=0,span=0,owners=0;
     for(unsigned k=0;k<5;k++){samples+=c->pending_samples[k];span+=c->pending_cycles[k];}
     for(unsigned k=0;k<4;k++)owners+=c->owner_cycles[k];
     assert(samples==c->probes&&span==c->observed_span&&owners<=tick);
     assert(c->known_probes==c->full_can+c->full_no+c->allowed_can+c->allowed_no);
     assert(c->first_submit<=c->last_submit&&c->last_submit<=c->graph_done);
     assert(c->pending_samples[YOLO32_CREDIT_LIMIT]>0);
     assert(s->conv_requests[w]==9''',1)
        s=s.replace('PASS: credit=3',f'PASS: credit={cls.limit}')
        s+='\n#include "capacity_observer.c"\n'
        p.write_text(s)
        cls.flags=[f for f in cls.flags if not f.startswith(('-DYOLO32_CREDIT_LIMIT=', '-DYOLO32_DIAGNOSTIC_BUILD='))]
        cls.flags += [f'-DYOLO32_CREDIT_LIMIT={cls.limit}','-DYOLO32_CAPACITY_EXPERIMENT=1',
                      '-DYOLO32_CAPACITY_DIAG=1','-DYOLO32_DIAGNOSTIC_BUILD=1',
                      '-DYOLO32_MEMORY_OPS=1','-DYOLO32_RESIZE_BATCH=1']
        subprocess.run(['gcc']+cls.flags+[str(cls.local/'test.c'),str(cls.local/'independent.c'),'-o',str(cls.host)],
                       check=True,capture_output=True)

    def check_executable(self,command):
        r=subprocess.run(command,capture_output=True,text=True,timeout=30)
        self.assertEqual(r.returncode,0,r.stderr)
        self.assertIn(f'PASS: credit={self.limit}',r.stdout)
        for mode,reason in [('STUCK','independent_timeout'),('PARTIAL_STUCK','independent_timeout'),
                            ('INGRESS_ERROR','independent_ingress_error'),('BAD_RETIRED','credit_retired_or_budget')]:
            r=subprocess.run(command,env=dict(os.environ,**{mode:'1'}),capture_output=True,text=True,timeout=30)
            self.assertEqual(r.returncode,42,r.stderr);self.assertIn(reason,r.stderr)

    def test_final_admission_rechecks_changed_status_and_full_budget_errors(self):
        for mode,code,reason in [('STATUS_FLAP',0,f'PASS: credit={self.limit}'),
                                 ('FULL_ERROR',42,'independent_ingress_error')]:
            r=subprocess.run([self.host],env=dict(os.environ,**{mode:'1'}),capture_output=True,text=True,timeout=30)
            self.assertEqual(r.returncode,code,r.stderr);self.assertIn(reason,r.stdout+r.stderr)


class CapacityFourRuntime(CapacityRuntime):
    limit=4


class CapacityMainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Reuse the real-main fixture builder without inheriting its old cases.
        main_tests.BenchmarkMainTests.setUpClass.__func__(cls)
        root=Path(cls.tmp.name);source=root/'triple32'
        for name in ('capacity_observer.h','capacity_observer.c'):
            shutil.copy(source_path(name),source/name)
        p=source/'mmio.h';p.write_text('#pragma once\n'+p.read_text())
        s=(source/'submit_fake.c').read_text()
        s=s.replace('#include "independent.h"','#include "independent.h"\n#if YOLO32_CAPACITY_DIAG\n#include "capacity_observer.h"\n'
            'static uint32_t cap_pending[3];\n'
            'uint32_t yolo32_independent_credit_pending(unsigned w,uint32_t n){(void)n;return cap_pending[w];}\n'
            'uint64_t yolo32_capacity_status(unsigned w){return cap_pending[w]<4?2:0;}\n#endif',1)
        marker='void yolo32_independent_begin(unsigned a) {'
        assert marker in s
        s=s.replace(marker,marker+'\n#if YOLO32_CAPACITY_DIAG\nyolo32_capacity_begin();memset(cap_pending,0,sizeof(cap_pending));\n#endif',1)
        s=s.replace('independent_stats.credit_max_pending[w]=3','independent_stats.credit_max_pending[w]=YOLO32_CREDIT_LIMIT')
        marker='independent_stats.done_mask|=1U<<w;'
        assert marker in s
        s=s.replace(marker,r'''
#if YOLO32_CAPACITY_DIAG
 yolo32_capacity_owner(w,14);
 for(unsigned n=0;n<500;n++){
   yolo32_capacity_prepare(w,14,n<499);
   if(n==5||n==20){
     cap_pending[w]=YOLO32_CREDIT_LIMIT;
     yolo32_capacity_query(w,n,DIAG_SCHEDULER,cap_pending[w],0);host_cycle+=20;
     --cap_pending[w];yolo32_capacity_query(w,n,DIAG_RESUME,cap_pending[w],1);
   }
   if(cap_pending[w]>=YOLO32_CREDIT_LIMIT)--cap_pending[w];
   yolo32_capacity_query(w,n,DIAG_ADMIT,cap_pending[w],1);++cap_pending[w];
   yolo32_capacity_return(w,n+1);
 }
 cap_pending[w]=0;yolo32_capacity_done(w);yolo32_capacity_owner(3,167);
#endif
 independent_stats.done_mask|=1U<<w;''',1)
        s=s.replace('void yolo32_independent_end(void) {',
                    'void yolo32_independent_end(void) {\n#if YOLO32_CAPACITY_DIAG\nyolo32_capacity_end();\n#endif\n',1)
        (source/'capacity_fake.c').write_text(s)
        cls.capacity_exe={}
        for limit in (3,4):
            for diagnostic in (0,1):
                exe=root/f'capacity-main-{limit}-{diagnostic}';cls.capacity_exe[limit,diagnostic]=exe
                flags=['-std=c11','-O2','-Wall','-Wextra','-Werror','-DYOLOV5NU_DIM16_WORKER_COUNT=3U',
                    '-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1','-DYOLO32_IDLE_PRIORITY=1',
                    '-DYOLO32_TAIL_WAIT=1','-DYOLO32_SCHED_ADAPTIVE=0','-DYOLO32_SUBMIT_BURST=1',
                    '-DYOLO32_HOT_PATHS=1','-DYOLO32_CONTEXT_FULL=0','-DYOLO32_PREPARED_PACKETS=1','-DYOLO32_PPU_EARLY=1',
                    '-DYOLO32_PPU_HEAD_CLEAN=1','-DYOLO32_WAIT_REUSE=1',f'-DYOLO32_CREDIT_LIMIT={limit}',
                    '-DYOLO32_MEMORY_OPS=1','-DYOLO32_RESIZE_BATCH=1','-DYOLO32_CREDIT_QUERY=1',
                    '-DYOLO32_PACKET_DISPATCH=1','-DYOLO32_SPLIT_DIAG=1','-DYOLO32_CAPACITY_EXPERIMENT=1',
                    f'-DYOLO32_CAPACITY_DIAG={diagnostic}',f'-DYOLO32_DIAGNOSTIC_BUILD={diagnostic}']
                result=subprocess.run(['gcc']+flags+[str(source/'main.c'),str(source/'compare.c'),
                    str(source/'capacity_fake.c'),str(source/'capacity_observer.c'),'-o',str(exe)],
                    capture_output=True,text=True)
                if result.returncode:raise RuntimeError(result.stderr)

    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()

    def invoke(self,commands,limit=3,diagnostic=1):
        r=subprocess.run([self.capacity_exe[limit,diagnostic]],env=dict(os.environ,COMMANDS=commands),
                         check=True,capture_output=True,text=True)
        return r.stdout

    def test_real_main_formal_bench_and_observer_rates(self):
        for limit in (3,4):
            for diagnostic in (0,1):
                log=self.invoke('atdDt',limit,diagnostic);errors,runs=parse(log)
                self.assertEqual(errors,[],str(errors)+log[-4000:])
                self.assertIn('YOLO32_FIRMWARE v26',log)
                self.assertFalse(any(r['analysis'] for r in runs))
                measured=[r for r in runs if r['phase']=='measure'];self.assertEqual(len(measured),25)
                observed=[r for r in runs if r['phase']=='capacity']
                self.assertEqual([r['capacity_period'] for r in observed],[16,64] if diagnostic else [])
                for r in observed:
                    self.assertEqual(set(r['capacity_stats']),{0,1,2});validate_capacity(r)
                self.assertEqual(runs[-1]['capacity_period'],0)
                self.assertNotIn('YOLO32_SCHED_PROFILE ',log)

    def test_missing_flags_records_gaps_and_wrong_counts_are_rejected(self):
        log=self.invoke('dD',4);errors,runs=parse(log);self.assertEqual(errors,[])
        row=next(l for l in log.splitlines() if l.startswith('YOLO32_CAPACITY '))
        gap=next(l for l in log.splitlines() if l.startswith('YOLO32_CAPACITY_GAP '))
        changes=[(row,''),(row,row+'\n'+row),(gap,''),(gap,gap+'\n'+gap),
                 (' credit_cap=0x0000000000000004',''),
                 ('capacity_experiment=0x0000000000000001','capacity_experiment=0'),
                 ('YOLO32_FIRMWARE v26','YOLO32_FIRMWARE v25'),
                 ('schema=0x0000000000000001','schema=2'),
                 ('capacity_period=0x0000000000000010','capacity_period=32')]
        for old,new in changes:
            with self.subTest(field=old):
                self.assertIn(old,log);self.assertTrue(parse(log.replace(old,new,1))[0])
        for key,value in [('probes','0'),('full_can','999999'),('observed_span','999999999'),
                          ('retired_reads','0'),('gap_kept','0')]:
            with self.subTest(key=key):
                import re
                changed=re.sub(rf' {key}=\S+',f' {key}={value}',row)
                self.assertTrue(parse(log.replace(row,changed,1))[0])

    def test_mixed_sessions_and_disabled_full_profiling(self):
        text=self.invoke('d',3)+self.invoke('d',4)
        errors,runs=parse(text);self.assertEqual(errors,[],errors)
        self.assertEqual({r['credit_limit'] for r in runs},{3,4})
        for diagnostic in (0,1):
            log=self.invoke('pq',4,diagnostic)
            self.assertNotIn('YOLO32_BEGIN ',log);self.assertIn('uses d/D',log)


if __name__=='__main__':unittest.main()
