#ifndef RT_INTERNAL_H
#define RT_INTERNAL_H

/* Private per-runtime context shared by core, scheduler and services. */
#include "ai/runtime/rt.h"
typedef AiRtStatus AiBatchRuntimeStatus;
typedef AiRtStreamStatus AiStreamRuntimeStatus;
#include "ai/backend/rt_backend.h"
#include "ai/runtime/ai_tensor_slot_pool.h"
#include "ai/runtime/resources/rt_tensor_manager.h"
#include "ai/runtime/core/rt_state.h"
#include "ai/postprocess/ai_overlay.h"
#include "ai/postprocess/ai_postprocess.h"
#include "ai/postprocess/ai_result_manager.h"
#include "drivers/tensor/ai_tensor_device.h"

#ifndef STREAM_MODEL_TIMEOUT_SECONDS
#define STREAM_MODEL_TIMEOUT_SECONDS 50
#endif
#define STREAM_MODEL_TIMEOUT (SOC_CLOCK_HZ * STREAM_MODEL_TIMEOUT_SECONDS)
#define STREAM_TARGET_PERIOD (SOC_CLOCK_HZ / UINT64_C(30))
#define STREAM_RESULT_TTL (SOC_CLOCK_HZ * UINT64_C(3))
#define STREAM_PROFILE_CAPACITY 16U

typedef struct {
    AiRtJob job;
    AiRtSlotHandle tensor_handle;
    uint32_t active;
    uint32_t release_pending;
    uint32_t release_attempted;
    uint32_t slot;
    uint32_t stream;
    uint32_t version;
    uint64_t frame_id;
    uint64_t timestamp;
    uint64_t job_id;
    uint64_t start_cycle;
    AiFrameProfile profile;
} AiRtWorker;

typedef struct {
    AiRtJob job;
    uint32_t active;
    uint32_t worker;
    uint32_t stream;
    uint32_t version;
    uint64_t frame_id;
    uint64_t timestamp;
    uint64_t job_id;
    uint64_t start_cycle;
    AiFrameProfile profile;
} AiRtPostJob;

typedef struct {
    uint64_t job_id;
    uint64_t frame_id;
    uint32_t stream;
    uint32_t worker;
    AiFrameProfile profile;
} AiRtProfileRecord;

typedef struct {
    AiRtBackend backend;
    AiBatchRuntimeStatus status;
    AiStreamRuntimeStatus streams[VIDEO_CHANNEL_COUNT];
    AiRtWorker workers[AI_MODEL_WORKER_COUNT];
    AiRtPostJob post_jobs[AI_MODEL_POSTPROCESS_CAPACITY];
    AiResultManager results;
    AiPostprocessWorkspace postprocess_workspace;
    uint16_t overlay_dirty;
    uint16_t overlay_clear;
    AiRtTensorManager tensors;
    uint32_t admission_mask;
    uint32_t admission_restart;
    uint32_t initialized;
    AiRtControl control;
    uint64_t next_job_id;
    uint64_t ready_seen_cycle[AI_TENSOR_SLOT_COUNT];
    uint64_t head_wait_start[AI_TENSOR_SLOT_COUNT];
    AiRtProfileRecord profiles[STREAM_PROFILE_CAPACITY];
    uint32_t profile_head;
    uint32_t profile_count;
} AiRtCore;


AiRtCore *rt_core_instance(void);

void rt_record_error(AiRtCore *rt, int error);
uint32_t rt_post_job_count(AiRtCore *rt);
void rt_core_init(AiRtCore *rt);
void rt_complete_stream_job(AiRtCore *rt, uint32_t stream_id, uint64_t frame_id,
                                uint32_t version, int error);
void rt_record_frame_profile(AiRtCore *rt, const AiRtPostJob *post,
                                 const AiRtBackendResultCompletion *completion);
AiRtPostJob *rt_find_post_job(AiRtCore *rt, uint64_t job_id);
void rt_pipeline_hold_worker_fault(AiRtCore *rt, AiRtWorker *worker, int error);
void rt_pipeline_workers(AiRtCore *rt);
void rt_pipeline_results(AiRtCore *rt);
uint32_t rt_has_no_owners(AiRtCore *rt);
void rt_state_set_enabled(AiRtCore *rt, uint32_t enabled);
uint32_t rt_state_is_idle(AiRtCore *rt);
uint32_t rt_tensor_ready(AiRtCore *rt);
uint32_t rt_tensor_error(AiRtCore *rt);
uint32_t rt_tensor_writing(AiRtCore *rt);
int rt_tensor_read_slot(uint32_t slot, AiTensorSlot *metadata);
int rt_tensor_release_slot(AiRtCore *rt, uint32_t slot);
void rt_tensor_track_ready(AiRtCore *rt, uint32_t ready);
void rt_tensor_service_stale(AiRtCore *rt, uint32_t ready);
void rt_overlay_service(AiRtCore *rt);
void rt_result_service_ttl(AiRtCore *rt);
int rt_result_service_publish(AiRtCore *rt, const AiDetectionResult *result, uint32_t stream);
void rt_dispatch_jobs(AiRtCore *rt, uint32_t ready);
uint32_t rt_tensor_drain_one(AiRtCore *rt, uint32_t ready);
void rt_state_poll_admission(AiRtCore *rt);
#endif
