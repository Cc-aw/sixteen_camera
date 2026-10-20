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
    for(unsigned lane=0;lane<3;lane++)
        if(memory_pad[lane]!=ddr_memory_pad[lane] ||
           memory_intermediate[lane]!=ddr_memory_intermediate[lane])return 20;
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
        const size_t offsets[]={SPPF_PAD_OFFSET,SPPF_INTERMEDIATE_OFFSET};
        const size_t sizes[]={SPPF_PAD_BYTES,SPPF_INTERMEDIATE_BYTES};
        int8_t *buffers[]={memory_pad[lane],memory_intermediate[lane]};
        int8_t *ddr[]={ddr_memory_pad[lane],ddr_memory_intermediate[lane]};
        for(unsigned k=0;k<2;k++) {
            if(buffers[k]!=(YOLO_SPPF_ASRAM?arena_views[lane].cpu_base+offsets[k]:ddr[k]))return 21;
            for(unsigned end=0;end<2;end++) {
                size_t off=end?sizes[k]-1:0;
                uintptr_t cpu=(uintptr_t)buffers[k]+off;
                uintptr_t dma=arena_dma_address(cpu,lane);
                if(dma!=(YOLO_SPPF_ASRAM?arena_views[lane].dma_base+offsets[k]+off:cpu))return 22;
                uint64_t expected=(UINT64_C(1)<<63)|((uint64_t)(3+k)<<40)|off;
                if(normalized_address(cpu,lane,0,0,k)!=expected ||
                   normalized_address(dma,lane,0,0,k)!=expected)return 23;
            }
            normalized_range(buffers[k],sizes[k],lane,0,0,1);
        }
    }
    yolo_fill_arenas(0x35);
    for(unsigned lane=0;lane<3;lane++)for(size_t i=0;i<ASRAM_ARENA_BYTES;i++)
        if(arena_views[lane].cpu_base[i]!=0x35)return 14;
    for(unsigned lane=0;lane<3;lane++) {
        for(size_t i=0;i<SPPF_PAD_BYTES;i++)if(memory_pad[lane][i]!=0x35)return 24;
        for(size_t i=0;i<SPPF_INTERMEDIATE_BYTES;i++)if(memory_intermediate[lane][i]!=0x35)return 25;
    }
    yolo_fill_arenas(0);
    for(unsigned lane=0;lane<3;lane++)for(size_t i=0;i<ASRAM_ARENA_BYTES;i++)
        if(arena_views[lane].cpu_base[i]!=0)return 15;
    prepare_model();
    if(fault==3)arena_views[1].cpu_base[ASRAM_ARENA_BYTES]=0;
    if(fault==4)arena_views[2].cpu_base[ASRAM_BYTES_PER_BANK-1]=0;
    if(fault==5)normalized_range(arena_views[0].cpu_base+ASRAM_ARENA_BYTES-1,2,0,0,0,1);
    if(fault==6)arena_views[0].cpu_base[SPPF_INTERMEDIATE_OFFSET-1]=0;
    if(fault==7)normalized_address(arena_dma_address((uintptr_t)memory_pad[1],1),0,0,0,0);
    if(fault==8)normalized_range(memory_pad[0],SPPF_PAD_BYTES+1,0,0,0,1);
    if(fault==9 && YOLO_SPPF_ASRAM)normalized_address((uintptr_t)ddr_memory_pad[0],0,0,0,0);
    planning=0;
    for(unsigned lane=0;lane<3;lane++) {
        for(size_t i=0;i<SPPF_INTERMEDIATE_BYTES;i++)memory_intermediate[lane][i]=(int8_t)(i*37+lane*71);
        memory_pad_input(memory_intermediate[lane],memory_pad[lane],15,20,128);
        for(unsigned y=0;y<17;y++)for(unsigned x=0;x<22;x++)for(unsigned c=0;c<128;c++) {
            int8_t expected=(y==0 || y==16 || x==0 || x==21)?-128:
                memory_intermediate[lane][((y-1)*20+x-1)*128+c];
            if(memory_pad[lane][(y*22+x)*128+c]!=expected)return 26;
        }
    }
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
                             (3,'arena_tail_guard'),(4,'arena_tail_guard'),(5,'operand_outside_owned_buffers'),
                             (6,'arena_tail_guard'),(7,'operand_outside_owned_buffers'),
                             (8,'operand_outside_owned_buffers'),(9,'operand_outside_owned_buffers')):
            if fault==9 and '-DYOLO_SPPF_ASRAM=0' in os.environ['YOLO_FLAGS']:continue
            with self.subTest(fault=fault):
                result=self.execute(fault)
                self.assertEqual(result.returncode,1,result.stdout+result.stderr)
                self.assertIn(reason,result.stdout)


if __name__=='__main__':unittest.main()
