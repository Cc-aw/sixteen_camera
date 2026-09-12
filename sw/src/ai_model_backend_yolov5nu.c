#include "ai_model_backend.h"

#include <string.h>

#include "ai_detection.h"
#include "ai_postprocess_diag.h"
#include "console.h"
#include "mmio.h"
#include "yolov5nu_dim16_dual.h"

enum {
    YOLOV5_STAGE_IDLE = 0,
    YOLOV5_STAGE_RUNNING = 1,
    YOLOV5_STAGE_COMPLETE = 2,
    YOLOV5_STAGE_ERROR = 3,
    YOLOV5_STAGE_HEAD_PENDING = 4,
    YOLOV5_STAGE_POSTPROCESS = 5
};

enum {
    PPU_ID = 0x100U,
    PPU_CONTROL = 0x100U,
    PPU_CLASS0 = 0x104U,
    PPU_CLASS1 = 0x108U,
    PPU_CLASS2 = 0x10cU,
    PPU_DFL0 = 0x110U,
    PPU_DFL1 = 0x114U,
    PPU_DFL2 = 0x118U,
    PPU_STATUS = 0x11cU,
    PPU_RESULT_INDEX = 0x120U,
    PPU_RESULT_COUNT = 0x124U,
    PPU_RESULT_XY0 = 0x128U,
    PPU_RESULT_XY1 = 0x12cU,
    PPU_RESULT_SCORE_CLASS = 0x130U
};

#define PPU_IDENT UINT32_C(0x50505531)
#define PPU_STATUS_BUSY UINT32_C(1)
#define PPU_STATUS_DONE UINT32_C(2)
#define PPU_STATUS_ERROR UINT32_C(4)
#define PPU_STATUS_READ_BUSY UINT32_C(8)

static AiModelFrameRequest requests[AI_MODEL_WORKER_COUNT];
static AiDetectionResult results[AI_MODEL_WORKER_COUNT];
static struct yolov5nu_dim16_result raw_results[AI_MODEL_WORKER_COUNT];
static uint32_t running[AI_MODEL_WORKER_COUNT];
static uint32_t stages[AI_MODEL_WORKER_COUNT];
static uint64_t start_cycles[AI_MODEL_WORKER_COUNT];
static uint32_t initialized;
static uint32_t hardware_present;
static uint32_t hardware_worker;
static uint32_t hardware_log_count;
static uint64_t hardware_start_cycles;

static void log_hardware_postprocess(uint32_t worker_id, uint32_t status)
{
    if ((status & PPU_STATUS_ERROR) == 0U && hardware_log_count >= 8U)
        return;
    if (hardware_log_count < 8U) hardware_log_count++;
    console_puts("AI PPU worker/status/count/positions/candidates/nms/cycles=");
    console_put_u32(worker_id);
    console_putc('/');
    console_put_hex32(status);
    console_putc('/');
    console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + PPU_RESULT_COUNT));
    console_putc('/');
    console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x138U));
    console_putc('/');
    console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x13cU));
    console_putc('/');
    console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x140U));
    console_putc('/');
    console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x144U));
    console_puts("\r\n");
    if (status & PPU_STATUS_ERROR) {
        console_puts("AI PPU reader status/bytes/ar/beats=");
        console_put_hex32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x0cU));
        console_putc('/');
        console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x28U));
        console_putc('/');
        console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x2cU));
        console_putc('/');
        console_put_u32(mmio_read32(POSTPROCESS_DIAG_BASE + 0x30U));
        console_puts("\r\n");
    }
}

static void start_hardware_postprocess(uint32_t worker_id)
{
    uintptr_t arena = yolov5nu_dim16_worker_arena(worker_id);
    // The same FBus path's coherence stress requires L2 line flushing for
    // CPU-addressed DDR.  Fence Gemmini first (in stage 165), then publish
    // every raw head before issuing the FBus read descriptors.
    ai_postprocess_diag_flush_range((void *)(arena + 499200U), 384000U);
    ai_postprocess_diag_flush_range((void *)(arena + 1113600U), 96000U);
    ai_postprocess_diag_flush_range((void *)(arena + 883200U), 24000U);
    ai_postprocess_diag_flush_range((void *)(arena + 153600U), 307200U);
    ai_postprocess_diag_flush_range((void *)(arena + 1036800U), 76800U);
    ai_postprocess_diag_flush_range((void *)(arena + 460800U), 19200U);
    // The FBus bridge applies the bit-31 coherent DDR alias itself.
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CLASS0,
                 (uint32_t)(arena + 499200U));
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CLASS1,
                 (uint32_t)(arena + 1113600U));
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CLASS2,
                 (uint32_t)(arena + 883200U));
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_DFL0,
                 (uint32_t)(arena + 153600U));
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_DFL1,
                 (uint32_t)(arena + 1036800U));
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_DFL2,
                 (uint32_t)(arena + 460800U));
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CONTROL, 1U);
    hardware_start_cycles = read_cycle();
    hardware_worker = worker_id;
    stages[worker_id] = YOLOV5_STAGE_POSTPROCESS;
}

static void read_hardware_postprocess(uint32_t worker_id)
{
    AiDetectionResult *destination = &results[worker_id];
    const AiModelFrameRequest *request = &requests[worker_id];
    uint32_t count = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_RESULT_COUNT);
    memset(destination, 0, sizeof(*destination));
    destination->job_id = request->job_id;
    destination->frame_id = request->frame_id;
    destination->timestamp = request->timestamp;
    destination->stream_id = request->stream_id;
    destination->worker_id = worker_id;
    destination->version = request->version;
    destination->count = count > AI_MAX_DETECTIONS ? AI_MAX_DETECTIONS : count;
    for (uint32_t index = 0; index < destination->count; ++index) {
        AiDetection *output = &destination->detections[index];
        uint32_t xy0, xy1, score_class;
        mmio_write32(POSTPROCESS_DIAG_BASE + PPU_RESULT_INDEX, index);
        xy0 = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_RESULT_XY0);
        xy1 = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_RESULT_XY1);
        score_class = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_RESULT_SCORE_CLASS);
        output->x_min = (int16_t)(xy0 & 0xffffU);
        output->y_min = (int16_t)(xy0 >> 16);
        output->x_max = (int16_t)(xy1 & 0xffffU);
        output->y_max = (int16_t)(xy1 >> 16);
        output->score_q15 = (uint16_t)(score_class & 0xffffU);
        output->class_id = (uint8_t)((score_class >> 16) & 0x7fU);
    }
}

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
    hardware_present = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_ID) ==
                       PPU_IDENT;
    hardware_worker = AI_MODEL_WORKER_COUNT;
    hardware_log_count = 0U;
    hardware_start_cycles = 0U;
    initialized = 1U;
    console_puts(hardware_present ?
        "AI MODEL init OK (YOLOv5nu dual + hardware postprocess)\r\n" :
        "AI MODEL init OK (YOLOv5nu dual CPU postprocess)\r\n");
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
    yolov5nu_dim16_worker_use_hardware(worker_id, hardware_present != 0U);
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
    if (stages[worker_id] == YOLOV5_STAGE_HEAD_PENDING) {
        if (hardware_worker != AI_MODEL_WORKER_COUNT ||
            mmio_read32(POSTPROCESS_DIAG_BASE + PPU_STATUS) &
                (PPU_STATUS_BUSY | PPU_STATUS_READ_BUSY))
            return 0;
        start_hardware_postprocess(worker_id);
        return 0;
    }
    if (stages[worker_id] == YOLOV5_STAGE_POSTPROCESS) {
        uint32_t hw_status = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_STATUS);
        if (!(hw_status & PPU_STATUS_DONE)) {
            if (read_cycle() - hardware_start_cycles >
                (uint64_t)SOC_CLOCK_HZ * UINT64_C(30)) {
                console_puts("AI PPU timeout status=");
                console_put_hex32(hw_status);
                console_puts("\r\n");
                stages[worker_id] = YOLOV5_STAGE_ERROR;
                running[worker_id] = 0U;
                // A busy reader might still touch its arena.  Keep that
                // worker reserved until the board is reset.
                return -2;
            }
            return 0;
        }
        hardware_worker = AI_MODEL_WORKER_COUNT;
        yolov5nu_dim16_worker_finish_hardware(worker_id);
        log_hardware_postprocess(worker_id, hw_status);
        if (hw_status & PPU_STATUS_ERROR) {
            stages[worker_id] = YOLOV5_STAGE_ERROR;
            running[worker_id] = 0U;
            return -2;
        }
        read_hardware_postprocess(worker_id);
    } else {
        status = yolov5nu_dim16_worker_poll(worker_id, &raw_results[worker_id]);
        if (status == YOLOV5NU_DIM16_RUNNING)
            return 0;
        if (status == YOLOV5NU_DIM16_HEAD_READY) {
            stages[worker_id] = YOLOV5_STAGE_HEAD_PENDING;
            return 0;
        }
        if (status != YOLOV5NU_DIM16_DONE) {
            stages[worker_id] = YOLOV5_STAGE_ERROR;
            running[worker_id] = 0U;
            return -2;
        }
        translate_result(worker_id);
    }
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
