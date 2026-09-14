#include "ai_yolov5nu_selftest.h"

#include <stdint.h>
#include <string.h>

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
