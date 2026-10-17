#ifndef ATSOFT_MMIO_H
#define ATSOFT_MMIO_H
#include <stdint.h>
static inline void mmio_write32(uintptr_t a,uint32_t v) { *(volatile uint32_t *)a=v; }
static inline uint32_t mmio_read32(uintptr_t a) { return *(volatile uint32_t *)a; }
void at_io_commit(void);
/* Native single-outstanding uncached MMIO ordering. Completion/coherence is
 * proved separately by frontend HOST/DONE and hardware Head publication. */
static inline void mmio_fence(void) { at_io_commit(); }
#endif
