#!/usr/bin/env bash

# Source this file from the Chipyard repository or any other directory.
opencv_rvv_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
opencv_rvv_conda="${opencv_rvv_root}/.conda-env"
opencv_rvv_toolchain="${OPENCV_RVV_TOOLCHAIN:-clang}"
opencv_rvv_gcc15="${opencv_rvv_conda}/toolchains/xpack-riscv-none-elf-gcc-15.2.0-1"

export OPENCV_RVV_ROOT="${opencv_rvv_root}"
export OPENCV_RVV_SOURCE="${opencv_rvv_root}/third_party_rvv/opencv"
export OPENCV_RVV_CONDA_PREFIX="${opencv_rvv_conda}"
export OPENCV_RVV_TOOLCHAIN="${opencv_rvv_toolchain}"
export RISCV="${opencv_rvv_conda}/riscv-tools"
export PATH="${opencv_rvv_conda}/bin:${RISCV}/bin:${PATH}"

case "${opencv_rvv_toolchain}" in
    clang)
        if [[ ! -x "${opencv_rvv_conda}/bin/clang-18" ]]; then
            printf 'error: missing local Clang 18: %s\n' "${opencv_rvv_conda}/bin/clang-18" >&2
            return 1 2>/dev/null || exit 1
        fi
        export OPENCV_RVV_TOOLCHAIN_TAG="clang18"
        export OPENCV_RVV_CC="${opencv_rvv_root}/scripts/opencv_rvv_clang.sh"
        export OPENCV_RVV_CXX="${opencv_rvv_root}/scripts/opencv_rvv_clangxx.sh"
        export OPENCV_RVV_LINK_CC="${RISCV}/bin/riscv64-unknown-elf-gcc"
        export OPENCV_RVV_AR="${RISCV}/bin/riscv64-unknown-elf-ar"
        export OPENCV_RVV_RANLIB="${RISCV}/bin/riscv64-unknown-elf-ranlib"
        export OPENCV_RVV_READELF="${RISCV}/bin/riscv64-unknown-elf-readelf"
        export OPENCV_RVV_OBJDUMP="${RISCV}/bin/riscv64-unknown-elf-objdump"
        export OPENCV_RVV_SIZE="${RISCV}/bin/riscv64-unknown-elf-size"
        export OPENCV_RVV_GDB="${RISCV}/bin/riscv64-unknown-elf-gdb"
        ;;
    gcc15)
        if [[ ! -x "${opencv_rvv_gcc15}/bin/riscv-none-elf-g++" ]]; then
            printf 'error: missing xPack GCC 15.2: %s\n' "${opencv_rvv_gcc15}" >&2
            printf 'run: %s/scripts/install_opencv_rvv_gcc15.sh\n' "${opencv_rvv_root}" >&2
            return 1 2>/dev/null || exit 1
        fi
        export OPENCV_RVV_TOOLCHAIN_TAG="gcc15"
        export OPENCV_RVV_GCC15_ROOT="${opencv_rvv_gcc15}"
        export OPENCV_RVV_CC="${opencv_rvv_gcc15}/bin/riscv-none-elf-gcc"
        export OPENCV_RVV_CXX="${opencv_rvv_gcc15}/bin/riscv-none-elf-g++"
        # Keep the established Chipyard startup/syscalls runtime. xPack's
        # bare-metal target lowers syscalls.c __thread buffers to emulated TLS,
        # while this runtime initializes native tp/.tdata and has no heap.
        export OPENCV_RVV_LINK_CC="${RISCV}/bin/riscv64-unknown-elf-gcc"
        export OPENCV_RVV_AR="${opencv_rvv_gcc15}/bin/riscv-none-elf-ar"
        export OPENCV_RVV_RANLIB="${opencv_rvv_gcc15}/bin/riscv-none-elf-ranlib"
        export OPENCV_RVV_READELF="${opencv_rvv_gcc15}/bin/riscv-none-elf-readelf"
        export OPENCV_RVV_OBJDUMP="${opencv_rvv_gcc15}/bin/riscv-none-elf-objdump"
        export OPENCV_RVV_SIZE="${opencv_rvv_gcc15}/bin/riscv-none-elf-size"
        export OPENCV_RVV_GDB="${opencv_rvv_gcc15}/bin/riscv-none-elf-gdb"
        ;;
    *)
        printf 'error: OPENCV_RVV_TOOLCHAIN must be clang or gcc15, got %s\n' \
            "${opencv_rvv_toolchain}" >&2
        return 1 2>/dev/null || exit 1
        ;;
esac

export OPENCV_RVV_ARCH="${OPENCV_RVV_ARCH:-rv64gcv}"
export OPENCV_RVV_ABI="${OPENCV_RVV_ABI:-lp64d}"
export OPENCV_RVV_COMMON_FLAGS="-march=${OPENCV_RVV_ARCH} -mabi=${OPENCV_RVV_ABI}"

unset opencv_rvv_root opencv_rvv_conda opencv_rvv_toolchain opencv_rvv_gcc15
