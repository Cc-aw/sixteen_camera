#include "ai_model_backend.h"

#include <string.h>

#include "console.h"
#include "ai_detection.h"
#include "mmio.h"
#include "platform.h"
#include "tinyyolov2_runtime.h"

#define YOLOV2_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(5))

static AiModelFrameRequest current_request;
static AiDetectionResult current_result;
static AiModelPeStats pe_stats;
static uint32_t initialized;
static uint32_t running;
static uint32_t stage;
static uint64_t stage_start_cycle;

enum {
    YOLOV2_STAGE_IDLE = 0,
    YOLOV2_STAGE_SUBMITTED = 1,
    YOLOV2_STAGE_FORWARD = 2,
    YOLOV2_STAGE_COMPLETE = 3,
    YOLOV2_STAGE_ERROR = 4
};

static uint32_t pe_util_permille(uint64_t macs, uint32_t exec_cycles)
{
    if (exec_cycles == 0U)
        return 0U;
    uint64_t capacity = (uint64_t)exec_cycles * 16U * 16U;
    uint64_t value = macs * 1000U / capacity;
    return value > 1000U ? 1000U : (uint32_t)value;
}

static void yolo_layer_begin(unsigned layer_index, uint32_t input_height,
                             uint32_t input_width, uint32_t input_channels,
                             uint32_t output_height, uint32_t output_width,
                             uint32_t output_channels)
{
    console_puts("AI LAYER ");
    console_put_u32(layer_index);
    console_puts(" CONV BEGIN ih=");
    console_put_u32(input_height);
    console_puts(" iw=");
    console_put_u32(input_width);
    console_puts(" ic=");
    console_put_u32(input_channels);
    console_puts(" oh=");
    console_put_u32(output_height);
    console_puts(" ow=");
    console_put_u32(output_width);
    console_puts(" oc=");
    console_put_u32(output_channels);
    console_puts("\r\n");
}

static void yolo_layer_metrics(unsigned layer_index, uint64_t macs,
                               uint64_t cycles, uint32_t load_active,
                               uint32_t exec_active, uint32_t store_active,
                               uint32_t output_elems)
{
    (void)output_elems;
    pe_stats.valid = 1U;
    pe_stats.layer_index = layer_index;
    pe_stats.macs = macs;
    pe_stats.cycles = cycles;
    pe_stats.load_active_cycles = load_active;
    pe_stats.exe_active_cycles = exec_active;
    pe_stats.store_active_cycles = store_active;
    pe_stats.pe_util_permille = pe_util_permille(macs, exec_active);

    console_puts("AI LAYER ");
    console_put_u32(layer_index);
    console_puts(" DONE cycles=");
    console_put_u32((uint32_t)cycles);
    console_puts(" load/exec/store=");
    console_put_u32(load_active);
    console_putc('/');
    console_put_u32(exec_active);
    console_putc('/');
    console_put_u32(store_active);
    console_puts(" PE_UTIL_EST=");
    console_put_u32(pe_stats.pe_util_permille / 10U);
    console_putc('.');
    console_put_u32(pe_stats.pe_util_permille % 10U);
    console_puts("%\r\n");
}

void ai_model_backend_init(void)
{
    memset(&current_request, 0, sizeof(current_request));
    memset(&current_result, 0, sizeof(current_result));
    memset(&pe_stats, 0, sizeof(pe_stats));
    tinyyolov2_set_diagnostics(0);
    tinyyolov2_set_layer_begin_callback(yolo_layer_begin);
    tinyyolov2_set_layer_metrics_callback(yolo_layer_metrics);
    initialized = 1U;
    running = 0U;
    stage = YOLOV2_STAGE_IDLE;
    console_puts("AI MODEL init OK (TinyYOLOv2 DIM16 input=416x416 "
                 "scheduler=native_layer_fence cache=l2_flush64)\r\n");
}

int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    if (initialized == 0U || running != 0U || request == 0 ||
        request->worker_id != 0U || request->input_addr == 0U ||
        request->input_bytes != AI_TINYYOLOV2_INPUT_BYTES)
        return -1;
    current_request = *request;
    running = 1U;
    stage = YOLOV2_STAGE_SUBMITTED;
    stage_start_cycle = read_cycle();
    memset(&pe_stats, 0, sizeof(pe_stats));
    return 0;
}

int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion)
{
    struct tinyyolov2_result result;
    int status;

    if (initialized == 0U || running == 0U || worker_id != 0U ||
        completion == 0)
        return -1;

    stage = YOLOV2_STAGE_FORWARD;
    console_puts("AI MODEL_FORWARD_BEGIN stream=");
    console_put_u32(current_request.stream_id + 1U);
    console_puts(" frame=");
    console_put_hex64(current_request.frame_id);
    console_puts(" input=");
    console_put_hex32((uint32_t)AI_DDR_CPU_ALIAS(current_request.input_addr));
    console_puts("\r\n");

    status = tinyyolov2_run_detect(
        (const int8_t *)AI_DDR_CPU_ALIAS(current_request.input_addr),
        "camera", &result);
    uint64_t elapsed = read_cycle() - stage_start_cycle;
    running = 0U;
    if (elapsed > YOLOV2_TIMEOUT_CYCLES || status == 0) {
        stage = YOLOV2_STAGE_ERROR;
        console_puts("AI MODEL_FORWARD_ERROR=");
        console_put_u32(status == 0 ? 1U : 2U);
        console_puts("\r\n");
        return status == 0 ? -2 : -3;
    }

    memset(&current_result, 0, sizeof(current_result));
    current_result.job_id = current_request.job_id;
    current_result.frame_id = current_request.frame_id;
    current_result.timestamp = current_request.timestamp;
    current_result.stream_id = current_request.stream_id;
    current_result.worker_id = worker_id;
    current_result.version = current_request.version;
    current_result.count = result.count > (int)AI_MAX_DETECTIONS ?
                           AI_MAX_DETECTIONS : (uint32_t)result.count;
    for (uint32_t index = 0U; index < current_result.count; ++index) {
        const struct tinyyolov2_detection *source = &result.detections[index];
        AiDetection *destination = &current_result.detections[index];
        destination->x_min = (int16_t)source->x_min;
        destination->y_min = (int16_t)source->y_min;
        destination->x_max = (int16_t)source->x_max;
        destination->y_max = (int16_t)source->y_max;
        uint32_t score = source->score_milli < 0 ? 0U :
                         (uint32_t)source->score_milli;
        if (score > 1000U)
            score = 1000U;
        destination->score_q15 = (uint16_t)(score * 32768U / 1000U);
        destination->class_id = source->class_id < 0 ? 0U :
                                (uint8_t)source->class_id;
        destination->reserved = 0U;
    }

    memset(completion, 0, sizeof(*completion));
    completion->job_id = current_request.job_id;
    completion->worker_id = worker_id;
    completion->stream_id = current_request.stream_id;
    completion->frame_id = current_request.frame_id;
    completion->version = current_request.version;
    completion->status = 0;
    completion->compute_cycles = elapsed;
    completion->output_addr = (uintptr_t)&current_result;
    completion->output_desc.dtype = AI_TENSOR_DTYPE_CUSTOM;
    completion->output_desc.layout = AI_TENSOR_LAYOUT_CHANNEL_ANCHOR;
    completion->output_desc.bytes = sizeof(current_result);
    stage = YOLOV2_STAGE_COMPLETE;
    console_puts("AI MODEL_FORWARD_DONE cycles=");
    console_put_u32((uint32_t)elapsed);
    console_puts(" detections=");
    console_put_u32(current_result.count);
    console_puts("\r\n");
    return 1;
}

int ai_model_backend_abort(uint32_t worker_id)
{
    if (worker_id != 0U)
        return -1;
    running = 0U;
    stage = YOLOV2_STAGE_IDLE;
    return 0;
}

uint32_t ai_model_backend_stage(void) { return stage; }

uint64_t ai_model_backend_elapsed_cycles(void)
{
    return stage == YOLOV2_STAGE_IDLE ? 0U : read_cycle() - stage_start_cycle;
}

void ai_model_backend_get_pe_stats(AiModelPeStats *stats)
{
    if (stats != 0)
        *stats = pe_stats;
}
