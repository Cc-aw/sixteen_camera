from paths import HERE, source_path
"""Production query scheduler and fixed-opcode packets with delayed hardware."""
from pathlib import Path
import os
import shutil
import subprocess
import sys
import unittest

from generate_parallel import function
import test_credit as credit_tests
import test_prepared_packets as prepared_tests
import test_fixed_packets as conv_tests
from submit_log import configuration,validate


class CreditQueryRuntime(credit_tests.CooperativeCredit):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        model=(source_path('model.c')).read_text()
        path=cls.local/'test.c';text=path.read_text()
        callbacks=function(model,'uint32_t yolo32_independent_credit_pending(')+'\n'+function(model,'unsigned yolo32_independent_credit_status(')
        text=text.replace('unsigned yolo32_independent_ready(',callbacks+'\nunsigned yolo32_independent_ready(',1)
        text=text.replace('uint64_t tick;', 'uint64_t tick;\nunsigned query_source;\nstatic unsigned final_status_seen[3],flapped;',1)
        text=text.replace('advance(w);\n if(getenv("INGRESS_ERROR")',
            'advance(w);\n if(getenv("STATUS_FLAP")&&query_source==DIAG_RESUME&&w==0&&!flapped){flapped=1;final_status_seen[w]=0;return 0;}\n'
            'if(getenv("FULL_ERROR")&&w==0&&posted[w]-retired_n[w]==3)return 0xc000;\n if(getenv("INGRESS_ERROR")',1)
        text=text.replace('return status;','if(query_source==DIAG_ADMIT||query_source==DIAG_RESUME)final_status_seen[w]=(status&2)!=0;\n return status;',1)
        text=text.replace('if(f>=16&&f<=21){',
            'if(f==16&&yolo32_independent_enabled){assert(final_status_seen[w]);final_status_seen[w]=0;}\n if(f>=16&&f<=21){',1)
        text=text.replace('const Yolo32IndependentStats *s=yolo32_independent_stats();',
            'const Yolo32IndependentStats *s=yolo32_independent_stats();\n'
            'for(unsigned w=0;w<3;w++){const Yolo32CreditQueryStats *q=&s->credit_queries[w];\n'
            ' if(repeat==0){assert(q->retired_reads+q->retirement_reused==s->credit_checks[w]);assert(q->retirement_reused>0);\n'
            ' assert(q->budget_rejects+q->hardware_rejects==s->credit_blocked[w]);\n'
            ' assert(q->status_reads==s->credit_checks[w]-q->budget_rejects+q->error_probes);\n'
            ' assert(q->error_probes==q->budget_rejects/16);assert(q->resume_rechecks==s->credit_resumes[w]);}\n'
            ' else assert(!q->retired_reads&&!q->status_reads&&!q->retirement_reused);}\n',1)
        text=text.replace('tick=0;max_observed=', 'query_source=DIAG_ADMIT;flapped=0;memset(final_status_seen,0,sizeof(final_status_seen));\n   tick=0;max_observed=',1)
        path.write_text(text)
        # Expose only query origin in the test copy, not in production firmware.
        path=cls.local/'independent.c';text=path.read_text()
        query=function(text,'static unsigned credit_query(')
        text=text.replace(query,query.replace('{','{\n    extern unsigned query_source; query_source=source;',1),1)
        path.write_text(text)
        cls.flags+=['-DYOLO32_CREDIT_QUERY=1']
        subprocess.run(['gcc']+cls.flags+[str(cls.local/'test.c'),str(cls.local/'independent.c'),'-o',str(cls.host)],check=True,capture_output=True)

    def test_final_admission_rechecks_changed_status_and_full_budget_errors(self):
        for env,code,reason in [('STATUS_FLAP',0,'PASS: credit=3'),('FULL_ERROR',42,'independent_ingress_error')]:
            with self.subTest(env=env):
                r=subprocess.run([self.host],env=dict(os.environ,**{env:'1'}),capture_output=True,text=True,timeout=30)
                self.assertEqual(r.returncode,code,r.stderr)
                self.assertIn(reason,r.stdout+r.stderr)


class PacketQueryRuntime(CreditQueryRuntime):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        shutil.copy(source_path('packet_dispatch_runtime.inc'),cls.local/'packet_dispatch_runtime.inc')
        path=cls.local/'test.c';text=path.read_text()
        runtime=(source_path('fixed_packets_runtime.inc')).read_text()
        helpers=runtime[runtime.index('#if YOLO32_PACKET_DISPATCH'):runtime.index('static inline void yolo32_packet_submit(')]
        text=text.replace('static inline void yolo32_packet_submit(',helpers+'\nstatic inline void yolo32_packet_submit(',1)
        text=text.replace('yolo32_independent_command_return(f);\n assert(selected==w);','assert(selected==w);',1)
        text=text.replace('#define ROCC_INSTRUCTION_RS1_RS2(x,a,b,f) emit(f,(uint64_t)(a),(uint64_t)(b))',
            '#define ROCC_INSTRUCTION_RS1_RS2(x,a,b,f) do{emit(f,(uint64_t)(a),(uint64_t)(b));yolo32_independent_command_return(f);}while(0)\n'
            '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) do{assert(op==3-selected);emit(f,(uint64_t)(a),(uint64_t)(b));}while(0)\n'
            '#define GEMMINI_POOL_COMMAND_ARGS_HOOK(f,a,b) ((void)0)\n'
            '#define GEMMINI_POOL_COMMAND_CLOCK(f) UINT64_C(0)\n'
            '#define GEMMINI_POOL_COMMAND_ELAPSED(f,start) ((void)(start))\n'
            '#define GEMMINI_POOL_RECORD_COMMAND(f) ((void)0)\n'
            '#define GEMMINI_POOL_COMMAND_RETURN_HOOK(f) yolo32_independent_command_return(f)\n'
            '#define gemmini_pool_active_worker selected',1)
        text=text.replace('emit(8,1,0);','emit(8,1,0);yolo32_independent_command_return(8);',1)
        path.write_text(text)
        cls.flags+=['-DYOLO32_PACKET_DISPATCH=1']
        subprocess.run(['gcc']+cls.flags+[str(cls.local/'test.c'),str(cls.local/'independent.c'),'-o',str(cls.host)],check=True,capture_output=True)


class FormalQueryRuntime(PacketQueryRuntime):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        path=cls.local/'test.c';text=path.read_text()
        text=text.replace('yolo32_independent_begin(repeat==0)','yolo32_independent_begin(0)')
        text=text.replace('if(repeat==0){assert(q->retired_reads','if(0){assert(q->retired_reads')
        text=text.replace('repeat?s->credit_check_cycles[w]==0:s->credit_check_cycles[w]>0','s->credit_check_cycles[w]==0')
        text=text.replace('repeat?s->credit_wait_cycles[w]==0:s->credit_wait_cycles[w]>0','s->credit_wait_cycles[w]==0')
        path.write_text(text)
        cls.flags+=['-DYOLO32_SPLIT_DIAG=1','-DYOLO32_DIAGNOSTIC_BUILD=0']
        subprocess.run(['gcc']+cls.flags+[str(cls.local/'test.c'),str(cls.local/'independent.c'),'-o',str(cls.host)],check=True,capture_output=True)


class FixedOpcodeWS(prepared_tests.PreparedPacketsTests):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        shutil.copy(source_path('packet_dispatch_runtime.inc'),cls.out/'packet_dispatch_runtime.inc')
        header=cls.out/'include/gemmini.h';text=header.read_text()
        text=text.replace('#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) record(f,(uint64_t)(a),(uint64_t)(b))',
                          '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) do{assert(op==3-gemmini_pool_active_worker);record(f,(uint64_t)(a),(uint64_t)(b));}while(0)',1)
        header.write_text(text)
        cls.flags+=['-DYOLO32_PACKET_DISPATCH=1']
        subprocess.run(['gcc']+cls.flags+[str(cls.out/'stream.c'),'-lm','-o',str(cls.exe)],check=True,capture_output=True)


class FixedOpcodeConv(conv_tests.FixedPacketsTests):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        shutil.copy(source_path('packet_dispatch_runtime.inc'),cls.out/'packet_dispatch_runtime.inc')
        header=cls.out/'include/gemmini.h';text=header.read_text()
        text=text.replace('#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) record(f,(uint64_t)(a),(uint64_t)(b))',
            '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) do{assert(op==3-gemmini_pool_active_worker);record(f,(uint64_t)(a),(uint64_t)(b));}while(0)',1)
        header.write_text(text)
        from test_fixed_plans import PARAMS
        from generate_parallel import ABI
        cls.flags=['-std=gnu11','-O2','-include',str(PARAMS),'-I'+str(cls.out),
                   '-I'+str(ABI.parent.parent),'-I'+str(ABI.parent),
                   '-I'+str(HERE.parents[3]/'sw/third_party/gemmini'),
                   '-DYOLO32_PACKET_DISPATCH=1']
        subprocess.run(['gcc']+cls.flags+[str(cls.out/'stream.c'),'-lm','-o',str(cls.exe)],check=True,capture_output=True)

    def test_real_riscv_fixed_opcode_conv_stream(self):
        cc=Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-linux-gnu-gcc');qemu=shutil.which('qemu-riscv64')
        if not cc.is_file() or not qemu:self.skipTest('RISC-V compiler/QEMU unavailable')
        # The reproducibility test restores the native header; reinstall just
        # the terminal instruction recorder for the RISC-V executable.
        header=self.out/'include/gemmini.h';text=header.read_text()
        if '#undef ROCC_INSTRUCTION_0_R_R' not in text:
            text=text.replace('#include "rocc-software/src/xcustom.h"',
                '#include "rocc-software/src/xcustom.h"\n#undef ROCC_INSTRUCTION_0_R_R\n'
                '#define ROCC_INSTRUCTION_0_R_R(op,a,b,f) do{assert(op==3-gemmini_pool_active_worker);record(f,(uint64_t)(a),(uint64_t)(b));}while(0)',1)
            header.write_text(text)
        out=self.out/'riscv-stream'
        subprocess.run([str(cc),'-static','-march=rv64gcv','-mabi=lp64d']+self.flags+
                       [str(self.out/'stream.c'),'-lm','-o',str(out)],check=True,capture_output=True)
        result=subprocess.run([qemu,'-cpu','rv64,v=true,vlen=256',str(out)],capture_output=True,text=True,timeout=30)
        self.assertEqual(result.returncode,0,result.stderr)


class QueryLog(unittest.TestCase):
    def test_capabilities_and_actual_csr_accounting(self):
        from test_credit import CreditLog
        r=CreditLog().example();r.update(credit_query=1,credit_query_stats={})
        for w in range(3):r['credit_query_stats'][w]=dict(worker=str(w),retired_reads='14',retirement_reused='1',
            status_reads='13',budget_rejects='2',hardware_rejects='0',error_probes='0',resume_rechecks='1',
            peer_queries='1',scheduler_queries='4',admit_queries='9',resume_queries='1')
        validate(r)
        r['credit_query_stats'][1]['status_reads']='14'
        with self.assertRaises(ValueError):validate(r)
        for version,flags in [('v23',(1,0,0,1)),('v24',(1,1,0,1)),('v25',(1,1,1,0)),('v25',(1,1,1,1))]:
            row=dict(zip(('credit_query','packet_dispatch','split_diag','diagnostic_build'),map(str,flags)))
            self.assertEqual(configuration(version,row),dict(zip(row,flags)))
            with self.assertRaises(ValueError):configuration('v22',row)
        with self.assertRaises(ValueError):configuration('v25',{})


if __name__=='__main__':unittest.main()
