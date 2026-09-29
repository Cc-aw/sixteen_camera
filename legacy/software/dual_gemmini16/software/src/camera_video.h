#ifndef ONE_OV5645_CAMERA_VIDEO_H
#define ONE_OV5645_CAMERA_VIDEO_H

#include <stdint.h>
#include "camera_config.h"

void camera_video_print_status(const CameraConfig *camera);
void camera_video_set_sample_tap(const CameraConfig *camera, uint32_t tap);
int camera_video_snapshot(const CameraConfig *camera);
uint32_t camera_ov7670_run_bist(const CameraConfig *camera);

#endif
