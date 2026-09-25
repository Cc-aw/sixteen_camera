#include "ai_ppu_publication.h"
#include "mmio.h"
#include "platform.h"
static uint32_t generations[4];
static int bank_of(uintptr_t base)
{
    switch ((uint32_t)base & UINT32_C(0x7ff00000)) {
    case UINT32_C(0x32000000): return 0;
    case UINT32_C(0x32100000): return 1;
    case UINT32_C(0x32400000): return 2;
    case UINT32_C(0x32500000): return 3;
    default: return -1;
    }
}
uint32_t ai_ppu_publication_generation(uintptr_t base) { int bank=bank_of(base); return bank<0?0:generations[bank]; }
int ai_ppu_publication_available(void)
{
    return mmio_read32(POSTPROCESS_DIAG_BASE+0x1a0U)==UINT32_C(0x50505532);
}
int ai_ppu_publication_select(uintptr_t base)
{
    int bank=bank_of(base);
    if (!ai_ppu_publication_available()) return 0;
    if (bank<0) return -1;
    mmio_write32(POSTPROCESS_DIAG_BASE+0x1a8U,(uint32_t)bank);
    mmio_write32(POSTPROCESS_DIAG_BASE+0x1acU,generations[bank]);
    return 1;
}
int ai_ppu_publication_begin(uintptr_t base)
{
    int bank=bank_of(base);
    if (!ai_ppu_publication_available()) return 0;
    if (bank<0) return -1;
    mmio_write32(POSTPROCESS_DIAG_BASE+0x1a4U,1U);
    mmio_write32(POSTPROCESS_DIAG_BASE+0x1a8U,(uint32_t)bank);
    if (mmio_read32(POSTPROCESS_DIAG_BASE+0x1b4U)&1U) return -1;
    generations[bank]=mmio_read32(POSTPROCESS_DIAG_BASE+0x1bcU)+1U;
    mmio_write32(POSTPROCESS_DIAG_BASE+0x1acU,generations[bank]);
    mmio_write32(POSTPROCESS_DIAG_BASE+0x1b0U,1U);
    mmio_fence();
    return (mmio_read32(POSTPROCESS_DIAG_BASE+0x1b4U)&1U) &&
        mmio_read32(POSTPROCESS_DIAG_BASE+0x1bcU)==generations[bank] ? 1 : -1;
}
void ai_ppu_publication_publish(uintptr_t base,uint32_t mask)
{
    if (ai_ppu_publication_select(base)>0) {
        mmio_fence();
        mmio_write32(POSTPROCESS_DIAG_BASE+0x1b0U,(mask&63U)<<8);
    }
}
void ai_ppu_publication_abort(uintptr_t base)
{
    if (ai_ppu_publication_select(base)>0) {
        mmio_write32(POSTPROCESS_DIAG_BASE+0x1b0U,4U);
        mmio_fence();
        /* A live clean must drain before release; faults otherwise retain ownership. */
        if (!(mmio_read32(POSTPROCESS_DIAG_BASE+0x1b4U)&8U))
            mmio_write32(POSTPROCESS_DIAG_BASE+0x1b0U,2U);
    }
}
