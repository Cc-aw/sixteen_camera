#!/usr/bin/env bash
# Build the video base with a selected SoC integration example.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
export SOC_VARIANT=${SOC_VARIANT:-dual16}
if [[ -z "${VIVADO_PROJECT:-}" && ( "$SOC_VARIANT" == triple32_v3_tensor || "${SOC_CONFIG:-}" == *MemoryParallelV3TensorIngressConfig ) ]]; then
  export VIVADO_PROJECT="$root/build/projects/triple32_v3_tensor/sixteen_camera.xpr"
fi
case "${1:-}" in
  --check) check_only=1 ;;
  '') check_only=0 ;;
  *) echo 'Usage: SOC_VARIANT=<alias> or SOC_CONFIG=<directory> bash tools/build/build_video_bitstream.sh [--check]' >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo 'Too many arguments' >&2; exit 2; }
vivado=${VIVADO_BIN:-vivado}
if [[ -n "${VIVADO_PROJECT:-}" ]]; then
  export VIVADO_PROJECT="$(realpath -m "$VIVADO_PROJECT")"
fi
command -v "$vivado" >/dev/null 2>&1 || { echo "Missing Vivado: $vivado" >&2; exit 2; }
[[ -f "$root/hw/vivado/create_project.tcl" ]] || { echo 'Missing project creation Tcl' >&2; exit 2; }
version=$("$vivado" -version 2>/dev/null)
[[ "$version" == *2023.2* ]] || { echo 'Vivado 2023.2 is required' >&2; exit 2; }
tclsh "$root/tools/check/check_production_manifest.tcl"
if ((check_only)); then
  printf 'VIDEO_BITSTREAM_PREFLIGHT=PASS\n'
  exit 0
fi
# All unified project-mutating entry points share the existing build lock.
mkdir -p "$root/build"
exec 9>"$root/build/video_project.lock"
flock -n 9 || { echo 'Another build is using the Vivado project' >&2; exit 2; }
label=$SOC_VARIANT
if [[ -n "${SOC_CONFIG:-}" ]]; then label=${SOC_CONFIG##*.}; fi
results="$root/build/bitstream/${label}/$(date +%Y%m%d_%H%M%S)_$$"
mkdir -p "$results"
cd "$results"
"$vivado" -mode batch -source "$root/tools/build/build_default_video_bitstream.tcl" \
  -log "$results/build.log" -journal "$results/build.jou"
# Keep the selected variant's result after another variant reuses the XPR.
project=${VIVADO_PROJECT:-$root/hw/vivado/sixteen_camera.xpr}
project=$(realpath -m "$project")
project_name=$(basename "$project" .xpr)
bitstream="$(dirname "$project")/$project_name.runs/impl_1/top_wrapper.bit"
[[ -s "$bitstream" ]] || { echo 'Bitstream missing' >&2; exit 4; }
cp "$bitstream" "$results/video_${label}.bit"
tclsh "$root/tools/check/print_soc_collateral.tcl" --config > "$results/soc_config.txt"
tclsh "$root/tools/check/print_soc_collateral.tcl" > "$results/soc_collateral.txt"
printf 'VIDEO_BITSTREAM=%s/video_%s.bit\n' "$results" "$label"
