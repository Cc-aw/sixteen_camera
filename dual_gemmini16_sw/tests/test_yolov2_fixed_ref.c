#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "yolov2_fixed_ref.h"

static int8_t tensor[YOLOV2_FIXED_TENSOR_BYTES];
static YoloV2FixedAnchorTrace traces[YOLOV2_FIXED_ANCHORS];
static YoloV2FixedWorkspace workspace;

static uint32_t hash_word(uint32_t hash, uint32_t value)
{
    for (uint32_t byte = 0U; byte < 4U; ++byte) {
        hash ^= (value >> (byte * 8U)) & UINT32_C(0xff);
        hash *= UINT32_C(16777619);
    }
    return hash;
}

static YoloV2FixedCandidate candidate(uint16_t score, uint8_t class_id,
                                      uint16_t original_index,
                                      uint16_t x_min, uint16_t y_min,
                                      uint16_t x_max, uint16_t y_max)
{
    YoloV2FixedCandidate value = {
        .x_min = x_min,
        .y_min = y_min,
        .x_max = x_max,
        .y_max = y_max,
        .score_q15 = score,
        .class_id = class_id,
        .flags = 0U,
        .original_index = original_index
    };
    return value;
}

static void test_lut_contract(void)
{
    uint32_t exp_neg_hash = UINT32_C(2166136261);
    uint32_t exp_bbox_hash = UINT32_C(2166136261);
    uint32_t sigmoid_hash = UINT32_C(2166136261);
    assert(yolov2_fixed_exp_neg_q24(0U) == UINT32_C(16777216));
    assert(yolov2_fixed_exp_q16(0) == UINT32_C(65536));
    assert(yolov2_fixed_sigmoid_q15(0) == UINT16_C(16384));
    assert(yolov2_fixed_exp_neg_q24(UINT8_MAX) == 0U);
    assert(yolov2_fixed_exp_q16(INT8_MIN) == 0U);
    assert(yolov2_fixed_exp_q16(INT8_MAX) == UINT32_MAX);
    for (uint32_t index = 0U; index < 256U; ++index) {
        exp_neg_hash = hash_word(exp_neg_hash,
                                 yolov2_fixed_exp_neg_q24((uint8_t)index));
        exp_bbox_hash = hash_word(exp_bbox_hash,
                                  yolov2_fixed_exp_q16((int8_t)index));
        sigmoid_hash = hash_word(sigmoid_hash,
                                 yolov2_fixed_sigmoid_q15((int8_t)index));
    }
    assert(exp_neg_hash == UINT32_C(0x61bc241e));
    assert(exp_bbox_hash == UINT32_C(0x6f6f9df0));
    assert(sigmoid_hash == UINT32_C(0x391d778f));
    for (uint32_t index = 1U; index < 256U; ++index)
        assert(yolov2_fixed_exp_neg_q24((uint8_t)index) <=
               yolov2_fixed_exp_neg_q24((uint8_t)(index - 1U)));
    for (int32_t value = -128; value < 127; ++value)
        assert(yolov2_fixed_exp_q16((int8_t)value) <=
               yolov2_fixed_exp_q16((int8_t)(value + 1)));
    for (int32_t value = -128; value < 127; ++value)
        assert(yolov2_fixed_sigmoid_q15((int8_t)value) <=
               yolov2_fixed_sigmoid_q15((int8_t)(value + 1)));
}

static void test_zero_tensor_and_layout(void)
{
    YoloV2FixedResult result;
    memset(tensor, 0, sizeof(tensor));
    assert(yolov2_fixed_decode(tensor, sizeof(tensor),
                              &yolov2_fixed_default_config, traces,
                              &workspace, &result) == 0);
    assert(result.count == 0U);
    assert(traces[0].best_class == 0U);
    assert(traces[0].objectness_q15 == 16384U);
    assert(traces[0].class_probability_q15 == 1638U);
    assert(traces[0].candidate.original_index == 0U);
    assert(traces[1].candidate.original_index == 1U);
    assert(traces[5].candidate.original_index == 5U);
    assert(traces[5].candidate.x_min > traces[0].candidate.x_min);
}

static void test_decode_extremes_and_class_tie(void)
{
    YoloV2FixedResult result;
    memset(tensor, INT8_MIN, sizeof(tensor));
    int8_t *attributes = tensor;
    attributes[0] = 0;
    attributes[1] = 0;
    attributes[2] = 0;
    attributes[3] = 0;
    attributes[4] = INT8_MAX;
    attributes[5U + 6U] = INT8_MAX;
    attributes[5U + 11U] = INT8_MAX;
    assert(yolov2_fixed_decode(tensor, sizeof(tensor),
                              &yolov2_fixed_default_config, traces,
                              &workspace, &result) == 0);
    assert(traces[0].best_class == 6U);
    assert(traces[0].candidate.class_id == 6U);
    assert(traces[0].passes_threshold == 1U);
    assert(result.count == 1U);
    assert(result.detections[0].x_min == 0U);
    assert(result.detections[0].y_min == 0U);
    assert(result.detections[0].original_index == 0U);
}

static void test_threshold_topk_sort_and_nms(void)
{
    YoloV2FixedCandidate inputs[260];
    YoloV2FixedConfig config = yolov2_fixed_default_config;
    YoloV2FixedResult result;
    config.candidate_limit = 256U;
    config.result_limit = 32U;
    for (uint32_t index = 0U; index < 260U; ++index) {
        inputs[index] = candidate((uint16_t)(10000U + index), 2U,
                                  (uint16_t)index,
                                  (uint16_t)(index * 2U), 0U,
                                  (uint16_t)(index * 2U + 1U), 1U);
    }
    assert(yolov2_fixed_select(inputs, 260U, &config, &workspace, &result) == 0);
    assert(workspace.candidate_count == 256U);
    assert(workspace.candidates[0].original_index == 259U);
    assert(workspace.candidates[255].original_index == 4U);

    inputs[0] = candidate(config.score_threshold_q15 - 1U, 0U, 9U,
                          0U, 0U, 10U, 10U);
    inputs[1] = candidate(config.score_threshold_q15, 0U, 8U,
                          0U, 0U, 10U, 10U);
    inputs[2] = candidate(config.score_threshold_q15, 1U, 7U,
                          0U, 0U, 10U, 10U);
    inputs[3] = candidate(config.score_threshold_q15, 0U, 6U,
                          0U, 0U, 10U, 10U);
    assert(yolov2_fixed_select(inputs, 4U, &config, &workspace, &result) == 0);
    assert(workspace.candidate_count == 3U);
    assert(workspace.candidates[0].class_id == 0U);
    assert(workspace.candidates[0].original_index == 6U);
    assert(workspace.candidates[1].original_index == 8U);
    assert(workspace.candidates[2].class_id == 1U);
    assert(result.count == 2U);
    assert(result.detections[0].original_index == 6U);
    assert(result.detections[1].class_id == 1U);
}

static void test_nms_threshold_inclusive(void)
{
    YoloV2FixedCandidate inputs[2];
    YoloV2FixedConfig config = yolov2_fixed_default_config;
    YoloV2FixedResult result;
    config.nms_threshold_q15 = UINT16_C(16384);
    inputs[0] = candidate(20000U, 3U, 0U, 0U, 0U, 20U, 10U);
    inputs[1] = candidate(19000U, 3U, 1U, 0U, 0U, 10U, 10U);
    assert(yolov2_fixed_select(inputs, 2U, &config, &workspace, &result) == 0);
    assert(result.count == 1U);
    config.nms_threshold_q15 = UINT16_C(16385);
    assert(yolov2_fixed_select(inputs, 2U, &config, &workspace, &result) == 0);
    assert(result.count == 2U);
    inputs[1].class_id = 4U;
    assert(yolov2_fixed_select(inputs, 2U, &config, &workspace, &result) == 0);
    assert(result.count == 2U);
}

static void test_contract_rejection(void)
{
    YoloV2FixedConfig invalid = yolov2_fixed_default_config;
    YoloV2FixedResult result;
    assert(yolov2_fixed_decode(NULL, sizeof(tensor),
                              &yolov2_fixed_default_config, traces,
                              &workspace, &result) == -3);
    assert(yolov2_fixed_decode(tensor, sizeof(tensor) - 1U,
                              &yolov2_fixed_default_config, traces,
                              &workspace, &result) == -3);
    invalid.candidate_limit = YOLOV2_FIXED_MAX_CANDIDATES + 1U;
    assert(yolov2_fixed_decode(tensor, sizeof(tensor), &invalid, traces,
                              &workspace, &result) == -2);
}

static void test_candidate_wire_format(void)
{
    YoloV2FixedCandidate logical = candidate(UINT16_C(0x1234),
                                              UINT8_C(0x56),
                                              UINT16_C(0x789a),
                                              UINT16_C(0x1111),
                                              UINT16_C(0x2222),
                                              UINT16_C(0x3333),
                                              UINT16_C(0x4444));
    YoloV2FixedCandidateWire wire;
    logical.flags = UINT8_C(0xab);
    yolov2_fixed_pack_candidate(&logical, &wire);
    assert(sizeof(wire) == 16U);
    assert(wire.word[0] == UINT32_C(0x22221111));
    assert(wire.word[1] == UINT32_C(0x44443333));
    assert(wire.word[2] == UINT32_C(0xab561234));
    assert(wire.word[3] == UINT32_C(0x0000789a));
}

int main(void)
{
    test_lut_contract();
    test_zero_tensor_and_layout();
    test_decode_extremes_and_class_tie();
    test_threshold_topk_sort_and_nms();
    test_nms_threshold_inclusive();
    test_contract_rejection();
    test_candidate_wire_format();
    puts("TEST_YOLOV2_FIXED_REF=PASS");
    return 0;
}
