#include "board/board_boot.h"
#include "video/video_service.h"
#include "ai/runtime/rt.h"
#include "app/app.h"

int main(void)
{
    board_boot();
    app_video_init();
    int runtime_status = rt_init();
    app_init(runtime_status);
    for (;;) {
        video_service_poll();
        rt_poll();
        app_poll();
    }
}
