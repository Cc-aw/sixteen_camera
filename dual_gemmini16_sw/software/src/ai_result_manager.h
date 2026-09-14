#ifndef AI_RESULT_MANAGER_H
#define AI_RESULT_MANAGER_H

#include <stdint.h>

#include "ai_detection.h"

typedef struct {
    AiDetectionResult latest[VIDEO_CHANNEL_COUNT];
    uint16_t valid_mask;
    uint32_t publish_count;
    uint32_t stale_count;
    uint32_t error_count;
} AiResultManager;

void ai_result_manager_init(AiResultManager *manager);
int ai_result_manager_publish(AiResultManager *manager,
                              const AiDetectionResult *result);
const AiDetectionResult *ai_result_manager_latest(
    const AiResultManager *manager, uint32_t stream_id);

#endif
