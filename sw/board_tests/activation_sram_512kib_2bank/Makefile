.DEFAULT_GOAL := all
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(ROOT)/config.example.mk
-include $(ROOT)/config.local.mk
export CROSS HOST_CC VIVADO_BIN OPENOCD_BIN GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL TIO_BIN
ARCH := -march=rv64gcv -mabi=lp64d -mcmodel=medany -msmall-data-limit=0
FLAGS := -O2 -g -std=gnu11 -ffreestanding -fno-builtin -fno-tree-vectorize -ffunction-sections -fdata-sections -Wall -Wextra -Werror
export ASRAM_ARCH := $(ARCH)
export ASRAM_FLAGS := $(FLAGS)
YOLO_ROUNDS ?= 1
YOLO_FLAGS := -O2 -g -std=gnu11 -ffreestanding -fno-builtin -fno-tree-vectorize -ffunction-sections -fdata-sections -Wall -Wextra -Wno-unused-variable -Wno-unused-function -Wno-unused-parameter -Wno-sign-compare -Werror=implicit-function-declaration -DATSOFT_THREE_WAY=1 -DYOLO32_FRONTEND_DIAG=2 -DYOLO_ROUNDS=$(YOLO_ROUNDS)
export YOLO_FLAGS
OUT := $(ROOT)/build
ELF := $(OUT)/activation_sram_test.elf
IPC_COMPAT := $(OUT)/program/libdigilent_ipc_compat.so
INC := -I$(ROOT)/include -I$(OUT)/generated
YINC := -I$(OUT)/yolo_generated -I$(OUT)/yolo_generated/include $(INC) -I$(ROOT)/model -I$(ROOT)/model/include -include $(ROOT)/include/config.h
YCOMMON := $(addprefix $(OUT)/yolo_obj/,support.o irq.o inputs.o activation_memory.o publication.o queue.o slots.o start.o)
YMODEL := $(OUT)/yolov5_asram_model.elf
YDIAG := $(OUT)/yolov5_asram_diagnostic.elf
TEST ?= asram
OBJECTS := $(addprefix $(OUT)/obj/,main.o reference.o device.o start.o trap.o probe.o rvv.o)
RUN ?= asram_01
PORT ?= /dev/ttyACM0
.PHONY: all prepare prepare-yolo check test host-check preflight program-bitstream program program-model program-diagnostic uart analyze force help
help:
	@echo 'make all / test / check / preflight: offline only'
	@echo 'make program-bitstream RUN=bit_01: download the ASRAM1 bitstream'
	@echo 'make uart RUN=asram_01 PORT=/dev/ttyACM0: capture UART before starting ELF'
	@echo 'make program RUN=asram_01: download and start the diagnostic ELF'
	@echo 'make program-model / program-diagnostic RUN=yolo_01: run YOLO DDR/local comparison'
	@echo 'make uart TEST=model RUN=yolo_01; make analyze TEST=model LOG=logs/yolo_01/model.log'
	@echo 'make analyze LOG=logs/asram_01/asram.log'
prepare:
	python3 -B $(ROOT)/scripts/build.py prepare
	@mkdir -p $(OUT)/obj
$(OUT)/obj/%.o: $(ROOT)/src/%.c force | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -MMD -MP -c $< -o $@
$(OUT)/obj/%.o: $(ROOT)/src/%.S force | prepare
	$(CROSS)gcc $(ARCH) $(FLAGS) $(INC) -MMD -MP -c $< -o $@
$(ELF): $(OBJECTS) $(ROOT)/src/link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/link.ld $(OBJECTS) -lgcc -o $@
$(IPC_COMPAT): $(ROOT)/program/digilent_ipc_compat.c
	@mkdir -p $(dir $@)
	$(HOST_CC) -std=gnu11 -O2 -Wall -Wextra -Werror -fPIC -shared $< -ldl -pthread -o $@
prepare-yolo: prepare
	python3 -B $(ROOT)/scripts/prepare_yolo.py
	@mkdir -p $(OUT)/yolo_obj
$(OUT)/yolo_obj/model.o: $(ROOT)/src/yolov5_asram_main.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/diagnostic.o: $(ROOT)/src/yolov5_asram_main.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) -DYOLO_DIAGNOSTIC=1 $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/support.o: $(ROOT)/src/yolo_support.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/irq.o: $(ROOT)/src/yolo_irq.c force | prepare-yolo
	$(CROSS)gcc $(filter-out -march=rv64gcv,$(ARCH)) -march=rv64gc $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/inputs.o: $(ROOT)/model/inputs.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/activation_memory.o: $(ROOT)/src/activation_memory.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/publication.o: $(ROOT)/model/ai/postprocess/ai_ppu_publication.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/queue.o: $(ROOT)/model/ai/postprocess/ai_ppu_queue.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/slots.o: $(ROOT)/model/ai/runtime/ai_head_slot_queue.c force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(OUT)/yolo_obj/start.o: $(ROOT)/src/yolo_start.S force | prepare-yolo
	$(CROSS)gcc $(ARCH) $(YOLO_FLAGS) $(YINC) -MMD -MP -c $< -o $@
$(YMODEL): $(OUT)/yolo_obj/model.o $(YCOMMON) $(ROOT)/src/yolo_link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/yolo_link.ld $(filter %.o,$^) -lm -lgcc -o $@
$(YDIAG): $(OUT)/yolo_obj/diagnostic.o $(YCOMMON) $(ROOT)/src/yolo_link.ld
	$(CROSS)gcc $(ARCH) -nostdlib -nostartfiles -Wl,--gc-sections,-Map,$(@:.elf=.map) -T $(ROOT)/src/yolo_link.ld $(filter %.o,$^) -lm -lgcc -o $@
all: prepare $(ELF) $(IPC_COMPAT) $(YMODEL) $(YDIAG)
	python3 -B $(ROOT)/scripts/build.py record
	python3 -B $(ROOT)/scripts/build_yolo.py record
	$(CROSS)size $(ELF) $(YMODEL) $(YDIAG)
check:
	python3 -B $(ROOT)/scripts/build.py check
	python3 -B $(ROOT)/scripts/build_yolo.py check
host-check: prepare-yolo
	$(HOST_CC) $(YOLO_FLAGS) -DACTIVATION_MEMORY_HOST_TEST $(YINC) $(ROOT)/src/yolov5_asram_main.c $(ROOT)/src/activation_memory.c $(ROOT)/model/inputs.c -Wl,--gc-sections -lm -o $(OUT)/yolo_plan_check
	$(HOST_CC) $(YOLO_FLAGS) -DACTIVATION_MEMORY_HOST_TEST -DATSOFT_NATIVE_ORACLE=1 $(YINC) $(ROOT)/src/yolov5_asram_main.c $(ROOT)/src/activation_memory.c $(ROOT)/model/inputs.c -Wl,--gc-sections -lm -o $(OUT)/yolo_native_check
	$(OUT)/yolo_plan_check $(OUT)/ddr_plan.txt 0
	$(OUT)/yolo_plan_check $(OUT)/local_plan.txt 1
	$(OUT)/yolo_native_check $(OUT)/native_ddr_plan.txt 0
	$(OUT)/yolo_native_check $(OUT)/native_local_plan.txt 1
	cmp $(OUT)/ddr_plan.txt $(OUT)/local_plan.txt
	cmp $(OUT)/ddr_plan.txt $(OUT)/native_ddr_plan.txt
	cmp $(OUT)/ddr_plan.txt $(OUT)/native_local_plan.txt
	cmp $(OUT)/ddr_plan.txt.stages $(OUT)/local_plan.txt.stages
	cmp $(OUT)/ddr_plan.txt.stages $(OUT)/native_ddr_plan.txt.stages
	cmp $(OUT)/ddr_plan.txt.stages $(OUT)/native_local_plan.txt.stages
	python3 -B $(ROOT)/scripts/yolo_inventory.py
test: all host-check
	python3 -B -m unittest discover -s $(ROOT)/tests -v
preflight: check $(IPC_COMPAT)
	python3 -B $(ROOT)/scripts/program.py preflight
program-bitstream: check $(IPC_COMPAT)
	python3 -B $(ROOT)/scripts/program.py bitstream --run $(RUN)
program: check
	python3 -B $(ROOT)/scripts/program.py load --run $(RUN)
program-model program-diagnostic: check
	python3 -B $(ROOT)/scripts/program.py load --test $(patsubst program-%,%,$@) --run $(RUN)
uart:
	python3 -B $(ROOT)/scripts/program.py uart --test $(TEST) --run $(RUN) --port $(PORT)
analyze:
	python3 -B $(ROOT)/scripts/$(if $(filter asram,$(TEST)),analyze.py,analyze_yolo.py) "$(LOG)"
-include $(wildcard $(OUT)/obj/*.d)
-include $(wildcard $(OUT)/yolo_obj/*.d)
