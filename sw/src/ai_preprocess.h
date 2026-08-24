#ifndef AI_PREPROCESS_H
#define AI_PREPROCESS_H

#include <stdint.h>

typedef struct {
    uint32_t arena;
    uint32_t tensor_base;
    uint32_t valid_mask;
    uint32_t fresh_mask;
    uint64_t batch_id;
    uint32_t cycles;
    uint32_t read_beats;
    uint32_t write_beats;
} AiPreprocessResult;

int ai_preprocess_run(AiPreprocessResult *result);
int ai_preprocess_recycle(uint32_t arena_mask);

#endif
