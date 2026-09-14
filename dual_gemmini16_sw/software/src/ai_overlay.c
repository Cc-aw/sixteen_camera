#include "ai_overlay.h"

#include "ai_class_names.h"
#include "ai_display_map.h"
#include "mmio.h"
#include "platform.h"

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

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_INDEX,
                 box_index);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL0, words[0]);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL1, words[1]);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL2, words[2]);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL3, words[3]);
}

int ai_overlay_try_submit(const AiDetectionResult *result)
{
    AiOverlayResult overlay;
    if (ai_display_map_mosaic(result, &overlay) != 0)
        return -1;
    if ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_CONTROL) &
         FRAMEBUFFER_OVERLAY_CONTROL_BUSY) != 0U)
        return 0;

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_STREAM,
                 overlay.stream_id);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_COUNT,
                 overlay.count);
    for (uint32_t index = 0U; index < overlay.count; ++index) {
        const AiOverlayBox *box = &overlay.boxes[index];
        uint64_t packed = (uint64_t)(box->x_min & UINT16_C(0x7ff)) |
            ((uint64_t)(box->y_min & UINT16_C(0x7ff)) << 11) |
            ((uint64_t)(box->x_max & UINT16_C(0x7ff)) << 22) |
            ((uint64_t)(box->y_max & UINT16_C(0x7ff)) << 33) |
            ((uint64_t)box->class_id << 44);
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_INDEX,
                     index);
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_XY0,
                     (uint32_t)packed);
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_XY1,
                     (uint32_t)(packed >> 32));
        write_label(index, box->class_id, box->score_q15);
    }
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_CONTROL,
                 FRAMEBUFFER_OVERLAY_CONTROL_COMMIT);
    return 1;
}
