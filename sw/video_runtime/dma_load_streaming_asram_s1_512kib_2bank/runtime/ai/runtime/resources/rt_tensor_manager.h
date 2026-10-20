#ifndef RT_TENSOR_MANAGER_H
#define RT_TENSOR_MANAGER_H
#include "ai/runtime/resources/rt_resources.h"
typedef struct {
    AiRtTensorLease slots[AI_TENSOR_DEVICE_SLOT_COUNT];
    uint32_t held, ready, error, writing, release_retry, unsafe_fault;
} AiRtTensorManager;

/* Claims capture stable READY metadata. Submit acceptance and matching compute
 * proof precede release; a failed device ack retains RELEASE_PENDING. */
void rt_tensor_manager_init(AiRtTensorManager *manager);
int rt_tensor_claim(AiRtTensorManager *manager, uint32_t slot,
                    const AiTensorDeviceDescriptor *descriptor,
                    const AiRtJobIdentity *identity, AiRtSlotHandle *handle);
int rt_tensor_prove_compute(AiRtTensorManager *manager, AiRtSlotHandle handle,
                            const AiRtJobIdentity *proof);
int rt_tensor_accept(AiRtTensorManager *manager, AiRtSlotHandle handle, const AiRtJobIdentity *identity);
int rt_tensor_reject(AiRtTensorManager *manager, AiRtSlotHandle handle, const AiRtJobIdentity *identity);
int rt_tensor_can_release(const AiRtTensorManager *manager, AiRtSlotHandle handle,
                          const AiRtJobIdentity *identity);
int rt_tensor_release_ack(AiRtTensorManager *manager, AiRtSlotHandle handle,
                          const AiRtJobIdentity *identity);
void rt_tensor_release_retry(AiRtTensorManager *manager);
void rt_tensor_fault(AiRtTensorManager *manager, AiRtSlotHandle handle);
#endif
