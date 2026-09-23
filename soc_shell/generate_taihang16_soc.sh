#!/usr/bin/env bash
set -Eeuo pipefail

readonly SOC_CONFIG="TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig"
readonly SOC_SUB_PROJECT="taihang_soc"
readonly SOC_TREE="tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.${SOC_CONFIG}"

# These revisions are part of the reproducibility contract. The payload contains
# local source changes relative to exactly these Chipyard/Gemmini/Rocket-Chip
# revisions; applying it to another revision is not guaranteed to be equivalent.
readonly EXPECTED_CHIPYARD_REV="0acc1e1de2d3284bcd4d876956932a013ffe1949"
readonly EXPECTED_GEMMINI_REV="8c3f9923a44a2fe2c7930587be297d6d4f8c09ca"
readonly EXPECTED_ROCKET_REV="55bcad0f59436de98ea510334121de8546b9e9d7"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
payload="$script_dir/taihang16_soc_source_payload.tar.gz"
chipyard_root=""
mode="install-generate"
force=0

usage() {
  printf '%s\n' \
    "Usage: $0 [--chipyard-root PATH] [--install-only|--verify-only] [--force]" \
    "" \
    "Default: install the packaged source overlay and generate the exact SoC RTL." \
    "Place soc_shell/ in the Chipyard root, or pass --chipyard-root explicitly."
}

while (($#)); do
  case "$1" in
    --chipyard-root)
      (($# >= 2)) || { echo "missing value for --chipyard-root" >&2; exit 2; }
      chipyard_root=$2
      shift 2
      ;;
    --install-only)
      mode="install-only"
      shift
      ;;
    --verify-only)
      mode="verify-only"
      shift
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$chipyard_root" ]]; then
  if [[ -d "$script_dir/../fpga" && -f "$script_dir/../env.sh" ]]; then
    chipyard_root=$(cd "$script_dir/.." && pwd)
  elif [[ -d "$PWD/fpga" && -f "$PWD/env.sh" ]]; then
    chipyard_root=$PWD
  else
    echo "cannot locate Chipyard; put soc_shell/ in its root or pass --chipyard-root" >&2
    exit 2
  fi
fi
chipyard_root=$(cd "$chipyard_root" && pwd)

require_path() {
  [[ -e "$1" ]] || { echo "missing required path: $1" >&2; exit 1; }
}

require_revision() {
  local repo=$1 expected=$2 label=$3 actual
  actual=$(git -C "$repo" rev-parse HEAD)
  if [[ "$actual" != "$expected" ]]; then
    if ((force)); then
      echo "REVISION_WARN $label expected=$expected actual=$actual"
    else
      echo "$label revision mismatch: expected $expected, got $actual" >&2
      echo "Use the matching revision, or --force only if you accept a non-identical build." >&2
      exit 1
    fi
  fi
}

verify_installed_sources() {
  local cfg="$chipyard_root/fpga/src/main/scala/taihang_soc/Configs.scala"
  require_path "$cfg"
  require_path "$chipyard_root/fpga/src/main/scala/taihang_soc/TestHarness.scala"
  require_path "$chipyard_root/generators/gemmini/src/main/scala/gemmini/LoopConvTrace.scala"
  require_path "$chipyard_root/generators/rocket-chip/src/main/scala/subsystem/Ports.scala"

  rg -q "class ${SOC_CONFIG} extends Config" "$cfg"
  rg -q "class WithTaihangSoCTwo16GemminiSingleHart" "$cfg"
  rg -q "meshRows = 16" "$cfg"
  rg -q "meshColumns = 8" "$cfg"
  rg -q "source_bits = 7" "$cfg"
  rg -q "fifo_bits = 5" "$cfg"
  rg -q 'ifeq \(\$\(SUB_PROJECT\),taihang_soc\)' "$chipyard_root/fpga/Makefile"
  echo "SOURCE_CONFIG_VERIFY=PASS"
}

require_path "$chipyard_root/fpga"
require_path "$chipyard_root/generators/gemmini"
require_path "$chipyard_root/generators/rocket-chip"
require_revision "$chipyard_root" "$EXPECTED_CHIPYARD_REV" "chipyard"
require_revision "$chipyard_root/generators/gemmini" "$EXPECTED_GEMMINI_REV" "gemmini"
require_revision "$chipyard_root/generators/rocket-chip" "$EXPECTED_ROCKET_REV" "rocket-chip"

if [[ "$mode" == "verify-only" ]]; then
  verify_installed_sources
  exit 0
fi

require_path "$payload"

backup_root="$chipyard_root/.taihang_soc_backups"
backup_stamp=$(date +%Y%m%d-%H%M%S)
backup="$backup_root/taihang16-before-${backup_stamp}.tar.gz"
mkdir -p "$backup_root"

# Keep every existing target recoverable before installing the overlay.
backup_paths=(
  fpga/Makefile
  fpga/src/main/scala/taihang_soc
  fpga/src/main/resources/taihang_soc
  generators/gemmini/src/main/scala/gemmini
  generators/gemmini/chipyard/GemminiConfigs.scala
  generators/rocket-chip/src/main/scala/devices/debug/Periphery.scala
  generators/rocket-chip/src/main/scala/rocket/RocketCore.scala
  generators/rocket-chip/src/main/scala/subsystem/Configs.scala
  generators/rocket-chip/src/main/scala/subsystem/Ports.scala
  generators/rocket-chip/src/main/scala/tile/LazyRoCC.scala
)
existing_paths=()
for path in "${backup_paths[@]}"; do
  [[ -e "$chipyard_root/$path" ]] && existing_paths+=("$path")
done
tar -C "$chipyard_root" -czf "$backup" "${existing_paths[@]}"
echo "SOURCE_BACKUP=$backup"

tar -C "$chipyard_root" -xzf "$payload"

# The source bundle may be transported through filesystems which expose every
# file as executable. Normalize source modes on ordinary Unix filesystems;
# permission-less mounts may reject chmod, which does not affect compilation.
chmod 0644 "$chipyard_root/fpga/Makefile" 2>/dev/null || true
for source_tree in \
  "$chipyard_root/fpga/src/main/scala/taihang_soc" \
  "$chipyard_root/fpga/src/main/resources/taihang_soc" \
  "$chipyard_root/generators/gemmini/src/main/scala/gemmini"; do
  find "$source_tree" -type d -exec chmod 0755 {} + 2>/dev/null || true
  find "$source_tree" -type f -exec chmod 0644 {} + 2>/dev/null || true
done
for source_file in \
  "$chipyard_root/generators/gemmini/chipyard/GemminiConfigs.scala" \
  "$chipyard_root/generators/rocket-chip/src/main/scala/devices/debug/Periphery.scala" \
  "$chipyard_root/generators/rocket-chip/src/main/scala/rocket/RocketCore.scala" \
  "$chipyard_root/generators/rocket-chip/src/main/scala/subsystem/Configs.scala" \
  "$chipyard_root/generators/rocket-chip/src/main/scala/subsystem/Ports.scala" \
  "$chipyard_root/generators/rocket-chip/src/main/scala/tile/LazyRoCC.scala"; do
  chmod 0644 "$source_file" 2>/dev/null || true
done

verify_installed_sources
echo "SOURCE_OVERLAY_INSTALL=PASS"

if [[ "$mode" == "install-only" ]]; then
  exit 0
fi

set +u
source "$chipyard_root/env.sh"
set -u

runtime_dir="/tmp/taihang16-soc-$UID"
mkdir -p "$runtime_dir"
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR="$runtime_dir" \
  make -C "$chipyard_root/fpga" \
    SUB_PROJECT="$SOC_SUB_PROJECT" \
    CONFIG="$SOC_CONFIG" \
    verilog

generated="$chipyard_root/fpga/generated-src/$SOC_TREE"
require_path "$generated/gen-collateral/TaihangSoCFPGATestHarness.sv"
require_path "$generated/gen-collateral/Gemmini.sv"
require_path "$generated/gen-collateral/Gemmini_1.sv"
require_path "$generated/gen-collateral/RocketTile.sv"
require_path "$generated/model_module_hierarchy.json"

echo "RTL_GENERATION=PASS"
echo "CONFIG=$SOC_CONFIG"
echo "COLLATERAL=$generated"
