.DEFAULT_GOAL := all
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(ROOT)/config.example.mk
-include $(ROOT)/config.local.mk
C ?= 12
N ?= 32
P ?= 2
STRIDE ?= 64
SCALE ?= 1
OFFSET ?= 0
OPS ?= 32
SAMPLES ?= 12
WARMUPS ?= 3
LANE ?= 0
PORT ?= /dev/ttyACM0
RUN ?= micro_01
OUT := $(ROOT)/build
ELF := $(OUT)/dma_spad_micro.elf
export CROSS HOST_CC OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL TIO_BIN
export MICRO_C := $(C)
export MICRO_N := $(N)
export MICRO_P := $(P)
export MICRO_STRIDE := $(STRIDE)
export MICRO_SCALE := $(SCALE)
export MICRO_OFFSET := $(OFFSET)
export MICRO_OPS := $(OPS)
export MICRO_SAMPLES := $(SAMPLES)
export MICRO_WARMUPS := $(WARMUPS)
export MICRO_LANE := $(LANE)
export MICRO_ARCH := -march=rv64gc -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
export MICRO_FLAGS := -O2 -g -std=gnu11 -ffreestanding -fno-builtin -fno-tree-vectorize -ffunction-sections -fdata-sections -Wall -Wextra -Werror
INC := -I$(ROOT)/include -I$(OUT)/generated
.PHONY: all prepare check test preflight program uart analyze force
prepare:
	python3 -B $(ROOT)/scripts/build.py prepare
	@mkdir -p $(OUT)/obj
$(OUT)/obj/%.o: $(ROOT)/src/%.c force | prepare
	$(CROSS)gcc $(MICRO_ARCH) $(MICRO_FLAGS) $(INC) -MMD -MP -c $< -o $@
$(ELF): $(addprefix $(OUT)/obj/,main.o hardware.o reference.o) $(ROOT)/src/start.S $(ROOT)/src/trap.S $(ROOT)/src/link.ld
	$(CROSS)gcc $(MICRO_ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(ROOT)/src/trap.S $(filter %.o,$^) -lgcc -o $@
all: prepare $(ELF)
	python3 -B $(ROOT)/scripts/build.py record
	$(CROSS)size $(ELF)
check:
	python3 -B $(ROOT)/scripts/build.py check
test: all
	python3 -B -m unittest discover -s $(ROOT)/tests -v
preflight: check
	python3 -B $(ROOT)/scripts/program.py preflight
program: check
	python3 -B $(ROOT)/scripts/program.py load --run $(RUN)
uart:
	python3 -B $(ROOT)/scripts/program.py uart --run $(RUN) --port $(PORT)
analyze:
	python3 -B $(ROOT)/scripts/analyze.py "$(LOG)"
-include $(wildcard $(OUT)/obj/*.d)
