#ifndef DMA_BOARD_PPU_RUN_SEQUENCE_H
#define DMA_BOARD_PPU_RUN_SEQUENCE_H

#include <stdint.h>

/* One sequence for the complete session: modes, warmups and diagnostic passes
 * share it. Check both version and frame overflow before advancing state. */
static inline int ppu_run_next(uint32_t *last, uint64_t frame_base,
                               uint32_t *run)
{
    if (!last || !run || *last == UINT32_MAX)
        return -1;
    uint32_t next = *last + 1U;
    if (frame_base > UINT64_MAX - next)
        return -1;
    *last = next;
    *run = next;
    return 0;
}

#endif
