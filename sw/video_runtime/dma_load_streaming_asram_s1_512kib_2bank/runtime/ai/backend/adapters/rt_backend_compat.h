#ifndef RT_BACKEND_COMPAT_H
#define RT_BACKEND_COMPAT_H

#include "ai/backend/rt_backend.h"
#include "ai/backend/ai_model_backend.h"

/* One native call at the old compute/result poll position. Partial Head
 * callbacks and publication remain inside the existing backend for R4a. */
int rt_backend_compat_progress(AiRtBackendPhase phase, uint32_t worker,
                               AiRtBackendPayload *payload);

#endif
