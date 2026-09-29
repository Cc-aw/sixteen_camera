#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
toolchain=${TOOLCHAIN:-/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-}
abi="$root/soc_shell/npu100_video/software/gemmini-rocc-tests"
tests=/home/wzr/chipyard/generators/gemmini/software/gemmini-rocc-tests
config=tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig
params="$root/generated/soc/$config/gen-collateral/include/gemmini_params_64x64_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h"
diag=${STANDALONE_INTERNAL_DIAGNOSTICS:-0}
[[ "$diag" == 0 || "$diag" == 1 ]] || { echo "STANDALONE_INTERNAL_DIAGNOSTICS must be 0 or 1" >&2; exit 2; }
no_reuse=${STANDALONE_DISABLE_B_REUSE:-0}
[[ "$no_reuse" == 0 || "$no_reuse" == 1 ]] || { echo 'STANDALONE_DISABLE_B_REUSE must be 0 or 1' >&2; exit 2; }
limit=${STANDALONE_CREDIT_LIMIT:-4}
[[ "$limit" == 1 || "$limit" == 4 ]] || { echo 'STANDALONE_CREDIT_LIMIT must be 1 or 4' >&2; exit 2; }
build="$root/sw/build/gemmini_standalone"
if [[ "$limit" == 1 ]]; then build="${build}_serial"; fi
if [[ "$no_reuse" == 1 ]]; then build="${build}_noreuse"; fi
if [[ "$diag" == 1 ]]; then build="${build}_diag9"; fi
mkdir -p "$build"
"${toolchain}gcc" -march=rv64gcv -mabi=lp64d -mcmodel=medany -c "$root/sw/src/startup.S" -o "$build/startup.o"
"${toolchain}gcc" -march=rv64gcv -mabi=lp64d -mcmodel=medany -std=gnu11 -O2 -g3 \
  -ffreestanding -fno-builtin -ffunction-sections -fdata-sections -DBAREMETAL=1 -DGEMMINI_INTERNAL_DIAGNOSTICS="$diag" -DGEMMINI_LOOPCONV_CREDIT_SAFE_MAX_OVERRIDE="$limit" -DGEMMINI_DISABLE_B_REUSE="$no_reuse" \
  -I"$root/sw/src" -I"$abi" -I"$tests" -include "$params" \
  -nostdlib -nostartfiles -Wl,--gc-sections -Wl,-Map,"$build/test.map" \
  -T "$root/sw/gemmini_standalone/linker.ld" \
  "$build/startup.o" "$root/sw/src/board_runtime.c" \
  "$root/sw/gemmini_standalone/main.c" -lgcc -o "$build/test.elf"
"${toolchain}size" "$build/test.elf"
"${toolchain}objdump" -d "$build/test.elf" > "$build/test.dis"
printf 'GEMMINI_STANDALONE_ELF=%s\n' "$build/test.elf"
