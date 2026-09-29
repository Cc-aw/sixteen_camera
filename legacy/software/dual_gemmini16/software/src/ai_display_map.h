#ifndef AI_DISPLAY_MAP_H
#define AI_DISPLAY_MAP_H

#include <stdint.h>

#include "ai_detection.h"

#define AI_OVERLAY_MAX_BOXES_PER_STREAM 8U

typedef struct {
    uint16_t x_min;
    uint16_t y_min;
    uint16_t x_max;
    uint16_t y_max;
    uint16_t score_q15;
    uint8_t class_id;
    uint8_t reserved;
} AiOverlayBox;

typedef struct {
    uint64_t frame_id;
    uint32_t stream_id;
    uint32_t count;
    AiOverlayBox boxes[AI_OVERLAY_MAX_BOXES_PER_STREAM];
} AiOverlayResult;

int ai_display_map_mosaic(const AiDetectionResult *result,
                          AiOverlayResult *overlay);

#endif
