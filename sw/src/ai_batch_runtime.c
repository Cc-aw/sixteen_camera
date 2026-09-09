#include "ai_batch_runtime.h"

#include "ai_model_backend.h"
#include "ai_overlay.h"
#include "ai_postprocess.h"
#include "ai_preprocess.h"
#include "ai_result_manager.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"

enum {
    AI_RUNTIME_IDLE = 0,
    AI_RUNTIME_PREPROCESS = 1,
    AI_RUNTIME_RELEASE = 2
};

#define AI_MODEL_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(50))

typedef struct {
    uint32_t active;
    uint32_t arena;
    uint32_t channel;
    uint64_t job_id;
    uint64_t start_cycle;
} AiRuntimeWorker;

typedef struct {
    AiBatchContext contexts[2];
    AiRuntimeWorker workers[AI_MODEL_WORKER_COUNT];
    AiFrameSnapshot pending_snapshot;
    uint64_t pending_admit_cycle;
    uint16_t release_pending_mask;
    uint16_t overlay_dirty_mask;
    uint32_t pending_valid;
    AiPostprocessWorkspace postprocess_workspace;
    AiResultManager result_manager;
    AiStreamRuntimeStatus streams[VIDEO_CHANNEL_COUNT];
    AiBatchRuntimeStatus status;
} AiBatchRuntime;
static uint32_t ai_trace_stage;

static AiBatchRuntime runtime;

static void clear_context(AiBatchContext *context, uint32_t arena)
{
    context->arena = arena;
    context->tensor_base = arena == 0U ? TENSOR_ARENA0_PHYS_BASE :
                                        TENSOR_ARENA1_PHYS_BASE;
    context->batch_id = 0U;
    context->valid_mask = 0U;
    context->fresh_mask = 0U;
    context->dispatched_mask = 0U;
    context->completed_mask = 0U;
    context->admit_cycle = 0U;
    context->preprocess_end_cycle = 0U;
    context->compute_start_cycle = 0U;
    context->compute_end_cycle = 0U;
    context->postprocess_end_cycle = 0U;
    context->preprocess_cycles = 0U;
    context->preprocess_read_bytes = 0U;
    context->preprocess_write_bytes = 0U;
    context->snapshot_released = 0U;
    context->error = 0;
    context->state = AI_BATCH_FREE;
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        context->members[channel].stream_id = channel;
        context->members[channel].frame_addr = 0U;
        context->members[channel].frame_id = 0U;
        context->members[channel].timestamp = 0U;
        context->members[channel].version = 0U;
    }
}

static void retain_batch_context(AiBatchContext *context,
                                 const AiFrameSnapshot *snapshot,
                                 const AiPreprocessResult *result)
{
    context->batch_id = result->batch_id;
    context->valid_mask = (uint16_t)result->valid_mask;
    context->fresh_mask = (uint16_t)result->fresh_mask;
    context->dispatched_mask = 0U;
    context->completed_mask = 0U;
    context->preprocess_end_cycle = read_cycle();
    context->preprocess_cycles = result->cycles;
    context->preprocess_read_bytes = result->read_beats * 32U;
    context->preprocess_write_bytes = result->write_beats * 32U;
    context->error = 0;
    for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
        if ((snapshot->valid_mask & (UINT16_C(1) << channel)) != 0U) {
            context->members[channel] = snapshot->members[channel];
        } else {
            context->members[channel].stream_id = channel;
            context->members[channel].frame_addr = 0U;
            context->members[channel].frame_id = 0U;
            context->members[channel].timestamp = 0U;
            context->members[channel].version = 0U;
        }
    }
    context->state = AI_BATCH_READY;
}

static void record_error(int error)
{
    runtime.status.error_count++;
    runtime.status.last_error = error;
    if (runtime.pending_valid != 0U)
        runtime.release_pending_mask |= runtime.pending_snapshot.valid_mask;
    runtime.pending_valid = 0U;
    runtime.status.phase = runtime.release_pending_mask != 0U ?
                           AI_RUNTIME_RELEASE : AI_RUNTIME_IDLE;
}

static void complete_channel(AiRuntimeWorker *worker, int error)
{
    AiBatchContext *context = &runtime.contexts[worker->arena];
    AiFrameMetadata *member = &context->members[worker->channel];
    AiStreamRuntimeStatus *stream = &runtime.streams[member->stream_id];
    uint16_t channel_mask = (uint16_t)(UINT16_C(1) << worker->channel);
    context->completed_mask |= channel_mask;
    context->compute_end_cycle = read_cycle();
    runtime.status.completed_job_count++;
    if (stream->inflight_count != 0U)
        stream->inflight_count--;
    stream->completed_count++;
    if (error != 0) {
        context->error = error;
        runtime.status.last_error = error;
        runtime.status.error_count++;
    } else {
        stream->last_frame_id = member->frame_id;
        stream->last_frame_valid = 1U;
        stream->last_service_cycle = context->compute_end_cycle;
    }
    if (context->completed_mask == context->valid_mask)
        context->state = AI_BATCH_DONE;
    worker->active = 0U;
}

static void progress_workers(void)
{
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        AiRuntimeWorker *worker = &runtime.workers[worker_id];
        if (worker->active == 0U)
            continue;

        AiModelFrameCompletion completion;
        int poll_status = ai_model_backend_poll(worker_id, &completion);
        if (poll_status == 0) {
            if (read_cycle() - worker->start_cycle >
                AI_MODEL_TIMEOUT_CYCLES) {
                (void)ai_model_backend_abort(worker_id);
                complete_channel(worker, -10);
            }
            continue;
        }
        AiBatchContext *context = &runtime.contexts[worker->arena];
        const AiFrameMetadata *member = &context->members[worker->channel];
        if (poll_status < 0 || completion.status != 0 ||
            completion.worker_id != worker_id ||
            completion.job_id != worker->job_id ||
            completion.stream_id != member->stream_id ||
            completion.frame_id != member->frame_id ||
            completion.version != member->version ||
            completion.output_addr == 0U) {
            (void)ai_model_backend_abort(worker_id);
            complete_channel(worker, poll_status < 0 ? poll_status : -11);
            continue;
        }

        AiDetectionResult result;
        context->state = AI_BATCH_POSTPROCESS;
        int post_status;
        if (completion.output_desc.dtype == AI_TENSOR_DTYPE_CUSTOM) {
            const AiDetectionResult *backend_result =
                (const AiDetectionResult *)completion.output_addr;
            result = *backend_result;
            post_status = 0;
        } else {
            post_status = ai_postprocess_yolov5nu(
                (const void *)completion.output_addr, &completion.output_desc,
                &ai_postprocess_default_config, worker->job_id, worker_id,
                member->stream_id, member->frame_id, member->timestamp,
                member->version,
                &runtime.postprocess_workspace, &result);
        }
        if (post_status == 0) {
            int publish_status =
                ai_result_manager_publish(&runtime.result_manager, &result);
            runtime.status.postprocess_count++;
            if (publish_status > 0)
                runtime.status.result_publish_count++;
            else if (publish_status == 0)
                runtime.status.stale_result_count++;
            else
                post_status = publish_status;
            if (publish_status > 0)
                runtime.overlay_dirty_mask |=
                    (uint16_t)(UINT16_C(1) << member->stream_id);
        }
        context->postprocess_end_cycle = read_cycle();
        context->state = AI_BATCH_RUNNING;
        complete_channel(worker, post_status);
    }
}

static void service_overlay(void)
{
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint16_t stream_mask = (uint16_t)(UINT16_C(1) << stream);
        if ((runtime.overlay_dirty_mask & stream_mask) == 0U)
            continue;
        const AiDetectionResult *result =
            ai_result_manager_latest(&runtime.result_manager, stream);
        int submit_status = ai_overlay_try_submit(result);
        if (submit_status > 0)
            runtime.overlay_dirty_mask &= (uint16_t)~stream_mask;
        else if (submit_status < 0) {
            runtime.status.error_count++;
            runtime.status.last_error = submit_status;
        }
        break;
    }
}

static void skip_superseded_members(void)
{
    for (uint32_t arena = 0U; arena < 2U; ++arena) {
        AiBatchContext *context = &runtime.contexts[arena];
        if (context->state != AI_BATCH_READY &&
            context->state != AI_BATCH_RUNNING)
            continue;
        uint16_t pending = context->valid_mask &
                           (uint16_t)~context->dispatched_mask;
        for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
            uint16_t mask = (uint16_t)(UINT16_C(1) << channel);
            if ((pending & mask) == 0U)
                continue;
            AiFrameMetadata *member = &context->members[channel];
            AiStreamRuntimeStatus *stream = &runtime.streams[member->stream_id];
            if (stream->last_frame_valid == 0U ||
                member->frame_id > stream->last_frame_id)
                continue;
            context->dispatched_mask |= mask;
            context->completed_mask |= mask;
            stream->superseded_count++;
        }
        if (context->completed_mask == context->valid_mask)
            context->state = AI_BATCH_DONE;
    }
}

static int select_fair_job(uint32_t *selected_arena,
                           uint32_t *selected_channel)
{
    uint32_t found = 0U;
    uint64_t oldest_service = UINT64_MAX;
    uint64_t newest_frame = 0U;

    for (uint32_t arena = 0U; arena < 2U; ++arena) {
        const AiBatchContext *context = &runtime.contexts[arena];
        if (context->state != AI_BATCH_READY &&
            context->state != AI_BATCH_RUNNING)
            continue;
        uint16_t pending = context->valid_mask &
                           (uint16_t)~context->dispatched_mask;
        for (uint32_t channel = 0U; channel < VIDEO_CHANNEL_COUNT; ++channel) {
            if ((pending & (UINT16_C(1) << channel)) == 0U)
                continue;
            const AiFrameMetadata *member = &context->members[channel];
            const AiStreamRuntimeStatus *stream =
                &runtime.streams[member->stream_id];
            if (stream->inflight_count != 0U)
                continue;
            if (found == 0U ||
                stream->last_service_cycle < oldest_service ||
                (stream->last_service_cycle == oldest_service &&
                 member->frame_id > newest_frame)) {
                found = 1U;
                oldest_service = stream->last_service_cycle;
                newest_frame = member->frame_id;
                *selected_arena = arena;
                *selected_channel = channel;
            }
        }
    }
    return found != 0U ? 0 : -1;
}

static void dispatch_jobs(void)
{
    skip_superseded_members();
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        AiRuntimeWorker *worker = &runtime.workers[worker_id];
        if (worker->active != 0U)
            continue;

        uint32_t arena;
        uint32_t channel;
        if (select_fair_job(&arena, &channel) != 0)
            continue;
        AiBatchContext *context = &runtime.contexts[arena];
        AiFrameMetadata *member = &context->members[channel];
        AiStreamRuntimeStatus *stream = &runtime.streams[member->stream_id];

            uint64_t job_id = (context->batch_id << 5) | channel;
            AiModelFrameRequest request = {
                .job_id = job_id,
                .worker_id = worker_id,
                .stream_id = member->stream_id,
                .frame_id = member->frame_id,
                .timestamp = member->timestamp,
                .version = member->version,
                .input_addr = context->tensor_base +
                              (uint32_t)channel * TENSOR_MEMBER_STRIDE,
                .input_bytes = TENSOR_MEMBER_BYTES,
                .output_addr = AI_MODEL_OUTPUT0_PHYS_BASE +
                    worker_id * AI_MODEL_OUTPUT_ARENA_BYTES,
                .output_bytes = AI_MODEL_OUTPUT_ARENA_BYTES
            };
            int submit_status = ai_model_backend_submit(&request);
            if (submit_status != 0) {
                context->dispatched_mask |=
                    (uint16_t)(UINT16_C(1) << channel);
                worker->arena = arena;
                worker->channel = (uint32_t)channel;
                complete_channel(worker, submit_status);
                continue;
            }
            context->dispatched_mask |=
                (uint16_t)(UINT16_C(1) << channel);
            context->compute_start_cycle = read_cycle();
            context->state = AI_BATCH_RUNNING;
            worker->active = 1U;
            worker->arena = arena;
            worker->channel = (uint32_t)channel;
            worker->job_id = job_id;
            worker->start_cycle = context->compute_start_cycle;
            stream->inflight_count++;
            stream->dispatched_count++;
    }
}

static void service_snapshot_release(void)
{
    if (runtime.release_pending_mask == 0U)
        return;
    if (ai_frame_snapshot_release(runtime.release_pending_mask) != 0) {
        runtime.status.release_retry_count++;
        return;
    }
    runtime.status.snapshot_release_count++;
    uint64_t hold_cycles = read_cycle() - runtime.pending_admit_cycle;
    runtime.status.snapshot_hold_cycles += hold_cycles;
    if (hold_cycles > runtime.status.max_snapshot_hold_cycles)
        runtime.status.max_snapshot_hold_cycles = hold_cycles;
    runtime.release_pending_mask = 0U;
    runtime.status.phase = AI_RUNTIME_IDLE;
}

static void recycle_completed_contexts(void)
{
    for (uint32_t arena = 0U; arena < 2U; ++arena) {
        AiBatchContext *context = &runtime.contexts[arena];
        if (context->state == AI_BATCH_READY && context->valid_mask == 0U)
            context->state = AI_BATCH_DONE;
        if (context->state != AI_BATCH_DONE)
            continue;
        if (ai_preprocess_recycle(UINT32_C(1) << context->arena) == 0) {
            runtime.status.consumed_count++;
            runtime.status.last_batch_id = context->batch_id;
            runtime.status.last_valid_mask = context->valid_mask;
            runtime.status.last_fresh_mask = context->fresh_mask;
            runtime.status.last_preprocess_cycles = context->preprocess_cycles;
            clear_context(context, context->arena);
        } else {
            runtime.status.recycle_error_count++;
            runtime.status.error_count++;
        }
    }
}

void ai_batch_runtime_init(void)
{
    ai_trace_stage = 0U;
    ai_preprocess_init();
    runtime.pending_valid = 0U;
    runtime.pending_admit_cycle = 0U;
    runtime.release_pending_mask = 0U;
    runtime.overlay_dirty_mask = 0U;
    runtime.status.enabled = 0U;
    runtime.status.phase = AI_RUNTIME_IDLE;
    runtime.status.snapshot_count = 0U;
    runtime.status.preprocess_count = 0U;
    runtime.status.consumed_count = 0U;
    runtime.status.completed_job_count = 0U;
    runtime.status.postprocess_count = 0U;
    runtime.status.result_publish_count = 0U;
    runtime.status.stale_result_count = 0U;
    runtime.status.error_count = 0U;
    runtime.status.release_retry_count = 0U;
    runtime.status.recycle_error_count = 0U;
    runtime.status.snapshot_release_count = 0U;
    runtime.status.snapshot_hold_cycles = 0U;
    runtime.status.max_snapshot_hold_cycles = 0U;
    runtime.status.arena_wait_count = 0U;
    runtime.status.last_error = 0;
    runtime.status.last_batch_id = 0U;
    runtime.status.last_valid_mask = 0U;
    runtime.status.last_fresh_mask = 0U;
    runtime.status.last_preprocess_cycles = 0U;
    clear_context(&runtime.contexts[0], 0U);
    clear_context(&runtime.contexts[1], 1U);
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        runtime.workers[worker].active = 0U;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        runtime.streams[stream].last_frame_id = 0U;
        runtime.streams[stream].last_service_cycle = 0U;
        runtime.streams[stream].dispatched_count = 0U;
        runtime.streams[stream].completed_count = 0U;
        runtime.streams[stream].superseded_count = 0U;
        runtime.streams[stream].inflight_count = 0U;
        runtime.streams[stream].last_frame_valid = 0U;
    }
    ai_result_manager_init(&runtime.result_manager);
    ai_model_backend_init();
}

void ai_batch_runtime_set_enabled(uint32_t enabled)
{
    if (enabled != 0U &&
        ai_preprocess_get_format() != AI_PREPROCESS_FORMAT_416X416) {
        runtime.status.enabled = 0U;
        runtime.status.error_count++;
        runtime.status.last_error = -12;
        return;
    }
    runtime.status.enabled = enabled != 0U ? 1U : 0U;
    if (runtime.status.enabled == 0U)
        ai_trace_stage = 0U;
}

uint32_t ai_batch_runtime_is_enabled(void)
{
    return runtime.status.enabled;
}

uint32_t ai_batch_runtime_is_idle(void)
{
    uint32_t workers_idle = 1U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        workers_idle &= runtime.workers[worker].active == 0U;
    return runtime.status.phase == AI_RUNTIME_IDLE &&
           runtime.pending_valid == 0U &&
           runtime.release_pending_mask == 0U &&
           runtime.contexts[0].state == AI_BATCH_FREE &&
           runtime.contexts[1].state == AI_BATCH_FREE && workers_idle;
}

void ai_batch_runtime_poll(void)
{
    AiPreprocessResult result;

    progress_workers();
    service_overlay();
    recycle_completed_contexts();
    service_snapshot_release();
    if (runtime.release_pending_mask != 0U)
        return;
    dispatch_jobs();

    if (runtime.status.phase == AI_RUNTIME_PREPROCESS) {
        int poll_status = ai_preprocess_poll(&result);
        if (poll_status == 0)
            return;
        if (poll_status < 0) {
            record_error(poll_status);
            return;
        }
        if (result.arena >= 2U ||
            runtime.contexts[result.arena].state != AI_BATCH_FREE ||
            result.batch_id != runtime.pending_snapshot.batch_id) {
            if (result.arena < 2U)
                (void)ai_preprocess_recycle(UINT32_C(1) << result.arena);
            record_error(-8);
            return;
        }
        AiBatchContext *context = &runtime.contexts[result.arena];
        context->arena = result.arena;
        context->tensor_base = result.tensor_base;
        context->admit_cycle = runtime.pending_admit_cycle;
        retain_batch_context(context, &runtime.pending_snapshot, &result);
        runtime.status.preprocess_count++;
        if (ai_trace_stage == 2U) {
            console_puts("AI TRACE PREPROCESS_DONE\r\n");
            ai_trace_stage = 3U;
        }
        runtime.release_pending_mask = runtime.pending_snapshot.valid_mask;
        runtime.pending_valid = 0U;
        runtime.status.phase = AI_RUNTIME_RELEASE;
        return;
    }

    if (runtime.status.enabled == 0U)
        return;
    if (ai_preprocess_get_format() != AI_PREPROCESS_FORMAT_416X416) {
        runtime.status.enabled = 0U;
        runtime.status.error_count++;
        runtime.status.last_error = -12;
        return;
    }
    if (runtime.contexts[0].state != AI_BATCH_FREE &&
        runtime.contexts[1].state != AI_BATCH_FREE) {
        runtime.status.arena_wait_count++;
        return;
    }

    runtime.pending_admit_cycle = read_cycle();
    if (ai_trace_stage == 0U) {
        console_puts("AI TRACE SNAPSHOT_BEGIN\r\n");
        ai_trace_stage = 1U;
    }
    int snapshot_status = ai_frame_snapshot_acquire(&runtime.pending_snapshot);
    if (snapshot_status != 0) {
        runtime.status.error_count++;
        if (ai_trace_stage == 1U) {
            console_puts("AI TRACE SNAPSHOT_ERROR=");
            console_put_u32((uint32_t)(-snapshot_status));
#ifndef AI_MODEL_BACKEND_HOST_TEST
            console_puts(" status=");
            console_put_hex32(mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_STATUS));
            console_puts(" valid=");
            console_put_hex32(mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_AI_VALID_MASK));
            console_puts(" present=");
            console_put_hex32(mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_PRESENT_MASK));
            console_puts(" ch1_frames=");
            console_put_u32(mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_WRITER_COUNT(0U)));
#endif
            console_puts("\r\n");
            ai_trace_stage = 4U;
        }
        return;
    }
    runtime.pending_valid = 1U;
    if (ai_trace_stage == 1U) {
        console_puts("AI TRACE SNAPSHOT_DONE\r\nAI TRACE PREPROCESS_BEGIN\r\n");
        ai_trace_stage = 2U;
    }
    runtime.status.snapshot_count++;
    if (ai_preprocess_start() != 0) {
        record_error(-9);
        return;
    }
    runtime.status.phase = AI_RUNTIME_PREPROCESS;
}

void ai_batch_runtime_print_status(void)
{
    console_puts("AI RT enable/phase ctx0/ctx1=");
    console_put_u32(runtime.status.enabled);
    console_putc('/');
    console_put_u32(runtime.status.phase);
    console_putc(' ');
    console_put_u32((uint32_t)runtime.contexts[0].state);
    console_putc('/');
    console_put_u32((uint32_t)runtime.contexts[1].state);
    console_puts(" batch/job/post/pub/stale/err=");
    console_put_u32(runtime.status.consumed_count);
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
    console_puts(" last_err=");
    console_put_u32((uint32_t)(runtime.status.last_error < 0 ?
                    -runtime.status.last_error : runtime.status.last_error));
    console_puts(" last(batch/mask/cycles)=");
    console_put_hex64(runtime.status.last_batch_id);
    console_putc('/');
    console_put_hex32(runtime.status.last_valid_mask);
    console_putc('/');
    console_put_u32(runtime.status.last_preprocess_cycles);
    console_puts(" snapshot(release/hold/max/arena_wait)=");
    console_put_u32(runtime.status.snapshot_release_count);
    console_putc('/');
    console_put_u32((uint32_t)runtime.status.snapshot_hold_cycles);
    console_putc('/');
    console_put_u32((uint32_t)runtime.status.max_snapshot_hold_cycles);
    console_putc('/');
    console_put_u32(runtime.status.arena_wait_count);
    console_puts(" backend(stage/cycles)=");
    console_put_u32(ai_model_backend_stage());
    console_putc('/');
    console_put_u32((uint32_t)ai_model_backend_elapsed_cycles());
    console_puts(" pre_fmt=");
    console_puts(ai_preprocess_get_format() == AI_PREPROCESS_FORMAT_416X416 ?
                 "416x416" : "640x480");
    console_puts("\r\n");
    AiModelPeStats pe_stats;
    ai_model_backend_get_pe_stats(&pe_stats);
    if (pe_stats.valid != 0U) {
        console_puts("AI PE layer=");
        console_put_u32(pe_stats.layer_index);
        console_puts(" util_est_permille=");
        console_put_u32(pe_stats.pe_util_permille);
        console_puts(" macs=");
        console_put_hex64(pe_stats.macs);
        console_puts(" exe/load/store=");
        console_put_u32(pe_stats.exe_active_cycles);
        console_putc('/');
        console_put_u32(pe_stats.load_active_cycles);
        console_putc('/');
        console_put_u32(pe_stats.store_active_cycles);
        console_puts("\r\n");
    }
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        const AiStreamRuntimeStatus *status = &runtime.streams[stream];
        if (status->dispatched_count == 0U &&
            status->completed_count == 0U &&
            status->superseded_count == 0U)
            continue;
        console_puts("AI CH");
        console_put_u32(stream + 1U);
        console_puts(" dispatch/done/supersede/inflight/frame=");
        console_put_u32(status->dispatched_count);
        console_putc('/');
        console_put_u32(status->completed_count);
        console_putc('/');
        console_put_u32(status->superseded_count);
        console_putc('/');
        console_put_u32(status->inflight_count);
        console_putc('/');
        console_put_hex64(status->last_frame_id);
        const AiDetectionResult *latest =
            ai_result_manager_latest(&runtime.result_manager, stream);
        if (latest == 0) {
            console_puts(" det=none");
        } else {
            console_puts(" det=");
            console_put_u32(latest->count);
        }
        console_puts("\r\n");
        if (latest != 0) {
            for (uint32_t index = 0U; index < latest->count; ++index) {
                const AiDetection *detection = &latest->detections[index];
                uint32_t score_milli =
                    ((uint32_t)detection->score_q15 * 1000U + 16384U) /
                    32768U;
                console_puts("  BOX");
                console_put_u32(index);
                console_puts(" class/score/xyxy=");
                console_put_u32(detection->class_id);
                console_putc('/');
                console_put_u32(score_milli);
                console_putc('/');
                console_put_u32((uint32_t)detection->x_min);
                console_putc(',');
                console_put_u32((uint32_t)detection->y_min);
                console_putc(',');
                console_put_u32((uint32_t)detection->x_max);
                console_putc(',');
                console_put_u32((uint32_t)detection->y_max);
                console_puts("\r\n");
            }
        }
    }
#ifndef AI_MODEL_BACKEND_HOST_TEST
    console_puts("AI OVL ctrl/stream/count/index/xy0/xy1=");
    console_put_hex32(mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_OVERLAY_CONTROL));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_OVERLAY_STREAM));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_OVERLAY_COUNT));
    console_putc('/');
    console_put_u32(mmio_read32(FRAMEBUFFER_BASE +
                                FRAMEBUFFER_OVERLAY_BOX_INDEX));
    console_putc('/');
    console_put_hex32(mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_OVERLAY_BOX_XY0));
    console_putc('/');
    console_put_hex32(mmio_read32(FRAMEBUFFER_BASE +
                                  FRAMEBUFFER_OVERLAY_BOX_XY1));
    console_puts("\r\n");
#endif
}

void ai_batch_runtime_get_status(AiBatchRuntimeStatus *status)
{
    if (status != 0)
        *status = runtime.status;
}

const AiBatchContext *ai_batch_runtime_context(uint32_t arena)
{
    return arena < 2U ? &runtime.contexts[arena] : 0;
}

const AiDetectionResult *ai_batch_runtime_latest_result(uint32_t stream_id)
{
    return ai_result_manager_latest(&runtime.result_manager, stream_id);
}

int ai_batch_runtime_get_stream_status(uint32_t stream_id,
                                       AiStreamRuntimeStatus *status)
{
    if (status == 0 || stream_id >= VIDEO_CHANNEL_COUNT)
        return -1;
    *status = runtime.streams[stream_id];
    return 0;
}
