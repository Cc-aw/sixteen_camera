#ifndef ONE_OV5645_CAMERA_CONFIG_H
#define ONE_OV5645_CAMERA_CONFIG_H

#include <stddef.h>
#include <stdint.h>

typedef enum {
    CAMERA_SENSOR_OV7670 = 0
} CameraSensorType;

typedef struct {
    uint8_t global_channel;
    uint8_t present;
    CameraSensorType sensor_type;
    uintptr_t csi_base;
} CameraConfig;

extern const CameraConfig camera_configs[];
extern const size_t camera_config_count;

const CameraConfig *camera_config_by_channel(uint8_t global_channel);

#endif
