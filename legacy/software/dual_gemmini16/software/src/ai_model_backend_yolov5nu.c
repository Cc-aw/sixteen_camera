#include "ai_model_backend.h"

#include <string.h>

#include "ai_detection.h"
#include "console.h"
#include "mmio.h"
#include "yolov5nu_dim16_dual.h"

enum {
    YOLOV5_STAGE_IDLE = 0,
    YOLOV5_STAGE_RUNNING = 1,
    YOLOV5_STAGE_COMPLETE = 2,
    YOLOV5_STAGE_ERROR = 3
};

static AiModelFrameRequest requests[AI_MODEL_WORKER_COUNT];
static AiDetectionResult results[AI_MODEL_WORKER_COUNT];
static struct yolov5nu_dim16_result raw_results[AI_MODEL_WORKER_COUNT];
static uint32_t running[AI_MODEL_WORKER_COUNT];
static uint32_t stages[AI_MODEL_WORKER_COUNT];
static uint64_t start_cycles[AI_MODEL_WORKER_COUNT];
static uint32_t initialized;

static int16_t clamp_i16(float value, int maximum)
{
    if (value <= 0.0f)
        return 0;
    if (value >= (float)maximum)
        return (int16_t)maximum;
    return (int16_t)(value + 0.5f);
}

static void translate_result(uint32_t worker_id)
{
    const AiModelFrameRequest *request = &requests[worker_id];
    const struct yolov5nu_dim16_result *source = &raw_results[worker_id];
    AiDetectionResult *destination = &results[worker_id];

    memset(destination, 0, sizeof(*destination));
    destination->job_id = request->job_id;
    destination->frame_id = request->frame_id;
    destination->timestamp = request->timestamp;
    destination->stream_id = request->stream_id;
    destination->worker_id = worker_id;
    destination->version = request->version;
    destination->count = source->count > AI_MAX_DETECTIONS ?
                         AI_MAX_DETECTIONS : source->count;

    for (uint32_t index = 0U; index < destination->count; ++index) {
        const struct yolov5nu_dim16_detection *input =
            &source->detections[index];
        AiDetection *output = &destination->detections[index];
        float half_width = input->width * 0.5f;
        float half_height = input->height * 0.5f;
        float score = input->score;
        if (score < 0.0f)
            score = 0.0f;
        if (score > 1.0f)
            score = 1.0f;
        output->x_min = clamp_i16(input->center_x - half_width,
                                  (int)AI_YOLOV5NU_INPUT_WIDTH);
        output->y_min = clamp_i16(input->center_y - half_height,
                                  (int)AI_YOLOV5NU_INPUT_HEIGHT);
        output->x_max = clamp_i16(input->center_x + half_width,
                                  (int)AI_YOLOV5NU_INPUT_WIDTH);
        output->y_max = clamp_i16(input->center_y + half_height,
                                  (int)AI_YOLOV5NU_INPUT_HEIGHT);
        output->score_q15 = (uint16_t)(score * 32768.0f + 0.5f);
        output->class_id = input->class_id < 0 ? 0U :
            (input->class_id >= (int)AI_YOLOV5NU_CLASSES ?
             (uint8_t)(AI_YOLOV5NU_CLASSES - 1U) :
             (uint8_t)input->class_id);
    }
}

void ai_model_backend_init(void)
{
    memset(requests, 0, sizeof(requests));
    memset(results, 0, sizeof(results));
    memset(raw_results, 0, sizeof(raw_results));
    memset(running, 0, sizeof(running));
    memset(stages, 0, sizeof(stages));
    memset(start_cycles, 0, sizeof(start_cycles));
    yolov5nu_dim16_dual_init();
    initialized = 1U;
    console_puts("AI MODEL init OK (YOLOv5nu 640x480 dual DIM16 "
                 "worker0=custom3 worker1=custom2)\r\n");
}

int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    uint32_t worker_id;
    const int8_t *input;
    if (initialized == 0U || request == 0)
        return -1;
    worker_id = request->worker_id;
    if (worker_id >= AI_MODEL_WORKER_COUNT || running[worker_id] != 0U ||
        request->input_addr == 0U ||
        request->input_bytes != AI_YOLOV5NU_INPUT_BYTES ||
        yolov5nu_dim16_worker_is_idle(worker_id) == 0)
        return -1;
    requests[worker_id] = *request;
    input = (const int8_t *)AI_DDR_CPU_ALIAS(request->input_addr);
    if (yolov5nu_dim16_worker_start(worker_id, input) < 0)
        return -2;
    running[worker_id] = 1U;
    stages[worker_id] = YOLOV5_STAGE_RUNNING;
    start_cycles[worker_id] = read_cycle();
    return 0;
}

int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion)
{
    int status;
    if (initialized == 0U || worker_id >= AI_MODEL_WORKER_COUNT ||
        running[worker_id] == 0U || completion == 0)
        return -1;
    status = yolov5nu_dim16_worker_poll(worker_id, &raw_results[worker_id]);
    if (status == YOLOV5NU_DIM16_RUNNING)
        return 0;
    if (status != YOLOV5NU_DIM16_DONE) {
        stages[worker_id] = YOLOV5_STAGE_ERROR;
        running[worker_id] = 0U;
        return -2;
    }
    translate_result(worker_id);
    memset(completion, 0, sizeof(*completion));
    completion->job_id = requests[worker_id].job_id;
    completion->worker_id = worker_id;
    completion->stream_id = requests[worker_id].stream_id;
    completion->frame_id = requests[worker_id].frame_id;
    completion->version = requests[worker_id].version;
    completion->compute_cycles = read_cycle() - start_cycles[worker_id];
    completion->output_addr = (uintptr_t)&results[worker_id];
    completion->output_desc.dtype = AI_TENSOR_DTYPE_CUSTOM;
    completion->output_desc.layout = AI_TENSOR_LAYOUT_CHANNEL_ANCHOR;
    completion->output_desc.bytes = sizeof(results[worker_id]);
    stages[worker_id] = YOLOV5_STAGE_COMPLETE;
    running[worker_id] = 0U;
    return 1;
}

int ai_model_backend_abort(uint32_t worker_id)
{
    if (worker_id >= AI_MODEL_WORKER_COUNT)
        return -1;
    if (running[worker_id] != 0U) {
        stages[worker_id] = YOLOV5_STAGE_ERROR;
        return -2;
    }
    stages[worker_id] = YOLOV5_STAGE_IDLE;
    return 0;
}

uint32_t ai_model_backend_stage(void)
{
    uint32_t maximum = 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker) {
        uint32_t stage = yolov5nu_dim16_worker_stage(worker);
        if (running[worker] != 0U && stage > maximum)
            maximum = stage;
    }
    return maximum;
}

uint64_t ai_model_backend_elapsed_cycles(void)
{
    uint64_t now = read_cycle();
    uint64_t maximum = 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (running[worker] != 0U && now - start_cycles[worker] > maximum)
            maximum = now - start_cycles[worker];
    return maximum;
}

void ai_model_backend_get_pe_stats(AiModelPeStats *stats)
{
    if (stats == 0)
        return;
    memset(stats, 0, sizeof(*stats));
    stats->valid = initialized;
    stats->layer_index = ai_model_backend_stage();
}
