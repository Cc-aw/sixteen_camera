#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "ai_batch_runtime.h"
#include "ai_preprocess.h"

uint64_t test_cycle;

static uint64_t next_batch_id = 1U;
static uint32_t preprocess_active;
static uint32_t preprocess_polls;
static uint32_t next_arena;
static uint32_t ready_mask;
static uint32_t release_fail_once = 1U;

int ai_frame_snapshot_acquire(AiFrameSnapshot *snapshot)
{
    snapshot->batch_id = next_batch_id++;
    snapshot->valid_mask = UINT16_C(0x00ff);
    snapshot->fresh_mask = UINT16_C(0x000f);
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        snapshot->members[channel].stream_id = channel;
        snapshot->members[channel].frame_addr =
            UINT32_C(0x08000000) + channel * UINT32_C(0x02000000);
        snapshot->members[channel].frame_id =
            snapshot->batch_id * 100U + channel;
        snapshot->members[channel].timestamp = 1000U + channel;
        snapshot->members[channel].version = (uint32_t)snapshot->batch_id;
    }
    return 0;
}

int ai_frame_snapshot_release(uint16_t release_mask)
{
    assert(release_mask == UINT16_C(0x00ff));
    if (release_fail_once != 0U) {
        release_fail_once = 0U;
        return -1;
    }
    return 0;
}

int ai_preprocess_start(void)
{
    assert(preprocess_active == 0U);
    preprocess_active = 1U;
    preprocess_polls = 0U;
    return 0;
}

int ai_preprocess_poll(AiPreprocessResult *result)
{
    assert(preprocess_active != 0U);
    if (preprocess_polls++ == 0U)
        return 0;
    assert((ready_mask & (UINT32_C(1) << next_arena)) == 0U);
    result->arena = next_arena;
    result->tensor_base = next_arena == 0U ? TENSOR_ARENA0_PHYS_BASE :
                                             TENSOR_ARENA1_PHYS_BASE;
    result->valid_mask = UINT32_C(0x00ff);
    result->fresh_mask = UINT32_C(0x000f);
    result->batch_id = next_batch_id - 1U;
    result->cycles = 1234U;
    result->read_beats = 10U;
    result->write_beats = 20U;
    ready_mask |= UINT32_C(1) << next_arena;
    next_arena ^= 1U;
    preprocess_active = 0U;
    return 1;
}

int ai_preprocess_run(AiPreprocessResult *result)
{
    (void)result;
    return -1;
}

int ai_preprocess_recycle(uint32_t arena_mask)
{
    assert((ready_mask & arena_mask) == arena_mask);
    ready_mask &= ~arena_mask;
    return 0;
}

void console_putc(char value) { (void)value; }
void console_puts(const char *text) { (void)text; }
void console_put_hex32(uint32_t value) { (void)value; }
void console_put_hex64(uint64_t value) { (void)value; }
void console_put_u32(uint32_t value) { (void)value; }

int ai_overlay_try_submit(const AiDetectionResult *result)
{
    assert(result != 0);
    return 1;
}

int main(void)
{
    AiBatchRuntimeStatus status;

    ai_batch_runtime_init();
    assert(ai_batch_runtime_is_idle() != 0U);
    ai_batch_runtime_set_enabled(1U);

    ai_batch_runtime_poll();
    ai_batch_runtime_poll();
    ai_batch_runtime_poll();

    const AiBatchContext *context = ai_batch_runtime_context(0U);
    assert(context != 0);
    assert(context->state == AI_BATCH_READY);
    assert(context->batch_id == 1U);
    assert(context->valid_mask == UINT16_C(0x00ff));
    assert(context->members[3].frame_id == 103U);
    assert(context->members[8].frame_addr == 0U);

    for (uint32_t iteration = 0U; iteration < 40U; ++iteration)
        ai_batch_runtime_poll();

    ai_batch_runtime_get_status(&status);
    assert(status.snapshot_count >= 2U);
    assert(status.preprocess_count >= 2U);
    assert(status.consumed_count >= 2U);
    assert(status.completed_job_count >= 16U);
    assert(status.postprocess_count == status.completed_job_count);
    assert(status.result_publish_count >= 8U);
    assert(ai_batch_runtime_latest_result(3U) != 0);
    assert(ai_batch_runtime_latest_result(3U)->count == 1U);
    assert(status.release_retry_count == 1U);
    assert(status.error_count == 0U);

    ai_batch_runtime_set_enabled(0U);
    for (uint32_t iteration = 0U; iteration < 20U; ++iteration)
        ai_batch_runtime_poll();
    assert(ai_batch_runtime_is_idle() != 0U);
    assert(ready_mask == 0U);

    puts("TEST_AI_BATCH_RUNTIME=PASS");
    return 0;
}
