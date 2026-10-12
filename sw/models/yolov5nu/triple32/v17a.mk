# Shared native V17 A model and scheduler for benchmark and video firmware.
V17A_ROOT := $(PROJECT_ROOT)/sw/models/yolov5nu/triple32
V17A_ABI := $(PROJECT_ROOT)/sw/third_party/gemmini_v3
V17A_CONFIG := tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig
V17A_PARAMS := $(PROJECT_ROOT)/hw/soc/$(V17A_CONFIG)/gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h
V17A_FLAGS := -I$(BUILD)/v17a -I$(V17A_ROOT) -I$(V17A_ROOT)/native \
	-I$(PROJECT_ROOT)/sw/src -I$(V17A_ABI) -I$(V17A_ABI)/include \
	-I$(PROJECT_ROOT)/sw/models/yolov5nu/aot \
	-DYOLOV5NU_GEMMINI_DIM=32 -DYOLOV5NU_DIM16_WORKER_COUNT=3U \
	-DYOLOV5NU_PROFILE=0 -DYOLOV5NU_FINAL_TENSOR_STATS=0 -DBAREMETAL=1 \
	-DYOLO32_TIMEOUT_SECONDS=600 -DYOLO32_SUBMIT_BURST=1 -DYOLO32_QUANTUM_US=200 \
	-DYOLO32_CONTEXT_FULL=0 -DYOLO32_SCHED_ADAPTIVE=0 -DYOLO32_BLOCK_US=20 \
	-DYOLO32_HOT_PATHS=1 -DYOLO32_ROCC_LAYERS=0 -DYOLO32_FIXED_PLANS=1 \
	-DYOLO32_FIXED_PACKETS=1 -DYOLO32_IDLE_PRIORITY=1 -DYOLO32_TAIL_WAIT=1 \
	-DYOLO32_PREPARED_PACKETS=1 -DYOLO32_PPU_EARLY=1 \
	-DYOLO32_PPU_HEAD_CLEAN=1 -DYOLO32_PPU_HEAD_ADMIT=0
V17A_CFLAGS := $(ARCH_FLAGS) -std=gnu11 -O2 -g3 -fstack-usage -ffreestanding \
	-fno-builtin -ffunction-sections -fdata-sections -Wall -Wextra -Werror
V17A_OBJECTS := $(BUILD)/v17a/model.o $(BUILD)/v17a/independent.o $(BUILD)/v17a/task_switch.o

$(BUILD)/v17a/parallel.stamp: $(wildcard $(V17A_ROOT)/*.py $(V17A_ROOT)/*.inc) \
	$(V17A_ROOT)/native/yolov5nu_dim16_dual.c $(V17A_PARAMS) \
	$(wildcard $(V17A_ABI)/include/*.h) \
	$(PROJECT_ROOT)/sw/models/yolov5nu/aot/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h
	@mkdir -p $(@D)
	python3 -B $(V17A_ROOT)/generate_parallel.py $(@D) --fixed-plans \
		--params $(V17A_PARAMS) --host-cc "$(HOST_CC)" --fixed-packets --prepared-packets
	touch $@

$(BUILD)/v17a/model.o: $(V17A_ROOT)/model.c $(BUILD)/v17a/parallel.stamp
	$(CC) $(V17A_FLAGS) $(V17A_CFLAGS) -include $(V17A_PARAMS) \
		-Wno-error -Wno-unused-function -Wno-unused-variable -Wno-unused-parameter \
		-Wno-sign-compare -MMD -MP -c $< -o $@

$(BUILD)/v17a/independent.o: $(V17A_ROOT)/independent.c
	@mkdir -p $(@D)
	$(CC) $(V17A_FLAGS) $(V17A_CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/v17a/task_switch.o: $(V17A_ROOT)/task_switch.S $(V17A_ROOT)/task_context_config.h
	@mkdir -p $(@D)
	$(CC) $(ARCH_FLAGS) -DYOLO32_CONTEXT_FULL=0 -MMD -MP -c $< -o $@
