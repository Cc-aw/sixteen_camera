#include "ai/runtime/rt.h"
#include "ai/runtime/rt_debug.h"
#include "ai/runtime/core/rt_internal.h"
#include <string.h>

static AiRtCore runtime;

_Static_assert(AI_TENSOR_SLOT_COUNT == AI_TENSOR_DEVICE_SLOT_COUNT,
               "Runtime and Tensor device slot capacities must match");
_Static_assert(AI_TENSOR_SLOT_READY == AI_TENSOR_DEVICE_READY,
               "Runtime and Tensor device READY states must match");

AiRtCore *rt_core_instance(void) { return &runtime; }
int rt_init(void)
{
    rt_core_init(&runtime);
    return rt_control_faulted(&runtime.control) ? -1 : 0;
}
void rt_set_enabled(uint32_t enabled) { rt_state_set_enabled(&runtime, enabled); }
uint32_t rt_is_enabled(void) { return rt_control_enabled(&runtime.control); }
uint32_t rt_is_idle(void) { return rt_state_is_idle(&runtime); }
AiRtState rt_state(void) { return rt_control_state(&runtime.control); }

void rt_poll(void)
{
    uint32_t ready = rt_tensor_ready(&runtime);
    rt_tensor_track_ready(&runtime, ready);
    rt_pipeline_workers(&runtime);
    rt_pipeline_results(&runtime);
    rt_result_service_ttl(&runtime);
    rt_overlay_service(&runtime);
    rt_state_poll_admission(&runtime);
}

void rt_get_status(AiRtStatus *status)
{
    if (status != 0)
        *status = runtime.status;
}

const AiDetectionResult *rt_latest_result(uint32_t stream_id)
{
    return ai_result_manager_latest(&runtime.results, stream_id);
}

int rt_get_stream_status(uint32_t stream_id,
                                       AiRtStreamStatus *status)
{
    if (status == 0 || stream_id >= VIDEO_CHANNEL_COUNT)
        return -1;
    *status = runtime.streams[stream_id];
    return 0;
}

void rt_get_resources(AiRtResourceSnapshot *snapshot)
{
    if (!snapshot) return;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->held_tensor = runtime.tensors.held;
    snapshot->ready = runtime.tensors.ready; snapshot->error = runtime.tensors.error;
    snapshot->writing = runtime.tensors.writing; snapshot->release_retry = runtime.tensors.release_retry;
    snapshot->unsafe_fault = runtime.tensors.unsafe_fault; snapshot->faulted = rt_control_faulted(&runtime.control);
    snapshot->pending_post = rt_post_job_count(&runtime);
    memcpy(snapshot->tensors, runtime.tensors.slots, sizeof(snapshot->tensors));
    rt_backend_get_resources(&runtime.backend, &snapshot->backend);
    snapshot->active_worker = snapshot->backend.activation_held;
    snapshot->owned_head = snapshot->backend.owned_head;
    snapshot->unsafe_fault += snapshot->backend.unsafe_fault;
    for (uint32_t p = 0; p < AI_MODEL_POSTPROCESS_CAPACITY; ++p)
        if (runtime.post_jobs[p].job.state == AI_RT_JOB_FAULT_HELD) snapshot->unsafe_fault++;
}

uint32_t rt_frame_metrics_count(void) { return runtime.profile_count; }

int rt_get_frame_metrics(uint32_t index, AiRtFrameMetrics *metrics)
{
    if (!metrics || index >= runtime.profile_count) return -1;
    uint32_t oldest = (runtime.profile_head + STREAM_PROFILE_CAPACITY -
                       runtime.profile_count) % STREAM_PROFILE_CAPACITY;
    const AiRtProfileRecord *record =
        &runtime.profiles[(oldest + index) % STREAM_PROFILE_CAPACITY];
    memset(metrics, 0, sizeof(*metrics));
    metrics->job_id = record->job_id;
    metrics->frame_id = record->frame_id;
    metrics->stream = record->stream;
    metrics->worker = record->worker;
    metrics->cpu_scheduler_cycles = record->profile.cpu_scheduler_cycles;
    metrics->tensor_wait_cycles = record->profile.tensor_wait_cycles;
    metrics->head_wait_cycles = record->profile.head_wait_cycles;
    metrics->ppu_queue_wait_cycles = record->profile.ppu_queue_wait_cycles;
    return 0;
}
