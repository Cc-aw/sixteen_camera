#include "app/app.h"
#include "app/command.h"
#include "diagnostics/board_bandwidth.h"
#include "diagnostics/tensor_production.h"
#include "platform/console.h"
#include "video/video_service.h"

void app_video_init(void)
{
    if (video_service_init() != 0)
        console_puts("Video pipeline initialization failed; press r to retry\r\n");
    tensor_production_init();
}

void app_init(int runtime_status)
{
    console_puts("AI_STAGE runtime_init\r\n");
    if (runtime_status != 0) console_puts("AI runtime initialization failed\r\n");
    app_print_help();
}

void app_poll(void)
{
    board_bandwidth_service();
    tensor_production_service();
    board_write_only_service();
    app_dispatch_command(console_getc_nonblock());
}
