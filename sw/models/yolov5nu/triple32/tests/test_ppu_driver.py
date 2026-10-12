"""Exercise production publication/queue drivers with a simulated MMIO device."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

HERE=Path(__file__).resolve().parents[1]


class PpuDriverTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp=tempfile.TemporaryDirectory(prefix='yolo32-ppu-')
        root=Path(cls.tmp.name); local=root/'triple32'; local.mkdir(); (root/'dim16_dual').mkdir()
        for name in ('ppu.c','ppu.h','yolo32.h'):
            shutil.copy(HERE/name,local/name)
        shutil.copy(HERE.parents[3]/'sw/src/platform/console.h',local/'console.h')
        for name in ('yolov5nu_dim16_dual.h','yolov5nu_head_layout.h'):
            shutil.copy(HERE/'native'/name,local/name)
        shutil.copy(HERE.parents[3]/'sw/src/platform/platform.h',local/'platform.h')
        (local/'mmio.h').write_text('#include <stdint.h>\nuint32_t mmio_read32(uintptr_t);void mmio_write32(uintptr_t,uint32_t);void mmio_fence(void);uint64_t read_cycle(void);\n')
        (local/'test.c').write_text(r'''
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ppu.h"
#include "platform.h"
#include "yolo32.h"
static uint32_t reg[256], bank, generation[6], allocated[6], record[40], index;
static unsigned valid,pops,retired[3], selected_bank[3], submitted[3];
static uint32_t out_bank,out_generation,out_stream,out_version,out_status;
static uint64_t tick,out_frame,submitted_frame[3],latest_frame[3];
static unsigned known[3];
void console_puts(const char *s){fputs(s,stdout);}
void console_putc(char c){putchar(c);}
void console_put_hex64(uint64_t v){printf("0x%016lX",v);}
uint64_t read_cycle(void) { return ++tick; }
void mmio_fence(void) {}
uint32_t mmio_read32(uintptr_t addr) {
 unsigned o=(unsigned)(addr-POSTPROCESS_DIAG_BASE);
 switch(o) {
 case 0x100:return 0x50505531;case 0x1a0:return 0x50505532;case 0x238:return 0x50505232;
 case 0x1b4:return allocated[bank];case 0x1bc:return generation[bank];case 0x208:return 32;
 case 0x240:return valid;case 0x250:return out_bank;case 0x254:return 1|(out_stream<<10)|(out_status<<14);
 case 0x258:return (uint32_t)out_frame;case 0x25c:return (uint32_t)(out_frame>>32);
 case 0x260:return out_version;case 0x264:return 100;case 0x268:return out_generation;
 case 0x248:assert(valid&&index<40);return record[index];
 default:return reg[o/4];
 }
}
void mmio_write32(uintptr_t addr,uint32_t v) {
 unsigned o=(unsigned)(addr-POSTPROCESS_DIAG_BASE);reg[o/4]=v;
 if(o==0x1a8){bank=v;assert(bank<6);}
 if(o==0x1b0&&v==1){assert(!allocated[bank]);allocated[bank]=1;generation[bank]=reg[0x1ac/4];}
 if(o==0x244)index=v;
 if(o==0x24c&&v==1&&valid){valid=0;++pops;}
 if(o==0x234&&v==1){
   unsigned w=reg[0x20c/4];uint64_t f=((uint64_t)reg[0x214/4]<<32)|reg[0x210/4];
   if(!known[w]||f>=latest_frame[w]){known[w]=1;latest_frame[w]=f;}
 }
 if(o==0x204&&v==1){
   unsigned w=reg[0x20c/4];assert(w<3&&bank/2==w);
   uintptr_t base=AI_MODEL_OUTPUT0_PHYS_BASE+w*AI_MODEL_OUTPUT_ARENA_BYTES+(bank&1)*YOLOV5NU_HEAD_SLOT_STRIDE;
   assert(reg[0x104/4]==base && reg[0x110/4]==base+YOLOV5NU_HEAD_DFL0_OFFSET);
   selected_bank[w]=bank;submitted[w]++;
   submitted_frame[w]=((uint64_t)reg[0x214/4]<<32)|reg[0x210/4];
 }
}
void yolo32_fail(const char *s){puts(s);exit(42);}
void yolo32_finish_hardware(unsigned w){retired[w]++;}
static void completion(unsigned w,uint64_t frame,unsigned fault){
 out_bank=selected_bank[w];out_generation=generation[out_bank]+(fault==1);
 out_stream=w;out_version=(uint32_t)frame;out_frame=submitted_frame[w];
 out_status=fault==2?3:fault==3?2:0;
 if(!known[w]||latest_frame[w]!=out_frame)out_status|=2;
 memset(record,0,sizeof(record));record[0]=100+w;record[1]=200+w;record[2]=(w<<16)|1234;record[3]=77;
 allocated[out_bank]=0;valid=1;
}
int main(int argc,char **argv){
 unsigned fault=argc>1?(unsigned)atoi(argv[1]):0;
 /* Retain a previous firmware's newer expectation, with a restarted CPU clock.
  * High/low CSR words must both participate in the next session frame ID. */
 const uint64_t previous=UINT64_C(0x100000040);
 reg[0x210/4]=(uint32_t)previous;reg[0x214/4]=(uint32_t)(previous>>32);
 for(unsigned w=0;w<3;w++){known[w]=1;latest_frame[w]=previous;}
 yolo32_ppu_init();
 for(unsigned w=0;w<3;w++){
   uintptr_t head=yolo32_ppu_begin(w,1);
   assert(head==AI_DDR_CPU_ALIAS(AI_MODEL_OUTPUT0_PHYS_BASE+w*AI_MODEL_OUTPUT_ARENA_BYTES));
   yolo32_ppu_head(w,3);assert(!submitted[w]);yolo32_ppu_head(w,0);assert(submitted[w]==1);
   assert(submitted_frame[w]>previous);
 }
 /* A hardware result arriving before graph completion must stay owned. */
 completion(0,1,fault);yolo32_ppu_service();assert(!pops&&!yolo32_ppu_done(0));
 yolo32_ppu_graph_done(0);assert(pops==1&&retired[0]==1&&yolo32_ppu_done(0));
 const Yolo32PpuResult *r=yolo32_ppu_result(0);assert(r->count==1&&r->core_cycles==100&&r->words[0][3]==77);
 for(unsigned w=1;w<3;w++)yolo32_ppu_graph_done(w);
 completion(2,1,0);yolo32_ppu_service();assert(yolo32_ppu_done(2)&&!yolo32_ppu_done(1));
 completion(1,1,0);yolo32_ppu_service();assert(yolo32_ppu_done(1)&&pops==3);
 /* A completed bank may now advance to its independent ping-pong partner. */
 assert(yolo32_ppu_begin(0,2)==AI_DDR_CPU_ALIAS(AI_MODEL_OUTPUT0_PHYS_BASE+YOLOV5NU_HEAD_SLOT_STRIDE));
 yolo32_ppu_head(0,3);yolo32_ppu_head(0,0);yolo32_ppu_graph_done(0);
 completion(0,2,0);yolo32_ppu_service();assert(pops==4&&retired[0]==2);
 /* Software-only restart retains hardware expectations and generations. */
 uint64_t last=submitted_frame[0];tick=0;yolo32_ppu_init();
 yolo32_ppu_begin(0,1);yolo32_ppu_head(0,0);yolo32_ppu_graph_done(0);
 assert(submitted_frame[0]>last);
 completion(0,1,0);yolo32_ppu_service();assert(pops==5);
 puts("PASS: production PPU publication/queue, result words, metadata, delayed completion, ping-pong");return 0;
}
''')
        ref=HERE.parents[3]/'sw/src'
        cls.exe=root/'ppu-test'
        sources=[local/'ppu.c',local/'test.c',ref/'ai/postprocess/ai_ppu_publication.c',ref/'ai/postprocess/ai_ppu_queue.c',ref/'ai/runtime/ai_head_slot_queue.c']
        subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror','-I'+str(local),'-I'+str(ref),
                        '-I'+str(root/'dim16_dual')]+list(map(str,sources))+['-o',str(cls.exe)],check=True,capture_output=True)

    @classmethod
    def tearDownClass(cls):cls.tmp.cleanup()

    def test_production_queue_and_result_capture(self):
        r=subprocess.run([self.exe],capture_output=True,text=True)
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
        self.assertIn('PASS:',r.stdout)

    def test_generation_and_ppu_error_are_rejected(self):
        for flag,reason in [('1','ppu_result_metadata'),('2','ppu_result_error_or_stale'),('3','ppu_result_error_or_stale')]:
            r=subprocess.run([self.exe,flag],capture_output=True,text=True)
            self.assertEqual(r.returncode,42,r.stdout+r.stderr)
            self.assertIn(reason,r.stdout)
            self.assertIn('YOLO32_PPU_ERROR',r.stdout)
            self.assertIn('expected_frame=',r.stdout)
            if flag=='2':self.assertIn('engine_error=0x0000000000000001 stale_flag=0x0000000000000001',r.stdout)
            if flag=='3':self.assertIn('engine_error=0x0000000000000000 stale_flag=0x0000000000000001',r.stdout)


if __name__=='__main__':unittest.main()
