/* R0 records the existing non-modular version ordering. A future protocol
 * change must replace this characterization with a wrap-aware safety test. */
#define main stream_existing_regression_main
#include "test_ai_batch_runtime_stream.c"
#undef main

int main(void)
{
    ai_batch_runtime_init();
    ai_batch_runtime_set_enabled(1);
    publish_slot(0, 100);
    version[0] = UINT32_MAX;
    ai_batch_runtime_poll();
    assert(submit_count == 1 && requests[0].version == UINT32_MAX);
    compute_allowed[0] = result_allowed[0] = 1;
    ai_batch_runtime_poll();
    const AiDetectionResult *latest = ai_batch_runtime_latest_result(0);
    assert(latest && latest->frame_id == 100 && latest->version == UINT32_MAX);
    publish_slot(16, 101);
    version[16] = 1;
    ai_batch_runtime_poll();
    AiStreamRuntimeStatus stream;
    assert(ai_batch_runtime_get_stream_status(0, &stream) == 0);
    assert(submit_count == 1 && ready == 0 && stream.superseded_count == 1);
    assert(stream.last_frame_id == 100 && stream.last_version == UINT32_MAX);
    puts("R0_VERSION_TRACE stream=0 completed_frame=100 last_version=4294967295 new_frame=101 new_version=1 action=release_as_stale");
    puts("R0_KNOWN_GAP=tensor_version_wrap_treated_as_stale correctness=FAIL characterization=PASS");
    return 0;
}
