/* Native PPU A: publish completed heads early for hardware clean, admit only
 * when this frame's full graph is done. Keep original queue/slot drivers. */
#include "mmio.h"
#include "platform/platform.h"
#include "ai/postprocess/ai_ppu_publication.h"
#include "ai/postprocess/ai_ppu_queue.h"
#include "ai/runtime/ai_head_slot_queue.h"
struct PpuResult {uint32_t count,words[10][4];};
static AiHeadSlotQueue ppu_queue;
static unsigned ppu_keys[3],ppu_done[3],ppu_heads[3],ppu_pending_mask;
static struct PpuResult ppu_result[3];
static uint64_t ppu_frame_base;
static uint32_t pget(unsigned o) {return mmio_read32(POSTPROCESS_DIAG_BASE+o);}
static void pput(unsigned o,uint32_t v) {mmio_write32(POSTPROCESS_DIAG_BASE+o,v);}
void at_io_commit(void) {
    __asm__ volatile("":::"memory");
    if(pget(0x1a0)!=UINT32_C(0x50505532))at_fail("ppu_mmio_ordering",0);
    __asm__ volatile("":::"memory");
}
static uint64_t pframe(unsigned o) {
    uint32_t hi,lo,next;do{hi=pget(o+4);lo=pget(o);next=pget(o+4);}while(hi!=next);
    return ((uint64_t)hi<<32)|lo;
}
static void ppu_init(void) {
    if(pget(0x100)!=UINT32_C(0x50505531)||!ai_ppu_publication_available()||!ai_ppu_queue_init())at_fail("hardware_ppu_missing",pget(0x100));
    pput(0x148,1);if(!(pget(0x148)&1))at_fail("ppu_local_reader",0);
    ppu_frame_base=clock_cycle();uint64_t old=pframe(0x210),active=pframe(0x228);
    if(old>ppu_frame_base)ppu_frame_base=old;
    if(active>ppu_frame_base)ppu_frame_base=active;
    AiPpuQueueResult stale;
    for(unsigned i=0;i<16&&ai_ppu_queue_peek(&stale);i++){if(stale.frame>ppu_frame_base)ppu_frame_base=stale.frame;ai_ppu_queue_pop();}
    if(ai_ppu_queue_peek(&stale))at_fail("ppu_stale_queue",0);
    pput(0x24c,0);ai_head_slot_queue_init(&ppu_queue,3);
    for(unsigned d=0;d<3;d++)ppu_keys[d]=AI_HEAD_SLOT_INVALID;
}
static unsigned ppu_begin(unsigned d,unsigned run) {
    AiModelFrameRequest req={0};req.worker_id=d;req.stream_id=d;req.job_id=run;req.frame_id=ppu_frame_base+run;req.version=run;
    if(req.frame_id<ppu_frame_base)at_fail("ppu_frame_overflow",run);
    uintptr_t base=AI_MODEL_OUTPUT0_PHYS_BASE+d*AI_MODEL_OUTPUT_ARENA_BYTES;
    if(ai_head_slot_acquire(&ppu_queue,d,base,&req,&ppu_keys[d]))at_fail("ppu_slot_acquire",d);
    AiHeadSlot *s=ai_head_slot_get(&ppu_queue,ppu_keys[d]);
    if(!s||ai_ppu_publication_begin(s->descriptor.base_addr)!=1)at_fail("ppu_publication_begin",d);
    ai_ppu_queue_expect(d,req.frame_id,req.version);ppu_done[d]=ppu_heads[d]=0;memset(&ppu_result[d],0,sizeof(ppu_result[d]));
    if(AI_DDR_CPU_ALIAS(s->descriptor.base_addr)!=head_address(d,s->slot_id))at_fail("head_alias",s->descriptor.base_addr);
    return s->slot_id;
}
static void ppu_head(unsigned d,unsigned h) {
    AiHeadSlot *s=ai_head_slot_get(&ppu_queue,ppu_keys[d]);
    if(!s||s->state!=AI_HEAD_SLOT_WRITING||h>=6||(ppu_heads[d]&(1U<<h)))at_fail("head_ownership",d);
    /* The caller has observed HOST after the native local completion barrier.
     * Publish only that immutable head, never uncompleted frame data. */
    ai_ppu_publication_publish(s->descriptor.base_addr,1U<<h);at_io_commit();ppu_heads[d]|=1U<<h;
    uint64_t start=clock_cycle();uint32_t generation=ai_ppu_publication_generation(s->descriptor.base_addr);
    for(;;) {
        uint32_t status=pget(0x1b4);
        if(pget(0x1bc)!=generation||(status&4)||!(status&1))at_fail("head_publication_metadata",status);
        if(((pget(0x1b8)>>8)&63)==ppu_heads[d])break;
        if(clock_cycle()-start>1000000)at_fail("head_publication_timeout",h);
    }
}
static void ppu_graph_done(unsigned d) {
    if(ppu_heads[d]!=63)at_fail("unpublished_heads",ppu_heads[d]);
    if(ai_head_slot_publish(&ppu_queue,ppu_keys[d]))at_fail("ppu_graph_publish",d);
    ppu_pending_mask|=1U<<d;
}
static void ppu_service(void) {
    if(!ppu_pending_mask)return;
#if YOLO32_FRONTEND_DIAG
    uint64_t service_begin=clock_cycle();
#endif
    AiPpuQueueResult r;
    if(ai_ppu_queue_peek(&r)) {
        AiHeadSlot *s=ai_head_slot_get(&ppu_queue,r.bank);
        if(!s||s->state!=AI_HEAD_SLOT_PROCESSING||!s->producer_complete||r.stream>=3||r.count>10||r.status||
           r.stream!=s->descriptor.stream_id||r.frame!=s->descriptor.frame_id||r.version!=s->descriptor.version||
           r.generation!=ai_ppu_publication_generation(s->descriptor.base_addr))at_fail("ppu_result_metadata_or_error",r.status);
        unsigned d=s->descriptor.worker_id;if(ppu_done[d])at_fail("ppu_duplicate_result",d);
        ppu_result[d].count=r.count;
        for(unsigned i=0;i<10;i++)for(unsigned j=0;j<4;j++){pput(0x244,i*4+j);ppu_result[d].words[i][j]=pget(0x248);}
        ai_ppu_queue_pop();ppu_queue.active=r.bank;
        if(ai_head_slot_complete(&ppu_queue,0))at_fail("ppu_complete",d);
        ppu_done[d]=1;
        ppu_pending_mask&=~(1U<<d);
    }
    while(ppu_queue.ready_count&&ai_ppu_queue_ready()) {
        AiHeadSlot *s;
        if(ai_head_slot_start_next(&ppu_queue,&s)!=1||ai_ppu_queue_submit(&s->descriptor)!=1)at_fail("ppu_submit",0);
        if(pget(0x204)!=UINT32_C(0x50505132))at_fail("ppu_doorbell_commit",0);
        ppu_queue.active=AI_HEAD_SLOT_INVALID;
    }
#if YOLO32_FRONTEND_DIAG
    ppu_service_cycles+=clock_cycle()-service_begin;
#endif
}
