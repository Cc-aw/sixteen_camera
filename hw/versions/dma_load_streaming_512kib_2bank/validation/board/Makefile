SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help
BOARD := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
FEATURE := $(abspath $(BOARD)/../..)
REPO := $(abspath $(FEATURE)/../../..)
-include $(REPO)/tools/config/tools.local.mk
-include $(BOARD)/config.local.mk
PYTHON ?= python3
HOST_CC ?= cc
VIVADO_BIN ?= vivado
OPENOCD_BIN ?= openocd
GDB_BIN ?= riscv64-unknown-elf-gdb
TIO_BIN ?= tio
RUN_DIR ?= $(REPO)/build/experiments/dma_load/streaming_20261017
DMA_CONTEXT := $(RUN_DIR)/candidate/GENERATION_CONTEXT.json
FIRMWARE := $(RUN_DIR)/firmware
BITSTREAM ?= $(RUN_DIR)/bitstream_recovery_routed_20261019/dma_load_streaming.bit
RECORD := $(FEATURE)/validation/bitstream_recovery.json
IPC_COMPAT := $(BOARD)/build/program/libdigilent_ipc_compat.so
RUN ?= $(shell date +%Y%m%d_%H%M%S)
TEST ?= first
PORT ?= /dev/ttyACM0
LOG_DIR := $(BOARD)/logs/$(RUN)
LOG ?= $(LOG_DIR)/$(TEST).log
export OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL VIVADO_BIN
BOARD_ARGS = --record "$(RECORD)" --context "$(DMA_CONTEXT)" --firmware "$(FIRMWARE)" --bitstream "$(BITSTREAM)"

.PHONY: help check preflight program-bitstream program-first program-model uart analyze
help:
	@printf '%s\n' \
	  'preflight              Verify recorded bitstream/ELFs and installed tools; no board access' \
	  'program-bitstream      Download the verified streaming bitstream' \
	  'program-first          Download and start the existing first-layer ELF' \
	  'program-model          Download and start the existing full-graph ELF' \
	  'uart TEST=first RUN=x  Capture UART before starting the ELF (also TEST=model)' \
	  'analyze TEST=first RUN=x  Validate UART and write JSON/text results' \
	  'Set RUN consistently in both terminals; PORT defaults to /dev/ttyACM0' \
	  'This entry uses the already audited artifacts and never rebuilds firmware or hardware.'

check:
	$(PYTHON) -B "$(BOARD)/board.py" check $(BOARD_ARGS)
	$(MAKE) -C "$(FEATURE)/software" check DMA_CONTEXT="$(DMA_CONTEXT)" OUT="$(FIRMWARE)"

$(IPC_COMPAT): $(BOARD)/program/digilent_ipc_compat.c
	@mkdir -p "$(dir $@)"
	$(HOST_CC) -std=gnu11 -O2 -Wall -Wextra -Werror -fPIC -shared "$<" -ldl -pthread -o "$@"

preflight: check $(IPC_COMPAT)
	TCL_SCRIPT="$(BOARD)/program/program_bitstream.tcl" bash "$(REPO)/tools/program/download_bitstream.sh" --check --vivado "$(VIVADO_BIN)" --bitstream "$(BITSTREAM)"
	ELF_FILE="$(FIRMWARE)/yolov5_dma_load_first.elf" bash "$(REPO)/tools/program/run_firmware.sh" --no-build --check
	ELF_FILE="$(FIRMWARE)/yolov5_dma_load_model.elf" bash "$(REPO)/tools/program/run_firmware.sh" --no-build --check
	@command -v "$(TIO_BIN)" >/dev/null
	@vivado_path="$$(command -v "$(VIVADO_BIN)")"; test -x "$$(dirname "$$(readlink -f "$$vivado_path")")/hw_server"
	@echo 'STREAMING_BOARD_PREFLIGHT=PASS board_accessed=0'

program-bitstream: check $(IPC_COMPAT)
	$(PYTHON) -B "$(BOARD)/program/vivado_program.py" --vivado "$(VIVADO_BIN)" --bitstream "$(BITSTREAM)" --tcl "$(BOARD)/program/program_bitstream.tcl" --log "$(LOG_DIR)/vivado_program.log"

program-first program-model: check
	ELF_FILE="$(FIRMWARE)/yolov5_dma_load_$(patsubst program-%,%,$@).elf" bash "$(REPO)/tools/program/run_firmware.sh" --no-build

uart:
	@test "$(TEST)" = first -o "$(TEST)" = model
	@mkdir -p "$(LOG_DIR)"
	@test ! -e "$(LOG)" || { echo 'UART log exists; choose a new RUN label.' >&2; exit 1; }
	"$(TIO_BIN)" -b 115200 -d 8 -s 1 -p none -f none -l "$(LOG)" "$(PORT)"

analyze: check
	$(PYTHON) -B "$(BOARD)/board.py" analyze $(BOARD_ARGS) --log "$(LOG)" --test "$(TEST)"
