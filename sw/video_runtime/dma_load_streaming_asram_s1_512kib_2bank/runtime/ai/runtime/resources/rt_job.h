#ifndef RT_JOB_H
#define RT_JOB_H

#include <stdint.h>

typedef struct {
    uint64_t job_id, frame_id;
    uint32_t worker_id, stream_id, version;
} AiRtJobIdentity;

typedef enum {
    AI_RT_JOB_FREE, AI_RT_JOB_RUNNING, AI_RT_JOB_COMPUTE_DONE,
    AI_RT_JOB_POSTPROCESS, AI_RT_JOB_RETIRED, AI_RT_JOB_FAULT_HELD
} AiRtJobState;

typedef struct {
    AiRtJobIdentity identity;
    AiRtJobState state;
} AiRtJob;

static inline AiRtJobIdentity rt_job_identity(uint64_t job, uint32_t worker,
                                             uint32_t stream, uint64_t frame,
                                             uint32_t version)
{
    return (AiRtJobIdentity){job, frame, worker, stream, version};
}

static inline int rt_job_identity_matches(const AiRtJobIdentity *a,
                                          const AiRtJobIdentity *b)
{
    return a->job_id == b->job_id && a->worker_id == b->worker_id &&
           a->stream_id == b->stream_id && a->frame_id == b->frame_id && a->version == b->version;
}

int rt_job_begin(AiRtJob *job, const AiRtJobIdentity *identity);
int rt_job_compute_done(AiRtJob *job, const AiRtJobIdentity *proof);
void rt_job_fault(AiRtJob *job);
#endif
