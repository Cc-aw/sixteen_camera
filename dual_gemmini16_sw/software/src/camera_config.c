#include "camera_config.h"

#include "platform.h"

#define CAMERA_CONFIG(channel_id, block_base, is_present, sensor) { \
    .global_channel = (channel_id), \
    .present = (is_present), \
    .sensor_type = (sensor), \
    .csi_base = (block_base) + CAMERA_CSI_OFFSET \
}

const CameraConfig camera_configs[] = {
    CAMERA_CONFIG(1U, CAMERA_CH1_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670),
    CAMERA_CONFIG(2U, CAMERA_CH2_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670),
    CAMERA_CONFIG(3U, CAMERA_CH3_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670),
    CAMERA_CONFIG(4U, CAMERA_CH4_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670),
    CAMERA_CONFIG(5U, CAMERA_CH5_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670),
    CAMERA_CONFIG(6U, CAMERA_CH6_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670),
    CAMERA_CONFIG(7U, CAMERA_CH7_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670),
    CAMERA_CONFIG(8U, CAMERA_CH8_BLOCK_BASE, 1U, CAMERA_SENSOR_OV7670)
};

const size_t camera_config_count =
    sizeof(camera_configs) / sizeof(camera_configs[0]);

const CameraConfig *camera_config_by_channel(uint8_t global_channel)
{
    for (size_t index = 0U; index < camera_config_count; ++index) {
        if (camera_configs[index].global_channel == global_channel)
            return &camera_configs[index];
    }
    return 0;
}
