HERE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PROJECT_ROOT := $(abspath $(HERE)/../../..)
-include $(PROJECT_ROOT)/tools/config/tools.local.mk
TOOLCHAIN ?= riscv64-unknown-elf-
HOST_CC ?= gcc
CC := $(TOOLCHAIN)gcc
ARCH_FLAGS := -march=rv64gcv -mabi=lp64d -mcmodel=medany
BUILD ?= $(PROJECT_ROOT)/build/firmware/benchmark
.DEFAULT_GOAL := all
include $(PROJECT_ROOT)/sw/models/yolov5nu/model.mk
OBJECTS := $(V26_OBJECTS) $(addprefix $(BUILD)/,startup.o console.o support.o compare.o inputs.o ppu.o main.o ai_ppu_publication.o ai_ppu_queue.o ai_head_slot_queue.o)
$(OBJECTS): $(HERE)/Makefile $(PROJECT_ROOT)/sw/models/yolov5nu/model.mk $(BUILD)/v26/native-config.stamp
.PHONY: all check clean
all: $(BUILD)/benchmark.elf $(BUILD)/benchmark.bin
$(BUILD)/startup.o: $(PROJECT_ROOT)/sw/src/platform/startup.S
	@mkdir -p $(@D)
	$(CC) $(ARCH_FLAGS) -c $< -o $@
$(BUILD)/console.o: $(PROJECT_ROOT)/sw/src/platform/console.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -MMD -MP -c $< -o $@
$(BUILD)/inputs.stamp: $(HERE)/generate_inputs.py $(wildcard $(PROJECT_ROOT)/tests/data/yolov5nu/v17a/*.bin)
	@mkdir -p $(@D)
	python3 -B $< $(@D)
	touch $@
$(BUILD)/inputs.o: $(BUILD)/inputs.stamp
	$(CC) $(V26_FLAGS) -I$(BUILD) $(V26_CFLAGS) -MMD -MP -c $(BUILD)/inputs.c -o $@
$(BUILD)/main.o: $(BUILD)/inputs.stamp
$(BUILD)/%.o: $(HERE)/%.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) -I$(BUILD) $(V26_CFLAGS) -MMD -MP -c $< -o $@
$(BUILD)/ai_ppu_publication.o: $(PROJECT_ROOT)/sw/src/ai/postprocess/ai_ppu_publication.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -DYOLO32_PPU_ORDERED_MMIO=1 -MMD -MP -c $< -o $@
$(BUILD)/ai_ppu_queue.o: $(PROJECT_ROOT)/sw/src/ai/postprocess/ai_ppu_queue.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -DYOLO32_PPU_ORDERED_MMIO=1 -MMD -MP -c $< -o $@
$(BUILD)/ai_head_slot_queue.o: $(PROJECT_ROOT)/sw/src/ai/runtime/ai_head_slot_queue.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -MMD -MP -c $< -o $@
$(BUILD)/benchmark.elf: $(OBJECTS) $(HERE)/linker.ld
	$(CC) $(ARCH_FLAGS) -nostdlib -nostartfiles -static -Wl,--gc-sections \
		-Wl,-Map,$(BUILD)/benchmark.map -T $(HERE)/linker.ld $(OBJECTS) -lm -lgcc -o $@
	$(TOOLCHAIN)size $@
$(BUILD)/benchmark.bin: $(BUILD)/benchmark.elf
	$(TOOLCHAIN)objcopy -O binary $< $@
check:
	RISCV_TOOLCHAIN_DIR="$(dir $(TOOLCHAIN))" python3 -B -m unittest discover -s $(PROJECT_ROOT)/tests/model/yolov5nu -p 'test_*.py' -v
clean:
	rm -rf $(BUILD)
-include $(OBJECTS:.o=.d)

.PHONY: credit-cap3 credit-cap4 credit-cap3-diag credit-cap4-diag
credit-cap3 credit-cap4 credit-cap3-diag credit-cap4-diag:
	$(MAKE) BUILD=$(PROJECT_ROOT)/build/firmware/triple32_v26_$(subst -,_,$@) V26_CREDIT_LIMIT=$(if $(findstring cap4,$@),4,3) V26_DIAGNOSTIC=$(if $(findstring diag,$@),1,0) all
all: $(BUILD)/capacity_manifest.json
$(BUILD)/capacity_manifest.json: $(BUILD)/benchmark.elf $(BUILD)/v26/parallel.stamp $(BUILD)/inputs.stamp $(HERE)/capacity_manifest.py
	cp $(BUILD)/v26/fixed_plans.json $(BUILD)/v26/memory_kernels.json $(BUILD)/
	python3 -B $(HERE)/capacity_manifest.py $(BUILD) --limit $(V26_CREDIT_LIMIT) --diagnostic $(V26_DIAGNOSTIC) --params $(V26_PARAMS) --compiler $(CC)
