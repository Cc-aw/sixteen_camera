#include "ai/backend/adapters/rt_backend_compat.h"

#if !defined(AI_RT_BACKEND_PROFILE) || AI_RT_BACKEND_PROFILE != AI_RT_BACKEND_PROFILE_V17A
#error "V17A adapter requires explicit V17A backend profile"
#endif
#if !defined(YOLO32_LIVE) || !YOLO32_LIVE
#error "V17A adapter requires live execution"
#endif
_Static_assert(AI_MODEL_WORKER_COUNT == 3U, "V17A video backend requires three workers");
#ifdef YOLOV5NU_GEMMINI_DIM
_Static_assert(YOLOV5NU_GEMMINI_DIM == 32, "V17A adapter requires the DIM32 hardware ABI");
#endif

static const AiRtBackendOps ops = {
#if defined(YOLO32_CAPACITY_EXPERIMENT) && YOLO32_CAPACITY_EXPERIMENT
    .name = "v26",
#else
    .name = "v17a",
#endif
    .profile = AI_RT_BACKEND_PROFILE_V17A,
    .worker_count = AI_MODEL_WORKER_COUNT, .gemmini_dim = 32U,
    .init = ai_model_backend_init, .submit = ai_model_backend_submit,
    .progress = rt_backend_compat_progress, .abort = ai_model_backend_abort,
    .is_idle = ai_model_backend_is_idle, .get_resources = ai_model_backend_get_resources
};

const AiRtBackendOps *rt_backend_selected_ops(void)
{
    return &ops;
}
