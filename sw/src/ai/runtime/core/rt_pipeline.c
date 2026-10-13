#include "ai/runtime/core/rt_internal.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

AiRtPostJob *rt_find_post_job(AiRtCore *rt, uint64_t job_id)
{
    for (uint32_t index = 0U; index < AI_MODEL_POSTPROCESS_CAPACITY;
         ++index)
        if (rt->post_jobs[index].active != 0U &&
            rt->post_jobs[index].job_id == job_id)
            return &rt->post_jobs[index];
    return 0;
}

static int register_post_job(AiRtCore *rt, const AiRtWorker *worker,
                             const AiModelComputeCompletion *completion)
{
    for (uint32_t index = 0U; index < AI_MODEL_POSTPROCESS_CAPACITY;
         ++index) {
        AiRtPostJob *post = &rt->post_jobs[index];
        if (post->active != 0U)
            continue;
        post->job = worker->job;
        post->job.state = AI_RT_JOB_POSTPROCESS;
        post->active = 1U;
        post->worker = (uint32_t)(worker - rt->workers);
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

static int release_worker_input(AiRtCore *rt, AiRtWorker *worker)
{
    if (!rt_tensor_can_release(&rt->tensors, worker->tensor_handle, &worker->job.identity)) return -1;
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
                &rt->tensors.slots[worker->slot].descriptor;
            if (state != AI_TENSOR_RELEASE_SLOT_PRESENT ||
                ai_tensor_device_read_slot(worker->slot, &current) != 0 ||
                current.stream_id != owner->stream_id || current.frame_id != owner->frame_id ||
                current.version != owner->version || current.timestamp != owner->timestamp ||
                current.tensor_addr != owner->tensor_addr || current.byte_count != owner->byte_count) {
                rt_pipeline_hold_worker_fault(rt, worker, -60);
                return -1;
            }
        }
    }
    worker->release_attempted = 1U;
    if (!acknowledged && rt_tensor_release_slot(rt, worker->slot) != 0) {
        rt_tensor_release_retry(&rt->tensors);
        rt->status.release_retry_count = rt->tensors.release_retry;
        return -1;
    }
    if (rt_tensor_release_ack(&rt->tensors, worker->tensor_handle, &worker->job.identity) != 0) return -1;
    worker->job.state = AI_RT_JOB_RETIRED;
    rt->status.consumed_count++;
    worker->active = 0U;
    worker->release_pending = 0U;
    return 0;
}

void rt_pipeline_hold_worker_fault(AiRtCore *rt, AiRtWorker *worker, int error)
{
    rt_job_fault(&worker->job);
    rt_tensor_fault(&rt->tensors, worker->tensor_handle);
    rt_control_fault(&rt->control);
    rt_record_error(rt, error);
}

void rt_pipeline_workers(AiRtCore *rt)
{
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        AiRtWorker *worker = &rt->workers[worker_id];
        if (worker->active == 0U || worker->job.state == AI_RT_JOB_FAULT_HELD)
            continue;
        if (worker->release_pending != 0U) {
            if (release_worker_input(rt, worker) != 0) {
                rt_record_error(rt, -41);
                rt_control_fault(&rt->control);
            }
            continue;
        }
        AiModelComputeCompletion completion;
        int status = ai_model_backend_poll_compute(worker_id, &completion);
        if (status == 0) {
            if (platform_read_cycle() - worker->start_cycle > STREAM_MODEL_TIMEOUT) {
                (void)ai_model_backend_abort(worker_id);
                rt_pipeline_hold_worker_fault(rt, worker, -43);
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
            rt_pipeline_hold_worker_fault(rt, worker, -45);
            continue;
        }
        AiRtJobIdentity proof = rt_job_identity(completion.job_id, completion.worker_id,
            completion.stream_id, completion.frame_id, completion.version);
        if (rt_job_compute_done(&worker->job, &proof) != 0 ||
            rt_tensor_prove_compute(&rt->tensors, worker->tensor_handle, &proof) != 0) {
            rt_pipeline_hold_worker_fault(rt, worker, -57); continue;
        }
        if (register_post_job(rt, worker, &completion) != 0) {
            rt_pipeline_hold_worker_fault(rt, worker, -51);
            continue;
        }
        worker->release_pending = 1U;
        /* Dispatch in this same service pass, before result polling can
         * retire a short PPU job and hide the intended overlap window. */
        if (release_worker_input(rt, worker) != 0) {
            rt_record_error(rt, -41);
            rt_control_fault(&rt->control);
            continue;
        }
        AiRtPostJob *post = rt_find_post_job(rt, completion.job_id);
        if (post != 0)
            post->profile.cpu_scheduler_cycles +=
                platform_read_cycle() - scheduler_start;
        rt_dispatch_jobs(rt, rt_tensor_ready(rt));
    }
}

void rt_pipeline_results(AiRtCore *rt)
{
    for (uint32_t completed = 0U;
         completed < AI_MODEL_POSTPROCESS_CAPACITY; ++completed) {
        AiModelFrameCompletion completion;
        int status = ai_model_backend_poll_result(&completion);
        if (status == 0)
            return;
        if (status < 0) {
            for (uint32_t p = 0; p < AI_MODEL_POSTPROCESS_CAPACITY; ++p)
                if (rt->post_jobs[p].active) rt_job_fault(&rt->post_jobs[p].job);
            rt_record_error(rt, status);
            rt_control_fault(&rt->control);
            return;
        }
        uint64_t scheduler_start = platform_read_cycle();
        AiRtPostJob *post = rt_find_post_job(rt, completion.job_id);
        if (post == 0) {
            rt_record_error(rt, -52);
            rt_control_fault(&rt->control);
            return;
        }
        int post_status = completion.status;
        AiRtJobIdentity identity = rt_job_identity(completion.job_id, completion.worker_id,
            completion.stream_id, completion.frame_id, completion.version);
        if (!rt_job_identity_matches(&post->job.identity, &identity)) {
            rt_job_fault(&post->job);
            rt_control_fault(&rt->control); rt_record_error(rt, -53); return;
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
                post->version, &rt->postprocess_workspace, &result);
        }
        if (post_status == 0 &&
            (result.job_id != post->job_id ||
             result.worker_id != post->worker ||
             result.stream_id != post->stream ||
             result.frame_id != post->frame_id ||
             result.version != post->version))
            post_status = -55;
        if (post_status == 0) {
            post_status = rt_result_service_publish(rt, &result, post->stream);
        }
        rt_complete_stream_job(rt, post->stream, post->frame_id, post->version,
                            post_status);
        post->profile.cpu_scheduler_cycles += platform_read_cycle() - scheduler_start;
        rt_record_frame_profile(rt, post, &completion);
        post->job.state = AI_RT_JOB_RETIRED;
        post->active = 0U;
    }
}
