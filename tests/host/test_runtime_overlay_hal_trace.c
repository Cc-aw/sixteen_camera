/* Exercise the unchanged Runtime with real old/new Overlay adapters and a
 * fake mailbox, including busy retry and the existing TTL/result policy. */
#define main existing_stream_main
#define mmio_read32 fixture_read32
#define mmio_write32 fixture_write32
#define mmio_fence fixture_fence
#define ai_overlay_try_submit fixture_overlay_submit
#include "test_ai_batch_runtime_stream.c"
#undef main
#undef mmio_read32
#undef mmio_write32
#undef mmio_fence
#undef ai_overlay_try_submit
#include "ai/postprocess/ai_result_manager.h"

int real_overlay_try_submit(const AiDetectionResult *result);
static uint32_t mailbox_busy, mailbox_stream, mailbox_count;
static uint32_t mailbox_commits, mailbox_writes;
uint32_t mmio_read32(uintptr_t address)
{
    uint32_t value;
    if (address == FRAMEBUFFER_BASE + FRAMEBUFFER_OVERLAY_CONTROL) {
        value = mailbox_busy ? FRAMEBUFFER_OVERLAY_CONTROL_BUSY : 0;
        if (mailbox_busy) --mailbox_busy;
    } else value = fixture_read32(address);
    printf("R %03lx %08x cycle=%llu\n", (unsigned long)(address - FRAMEBUFFER_BASE),
           value, (unsigned long long)test_cycle);
    return value;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    printf("W %03lx %08x cycle=%llu\n", (unsigned long)(address - FRAMEBUFFER_BASE),
           value, (unsigned long long)test_cycle);
    uintptr_t offset = address - FRAMEBUFFER_BASE;
    if (offset >= FRAMEBUFFER_OVERLAY_CONTROL && offset <= FRAMEBUFFER_OVERLAY_LABEL3) {
        ++mailbox_writes;
        if (offset == FRAMEBUFFER_OVERLAY_STREAM) mailbox_stream = value;
        if (offset == FRAMEBUFFER_OVERLAY_COUNT) mailbox_count = value;
        if (offset == FRAMEBUFFER_OVERLAY_CONTROL) {
            assert(value == FRAMEBUFFER_OVERLAY_CONTROL_COMMIT);
            ++mailbox_commits;
            printf("COMMIT stream=%u count=%u cycle=%llu\n", mailbox_stream, mailbox_count,
                   (unsigned long long)test_cycle);
        }
    } else fixture_write32(address, value);
}
void mmio_fence(void)
{
    printf("F cycle=%llu\n", (unsigned long long)test_cycle);
    fixture_fence();
}
int ai_overlay_try_submit(const AiDetectionResult *result)
{
    int status = real_overlay_try_submit(result);
    printf("OVERLAY job=%llu frame=%llu version=%u stream=%u count=%u flags=%u status=%d cycle=%llu\n",
           (unsigned long long)result->job_id, (unsigned long long)result->frame_id,
           result->version, result->stream_id, result->count, result->flags,
           status, (unsigned long long)test_cycle);
    if (status > 0) assert(fixture_overlay_submit(result) == 1);
    return status;
}
static void ttl_retry(void)
{
    ready = writing = control = release_mask = 0;
    submit_count = release_count = overlay_count = overlay_clear_count = 0;
    corrupt_completion = 0;
    memset(compute_allowed, 0, sizeof(compute_allowed));
    memset(result_allowed, 0, sizeof(result_allowed));
    ai_batch_runtime_init(); ai_batch_runtime_set_enabled(1);
    publish_slot(0, 90); ai_batch_runtime_poll();
    assert(submit_count == 1 && requests[0].frame_id == 90);
    compute_allowed[0] = 1; ai_batch_runtime_poll();
    uint32_t old_writes = mailbox_writes, old_commits = mailbox_commits;
    mailbox_busy = 3;
    result_allowed[0] = 1; ai_batch_runtime_poll();
    assert(ai_batch_runtime_latest_result(0)->frame_id == 90);
    assert(mailbox_writes == old_writes);
    ai_batch_runtime_poll(); ai_batch_runtime_poll();
    assert(mailbox_writes == old_writes);
    ai_batch_runtime_poll();
    assert(mailbox_commits == old_commits + 1 && mailbox_count == 1);
    test_cycle += SOC_CLOCK_HZ * UINT64_C(2);
    ai_batch_runtime_poll();
    assert(ai_batch_runtime_latest_result(0)->frame_id == 90); /* Running: no TTL clear. */
    mailbox_busy = 3; old_writes = mailbox_writes;
    ai_batch_runtime_set_enabled(0);
    ai_batch_runtime_poll();
    assert(ai_batch_runtime_latest_result(0) == NULL); /* Disabled: TTL invalidates. */
    ai_batch_runtime_poll(); ai_batch_runtime_poll();
    assert(mailbox_writes == old_writes);
    ai_batch_runtime_poll();
    assert(mailbox_commits == old_commits + 2 && mailbox_count == 0 && overlay_clear_count == 1);
    assert(ai_batch_runtime_is_idle());
    puts("R1C_TTL_BUSY_RETRY=PASS running_retained disabled_clear_pending_retry");
}
static void result_order(void)
{
    AiResultManager manager; ai_result_manager_init(&manager);
    AiDetectionResult r = {0};
    r.job_id = 4097; r.frame_id = UINT64_C(0x100000065); r.stream_id = 4;
    r.version = 9; r.count = 1; r.detections[0].x_max = 200; r.detections[0].y_max = 200;
    assert(ai_result_manager_publish(&manager, &r) == 1);
    assert(ai_overlay_try_submit(ai_result_manager_latest(&manager, 4)) == 1);
    uint32_t old_writes = mailbox_writes;
    r.frame_id--; r.version = UINT32_MAX;
    assert(ai_result_manager_publish(&manager, &r) == 0);
    r.frame_id++; r.version = 9;
    assert(ai_result_manager_publish(&manager, &r) == 0);
    r.frame_id++; r.flags = AI_RESULT_STALE;
    assert(ai_result_manager_publish(&manager, &r) == 0);
    assert(mailbox_writes == old_writes && manager.stale_count == 3);
    r.flags = AI_RESULT_HARDWARE_OVERLAY | AI_RESULT_METADATA_ONLY;
    r.version = 1; /* A newer frame can carry a lower version in Result Manager. */
    assert(ai_result_manager_publish(&manager, &r) == 1);
    assert(ai_overlay_try_submit(ai_result_manager_latest(&manager, 4)) == 1);
    assert(mailbox_writes == old_writes);
    puts("R1C_RESULT_ORDER=PASS stale_late_rejected hardware_metadata_no_CPU_draw");
}
int main(void)
{
    assert(existing_stream_main() == 0);
    ttl_retry(); result_order();
    printf("FINAL commits=%u writes=%u cycle=%llu\n", mailbox_commits, mailbox_writes,
           (unsigned long long)test_cycle);
    return 0;
}
