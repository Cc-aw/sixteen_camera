#include "ai/backend/rt_backend.h"
#include <string.h>

void rt_backend_init(AiRtBackend *backend)
{
    if (!backend || backend->pending)
        return;
    rt_backend_selected_ops()->init();
}

int rt_backend_submit(AiRtBackend *backend, const AiRtBackendRequest *request)
{
    if (!backend)
        return -1;
    if (backend->pending)
        return AI_RT_BACKEND_EVENT_PENDING;
    return rt_backend_selected_ops()->submit(request);
}

int rt_backend_progress(AiRtBackend *backend, AiRtBackendPhase phase, uint32_t worker)
{
    if (!backend)
        return -1;
    if (backend->pending)
        return AI_RT_BACKEND_EVENT_PENDING;
    memset(&backend->event, 0, sizeof(backend->event));
    backend->event.phase = phase;
    backend->event.requested_worker = worker;
    int status = rt_backend_selected_ops()->progress(phase, worker, &backend->event.payload);
    if (status == 0)
        return 0;
    backend->event.backend_status = status;
    backend->event.type = status < 0 ? AI_RT_BACKEND_FAULT :
        (phase == AI_RT_BACKEND_COMPUTE ? AI_RT_BACKEND_COMPUTE_DONE : AI_RT_BACKEND_RESULT_READY);
    backend->pending = 1U;
    return status;
}

int rt_backend_poll_event(AiRtBackend *backend, AiRtBackendEvent *event)
{
    if (!backend || !event)
        return -1;
    if (!backend->pending)
        return 0;
    *event = backend->event;
    backend->pending = 0U;
    return event->backend_status;
}

int rt_backend_abort(AiRtBackend *backend, uint32_t worker)
{
    if (!backend)
        return -1;
    /* Abort does not consume an event or create a completion/stop proof. */
    return rt_backend_selected_ops()->abort(worker);
}

uint32_t rt_backend_is_idle(const AiRtBackend *backend)
{
    if (!backend || backend->pending)
        return 0U;
    return rt_backend_selected_ops()->is_idle();
}

void rt_backend_get_resources(const AiRtBackend *backend, AiRtBackendResources *resources)
{
    if (backend && resources)
        rt_backend_selected_ops()->get_resources(resources);
}
