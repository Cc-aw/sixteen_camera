#ifndef AI_OVERLAY_H
#define AI_OVERLAY_H

#include "ai_detection.h"

/* Returns one when committed, zero while the hardware mailbox is busy. */
int ai_overlay_try_submit(const AiDetectionResult *result);
int ai_overlay_draw_test_pattern(void);

#endif
