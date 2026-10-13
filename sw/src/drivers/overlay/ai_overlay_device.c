#include "drivers/overlay/ai_overlay_device.h"
#include "mmio.h"
#include "platform/platform.h"

int ai_overlay_device_begin(uint32_t stream, uint32_t count)
{
    if ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_CONTROL) &
         FRAMEBUFFER_OVERLAY_CONTROL_BUSY) != 0U)
        return 0;
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_STREAM, stream);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_COUNT, count);
    return 1;
}

void ai_overlay_device_write_box(uint32_t index, uint64_t packed_coordinates)
{
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_INDEX, index);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_XY0,
                 (uint32_t)packed_coordinates);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_XY1,
                 (uint32_t)(packed_coordinates >> 32));
}

void ai_overlay_device_write_label(uint32_t index, const uint32_t words[4])
{
    /* Preserve the second INDEX write before the four label words. */
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_BOX_INDEX, index);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL0, words[0]);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL1, words[1]);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL2, words[2]);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_LABEL3, words[3]);
}

void ai_overlay_device_commit(void)
{
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_CONTROL,
                 FRAMEBUFFER_OVERLAY_CONTROL_COMMIT);
}
