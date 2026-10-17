ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT := $(abspath $(ROOT)/../../..)
-include $(PROJECT)/tools/config/tools.local.mk
OUT := $(PROJECT)/build/firmware/dma-load-2bank
GEN := $(OUT)/generated
NATIVE := $(OUT)/native
CROSS ?= $(if $(TOOLCHAIN),$(TOOLCHAIN),riscv64-unknown-elf-)
HOST_CC ?= cc
export CROSS HOST_CC
export FRONTEND_BUILD := $(OUT)
export SW_P3 := 0
DMA_CONTEXT ?=
INC := -I$(GEN) -I$(ROOT)/include -I$(GEN)/include -I$(NATIVE) -I$(NATIVE)/include
FLAGS := -O2 -g -std=gnu11 -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fno-tree-vectorize -Wall -Wextra -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare -Werror=implicit-function-declaration
MODE := -DATSOFT_THREE_WAY=1 -DYOLO32_FRONTEND_DIAG=2
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
COMMON := $(addprefix $(OUT)/common/,support.o inputs.o publication.o queue.o slots.o)
ELF := $(OUT)/yolov5_dma_load_model.elf
FIRST_ELF := $(OUT)/yolov5_dma_load_first.elf
.DEFAULT_GOAL := all
.PHONY: all prepare audit
prepare:
	$(MAKE) -f $(ROOT)/v34.mk prepare OUT=$(OUT)
	$(MAKE) -f $(ROOT)/Makefile $(OUT)/common/irq.o
	python3 -B $(ROOT)/scripts/first_layer_s2d_prepare.py
	python3 -B $(ROOT)/scripts/dma_load_manifest.py --context "$(DMA_CONTEXT)" --prepare
all: prepare
	$(CROSS)gcc -march=rv64gc -mabi=lp64d -mcmodel=medany $(FLAGS) -c $(ROOT)/src/boundary_irq.c -o $(OUT)/boundary_irq.o
	$(CROSS)gcc $(ARCH) $(FLAGS) $(MODE) $(INC) -include $(ROOT)/include/config.h -c $(ROOT)/src/dma_load_model_main.c -o $(OUT)/dma_load_model.o
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(ELF:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/dma_load_model.o $(OUT)/boundary_irq.o $(COMMON) -lm -lgcc -o $(ELF)
	$(CROSS)objdump -d $(ELF) > $(ELF:.elf=.dis)
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -c $(ROOT)/src/dma_load_first_main.c -o $(OUT)/dma_load_first.o
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(FIRST_ELF:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/dma_load_first.o $(OUT)/common/irq.o $(OUT)/common/support.o $(OUT)/common/inputs.o -lgcc -o $(FIRST_ELF)
	$(CROSS)objdump -d $(FIRST_ELF) > $(FIRST_ELF:.elf=.dis)
	python3 -B $(ROOT)/scripts/dma_load_manifest.py --context "$(DMA_CONTEXT)" --record
audit:
	python3 -B $(ROOT)/scripts/dma_load_manifest.py --context "$(DMA_CONTEXT)" --check
