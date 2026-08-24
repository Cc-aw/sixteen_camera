#include "ai_preprocess.h"

#include "mmio.h"
#include "platform.h"

#define PREPROCESS_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(5))

static uint64_t read_pair(uint32_t low_offset, uint32_t high_offset)
{
    uint32_t low = mmio_read32(FRAMEBUFFER_BASE + low_offset);
    uint32_t high = mmio_read32(FRAMEBUFFER_BASE + high_offset);
    return ((uint64_t)high << 32) | low;
}

static int wait_command(uint32_t busy_mask)
{
    uint64_t start_cycle = read_cycle();
    while ((mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_STATUS) &
            busy_mask) != 0U) {
        if (read_cycle() - start_cycle > PREPROCESS_TIMEOUT_CYCLES)
            return -1;
    }
    return 0;
}

int ai_preprocess_run(AiPreprocessResult *result)
{
    if (result == 0)
        return -1;

    uint32_t status = mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_PRE_STATUS);
    if ((status & (FRAMEBUFFER_PRE_STATUS_START_BUSY |
                   FRAMEBUFFER_PRE_STATUS_ENGINE_BUSY)) != 0U)
        return -2;

    uint32_t ready_before = (status & FRAMEBUFFER_PRE_STATUS_READY_MASK) >>
                            FRAMEBUFFER_PRE_STATUS_READY_SHIFT;
    uint32_t complete_before = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_COMPLETE_COUNT);
    uint32_t error_before = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ERROR_COUNT);

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_CONTROL,
                 FRAMEBUFFER_PRE_CONTROL_START);
    if (wait_command(FRAMEBUFFER_PRE_STATUS_START_BUSY) != 0)
        return -3;

    uint64_t start_cycle = read_cycle();
    for (;;) {
        uint32_t complete_now = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_COMPLETE_COUNT);
        uint32_t error_now = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ERROR_COUNT);
        if (error_now != error_before)
            return -4;
        if (complete_now != complete_before)
            break;
        if (read_cycle() - start_cycle > PREPROCESS_TIMEOUT_CYCLES)
            return -5;
    }

    status = mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_STATUS);
    uint32_t ready_after = (status & FRAMEBUFFER_PRE_STATUS_READY_MASK) >>
                           FRAMEBUFFER_PRE_STATUS_READY_SHIFT;
    uint32_t new_ready = ready_after & ~ready_before;
    if (new_ready == 0U)
        return -6;

    result->arena = (new_ready & 1U) != 0U ? 0U : 1U;
    result->tensor_base = result->arena == 0U ? TENSOR_ARENA0_PHYS_BASE :
                                               TENSOR_ARENA1_PHYS_BASE;
    if (result->arena == 0U) {
        result->batch_id = read_pair(FRAMEBUFFER_PRE_ARENA0_BATCH_LO,
                                     FRAMEBUFFER_PRE_ARENA0_BATCH_HI);
        result->valid_mask = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ARENA0_VALID);
        result->fresh_mask = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ARENA0_FRESH);
    } else {
        result->batch_id = read_pair(FRAMEBUFFER_PRE_ARENA1_BATCH_LO,
                                     FRAMEBUFFER_PRE_ARENA1_BATCH_HI);
        result->valid_mask = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ARENA1_VALID);
        result->fresh_mask = mmio_read32(
            FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ARENA1_FRESH);
    }
    result->cycles = mmio_read32(FRAMEBUFFER_BASE +
                                 FRAMEBUFFER_PRE_LAST_CYCLES);
    result->read_beats = mmio_read32(FRAMEBUFFER_BASE +
                                     FRAMEBUFFER_PRE_LAST_READ);
    result->write_beats = mmio_read32(FRAMEBUFFER_BASE +
                                      FRAMEBUFFER_PRE_LAST_WRITE);
    return 0;
}

int ai_preprocess_recycle(uint32_t arena_mask)
{
    if (arena_mask == 0U || (arena_mask & ~UINT32_C(3)) != 0U)
        return -1;
    uint32_t status = mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_PRE_STATUS);
    if ((status & FRAMEBUFFER_PRE_STATUS_RECYCLE_BUSY) != 0U)
        return -2;
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_RECYCLE_MASK,
                 arena_mask);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_CONTROL,
                 FRAMEBUFFER_PRE_CONTROL_RECYCLE);
    return wait_command(FRAMEBUFFER_PRE_STATUS_RECYCLE_BUSY) == 0 ? 0 : -3;
}
