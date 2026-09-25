#include "ai_ppu_queue.h"
#include "ai_ppu_publication.h"
#include "mmio.h"
#include "platform.h"
static int enabled;
static void put(uint32_t offset,uint32_t value) { mmio_write32(POSTPROCESS_DIAG_BASE+offset,value); }
static uint32_t get(uint32_t offset) { return mmio_read32(POSTPROCESS_DIAG_BASE+offset); }
int ai_ppu_queue_init(void)
{
    enabled=0;
    if(get(0x238)!=UINT32_C(0x50505232)) return 0;
    put(0x200,1);enabled=(get(0x200)&1U)!=0;return enabled;
}
int ai_ppu_queue_active(void) { return enabled; }
static void metadata(uint32_t stream,uint64_t frame,uint32_t version)
{
    put(0x20c,stream);put(0x210,(uint32_t)frame);put(0x214,(uint32_t)(frame>>32));put(0x218,version);
}
void ai_ppu_queue_expect(uint32_t stream,uint64_t frame,uint32_t version)
{
    if(enabled) { metadata(stream,frame,version);put(0x234,1); }
}
int ai_ppu_queue_ready(void) { return enabled && (get(0x208)&32U); }
int ai_ppu_queue_submit(const AiHeadSlotDescriptor *d)
{
    if(!ai_ppu_queue_ready()) return 0;
    if(ai_ppu_publication_select(d->base_addr)<=0) return -1;
    for(uint32_t i=0;i<3;i++) { put(0x104+4*i,(uint32_t)d->class_addr[i]);put(0x110+4*i,(uint32_t)d->dfl_addr[i]); }
    metadata(d->stream_id,d->frame_id,d->version);put(0x21c,0);mmio_fence();put(0x204,1);
    return 1;
}
int ai_ppu_queue_peek(AiPpuQueueResult *r)
{
    if(!enabled || !(get(0x240)&1U)) return 0;
    uint32_t packed=get(0x254);
    r->bank=get(0x250);r->generation=get(0x268);r->count=packed&63U;
    r->stream=(packed>>10)&15U;r->status=(packed>>14)&15U;
    r->frame=get(0x258);r->frame|=(uint64_t)get(0x25c)<<32;
    r->version=get(0x260);r->cycles=get(0x264);return 1;
}
void ai_ppu_queue_pop(void) { put(0x24c,1); }
