#include "ai_yolov5nu_selftest.h"

#include <stdint.h>
#include <string.h>

#include "ai_postprocess_diag.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"
#include "yolov5nu_dim16_dual.h"
#include "yolov5nu_head_layout.h"

#define SELFTEST_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(120))
#define BENCH_L1_EVICT_BYTES (64U * 1024U)

/*
 * Local PPU reads bypass the coherent FBus, while the T benchmark later asks
 * the CPU to consume the same DMA-produced Head payload.  Reusing A/B slots
 * can therefore leave old Head lines in the 32 KiB Rocket D-cache.  Touch two
 * cache capacities before the software reference so it measures the current
 * payload rather than a line retained from the previous use of that slot.
 */
static volatile uint8_t benchmark_l1_evict[BENCH_L1_EVICT_BYTES]
    __attribute__((aligned(64)));
static volatile uint8_t benchmark_l1_evict_sink;

static void benchmark_evict_l1(void)
{
    uint8_t sink = benchmark_l1_evict_sink;
    for (size_t offset = 0U; offset < sizeof(benchmark_l1_evict);
         offset += 64U)
        sink ^= benchmark_l1_evict[offset];
    benchmark_l1_evict_sink = sink;
    mmio_fence();
}

static int rounded(float value)
{
    return (int)(value + 0.5f);
}

static int result_matches_reference(
    const struct yolov5nu_dim16_result *result)
{
    const struct yolov5nu_dim16_detection *detection;
    if (result->class_logits_checksum != INT64_C(-17904818) ||
        result->class_logits_fnv1a != UINT64_C(0x20012ccb8f2d3159) ||
        result->class_scores_checksum != INT64_C(1050) ||
        result->class_scores_fnv1a != UINT64_C(0x0aeb25432e02cc59) ||
        result->sparse_dfl_checksum != INT64_C(1405) ||
        result->sparse_dfl_fnv1a != UINT64_C(0xaa070e839df35480) ||
        result->dfl_candidate_count != 10U || result->count != 1U)
        return 0;
    detection = &result->detections[0];
    return detection->class_id == 23 &&
           rounded(detection->score * 1000.0f) == 858 &&
           rounded(detection->center_x) == 494 &&
           rounded(detection->center_y) == 240 &&
           rounded(detection->width) == 213 &&
           rounded(detection->height) == 289;
}

static int results_equal(const struct yolov5nu_dim16_result *left,
                         const struct yolov5nu_dim16_result *right)
{
    if (left->count != right->count ||
        left->class_logits_checksum != right->class_logits_checksum ||
        left->class_logits_fnv1a != right->class_logits_fnv1a ||
        left->class_scores_checksum != right->class_scores_checksum ||
        left->class_scores_fnv1a != right->class_scores_fnv1a ||
        left->sparse_dfl_checksum != right->sparse_dfl_checksum ||
        left->sparse_dfl_fnv1a != right->sparse_dfl_fnv1a ||
        left->dfl_candidate_count != right->dfl_candidate_count)
        return 0;
    for (uint32_t index = 0U; index < left->count; ++index)
        if (memcmp(&left->detections[index], &right->detections[index],
                   sizeof(left->detections[index])) != 0)
            return 0;
    return 1;
}

static void print_worker_result(uint32_t worker,
    const struct yolov5nu_dim16_result *result, int passed)
{
    console_puts("YOLOV5NU_TEST worker=");
    console_put_u32(worker);
    console_puts(" status=");
    console_puts(passed != 0 ? "PASS" : "FAIL");
    console_puts(" logits_sum=");
    console_put_hex64((uint64_t)result->class_logits_checksum);
    console_puts(" logits_fnv=");
    console_put_hex64(result->class_logits_fnv1a);
    console_puts(" scores_sum=");
    console_put_hex64((uint64_t)result->class_scores_checksum);
    console_puts(" scores_fnv=");
    console_put_hex64(result->class_scores_fnv1a);
    console_puts(" dfl_sum=");
    console_put_hex64((uint64_t)result->sparse_dfl_checksum);
    console_puts(" dfl_fnv=");
    console_put_hex64(result->sparse_dfl_fnv1a);
    console_puts(" candidates/nms=");
    console_put_u32(result->dfl_candidate_count);
    console_putc('/');
    console_put_u32(result->count);
    if (result->count != 0U) {
        const struct yolov5nu_dim16_detection *d = &result->detections[0];
        console_puts(" class/score/cx/cy/w/h=");
        console_put_u32((uint32_t)d->class_id);
        console_putc('/');
        console_put_u32((uint32_t)rounded(d->score * 1000.0f));
        console_putc('/');
        console_put_u32((uint32_t)rounded(d->center_x));
        console_putc('/');
        console_put_u32((uint32_t)rounded(d->center_y));
        console_putc('/');
        console_put_u32((uint32_t)rounded(d->width));
        console_putc('/');
        console_put_u32((uint32_t)rounded(d->height));
    }
    console_puts("\r\n");
}

int ai_yolov5nu_correctness_test(void)
{
    struct yolov5nu_dim16_result results[YOLOV5NU_DIM16_WORKER_COUNT];
    uint32_t done_mask = 0U;
    uint64_t start = read_cycle();
    int passed0;
    int passed1;

    memset(results, 0, sizeof(results));
    console_puts("YOLOV5NU_TEST_BEGIN image=025 workers=2\r\n");
    for (uint32_t worker = 0U;
         worker < YOLOV5NU_DIM16_WORKER_COUNT; ++worker) {
        if (yolov5nu_dim16_worker_start_reference(worker) < 0) {
            console_puts("YOLOV5NU_TEST_RESULT FAIL reason=start\r\n");
            return 0;
        }
    }

    while (done_mask != UINT32_C(3)) {
        for (uint32_t worker = 0U;
             worker < YOLOV5NU_DIM16_WORKER_COUNT; ++worker) {
            uint32_t mask = UINT32_C(1) << worker;
            int status;
            if ((done_mask & mask) != 0U)
                continue;
            status = yolov5nu_dim16_worker_poll(worker, &results[worker]);
            if (status == YOLOV5NU_DIM16_DONE)
                done_mask |= mask;
            else if (status == YOLOV5NU_DIM16_ERROR) {
                console_puts("YOLOV5NU_TEST_RESULT FAIL reason=poll\r\n");
                return 0;
            }
        }
        if (read_cycle() - start > SELFTEST_TIMEOUT_CYCLES) {
            console_puts("YOLOV5NU_TEST_RESULT FAIL reason=timeout\r\n");
            return 0;
        }
    }

    passed0 = result_matches_reference(&results[0]);
    passed1 = result_matches_reference(&results[1]);
    print_worker_result(0U, &results[0], passed0);
    print_worker_result(1U, &results[1], passed1);
    if (passed0 == 0 || passed1 == 0 ||
        results_equal(&results[0], &results[1]) == 0) {
        console_puts("YOLOV5NU_TEST_RESULT FAIL reason=reference_or_dual_mismatch\r\n");
        return 0;
    }
    console_puts("YOLOV5NU_TEST_RESULT PASS reference=bit_exact dual=bit_exact\r\n");
    return 1;
}

int ai_yolov5nu_sequential_correctness_test(int reverse_order)
{
    struct yolov5nu_dim16_result results[YOLOV5NU_DIM16_WORKER_COUNT];
    int passed = 1;

    memset(results, 0, sizeof(results));
    console_puts(reverse_order ?
        "YOLOV5NU_SEQ_TEST_BEGIN image=025 order=1,0\r\n" :
        "YOLOV5NU_SEQ_TEST_BEGIN image=025 order=0,1\r\n");
    for (uint32_t index = 0U;
         index < YOLOV5NU_DIM16_WORKER_COUNT; ++index) {
        uint32_t worker = reverse_order ?
            YOLOV5NU_DIM16_WORKER_COUNT - 1U - index : index;
        uint64_t start = read_cycle();
        if (yolov5nu_dim16_worker_start_reference(worker) < 0) {
            console_puts("YOLOV5NU_SEQ_TEST_RESULT FAIL reason=start\r\n");
            return 0;
        }
        for (;;) {
            int status = yolov5nu_dim16_worker_poll(worker,
                                                     &results[worker]);
            if (status == YOLOV5NU_DIM16_DONE)
                break;
            if (status != YOLOV5NU_DIM16_RUNNING ||
                read_cycle() - start > SELFTEST_TIMEOUT_CYCLES) {
                console_puts("YOLOV5NU_SEQ_TEST_RESULT FAIL reason=poll_or_timeout\r\n");
                return 0;
            }
        }
        int worker_passed = result_matches_reference(&results[worker]);
        print_worker_result(worker, &results[worker], worker_passed);
        if (!worker_passed)
            passed = 0;
    }
    if (!results_equal(&results[0], &results[1]))
        passed = 0;
    console_puts(passed ?
        "YOLOV5NU_SEQ_TEST_RESULT PASS reference=bit_exact\r\n" :
        "YOLOV5NU_SEQ_TEST_RESULT FAIL reason=reference_or_worker_mismatch\r\n");
    return passed;
}

// The benchmark starts both implementations at the same six raw Gemmini
// heads. PPU wall time includes cache publication, MMIO and result reads;
// the CPU time is the existing software head/Decode/NMS worker path.
enum {
    BENCH_PPU_CONTROL = 0x100U,
    BENCH_PPU_CLASS0 = 0x104U,
    BENCH_PPU_CLASS1 = 0x108U,
    BENCH_PPU_CLASS2 = 0x10cU,
    BENCH_PPU_DFL0 = 0x110U,
    BENCH_PPU_DFL1 = 0x114U,
    BENCH_PPU_DFL2 = 0x118U,
    BENCH_PPU_STATUS = 0x11cU,
    BENCH_PPU_RESULT_INDEX = 0x120U,
    BENCH_PPU_RESULT_COUNT = 0x124U,
    BENCH_PPU_XY0 = 0x128U,
    BENCH_PPU_XY1 = 0x12cU,
    BENCH_PPU_SCORE_CLASS = 0x130U,
    BENCH_PPU_POSITIONS = 0x138U,
    BENCH_PPU_CANDIDATES = 0x13cU,
    BENCH_PPU_NMS_CANDIDATES = 0x140U,
    BENCH_PPU_CYCLES = 0x144U,
    BENCH_REPETITIONS = 3U
};

static uint32_t difference_u32(uint32_t left, uint32_t right)
{
    return left >= right ? left - right : right - left;
}

static void start_benchmark_ppu(uintptr_t head)
{
    ai_postprocess_diag_flush_range((void *)head,
                                    YOLOV5NU_HEAD_PAYLOAD_BYTES);
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CLASS0,
                 (uint32_t)(head + YOLOV5NU_HEAD_CLASS0_OFFSET));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CLASS1,
                 (uint32_t)(head + YOLOV5NU_HEAD_CLASS1_OFFSET));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CLASS2,
                 (uint32_t)(head + YOLOV5NU_HEAD_CLASS2_OFFSET));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_DFL0,
                 (uint32_t)(head + YOLOV5NU_HEAD_DFL0_OFFSET));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_DFL1,
                 (uint32_t)(head + YOLOV5NU_HEAD_DFL1_OFFSET));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_DFL2,
                 (uint32_t)(head + YOLOV5NU_HEAD_DFL2_OFFSET));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CONTROL, 1U);
}

static uint32_t benchmark_cycles_to_us(uint64_t cycles)
{
    return (uint32_t)((cycles * UINT64_C(1000000) +
                       SOC_CLOCK_HZ / UINT64_C(2)) / SOC_CLOCK_HZ);
}

static int finish_benchmark_software(
    struct yolov5nu_dim16_result *software_result,
    uint64_t *software_cycles)
{
    uint64_t start;
    int status;
    benchmark_evict_l1();
    start = read_cycle();
    status = yolov5nu_dim16_worker_finish_software(0U, software_result);
    *software_cycles = read_cycle() - start;
    if (status != YOLOV5NU_DIM16_DONE ||
        !result_matches_reference(software_result)) {
        console_puts("YOLOV5NU_POST_BENCH FAIL reason=software_reference\r\n");
        print_worker_result(0U, software_result, 0);
        return 0;
    }
    return 1;
}

/*
 * Standalone board timing path.  Unlike the T command, this does not run the
 * software postprocessor.  It measures the current production head layout:
 * fixed image025 Graph -> dedicated Head Slot -> cache publication -> PPU1.
 */
int ai_yolov5nu_graph_post_benchmark(void)
{
    uint64_t graph_sum = 0U;
    uint64_t post_wall_sum = 0U;
    uint64_t post_core_sum = 0U;
    uint64_t total_sum = 0U;

    if (mmio_read32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CONTROL) !=
        UINT32_C(0x50505531)) {
        console_puts("YOLOV5NU_PIPE_BENCH FAIL reason=ppu_missing\r\n");
        return 0;
    }
    console_puts("YOLOV5NU_PIPE_BENCH_BEGIN image=025 repeats=");
    console_put_u32(BENCH_REPETITIONS);
    console_puts(" clock_hz=");
    console_put_u32(SOC_CLOCK_HZ);
    console_puts("\r\n");

    for (uint32_t iteration = 0U; iteration < BENCH_REPETITIONS;
         ++iteration) {
        struct yolov5nu_dim16_result unused_result;
        uintptr_t head;
        uint64_t graph_start, graph_cycles, post_start, post_wall_cycles;
        uint64_t total_cycles;
        uint32_t ppu_status, ppu_core_cycles, ppu_count, ppu_positions;
        uint32_t ppu_candidates, ppu_nms_candidates, score_class;
        uint32_t score_milli;
        int status;

        memset(&unused_result, 0, sizeof(unused_result));
        graph_start = read_cycle();
        if (yolov5nu_dim16_worker_start_reference(0U) < 0) {
            console_puts("YOLOV5NU_PIPE_BENCH FAIL reason=graph_start\r\n");
            return 0;
        }
        head = AI_DDR_CPU_ALIAS(AI_MODEL_OUTPUT0_PHYS_BASE +
            (iteration & 1U) * YOLOV5NU_HEAD_SLOT_STRIDE);
        yolov5nu_dim16_worker_set_head_slot(0U, head);
        yolov5nu_dim16_worker_use_hardware(0U, 1);
        for (;;) {
            status = yolov5nu_dim16_worker_poll(0U, &unused_result);
            if (status == YOLOV5NU_DIM16_HEAD_READY)
                break;
            if (status != YOLOV5NU_DIM16_RUNNING ||
                read_cycle() - graph_start > SELFTEST_TIMEOUT_CYCLES) {
                console_puts("YOLOV5NU_PIPE_BENCH FAIL reason=graph\r\n");
                yolov5nu_dim16_worker_finish_hardware(0U);
                return 0;
            }
        }
        graph_cycles = read_cycle() - graph_start;

        post_start = read_cycle();
        start_benchmark_ppu(head);
        for (;;) {
            ppu_status = mmio_read32(POSTPROCESS_DIAG_BASE +
                                     BENCH_PPU_STATUS);
            if ((ppu_status & 2U) != 0U)
                break;
            if (read_cycle() - post_start > SOC_CLOCK_HZ * UINT64_C(30)) {
                console_puts("YOLOV5NU_PIPE_BENCH FAIL reason=ppu_timeout status=");
                console_put_hex32(ppu_status);
                console_puts("\r\n");
                yolov5nu_dim16_worker_finish_hardware(0U);
                return 0;
            }
        }
        ppu_core_cycles = mmio_read32(POSTPROCESS_DIAG_BASE +
                                      BENCH_PPU_CYCLES);
        ppu_positions = mmio_read32(POSTPROCESS_DIAG_BASE +
                                    BENCH_PPU_POSITIONS);
        ppu_candidates = mmio_read32(POSTPROCESS_DIAG_BASE +
                                     BENCH_PPU_CANDIDATES);
        ppu_nms_candidates = mmio_read32(POSTPROCESS_DIAG_BASE +
                                         BENCH_PPU_NMS_CANDIDATES);
        ppu_count = mmio_read32(POSTPROCESS_DIAG_BASE +
                                BENCH_PPU_RESULT_COUNT);
        mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_RESULT_INDEX, 0U);
        score_class = mmio_read32(POSTPROCESS_DIAG_BASE +
                                  BENCH_PPU_SCORE_CLASS);
        post_wall_cycles = read_cycle() - post_start;
        yolov5nu_dim16_worker_finish_hardware(0U);

        score_milli = ((score_class & 0xffffU) * 1000U + 16384U) /
                      32768U;
        if (ppu_status != 2U || ppu_positions != 6300U ||
            ppu_candidates != 10U || ppu_nms_candidates != 10U ||
            ppu_count != 1U || ((score_class >> 16) & 0x7fU) != 23U ||
            difference_u32(score_milli, 858U) > 1U) {
            console_puts("YOLOV5NU_PIPE_BENCH FAIL reason=ppu_result status/count/positions/candidates/nms/class/score_milli=");
            console_put_hex32(ppu_status);
            console_putc('/');
            console_put_u32(ppu_count);
            console_putc('/');
            console_put_u32(ppu_positions);
            console_putc('/');
            console_put_u32(ppu_candidates);
            console_putc('/');
            console_put_u32(ppu_nms_candidates);
            console_putc('/');
            console_put_u32((score_class >> 16) & 0x7fU);
            console_putc('/');
            console_put_u32(score_milli);
            console_puts("\r\n");
            return 0;
        }

        total_cycles = graph_cycles + post_wall_cycles;
        graph_sum += graph_cycles;
        post_wall_sum += post_wall_cycles;
        post_core_sum += ppu_core_cycles;
        total_sum += total_cycles;
        console_puts("YOLOV5NU_PIPE_BENCH sample/graph_cycles/post_wall_cycles/post_core_cycles/total_cycles=");
        console_put_u32(iteration + 1U);
        console_putc('/');
        console_put_hex64(graph_cycles);
        console_putc('/');
        console_put_hex64(post_wall_cycles);
        console_putc('/');
        console_put_u32(ppu_core_cycles);
        console_putc('/');
        console_put_hex64(total_cycles);
        console_puts("\r\n");
        console_puts("YOLOV5NU_PIPE_BENCH time_us graph/post_wall/post_core/total=");
        console_put_u32(benchmark_cycles_to_us(graph_cycles));
        console_putc('/');
        console_put_u32(benchmark_cycles_to_us(post_wall_cycles));
        console_putc('/');
        console_put_u32(benchmark_cycles_to_us(ppu_core_cycles));
        console_putc('/');
        console_put_u32(benchmark_cycles_to_us(total_cycles));
        console_puts("\r\n");
    }

    console_puts("YOLOV5NU_PIPE_BENCH_RESULT PASS avg_cycles graph/post_wall/post_core/total=");
    console_put_hex64(graph_sum / BENCH_REPETITIONS);
    console_putc('/');
    console_put_hex64(post_wall_sum / BENCH_REPETITIONS);
    console_putc('/');
    console_put_hex64(post_core_sum / BENCH_REPETITIONS);
    console_putc('/');
    console_put_hex64(total_sum / BENCH_REPETITIONS);
    console_puts("\r\n");
    console_puts("YOLOV5NU_PIPE_BENCH_RESULT avg_us graph/post_wall/post_core/total=");
    console_put_u32(benchmark_cycles_to_us(graph_sum / BENCH_REPETITIONS));
    console_putc('/');
    console_put_u32(benchmark_cycles_to_us(post_wall_sum /
                                           BENCH_REPETITIONS));
    console_putc('/');
    console_put_u32(benchmark_cycles_to_us(post_core_sum /
                                           BENCH_REPETITIONS));
    console_putc('/');
    console_put_u32(benchmark_cycles_to_us(total_sum /
                                           BENCH_REPETITIONS));
    console_puts("\r\n");
    return 1;
}

int ai_yolov5nu_postprocess_benchmark(void)
{
    uint64_t hardware_sum = 0U;
    uint64_t software_sum = 0U;
    uint32_t backing_status;
    uint32_t software_before_ppu;
    if (mmio_read32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CONTROL) !=
        UINT32_C(0x50505531)) {
        console_puts("YOLOV5NU_POST_BENCH FAIL reason=ppu_missing\r\n");
        return 0;
    }
    backing_status = ai_postprocess_ppu_backing_status();
    software_before_ppu = (backing_status & 3U) != 2U;
    console_puts("YOLOV5NU_POST_BENCH_BEGIN image=025 repeats=3 clock_hz=100000000\r\n");
    for (uint32_t iteration = 0U; iteration < BENCH_REPETITIONS;
         ++iteration) {
        struct yolov5nu_dim16_result software_result;
        uint64_t start, graph_cycles, hardware_cycles, software_cycles;
        uint32_t ppu_status, ppu_core_cycles, ppu_count, ppu_positions;
        uint32_t ppu_candidates, ppu_nms_candidates, xy0, xy1, score_class;
        uint32_t hardware_score_milli, software_score_milli;
        const struct yolov5nu_dim16_detection *software_box;
        uintptr_t head;
        int status;

        memset(&software_result, 0, sizeof(software_result));
        start = read_cycle();
        if (yolov5nu_dim16_worker_start_reference(0U) < 0) {
            console_puts("YOLOV5NU_POST_BENCH FAIL reason=graph_start\r\n");
            return 0;
        }
        head = AI_DDR_CPU_ALIAS(AI_MODEL_OUTPUT0_PHYS_BASE +
            (iteration & 1U) * YOLOV5NU_HEAD_SLOT_STRIDE);
        yolov5nu_dim16_worker_set_head_slot(0U, head);
        yolov5nu_dim16_worker_use_hardware(0U, 1);
        for (;;) {
            status = yolov5nu_dim16_worker_poll(0U, &software_result);
            if (status == YOLOV5NU_DIM16_HEAD_READY)
                break;
            if (status != YOLOV5NU_DIM16_RUNNING ||
                read_cycle() - start > SELFTEST_TIMEOUT_CYCLES) {
                console_puts("YOLOV5NU_POST_BENCH FAIL reason=graph\r\n");
                return 0;
            }
        }
        graph_cycles = read_cycle() - start;

        /*
         * P3 shadow images use the coherent producer view for the CPU oracle.
         * In P4.2 URAM-only mode, eviction before publication can make a CPU
         * miss reach stale URAM.  Publish and validate URAM with the PPU
         * first, then evict L1 and let the CPU consume the same backing.
         */
        if (software_before_ppu != 0U &&
            finish_benchmark_software(&software_result,
                                      &software_cycles) == 0)
            return 0;

        start = read_cycle();
        start_benchmark_ppu(head);
        for (;;) {
            ppu_status = mmio_read32(POSTPROCESS_DIAG_BASE +
                                     BENCH_PPU_STATUS);
            if (ppu_status & 2U)
                break;
            if (read_cycle() - start > SOC_CLOCK_HZ * UINT64_C(30)) {
                console_puts("YOLOV5NU_POST_BENCH FAIL reason=ppu_timeout status=");
                console_put_hex32(ppu_status);
                console_puts("\r\n");
                yolov5nu_dim16_worker_finish_hardware(0U);
                return 0;
            }
        }
        ppu_core_cycles = mmio_read32(POSTPROCESS_DIAG_BASE +
                                      BENCH_PPU_CYCLES);
        ppu_positions = mmio_read32(POSTPROCESS_DIAG_BASE +
                                    BENCH_PPU_POSITIONS);
        ppu_candidates = mmio_read32(POSTPROCESS_DIAG_BASE +
                                     BENCH_PPU_CANDIDATES);
        ppu_nms_candidates = mmio_read32(POSTPROCESS_DIAG_BASE +
                                         BENCH_PPU_NMS_CANDIDATES);
        ppu_count = mmio_read32(POSTPROCESS_DIAG_BASE + BENCH_PPU_RESULT_COUNT);
        mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_RESULT_INDEX, 0U);
        xy0 = mmio_read32(POSTPROCESS_DIAG_BASE + BENCH_PPU_XY0);
        xy1 = mmio_read32(POSTPROCESS_DIAG_BASE + BENCH_PPU_XY1);
        score_class = mmio_read32(POSTPROCESS_DIAG_BASE +
                                  BENCH_PPU_SCORE_CLASS);
        hardware_cycles = read_cycle() - start;
        if (ppu_status != 2U || ppu_positions != 6300U ||
            ppu_candidates != 10U || ppu_nms_candidates != 10U ||
            ppu_count != 1U) {
            console_puts("YOLOV5NU_POST_BENCH FAIL reason=ppu_result status/count/positions/candidates/nms=");
            console_put_hex32(ppu_status);
            console_putc('/');
            console_put_u32(ppu_count);
            console_putc('/');
            console_put_u32(ppu_positions);
            console_putc('/');
            console_put_u32(ppu_candidates);
            console_putc('/');
            console_put_u32(ppu_nms_candidates);
            console_puts("\r\n");
            yolov5nu_dim16_worker_finish_hardware(0U);
            return 0;
        }
        if (software_before_ppu == 0U &&
            finish_benchmark_software(&software_result,
                                      &software_cycles) == 0)
            return 0;
        software_box = &software_result.detections[0];
        software_score_milli =
            (uint32_t)rounded(software_box->score * 1000.0f);
        hardware_score_milli =
            ((score_class & 0xffffU) * 1000U + 16384U) / 32768U;
        if (((score_class >> 16) & 0x7fU) !=
                (uint32_t)software_box->class_id ||
            difference_u32(hardware_score_milli, software_score_milli) > 1U ||
            difference_u32(xy0 & 0xffffU,
                (uint32_t)rounded(software_box->center_x -
                                  software_box->width * 0.5f)) > 2U ||
            difference_u32(xy0 >> 16,
                (uint32_t)rounded(software_box->center_y -
                                  software_box->height * 0.5f)) > 2U ||
            difference_u32(xy1 & 0xffffU,
                (uint32_t)rounded(software_box->center_x +
                                  software_box->width * 0.5f)) > 2U ||
            difference_u32(xy1 >> 16,
                (uint32_t)rounded(software_box->center_y +
                                  software_box->height * 0.5f)) > 2U) {
            console_puts("YOLOV5NU_POST_BENCH FAIL reason=hardware_software_mismatch\r\n");
            return 0;
        }
        hardware_sum += hardware_cycles;
        software_sum += software_cycles;
        console_puts("YOLOV5NU_POST_BENCH sample/graph/hw_wall/hw_core/sw_cycles/score_milli=");
        console_put_u32(iteration + 1U);
        console_putc('/');
        console_put_hex64(graph_cycles);
        console_putc('/');
        console_put_hex64(hardware_cycles);
        console_putc('/');
        console_put_u32(ppu_core_cycles);
        console_putc('/');
        console_put_hex64(software_cycles);
        console_putc('/');
        console_put_u32(hardware_score_milli);
        console_puts("\r\n");
    }
    console_puts("YOLOV5NU_POST_BENCH_RESULT PASS avg_hw_wall/avg_sw_cycles/speedup_x100=");
    console_put_hex64(hardware_sum / BENCH_REPETITIONS);
    console_putc('/');
    console_put_hex64(software_sum / BENCH_REPETITIONS);
    console_putc('/');
    console_put_u32((uint32_t)((software_sum * 100U + hardware_sum / 2U) /
                               hardware_sum));
    console_puts("\r\n");
    return 1;
}
