#ifndef RT_TYPES_H
#define RT_TYPES_H
#include <stdint.h>

typedef enum {
    AI_RT_STATE_STOPPED = 0,
    AI_RT_STATE_RUNNING,
    AI_RT_STATE_DRAINING,
    AI_RT_STATE_FAULTED
} AiRtState;

typedef struct {
    uint64_t last_frame_id;
    uint64_t last_service_cycle;
    uint64_t last_complete_cycle;
    uint64_t next_deadline;
    uint64_t max_service_gap_cycles;
    uint64_t last_result_cycle;
    uint32_t last_version;
    uint32_t dispatched_count;
    uint32_t completed_count;
    uint32_t superseded_count;
    uint32_t missed_deadline_count;
    uint32_t expired_result_count;
    uint32_t inflight_count;
    uint32_t last_frame_valid;
} AiRtStreamStatus;

typedef struct {
    uint32_t enabled;
    uint32_t phase;
    uint32_t snapshot_count;
    uint32_t preprocess_count;
    uint32_t consumed_count;
    uint32_t completed_job_count;
    uint32_t postprocess_count;
    uint32_t result_publish_count;
    uint32_t stale_result_count;
    uint32_t error_count;
    uint32_t release_retry_count;
    uint32_t recycle_error_count;
    uint32_t snapshot_release_count;
    uint64_t snapshot_hold_cycles;
    uint64_t max_snapshot_hold_cycles;
    uint32_t arena_wait_count;
    int32_t last_error;
    uint64_t last_batch_id;
    uint32_t last_valid_mask;
    uint32_t last_fresh_mask;
    uint32_t last_preprocess_cycles;
} AiRtStatus;

/* Common frame timings. Accelerator instruction/stall counters stay in
 * the diagnostic profile, outside the Application contract. */
typedef struct {
    uint64_t job_id, frame_id;
    uint32_t stream, worker;
    uint64_t cpu_scheduler_cycles, tensor_wait_cycles;
    uint64_t head_wait_cycles, ppu_queue_wait_cycles;
} AiRtFrameMetrics;
#endif
