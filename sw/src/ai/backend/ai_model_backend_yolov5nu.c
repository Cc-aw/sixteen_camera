#include "ai/backend/ai_model_backend.h"

#include <string.h>

#include "ai/postprocess/ai_detection.h"
#include "ai/runtime/ai_head_slot_queue.h"
#include "ai/postprocess/ai_ppu_publication.h"
#include "ai/postprocess/ai_ppu_queue.h"
#include "drivers/ppu/ai_ppu_device.h"
#include "ai/runtime/resources/rt_arena_manager.h"
#include "ai/runtime/resources/rt_head_manager.h"
#include "platform/cache_ops.h"
#include "platform/console.h"
#include "mmio.h"
#include "yolov5nu_dim16_dual.h"
#include "yolov5nu_head_layout.h"
#ifndef YOLO32_LIVE
#define YOLO32_LIVE 0
#endif
#if YOLO32_LIVE
#include "yolo32.h"
#include "independent.h"
#include "ppu.h"
static uint32_t published_heads[AI_MODEL_WORKER_COUNT];
#endif

enum {
    YOLOV5_STAGE_IDLE = 0,
    YOLOV5_STAGE_RUNNING = 1,
    YOLOV5_STAGE_COMPLETE = 2,
    YOLOV5_STAGE_ERROR = 3
};

#define PPU_STATUS_BUSY AI_PPU_DEVICE_STATUS_BUSY
#define PPU_STATUS_DONE AI_PPU_DEVICE_STATUS_DONE
#define PPU_STATUS_ERROR AI_PPU_DEVICE_STATUS_ERROR
#define PPU_STATUS_READ_BUSY AI_PPU_DEVICE_STATUS_READ_BUSY
#define AI_STREAM_HOTPATH_LOG 0

_Static_assert(AI_MODEL_WORKER_COUNT == YOLOV5NU_DIM16_WORKER_COUNT,
               "backend and accelerator worker counts must match");
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
static AiRtHeadManager head_manager;
static AiRtArenaManager arena_manager;
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

static void hold_backend_fault(uint32_t worker)
{
    hardware_faulted = 1U;
    stages[worker] = YOLOV5_STAGE_ERROR;
    rt_arena_fault(&arena_manager, worker);
    rt_head_fault(&head_manager, worker_head_slot[worker]);
    /* Do not clear running, producer_complete, Head or model ownership. */
}

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
    console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_RESULT_COUNT));
    console_putc('/');
    console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_POSITIONS));
    console_putc('/');
    console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_CANDIDATES));
    console_putc('/');
    console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_NMS));
    console_putc('/');
    console_put_u32(head_queue.ready_count);
    console_putc('/');
    console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_CYCLES));
    console_puts("\r\n");
    if (status & PPU_STATUS_ERROR) {
        console_puts("AI PPU reader status/bytes/ar/beats=");
        console_put_hex32(ai_ppu_device_read_counter(AI_PPU_COUNTER_READER_STATUS));
        console_putc('/');
        console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_READER_BYTES));
        console_putc('/');
        console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_READER_AR));
        console_putc('/');
        console_put_u32(ai_ppu_device_read_counter(AI_PPU_COUNTER_READER_BEATS));
        console_puts("\r\n");
    }
}

static void start_hardware_postprocess(AiHeadSlot *slot)
{
    const AiHeadSlotDescriptor *descriptor = &slot->descriptor;
    uint32_t worker_id = descriptor->worker_id;
    uintptr_t head = AI_DDR_CPU_ALIAS(descriptor->base_addr);
    int published = ai_ppu_publication_select(descriptor->base_addr);
    if (published <= 0)
        cache_flush_range((void *)head, YOLOV5NU_HEAD_PAYLOAD_BYTES);
    // The FBus bridge applies the bit-31 coherent DDR alias itself.
    ai_ppu_device_start(descriptor->class_addr, descriptor->dfl_addr, published);
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
    uint32_t count = ai_ppu_device_read_counter(AI_PPU_COUNTER_RESULT_COUNT);
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
        AiPpuDeviceDetection detection;
        ai_ppu_device_read_detection(index, &detection);
        uint32_t xy0 = detection.xy0, xy1 = detection.xy1;
        uint32_t score_class = detection.score_class;
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

static int service_hardware_postprocess(void);
static void head_published(unsigned worker, unsigned head)
{
    if (worker >= AI_MODEL_WORKER_COUNT || stages[worker] == YOLOV5_STAGE_ERROR || !ai_ppu_publication_available()) return;
    uint32_t key = worker_head_slot[worker];
    AiHeadSlot *slot = ai_head_slot_get(&head_queue, key);
    if (!slot) return;
    ai_ppu_publication_publish(slot->descriptor.base_addr, 1U << head);
    head_manager.slots[key].producer_mask |= 1U << head;
    if (head == 0 && slot->state == AI_HEAD_SLOT_WRITING && !YOLO32_LIVE) {
        head_ready_cycles[key] = read_cycle();
        memset(&head_profiles[key], 0, sizeof(head_profiles[key]));
        if (ai_head_slot_admit(&head_queue, key) == 0)
            (void)service_hardware_postprocess();
    }
}

void ai_model_backend_init(void)
{
    if (initialized && !ai_model_backend_is_idle()) return;
    memset(requests, 0, sizeof(requests));
    memset(raw_results, 0, sizeof(raw_results));
    memset(post_completions, 0, sizeof(post_completions));
    memset(running, 0, sizeof(running));
    memset(stages, 0, sizeof(stages));
    memset(start_cycles, 0, sizeof(start_cycles));
    memset(head_ready_cycles, 0, sizeof(head_ready_cycles));
    memset(head_profiles, 0, sizeof(head_profiles));
    yolov5nu_dim16_dual_init();
    yolov5nu_dim16_set_head_callback(head_published);
#if YOLO32_LIVE
    memset(published_heads, 0, sizeof(published_heads));
    yolo32_independent_live_init();
#endif
    hardware_present = ai_ppu_device_available();
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
    rt_head_manager_init(&head_manager);
    rt_arena_manager_init(&arena_manager, AI_MODEL_WORKER_COUNT);
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        worker_head_slot[worker] = AI_HEAD_SLOT_INVALID;
    if (hardware_present) (void)ai_ppu_queue_init();
#if YOLO32_LIVE
    if (hardware_present) {
        /* Disable diagnostic-only queue observations on the live path. */
        ai_ppu_device_live_configure();
        yolo32_ppu_io_barrier();
    }
#endif
    initialized = 1U;
    console_puts(hardware_present ?
        "AI MODEL init OK (YOLOv5nu worker pool + hardware postprocess)\r\n" :
        "AI MODEL init OK (YOLOv5nu worker pool CPU postprocess)\r\n");
    if (hardware_present != 0U) {
        console_puts("AI PPU head reader enable/active/busy/error=");
        uint32_t reader = ai_ppu_device_reader_state();
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
#if YOLO32_LIVE
    if (!hardware_present || !ai_ppu_publication_available() ||
        !ai_ppu_queue_active() || hardware_faulted)
        return -2;
#endif
    if (hardware_faulted) return -2;
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
    AiRtJobIdentity identity = rt_job_identity(request->job_id, worker_id,
        request->stream_id, request->frame_id, request->version);
    if (rt_arena_claim(&arena_manager, &identity) != 0) {
        /* No publication or model start has occurred yet. */
        if (slot_key != AI_HEAD_SLOT_INVALID)
            (void)ai_head_slot_release_writing(&head_queue, slot_key);
        return -2;
    }
    worker_head_slot[worker_id] = slot_key;
    if (hardware_present != 0U) {
        const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue, slot_key);
        if (rt_head_bind(&head_manager, &head_queue, slot_key,
                         ai_ppu_publication_generation(slot->descriptor.base_addr)) != 0) {
            hold_backend_fault(worker_id); return AI_MODEL_SUBMIT_FAULT_HELD;
        }
        if (ai_ppu_publication_begin(slot->descriptor.base_addr) < 0) {
            hold_backend_fault(worker_id);
            return AI_MODEL_SUBMIT_FAULT_HELD;
        }
        head_manager.slots[slot_key].hardware_generation =
            ai_ppu_publication_generation(slot->descriptor.base_addr);
    }
    ai_ppu_queue_expect(request->stream_id, request->frame_id, request->version);
    if (yolov5nu_dim16_worker_start(worker_id, input) < 0) {
        hold_backend_fault(worker_id);
        return AI_MODEL_SUBMIT_FAULT_HELD;
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
#if YOLO32_LIVE
    published_heads[worker_id] = 0;
    yolo32_independent_live_start(worker_id);
#endif
    if (AI_STREAM_HOTPATH_LOG != 0 && hardware_present != 0U &&
        graph_start_log_count < 8U) {
        const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue,
                                                        slot_key);
        uint32_t ppu_status = ai_ppu_device_status();
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

/* Multiple hardware descriptors own independent software slots. Completion
 * metadata is sufficient: boxes travel directly from PPU to the display. */
static int service_queued_postprocess(void)
{
    AiPpuQueueResult r;
    if (post_count < AI_MODEL_RESULT_QUEUE_CAPACITY && ai_ppu_queue_peek(&r)) {
        AiHeadSlot *slot = ai_head_slot_get(&head_queue, r.bank);
        if (!slot || slot->state != AI_HEAD_SLOT_PROCESSING ||
            slot->descriptor.stream_id != r.stream || slot->descriptor.frame_id != r.frame ||
            slot->descriptor.version != r.version ||
            !ai_ppu_device_publication_matches(slot->descriptor.base_addr, r.generation)) {
            rt_head_fault(&head_manager, r.bank); return -1;
        }
        AiPpuDeviceResult device_result = {.bank = r.bank, .generation = r.generation,
            .stream = r.stream, .frame = r.frame, .version = r.version};
        if (!rt_head_result_matches(&head_manager, &head_queue, &device_result)) {
            rt_head_fault(&head_manager, r.bank); return -1;
        }
        if (!slot->producer_complete) return 0;
        AiPostprocessCompletion *record = &post_completions[post_tail];
        fill_post_completion(record, &slot->descriptor, (r.status & 1U) ? -2 : 0);
        AiDetectionResult *result = &record->result;
        result->job_id=slot->descriptor.job_id;result->frame_id=r.frame;
        result->timestamp=slot->descriptor.timestamp;result->stream_id=r.stream;
        result->worker_id=slot->descriptor.worker_id;result->version=r.version;result->count=r.count;
        result->flags=AI_RESULT_HARDWARE_OVERLAY|AI_RESULT_METADATA_ONLY|((r.status&2U)?AI_RESULT_STALE:0U);
        record->completion.profile=head_profiles[r.bank];
        ai_ppu_queue_pop();
        head_queue.active=r.bank;
        if(ai_head_slot_complete(&head_queue,r.status)!=0) return -1;
        if (rt_head_retire(&head_manager, &head_queue,
                           (AiRtSlotHandle){r.bank, head_manager.slots[r.bank].generation},
                           &head_manager.slots[r.bank].identity) != 0) return -1;
        post_tail=(post_tail+1U)%AI_MODEL_RESULT_QUEUE_CAPACITY;post_count++;
    }
    while(!hardware_faulted && head_queue.ready_count && ai_ppu_queue_ready()) {
        AiHeadSlot *slot;
        if(ai_head_slot_start_next(&head_queue,&slot)!=1) return -1;
        uint32_t key=head_queue.active;
        head_profiles[key].ppu_queue_wait_cycles=read_cycle()-head_ready_cycles[key];
        if(ai_ppu_queue_submit(&slot->descriptor)!=1) return -1;
        head_queue.active=AI_HEAD_SLOT_INVALID;
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
    if (ai_ppu_queue_active()) return service_queued_postprocess();
    if (hardware_worker != AI_MODEL_WORKER_COUNT) {
        slot = ai_head_slot_get(&head_queue, head_queue.active);
        if (slot == 0 || slot->state != AI_HEAD_SLOT_PROCESSING ||
            slot->descriptor.worker_id != hardware_worker)
            return -1;
        worker_id = hardware_worker;
        if (!slot->producer_complete) { hardware_start_cycles = read_cycle(); return 0; }
        if (hardware_faulted != 0U)
            return 0;
        hw_status = ai_ppu_device_status();
        if (!(hw_status & PPU_STATUS_DONE)) {
            if (read_cycle() - hardware_start_cycles >
                (uint64_t)SOC_CLOCK_HZ * UINT64_C(30)) {
                console_puts("AI PPU timeout status=");
                console_put_hex32(hw_status);
                console_puts("\r\n");
                slot->error_status = UINT32_C(0x80000000) | hw_status;
                hardware_faulted = 1U;
                rt_head_fault(&head_manager, head_queue.active);
                // A busy reader might still touch its arena.  Keep that
                // slot PROCESSING and the PPU reserved until board reset.
            }
            return 0;
        }
        if (hw_status & (PPU_STATUS_BUSY | PPU_STATUS_READ_BUSY)) {
            rt_head_fault(&head_manager, head_queue.active);
            hardware_faulted = 1U; return -1;
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
        uint32_t retired_key = head_queue.active;
        if (ai_head_slot_complete(&head_queue, hw_status & PPU_STATUS_ERROR) != 0) return -1;
        if (rt_head_retire(&head_manager, &head_queue,
                           (AiRtSlotHandle){retired_key, head_manager.slots[retired_key].generation},
                           &head_manager.slots[retired_key].identity) != 0) return -1;
    }
    if (hardware_worker != AI_MODEL_WORKER_COUNT ||
        hardware_faulted != 0U ||
        post_count >= AI_MODEL_RESULT_QUEUE_CAPACITY)
        return 0;
    hw_status = ai_ppu_device_status();
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

#if YOLO32_LIVE
void yolo32_ppu_io_barrier(void)
{
    /* A CPU uncached read orders preceding PPU writes without a global RoCC
     * fence. Head coherence is supplied by local completion and Flush64. */
    cache_compiler_barrier();
    if (!ai_ppu_publication_available()) yolo32_fail("live_ppu_io_commit");
    cache_compiler_barrier();
}

void yolo32_ppu_early_service(void)
{
    const Yolo32IndependentStats *stats = yolo32_independent_stats();
    for (uint32_t w = 0; w < AI_MODEL_WORKER_COUNT; ++w) {
        uint32_t delta = stats->head_produced_mask[w] & ~published_heads[w];
        if (!running[w] || stages[w] == YOLOV5_STAGE_ERROR || !delta) continue;
        AiHeadSlot *slot = ai_head_slot_get(&head_queue, worker_head_slot[w]);
        if (!slot || slot->state != AI_HEAD_SLOT_WRITING || slot->producer_complete ||
            (delta & ~yolo32_independent_head_mask(w)))
            yolo32_fail("live_head_slot_state");
        for (uint32_t h = 0; h < 6; ++h)
            if ((delta & (1U << h)) &&
                (!stats->head_requests[w][h] ||
                 stats->head_completed_cycle[w][h] < start_cycles[w]))
                yolo32_fail("live_head_completion_proof");
        ai_ppu_publication_publish(slot->descriptor.base_addr, delta);
        uint32_t cumulative = published_heads[w] | delta;
        uint64_t start = read_cycle();
        for (;;) {
            AiPpuDeviceReceipt receipt;
            ai_ppu_device_publication_receipt(&receipt);
            if (!ai_ppu_device_receipt_matches(slot->descriptor.base_addr, &receipt))
                yolo32_fail("live_head_ownership");
            if (((receipt.masks >> 8) & 63U) == cumulative) break;
            if (read_cycle() - start > UINT64_C(1000000))
                yolo32_fail("live_head_commit_timeout");
        }
        published_heads[w] = cumulative;
        head_manager.slots[worker_head_slot[w]].producer_mask = cumulative;
    }
    if (service_hardware_postprocess() < 0) hardware_faulted = 1;
}

__attribute__((noreturn)) void yolo32_fail(const char *reason)
{
    console_puts("V17A runtime fault: ");
    console_puts(reason);
    console_puts("\r\n");
    for (;;) cpu_wfi();
}
#endif

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
    if (stages[worker_id] == YOLOV5_STAGE_ERROR) return -2;

#if YOLO32_LIVE
    (void)yolo32_independent_step();
    yolo32_ppu_early_service();
    status = (yolo32_independent_stats()->done_mask & (1U << worker_id)) &&
             yolo32_independent_finished(worker_id) ?
             YOLOV5NU_DIM16_HEAD_READY : YOLOV5NU_DIM16_RUNNING;
#else
    status = yolov5nu_dim16_worker_poll(worker_id, &raw_results[worker_id]);
#endif
    if (status == YOLOV5NU_DIM16_RUNNING)
        return 0;
    if (status == YOLOV5NU_DIM16_HEAD_READY) {
        uint32_t slot_key = worker_head_slot[worker_id];
        if (slot_key == AI_HEAD_SLOT_INVALID ||
            ai_head_slot_publish(&head_queue, slot_key) != 0) {
            hold_backend_fault(worker_id);
            return -2;
        }
#if YOLO32_LIVE
        if (published_heads[worker_id] != 63U) yolo32_fail("live_unpublished_heads");
        head_ready_cycles[slot_key] = read_cycle();
#else
        ai_ppu_publication_publish(ai_head_slot_get_const(&head_queue, slot_key)->descriptor.base_addr, 63U);
#endif
        fill_compute_completion(worker_id, completion);
        /* Class0 may already have admitted this slot while the graph ran. */
        uint64_t queue_wait = head_profiles[slot_key].ppu_queue_wait_cycles;
        if (!ai_ppu_publication_available()) head_ready_cycles[slot_key] = read_cycle();
        head_profiles[slot_key] = completion->profile;
        if (ai_head_slot_get_const(&head_queue, slot_key)->state == AI_HEAD_SLOT_PROCESSING)
            head_profiles[slot_key].ppu_queue_wait_cycles = queue_wait;
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
#if YOLO32_LIVE
        yolo32_independent_live_release(worker_id);
#endif
        yolov5nu_dim16_worker_finish_hardware(worker_id);
        head_manager.slots[slot_key].producer_mask = 63U;
        AiRtJobIdentity proof = rt_job_identity(completion->job_id, completion->worker_id,
            completion->stream_id, completion->frame_id, completion->version);
        if (rt_arena_compute_done(&arena_manager, &proof) != 0) {
            hold_backend_fault(worker_id); return -2;
        }
        worker_head_slot[worker_id] = AI_HEAD_SLOT_INVALID;
        stages[worker_id] = YOLOV5_STAGE_COMPLETE;
        running[worker_id] = 0U;
        if (service_hardware_postprocess() < 0)
            hardware_faulted = 1U;
        return 1;
    }
    if (status != YOLOV5NU_DIM16_DONE || post_count >= AI_MODEL_RESULT_QUEUE_CAPACITY) {
        hold_backend_fault(worker_id);
        return -2;
    }
    AiHeadSlotDescriptor descriptor;
    AiPostprocessCompletion *record = &post_completions[post_tail];
    descriptor_from_request(worker_id, &descriptor);
    fill_post_completion(record, &descriptor, 0);
    translate_result(worker_id, &record->result);
    post_tail = (post_tail + 1U) % AI_MODEL_RESULT_QUEUE_CAPACITY;
    post_count++;
    AiRtJobIdentity proof = rt_job_identity(requests[worker_id].job_id, worker_id,
        requests[worker_id].stream_id, requests[worker_id].frame_id, requests[worker_id].version);
    if (rt_arena_compute_done(&arena_manager, &proof) != 0) {
        hold_backend_fault(worker_id); return -2;
    }
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
    for (uint32_t key = 0; key < AI_MODEL_WORKER_COUNT*2U; ++key)
        if (head_queue.slots[key].state != AI_HEAD_SLOT_FREE ||
            head_manager.slots[key].state != AI_RT_FREE) return 0U;
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        if (running[worker] != 0U || arena_manager.workers[worker].state != AI_RT_FREE)
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
    if (running[worker_id] != 0U || arena_manager.workers[worker_id].state != AI_RT_FREE) {
        hold_backend_fault(worker_id);
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

void ai_model_backend_get_resources(AiModelResourceSnapshot *snapshot)
{
    if (!snapshot) return;
    memset(snapshot, 0, sizeof(*snapshot));
    snapshot->unsafe_fault = arena_manager.unsafe_fault + head_manager.unsafe_fault;
    for (uint32_t w = 0; w < AI_MODEL_WORKER_COUNT; ++w) {
        snapshot->arenas[w] = arena_manager.workers[w];
        snapshot->arenas[w].activation_base = yolov5nu_dim16_worker_arena(w);
        if (snapshot->arenas[w].state != AI_RT_FREE) snapshot->activation_held |= 1U << w;
    }
    for (uint32_t key = 0; key < AI_MODEL_WORKER_COUNT * 2U; ++key) {
        snapshot->heads[key] = head_manager.slots[key];
        snapshot->heads[key].queue_state = head_queue.slots[key].state;
        snapshot->heads[key].producer_complete = head_queue.slots[key].producer_complete;
        if (snapshot->heads[key].state != AI_RT_FREE || head_queue.slots[key].state != AI_HEAD_SLOT_FREE)
            snapshot->owned_head |= 1U << key;
    }
}
