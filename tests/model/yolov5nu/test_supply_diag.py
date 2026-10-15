from paths import HERE, source_path
"""Production scheduler/credit/packet diagnostics and strict log conservation."""
from pathlib import Path
import copy
import shutil
import subprocess
import sys
import unittest

import test_credit as credit_tests
from supply_diag_log import validate, CATEGORIES, HARDWARE, SOURCES
from diagnostic_traffic import matrix, union_bytes, analyze
from generate_parallel import function


class SupplyScheduler(credit_tests.CooperativeCredit):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        shutil.copy(source_path('diagnostics.c'),cls.local/'diagnostics.c')
        (cls.local/'console.h').write_text('#include <stdint.h>\nvoid console_puts(const char*);void console_putc(char);void console_put_u32(uint32_t);void console_put_hex64(uint64_t);\n')
        source=(cls.local/'test.c').read_text()
        source=source.replace('static unsigned selected,', '#define gemmini_pool_active_worker selected\nstatic unsigned selected,',1)
        stub='static inline uint64_t yolo32_packet_address(const void *b,uint32_t o){return o==UINT32_MAX?0:(uintptr_t)b+o;}'
        assert stub in source
        source=source.replace(stub,function((source_path('fixed_packets_runtime.inc')).read_text(),
                                           'static inline uint64_t yolo32_packet_address('),1)
        source=source.replace('uint64_t tick;', 'uint64_t tick;\n'
            'void console_puts(const char*s){(void)s;} void console_putc(char c){(void)c;}\n'
            'void console_put_u32(uint32_t n){(void)n;} void console_put_hex64(uint64_t n){(void)n;}\n',1)
        source=source.replace('static void conv(unsigned tile){',
            'static void conv(unsigned tile){\n'
            ' yolo32_diag_work(selected,1); yolo32_diag_conv_next(selected,tile<8);',1)
        source=source.replace('if(stage[w]==14){','if(stage[w]==14){\n'
            '   yolo32_diag_stage_begin(w,14,"conv");',1)
        source=source.replace('stage[w]=165;heads[w]=63;',
            'yolo32_diag_stage_end(w);stage[w]=165;heads[w]=63;',1)
        source=source.replace('yolo32_independent_begin(repeat==0);',
            'yolo32_diag_reset(repeat==0);yolo32_independent_begin(repeat==0);',1)
        source=source.replace('assert(s->conv_requests[w]==9&&s->matmul_requests[w]==1);',
            '''assert(s->conv_requests[w]==9&&s->matmul_requests[w]==1);
     if(!repeat){
       uint64_t checks=0,cycles=0,blocked=0;
       for(unsigned origin=0;origin<DIAG_SOURCES;origin++){
         const Yolo32DiagCredit *c=yolo32_diag_credit(w,origin);
         assert(c->checks==c->ready+c->budget_only+c->hardware_only+c->both);
         assert(c->checks==c->pending[0]+c->pending[1]+c->pending[2]+c->pending[3]);
         assert(c->budget_only+c->both==c->pending[3]);
         checks+=c->checks;cycles+=c->cycles;blocked+=c->budget_only+c->hardware_only+c->both;
       }
       assert(checks==s->credit_checks[w]&&cycles==s->credit_check_cycles[w]&&blocked==s->credit_blocked[w]);
       const Yolo32DiagSupply *d=yolo32_diag_supply(w);
       assert(d->known_packets==9&&d->submitted_packets==9&&d->events==9);
       assert(d->admitted[0]+d->admitted[1]+d->admitted[2]==9&&!d->admitted[3]);
       assert(d->gap_cycles==d->peer_cycles+d->scheduler_cycles+d->self_cycles);
       assert(d->gap_cycles>0&&d->positive_samples>=d->events);
       const Yolo32DiagStage *stage_d=yolo32_diag_stage(w,14);
       assert(stage_d->flow.events==d->events&&stage_d->flow.gap_cycles==d->gap_cycles);
       assert(stage_d->cpu[DIAG_ADDRESS]>0);
     }
''',1)
        source=source.replace('puts("PASS: credit=3;',
            '''/* Clock attribution must survive a peer and scheduler interval. */
 yolo32_diag_reset(1);yolo32_diag_owner(0);yolo32_diag_stage_begin(0,0,"conv");
 unsigned parent=yolo32_diag_push(0,DIAG_PREPARE);tick+=50;
 unsigned nested=yolo32_diag_push(0,DIAG_ADDRESS);tick+=20;yolo32_diag_pop(0,nested);
 yolo32_diag_work(0,1);yolo32_diag_credit_status(0,2);
 yolo32_diag_credit_record(0,1,DIAG_PEER,7);
 yolo32_diag_owner(1);tick+=200;yolo32_diag_owner(3);tick+=100;
 yolo32_diag_owner(0);tick+=30;yolo32_diag_packet_start(0);yolo32_diag_pop(0,parent);
 const Yolo32DiagSupply *gap_d=yolo32_diag_supply(0);
 assert(gap_d->peer_cycles>=200&&gap_d->scheduler_cycles>=100&&gap_d->self_cycles>=30);
 assert(gap_d->gap_cycles==gap_d->peer_cycles+gap_d->scheduler_cycles+gap_d->self_cycles);
 const Yolo32DiagStage *cpu_d=yolo32_diag_stage(0,0);
 assert(cpu_d->cpu[DIAG_ADDRESS]>=20&&cpu_d->cpu[DIAG_ADDRESS]<100);
 assert(cpu_d->cpu[DIAG_PREPARE]>=80&&cpu_d->cpu[DIAG_PREPARE]<200);
 uint32_t before[6],after[6];for(unsigned i=0;i<6;i++){before[i]=UINT32_MAX-2;after[i]=2;}
 yolo32_diag_hw_begin(0,before);yolo32_diag_hw_end(0,after);
 assert(cpu_d->hw_valid==1);for(unsigned i=0;i<6;i++)assert(cpu_d->hw[i]==5);
 yolo32_diag_copy(0,64,64);assert(cpu_d->copy_read_bytes==64&&cpu_d->copy_write_bytes==64);
 /* A later negative snapshot withdraws a candidate; never count it as supplied. */
 yolo32_diag_work(0,1);yolo32_diag_credit_status(0,2);yolo32_diag_credit_record(0,1,DIAG_SCHEDULER,1);
 tick+=40;yolo32_diag_credit_status(0,0);yolo32_diag_credit_record(0,1,DIAG_RESUME,1);
 assert(gap_d->events==1&&gap_d->withdrawn_events==1&&gap_d->withdrawn_cycles>=40);
 yolo32_diag_credit_status(0,2);yolo32_diag_credit_record(0,3,DIAG_ADMIT,1);
 assert(yolo32_diag_credit(0,DIAG_ADMIT)->budget_only==1);
 yolo32_diag_credit_status(0,0);yolo32_diag_credit_record(0,3,DIAG_ADMIT,1);
 assert(yolo32_diag_credit(0,DIAG_ADMIT)->both==1);
 yolo32_diag_credit_status(0,(2U<<8)|(1U<<12));yolo32_diag_credit_record(0,3,DIAG_ADMIT,1);
 assert(yolo32_diag_credit(0,DIAG_ADMIT)->hw_queue_full==1&&yolo32_diag_credit(0,DIAG_ADMIT)->hw_partial==1);
 puts("PASS: credit=3;''',1)
        (cls.local/'test.c').write_text(source)
        cls.flags += ['-DYOLO32_SUPPLY_DIAG=1','-DYOLO32_ROCC_LAYERS=1']
        subprocess.run(['gcc']+cls.flags+[str(cls.local/'test.c'),str(cls.local/'independent.c'),str(cls.local/'diagnostics.c'),'-o',str(cls.host)],check=True,capture_output=True)

    def test_actual_riscv_switch_preserves_credit_packet(self):
        cc=Path('/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-linux-gnu-gcc')
        qemu=shutil.which('qemu-riscv64')
        if not cc.exists() or not qemu: self.skipTest('RISC-V compiler/QEMU unavailable')
        exe=self.root/'riscv-diag'
        subprocess.run([cc,'-static','-march=rv64gcv','-mabi=lp64d']+self.flags+
            [str(self.local/'test.c'),str(self.local/'independent.c'),str(self.local/'diagnostics.c'),str(self.local/'task_switch.S'),'-o',str(exe)],check=True,capture_output=True)
        self.check_executable([qemu,'-cpu','rv64,v=true,vlen=256',exe])


class SupplyLog(unittest.TestCase):
    def example(self):
        def row(**kwargs): return {k:str(v) for k,v in kwargs.items()}
        r=dict(supply_diag=1,supply_detail=1,analysis=1,rocc_layers=1,mode='independent',credit_limit=3,graph=10000,
               credit={},credit_sources={},supply={},cpu_details={},hw_stages={},feed_stages={},task_stages={},rocc_layer_stats={})
        r.update(hw_totals={},profiles={})
        for w in range(3):
            r['hw_totals'][w]=row(worker=w,**{h:0 for h in HARDWARE})
            r['profiles'][w]=row(gem_busy=0,exec=0,load_stall=0,store_stall=0)
            r['rocc_layer_stats'][(w,0,15)]=row(count=1)
            r['credit'][w]=row(admitted=1,checks=2,blocked=1,check_cycles=10)
            for source in SOURCES:
                nonzero=source=='admit'
                r['credit_sources'][(w,source)]=row(worker=w,source=source,cycles=10 if nonzero else 0,
                    checks=2 if nonzero else 0,ready=int(nonzero),budget_only=int(nonzero),hardware_only=0,both=0,
                    pending0=int(nonzero),pending1=0,pending2=0,pending3=int(nonzero),**{k:0 for k in ('hw_slots_full','hw_queue_full','hw_partial','hw_unknown')})
            r['supply'][w]=row(worker=w,events=1,gap_cycles=10,peer_cycles=4,scheduler_cycles=3,self_cycles=3,
                max_gap=10,withdrawn_events=0,withdrawn_cycles=0,positive_samples=1,known_packets=1,
                submitted_packets=1,scheduler_bind_cycles=0,admit0=1,admit1=0,admit2=0,admit3=0)
            for stage in range(165):
                key=(w,stage)
                r['task_stages'][key]=row(kind='conv' if stage==0 else 'cpu',span_cycles=100)
                r['cpu_details'][key]=row(worker=w,stage=stage,copy_read=0,copy_write=0,**{c:1 for c in CATEGORIES})
                r['hw_stages'][key]=row(worker=w,stage=stage,samples=1,**{h:0 for h in HARDWARE})
            r['feed_stages'][(w,0)]=row(worker=w,stage=0,checks=2,ready=1,budget_only=1,hardware_only=0,both=0,
                pending0=1,pending1=0,pending2=0,pending3=1,events=1,gap_cycles=10,peer_cycles=4,scheduler_cycles=3,self_cycles=3)
        return r

    def test_closed_sources_depth_cpu_hardware_and_supply(self):
        validate(self.example())

    def test_light_pass_has_no_detailed_records_and_total_counters_match(self):
        r=self.example();r.update(supply_detail=0,cpu_details={},hw_stages={})
        validate(r)
        r['hw_totals'][1]['load_dma']='1'
        with self.assertRaises(ValueError): validate(r)

    def test_missing_rows_and_inconsistent_classes_are_rejected(self):
        for collection,key in (('credit_sources',(0,'resume')),('cpu_details',(2,164)),('hw_stages',(1,100)),('feed_stages',(0,0)),('supply',2)):
            r=self.example(); del r[collection][key]
            with self.subTest(collection=collection),self.assertRaises(ValueError): validate(r)
        for collection,key,field,value in (
            ('credit_sources',(0,'admit'),'budget_only','0'),('credit_sources',(0,'admit'),'cycles','11'),
            ('credit_sources',(0,'admit'),'pending3','0'),('supply',0,'peer_cycles','99'),
            ('supply',0,'admit3','1'),('cpu_details',(0,0),'address','1000'),
            ('hw_stages',(0,0),'samples','0'),('feed_stages',(0,0),'events','2')):
            r=self.example(); r[collection][key][field]=value
            with self.subTest(field=field),self.assertRaises(ValueError): validate(r)

    def test_unflagged_records_rejected_and_legacy_accepted(self):
        r=self.example();r['supply_diag']=0
        with self.assertRaises(ValueError): validate(r)
        validate(dict(supply_diag=0))


class LogicalTraffic(unittest.TestCase):
    def test_sparse_rows_overlap_and_broadcast(self):
        self.assertEqual(matrix(8,3,2,4),[(8,10),(12,14),(16,18)])
        self.assertEqual(matrix(8,3,2,0,4),[(8,16)])
        self.assertEqual(union_bytes([(0,8),(4,12),(15,19),(0,8)]),16)
        with self.assertRaises(ValueError): union_bytes([(4,2)])

    def test_ws_null_reuse_strides_and_repeated_weights(self):
        packet=dict(bounds=[0,(1<<32)|(1<<16)|1],launch=[0,0],roles=[0,4,255,8],offsets=[0]*4,strides=[32]*4)
        m=dict(fixed_packets={},prepared_ws={'1':dict(helper='gemmini_splitk_x',packets=2,
            bases=['tensor_A','NULL','NULL','NULL','weight','NULL','NULL','NULL','tensor_C','NULL'],steps=[[1,0],[1,1]])},
            prepared_ws_packets=[packet,copy.deepcopy(packet)])
        m['prepared_ws_packets'][1]['roles'][0]=255
        result=analyze(m)['1']
        self.assertEqual(result['input']['logical_span_bytes'],1024)
        self.assertEqual(result['input']['null_reuse_or_no_transfer'],1)
        self.assertEqual(result['weight']['logical_span_bytes'],2048)
        self.assertEqual(result['weight']['logical_unique_bytes'],1024)
        self.assertEqual(result['weight']['logical_overlap_bytes'],1024)
        self.assertEqual(result['output']['logical_span_bytes'],2048)
