CHIPYARD ?= /home/wzr/chipyard
TOOLCHAIN ?= $(CHIPYARD)/.conda-env/riscv-tools/bin/riscv64-unknown-elf-

CC      := $(TOOLCHAIN)gcc
OBJCOPY := $(TOOLCHAIN)objcopy
OBJDUMP := $(TOOLCHAIN)objdump
SIZE    := $(TOOLCHAIN)size

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

ARCH_FLAGS := -march=rv64imac_zicsr_zifencei -mabi=lp64 -mcmodel=medany
CFLAGS := $(ARCH_FLAGS) -std=c11 -Os -g3 -ffreestanding -fno-builtin \
	-fno-common -fdata-sections -ffunction-sections -Wall -Wextra -Werror \
	-DXV_CONFIG_LOG_DISABLE_ALL -Isrc -I$(REFERENCE_SW)/include $(VENDOR_INCLUDES)
VENDOR_CFLAGS := $(filter-out -Werror,$(CFLAGS)) -Wno-unused-parameter \
	-Wno-sign-compare -Wno-type-limits -Wno-unused-variable \
	-Wno-incompatible-pointer-types -Wno-return-type -Wno-enum-conversion \
	-include xparameters.h -include string.h
ASFLAGS := $(ARCH_FLAGS) -g3
LDFLAGS := $(ARCH_FLAGS) -nostdlib -nostartfiles -static -Wl,--gc-sections \
	-Wl,-Map,$(TARGET).map -T linker.ld

LOCAL_SOURCES := src/main.c src/console.c src/runtime.c src/hdmi_tx.c \
	src/xilinx_config.c src/board_gpio.c src/camera_video.c \
	src/camera_config.c src/ai_frame_snapshot.c src/ai_preprocess.c \
	src/ai_batch_runtime.c src/ai_model_backend_stub.c \
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
BOARD_OBJECTS := $(addprefix $(BUILD)/board_,$(notdir $(BOARD_SOURCES:.c=.o)))
VENDOR_OBJECTS := $(addprefix $(BUILD)/vendor_,$(notdir $(VENDOR_SOURCES:.c=.o)))
OBJECTS := $(BUILD)/startup.o $(LOCAL_OBJECTS) $(BOARD_OBJECTS) $(VENDOR_OBJECTS)

.PHONY: all clean size check-tools
all: check-tools $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).dump size

check-tools:
	@test -x "$(CC)" || { echo "Missing compiler: $(CC)"; exit 1; }

$(BUILD):
	mkdir -p $@

$(BUILD)/startup.o: src/startup.S | $(BUILD)
	$(CC) $(ASFLAGS) -MMD -MP -c $< -o $@

$(BUILD)/%.o: src/%.c | $(BUILD)
	$(CC) $(CFLAGS) -MMD -MP -c $< -o $@

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

$(TARGET).elf: $(OBJECTS) linker.ld
	$(CC) $(OBJECTS) $(LDFLAGS) -o $@

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
