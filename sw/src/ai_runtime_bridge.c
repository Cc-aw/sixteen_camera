#include "ai_runtime_bridge.h"

#include "console.h"

/* Integration point for the generated YOLO model.  The initial bridge is a
 * no-op so the unified video runtime can be validated independently. */
int ai_runtime_bridge_init(void)
{
    console_puts("AI_STAGE runtime_init\r\n");
    return 0;
}

int ai_runtime_bridge_step(void)
{
    console_puts("AI_STAGE inference_stub\r\n");
    return 0;
}
