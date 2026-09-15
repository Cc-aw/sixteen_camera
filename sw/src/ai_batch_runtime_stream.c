#include "ai_batch_runtime.h"

#include "ai_model_backend.h"
#include "ai_overlay.h"
#include "ai_postprocess.h"
#include "ai_result_manager.h"
#include "ai_tensor_slot_pool.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"

#include <string.h>

#define STREAM_MODEL_TIMEOUT (SOC_CLOCK_HZ * UINT64_C(50))
#define STREAM_MMIO_TIMEOUT (SOC_CLOCK_HZ / UINT64_C(10))
#define STREAM_META_SETTLE (SOC_CLOCK_HZ / UINT64_C(100000))

typedef struct {
    uint32_t active;
    uint32_t release_pending;
    uint32_t slot;
    uint32_t stream;
    uint32_t version;
    uint64_t frame_id;
    uint64_t timestamp;
    uint64_t job_id;
    uint64_t start_cycle;
} StreamWorker;

typedef struct {
    AiBatchRuntimeStatus status;
    AiStreamRuntimeStatus streams[VIDEO_CHANNEL_COUNT];
    StreamWorker workers[AI_MODEL_WORKER_COUNT];
    AiResultManager results;
    AiPostprocessWorkspace postprocess_workspace;
    uint16_t overlay_dirty;
    uint32_t held_mask;
    uint32_t draining;
    uint32_t faulted;
    uint64_t next_job_id;
} StreamRuntime;

static StreamRuntime runtime;

static uint32_t slot_address(uint32_t slot)
{
    uint32_t arena_base = slot < VIDEO_CHANNEL_COUNT ?
                          TENSOR_ARENA0_PHYS_BASE : TENSOR_ARENA1_PHYS_BASE;
    return arena_base + (slot % VIDEO_CHANNEL_COUNT) *
           TENSOR_MEMBER_STRIDE;
}

static uint32_t hardware_ready(void)
{
    return mmio_read32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_READY);
}

static void record_error(int error)
{
    runtime.status.error_count++;
    runtime.status.last_error = error;
}

static int read_slot(uint32_t slot, uint32_t *frame, uint32_t *bytes)
{
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_INDEX, slot);
    mmio_fence();
    uint64_t settle_start = read_cycle();
    while (read_cycle() - settle_start < STREAM_META_SETTLE)
        ;
    uint64_t start = read_cycle();
    do {
        *frame = mmio_read32(FRAMEBUFFER_BASE +
                             FRAMEBUFFER_TENSOR_PROD_FRAME);
        *bytes = mmio_read32(FRAMEBUFFER_BASE +
                             FRAMEBUFFER_TENSOR_PROD_BYTES);
        if (*frame != 0U && *bytes == TENSOR_MEMBER_BYTES)
            return 0;
    } while (read_cycle() - start < STREAM_MMIO_TIMEOUT);
    return -1;
}

static int release_slot(uint32_t slot)
{
    uint32_t bit = UINT32_C(1) << slot;
    uint64_t start = read_cycle();
    while ((mmio_read32(FRAMEBUFFER_BASE +
                        FRAMEBUFFER_TENSOR_PROD_CONTROL) &
            FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
        if (read_cycle() - start > STREAM_MMIO_TIMEOUT)
            return -1;
    }
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_RELEASE, bit);
    mmio_fence();
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 (runtime.status.enabled != 0U ?
                  FRAMEBUFFER_TENSOR_PROD_ENABLE : 0U) |
                 FRAMEBUFFER_TENSOR_PROD_RELEASE_GO);
    mmio_fence();
    start = read_cycle();
    while ((hardware_ready() & bit) != 0U ||
           (mmio_read32(FRAMEBUFFER_BASE +
                        FRAMEBUFFER_TENSOR_PROD_CONTROL) &
            FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
        if (read_cycle() - start > STREAM_MMIO_TIMEOUT)
            return -1;
    }
    return 0;
}

static void service_overlay(void)
{
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint16_t bit = (uint16_t)(UINT16_C(1) << stream);
        if ((runtime.overlay_dirty & bit) == 0U)
            continue;
        const AiDetectionResult *result =
            ai_result_manager_latest(&runtime.results, stream);
        int status = ai_overlay_try_submit(result);
        if (status > 0)
            runtime.overlay_dirty &= (uint16_t)~bit;
        else if (status < 0)
            record_error(status);
        break;
    }
}

static void finish_worker(uint32_t worker_id, int error)
{
    StreamWorker *worker = &runtime.workers[worker_id];
    AiStreamRuntimeStatus *stream = &runtime.streams[worker->stream];
    worker->release_pending = 1U;
    runtime.status.completed_job_count++;
    stream->completed_count++;
    if (error == 0) {
        stream->last_frame_id = worker->frame_id;
        stream->last_frame_valid = 1U;
    } else {
        record_error(error);
    }
}

static void progress_workers(void)
{
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        StreamWorker *worker = &runtime.workers[worker_id];
        if (worker->active == 0U)
            continue;
        if (worker->release_pending != 0U) {
            if (release_slot(worker->slot) != 0) {
                record_error(-41);
                runtime.faulted = 1U;
                continue;
            }
            runtime.held_mask &= ~(UINT32_C(1) << worker->slot);
            if (runtime.streams[worker->stream].inflight_count != 0U)
                runtime.streams[worker->stream].inflight_count--;
            runtime.status.consumed_count++;
            worker->active = 0U;
            worker->release_pending = 0U;
            continue;
        }
        AiModelFrameCompletion completion;
        int status = ai_model_backend_poll(worker_id, &completion);
        if (status == 0) {
            if (read_cycle() - worker->start_cycle > STREAM_MODEL_TIMEOUT) {
                if (ai_model_backend_abort(worker_id) == 0)
                    finish_worker(worker_id, -42);
                else {
                    runtime.faulted = 1U;
                    record_error(-43);
                }
            }
            continue;
        }
        if (status < 0 || completion.status != 0 ||
            completion.worker_id != worker_id ||
            completion.job_id != worker->job_id ||
            completion.stream_id != worker->stream ||
            completion.frame_id != worker->frame_id ||
            completion.version != worker->version ||
            completion.output_addr == 0U) {
            if (ai_model_backend_abort(worker_id) == 0)
                finish_worker(worker_id, status < 0 ? status : -44);
            else {
                runtime.faulted = 1U;
                record_error(-45);
            }
            continue;
        }
        AiDetectionResult result;
        int post_status;
        if (completion.output_desc.dtype == AI_TENSOR_DTYPE_CUSTOM) {
            result = *(const AiDetectionResult *)completion.output_addr;
            post_status = 0;
        } else {
            post_status = ai_postprocess_yolov5nu(
                (const void *)completion.output_addr, &completion.output_desc,
                &ai_postprocess_default_config, worker->job_id, worker_id,
                worker->stream, worker->frame_id, worker->timestamp,
                worker->version, &runtime.postprocess_workspace, &result);
        }
        if (post_status == 0 &&
            (result.job_id != worker->job_id ||
             result.worker_id != worker_id ||
             result.stream_id != worker->stream ||
             result.frame_id != worker->frame_id ||
             result.version != worker->version))
            post_status = -51;
        if (post_status == 0) {
            int published =
                ai_result_manager_publish(&runtime.results, &result);
            runtime.status.postprocess_count++;
            if (published > 0) {
                runtime.status.result_publish_count++;
                runtime.overlay_dirty |=
                    (uint16_t)(UINT16_C(1) << worker->stream);
            } else if (published == 0)
                runtime.status.stale_result_count++;
            else
                post_status = published;
        }
        finish_worker(worker_id, post_status);
    }
}

static uint32_t inflight_streams(void)
{
    uint32_t mask = 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (runtime.workers[worker].active != 0U)
            mask |= UINT32_C(1) << runtime.workers[worker].stream;
    return mask;
}

static void service_stale_slots(uint32_t ready)
{
    if (runtime.faulted != 0U)
        return;
    uint32_t free_ready = ready & ~runtime.held_mask;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint32_t bit0 = UINT32_C(1) << stream;
        uint32_t bit1 = UINT32_C(1) << (stream + VIDEO_CHANNEL_COUNT);
        uint32_t pair = free_ready & (bit0 | bit1);
        uint32_t stale_slot = AI_TENSOR_SLOT_INVALID;
        if (pair == (bit0 | bit1)) {
            uint32_t frame0, frame1, bytes0, bytes1;
            if (read_slot(stream, &frame0, &bytes0) != 0 ||
                read_slot(stream + VIDEO_CHANNEL_COUNT,
                          &frame1, &bytes1) != 0)
                continue;
            stale_slot = frame0 <= frame1 ? stream :
                         stream + VIDEO_CHANNEL_COUNT;
        } else if (pair != 0U &&
                   runtime.streams[stream].last_frame_valid != 0U) {
            uint32_t slot = (pair & bit0) != 0U ? stream :
                            stream + VIDEO_CHANNEL_COUNT;
            uint32_t frame, bytes;
            if (read_slot(slot, &frame, &bytes) == 0 &&
                frame <= runtime.streams[stream].last_frame_id)
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
    if (runtime.status.enabled == 0U || runtime.faulted != 0U)
        return;
    for (uint32_t worker_id = 0U;
         worker_id < AI_MODEL_WORKER_COUNT; ++worker_id) {
        StreamWorker *worker = &runtime.workers[worker_id];
        if (worker->active != 0U)
            continue;
        uint32_t busy_streams = inflight_streams();
        uint32_t selected_slot = AI_TENSOR_SLOT_INVALID;
        uint32_t selected_stream = 0U;
        uint32_t selected_frame = 0U;
        uint64_t oldest_service = UINT64_MAX;
        for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT;
             ++stream) {
            if ((busy_streams & (UINT32_C(1) << stream)) != 0U)
                continue;
            uint32_t slot = AI_TENSOR_SLOT_INVALID;
            uint32_t bit0 = UINT32_C(1) << stream;
            uint32_t bit1 = UINT32_C(1) <<
                            (stream + VIDEO_CHANNEL_COUNT);
            if ((ready & bit0 & ~runtime.held_mask) != 0U)
                slot = stream;
            if ((ready & bit1 & ~runtime.held_mask) != 0U)
                slot = stream + VIDEO_CHANNEL_COUNT;
            if (slot == AI_TENSOR_SLOT_INVALID)
                continue;
            uint32_t frame, bytes;
            if (read_slot(slot, &frame, &bytes) != 0) {
                record_error(-47);
                continue;
            }
            if (runtime.streams[stream].last_frame_valid != 0U &&
                frame <= runtime.streams[stream].last_frame_id)
                continue;
            uint64_t last_service =
                runtime.streams[stream].last_service_cycle;
            if (selected_slot == AI_TENSOR_SLOT_INVALID ||
                last_service < oldest_service ||
                (last_service == oldest_service &&
                 frame > selected_frame)) {
                selected_slot = slot;
                selected_stream = stream;
                selected_frame = frame;
                oldest_service = last_service;
            }
        }
        if (selected_slot == AI_TENSOR_SLOT_INVALID)
            return;
        uint64_t job_id = ++runtime.next_job_id;
        uint64_t timestamp = read_cycle();
        AiModelFrameRequest request = {
            .job_id = job_id,
            .worker_id = worker_id,
            .stream_id = selected_stream,
            .frame_id = selected_frame,
            .timestamp = timestamp,
            .version = selected_frame,
            .input_addr = slot_address(selected_slot),
            .input_bytes = TENSOR_MEMBER_BYTES,
            .output_addr = AI_MODEL_OUTPUT0_PHYS_BASE +
                           worker_id * AI_MODEL_OUTPUT_ARENA_BYTES,
            .output_bytes = AI_MODEL_OUTPUT_ARENA_BYTES
        };
        int submitted = ai_model_backend_submit(&request);
        if (submitted != 0) {
            record_error(submitted);
            return;
        }
        worker->active = 1U;
        worker->release_pending = 0U;
        worker->slot = selected_slot;
        worker->stream = selected_stream;
        worker->version = selected_frame;
        worker->frame_id = selected_frame;
        worker->timestamp = timestamp;
        worker->job_id = job_id;
        worker->start_cycle = timestamp;
        runtime.held_mask |= UINT32_C(1) << selected_slot;
        runtime.streams[selected_stream].inflight_count++;
        runtime.streams[selected_stream].dispatched_count++;
        runtime.streams[selected_stream].last_service_cycle = timestamp;
        runtime.status.preprocess_count++;
    }
}

void ai_batch_runtime_init(void)
{
    memset(&runtime, 0, sizeof(runtime));
    ai_result_manager_init(&runtime.results);
    ai_model_backend_init();
    runtime.next_job_id = UINT64_C(1) << 60;
}

void ai_batch_runtime_set_enabled(uint32_t enabled)
{
    if (enabled == 0U) {
        runtime.status.enabled = 0U;
        runtime.draining = 1U;
        mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL, 0U);
        mmio_fence();
        return;
    }
    if (runtime.status.enabled != 0U || runtime.draining != 0U ||
        runtime.faulted != 0U || ai_batch_runtime_is_idle() == 0U) {
        record_error(-48);
        return;
    }
    mmio_write32(FRAMEBUFFER_BASE + FRAMEBUFFER_TENSOR_PROD_CONTROL,
                 FRAMEBUFFER_TENSOR_PROD_ENABLE);
    mmio_fence();
    if ((mmio_read32(FRAMEBUFFER_BASE +
                     FRAMEBUFFER_TENSOR_PROD_CONTROL) &
         FRAMEBUFFER_TENSOR_PROD_ENABLE) == 0U) {
        record_error(-49);
        return;
    }
    runtime.status.enabled = 1U;
}

uint32_t ai_batch_runtime_is_enabled(void)
{
    return runtime.status.enabled;
}

uint32_t ai_batch_runtime_is_idle(void)
{
    if (runtime.status.enabled != 0U || runtime.draining != 0U ||
        runtime.held_mask != 0U)
        return 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (runtime.workers[worker].active != 0U)
            return 0U;
    return hardware_ready() == 0U &&
           mmio_read32(FRAMEBUFFER_BASE +
                       FRAMEBUFFER_TENSOR_PROD_WRITING) == 0U;
}

void ai_batch_runtime_poll(void)
{
    progress_workers();
    service_overlay();
    if (runtime.status.enabled == 0U && runtime.draining == 0U)
        return;
    uint32_t ready = hardware_ready();
    if (runtime.draining != 0U) {
        uint32_t releasable = ready & ~runtime.held_mask;
        if (releasable != 0U) {
            for (uint32_t slot = 0U; slot < 32U; ++slot)
                if ((releasable & (UINT32_C(1) << slot)) != 0U) {
                    if (release_slot(slot) != 0)
                        record_error(-50);
                    break;
                }
            return;
        }
        if (runtime.held_mask == 0U &&
            mmio_read32(FRAMEBUFFER_BASE +
                        FRAMEBUFFER_TENSOR_PROD_WRITING) == 0U)
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

void ai_batch_runtime_print_status(void)
{
    console_puts("AI RT stream enable/drain/fault held/ready/writing/error=");
    console_put_u32(runtime.status.enabled);
    console_putc('/');
    console_put_u32(runtime.draining);
    console_putc('/');
    console_put_u32(runtime.faulted);
    console_putc(' ');
    console_put_hex32(runtime.held_mask);
    console_putc('/');
    console_put_hex32(hardware_ready());
    console_putc('/');
    console_put_hex32(mmio_read32(FRAMEBUFFER_BASE +
                                 FRAMEBUFFER_TENSOR_PROD_WRITING));
    console_putc('/');
    console_put_hex32(mmio_read32(FRAMEBUFFER_BASE +
                                 FRAMEBUFFER_TENSOR_PROD_ERROR));
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
    console_puts(" last_err=");
    console_put_u32((uint32_t)(runtime.status.last_error < 0 ?
                    -runtime.status.last_error : runtime.status.last_error));
    console_puts("\r\n");
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        AiStreamRuntimeStatus *status = &runtime.streams[stream];
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
        const AiDetectionResult *result =
            ai_result_manager_latest(&runtime.results, stream);
        console_puts(" det=");
        if (result == 0)
            console_puts("none");
        else
            console_put_u32(result->count);
        console_puts("\r\n");
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
