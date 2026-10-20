#include "ai/runtime/core/rt_internal.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

void rt_record_error(AiRtCore *rt, int error)
{
    rt->status.error_count++;
    rt->status.last_error = error;
}

uint32_t rt_post_job_count(AiRtCore *rt)
{
    uint32_t count = 0U;
    for (uint32_t index = 0U; index < AI_MODEL_POSTPROCESS_CAPACITY;
         ++index)
        if (rt->post_jobs[index].active != 0U)
            count++;
    return count;
}

void rt_core_init(AiRtCore *rt)
{
    if (rt->initialized && !rt_state_is_idle(rt)) {
        rt_control_fault(&rt->control);
        rt_record_error(rt, -59);
        return;
    }
    memset(rt, 0, sizeof(*rt));
    rt_tensor_manager_init(&rt->tensors);
    rt->initialized = 1U;
    ai_result_manager_init(&rt->results);
    rt_backend_init(&rt->backend);
    rt->next_job_id = UINT64_C(1) << 60;
}
