#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "ai_batch_runtime.h"
#include "ai_model_backend.h"
#include "ai_overlay.h"
#include "ai_postprocess.h"
#include "ai_tensor_slot_pool.h"
#include "mmio.h"
#include "platform.h"

uint64_t test_cycle;
static uint32_t control, ready, writing, release_mask, selected_slot;
static uint32_t frame[32], bytes[32], release_count, overlay_count;
static uint32_t version[32];
static uint64_t capture_timestamp[32];
static uint32_t overlay_clear_count;
static AiModelFrameRequest requests[AI_MODEL_WORKER_COUNT];
static uint32_t backend_running[AI_MODEL_WORKER_COUNT];
static uint32_t compute_allowed[AI_MODEL_WORKER_COUNT];
static uint32_t result_allowed[AI_MODEL_WORKER_COUNT];
static uint32_t submit_count;
static uint32_t corrupt_completion;
static uint32_t admission_mask, admission_limit;
typedef struct {
    uint32_t active;
    AiModelFrameRequest request;
    AiDetectionResult result;
} MockPostCompletion;
static MockPostCompletion pending[AI_MODEL_RESULT_QUEUE_CAPACITY];

uint32_t mmio_read32(uintptr_t address)
{
    assert(address >= FRAMEBUFFER_BASE);
    switch (address - FRAMEBUFFER_BASE) {
    case FRAMEBUFFER_TENSOR_PROD_CONTROL: return control;
    case FRAMEBUFFER_TENSOR_PROD_READY: return ready;
    case FRAMEBUFFER_TENSOR_PROD_WRITING: return writing;
    case FRAMEBUFFER_TENSOR_PROD_ERROR: return 0U;
    case FRAMEBUFFER_TENSOR_PROD_FRAME: return frame[selected_slot];
    case FRAMEBUFFER_TENSOR_PROD_BYTES: return bytes[selected_slot];
    case FRAMEBUFFER_TENSOR_PROD_TIME_LO:
        return (uint32_t)capture_timestamp[selected_slot];
    case FRAMEBUFFER_TENSOR_PROD_TIME_HI:
        return (uint32_t)(capture_timestamp[selected_slot] >> 32);
    case FRAMEBUFFER_TENSOR_PROD_VERSION: return version[selected_slot];
    case FRAMEBUFFER_TENSOR_PROD_STREAM:
        return selected_slot % VIDEO_CHANNEL_COUNT;
    case FRAMEBUFFER_TENSOR_PROD_ADDR:
        return (selected_slot < VIDEO_CHANNEL_COUNT ?
                TENSOR_ARENA0_PHYS_BASE : TENSOR_ARENA1_PHYS_BASE) +
               (selected_slot % VIDEO_CHANNEL_COUNT) * TENSOR_MEMBER_STRIDE;
    case FRAMEBUFFER_TENSOR_PROD_STATE:
        return (ready & (UINT32_C(1) << selected_slot)) != 0U ?
               AI_TENSOR_SLOT_READY : AI_TENSOR_SLOT_FREE;
    case FRAMEBUFFER_TENSOR_PROD_ERROR_CODE: return 0U;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK: return admission_mask;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT: return admission_limit;
    default: assert(0); return 0U;
    }
}

void mmio_write32(uintptr_t address, uint32_t value)
{
    assert(address >= FRAMEBUFFER_BASE);
    switch (address - FRAMEBUFFER_BASE) {
    case FRAMEBUFFER_TENSOR_PROD_CONTROL:
        if ((value & FRAMEBUFFER_TENSOR_PROD_RELEASE_GO) != 0U) {
            assert((ready & release_mask) == release_mask);
            ready &= ~release_mask;
            release_count++;
        }
        control = value & FRAMEBUFFER_TENSOR_PROD_ENABLE;
        break;
    case FRAMEBUFFER_TENSOR_PROD_RELEASE:
        release_mask = value;
        break;
    case FRAMEBUFFER_TENSOR_PROD_INDEX:
        assert(value < 32U);
        selected_slot = value;
        break;
    case FRAMEBUFFER_PRE_ARENA0_BASE:
        assert(value == TENSOR_ARENA0_PHYS_BASE);
        break;
    case FRAMEBUFFER_PRE_ARENA1_BASE:
        assert(value == TENSOR_ARENA1_PHYS_BASE);
        break;
    case FRAMEBUFFER_PRE_MEMBER_STRIDE:
        assert(value == TENSOR_MEMBER_STRIDE);
        break;
    case FRAMEBUFFER_PRE_MEMBER_BYTES:
        assert(value == TENSOR_MEMBER_BYTES);
        break;
    case FRAMEBUFFER_PRE_FORMAT:
        assert(value == FRAMEBUFFER_PRE_FORMAT_640X480);
        break;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK:
        admission_mask = value;
        break;
    case FRAMEBUFFER_TENSOR_PROD_ADMISSION_LIMIT:
        admission_limit = value;
        break;
    default: assert(0);
    }
}

void mmio_fence(void) {}
void console_puts(const char *value) { (void)value; }
void console_putc(char value) { (void)value; }
void console_put_u32(uint32_t value) { (void)value; }
void console_put_hex32(uint32_t value) { (void)value; }
void console_put_hex64(uint64_t value) { (void)value; }

int ai_overlay_try_submit(const AiDetectionResult *result)
{
    assert(result != NULL);
    if (result->count == 0U)
        overlay_clear_count++;
    overlay_count++;
    return 1;
}

const AiPostprocessConfig ai_postprocess_default_config = {0};
int ai_postprocess_yolov5nu(const void *tensor,
                            const AiTensorDesc *desc,
                            const AiPostprocessConfig *config,
                            uint64_t job_id, uint32_t worker_id,
                            uint32_t stream_id, uint64_t frame_id,
                            uint64_t timestamp, uint32_t version,
                            AiPostprocessWorkspace *workspace,
                            AiDetectionResult *result)
{
    (void)tensor; (void)desc; (void)config; (void)job_id;
    (void)worker_id; (void)stream_id; (void)frame_id;
    (void)timestamp; (void)version; (void)workspace; (void)result;
    assert(0);
    return -1;
}

void ai_model_backend_init(void)
{
    memset(requests, 0, sizeof(requests));
    memset(backend_running, 0, sizeof(backend_running));
    memset(pending, 0, sizeof(pending));
}

int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    uint32_t worker = request->worker_id;
    assert(worker < AI_MODEL_WORKER_COUNT && !backend_running[worker]);
    assert(request->input_bytes == TENSOR_MEMBER_BYTES);
    uint32_t matched_slot = UINT32_MAX;
    for (uint32_t slot = 0U; slot < 32U; ++slot)
        if ((ready & (UINT32_C(1) << slot)) != 0U &&
            frame[slot] == request->frame_id &&
            version[slot] == request->version)
            matched_slot = slot;
    assert(matched_slot != UINT32_MAX);
    assert(request->input_addr ==
           (matched_slot < VIDEO_CHANNEL_COUNT ?
            TENSOR_ARENA0_PHYS_BASE : TENSOR_ARENA1_PHYS_BASE) +
           (matched_slot % VIDEO_CHANNEL_COUNT) * TENSOR_MEMBER_STRIDE);
    requests[worker] = *request;
    backend_running[worker] = 1U;
    submit_count++;
    return 0;
}

int ai_model_backend_poll_compute(uint32_t worker,
                                  AiModelComputeCompletion *completion)
{
    assert(worker < AI_MODEL_WORKER_COUNT && backend_running[worker]);
    if (compute_allowed[worker] == 0U)
        return 0;
    compute_allowed[worker] = 0U;
    backend_running[worker] = 0U;
    AiModelFrameRequest *request = &requests[worker];
    memset(completion, 0, sizeof(*completion));
    completion->job_id = request->job_id;
    completion->worker_id = worker;
    completion->stream_id = request->stream_id;
    completion->frame_id = request->frame_id;
    completion->version = request->version;
    uint32_t slot;
    for (slot = 0U; slot < AI_MODEL_RESULT_QUEUE_CAPACITY; ++slot)
        if (pending[slot].active == 0U)
            break;
    assert(slot < AI_MODEL_RESULT_QUEUE_CAPACITY);
    pending[slot].active = 1U;
    pending[slot].request = *request;
    pending[slot].result.job_id = request->job_id;
    pending[slot].result.stream_id = request->stream_id;
    pending[slot].result.frame_id = request->frame_id;
    pending[slot].result.worker_id = worker;
    pending[slot].result.version = request->version;
    pending[slot].result.count = 1U;
    return 1;
}

int ai_model_backend_poll_result(AiModelFrameCompletion *completion)
{
    for (uint32_t slot = 0U; slot < AI_MODEL_RESULT_QUEUE_CAPACITY; ++slot) {
        MockPostCompletion *post = &pending[slot];
        uint32_t worker = post->request.worker_id;
        if (post->active == 0U || result_allowed[worker] == 0U)
            continue;
        result_allowed[worker]--;
        memset(completion, 0, sizeof(*completion));
        completion->job_id = post->request.job_id;
        completion->worker_id = worker;
        completion->stream_id = post->request.stream_id;
        completion->frame_id = post->request.frame_id;
        if (corrupt_completion != 0U) {
            completion->frame_id++;
            corrupt_completion = 0U;
        }
        completion->version = post->request.version;
        completion->output_addr = (uintptr_t)&post->result;
        completion->output_desc.dtype = AI_TENSOR_DTYPE_CUSTOM;
        post->active = 0U;
        return 1;
    }
    return 0;
}

uint32_t ai_model_backend_is_idle(void)
{
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (backend_running[worker] != 0U)
            return 0U;
    for (uint32_t slot = 0U; slot < AI_MODEL_RESULT_QUEUE_CAPACITY; ++slot)
        if (pending[slot].active != 0U)
            return 0U;
    return 1U;
}

int ai_model_backend_abort(uint32_t worker)
{
    assert(worker < AI_MODEL_WORKER_COUNT);
    return backend_running[worker] != 0U ? -2 : 0;
}

static void publish_slot(uint32_t slot, uint32_t source_frame)
{
    assert(slot < 32U);
    frame[slot] = source_frame;
    version[slot] = source_frame;
    capture_timestamp[slot] = UINT64_C(0x1234000000000000) + source_frame;
    bytes[slot] = TENSOR_MEMBER_BYTES;
    ready |= UINT32_C(1) << slot;
}

int main(void)
{
    ai_batch_runtime_init();
    assert(ai_batch_runtime_is_idle() != 0U);
    ai_batch_runtime_set_enabled(1U);
    assert(ai_batch_runtime_is_enabled() != 0U);
    assert(admission_mask == CAMERA_PRESENT_MASK && admission_limit == 1U);
    publish_slot(0U, 10U);
    publish_slot(16U, 12U);
    publish_slot(1U, 15U);
    ai_batch_runtime_poll();
    assert(release_count == 1U && (ready & 1U) == 0U);
    assert(submit_count == 2U);
    assert(requests[0].stream_id == 1U && requests[0].frame_id == 15U);
    assert(requests[1].stream_id == 0U && requests[1].frame_id == 12U);
    assert(requests[0].version == 15U &&
           requests[0].timestamp == UINT64_C(0x123400000000000f));
    assert((ready & ((UINT32_C(1) << 16) | (UINT32_C(1) << 1))) ==
           ((UINT32_C(1) << 16) | (UINT32_C(1) << 1)));

    publish_slot(17U, 16U);
    publish_slot(2U, 18U);
    ai_batch_runtime_poll();
    assert(submit_count == 2U); /* One in-flight job per stream. */
    assert(release_count == 1U); /* Input remains owned during compute. */

    /* A compute completion does not wait for its PPU result. */
    compute_allowed[0] = 1U;
    ai_batch_runtime_poll();
    assert(release_count == 2U && submit_count == 3U);
    assert(ai_batch_runtime_latest_result(1U) == NULL);
    assert(requests[0].stream_id == 2U && requests[0].frame_id == 18U);

    /* worker0 now computes stream2 while its old stream1 result is pending. */
    result_allowed[0] = 1U;
    ai_batch_runtime_poll();
    assert(ai_batch_runtime_latest_result(1U)->frame_id == 15U);
    assert(backend_running[0] != 0U);

    ai_batch_runtime_set_enabled(0U);
    assert(ai_batch_runtime_is_idle() == 0U);
    compute_allowed[0] = 1U;
    compute_allowed[1] = 1U;
    ai_batch_runtime_poll();
    result_allowed[0] = 1U;
    result_allowed[1] = 1U;
    for (uint32_t poll = 0U; poll < 12U; ++poll)
        ai_batch_runtime_poll();
    assert(ai_batch_runtime_is_idle() != 0U);
    assert(ready == 0U && release_count == 5U);
    assert(overlay_count >= 3U);
    AiBatchRuntimeStatus status;
    ai_batch_runtime_get_status(&status);
    assert(status.completed_job_count == 3U &&
           status.result_publish_count == 3U &&
           status.error_count == 0U);

    test_cycle += SOC_CLOCK_HZ / 10U + 1U;
    ai_batch_runtime_poll();
    assert(ai_batch_runtime_latest_result(0U) == NULL);
    assert(ai_batch_runtime_latest_result(1U) == NULL);
    ai_batch_runtime_poll();
    assert(overlay_clear_count >= 2U);

    /* Corrupt final-result metadata after a valid compute completion. */
    ai_batch_runtime_set_enabled(1U);
    publish_slot(0U, 20U);
    ai_batch_runtime_poll();
    assert(submit_count == 4U && (ready & 1U) != 0U);
    compute_allowed[0] = 1U;
    ai_batch_runtime_poll();
    ai_batch_runtime_poll();
    assert((ready & 1U) == 0U);
    corrupt_completion = 1U;
    result_allowed[0] = 1U;
    ai_batch_runtime_poll();
    ai_batch_runtime_set_enabled(0U);
    ai_batch_runtime_poll();
    assert(ai_batch_runtime_is_idle() != 0U);
    ai_batch_runtime_get_status(&status);
    assert(status.error_count == 1U &&
           status.result_publish_count == 3U);

    /* Streams 2 and 3 retain the earliest deadline and win EDF. */
    ai_batch_runtime_set_enabled(1U);
    publish_slot(0U, 21U);
    publish_slot(2U, 30U);
    publish_slot(3U, 40U);
    ai_batch_runtime_poll();
    assert(submit_count == 6U);
    assert(requests[0].stream_id == 3U && requests[0].frame_id == 40U);
    assert(requests[1].stream_id == 2U && requests[1].frame_id == 30U);
    ai_batch_runtime_set_enabled(0U);
    compute_allowed[0] = 1U;
    compute_allowed[1] = 1U;
    ai_batch_runtime_poll();
    result_allowed[0] = 1U;
    result_allowed[1] = 1U;
    for (uint32_t poll = 0U; poll < 12U; ++poll)
        ai_batch_runtime_poll();
    assert(ai_batch_runtime_is_idle() != 0U);
    printf("AI_BATCH_RUNTIME_STREAM=PASS submit=%u release=%u\n",
           submit_count, release_count);
    return 0;
}
