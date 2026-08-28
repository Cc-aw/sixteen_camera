#ifndef AI_DETECTION_H
#define AI_DETECTION_H

#include <stdint.h>

#include "platform.h"

#define AI_MAX_DETECTIONS 32U

typedef struct {
    int16_t x_min;
    int16_t y_min;
    int16_t x_max;
    int16_t y_max;
    uint16_t score_q15;
    uint8_t class_id;
    uint8_t reserved;
} AiDetection;

typedef struct {
    uint64_t job_id;
    uint64_t frame_id;
    uint64_t timestamp;
    uint32_t stream_id;
    uint32_t worker_id;
    uint32_t count;
    AiDetection detections[AI_MAX_DETECTIONS];
} AiDetectionResult;

#endif
