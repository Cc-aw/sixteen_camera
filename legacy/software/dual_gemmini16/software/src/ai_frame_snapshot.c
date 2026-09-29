#include "ai_frame_snapshot.h"

#include "mmio.h"

#define AI_SNAPSHOT_TIMEOUT_CYCLES (SOC_CLOCK_HZ / UINT64_C(10))
#define AI_STATUS_SNAPSHOT_BUSY UINT32_C(0x01)
#define AI_STATUS_RELEASE_BUSY  UINT32_C(0x02)
#define AI_STATUS_ACTIVE        UINT32_C(0x04)
#define AI_STATUS_META_BUSY     UINT32_C(0x10)

static int wait_status_clear(uint32_t mask)
{
    uint64_t start = read_cycle();
    while ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_STATUS) & mask) !=
           0U) {
        if (read_cycle() - start > AI_SNAPSHOT_TIMEOUT_CYCLES)
            return -1;
    }
    mmio_fence();
    return 0;
}

static uint64_t read_pair(uint32_t low_offset, uint32_t high_offset)
{
    uint32_t low = mmio_read32(FRAMEBUFFER_BASE + low_offset);
    uint32_t high = mmio_read32(FRAMEBUFFER_BASE + high_offset);
    return ((uint64_t)high << 32) | low;
}

int ai_frame_snapshot_acquire(AiFrameSnapshot *snapshot)
{
    if (snapshot == 0)
        return -2;
    if ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_STATUS) &
         (AI_STATUS_ACTIVE | AI_STATUS_SNAPSHOT_BUSY |
          AI_STATUS_RELEASE_BUSY)) != 0U)
        return -3;

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_CONTROL,
                 FRAMEBUFFER_AI_CONTROL_SNAPSHOT);
    mmio_fence();
    if (wait_status_clear(AI_STATUS_SNAPSHOT_BUSY) != 0)
        return -1;
    if ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_STATUS) &
         AI_STATUS_ACTIVE) == 0U)
        return -4;

    snapshot->batch_id = read_pair(FRAMEBUFFER_AI_BATCH_LO,
                                   FRAMEBUFFER_AI_BATCH_HI);
    snapshot->valid_mask = (uint16_t)mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_AI_VALID_MASK);
    snapshot->fresh_mask = (uint16_t)mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_AI_FRESH_MASK);

    for (uint32_t channel = 0; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        AiFrameMetadata *member = &snapshot->members[channel];
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_META_INDEX, channel);
        mmio_fence();
        if (wait_status_clear(AI_STATUS_META_BUSY) != 0)
            return -1;
        member->stream_id = channel;
        member->frame_addr = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_AI_META_ADDR);
        member->frame_id = read_pair(FRAMEBUFFER_AI_META_FRAME_LO,
                                     FRAMEBUFFER_AI_META_FRAME_HI);
        member->timestamp = read_pair(FRAMEBUFFER_AI_META_TIME_LO,
                                      FRAMEBUFFER_AI_META_TIME_HI);
        member->version = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_AI_META_VERSION);
    }
    return 0;
}

int ai_frame_snapshot_release(uint16_t release_mask)
{
    uint16_t held = (uint16_t)mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_AI_HELD_MASK);
    release_mask &= held;
    if (release_mask == 0U)
        return 0;
    if ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_STATUS) &
         AI_STATUS_RELEASE_BUSY) != 0U)
        return -3;

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_RELEASE_MASK,
                 release_mask);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_CONTROL,
                 FRAMEBUFFER_AI_CONTROL_RELEASE);
    mmio_fence();
    if (wait_status_clear(AI_STATUS_RELEASE_BUSY) != 0)
        return -1;
    if ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_HELD_MASK) &
         release_mask) != 0U)
        return -4;
    return 0;
}

uint16_t ai_frame_snapshot_available_mask(void)
{
    return (uint16_t)mmio_read32(FRAMEBUFFER_BASE +
                                 FRAMEBUFFER_AI_VALID_MASK);
}
