#include "ai_display_map.h"

#include "ai_model_abi.h"

#define MOSAIC_TILE_WIDTH 480U
#define MOSAIC_TILE_HEIGHT 270U
#define MOSAIC_IMAGE_WIDTH 360U
#define MOSAIC_PAD_LEFT 60U

static uint32_t clamp_coordinate(int32_t value, uint32_t maximum)
{
    if (value <= 0)
        return 0U;
    if ((uint32_t)value >= maximum)
        return maximum;
    return (uint32_t)value;
}

int ai_display_map_mosaic(const AiDetectionResult *result,
                          AiOverlayResult *overlay)
{
    if (result == 0 || overlay == 0 ||
        result->stream_id >= VIDEO_CHANNEL_COUNT ||
        result->count > AI_MAX_DETECTIONS)
        return -1;

    uint32_t column = result->stream_id & 3U;
    uint32_t row = result->stream_id >> 2;
    uint32_t x_origin = column * MOSAIC_TILE_WIDTH + MOSAIC_PAD_LEFT;
    uint32_t y_origin = row * MOSAIC_TILE_HEIGHT;
    uint32_t count = result->count < AI_OVERLAY_MAX_BOXES_PER_STREAM ?
                     result->count : AI_OVERLAY_MAX_BOXES_PER_STREAM;

    overlay->frame_id = result->frame_id;
    overlay->stream_id = result->stream_id;
    overlay->count = count;
    for (uint32_t index = 0U; index < count; ++index) {
        const AiDetection *source = &result->detections[index];
        AiOverlayBox *destination = &overlay->boxes[index];
        uint32_t x_min = clamp_coordinate(source->x_min,
                                          AI_MODEL_INPUT_WIDTH);
        uint32_t y_min = clamp_coordinate(source->y_min,
                                          AI_MODEL_INPUT_HEIGHT);
        uint32_t x_max = clamp_coordinate(source->x_max,
                                          AI_MODEL_INPUT_WIDTH);
        uint32_t y_max = clamp_coordinate(source->y_max,
                                          AI_MODEL_INPUT_HEIGHT);
        destination->x_min = (uint16_t)(x_origin +
            x_min * MOSAIC_IMAGE_WIDTH / AI_MODEL_INPUT_WIDTH);
        destination->y_min = (uint16_t)(y_origin +
            y_min * MOSAIC_TILE_HEIGHT / AI_MODEL_INPUT_HEIGHT);
        destination->x_max = (uint16_t)(x_origin +
            (x_max * MOSAIC_IMAGE_WIDTH + AI_MODEL_INPUT_WIDTH - 1U) /
            AI_MODEL_INPUT_WIDTH);
        destination->y_max = (uint16_t)(y_origin +
            (y_max * MOSAIC_TILE_HEIGHT + AI_MODEL_INPUT_HEIGHT - 1U) /
            AI_MODEL_INPUT_HEIGHT);
        destination->score_q15 = source->score_q15;
        destination->class_id = source->class_id;
        destination->reserved = 0U;
    }
    return 0;
}
