#include "ai_model_backend.h"

#include "platform.h"

static uint32_t running;

void ai_model_backend_init(void)
{
    running = 0U;
}

int ai_model_backend_submit(const AiModelRequest *request)
{
    if (request == 0 || running != 0U)
        return -1;
    if ((request->input_tensor_base & UINT32_C(31)) != 0U ||
        request->input_tensor_bytes !=
            TENSOR_MEMBER_BYTES * VIDEO_CHANNEL_COUNT ||
        request->batch_size != VIDEO_CHANNEL_COUNT)
        return -2;
    running = 1U;
    return 0;
}

int ai_model_backend_poll(void)
{
    if (running == 0U)
        return -1;
    running = 0U;
    return 1;
}

void ai_model_backend_abort(void)
{
    running = 0U;
}
