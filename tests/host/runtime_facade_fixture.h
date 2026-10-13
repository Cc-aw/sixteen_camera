#ifndef RUNTIME_FACADE_FIXTURE_H
#define RUNTIME_FACADE_FIXTURE_H
/* Declare the migration ABI before remapping fixture calls to the real
 * canonical facade. Production modules never receive these macros. */
#include "ai/runtime/ai_batch_runtime.h"
#include "ai/runtime/rt.h"
#include "ai/runtime/rt_debug.h"
#include "diagnostics/runtime_diagnostics.h"
#define ai_batch_runtime_init rt_init
#define ai_batch_runtime_set_enabled rt_set_enabled
#define ai_batch_runtime_is_enabled rt_is_enabled
#define ai_batch_runtime_is_idle rt_is_idle
#define ai_batch_runtime_state rt_state
#define ai_batch_runtime_poll rt_poll
#define ai_batch_runtime_print_status rt_diagnostics_print_status
#define ai_batch_runtime_print_frame_profiles rt_diagnostics_print_frame_profiles
#define ai_batch_runtime_get_status rt_get_status
#define ai_batch_runtime_get_resources rt_get_resources
#define ai_batch_runtime_latest_result rt_latest_result
#define ai_batch_runtime_get_stream_status rt_get_stream_status
#endif
