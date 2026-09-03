#include "ai_model_backend.h"

#include <string.h>

#include "platform.h"

typedef struct {
    uint32_t running;
    AiModelFrameRequest request;
} AiStubWorker;

static AiStubWorker workers[AI_MODEL_WORKER_COUNT];

#ifdef AI_MODEL_BACKEND_HOST_TEST
static int32_t host_output[AI_MODEL_WORKER_COUNT]
                          [AI_YOLOV5NU_CHANNELS * AI_YOLOV5NU_ANCHORS];

static int32_t *stub_output_pointer(uint32_t worker_id)
{
    return host_output[worker_id];
}
#else
static int32_t *stub_output_pointer(uint32_t worker_id)
{
    uintptr_t device_address = AI_MODEL_OUTPUT0_PHYS_BASE +
        worker_id * AI_MODEL_OUTPUT_ARENA_BYTES;
    return (int32_t *)AI_DDR_CPU_ALIAS(device_address);
}
#endif

static void prepare_stub_output(uint32_t worker_id, uint32_t stream_id)
{
    int32_t *output = stub_output_pointer(worker_id);
    uint32_t element_count = AI_YOLOV5NU_CHANNELS * AI_YOLOV5NU_ANCHORS;
    for (uint32_t index = 0U; index < element_count; ++index)
        output[index] = 0;

    uint32_t anchor = stream_id;
    output[0U * AI_YOLOV5NU_ANCHORS + anchor] =
        (int32_t)(80U + stream_id * 24U) << 16;
    output[1U * AI_YOLOV5NU_ANCHORS + anchor] =
        (int32_t)(100U + (stream_id & 3U) * 32U) << 16;
    output[2U * AI_YOLOV5NU_ANCHORS + anchor] = 64 << 16;
    output[3U * AI_YOLOV5NU_ANCHORS + anchor] = 80 << 16;
    output[(4U + (stream_id % AI_YOLOV5NU_CLASSES)) *
           AI_YOLOV5NU_ANCHORS + anchor] = 58982;
}

void ai_model_backend_init(void)
{
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        workers[worker].running = 0U;
}

int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    if (request == 0 || request->worker_id >= AI_MODEL_WORKER_COUNT)
        return -1;
    AiStubWorker *worker = &workers[request->worker_id];
    if (worker->running != 0U)
        return -2;
    if ((request->input_addr & UINT32_C(31)) != 0U ||
        request->input_bytes != TENSOR_MEMBER_BYTES ||
        request->output_bytes < AI_MODEL_OUTPUT_TENSOR_BYTES)
        return -3;
    worker->request = *request;
    worker->running = 1U;
    return 0;
}

int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion)
{
    if (worker_id >= AI_MODEL_WORKER_COUNT || completion == 0)
        return -1;
    AiStubWorker *worker = &workers[worker_id];
    if (worker->running == 0U)
        return -2;

    prepare_stub_output(worker_id, worker->request.stream_id);
    completion->job_id = worker->request.job_id;
    completion->worker_id = worker_id;
    completion->stream_id = worker->request.stream_id;
    completion->frame_id = worker->request.frame_id;
    completion->version = worker->request.version;
    completion->status = 0;
    completion->compute_cycles = 0U;
    completion->output_addr = (uintptr_t)stub_output_pointer(worker_id);
    completion->output_desc.dtype = AI_TENSOR_DTYPE_Q16_16;
    completion->output_desc.layout = AI_TENSOR_LAYOUT_CHANNEL_ANCHOR;
    completion->output_desc.channels = AI_YOLOV5NU_CHANNELS;
    completion->output_desc.anchors = AI_YOLOV5NU_ANCHORS;
    completion->output_desc.bytes = AI_MODEL_OUTPUT_TENSOR_BYTES;
    completion->output_desc.coordinate_scale_q16 = 0;
    completion->output_desc.score_scale_q16 = 0;
    completion->output_desc.coordinate_zero_point = 0;
    completion->output_desc.score_zero_point = 0;
    worker->running = 0U;
    return 1;
}

int ai_model_backend_abort(uint32_t worker_id)
{
    if (worker_id >= AI_MODEL_WORKER_COUNT)
        return -1;
    workers[worker_id].running = 0U;
    return 0;
}

uint32_t ai_model_backend_stage(void) { return 0U; }
uint64_t ai_model_backend_elapsed_cycles(void) { return 0U; }
void ai_model_backend_get_pe_stats(AiModelPeStats *stats)
{
    if (stats != 0)
        memset(stats, 0, sizeof(*stats));
}
