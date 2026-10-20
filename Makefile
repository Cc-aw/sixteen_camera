# The board-validated S1 hardware and live-video software are the sole default.
.DEFAULT_GOAL := help
PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
-include $(PROJECT_ROOT)/tools/config/tools.local.mk
SOC_VARIANT ?= dma_load_streaming_asram_s1_512kib_2bank
ifneq ($(SOC_VARIANT),dma_load_streaming_asram_s1_512kib_2bank)
$(error The default hardware/software pair is dma_load_streaming_asram_s1_512kib_2bank)
endif
HW := $(PROJECT_ROOT)/hw/soc/version/$(SOC_VARIANT)
SW := $(PROJECT_ROOT)/sw/video_runtime/$(SOC_VARIANT)
VIVADO_BIN ?= vivado
CROSS ?= $(or $(TOOLCHAIN),riscv64-unknown-elf-)
HOST_CC ?= cc
OPENOCD_BIN ?= openocd
GDB_BIN ?= $(CROSS)gdb
RUN ?= s1_01
PORT ?= /dev/ttyACM0
PROJECT_OUTPUT ?= $(HW)/build/production
SOC_WORKSPACE ?= $(HW)/build/workspace
SOC_OUTPUT ?= $(HW)/build/generated
JOBS ?= 8
export CROSS VIVADO_BIN OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL HOST_CC
export SOC_VARIANT SOC_CONFIG JAVA_HOME SBT_LAUNCH RISCV

.PHONY: help check check-deps firmware benchmark test test-default test-software test-host test-runtime test-tensor test-rtl test-input-rtl preflight check-firmware program program-bitstream board-run board-live uart analyze project elaborate synth bitstream soc prepare-workspace
help:
	@printf '%s\n' \
	  'Default: S1 DMA streaming + ASRAM, L2 512 KiB / 2 bank, live YOLO video Runtime' \
	  'make check / check-deps     Check selected hardware/software identity and source closure' \
	  'make firmware / preflight  Build the live ELF / check downloads offline' \
	  'make program-bitstream RUN=bit_01  Program the board-validated S1 bitstream' \
	  'make board-live RUN=live_01 PORT=/dev/ttyACM0  Continuous inference; Ctrl-C stops/drains' \
	  'make board-run RUN=sample_01 PORT=/dev/ttyACM0  About 100 total inferences' \
	  'make program / uart        Load ELF / capture UART separately' \
	  'make test                  Software scenarios, tools and capture RTL' \
	  'make test-rtl              Three native Gemminis + ASRAM numerical regression' \
	  'make benchmark             Independent S1 fixed-image benchmark' \
	  'make project / elaborate / synth / bitstream  Reconstruct/build S1 hardware' \
	  'make soc SOC_WORKSPACE=<new path below S1 build/> SOC_OUTPUT=<new path>' \
	  'Local tool overrides: tools/config/tools.local.mk'

check:
	python3 -B $(PROJECT_ROOT)/tools/check/check_current_product.py
	tclsh $(PROJECT_ROOT)/tools/check/check_production_manifest.tcl
check-deps: check
	python3 -B $(PROJECT_ROOT)/tools/check/check_dependencies.py
firmware: check
	$(MAKE) -C $(SW) all
check-firmware:
	$(MAKE) -C $(SW) check
preflight:
	$(MAKE) -C $(SW) preflight
benchmark:
	$(MAKE) -C $(PROJECT_ROOT)/sw/board_tests/$(SOC_VARIANT) all
test-default: check
	python3 -B $(PROJECT_ROOT)/tests/default_s1/run.py
test: test-default
	$(MAKE) -C $(SW) test
test-software test-host test-runtime: firmware
	python3 -B $(SW)/tests/run.py
test-input-rtl test-tensor:
	$(MAKE) -C $(SW) test-input-rtl
test-rtl:
	$(MAKE) -C $(HW) test-rtl $(if $(RTL_RUN),RTL_RUN=$(RTL_RUN))
program program-bitstream board-run board-live uart:
	$(MAKE) -C $(SW) $@ RUN=$(RUN) PORT=$(PORT)
analyze:
	$(MAKE) -C $(SW) analyze LOG="$(LOG)"
project: check
	$(MAKE) -C $(HW) project PROJECT_OUTPUT="$(PROJECT_OUTPUT)"
elaborate synth bitstream: check
	python3 -B $(PROJECT_ROOT)/tools/build/build_s1.py $@ --project "$(PROJECT_OUTPUT)" --jobs $(JOBS)
prepare-workspace:
	$(MAKE) -C $(HW) prepare-workspace WORKSPACE="$(SOC_WORKSPACE)"
soc:
	$(MAKE) -C $(HW) soc WORKSPACE="$(SOC_WORKSPACE)" OUTPUT="$(SOC_OUTPUT)"
