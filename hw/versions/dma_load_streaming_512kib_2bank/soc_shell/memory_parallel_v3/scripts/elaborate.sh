#!/usr/bin/env bash
set -euo pipefail
cy=$(realpath "${CHIPYARD_ROOT:?Set private Chipyard checkout}")
[[ -f "$cy/.npu100-video-workspace.json" && "$cy" != /home/wzr/chipyard ]]
export COURSIER_CACHE="$cy/.coursier/v1"
export XDG_RUNTIME_DIR="$cy/.runtime"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
export RISCV="$cy/.conda-env/riscv-tools"
export JAVA_HOME="$cy/.conda-env/lib/jvm"
export PATH="$JAVA_HOME/bin:$cy/.conda-env/bin:$cy/.local/bin:$cy/.local-espresso/bin:$RISCV/bin:$PATH"
export JAVA_TOOL_OPTIONS="-Xmx16G -Xss8M -XX:ActiveProcessorCount=8 -Djava.io.tmpdir=$cy/.java_tmp"
unset USE_CHISEL7
make -C "$cy/fpga" -W "$cy/build.sbt" verilog SUB_PROJECT=taihang_soc \
  SBT_PROJECT=chipyard_fpga MODEL=TaihangSoCFPGATestHarness VLOG_MODEL=TaihangSoCFPGATestHarness \
  MODEL_PACKAGE=tsmcchip.fpga.taihangsoc CONFIG_PACKAGE=tsmcchip.fpga.taihangsoc \
  CONFIG=TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config GENERATOR_PACKAGE=chipyard TOP=ChipTop TB=none
bash "$(dirname "${BASH_SOURCE[0]}")/postprocess.sh" "$cy/fpga/generated-src/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config/gen-collateral"
