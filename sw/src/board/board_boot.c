#include "board/board_boot.h"
#include "platform/console.h"

void board_boot(void)
{
    console_init();
    console_puts("\r\n8x OV7670 -> shared DMA -> DDR -> HDMI TX\r\n");
    console_puts("CH1-CH8 local + CH9-CH16 HDMI in 4x4 1080p60 mosaic\r\n");
    console_puts("All OV7670 initialization is hardware controlled\r\n");
#ifdef FBUS_BANDWIDTH_DIAGNOSTIC
    console_puts("Dedicated FBus bandwidth diagnostic firmware\r\n");
#endif

}
