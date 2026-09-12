#include "ai_yolov5nu_selftest.h"

#include <stdint.h>
#include <string.h>

#include "ai_postprocess_diag.h"
#include "console.h"
#include "mmio.h"
#include "platform.h"
#include "yolov5nu_dim16_dual.h"

#define SELFTEST_TIMEOUT_CYCLES (SOC_CLOCK_HZ * UINT64_C(120))

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

static void start_benchmark_ppu(uintptr_t arena)
{
    ai_postprocess_diag_flush_range((void *)(arena + 499200U), 384000U);
    ai_postprocess_diag_flush_range((void *)(arena + 1113600U), 96000U);
    ai_postprocess_diag_flush_range((void *)(arena + 883200U), 24000U);
    ai_postprocess_diag_flush_range((void *)(arena + 153600U), 307200U);
    ai_postprocess_diag_flush_range((void *)(arena + 1036800U), 76800U);
    ai_postprocess_diag_flush_range((void *)(arena + 460800U), 19200U);
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CLASS0,
                 (uint32_t)(arena + 499200U));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CLASS1,
                 (uint32_t)(arena + 1113600U));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CLASS2,
                 (uint32_t)(arena + 883200U));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_DFL0,
                 (uint32_t)(arena + 153600U));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_DFL1,
                 (uint32_t)(arena + 1036800U));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_DFL2,
                 (uint32_t)(arena + 460800U));
    mmio_write32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CONTROL, 1U);
}

int ai_yolov5nu_postprocess_benchmark(void)
{
    uint64_t hardware_sum = 0U;
    uint64_t software_sum = 0U;
    if (mmio_read32(POSTPROCESS_DIAG_BASE + BENCH_PPU_CONTROL) !=
        UINT32_C(0x50505531)) {
        console_puts("YOLOV5NU_POST_BENCH FAIL reason=ppu_missing\r\n");
        return 0;
    }
    console_puts("YOLOV5NU_POST_BENCH_BEGIN image=025 repeats=3 clock_hz=100000000\r\n");
    for (uint32_t iteration = 0U; iteration < BENCH_REPETITIONS;
         ++iteration) {
        struct yolov5nu_dim16_result software_result;
        uint64_t start, graph_cycles, hardware_cycles, software_cycles;
        uint32_t ppu_status, ppu_core_cycles, ppu_count, ppu_positions;
        uint32_t ppu_candidates, ppu_nms_candidates, xy0, xy1, score_class;
        uint32_t hardware_score_milli, software_score_milli;
        const struct yolov5nu_dim16_detection *software_box;
        uintptr_t arena;
        int status;

        memset(&software_result, 0, sizeof(software_result));
        start = read_cycle();
        if (yolov5nu_dim16_worker_start_reference(0U) < 0) {
            console_puts("YOLOV5NU_POST_BENCH FAIL reason=graph_start\r\n");
            return 0;
        }
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
        arena = yolov5nu_dim16_worker_arena(0U);

        start = read_cycle();
        start_benchmark_ppu(arena);
        for (;;) {
            ppu_status = mmio_read32(POSTPROCESS_DIAG_BASE +
                                     BENCH_PPU_STATUS);
            if (ppu_status & 2U)
                break;
            if (read_cycle() - start > SOC_CLOCK_HZ * UINT64_C(30)) {
                console_puts("YOLOV5NU_POST_BENCH FAIL reason=ppu_timeout status=");
                console_put_hex32(ppu_status);
                console_puts("\r\n");
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

        start = read_cycle();
        status = yolov5nu_dim16_worker_finish_software(0U,
                                                        &software_result);
        software_cycles = read_cycle() - start;
        if (status != YOLOV5NU_DIM16_DONE ||
            !result_matches_reference(&software_result)) {
            console_puts("YOLOV5NU_POST_BENCH FAIL reason=software_reference\r\n");
            return 0;
        }
        software_box = &software_result.detections[0];
        hardware_score_milli =
            ((score_class & 0xffffU) * 1000U + 16384U) / 32768U;
        software_score_milli =
            (uint32_t)rounded(software_box->score * 1000.0f);
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
