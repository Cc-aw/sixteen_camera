#ifndef AI_MODEL_BACKEND_H
#define AI_MODEL_BACKEND_H

#include <stdint.h>

#include "ai_model_abi.h"

#define AI_MODEL_WORKER_COUNT 2U
#define AI_MODEL_RESULT_QUEUE_CAPACITY (AI_MODEL_WORKER_COUNT * 2U)
#define AI_MODEL_POSTPROCESS_CAPACITY (AI_MODEL_WORKER_COUNT * 4U)

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
 * Single-phase compatibility boundary used by the older model backends.
 * YOLOv5nu streaming uses the two-phase compute/result interface below so a
 * Gemmini worker does not remain owned while the PPU consumes its Head Slot.
 */
void ai_model_backend_init(void);
int ai_model_backend_submit(const AiModelFrameRequest *request);
int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion);
int ai_model_backend_abort(uint32_t worker_id);

/* Two-phase streaming interface used by the YOLOv5nu backend. */
int ai_model_backend_poll_compute(uint32_t worker_id,
                                  AiModelComputeCompletion *completion);
int ai_model_backend_poll_result(AiModelFrameCompletion *completion);
uint32_t ai_model_backend_is_idle(void);

/* Diagnostic state for the synchronous model invocation. */
uint32_t ai_model_backend_stage(void);
uint64_t ai_model_backend_elapsed_cycles(void);
void ai_model_backend_get_pe_stats(AiModelPeStats *stats);

#endif
