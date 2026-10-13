/* R0 characterization uses the existing device/model double and links the
 * production backend, PPU drivers and Head queue. It does not simulate DMA.
 * The abort-gap scenario records a known baseline defect, not a safe contract. */
#define main v17a_existing_regression_main
#include "test_v17a_backend.c"
#undef main
#include "ai/postprocess/ai_ppu_publication.h"

static void trace(const char *event, const AiModelFrameRequest *r, unsigned b)
{
    printf("R0_TRACE event=%s job=%llu worker=%u stream=%u frame=%llu version=%u bank=%u generation=%u\n",
           event, (unsigned long long)r->job_id, r->worker_id, r->stream_id,
           (unsigned long long)r->frame_id, r->version, b, generation[b]);
}

static AiModelFrameRequest trace_request(unsigned index)
{
    AiModelFrameRequest r = request(2, 101 + index);
    r.job_id = 4097 + index;
    r.stream_id = 11 + index;
    r.frame_id = UINT64_C(0x100000065) + index;
    r.version = 7 + index;
    return r;
}

static int complete_result(unsigned index, uint64_t job, int bad_generation)
{
    unsigned b = commands[index].bank;
    if (!bad_generation) allocated[b] = 0;
    regs[0x240 / 4] = 1;
    regs[0x250 / 4] = b;
    regs[0x254 / 4] = 2 | (commands[index].stream << 10);
    regs[0x258 / 4] = (uint32_t)commands[index].frame;
    regs[0x25c / 4] = (uint32_t)(commands[index].frame >> 32);
    regs[0x260 / 4] = commands[index].version;
    regs[0x268 / 4] = commands[index].generation + (unsigned)bad_generation;
    AiModelFrameCompletion c;
    int status = ai_model_backend_poll_result(&c);
    if (bad_generation) {
        assert(status == -2 && regs[0x240 / 4] == 1);
        assert(!ai_model_backend_is_idle());
        return status;
    }
    assert(status == 1 && c.job_id == job && c.worker_id == b / 2);
    assert(c.stream_id == commands[index].stream && c.frame_id == commands[index].frame);
    assert(c.version == commands[index].version && c.status == 0);
    const AiDetectionResult *r = (const AiDetectionResult *)c.output_addr;
    assert(r && r->job_id == job && r->count == 2);
    assert((r->flags & (AI_RESULT_HARDWARE_OVERLAY | AI_RESULT_METADATA_ONLY)) ==
           (AI_RESULT_HARDWARE_OVERLAY | AI_RESULT_METADATA_ONLY));
    assert(regs[0x240 / 4] == 0);
    return status;
}

static void identity_trace(void)
{
    AiModelFrameRequest a = trace_request(0), b = trace_request(1), c = trace_request(2);
    assert(!ai_model_backend_submit(&a));
    trace("SUBMIT", &a, 4);
    drive_worker = 2;
    drive_done = 0;
    AiModelComputeCompletion done;
    for (drive_head = 0; drive_head < 6; ++drive_head) {
        assert(ai_model_backend_poll_compute(2, &done) == 0);
        assert(queued == 0 && live_owned[2]);
    }
    assert(published[4] == 63);
    trace("HEADS_PUBLISHED_NO_ADMISSION", &a, 4);
    drive_done = 1;
    assert(ai_model_backend_poll_compute(2, &done) == 1);
    assert(done.job_id == a.job_id && done.stream_id == a.stream_id);
    assert(done.frame_id == a.frame_id && done.version == a.version);
    assert(idle[2] && !live_owned[2] && allocated[4] && queued == 1);
    trace("COMPUTE_DONE_HEAD_HELD", &a, 4);
    drive_worker = 3;
    assert(!ai_model_backend_submit(&b));
    trace("NEXT_STREAM_SUBMIT", &b, 5);
    graph(2);
    assert(ai_model_backend_submit(&c) == -3);
    trace("HEAD_BACKPRESSURE", &c, 4);
    assert(complete_result(0, a.job_id, 0) == 1);
    trace("RESULT_DONE_HEAD_RELEASED", &a, 4);
    assert(!ai_model_backend_submit(&c));
    assert(generation[4] == 2);
    trace("BANK_REUSED", &c, 4);
    graph(2);
    assert(complete_result(2, c.job_id, 0) == 1); /* Results can complete out of order. */
    trace("RESULT_DONE", &c, 4);
    assert(complete_result(1, b.job_id, 0) == 1);
    trace("LATE_RESULT_DONE", &b, 5);
    assert(ai_model_backend_is_idle());
    puts("R0_IDENTITY_TRACE=PASS");
}

static void generation_fault(void)
{
    AiModelFrameRequest r = trace_request(0);
    assert(!ai_model_backend_submit(&r));
    graph(2);
    assert(complete_result(0, r.job_id, 1) == -2);
    assert(allocated[4] && ai_model_backend_submit(&r) == -2);
    trace("GENERATION_FAULT_OWNERSHIP_HELD", &r, 4);
    puts("R0_GENERATION_FAULT=PASS");
}

static void abort_gap(void)
{
    AiModelFrameRequest r = request(0, 1);
    assert(!ai_model_backend_submit(&r));
    assert(ai_model_backend_abort(0) == -2 && live_owned[0]);
    AiModelComputeCompletion c;
    assert(ai_model_backend_poll_compute(0, &c) == -2);
    /* ERROR polling cleared backend running[], but did not stop the model
     * or release its scheduler ownership. The next abort still returns zero. */
    assert(ai_model_backend_abort(0) == 0);
    assert(live_owned[0] && !idle[0] && !(stats.done_mask & 1));
    trace("ABORT_ZERO_WITH_LIVE_TASK_OWNER", &r, 0);
    puts("R0_KNOWN_GAP=abort_zero_without_compute_stop_proof safety=FAIL characterization=PASS");
}

int main(int argc, char **argv)
{
    assert(argc == 2);
    drive_worker = 3;
    ai_model_backend_init();
    if (!strcmp(argv[1], "identity")) identity_trace();
    else if (!strcmp(argv[1], "generation-fault")) generation_fault();
    else if (!strcmp(argv[1], "abort-gap")) abort_gap();
    else assert(!"unknown scenario");
    return 0;
}
