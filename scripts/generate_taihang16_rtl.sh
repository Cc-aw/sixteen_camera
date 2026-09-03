#!/usr/bin/env bash
set -Eeuo pipefail

# Regenerate the exact SoC collateral used by setup_vivado.tcl.  This script
# intentionally runs in Chipyard's own generated-src directory; it does not
# modify demo/ai or copy unrelated configurations into this repository.
CHIPYARD_ROOT="${CHIPYARD_ROOT:-/home/wzr/chipyard}"
FPGA_DIR="$CHIPYARD_ROOT/fpga"
CONFIG="TaihangSoC1Rocket1RVV1Gemmini16x16PackedFullOps256BitConfig"

[[ -d "$FPGA_DIR" ]] || { echo "missing Chipyard FPGA directory: $FPGA_DIR" >&2; exit 1; }

# Chipyard's generated build depends on the Conda toolchain and the local
# espresso minimizer exported by env.sh.  Source it here so the script is
# reproducible when invoked from an arbitrary shell.
if [[ -f "$CHIPYARD_ROOT/env.sh" ]]; then
  # shellcheck disable=SC1090
  # Conda's activation hooks reference optional variables while they are
  # being initialized, so nounset must be disabled for this one operation.
  set +u
  source "$CHIPYARD_ROOT/env.sh"
  set -u
else
  echo "missing Chipyard environment: $CHIPYARD_ROOT/env.sh" >&2
  exit 1
fi

command -v espresso >/dev/null 2>&1 || {
  echo "espresso is unavailable after sourcing $CHIPYARD_ROOT/env.sh" >&2
  exit 1
}

make -C "$FPGA_DIR" \
  SUB_PROJECT=taihang_soc \
  CONFIG="$CONFIG" \
  verilog

echo "RTL_GENERATION=PASS"
echo "CONFIG=$CONFIG"
echo "COLLATERAL=$FPGA_DIR/generated-src/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.$CONFIG"
