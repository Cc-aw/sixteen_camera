#include "ai/runtime/resources/rt_job.h"
int rt_job_begin(AiRtJob *job, const AiRtJobIdentity *identity)
{
    if (!job || !identity || (job->state != AI_RT_JOB_FREE && job->state != AI_RT_JOB_RETIRED))
        return -1;
    job->identity = *identity;
    job->state = AI_RT_JOB_RUNNING;
    return 0;
}

int rt_job_compute_done(AiRtJob *job, const AiRtJobIdentity *proof)
{
    if (!job || !proof || job->state != AI_RT_JOB_RUNNING ||
        !rt_job_identity_matches(&job->identity, proof))
        return -1;
    job->state = AI_RT_JOB_COMPUTE_DONE;
    return 0;
}

void rt_job_fault(AiRtJob *job)
{
    if (job && job->state != AI_RT_JOB_FREE && job->state != AI_RT_JOB_RETIRED)
        job->state = AI_RT_JOB_FAULT_HELD;
}
