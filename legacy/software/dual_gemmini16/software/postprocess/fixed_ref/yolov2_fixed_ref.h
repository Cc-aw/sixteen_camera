#ifndef YOLOV2_FIXED_REF_H
#define YOLOV2_FIXED_REF_H

#include <stdint.h>

#define YOLOV2_FIXED_GRID_SIZE          13U
#define YOLOV2_FIXED_ANCHOR_COUNT       5U
#define YOLOV2_FIXED_CLASS_COUNT        20U
#define YOLOV2_FIXED_ATTRS_PER_ANCHOR   25U
#define YOLOV2_FIXED_ANCHORS            845U
#define YOLOV2_FIXED_TENSOR_BYTES       21125U
#define YOLOV2_FIXED_INPUT_WIDTH        416U
#define YOLOV2_FIXED_INPUT_HEIGHT       416U
#define YOLOV2_FIXED_MAX_CANDIDATES     256U
#define YOLOV2_FIXED_MAX_RESULTS        32U

/*
 * TinyYOLOv2 hardware contract v0.
 *
 * Tensor: signed INT8, zero point 0, NHWC physical order
 *         [row][column][anchor][attribute].
 * Attributes: tx, ty, tw, th, objectness, class0..class19.
 * Tensor scale: 0.2735902981 quantized to unsigned Q8.24.
 * Probabilities and thresholds: unsigned Q0.15, where 32768 is internal
 * unity and externally visible values saturate to 32767.
 * Coordinates: unsigned integer pixels in the 416 x 416 network input.
 */
#define YOLOV2_FIXED_TENSOR_SCALE_Q24   UINT32_C(4590084)
#define YOLOV2_FIXED_SCORE_THRESHOLD_Q15 UINT16_C(9830)
#define YOLOV2_FIXED_NMS_THRESHOLD_Q15   UINT16_C(14746)

typedef struct {
    uint16_t x_min;
    uint16_t y_min;
    uint16_t x_max;
    uint16_t y_max;
    uint16_t score_q15;
    uint8_t class_id;
    uint8_t flags;
    uint16_t original_index;
} YoloV2FixedCandidate;

/* Fixed 16-byte Candidate/Result RAM wire record. */
typedef struct {
    uint32_t word[4];
} YoloV2FixedCandidateWire;

typedef struct {
    int8_t tx;
    int8_t ty;
    int8_t tw;
    int8_t th;
    int8_t objectness;
    int8_t best_class_logit;
    uint8_t best_class;
    uint16_t objectness_q15;
    uint16_t class_probability_q15;
    YoloV2FixedCandidate candidate;
    uint8_t passes_threshold;
} YoloV2FixedAnchorTrace;

typedef struct {
    uint16_t score_threshold_q15;
    uint16_t nms_threshold_q15;
    uint16_t candidate_limit;
    uint16_t result_limit;
} YoloV2FixedConfig;

typedef struct {
    YoloV2FixedCandidate candidates[YOLOV2_FIXED_MAX_CANDIDATES];
    uint16_t candidate_count;
} YoloV2FixedWorkspace;

typedef struct {
    YoloV2FixedCandidate detections[YOLOV2_FIXED_MAX_RESULTS];
    uint16_t count;
} YoloV2FixedResult;

extern const YoloV2FixedConfig yolov2_fixed_default_config;

/* Values returned by these functions are the normative RTL LUT contents. */
uint32_t yolov2_fixed_exp_neg_q24(uint8_t difference);
uint32_t yolov2_fixed_exp_q16(int8_t value);
uint16_t yolov2_fixed_sigmoid_q15(int8_t value);
void yolov2_fixed_pack_candidate(const YoloV2FixedCandidate *candidate,
                                 YoloV2FixedCandidateWire *wire);

int yolov2_fixed_decode(const int8_t *tensor,
                        uint32_t tensor_bytes,
                        const YoloV2FixedConfig *config,
                        YoloV2FixedAnchorTrace *anchor_trace,
                        YoloV2FixedWorkspace *workspace,
                        YoloV2FixedResult *result);

int yolov2_fixed_select(const YoloV2FixedCandidate *candidates,
                        uint32_t candidate_count,
                        const YoloV2FixedConfig *config,
                        YoloV2FixedWorkspace *workspace,
                        YoloV2FixedResult *result);

#endif
