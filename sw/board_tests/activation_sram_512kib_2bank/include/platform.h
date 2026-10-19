#ifndef AT_YOLO_PLATFORM_H
#define AT_YOLO_PLATFORM_H

/* The standalone AtestRuntimev5 and camera SoC have different MMIO maps.
 * Target makefiles must select the board UART explicitly. */
#ifndef AT_UART_BASE
#define AT_UART_BASE 0x64000000UL
#endif
#define AT_UART_DIV 867U

#endif
