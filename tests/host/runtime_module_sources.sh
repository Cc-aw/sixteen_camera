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

# Host workloads model the same explicit profiles as the firmware build.
# Keep sources separate so frozen Runtime references never link adapters.
runtime_select_backend() {
  runtime_backend_sources=(
    "$project_root/sw/src/ai/backend/rt_backend.c"
    "$project_root/sw/src/ai/backend/adapters/rt_backend_compat.c"
  )
  case "$1" in
    1|2)
      runtime_backend_flags=(-DAI_RT_BACKEND_PROFILE=AI_RT_BACKEND_PROFILE_LEGACY -DYOLO32_LIVE=0)
      runtime_backend_sources+=("$project_root/sw/src/ai/backend/adapters/legacy/rt_backend_legacy.c")
      ;;
    3)
      runtime_backend_flags=(-DAI_RT_BACKEND_PROFILE=AI_RT_BACKEND_PROFILE_V17A -DYOLO32_LIVE=1)
      runtime_backend_sources+=("$project_root/sw/src/ai/backend/adapters/v17a/rt_backend_v17a.c")
      ;;
    *) echo "Unsupported test backend worker count: $1" >&2; return 1 ;;
  esac
}
