ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT := $(abspath $(ROOT)/../../..)
-include $(PROJECT)/tools/config/tools.local.mk
SW_P3_MODE ?= reference
ifeq ($(filter $(SW_P3_MODE),reference compare),)
$(error SW_P3_MODE must be reference or compare)
endif
OUT := $(PROJECT)/build/firmware/$(if $(filter compare,$(SW_P3_MODE)),sw-p3-compare,sw-p3)
GEN := $(OUT)/generated
NATIVE := $(OUT)/native
CROSS ?= $(if $(TOOLCHAIN),$(TOOLCHAIN),riscv64-unknown-elf-)
HOST_CC ?= cc
VIVADO_BIN ?= vivado
export CROSS HOST_CC VIVADO_BIN SW_P3_MODE
export SW_P3 := 1
export FRONTEND_BUILD := $(OUT)
INC := -I$(GEN) -I$(ROOT)/src -I$(ROOT)/include -I$(GEN)/include -I$(NATIVE) -I$(NATIVE)/include
FLAGS := -DATSOFT_THREE_WAY=1 -DSW_P3_COMPARE=$(if $(filter compare,$(SW_P3_MODE)),1,0) -O2 -g -std=gnu11 -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fno-tree-vectorize -Wall -Wextra -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare -Werror=implicit-function-declaration
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
COMMON := $(addprefix $(OUT)/common/,irq.o support.o inputs.o publication.o queue.o slots.o)
ELF := $(OUT)/yolov5_sw_p3_suite_12.elf
.DEFAULT_GOAL := all
.PHONY: all prepare common test audit
# Prepare is deliberately explicit: candidate searches and address audits must
# not silently reuse a stale generated manifest after a tool/source change.
prepare:
	$(MAKE) -f $(ROOT)/Makefile prepare
	python3 -B $(ROOT)/scripts/prepare.py
common: prepare
	$(MAKE) -f $(ROOT)/Makefile $(COMMON)
all: common
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h $(GEN)/sw_p3_main.c $(NATIVE)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/sw_p3_plan_check
	$(OUT)/sw_p3_plan_check $(OUT)/reference_plan.txt 0
	python3 -B $(ROOT)/scripts/parallel_cache_verify.py --identity
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -c $(GEN)/sw_p3_main.c -o $(OUT)/suite.o
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(ELF:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/suite.o $(COMMON) -lm -lgcc -o $(ELF)
	python3 -B $(ROOT)/scripts/parallel_cache_verify.py --search
	python3 -B $(ROOT)/scripts/parallel_cache_verify.py --identity
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h $(GEN)/sw_p3_main.c $(NATIVE)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/sw_p3_plan_check
	$(OUT)/sw_p3_plan_check $(OUT)/layout_plan.txt 1
	$(OUT)/sw_p3_plan_check $(OUT)/cache_plan.txt 2
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -c $(GEN)/sw_p3_main.c -o $(OUT)/suite.o
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(ELF:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/suite.o $(COMMON) -lm -lgcc -o $(ELF)
	$(CROSS)objdump -d $(ELF) > $(ELF:.elf=.dis)
	python3 -B $(ROOT)/scripts/parallel_cache_verify.py --record

test: all
ifeq ($(SW_P3_MODE),compare)
	python3 -B $(PROJECT)/tests/model/frontend_parallel_cache/test_real_tiling.py --reuse
	$(MAKE) -f $(ROOT)/sw-p3.mk all
endif
	python3 -B $(PROJECT)/tests/model/frontend_parallel_cache/run_tests.py

audit:
	python3 -B $(ROOT)/scripts/parallel_cache_verify.py --audit
