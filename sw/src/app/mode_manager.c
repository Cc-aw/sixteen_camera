#include "app/mode_manager.h"
#include "platform/console.h"

AiAppModes app_modes;

int app_mode_command_allowed(int command)
{
    return !(app_modes.tensor.mode != 0U && command >= 0 &&
#ifdef TENSOR_INGRESS_STATS
             command != 'g' &&
#endif
             command != 'm' && command != 's' && command != 'h');
}

int app_mode_selftest_allowed(void)
{
    return !(rt_is_idle() == 0U || app_modes.tensor.mode != 0U ||
             app_modes.bandwidth.active != 0U || app_modes.write_only.active != 0U);
}

void app_mode_toggle_runtime(void)
{
    if (app_modes.tensor.mode != 0U && rt_is_enabled() == 0U) {
        console_puts("TENSOR PROD active; press m and wait for drain\r\n");
        return;
    }
    rt_set_enabled(!rt_is_enabled());
    console_puts(rt_is_enabled() != 0U ?
                 "AI stream runtime enabled\r\n" : "AI stream runtime draining\r\n");
}
