#include "ai_postprocess.h"

#include <limits.h>

const AiPostprocessConfig ai_postprocess_default_config = {
    .confidence_q15 = 8192U,
    .nms_iou_q15 = 14746U,
    .candidate_limit = AI_POSTPROCESS_MAX_CANDIDATES,
    .detection_limit = AI_MAX_DETECTIONS
};

static uint32_t dtype_bytes(AiTensorDType dtype)
{
    switch (dtype) {
    case AI_TENSOR_DTYPE_I8:
        return 1U;
    case AI_TENSOR_DTYPE_I16:
        return 2U;
    case AI_TENSOR_DTYPE_F32:
    case AI_TENSOR_DTYPE_Q16_16:
        return 4U;
    default:
        return 0U;
    }
}

static int32_t saturate_i64(int64_t value)
{
    if (value > INT32_MAX)
        return INT32_MAX;
    if (value < INT32_MIN)
        return INT32_MIN;
    return (int32_t)value;
}

/* Convert an IEEE-754 binary32 bit pattern to signed Q16.16 without FP. */
static int float_bits_to_q16(uint32_t bits, int32_t *value)
{
    uint32_t exponent = (bits >> 23) & UINT32_C(0xff);
    uint32_t fraction = bits & UINT32_C(0x7fffff);
    int negative = (bits >> 31) != 0U;
    uint64_t mantissa;
    int shift;
    int64_t magnitude;

    if (exponent == UINT32_C(0xff))
        return -1;
    if (exponent == 0U) {
        *value = 0;
        return 0;
    }

    mantissa = UINT64_C(0x800000) | fraction;
    shift = (int)exponent - 134;
    if (shift >= 0) {
        if (shift > 38 || mantissa > ((uint64_t)INT32_MAX >> shift))
            magnitude = INT32_MAX;
        else
            magnitude = (int64_t)(mantissa << shift);
    } else if (shift <= -24) {
        magnitude = 0;
    } else {
        uint32_t right = (uint32_t)(-shift);
        magnitude = (int64_t)((mantissa + (UINT64_C(1) << (right - 1U))) >> right);
    }
    *value = negative ? saturate_i64(-magnitude) : saturate_i64(magnitude);
    return 0;
}

static uint32_t tensor_index(const AiTensorDesc *desc,
                             uint32_t channel,
                             uint32_t anchor)
{
    if (desc->layout == AI_TENSOR_LAYOUT_CHANNEL_ANCHOR)
        return channel * desc->anchors + anchor;
    return anchor * desc->channels + channel;
}

static int read_q16(const void *tensor,
                    const AiTensorDesc *desc,
                    uint32_t channel,
                    uint32_t anchor,
                    int32_t *value)
{
    uint32_t index = tensor_index(desc, channel, anchor);
    int32_t zero_point = channel < 4U ? desc->coordinate_zero_point :
                                        desc->score_zero_point;
    int32_t scale_q16 = channel < 4U ? desc->coordinate_scale_q16 :
                                       desc->score_scale_q16;

    switch (desc->dtype) {
    case AI_TENSOR_DTYPE_F32: {
        const uint32_t *words = (const uint32_t *)tensor;
        return float_bits_to_q16(words[index], value);
    }
    case AI_TENSOR_DTYPE_I8: {
        const int8_t *values = (const int8_t *)tensor;
        *value = saturate_i64((int64_t)(values[index] - zero_point) *
                             scale_q16);
        return 0;
    }
    case AI_TENSOR_DTYPE_I16: {
        const int16_t *values = (const int16_t *)tensor;
        *value = saturate_i64((int64_t)(values[index] - zero_point) *
                             scale_q16);
        return 0;
    }
    case AI_TENSOR_DTYPE_Q16_16:
        *value = ((const int32_t *)tensor)[index];
        return 0;
    default:
        return -1;
    }
}

static int candidate_lower(const AiPostprocessCandidate *left,
                           const AiPostprocessCandidate *right)
{
    if (left->score_q15 != right->score_q15)
        return left->score_q15 < right->score_q15;
    if (left->class_id != right->class_id)
        return left->class_id > right->class_id;
    if (left->y_min != right->y_min)
        return left->y_min > right->y_min;
    return left->x_min > right->x_min;
}

static void swap_candidate(AiPostprocessCandidate *left,
                           AiPostprocessCandidate *right)
{
    AiPostprocessCandidate temporary = *left;
    *left = *right;
    *right = temporary;
}

static void heap_sift_up(AiPostprocessWorkspace *workspace, uint32_t index)
{
    while (index != 0U) {
        uint32_t parent = (index - 1U) / 2U;
        if (!candidate_lower(&workspace->candidates[index],
                             &workspace->candidates[parent]))
            break;
        swap_candidate(&workspace->candidates[index],
                       &workspace->candidates[parent]);
        index = parent;
    }
}

static void heap_sift_down(AiPostprocessWorkspace *workspace,
                           uint32_t index,
                           uint32_t count)
{
    for (;;) {
        uint32_t left = index * 2U + 1U;
        uint32_t right = left + 1U;
        uint32_t smallest = index;
        if (left < count &&
            candidate_lower(&workspace->candidates[left],
                            &workspace->candidates[smallest]))
            smallest = left;
        if (right < count &&
            candidate_lower(&workspace->candidates[right],
                            &workspace->candidates[smallest]))
            smallest = right;
        if (smallest == index)
            break;
        swap_candidate(&workspace->candidates[index],
                       &workspace->candidates[smallest]);
        index = smallest;
    }
}

static void retain_candidate(AiPostprocessWorkspace *workspace,
                             uint32_t limit,
                             const AiPostprocessCandidate *candidate)
{
    if (workspace->candidate_count < limit) {
        uint32_t index = workspace->candidate_count++;
        workspace->candidates[index] = *candidate;
        heap_sift_up(workspace, index);
    } else if (candidate_lower(&workspace->candidates[0], candidate)) {
        workspace->candidates[0] = *candidate;
        heap_sift_down(workspace, 0U, limit);
    }
}

static void sort_candidates_descending(AiPostprocessWorkspace *workspace)
{
    uint32_t count = workspace->candidate_count;
    while (count > 1U) {
        swap_candidate(&workspace->candidates[0],
                       &workspace->candidates[count - 1U]);
        count--;
        heap_sift_down(workspace, 0U, count);
    }
}

static int overlaps_above_threshold(const AiPostprocessCandidate *candidate,
                                    const AiDetection *selected,
                                    uint16_t threshold_q15)
{
    int32_t left = candidate->x_min > selected->x_min ?
                   candidate->x_min : selected->x_min;
    int32_t top = candidate->y_min > selected->y_min ?
                  candidate->y_min : selected->y_min;
    int32_t right = candidate->x_max < selected->x_max ?
                    candidate->x_max : selected->x_max;
    int32_t bottom = candidate->y_max < selected->y_max ?
                     candidate->y_max : selected->y_max;
    uint64_t intersection;
    uint64_t candidate_area;
    uint64_t selected_area;
    uint64_t union_area;

    if (right <= left || bottom <= top)
        return 0;
    intersection = (uint64_t)(right - left) * (uint32_t)(bottom - top);
    candidate_area = (uint64_t)(candidate->x_max - candidate->x_min) *
                     (uint32_t)(candidate->y_max - candidate->y_min);
    selected_area = (uint64_t)(selected->x_max - selected->x_min) *
                    (uint32_t)(selected->y_max - selected->y_min);
    union_area = candidate_area + selected_area - intersection;
    return intersection * UINT32_C(32768) >=
           union_area * threshold_q15;
}

static int validate_arguments(const void *tensor,
                              const AiTensorDesc *desc,
                              const AiPostprocessConfig *config,
                              uint32_t stream_id,
                              const AiPostprocessWorkspace *workspace,
                              const AiDetectionResult *result)
{
    uint32_t element_bytes;
    uint64_t required_bytes;
    if (tensor == 0 || desc == 0 || config == 0 || workspace == 0 ||
        result == 0 || stream_id >= VIDEO_CHANNEL_COUNT)
        return -1;
    element_bytes = dtype_bytes(desc->dtype);
    required_bytes = (uint64_t)desc->channels * desc->anchors * element_bytes;
    if (element_bytes == 0U || desc->channels != AI_YOLOV5NU_CHANNELS ||
        desc->anchors != AI_YOLOV5NU_ANCHORS || desc->bytes < required_bytes ||
        desc->layout > AI_TENSOR_LAYOUT_ANCHOR_CHANNEL)
        return -2;
    if (config->candidate_limit == 0U ||
        config->candidate_limit > AI_POSTPROCESS_MAX_CANDIDATES ||
        config->detection_limit == 0U ||
        config->detection_limit > AI_MAX_DETECTIONS ||
        config->confidence_q15 > UINT16_C(32767) ||
        config->nms_iou_q15 > UINT16_C(32767))
        return -3;
    if ((desc->dtype == AI_TENSOR_DTYPE_I8 ||
         desc->dtype == AI_TENSOR_DTYPE_I16) &&
        (desc->coordinate_scale_q16 <= 0 || desc->score_scale_q16 <= 0))
        return -4;
    return 0;
}

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
                            AiDetectionResult *result)
{
    int status = validate_arguments(tensor, desc, config, stream_id,
                                    workspace, result);
    if (status != 0)
        return status;

    workspace->candidate_count = 0U;
    result->job_id = job_id;
    result->worker_id = worker_id;
    result->stream_id = stream_id;
    result->frame_id = frame_id;
    result->timestamp = timestamp;
    result->version = version;
    result->count = 0U;

    for (uint32_t anchor = 0U; anchor < desc->anchors; ++anchor) {
        int32_t best_score = INT32_MIN;
        uint32_t best_class = 0U;
        int invalid = 0;
        for (uint32_t class_id = 0U;
             class_id < AI_YOLOV5NU_CLASSES; ++class_id) {
            int32_t score;
            if (read_q16(tensor, desc, class_id + 4U, anchor, &score) != 0) {
                invalid = 1;
                break;
            }
            if (score > best_score) {
                best_score = score;
                best_class = class_id;
            }
        }
        if (invalid || best_score < ((int32_t)config->confidence_q15 << 1))
            continue;

        int32_t x_center;
        int32_t y_center;
        int32_t width;
        int32_t height;
        if (read_q16(tensor, desc, 0U, anchor, &x_center) != 0 ||
            read_q16(tensor, desc, 1U, anchor, &y_center) != 0 ||
            read_q16(tensor, desc, 2U, anchor, &width) != 0 ||
            read_q16(tensor, desc, 3U, anchor, &height) != 0 ||
            width <= 0 || height <= 0)
            continue;

        int64_t x_min_q16 = (int64_t)x_center - width / 2;
        int64_t y_min_q16 = (int64_t)y_center - height / 2;
        int64_t x_max_q16 = (int64_t)x_center + width / 2;
        int64_t y_max_q16 = (int64_t)y_center + height / 2;
        const int64_t max_x_q16 = (int64_t)AI_YOLOV5NU_INPUT_WIDTH << 16;
        const int64_t max_y_q16 = (int64_t)AI_YOLOV5NU_INPUT_HEIGHT << 16;
        if (x_min_q16 < 0)
            x_min_q16 = 0;
        if (y_min_q16 < 0)
            y_min_q16 = 0;
        if (x_max_q16 > max_x_q16)
            x_max_q16 = max_x_q16;
        if (y_max_q16 > max_y_q16)
            y_max_q16 = max_y_q16;

        AiPostprocessCandidate candidate = {
            .x_min = (int16_t)(x_min_q16 >> 16),
            .y_min = (int16_t)(y_min_q16 >> 16),
            .x_max = (int16_t)((x_max_q16 + UINT16_MAX) >> 16),
            .y_max = (int16_t)((y_max_q16 + UINT16_MAX) >> 16),
            .score_q15 = (uint16_t)(best_score >= 65534 ?
                                    32767 : (best_score > 0 ?
                                    (uint32_t)best_score >> 1 : 0U)),
            .class_id = (uint8_t)best_class,
            .reserved = 0U
        };
        if (candidate.x_max <= candidate.x_min ||
            candidate.y_max <= candidate.y_min)
            continue;
        retain_candidate(workspace, config->candidate_limit, &candidate);
    }

    sort_candidates_descending(workspace);
    for (uint32_t index = 0U;
         index < workspace->candidate_count &&
         result->count < config->detection_limit; ++index) {
        const AiPostprocessCandidate *candidate = &workspace->candidates[index];
        int suppressed = 0;
        for (uint32_t selected = 0U; selected < result->count; ++selected) {
            if (candidate->class_id == result->detections[selected].class_id &&
                overlaps_above_threshold(candidate,
                    &result->detections[selected], config->nms_iou_q15)) {
                suppressed = 1;
                break;
            }
        }
        if (!suppressed) {
            AiDetection *detection = &result->detections[result->count++];
            detection->x_min = candidate->x_min;
            detection->y_min = candidate->y_min;
            detection->x_max = candidate->x_max;
            detection->y_max = candidate->y_max;
            detection->score_q15 = candidate->score_q15;
            detection->class_id = candidate->class_id;
            detection->reserved = 0U;
        }
    }
    return 0;
}
