# Source after project_root is set. Only the current split Runtime links these.
runtime_module_sources=(
  "$project_root/sw/src/ai/runtime/core/rt_core.c"
  "$project_root/sw/src/ai/runtime/core/rt_pipeline.c"
  "$project_root/sw/src/ai/runtime/core/rt_state.c"
  "$project_root/sw/src/ai/runtime/core/rt_stats.c"
  "$project_root/sw/src/ai/runtime/scheduler/rt_frame_scheduler.c"
  "$project_root/sw/src/ai/runtime/scheduler/rt_worker_dispatch.c"
  "$project_root/sw/src/ai/runtime/services/rt_tensor_service.c"
  "$project_root/sw/src/ai/runtime/services/rt_result_service.c"
  "$project_root/sw/src/ai/runtime/services/rt_overlay_service.c"
)
