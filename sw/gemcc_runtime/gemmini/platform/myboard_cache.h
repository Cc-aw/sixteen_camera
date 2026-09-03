#ifndef GEMCC_MYBOARD_CACHE_H
#define GEMCC_MYBOARD_CACHE_H

#include <stddef.h>
#include "gemmini_params.h"

#if GEMCC_COHERENCE_BACKEND_MYBOARD
#if !defined(GEMCC_MYBOARD_CACHE_BYTES) || !defined(GEMCC_MYBOARD_CACHE_LINE)
#error "MyBoard backend requires cache capacity and line size"
#endif
#if !defined(GEMCC_DMA_COHERENT)
#error "MyBoard backend requires GEMCC_DMA_COHERENT"
#endif
#if GEMCC_MYBOARD_CACHE_BYTES <= 0 || GEMCC_MYBOARD_CACHE_LINE <= 0
#error "MyBoard backend requires positive cache and line sizes"
#endif
/*
 * The eviction buffer must exceed the cache capacity.  If it is exactly one
 * cache, a second pass can hit every line populated by the first pass and no
 * longer force dirty data out of the D-cache.  Two caches worth of lines give
 * each set more lines than the generated 8-way, 32 KiB cache can retain.
 */
#define GEMCC_MYBOARD_EVICT_BYTES (2u * GEMCC_MYBOARD_CACHE_BYTES)
#endif

void gemcc_myboard_l1_evict(void);

#endif
