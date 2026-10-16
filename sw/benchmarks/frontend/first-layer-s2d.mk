ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT := $(abspath $(ROOT)/../../..)
-include $(PROJECT)/tools/config/tools.local.mk
OUT := $(PROJECT)/build/firmware/first-layer-s2d
GEN := $(OUT)/generated
NATIVE := $(OUT)/native
CROSS ?= $(if $(TOOLCHAIN),$(TOOLCHAIN),riscv64-unknown-elf-)
HOST_CC ?= cc
export CROSS HOST_CC
export FRONTEND_BUILD := $(OUT)
export SW_P3 := 0
INC := -I$(GEN) -I$(ROOT)/include -I$(NATIVE)
FLAGS := -O2 -g -std=gnu11 -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fno-tree-vectorize -Wall -Wextra -Werror -Wno-unused-function
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
COMMON := $(addprefix $(OUT)/common/,support.o inputs.o irq.o)
ELF := $(OUT)/yolov5_first_layer_s2d.elf
.DEFAULT_GOAL := all
.PHONY: all prepare test test-rtl audit
prepare:
	$(MAKE) -f $(ROOT)/Makefile prepare $(COMMON)
	python3 -B $(ROOT)/scripts/first_layer_s2d_prepare.py
all: prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -c $(ROOT)/src/first_layer_s2d_main.c -o $(OUT)/main.o
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(ELF:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/main.o $(COMMON) -lgcc -o $(ELF)
	$(CROSS)objdump -d $(ELF) > $(ELF:.elf=.dis)
	$(CROSS)size $(ELF)
	python3 -B $(ROOT)/scripts/check_first_layer_s2d.py --record
test: all
	python3 -B $(PROJECT)/tests/model/first_layer_s2d/test_s2d.py
test-rtl: all
	python3 -B $(PROJECT)/tests/model/first_layer_s2d/test_real_gemmini.py
audit:
	python3 -B $(ROOT)/scripts/check_first_layer_s2d.py
