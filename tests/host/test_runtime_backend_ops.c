#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "ai/backend/rt_backend.h"
#include "ai/backend/ai_model_backend.h"

static unsigned init_calls, submit_calls, compute_calls, result_calls, abort_calls, idle_calls;
static int compute_status, result_status, submit_status;
static AiRtBackendRequest accepted;
void ai_model_backend_init(void) { init_calls++; }
int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    submit_calls++;
    if (request) accepted = *request;
    return submit_status;
}
int ai_model_backend_poll_compute(uint32_t worker, AiModelComputeCompletion *completion)
{
    compute_calls++;
    /* Even a negative return may leave plausible metadata. It is not proof. */
    memset(completion, 0, sizeof(*completion));
    completion->job_id = accepted.job_id; completion->worker_id = worker;
    completion->stream_id = accepted.stream_id; completion->frame_id = accepted.frame_id;
    completion->version = accepted.version; completion->compute_cycles = 123;
    completion->profile.gemmini_busy_cycles = 456;
    return compute_status;
}
int ai_model_backend_poll_result(AiModelFrameCompletion *completion)
{
    result_calls++;
    memset(completion, 0, sizeof(*completion));
    completion->job_id = accepted.job_id; completion->worker_id = accepted.worker_id;
    completion->stream_id = accepted.stream_id; completion->frame_id = accepted.frame_id;
    completion->version = accepted.version; completion->output_addr = UINT32_C(0x10203040);
    completion->output_desc.dtype = AI_TENSOR_DTYPE_CUSTOM;
    completion->profile.ppu_queue_wait_cycles = 789;
    return result_status;
}
int ai_model_backend_abort(uint32_t worker) { assert(worker < AI_MODEL_WORKER_COUNT); abort_calls++; return 0; }
uint32_t ai_model_backend_is_idle(void) { idle_calls++; return 1; }
void ai_model_backend_get_resources(AiModelResourceSnapshot *resources)
{
    memset(resources, 0, sizeof(*resources)); resources->owned_head = 1;
}

int main(void)
{
    AiRtBackend backend = {0};
    const AiRtBackendOps *ops = rt_backend_selected_ops();
    assert(ops->worker_count == AI_MODEL_WORKER_COUNT);
    assert(ops->profile == AI_RT_BACKEND_PROFILE);
    assert(ops->gemmini_dim == YOLOV5NU_GEMMINI_DIM);
    rt_backend_init(&backend); assert(init_calls == 1);
    AiRtBackendRequest request = {.job_id = UINT64_C(0x100000001), .worker_id = 0,
        .stream_id = 15, .frame_id = UINT64_C(0x1234567889abcdef), .version = UINT32_MAX};
    for (int status = -4; status <= 0; ++status) {
        submit_status = status;
        assert(rt_backend_submit(&backend, &request) == status);
    }
    assert(submit_calls == 5);
    AiRtBackendEvent event; memset(&event, 0x5a, sizeof(event));
    compute_status = 0;
    assert(rt_backend_progress(&backend, AI_RT_BACKEND_COMPUTE, 0) == 0);
    assert(rt_backend_poll_event(&backend, &event) == 0 && event.backend_status == 0x5a5a5a5a);
    assert(compute_calls == 1 && result_calls == 0);
    compute_status = 1;
    assert(rt_backend_progress(&backend, AI_RT_BACKEND_COMPUTE, 0) == 1);
    unsigned before = idle_calls;
    assert(!rt_backend_is_idle(&backend) && idle_calls == before);
    assert(rt_backend_progress(&backend, AI_RT_BACKEND_RESULT, AI_RT_BACKEND_ANY_WORKER) == AI_RT_BACKEND_EVENT_PENDING);
    assert(result_calls == 0);
    assert(rt_backend_submit(&backend, &request) == AI_RT_BACKEND_EVENT_PENDING && submit_calls == 5);
    rt_backend_init(&backend); assert(init_calls == 1);
    assert(rt_backend_poll_event(&backend, 0) < 0 && backend.pending);
    assert(rt_backend_abort(&backend, 0) == 0 && backend.pending); /* Advisory abort cannot erase proof. */
    assert(rt_backend_poll_event(&backend, &event) == 1 && !backend.pending);
    assert(event.type == AI_RT_BACKEND_COMPUTE_DONE && event.phase == AI_RT_BACKEND_COMPUTE);
    assert(event.payload.compute.job_id == request.job_id && event.payload.compute.frame_id == request.frame_id);
    assert(event.payload.compute.stream_id == 15 && event.payload.compute.version == UINT32_MAX);
    assert(event.payload.compute.compute_cycles == 123 && event.payload.compute.profile.gemmini_busy_cycles == 456);
    assert(rt_backend_poll_event(&backend, &event) == 0 && compute_calls == 2);

    result_status = 1;
    assert(rt_backend_progress(&backend, AI_RT_BACKEND_RESULT, AI_RT_BACKEND_ANY_WORKER) == 1);
    assert(rt_backend_poll_event(&backend, &event) == 1);
    assert(event.type == AI_RT_BACKEND_RESULT_READY && event.requested_worker == AI_RT_BACKEND_ANY_WORKER);
    assert(event.payload.result.job_id == request.job_id && event.payload.result.version == UINT32_MAX);
    assert(event.payload.result.output_addr == UINT32_C(0x10203040));
    assert(event.payload.result.profile.ppu_queue_wait_cycles == 789);
    assert(rt_backend_poll_event(&backend, &event) == 0 && result_calls == 1);
    for (int status = -1; status >= -4; --status) {
        compute_status = status;
        assert(rt_backend_progress(&backend, AI_RT_BACKEND_COMPUTE, 0) == status);
        assert(rt_backend_abort(&backend, 0) == 0);
        assert(rt_backend_poll_event(&backend, &event) == status);
        assert(event.type == AI_RT_BACKEND_FAULT && event.backend_status == status);
        assert(rt_backend_poll_event(&backend, &event) == 0);
    }
    unsigned total = compute_calls + result_calls;
    assert(rt_backend_progress(&backend, (AiRtBackendPhase)99, 0) < 0);
    assert(rt_backend_poll_event(&backend, &event) < 0 && event.type == AI_RT_BACKEND_FAULT);
    assert(compute_calls + result_calls == total);
    assert(rt_backend_is_idle(&backend));
    AiRtBackendResources resources; rt_backend_get_resources(&backend, &resources);
    assert(resources.owned_head == 1 && abort_calls == 5);
    printf("R4A_BACKEND_OPS=PASS profile=%s workers=%u DIM=%u once_only_no_overwrite_fault_not_stop_proof ABI_payload_preserved\n", ops->name, ops->worker_count, ops->gemmini_dim);
    return 0;
}
