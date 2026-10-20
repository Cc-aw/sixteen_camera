#ifndef VIDEO_CTRL_CLOCK_CHIP_H
#define VIDEO_CTRL_CLOCK_CHIP_H

#include <stdint.h>

enum clock_chip_result {
    CLOCK_CHIP_OK = 0,
    CLOCK_CHIP_IIC_ERROR = -1,
    CLOCK_CHIP_BAD_ID = -2
};

int clock_chip_read_id(uint16_t *device_id);
int clock_chip_program_148p5(void);
int clock_chip_program_148p5_locked(void);
int clock_chip_select_148p5_free_running(void);

#endif
