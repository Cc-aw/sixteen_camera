#include "ai/runtime/core/rt_internal.h"
#include "ai/runtime/scheduler/rt_frame_scheduler.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

static uint32_t inflight_streams(AiRtCore *rt)
{
    uint32_t mask = 0U;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream)
        if (rt->streams[stream].inflight_count != 0U)
            mask |= UINT32_C(1) << stream;
    return mask;
}

/* Submit/ownership transaction. Nonzero stops this dispatch pass exactly as
 * in R2, including Head backpressure and unconfirmed submission. */
static int dispatch_candidate(AiRtCore *rt, uint32_t worker_id,
                               const AiRtFrameCandidate *selected,
                               uint64_t scheduler_start)
{
    AiRtWorker *worker = &rt->workers[worker_id];
    uint32_t selected_slot = selected->slot;
    uint32_t selected_stream = selected->stream;
    AiTensorSlot selected_metadata = selected->metadata;
    if (rt->next_job_id == UINT64_MAX) {
        rt_control_fault(&rt->control);
        rt_record_error(rt, -56);
        return 1;
    }
    uint64_t job_id = ++rt->next_job_id;
    uint64_t submit_cycle = platform_read_cycle();
    AiModelFrameRequest request = {
        .job_id = job_id,
        .worker_id = worker_id,
        .stream_id = selected_stream,
        .frame_id = selected_metadata.frame_id,
        .timestamp = selected_metadata.timestamp,
        .version = selected_metadata.version,
        .input_addr = selected_metadata.tensor_addr,
        .input_bytes = selected_metadata.byte_count,
        .output_addr = AI_MODEL_OUTPUT0_PHYS_BASE +
                       worker_id * AI_MODEL_OUTPUT_ARENA_BYTES,
        .output_bytes = AI_MODEL_OUTPUT_ARENA_BYTES
    };
    AiRtJobIdentity identity = rt_job_identity(job_id, worker_id, selected_stream,
        selected_metadata.frame_id, selected_metadata.version);
    AiTensorDeviceDescriptor descriptor = {
        .tensor_addr = selected_metadata.tensor_addr, .stream_id = selected_metadata.stream_id,
        .frame_id = selected_metadata.frame_id, .timestamp = selected_metadata.timestamp,
        .version = selected_metadata.version, .byte_count = selected_metadata.byte_count,
        .error_code = selected_metadata.error_code, .state = AI_TENSOR_DEVICE_READY
    };
    AiRtSlotHandle handle;
    if (rt_tensor_claim(&rt->tensors, selected_slot, &descriptor, &identity, &handle) != 0) {
        rt_control_fault(&rt->control);
        rt_record_error(rt, -58);
        return 1;
    }
    uint64_t before_submit = platform_read_cycle();
    int submitted = ai_model_backend_submit(&request);
    uint64_t after_submit = platform_read_cycle();
    if (submitted != 0) {
        if (submitted == AI_MODEL_SUBMIT_FAULT_HELD) {
            (void)rt_job_begin(&worker->job, &identity);
            worker->tensor_handle = handle; worker->active = 1U; worker->slot = selected_slot;
            worker->stream = selected_stream; worker->version = selected_metadata.version;
            worker->frame_id = selected_metadata.frame_id; worker->timestamp = selected_metadata.timestamp;
            worker->job_id = job_id; worker->start_cycle = submit_cycle;
            rt->streams[selected_stream].inflight_count++;
            rt_pipeline_hold_worker_fault(rt, worker, submitted); return 1;
        }
        (void)rt_tensor_reject(&rt->tensors, handle, &identity);
        /* Both raw-head slots can be owned while the PPU drains.  This
         * is normal backpressure, not a model failure. */
        if (submitted == -3) {
            if (rt->head_wait_start[selected_slot] == 0U)
                rt->head_wait_start[selected_slot] = after_submit;
            return 1;
        }
        rt_record_error(rt, submitted);
        return 1;
    }
    int accepted = rt_tensor_accept(&rt->tensors, handle, &identity);
    int begun = rt_job_begin(&worker->job, &identity);
    worker->tensor_handle = handle;
    worker->active = 1U;
    worker->release_pending = 0U;
    worker->release_attempted = 0U;
    worker->slot = selected_slot;
    worker->stream = selected_stream;
    worker->version = selected_metadata.version;
    worker->frame_id = selected_metadata.frame_id;
    worker->timestamp = selected_metadata.timestamp;
    worker->job_id = job_id;
    worker->start_cycle = submit_cycle;
    memset(&worker->profile, 0, sizeof(worker->profile));
    worker->profile.cpu_scheduler_cycles =
        before_submit - scheduler_start;
    if (rt->ready_seen_cycle[selected_slot] != 0U)
        worker->profile.tensor_wait_cycles =
            submit_cycle - rt->ready_seen_cycle[selected_slot];
    if (rt->head_wait_start[selected_slot] != 0U)
        worker->profile.head_wait_cycles =
            submit_cycle - rt->head_wait_start[selected_slot];
    rt->head_wait_start[selected_slot] = 0U;
    rt->streams[selected_stream].inflight_count++;
    if (accepted != 0 || begun != 0) {
        rt_pipeline_hold_worker_fault(rt, worker, -58);
        return 1;
    }
    rt->streams[selected_stream].dispatched_count++;
    AiStreamRuntimeStatus *stream = &rt->streams[selected_stream];
    if (stream->last_service_cycle != 0U) {
        uint64_t gap = submit_cycle - stream->last_service_cycle;
        if (gap > stream->max_service_gap_cycles)
            stream->max_service_gap_cycles = gap;
    }
    stream->last_service_cycle = submit_cycle;
    rt->status.preprocess_count++;
    worker->profile.cpu_scheduler_cycles += platform_read_cycle() - after_submit;
    return 0;
}

void rt_dispatch_jobs(AiRtCore *rt, uint32_t ready)
{
    rt_tensor_track_ready(rt, ready);
    if (rt_control_enabled(&rt->control) == 0U || rt_control_faulted(&rt->control) != 0U)
        return;
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        uint64_t scheduler_start = platform_read_cycle();
        AiRtWorker *worker = &rt->workers[worker_id];
        if (worker->active != 0U)
            continue;
        uint32_t busy_streams = inflight_streams(rt);
        AiRtFrameSnapshot snapshot = {0};
        for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
            uint32_t slot = rt_frame_candidate_slot(ready, rt->tensors.held,
                                                     busy_streams, stream);
            if (slot == AI_TENSOR_SLOT_INVALID)
                continue;
            AiTensorSlot metadata;
            if (rt_tensor_read_slot(slot, &metadata) != 0) {
                rt_record_error(rt, -47);
                continue;
            }
            snapshot.valid |= UINT32_C(1) << stream;
            snapshot.candidates[stream] = (AiRtFrameCandidate){
                .slot = slot, .stream = stream, .metadata = metadata,
                .deadline = rt->streams[stream].next_deadline,
                .last_version = rt->streams[stream].last_version,
                .last_frame_valid = rt->streams[stream].last_frame_valid
            };
        }
        AiRtFrameCandidate selected;
        if (!rt_frame_select(&snapshot, &selected))
            return;
        if (dispatch_candidate(rt, worker_id, &selected, scheduler_start))
            return;
    }
}
