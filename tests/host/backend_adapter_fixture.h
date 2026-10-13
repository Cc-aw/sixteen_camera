#ifndef BACKEND_ADAPTER_FIXTURE_H
#define BACKEND_ADAPTER_FIXTURE_H
#include "ai/backend/rt_backend.h"
void r4a_backend_init(void);
int r4a_backend_submit(const AiModelFrameRequest *request);
int r4a_backend_poll_compute(uint32_t worker, AiModelComputeCompletion *completion);
int r4a_backend_poll_result(AiModelFrameCompletion *completion);
int r4a_backend_abort(uint32_t worker);
uint32_t r4a_backend_is_idle(void);
void r4a_backend_get_resources(AiModelResourceSnapshot *resources);
#define ai_model_backend_init r4a_backend_init
#define ai_model_backend_submit r4a_backend_submit
#define ai_model_backend_poll_compute r4a_backend_poll_compute
#define ai_model_backend_poll_result r4a_backend_poll_result
#define ai_model_backend_abort r4a_backend_abort
#define ai_model_backend_is_idle r4a_backend_is_idle
#define ai_model_backend_get_resources r4a_backend_get_resources
#endif
