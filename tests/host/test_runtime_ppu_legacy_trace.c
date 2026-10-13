/* Legacy single-command and CPU fallback paths use the same existing model
 * double, with an explicit HEAD_READY/DONE response instead of live tasks. */
#define main unused_v17a_fixture_main
#define yolov5nu_dim16_worker_use_hardware fixture_worker_use_hardware
#define yolov5nu_dim16_worker_set_head_slot fixture_worker_set_head_slot
#include "test_v17a_backend.c"
#undef main
#undef yolov5nu_dim16_worker_use_hardware
#undef yolov5nu_dim16_worker_set_head_slot

static unsigned legacy_publication_present, legacy_core_present;
void yolov5nu_dim16_worker_use_hardware(uint32_t worker, int enabled)
{
    assert(worker < AI_MODEL_WORKER_COUNT && enabled == (int)legacy_core_present);
}
void yolov5nu_dim16_worker_set_head_slot(uint32_t worker, uintptr_t address)
{
    assert(worker < AI_MODEL_WORKER_COUNT && (!!address) == legacy_core_present);
}
int yolov5nu_dim16_worker_poll(uint32_t worker, struct yolov5nu_dim16_result *result)
{
    assert(worker < AI_MODEL_WORKER_COUNT && !idle[worker]);
    memset(result, 0, sizeof(*result));
    if (!legacy_core_present) {
        idle[worker] = 1;
        return YOLOV5NU_DIM16_DONE;
    }
    return YOLOV5NU_DIM16_HEAD_READY;
}
int main(int argc, char **argv)
{
    assert(argc == 2);
    legacy_core_present = strcmp(argv[1], "cpu-fallback") != 0;
    legacy_publication_present = strcmp(argv[1], "flush-fallback") != 0;
    ai_model_backend_init();
    AiModelFrameRequest r = request(0, 1);
    r.job_id = 4097; r.frame_id = UINT64_C(0x1234567889abcdef); r.version = UINT32_MAX;
    assert(ai_model_backend_submit(&r) == 0);
    if (!strcmp(argv[1], "reader-busy")) regs[0x11c / 4] = 9;
    AiModelComputeCompletion compute;
    assert(ai_model_backend_poll_compute(0, &compute) == 1);
    assert(compute.job_id == r.job_id && compute.frame_id == r.frame_id);
    assert(!ai_model_backend_is_idle());
    AiModelFrameCompletion completion;
    if (!legacy_core_present) {
        assert(ai_model_backend_poll_result(&completion) == 1);
        assert(completion.status == 0 && completion.frame_id == r.frame_id);
        assert(ai_model_backend_is_idle());
        puts("LEGACY_CPU_FALLBACK=PASS");
        return 0;
    }
    if (!strcmp(argv[1], "reader-busy")) {
        assert(ai_model_backend_poll_result(&completion) == 0);
        assert(!ai_model_backend_is_idle());
        regs[0x11c / 4] = 0;
        assert(ai_model_backend_poll_result(&completion) == 0);
    }
    assert(ai_model_backend_poll_result(&completion) == 0);
    if (!strcmp(argv[1], "timeout")) {
        test_cycle += SOC_CLOCK_HZ * UINT64_C(31);
        regs[0x11c / 4] = 1;
        assert(ai_model_backend_poll_result(&completion) == -2);
        assert(!ai_model_backend_is_idle() && allocated[0]);
        puts("LEGACY_TIMEOUT_OWNERSHIP_HELD=PASS");
        return 0;
    }
    int error = !strcmp(argv[1], "ppu-error");
    regs[0x11c / 4] = error ? 6 : 2;
    regs[0x124 / 4] = 2;
    regs[0x128 / 4] = 0x00200010;
    regs[0x12c / 4] = 0x00400030;
    regs[0x130 / 4] = 0x00051234;
    allocated[0] = 0; /* Device completed its single command. */
    assert(ai_model_backend_poll_result(&completion) == 1);
    assert(completion.job_id == r.job_id && completion.frame_id == r.frame_id);
    assert(completion.version == r.version && completion.status == (error ? -2 : 0));
    if (!error) {
        const AiDetectionResult *result = (const AiDetectionResult *)completion.output_addr;
        assert(result->count == 2 && result->detections[0].x_min == 16);
        assert(result->detections[1].y_max == 64 && result->detections[1].score_q15 == 0x1234);
        assert(result->detections[0].class_id == 5);
    }
    assert(ai_model_backend_is_idle());
    puts("LEGACY_SINGLE_COMMAND=PASS");
    return 0;
}
