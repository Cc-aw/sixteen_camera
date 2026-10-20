#include "ai/runtime/core/rt_internal.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

void rt_result_service_ttl(AiRtCore *rt)
{
    /* A stalled or disconnected input must not retain boxes indefinitely.
     * Allow three seconds between results; keep the overlay while a newer
     * job for this stream still owns compute/postprocess resources. */
    uint64_t now = platform_read_cycle();
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        AiStreamRuntimeStatus *status = &rt->streams[stream];
        if (status->inflight_count != 0U || status->last_result_cycle == 0U ||
            now - status->last_result_cycle <= STREAM_RESULT_TTL)
            continue;
        if (ai_result_manager_invalidate(&rt->results, stream) > 0) {
            uint16_t bit = (uint16_t)(UINT16_C(1) << stream);
            rt->overlay_dirty &= (uint16_t)~bit;
            rt->overlay_clear |= bit;
            status->expired_result_count++;
        }
        status->last_result_cycle = 0U;
    }
}

int rt_result_service_publish(AiRtCore *rt, const AiDetectionResult *result,
                              uint32_t stream)
{
    int published =
        ai_result_manager_publish(&rt->results, result);
    rt->status.postprocess_count++;
    if (published > 0) {
        rt->status.result_publish_count++;
        rt->streams[stream].last_result_cycle =
            platform_read_cycle();
        rt->overlay_clear &=
            (uint16_t)~(UINT16_C(1) << stream);
        rt->overlay_dirty |=
            (uint16_t)(UINT16_C(1) << stream);
    } else if (published == 0)
        rt->status.stale_result_count++;
    else
        return published;
    return 0;
}
