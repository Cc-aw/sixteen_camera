#include "ai/runtime/ai_batch_runtime.h"

#include "ai/backend/ai_model_backend.h"
#include "ai/postprocess/ai_overlay.h"
#include "ai/postprocess/ai_postprocess.h"
#include "ai/postprocess/ai_result_manager.h"
#include "ai/runtime/ai_tensor_slot_pool.h"
#include "ai/runtime/resources/rt_tensor_manager.h"
#include "platform/console.h"
#include "drivers/tensor/ai_tensor_device.h"
#include "platform/cycle.h"
#include "platform/platform.h"

#include <string.h>

#ifndef STREAM_MODEL_TIMEOUT_SECONDS
#define STREAM_MODEL_TIMEOUT_SECONDS 50
#endif
#define STREAM_MODEL_TIMEOUT (SOC_CLOCK_HZ * STREAM_MODEL_TIMEOUT_SECONDS)
#define STREAM_TARGET_PERIOD (SOC_CLOCK_HZ / UINT64_C(30))
#define STREAM_RESULT_TTL SOC_CLOCK_HZ
#define STREAM_PROFILE_CAPACITY 16U

typedef struct {
    AiRtJob job;
    AiRtSlotHandle tensor_handle;
    uint32_t active;
    uint32_t release_pending;
    uint32_t release_attempted;
    uint32_t slot;
    uint32_t stream;
    uint32_t version;
    uint64_t frame_id;
    uint64_t timestamp;
    uint64_t job_id;
    uint64_t start_cycle;
    AiFrameProfile profile;
} StreamWorker;

typedef struct {
    AiRtJob job;
    uint32_t active;
    uint32_t worker;
    uint32_t stream;
    uint32_t version;
    uint64_t frame_id;
    uint64_t timestamp;
    uint64_t job_id;
    uint64_t start_cycle;
    AiFrameProfile profile;
} StreamPostJob;

typedef struct {
    uint64_t job_id;
    uint64_t frame_id;
    uint32_t stream;
    uint32_t worker;
    AiFrameProfile profile;
} StreamProfileRecord;

typedef struct {
    AiBatchRuntimeStatus status;
    AiStreamRuntimeStatus streams[VIDEO_CHANNEL_COUNT];
    StreamWorker workers[AI_MODEL_WORKER_COUNT];
    StreamPostJob post_jobs[AI_MODEL_POSTPROCESS_CAPACITY];
    AiResultManager results;
    AiPostprocessWorkspace postprocess_workspace;
    uint16_t overlay_dirty;
    uint16_t overlay_clear;
    AiRtTensorManager tensors;
    uint32_t initialized;
    uint32_t draining;
    uint32_t faulted;
    uint64_t next_job_id;
    uint64_t ready_seen_cycle[AI_TENSOR_SLOT_COUNT];
    uint64_t head_wait_start[AI_TENSOR_SLOT_COUNT];
    StreamProfileRecord profiles[STREAM_PROFILE_CAPACITY];
    uint32_t profile_head;
    uint32_t profile_count;
} StreamRuntime;

static StreamRuntime runtime;

_Static_assert(AI_TENSOR_SLOT_COUNT == AI_TENSOR_DEVICE_SLOT_COUNT,
               "Runtime and Tensor device slot capacities must match");
_Static_assert(AI_TENSOR_SLOT_READY == AI_TENSOR_DEVICE_READY,
               "Runtime and Tensor device READY states must match");

static uint32_t hardware_ready(void)
{
    runtime.tensors.ready = ai_tensor_device_ready();
    return runtime.tensors.ready;
}

static uint32_t hardware_error(void)
{
    runtime.tensors.error = ai_tensor_device_error();
    return runtime.tensors.error;
}

static uint32_t hardware_writing(void)
{
    runtime.tensors.writing = ai_tensor_device_writing();
    return runtime.tensors.writing;
}

static void record_error(int error)
{
    runtime.status.error_count++;
    runtime.status.last_error = error;
}

static int read_slot(uint32_t slot, AiTensorSlot *metadata)
{
    AiTensorDeviceDescriptor descriptor;
    if (metadata == 0 || ai_tensor_device_read_slot(slot, &descriptor) != 0)
        return -1;
    metadata->tensor_addr = descriptor.tensor_addr;
    metadata->stream_id = descriptor.stream_id;
    metadata->frame_id = descriptor.frame_id;
    metadata->timestamp = descriptor.timestamp;
    metadata->version = descriptor.version;
    metadata->byte_count = descriptor.byte_count;
    metadata->error_code = descriptor.error_code;
    metadata->owner_worker = AI_TENSOR_SLOT_INVALID;
    metadata->generation = descriptor.version;
    metadata->state = AI_TENSOR_SLOT_READY;
    return 0;
}

static int release_slot(uint32_t slot)
{
    return ai_tensor_device_release(slot, runtime.status.enabled);
}

static void service_overlay(void)
{
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint16_t bit = (uint16_t)(UINT16_C(1) << stream);
        if ((runtime.overlay_dirty & bit) == 0U &&
            (runtime.overlay_clear & bit) == 0U)
            continue;
        AiDetectionResult clear_result;
        const AiDetectionResult *result;
        if ((runtime.overlay_clear & bit) != 0U) {
            memset(&clear_result, 0, sizeof(clear_result));
            clear_result.stream_id = stream;
            result = &clear_result;
        } else {
            result = ai_result_manager_latest(&runtime.results, stream);
        }
        int status = ai_overlay_try_submit(result);
        if (status > 0) {
            runtime.overlay_dirty &= (uint16_t)~bit;
            runtime.overlay_clear &= (uint16_t)~bit;
        } else if (status < 0)
            record_error(status);
        break;
    }
}

static void service_result_ttl(void)
{
    /*
     * A channel is revisited much less frequently than once per second when
     * all cameras share the inference workers.  Keep the latest result while
     * streaming; the next result for that channel (including count == 0)
     * replaces it.  The TTL remains useful after streaming is disabled so a
     * stopped runtime cannot leave stale boxes on screen indefinitely.
     */
    if (runtime.status.enabled != 0U)
        return;

    uint64_t now = platform_read_cycle();
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        AiStreamRuntimeStatus *status = &runtime.streams[stream];
        if (status->last_result_cycle == 0U ||
            now - status->last_result_cycle <= STREAM_RESULT_TTL)
            continue;
        if (ai_result_manager_invalidate(&runtime.results, stream) > 0) {
            uint16_t bit = (uint16_t)(UINT16_C(1) << stream);
            runtime.overlay_dirty &= (uint16_t)~bit;
            runtime.overlay_clear |= bit;
            status->expired_result_count++;
        }
        status->last_result_cycle = 0U;
    }
}

static void complete_stream_job(uint32_t stream_id, uint64_t frame_id,
                                uint32_t version, int error)
{
    AiStreamRuntimeStatus *stream = &runtime.streams[stream_id];
    runtime.status.completed_job_count++;
    stream->completed_count++;
    if (stream->inflight_count != 0U)
        stream->inflight_count--;
    if (error == 0) {
        uint64_t now = platform_read_cycle();
        stream->last_frame_id = frame_id;
        stream->last_version = version;
        stream->last_frame_valid = 1U;
        if (stream->next_deadline != 0U && now > stream->next_deadline)
            stream->missed_deadline_count++;
        stream->last_complete_cycle = now;
        stream->next_deadline = now + STREAM_TARGET_PERIOD;
    } else {
        record_error(error);
    }
}

static StreamPostJob *find_post_job(uint64_t job_id)
{
    for (uint32_t index = 0U; index < AI_MODEL_POSTPROCESS_CAPACITY;
         ++index)
        if (runtime.post_jobs[index].active != 0U &&
            runtime.post_jobs[index].job_id == job_id)
            return &runtime.post_jobs[index];
    return 0;
}

static int register_post_job(const StreamWorker *worker,
                             const AiModelComputeCompletion *completion)
{
    for (uint32_t index = 0U; index < AI_MODEL_POSTPROCESS_CAPACITY;
         ++index) {
        StreamPostJob *post = &runtime.post_jobs[index];
        if (post->active != 0U)
            continue;
        post->job = worker->job;
        post->job.state = AI_RT_JOB_POSTPROCESS;
        post->active = 1U;
        post->worker = (uint32_t)(worker - runtime.workers);
        post->stream = worker->stream;
        post->version = worker->version;
        post->frame_id = worker->frame_id;
        post->timestamp = worker->timestamp;
        post->job_id = worker->job_id;
        post->start_cycle = platform_read_cycle();
        post->profile = completion->profile;
        post->profile.cpu_scheduler_cycles +=
            worker->profile.cpu_scheduler_cycles;
        post->profile.tensor_wait_cycles =
            worker->profile.tensor_wait_cycles;
        post->profile.head_wait_cycles = worker->profile.head_wait_cycles;
        return 0;
    }
    return -1;
}

static void track_ready_slots(uint32_t ready)
{
    uint64_t now = platform_read_cycle();
    for (uint32_t slot = 0U; slot < AI_TENSOR_SLOT_COUNT; ++slot) {
        uint32_t bit = UINT32_C(1) << slot;
        if ((ready & bit) != 0U) {
            if (runtime.ready_seen_cycle[slot] == 0U)
                runtime.ready_seen_cycle[slot] = now;
        } else {
            runtime.ready_seen_cycle[slot] = 0U;
            runtime.head_wait_start[slot] = 0U;
        }
    }
}

static void record_frame_profile(const StreamPostJob *post,
                                 const AiModelFrameCompletion *completion)
{
    StreamProfileRecord *record = &runtime.profiles[runtime.profile_head];
    record->job_id = post->job_id;
    record->frame_id = post->frame_id;
    record->stream = post->stream;
    record->worker = post->worker;
    record->profile = post->profile;
    record->profile.ppu_queue_wait_cycles =
        completion->profile.ppu_queue_wait_cycles;
    runtime.profile_head =
        (runtime.profile_head + 1U) % STREAM_PROFILE_CAPACITY;
    if (runtime.profile_count < STREAM_PROFILE_CAPACITY)
        runtime.profile_count++;
}

static uint32_t post_job_count(void)
{
    uint32_t count = 0U;
    for (uint32_t index = 0U; index < AI_MODEL_POSTPROCESS_CAPACITY;
         ++index)
        if (runtime.post_jobs[index].active != 0U)
            count++;
    return count;
}

static void dispatch_jobs(uint32_t ready);
static void hold_worker_fault(StreamWorker *worker, int error);

static int release_worker_input(StreamWorker *worker)
{
    if (!rt_tensor_can_release(&runtime.tensors, worker->tensor_handle, &worker->job.identity)) return -1;
    int acknowledged = 0;
    if (worker->release_attempted) {
        int state = ai_tensor_device_release_poll(worker->slot);
        if (state == AI_TENSOR_RELEASE_WAIT)
            return -1;
        if (state == AI_TENSOR_RELEASE_ACK) {
            acknowledged = 1;
        } else {
            AiTensorDeviceDescriptor current;
            const AiTensorDeviceDescriptor *owner =
                &runtime.tensors.slots[worker->slot].descriptor;
            if (state != AI_TENSOR_RELEASE_SLOT_PRESENT ||
                ai_tensor_device_read_slot(worker->slot, &current) != 0 ||
                current.stream_id != owner->stream_id || current.frame_id != owner->frame_id ||
                current.version != owner->version || current.timestamp != owner->timestamp ||
                current.tensor_addr != owner->tensor_addr || current.byte_count != owner->byte_count) {
                hold_worker_fault(worker, -60);
                return -1;
            }
        }
    }
    worker->release_attempted = 1U;
    if (!acknowledged && release_slot(worker->slot) != 0) {
        rt_tensor_release_retry(&runtime.tensors);
        runtime.status.release_retry_count = runtime.tensors.release_retry;
        return -1;
    }
    if (rt_tensor_release_ack(&runtime.tensors, worker->tensor_handle, &worker->job.identity) != 0) return -1;
    worker->job.state = AI_RT_JOB_RETIRED;
    runtime.status.consumed_count++;
    worker->active = 0U;
    worker->release_pending = 0U;
    return 0;
}

static void hold_worker_fault(StreamWorker *worker, int error)
{
    rt_job_fault(&worker->job);
    rt_tensor_fault(&runtime.tensors, worker->tensor_handle);
    runtime.faulted = 1U;
    record_error(error);
}

static void progress_workers(void)
{
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        StreamWorker *worker = &runtime.workers[worker_id];
        if (worker->active == 0U || worker->job.state == AI_RT_JOB_FAULT_HELD)
            continue;
        if (worker->release_pending != 0U) {
            if (release_worker_input(worker) != 0) {
                record_error(-41);
                runtime.faulted = 1U;
            }
            continue;
        }
        AiModelComputeCompletion completion;
        int status = ai_model_backend_poll_compute(worker_id, &completion);
        if (status == 0) {
            if (platform_read_cycle() - worker->start_cycle > STREAM_MODEL_TIMEOUT) {
                (void)ai_model_backend_abort(worker_id);
                hold_worker_fault(worker, -43);
            }
            continue;
        }
        uint64_t scheduler_start = platform_read_cycle();
        if (status < 0 || completion.status != 0 ||
            completion.worker_id != worker_id ||
            completion.job_id != worker->job_id ||
            completion.stream_id != worker->stream ||
            completion.frame_id != worker->frame_id ||
            completion.version != worker->version) {
            (void)ai_model_backend_abort(worker_id);
            hold_worker_fault(worker, -45);
            continue;
        }
        AiRtJobIdentity proof = rt_job_identity(completion.job_id, completion.worker_id,
            completion.stream_id, completion.frame_id, completion.version);
        if (rt_job_compute_done(&worker->job, &proof) != 0 ||
            rt_tensor_prove_compute(&runtime.tensors, worker->tensor_handle, &proof) != 0) {
            hold_worker_fault(worker, -57); continue;
        }
        if (register_post_job(worker, &completion) != 0) {
            hold_worker_fault(worker, -51);
            continue;
        }
        worker->release_pending = 1U;
        /* Dispatch in this same service pass, before result polling can
         * retire a short PPU job and hide the intended overlap window. */
        if (release_worker_input(worker) != 0) {
            record_error(-41);
            runtime.faulted = 1U;
            continue;
        }
        StreamPostJob *post = find_post_job(completion.job_id);
        if (post != 0)
            post->profile.cpu_scheduler_cycles +=
                platform_read_cycle() - scheduler_start;
        dispatch_jobs(hardware_ready());
    }
}

static void progress_results(void)
{
    for (uint32_t completed = 0U;
         completed < AI_MODEL_POSTPROCESS_CAPACITY; ++completed) {
        AiModelFrameCompletion completion;
        int status = ai_model_backend_poll_result(&completion);
        if (status == 0)
            return;
        if (status < 0) {
            for (uint32_t p = 0; p < AI_MODEL_POSTPROCESS_CAPACITY; ++p)
                if (runtime.post_jobs[p].active) rt_job_fault(&runtime.post_jobs[p].job);
            record_error(status);
            runtime.faulted = 1U;
            return;
        }
        uint64_t scheduler_start = platform_read_cycle();
        StreamPostJob *post = find_post_job(completion.job_id);
        if (post == 0) {
            record_error(-52);
            runtime.faulted = 1U;
            return;
        }
        int post_status = completion.status;
        AiRtJobIdentity identity = rt_job_identity(completion.job_id, completion.worker_id,
            completion.stream_id, completion.frame_id, completion.version);
        if (!rt_job_identity_matches(&post->job.identity, &identity)) {
            rt_job_fault(&post->job);
            runtime.faulted = 1U; record_error(-53); return;
        }
        AiDetectionResult result;
        if (post_status == 0 && completion.output_addr == 0U)
            post_status = -54;
        if (post_status == 0 &&
            completion.output_desc.dtype == AI_TENSOR_DTYPE_CUSTOM) {
            result = *(const AiDetectionResult *)completion.output_addr;
        } else if (post_status == 0) {
            post_status = ai_postprocess_yolov5nu(
                (const void *)completion.output_addr, &completion.output_desc,
                &ai_postprocess_default_config, post->job_id, post->worker,
                post->stream, post->frame_id, post->timestamp,
                post->version, &runtime.postprocess_workspace, &result);
        }
        if (post_status == 0 &&
            (result.job_id != post->job_id ||
             result.worker_id != post->worker ||
             result.stream_id != post->stream ||
             result.frame_id != post->frame_id ||
             result.version != post->version))
            post_status = -55;
        if (post_status == 0) {
            int published =
                ai_result_manager_publish(&runtime.results, &result);
            runtime.status.postprocess_count++;
            if (published > 0) {
                runtime.status.result_publish_count++;
                runtime.streams[post->stream].last_result_cycle =
                    platform_read_cycle();
                runtime.overlay_clear &=
                    (uint16_t)~(UINT16_C(1) << post->stream);
                runtime.overlay_dirty |=
                    (uint16_t)(UINT16_C(1) << post->stream);
            } else if (published == 0)
                runtime.status.stale_result_count++;
            else
                post_status = published;
        }
        complete_stream_job(post->stream, post->frame_id, post->version,
                            post_status);
        post->profile.cpu_scheduler_cycles += platform_read_cycle() - scheduler_start;
        record_frame_profile(post, &completion);
        post->job.state = AI_RT_JOB_RETIRED;
        post->active = 0U;
    }
}

static uint32_t inflight_streams(void)
{
    uint32_t mask = 0U;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream)
        if (runtime.streams[stream].inflight_count != 0U)
            mask |= UINT32_C(1) << stream;
    return mask;
}

static void service_stale_slots(uint32_t ready)
{
    if (runtime.faulted != 0U)
        return;
    uint32_t free_ready = ready & ~runtime.tensors.held;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint32_t bit0 = UINT32_C(1) << stream;
        uint32_t bit1 = UINT32_C(1) << (stream + VIDEO_CHANNEL_COUNT);
        uint32_t pair = free_ready & (bit0 | bit1);
        uint32_t stale_slot = AI_TENSOR_SLOT_INVALID;
        if (pair == (bit0 | bit1)) {
            AiTensorSlot slot0, slot1;
            if (read_slot(stream, &slot0) != 0 ||
                read_slot(stream + VIDEO_CHANNEL_COUNT, &slot1) != 0)
                continue;
            stale_slot = slot0.version <= slot1.version ? stream :
                         stream + VIDEO_CHANNEL_COUNT;
        } else if (pair != 0U &&
                   runtime.streams[stream].last_frame_valid != 0U) {
            uint32_t slot = (pair & bit0) != 0U ? stream :
                            stream + VIDEO_CHANNEL_COUNT;
            AiTensorSlot metadata;
            if (read_slot(slot, &metadata) == 0 &&
                metadata.version <= runtime.streams[stream].last_version)
                stale_slot = slot;
        }
        if (stale_slot != AI_TENSOR_SLOT_INVALID) {
            if (release_slot(stale_slot) == 0)
                runtime.streams[stream].superseded_count++;
            else {
                record_error(-46);
                runtime.faulted = 1U;
            }
            return;
        }
    }
}

static void dispatch_jobs(uint32_t ready)
{
    track_ready_slots(ready);
    if (runtime.status.enabled == 0U || runtime.faulted != 0U)
        return;
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        uint64_t scheduler_start = platform_read_cycle();
        StreamWorker *worker = &runtime.workers[worker_id];
        if (worker->active != 0U)
            continue;
        uint32_t busy_streams = inflight_streams();
        uint32_t selected_slot = AI_TENSOR_SLOT_INVALID;
        uint32_t selected_stream = 0U;
        AiTensorSlot selected_metadata;
        uint64_t earliest_deadline = UINT64_MAX;
        for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT;
             ++stream) {
            if ((busy_streams & (UINT32_C(1) << stream)) != 0U)
                continue;
            uint32_t slot = AI_TENSOR_SLOT_INVALID;
            uint32_t bit0 = UINT32_C(1) << stream;
            uint32_t bit1 = UINT32_C(1) <<
                            (stream + VIDEO_CHANNEL_COUNT);
            if ((ready & bit0 & ~runtime.tensors.held) != 0U)
                slot = stream;
            if ((ready & bit1 & ~runtime.tensors.held) != 0U)
                slot = stream + VIDEO_CHANNEL_COUNT;
            if (slot == AI_TENSOR_SLOT_INVALID)
                continue;
            AiTensorSlot metadata;
            if (read_slot(slot, &metadata) != 0) {
                record_error(-47);
                continue;
            }
            if (runtime.streams[stream].last_frame_valid != 0U &&
                metadata.version <= runtime.streams[stream].last_version)
                continue;
            uint64_t deadline = runtime.streams[stream].next_deadline;
            if (selected_slot == AI_TENSOR_SLOT_INVALID ||
                deadline < earliest_deadline ||
                (deadline == earliest_deadline &&
                 metadata.frame_id > selected_metadata.frame_id)) {
                selected_slot = slot;
                selected_stream = stream;
                selected_metadata = metadata;
                earliest_deadline = deadline;
            }
        }
        if (selected_slot == AI_TENSOR_SLOT_INVALID)
            return;
        if (runtime.next_job_id == UINT64_MAX) {
            runtime.faulted = 1U; record_error(-56); return;
        }
        uint64_t job_id = ++runtime.next_job_id;
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
        if (rt_tensor_claim(&runtime.tensors, selected_slot, &descriptor, &identity, &handle) != 0) {
            runtime.faulted = 1U; record_error(-58); return;
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
                runtime.streams[selected_stream].inflight_count++;
                hold_worker_fault(worker, submitted); return;
            }
            (void)rt_tensor_reject(&runtime.tensors, handle, &identity);
            /* Both raw-head slots can be owned while the PPU drains.  This
             * is normal backpressure, not a model failure. */
            if (submitted == -3) {
                if (runtime.head_wait_start[selected_slot] == 0U)
                    runtime.head_wait_start[selected_slot] = after_submit;
                return;
            }
            record_error(submitted);
            return;
        }
        int accepted = rt_tensor_accept(&runtime.tensors, handle, &identity);
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
        if (runtime.ready_seen_cycle[selected_slot] != 0U)
            worker->profile.tensor_wait_cycles =
                submit_cycle - runtime.ready_seen_cycle[selected_slot];
        if (runtime.head_wait_start[selected_slot] != 0U)
            worker->profile.head_wait_cycles =
                submit_cycle - runtime.head_wait_start[selected_slot];
        runtime.head_wait_start[selected_slot] = 0U;
        runtime.streams[selected_stream].inflight_count++;
        if (accepted != 0 || begun != 0) {
            hold_worker_fault(worker, -58);
            return;
        }
        runtime.streams[selected_stream].dispatched_count++;
        AiStreamRuntimeStatus *stream = &runtime.streams[selected_stream];
        if (stream->last_service_cycle != 0U) {
            uint64_t gap = submit_cycle - stream->last_service_cycle;
            if (gap > stream->max_service_gap_cycles)
                stream->max_service_gap_cycles = gap;
        }
        stream->last_service_cycle = submit_cycle;
        runtime.status.preprocess_count++;
        worker->profile.cpu_scheduler_cycles += platform_read_cycle() - after_submit;
    }
}

void ai_batch_runtime_init(void)
{
    if (runtime.initialized && !ai_batch_runtime_is_idle()) {
        runtime.faulted = 1U; record_error(-59); return;
    }
    memset(&runtime, 0, sizeof(runtime));
    rt_tensor_manager_init(&runtime.tensors);
    runtime.initialized = 1U;
    ai_result_manager_init(&runtime.results);
    ai_model_backend_init();
    runtime.next_job_id = UINT64_C(1) << 60;
}

static uint32_t runtime_has_no_owners(void)
{
    if (runtime.tensors.held != 0U || post_job_count() != 0U ||
        ai_model_backend_is_idle() == 0U)
        return 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (runtime.workers[worker].active != 0U)
            return 0U;
    return 1U;
}

void ai_batch_runtime_set_enabled(uint32_t enabled)
{
    if (enabled == 0U) {
        runtime.status.enabled = 0U;
        runtime.draining = 1U;
        ai_tensor_device_disable();
        return;
    }
    if (runtime.status.enabled != 0U || runtime.draining != 0U ||
        runtime.faulted != 0U) {
        record_error(-48);
        return;
    }
    /* Preserve startup cleanup of unowned ERROR slots.  An ERROR-only
     * device is not idle, but it can be acknowledged before admission. */
    if (!ai_batch_runtime_is_idle() &&
        (!runtime_has_no_owners() || hardware_ready() != 0U ||
         hardware_writing() != 0U)) {
        record_error(-48);
        return;
    }
    uint32_t error_mask = hardware_error();
    for (uint32_t slot = 0U; slot < AI_TENSOR_SLOT_COUNT; ++slot) {
        if ((error_mask & (UINT32_C(1) << slot)) != 0U &&
            release_slot(slot) != 0) {
            record_error(-50);
            return;
        }
    }
    if (ai_tensor_device_enable(CAMERA_PRESENT_MASK,
                                TENSOR_PRODUCTION_ADMISSION_LIMIT) != 0) {
        record_error(-49);
        return;
    }
    uint64_t first_deadline = platform_read_cycle() + STREAM_TARGET_PERIOD;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream)
        if (runtime.streams[stream].next_deadline == 0U)
            runtime.streams[stream].next_deadline = first_deadline;
    runtime.status.enabled = 1U;
}

uint32_t ai_batch_runtime_is_enabled(void)
{
    return runtime.status.enabled;
}

uint32_t ai_batch_runtime_is_idle(void)
{
    if (runtime.status.enabled != 0U || runtime.draining != 0U ||
        !runtime_has_no_owners())
        return 0U;
    return hardware_ready() == 0U && hardware_error() == 0U &&
           hardware_writing() == 0U;
}

void ai_batch_runtime_poll(void)
{
    uint32_t ready = hardware_ready();
    track_ready_slots(ready);
    progress_workers();
    progress_results();
    service_result_ttl();
    service_overlay();
    if (runtime.status.enabled == 0U && runtime.draining == 0U)
        return;
    ready = hardware_ready();
    track_ready_slots(ready);
    if (runtime.draining != 0U) {
        uint32_t releasable = (ready | hardware_error()) & ~runtime.tensors.held;
        if (releasable != 0U) {
            for (uint32_t slot = 0U; slot < 32U; ++slot)
                if ((releasable & (UINT32_C(1) << slot)) != 0U) {
                    if (release_slot(slot) != 0)
                        record_error(-50);
                    break;
                }
            return;
        }
        if (runtime.tensors.held == 0U && post_job_count() == 0U &&
            ai_model_backend_is_idle() != 0U &&
            hardware_writing() == 0U)
            runtime.draining = 0U;
        return;
    }
    if (runtime.faulted != 0U) {
        ai_batch_runtime_set_enabled(0U);
        return;
    }
    service_stale_slots(ready);
    dispatch_jobs(hardware_ready());
}

void ai_batch_runtime_print_frame_profiles(void)
{
    console_puts("AI FRAME PROFILE count/clock_hz=");
    console_put_u32(runtime.profile_count);
    console_putc('/');
    console_put_u32(SOC_CLOCK_HZ);
    console_puts("\r\n");
    uint32_t oldest = (runtime.profile_head + STREAM_PROFILE_CAPACITY -
                       runtime.profile_count) % STREAM_PROFILE_CAPACITY;
    for (uint32_t item = 0U; item < runtime.profile_count; ++item) {
        const StreamProfileRecord *record =
            &runtime.profiles[(oldest + item) % STREAM_PROFILE_CAPACITY];
        const AiFrameProfile *profile = &record->profile;
        uint64_t rvv_cycles = profile->rvv_maxpool_cycles +
                              profile->rvv_resize_cycles +
                              profile->rvv_copy_requant_cycles;
        console_puts("AI FRAME id/frame/stream/worker=");
        console_put_hex64(record->job_id);
        console_putc('/');
        console_put_hex64(record->frame_id);
        console_putc('/');
        console_put_u32(record->stream);
        console_putc('/');
        console_put_u32(record->worker);
        console_puts("\r\n  cycles scheduler/rocc/gem_busy/load_stall/exec/store_stall=");
        console_put_hex64(profile->cpu_scheduler_cycles);
        console_putc('/');
        console_put_hex64(profile->rocc_submit_cycles);
        console_putc('/');
        console_put_hex64(profile->gemmini_busy_cycles);
        console_putc('/');
        console_put_hex64(profile->gemmini_load_stall_cycles);
        console_putc('/');
        console_put_hex64(profile->gemmini_exec_cycles);
        console_putc('/');
        console_put_hex64(profile->gemmini_store_stall_cycles);
        console_puts("\r\n  cycles rvv/maxpool/resize/copy_requant/fence/tensor_wait/head_wait/ppu_queue_wait=");
        console_put_hex64(rvv_cycles);
        console_putc('/');
        console_put_hex64(profile->rvv_maxpool_cycles);
        console_putc('/');
        console_put_hex64(profile->rvv_resize_cycles);
        console_putc('/');
        console_put_hex64(profile->rvv_copy_requant_cycles);
        console_putc('/');
        console_put_hex64(profile->fence_cycles);
        console_putc('/');
        console_put_hex64(profile->tensor_wait_cycles);
        console_putc('/');
        console_put_hex64(profile->head_wait_cycles);
        console_putc('/');
        console_put_hex64(profile->ppu_queue_wait_cycles);
        console_puts("\r\n");
    }
}

void ai_batch_runtime_print_status(void)
{
    uint32_t hardware_error = ai_tensor_device_error();
    console_puts("AI RT stream enable/drain/fault held/ready/writing/error=");
    console_put_u32(runtime.status.enabled);
    console_putc('/');
    console_put_u32(runtime.draining);
    console_putc('/');
    console_put_u32(runtime.faulted);
    console_putc(' ');
    console_put_hex32(runtime.tensors.held);
    console_putc('/');
    console_put_hex32(hardware_ready());
    console_putc('/');
    console_put_hex32(hardware_writing());
    console_putc('/');
    console_put_hex32(hardware_error);
    console_puts(" jobs/done/post/pub/stale/err=");
    console_put_u32(runtime.status.preprocess_count);
    console_putc('/');
    console_put_u32(runtime.status.completed_job_count);
    console_putc('/');
    console_put_u32(runtime.status.postprocess_count);
    console_putc('/');
    console_put_u32(runtime.status.result_publish_count);
    console_putc('/');
    console_put_u32(runtime.status.stale_result_count);
    console_putc('/');
    console_put_u32(runtime.status.error_count);
    console_puts(" post_inflight=");
    console_put_u32(post_job_count());
    console_puts(" last_err=");
    console_put_u32((uint32_t)(runtime.status.last_error < 0 ?
                    -runtime.status.last_error : runtime.status.last_error));
    console_puts("\r\n");
    console_puts("AI DMA out/max/starve/awstall/wstall/xfer/bwait/burst/done/resp=");
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_OUTSTANDING));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_OUTSTANDING_MAX));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_STARVATION));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_AW_STALL));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_W_STALL));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_W_TRANSFER));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_B_WAIT));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_BURSTS));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_COMPLETED));
    console_putc('/');
    console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_RESP_ERRORS));
    console_puts("\r\n");
    for (uint32_t slot = 0U; slot < AI_TENSOR_SLOT_COUNT; ++slot) {
        if ((hardware_error & (UINT32_C(1) << slot)) == 0U)
            continue;
        (void)ai_tensor_device_select_slot(slot);
        console_puts("AI SLOT ERR slot/ch/code/frame/ver/overflow=");
        console_put_u32(slot);
        console_putc('/');
        console_put_u32(slot % VIDEO_CHANNEL_COUNT + 1U);
        console_putc('/');
        console_put_hex32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_ERROR_CODE));
        console_putc('/');
        console_put_hex32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_FRAME));
        console_putc('/');
        console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_VERSION));
        console_putc('/');
        console_put_u32(ai_tensor_device_read_counter(AI_TENSOR_COUNTER_OVERFLOW));
        console_puts("\r\n");
    }
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        AiStreamRuntimeStatus *status = &runtime.streams[stream];
        if (status->dispatched_count == 0U &&
            status->completed_count == 0U &&
            status->superseded_count == 0U)
            continue;
        console_puts("AI CH");
        console_put_u32(stream + 1U);
        console_puts(" dispatch/done/supersede/inflight/frame/ver/deadline_miss/expire=");
        console_put_u32(status->dispatched_count);
        console_putc('/');
        console_put_u32(status->completed_count);
        console_putc('/');
        console_put_u32(status->superseded_count);
        console_putc('/');
        console_put_u32(status->inflight_count);
        console_putc('/');
        console_put_hex64(status->last_frame_id);
        console_putc('/');
        console_put_u32(status->last_version);
        console_putc('/');
        console_put_u32(status->missed_deadline_count);
        console_putc('/');
        console_put_u32(status->expired_result_count);
        const AiDetectionResult *result =
            ai_result_manager_latest(&runtime.results, stream);
        console_puts(" det=");
        if (result == 0)
            console_puts("none");
        else {
            console_put_u32(result->count);
            if (result->flags & AI_RESULT_METADATA_ONLY)
                console_puts(" (hardware overlay)");
            else if (result->count != 0U) {
                const AiDetection *detection = &result->detections[0];
                console_puts(" first(class/score/xyxy)=");
                console_put_u32(detection->class_id);
                console_putc('/');
                console_put_u32(detection->score_q15);
                console_putc('/');
                console_put_u32((uint32_t)detection->x_min);
                console_putc(',');
                console_put_u32((uint32_t)detection->y_min);
                console_putc(',');
                console_put_u32((uint32_t)detection->x_max);
                console_putc(',');
                console_put_u32((uint32_t)detection->y_max);
            }
        }
        console_puts("\r\n");
    }
    if (runtime.faulted) {
        AiRtResourceSnapshot resources; ai_batch_runtime_get_resources(&resources);
        console_puts("AI OWN tensor/activation/post/Head/retry/fault=");
        console_put_hex32(resources.held_tensor); console_putc('/');
        console_put_hex32(resources.active_worker); console_putc('/');
        console_put_u32(resources.pending_post); console_putc('/');
        console_put_hex32(resources.owned_head); console_putc('/');
        console_put_u32(resources.release_retry); console_putc('/');
        console_put_u32(resources.unsafe_fault); console_puts("\r\n");
        for (uint32_t slot = 0; slot < AI_TENSOR_DEVICE_SLOT_COUNT; ++slot) {
            const AiRtTensorLease *lease = &resources.tensors[slot];
            if (lease->state == AI_RT_FREE) continue;
            console_puts("AI OWN Tensor slot/job/lease/frame/version=");
            console_put_u32(slot); console_putc('/'); console_put_hex64(lease->identity.job_id);
            console_putc('/'); console_put_hex64(lease->generation);
            console_putc('/'); console_put_hex64(lease->identity.frame_id);
            console_putc('/'); console_put_u32(lease->identity.version); console_puts("\r\n");
        }
    }

}

void ai_batch_runtime_get_status(AiBatchRuntimeStatus *status)
{
    if (status != 0)
        *status = runtime.status;
}

const AiBatchContext *ai_batch_runtime_context(uint32_t arena)
{
    (void)arena;
    return 0;
}

const AiDetectionResult *ai_batch_runtime_latest_result(uint32_t stream_id)
{
    return ai_result_manager_latest(&runtime.results, stream_id);
}

int ai_batch_runtime_get_stream_status(uint32_t stream_id,
                                       AiStreamRuntimeStatus *status)
{
    if (status == 0 || stream_id >= VIDEO_CHANNEL_COUNT)
        return -1;
    *status = runtime.streams[stream_id];
    return 0;
}

void ai_batch_runtime_get_resources(AiRtResourceSnapshot *snapshot)
{
    if (!snapshot) return;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->held_tensor = runtime.tensors.held;
    snapshot->ready = runtime.tensors.ready; snapshot->error = runtime.tensors.error;
    snapshot->writing = runtime.tensors.writing; snapshot->release_retry = runtime.tensors.release_retry;
    snapshot->unsafe_fault = runtime.tensors.unsafe_fault; snapshot->faulted = runtime.faulted;
    snapshot->pending_post = post_job_count();
    memcpy(snapshot->tensors, runtime.tensors.slots, sizeof(snapshot->tensors));
    ai_model_backend_get_resources(&snapshot->backend);
    snapshot->active_worker = snapshot->backend.activation_held;
    snapshot->owned_head = snapshot->backend.owned_head;
    snapshot->unsafe_fault += snapshot->backend.unsafe_fault;
    for (uint32_t p = 0; p < AI_MODEL_POSTPROCESS_CAPACITY; ++p)
        if (runtime.post_jobs[p].job.state == AI_RT_JOB_FAULT_HELD) snapshot->unsafe_fault++;
}
