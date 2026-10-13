#include "ai/postprocess/ai_overlay.h"

#include "ai/postprocess/ai_class_names.h"
#include "ai/postprocess/ai_display_map.h"
#include "drivers/overlay/ai_overlay_device.h"
#include "platform/cycle.h"
#include "platform/platform.h"

static void write_label(uint32_t box_index, uint8_t class_id,
                        uint16_t score_q15)
{
    const char *name = ai_class_name(class_id);
    char label[16] = {0};
    uint32_t words[4] = {0U, 0U, 0U, 0U};
    uint32_t length = 0U;
    uint32_t percent = ((uint32_t)score_q15 * 100U + 16384U) >> 15;

    if (percent > 100U)
        percent = 100U;

    while (length < sizeof(label) && name[length] != '\0') {
        label[length] = name[length];
        ++length;
    }
    if (length < sizeof(label))
        label[length++] = ' ';
    if (percent >= 100U && length < sizeof(label))
        label[length++] = '1';
    if (percent >= 10U && length < sizeof(label))
        label[length++] = (char)('0' + (percent / 10U) % 10U);
    if (length < sizeof(label))
        label[length++] = (char)('0' + percent % 10U);
    if (length < sizeof(label))
        label[length] = '%';

    for (uint32_t byte = 0U; byte < sizeof(label); ++byte)
        words[byte >> 2] |= (uint32_t)(uint8_t)label[byte]
                            << ((byte & 3U) * 8U);

    ai_overlay_device_write_label(box_index, words);
}

int ai_overlay_try_submit(const AiDetectionResult *result)
{
    if (result != 0 && (result->flags & AI_RESULT_HARDWARE_OVERLAY)) return 1;
    AiOverlayResult overlay;
    if (ai_display_map_mosaic(result, &overlay) != 0)
        return -1;
    if (ai_overlay_device_begin(overlay.stream_id, overlay.count) == 0)
        return 0;
    for (uint32_t index = 0U; index < overlay.count; ++index) {
        const AiOverlayBox *box = &overlay.boxes[index];
        uint64_t packed = (uint64_t)(box->x_min & UINT16_C(0x7ff)) |
            ((uint64_t)(box->y_min & UINT16_C(0x7ff)) << 11) |
            ((uint64_t)(box->x_max & UINT16_C(0x7ff)) << 22) |
            ((uint64_t)(box->y_max & UINT16_C(0x7ff)) << 33) |
            ((uint64_t)box->class_id << 44);
        ai_overlay_device_write_box(index, packed);
        write_label(index, box->class_id, box->score_q15);
    }
    ai_overlay_device_commit();
    return 1;
}

int ai_overlay_draw_test_pattern(void)
{
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        AiDetectionResult result = {0};
        result.stream_id = stream;
        result.frame_id = 1U;
        result.count = 1U;
        result.detections[0].x_min = 80;
        result.detections[0].y_min = 80;
        result.detections[0].x_max = 560;
        result.detections[0].y_max = 400;
        result.detections[0].score_q15 = UINT16_C(32767);
        result.detections[0].class_id = (uint8_t)stream;

        uint64_t start = platform_read_cycle();
        int status;
        do {
            status = ai_overlay_try_submit(&result);
            if (status < 0)
                return status;
            if (platform_read_cycle() - start > SOC_CLOCK_HZ / UINT64_C(10))
                return -2;
        } while (status == 0);
    }
    return 0;
}
