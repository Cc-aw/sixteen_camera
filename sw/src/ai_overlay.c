#include "ai_overlay.h"

#include "ai_display_map.h"
#include "mmio.h"
#include "platform.h"

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
    }
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_CONTROL,
                 FRAMEBUFFER_OVERLAY_CONTROL_COMMIT);
    return 1;
}
