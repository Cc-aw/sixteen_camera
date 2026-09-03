#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>

#if TINYYOLOV2_GEMMINI_POOL
#define GEMMINI_POOL_RUNTIME_DISPATCH 1
extern unsigned gemmini_pool_active_worker;
#endif
#include "include/gemmini.h"
#include "include/gemmini_nn.h"
#include "include/gemmini_counter.h"
#include "tinyyolov2_params.h"
#include "tinyyolov2_runtime.h"
#include "tinyyolov2_worker_pool.h"

/* The board runtime uses read_cycle(); the reference Gemmini test helpers
 * expose the same CSR as read_cycles(). */
static inline uint64_t read_cycle(void) {
  return read_cycles();
}

#if TINYYOLOV2_INPUT_H != TINYYOLOV2_INPUT_HEIGHT || \
    TINYYOLOV2_INPUT_W != TINYYOLOV2_INPUT_WIDTH || \
    TINYYOLOV2_INPUT_C != TINYYOLOV2_INPUT_CHANNELS
#error "TinyYOLOv2 generated parameters do not match the input contract"
#endif

static elem_t tinyyolov2_buf0[TINYYOLOV2_MAX_BUFFER_ELEMS] row_align(1);
static elem_t tinyyolov2_buf1[TINYYOLOV2_MAX_BUFFER_ELEMS] row_align(1);

/* Flush64 is the Taihang L2 cache-maintenance register. Gemmini DMA and the
 * camera preprocess engine are not coherent with Rocket's private caches. */
#define TINYYOLOV2_L2_FLUSH64 ((uintptr_t)0x02010200UL)
#define TINYYOLOV2_CACHE_LINE_BYTES 64U

static inline void tinyyolov2_cache_line_flush(uintptr_t address) {
  __asm__ volatile ("fence rw, rw" : : : "memory");
  *(volatile uint64_t *)TINYYOLOV2_L2_FLUSH64 =
      (uint64_t)(address & ~(uintptr_t)(TINYYOLOV2_CACHE_LINE_BYTES - 1U));
  __asm__ volatile ("fence rw, rw" : : : "memory");
}

static void tinyyolov2_cache_range_flush(const void *base, size_t bytes) {
  uintptr_t address = (uintptr_t)base &
      ~(uintptr_t)(TINYYOLOV2_CACHE_LINE_BYTES - 1U);
  const uintptr_t end = ((uintptr_t)base + bytes +
      TINYYOLOV2_CACHE_LINE_BYTES - 1U) &
      ~(uintptr_t)(TINYYOLOV2_CACHE_LINE_BYTES - 1U);

  while (address < end) {
    tinyyolov2_cache_line_flush(address);
    address += TINYYOLOV2_CACHE_LINE_BYTES;
  }
}

#if TINYYOLOV2_GEMMINI_POOL
unsigned gemmini_pool_active_worker;
volatile uint32_t tinyyolov2_worker_last_load[2];
volatile uint32_t tinyyolov2_worker_last_exec[2];
volatile uint32_t tinyyolov2_worker_last_store[2];

static elem_t tinyyolov2_worker1_buf0[TINYYOLOV2_MAX_BUFFER_ELEMS]
    row_align(1);
static elem_t tinyyolov2_worker1_buf1[TINYYOLOV2_MAX_BUFFER_ELEMS]
    row_align(1);

enum tinyyolov2_worker_state {
  TINYYOLOV2_WORKER_IDLE,
  TINYYOLOV2_WORKER_WAIT_LAYER,
};

struct tinyyolov2_worker_context {
  enum tinyyolov2_worker_state state;
  unsigned worker_id;
  int layer_index;
  int poll_armed;
  const char *input_name;
  const elem_t *input;
  elem_t *output;
  elem_t *buf0;
  elem_t *buf1;
};

static struct tinyyolov2_worker_context
    tinyyolov2_workers[TINYYOLOV2_WORKER_COUNT];
#endif

static void apply_leaky_relu_int8(elem_t *values, int elems) {
  const elem_t *lut = tinyyolov2_leaky_relu_lut;
  elem_t *p = values;
  elem_t *end = values + elems;

  for (; p + 8 <= end; p += 8) {
    p[0] = lut[(uint8_t)p[0]];
    p[1] = lut[(uint8_t)p[1]];
    p[2] = lut[(uint8_t)p[2]];
    p[3] = lut[(uint8_t)p[3]];
    p[4] = lut[(uint8_t)p[4]];
    p[5] = lut[(uint8_t)p[5]];
    p[6] = lut[(uint8_t)p[6]];
    p[7] = lut[(uint8_t)p[7]];
  }
  for (; p < end; p++) {
    *p = lut[(uint8_t)*p];
  }
}

static inline void enable_vector_state(void) {
  const uintptr_t state_mask = (3UL << 9) | (3UL << 13) | (3UL << 15);
  __asm__ volatile ("csrs mstatus, %0" : : "r" (state_mask) : "memory");
}

#if TINYYOLOV2_RVV_POOL
static inline void rvv_max4_i8(const elem_t *a, const elem_t *b,
                               const elem_t *c, const elem_t *d,
                               elem_t *out, int elems) {
  uintptr_t vl = 0;
  uintptr_t offset = 0;
  uintptr_t remaining = (uintptr_t)elems;
  while (remaining != 0) {
    __asm__ volatile (
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v0, (%[a])\n\t"
      "vle8.v v1, (%[b])\n\t"
      "vmax.vv v0, v0, v1\n\t"
      "vle8.v v1, (%[c])\n\t"
      "vmax.vv v0, v0, v1\n\t"
      "vle8.v v1, (%[d])\n\t"
      "vmax.vv v0, v0, v1\n\t"
      "vse8.v v0, (%[out])\n\t"
      : [vl] "=&r" (vl)
      : [n] "r" (remaining),
        [a] "r" (a + offset), [b] "r" (b + offset),
        [c] "r" (c + offset), [d] "r" (d + offset),
        [out] "r" (out + offset)
      : "v0", "v1", "memory");
    if (vl == 0) break;
    offset += vl;
    remaining -= vl;
  }
}

static inline void rvv_max2_i8(const elem_t *a, const elem_t *b,
                               elem_t *out, int elems) {
  uintptr_t vl = 0;
  uintptr_t offset = 0;
  uintptr_t remaining = (uintptr_t)elems;
  while (remaining != 0) {
    __asm__ volatile (
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v0, (%[a])\n\t"
      "vle8.v v1, (%[b])\n\t"
      "vmax.vv v0, v0, v1\n\t"
      "vse8.v v0, (%[out])\n\t"
      : [vl] "=&r" (vl)
      : [n] "r" (remaining),
        [a] "r" (a + offset), [b] "r" (b + offset),
        [out] "r" (out + offset)
      : "v0", "v1", "memory");
    if (vl == 0) break;
    offset += vl;
    remaining -= vl;
  }
}

static inline void rvv_copy_i8(const elem_t *src, elem_t *dst, int elems) {
  uintptr_t vl = 0;
  uintptr_t offset = 0;
  uintptr_t remaining = (uintptr_t)elems;
  while (remaining != 0) {
    __asm__ volatile (
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v0, (%[src])\n\t"
      "vse8.v v0, (%[dst])\n\t"
      : [vl] "=&r" (vl)
      : [n] "r" (remaining),
        [src] "r" (src + offset), [dst] "r" (dst + offset)
      : "v0", "memory");
    if (vl == 0) break;
    offset += vl;
    remaining -= vl;
  }
}

static void maxpool2x2_stride1_same_upper_rvv(
    const elem_t *restrict src, elem_t *restrict dst,
    int dim, int channels) {
  const int row_stride = dim * channels;
  const int last = dim - 1;

  for (int row = 0; row < last; row++) {
    const elem_t *row0 = src + row * row_stride;
    const elem_t *row1 = row0 + row_stride;
    elem_t *out = dst + row * row_stride;

    for (int col = 0; col < last; col++) {
      const elem_t *p00 = row0 + col * channels;
      const elem_t *p01 = p00 + channels;
      const elem_t *p10 = row1 + col * channels;
      const elem_t *p11 = p10 + channels;
      rvv_max4_i8(p00, p01, p10, p11, out + col * channels, channels);
    }

    rvv_max2_i8(row0 + last * channels, row1 + last * channels,
                out + last * channels, channels);
  }

  const elem_t *last_row = src + last * row_stride;
  elem_t *last_out = dst + last * row_stride;
  for (int col = 0; col < last; col++) {
    rvv_max2_i8(last_row + col * channels,
                last_row + (col + 1) * channels,
                last_out + col * channels, channels);
  }
  rvv_copy_i8(last_row + last * channels,
              last_out + last * channels, channels);
}
#endif

static void maxpool2x2_stride1_same_upper(const elem_t *src, elem_t *dst, int dim, int channels) {
  for (int row = 0; row < dim; row++) {
    for (int col = 0; col < dim; col++) {
      for (int ch = 0; ch < channels; ch++) {
        int base = (row * dim + col) * channels + ch;
        elem_t max_value = src[base];
        if (col + 1 < dim) {
          elem_t value = src[(row * dim + col + 1) * channels + ch];
          if (value > max_value) max_value = value;
        }
        if (row + 1 < dim) {
          elem_t value = src[((row + 1) * dim + col) * channels + ch];
          if (value > max_value) max_value = value;
        }
        if (row + 1 < dim && col + 1 < dim) {
          elem_t value = src[((row + 1) * dim + col + 1) * channels + ch];
          if (value > max_value) max_value = value;
        }
        dst[base] = max_value;
      }
    }
  }
}

struct DetectionCandidate {
  int score_milli;
  int class_id;
  int row;
  int col;
  int anchor;
  int x;
  int y;
  int w;
  int h;
  int obj_raw;
  int cls_raw;
  int original_index;
};

struct DetectionSummary {
  struct DetectionCandidate top[10];
  struct DetectionCandidate best_by_class[TINYYOLOV2_CLASS_COUNT];
  struct DetectionCandidate candidates[TINYYOLOV2_GRID_SIZE *
                                       TINYYOLOV2_GRID_SIZE *
                                       TINYYOLOV2_ANCHOR_COUNT];
  int candidate_count;
};

struct DecodeCandidateLite {
  int base;
  int row;
  int col;
  int anchor;
  int obj_raw;
  int best_class;
  int best_class_raw;
  int obj_upper_milli;
  int original_index;
};

static struct DetectionSummary tinyyolov2_detection_summary;
static struct DecodeCandidateLite tinyyolov2_decode_candidates[
    TINYYOLOV2_GRID_SIZE * TINYYOLOV2_GRID_SIZE * TINYYOLOV2_ANCHOR_COUNT];
static int tinyyolov2_decode_order[
    TINYYOLOV2_GRID_SIZE * TINYYOLOV2_GRID_SIZE * TINYYOLOV2_ANCHOR_COUNT];
static int tinyyolov2_decode_counts[1001];
static int tinyyolov2_decode_offsets[1001];
static uint8_t tinyyolov2_candidate_suppressed[
    TINYYOLOV2_GRID_SIZE * TINYYOLOV2_GRID_SIZE * TINYYOLOV2_ANCHOR_COUNT];
static int tinyyolov2_diagnostics_enabled = 1;
static tinyyolov2_layer_begin_fn tinyyolov2_layer_begin_callback;
static tinyyolov2_layer_metrics_fn tinyyolov2_layer_metrics_callback;

static const float tinyyolov2_anchors[TINYYOLOV2_ANCHOR_COUNT][2] = {
  {1.08f, 1.19f},
  {3.42f, 4.41f},
  {6.63f, 11.38f},
  {9.42f, 5.11f},
  {16.62f, 10.52f},
};

static float exp_approx(float x) {
  if (x < -10.0f) return 0.000045f;
  if (x > 10.0f) return 22026.46f;

  const float ln2 = 0.69314718f;
  int n = (int)(x / ln2);
  if (x < 0.0f && ((float)n * ln2) > x) {
    n--;
  }
  float r = x - (float)n * ln2;
  float r2 = r * r;
  float poly = 1.0f + r + 0.5f * r2 + 0.16666667f * r2 * r + 0.04166667f * r2 * r2;

  if (n >= 0) {
    while (n-- > 0) poly *= 2.0f;
  } else {
    while (n++ < 0) poly *= 0.5f;
  }
  return poly;
}

static float sigmoid_approx(float x) {
  if (x <= -10.0f) return 0.0f;
  if (x >= 10.0f) return 1.0f;
  return 1.0f / (1.0f + exp_approx(-x));
}

static int round_positive_to_int(float x) {
  if (x <= 0.0f) return 0;
  return (int)(x + 0.5f);
}

static void insert_top_candidate(struct DetectionCandidate *top, int top_count,
                                 struct DetectionCandidate candidate) {
  for (int i = 0; i < top_count; i++) {
    if (candidate.score_milli > top[i].score_milli ||
        (candidate.score_milli == top[i].score_milli &&
         candidate.original_index < top[i].original_index)) {
      for (int j = top_count - 1; j > i; j--) {
        top[j] = top[j - 1];
      }
      top[i] = candidate;
      return;
    }
  }
}

static void compute_tinyyolov2_detections(const elem_t *output, struct DetectionSummary *summary) {
  const int top_count = 10;
  const int total_candidates = TINYYOLOV2_GRID_SIZE * TINYYOLOV2_GRID_SIZE *
                               TINYYOLOV2_ANCHOR_COUNT;
  summary->candidate_count = 0;
  for (int i = 0; i < top_count; i++) {
    summary->top[i].score_milli = -1;
    summary->top[i].original_index = total_candidates;
  }
  for (int i = 0; i < TINYYOLOV2_CLASS_COUNT; i++) {
    summary->best_by_class[i].score_milli = -1;
    summary->best_by_class[i].original_index = total_candidates;
  }

  const float final_scale = tinyyolov2_activation_scales[TINYYOLOV2_LAYER_COUNT - 1];
  for (int i = 0; i <= 1000; i++) {
    tinyyolov2_decode_counts[i] = 0;
  }

  int candidate_index = 0;
  for (int row = 0; row < TINYYOLOV2_GRID_SIZE; row++) {
    for (int col = 0; col < TINYYOLOV2_GRID_SIZE; col++) {
      for (int anchor = 0; anchor < TINYYOLOV2_ANCHOR_COUNT; anchor++) {
        int base = ((row * TINYYOLOV2_GRID_SIZE + col) * TINYYOLOV2_ANCHOR_COUNT + anchor) *
                   TINYYOLOV2_ATTRS_PER_ANCHOR;
        int best_class = 0;
        int best_class_raw = output[base + 5];
        for (int class_id = 1; class_id < TINYYOLOV2_CLASS_COUNT; class_id++) {
          int raw = output[base + 5 + class_id];
          if (raw > best_class_raw) {
            best_class_raw = raw;
            best_class = class_id;
          }
        }
        const int obj_raw = output[base + 4];
        const int obj_upper_milli =
            tinyyolov2_objectness_upper_milli_lut[(uint8_t)obj_raw];
        tinyyolov2_decode_candidates[candidate_index] = (struct DecodeCandidateLite){
          base,
          row,
          col,
          anchor,
          obj_raw,
          best_class,
          best_class_raw,
          obj_upper_milli,
          candidate_index,
        };
        tinyyolov2_decode_counts[obj_upper_milli]++;
        candidate_index++;
      }
    }
  }

  int offset = 0;
  for (int score = 1000; score >= 0; score--) {
    tinyyolov2_decode_offsets[score] = offset;
    offset += tinyyolov2_decode_counts[score];
  }
  for (int i = 0; i < total_candidates; i++) {
    const int upper = tinyyolov2_decode_candidates[i].obj_upper_milli;
    tinyyolov2_decode_order[tinyyolov2_decode_offsets[upper]++] = i;
  }

  for (int order_index = 0; order_index < total_candidates; order_index++) {
    const struct DecodeCandidateLite lite =
        tinyyolov2_decode_candidates[tinyyolov2_decode_order[order_index]];
    const int top_threshold = summary->top[top_count - 1].score_milli;
    const int class_threshold = summary->best_by_class[lite.best_class].score_milli;
    const int nms_threshold = TINYYOLOV2_SCORE_THRESHOLD_MILLI - 1;
    if (lite.obj_upper_milli <= top_threshold &&
        lite.obj_upper_milli <= class_threshold &&
        lite.obj_upper_milli <= nms_threshold) {
      continue;
    }

    float class_denom = 0.0f;
    for (int class_id = 0; class_id < TINYYOLOV2_CLASS_COUNT; class_id++) {
      float shifted = (float)(output[lite.base + 5 + class_id] -
                              lite.best_class_raw) * final_scale;
      class_denom += exp_approx(shifted);
    }
    const float objectness = sigmoid_approx((float)lite.obj_raw * final_scale);
    const float class_conf = class_denom > 0.0f ? 1.0f / class_denom : 0.0f;
    const int score_milli =
        round_positive_to_int(objectness * class_conf * 1000.0f);
    if (score_milli <= top_threshold && score_milli <= class_threshold &&
        score_milli < TINYYOLOV2_SCORE_THRESHOLD_MILLI) {
      continue;
    }

    const float tx = (float)output[lite.base + 0] * final_scale;
    const float ty = (float)output[lite.base + 1] * final_scale;
    const float tw = (float)output[lite.base + 2] * final_scale;
    const float th = (float)output[lite.base + 3] * final_scale;
    const float cx = ((float)lite.col + sigmoid_approx(tx)) * 32.0f;
    const float cy = ((float)lite.row + sigmoid_approx(ty)) * 32.0f;
    const float bw = tinyyolov2_anchors[lite.anchor][0] * exp_approx(tw) * 32.0f;
    const float bh = tinyyolov2_anchors[lite.anchor][1] * exp_approx(th) * 32.0f;

    struct DetectionCandidate candidate = {
      score_milli,
      lite.best_class,
      lite.row,
      lite.col,
      lite.anchor,
      round_positive_to_int(cx),
      round_positive_to_int(cy),
      round_positive_to_int(bw),
      round_positive_to_int(bh),
      lite.obj_raw,
      lite.best_class_raw,
      lite.original_index,
    };

    insert_top_candidate(summary->top, top_count, candidate);
    if (candidate.score_milli >= TINYYOLOV2_SCORE_THRESHOLD_MILLI) {
      summary->candidates[summary->candidate_count++] = candidate;
    }
    if (candidate.score_milli >
            summary->best_by_class[lite.best_class].score_milli ||
        (candidate.score_milli ==
             summary->best_by_class[lite.best_class].score_milli &&
         candidate.original_index <
             summary->best_by_class[lite.best_class].original_index)) {
      summary->best_by_class[lite.best_class] = candidate;
    }
  }
}

static void print_tinyyolov2_detections(const struct DetectionSummary *summary,
                                        const char *input_name) {
  const int top_count = 10;
  printf("\nTinyYOLOv2 decode candidates for %s\n", input_name);
  printf("Raw top candidates before score threshold and class-aware NMS.\n");
  for (int i = 0; i < top_count; i++) {
    const struct DetectionCandidate c = summary->top[i];
    if (c.score_milli < 0) continue;
    printf("#%d %s score_milli=%d bbox_cxcywh=(%d,%d,%d,%d) cell=(%d,%d) anchor=%d raw_obj=%d raw_cls=%d\n",
           i,
           tinyyolov2_voc_labels[c.class_id],
           c.score_milli,
           c.x,
           c.y,
           c.w,
           c.h,
           c.row,
           c.col,
           c.anchor,
           c.obj_raw,
           c.cls_raw);
  }

  printf("Expected-class best candidates:\n");
  for (int i = 0; i < 3; i++) {
    int class_id = tinyyolov2_expected_classes[i];
    struct DetectionCandidate c = summary->best_by_class[class_id];
    if (c.score_milli < 0) {
      printf("%s: not present\n", tinyyolov2_voc_labels[class_id]);
    } else {
      printf("%s best score_milli=%d bbox_cxcywh=(%d,%d,%d,%d) cell=(%d,%d) anchor=%d raw_obj=%d raw_cls=%d\n",
             tinyyolov2_voc_labels[class_id],
             c.score_milli,
             c.x,
             c.y,
             c.w,
             c.h,
             c.row,
             c.col,
             c.anchor,
             c.obj_raw,
             c.cls_raw);
    }
  }
}

static int clamp_coordinate(int value, int limit) {
  if (value < 0) return 0;
  if (value > limit) return limit;
  return value;
}

static struct tinyyolov2_detection candidate_to_detection(
    const struct DetectionCandidate *candidate) {
  int x_min = candidate->x - candidate->w / 2;
  int y_min = candidate->y - candidate->h / 2;
  int x_max = x_min + candidate->w;
  int y_max = y_min + candidate->h;

  struct tinyyolov2_detection detection = {
    candidate->score_milli,
    candidate->class_id,
    clamp_coordinate(x_min, TINYYOLOV2_INPUT_WIDTH),
    clamp_coordinate(y_min, TINYYOLOV2_INPUT_HEIGHT),
    clamp_coordinate(x_max, TINYYOLOV2_INPUT_WIDTH),
    clamp_coordinate(y_max, TINYYOLOV2_INPUT_HEIGHT),
  };
  return detection;
}

static int detections_overlap_for_nms(
    const struct tinyyolov2_detection *a,
    const struct tinyyolov2_detection *b) {
  int intersection_x_min = a->x_min > b->x_min ? a->x_min : b->x_min;
  int intersection_y_min = a->y_min > b->y_min ? a->y_min : b->y_min;
  int intersection_x_max = a->x_max < b->x_max ? a->x_max : b->x_max;
  int intersection_y_max = a->y_max < b->y_max ? a->y_max : b->y_max;
  int intersection_w = intersection_x_max - intersection_x_min;
  int intersection_h = intersection_y_max - intersection_y_min;
  if (intersection_w <= 0 || intersection_h <= 0) return 0;

  int64_t intersection = (int64_t)intersection_w * intersection_h;
  int64_t area_a = (int64_t)(a->x_max - a->x_min) *
                   (a->y_max - a->y_min);
  int64_t area_b = (int64_t)(b->x_max - b->x_min) *
                   (b->y_max - b->y_min);
  int64_t union_area = area_a + area_b - intersection;
  return union_area > 0 &&
         intersection * 1000 >= union_area * TINYYOLOV2_NMS_IOU_MILLI;
}

static void select_tinyyolov2_detections(
    const struct DetectionSummary *summary,
    struct tinyyolov2_result *result) {
  result->count = 0;
  for (int i = 0; i < summary->candidate_count; i++) {
    tinyyolov2_candidate_suppressed[i] = 0;
  }

  while (result->count < TINYYOLOV2_MAX_DETECTIONS) {
    int best_index = -1;
    for (int i = 0; i < summary->candidate_count; i++) {
      if (!tinyyolov2_candidate_suppressed[i] &&
          summary->candidates[i].score_milli >=
              TINYYOLOV2_SCORE_THRESHOLD_MILLI &&
          (best_index < 0 || summary->candidates[i].score_milli >
                               summary->candidates[best_index].score_milli)) {
        best_index = i;
      }
    }
    if (best_index < 0) break;

    tinyyolov2_candidate_suppressed[best_index] = 1;
    struct tinyyolov2_detection selected =
        candidate_to_detection(&summary->candidates[best_index]);
    if (selected.x_min >= selected.x_max || selected.y_min >= selected.y_max)
      continue;

    result->detections[result->count++] = selected;
    for (int i = 0; i < summary->candidate_count; i++) {
      if (tinyyolov2_candidate_suppressed[i] ||
          summary->candidates[i].class_id != selected.class_id)
        continue;
      struct tinyyolov2_detection candidate =
          candidate_to_detection(&summary->candidates[i]);
      if (detections_overlap_for_nms(&selected, &candidate))
        tinyyolov2_candidate_suppressed[i] = 1;
    }
  }
}

static void print_selected_detections(const struct tinyyolov2_result *result) {
  printf("Final detections: count=%d score_threshold_milli=%d nms_iou_milli=%d\n",
         result->count, TINYYOLOV2_SCORE_THRESHOLD_MILLI,
         TINYYOLOV2_NMS_IOU_MILLI);
  for (int i = 0; i < result->count; i++) {
    const struct tinyyolov2_detection *detection = &result->detections[i];
    printf("final #%d %s class_id=%d score_milli=%d bbox_xyxy=(%d,%d,%d,%d)\n",
           i, tinyyolov2_class_name(detection->class_id),
           detection->class_id, detection->score_milli,
           detection->x_min, detection->y_min,
           detection->x_max, detection->y_max);
  }
}

const char *tinyyolov2_class_name(int class_id) {
  if (class_id < 0 || class_id >= TINYYOLOV2_CLASS_COUNT) return "unknown";
  return tinyyolov2_voc_labels[class_id];
}

void tinyyolov2_set_diagnostics(int enabled) {
  tinyyolov2_diagnostics_enabled = enabled != 0;
}

void tinyyolov2_set_layer_begin_callback(
    tinyyolov2_layer_begin_fn callback) {
  tinyyolov2_layer_begin_callback = callback;
}

void tinyyolov2_set_layer_metrics_callback(
    tinyyolov2_layer_metrics_fn callback) {
  tinyyolov2_layer_metrics_callback = callback;
}

#if TINYYOLOV2_PRINT_STATS
struct OutputStats {
  int32_t checksum;
  int nonzero_count;
  int best_idx;
  elem_t best_value;
};

static struct OutputStats compute_output_stats(const elem_t *output, int elems) {
  struct OutputStats stats = {0, 0, 0, 0};
  int best_abs = 0;

  for (int i = 0; i < elems; i++) {
    int value = output[i];
    int abs_value = value < 0 ? -value : value;
    stats.checksum += value;
    stats.nonzero_count += value != 0;
    if (abs_value > best_abs) {
      best_abs = abs_value;
      stats.best_idx = i;
      stats.best_value = output[i];
    }
  }
  return stats;
}

static void print_output_stats(const char *name, struct OutputStats stats, int elems) {
  printf("%s stats checksum: %d nonzero: %d / %d top_abs_index: %d value: %d\n",
         name, stats.checksum, stats.nonzero_count, elems, stats.best_idx, stats.best_value);
}
#endif

static int run_tinyyolov2_conv(int layer_index,
                               const struct TinyYoloLayerDesc *layer,
                               const elem_t *input,
                               elem_t *output) {
  const struct ConvParams *p = layer->params;

#if TINYYOLOV2_LOOPCONV5
  if (layer_index == 5) {
    tiled_conv(
      p->batch_size, p->in_row_dim, p->in_col_dim, p->in_channels,
      p->out_channels, p->out_row_dim, p->out_col_dim,
      p->stride, 1, 1, p->padding, p->kernel_size,
      p->in_channels, p->out_channels, p->out_channels,
      false, false, false, false, false,
      1, TINYYOLOV2_C5_POROWS, TINYYOLOV2_C5_POCOLS,
      TINYYOLOV2_C5_POCHS, 3, 3, TINYYOLOV2_C5_KCHS,
      input, layer->weights, layer->bias, output,
      layer->act, p->output_scale,
      p->pool_size, p->pool_stride, p->pool_padding,
      WS);
    return 1;
  }
#endif

#if TINYYOLOV2_LOOPCONV67
  if (layer_index == 6 || layer_index == 7) {
    const int porows = layer_index == 6 ?
        TINYYOLOV2_C6_POROWS : TINYYOLOV2_C7_POROWS;
    const int pocols = layer_index == 6 ?
        TINYYOLOV2_C6_POCOLS : TINYYOLOV2_C7_POCOLS;
    const int pochs = layer_index == 6 ?
        TINYYOLOV2_C6_POCHS : TINYYOLOV2_C7_POCHS;
    const int kchs = layer_index == 6 ?
        TINYYOLOV2_C6_KCHS : TINYYOLOV2_C7_KCHS;
    tiled_conv(
      p->batch_size, p->in_row_dim, p->in_col_dim, p->in_channels,
      p->out_channels, p->out_row_dim, p->out_col_dim,
      p->stride, 1, 1, p->padding, p->kernel_size,
      p->in_channels, p->out_channels, p->out_channels,
      false, false, false, false, false,
      1, porows, pocols, pochs, 3, 3, kchs,
      input, layer->weights, layer->bias, output,
      layer->act, p->output_scale,
      p->pool_size, p->pool_stride, p->pool_padding,
      WS);
    return 1;
  }
#endif

#if TINYYOLOV2_CONV8_MATMUL
  if (layer_index == 8) {
    tiled_matmul_auto(
      p->I, p->J, p->K,
      input, layer->weights, (const void *)layer->bias, output,
      p->K, p->J, p->J, p->J,
      MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      layer->act, p->output_scale, 0,
      true,
      false, false, false, false,
      0,
      WS);
    return 1;
  }
#endif

  tiled_conv_auto(
    p->batch_size, p->in_row_dim, p->in_col_dim, p->in_channels,
    p->out_channels, p->out_row_dim, p->out_col_dim,
    p->stride, 1, 1, p->padding, p->kernel_size,
    false, false, false, false, false,
    input, layer->weights, layer->bias, output,
    layer->act, p->output_scale,
    p->pool_size, p->pool_stride, p->pool_padding,
    WS);
  return 1;
}

#if TINYYOLOV2_GEMMINI_POOL
static inline uint64_t read_gemmini1_busy(void) {
  uint64_t value;
  __asm__ volatile ("csrr %0, 0x7c3" : "=r" (value) : : "memory");
  return value & 1u;
}

uint64_t tinyyolov2_worker_busy(unsigned worker_id) {
  if (worker_id == 0u)
    return read_gemmini0_busy();
  if (worker_id == 1u)
    return read_gemmini1_busy();
  return 0u;
}

static elem_t *worker_other_buffer(
    const struct tinyyolov2_worker_context *worker, const elem_t *buffer) {
  return buffer == worker->buf0 ? worker->buf1 : worker->buf0;
}

static void worker_submit_layer(struct tinyyolov2_worker_context *worker) {
  const struct TinyYoloLayerDesc *layer =
      &tinyyolov2_layers[worker->layer_index];

  gemmini_pool_active_worker = worker->worker_id;
  run_tinyyolov2_conv(worker->layer_index, layer,
                      worker->input, worker->output);
  worker->poll_armed = 0;
  worker->state = TINYYOLOV2_WORKER_WAIT_LAYER;
}

void tinyyolov2_worker_pool_init(void) {
#if TINYYOLOV2_RVV_POOL
  enable_vector_state();
#endif
  /* Flush each Gemmini once at pool startup; per-frame flushes serialize the
     pipeline and are unnecessary after the worker is initialized. */
  for (unsigned worker = 0; worker < TINYYOLOV2_WORKER_COUNT; ++worker) {
    gemmini_pool_active_worker = worker;
    counter_configure(0, LOAD_ACTIVE_CYCLE);
    counter_configure(1, EXE_ACTIVE_CYCLE);
    counter_configure(2, STORE_ACTIVE_CYCLE);
    gemmini_flush(0);
  }
  tinyyolov2_workers[0] = (struct tinyyolov2_worker_context) {
    .state = TINYYOLOV2_WORKER_IDLE,
    .worker_id = 0u,
    .buf0 = tinyyolov2_buf0,
    .buf1 = tinyyolov2_buf1,
  };
#if TINYYOLOV2_WORKER_COUNT > 1
  tinyyolov2_workers[1] = (struct tinyyolov2_worker_context) {
    .state = TINYYOLOV2_WORKER_IDLE,
    .worker_id = 1u,
    .buf0 = tinyyolov2_worker1_buf0,
    .buf1 = tinyyolov2_worker1_buf1,
  };
#endif
}

int tinyyolov2_worker_is_idle(unsigned worker_id) {
  return worker_id < TINYYOLOV2_WORKER_COUNT &&
      tinyyolov2_workers[worker_id].state == TINYYOLOV2_WORKER_IDLE;
}

int tinyyolov2_worker_start(unsigned worker_id, const int8_t *input,
                            const char *input_name) {
  struct tinyyolov2_worker_context *worker;

  if (worker_id >= TINYYOLOV2_WORKER_COUNT || input == NULL ||
      input_name == NULL || !tinyyolov2_worker_is_idle(worker_id))
    return 0;

  worker = &tinyyolov2_workers[worker_id];
  worker->layer_index = 0;
  worker->input_name = input_name;
  worker->input = (const elem_t *)input;
  worker->output = worker->buf0;

  gemmini_pool_active_worker = worker_id;
  counter_reset();
  worker_submit_layer(worker);
  return 1;
}

int tinyyolov2_worker_poll(unsigned worker_id,
                           struct tinyyolov2_result *result,
                           int collect_result) {
  struct tinyyolov2_worker_context *worker;
  const struct TinyYoloLayerDesc *layer;

  if (worker_id >= TINYYOLOV2_WORKER_COUNT || result == NULL)
    return TINYYOLOV2_WORKER_ERROR;
  worker = &tinyyolov2_workers[worker_id];
  if (worker->state != TINYYOLOV2_WORKER_WAIT_LAYER)
    return TINYYOLOV2_WORKER_ERROR;

  /* Avoid observing the one-cycle-old CSR value immediately after submit. */
  if (!worker->poll_armed) {
    worker->poll_armed = 1;
    return TINYYOLOV2_WORKER_RUNNING;
  }
  if (tinyyolov2_worker_busy(worker_id))
    return TINYYOLOV2_WORKER_RUNNING;

  /* Snapshot Gemmini activity accumulated by all layers of this job. */
  gemmini_pool_active_worker = worker_id;
  tinyyolov2_worker_last_load[worker_id] = counter_read(0);
  tinyyolov2_worker_last_exec[worker_id] = counter_read(1);
  tinyyolov2_worker_last_store[worker_id] = counter_read(2);

  layer = &tinyyolov2_layers[worker->layer_index];
  if (layer->leaky)
    apply_leaky_relu_int8(worker->output, layer->pooled_elems);

  if (layer->post_pool_2x2_stride1_same_upper) {
    elem_t *pool_output = worker_other_buffer(worker, worker->output);
#if TINYYOLOV2_RVV_POOL
    maxpool2x2_stride1_same_upper_rvv(
        worker->output, pool_output, layer->out_dim, layer->out_channels);
#else
    maxpool2x2_stride1_same_upper(
        worker->output, pool_output, layer->out_dim, layer->out_channels);
#endif
    worker->output = pool_output;
  }

  worker->input = worker->output;
  worker->layer_index++;
  if (worker->layer_index < TINYYOLOV2_LAYER_COUNT) {
    worker->output = worker_other_buffer(worker, worker->output);
    worker_submit_layer(worker);
    return TINYYOLOV2_WORKER_RUNNING;
  }

  if (collect_result) {
    compute_tinyyolov2_detections(worker->input,
                                  &tinyyolov2_detection_summary);
    select_tinyyolov2_detections(&tinyyolov2_detection_summary, result);
  } else {
    result->count = 0;
  }
  worker->state = TINYYOLOV2_WORKER_IDLE;
  return TINYYOLOV2_WORKER_DONE;
}
#else
void tinyyolov2_worker_pool_init(void) {}
int tinyyolov2_worker_is_idle(unsigned worker_id) {
  (void)worker_id;
  return 0;
}
int tinyyolov2_worker_start(unsigned worker_id, const int8_t *input,
                            const char *input_name) {
  (void)worker_id;
  (void)input;
  (void)input_name;
  return 0;
}
int tinyyolov2_worker_poll(unsigned worker_id,
                           struct tinyyolov2_result *result,
                           int collect_result) {
  (void)worker_id;
  (void)result;
  (void)collect_result;
  return TINYYOLOV2_WORKER_ERROR;
}
uint64_t tinyyolov2_worker_busy(unsigned worker_id) {
  (void)worker_id;
  return 0u;
}
#endif

static uint64_t cycles_to_us(uint64_t cycles) {
  return (cycles + TINYYOLOV2_CYCLES_PER_US / 2) / TINYYOLOV2_CYCLES_PER_US;
}

static void print_time_summary(const char *name, uint64_t cycles) {
  uint64_t us = cycles_to_us(cycles);
  uint64_t fps_x100 = cycles == 0 ? 0 : (TINYYOLOV2_CLOCK_HZ * 100ULL) / cycles;
  printf("%s cycles: %lu\n", name, cycles);
  printf("%s time: %lu.%03lu ms @ 100 MHz\n", name, us / 1000UL, us % 1000UL);
  printf("%s throughput: %lu.%02lu FPS\n", name, fps_x100 / 100UL, fps_x100 % 100UL);
}

int tinyyolov2_run_detect(const int8_t *input_data, const char *input_name,
                          struct tinyyolov2_result *result) {
  if (input_data == NULL || input_name == NULL) {
    printf("FAIL: TinyYOLOv2 received an invalid runtime input\n");
    return 0;
  }

  if (tinyyolov2_diagnostics_enabled) {
    printf("Input: 1x416x416x3 NHWC, output: 1x13x13x125 NHWC\n");
    printf("Image: %s\n", input_name);
#if TINYYOLOV2_HW_LEAKY
    printf("Note: Gemmini hardware LeakyReLU, RVV SAME_UPPER pool, optimized conv5/6/7/8.\n");
#else
    printf("Note: legacy SoC compatibility mode uses CPU int8 LeakyReLU and scalar SAME_UPPER pool.\n");
#endif
  }

#if TINYYOLOV2_RVV_POOL
  enable_vector_state();
#endif
  gemmini_flush(0);

  counter_configure(0, LOAD_ACTIVE_CYCLE);
  counter_configure(1, EXE_ACTIVE_CYCLE);
  counter_configure(2, STORE_ACTIVE_CYCLE);

  const elem_t *input = (const elem_t *)input_data;
  elem_t *output = tinyyolov2_buf0;

  /* The first tensor is written by the non-coherent preprocess DMA. Later
   * layer inputs have already crossed a Gemmini/CPU ownership boundary. */
  tinyyolov2_cache_range_flush(
      input, (size_t)TINYYOLOV2_INPUT_ELEMS * sizeof(elem_t));
  uint64_t total_cycles = 0;
  uint64_t total_conv_cycles = 0;
  uint64_t total_post_cycles = 0;
  uint64_t total_leaky_cycles = 0;
  uint64_t total_pool_cycles = 0;
  uint64_t total_stats_cycles = 0;
  uint64_t total_load_cycles = 0;
  uint64_t total_exec_cycles = 0;
  uint64_t total_store_cycles = 0;

  for (int i = 0; i < TINYYOLOV2_LAYER_COUNT; i++) {
    const struct TinyYoloLayerDesc *layer = &tinyyolov2_layers[i];
    const struct ConvParams *p = layer->params;

    if (tinyyolov2_layer_begin_callback != NULL)
      tinyyolov2_layer_begin_callback((unsigned)i,
          (uint32_t)p->in_row_dim, (uint32_t)p->in_col_dim,
          (uint32_t)p->in_channels, (uint32_t)p->out_row_dim,
          (uint32_t)p->out_col_dim, (uint32_t)p->out_channels);
    /* The destination may contain dirty CPU postprocessing data from an
     * earlier ping-pong use, so release it before Gemmini writes it. */
    tinyyolov2_cache_range_flush(
        output, (size_t)layer->pooled_elems * sizeof(elem_t));
    counter_reset();
    uint64_t start = read_cycle();
    if (!run_tinyyolov2_conv(i, layer, input, output))
      return 0;
    /* Let the native LoopConv/tiled-matmul schedule run without CPU
     * intervention, then wait once at the layer boundary before touching
     * its output. */
    gemmini_fence();
    tinyyolov2_cache_range_flush(
        output, (size_t)layer->pooled_elems * sizeof(elem_t));
    uint64_t conv_end = read_cycle();
    uint64_t conv_cycles = conv_end - start;
    uint32_t load_active = counter_read(0);
    uint32_t exec_active = counter_read(1);
    uint32_t store_active = counter_read(2);
    uint64_t macs = (uint64_t)p->batch_size * (uint64_t)p->out_row_dim *
        (uint64_t)p->out_col_dim * (uint64_t)p->out_channels *
        (uint64_t)p->kernel_size * (uint64_t)p->kernel_size *
        (uint64_t)p->in_channels;
    if (i == 8 && TINYYOLOV2_CONV8_MATMUL)
      macs = (uint64_t)p->I * (uint64_t)p->J * (uint64_t)p->K;
    if (tinyyolov2_layer_metrics_callback != NULL)
      tinyyolov2_layer_metrics_callback((unsigned)i, macs, conv_cycles,
          load_active, exec_active, store_active,
          (uint32_t)layer->pooled_elems);
    uint64_t leaky_cycles = 0;
    uint64_t pool_cycles = 0;
    uint64_t stats_cycles = 0;

    if (layer->leaky) {
      uint64_t leaky_start = read_cycle();
      apply_leaky_relu_int8(output, layer->pooled_elems);
      tinyyolov2_cache_range_flush(
          output, (size_t)layer->pooled_elems * sizeof(elem_t));
      leaky_cycles = read_cycle() - leaky_start;
    }
    if (layer->post_pool_2x2_stride1_same_upper) {
      uint64_t pool_start = read_cycle();
      elem_t *pool_output = (output == tinyyolov2_buf0) ? tinyyolov2_buf1 : tinyyolov2_buf0;
#if TINYYOLOV2_RVV_POOL
      maxpool2x2_stride1_same_upper_rvv(
          output, pool_output, layer->out_dim, layer->out_channels);
#else
      maxpool2x2_stride1_same_upper(output, pool_output, layer->out_dim, layer->out_channels);
#endif
      output = pool_output;
      tinyyolov2_cache_range_flush(
          output, (size_t)layer->pooled_elems * sizeof(elem_t));
      pool_cycles = read_cycle() - pool_start;
    }
    uint64_t end = read_cycle();
    uint64_t layer_cycles = end - start;
    uint64_t post_cycles = layer_cycles - conv_cycles;

#if TINYYOLOV2_PRINT_STATS
    struct OutputStats layer_stats = {0, 0, 0, 0};
    if (tinyyolov2_diagnostics_enabled) {
      uint64_t stats_start = read_cycle();
      layer_stats = compute_output_stats(output, layer->pooled_elems);
      stats_cycles = read_cycle() - stats_start;
    }
#endif

    total_cycles += layer_cycles;
    total_conv_cycles += conv_cycles;
    total_load_cycles += load_active;
    total_exec_cycles += exec_active;
    total_store_cycles += store_active;
    total_post_cycles += post_cycles;
    total_leaky_cycles += leaky_cycles;
    total_pool_cycles += pool_cycles;
    total_stats_cycles += stats_cycles;

#if TINYYOLOV2_PRINT_LAYER_TIMING
    if (tinyyolov2_diagnostics_enabled)
      printf("%s cycles: %lu conv_cycles: %lu load: %u exec: %u store: %u leaky_cycles: %lu pool_cycles: %lu post_cycles: %lu stats_cycles: %lu time_us: %lu output_elems: %d\n",
             layer->name, layer_cycles, conv_cycles, load_active, exec_active, store_active, leaky_cycles, pool_cycles, post_cycles, stats_cycles, cycles_to_us(layer_cycles), layer->pooled_elems);
#endif
#if TINYYOLOV2_PRINT_STATS
    if (tinyyolov2_diagnostics_enabled)
      print_output_stats(layer->name, layer_stats, layer->pooled_elems);
#endif

    input = output;
    output = (output == tinyyolov2_buf0) ? tinyyolov2_buf1 : tinyyolov2_buf0;
  }

  const elem_t *final_output = input;
  tinyyolov2_cache_range_flush(
      final_output, (size_t)TINYYOLOV2_OUTPUT_ELEMS * sizeof(elem_t));
#if TINYYOLOV2_PRINT_STATS
  uint64_t final_stats_start = read_cycle();
  struct OutputStats final_stats = compute_output_stats(final_output, TINYYOLOV2_OUTPUT_ELEMS);
  uint64_t final_stats_cycles = read_cycle() - final_stats_start;
  total_stats_cycles += final_stats_cycles;
#endif
  if (tinyyolov2_diagnostics_enabled) {
    print_time_summary("TinyYOLOv2 inference", total_cycles);
    printf("TinyYOLOv2 conv cycles: %lu\n", total_conv_cycles);
    printf("TinyYOLOv2 load cycles: %lu\n", total_load_cycles);
    printf("TinyYOLOv2 exec cycles: %lu\n", total_exec_cycles);
    printf("TinyYOLOv2 store cycles: %lu\n", total_store_cycles);
    printf("TinyYOLOv2 post cycles: %lu\n", total_post_cycles);
    printf("TinyYOLOv2 leaky cycles: %lu\n", total_leaky_cycles);
    printf("TinyYOLOv2 pool cycles: %lu\n", total_pool_cycles);
    uint64_t t_other = total_cycles - total_conv_cycles - total_leaky_cycles - total_pool_cycles - total_stats_cycles;
    printf("T_pool: %lu\n", total_pool_cycles);
    printf("T_stats: %lu\n", total_stats_cycles);
    printf("T_other: %lu\n", t_other);
  }
#if TINYYOLOV2_PRINT_STATS
  if (tinyyolov2_diagnostics_enabled) {
    printf("TinyYOLOv2 stats cycles: %lu\n", total_stats_cycles);
    printf("Output checksum: %d\n", final_stats.checksum);
    printf("Output nonzero count: %d / %d\n", final_stats.nonzero_count, TINYYOLOV2_OUTPUT_ELEMS);
    printf("Top abs output index: %d value: %d\n", final_stats.best_idx, final_stats.best_value);
  }
#endif
  struct tinyyolov2_result local_result;
  struct tinyyolov2_result *selected = result != NULL ? result : &local_result;
  uint64_t decode_start = read_cycle();
  compute_tinyyolov2_detections(final_output, &tinyyolov2_detection_summary);
  uint64_t decode_candidate_cycles = read_cycle() - decode_start;
  uint64_t nms_start = read_cycle();
  select_tinyyolov2_detections(&tinyyolov2_detection_summary, selected);
  uint64_t nms_cycles = read_cycle() - nms_start;
  uint64_t decode_compute_cycles = decode_candidate_cycles + nms_cycles;
  if (tinyyolov2_diagnostics_enabled) {
    print_tinyyolov2_detections(&tinyyolov2_detection_summary, input_name);
    print_selected_detections(selected);
    printf("T_decode: %lu time_us: %lu\n", decode_candidate_cycles, cycles_to_us(decode_candidate_cycles));
    printf("T_nms: %lu time_us: %lu\n", nms_cycles, cycles_to_us(nms_cycles));
  }
#if TINYYOLOV2_PRINT_STATS
  if (final_stats.nonzero_count == 0) {
    printf("FAIL: final output is all zeros\n");
    return 0;
  }
#endif
  return 1;
}

int tinyyolov2_run(const int8_t *input_data, const char *input_name) {
  return tinyyolov2_run_detect(input_data, input_name, NULL);
}

int tinyyolov2_run_builtin_dog(void) {
  struct tinyyolov2_result result;
  tinyyolov2_set_diagnostics(1);
  if (!tinyyolov2_run_detect((const int8_t *)tinyyolov2_image_input,
                             TINYYOLOV2_IMAGE_NAME, &result))
    return 0;

  for (int i = 0; i < result.count; i++) {
    if (result.detections[i].class_id == 11) {
      printf("builtin dog detected score_milli=%d bbox_xyxy=(%d,%d,%d,%d)\n",
             result.detections[i].score_milli,
             result.detections[i].x_min, result.detections[i].y_min,
             result.detections[i].x_max, result.detections[i].y_max);
      return 1;
    }
  }

  printf("builtin dog was not present in %d final detections\n", result.count);
  return 0;
}

#ifndef TINYYOLOV2_NO_STANDALONE_MAIN
int main(void) {
  printf("TinyYOLOv2 baremetal UART image decode test\n");
  printf("Expected coarse labels: %s\n", tinyyolov2_expected_summary);
  int ok = tinyyolov2_run_builtin_dog();
  printf(ok ? "RESULT: PASS - embedded dog.jpg detected as dog\n" :
              "RESULT: FAIL - embedded dog.jpg dog detection missing\n");
  exit(ok ? 0 : 1);
  return 0;
}
#endif
