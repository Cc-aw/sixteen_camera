#ifndef ONE_OV5645_BOARD_GPIO_H
#define ONE_OV5645_BOARD_GPIO_H

#include <stdint.h>

void board_gpio_init_safe(void);
void board_gpio_write(uint32_t value);
uint32_t board_gpio_outputs(void);
uint32_t board_gpio_status(void);
void board_clock_release_reset(void);
void board_tx_enable(int enable);

#endif
