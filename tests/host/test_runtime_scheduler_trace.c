#define AI_RUNTIME_TRACE_EMBED 1
#define AI_RUNTIME_EXTENDED_TRACE 1
#include "test_runtime_tensor_hal_trace.c"

int main(int argc, char **argv)
{
    assert(argc == 2);
    ai_batch_runtime_init(); ai_batch_runtime_set_enabled(1);
    if (!strcmp(argv[1], "writing-drain")) {
        writing = UINT32_C(1) << 31;
        ai_batch_runtime_set_enabled(0);
        ai_batch_runtime_poll();
        assert(!ai_batch_runtime_is_idle());
        ai_batch_runtime_set_enabled(1);
        assert(!ai_batch_runtime_is_enabled());
        writing = 0;
    } else if (!strcmp(argv[1], "backpressure")) {
        publish_slot(0, 100); reject_submit_once = 1;
        ai_batch_runtime_poll();
        AiRtResourceSnapshot resources; ai_batch_runtime_get_resources(&resources);
        assert(!submit_count && ready == 1 && !resources.held_tensor && !resources.faulted);
        ai_batch_runtime_poll(); assert(submit_count == 1 && backend_running[0]);
    } else if (!strcmp(argv[1], "metadata-failure")) {
        publish_slot(0, 100); publish_slot(1, 101); bad_metadata_slot = 0;
        ai_batch_runtime_poll();
        assert(submit_count == 1 && requests[0].stream_id == 1);
        bad_metadata_slot = UINT32_MAX;
    } else if (!strcmp(argv[1], "multi-double")) {
        publish_slot(0, 100); publish_slot(16, 102);
        publish_slot(1, 200); publish_slot(17, 199);
        ai_batch_runtime_poll();
        /* R2 cleans only the first stale pair per poll, then favors s+16
         * for a still-double pair. Preserve this known fallback. */
        assert(requests[0].stream_id == 1 && requests[0].frame_id == 199);
    } else {
        for (uint32_t stream = 0; stream < AI_MODEL_WORKER_COUNT; ++stream)
            publish_slot(stream, 100 + stream);
        publish_slot(8, 90);
        ai_batch_runtime_poll(); assert(submit_count == AI_MODEL_WORKER_COUNT);
        uint32_t first_stream = requests[0].stream_id;
        assert(first_stream == AI_MODEL_WORKER_COUNT - 1);
        compute_allowed[0] = 1; ai_batch_runtime_poll();
        assert(release_count == 1 && submit_count == AI_MODEL_WORKER_COUNT + 1);
        assert(requests[0].stream_id == 8 && !ai_batch_runtime_latest_result(first_stream));
    }
    for (uint32_t poll = 0; poll < 6; ++poll) {
        for (uint32_t worker = 0; worker < AI_MODEL_WORKER_COUNT; ++worker) {
            compute_allowed[worker] = 1;
            result_allowed[worker] = AI_MODEL_RESULT_QUEUE_CAPACITY;
        }
        ai_batch_runtime_poll();
    }
    ai_batch_runtime_set_enabled(0);
    for (uint32_t poll = 0; poll < 6; ++poll) ai_batch_runtime_poll();
    assert(ai_batch_runtime_is_idle());
    ai_batch_runtime_print_status(); ai_batch_runtime_print_frame_profiles();
    printf("FINAL scenario=%s workers=%u submits=%u release=%u overlay=%u cycle=%llu\n", argv[1], AI_MODEL_WORKER_COUNT, submit_count, release_count, overlay_count, (unsigned long long)test_cycle);
    return 0;
}
