CHIPYARD ?= /home/wzr/chipyard
TOOLCHAIN ?= $(CHIPYARD)/.conda-env/riscv-tools/bin/riscv64-unknown-elf-
GEMMINI_TESTS := $(CHIPYARD)/generators/gemmini/software/gemmini-rocc-tests
GEMMINI_PARAMS := $(GEMMINI_TESTS)/include/gemmini_params_taihang_16x16_packed_gemmini0.h

CC      := $(TOOLCHAIN)gcc
OBJCOPY := $(TOOLCHAIN)objcopy
OBJDUMP := $(TOOLCHAIN)objdump
SIZE    := $(TOOLCHAIN)size

.DEFAULT_GOAL := all

BUILD  := build
TARGET := $(BUILD)/hdmi_tx_test
AI_MODEL ?= yolov5nu

# Reuse the board/IIC/clock code and the AMD 2023.2 BSP already validated by
# the working 4k60 project. This project supplies its own TX-only config table.
REFERENCE_SW := ../../../4k/4k60to1k60/sw
DEMO_BSP := ../../../4k/4k60to1k60/demo/11.FH1159/2_software/XCZU15EG/ZYNQMPSOC_15EG_HDMI_4K_LOOP/Vitis/exdes_wrapper/psu_cortexa53_0/standalone_psu_cortexa53_0/bsp/psu_cortexa53_0/libsrc
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
CFLAGS := $(ARCH_FLAGS) -std=c11 -Os -g3 -ffreestanding -fno-builtin \
	-fno-common -fdata-sections -ffunction-sections -Wall -Wextra -Werror \
	-DXV_CONFIG_LOG_DISABLE_ALL -Isrc -I$(GEMMINI_TESTS) \
	-I$(CURDIR)/yolov2 \
	-I$(CURDIR)/yolov5/dim16_dual \
	-I$(REFERENCE_SW)/include $(VENDOR_INCLUDES)

ifeq ($(AI_MODEL),yolov5nu)
CFLAGS += -DAI_MODEL_YOLOV5NU=1
else ifneq ($(AI_MODEL),yolov2)
$(error AI_MODEL must be yolov5nu or yolov2)
endif
VENDOR_CFLAGS := $(filter-out -Werror,$(CFLAGS)) -Wno-unused-parameter \
	-Wno-sign-compare -Wno-type-limits -Wno-unused-variable \
	-Wno-incompatible-pointer-types -Wno-return-type -Wno-enum-conversion \
	-include xparameters.h -include string.h
ASFLAGS := $(ARCH_FLAGS) -g3
LDFLAGS := $(ARCH_FLAGS) -nostdlib -nostartfiles -static -Wl,--gc-sections \
	-Wl,-Map,$(TARGET).map -T linker_ai_video.ld -Wl,--wrap=malloc -Wl,--wrap=free
LDLIBS := -lm -lgcc

LOCAL_SOURCES := src/main.c src/console.c src/runtime.c src/board_runtime.c src/ai_runtime_bridge.c src/hdmi_tx.c \
	src/xilinx_config.c src/board_gpio.c src/camera_video.c \
	src/video_service.c \
	src/camera_config.c src/ai_frame_snapshot.c \
	src/ai_tensor_slot_pool.c \
	src/ai_postprocess_scalar.c src/ai_result_manager.c src/ai_display_map.c \
	src/ai_class_names.c \
	src/ai_postprocess_diag.c \
	src/ai_overlay.c

ifeq ($(AI_MODEL),yolov5nu)
LOCAL_SOURCES += src/ai_batch_runtime_stream.c \
	src/ai_model_backend_yolov5nu.c src/ai_yolov5nu_selftest.c
MODEL_OBJECT := $(BUILD)/yolov5nu_dim16_dual.o
else
LOCAL_SOURCES += src/ai_preprocess.c src/ai_batch_runtime.c \
	src/ai_model_backend_yolov2.c \
	src/ai_inference_runtime.c src/ai_tinyyolov2_runtime_adapter.c
MODEL_OBJECT := $(BUILD)/tinyyolov2.o
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
OBJECTS := $(BUILD)/startup.o $(LOCAL_OBJECTS) $(MODEL_OBJECT) $(BOARD_OBJECTS) $(VENDOR_OBJECTS)

.PHONY: all clean size check-tools yolov5nu-regenerate
all: check-tools $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dump size

check-tools:
	@test -x "$(CC)" || { echo "Missing compiler: $(CC)"; exit 1; }

$(BUILD):
	mkdir -p $@

$(BUILD)/startup.o: src/startup.S | $(BUILD)
	$(CC) $(ASFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/tinyyolov2.o: yolov2/tinyyolov2.c yolov2/tinyyolov2_params.h \
		yolov2/tinyyolov2_runtime.h yolov2/tinyyolov2_worker_pool.h \
		yolov2/tinyyolov2_input_contract.h | $(BUILD)
	$(CC) $(CFLAGS) -include $(GEMMINI_PARAMS) \
		-std=gnu11 -O2 -DBAREMETAL=1 \
		-DTINYYOLOV2_NO_STANDALONE_MAIN=1 -DTINYYOLOV2_GEMMINI_POOL=1 \
		-DGEMMINI_POOL_NO_INTERNAL_FENCE=1 \
		-DGEMMINI_LOOPCONV_CREDIT_ADMISSION=1 \
		-DGEMMINI_LOOPCONV_WORKER1_STATUS_CSR=0x7c5 \
		-DGEMMINI_LOOPCONV_WORKER1_ACCEPTED_CSR=0x7c8 \
		-DGEMMINI_LOOPCONV_WORKER1_RETIRED_CSR=0x7c9 \
		-Wno-error -Wno-sign-compare -Wno-unused-parameter \
		-Wno-unused-variable -I$(CURDIR)/yolov2 -MMD -MP -c $< -o $@

YOLOV5_GEN_ROOT := $(CURDIR)/yolov5/generators/gemmini/software/gemmini-rocc-tests
YOLOV5_IMAGENET := $(YOLOV5_GEN_ROOT)/imagenet
YOLOV5_PARAMS := $(YOLOV5_IMAGENET)/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h

yolov5nu-regenerate:
	python3 yolov5/dim16_dual/generate_runtime.py

$(BUILD)/yolov5nu_dim16_dual.o: yolov5/dim16_dual/yolov5nu_dim16_dual.c \
		yolov5/dim16_dual/yolov5nu_dim16_dual.h $(YOLOV5_PARAMS) | $(BUILD)
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
$(BUILD)/board_$(notdir $(1:.c=.o)): $(1) | $(BUILD)
	$$(CC) $$(CFLAGS) -MMD -MP -c $$< -o $$@
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
