.DEFAULT_GOAL := all
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT := $(abspath $(ROOT)/../../../..)
-include $(PROJECT)/tools/config/tools.local.mk
CROSS ?= $(if $(TOOLCHAIN),$(TOOLCHAIN),riscv64-unknown-elf-)
include $(ROOT)/config.example.mk
-include $(ROOT)/config.local.mk
OUT ?= $(PROJECT)/build/experiments/dma_load/streaming_diagnostics
export FRONTEND_BUILD := $(OUT)
DMA_CONTEXT ?=
GEN := $(OUT)/generated
MODEL := $(ROOT)/model
export CROSS HOST_CC VIVADO_BIN OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL TIO_BIN
DMA_ABLATION ?= 1
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
FLAGS := -DDMA_REQUIRE_SPAD_ONLY=$(DMA_ABLATION) -O2 -g -std=gnu11 -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fno-tree-vectorize -Wall -Wextra -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare -Werror=implicit-function-declaration
INC := -I$(GEN) -I$(ROOT)/include -I$(GEN)/include -I$(MODEL) -I$(MODEL)/include
export DMA_CFLAGS := $(FLAGS)
export DMA_ARCH := $(ARCH)
COMMON := $(addprefix $(OUT)/obj/,support.o inputs.o publication.o queue.o slots.o)
IPC_COMPAT := $(OUT)/program/libdigilent_ipc_compat.so
TEST ?= model
PORT ?= /dev/ttyACM0
RUN ?= $(shell date +%Y%m%d_%H%M%S)
.PHONY: all prepare first model check test host-check preflight uart analyze program-bitstream program-first program-model force-identity help
help:
	@echo 'make all / test / check / preflight: offline only'
	@echo 'make uart TEST=model RUN=model_01 PORT=/dev/ttyACM0'
	@echo 'make program-first / program-model RUN=model_01: download and start ELF'
	@echo 'make program-bitstream RUN=bit_01: program the local candidate'
	@echo 'make analyze LOG=logs/model_01/model.log'
prepare:
	python3 -B $(ROOT)/scripts/identity.py --context "$(DMA_CONTEXT)" --prepare
	python3 -B $(ROOT)/scripts/prepare.py
	@mkdir -p $(OUT)/obj
$(OUT)/obj/support.o: $(ROOT)/src/support.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/inputs.o: $(MODEL)/inputs.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/publication.o: $(MODEL)/ai/postprocess/ai_ppu_publication.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/queue.o: $(MODEL)/ai/postprocess/ai_ppu_queue.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/slots.o: $(MODEL)/ai/runtime/ai_head_slot_queue.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/irq.o: $(ROOT)/src/irq.c | prepare
	$(CROSS)gcc $(filter-out -march=rv64gcv,$(ARCH)) -march=rv64gc $(FLAGS) $(INC) -MMD -MP -c $< -o $@
$(OUT)/obj/boundary_irq.o: $(ROOT)/src/boundary_irq.c | prepare
	$(CROSS)gcc $(filter-out -march=rv64gcv,$(ARCH)) -march=rv64gc $(FLAGS) $(INC) -MMD -MP -c $< -o $@
$(OUT)/obj/model.o: $(ROOT)/src/dma_load_model_main.c force-identity | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) -DATSOFT_THREE_WAY=1 -DYOLO32_FRONTEND_DIAG=2 $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/first.o: $(ROOT)/src/dma_load_first_main.c force-identity | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/yolov5_dma_load_model.elf: $(OUT)/obj/model.o $(OUT)/obj/boundary_irq.o $(COMMON) $(ROOT)/src/start.S $(ROOT)/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(filter %.o,$^) -lm -lgcc -o $@
$(OUT)/yolov5_dma_load_first.elf: $(OUT)/obj/first.o $(OUT)/obj/irq.o $(OUT)/obj/support.o $(OUT)/obj/inputs.o $(ROOT)/src/start.S $(ROOT)/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(filter %.o,$^) -lgcc -o $@
first: $(OUT)/yolov5_dma_load_first.elf
model: $(OUT)/yolov5_dma_load_model.elf
all: prepare first model
	$(CROSS)objdump -d $(OUT)/yolov5_dma_load_first.elf > $(OUT)/yolov5_dma_load_first.dis
	$(CROSS)objdump -d $(OUT)/yolov5_dma_load_model.elf > $(OUT)/yolov5_dma_load_model.dis
	python3 -B $(ROOT)/scripts/identity.py --context "$(DMA_CONTEXT)" --record
check:
	python3 -B $(ROOT)/scripts/identity.py --context "$(DMA_CONTEXT)" --check
host-check: prepare
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -DATSOFT_THREE_WAY=1 $(ROOT)/src/boundary_main.c $(MODEL)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/plan_check
	$(OUT)/plan_check $(OUT)/adapted_plan.txt
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -DATSOFT_THREE_WAY=1 -DATSOFT_NATIVE_ORACLE=1 $(ROOT)/src/boundary_main.c $(MODEL)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/native_plan_check
	$(OUT)/native_plan_check $(OUT)/native_plan.txt
	cmp $(OUT)/adapted_plan.txt $(OUT)/native_plan.txt
-include $(wildcard $(OUT)/obj/*.d)
