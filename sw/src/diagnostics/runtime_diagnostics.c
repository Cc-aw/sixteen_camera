#include "diagnostics/runtime_diagnostics.h"
#include "ai/runtime/core/rt_internal.h"
#include "ai/runtime/rt_debug.h"
#include "platform/console.h"

void rt_diagnostics_print_frame_profiles(void)
{
    AiRtCore *runtime = rt_core_instance();
    console_puts("AI FRAME PROFILE count/clock_hz=");
    console_put_u32(runtime->profile_count);
    console_putc('/');
    console_put_u32(SOC_CLOCK_HZ);
    console_puts("\r\n");
    uint32_t oldest = (runtime->profile_head + STREAM_PROFILE_CAPACITY -
                       runtime->profile_count) % STREAM_PROFILE_CAPACITY;
    for (uint32_t item = 0U; item < runtime->profile_count; ++item) {
        const AiRtProfileRecord *record =
            &runtime->profiles[(oldest + item) % STREAM_PROFILE_CAPACITY];
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

void rt_diagnostics_print_status(void)
{
    AiRtCore *runtime = rt_core_instance();
    uint32_t hardware_error = ai_tensor_device_error();
    console_puts("AI RT stream enable/drain/fault held/ready/writing/error=");
    console_put_u32(runtime->status.enabled);
    console_putc('/');
    console_put_u32(rt_control_draining(&runtime->control));
    console_putc('/');
    console_put_u32(rt_control_faulted(&runtime->control));
    console_putc(' ');
    console_put_hex32(runtime->tensors.held);
    console_putc('/');
    console_put_hex32(rt_tensor_ready(runtime));
    console_putc('/');
    console_put_hex32(rt_tensor_writing(runtime));
    console_putc('/');
    console_put_hex32(hardware_error);
    console_puts(" jobs/done/post/pub/stale/err=");
    console_put_u32(runtime->status.preprocess_count);
    console_putc('/');
    console_put_u32(runtime->status.completed_job_count);
    console_putc('/');
    console_put_u32(runtime->status.postprocess_count);
    console_putc('/');
    console_put_u32(runtime->status.result_publish_count);
    console_putc('/');
    console_put_u32(runtime->status.stale_result_count);
    console_putc('/');
    console_put_u32(runtime->status.error_count);
    console_puts(" post_inflight=");
    console_put_u32(rt_post_job_count(runtime));
    console_puts(" last_err=");
    console_put_u32((uint32_t)(runtime->status.last_error < 0 ?
                    -runtime->status.last_error : runtime->status.last_error));
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
        AiStreamRuntimeStatus *status = &runtime->streams[stream];
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
            ai_result_manager_latest(&runtime->results, stream);
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
    if (rt_control_faulted(&runtime->control)) {
        AiRtResourceSnapshot resources; rt_get_resources(&resources);
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
