#ifndef RT_POSTPROCESS_SERVICE_H
#define RT_POSTPROCESS_SERVICE_H

#include "ai/backend/ai_model_abi.h"
#include "ai/postprocess/ai_detection.h"
#include "ai/runtime/resources/rt_resources.h"

/* Synchronous events borrow no model state. Partial Head proof authorizes
 * publication only; graph completion and PPU retirement remain separate. */
typedef struct {
    AiRtJobIdentity identity;
    uint32_t produced_mask;
    uint32_t local_completed_mask;
    uint32_t requested_mask;
    uint64_t start_cycle;
    uint64_t completed_cycle[6];
} AiRtHeadEvent;

/* Internal singleton interface, serialized by the existing backend facade.
 * Lifecycle helpers require a validated worker and an initialized service.
 * begin failure retains the reservation; only pre-publication cancellation
 * may give it back. init refuses to erase outstanding Head/results/faults. */
void rt_postprocess_init(void);
uint32_t rt_postprocess_hardware_present(void);
uint32_t rt_postprocess_faulted(void);
int rt_postprocess_submit_allowed(void);
int rt_postprocess_reserve(const AiModelFrameRequest *request);
void rt_postprocess_cancel_reservation(uint32_t worker);
int rt_postprocess_begin(uint32_t worker);
void rt_postprocess_expect(const AiModelFrameRequest *request);
uintptr_t rt_postprocess_head_base(uint32_t worker);
void rt_postprocess_fault(uint32_t worker);
void rt_postprocess_progress(void);
void rt_postprocess_legacy_head(const AiRtJobIdentity *identity, unsigned head);
void rt_postprocess_producer_start(uint32_t worker);
uint32_t rt_postprocess_producer_mask(uint32_t worker);
void rt_postprocess_live_head(const AiRtHeadEvent *event);
int rt_postprocess_graph_complete(const AiRtJobIdentity *proof);
void rt_postprocess_profile(uint32_t worker, const AiFrameProfile *profile,
                            uint64_t start_cycle);
void rt_postprocess_producer_finished(uint32_t worker);
void rt_postprocess_producer_release(uint32_t worker);
uint32_t rt_postprocess_result_capacity(void);
int rt_postprocess_cpu_result(const AiModelFrameRequest *request,
                             const AiDetectionResult *result);
int rt_postprocess_poll_result(AiModelFrameCompletion *completion);
uint32_t rt_postprocess_is_idle(void);
void rt_postprocess_get_resources(AiModelResourceSnapshot *snapshot);

#endif
