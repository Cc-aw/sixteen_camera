.DEFAULT_GOAL := all
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(ROOT)/config.example.mk
-include $(ROOT)/config.local.mk
OUT := $(ROOT)/build
GEN := $(OUT)/generated
MODEL := $(ROOT)/model
export CROSS HOST_CC VIVADO_BIN OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
FLAGS := -O2 -g -std=gnu11 -ffunction-sections -fdata-sections -ffreestanding -fno-builtin -fno-tree-vectorize -Wall -Wextra -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare -Werror=implicit-function-declaration
INC := -I$(GEN) -I$(ROOT)/include -I$(GEN)/include -I$(MODEL) -I$(MODEL)/include
export L2_CFLAGS := $(FLAGS)
export L2_ARCH := $(ARCH)
COMMON := $(addprefix $(OUT)/obj/,support.o inputs.o publication.o queue.o slots.o)
IPC_COMPAT := $(OUT)/program/libdigilent_ipc_compat.so
TEST ?= smoke
PORT ?= /dev/ttyACM0
RUN ?= $(shell date +%Y%m%d_%H%M%S)
.PHONY: all prepare smoke reference diagnostic host-check check test preflight uart analyze program-bitstream program-smoke program-reference program-diagnostic help
.PHONY: force-identity
help:
	@echo 'make all / test / check / preflight: offline only'
	@echo 'make program-bitstream; make uart TEST=smoke RUN=new_smoke PORT=/dev/ttyACM0'
	@echo 'make program-smoke / program-reference / program-diagnostic: explicit board access'
	@echo 'make analyze LOG=logs/new_smoke/smoke.log'
prepare:
	python3 -B $(ROOT)/scripts/package.py prepare
	python3 -B $(ROOT)/scripts/prepare.py
	@mkdir -p $(OUT)/obj
$(OUT)/obj/support.o: $(ROOT)/reference/src/support.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/inputs.o: $(MODEL)/inputs.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/publication.o: $(MODEL)/ai/postprocess/ai_ppu_publication.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/queue.o: $(MODEL)/ai/postprocess/ai_ppu_queue.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/slots.o: $(MODEL)/ai/runtime/ai_head_slot_queue.c | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/irq.o: $(ROOT)/reference/src/irq.c | prepare
	$(CROSS)gcc $(filter-out -march=rv64gcv,$(ARCH)) -march=rv64gc $(FLAGS) $(INC) -MMD -MP -c $< -o $@
$(OUT)/obj/boundary_irq.o: $(ROOT)/reference/src/boundary_irq.c | prepare
	$(CROSS)gcc $(filter-out -march=rv64gcv,$(ARCH)) -march=rv64gc $(FLAGS) $(INC) -MMD -MP -c $< -o $@
$(OUT)/obj/reference.o: $(ROOT)/src/reference_main.c $(ROOT)/reference/src/main.c $(ROOT)/reference/src/ppu.inc | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) -DATSOFT_THREE_WAY=1 $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/diagnostic.o: $(ROOT)/src/diagnostic_main.c $(ROOT)/reference/src/boundary_main.c $(ROOT)/reference/src/memory_diag.inc $(ROOT)/reference/src/ppu.inc | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) -DATSOFT_THREE_WAY=1 -DYOLO32_FRONTEND_DIAG=2 $(INC) -include $(ROOT)/include/config.h -MMD -MP -c $< -o $@
$(OUT)/obj/l2_smoke.o: $(ROOT)/src/l2_smoke.c $(ROOT)/include/board_io.h | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) -Werror $(INC) -MMD -MP -c $< -o $@
$(OUT)/obj/smoke_runtime.o: $(ROOT)/src/smoke_runtime.c $(ROOT)/include/board_io.h | prepare
	$(CROSS)gcc $(filter-out -march=rv64gcv,$(ARCH)) -march=rv64gc $(FLAGS) -Werror $(INC) -MMD -MP -c $< -o $@
$(OUT)/l2_smoke.elf: $(OUT)/obj/l2_smoke.o $(OUT)/obj/smoke_runtime.o $(ROOT)/reference/src/start.S $(ROOT)/reference/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/reference/src/link.ld $(ROOT)/reference/src/start.S $(filter %.o,$^) -lgcc -o $@
$(OUT)/yolov5_reference.elf: $(OUT)/obj/reference.o $(OUT)/obj/irq.o $(COMMON) $(ROOT)/reference/src/start.S $(ROOT)/reference/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/reference/src/link.ld $(ROOT)/reference/src/start.S $(filter %.o,$^) -lm -lgcc -o $@
$(OUT)/yolov5_diagnostic.elf: $(OUT)/obj/diagnostic.o $(OUT)/obj/boundary_irq.o $(COMMON) $(ROOT)/reference/src/start.S $(ROOT)/reference/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/reference/src/link.ld $(ROOT)/reference/src/start.S $(filter %.o,$^) -lm -lgcc -o $@
smoke: $(OUT)/l2_smoke.elf
reference: $(OUT)/yolov5_reference.elf
diagnostic: $(OUT)/yolov5_diagnostic.elf
$(IPC_COMPAT): $(ROOT)/program/digilent_ipc_compat.c
	@mkdir -p $(@D)
	$(HOST_CC) -O2 -std=gnu11 -fPIC -shared -Wall -Wextra -Werror -Wl,-z,relro,-z,now $< -ldl -pthread -o $@
all: prepare smoke reference diagnostic $(IPC_COMPAT)
	python3 -B $(ROOT)/scripts/package.py record
host-check: prepare
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -DATSOFT_THREE_WAY=1 $(ROOT)/reference/src/main.c $(MODEL)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/plan_check
	$(OUT)/plan_check $(OUT)/adapted_plan.txt
	$(HOST_CC) $(FLAGS) $(INC) -include $(ROOT)/include/config.h -DATSOFT_THREE_WAY=1 -DATSOFT_NATIVE_ORACLE=1 $(ROOT)/reference/src/main.c $(MODEL)/inputs.c -Wl,--gc-sections -lm -o $(OUT)/native_plan_check
	$(OUT)/native_plan_check $(OUT)/native_plan.txt
	cmp $(OUT)/adapted_plan.txt $(OUT)/native_plan.txt
check:
	python3 -B $(ROOT)/scripts/package.py check
test: all host-check
	python3 -B $(ROOT)/tests/reference/test_log.py
	python3 -B $(ROOT)/tests/reference/test_boundary.py
	python3 -B $(ROOT)/tests/test_package.py
	python3 -B $(ROOT)/tests/test_programming.py
preflight: check
	python3 -B $(ROOT)/scripts/program.py preflight
program-bitstream: check
	python3 -B $(ROOT)/scripts/program.py bitstream --run $(RUN)
program-smoke program-reference program-diagnostic: check
	python3 -B $(ROOT)/scripts/program.py load --test $(patsubst program-%,%,$@) --run $(RUN)
uart:
	python3 -B $(ROOT)/scripts/program.py uart --test $(TEST) --run $(RUN) --port $(PORT)
analyze:
	python3 -B $(ROOT)/scripts/analyze.py "$(LOG)"
$(OUT)/obj/reference.o $(OUT)/obj/diagnostic.o $(OUT)/obj/smoke_runtime.o: force-identity
-include $(wildcard $(OUT)/obj/*.d)
