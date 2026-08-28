#ifndef AI_MODEL_BACKEND_H
#define AI_MODEL_BACKEND_H

#include <stdint.h>

#include "ai_model_abi.h"

#define AI_MODEL_WORKER_COUNT 3U

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

#endif
