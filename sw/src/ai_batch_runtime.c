#include "ai_batch_runtime.h"

#include "ai_preprocess.h"
#include "ai_model_backend.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"

enum {
    AI_RUNTIME_IDLE = 0,
    AI_RUNTIME_PREPROCESS = 1,
    AI_RUNTIME_RELEASE = 2
};

#define AI_MODEL_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(5))

typedef struct {
    AiBatchContext contexts[2];
    AiFrameSnapshot pending_snapshot;
    uint64_t pending_admit_cycle;
    uint16_t release_pending_mask;
    uint32_t pending_valid;
    AiBatchRuntimeStatus status;
} AiBatchRuntime;

static AiBatchRuntime runtime;

static void clear_context(AiBatchContext *context, uint32_t arena)
{
    context->arena = arena;
    context->tensor_base = arena == 0U ? TENSOR_ARENA0_PHYS_BASE :
                                        TENSOR_ARENA1_PHYS_BASE;
    context->batch_id = 0U;
    context->valid_mask = 0U;
    context->fresh_mask = 0U;
    context->admit_cycle = 0U;
    context->preprocess_end_cycle = 0U;
    context->compute_start_cycle = 0U;
    context->compute_end_cycle = 0U;
    context->postprocess_end_cycle = 0U;
    context->preprocess_cycles = 0U;
    context->preprocess_read_bytes = 0U;
    context->preprocess_write_bytes = 0U;
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

static void progress_consumer(AiBatchContext *context,
                              uint32_t *backend_busy)
{
    switch (context->state) {
    case AI_BATCH_READY: {
        if (*backend_busy != 0U)
            break;
        AiModelRequest request = {
            .batch_id = context->batch_id,
            .input_tensor_base = context->tensor_base,
            .input_tensor_bytes = TENSOR_MEMBER_BYTES * VIDEO_CHANNEL_COUNT,
            .valid_mask = context->valid_mask,
            .fresh_mask = context->fresh_mask,
            .batch_size = VIDEO_CHANNEL_COUNT
        };
        int submit_status = ai_model_backend_submit(&request);
        if (submit_status != 0) {
            context->error = submit_status;
            runtime.status.last_error = submit_status;
            runtime.status.error_count++;
            context->state = AI_BATCH_DONE;
            break;
        }
        *backend_busy = 1U;
        context->compute_start_cycle = read_cycle();
        context->state = AI_BATCH_RUNNING;
        break;
    }
    case AI_BATCH_RUNNING: {
        int poll_status = ai_model_backend_poll();
        if (poll_status < 0 ||
            read_cycle() - context->compute_start_cycle >
                AI_MODEL_TIMEOUT_CYCLES) {
            ai_model_backend_abort();
            *backend_busy = 0U;
            context->error = poll_status < 0 ? poll_status : -10;
            runtime.status.last_error = context->error;
            runtime.status.error_count++;
            context->state = AI_BATCH_DONE;
        } else if (poll_status > 0) {
            *backend_busy = 0U;
            context->compute_end_cycle = read_cycle();
            context->state = AI_BATCH_POSTPROCESS;
        }
        break;
    }
    case AI_BATCH_POSTPROCESS:
        context->postprocess_end_cycle = read_cycle();
        context->state = AI_BATCH_DONE;
        break;
    case AI_BATCH_DONE:
        if (ai_preprocess_recycle(UINT32_C(1) << context->arena) == 0) {
            runtime.status.consumed_count++;
            runtime.status.last_batch_id = context->batch_id;
            runtime.status.last_valid_mask = context->valid_mask;
            runtime.status.last_fresh_mask = context->fresh_mask;
            runtime.status.last_preprocess_cycles =
                context->preprocess_cycles;
            clear_context(context, context->arena);
        } else {
            runtime.status.recycle_error_count++;
            runtime.status.error_count++;
        }
        break;
    default:
        break;
    }
}

void ai_batch_runtime_init(void)
{
    runtime.pending_valid = 0U;
    runtime.pending_admit_cycle = 0U;
    runtime.release_pending_mask = 0U;
    runtime.status.enabled = 0U;
    runtime.status.phase = AI_RUNTIME_IDLE;
    runtime.status.snapshot_count = 0U;
    runtime.status.preprocess_count = 0U;
    runtime.status.consumed_count = 0U;
    runtime.status.error_count = 0U;
    runtime.status.release_retry_count = 0U;
    runtime.status.recycle_error_count = 0U;
    runtime.status.last_error = 0;
    runtime.status.last_batch_id = 0U;
    runtime.status.last_valid_mask = 0U;
    runtime.status.last_fresh_mask = 0U;
    runtime.status.last_preprocess_cycles = 0U;
    clear_context(&runtime.contexts[0], 0U);
    clear_context(&runtime.contexts[1], 1U);
    ai_model_backend_init();
}

void ai_batch_runtime_set_enabled(uint32_t enabled)
{
    runtime.status.enabled = enabled != 0U ? 1U : 0U;
}

uint32_t ai_batch_runtime_is_enabled(void)
{
    return runtime.status.enabled;
}

uint32_t ai_batch_runtime_is_idle(void)
{
    return runtime.status.phase == AI_RUNTIME_IDLE &&
           runtime.pending_valid == 0U &&
           runtime.release_pending_mask == 0U &&
           runtime.contexts[0].state == AI_BATCH_FREE &&
           runtime.contexts[1].state == AI_BATCH_FREE;
}

void ai_batch_runtime_poll(void)
{
    AiPreprocessResult result;
    uint32_t backend_busy =
        runtime.contexts[0].state == AI_BATCH_RUNNING ||
        runtime.contexts[1].state == AI_BATCH_RUNNING;

    for (uint32_t arena = 0U; arena < 2U; ++arena)
        progress_consumer(&runtime.contexts[arena], &backend_busy);

    if (runtime.release_pending_mask != 0U) {
        if (ai_frame_snapshot_release(runtime.release_pending_mask) != 0) {
            runtime.status.release_retry_count++;
            return;
        }
        runtime.release_pending_mask = 0U;
        runtime.status.phase = AI_RUNTIME_IDLE;
    }

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
        runtime.release_pending_mask = runtime.pending_snapshot.valid_mask;
        runtime.pending_valid = 0U;
        runtime.status.phase = AI_RUNTIME_RELEASE;
        return;
    }

    if (runtime.status.enabled == 0U)
        return;
    if (runtime.contexts[0].state != AI_BATCH_FREE &&
        runtime.contexts[1].state != AI_BATCH_FREE)
        return;

    runtime.pending_admit_cycle = read_cycle();
    int snapshot_status = ai_frame_snapshot_acquire(
        &runtime.pending_snapshot);
    if (snapshot_status != 0) {
        runtime.status.error_count++;
        return;
    }
    runtime.pending_valid = 1U;
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
    console_puts(" snap/pre/done/err=");
    console_put_u32(runtime.status.snapshot_count);
    console_putc('/');
    console_put_u32(runtime.status.preprocess_count);
    console_putc('/');
    console_put_u32(runtime.status.consumed_count);
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
    console_puts("\r\n");
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
