#include "ai/runtime/core/rt_internal.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

uint32_t rt_has_no_owners(AiRtCore *rt)
{
    if (rt->tensors.held != 0U || rt_post_job_count(rt) != 0U ||
        rt_backend_is_idle(&rt->backend) == 0U)
        return 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (rt->workers[worker].active != 0U)
            return 0U;
    return 1U;
}

void rt_state_set_enabled(AiRtCore *rt, uint32_t enabled)
{
    if (enabled == 0U) {
        rt->admission_restart = 0U;
        rt->status.enabled = 0U;
        rt_control_stop(&rt->control);
        if (ai_tensor_device_quiesce() != 0) {
            rt_record_error(rt, -60);
            rt_control_fault(&rt->control);
        }
        return;
    }
    if (rt_control_enabled(&rt->control) != 0U || rt_control_draining(&rt->control) != 0U ||
        rt_control_faulted(&rt->control) != 0U) {
        rt_record_error(rt, -48);
        return;
    }
    /* Preserve startup cleanup of unowned ERROR slots.  An ERROR-only
     * device is not idle, but it can be acknowledged before admission. */
    if (!rt_state_is_idle(rt) &&
        (!rt_has_no_owners(rt) || rt_tensor_ready(rt) != 0U ||
         rt_tensor_writing(rt) != 0U)) {
        rt_record_error(rt, -48);
        return;
    }
    uint32_t error_mask = rt_tensor_error(rt);
    for (uint32_t slot = 0U; slot < AI_TENSOR_SLOT_COUNT; ++slot) {
        if ((error_mask & (UINT32_C(1) << slot)) != 0U &&
            rt_tensor_release_slot(rt, slot) != 0) {
            rt_record_error(rt, -50);
            return;
        }
    }
    uint32_t input_mask = ai_tensor_device_active_inputs();
    if (ai_tensor_device_enable(input_mask,
                                TENSOR_PRODUCTION_ADMISSION_LIMIT) != 0) {
        rt_record_error(rt, -49);
        return;
    }
    uint64_t first_deadline = platform_read_cycle() + STREAM_TARGET_PERIOD;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream)
        if (rt->streams[stream].next_deadline == 0U)
            rt->streams[stream].next_deadline = first_deadline;
    (void)rt_control_start(&rt->control);
    rt->admission_mask = input_mask;
    rt->admission_restart = 0U;
    rt->status.enabled = 1U;
}

uint32_t rt_state_is_idle(AiRtCore *rt)
{
    if (rt_control_enabled(&rt->control) != 0U || rt_control_draining(&rt->control) != 0U ||
        !rt_has_no_owners(rt))
        return 0U;
    return rt_tensor_ready(rt) == 0U && rt_tensor_error(rt) == 0U &&
           rt_tensor_writing(rt) == 0U;
}

void rt_state_poll_admission(AiRtCore *rt)
{
    uint32_t ready;
    if (rt_control_enabled(&rt->control) == 0U && rt_control_draining(&rt->control) == 0U)
        return;
    /* Mask writes are accepted only with production disabled. Drain existing
     * jobs before reopening admission; never abandon Tensor or Head owners. */
    if (rt_control_enabled(&rt->control) != 0U &&
        !rt_control_faulted(&rt->control) &&
        ai_tensor_device_active_inputs() != rt->admission_mask) {
        rt_state_set_enabled(rt, 0U);
        rt->admission_restart = 1U;
    }
    ready = rt_tensor_ready(rt);
    rt_tensor_track_ready(rt, ready);
    if (rt_control_draining(&rt->control) != 0U) {
        if (rt_tensor_drain_one(rt, ready))
            return;
        if (rt->tensors.held == 0U && rt_post_job_count(rt) == 0U &&
            rt_backend_is_idle(&rt->backend) != 0U &&
            rt_tensor_writing(rt) == 0U) {
            rt_control_drained(&rt->control);
            if (rt->admission_restart && !rt_control_faulted(&rt->control))
                rt_state_set_enabled(rt, 1U);
        }
        return;
    }
    if (rt_control_faulted(&rt->control) != 0U) {
        rt_state_set_enabled(rt, 0U);
        return;
    }
    rt_tensor_service_stale(rt, ready);
    rt_dispatch_jobs(rt, rt_tensor_ready(rt));
}
