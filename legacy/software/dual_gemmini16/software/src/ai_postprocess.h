#ifndef AI_POSTPROCESS_H
#define AI_POSTPROCESS_H

#include <stdint.h>

#include "ai_detection.h"
#include "ai_model_abi.h"

#define AI_POSTPROCESS_MAX_CANDIDATES 256U

typedef struct {
    uint16_t confidence_q15;
    uint16_t nms_iou_q15;
    uint32_t candidate_limit;
    uint32_t detection_limit;
} AiPostprocessConfig;

typedef struct {
    int16_t x_min;
    int16_t y_min;
    int16_t x_max;
    int16_t y_max;
    uint16_t score_q15;
    uint8_t class_id;
    uint8_t reserved;
} AiPostprocessCandidate;

typedef struct {
    AiPostprocessCandidate candidates[AI_POSTPROCESS_MAX_CANDIDATES];
    uint32_t candidate_count;
} AiPostprocessWorkspace;

extern const AiPostprocessConfig ai_postprocess_default_config;

int ai_postprocess_yolov5nu(const void *tensor,
                            const AiTensorDesc *desc,
                            const AiPostprocessConfig *config,
                            uint64_t job_id,
                            uint32_t worker_id,
                            uint32_t stream_id,
                            uint64_t frame_id,
                            uint64_t timestamp,
                            uint32_t version,
                            AiPostprocessWorkspace *workspace,
                            AiDetectionResult *result);

#endif
