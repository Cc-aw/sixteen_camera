#ifndef RT_RESOURCES_H
#define RT_RESOURCES_H

#include "ai/runtime/resources/rt_job.h"
#include "drivers/tensor/ai_tensor_device.h"
#define AI_RT_MAX_WORKERS 3U
#define AI_RT_HEAD_CAPACITY 6U

typedef enum {
    AI_RT_FREE,
    AI_RT_RESERVED,
    AI_RT_OWNED,
    AI_RT_RELEASE_PENDING,
    AI_RT_FAULT_HELD
} AiRtLeaseState;

typedef struct {
    uint32_t index;
    uint64_t generation;
} AiRtSlotHandle;

typedef struct {
    AiRtJobIdentity identity;
    AiRtLeaseState state;
    uint64_t generation; /* Software lease identity, never producer version. */
    AiTensorDeviceDescriptor descriptor;
} AiRtTensorLease;
typedef struct {
    AiRtJobIdentity identity;
    AiRtLeaseState state;
    uintptr_t activation_base, head_pool_base;
} AiRtArenaLease;
typedef struct {
    AiRtJobIdentity identity;
    AiRtLeaseState state;
    uint64_t generation; /* Software handle, separate from hardware generation. */
    uint32_t hardware_generation, producer_mask, producer_complete, queue_state;
    uintptr_t base;
} AiRtHeadLease;
typedef struct AiModelResourceSnapshot {
    uint32_t activation_held, owned_head, unsafe_fault;
    AiRtArenaLease arenas[AI_RT_MAX_WORKERS];
    AiRtHeadLease heads[AI_RT_HEAD_CAPACITY];
} AiModelResourceSnapshot;
typedef struct {
    /* Diagnostic snapshots do not perform device reads. Mask fields use
     * physical slot/worker indices; pending_post and retry/fault are counts. */
    uint32_t held_tensor, active_worker, pending_post, owned_head;
    uint32_t release_retry, unsafe_fault, faulted;
    uint32_t ready, error, writing;
    AiRtTensorLease tensors[AI_TENSOR_DEVICE_SLOT_COUNT];
    AiModelResourceSnapshot backend;
} AiRtResourceSnapshot;
#endif
