#ifndef TEST_APP_TENSOR_INGRESS_H
#define TEST_APP_TENSOR_INGRESS_H
#include <stdint.h>
/* The production snapshot HAL is frozen and tested separately. This fixture
 * checks command g's stable API, previous snapshot and delta calculations. */
typedef struct {
    uint64_t cycles, accepted_bytes, completed_bytes, errors;
    uint64_t aw_stall, w_stall, tl_a_stall, source_stall, b_stall;
    uint64_t inflight, max_inflight, ack_latency_sum, ack_latency_max;
} TensorIngressSnapshot;
TensorIngressSnapshot test_ingress_snapshot(void);
static inline TensorIngressSnapshot tensor_ingress_snapshot(void)
{
    return test_ingress_snapshot();
}
#endif
