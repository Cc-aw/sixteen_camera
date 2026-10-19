"""Exercise actual model views and reject stale bindings, guards and ranges."""
import os
from pathlib import Path
import shlex
import subprocess
import unittest

ROOT=Path(__file__).resolve().parents[1]
HARNESS=r'''
#define main original_plan_main
#include "yolo_boundary.c"
#undef main
static bool reject_completion(void *context,unsigned lane) {(void)context;(void)lane;return false;}
int main(int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)atoi(argv[1]):0;
    yolo_bind_storage(0,1);
    if(activation_memory_commit(&arena_views[0],NULL,NULL) ||
       activation_memory_commit(&arena_views[0],reject_completion,NULL))return 10;
    int8_t *cpu=NULL;uintptr_t dma=0;
    if(activation_memory_offset(&arena_views[0],ASRAM_ARENA_BYTES-1,2,&cpu,&dma) ||
       activation_memory_offset(&arena_views[0],SIZE_MAX,1,&cpu,&dma))return 11;
    if(fault==1)yolo_bind_storage(1,0);
    prepare_model();GfCommand stale={0};
    for(unsigned i=0;i<plans[0][0][0].count;i++) {
        GfCommand c=plans[0][0][0].commands[i];
        if((c.control>>8)==20 && normalized_address(c.rs2,0,0,0,1)>>63){stale=c;break;}
    }
    yolo_bind_storage(1,1);
    if(fault==2)normalize(stale,0,0,0);
    for(unsigned lane=0;lane<3;lane++) {
        if(arena_views[lane].dma_base!=ASRAM_BASE_0+lane*ASRAM_RESERVED_STRIDE ||
           arena_views[lane].physical_bytes!=ASRAM_BYTES_PER_BANK ||
           arena_views[lane].logical_bytes!=ASRAM_ARENA_BYTES ||
           (uintptr_t)arena_views[lane].cpu_base==arena_views[lane].dma_base)return 12;
        select_worker_memory(lane);
        if(activation_arena!=arena_views[lane].cpu_base)return 13;
    }
    yolo_fill_arenas(0x35);
    for(unsigned lane=0;lane<3;lane++)for(size_t i=0;i<ASRAM_ARENA_BYTES;i++)
        if(arena_views[lane].cpu_base[i]!=0x35)return 14;
    yolo_fill_arenas(0);
    for(unsigned lane=0;lane<3;lane++)for(size_t i=0;i<ASRAM_ARENA_BYTES;i++)
        if(arena_views[lane].cpu_base[i]!=0)return 15;
    prepare_model();
    if(fault==3)arena_views[1].cpu_base[ASRAM_ARENA_BYTES]=0;
    if(fault==4)arena_views[2].cpu_base[ASRAM_BYTES_PER_BANK-1]=0;
    if(fault==5)normalized_range(arena_views[0].cpu_base+ASRAM_ARENA_BYTES-1,2,0,0,0,1);
    yolo_check_guards();
    puts("YOLO_ARENA_HOST_PASS profiles=2 full_init=1 native_tables=18 host_only=1");
    return 0;
}
'''


class YoloArena(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        out=ROOT/'build/tests';out.mkdir(parents=True,exist_ok=True)
        source=out/'yolo_arena.c';source.write_text(HARNESS);cls.exe=out/'yolo_arena'
        flags=shlex.split(os.environ['YOLO_FLAGS'])
        includes=[ROOT/'src',ROOT/'build/yolo_generated',ROOT/'build/yolo_generated/include',
                  ROOT/'include',ROOT/'build/generated',ROOT/'model',ROOT/'model/include']
        subprocess.run([os.environ.get('HOST_CC','cc'),*flags,'-DACTIVATION_MEMORY_HOST_TEST',
                        *['-I'+str(p) for p in includes],'-include',str(ROOT/'include/config.h'),
                        str(source),str(ROOT/'src/activation_memory.c'),str(ROOT/'model/inputs.c'),
                        '-Wl,--gc-sections','-lm','-o',str(cls.exe)],check=True)

    def execute(self,fault):
        return subprocess.run([str(self.exe),str(fault)],capture_output=True,text=True,timeout=20)

    def test_real_views_initialization_and_completion(self):
        result=self.execute(0)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)
        self.assertIn('YOLO_ARENA_HOST_PASS',result.stdout)

    def test_busy_switch_stale_plan_full_tail_and_range_are_rejected(self):
        for fault,reason in ((1,'arena_switch_not_quiescent'),(2,'operand_outside_owned_buffers'),
                             (3,'arena_tail_guard'),(4,'arena_tail_guard'),(5,'operand_outside_owned_buffers')):
            with self.subTest(fault=fault):
                result=self.execute(fault)
                self.assertEqual(result.returncode,1,result.stdout+result.stderr)
                self.assertIn(reason,result.stdout)


if __name__=='__main__':unittest.main()
