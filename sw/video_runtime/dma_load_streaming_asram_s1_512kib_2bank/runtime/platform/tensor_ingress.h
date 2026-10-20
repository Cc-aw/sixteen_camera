#ifndef TENSOR_INGRESS_H
#define TENSOR_INGRESS_H

#include <stdint.h>

/* Only present in TensorIngress SoC configurations. Snapshot before reading.
 * Counters are in the 100MHz SoC domain and reset on global hardware reset.
 * Both 32-bit halves remain stable until the next snapshot command.
 * Successful bytes count completed B handshakes, not FIFO enqueue.
 */
#define TENSOR_INGRESS_CSR_BASE UINT32_C(0x02012000)
#define TENSOR_INGRESS_CSR_SNAPSHOT 0x00U
#define TENSOR_INGRESS_CSR_VERSION 0x08U
#define TENSOR_INGRESS_CSR_CYCLES 0x20U
#define TENSOR_INGRESS_CSR_ACCEPTED_BYTES 0x28U
#define TENSOR_INGRESS_CSR_COMPLETED_BYTES 0x30U
#define TENSOR_INGRESS_CSR_ERRORS 0x38U
#define TENSOR_INGRESS_CSR_AW_STALL 0x40U
#define TENSOR_INGRESS_CSR_W_STALL 0x48U
#define TENSOR_INGRESS_CSR_TL_A_STALL 0x50U
#define TENSOR_INGRESS_CSR_SOURCE_STALL 0x58U
#define TENSOR_INGRESS_CSR_B_STALL 0x60U
#define TENSOR_INGRESS_CSR_INFLIGHT 0x68U
#define TENSOR_INGRESS_CSR_MAX_INFLIGHT 0x70U
#define TENSOR_INGRESS_CSR_ACK_LATENCY_SUM 0x78U
#define TENSOR_INGRESS_CSR_ACK_LATENCY_MAX 0x80U

typedef struct {
    uint64_t cycles, accepted_bytes, completed_bytes, errors;
    uint64_t aw_stall, w_stall, tl_a_stall, source_stall, b_stall;
    uint64_t inflight, max_inflight, ack_latency_sum, ack_latency_max;
} TensorIngressSnapshot;

static inline void tensor_ingress_mmio_fence(void)
{
#ifdef __riscv
    __asm__ volatile("fence iorw, iorw" ::: "memory");
#else
    __sync_synchronize();
#endif
}

static inline uint64_t tensor_ingress_read_snapshot_counter(uint32_t offset)
{
    volatile const uint32_t *reg = (volatile const uint32_t *)(uintptr_t)
        (TENSOR_INGRESS_CSR_BASE + offset);
    uint32_t lo = reg[0];
    uint32_t hi = reg[1];
    return ((uint64_t)hi << 32) | lo;
}

/* Call only with a TensorIngress bitstream. Keep the snapshot operation and
 * all reads under one owner; another caller must not refresh it concurrently.
 */
static inline TensorIngressSnapshot tensor_ingress_snapshot(void)
{
    volatile uint32_t *command = (volatile uint32_t *)(uintptr_t)TENSOR_INGRESS_CSR_BASE;
    tensor_ingress_mmio_fence();
    *command = 1;
    tensor_ingress_mmio_fence();
    TensorIngressSnapshot snapshot = {
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_CYCLES),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_ACCEPTED_BYTES),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_COMPLETED_BYTES),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_ERRORS),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_AW_STALL),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_W_STALL),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_TL_A_STALL),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_SOURCE_STALL),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_B_STALL),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_INFLIGHT),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_MAX_INFLIGHT),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_ACK_LATENCY_SUM),
        tensor_ingress_read_snapshot_counter(TENSOR_INGRESS_CSR_ACK_LATENCY_MAX)
    };
    return snapshot;
}

#endif
