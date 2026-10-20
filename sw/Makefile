# Keep `make -C sw` aligned with the repository's selected live-video package.
.DEFAULT_GOAL := all
SW_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
-include $(SW_ROOT)/../tools/config/tools.local.mk
CROSS ?= $(or $(TOOLCHAIN),riscv64-unknown-elf-)
HOST_CC ?= cc
OPENOCD_BIN ?= openocd
GDB_BIN ?= $(CROSS)gdb
export CROSS HOST_CC VIVADO_BIN OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL
PACKAGE := $(SW_ROOT)/video_runtime/dma_load_streaming_asram_s1_512kib_2bank
.PHONY: all help check test preflight program program-bitstream uart board-run board-live analyze test-input-rtl
all help check test preflight program program-bitstream uart board-run board-live analyze test-input-rtl:
	$(MAKE) -C $(PACKAGE) $@
