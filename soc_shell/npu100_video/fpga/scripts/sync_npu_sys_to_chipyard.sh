#!/usr/bin/env bash
set -euo pipefail

npu_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
chipyard_root=${CHIPYARD_ROOT:?Set CHIPYARD_ROOT to a complete Chipyard checkout}
# The user's working Taihang tree is a reference, never an overlay destination.
if [[ $(realpath "$chipyard_root") == /home/wzr/chipyard ]]; then
  echo "Refusing to overwrite the original Taihang Chipyard; use an isolated checkout." >&2
  exit 2
fi

[[ -f "$chipyard_root/.npu100-video-workspace.json" ]] || {
  echo 'Use prepare_workspace.py first; overlays are restricted to the dedicated workspace.' >&2
  exit 2
}


[[ -f "$chipyard_root/fpga/Makefile" ]] || {
  echo "Error: CHIPYARD_ROOT is not a complete Chipyard checkout: $chipyard_root" >&2
  exit 1
}
[[ -d "$chipyard_root/generators/gemmini/src/main/scala/gemmini" ]] || {
  echo "Error: Gemmini generator directory is missing under CHIPYARD_ROOT" >&2
  exit 1
}

python3 - "$chipyard_root" <<'PY_CHECK'
from pathlib import Path
import sys
base = Path(sys.argv[1]) / "generators/rocket-chip/src/main/scala/subsystem"
ports = (base / "Ports.scala").read_text()
configs = (base / "Configs.scala").read_text()
for token in ["params.fifoBits", "AXI4IdIndexer(fifoBits)",
              "params.sourceBits - fifoBits - 1", "AddressSet.misaligned(params.base, params.size)"]:
    if token not in ports:
        raise SystemExit("Video FBus/MMIO dependency missing in Ports.scala: " + token)
for token in ["source_bits: Int", "fifo_bits: Int", "fifoBits = fifo_bits"]:
    if token not in configs:
        raise SystemExit("Video FBus dependency missing in subsystem/Configs.scala: " + token)
lazy = (base.parent / "tile/LazyRoCC.scala").read_text()
for token in ["replay_release", "RoCCBusyWriteBypassCSRsKey", "roccMbusMasterNodes",
              "loopconv_ingress_debug", "LoopConvIngressDebugEscapeKey"]:
    if token not in lazy:
        raise SystemExit("Current Rocket-Chip interface missing: " + token)
PY_CHECK

mkdir -p "$chipyard_root/generators/gemmini/src/main/scala/gemmini"
rsync -rlt --delete "$npu_root/src/main/scala/gemmini/" \
  "$chipyard_root/generators/gemmini/src/main/scala/gemmini/"

mkdir -p "$chipyard_root/generators/gemmini/src/main/resources"
cp -R --preserve=timestamps "$npu_root/src/main/resources/." "$chipyard_root/generators/gemmini/src/main/resources/"

# Keep the workspace's complete Rocket-Chip revision, including LazyRoCC,
# RocketCore and HasTiles. Its replay fix already handles the 0918 protocol.
# The diagnostic sideband is an input supplied by HasLazyRoCC; the 0918
# Gemmini can leave that observation input unused.

# 0913 breaks the Saturn issue/segment-buffer control paths in Scala as well.
cp -R --preserve=timestamps "$npu_root/saturn/src/main/scala/." \
  "$chipyard_root/generators/saturn/src/main/scala/"

mkdir -p "$chipyard_root/fpga/src/main/scala/xcvu13p_gemmini_64x64_packed_inference_ram"
cp -R --preserve=timestamps "$npu_root/fpga/src/main/scala/xcvu13p_gemmini_64x64_packed_inference_ram/." \
  "$chipyard_root/fpga/src/main/scala/xcvu13p_gemmini_64x64_packed_inference_ram/"
mkdir -p "$chipyard_root/fpga/src/main/scala/taihang_soc"
cp -R --preserve=timestamps "$npu_root/fpga/src/main/scala/taihang_soc/Npu100Video.scala" \
  "$chipyard_root/fpga/src/main/scala/taihang_soc/Npu100Video.scala"

mkdir -p "$chipyard_root/generators/gemmini/software/libgemmini"
cp -R --preserve=timestamps "$npu_root/software/libgemmini/." \
  "$chipyard_root/generators/gemmini/software/libgemmini/"

mkdir -p "$chipyard_root/generators/gemmini/software/gemmini-rocc-tests/include"
cp -R --preserve=timestamps "$npu_root/software/gemmini-rocc-tests/include/." \
  "$chipyard_root/generators/gemmini/software/gemmini-rocc-tests/include/"

echo "SYNCHRONIZED_NPU_SYS=$npu_root"
echo "SYNCHRONIZED_CHIPYARD=$chipyard_root"
