#ifndef RT_H
#define RT_H

#include "ai/runtime/rt_types.h"
#include "ai/postprocess/ai_detection.h"

/* Singleton facade. poll retains synchronous device waits and the original
 * service order; it does not promise a hard execution-time budget. */
int rt_init(void);
void rt_set_enabled(uint32_t enabled);
uint32_t rt_is_enabled(void);
uint32_t rt_is_idle(void);
AiRtState rt_state(void);
void rt_poll(void);
void rt_get_status(AiRtStatus *status);
int rt_get_stream_status(uint32_t stream, AiRtStreamStatus *status);
/* Borrowed result retains the existing lifetime across Runtime polls. */
const AiDetectionResult *rt_latest_result(uint32_t stream);
uint32_t rt_frame_metrics_count(void);
/* Chronological index, oldest first. Copies only; no IO/progress/consumption. */
int rt_get_frame_metrics(uint32_t index, AiRtFrameMetrics *metrics);

#endif
