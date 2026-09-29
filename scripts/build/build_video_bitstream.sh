#!/usr/bin/env bash
# Dispatch to existing flows with the same SoC selection as the firmware.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
export SOC_VARIANT=${SOC_VARIANT:-triple64}
flow=$(tclsh "$root/scripts/check/print_soc_collateral.tcl" --flow)
if [[ "$flow" == triple64 ]]; then
  exec bash "$root/scripts/build/build_triple64_video_bitstream.sh" "$@"
fi
case "${1:-}" in
  --check) check_only=1 ;;
  '') check_only=0 ;;
  *) echo 'Usage: SOC_VARIANT=<alias> or SOC_CONFIG=<directory> bash scripts/build/build_video_bitstream.sh [--check]' >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { echo 'Too many arguments' >&2; exit 2; }
vivado=${VIVADO_BIN:-/mnt/data/Vivado/Vivado/2023.2/bin/vivado}
[[ -x "$vivado" ]] || { echo "Missing Vivado: $vivado" >&2; exit 2; }
[[ -f "$root/prj/sixteen_camera.xpr" ]] || { echo 'Missing Vivado project' >&2; exit 2; }
version=$("$vivado" -version 2>/dev/null)
[[ "$version" == *2023.2* ]] || { echo 'Vivado 2023.2 is required' >&2; exit 2; }
tclsh "$root/scripts/check/check_production_manifest.tcl"
if ((check_only)); then
  printf 'VIDEO_BITSTREAM_PREFLIGHT=PASS flow=default\n'
  exit 0
fi
# All unified project-mutating entry points share the existing build lock.
mkdir -p "$root/build"
exec 9>"$root/build/npu0918_video.lock"
flock -n 9 || { echo 'Another build is using the Vivado project' >&2; exit 2; }
label=$SOC_VARIANT
if [[ -n "${SOC_CONFIG:-}" ]]; then label=${SOC_CONFIG##*.}; fi
results="$root/build/bitstream/${label}/$(date +%Y%m%d_%H%M%S)_$$"
mkdir -p "$results"
cd "$results"
"$vivado" -mode batch -source "$root/scripts/build/build_default_video_bitstream.tcl" \
  -log "$results/build.log" -journal "$results/build.jou"
# Keep the selected variant's result after another variant reuses the XPR.
bitstream="$root/prj/sixteen_camera.runs/impl_1/top_wrapper.bit"
[[ -s "$bitstream" ]] || { echo 'Bitstream missing' >&2; exit 4; }
cp "$bitstream" "$results/video_${label}.bit"
tclsh "$root/scripts/check/print_soc_collateral.tcl" --config > "$results/soc_config.txt"
tclsh "$root/scripts/check/print_soc_collateral.tcl" > "$results/soc_collateral.txt"
printf 'VIDEO_BITSTREAM=%s/video_%s.bit\n' "$results" "$label"
