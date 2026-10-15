ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT := $(abspath $(ROOT)/../../..)
-include $(PROJECT)/tools/config/tools.local.mk
OUT := $(abspath $(if $(FRONTEND_BUILD),$(FRONTEND_BUILD),$(PROJECT)/build/firmware/frontend))
CROSS ?= $(if $(TOOLCHAIN),$(TOOLCHAIN),riscv64-unknown-elf-)
HOST_CC ?= cc
export CROSS
export FRONTEND_BUILD := $(OUT)
GEN := $(OUT)/generated
NATIVE := $(OUT)/native
LOCK := $(PROJECT)/sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json
PARAMS := $(shell python3 -c 'import json; from pathlib import Path; p=json.load(open("$(PROJECT)/hw/manifests/current.json")); print("$(PROJECT)/"+p["parameter_headers"][p["opcodes"].index("custom0")])')
INPUTS := $(shell python3 -c 'import json; print(" ".join("$(PROJECT)/"+i["path"] for i in json.load(open("$(LOCK)"))["sources"]))')
INC := -I$(GEN) -I$(ROOT)/include -I$(GEN)/include -I$(NATIVE) -I$(NATIVE)/include
FLAGS := -O2 -g -std=gnu11 -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fno-tree-vectorize -Wall -Wextra -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare -Werror=implicit-function-declaration
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
COMMON := $(OUT)/common/irq.o $(OUT)/common/support.o $(OUT)/common/inputs.o $(OUT)/common/publication.o $(OUT)/common/queue.o $(OUT)/common/slots.o
FORMAL := $(OUT)/yolov5_three_way_12.elf
DIAG := $(OUT)/yolov5_frontend_diag_12.elf
TESTS := $(PROJECT)/tests/model/frontend_v33
.DEFAULT_GOAL := all
.PHONY: all prepare host-check check manifest audit
all: $(FORMAL) $(DIAG) manifest
prepare: $(OUT)/prepared.stamp
$(OUT)/prepared.stamp: $(ROOT)/scripts/prepare.py $(LOCK) $(INPUTS) $(PARAMS) $(PROJECT)/hw/manifests/current.json
	@mkdir -p $(OUT)
	python3 -B $(ROOT)/scripts/prepare.py
	@touch $@
$(GEN)/graph.inc: $(OUT)/prepared.stamp
	@test -f $@ || python3 -B $(ROOT)/scripts/prepare.py

$(OUT)/config.stamp: force-config
	@mkdir -p $(OUT)
	@python3 -c 'import sys; from pathlib import Path; p=Path(sys.argv[1]); s=sys.argv[2]+"\n"; p.write_text(s) if not p.exists() or p.read_text()!=s else None' "$@" '$(CROSS) $(ARCH) $(FLAGS) $(INC)'
.PHONY: force-config
$(COMMON) $(OUT)/formal/main.o $(OUT)/diagnostic/main.o: $(OUT)/config.stamp $(OUT)/prepared.stamp $(ROOT)/Makefile
$(OUT)/common/irq.o: $(ROOT)/src/irq.c
	@mkdir -p $(@D)
	$(CROSS)gcc -march=rv64gc -mabi=lp64d -mcmodel=medany $(FLAGS) -MMD -MP -c $< -o $@
$(OUT)/common/support.o: $(ROOT)/src/support.c
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/common/inputs.o: $(NATIVE)/inputs.c
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/common/publication.o: $(NATIVE)/ai/postprocess/ai_ppu_publication.c
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/common/queue.o: $(NATIVE)/ai/postprocess/ai_ppu_queue.c
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/common/slots.o: $(NATIVE)/ai/runtime/ai_head_slot_queue.c
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(NATIVE)/inputs.c $(NATIVE)/ai/postprocess/ai_ppu_publication.c $(NATIVE)/ai/postprocess/ai_ppu_queue.c $(NATIVE)/ai/runtime/ai_head_slot_queue.c: $(OUT)/prepared.stamp
	@test -f $@
$(OUT)/formal/main.o: $(ROOT)/src/main.c $(ROOT)/src/ppu.inc $(GEN)/graph.inc $(wildcard $(ROOT)/include/*.h)
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) -DATSOFT_THREE_WAY=1 $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/diagnostic/main.o: $(ROOT)/src/main.c $(ROOT)/src/ppu.inc $(GEN)/graph.inc $(wildcard $(ROOT)/include/*.h)
	@mkdir -p $(@D)
	$(CROSS)gcc $(ARCH) $(FLAGS) -DATSOFT_THREE_WAY=1 -DYOLO32_FRONTEND_DIAG=1 $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(FORMAL): $(OUT)/formal/main.o $(COMMON) $(ROOT)/src/start.S $(ROOT)/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/formal/main.o $(COMMON) -lm -lgcc -o $@
	$(CROSS)size $@
	$(CROSS)objdump -d $@ > $(@:.elf=.dis)
	python3 -B $(ROOT)/scripts/check_elf.py $@ --three-way
$(DIAG): $(OUT)/diagnostic/main.o $(COMMON) $(ROOT)/src/start.S $(ROOT)/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/link.ld $(ROOT)/src/start.S $(OUT)/diagnostic/main.o $(COMMON) -lm -lgcc -o $@
	$(CROSS)size $@
	$(CROSS)objdump -d $@ > $(@:.elf=.dis)
	python3 -B $(ROOT)/scripts/check_elf.py $@ --three-way --diagnostic
host-check: prepare
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h $(ROOT)/src/main.c $(NATIVE)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/plan_check
	$(OUT)/plan_check $(OUT)/adapted_plan.txt
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -DATSOFT_NATIVE_ORACLE=1 $(ROOT)/src/main.c $(NATIVE)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/native_plan_check
	$(OUT)/native_plan_check $(OUT)/native_plan.txt
	cmp $(OUT)/adapted_plan.txt $(OUT)/native_plan.txt
	@echo 'ATSOFT1,NATIVE_PLAN_MATCH,commands_and_host_boundaries=identical'
audit: $(FORMAL) $(DIAG)
	python3 -B $(ROOT)/scripts/check_elf.py $(FORMAL) --three-way
	python3 -B $(ROOT)/scripts/check_elf.py $(DIAG) --three-way --diagnostic
manifest: $(FORMAL) $(DIAG)
	python3 -B $(ROOT)/scripts/manifest.py
check: all host-check
	python3 -B $(TESTS)/test_dispatch.py
	python3 -B $(TESTS)/test_ppu.py
	python3 -B $(TESTS)/test_log.py
	python3 -B $(ROOT)/scripts/manifest.py --check
-include $(wildcard $(OUT)/common/*.d $(OUT)/formal/*.d $(OUT)/diagnostic/*.d)
