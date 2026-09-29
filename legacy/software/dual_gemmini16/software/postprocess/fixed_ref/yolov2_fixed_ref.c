#include "yolov2_fixed_ref.h"

#include <limits.h>
#include <stddef.h>

#define Q15_ONE UINT32_C(32768)
#define Q24_ONE UINT32_C(16777216)
#define Q16_ONE UINT32_C(65536)

/* round(exp(-tensor_scale) * 2^24) */
#define EXP_NEG_STEP_Q24 UINT32_C(12761483)
/* round(exp(+tensor_scale) * 2^16) */
#define EXP_POS_STEP_Q16 UINT32_C(86159)
/* round(exp(-tensor_scale) * 2^16) */
#define EXP_NEG_STEP_Q16 UINT32_C(49850)

static const uint32_t anchor_width_q16[YOLOV2_FIXED_ANCHOR_COUNT] = {
    UINT32_C(70779), UINT32_C(224133), UINT32_C(434504),
    UINT32_C(617349), UINT32_C(1089208)
};

static const uint32_t anchor_height_q16[YOLOV2_FIXED_ANCHOR_COUNT] = {
    UINT32_C(77988), UINT32_C(289014), UINT32_C(745800),
    UINT32_C(334889), UINT32_C(689439)
};

const YoloV2FixedConfig yolov2_fixed_default_config = {
    .score_threshold_q15 = YOLOV2_FIXED_SCORE_THRESHOLD_Q15,
    .nms_threshold_q15 = YOLOV2_FIXED_NMS_THRESHOLD_Q15,
    .candidate_limit = YOLOV2_FIXED_MAX_CANDIDATES,
    .result_limit = YOLOV2_FIXED_MAX_RESULTS
};

static uint32_t rounded_shift_u64(uint64_t value, uint32_t shift)
{
    return (uint32_t)((value + (UINT64_C(1) << (shift - 1U))) >> shift);
}

uint32_t yolov2_fixed_exp_neg_q24(uint8_t difference)
{
    uint32_t value = Q24_ONE;
    for (uint32_t index = 0U; index < difference; ++index) {
        uint32_t next = rounded_shift_u64((uint64_t)value *
                                          EXP_NEG_STEP_Q24, 24U);
        if (next >= value)
            return 0U;
        value = next;
    }
    return value;
}

uint32_t yolov2_fixed_exp_q16(int8_t input)
{
    uint32_t magnitude = input < 0 ? (uint32_t)(-(int32_t)input) :
                                     (uint32_t)input;
    uint32_t value = Q16_ONE;
    uint32_t step = input < 0 ? EXP_NEG_STEP_Q16 : EXP_POS_STEP_Q16;
    for (uint32_t index = 0U; index < magnitude; ++index) {
        uint64_t product = (uint64_t)value * step;
        uint64_t rounded = (product + (Q16_ONE / 2U)) >> 16;
        if (rounded > UINT32_MAX)
            return UINT32_MAX;
        if (input < 0 && rounded >= value)
            return 0U;
        value = (uint32_t)rounded;
    }
    return value;
}

uint16_t yolov2_fixed_sigmoid_q15(int8_t input)
{
    uint32_t magnitude = input < 0 ? (uint32_t)(-(int32_t)input) :
                                     (uint32_t)input;
    uint32_t exp_negative = yolov2_fixed_exp_neg_q24((uint8_t)magnitude);
    uint64_t numerator = (uint64_t)Q15_ONE * Q24_ONE;
    uint32_t denominator = Q24_ONE + exp_negative;
    uint32_t positive = (uint32_t)((numerator + denominator / 2U) /
                                   denominator);
    uint32_t value = input < 0 ? Q15_ONE - positive : positive;
    return (uint16_t)(value >= Q15_ONE ? Q15_ONE - 1U : value);
}

void yolov2_fixed_pack_candidate(const YoloV2FixedCandidate *candidate,
                                 YoloV2FixedCandidateWire *wire)
{
    if (candidate == NULL || wire == NULL)
        return;
    wire->word[0] = (uint32_t)candidate->x_min |
                    ((uint32_t)candidate->y_min << 16);
    wire->word[1] = (uint32_t)candidate->x_max |
                    ((uint32_t)candidate->y_max << 16);
    wire->word[2] = (uint32_t)candidate->score_q15 |
                    ((uint32_t)candidate->class_id << 16) |
                    ((uint32_t)candidate->flags << 24);
    wire->word[3] = candidate->original_index;
}

static uint16_t softmax_best_q15(const int8_t *class_logits,
                                 int8_t best_logit)
{
    uint64_t sum = 0U;
    for (uint32_t class_id = 0U; class_id < YOLOV2_FIXED_CLASS_COUNT;
         ++class_id) {
        uint8_t difference = (uint8_t)((int32_t)best_logit -
                                       class_logits[class_id]);
        sum += yolov2_fixed_exp_neg_q24(difference);
    }
    if (sum == 0U)
        return 0U;
    uint64_t numerator = (uint64_t)Q15_ONE * Q24_ONE;
    uint32_t value = (uint32_t)((numerator + sum / 2U) / sum);
    return (uint16_t)(value >= Q15_ONE ? Q15_ONE - 1U : value);
}

static uint16_t probability_product_q15(uint16_t left, uint16_t right)
{
    uint32_t product = (uint32_t)left * right;
    uint32_t value = (product + Q15_ONE / 2U) >> 15;
    return (uint16_t)(value >= Q15_ONE ? Q15_ONE - 1U : value);
}

static uint16_t clip_floor_q16(int64_t coordinate, uint32_t limit)
{
    if (coordinate <= 0)
        return 0U;
    if (coordinate >= ((int64_t)limit << 16))
        return (uint16_t)limit;
    return (uint16_t)((uint64_t)coordinate >> 16);
}

static uint16_t clip_ceil_q16(int64_t coordinate, uint32_t limit)
{
    if (coordinate <= 0)
        return 0U;
    if (coordinate >= ((int64_t)limit << 16))
        return (uint16_t)limit;
    return (uint16_t)(((uint64_t)coordinate + UINT16_MAX) >> 16);
}

static YoloV2FixedCandidate decode_box(const int8_t *attributes,
                                       uint32_t row,
                                       uint32_t column,
                                       uint32_t anchor,
                                       uint16_t score_q15,
                                       uint8_t class_id,
                                       uint16_t original_index)
{
    uint32_t sigmoid_x = yolov2_fixed_sigmoid_q15(attributes[0]);
    uint32_t sigmoid_y = yolov2_fixed_sigmoid_q15(attributes[1]);
    uint32_t exp_width = yolov2_fixed_exp_q16(attributes[2]);
    uint32_t exp_height = yolov2_fixed_exp_q16(attributes[3]);
    int64_t center_x_q16 = ((int64_t)column * Q15_ONE + sigmoid_x) * 64;
    int64_t center_y_q16 = ((int64_t)row * Q15_ONE + sigmoid_y) * 64;
    uint64_t width_grid_q16 =
        ((uint64_t)anchor_width_q16[anchor] * exp_width + Q16_ONE / 2U) >> 16;
    uint64_t height_grid_q16 =
        ((uint64_t)anchor_height_q16[anchor] * exp_height + Q16_ONE / 2U) >> 16;
    int64_t width_q16 = width_grid_q16 > (uint64_t)INT64_MAX / 32U ?
                        INT64_MAX : (int64_t)(width_grid_q16 * 32U);
    int64_t height_q16 = height_grid_q16 > (uint64_t)INT64_MAX / 32U ?
                         INT64_MAX : (int64_t)(height_grid_q16 * 32U);
    int64_t x_min_q16 = center_x_q16 - width_q16 / 2;
    int64_t y_min_q16 = center_y_q16 - height_q16 / 2;
    int64_t x_max_q16 = center_x_q16 + width_q16 / 2;
    int64_t y_max_q16 = center_y_q16 + height_q16 / 2;
    YoloV2FixedCandidate candidate = {
        .x_min = clip_floor_q16(x_min_q16, YOLOV2_FIXED_INPUT_WIDTH),
        .y_min = clip_floor_q16(y_min_q16, YOLOV2_FIXED_INPUT_HEIGHT),
        .x_max = clip_ceil_q16(x_max_q16, YOLOV2_FIXED_INPUT_WIDTH),
        .y_max = clip_ceil_q16(y_max_q16, YOLOV2_FIXED_INPUT_HEIGHT),
        .score_q15 = score_q15,
        .class_id = class_id,
        .flags = 0U,
        .original_index = original_index
    };
    return candidate;
}

static int candidate_better(const YoloV2FixedCandidate *left,
                            const YoloV2FixedCandidate *right)
{
    if (left->score_q15 != right->score_q15)
        return left->score_q15 > right->score_q15;
    if (left->class_id != right->class_id)
        return left->class_id < right->class_id;
    return left->original_index < right->original_index;
}

static void retain_top_candidate(YoloV2FixedWorkspace *workspace,
                                 uint32_t limit,
                                 const YoloV2FixedCandidate *candidate)
{
    if (workspace->candidate_count < limit) {
        workspace->candidates[workspace->candidate_count++] = *candidate;
        return;
    }

    uint32_t worst = 0U;
    for (uint32_t index = 1U; index < workspace->candidate_count; ++index) {
        if (candidate_better(&workspace->candidates[worst],
                             &workspace->candidates[index]))
            worst = index;
    }
    if (candidate_better(candidate, &workspace->candidates[worst]))
        workspace->candidates[worst] = *candidate;
}

static void sort_candidates(YoloV2FixedWorkspace *workspace)
{
    for (uint32_t index = 1U; index < workspace->candidate_count; ++index) {
        YoloV2FixedCandidate candidate = workspace->candidates[index];
        uint32_t position = index;
        while (position > 0U &&
               candidate_better(&candidate,
                                &workspace->candidates[position - 1U])) {
            workspace->candidates[position] =
                workspace->candidates[position - 1U];
            --position;
        }
        workspace->candidates[position] = candidate;
    }
}

static int nms_overlap(const YoloV2FixedCandidate *candidate,
                       const YoloV2FixedCandidate *selected,
                       uint16_t threshold_q15)
{
    uint32_t left = candidate->x_min > selected->x_min ?
                    candidate->x_min : selected->x_min;
    uint32_t top = candidate->y_min > selected->y_min ?
                   candidate->y_min : selected->y_min;
    uint32_t right = candidate->x_max < selected->x_max ?
                     candidate->x_max : selected->x_max;
    uint32_t bottom = candidate->y_max < selected->y_max ?
                      candidate->y_max : selected->y_max;
    if (right <= left || bottom <= top)
        return 0;
    uint64_t intersection = (uint64_t)(right - left) * (bottom - top);
    uint64_t candidate_area =
        (uint64_t)(candidate->x_max - candidate->x_min) *
        (candidate->y_max - candidate->y_min);
    uint64_t selected_area =
        (uint64_t)(selected->x_max - selected->x_min) *
        (selected->y_max - selected->y_min);
    uint64_t union_area = candidate_area + selected_area - intersection;
    return union_area != 0U &&
           intersection * Q15_ONE >= union_area * threshold_q15;
}

static int validate_config(const YoloV2FixedConfig *config,
                           const YoloV2FixedWorkspace *workspace,
                           const YoloV2FixedResult *result)
{
    if (config == NULL || workspace == NULL || result == NULL)
        return -1;
    if (config->score_threshold_q15 > UINT16_C(32767) ||
        config->nms_threshold_q15 > UINT16_C(32767) ||
        config->candidate_limit == 0U ||
        config->candidate_limit > YOLOV2_FIXED_MAX_CANDIDATES ||
        config->result_limit == 0U ||
        config->result_limit > YOLOV2_FIXED_MAX_RESULTS)
        return -2;
    return 0;
}

int yolov2_fixed_select(const YoloV2FixedCandidate *candidates,
                        uint32_t candidate_count,
                        const YoloV2FixedConfig *config,
                        YoloV2FixedWorkspace *workspace,
                        YoloV2FixedResult *result)
{
    int status = validate_config(config, workspace, result);
    if (status != 0 || (candidates == NULL && candidate_count != 0U))
        return status != 0 ? status : -1;

    workspace->candidate_count = 0U;
    result->count = 0U;
    for (uint32_t index = 0U; index < candidate_count; ++index) {
        const YoloV2FixedCandidate *candidate = &candidates[index];
        if (candidate->score_q15 < config->score_threshold_q15 ||
            candidate->x_min >= candidate->x_max ||
            candidate->y_min >= candidate->y_max)
            continue;
        retain_top_candidate(workspace, config->candidate_limit, candidate);
    }
    sort_candidates(workspace);

    for (uint32_t index = 0U;
         index < workspace->candidate_count &&
         result->count < config->result_limit; ++index) {
        const YoloV2FixedCandidate *candidate = &workspace->candidates[index];
        int suppressed = 0;
        for (uint32_t selected = 0U; selected < result->count; ++selected) {
            if (candidate->class_id == result->detections[selected].class_id &&
                nms_overlap(candidate, &result->detections[selected],
                            config->nms_threshold_q15)) {
                suppressed = 1;
                break;
            }
        }
        if (!suppressed)
            result->detections[result->count++] = *candidate;
    }
    return 0;
}

int yolov2_fixed_decode(const int8_t *tensor,
                        uint32_t tensor_bytes,
                        const YoloV2FixedConfig *config,
                        YoloV2FixedAnchorTrace *anchor_trace,
                        YoloV2FixedWorkspace *workspace,
                        YoloV2FixedResult *result)
{
    int status = validate_config(config, workspace, result);
    if (status != 0 || tensor == NULL ||
        tensor_bytes != YOLOV2_FIXED_TENSOR_BYTES)
        return status != 0 ? status : -3;

    workspace->candidate_count = 0U;
    result->count = 0U;
    for (uint32_t original_index = 0U;
         original_index < YOLOV2_FIXED_ANCHORS; ++original_index) {
        uint32_t cell = original_index / YOLOV2_FIXED_ANCHOR_COUNT;
        uint32_t anchor = original_index % YOLOV2_FIXED_ANCHOR_COUNT;
        uint32_t row = cell / YOLOV2_FIXED_GRID_SIZE;
        uint32_t column = cell % YOLOV2_FIXED_GRID_SIZE;
        const int8_t *attributes =
            tensor + original_index * YOLOV2_FIXED_ATTRS_PER_ANCHOR;
        uint8_t best_class = 0U;
        int8_t best_logit = attributes[5];
        for (uint32_t class_id = 1U; class_id < YOLOV2_FIXED_CLASS_COUNT;
             ++class_id) {
            if (attributes[5U + class_id] > best_logit) {
                best_logit = attributes[5U + class_id];
                best_class = (uint8_t)class_id;
            }
        }
        uint16_t objectness_q15 = yolov2_fixed_sigmoid_q15(attributes[4]);
        uint16_t class_probability_q15 =
            softmax_best_q15(attributes + 5, best_logit);
        uint16_t score_q15 = probability_product_q15(objectness_q15,
                                                     class_probability_q15);
        YoloV2FixedCandidate candidate =
            decode_box(attributes, row, column, anchor, score_q15,
                       best_class, (uint16_t)original_index);
        uint8_t passes = score_q15 >= config->score_threshold_q15 &&
                         candidate.x_min < candidate.x_max &&
                         candidate.y_min < candidate.y_max;

        if (anchor_trace != NULL) {
            YoloV2FixedAnchorTrace *trace = &anchor_trace[original_index];
            trace->tx = attributes[0];
            trace->ty = attributes[1];
            trace->tw = attributes[2];
            trace->th = attributes[3];
            trace->objectness = attributes[4];
            trace->best_class_logit = best_logit;
            trace->best_class = best_class;
            trace->objectness_q15 = objectness_q15;
            trace->class_probability_q15 = class_probability_q15;
            trace->candidate = candidate;
            trace->passes_threshold = passes;
        }
        if (passes)
            retain_top_candidate(workspace, config->candidate_limit,
                                 &candidate);
    }

    sort_candidates(workspace);
    for (uint32_t index = 0U;
         index < workspace->candidate_count &&
         result->count < config->result_limit; ++index) {
        const YoloV2FixedCandidate *candidate = &workspace->candidates[index];
        int suppressed = 0;
        for (uint32_t selected = 0U; selected < result->count; ++selected) {
            if (candidate->class_id == result->detections[selected].class_id &&
                nms_overlap(candidate, &result->detections[selected],
                            config->nms_threshold_q15)) {
                suppressed = 1;
                break;
            }
        }
        if (!suppressed)
            result->detections[result->count++] = *candidate;
    }
    return 0;
}
