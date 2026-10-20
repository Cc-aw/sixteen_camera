#ifndef DMA_LOAD_SUITE_H
#define DMA_LOAD_SUITE_H

/* Exact total per mode/executor, not per lane. A twelve-frame parallel batch
 * has equal quotas 4/4/4; warmups contain three complete frames. */
enum { DMA_MEASURE_FRAMES=12, DMA_WARMUP_FRAMES=3,
       DMA_FIRST_COUNTER=8, DMA_LAST_COUNTER=34,
       DMA_FIXED_MODE=2, DMA_SUPPORTED_MODES=1 };
#ifndef DMA_REQUIRE_SPAD_ONLY
#define DMA_REQUIRE_SPAD_ONLY 0
#endif
/* The ABI retains mode ID 2; this hardware exposes read_assembled only. */

#endif
