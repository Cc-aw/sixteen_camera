#include "myboard_cache.h"

#include <stdint.h>

static unsigned g_l1_evicts;

/* The generated Rocket D-cache has no software flush instruction exposed to
 * this bare-metal target.  Reading a buffer larger than the complete cache
 * forces dirty lines out before Gemmini DMA consumes or produces DDR data. */
void gemcc_myboard_l1_evict(void) {
#if defined(__riscv) && defined(BAREMETAL) && !GEMCC_DMA_COHERENT
  static volatile uint8_t evict[GEMCC_MYBOARD_EVICT_BYTES]
      __attribute__((aligned(64)));
  const size_t line = GEMCC_MYBOARD_CACHE_LINE ? GEMCC_MYBOARD_CACHE_LINE : 64u;
  for (size_t i = 0; i < sizeof(evict); i += line)
    (void)evict[i];
  __asm__ volatile("fence.i" ::: "memory");
  g_l1_evicts++;
#else
  (void)g_l1_evicts;
#endif
}
