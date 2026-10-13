#define main unused_live_fixture_main
#define yolov5nu_dim16_worker_start fixture_worker_start
#define mmio_write32 fixture_write32
#define mmio_read32 fixture_read32
#define mmio_fence fixture_fence
#include "test_v17a_backend.c"
#undef main
#undef yolov5nu_dim16_worker_start
#undef mmio_write32
#undef mmio_read32
#undef mmio_fence
#include "drivers/ppu/ai_ppu_device.h"
static unsigned partial_start_error, missing_begin_ack, ppu_busy_fault;
uint32_t mmio_read32(uintptr_t address)
{
    if (ppu_busy_fault && address == POSTPROCESS_DIAG_BASE + 0x238)
        return 0; /* Exercise the legacy single-reader path. */
    return fixture_read32(address);
}
int yolov5nu_dim16_worker_start(uint32_t worker, const int8_t *input)
{
    int status = fixture_worker_start(worker, input);
    return partial_start_error ? -1 : status;
}
void mmio_write32(uintptr_t address, uint32_t value)
{
    if (missing_begin_ack && address == POSTPROCESS_DIAG_BASE + 0x1b0 && value == 1) return;
    fixture_write32(address, value);
}
void mmio_fence(void) { /* Legacy normal fence is observable separately in trace tests. */ }
#if !YOLO32_LIVE
int yolov5nu_dim16_worker_poll(uint32_t worker, struct yolov5nu_dim16_result *result)
{
    (void)worker; (void)result;
    return ppu_busy_fault ? YOLOV5NU_DIM16_HEAD_READY : YOLOV5NU_DIM16_ERROR;
}
#endif
int main(int argc, char **argv)
{
    assert(argc == 2); drive_worker = 3;
    partial_start_error = !strcmp(argv[1], "start-error");
    missing_begin_ack = !strcmp(argv[1], "begin-error");
    ppu_busy_fault = !strcmp(argv[1], "ppu-busy-done");
    ai_model_backend_init();
    AiModelFrameRequest r = request(0, 1);
    int status = ai_model_backend_submit(&r);
    if (ppu_busy_fault) {
        assert(status == 0);
        AiModelComputeCompletion compute;
        assert(ai_model_backend_poll_compute(0, &compute) == 1);
        regs[0x11c / 4] = AI_PPU_DEVICE_STATUS_DONE | AI_PPU_DEVICE_STATUS_READ_BUSY;
        AiModelFrameCompletion result;
        assert(ai_model_backend_poll_result(&result) == -2);
        AiModelResourceSnapshot before, after;
        ai_model_backend_get_resources(&before);
        assert(!before.activation_held && before.owned_head == 1);
        assert(before.heads[0].state == AI_RT_FAULT_HELD && before.heads[0].producer_complete);
        assert(ai_model_backend_abort(0) == 0); /* Compute stopped; reader has not. */
        ai_model_backend_init();
        ai_model_backend_get_resources(&after);
        assert(after.owned_head == before.owned_head && !ai_model_backend_is_idle());
        assert(ai_model_backend_submit(&r) == -2);
        puts("R2_PPU_BUSY_DONE=PASS activation_released_Head_retained");
        return 0;
    }
    if (partial_start_error || missing_begin_ack) assert(status == AI_MODEL_SUBMIT_FAULT_HELD);
    else {
        assert(status == 0);
#if YOLO32_LIVE
        assert(ai_model_backend_abort(0) == -2);
#endif
        AiModelComputeCompletion completion;
        assert(ai_model_backend_poll_compute(0, &completion) == -2);
    }
    AiModelResourceSnapshot first, after;
    ai_model_backend_get_resources(&first);
    assert(first.activation_held == 1 && first.owned_head == 1);
    assert(first.arenas[0].state == AI_RT_FAULT_HELD && first.heads[0].state == AI_RT_FAULT_HELD);
    assert(first.heads[0].identity.job_id == r.job_id && !first.heads[0].producer_complete);
    for (unsigned repeat = 0; repeat < 4; ++repeat) assert(ai_model_backend_abort(0) == -2);
    ai_model_backend_init(); ai_model_backend_get_resources(&after);
    assert(after.activation_held == first.activation_held && after.owned_head == first.owned_head);
    assert(after.heads[0].generation == first.heads[0].generation && !ai_model_backend_is_idle());
    assert(ai_model_backend_submit(&r) == -2);
    puts("R2_BACKEND_FAULT=PASS begin_start_model_error_retain_activation_Head init_abort_cannot_erase_ownership");
    return 0;
}
