#ifndef AI_MODEL_BACKEND_H
#define AI_MODEL_BACKEND_H

#include <stdint.h>

#include "ai_model_abi.h"

#define AI_MODEL_WORKER_COUNT 2U

typedef struct {
    uint32_t valid;
    uint32_t layer_index;
    uint64_t macs;
    uint64_t cycles;
    uint32_t load_active_cycles;
    uint32_t exe_active_cycles;
    uint32_t store_active_cycles;
    uint32_t pe_util_permille;
    uint32_t coherence_checks;
    uint32_t coherence_errors;
    uint32_t coherence_error_flags;
    uint32_t coherence_busy_skips;
} AiModelPeStats;

/*
 * Stable boundary implemented by the future Gemmini executor. A worker owns
 * its output arena until poll() reports completion. poll() returns zero while
 * running, one on completion, or a negative backend error.
 */
void ai_model_backend_init(void);
int ai_model_backend_submit(const AiModelFrameRequest *request);
int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion);
int ai_model_backend_abort(uint32_t worker_id);

/* Diagnostic state for the synchronous model invocation. */
uint32_t ai_model_backend_stage(void);
uint64_t ai_model_backend_elapsed_cycles(void);
void ai_model_backend_get_pe_stats(AiModelPeStats *stats);

#endif
