#include "ai/backend/adapters/rt_backend_compat.h"

#if !defined(AI_RT_BACKEND_PROFILE) || AI_RT_BACKEND_PROFILE != AI_RT_BACKEND_PROFILE_LEGACY
#error "Legacy adapter requires explicit legacy backend profile"
#endif
#if defined(YOLO32_LIVE) && YOLO32_LIVE
#error "Legacy adapter cannot bind V17A live execution"
#endif
_Static_assert(AI_MODEL_WORKER_COUNT == 1U || AI_MODEL_WORKER_COUNT == 2U,
               "legacy video backend supports one or two workers");
#ifdef YOLOV5NU_GEMMINI_DIM
_Static_assert(YOLOV5NU_GEMMINI_DIM == (AI_MODEL_WORKER_COUNT == 1U ? 4 : 16),
               "legacy adapter must match the selected hardware ABI");
#endif

static const AiRtBackendOps ops = {
    .name = "legacy", .profile = AI_RT_BACKEND_PROFILE_LEGACY,
    .worker_count = AI_MODEL_WORKER_COUNT,
    .gemmini_dim = AI_MODEL_WORKER_COUNT == 1U ? 4U : 16U,
    .init = ai_model_backend_init, .submit = ai_model_backend_submit,
    .progress = rt_backend_compat_progress, .abort = ai_model_backend_abort,
    .is_idle = ai_model_backend_is_idle, .get_resources = ai_model_backend_get_resources
};

const AiRtBackendOps *rt_backend_selected_ops(void)
{
    return &ops;
}
