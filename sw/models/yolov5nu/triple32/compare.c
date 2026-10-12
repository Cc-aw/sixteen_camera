#include "yolo32.h"

uint64_t yolo32_hash(const void *data, size_t bytes) {
    const uint8_t *p = data;
    uint64_t hash = UINT64_C(14695981039346656037);
    for (size_t i = 0; i < bytes; ++i) {
        hash ^= p[i];
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

uint32_t yolo32_float_bits(float value) {
    union { float f; uint32_t u; } bits = {.f = value};
    return bits.u;
}

static void mismatch(Yolo32Comparison *out, const char *field, uint32_t index) {
    if (out->mismatches++ == 0) {
        out->first_field = field;
        out->first_index = index;
    }
}

static void compare_bytes(Yolo32Comparison *out, const void *left,
                          const void *right, uint32_t bytes, const char *field) {
    const uint8_t *a = left, *b = right;
    for (uint32_t i = 0; i < bytes; ++i)
        if (a[i] != b[i]) mismatch(out, field, i);
}

Yolo32Comparison yolo32_compare(const Yolo32Output *left,
                                const Yolo32Output *right) {
    Yolo32Comparison out = {0, "none", 0};
    const Yolo32Result *a = left->result, *b = right->result;
    compare_bytes(&out, left->heads, right->heads,
                  YOLOV5NU_HEAD_PAYLOAD_BYTES, "raw_heads");
    compare_bytes(&out, left->logits, right->logits, YOLO32_CLASS_BYTES, "logits");
    compare_bytes(&out, left->scores, right->scores, YOLO32_CLASS_BYTES, "scores");
    compare_bytes(&out, left->mask, right->mask, YOLO32_POSITIONS, "dfl_mask");
    for (uint32_t p = 0; p < YOLO32_POSITIONS; ++p) {
        if (!left->mask[p] && !right->mask[p]) continue;
        for (uint32_t edge = 0; edge < 4; ++edge) {
            uint32_t i = p * 4 + edge;
            if (left->dfl[i] != right->dfl[i]) mismatch(&out, "dfl", i);
        }
    }
#define CHECK(field) do { if (a->field != b->field) mismatch(&out, #field, 0); } while (0)
    CHECK(count);
    CHECK(class_logits_checksum); CHECK(class_logits_fnv1a);
    CHECK(class_scores_checksum); CHECK(class_scores_fnv1a);
    CHECK(sparse_dfl_checksum); CHECK(sparse_dfl_fnv1a);
    CHECK(dfl_candidate_count);
#undef CHECK
    if (a->count > YOLOV5NU_DIM16_MAX_DETECTIONS ||
        b->count > YOLOV5NU_DIM16_MAX_DETECTIONS ||
        a->dfl_candidate_count > YOLO32_POSITIONS ||
        b->dfl_candidate_count > YOLO32_POSITIONS) {
        mismatch(&out, "invalid_count", 0);
        return out;
    }
    uint32_t count = a->count < b->count ? a->count : b->count;
    for (uint32_t i = 0; i < count; ++i) {
        const struct yolov5nu_dim16_detection *x = &a->detections[i], *y = &b->detections[i];
        if (x->class_id != y->class_id) mismatch(&out, "class_id", i);
#define CHECK_FLOAT(field) do { if (yolo32_float_bits(x->field) != yolo32_float_bits(y->field)) mismatch(&out, #field, i); } while (0)
        CHECK_FLOAT(score); CHECK_FLOAT(center_x); CHECK_FLOAT(center_y);
        CHECK_FLOAT(width); CHECK_FLOAT(height);
#undef CHECK_FLOAT
    }
    return out;
}
