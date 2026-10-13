#ifndef RT_DEBUG_H
#define RT_DEBUG_H
/* Diagnostic ownership snapshot. Application uses the common facade rt.h. */
#include "ai/runtime/resources/rt_resources.h"
void rt_get_resources(AiRtResourceSnapshot *snapshot);
#endif
