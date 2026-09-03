#ifndef GEMCC_TRACE_H
#define GEMCC_TRACE_H

#include <stdint.h>

/* Trace kinds used by generated model ABI wrappers. */
enum {
    GEMCC_TRACE_KIND_CONV = 1U,
    GEMCC_TRACE_KIND_MATMUL = 2U
};

/* Trace phases are ordered to identify the synchronous stall boundary. */
enum {
    GEMCC_TRACE_PHASE_LAUNCH = 1U,
    GEMCC_TRACE_PHASE_GEMMINI_DONE = 2U,
    GEMCC_TRACE_PHASE_DONE = 3U
};

void gemcc_trace_reset(void);
uint32_t gemcc_trace_begin(uint32_t kind, uint32_t x0, uint32_t x1,
                           uint32_t x2, uint32_t x3, uint32_t x4,
                           uint32_t x5);
void gemcc_trace_phase(uint32_t op, uint32_t phase);

#endif
