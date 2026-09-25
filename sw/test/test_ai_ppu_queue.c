#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "platform.h"
#include "ai_ppu_queue.h"
static uint32_t regs[256];
uint64_t test_cycle;
uint32_t mmio_read32(uintptr_t a) { assert(a>=POSTPROCESS_DIAG_BASE && a<POSTPROCESS_DIAG_BASE+1024); return regs[(a-POSTPROCESS_DIAG_BASE)/4]; }
void mmio_write32(uintptr_t a,uint32_t v) { assert(a>=POSTPROCESS_DIAG_BASE && a<POSTPROCESS_DIAG_BASE+1024); regs[(a-POSTPROCESS_DIAG_BASE)/4]=v; }
void mmio_fence(void) {}
int ai_ppu_publication_select(uintptr_t base) { return base==0x32000000?1:-1; }
int main(void)
{
 assert(ai_ppu_queue_init()==0);
 regs[0x238/4]=0x50505232;assert(ai_ppu_queue_init()==1);
 AiHeadSlotDescriptor d={.base_addr=0x32000000,.stream_id=5,.frame_id=UINT64_C(0x123456789),.version=0xffffffff,
 .class_addr={0x32000000,0x3205dc00,0x32075300},.dfl_addr={0x3207b0c0,0x320c60c0,0x320d8cc0}};
 assert(ai_ppu_queue_submit(&d)==0);regs[0x208/4]=32;
 assert(ai_ppu_queue_submit(&d)==1);assert(regs[0x204/4]==1);
 assert(regs[0x104/4]==d.class_addr[0]&&regs[0x118/4]==d.dfl_addr[2]);
 assert(regs[0x210/4]==0x23456789&&regs[0x214/4]==1&&regs[0x218/4]==0xffffffff);
 ai_ppu_queue_expect(6,100,0);assert(regs[0x234/4]==1&&regs[0x20c/4]==6);
 AiPpuQueueResult r;assert(ai_ppu_queue_peek(&r)==0);
 regs[0x240/4]=1;regs[0x250/4]=3;regs[0x268/4]=7;
 regs[0x254/4]=(2<<14)|(5<<10)|10;regs[0x258/4]=0x23456789;regs[0x25c/4]=1;
 regs[0x260/4]=0xffffffff;regs[0x264/4]=42268;
 assert(ai_ppu_queue_peek(&r)==1&&r.bank==3&&r.generation==7&&r.stream==5&&r.count==10&&r.status==2);
 assert(r.frame==UINT64_C(0x123456789)&&r.version==0xffffffff&&r.cycles==42268);
 ai_ppu_queue_pop();assert(regs[0x24c/4]==1);
 puts("AI_PPU_QUEUE_DRIVER=PASS");return 0;
}
