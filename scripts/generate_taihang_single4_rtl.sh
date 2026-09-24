#!/usr/bin/env bash
set -Eeuo pipefail

chipyard_root=${CHIPYARD_ROOT:-/home/wzr/chipyard}
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config=TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig
tree=tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.$config
source_dir="$chipyard_root/fpga/generated-src/$tree/gen-collateral"
target_dir="$repo_dir/generated/soc/$tree/gen-collateral"

python3 "$repo_dir/scripts/add_taihang_single4_gemmini_config.py" --chipyard-root "$chipyard_root"
python3 "$repo_dir/scripts/configure_taihang16_p1c2.py" --chipyard-root "$chipyard_root"

set +u
source "$chipyard_root/env.sh"
set -u
mkdir -p /tmp/chipyard-sbt-wzr
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR=/tmp/chipyard-sbt-wzr \
  make -C "$chipyard_root/fpga" SUB_PROJECT=taihang_soc CONFIG="$config" verilog

[[ -f "$source_dir/TaihangSoCFPGATestHarness.sv" ]] || {
  echo "missing generated harness: $source_dir" >&2
  exit 1
}
python3 "$repo_dir/scripts/check_fbus_id_groups.py" "$source_dir"
mkdir -p "$target_dir"
rsync -rt --delete "$source_dir/" "$target_dir/"
echo "SOC_COLLATERAL_SYNC=PASS"
echo "TARGET=$target_dir"
