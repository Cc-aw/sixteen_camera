#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "ai_display_map.h"
#include "ai_postprocess.h"
#include "ai_result_manager.h"

#define Q16(value) ((int32_t)((value) * 65536))

static int32_t tensor[AI_YOLOV5NU_CHANNELS * AI_YOLOV5NU_ANCHORS];
static AiPostprocessWorkspace workspace;

static void clear_tensor(void)
{
    for (uint32_t index = 0U;
         index < AI_YOLOV5NU_CHANNELS * AI_YOLOV5NU_ANCHORS; ++index)
        tensor[index] = 0;
}

static void set_value(uint32_t channel, uint32_t anchor, int32_t value)
{
    tensor[channel * AI_YOLOV5NU_ANCHORS + anchor] = value;
}

static void set_detection(uint32_t anchor, uint32_t class_id,
                          int32_t x, int32_t y, int32_t width, int32_t height,
                          int32_t score_q16)
{
    set_value(0U, anchor, Q16(x));
    set_value(1U, anchor, Q16(y));
    set_value(2U, anchor, Q16(width));
    set_value(3U, anchor, Q16(height));
    set_value(class_id + 4U, anchor, score_q16);
}

static AiTensorDesc q16_desc(void)
{
    AiTensorDesc desc = {
        .dtype = AI_TENSOR_DTYPE_Q16_16,
        .layout = AI_TENSOR_LAYOUT_CHANNEL_ANCHOR,
        .channels = AI_YOLOV5NU_CHANNELS,
        .anchors = AI_YOLOV5NU_ANCHORS,
        .bytes = sizeof(tensor),
        .coordinate_scale_q16 = 0,
        .score_scale_q16 = 0,
        .coordinate_zero_point = 0,
        .score_zero_point = 0
    };
    return desc;
}

static void test_nms_and_metadata(void)
{
    AiTensorDesc desc = q16_desc();
    AiDetectionResult result;
    clear_tensor();
    set_detection(0U, 2U, 100, 100, 40, 40, 58982);
    set_detection(1U, 2U, 102, 102, 40, 40, 52429);
    set_detection(2U, 3U, 100, 100, 40, 40, 55706);
    set_detection(3U, 4U, 300, 200, 20, 20, 1000);

    assert(ai_postprocess_yolov5nu(tensor, &desc,
        &ai_postprocess_default_config, 11U, 1U, 5U, 99U, 1234U,
        &workspace, &result) == 0);
    assert(result.job_id == 11U && result.worker_id == 1U);
    assert(result.stream_id == 5U && result.frame_id == 99U);
    assert(result.timestamp == 1234U);
    assert(result.count == 2U);
    assert(result.detections[0].class_id == 2U);
    assert(result.detections[0].x_min == 80);
    assert(result.detections[0].x_max == 120);
    assert(result.detections[1].class_id == 3U);
}

static void test_top_k(void)
{
    AiTensorDesc desc = q16_desc();
    AiPostprocessConfig config = ai_postprocess_default_config;
    AiDetectionResult result;
    config.candidate_limit = 2U;
    clear_tensor();
    set_detection(10U, 1U, 50, 50, 10, 10, 40000);
    set_detection(11U, 1U, 150, 50, 10, 10, 50000);
    set_detection(12U, 1U, 250, 50, 10, 10, 60000);
    assert(ai_postprocess_yolov5nu(tensor, &desc, &config,
        12U, 0U, 0U, 1U, 2U, &workspace, &result) == 0);
    assert(result.count == 2U);
    assert(result.detections[0].score_q15 == 30000U);
    assert(result.detections[1].score_q15 == 25000U);
}

static void test_result_manager(void)
{
    AiResultManager manager;
    AiDetectionResult result = {0};
    ai_result_manager_init(&manager);
    result.stream_id = 7U;
    result.frame_id = 10U;
    assert(ai_result_manager_publish(&manager, &result) == 1);
    result.frame_id = 9U;
    assert(ai_result_manager_publish(&manager, &result) == 0);
    result.frame_id = 11U;
    result.count = 0U;
    assert(ai_result_manager_publish(&manager, &result) == 1);
    assert(ai_result_manager_latest(&manager, 7U)->frame_id == 11U);
    assert(ai_result_manager_latest(&manager, 7U)->count == 0U);
    assert(manager.publish_count == 2U && manager.stale_count == 1U);
}

static void test_display_map(void)
{
    AiDetectionResult result = {0};
    AiOverlayResult overlay;
    result.stream_id = 0U;
    result.frame_id = 3U;
    result.count = 1U;
    result.detections[0].x_min = 0;
    result.detections[0].y_min = 0;
    result.detections[0].x_max = 640;
    result.detections[0].y_max = 480;
    assert(ai_display_map_mosaic(&result, &overlay) == 0);
    assert(overlay.boxes[0].x_min == 60U);
    assert(overlay.boxes[0].x_max == 420U);
    assert(overlay.boxes[0].y_min == 0U);
    assert(overlay.boxes[0].y_max == 270U);

    result.stream_id = 15U;
    assert(ai_display_map_mosaic(&result, &overlay) == 0);
    assert(overlay.boxes[0].x_min == 1500U);
    assert(overlay.boxes[0].x_max == 1860U);
    assert(overlay.boxes[0].y_min == 810U);
    assert(overlay.boxes[0].y_max == 1080U);
}

int main(void)
{
    test_nms_and_metadata();
    test_top_k();
    test_result_manager();
    test_display_map();
    puts("TEST_AI_POSTPROCESS=PASS");
    return 0;
}
