ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT := $(abspath $(ROOT)/../../..)
-include $(PROJECT)/tools/config/tools.local.mk
OUT := $(PROJECT)/build/firmware/frontend-v34
GEN := $(OUT)/generated
NATIVE := $(OUT)/native
CROSS ?= $(if $(TOOLCHAIN),$(TOOLCHAIN),riscv64-unknown-elf-)
HOST_CC ?= cc
export CROSS HOST_CC
export FRONTEND_BUILD := $(OUT)
export SW_P3 := 0
INC := -I$(GEN) -I$(ROOT)/include -I$(GEN)/include -I$(NATIVE) -I$(NATIVE)/include
FLAGS := -O2 -g -std=gnu11 -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fno-tree-vectorize -Wall -Wextra -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare -Werror=implicit-function-declaration
MODE := -DATSOFT_THREE_WAY=1 -DYOLO32_FRONTEND_DIAG=2
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
COMMON := $(addprefix $(OUT)/common/,support.o inputs.o publication.o queue.o slots.o)
ELF := $(OUT)/yolov5_frontend_boundary_diag_12.elf
.DEFAULT_GOAL := all
.PHONY: all prepare test audit
prepare:
	$(MAKE) -f $(ROOT)/Makefile prepare $(COMMON)
all: prepare
	$(HOST_CC) $(FLAGS) $(MODE) $(INC) -include $(ROOT)/include/config.h $(ROOT)/src/boundary_main.c $(NATIVE)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/boundary_plan_check
	$(OUT)/boundary_plan_check $(OUT)/boundary_plan.txt
	cmp $(OUT)/boundary_plan.txt $(PROJECT)/build/firmware/frontend/native_plan.txt
	$(CROSS)gcc -march=rv64gc -mabi=lp64d -mcmodel=medany $(FLAGS) -c $(ROOT)/src/boundary_irq.c -o $(OUT)/boundary_irq.o
	$(CROSS)gcc $(ARCH) $(FLAGS) $(MODE) $(INC) -include $(ROOT)/include/config.h -c $(ROOT)/src/boundary_main.c -o $(OUT)/boundary_main.o
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(ELF:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/boundary_main.o $(OUT)/boundary_irq.o $(COMMON) -lm -lgcc -o $(ELF)
	$(CROSS)objdump -d $(ELF) > $(ELF:.elf=.dis)
	python3 -B $(ROOT)/scripts/check_boundary_elf.py $(ELF) --three-way --diagnostic
	python3 -B $(ROOT)/scripts/boundary_manifest.py
test: all
	python3 -B $(PROJECT)/tests/model/frontend_v34/test_boundary.py
audit:
	python3 -B $(ROOT)/scripts/boundary_manifest.py --check
	python3 -B $(ROOT)/scripts/check_boundary_elf.py $(ELF) --three-way --diagnostic
