.DEFAULT_GOAL := all
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(ROOT)/config.example.mk
-include $(ROOT)/config.local.mk
export CROSS HOST_CC VIVADO_BIN OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL
VIDEO_STREAM_MASK ?= 0xffff
RUN ?= video_01
PORT ?= /dev/ttyACM0
OUT := $(ROOT)/build
ELF := $(OUT)/s1_video_runtime.elf
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
VENDOR_DIRS := $(wildcard $(ROOT)/bsp/amd/*/src)
INC := -I$(ROOT)/build/yolo_generated -I$(ROOT)/build/yolo_generated/include -I$(ROOT)/runtime -I$(ROOT)/runtime/board -I$(ROOT)/include -I$(ROOT)/model -I$(ROOT)/model/include -I$(ROOT)/bsp/board/include $(addprefix -I,$(VENDOR_DIRS))
FLAGS := -O2 -g -std=gnu11 -ffreestanding -fno-builtin -fno-tree-vectorize -fno-common -ffunction-sections -fdata-sections -Wall -Wextra -Werror -DXV_CONFIG_LOG_DISABLE_ALL -DAI_MODEL_WORKER_COUNT=3U -DYOLOV5NU_DIM16_WORKER_COUNT=3U -DYOLOV5NU_GEMMINI_DIM=32 -DYOLO32_LIVE=1 -DVIDEO_STREAM_MASK=$(VIDEO_STREAM_MASK)
MODEL_FLAGS := -include $(ROOT)/include/config.h -DATSOFT_THREE_WAY=1 -DYOLO_SPPF_ASRAM=0 -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare
include $(ROOT)/sources.mk
OBJECTS := $(addprefix $(OUT)/obj/,$(addsuffix .o,$(basename $(SOURCES))))
.PHONY: all prepare force check test preflight program program-bitstream uart board-run board-live help
help:
	@echo 'make all / test / preflight: offline only'
	@echo 'make program-bitstream RUN=bit_01: reset/program frozen S1 hardware'
	@echo 'make uart RUN=video_01 PORT=/dev/ttyACM0: UART capture and keyboard'
	@echo 'make program RUN=video_01: load live-video ELF; continuous inference'
	@echo 'make board-run RUN=video_01: capture and load; stop after ~100 TOTAL results'
	@echo 'make board-live RUN=live_01: continuous inference and UART capture; Ctrl-C drains/stops'
prepare:
	@mkdir -p $(OUT)
	python3 -B $(ROOT)/scripts/prepare_yolo.py
	@python3 -c 'from pathlib import Path; p=Path("$(OUT)/flags"); s="$(ARCH) $(FLAGS) $(MODEL_FLAGS)\n"; p.write_text(s) if not p.exists() or p.read_text()!=s else None'
$(OBJECTS): $(OUT)/flags
$(OUT)/flags: | prepare
$(OUT)/obj/src/yolo_boundary.o: FLAGS += $(MODEL_FLAGS)
$(OUT)/obj/model/ai/postprocess/ai_ppu_publication.o $(OUT)/obj/model/ai/postprocess/ai_ppu_queue.o: FLAGS += -DYOLO32_PPU_ORDERED_MMIO=1
$(OUT)/obj/src/yolo_irq.o: ARCH := -march=rv64gc -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
$(OUT)/obj/%.o: $(ROOT)/%.c
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) $(if $(filter $(OUT)/obj/bsp/amd/%,$@),-Wno-error -Wno-unused-parameter -Wno-sign-compare -Wno-type-limits -Wno-unused-variable -Wno-incompatible-pointer-types -Wno-return-type -Wno-enum-conversion -include board/xparameters.h -include string.h) $(if $(filter $(OUT)/obj/bsp/board/%,$@),-iquote $(ROOT)/runtime/platform) -MMD -MP -c $< -o $@
$(OUT)/obj/%.o: $(ROOT)/%.S
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) -g -c $< -o $@
$(ELF): $(OBJECTS) $(ROOT)/src/yolo_link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -static -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/yolo_link.ld $(OBJECTS) -lm -lgcc -o $@
$(OUT)/program/libdigilent_ipc_compat.so: $(ROOT)/program/digilent_ipc_compat.c
	@mkdir -p $(@D)
	$(HOST_CC) -std=gnu11 -O2 -Wall -Wextra -Werror -fPIC -shared $< -ldl -pthread -o $@
all: prepare $(ELF) $(OUT)/program/libdigilent_ipc_compat.so
	$(CROSS)size $(ELF)
	python3 -B $(ROOT)/scripts/build.py record
check:
	python3 -B $(ROOT)/scripts/build.py check
test-input-rtl:
	python3 -B $(ROOT)/tests/run_input_rtl.py
test: all test-input-rtl
	python3 -B $(ROOT)/tests/run.py
preflight: check
	python3 -B $(ROOT)/scripts/program.py preflight
program: check
	python3 -B $(ROOT)/scripts/program.py load --run $(RUN)
program-bitstream: check
	python3 -B $(ROOT)/scripts/program.py bitstream --run $(RUN)
uart:
	python3 -B $(ROOT)/scripts/program.py uart --run $(RUN) --port $(PORT)
analyze:
	python3 -B $(ROOT)/scripts/analyze.py "$(LOG)"
board-live: check
	python3 -B $(ROOT)/scripts/run_board.py --live --run $(RUN) --port $(PORT)
board-run: check
	python3 -B $(ROOT)/scripts/run_board.py --run $(RUN) --port $(PORT)
-include $(OBJECTS:.o=.d)
