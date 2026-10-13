/* Reuse the PPU/native model double, including its admission assertions. */
#define main unused_backend_fixture_main
#define test_wfi fixture_wfi
#define console_puts fixture_console_puts
#define mmio_read32 fixture_mmio_read32
#define mmio_write32 fixture_mmio_write32
#include "test_v17a_backend.c"
#undef main
#undef test_wfi
#undef console_puts
#undef mmio_read32
#undef mmio_write32

#include <setjmp.h>
#include "ai/runtime/services/rt_postprocess_service.h"

static jmp_buf fault_jump;
static unsigned io_count;
static const char *fault_reason;

void console_puts(const char *text)
{
    if (strncmp(text, "live_", 5) == 0) fault_reason = text;
}

void test_wfi(void) { longjmp(fault_jump, 1); }
uint32_t mmio_read32(uintptr_t address)
{
    ++io_count;
    return fixture_mmio_read32(address);
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    ++io_count;
    fixture_mmio_write32(address, value);
}

static void reject(const AiRtHeadEvent *event, const char *reason)
{
    AiModelResourceSnapshot before, after;
    ai_model_backend_get_resources(&before);
    unsigned prior_io = io_count;
    fault_reason = 0;
    if (setjmp(fault_jump) == 0) {
        rt_postprocess_live_head(event);
        assert(!"invalid Head proof returned successfully");
    }
    assert(fault_reason && strcmp(fault_reason, reason) == 0);
    assert(io_count == prior_io); /* Reject before publication or admission. */
    ai_model_backend_get_resources(&after);
    assert(memcmp(&before, &after, sizeof(before)) == 0);
    assert(before.activation_held == 1 && before.owned_head == 1);
    assert(!published[0] && !queued && live_owned[0] && !idle[0]);
}

int main(void)
{
    drive_worker = 3;
    ai_model_backend_init();
    AiModelFrameRequest r = request(0, 1);
    assert(ai_model_backend_submit(&r) == 0);
    AiRtHeadEvent valid = {0};
    valid.identity = rt_job_identity(r.job_id, r.worker_id, r.stream_id,
                                     r.frame_id, r.version);
    valid.produced_mask = valid.local_completed_mask = valid.requested_mask = 1;
    valid.start_cycle = test_cycle;
    valid.completed_cycle[0] = test_cycle + 1;

    for (unsigned field = 0; field < 5; ++field) {
        AiRtHeadEvent bad = valid;
        switch (field) {
        case 0: ++bad.identity.job_id; break;
        case 1: ++bad.identity.worker_id; break;
        case 2: ++bad.identity.stream_id; break;
        case 3: ++bad.identity.frame_id; break;
        default: ++bad.identity.version; break;
        }
        reject(&bad, "live_head_slot_state");
    }
    AiRtHeadEvent bad = valid;
    bad.local_completed_mask = 0;
    reject(&bad, "live_head_slot_state");
    bad = valid;
    bad.produced_mask = bad.local_completed_mask = 64;
    reject(&bad, "live_head_slot_state");
    bad = valid;
    bad.requested_mask = 0;
    reject(&bad, "live_head_completion_proof");
    bad = valid;
    bad.completed_cycle[0] = valid.start_cycle - 1;
    reject(&bad, "live_head_completion_proof");

    unsigned prior_io = io_count;
    ai_model_backend_init();
    rt_postprocess_init();
    assert(io_count == prior_io && live_owned[0] && !idle[0]);
    rt_postprocess_live_head(&valid);
    rt_postprocess_progress();
    AiModelResourceSnapshot ownership;
    ai_model_backend_get_resources(&ownership);
    assert(ownership.activation_held == 1 && ownership.owned_head == 1);
    assert(ownership.heads[0].producer_mask == 1);
    assert(!ownership.heads[0].producer_complete && queued == 0);

    AiRtJobIdentity wrong = valid.identity;
    ++wrong.job_id;
    prior_io = io_count;
    assert(rt_postprocess_graph_complete(&wrong) < 0);
    assert(io_count == prior_io && !queued && live_owned[0]);
    graph(0);
    assert(!live_owned[0] && idle[0] && queued == 1);
    ai_model_backend_get_resources(&ownership);
    assert(!ownership.activation_held && ownership.owned_head == 1);
    assert(ownership.heads[0].producer_complete);
    assert(ownership.heads[0].producer_mask == 63);
    result(0);
    assert(ai_model_backend_is_idle());
    puts("R4B_HEAD_PROOF=PASS invalid_identity_masks_requests_cycles_no_IO_no_release partial_no_admission init_retains graph_then_PPU_retirement");
    return 0;
}
