#include "ai/backend/rt_backend.h"
#include "ai/backend/ai_model_backend.h"
static AiRtBackend backend;
void r4a_backend_init(void) { rt_backend_init(&backend); }
int r4a_backend_submit(const AiModelFrameRequest *request) { return rt_backend_submit(&backend, request); }
int r4a_backend_poll_compute(uint32_t worker, AiModelComputeCompletion *completion)
{
    AiRtBackendEvent event;
    (void)rt_backend_progress(&backend, AI_RT_BACKEND_COMPUTE, worker);
    int status = rt_backend_poll_event(&backend, &event);
    if (status > 0) *completion = event.payload.compute;
    return status;
}
int r4a_backend_poll_result(AiModelFrameCompletion *completion)
{
    AiRtBackendEvent event;
    (void)rt_backend_progress(&backend, AI_RT_BACKEND_RESULT, AI_RT_BACKEND_ANY_WORKER);
    int status = rt_backend_poll_event(&backend, &event);
    if (status > 0) *completion = event.payload.result;
    return status;
}
int r4a_backend_abort(uint32_t worker) { return rt_backend_abort(&backend, worker); }
uint32_t r4a_backend_is_idle(void) { return rt_backend_is_idle(&backend); }
void r4a_backend_get_resources(AiModelResourceSnapshot *resources) { rt_backend_get_resources(&backend, resources); }
