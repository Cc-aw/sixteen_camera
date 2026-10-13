#include "ai/runtime/services/rt_postprocess_service.h"

#include <string.h>
#include "ai/runtime/ai_head_slot_queue.h"
#include "ai/runtime/resources/rt_head_manager.h"
#include "ai/postprocess/ai_ppu_publication.h"
#include "ai/postprocess/ai_ppu_queue.h"
#include "drivers/ppu/ai_ppu_device.h"
#include "platform/cache_ops.h"
#include "platform/console.h"
#include "mmio.h"
#include "yolov5nu_head_layout.h"
#ifndef YOLO32_LIVE
#define YOLO32_LIVE 0
#endif
#if YOLO32_LIVE
#include "yolo32.h"
#include "ppu.h"
static uint32_t published_heads[AI_MODEL_WORKER_COUNT];
#endif
#define PPU_STATUS_BUSY AI_PPU_DEVICE_STATUS_BUSY
#define PPU_STATUS_DONE AI_PPU_DEVICE_STATUS_DONE
#define PPU_STATUS_ERROR AI_PPU_DEVICE_STATUS_ERROR
#define PPU_STATUS_READ_BUSY AI_PPU_DEVICE_STATUS_READ_BUSY
#define AI_STREAM_HOTPATH_LOG 0

_Static_assert(AI_MODEL_WORKER_COUNT <= AI_HEAD_SLOT_QUEUE_MAX_WORKERS,
               "Head service is smaller than the model worker pool");

/* Singleton, matching the physical PPU. All Head leases and result storage
 * live here; the model backend owns only its activation arenas. */
static uint32_t initialized;
static uint32_t hardware_present;
static uint32_t hardware_worker;
static uint32_t hardware_log_count;
static uint32_t queue_log_count;
static uint64_t hardware_start_cycles;
static uint64_t head_ready_cycles[AI_HEAD_SLOT_QUEUE_CAPACITY];
static AiFrameProfile head_profiles[AI_HEAD_SLOT_QUEUE_CAPACITY];
static AiHeadSlotQueue head_queue;
static AiRtHeadManager head_manager;
static uint32_t worker_head_slot[AI_MODEL_WORKER_COUNT];
typedef struct {
    AiModelFrameCompletion completion;
    AiDetectionResult result;
} AiPostprocessCompletion;
static AiPostprocessCompletion post_completions[
    (AI_MODEL_WORKER_COUNT * 2U)];
static uint32_t post_head;
static uint32_t post_tail;
static uint32_t post_count;
static uint32_t hardware_faulted;

static int service_hardware_postprocess(void);

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

static int service_queued_postprocess(void)
{
    AiPpuQueueResult r;
    if (post_count < (AI_MODEL_WORKER_COUNT * 2U) && ai_ppu_queue_peek(&r)) {
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
        post_tail=(post_tail+1U)%(AI_MODEL_WORKER_COUNT * 2U);post_count++;
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
        if (post_count >= (AI_MODEL_WORKER_COUNT * 2U))
            return -1;
        record = &post_completions[post_tail];
        if (hw_status & PPU_STATUS_ERROR) {
            fill_post_completion(record, &slot->descriptor, -2);
        } else {
            read_hardware_postprocess(slot, record);
        }
        if (head_queue.active < AI_HEAD_SLOT_QUEUE_CAPACITY)
            record->completion.profile = head_profiles[head_queue.active];
        post_tail = (post_tail + 1U) % (AI_MODEL_WORKER_COUNT * 2U);
        post_count++;
        uint32_t retired_key = head_queue.active;
        if (ai_head_slot_complete(&head_queue, hw_status & PPU_STATUS_ERROR) != 0) return -1;
        if (rt_head_retire(&head_manager, &head_queue,
                           (AiRtSlotHandle){retired_key, head_manager.slots[retired_key].generation},
                           &head_manager.slots[retired_key].identity) != 0) return -1;
    }
    if (hardware_worker != AI_MODEL_WORKER_COUNT ||
        hardware_faulted != 0U ||
        post_count >= (AI_MODEL_WORKER_COUNT * 2U))
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

static AiHeadSlot *matching_head(const AiRtJobIdentity *identity)
{
    if (!identity || identity->worker_id >= AI_MODEL_WORKER_COUNT) return 0;
    uint32_t key = worker_head_slot[identity->worker_id];
    AiHeadSlot *slot = ai_head_slot_get(&head_queue, key);
    if (!slot ||
        !rt_job_identity_matches(identity, &head_manager.slots[key].identity)) return 0;
    return slot;
}

void rt_postprocess_init(void)
{
    if (initialized && !rt_postprocess_is_idle()) return;
#if YOLO32_LIVE
    memset(published_heads, 0, sizeof(published_heads));
#endif
    memset(post_completions, 0, sizeof(post_completions));
    memset(head_ready_cycles, 0, sizeof(head_ready_cycles));
    memset(head_profiles, 0, sizeof(head_profiles));
    hardware_present = ai_ppu_device_available();
    hardware_worker = AI_MODEL_WORKER_COUNT;
    hardware_log_count = 0U;
    queue_log_count = 0U;
    hardware_start_cycles = 0U;
    hardware_faulted = 0U;
    post_head = post_tail = post_count = 0U;
    ai_head_slot_queue_init(&head_queue, AI_MODEL_WORKER_COUNT);
    rt_head_manager_init(&head_manager);
    for (uint32_t worker = 0U; worker < AI_MODEL_WORKER_COUNT; ++worker)
        worker_head_slot[worker] = AI_HEAD_SLOT_INVALID;
    if (hardware_present) (void)ai_ppu_queue_init();
#if YOLO32_LIVE
    if (hardware_present) {
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

uint32_t rt_postprocess_hardware_present(void) { return hardware_present; }
uint32_t rt_postprocess_faulted(void) { return hardware_faulted; }

int rt_postprocess_submit_allowed(void)
{
#if YOLO32_LIVE
    if (!hardware_present || !ai_ppu_publication_available() ||
        !ai_ppu_queue_active() || hardware_faulted) return 0;
#endif
    return !hardware_faulted;
}

int rt_postprocess_reserve(const AiModelFrameRequest *request)
{
    uint32_t key = AI_HEAD_SLOT_INVALID;
    if (hardware_present && ((request->output_addr & 63U) != 0U ||
        request->output_bytes < YOLOV5NU_HEAD_POOL_BYTES)) return -1;
    if (hardware_present && ai_head_slot_acquire(&head_queue, request->worker_id,
        request->output_addr, request, &key) != 0) return -3;
    worker_head_slot[request->worker_id] = key;
    return 0;
}

void rt_postprocess_cancel_reservation(uint32_t worker)
{
    uint32_t key = worker_head_slot[worker];
    if (key != AI_HEAD_SLOT_INVALID)
        (void)ai_head_slot_release_writing(&head_queue, key);
    worker_head_slot[worker] = AI_HEAD_SLOT_INVALID;
}

int rt_postprocess_begin(uint32_t worker)
{
    if (hardware_present) {
        uint32_t key = worker_head_slot[worker];
        const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue, key);
        if (!slot || rt_head_bind(&head_manager, &head_queue, key,
            ai_ppu_publication_generation(slot->descriptor.base_addr)) != 0) return -1;
        if (ai_ppu_publication_begin(slot->descriptor.base_addr) < 0) return -1;
        head_manager.slots[key].hardware_generation =
            ai_ppu_publication_generation(slot->descriptor.base_addr);
    }
    return 0;
}

uintptr_t rt_postprocess_head_base(uint32_t worker)
{
    const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue, worker_head_slot[worker]);
    return slot ? AI_DDR_CPU_ALIAS(slot->descriptor.base_addr) : 0U;
}

void rt_postprocess_fault(uint32_t worker)
{
    hardware_faulted = 1U;
    if (worker < AI_MODEL_WORKER_COUNT)
        rt_head_fault(&head_manager, worker_head_slot[worker]);
}

void rt_postprocess_progress(void)
{
    if (hardware_present && service_hardware_postprocess() < 0)
        hardware_faulted = 1U;
}

void rt_postprocess_legacy_head(const AiRtJobIdentity *identity, unsigned head)
{
    if (!ai_ppu_publication_available()) return;
    AiHeadSlot *slot = matching_head(identity);
    if (!slot || head >= 6U) return;
    uint32_t key = worker_head_slot[identity->worker_id];
    ai_ppu_publication_publish(slot->descriptor.base_addr, 1U << head);
    head_manager.slots[key].producer_mask |= 1U << head;
    if (head == 0 && slot->state == AI_HEAD_SLOT_WRITING && !YOLO32_LIVE) {
        head_ready_cycles[key] = read_cycle();
        memset(&head_profiles[key], 0, sizeof(head_profiles[key]));
        if (ai_head_slot_admit(&head_queue, key) == 0)
            (void)service_hardware_postprocess();
    }
}

void rt_postprocess_producer_start(uint32_t worker)
{
#if YOLO32_LIVE
    published_heads[worker] = 0;
#else
    (void)worker;
#endif
}

uint32_t rt_postprocess_producer_mask(uint32_t worker)
{
#if YOLO32_LIVE
    return worker < AI_MODEL_WORKER_COUNT ? published_heads[worker] : 0U;
#else
    (void)worker;
    return 0U;
#endif
}

void rt_postprocess_live_head(const AiRtHeadEvent *event)
{
#if YOLO32_LIVE
    AiHeadSlot *slot = matching_head(&event->identity);
    uint32_t delta = event->produced_mask;
    if (!slot || slot->state != AI_HEAD_SLOT_WRITING || slot->producer_complete ||
        (delta & ~event->local_completed_mask) || (delta & ~63U))
        yolo32_fail("live_head_slot_state");
    for (uint32_t h = 0; h < 6; ++h)
        if ((delta & (1U << h)) && (!(event->requested_mask & (1U << h)) ||
            event->completed_cycle[h] < event->start_cycle))
            yolo32_fail("live_head_completion_proof");
    ai_ppu_publication_publish(slot->descriptor.base_addr, delta);
    uint32_t key = worker_head_slot[event->identity.worker_id];
    uint32_t cumulative = published_heads[event->identity.worker_id] | delta;
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
    published_heads[event->identity.worker_id] = cumulative;
    head_manager.slots[key].producer_mask = cumulative;
#else
    (void)event;
#endif
}

int rt_postprocess_graph_complete(const AiRtJobIdentity *proof)
{
    AiHeadSlot *slot = matching_head(proof);
    if (!slot) return -1;
    uint32_t key = worker_head_slot[proof->worker_id];
    if (ai_head_slot_publish(&head_queue, key) != 0) return -1;
#if YOLO32_LIVE
    if (published_heads[proof->worker_id] != 63U)
        yolo32_fail("live_unpublished_heads");
    head_ready_cycles[key] = read_cycle();
#else
    ai_ppu_publication_publish(slot->descriptor.base_addr, 63U);
#endif
    return 0;
}

void rt_postprocess_profile(uint32_t worker, const AiFrameProfile *profile,
                            uint64_t start_cycle)
{
    uint32_t key = worker_head_slot[worker];
    uint64_t queue_wait = head_profiles[key].ppu_queue_wait_cycles;
    if (!ai_ppu_publication_available()) head_ready_cycles[key] = read_cycle();
    head_profiles[key] = *profile;
    const AiHeadSlot *slot = ai_head_slot_get_const(&head_queue, key);
    if (slot->state == AI_HEAD_SLOT_PROCESSING)
        head_profiles[key].ppu_queue_wait_cycles = queue_wait;
    if (AI_STREAM_HOTPATH_LOG != 0 && queue_log_count < 8U) {
        queue_log_count++;
        console_puts("AI PPU enqueue worker/slot/job/ready/cycles=");
        console_put_u32(worker); console_putc('/');
        console_put_u32(slot->slot_id); console_putc('/');
        console_put_hex64(slot->descriptor.job_id); console_putc('/');
        console_put_u32(head_queue.ready_count); console_putc('/');
        console_put_u32((uint32_t)(read_cycle() - start_cycle));
        console_puts("\r\n");
    }
}

void rt_postprocess_producer_finished(uint32_t worker)
{
    head_manager.slots[worker_head_slot[worker]].producer_mask = 63U;
}

void rt_postprocess_producer_release(uint32_t worker)
{
    worker_head_slot[worker] = AI_HEAD_SLOT_INVALID;
}

uint32_t rt_postprocess_result_capacity(void)
{
    return post_count < (AI_MODEL_WORKER_COUNT * 2U);
}

int rt_postprocess_cpu_result(const AiModelFrameRequest *request,
                             const AiDetectionResult *result)
{
    if (!rt_postprocess_result_capacity()) return -1;
    AiHeadSlotDescriptor descriptor = {0};
    descriptor.job_id = request->job_id;
    descriptor.worker_id = request->worker_id;
    descriptor.stream_id = request->stream_id;
    descriptor.frame_id = request->frame_id;
    descriptor.timestamp = request->timestamp;
    descriptor.version = request->version;
    AiPostprocessCompletion *record = &post_completions[post_tail];
    fill_post_completion(record, &descriptor, 0);
    record->result = *result;
    post_tail = (post_tail + 1U) % (AI_MODEL_WORKER_COUNT * 2U);
    post_count++;
    return 0;
}

int rt_postprocess_poll_result(AiModelFrameCompletion *completion)
{
    rt_postprocess_progress();
    if (post_count != 0U) {
        *completion = post_completions[post_head].completion;
        post_head = (post_head + 1U) % (AI_MODEL_WORKER_COUNT * 2U);
        post_count--;
        return 1;
    }
    return hardware_faulted != 0U ? -2 : 0;
}

uint32_t rt_postprocess_is_idle(void)
{
    if (!initialized || hardware_faulted || post_count || hardware_worker != AI_MODEL_WORKER_COUNT ||
        head_queue.ready_count || head_queue.active != AI_HEAD_SLOT_INVALID) return 0;
    for (uint32_t key = 0; key < AI_MODEL_WORKER_COUNT * 2U; ++key)
        if (head_queue.slots[key].state != AI_HEAD_SLOT_FREE ||
            head_manager.slots[key].state != AI_RT_FREE) return 0;
    return 1;
}

void rt_postprocess_get_resources(AiModelResourceSnapshot *snapshot)
{
    snapshot->unsafe_fault += head_manager.unsafe_fault;
    for (uint32_t key = 0; key < AI_MODEL_WORKER_COUNT * 2U; ++key) {
        snapshot->heads[key] = head_manager.slots[key];
        snapshot->heads[key].queue_state = head_queue.slots[key].state;
        snapshot->heads[key].producer_complete = head_queue.slots[key].producer_complete;
        if (snapshot->heads[key].state != AI_RT_FREE || head_queue.slots[key].state != AI_HEAD_SLOT_FREE)
            snapshot->owned_head |= 1U << key;
    }
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
#endif

void rt_postprocess_expect(const AiModelFrameRequest *request)
{
    ai_ppu_queue_expect(request->stream_id, request->frame_id, request->version);
}
