CHIPYARD ?= /home/wzr/chipyard
TOOLCHAIN ?= $(CHIPYARD)/.conda-env/riscv-tools/bin/riscv64-unknown-elf-

CC      := $(TOOLCHAIN)gcc
OBJCOPY := $(TOOLCHAIN)objcopy
OBJDUMP := $(TOOLCHAIN)objdump
SIZE    := $(TOOLCHAIN)size

.DEFAULT_GOAL := all

BUILD  := build
TARGET := $(BUILD)/hdmi_tx_test

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
	-DXV_CONFIG_LOG_DISABLE_ALL -Isrc -I$(CURDIR)/yolov2 \
	-I$(REFERENCE_SW)/include $(VENDOR_INCLUDES)
VENDOR_CFLAGS := $(filter-out -Werror,$(CFLAGS)) -Wno-unused-parameter \
	-Wno-sign-compare -Wno-type-limits -Wno-unused-variable \
	-Wno-incompatible-pointer-types -Wno-return-type -Wno-enum-conversion \
	-include xparameters.h -include string.h
ASFLAGS := $(ARCH_FLAGS) -g3
LDFLAGS := $(ARCH_FLAGS) -nostdlib -nostartfiles -static -Wl,--gc-sections \
	-Wl,-Map,$(TARGET).map -T linker_ai_video.ld -Wl,--wrap=malloc -Wl,--wrap=free
LDLIBS := -lm -lgcc

GEMCC_ROOT := $(CURDIR)/gemcc_runtime
GEMCC_ARTIFACTS := ../artifacts/yolov5nu-dim16-packed-board
GEMMINI_ROOT := $(GEMCC_ROOT)/gemmini/lib
GEMCC_ADAPTER := $(GEMCC_ROOT)/adapter
GEMMINI_PLATFORM := $(GEMCC_ROOT)/gemmini/platform
GEMCC_CFLAGS := -DGEMCC_HAS_MODEL_ABI \
	-DGEMCC_DEVICE_HARDWARE_PROFILE_ID=\"xcvu13p-dim16-packed-quicktest\" \
	-I$(GEMCC_ROOT)/engine -I$(GEMCC_ARTIFACTS) \
	-I$(GEMCC_ROOT) -I$(GEMMINI_ROOT) -I$(GEMCC_ADAPTER) \
	-I$(GEMMINI_PLATFORM)
GEMMINI_CFLAGS := $(ARCH_FLAGS) -O2 -std=gnu99 -ffreestanding -fno-builtin \
	-fno-common -Wno-unused-function -Wno-unused-parameter \
	-DGEMCC_HAS_MODEL_ABI -DBAREMETAL=1 \
	-I$(GEMMINI_ROOT) -I$(GEMCC_ROOT) -I$(GEMCC_ROOT)/engine -I$(GEMCC_ADAPTER) \
	-I$(GEMMINI_PLATFORM)

GEMCC_ADAPTER_CFLAGS := $(GEMMINI_CFLAGS) $(GEMCC_CFLAGS)

LOCAL_SOURCES := src/main.c src/console.c src/runtime.c src/board_runtime.c src/ai_runtime_bridge.c src/hdmi_tx.c \
	src/xilinx_config.c src/board_gpio.c src/camera_video.c \
	src/video_service.c \
	src/camera_config.c src/ai_frame_snapshot.c src/ai_preprocess.c \
	src/ai_batch_runtime.c src/ai_model_backend_yolov2.c \
	src/ai_postprocess_scalar.c src/ai_result_manager.c src/ai_display_map.c \
	src/ai_overlay.c
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
YOLOV2_OBJECT := $(BUILD)/tinyyolov2.o
BOARD_OBJECTS := $(addprefix $(BUILD)/board_,$(notdir $(BOARD_SOURCES:.c=.o)))
VENDOR_OBJECTS := $(addprefix $(BUILD)/vendor_,$(notdir $(VENDOR_SOURCES:.c=.o)))
OBJECTS := $(BUILD)/startup.o $(LOCAL_OBJECTS) $(YOLOV2_OBJECT) $(BOARD_OBJECTS) $(VENDOR_OBJECTS)

GEMCC_OBJECTS := \
	$(BUILD)/gemcc_workspace_malloc.o \
	$(BUILD)/gemcc_library_device.o \
	$(BUILD)/gemcc_ownership.o \
	$(BUILD)/myboard_cache.o \
	$(GEMCC_ARTIFACTS)/forward_medany.o \
	$(GEMCC_ARTIFACTS)/forward_trampoline_bm.o \
	$(GEMCC_ARTIFACTS)/forward_constants_bm.o \
	$(GEMCC_ARTIFACTS)/gemcc_model_bm.o \
	$(GEMCC_ARTIFACTS)/gemcc_device_bm.o \
	$(GEMCC_ARTIFACTS)/memref_copy_bm.o \
	$(BUILD)/gemmini_wrappers_fwd.o \
	$(GEMCC_ARTIFACTS)/gemcc_kernel_ops_fwd_bm.o \
	$(GEMCC_ARTIFACTS)/buddy_same_upper_maxpool_fwd_bm.o \
	$(GEMCC_ARTIFACTS)/buddy_rvv_mem_fwd_bm.o \
	$(GEMCC_ARTIFACTS)/buddy_int8_leaky_fwd_bm.o \
	$(GEMCC_ARTIFACTS)/buddy_int8_silu_fwd_bm.o \
	$(GEMCC_ARTIFACTS)/buddy_int8_sigmoid_fwd_bm.o

$(BUILD)/gemcc_workspace_malloc.o: $(GEMCC_ROOT)/engine/workspace_malloc.c | $(BUILD)
	$(CC) $(CFLAGS) $(GEMCC_CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/gemcc_library_device.o: $(GEMCC_ADAPTER)/gemcc_library_device.c | $(BUILD)
	$(CC) $(GEMCC_ADAPTER_CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/gemcc_ownership.o: $(GEMCC_ADAPTER)/gemcc_ownership.c \
		$(GEMCC_ADAPTER)/gemcc_ownership.h | $(BUILD)
	$(CC) $(GEMCC_ADAPTER_CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/myboard_cache.o: $(GEMMINI_PLATFORM)/myboard_cache.c \
		$(GEMMINI_PLATFORM)/myboard_cache.h \
		$(GEMMINI_ROOT)/gemmini_params.h | $(BUILD)
	$(CC) $(GEMCC_ADAPTER_CFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/gemmini_wrappers_fwd.o: $(GEMMINI_ROOT)/gemmini_wrappers.c \
		$(GEMMINI_ROOT)/gemmini.h $(GEMMINI_ROOT)/gemmini_params.h \
		$(GEMMINI_ROOT)/gemmini_counter.h $(GEMMINI_ROOT)/xcustom.h \
		$(GEMCC_ROOT)/engine/gemcc_trace.h | $(BUILD)
	$(CC) $(GEMMINI_CFLAGS) -MMD -MP -c $< -o $@

.PHONY: all clean size check-tools
all: check-tools $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dump size

check-tools:
	@test -x "$(CC)" || { echo "Missing compiler: $(CC)"; exit 1; }

$(BUILD):
	mkdir -p $@

$(BUILD)/startup.o: src/startup.S | $(BUILD)
	$(CC) $(ASFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) $(GEMCC_CFLAGS) -MMD -MP -c $< -o $@

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

$(YOLOV2_OBJECT): yolov2/tinyyolov2.c yolov2/tinyyolov2_params.h \
		yolov2/tinyyolov2_runtime.h yolov2/tinyyolov2_worker_pool.h \
		yolov2/tinyyolov2_input_contract.h | $(BUILD)
	$(CC) $(CFLAGS) -std=gnu11 -O2 -DBAREMETAL=1 -DTINYYOLOV2_NO_STANDALONE_MAIN=1 \
		-DTINYYOLOV2_GEMMINI_POOL=0 -DGEMCC_CHANNEL_TILE_DIM=DIM \
		-Wno-error -Wno-sign-compare \
		-Wno-unused-parameter -Wno-unused-variable -I$(CURDIR)/yolov2 \
		-MMD -MP -c $< -o $@

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

-include $(OBJECTS:.o=.d) $(GEMCC_OBJECTS:.o=.d)
