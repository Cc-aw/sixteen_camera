#include "ai_model_backend.h"

#include <string.h>

#include "ai_detection.h"
#include "ai_head_slot_queue.h"
#include "cache_ops.h"
#include "console.h"
#include "mmio.h"
#include "yolov5nu_dim16_dual.h"
#include "yolov5nu_head_layout.h"

enum {
    YOLOV5_STAGE_IDLE = 0,
    YOLOV5_STAGE_RUNNING = 1,
    YOLOV5_STAGE_COMPLETE = 2,
    YOLOV5_STAGE_ERROR = 3
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
    PPU_RESULT_SCORE_CLASS = 0x130U,
    PPU_READER_SELECT = 0x148U
};

#define PPU_IDENT UINT32_C(0x50505531)
#define PPU_STATUS_BUSY UINT32_C(1)
#define PPU_STATUS_DONE UINT32_C(2)
#define PPU_STATUS_ERROR UINT32_C(4)
#define PPU_STATUS_READ_BUSY UINT32_C(8)
#define AI_STREAM_HOTPATH_LOG 0

_Static_assert(AI_MODEL_WORKER_COUNT <= AI_HEAD_SLOT_QUEUE_MAX_WORKERS,
               "head slot queue is smaller than the model worker pool");

static AiModelFrameRequest requests[AI_MODEL_WORKER_COUNT];
static struct yolov5nu_dim16_result raw_results[AI_MODEL_WORKER_COUNT];
static uint32_t running[AI_MODEL_WORKER_COUNT];
static uint32_t stages[AI_MODEL_WORKER_COUNT];
static uint64_t start_cycles[AI_MODEL_WORKER_COUNT];
static uint32_t initialized;
static uint32_t hardware_present;
static uint32_t hardware_worker;
static uint32_t hardware_log_count;
static uint32_t queue_log_count;
static uint32_t graph_start_log_count;
static uint64_t hardware_start_cycles;
static uint64_t head_ready_cycles[AI_HEAD_SLOT_QUEUE_CAPACITY];
static AiFrameProfile head_profiles[AI_HEAD_SLOT_QUEUE_CAPACITY];
static AiHeadSlotQueue head_queue;
static uint32_t worker_head_slot[AI_MODEL_WORKER_COUNT];
typedef struct {
    AiModelFrameCompletion completion;
    AiDetectionResult result;
} AiPostprocessCompletion;
static AiPostprocessCompletion post_completions[
    AI_MODEL_RESULT_QUEUE_CAPACITY];
static uint32_t post_head;
static uint32_t post_tail;
static uint32_t post_count;
static uint32_t hardware_faulted;

static void log_hardware_postprocess(uint32_t worker_id, uint32_t slot_id,
                                     uint32_t status)
{
    if ((status & PPU_STATUS_ERROR) == 0U &&
        (AI_STREAM_HOTPATH_LOG == 0 || hardware_log_count >= 8U))
        return;
    if (hardware_log_count < 8U) hardware_log_count++;
    const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue,
                                                     head_queue.active);
    console_puts("AI PPU worker/slot/job/status/count/positions/candidates/nms/ready/cycles=");
    console_put_u32(worker_id);
    console_putc('/');
    console_put_u32(slot_id);
    console_putc('/');
    console_put_hex64(slot != 0 ? slot->descriptor.job_id : 0U);
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
    console_put_u32(head_queue.ready_count);
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

static void start_hardware_postprocess(AiHeadSlot *slot)
{
    const AiHeadSlotDescriptor *descriptor = &slot->descriptor;
    uint32_t worker_id = descriptor->worker_id;
    uintptr_t head = AI_DDR_CPU_ALIAS(descriptor->base_addr);
    // gemmini_fence() completes the accelerator command, but board testing
    // shows that dirty Head cache lines may still not have reached the AXI
    // router. Flush before either reader so the URAM mirror and DDR shadow
    // both contain the completed payload before the PPU command is issued.
    cache_flush_range((void *)head, YOLOV5NU_HEAD_PAYLOAD_BYTES);
    // The FBus bridge applies the bit-31 coherent DDR alias itself.
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CLASS0,
                 (uint32_t)descriptor->class_addr[0]);
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CLASS1,
                 (uint32_t)descriptor->class_addr[1]);
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CLASS2,
                 (uint32_t)descriptor->class_addr[2]);
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_DFL0,
                 (uint32_t)descriptor->dfl_addr[0]);
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_DFL1,
                 (uint32_t)descriptor->dfl_addr[1]);
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_DFL2,
                 (uint32_t)descriptor->dfl_addr[2]);
    mmio_write32(POSTPROCESS_DIAG_BASE + PPU_CONTROL, 1U);
    hardware_start_cycles = read_cycle();
    hardware_worker = worker_id;
}

static void fill_post_completion(AiPostprocessCompletion *record,
                                 const AiHeadSlotDescriptor *descriptor,
                                 int32_t status)
{
    memset(record, 0, sizeof(*record));
    record->completion.job_id = descriptor->job_id;
    record->completion.worker_id = descriptor->worker_id;
    record->completion.stream_id = descriptor->stream_id;
    record->completion.frame_id = descriptor->frame_id;
    record->completion.version = descriptor->version;
    record->completion.status = status;
    record->completion.output_addr = status == 0 ?
                                     (uintptr_t)&record->result : 0U;
    record->completion.output_desc.dtype = AI_TENSOR_DTYPE_CUSTOM;
    record->completion.output_desc.layout =
        AI_TENSOR_LAYOUT_CHANNEL_ANCHOR;
    record->completion.output_desc.bytes = sizeof(record->result);
}

static void read_hardware_postprocess(const AiHeadSlot *slot,
                                      AiPostprocessCompletion *record)
{
    const AiHeadSlotDescriptor *descriptor = &slot->descriptor;
    uint32_t worker_id = descriptor->worker_id;
    AiDetectionResult *destination = &record->result;
    uint32_t count = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_RESULT_COUNT);
    fill_post_completion(record, descriptor, 0);
    destination->job_id = descriptor->job_id;
    destination->frame_id = descriptor->frame_id;
    destination->timestamp = descriptor->timestamp;
    destination->stream_id = descriptor->stream_id;
    destination->worker_id = worker_id;
    destination->version = descriptor->version;
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

static void translate_result(uint32_t worker_id,
                             AiDetectionResult *destination)
{
    const AiModelFrameRequest *request = &requests[worker_id];
    const struct yolov5nu_dim16_result *source = &raw_results[worker_id];
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
    memset(raw_results, 0, sizeof(raw_results));
    memset(post_completions, 0, sizeof(post_completions));
    memset(running, 0, sizeof(running));
    memset(stages, 0, sizeof(stages));
    memset(start_cycles, 0, sizeof(start_cycles));
    memset(head_ready_cycles, 0, sizeof(head_ready_cycles));
    memset(head_profiles, 0, sizeof(head_profiles));
    yolov5nu_dim16_dual_init();
    hardware_present = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_ID) ==
                       PPU_IDENT;
    hardware_worker = AI_MODEL_WORKER_COUNT;
    hardware_log_count = 0U;
    queue_log_count = 0U;
    graph_start_log_count = 0U;
    hardware_start_cycles = 0U;
    hardware_faulted = 0U;
    post_head = 0U;
    post_tail = 0U;
    post_count = 0U;
    ai_head_slot_queue_init(&head_queue, AI_MODEL_WORKER_COUNT);
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        worker_head_slot[worker] = AI_HEAD_SLOT_INVALID;
    initialized = 1U;
    console_puts(hardware_present ?
        "AI MODEL init OK (YOLOv5nu dual + hardware postprocess)\r\n" :
        "AI MODEL init OK (YOLOv5nu dual CPU postprocess)\r\n");
    if (hardware_present != 0U) {
        console_puts("AI PPU head reader enable/active/busy/error=");
        uint32_t reader = mmio_read32(POSTPROCESS_DIAG_BASE +
                                      PPU_READER_SELECT);
        console_put_u32(reader & 1U);
        console_putc('/');
        console_put_u32((reader >> 1) & 1U);
        console_putc('/');
        console_put_u32((reader >> 2) & 1U);
        console_putc('/');
        console_put_u32((reader >> 3) & 1U);
        console_puts("\r\n");
    }
}

int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    uint32_t worker_id;
    uint32_t slot_key = AI_HEAD_SLOT_INVALID;
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
    if (hardware_present != 0U &&
        ((request->output_addr & 63U) != 0U ||
         request->output_bytes < YOLOV5NU_HEAD_POOL_BYTES))
        return -1;
    if (hardware_present != 0U &&
        ai_head_slot_acquire(&head_queue, worker_id, request->output_addr,
                             request, &slot_key) != 0)
        return -3;
    if (yolov5nu_dim16_worker_start(worker_id, input) < 0) {
        if (slot_key != AI_HEAD_SLOT_INVALID)
            (void)ai_head_slot_release_writing(&head_queue, slot_key);
        return -2;
    }
    if (hardware_present != 0U) {
        const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue,
                                                        slot_key);
        worker_head_slot[worker_id] = slot_key;
        yolov5nu_dim16_worker_set_head_slot(
            worker_id, AI_DDR_CPU_ALIAS(slot->descriptor.base_addr));
    } else {
        worker_head_slot[worker_id] = AI_HEAD_SLOT_INVALID;
        yolov5nu_dim16_worker_set_head_slot(worker_id, 0U);
    }
    yolov5nu_dim16_worker_use_hardware(worker_id, hardware_present != 0U);
    running[worker_id] = 1U;
    stages[worker_id] = YOLOV5_STAGE_RUNNING;
    start_cycles[worker_id] = read_cycle();
    if (AI_STREAM_HOTPATH_LOG != 0 && hardware_present != 0U &&
        graph_start_log_count < 8U) {
        const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue,
                                                        slot_key);
        uint32_t ppu_status = mmio_read32(POSTPROCESS_DIAG_BASE +
                                          PPU_STATUS);
        graph_start_log_count++;
        console_puts("AI GRAPH start worker/slot/job/ppu_status=");
        console_put_u32(worker_id);
        console_putc('/');
        console_put_u32(slot->slot_id);
        console_putc('/');
        console_put_hex64(request->job_id);
        console_putc('/');
        console_put_hex32(ppu_status);
        console_puts("\r\n");
    }
    return 0;
}

static int service_hardware_postprocess(void)
{
    AiHeadSlot *slot;
    AiPostprocessCompletion *record;
    uint32_t hw_status;
    uint32_t worker_id;
    int queue_status;
    if (hardware_present == 0U)
        return 0;
    if (hardware_worker != AI_MODEL_WORKER_COUNT) {
        slot = ai_head_slot_get(&head_queue, head_queue.active);
        if (slot == 0 || slot->state != AI_HEAD_SLOT_PROCESSING ||
            slot->descriptor.worker_id != hardware_worker)
            return -1;
        worker_id = hardware_worker;
        if (hardware_faulted != 0U)
            return 0;
        hw_status = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_STATUS);
        if (!(hw_status & PPU_STATUS_DONE)) {
            if (read_cycle() - hardware_start_cycles >
                (uint64_t)SOC_CLOCK_HZ * UINT64_C(30)) {
                console_puts("AI PPU timeout status=");
                console_put_hex32(hw_status);
                console_puts("\r\n");
                slot->error_status = UINT32_C(0x80000000) | hw_status;
                hardware_faulted = 1U;
                // A busy reader might still touch its arena.  Keep that
                // slot PROCESSING and the PPU reserved until board reset.
            }
            return 0;
        }
        hardware_worker = AI_MODEL_WORKER_COUNT;
        log_hardware_postprocess(worker_id, slot->slot_id, hw_status);
        if (post_count >= AI_MODEL_RESULT_QUEUE_CAPACITY)
            return -1;
        record = &post_completions[post_tail];
        if (hw_status & PPU_STATUS_ERROR) {
            fill_post_completion(record, &slot->descriptor, -2);
        } else {
            read_hardware_postprocess(slot, record);
        }
        if (head_queue.active < AI_HEAD_SLOT_QUEUE_CAPACITY)
            record->completion.profile = head_profiles[head_queue.active];
        post_tail = (post_tail + 1U) % AI_MODEL_RESULT_QUEUE_CAPACITY;
        post_count++;
        if (ai_head_slot_complete(&head_queue,
                                  hw_status & PPU_STATUS_ERROR) != 0)
            return -1;
    }
    if (hardware_worker != AI_MODEL_WORKER_COUNT ||
        hardware_faulted != 0U ||
        post_count >= AI_MODEL_RESULT_QUEUE_CAPACITY)
        return 0;
    hw_status = mmio_read32(POSTPROCESS_DIAG_BASE + PPU_STATUS);
    if (hw_status & (PPU_STATUS_BUSY | PPU_STATUS_READ_BUSY))
        return 0;
    queue_status = ai_head_slot_start_next(&head_queue, &slot);
    if (queue_status <= 0)
        return queue_status;
    if (head_queue.active < AI_HEAD_SLOT_QUEUE_CAPACITY)
        head_profiles[head_queue.active].ppu_queue_wait_cycles =
            read_cycle() - head_ready_cycles[head_queue.active];
    worker_id = slot->descriptor.worker_id;
    if (worker_id >= AI_MODEL_WORKER_COUNT)
        return -1;
    start_hardware_postprocess(slot);
    return 0;
}

static void fill_compute_completion(uint32_t worker_id,
                                    AiModelComputeCompletion *completion)
{
    const AiModelFrameRequest *request = &requests[worker_id];
    memset(completion, 0, sizeof(*completion));
    completion->job_id = request->job_id;
    completion->worker_id = worker_id;
    completion->stream_id = request->stream_id;
    completion->frame_id = request->frame_id;
    completion->version = request->version;
    completion->compute_cycles = read_cycle() - start_cycles[worker_id];
    struct yolov5nu_dim16_profile model_profile;
    if (yolov5nu_dim16_worker_get_profile(worker_id, &model_profile) == 0) {
        completion->profile.rocc_submit_cycles =
            model_profile.rocc_submit_cycles;
        completion->profile.gemmini_busy_cycles =
            model_profile.gemmini_busy_cycles;
        completion->profile.gemmini_load_stall_cycles =
            model_profile.gemmini_load_stall_cycles;
        completion->profile.gemmini_exec_cycles =
            model_profile.gemmini_exec_cycles;
        completion->profile.gemmini_store_stall_cycles =
            model_profile.gemmini_store_stall_cycles;
        completion->profile.rvv_maxpool_cycles =
            model_profile.rvv_maxpool_cycles;
        completion->profile.rvv_resize_cycles =
            model_profile.rvv_resize_cycles;
        completion->profile.rvv_copy_requant_cycles =
            model_profile.rvv_copy_requant_cycles;
        completion->profile.fence_cycles = model_profile.fence_cycles;
    }
}

static void descriptor_from_request(uint32_t worker_id,
                                    AiHeadSlotDescriptor *descriptor)
{
    const AiModelFrameRequest *request = &requests[worker_id];
    memset(descriptor, 0, sizeof(*descriptor));
    descriptor->job_id = request->job_id;
    descriptor->worker_id = worker_id;
    descriptor->stream_id = request->stream_id;
    descriptor->frame_id = request->frame_id;
    descriptor->timestamp = request->timestamp;
    descriptor->version = request->version;
}

int ai_model_backend_poll_compute(uint32_t worker_id,
                                  AiModelComputeCompletion *completion)
{
    int status;
    if (initialized == 0U || worker_id >= AI_MODEL_WORKER_COUNT ||
        running[worker_id] == 0U || completion == 0)
        return -1;
    if (hardware_present != 0U && service_hardware_postprocess() < 0)
        hardware_faulted = 1U;
    if (stages[worker_id] == YOLOV5_STAGE_ERROR) {
        running[worker_id] = 0U;
        return -2;
    }

    status = yolov5nu_dim16_worker_poll(worker_id, &raw_results[worker_id]);
    if (status == YOLOV5NU_DIM16_RUNNING)
        return 0;
    if (status == YOLOV5NU_DIM16_HEAD_READY) {
        uint32_t slot_key = worker_head_slot[worker_id];
        if (slot_key == AI_HEAD_SLOT_INVALID ||
            ai_head_slot_publish(&head_queue, slot_key) != 0) {
            stages[worker_id] = YOLOV5_STAGE_ERROR;
            running[worker_id] = 0U;
            return -2;
        }
        fill_compute_completion(worker_id, completion);
        head_ready_cycles[slot_key] = read_cycle();
        head_profiles[slot_key] = completion->profile;
        if (AI_STREAM_HOTPATH_LOG != 0 && queue_log_count < 8U) {
            const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue,
                                                            slot_key);
            queue_log_count++;
            console_puts("AI PPU enqueue worker/slot/job/ready/cycles=");
            console_put_u32(worker_id);
            console_putc('/');
            console_put_u32(slot->slot_id);
            console_putc('/');
            console_put_hex64(slot->descriptor.job_id);
            console_putc('/');
            console_put_u32(head_queue.ready_count);
            console_putc('/');
            console_put_u32((uint32_t)(read_cycle() -
                            start_cycles[worker_id]));
            console_puts("\r\n");
        }
        /* Raw heads now belong to the slot.  The worker's activation arena
         * and input tensor are no longer needed by postprocessing. */
        yolov5nu_dim16_worker_finish_hardware(worker_id);
        worker_head_slot[worker_id] = AI_HEAD_SLOT_INVALID;
        stages[worker_id] = YOLOV5_STAGE_COMPLETE;
        running[worker_id] = 0U;
        if (service_hardware_postprocess() < 0)
            hardware_faulted = 1U;
        return 1;
    }
    if (status != YOLOV5NU_DIM16_DONE) {
        stages[worker_id] = YOLOV5_STAGE_ERROR;
        running[worker_id] = 0U;
        return -2;
    }
    if (post_count >= AI_MODEL_RESULT_QUEUE_CAPACITY) {
        stages[worker_id] = YOLOV5_STAGE_ERROR;
        running[worker_id] = 0U;
        return -2;
    }
    AiHeadSlotDescriptor descriptor;
    AiPostprocessCompletion *record = &post_completions[post_tail];
    descriptor_from_request(worker_id, &descriptor);
    fill_post_completion(record, &descriptor, 0);
    translate_result(worker_id, &record->result);
    post_tail = (post_tail + 1U) % AI_MODEL_RESULT_QUEUE_CAPACITY;
    post_count++;
    stages[worker_id] = YOLOV5_STAGE_COMPLETE;
    running[worker_id] = 0U;
    fill_compute_completion(worker_id, completion);
    return 1;
}

int ai_model_backend_poll_result(AiModelFrameCompletion *completion)
{
    if (initialized == 0U || completion == 0)
        return -1;
    if (hardware_present != 0U && service_hardware_postprocess() < 0)
        hardware_faulted = 1U;
    if (post_count != 0U) {
        *completion = post_completions[post_head].completion;
        post_head = (post_head + 1U) % AI_MODEL_RESULT_QUEUE_CAPACITY;
        post_count--;
        return 1;
    }
    return hardware_faulted != 0U ? -2 : 0;
}

uint32_t ai_model_backend_is_idle(void)
{
    if (initialized == 0U || hardware_faulted != 0U || post_count != 0U ||
        hardware_worker != AI_MODEL_WORKER_COUNT ||
        head_queue.ready_count != 0U ||
        head_queue.active != AI_HEAD_SLOT_INVALID)
        return 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (running[worker] != 0U)
            return 0U;
    return 1U;
}

int ai_model_backend_poll(uint32_t worker_id,
                          AiModelFrameCompletion *completion)
{
    AiModelComputeCompletion compute;
    int status;
    if (completion == 0)
        return -1;
    status = ai_model_backend_poll_compute(worker_id, &compute);
    if (status <= 0)
        return status;
    memset(completion, 0, sizeof(*completion));
    completion->job_id = compute.job_id;
    completion->worker_id = compute.worker_id;
    completion->stream_id = compute.stream_id;
    completion->frame_id = compute.frame_id;
    completion->version = compute.version;
    completion->status = compute.status;
    completion->compute_cycles = compute.compute_cycles;
    completion->profile = compute.profile;
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
