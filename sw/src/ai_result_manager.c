#include "ai_result_manager.h"

void ai_result_manager_init(AiResultManager *manager)
{
    if (manager == 0)
        return;
    manager->valid_mask = 0U;
    manager->publish_count = 0U;
    manager->stale_count = 0U;
    manager->error_count = 0U;
    for (uint32_t stream = 0U; stream < VIDEO_CHANNEL_COUNT; ++stream) {
        manager->latest[stream].job_id = 0U;
        manager->latest[stream].frame_id = 0U;
        manager->latest[stream].timestamp = 0U;
        manager->latest[stream].stream_id = stream;
        manager->latest[stream].worker_id = 0U;
        manager->latest[stream].version = 0U;
        manager->latest[stream].count = 0U;
    }
}

int ai_result_manager_publish(AiResultManager *manager,
                              const AiDetectionResult *result)
{
    uint16_t stream_mask;
    if (manager == 0 || result == 0 ||
        result->stream_id >= VIDEO_CHANNEL_COUNT ||
        result->count > AI_MAX_DETECTIONS) {
        if (manager != 0)
            manager->error_count++;
        return -1;
    }

    stream_mask = (uint16_t)(UINT16_C(1) << result->stream_id);
    if ((manager->valid_mask & stream_mask) != 0U) {
        const AiDetectionResult *latest =
            &manager->latest[result->stream_id];
        if (result->frame_id < latest->frame_id ||
            (result->frame_id == latest->frame_id &&
             result->version <= latest->version)) {
            manager->stale_count++;
            return 0;
        }
    }
    manager->latest[result->stream_id] = *result;
    manager->valid_mask |= stream_mask;
    manager->publish_count++;
    return 1;
}

const AiDetectionResult *ai_result_manager_latest(
    const AiResultManager *manager, uint32_t stream_id)
{
    if (manager == 0 || stream_id >= VIDEO_CHANNEL_COUNT ||
        (manager->valid_mask & (UINT16_C(1) << stream_id)) == 0U)
        return 0;
    return &manager->latest[stream_id];
}

int ai_result_manager_invalidate(AiResultManager *manager,
                                 uint32_t stream_id)
{
    if (manager == 0 || stream_id >= VIDEO_CHANNEL_COUNT)
        return -1;
    uint16_t mask = (uint16_t)(UINT16_C(1) << stream_id);
    if ((manager->valid_mask & mask) == 0U)
        return 0;
    manager->valid_mask &= (uint16_t)~mask;
    manager->latest[stream_id].count = 0U;
    return 1;
}
