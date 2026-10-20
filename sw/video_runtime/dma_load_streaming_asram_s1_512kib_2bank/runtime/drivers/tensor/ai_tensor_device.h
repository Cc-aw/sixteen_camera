#ifndef AI_TENSOR_DEVICE_H
#define AI_TENSOR_DEVICE_H

#include <stdint.h>

#define AI_TENSOR_DEVICE_SLOT_COUNT 32U
#define AI_TENSOR_DEVICE_READY 2U

/* Device metadata only. Job ownership and generation handles belong to the
 * Runtime; the hardware version remains a separate identity field. */
typedef struct {
    uint32_t tensor_addr;
    uint32_t stream_id;
    uint64_t frame_id;
    uint64_t timestamp;
    uint32_t version;
    uint32_t byte_count;
    uint32_t error_code;
    uint32_t state;
} AiTensorDeviceDescriptor;

typedef enum {
    AI_TENSOR_COUNTER_OUTSTANDING = 0,
    AI_TENSOR_COUNTER_OUTSTANDING_MAX,
    AI_TENSOR_COUNTER_STARVATION,
    AI_TENSOR_COUNTER_AW_STALL,
    AI_TENSOR_COUNTER_W_STALL,
    AI_TENSOR_COUNTER_W_TRANSFER,
    AI_TENSOR_COUNTER_B_WAIT,
    AI_TENSOR_COUNTER_BURSTS,
    AI_TENSOR_COUNTER_COMPLETED,
    AI_TENSOR_COUNTER_RESP_ERRORS,
    AI_TENSOR_COUNTER_ERROR_CODE,
    AI_TENSOR_COUNTER_FRAME,
    AI_TENSOR_COUNTER_VERSION,
    AI_TENSOR_COUNTER_OVERFLOW,
    AI_TENSOR_COUNTER_COUNT
} AiTensorDeviceCounter;

/* Recent completed video frames, intersected with the requested input mask. */
uint32_t ai_tensor_device_active_inputs(void);
uint32_t ai_tensor_device_ready(void);
uint32_t ai_tensor_device_error(void);
uint32_t ai_tensor_device_writing(void);

/* Synchronous legacy protocol: 0 = confirmed, -1 = invalid/timeout/rejected.
 * Read accepts only a stable READY descriptor and leaves output unchanged on
 * failure. Release preserves the caller's producer-enabled state; success
 * alone says nothing about whether that caller safely stopped its consumer. */
int ai_tensor_device_read_slot(uint32_t slot, AiTensorDeviceDescriptor *descriptor);
int ai_tensor_device_release(uint32_t slot, uint32_t producer_enabled);
/* Non-mutating observation after a timed-out release. SLOT_PRESENT requires
 * the owner to validate current metadata before resending any release. */
enum {
    AI_TENSOR_RELEASE_WAIT = 0,
    AI_TENSOR_RELEASE_ACK = 1,
    AI_TENSOR_RELEASE_SLOT_PRESENT = 2
};
int ai_tensor_device_release_poll(uint32_t slot);
int ai_tensor_device_enable(uint32_t admission_mask, uint32_t admission_limit);
/* Drain capture into its two slots before disabling: S1 cancellation has
 * sticky ERROR state. A failed quiesce leaves production enabled. */
int ai_tensor_device_quiesce(void);
void ai_tensor_device_disable(void);

/* Diagnostic selection retains INDEX -> fence -> metadata-settle ordering.
 * These transactions have one CPU owner; selected counter reads are not an
 * atomic snapshot and must not be interleaved with another selection. */
int ai_tensor_device_select_slot(uint32_t slot);
uint32_t ai_tensor_device_read_counter(AiTensorDeviceCounter counter);

#endif
