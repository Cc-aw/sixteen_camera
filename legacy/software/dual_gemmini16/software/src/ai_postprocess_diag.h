#ifndef AI_POSTPROCESS_DIAG_H
#define AI_POSTPROCESS_DIAG_H

#include <stddef.h>
#include <stdint.h>

#define AI_POSTPROCESS_DIAG_ID UINT32_C(0x50504431)
#define AI_POSTPROCESS_DIAG_P1C_CAPABILITY UINT32_C(0x00202105)

typedef struct {
    uint32_t crc32;
    uint32_t byte_sum;
    uint32_t nonzero_count;
    uint32_t bytes_read;
    uint32_t ar_requests;
    uint32_t read_beats;
    uint32_t completion_count;
    uint32_t error_count;
    uint32_t error_flags;
    uint32_t active_cycles;
    uint32_t ar_stall_cycles;
    uint32_t r_wait_cycles;
    uint32_t r_backpressure_cycles;
    uint32_t max_outstanding_observed;
    uint32_t max_reorder_occupancy;
    uint32_t active_id_mask_observed;
} AiPostprocessDiagResult;

typedef struct {
    uint32_t iterations_completed;
    uint32_t failed_iteration;
    int32_t status;
    uint32_t expected_crc32;
    uint32_t observed_crc32;
    uint32_t error_flags;
    uint64_t total_cycles;
    uint64_t maximum_cycles;
} AiPostprocessDiagStressResult;

typedef struct {
    uint32_t iterations_requested;
    uint32_t iterations_completed;
    uint32_t expected_crc32;
    uint32_t observed_crc32;
    uint32_t crc_mismatches;
    uint32_t timeout_count;
    uint32_t axi_error_count;
    uint32_t error_flags;
    uint64_t bytes_read;
    uint64_t active_cycles;
    uint64_t ar_requests;
    uint64_t read_beats;
    uint64_t ar_stall_cycles;
    uint64_t r_wait_cycles;
    uint64_t r_backpressure_cycles;
    uint32_t max_outstanding_observed;
    uint32_t max_reorder_occupancy;
    uint32_t active_id_mask_observed;
} AiPostprocessBandwidthResult;

int ai_postprocess_diag_probe(void);
uint32_t ai_postprocess_diag_read_id(void);
uint32_t ai_postprocess_diag_read_capability(void);
int ai_postprocess_diag_start(uint64_t tensor_addr, uint32_t tensor_bytes);
int ai_postprocess_diag_start_fast(uint64_t tensor_addr,
                                   uint32_t tensor_bytes);
int ai_postprocess_diag_poll(AiPostprocessDiagResult *result);
int ai_postprocess_diag_run(uint64_t tensor_addr, uint32_t tensor_bytes,
                            AiPostprocessDiagResult *result);
int ai_postprocess_diag_coherence_stress(
    uint32_t iterations, AiPostprocessDiagStressResult *result);
uint32_t ai_postprocess_diag_is_active(void);
int ai_postprocess_bandwidth_start(uint32_t iterations);
int ai_postprocess_bandwidth_poll(AiPostprocessBandwidthResult *result);
uint32_t ai_postprocess_crc32(const void *data, size_t bytes);

#endif
