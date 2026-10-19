#ifndef DMA_LOAD_SUITE_H
#define DMA_LOAD_SUITE_H

/* Exact total per mode/executor, not per lane. A twelve-frame parallel batch
 * has equal quotas 4/4/4; warmups contain three complete frames. */
enum { DMA_MEASURE_FRAMES=12, DMA_WARMUP_FRAMES=3,
       DMA_FIRST_COUNTER=8, DMA_LAST_COUNTER=34, DMA_MAX_MODES=4 };
#ifndef DMA_REQUIRE_SPAD_ONLY
#define DMA_REQUIRE_SPAD_ONLY 0
#endif
static const char *const dma_modes[DMA_MAX_MODES]={
    "legacy", "read_coalesced", "read_assembled", "spad_assembled"};

#endif
