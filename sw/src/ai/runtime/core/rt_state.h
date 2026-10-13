#ifndef RT_STATE_H
#define RT_STATE_H

#include "ai/runtime/ai_batch_runtime.h"

/* Phase captures producer enable/drain. Fault is latched independently so a
 * fault can precede the original poll-position disable and safe drain. */
typedef struct {
    AiRtState phase;
    uint32_t fault_latched;
} AiRtControl;

static inline uint32_t rt_control_enabled(const AiRtControl *control)
{
    return control->phase == AI_RT_STATE_RUNNING;
}

static inline uint32_t rt_control_draining(const AiRtControl *control)
{
    return control->phase == AI_RT_STATE_DRAINING;
}

static inline uint32_t rt_control_faulted(const AiRtControl *control)
{
    return control->fault_latched;
}

static inline AiRtState rt_control_state(const AiRtControl *control)
{
    return control->fault_latched ? AI_RT_STATE_FAULTED : control->phase;
}

static inline int rt_control_start(AiRtControl *control)
{
    if (control->phase != AI_RT_STATE_STOPPED || control->fault_latched)
        return -1;
    control->phase = AI_RT_STATE_RUNNING;
    return 0;
}

static inline void rt_control_stop(AiRtControl *control)
{
    control->phase = AI_RT_STATE_DRAINING;
}

static inline void rt_control_fault(AiRtControl *control)
{
    control->fault_latched = 1U;
}

static inline void rt_control_drained(AiRtControl *control)
{
    control->phase = AI_RT_STATE_STOPPED;
}

#endif
