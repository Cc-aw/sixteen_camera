#include "ai/runtime/core/rt_internal.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include <string.h>

void rt_complete_stream_job(AiRtCore *rt, uint32_t stream_id, uint64_t frame_id,
                                uint32_t version, int error)
{
    AiStreamRuntimeStatus *stream = &rt->streams[stream_id];
    rt->status.completed_job_count++;
    stream->completed_count++;
    if (stream->inflight_count != 0U)
        stream->inflight_count--;
    if (error == 0) {
        uint64_t now = platform_read_cycle();
        stream->last_frame_id = frame_id;
        stream->last_version = version;
        stream->last_frame_valid = 1U;
        if (stream->next_deadline != 0U && now > stream->next_deadline)
            stream->missed_deadline_count++;
        stream->last_complete_cycle = now;
        stream->next_deadline = now + STREAM_TARGET_PERIOD;
    } else {
        rt_record_error(rt, error);
    }
}

void rt_record_frame_profile(AiRtCore *rt, const AiRtPostJob *post,
                                 const AiRtBackendResultCompletion *completion)
{
    AiRtProfileRecord *record = &rt->profiles[rt->profile_head];
    record->job_id = post->job_id;
    record->frame_id = post->frame_id;
    record->stream = post->stream;
    record->worker = post->worker;
    record->profile = post->profile;
    record->profile.ppu_queue_wait_cycles =
        completion->profile.ppu_queue_wait_cycles;
    rt->profile_head =
        (rt->profile_head + 1U) % STREAM_PROFILE_CAPACITY;
    if (rt->profile_count < STREAM_PROFILE_CAPACITY)
        rt->profile_count++;
}
