#ifndef TINYYOLOV2_WORKER_POOL_H
#define TINYYOLOV2_WORKER_POOL_H

#include <stdint.h>

#include "tinyyolov2_runtime.h"

#ifndef TINYYOLOV2_WORKER_COUNT
#define TINYYOLOV2_WORKER_COUNT 2u
#endif
#define TINYYOLOV2_WORKER_RUNNING 0
#define TINYYOLOV2_WORKER_DONE    1
#define TINYYOLOV2_WORKER_ERROR  -1

/* Initialize both worker contexts. Call once before submitting jobs. */
void tinyyolov2_worker_pool_init(void);

/* Return nonzero when the selected worker can accept a new job. */
int tinyyolov2_worker_is_idle(unsigned worker_id);

/* Submit the first layer of a job to one Gemmini worker. */
int tinyyolov2_worker_start(unsigned worker_id, const int8_t *input,
                            const char *input_name);

/*
 * Advance one worker without blocking. A completed result is copied to
 * result and the worker becomes idle when TINYYOLOV2_WORKER_DONE is returned.
 */
int tinyyolov2_worker_poll(unsigned worker_id,
                           struct tinyyolov2_result *result,
                           int collect_result);

/* Final INT8 tensor retained until this worker accepts another job. */
const int8_t *tinyyolov2_worker_last_output(unsigned worker_id);
uint32_t tinyyolov2_worker_last_output_bytes(unsigned worker_id);

/* Read the hardware busy bit published by one Gemmini instance. */
uint64_t tinyyolov2_worker_busy(unsigned worker_id);

extern volatile uint32_t tinyyolov2_worker_last_load[2];
extern volatile uint32_t tinyyolov2_worker_last_exec[2];
extern volatile uint32_t tinyyolov2_worker_last_store[2];

#endif
