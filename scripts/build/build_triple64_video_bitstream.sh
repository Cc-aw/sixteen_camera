#!/usr/bin/env bash
# Reuse the successful 0918 implementation flow with the current video board.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
flow="$root/scripts/build/npu0918_video"
case "${1:-}" in
  --check) check_only=1 ;;
  '') check_only=0 ;;
  -h|--help)
    echo 'Usage: bash scripts/build/build_triple64_video_bitstream.sh [--check]'
    echo 'RESULTS_DIR, VIVADO_BIN, FINAL_JOBS=8, FINAL_THREADS=8, ROUTE_THREADS=4'
    echo 'RESUME_SYNTH_DCP=/absolute/path/synth_opt.dcp: reuse an existing synthesis checkpoint.'
    echo 'BIT_REQUIRE_TARGET=0: allow a distinctly named setup-violated bit if route and hold are clean.'
    exit 0 ;;
  *) echo "Unknown argument: $1" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo 'Too many arguments' >&2; exit 2; }
vivado=${VIVADO_BIN:-/mnt/data/Vivado/Vivado/2023.2/bin/vivado}
[[ -x "$vivado" ]] || { echo "Missing Vivado: $vivado" >&2; exit 2; }
[[ -f "$root/prj/sixteen_camera.xpr" ]] || { echo "Video project missing" >&2; exit 2; }
version=$("$vivado" -version 2>/dev/null)
[[ "$version" == *2023.2* ]] || { echo 'Vivado 2023.2 is required' >&2; exit 2; }
export FINAL_JOBS=${FINAL_JOBS:-8} FINAL_THREADS=${FINAL_THREADS:-8} ROUTE_THREADS=${ROUTE_THREADS:-4}
for count in "$FINAL_JOBS" "$FINAL_THREADS" "$ROUTE_THREADS"; do
  [[ "$count" =~ ^([1-9]|[12][0-9]|3[0-2])$ ]] || { echo 'Job/thread counts must be 1..32' >&2; exit 2; }
done
require_target=${BIT_REQUIRE_TARGET:-0}
resume_dcp=${RESUME_SYNTH_DCP:-}
if [[ -n "$resume_dcp" ]]; then
  resume_dcp=$(realpath -e "$resume_dcp")
  [[ -s "$resume_dcp" ]] || { echo 'Resume checkpoint missing or empty' >&2; exit 2; }
fi
[[ "$require_target" =~ ^[01]$ ]] || { echo 'BIT_REQUIRE_TARGET must be 0 or 1' >&2; exit 2; }
# Resolve the same selected RTL as setup_vivado.tcl.
rtl=$(tclsh <<TCL
source {$root/config/manifests/soc_manifest.tcl}
puts [file join {$root} \$SOC_COLLATERAL_DIR]
TCL
)
[[ "$rtl" == *TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig/gen-collateral ]] || {
  echo 'Production manifest must select the triple64 video SoC' >&2; exit 2;
}
tclsh "$root/scripts/check/check_production_manifest.tcl"
python3 "$root/soc_shell/npu100_video/tests/check_video_rtl.py" "$rtl"
python3 "$root/scripts/check/check_fbus_id_groups.py" "$rtl"
results=$(realpath -m "${RESULTS_DIR:-$root/build/bitstream/triple64/$(date +%Y%m%d_%H%M%S)_$$}")
if ((check_only)); then
  printf 'BITSTREAM_PREFLIGHT=PASS\nRTL=%s\nRESULTS_DIR=%s\n' "$rtl" "$results"
  exit 0
fi
# The source project/synth_1 is shared; serialize this entry point.
mkdir -p "$root/build"
exec 9>"$root/build/npu0918_video.lock"
flock -n 9 || { echo 'Another 0918 video build is using this project' >&2; exit 2; }
mkdir -p "$(dirname "$results")"
mkdir "$results" || { echo 'RESULTS_DIR must be a new directory' >&2; exit 2; }
export FINAL_RESULTS_DIR="$results" PROJECT_XPR="$root/prj/sixteen_camera.xpr"
export SYNTH_DCP="$results/synth_opt.dcp"
if [[ -n "$resume_dcp" ]]; then
  export SYNTH_DCP="$resume_dcp"
  printf '%s\n' "$resume_dcp" > "$results/resumed_from.txt"
fi
printf 'started=%s\nrtl=%s\nversion=%s\n' "$(date -Is)" "$rtl" "${version%%$'\n'*}" > "$results/RUN_STARTED"
cp "$root/config/manifests/soc_manifest.tcl" "$results/soc_manifest.tcl"
cp -R "$flow" "$results/flow_snapshot"
git -C "$root" rev-parse HEAD > "$results/git_head.txt"
git -C "$root" diff --binary > "$results/worktree.patch"
# Isolate Vivado scratch/log outputs from the repository root.
cd "$results"
run_vivado() {
  local stage=$1 script=$2
  "$vivado" -mode batch -source "$script" -log "$results/$stage.log" \
    -journal "$results/$stage.jou" 2>&1 | tee "$results/${stage}_console.log"
}
if [[ -z "$resume_dcp" ]]; then
  run_vivado synth "$flow/synth_0918.tcl"
fi
run_vivado implementation "$results/flow_snapshot/implementation_0918.tcl"
status="$results/final_status.txt"
cat "$status"
grep -qx 'LEGAL_ROUTE=1' "$status"
grep -qx 'HOLD_CLEAN=1' "$status"
bit=$(sed -n 's/^BITSTREAM=//p' "$status" | tail -n 1)
[[ -n "$bit" && -s "$bit" ]] || { echo 'Bitstream missing' >&2; exit 4; }
printf 'VIDEO_BITSTREAM=%s\n' "$bit"
if ! grep -qx 'TARGET_MET=1' "$status"; then
  echo 'TIMING_TARGET=NOT_MET (setup-violated bit; inspect final_status.txt and final_setup.rpt)'
  [[ "$require_target" == 0 ]] || exit 5
fi
printf 'VIDEO_BITSTREAM_BUILD=PASS\n'
