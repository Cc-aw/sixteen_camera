#include "ai/runtime/ai_batch_runtime.h"
#include "ai/runtime/rt.h"
#include "ai/runtime/rt_debug.h"
#include "diagnostics/runtime_diagnostics.h"

/* Migration shim: no state, IO, scheduling or model/Head dependencies. */
void ai_batch_runtime_init(void) { (void)rt_init(); }
void ai_batch_runtime_set_enabled(uint32_t enabled) { rt_set_enabled(enabled); }
uint32_t ai_batch_runtime_is_enabled(void) { return rt_is_enabled(); }
uint32_t ai_batch_runtime_is_idle(void) { return rt_is_idle(); }
AiRtState ai_batch_runtime_state(void) { return rt_state(); }
void ai_batch_runtime_poll(void) { rt_poll(); }
void ai_batch_runtime_print_status(void) { rt_diagnostics_print_status(); }
void ai_batch_runtime_print_frame_profiles(void) { rt_diagnostics_print_frame_profiles(); }
void ai_batch_runtime_get_status(AiBatchRuntimeStatus *status) { rt_get_status(status); }
void ai_batch_runtime_get_resources(AiRtResourceSnapshot *snapshot) { rt_get_resources(snapshot); }
const AiBatchContext *ai_batch_runtime_context(uint32_t arena) { (void)arena; return 0; }
const AiDetectionResult *ai_batch_runtime_latest_result(uint32_t stream) { return rt_latest_result(stream); }
int ai_batch_runtime_get_stream_status(uint32_t stream, AiStreamRuntimeStatus *status)
{
    return rt_get_stream_status(stream, status);
}
