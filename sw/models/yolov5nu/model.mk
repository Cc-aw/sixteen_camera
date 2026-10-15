# Shared native v26 model and scheduler for benchmark and video firmware.
V26_ROOT := $(PROJECT_ROOT)/sw/models/yolov5nu
V26_ABI := $(PROJECT_ROOT)/sw/third_party/gemmini
V26_CONFIG := tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig
V26_PARAMS := $(PROJECT_ROOT)/hw/soc/$(V26_CONFIG)/gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h
V26_CREDIT_LIMIT ?= 4
V26_DIAGNOSTIC ?= 0
ifneq ($(filter $(V26_CREDIT_LIMIT),3 4),$(V26_CREDIT_LIMIT))
$(error v26 credit limit must be 3 or 4)
endif
ifneq ($(filter $(V26_DIAGNOSTIC),0 1),$(V26_DIAGNOSTIC))
$(error v26 diagnostic build must be 0 or 1)
endif
V26_FLAGS := -I$(BUILD)/v26 -I$(V26_ROOT)/include -I$(V26_ROOT)/src -I$(V26_ROOT)/codegen -I$(V26_ROOT)/frozen/native \
	-I$(PROJECT_ROOT)/sw/src -I$(V26_ABI) -I$(V26_ABI)/include \
	-I$(PROJECT_ROOT)/sw/models/yolov5nu/assets \
	-DYOLOV5NU_GEMMINI_DIM=32 -DYOLOV5NU_DIM16_WORKER_COUNT=3U \
	-DYOLOV5NU_PROFILE=0 -DYOLOV5NU_FINAL_TENSOR_STATS=0 -DBAREMETAL=1 \
	-DYOLO32_TIMEOUT_SECONDS=600 -DYOLO32_SUBMIT_BURST=1 -DYOLO32_QUANTUM_US=200 \
	-DYOLO32_CONTEXT_FULL=0 -DYOLO32_SCHED_ADAPTIVE=0 -DYOLO32_BLOCK_US=20 \
	-DYOLO32_HOT_PATHS=1 -DYOLO32_ROCC_LAYERS=0 -DYOLO32_FIXED_PLANS=1 \
	-DYOLO32_FIXED_PACKETS=1 -DYOLO32_IDLE_PRIORITY=1 -DYOLO32_TAIL_WAIT=1 \
	-DYOLO32_PREPARED_PACKETS=1 -DYOLO32_PPU_EARLY=1 \
	-DYOLO32_PPU_HEAD_CLEAN=1 -DYOLO32_PPU_HEAD_ADMIT=0 \
	-DYOLO32_WAIT_REUSE=1 -DYOLO32_CREDIT_LIMIT=$(V26_CREDIT_LIMIT) \
	-DYOLO32_SUPPLY_DIAG=0 -DYOLO32_MEMORY_OPS=1 -DYOLO32_RESIZE_BATCH=1 -DYOLO32_RESIZE_ROWS=0 \
	-DYOLO32_CREDIT_QUERY=1 -DYOLO32_PACKET_DISPATCH=1 -DYOLO32_SPLIT_DIAG=1 \
	-DYOLO32_DIAGNOSTIC_BUILD=$(V26_DIAGNOSTIC) -DYOLO32_CAPACITY_DIAG=$(V26_DIAGNOSTIC) \
	-DYOLO32_CAPACITY_EXPERIMENT=1 -DYOLO32_SOFTWARE_BATCH=0 -DAI_MODEL_WORKER_COUNT=3U
V26_CFLAGS := $(ARCH_FLAGS) -std=gnu11 -O2 -g3 -fstack-usage -ffreestanding \
	-fno-builtin -ffunction-sections -fdata-sections -Wall -Wextra -Werror
V26_OBJECTS := $(BUILD)/v26/model.o $(BUILD)/v26/independent.o $(BUILD)/v26/task_switch.o $(BUILD)/v26/diagnostics.o $(BUILD)/v26/capacity_observer.o

.PHONY: force-v26-native-config
$(BUILD)/v26/native-config.stamp: force-v26-native-config
	@mkdir -p $(@D)
	@python3 -c 'import sys; from pathlib import Path; p=Path(sys.argv[1]); v=sys.argv[2]+"\n"; p.write_text(v) if not p.exists() or p.read_text()!=v else None' "$@" "$(V26_FLAGS) $(V26_CFLAGS)"
$(V26_OBJECTS): $(BUILD)/v26/native-config.stamp $(V26_ROOT)/model.mk

$(BUILD)/v26/parallel.stamp: $(BUILD)/v26/native-config.stamp $(wildcard $(V26_ROOT)/codegen/*.py $(V26_ROOT)/codegen/*.inc) \
	$(V26_ROOT)/frozen/native/yolov5nu_dim16_dual.c $(V26_PARAMS) \
	$(wildcard $(V26_ABI)/include/*.h) \
	$(PROJECT_ROOT)/sw/models/yolov5nu/assets/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h
	@mkdir -p $(@D)
	python3 -B $(V26_ROOT)/codegen/generate_parallel.py $(@D) --fixed-plans \
		--params $(V26_PARAMS) --host-cc "$(HOST_CC)" --fixed-packets --prepared-packets \
		--wait-reuse --memory-ops --resize-batch --resize-rows 0
	touch $@

$(BUILD)/v26/model.o: $(V26_ROOT)/src/model.c $(BUILD)/v26/parallel.stamp
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -include $(V26_PARAMS) \
		-Wno-error -Wno-unused-function -Wno-unused-variable -Wno-unused-parameter \
		-Wno-sign-compare -MMD -MP -c $< -o $@

$(BUILD)/v26/independent.o: $(V26_ROOT)/src/independent.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/v26/task_switch.o: $(V26_ROOT)/src/task_switch.S $(V26_ROOT)/src/task_context_config.h
	@mkdir -p $(@D)
	$(CC) $(ARCH_FLAGS) -DYOLO32_CONTEXT_FULL=0 -DYOLO32_DIAGNOSTIC_BUILD=$(V26_DIAGNOSTIC) -MMD -MP -c $< -o $@

$(BUILD)/v26/diagnostics.o: $(V26_ROOT)/src/diagnostics.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/v26/capacity_observer.o: $(V26_ROOT)/src/capacity_observer.c
	@mkdir -p $(@D)
	$(CC) $(V26_FLAGS) $(V26_CFLAGS) -MMD -MP -c $< -o $@

# Expose evaluated build settings for the production pairing audit; no compilation.
.PHONY: print-current-config
print-current-config:
	@printf '%s\n' 'WORKERS=$(if $(MODEL_WORKERS),$(MODEL_WORKERS),3)' 'DIM=$(if $(MODEL_DIM),$(MODEL_DIM),32)' \
	  'CREDIT=$(V26_CREDIT_LIMIT)' 'DIAGNOSTIC=$(V26_DIAGNOSTIC)' 'PARAMS=$(V26_PARAMS)' 'FLAGS=$(V26_FLAGS)' \
	  'MODEL=$(V26_ROOT)/src/model.c' 'GENERATOR=$(V26_ROOT)/codegen/generate_parallel.py' \
	  'FROZEN=$(V26_ROOT)/frozen/native/yolov5nu_dim16_dual.c'
