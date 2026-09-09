#include "ai_model_backend.h"

#include <string.h>

#include "ai_detection.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"
#include "tinyyolov2_runtime.h"
#include "tinyyolov2_worker_pool.h"

enum {
    YOLOV2_STAGE_IDLE = 0,
    YOLOV2_STAGE_SUBMITTED = 1,
    YOLOV2_STAGE_FORWARD = 2,
    YOLOV2_STAGE_COMPLETE = 3,
    YOLOV2_STAGE_ERROR = 4
};

static AiModelFrameRequest requests[AI_MODEL_WORKER_COUNT];
static AiDetectionResult results[AI_MODEL_WORKER_COUNT];
static struct tinyyolov2_result raw_results[AI_MODEL_WORKER_COUNT];
static uint32_t running[AI_MODEL_WORKER_COUNT];
static uint32_t stages[AI_MODEL_WORKER_COUNT];
static uint64_t start_cycles[AI_MODEL_WORKER_COUNT];
static uint32_t initialized;

static void translate_result(uint32_t worker_id)
{
    const AiModelFrameRequest *request = &requests[worker_id];
    const struct tinyyolov2_result *source_result = &raw_results[worker_id];
    AiDetectionResult *destination_result = &results[worker_id];

    memset(destination_result, 0, sizeof(*destination_result));
    destination_result->job_id = request->job_id;
    destination_result->frame_id = request->frame_id;
    destination_result->timestamp = request->timestamp;
    destination_result->stream_id = request->stream_id;
    destination_result->worker_id = worker_id;
    destination_result->version = request->version;
    destination_result->count =
        source_result->count > (int)AI_MAX_DETECTIONS ?
        AI_MAX_DETECTIONS : (uint32_t)source_result->count;

    for (uint32_t index = 0U; index < destination_result->count; ++index) {
        const struct tinyyolov2_detection *source =
            &source_result->detections[index];
        AiDetection *destination = &destination_result->detections[index];
        uint32_t score;

        destination->x_min = (int16_t)source->x_min;
        destination->y_min = (int16_t)source->y_min;
        destination->x_max = (int16_t)source->x_max;
        destination->y_max = (int16_t)source->y_max;
        score = source->score_milli < 0 ? 0U :
                (uint32_t)source->score_milli;
        if (score > 1000U)
            score = 1000U;
        destination->score_q15 = (uint16_t)(score * 32768U / 1000U);
        destination->class_id = source->class_id < 0 ? 0U :
                                (uint8_t)source->class_id;
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
    tinyyolov2_set_diagnostics(0);
    tinyyolov2_worker_pool_init();
    initialized = 1U;
    console_puts("AI MODEL init OK (TinyYOLOv2 dual DIM16 "
                 "worker0=custom3 worker1=custom2 cache=coherent)\r\n");
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
        request->input_bytes != AI_TINYYOLOV2_INPUT_BYTES ||
        tinyyolov2_worker_is_idle(worker_id) == 0)
        return -1;

    requests[worker_id] = *request;
    input = (const int8_t *)AI_DDR_CPU_ALIAS(request->input_addr);
    if (tinyyolov2_worker_start(worker_id, input, "camera") == 0)
        return -2;
    running[worker_id] = 1U;
    stages[worker_id] = YOLOV2_STAGE_SUBMITTED;
    start_cycles[worker_id] = read_cycle();
    return 0;
}

int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion)
{
    int poll_status;
    uint64_t elapsed;

    if (initialized == 0U || worker_id >= AI_MODEL_WORKER_COUNT ||
        running[worker_id] == 0U || completion == 0)
        return -1;

    stages[worker_id] = YOLOV2_STAGE_FORWARD;
    poll_status = tinyyolov2_worker_poll(worker_id,
                                         &raw_results[worker_id], 1);
    if (poll_status == TINYYOLOV2_WORKER_RUNNING)
        return 0;
    if (poll_status != TINYYOLOV2_WORKER_DONE) {
        stages[worker_id] = YOLOV2_STAGE_ERROR;
        running[worker_id] = 0U;
        return -2;
    }

    elapsed = read_cycle() - start_cycles[worker_id];
    translate_result(worker_id);
    memset(completion, 0, sizeof(*completion));
    completion->job_id = requests[worker_id].job_id;
    completion->worker_id = worker_id;
    completion->stream_id = requests[worker_id].stream_id;
    completion->frame_id = requests[worker_id].frame_id;
    completion->version = requests[worker_id].version;
    completion->status = 0;
    completion->compute_cycles = elapsed;
    completion->output_addr = (uintptr_t)&results[worker_id];
    completion->output_desc.dtype = AI_TENSOR_DTYPE_CUSTOM;
    completion->output_desc.layout = AI_TENSOR_LAYOUT_CHANNEL_ANCHOR;
    completion->output_desc.bytes = sizeof(results[worker_id]);
    stages[worker_id] = YOLOV2_STAGE_COMPLETE;
    running[worker_id] = 0U;
    return 1;
}

int ai_model_backend_abort(uint32_t worker_id)
{
    if (worker_id >= AI_MODEL_WORKER_COUNT)
        return -1;
    /* RoCC has no per-job cancel. Keep an active worker reserved on a real
       timeout so a new request cannot overwrite its unfinished state. */
    if (running[worker_id] != 0U) {
        stages[worker_id] = YOLOV2_STAGE_ERROR;
        return -2;
    }
    stages[worker_id] = YOLOV2_STAGE_IDLE;
    return 0;
}

uint32_t ai_model_backend_stage(void)
{
    uint32_t stage = YOLOV2_STAGE_IDLE;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker) {
        if (running[worker] != 0U)
            return YOLOV2_STAGE_FORWARD;
        if (stages[worker] > stage)
            stage = stages[worker];
    }
    return stage;
}

uint64_t ai_model_backend_elapsed_cycles(void)
{
    uint64_t now = read_cycle();
    uint64_t maximum = 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker) {
        if (running[worker] != 0U) {
            uint64_t elapsed = now - start_cycles[worker];
            if (elapsed > maximum)
                maximum = elapsed;
        }
    }
    return maximum;
}

void ai_model_backend_get_pe_stats(AiModelPeStats *stats)
{
    if (stats == 0)
        return;
    memset(stats, 0, sizeof(*stats));
    stats->valid = initialized;
    stats->layer_index = 8U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker) {
        stats->load_active_cycles += tinyyolov2_worker_last_load[worker];
        stats->exe_active_cycles += tinyyolov2_worker_last_exec[worker];
        stats->store_active_cycles += tinyyolov2_worker_last_store[worker];
    }
}
