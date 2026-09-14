#include "board_gpio.h"
#include "mmio.h"
#include "platform.h"

#define GPIO_DATA  0x00U
#define GPIO_DATA2 0x08U
#define GPIO_OUTPUT_MASK (GPIO_OUT_TX_ENABLE | GPIO_OUT_CLK_RESET_N)

static uint32_t output_shadow;

void board_gpio_write(uint32_t value)
{
    output_shadow = value & GPIO_OUTPUT_MASK;
    mmio_write32(AXI_GPIO_BASE + GPIO_DATA, output_shadow);
    mmio_fence();
}

void board_gpio_init_safe(void)
{
    /* Match the validated ai project: reset_n=0 and pwdn=0 at startup. */
    board_gpio_write(0U);
}

uint32_t board_gpio_outputs(void)
{
    return output_shadow;
}

uint32_t board_gpio_status(void)
{
    return mmio_read32(AXI_GPIO_BASE + GPIO_DATA2) & 0x1FU;
}

void board_clock_release_reset(void)
{
    board_gpio_write(output_shadow | GPIO_OUT_CLK_RESET_N);
}

void board_tx_enable(int enable)
{
    board_gpio_write(enable != 0 ? output_shadow | GPIO_OUT_TX_ENABLE
                                 : output_shadow & ~GPIO_OUT_TX_ENABLE);
}
