#include "ai/backend/ai_model_backend.h"

#include <string.h>

#include "ai/postprocess/ai_detection.h"
#include "ai/runtime/services/rt_postprocess_service.h"
#include "ai/runtime/resources/rt_arena_manager.h"
#include "platform/console.h"
#include "mmio.h"
#include "yolov5nu_dim16_dual.h"
#ifndef YOLO32_LIVE
#define YOLO32_LIVE 0
#endif
#if YOLO32_LIVE
#include "yolo32.h"
#include "independent.h"
#include "ppu.h"
#endif

enum {
    YOLOV5_STAGE_IDLE = 0,
    YOLOV5_STAGE_RUNNING = 1,
    YOLOV5_STAGE_COMPLETE = 2,
    YOLOV5_STAGE_ERROR = 3
};

_Static_assert(AI_MODEL_WORKER_COUNT == YOLOV5NU_DIM16_WORKER_COUNT,
               "backend and accelerator worker counts must match");

static AiModelFrameRequest requests[AI_MODEL_WORKER_COUNT];
static struct yolov5nu_dim16_result raw_results[AI_MODEL_WORKER_COUNT];
static uint32_t running[AI_MODEL_WORKER_COUNT];
static uint32_t stages[AI_MODEL_WORKER_COUNT];
static uint64_t start_cycles[AI_MODEL_WORKER_COUNT];
static uint32_t initialized;
static AiRtArenaManager arena_manager;

static void hold_backend_fault(uint32_t worker)
{
    rt_postprocess_fault(worker);
    stages[worker] = YOLOV5_STAGE_ERROR;
    rt_arena_fault(&arena_manager, worker);
    /* No completion proof: retain model, activation and Head ownership. */
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

static AiRtJobIdentity worker_identity(uint32_t worker)
{
    const AiModelFrameRequest *request = &requests[worker];
    return rt_job_identity(request->job_id, worker, request->stream_id,
                           request->frame_id, request->version);
}

static void head_published(unsigned worker, unsigned head)
{
    if (worker >= AI_MODEL_WORKER_COUNT || stages[worker] == YOLOV5_STAGE_ERROR) return;
    AiRtJobIdentity identity = worker_identity(worker);
    rt_postprocess_legacy_head(&identity, head);
}

void ai_model_backend_init(void)
{
    if (initialized && !ai_model_backend_is_idle()) return;
    memset(requests, 0, sizeof(requests));
    memset(raw_results, 0, sizeof(raw_results));
    memset(running, 0, sizeof(running));
    memset(stages, 0, sizeof(stages));
    memset(start_cycles, 0, sizeof(start_cycles));
    yolov5nu_dim16_dual_init();
    yolov5nu_dim16_set_head_callback(head_published);
#if YOLO32_LIVE
    yolo32_independent_live_init();
#endif
    rt_postprocess_init();
    rt_arena_manager_init(&arena_manager, AI_MODEL_WORKER_COUNT);
    initialized = 1U;
}

int ai_model_backend_submit(const AiModelFrameRequest *request)
{
    if (initialized == 0U || request == 0) return -1;
    if (!rt_postprocess_submit_allowed()) return -2;
    uint32_t worker = request->worker_id;
    if (worker >= AI_MODEL_WORKER_COUNT || running[worker] != 0U ||
        request->input_addr == 0U || request->input_bytes != AI_YOLOV5NU_INPUT_BYTES ||
        yolov5nu_dim16_worker_is_idle(worker) == 0) return -1;
    requests[worker] = *request;
    const int8_t *input = (const int8_t *)AI_DDR_CPU_ALIAS(request->input_addr);
    int reserved = rt_postprocess_reserve(request);
    if (reserved != 0) return reserved;
    AiRtJobIdentity identity = worker_identity(worker);
    if (rt_arena_claim(&arena_manager, &identity) != 0) {
        rt_postprocess_cancel_reservation(worker);
        return -2;
    }
    if (rt_postprocess_begin(worker) != 0) {
        hold_backend_fault(worker); return AI_MODEL_SUBMIT_FAULT_HELD;
    }
    rt_postprocess_expect(request);
    if (yolov5nu_dim16_worker_start(worker, input) < 0) {
        hold_backend_fault(worker); return AI_MODEL_SUBMIT_FAULT_HELD;
    }
    yolov5nu_dim16_worker_set_head_slot(worker, rt_postprocess_head_base(worker));
    yolov5nu_dim16_worker_use_hardware(worker, rt_postprocess_hardware_present() != 0U);
    running[worker] = 1U;
    stages[worker] = YOLOV5_STAGE_RUNNING;
    start_cycles[worker] = read_cycle();
    rt_postprocess_producer_start(worker);
#if YOLO32_LIVE
    yolo32_independent_live_start(worker);
#endif
    return 0;
}

/* Multiple hardware descriptors own independent software slots. Completion
 * metadata is sufficient: boxes travel directly from PPU to the display. */

#if YOLO32_LIVE

void yolo32_ppu_early_service(void)
{
    const Yolo32IndependentStats *stats = yolo32_independent_stats();
    for (uint32_t w = 0; w < AI_MODEL_WORKER_COUNT; ++w) {
        uint32_t delta = stats->head_produced_mask[w] & ~rt_postprocess_producer_mask(w);
        if (!running[w] || stages[w] == YOLOV5_STAGE_ERROR || !delta) continue;
        AiRtHeadEvent event = {0};
        event.identity = worker_identity(w);
        event.produced_mask = delta;
        event.local_completed_mask = yolo32_independent_head_mask(w);
        event.start_cycle = start_cycles[w];
        for (uint32_t h = 0; h < 6; ++h) {
            if (stats->head_requests[w][h]) event.requested_mask |= 1U << h;
            event.completed_cycle[h] = stats->head_completed_cycle[w][h];
        }
        rt_postprocess_live_head(&event);
    }
    rt_postprocess_progress();
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

int ai_model_backend_poll_compute(uint32_t worker_id,
                                  AiModelComputeCompletion *completion)
{
    int status;
    if (initialized == 0U || worker_id >= AI_MODEL_WORKER_COUNT ||
        running[worker_id] == 0U || completion == 0)
        return -1;
    rt_postprocess_progress();
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
        AiRtJobIdentity identity = worker_identity(worker_id);
        if (rt_postprocess_graph_complete(&identity) != 0) {
            hold_backend_fault(worker_id);
            return -2;
        }
        fill_compute_completion(worker_id, completion);
        rt_postprocess_profile(worker_id, &completion->profile, start_cycles[worker_id]);
        /* Raw heads now belong to the slot.  The worker's activation arena
         * and input tensor are no longer needed by postprocessing. */
#if YOLO32_LIVE
        yolo32_independent_live_release(worker_id);
#endif
        yolov5nu_dim16_worker_finish_hardware(worker_id);
        rt_postprocess_producer_finished(worker_id);
        AiRtJobIdentity proof = rt_job_identity(completion->job_id, completion->worker_id,
            completion->stream_id, completion->frame_id, completion->version);
        if (rt_arena_compute_done(&arena_manager, &proof) != 0) {
            hold_backend_fault(worker_id); return -2;
        }
        rt_postprocess_producer_release(worker_id);
        stages[worker_id] = YOLOV5_STAGE_COMPLETE;
        running[worker_id] = 0U;
        rt_postprocess_progress();
        return 1;
    }
    if (status != YOLOV5NU_DIM16_DONE || !rt_postprocess_result_capacity()) {
        hold_backend_fault(worker_id);
        return -2;
    }
    AiDetectionResult result;
    translate_result(worker_id, &result);
    if (rt_postprocess_cpu_result(&requests[worker_id], &result) != 0) {
        hold_backend_fault(worker_id); return -2;
    }
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
    if (initialized == 0U || completion == 0) return -1;
    return rt_postprocess_poll_result(completion);
}

uint32_t ai_model_backend_is_idle(void)
{
    if (initialized == 0U || !rt_postprocess_is_idle()) return 0U;
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
    snapshot->unsafe_fault = arena_manager.unsafe_fault;
    for (uint32_t w = 0; w < AI_MODEL_WORKER_COUNT; ++w) {
        snapshot->arenas[w] = arena_manager.workers[w];
        snapshot->arenas[w].activation_base = yolov5nu_dim16_worker_arena(w);
        if (snapshot->arenas[w].state != AI_RT_FREE) snapshot->activation_held |= 1U << w;
    }
    rt_postprocess_get_resources(snapshot);
}
