#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "ai_batch_runtime.h"
#include "ai_model_backend.h"
#include "ai_overlay.h"
#include "ai_postprocess.h"
#include "mmio.h"
#include "platform.h"

uint64_t test_cycle;
static uint32_t control, ready, writing, release_mask, selected_slot;
static uint32_t frame[32], bytes[32], release_count, overlay_count;
static AiModelFrameRequest requests[AI_MODEL_WORKER_COUNT];
static AiDetectionResult results[AI_MODEL_WORKER_COUNT];
static uint32_t backend_running[AI_MODEL_WORKER_COUNT];
static uint32_t complete_allowed[AI_MODEL_WORKER_COUNT];
static uint32_t submit_count;
static uint32_t corrupt_completion;

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
}

int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    uint32_t worker = request->worker_id;
    assert(worker < AI_MODEL_WORKER_COUNT && !backend_running[worker]);
    assert(request->input_bytes == TENSOR_MEMBER_BYTES);
    assert(request->input_addr ==
           (request->frame_id == 15U ?
            TENSOR_ARENA0_PHYS_BASE + TENSOR_MEMBER_STRIDE :
            request->frame_id == 12U ?
            TENSOR_ARENA1_PHYS_BASE :
            request->frame_id == 20U ?
            TENSOR_ARENA0_PHYS_BASE :
            TENSOR_ARENA1_PHYS_BASE + TENSOR_MEMBER_STRIDE));
    requests[worker] = *request;
    backend_running[worker] = 1U;
    submit_count++;
    return 0;
}

int ai_model_backend_poll(uint32_t worker,
                          AiModelFrameCompletion *completion)
{
    assert(worker < AI_MODEL_WORKER_COUNT && backend_running[worker]);
    if (complete_allowed[worker] == 0U)
        return 0;
    complete_allowed[worker] = 0U;
    backend_running[worker] = 0U;
    AiModelFrameRequest *request = &requests[worker];
    memset(completion, 0, sizeof(*completion));
    completion->job_id = request->job_id;
    completion->worker_id = worker;
    completion->stream_id = request->stream_id;
    completion->frame_id = request->frame_id;
    if (corrupt_completion != 0U) {
        completion->frame_id++;
        corrupt_completion = 0U;
    }
    completion->version = request->version;
    results[worker].job_id = request->job_id;
    results[worker].stream_id = request->stream_id;
    results[worker].frame_id = request->frame_id;
    results[worker].worker_id = worker;
    results[worker].version = request->version;
    results[worker].count = 0U;
    completion->output_addr = (uintptr_t)&results[worker];
    completion->output_desc.dtype = AI_TENSOR_DTYPE_CUSTOM;
    return 1;
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
    bytes[slot] = TENSOR_MEMBER_BYTES;
    ready |= UINT32_C(1) << slot;
}

int main(void)
{
    ai_batch_runtime_init();
    assert(ai_batch_runtime_is_idle() != 0U);
    ai_batch_runtime_set_enabled(1U);
    assert(ai_batch_runtime_is_enabled() != 0U);
    publish_slot(0U, 10U);
    publish_slot(16U, 12U);
    publish_slot(1U, 15U);
    ai_batch_runtime_poll();
    assert(release_count == 1U && (ready & 1U) == 0U);
    assert(submit_count == 2U);
    assert(requests[0].stream_id == 1U && requests[0].frame_id == 15U);
    assert(requests[1].stream_id == 0U && requests[1].frame_id == 12U);
    assert((ready & ((UINT32_C(1) << 16) | (UINT32_C(1) << 1))) ==
           ((UINT32_C(1) << 16) | (UINT32_C(1) << 1)));

    publish_slot(17U, 16U);
    ai_batch_runtime_poll();
    assert(submit_count == 2U); /* One in-flight job per stream. */
    assert(release_count == 1U); /* Input must remain owned while running. */

    complete_allowed[0] = 1U;
    ai_batch_runtime_poll();
    assert(release_count == 1U);
    assert(ai_batch_runtime_latest_result(1U)->frame_id == 15U);
    ai_batch_runtime_poll();
    assert(release_count == 2U && submit_count == 3U);
    assert(requests[0].frame_id == 16U);

    ai_batch_runtime_set_enabled(0U);
    assert(ai_batch_runtime_is_idle() == 0U);
    complete_allowed[0] = 1U;
    complete_allowed[1] = 1U;
    for (uint32_t poll = 0U; poll < 12U; ++poll)
        ai_batch_runtime_poll();
    assert(ai_batch_runtime_is_idle() != 0U);
    assert(ready == 0U && release_count == 4U);
    assert(overlay_count >= 2U);
    AiBatchRuntimeStatus status;
    ai_batch_runtime_get_status(&status);
    assert(status.completed_job_count == 3U &&
           status.result_publish_count == 3U &&
           status.error_count == 0U);
    ai_batch_runtime_set_enabled(1U);
    publish_slot(0U, 20U);
    ai_batch_runtime_poll();
    assert(submit_count == 4U && (ready & 1U) != 0U);
    corrupt_completion = 1U;
    complete_allowed[0] = 1U;
    ai_batch_runtime_poll();
    assert((ready & 1U) != 0U);
    ai_batch_runtime_poll();
    assert((ready & 1U) == 0U);
    ai_batch_runtime_set_enabled(0U);
    ai_batch_runtime_poll();
    assert(ai_batch_runtime_is_idle() != 0U);
    ai_batch_runtime_get_status(&status);
    assert(status.error_count == 1U &&
           status.result_publish_count == 3U);
    printf("AI_BATCH_RUNTIME_STREAM=PASS submit=%u release=%u\n",
           submit_count, release_count);
    return 0;
}
