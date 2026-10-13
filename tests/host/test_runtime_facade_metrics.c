/* Run real Runtime/PPU-result transitions with the existing model double. */
#define main unused_stream_fixture_main
#include "test_ai_batch_runtime_stream.c"
#undef main
#include "ai/runtime/rt.h"
#include "ai/runtime/rt_debug.h"

int main(void)
{
    assert(rt_init() == 0 && rt_state() == AI_RT_STATE_STOPPED);
    assert(rt_frame_metrics_count() == 0);
    AiRtFrameMetrics metrics;
    assert(rt_get_frame_metrics(0, &metrics) == -1);
    assert(rt_get_frame_metrics(0, 0) == -1);
    rt_set_enabled(1);
    for (unsigned item = 1; item <= 24; ++item) {
        publish_slot(0, 100 + item);
        rt_poll();
        assert(backend_running[0]);
        compute_allowed[0] = 1;
        rt_poll();
        result_allowed[0] = 1;
        rt_poll();
        assert(rt_latest_result(0)->frame_id == 100 + item);
    }
    rt_set_enabled(0);
    for (unsigned poll = 0; poll < 3; ++poll) rt_poll();
    assert(rt_is_idle() && rt_state() == AI_RT_STATE_STOPPED);
    AiRtStatus status;
    rt_get_status(&status);
    assert(status.completed_job_count == 24 && status.result_publish_count == 24);
    AiRtStreamStatus stream;
    assert(rt_get_stream_status(0, &stream) == 0 && stream.last_frame_id == 124);
    assert(rt_get_stream_status(VIDEO_CHANNEL_COUNT, &stream) == -1);
    assert(rt_get_stream_status(0, 0) == -1);
    assert(rt_frame_metrics_count() == 16);
    uint64_t before = test_cycle;
    for (unsigned item = 0; item < 16; ++item) {
        assert(rt_get_frame_metrics(item, &metrics) == 0);
        assert(metrics.frame_id == 109 + item && metrics.stream == 0 && metrics.worker == 0);
        assert(metrics.job_id == (UINT64_C(1) << 60) + 9 + item);
    }
    assert(rt_get_frame_metrics(16, &metrics) == -1);
    assert(rt_frame_metrics_count() == 16 && test_cycle == before);

    /* Failed re-init reports failure and preserves the active input and
     * completed profile history. It cannot silently install a new backend. */
    rt_set_enabled(1);
    publish_slot(0, 125);
    rt_poll();
    AiRtResourceSnapshot ownership_before, ownership_after;
    rt_get_resources(&ownership_before);
    assert(ownership_before.held_tensor && ownership_before.active_worker);
    assert(rt_init() == -1 && rt_state() == AI_RT_STATE_FAULTED);
    rt_get_resources(&ownership_after);
    assert(ownership_after.held_tensor == ownership_before.held_tensor);
    assert(ownership_after.active_worker == ownership_before.active_worker);
    assert(rt_frame_metrics_count() == 16 && backend_running[0]);
    puts("R5_FACADE_METRICS=PASS real_completion_ring_wrap chronological_nonconsuming_queries common_stats unsafe_init_retains_ownership");
    return 0;
}
