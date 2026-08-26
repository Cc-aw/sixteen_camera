#ifndef AI_MODEL_BACKEND_H
#define AI_MODEL_BACKEND_H

#include <stdint.h>

typedef struct {
    uint64_t batch_id;
    uint32_t input_tensor_base;
    uint32_t input_tensor_bytes;
    uint16_t valid_mask;
    uint16_t fresh_mask;
    uint32_t batch_size;
} AiModelRequest;

/*
 * Stable boundary for the future fixed-model Gemmini executor.  submit()
 * accepts one READY Batch; poll() returns 0 while running, 1 on completion,
 * or a negative error code.
 */
void ai_model_backend_init(void);
int ai_model_backend_submit(const AiModelRequest *request);
int ai_model_backend_poll(void);
void ai_model_backend_abort(void);

#endif
