#define main unused_stream_fixture_main
#define mmio_read32 fixture_read32
#define mmio_write32 fixture_write32
#define ai_model_backend_poll_compute fixture_poll_compute
#define ai_model_backend_abort fixture_abort
#define ai_model_backend_submit fixture_submit
#include "test_ai_batch_runtime_stream.c"
#undef main
#undef mmio_read32
#undef mmio_write32
#undef ai_model_backend_poll_compute
#undef ai_model_backend_abort
#undef ai_model_backend_submit

static uint32_t error_bits, refuse_release, release_commands;
static uint32_t fail_compute, bad_compute, fake_abort_zero, uncertain_submit;
uint32_t mmio_read32(uintptr_t address)
{
    if (address == FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_ERROR) return error_bits;
    return fixture_read32(address);
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    if (address == FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL &&
        (value & FRAMEBUFFER_TENSOR_PROD_RELEASE_GO)) {
        release_commands++;
        if (refuse_release) return;
        if (!(ready & release_mask) && (error_bits & release_mask)) {
            error_bits &= ~release_mask; release_count++; control = value & 1U; return;
        }
    }
    fixture_write32(address, value);
}
int ai_model_backend_poll_compute(uint32_t worker, AiModelComputeCompletion *completion)
{
    if (fail_compute) return -2; /* No completion/stop evidence. */
    int result = fixture_poll_compute(worker, completion);
    if (result > 0 && bad_compute) completion->job_id++;
    return result;
}
int ai_model_backend_abort(uint32_t worker)
{
    if (fake_abort_zero) return 0; /* An advisory zero must not authorize release. */
    return fixture_abort(worker);
}
int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    if (uncertain_submit) {
        assert(fixture_submit(request) == 0);
        return AI_MODEL_SUBMIT_FAULT_HELD;
    }
    return fixture_submit(request);
}
static void admit(void)
{
    ai_batch_runtime_init(); ai_batch_runtime_set_enabled(1);
    publish_slot(0, 100); ai_batch_runtime_poll();
    assert(submit_count == 1 && backend_running[0]);
}
int main(int argc, char **argv)
{
    assert(argc == 2);
    if (!strcmp(argv[1], "error-enable")) {
        ai_batch_runtime_init(); error_bits = 1U << 31;
        assert(!ai_batch_runtime_is_idle());
        ai_batch_runtime_set_enabled(1);
        assert(ai_batch_runtime_is_enabled() && error_bits == 0 && release_count == 1);
        puts("R2_ERROR_STARTUP=PASS acknowledged_before_admission"); return 0;
    }
    if (!strcmp(argv[1], "error-only")) {
        ai_batch_runtime_init(); error_bits = 1U << 31;
        assert(!ai_batch_runtime_is_idle());
        ai_batch_runtime_set_enabled(0); ai_batch_runtime_poll();
        assert(error_bits == 0 && release_count == 1);
        ai_batch_runtime_poll(); assert(ai_batch_runtime_is_idle());
        puts("R2_ERROR_ONLY_DRAIN=PASS acknowledged_once"); return 0;
    }
    uncertain_submit = !strcmp(argv[1], "uncertain-submit");
    admit();
    if (!strcmp(argv[1], "release-retry") || !strcmp(argv[1], "late-ack") ||
        !strcmp(argv[1], "release-pending") || !strcmp(argv[1], "reused-after-timeout")) {
        compute_allowed[0] = 1; refuse_release = 1;
        ai_batch_runtime_poll();
        AiRtResourceSnapshot view; ai_batch_runtime_get_resources(&view);
        assert(view.held_tensor == 1 && view.release_retry == 1 && view.pending_post == 1);
        assert(view.tensors[0].state == AI_RT_RELEASE_PENDING && release_count == 0);
        assert(release_commands == 1);
        refuse_release = 0;
        if (!strcmp(argv[1], "late-ack")) {
            ready = 0; release_count++; /* Original command ack arrived after timeout. */
        } else if (!strcmp(argv[1], "reused-after-timeout")) {
            publish_slot(0, 101); /* Ack was missed and producer has already reused the slot. */
            ai_batch_runtime_poll(); ai_batch_runtime_get_resources(&view);
            assert(view.tensors[0].state == AI_RT_FAULT_HELD && view.held_tensor == 1);
            assert(release_commands == 1 && (ready & 1) && frame[0] == 101);
            puts("R2_RELEASE_REUSED=PASS no_second_command_for_new_frame"); return 0;
        } else if (!strcmp(argv[1], "release-pending")) {
            control |= FRAMEBUFFER_TENSOR_PROD_RELEASE_GO;
            ai_batch_runtime_poll();
            assert(release_commands == 1 && release_count == 0);
            control &= ~FRAMEBUFFER_TENSOR_PROD_RELEASE_GO;
        }
        ai_batch_runtime_poll();
        assert(release_count == 1 && !ready);
        assert(release_commands == (!strcmp(argv[1], "late-ack") ? 1U : 2U));
        result_allowed[0] = 1; ai_batch_runtime_poll();
        ai_batch_runtime_poll();
        ai_batch_runtime_get_resources(&view);
        assert(!view.held_tensor && !view.pending_post && release_count == 1);
        puts("R2_RELEASE_RETRY=PASS proof_retained_ack_once pending_and_late_ack_safe"); return 0;
    }
    if (!strcmp(argv[1], "bad-compute")) {
        bad_compute = 1; compute_allowed[0] = 1;
    } else if (!strcmp(argv[1], "timeout")) {
        fake_abort_zero = 1;
        test_cycle += SOC_CLOCK_HZ * UINT64_C(400);
    } else if (!uncertain_submit) {
        fail_compute = 1; fake_abort_zero = 1;
    }
    ai_batch_runtime_poll();
    for (unsigned repeat = 0; repeat < 4; ++repeat) ai_batch_runtime_poll();
    AiRtResourceSnapshot before, after; ai_batch_runtime_get_resources(&before);
    assert(before.faulted && before.held_tensor == 1 && before.tensors[0].state == AI_RT_FAULT_HELD);
    assert(before.tensors[0].identity.frame_id == 100 && before.tensors[0].identity.job_id);
    assert(release_count == 0 && (ready & 1) && !ai_batch_runtime_is_idle());
    ai_batch_runtime_init(); ai_batch_runtime_get_resources(&after);
    assert(after.held_tensor == before.held_tensor && after.tensors[0].generation == before.tensors[0].generation);
    ai_batch_runtime_set_enabled(1); ai_batch_runtime_poll();
    assert(!ai_batch_runtime_is_enabled() && submit_count == 1 && release_count == 0);
    puts("R2_FAULT_OWNERSHIP=PASS no_abort_zero_release no_unsafe_reinit no_reuse");
    return 0;
}
