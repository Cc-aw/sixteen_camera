#ifndef YOLO32_INPUTS_H
#define YOLO32_INPUTS_H
#include <stdint.h>
#define YOLO32_INPUT_BYTES (640U * 480U * 3U)
extern const int8_t yolo32_inputs[3][YOLO32_INPUT_BYTES];
extern const char *const yolo32_image_ids[3];
#endif
