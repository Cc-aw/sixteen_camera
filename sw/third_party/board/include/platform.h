#ifndef VIDEO_CTRL_PLATFORM_H
#define VIDEO_CTRL_PLATFORM_H

#include <stdint.h>

#define SOC_CLOCK_HZ       100000000UL
#define UART_BAUD          115200UL

#define BRAM_BASE          0x80000000UL
#define BRAM_SIZE          0x00100000UL
#define UART_BASE          0x10020000UL

/* Actual addresses exported by the current video_ctrl_bd address editor. */
#define AXI_GPIO_BASE      0x40000000UL
#define AXI_IIC_BASE       0x40010000UL
#define VPHY_BASE          0x40020000UL
#define HDMI_RX_BASE       0x40030000UL
#define HDMI_TX_BASE       0x40040000UL
#define HDMI_TX_VTC_BASE   0x40050000UL
#define VPSS_BASE          0x40100000UL
#define VPSS_HSC_BASE      0x40100000UL
#define VPSS_RESET_BASE    0x40110000UL
#define VPSS_VSC_BASE      0x40120000UL

/* AXI GPIO channel 1 outputs. */
#define GPIO_OUT_TX_ENABLE       (1U << 0)
#define GPIO_OUT_CLK_RESET_N     (1U << 1)

/* AXI GPIO channel 2 inputs. */
#define GPIO_IN_RX_PWR_DET       (1U << 0)
#define GPIO_IN_TX_HPD           (1U << 1)
#define GPIO_IN_CLK_LOL          (1U << 2)
#define GPIO_IN_CLK_INT          (1U << 3)
#define GPIO_IN_TX_LOCKED        (1U << 4)

/* 8T49N241 address used by the AMD FMC HDMI reference design. */
#define HDMI_CLK_I2C_ADDRESS     0x7CU

#endif
