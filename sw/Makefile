TOOLCHAIN ?= riscv64-unknown-elf-
GEMMINI_TESTS := $(CURDIR)/third_party/gemmini
PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
SOC_VARIANT ?= dual16
ifeq ($(SOC_VARIANT),dual16)
GEMMINI_ABI_ROOT := $(GEMMINI_TESTS)
GEMMINI_PARAMS := $(GEMMINI_TESTS)/include/gemmini_params_taihang_16x16_packed_gemmini0.h
MODEL_WORKERS := 2
MODEL_DIM := 16
else ifeq ($(SOC_VARIANT),single4)
GEMMINI_ABI_ROOT := $(GEMMINI_TESTS)
GEMMINI_PARAMS := $(GEMMINI_TESTS)/include/gemmini_params_taihang_single_4x4_packed.h
MODEL_WORKERS := 1
MODEL_DIM := 4
else ifeq ($(SOC_VARIANT),triple32_v3_tensor)
GEMMINI_ABI_ROOT := $(PROJECT_ROOT)/sw/third_party/gemmini_v3
MODEL_WORKERS := 3
MODEL_DIM := 32
else
$(error Unknown SOC_VARIANT $(SOC_VARIANT))
endif

HOST_CC ?= gcc
CC      := $(TOOLCHAIN)gcc
OBJCOPY := $(TOOLCHAIN)objcopy
OBJDUMP := $(TOOLCHAIN)objdump
SIZE    := $(TOOLCHAIN)size

.DEFAULT_GOAL := all

BUILD  := $(PROJECT_ROOT)/build/firmware/$(SOC_VARIANT)
TARGET := $(BUILD)/hdmi_tx_test
AI_MODEL ?= yolov5nu
BANDWIDTH_DIAGNOSTIC ?= 0
TENSOR_INGRESS_STATS ?= 0

# Validated board and AMD BSP source snapshots live in this repository.
REFERENCE_SW := $(CURDIR)/third_party/board
DEMO_BSP := $(CURDIR)/third_party/amd
VENDOR_DIRS := \
	$(DEMO_BSP)/video_common_v4_13/src \
	$(DEMO_BSP)/v_hdmi_common_v1_7/src \
	$(DEMO_BSP)/vtc_v8_4/src \
	$(DEMO_BSP)/v_hdmirx_v2_7/src \
	$(DEMO_BSP)/v_hdmirxss_v6_4/src \
	$(DEMO_BSP)/v_hdmitx_v2_6/src \
	$(DEMO_BSP)/v_hdmitxss_v6_3/src \
	$(DEMO_BSP)/vphy_v1_13/src
VENDOR_INCLUDES := $(addprefix -I,$(VENDOR_DIRS))

ARCH_FLAGS := -march=rv64gcv -mabi=lp64d -mcmodel=medany
# Project headers use paths relative to src/. AMD BSP headers additionally
# require the fixed name xparameters.h, supplied by src/board ahead of the BSP.
CFLAGS := $(ARCH_FLAGS) -std=c11 -Os -g3 -ffreestanding -fno-builtin \
	-fno-common -fdata-sections -ffunction-sections -Wall -Wextra -Werror \
	-DXV_CONFIG_LOG_DISABLE_ALL -Isrc -Isrc/board -I$(GEMMINI_ABI_ROOT) -I$(GEMMINI_TESTS) \
	-DAI_MODEL_WORKER_COUNT=$(MODEL_WORKERS)U \
	-DYOLOV5NU_DIM16_WORKER_COUNT=$(MODEL_WORKERS)U \
	-DYOLOV5NU_GEMMINI_DIM=$(MODEL_DIM) \
	-I$(CURDIR)/models/yolov5nu/runtime \
	-I$(REFERENCE_SW)/include $(VENDOR_INCLUDES)

ifeq ($(SOC_VARIANT),single4)
CFLAGS += -DSTREAM_MODEL_TIMEOUT_SECONDS=300
endif

ifeq ($(BANDWIDTH_DIAGNOSTIC),1)
CFLAGS += -DFBUS_BANDWIDTH_DIAGNOSTIC=1
endif

ifeq ($(TENSOR_INGRESS_STATS),1)
CFLAGS += -DTENSOR_INGRESS_STATS=1
endif

ifeq ($(AI_MODEL),yolov5nu)
CFLAGS += -DAI_MODEL_YOLOV5NU=1
else
$(error Only AI_MODEL=yolov5nu is supported)
endif
VENDOR_CFLAGS := $(filter-out -Werror,$(CFLAGS)) -Wno-unused-parameter \
	-Wno-sign-compare -Wno-type-limits -Wno-unused-variable \
	-Wno-incompatible-pointer-types -Wno-return-type -Wno-enum-conversion \
	-include board/xparameters.h -include string.h
ASFLAGS := $(ARCH_FLAGS) -g3
LDFLAGS := $(ARCH_FLAGS) -nostdlib -nostartfiles -static -Wl,--gc-sections \
	-Wl,-Map,$(TARGET).map -T linker_ai_video.ld -Wl,--wrap=malloc -Wl,--wrap=free
LDLIBS := -lm -lgcc

LOCAL_SOURCES := src/main.c src/platform/console.c src/platform/runtime.c src/board/board_runtime.c src/ai/runtime/ai_runtime_bridge.c src/video/hdmi_tx.c \
	src/board/xilinx_config.c src/board/board_gpio.c src/video/camera_video.c \
	src/video/video_service.c \
	src/video/camera_config.c src/platform/cache_ops.c \
	src/ai/runtime/ai_tensor_slot_pool.c src/drivers/tensor/ai_tensor_device.c \
	src/ai/runtime/resources/rt_job.c src/ai/runtime/resources/rt_tensor_manager.c \
	src/ai/runtime/resources/rt_arena_manager.c src/ai/runtime/resources/rt_head_manager.c \
	src/ai/runtime/core/rt_core.c src/ai/runtime/core/rt_pipeline.c \
	src/ai/runtime/core/rt_state.c src/ai/runtime/core/rt_stats.c \
	src/ai/runtime/scheduler/rt_frame_scheduler.c src/ai/runtime/scheduler/rt_worker_dispatch.c \
	src/ai/runtime/services/rt_tensor_service.c src/ai/runtime/services/rt_result_service.c \
	src/ai/runtime/services/rt_overlay_service.c \
	src/diagnostics/ai_postprocess_diag.c src/ai/postprocess/ai_ppu_publication.c src/ai/postprocess/ai_ppu_queue.c \
	src/ai/postprocess/ai_postprocess_scalar.c src/ai/postprocess/ai_result_manager.c src/ai/postprocess/ai_display_map.c \
	src/ai/postprocess/ai_class_names.c \
	src/ai/postprocess/ai_overlay.c src/drivers/overlay/ai_overlay_device.c

ifeq ($(AI_MODEL),yolov5nu)
LOCAL_SOURCES += src/ai/runtime/ai_batch_runtime_stream.c \
	src/ai/runtime/ai_head_slot_queue.c src/ai/backend/ai_model_backend_yolov5nu.c \
	src/ai/backend/rt_backend.c src/ai/backend/adapters/rt_backend_compat.c \
	src/diagnostics/ai_yolov5nu_selftest.c

ifeq ($(SOC_VARIANT),triple32_v3_tensor)
LOCAL_SOURCES += src/ai/backend/adapters/v17a/rt_backend_v17a.c
CFLAGS += -DAI_RT_BACKEND_PROFILE=AI_RT_BACKEND_PROFILE_V17A
else
LOCAL_SOURCES += src/ai/backend/adapters/legacy/rt_backend_legacy.c
CFLAGS += -DAI_RT_BACKEND_PROFILE=AI_RT_BACKEND_PROFILE_LEGACY
endif

ifeq ($(SOC_VARIANT),triple32_v3_tensor)
LOCAL_SOURCES := $(filter-out src/diagnostics/ai_yolov5nu_selftest.c,$(LOCAL_SOURCES))
include models/yolov5nu/triple32/v17a.mk
V17A_FLAGS += -DYOLO32_LIVE=1
CFLAGS := $(V17A_FLAGS) $(CFLAGS) -DYOLO32_LIVE=1
$(BUILD)/ai/postprocess/ai_ppu_publication.o $(BUILD)/ai/postprocess/ai_ppu_queue.o: CFLAGS += -DYOLO32_PPU_ORDERED_MMIO=1
MODEL_OBJECT := $(V17A_OBJECTS)
else
MODEL_OBJECT := $(BUILD)/yolov5nu_dim16_dual.o
endif
endif
BOARD_SOURCES := $(REFERENCE_SW)/src/axi_iic.c \
	$(REFERENCE_SW)/src/clock_chip.c
VENDOR_SOURCES := \
	$(DEMO_BSP)/video_common_v4_13/src/xvidc.c \
	$(DEMO_BSP)/video_common_v4_13/src/xvidc_timings_table.c \
	$(DEMO_BSP)/v_hdmi_common_v1_7/src/xv_hdmic.c \
	$(DEMO_BSP)/v_hdmi_common_v1_7/src/xv_hdmic_vsif.c \
	$(DEMO_BSP)/vtc_v8_4/src/xvtc.c \
	$(DEMO_BSP)/vtc_v8_4/src/xvtc_intr.c \
	$(DEMO_BSP)/vtc_v8_4/src/xvtc_sinit.c \
	$(DEMO_BSP)/v_hdmirx_v2_7/src/xv_hdmirx.c \
	$(DEMO_BSP)/v_hdmirx_v2_7/src/xv_hdmirx_intr.c \
	$(DEMO_BSP)/v_hdmirx_v2_7/src/xv_hdmirx_sinit.c \
	$(DEMO_BSP)/v_hdmirx_v2_7/src/xv_hdmirx_vsif.c \
	$(DEMO_BSP)/v_hdmirxss_v6_4/src/xv_hdmirxss.c \
	$(DEMO_BSP)/v_hdmirxss_v6_4/src/xv_hdmirxss_coreinit.c \
	$(DEMO_BSP)/v_hdmirxss_v6_4/src/xv_hdmirxss_log.c \
	$(DEMO_BSP)/v_hdmitx_v2_6/src/xv_hdmitx.c \
	$(DEMO_BSP)/v_hdmitx_v2_6/src/xv_hdmitx_intr.c \
	$(DEMO_BSP)/v_hdmitx_v2_6/src/xv_hdmitx_sinit.c \
	$(DEMO_BSP)/v_hdmitx_v2_6/src/xv_hdmitx_vsif.c \
	$(DEMO_BSP)/v_hdmitxss_v6_3/src/xv_hdmitxss.c \
	$(DEMO_BSP)/v_hdmitxss_v6_3/src/xv_hdmitxss_coreinit.c \
	$(DEMO_BSP)/v_hdmitxss_v6_3/src/xv_hdmitxss_log.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_i.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_hdmi.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_hdmi_intr.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_intr.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_log.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_gthe4.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_gtye4.c \
	$(DEMO_BSP)/vphy_v1_13/src/xvphy_mmcme4.c

LOCAL_OBJECTS := $(patsubst src/%.c,$(BUILD)/%.o,$(LOCAL_SOURCES))
BOARD_OBJECTS := $(addprefix $(BUILD)/board_,$(notdir $(BOARD_SOURCES:.c=.o)))
VENDOR_OBJECTS := $(addprefix $(BUILD)/vendor_,$(notdir $(VENDOR_SOURCES:.c=.o)))
OBJECTS := $(BUILD)/platform/startup.o $(LOCAL_OBJECTS) $(MODEL_OBJECT) $(BOARD_OBJECTS) $(VENDOR_OBJECTS)

ifeq ($(SOC_VARIANT),triple32_v3_tensor)
# Include selection and policy flags must also invalidate previously built objects.
V17A_BUILD_SIGNATURE := $(CFLAGS) $(V17A_FLAGS) $(V17A_CFLAGS) $(LDFLAGS)
.PHONY: force-v17a-config
$(BUILD)/v17a/firmware-config.stamp: force-v17a-config
	@mkdir -p $(@D)
	@python3 -c 'import sys; from pathlib import Path; p=Path(sys.argv[1]); v=sys.argv[2]+"\n"; p.write_text(v) if not p.exists() or p.read_text()!=v else None' "$@" "$(V17A_BUILD_SIGNATURE)"
$(OBJECTS): Makefile $(V17A_ROOT)/v17a.mk $(BUILD)/v17a/firmware-config.stamp
endif

.PHONY: all clean size check-tools yolov5nu-regenerate
all: check-tools $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dump size

check-tools:
	@command -v "$(CC)" >/dev/null 2>&1 || { echo "Missing compiler: $(CC)"; exit 1; }

$(BUILD):
	mkdir -p $@

$(BUILD)/platform/startup.o: src/platform/startup.S | $(BUILD)
	@mkdir -p $(@D)
	$(CC) $(ASFLAGS) -MMD -MP -c $< -o $@

# Preserve the source hierarchy for objects and dependency files.
$(BUILD)/%.o: src/%.c | $(BUILD)
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

YOLOV5_GEN_ROOT := $(CURDIR)/models/yolov5nu
YOLOV5_IMAGENET := $(YOLOV5_GEN_ROOT)/aot
YOLOV5_PARAMS := $(YOLOV5_IMAGENET)/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h

yolov5nu-regenerate:
	python3 models/yolov5nu/runtime/generate_runtime.py

$(BUILD)/yolov5nu_dim16_dual.o: models/yolov5nu/runtime/yolov5nu_dim16_dual.c \
		models/yolov5nu/runtime/yolov5nu_dim16_dual.h $(YOLOV5_PARAMS) $(GEMMINI_PARAMS) | $(BUILD)
	$(CC) $(CFLAGS) -include $(GEMMINI_PARAMS) -std=gnu11 -O2 \
		-DBAREMETAL=1 -DYOLOV5NU_PROFILE=0 \
		-DYOLOV5NU_FINAL_TENSOR_STATS=0 \
		-DGEMMINI_LOOPCONV_CREDIT_ADMISSION=1 \
		-DGEMMINI_LOOPCONV_WORKER1_STATUS_CSR=0x7c5 \
		-DGEMMINI_LOOPCONV_WORKER1_ACCEPTED_CSR=0x7c8 \
		-DGEMMINI_LOOPCONV_WORKER1_RETIRED_CSR=0x7c9 \
		-Wno-error -Wno-sign-compare -Wno-unused-parameter \
		-Wno-unused-variable -Wno-unused-function \
		-I$(YOLOV5_GEN_ROOT) -I$(YOLOV5_IMAGENET) \
		-MMD -MP -c $< -o $@

define make-board-rule
# The reference platform.h uses internal video BD addresses. Compile these
# drivers against the project's CPU-visible Taihang MMIO map instead.
$(BUILD)/board_$(notdir $(1:.c=.o)): $(1) Makefile | $(BUILD)
	$$(CC) $$(CFLAGS) -iquote $$(CURDIR)/src/platform -MMD -MP -c $$< -o $$@
endef
$(foreach source,$(BOARD_SOURCES),$(eval $(call make-board-rule,$(source))))

define make-vendor-rule
$(BUILD)/vendor_$(notdir $(1:.c=.o)): $(1) | $(BUILD)
	$$(CC) $$(VENDOR_CFLAGS) -MMD -MP -c $$< -o $$@
endef
$(foreach source,$(VENDOR_SOURCES),$(eval $(call make-vendor-rule,$(source))))

$(TARGET).elf: $(OBJECTS) linker_ai_video.ld
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@ $(LDLIBS)

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex $< $@

$(TARGET).dump: $(TARGET).elf
	$(OBJDUMP) -d -S $< > $@

size: $(TARGET).elf
	$(SIZE) -A $<

clean:
	rm -rf $(BUILD)

-include $(OBJECTS:.o=.d)
