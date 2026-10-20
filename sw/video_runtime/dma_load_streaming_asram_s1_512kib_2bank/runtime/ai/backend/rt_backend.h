#ifndef RT_BACKEND_H
#define RT_BACKEND_H

#include "ai/backend/ai_model_abi.h"
#include "ai/runtime/resources/rt_resources.h"

#ifndef AI_MODEL_WORKER_COUNT
#define AI_MODEL_WORKER_COUNT 2U
#endif
#define AI_MODEL_RESULT_QUEUE_CAPACITY (AI_MODEL_WORKER_COUNT * 2U)
#define AI_MODEL_POSTPROCESS_CAPACITY (AI_MODEL_WORKER_COUNT * 4U)

#define AI_RT_BACKEND_PROFILE_LEGACY 1
#define AI_RT_BACKEND_PROFILE_V17A 2
#define AI_RT_BACKEND_HEAD_BUSY (-3)
#define AI_RT_BACKEND_FAULT_HELD (-4)
#define AI_RT_BACKEND_EVENT_PENDING (-5)
#define AI_RT_BACKEND_ANY_WORKER UINT32_MAX

/* Layout aliases preserve the existing firmware ABI and borrowed result
 * pointer lifetime. Runtime code uses these names rather than model entry points. */
typedef AiModelFrameRequest AiRtBackendRequest;
typedef AiModelComputeCompletion AiRtBackendComputeCompletion;
typedef AiModelFrameCompletion AiRtBackendResultCompletion;
typedef AiModelResourceSnapshot AiRtBackendResources;

typedef enum {
    AI_RT_BACKEND_COMPUTE = 0,
    AI_RT_BACKEND_RESULT
} AiRtBackendPhase;

typedef enum {
    AI_RT_BACKEND_EVENT_NONE = 0,
    AI_RT_BACKEND_COMPUTE_DONE,
    AI_RT_BACKEND_RESULT_READY,
    AI_RT_BACKEND_FAULT
} AiRtBackendEventType;

typedef union {
    AiRtBackendComputeCompletion compute;
    AiRtBackendResultCompletion result;
} AiRtBackendPayload;

typedef struct {
    AiRtBackendEventType type;
    AiRtBackendPhase phase;
    int32_t backend_status;
    uint32_t requested_worker;
    /* Valid completion payload only for positive backend_status. FAULT does
     * not identify a stopped job or authorize any resource release. */
    AiRtBackendPayload payload;
} AiRtBackendEvent;

typedef struct {
    const char *name;
    uint32_t profile, worker_count, gemmini_dim;
    void (*init)(void);
    int (*submit)(const AiRtBackendRequest *request);
    int (*progress)(AiRtBackendPhase phase, uint32_t worker,
                    AiRtBackendPayload *payload);
    int (*abort)(uint32_t worker);
    uint32_t (*is_idle)(void);
    void (*get_resources)(AiRtBackendResources *resources);
} AiRtBackendOps;

typedef struct {
    uint32_t pending;
    AiRtBackendEvent event;
} AiRtBackend;

/* Handles start zero-initialized. Reinitialization never discards an unconsumed
 * event; Runtime separately guards native ownership before clearing its Context.
 * Exactly one profile is selected and linked by the build. The underlying
 * native backend remains a singleton; multiple independent handles are not
 * independent accelerators. No heap, lock or extra scheduler pump is added. */
const AiRtBackendOps *rt_backend_selected_ops(void);
void rt_backend_init(AiRtBackend *backend);
int rt_backend_submit(AiRtBackend *backend, const AiRtBackendRequest *request);
int rt_backend_progress(AiRtBackend *backend, AiRtBackendPhase phase, uint32_t worker);
/* Pure mailbox read: 0 = empty, native positive/negative status = one event.
 * A null destination does not consume an event. */
int rt_backend_poll_event(AiRtBackend *backend, AiRtBackendEvent *event);
int rt_backend_abort(AiRtBackend *backend, uint32_t worker);
uint32_t rt_backend_is_idle(const AiRtBackend *backend);
void rt_backend_get_resources(const AiRtBackend *backend, AiRtBackendResources *resources);

#endif
