#include "yolo32.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static int8_t heads[2][YOLOV5NU_HEAD_PAYLOAD_BYTES];
static int8_t logits[2][YOLO32_CLASS_BYTES], scores[2][YOLO32_CLASS_BYTES];
static int8_t dfl[2][YOLO32_POSITIONS * 4];
static uint8_t masks[2][YOLO32_POSITIONS];
static Yolo32Result results[2];

int main(void) {
    Yolo32Output a = {heads[0], logits[0], scores[0], dfl[0], masks[0], &results[0]};
    Yolo32Output b = {heads[1], logits[1], scores[1], dfl[1], masks[1], &results[1]};
    /* Arbitrary equal outputs pass even when unlike any old model golden. */
    memset(heads, 23, sizeof(heads));
    memset(logits, -17, sizeof(logits));
    memset(scores, 42, sizeof(scores));
    results[0].class_logits_checksum = results[1].class_logits_checksum = 12345;
    assert(yolo32_compare(&a, &b).mismatches == 0);
    heads[1][YOLOV5NU_HEAD_PAYLOAD_BYTES - 1]++;
    Yolo32Comparison cmp = yolo32_compare(&a, &b);
    assert(cmp.mismatches == 1 && !strcmp(cmp.first_field, "raw_heads"));
    assert(cmp.first_index == YOLOV5NU_HEAD_PAYLOAD_BYTES - 1);
    heads[1][YOLOV5NU_HEAD_PAYLOAD_BYTES - 1]--;
    logits[1][503999]++;
    assert(!strcmp(yolo32_compare(&a, &b).first_field, "logits"));
    logits[1][503999]--;
    scores[1][0]++;
    assert(!strcmp(yolo32_compare(&a, &b).first_field, "scores"));
    scores[1][0]--;
    /* Uncomputed sparse DFL bytes are not evidence of numerical differences. */
    dfl[1][28] = 7;
    assert(yolo32_compare(&a, &b).mismatches == 0);
    masks[0][7] = masks[1][7] = 1;
    assert(!strcmp(yolo32_compare(&a, &b).first_field, "dfl"));
    dfl[1][28] = 0;
    masks[1][7] = 0;
    assert(!strcmp(yolo32_compare(&a, &b).first_field, "dfl_mask"));
    masks[1][7] = 1;
    results[0].count = results[1].count = 1;
    results[1].detections[0].width = 3.5f;
    assert(!strcmp(yolo32_compare(&a, &b).first_field, "width"));
    results[0].detections[0].width = 3.5f;
    results[1].detections[0].class_id = 4;
    assert(!strcmp(yolo32_compare(&a, &b).first_field, "class_id"));
    results[0].detections[0].class_id = 4;
    assert(yolo32_compare(&a, &b).mismatches == 0);
    results[0].count = results[1].count = 100;
    assert(yolo32_compare(&a, &b).mismatches != 0);
    assert(yolo32_hash("", 0) == UINT64_C(14695981039346656037));
    assert(yolo32_hash("a", 1) == UINT64_C(0xaf63dc4c8601ec8c));
    puts("YOLO32_COMPARE_TEST=PASS");
    return 0;
}
