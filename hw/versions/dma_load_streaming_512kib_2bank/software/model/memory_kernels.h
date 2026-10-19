#ifndef YOLO32_MEMORY_KERNELS_H
#define YOLO32_MEMORY_KERNELS_H
#include <stdint.h>
#include "independent.h"
/* Full graph counts for DIM32 / ACC_ROWS=2048 / two 32-channel blocks.
 * Keep the original v21 graph and its loader selectable as the control. */
#define YOLO32_RESIZE_FIRST_ROWS ((YOLO32_RESIZE_ROWS && YOLO32_RESIZE_ROWS < 15) ? YOLO32_RESIZE_ROWS : 15)
#define YOLO32_RESIZE_SECOND_ROWS ((YOLO32_RESIZE_ROWS && YOLO32_RESIZE_ROWS < 12) ? YOLO32_RESIZE_ROWS : 12)
#define YOLO32_MEMORY_WAITS (YOLO32_RESIZE_BATCH ? \
    (24 + 4*((15+YOLO32_RESIZE_FIRST_ROWS-1)/YOLO32_RESIZE_FIRST_ROWS) + \
          2*((30+YOLO32_RESIZE_SECOND_ROWS-1)/YOLO32_RESIZE_SECOND_ROWS)) : 144)
typedef struct {
    uint64_t pool_calls, resize_calls, mvin, mvout, waits, pad_cycles;
} Yolo32MemoryStats;
const Yolo32MemoryStats *yolo32_memory_stats(unsigned worker);
/* Board-only element/guard comparison. Uses native hardware commands on all
 * three workers and no PPU/CPU postprocessing path. */
void yolo32_memory_test(void);
#endif
