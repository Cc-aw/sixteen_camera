#include "ai/backend/adapters/rt_backend_compat.h"

_Static_assert(AI_RT_BACKEND_FAULT_HELD == AI_MODEL_SUBMIT_FAULT_HELD,
               "uncertain submit status must retain its original meaning");

int rt_backend_compat_progress(AiRtBackendPhase phase, uint32_t worker,
                               AiRtBackendPayload *payload)
{
    if (!payload)
        return -1;
    if (phase == AI_RT_BACKEND_COMPUTE)
        return ai_model_backend_poll_compute(worker, &payload->compute);
    if (phase == AI_RT_BACKEND_RESULT)
        return ai_model_backend_poll_result(&payload->result);
    return -1;
}
