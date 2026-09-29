#ifndef AI_PPU_PUBLICATION_H
#define AI_PPU_PUBLICATION_H
#include <stdint.h>
uint32_t ai_ppu_publication_generation(uintptr_t base);
int ai_ppu_publication_available(void);
int ai_ppu_publication_begin(uintptr_t base);
int ai_ppu_publication_select(uintptr_t base);
void ai_ppu_publication_publish(uintptr_t base, uint32_t mask);
void ai_ppu_publication_abort(uintptr_t base);
#endif
