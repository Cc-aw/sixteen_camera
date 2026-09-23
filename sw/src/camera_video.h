#ifndef ONE_OV5645_CAMERA_VIDEO_H
#define ONE_OV5645_CAMERA_VIDEO_H

#include <stdint.h>
#include "camera_config.h"

void camera_video_print_status(const CameraConfig *camera);
int camera_video_snapshot(const CameraConfig *camera);

#endif
