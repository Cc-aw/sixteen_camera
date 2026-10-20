#include "ai/runtime/core/rt_internal.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

void rt_overlay_service(AiRtCore *rt)
{
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        uint16_t bit = (uint16_t)(UINT16_C(1) << stream);
        if ((rt->overlay_dirty & bit) == 0U &&
            (rt->overlay_clear & bit) == 0U)
            continue;
        AiDetectionResult clear_result;
        const AiDetectionResult *result;
        if ((rt->overlay_clear & bit) != 0U) {
            memset(&clear_result, 0, sizeof(clear_result));
            clear_result.stream_id = stream;
            result = &clear_result;
        } else {
            result = ai_result_manager_latest(&rt->results, stream);
        }
        int status = ai_overlay_try_submit(result);
        if (status > 0) {
            rt->overlay_dirty &= (uint16_t)~bit;
            rt->overlay_clear &= (uint16_t)~bit;
        } else if (status < 0)
            rt_record_error(rt, status);
        break;
    }
}
