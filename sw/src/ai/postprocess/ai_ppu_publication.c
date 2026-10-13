#include "ai/postprocess/ai_ppu_publication.h"

/* Transitional build entry: keep the existing two PPU translation units and
 * their per-object ordered-MMIO flags for video, benchmark and host builds.
 * The device implementation is compiled exactly once through this adapter. */
#include "../../drivers/ppu/ai_ppu_device_publication.c"

uint32_t ai_ppu_publication_generation(uintptr_t base)
{
    return ai_ppu_device_publication_generation(base);
}
int ai_ppu_publication_available(void) { return ai_ppu_device_publication_available(); }
int ai_ppu_publication_select(uintptr_t base) { return ai_ppu_device_publication_select(base); }
int ai_ppu_publication_begin(uintptr_t base) { return ai_ppu_device_publication_begin(base); }
void ai_ppu_publication_publish(uintptr_t base, uint32_t mask)
{
    ai_ppu_device_publication_publish(base, mask);
}
void ai_ppu_publication_abort(uintptr_t base) { ai_ppu_device_publication_abort(base); }
