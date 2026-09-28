#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
checkout=$(realpath "${CHIPYARD_ROOT:?Use an isolated complete Chipyard checkout}")
[[ -f "$checkout/.npu100-video-workspace.json" ]] || {
  echo 'First run prepare_workspace.py to create a dedicated source snapshot.' >&2
  exit 2
}
export COURSIER_CACHE="$checkout/.coursier/v1"
export XDG_RUNTIME_DIR="$checkout/.runtime"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export RISCV="$checkout/.conda-env/riscv-tools"
export PATH="$checkout/.conda-env/bin:$RISCV/bin:$PATH"
export JAVA_TOOL_OPTIONS="-Xmx${NPU_JAVA_HEAP:-12G} -Xss8M -XX:ActiveProcessorCount=${NPU_BUILD_CPUS:-8} -Djava.io.tmpdir=$checkout/.java_tmp"
unset USE_CHISEL7
config=TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig
package=tsmcchip.fpga.taihangsoc
model=TaihangSoCFPGATestHarness
CHIPYARD_ROOT="$checkout" CONFIG="$config" CONFIG_PACKAGE="$package" MODEL="$model" SUB_PROJECT=taihang_soc \
  bash "$root/fpga/scripts/generate_merged_batch2_rtl.sh"
rtl="$checkout/fpga/generated-src/$package.$model.$config/gen-collateral"
python3 "$root/tests/check_video_rtl.py" "$rtl" "$model"
python3 "$root/../../scripts/check_fbus_id_groups.py" "$rtl"
python3 "$root/fpga/scripts/manifest_0914.py" write --root "$root" --rtl "$rtl"
python3 "$root/export_video_soc.py" "$rtl" "$checkout" "${NPU_SOC_EXPORT_ROOT:-$root/../../generated/soc}"
printf 'NPU100_VIDEO_RTL=%s\n' "$rtl"
