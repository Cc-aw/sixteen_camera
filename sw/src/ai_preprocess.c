#include "ai_preprocess.h"

#include "console.h"
#include "mmio.h"
#include "platform.h"

#define PREPROCESS_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(5))

typedef struct {
    uint32_t active;
    uint32_t ready_before;
    uint32_t complete_before;
    uint32_t error_before;
    uint64_t start_cycle;
} AiPreprocessCommand;

static AiPreprocessCommand command;
#ifdef AI_MODEL_YOLOV5NU
#define AI_PREPROCESS_MODEL_FORMAT AI_PREPROCESS_FORMAT_640X480
#else
#define AI_PREPROCESS_MODEL_FORMAT AI_PREPROCESS_FORMAT_416X416
#endif

static AiPreprocessFormat current_format = AI_PREPROCESS_MODEL_FORMAT;

static int ai_preprocess_configure_memory(AiPreprocessFormat format)
{
    uint32_t member_bytes;

    if (format != AI_PREPROCESS_FORMAT_416X416 &&
        format != AI_PREPROCESS_FORMAT_640X480)
        return -1;
    member_bytes = format == AI_PREPROCESS_FORMAT_640X480 ?
                   AI_PREPROCESS_640X480_BYTES : AI_PREPROCESS_416X416_BYTES;
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ARENA0_BASE,
                 TENSOR_ARENA0_PHYS_BASE);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ARENA1_BASE,
                 TENSOR_ARENA1_PHYS_BASE);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_MEMBER_STRIDE,
                 member_bytes);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_MEMBER_BYTES,
                 member_bytes);
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_FORMAT,
                 format == AI_PREPROCESS_FORMAT_640X480 ?
                 FRAMEBUFFER_PRE_FORMAT_640X480 :
                 FRAMEBUFFER_PRE_FORMAT_416X416);
    mmio_fence();
    current_format = format;
    return 0;
}

int ai_preprocess_set_format(AiPreprocessFormat format)
{
    uint32_t status;

    if (format != AI_PREPROCESS_FORMAT_416X416 &&
        format != AI_PREPROCESS_FORMAT_640X480)
        return -1;
    status = mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_STATUS);
    if (command.active != 0U ||
        (status & (FRAMEBUFFER_PRE_STATUS_START_BUSY |
                   FRAMEBUFFER_PRE_STATUS_RECYCLE_BUSY |
                   FRAMEBUFFER_PRE_STATUS_ENGINE_BUSY |
                   FRAMEBUFFER_PRE_STATUS_READY_MASK)) != 0U)
        return -2;
    return ai_preprocess_configure_memory(format);
}

AiPreprocessFormat ai_preprocess_get_format(void)
{
    return current_format;
}

static uint64_t read_pair(uint32_t low_offset, uint32_t high_offset)
{
    uint32_t low = mmio_read32(FRAMEBUFFER_BASE + low_offset);
    uint32_t high = mmio_read32(FRAMEBUFFER_BASE + high_offset);
    return ((uint64_t)high << 32) | low;
}

int ai_preprocess_start(void)
{
    uint32_t status = mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_PRE_STATUS);
    if (command.active != 0U ||
        (status & (FRAMEBUFFER_PRE_STATUS_START_BUSY |
                   FRAMEBUFFER_PRE_STATUS_ENGINE_BUSY)) != 0U)
        return -2;

    command.ready_before = (status & FRAMEBUFFER_PRE_STATUS_READY_MASK) >>
                           FRAMEBUFFER_PRE_STATUS_READY_SHIFT;
    command.complete_before = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_COMPLETE_COUNT);
    command.error_before = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ERROR_COUNT);
    command.start_cycle = read_cycle();
    command.active = 1U;

    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_CONTROL,
                 FRAMEBUFFER_PRE_CONTROL_START);
    mmio_fence();
    return 0;
}

void ai_preprocess_init(void)
{
    command.active = 0U;
    current_format = AI_PREPROCESS_MODEL_FORMAT;

    /* A debugger reset restarts Rocket but does not reset the DDR/video clock
     * domain.  Let an old command finish, then reclaim any tensor arenas left
     * ready by the previous ELF before starting a new software epoch. */
    uint64_t start_cycle = read_cycle();
    uint32_t status;
    do {
        status = mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_STATUS);
        if ((status & (FRAMEBUFFER_PRE_STATUS_START_BUSY |
                       FRAMEBUFFER_PRE_STATUS_RECYCLE_BUSY |
                       FRAMEBUFFER_PRE_STATUS_ENGINE_BUSY)) == 0U)
            break;
        if (read_cycle() - start_cycle > PREPROCESS_TIMEOUT_CYCLES) {
            console_puts("AI PRE init recovery timeout status=");
            console_put_hex32(status);
            console_puts("; reload bitstream required\r\n");
            return;
        }
    } while (1);

    uint32_t ready_mask =
        (status & FRAMEBUFFER_PRE_STATUS_READY_MASK) >>
        FRAMEBUFFER_PRE_STATUS_READY_SHIFT;
    if (ready_mask != 0U) {
        console_puts("AI PRE init reclaim stale arenas=");
        console_put_hex32(ready_mask);
        console_puts("\r\n");
        if (ai_preprocess_recycle(ready_mask) != 0) {
            console_puts("AI PRE init arena reclaim failed; reload bitstream required\r\n");
            return;
        }
    }
    (void)ai_preprocess_configure_memory(AI_PREPROCESS_MODEL_FORMAT);
}

int ai_preprocess_poll(AiPreprocessResult *result)
{
    if (result == 0)
        return -1;
    if (command.active == 0U)
        return -7;

    uint32_t error_now = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_ERROR_COUNT);
    if (error_now != command.error_before) {
        command.active = 0U;
        return -4;
    }
    uint32_t complete_now = mmio_read32(
        FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_COMPLETE_COUNT);
    if (complete_now == command.complete_before) {
        if (read_cycle() - command.start_cycle > PREPROCESS_TIMEOUT_CYCLES) {
            command.active = 0U;
            return -5;
        }
        return 0;
    }

    uint32_t status = mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_PRE_STATUS);
    uint32_t ready_after = (status & FRAMEBUFFER_PRE_STATUS_READY_MASK) >>
                           FRAMEBUFFER_PRE_STATUS_READY_SHIFT;
    uint32_t new_ready = ready_after & ~command.ready_before;
    command.active = 0U;
    if (new_ready == 0U || (new_ready & (new_ready - 1U)) != 0U)
        return -6;

    result->arena = (new_ready & 1U) != 0U ? 0U : 1U;
    result->tensor_base = mmio_read32(FRAMEBUFFER_BASE +
                                      FRAMEBUFFER_PRE_ACTIVE_BASE);
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
    return 1;
}

int ai_preprocess_run(AiPreprocessResult *result)
{
    int status;

    if (result == 0)
        return -1;
    status = ai_preprocess_start();
    if (status != 0)
        return status;
    do {
        status = ai_preprocess_poll(result);
    } while (status == 0);
    return status == 1 ? 0 : status;
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
    mmio_fence();

    /* Verify the ownership bit itself instead of relying on observing a short
     * CDC busy pulse; a fast CPU poll may otherwise miss that pulse entirely.
     */
    uint64_t start_cycle = read_cycle();
    for (;;) {
        status = mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRE_STATUS);
        uint32_t ready = (status & FRAMEBUFFER_PRE_STATUS_READY_MASK) >>
                         FRAMEBUFFER_PRE_STATUS_READY_SHIFT;
        if ((ready & arena_mask) == 0U)
            return 0;
        if (read_cycle() - start_cycle > PREPROCESS_TIMEOUT_CYCLES)
            return -3;
    }
}
