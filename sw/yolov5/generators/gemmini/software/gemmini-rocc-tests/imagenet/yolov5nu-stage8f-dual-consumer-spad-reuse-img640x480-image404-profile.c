#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "include/gemmini.h"
#include "include/gemmini_nn.h"
#include "include/yolov5nu_silu_opencv_rvv.h"
#include "include/yolov5nu_silu_lut_rvv.h"
#include "include/yolov5nu_stage3_rvv.h"
#include "include/yolov5nu_stage4_rvv.h"
#include "yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image404-profile_params.h"

#ifndef YOLOV5NU_LAYER_STATS
#define YOLOV5NU_LAYER_STATS 0
#endif

#ifndef YOLOV5NU_FINAL_TENSOR_STATS
#define YOLOV5NU_FINAL_TENSOR_STATS 1
#endif

#ifndef YOLOV5NU_PROFILE
#define YOLOV5NU_PROFILE 0
#endif

#if defined(YOLOV5NU_MEMORY_STAGE_5A) || defined(YOLOV5NU_MEMORY_STAGE_5B) ||     defined(YOLOV5NU_MEMORY_STAGE_5C) || defined(YOLOV5NU_MEMORY_STAGE_5D)
#if YOLOV5NU_LAYER_STATS && !defined(YOLOV5NU_DIAGNOSTIC_LAYER_STATS)
#error "Stage 5 arena planning requires YOLOV5NU_LAYER_STATS=0"
#endif
#endif

enum YoloProfileKind {
  PROFILE_CONV_TOTAL,
  PROFILE_SIGMOID,
  PROFILE_MUL,
  PROFILE_SILU_FUSED_LUT,
  PROFILE_ADD,
  PROFILE_CONCAT,
  PROFILE_MAXPOOL,
  PROFILE_RESIZE,
  PROFILE_RESHAPE,
  PROFILE_TRANSPOSE,
  PROFILE_SOFTMAX,
  PROFILE_HEAD_CLASS,
  PROFILE_HEAD_DFL,
  PROFILE_CONV_IN_LAYOUT,
  PROFILE_CONV_GEMMINI,
  PROFILE_CONV_OUT_LAYOUT,
  PROFILE_DECODE,
  PROFILE_NMS,
  PROFILE_KIND_COUNT
};

struct YoloProfileRecord {
  int kind;
  const char *kind_name;
  const char *name;
  uint64_t cycles;
};

#if YOLOV5NU_PROFILE
#define YOLOV5NU_PROFILE_MAX_RECORDS 512
static struct YoloProfileRecord yolo_profile_records[YOLOV5NU_PROFILE_MAX_RECORDS];
static int yolo_profile_record_count;

static inline void yolo_profile_reset(void) {
  yolo_profile_record_count = 0;
}

static inline uint64_t yolo_profile_clock(void) {
  uint64_t value;
  asm volatile("rdcycle %0" : "=r"(value));
  return value;
}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {
  (void)kind; (void)kind_name; (void)name;
  return yolo_profile_clock();
}

static void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {
  if (yolo_profile_record_count < YOLOV5NU_PROFILE_MAX_RECORDS) {
    yolo_profile_records[yolo_profile_record_count++] = (struct YoloProfileRecord){
      kind, kind_name, name, cycles
    };
  }
}
#else
static inline void yolo_profile_reset(void) {}

static inline uint64_t yolo_profile_clock(void) {
  return 0;
}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {
  (void)kind; (void)kind_name; (void)name;
  return 0;
}
static inline void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {
  (void)kind; (void)kind_name; (void)name; (void)cycles;
}
#endif

static uint64_t head_class_requant_cycles;
static uint64_t head_class_sigmoid_cycles;
static uint64_t head_dfl_requant_cycles;
static uint64_t head_dfl_core_cycles;
static int head_dfl_rvv_enabled;
static int head_dfl_batch_enabled;
static int head_dfl_ordered_sum_enabled;
static int head_dfl_gather_enabled;
static int head_dfl_elementwise_sum_enabled;
static int head_dfl_unordered_sum_enabled;
static int head_dfl_interleaved_sum_enabled;
static int head_dfl_sparse_enabled;
static int head_dfl_candidate_count;
static uint64_t head_dfl_candidate_cycles;
static uint64_t head_class_candidate_cycles;
static int head_dfl_candidate_rvv_enabled;

static elem_t activation_arena[2217600] row_align(1);
#define tensor_3 (activation_arena + 0)
#define tensor_6 (activation_arena + 1228800)
#define tensor_11 (activation_arena + 0)
#define tensor_12 (activation_arena + 307200)
#define tensor_15 (activation_arena + 614400)
#define tensor_18 (activation_arena + 921600)
#define tensor_19 (activation_arena + 0)
#define tensor_23 (activation_arena + 614400)
#define tensor_26 (activation_arena + 0)
#define tensor_31 (activation_arena + 307200)
#define tensor_32 (activation_arena + 460800)
#define tensor_35 (activation_arena + 0)
#define tensor_38 (activation_arena + 153600)
#define tensor_39 (activation_arena + 307200)
#define tensor_42 (activation_arena + 0)
#define tensor_45 (activation_arena + 153600)
#define tensor_46 (activation_arena + 307200)
#define tensor_50 (activation_arena + 0)
#define tensor_53 (activation_arena + 307200)
#define tensor_58 (activation_arena + 460800)
#define tensor_59 (activation_arena + 537600)
#define tensor_62 (activation_arena + 307200)
#define tensor_65 (activation_arena + 384000)
#define tensor_66 (activation_arena + 460800)
#define tensor_69 (activation_arena + 307200)
#define tensor_72 (activation_arena + 384000)
#define tensor_73 (activation_arena + 460800)
#define tensor_76 (activation_arena + 307200)
#define tensor_79 (activation_arena + 384000)
#define tensor_80 (activation_arena + 460800)
#define tensor_84 (activation_arena + 307200)
#define tensor_87 (activation_arena + 460800)
#define tensor_92 (activation_arena + 537600)
#define tensor_93 (activation_arena + 576000)
#define tensor_96 (activation_arena + 460800)
#define tensor_99 (activation_arena + 499200)
#define tensor_100 (activation_arena + 537600)
#define tensor_104 (activation_arena + 460800)
#define tensor_107 (activation_arena + 537600)
#define tensor_108 (activation_arena + 460800)
#define tensor_109 (activation_arena + 499200)
#define tensor_110 (activation_arena + 576000)
#define tensor_114 (activation_arena + 614400)
#define tensor_117 (activation_arena + 460800)
#define tensor_118 (activation_arena + 499200)
#define tensor_124 (activation_arena + 652800)
#define tensor_125 (activation_arena + 729600)
#define tensor_128 (activation_arena + 307200)
#define tensor_131 (activation_arena + 384000)
#define tensor_135 (activation_arena + 499200)
#define tensor_138 (activation_arena + 307200)
#define tensor_139 (activation_arena + 499200)
#define tensor_145 (activation_arena + 806400)
#define tensor_146 (activation_arena + 960000)
#define tensor_149 (activation_arena + 0)
#define tensor_152 (activation_arena + 153600)
#define tensor_156 (activation_arena + 499200)
#define tensor_163 (activation_arena + 384000)
#define tensor_164 (activation_arena + 0)
#define tensor_165 (activation_arena + 806400)
#define tensor_175 (activation_arena + 499200)
#define tensor_176 (activation_arena + 1190400)
#define tensor_177 (activation_arena + 0)
#define tensor_178 (activation_arena + 76800)
#define tensor_179 (activation_arena + 153600)
#define tensor_180 (activation_arena + 499200)
#define tensor_185 (activation_arena + 883200)
#define tensor_188 (activation_arena + 0)
#define tensor_192 (activation_arena + 883200)
#define tensor_199 (activation_arena + 0)
#define tensor_200 (activation_arena + 38400)
#define tensor_201 (activation_arena + 1036800)
#define tensor_211 (activation_arena + 883200)
#define tensor_212 (activation_arena + 38400)
#define tensor_213 (activation_arena + 960000)
#define tensor_214 (activation_arena + 998400)
#define tensor_215 (activation_arena + 1036800)
#define tensor_216 (activation_arena + 1113600)
#define tensor_221 (activation_arena + 460800)
#define tensor_224 (activation_arena + 883200)
#define tensor_228 (activation_arena + 921600)
#define tensor_233 (activation_arena + 460800)
#define tensor_234 (activation_arena + 883200)
#define tensor_239 (activation_arena + 480000)
#define tensor_240 (activation_arena + 907200)
#define tensor_241 (activation_arena + 460800)
#define tensor_242 (activation_arena + 883200)
#define tensor_245 (activation_arena + 480000)
#define tensor_246 (activation_arena + 1209600)
#define tensor_248 (activation_arena + 1713600)
#define tensor_252 (activation_arena + 1113600)
static elem_t conv_input_scratch[YOLOV5NU_CONV_INPUT_SCRATCH] row_align(1);
static elem_t conv_output_scratch[YOLOV5NU_CONV_OUTPUT_SCRATCH] row_align(1);
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
static uint8_t dfl_candidate_mask[6300];
#endif

static inline int round_nearest_even(float value) {
  int base = (int)value;
  float fraction = value - (float)base;
  if (fraction > 0.5f || (fraction == 0.5f && (base & 1))) base++;
  if (fraction < -0.5f || (fraction == -0.5f && (base & 1))) base--;
  return base;
}

static inline elem_t quantize_float(float value, float scale) {
  int value_i = round_nearest_even(value / scale);
  if (value_i > 127) value_i = 127;
  if (value_i < -128) value_i = -128;
  return (elem_t)value_i;
}

static void nchw_to_nhwc(const elem_t *src, elem_t *dst, int n, int c, int h, int w) {
  for (int bn = 0; bn < n; bn++)
    for (int y = 0; y < h; y++)
      for (int x = 0; x < w; x++)
        for (int ch = 0; ch < c; ch++)
          dst[((bn * h + y) * w + x) * c + ch] = src[((bn * c + ch) * h + y) * w + x];
}

static void nhwc_to_nchw(const elem_t *src, elem_t *dst, int n, int c, int h, int w) {
  for (int bn = 0; bn < n; bn++)
    for (int ch = 0; ch < c; ch++)
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
          dst[((bn * c + ch) * h + y) * w + x] = src[((bn * h + y) * w + x) * c + ch];
}

static void nhwc_to_ncl_i8(const elem_t *src, elem_t *dst, int n, int c, int h, int w,
    float ss, float ds) {
  for (int bn = 0; bn < n; bn++)
    for (int ch = 0; ch < c; ch++)
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {
          elem_t value = src[((bn * h + y) * w + x) * c + ch];
          dst[(bn * c + ch) * (h * w) + y * w + x] =
            quantize_float((float)value * ss, ds);
        }
}

static void requant_copy(const elem_t *src, elem_t *dst, int count, float src_scale, float dst_scale) {
#if defined(YOLOV5NU_COPY_KERNEL_RVV) && defined(__riscv_vector)
  if (src_scale == dst_scale)
    yolov5nu_rvv_copy_i8(src, dst, (uintptr_t)count);
  else
    yolov5nu_rvv_requant_i8(src, dst, (uintptr_t)count, src_scale / dst_scale);
  return;
#else
  if (src_scale == dst_scale) {
#ifdef __riscv_vector
    uintptr_t remaining=(uintptr_t)count, offset=0, vl;
    while(remaining) {
      asm volatile("vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
                   "vle8.v v0, (%[src])\n\t" "vse8.v v0, (%[dst])"
        : [vl] "=&r" (vl) : [n] "r" (remaining), [src] "r" (src+offset), [dst] "r" (dst+offset) : "memory");
      offset+=vl; remaining-=vl;
    }
#else
    memcpy(dst, src, count);
#endif
    return;
  }
  for (int i = 0; i < count; i++) dst[i] = quantize_float((float)src[i] * src_scale, dst_scale);
#endif
}

#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
static void stage8h_config_ld_if_needed(size_t stride, float scale,
    size_t *current_stride, float *current_scale, bool *valid) {
  if (*valid && *current_stride == stride && *current_scale == scale)
    return;
  if (*valid)
    gemmini_fence();
  gemmini_extended3_config_ld(stride, scale, true, 0);
  *current_stride = stride;
  *current_scale = scale;
  *valid = true;
}
#endif

static void concat_nhwc_slice_strided_i8(const elem_t *src, elem_t *dst,
    int positions, int channels, int dst_stride, float src_scale,
    float dst_scale) {
#if defined(__riscv_vector)
  yolov5nu_rvv_concat_nhwc_slice_i8(src, dst, (uintptr_t)positions,
    (uintptr_t)channels, (uintptr_t)dst_stride, src_scale / dst_scale);
#else
  for (int position = 0; position < positions; position++) {
    requant_copy(src, dst, channels, src_scale, dst_scale);
    src += channels;
    dst += dst_stride;
  }
#endif
}

static void sigmoid_i8(const elem_t *src, elem_t *dst, int count, const elem_t lut[256]) {
  for (int i = 0; i < count; i++) dst[i] = lut[(uint8_t)src[i]];
}



static void silu_lut_i8_strided(const elem_t *src, elem_t *dst,
    int positions, int channels, int dst_stride, const elem_t lut[256]) {
  for (int position = 0; position < positions; position++) {
    for (int channel = 0; channel < channels; channel++)
      dst[channel] = lut[(uint8_t)src[channel]];
    src += channels;
    dst += dst_stride;
  }
}

static void mul_i8(const elem_t *a, const elem_t *b, elem_t *dst, int count, float as, float bs, float ds) {
  for (int i = 0; i < count; i++) dst[i] = quantize_float((float)a[i] * as * (float)b[i] * bs, ds);
}

static void add_i8(const elem_t *a, const elem_t *b, elem_t *dst, int count, float as, float bs, float ds) {
#if defined(YOLOV5NU_ADD_KERNEL_RVV) && defined(__riscv_vector)
  yolov5nu_rvv_add_i8(a, b, dst, (uintptr_t)count, as, bs, ds);
#else
  for (int i = 0; i < count; i++) dst[i] = quantize_float((float)a[i] * as + (float)b[i] * bs, ds);
#endif
}

static void add_ratio_i8(const elem_t *a, const elem_t *b, elem_t *dst,
    int count, float ar, float br) {
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_ratio_i8(a, b, dst, (uintptr_t)count, ar, br);
#else
  for (int i = 0; i < count; i++)
    dst[i] = quantize_float((float)a[i] * ar + (float)b[i] * br, 1.0f);
#endif
}

static void add_fixed_i8(const elem_t *a, const elem_t *b, elem_t *dst,
    int count, float ar, float br, int32_t am, int32_t bm) {
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_fixed_i8(a, b, dst, (uintptr_t)count, am, bm);
#else
  for (int i = 0; i < count; i++)
    dst[i] = quantize_float((float)a[i] * ar + (float)b[i] * br, 1.0f);
#endif
}

static void add_fixed_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br, int32_t am, int32_t bm) {
  for (int position = 0; position < positions; position++) {
    add_fixed_i8(a, b, dst, channels, ar, br, am, bm);
    a += channels;
    b += channels;
    dst += dst_stride;
  }
}

static void add_ratio_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br) {
  for (int position = 0; position < positions; position++) {
    add_ratio_i8(a, b, dst, channels, ar, br);
    a += channels;
    b += channels;
    dst += dst_stride;
  }
}

static void add_gemmini_resadd_strided_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br);

static void add_gemmini_resadd_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, float ar, float br) {
  add_gemmini_resadd_strided_i8(
    a, b, dst, positions, channels, channels, ar, br);
}

static void add_gemmini_resadd_strided_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br) {
  const size_t j_blocks = (channels + DIM - 1) / DIM;
  size_t i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (i_blocks == 0) i_blocks = 1;
  const size_t tile_i = i_blocks * DIM;
  gemmini_extended_config_st((size_t)dst_stride * sizeof(elem_t),
    NO_ACTIVATION, br);
  gemmini_config_ex(WS, 0, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    ar / br, true, DIM, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, DIM, 1);
  for (size_t i = 0; i < (size_t)positions; i += tile_i) {
    const size_t i_tile = i + tile_i <= (size_t)positions
      ? tile_i : (size_t)positions - i;
    sp_tiled_resadd(i_tile, (size_t)channels, ar / br,
      MVIN_SCALE_IDENTITY, a + i * channels, b + i * channels,
      dst + i * dst_stride, (size_t)channels, (size_t)channels,
      (size_t)dst_stride, false);
  }
  gemmini_fence();
}

static void add_gemmini_shared_resadd_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, float output_scale) {
  const size_t j_blocks = (channels + DIM - 1) / DIM;
  size_t i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (i_blocks == 0) i_blocks = 1;
  const size_t tile_i = i_blocks * DIM;
  // Both inputs already use the shared scale; only the output requant remains.
  gemmini_extended_config_st((size_t)channels * sizeof(elem_t),
    NO_ACTIVATION, output_scale);
  gemmini_config_ex(WS, 0, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, DIM, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, DIM, 1);
  for (size_t i = 0; i < (size_t)positions; i += tile_i) {
    const size_t i_tile = i + tile_i <= (size_t)positions
      ? tile_i : (size_t)positions - i;
    sp_tiled_resadd(i_tile, (size_t)channels,
      MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      a + i * channels, b + i * channels, dst + i * channels,
      (size_t)channels, (size_t)channels, (size_t)channels, false);
  }
  gemmini_fence();
}

static void gemmini_splitk_1x1_two_slice_i8(
    const elem_t *a0, const elem_t *a1, const elem_t *weights,
    const acc_t *bias, elem_t *output, int positions, int slice_channels,
    int out_channels, float a0_scale, float a1_scale, float concat_scale,
    int act, float output_scale) {
  if (slice_channels <= 0 || out_channels <= 0 || out_channels % DIM != 0) {
    printf("Stage 8C split-K geometry mismatch\n");
    exit(1);
  }
  const size_t j_blocks = (out_channels + DIM - 1) / DIM;
  const size_t k_blocks = (slice_channels + DIM - 1) / DIM;
  const size_t pad_k = k_blocks * DIM - slice_channels;
  const size_t max_i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (max_i_blocks == 0) {
    printf("Stage 8C split-K accumulator capacity exceeded\n");
    exit(1);
  }
  const size_t tile_rows = max_i_blocks * DIM;

  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended_config_st((size_t)out_channels * sizeof(elem_t),
    act & 7, output_scale);
  gemmini_extended3_config_ld((size_t)out_channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks = (rows + DIM - 1) / DIM;
    const size_t pad_i = i_blocks * DIM - rows;

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a0 + row * slice_channels, weights, bias, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, false, true, act, 0, 0);
    // The load scale is global state. Complete partial 0 before changing it;
    // the accumulator contents survive the fence because no mvout was issued.
    gemmini_fence();

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a1 + row * slice_channels,
      weights + slice_channels * out_channels, NULL,
      output + row * out_channels,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, true, false, act, 0, 0);
    gemmini_fence();
  }
}

// Stage 8F: keep both input slices resident in separate A-side Scratchpad
// partitions so a second consumer can reuse them without another mvin.
static void gemmini_splitk_1x1_two_slice_i8_spad_reuse(
    const elem_t *a0, const elem_t *a1, const elem_t *weights,
    const acc_t *bias, elem_t *output, int positions, int slice_channels,
    int out_channels, float a0_scale, float a1_scale, float concat_scale,
    int act, float output_scale, bool reuse_a) {
  if (slice_channels <= 0 || out_channels <= 0 || out_channels % DIM != 0) {
    printf("Stage 8F split-K geometry mismatch\n");
    exit(1);
  }
  const size_t j_blocks = (out_channels + DIM - 1) / DIM;
  const size_t k_blocks = (slice_channels + DIM - 1) / DIM;
  const size_t pad_k = k_blocks * DIM - slice_channels;
  const size_t max_i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (max_i_blocks == 0) {
    printf("Stage 8F split-K accumulator capacity exceeded\n");
    exit(1);
  }
  const size_t tile_rows = max_i_blocks * DIM;

  // A-side partitions 1 and 2 are disjoint.  The second invocation passes
  // NULL for A, which makes the loop engine skip A's DRAM load while the
  // execute engine still selects the requested resident partition.
  const int a0_spad_id = 1;
  const int a1_spad_id = 2;
  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended_config_st((size_t)out_channels * sizeof(elem_t),
    act & 7, output_scale);
  gemmini_extended3_config_ld((size_t)out_channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks = (rows + DIM - 1) / DIM;
    const size_t pad_i = i_blocks * DIM - rows;

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      reuse_a ? NULL : a0 + row * slice_channels, weights, bias, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, false, true, act, a0_spad_id, 0);
    gemmini_fence();

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      reuse_a ? NULL : a1 + row * slice_channels,
      weights + slice_channels * out_channels, NULL,
      output + row * out_channels,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, true, false, act, a1_spad_id, 0);
    gemmini_fence();
  }
}

// Stage 8F pair helper.  The two consumers are interleaved per spatial tile:
// load both A slices once, finish consumer 0, then reuse the resident slices
// for consumer 1.  Accumulators and output stores remain independent.
static void gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(
    const elem_t *a0, const elem_t *a1,
    const elem_t *weights0, const acc_t *bias0, elem_t *output0,
    const elem_t *silu_lut0, int out_channels0, float requant0,
    const elem_t *weights1, const acc_t *bias1, elem_t *output1,
    const elem_t *silu_lut1, int out_channels1, float requant1,
    int positions, int slice_channels, float a0_scale, float a1_scale,
    float concat_scale, int act) {
  if (slice_channels <= 0 || out_channels0 <= 0 || out_channels1 <= 0 ||
      out_channels0 % DIM != 0 || out_channels1 % DIM != 0) {
    printf("Stage 8F pair split-K geometry mismatch\n");
    exit(1);
  }
  const size_t j_blocks0 = (out_channels0 + DIM - 1) / DIM;
  const size_t j_blocks1 = (out_channels1 + DIM - 1) / DIM;
  const size_t k_blocks = (slice_channels + DIM - 1) / DIM;
  const size_t pad_k = k_blocks * DIM - slice_channels;
  const size_t max_i_blocks0 = (ACC_ROWS / 2) / (j_blocks0 * DIM);
  const size_t max_i_blocks1 = (ACC_ROWS / 2) / (j_blocks1 * DIM);
  const size_t max_i_blocks = max_i_blocks0 < max_i_blocks1
    ? max_i_blocks0 : max_i_blocks1;
  if (max_i_blocks == 0) {
    printf("Stage 8F pair accumulator capacity exceeded\n");
    exit(1);
  }
  const size_t tile_rows = max_i_blocks * DIM;

  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended3_config_ld((size_t)out_channels0 * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks0 = (rows + DIM - 1) / DIM;
    const size_t i_blocks1 = i_blocks0;
    const size_t pad_i = i_blocks0 * DIM - rows;

    // Consumer 0 loads each A slice once and keeps its private accumulator.
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a0 + row * slice_channels, weights0, bias0, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks0, j_blocks0, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels0, out_channels0, out_channels0,
      false, false, false, false, false, true, act, 1, 0);
    gemmini_fence();

    gemmini_config_silu_lut(silu_lut0);
    gemmini_fence();
    gemmini_extended_config_st((size_t)out_channels0 * sizeof(elem_t),
      act & 7, requant0);
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a1 + row * slice_channels,
      weights0 + slice_channels * out_channels0, NULL,
      output0 + row * out_channels0,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks0, j_blocks0, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels0, out_channels0, out_channels0,
      false, false, false, false, true, false, act, 2, 0);
    gemmini_fence();

    // Consumer 1 reuses both A partitions; only B, bias, accumulator and
    // output differ.  A=NULL is translated to the skip-A loop macro.
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      NULL, weights1, bias1, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks1, j_blocks1, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels1, out_channels1, out_channels1,
      false, false, false, false, false, true, act, 1, 0);
    gemmini_fence();

    gemmini_config_silu_lut(silu_lut1);
    gemmini_fence();
    gemmini_extended_config_st((size_t)out_channels1 * sizeof(elem_t),
      act & 7, requant1);
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      NULL, weights1 + slice_channels * out_channels1, NULL,
      output1 + row * out_channels1,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks1, j_blocks1, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels1, out_channels1, out_channels1,
      false, false, false, false, true, false, act, 2, 0);
    gemmini_fence();
  }
}

static void gemmini_splitk_1x1_multi_slice_i8(
    const elem_t *const inputs[], const int slice_channels[],
    const float input_scales[], int slice_count, const elem_t *weights,
    const acc_t *bias, elem_t *output, int positions, int out_channels,
    float concat_scale, int act, float output_scale) {
  if (slice_count <= 1 || out_channels <= 0 || out_channels % DIM != 0) {
    printf("Stage 8C multi-slice geometry mismatch\n");
    exit(1);
  }
  const size_t j_blocks = (out_channels + DIM - 1) / DIM;
  const size_t max_i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (max_i_blocks == 0) {
    printf("Stage 8C multi-slice accumulator capacity exceeded\n");
    exit(1);
  }
  const size_t tile_rows = max_i_blocks * DIM;

#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
  size_t stage8h_current_stride = 0;
  float stage8h_current_scale = 0.0f;
  bool stage8h_scale_valid = false;
#endif

  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended_config_st((size_t)out_channels * sizeof(elem_t),
    act & 7, output_scale);
  gemmini_extended3_config_ld((size_t)out_channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks = (rows + DIM - 1) / DIM;
    const size_t pad_i = i_blocks * DIM - rows;
    size_t weight_channel_offset = 0;
    for (int slice = 0; slice < slice_count; slice++) {
      const size_t channels = (size_t)slice_channels[slice];
      const size_t k_blocks = (channels + DIM - 1) / DIM;
      const size_t pad_k = k_blocks * DIM - channels;
      const bool first = slice == 0;
      const bool last = slice == slice_count - 1;
      const float input_scale = input_scales[slice] / concat_scale;
#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
      stage8h_config_ld_if_needed(channels * sizeof(elem_t), input_scale,
        &stage8h_current_stride, &stage8h_current_scale, &stage8h_scale_valid);
#else
      gemmini_extended3_config_ld(channels * sizeof(elem_t),
        input_scale, true, 0);
#endif
      sp_tiled_matmul_ws(
        inputs[slice] + row * channels,
        weights + weight_channel_offset * out_channels,
        first ? bias : NULL,
        last ? output + row * out_channels : NULL,
        input_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
        i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
        channels, out_channels, out_channels, out_channels,
        false, false, false, false, !first, first, act, 0, 0);
#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
      // A scale change requires a fence because mvin scale is global.  The
      // final fence remains mandatory even when the next partial has the same
      // scale, since the caller may consume the output immediately.
      if (last || input_scales[slice] != input_scales[slice + 1])
        gemmini_fence();
#else
      gemmini_fence();
#endif
      weight_channel_offset += channels;
    }
  }
}

static void add_two_step_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float a_scale, float b_scale, float add_scale, float concat_scale) {
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  for (int position = 0; position < positions; position++) {
    yolov5nu_rvv_add_two_step_i8(a, b, dst, (uintptr_t)channels,
      a_scale / add_scale, b_scale / add_scale, add_scale / concat_scale);
    a += channels;
    b += channels;
    dst += dst_stride;
  }
#else
  for (int position = 0; position < positions; position++) {
    for (int channel = 0; channel < channels; channel++) {
      int first = quantize_float(
        (float)a[channel] * a_scale + (float)b[channel] * b_scale,
        add_scale);
      dst[channel] = quantize_float((float)first * add_scale, concat_scale);
    }
    a += channels;
    b += channels;
    dst += dst_stride;
  }
#endif
}

static void add_two_step_lut_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float a_scale, float b_scale, float add_scale, float concat_scale,
    const elem_t requant_lut[256]) {
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
    for (int position = 0; position < positions; position++) {
    yolov5nu_rvv_add_two_step_lut_i8(a, b, dst, (uintptr_t)channels,
      a_scale / add_scale, b_scale / add_scale, requant_lut);
    a += channels;
    b += channels;
    dst += dst_stride;
  }
#else
  for (int position = 0; position < positions; position++) {
    for (int channel = 0; channel < channels; channel++) {
      int first = quantize_float(
        (float)a[channel] * a_scale + (float)b[channel] * b_scale,
        add_scale);
      dst[channel] = requant_lut[(uint8_t)first];
    }
    a += channels;
    b += channels;
    dst += dst_stride;
  }
#endif
}

static void add_two_step_register_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float a_scale, float b_scale, float add_scale, float concat_scale,
    const elem_t requant_lut[256]) {
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_two_step_register_strided_i8(
    a, b, dst, (uintptr_t)positions, (uintptr_t)channels,
    (uintptr_t)dst_stride, a_scale / add_scale, b_scale / add_scale,
    add_scale / concat_scale, requant_lut);
#else
  add_two_step_lut_i8_strided(a, b, dst, positions, channels, dst_stride,
    a_scale, b_scale, add_scale, concat_scale, requant_lut);
#endif
}

static void add_two_step_register_fixed_i8_strided(const elem_t *a,
    const elem_t *b, elem_t *dst, int positions, int channels, int dst_stride,
    int32_t am, int32_t bm, const elem_t requant_lut[256]) {
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_two_step_register_fixed_strided_i8(
    a, b, dst, (uintptr_t)positions, (uintptr_t)channels,
    (uintptr_t)dst_stride, am, bm, requant_lut);
#else
  for (int position = 0; position < positions; position++) {
    for (int channel = 0; channel < channels; channel++) {
      int64_t value = (int64_t)a[channel] * am + (int64_t)b[channel] * bm;
      int negative = value < 0;
      uint64_t magnitude = negative ? (uint64_t)(-value) : (uint64_t)value;
      int first = (int)(magnitude >> 22);
      uint64_t remainder = magnitude & ((1ULL << 22) - 1);
      if (remainder > (1ULL << 21) ||
          (remainder == (1ULL << 21) && (first & 1))) first++;
      if (negative) first = -first;
      if (first > 127) first = 127;
      if (first < -128) first = -128;
      dst[channel] = requant_lut[(uint8_t)first];
    }
    a += channels;
    b += channels;
    dst += dst_stride;
  }
#endif
}

static void maxpool_nchw_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, int kh, int kw, int sh, int sw, int ph, int pw, float ss, float ds) {
  for (int bn = 0; bn < n; bn++) for (int ch = 0; ch < c; ch++)
    for (int oy = 0; oy < oh; oy++) for (int ox = 0; ox < ow; ox++) {
      int best = -128;
      for (int ky = 0; ky < kh; ky++) for (int kx = 0; kx < kw; kx++) {
        int iy = oy * sh + ky - ph, ix = ox * sw + kx - pw;
        if (iy >= 0 && iy < ih && ix >= 0 && ix < iw) {
          int value = src[((bn * c + ch) * ih + iy) * iw + ix];
          if (value > best) best = value;
        }
      }
      dst[((bn * c + ch) * oh + oy) * ow + ox] = quantize_float((float)best * ss, ds);
    }
}

static void maxpool_nhwc_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, int kh, int kw, int sh, int sw, int ph, int pw, float ss, float ds) {
#if defined(YOLOV5NU_MAXPOOL_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {
    yolov5nu_rvv_maxpool_nhwc_i8(src, dst, n, c, ih, iw, oh, ow,
      kh, kw, sh, sw, ph, pw);
    return;
  }
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {
      int best = -128;
      for (int ky = 0; ky < kh; ky++) for (int kx = 0; kx < kw; kx++) {
        int iy = oy * sh + ky - ph, ix = ox * sw + kx - pw;
        if (iy >= 0 && iy < ih && ix >= 0 && ix < iw) {
          int value = src[((bn * ih + iy) * iw + ix) * c + ch];
          if (value > best) best = value;
        }
      }
      dst[((bn * oh + oy) * ow + ox) * c + ch] = quantize_float((float)best * ss, ds);
    }
}

static void maxpool_nhwc_i8_strided(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, int kh, int kw, int sh, int sw, int ph, int pw,
    float ss, float ds, int dst_stride) {
#if defined(YOLOV5NU_MAXPOOL_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {
    yolov5nu_rvv_maxpool_nhwc_i8_strided(src, dst, n, c, ih, iw, oh, ow,
      kh, kw, sh, sw, ph, pw, dst_stride);
    return;
  }
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {
      int best = -128;
      for (int ky = 0; ky < kh; ky++) for (int kx = 0; kx < kw; kx++) {
        int iy = oy * sh + ky - ph, ix = ox * sw + kx - pw;
        if (iy >= 0 && iy < ih && ix >= 0 && ix < iw) {
          int value = src[((bn * ih + iy) * iw + ix) * c + ch];
          if (value > best) best = value;
        }
      }
      dst[((bn * oh + oy) * ow + ox) * dst_stride + ch] = quantize_float((float)best * ss, ds);
    }
}

static void resize_nearest_nchw_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, float ss, float ds) {
  for (int bn = 0; bn < n; bn++) for (int ch = 0; ch < c; ch++)
    for (int oy = 0; oy < oh; oy++) for (int ox = 0; ox < ow; ox++) {
      int iy = (oy * ih) / oh, ix = (ox * iw) / ow;
      elem_t value = src[((bn * c + ch) * ih + iy) * iw + ix];
      dst[((bn * c + ch) * oh + oy) * ow + ox] = quantize_float((float)value * ss, ds);
    }
}

static void resize_nearest_nhwc_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, float ss, float ds) {
#if defined(YOLOV5NU_RESIZE_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {
    yolov5nu_rvv_resize_nearest_nhwc_i8(src, dst, n, c, ih, iw, oh, ow);
    return;
  }
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {
      int iy = (oy * ih) / oh, ix = (ox * iw) / ow;
      elem_t value = src[((bn * ih + iy) * iw + ix) * c + ch];
      dst[((bn * oh + oy) * ow + ox) * c + ch] = quantize_float((float)value * ss, ds);
    }
}

static void resize_nearest_nhwc_i8_strided(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, float ss, float ds, int dst_stride) {
#if defined(YOLOV5NU_RESIZE_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {
    yolov5nu_rvv_resize_nearest_nhwc_i8_strided(src, dst, n, c, ih, iw, oh, ow, dst_stride);
    return;
  }
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {
      int iy = (oy * ih) / oh, ix = (ox * iw) / ow;
      elem_t value = src[((bn * ih + iy) * iw + ix) * c + ch];
      dst[((bn * oh + oy) * ow + ox) * dst_stride + ch] = quantize_float((float)value * ss, ds);
    }
}

static void transpose4_i8(const elem_t *src, elem_t *dst, int d0, int d1, int d2, int d3,
    int p0, int p1, int p2, int p3, float ss, float ds) {
  int dims[4] = {d0,d1,d2,d3}, perm[4] = {p0,p1,p2,p3};
  int od[4] = {dims[p0],dims[p1],dims[p2],dims[p3]};
  for (int i0=0;i0<od[0];i0++) for(int i1=0;i1<od[1];i1++)
    for(int i2=0;i2<od[2];i2++) for(int i3=0;i3<od[3];i3++) {
      int out_idx[4]={i0,i1,i2,i3}, in_idx[4];
      for(int k=0;k<4;k++) in_idx[perm[k]]=out_idx[k];
      int si=((in_idx[0]*d1+in_idx[1])*d2+in_idx[2])*d3+in_idx[3];
      int di=((i0*od[1]+i1)*od[2]+i2)*od[3]+i3;
      dst[di]=quantize_float((float)src[si]*ss,ds);
    }
}

static void softmax_i8(const elem_t *src, elem_t *dst, int outer, int axis, int inner,
    float ds, const float exp_lut[256]) {
  for (int o=0;o<outer;o++) for(int i=0;i<inner;i++) {
    int max_value=-128; float sum=0.0f;
    for(int a=0;a<axis;a++) { int x=src[(o*axis+a)*inner+i]; if(x>max_value)max_value=x; }
    for(int a=0;a<axis;a++) sum += exp_lut[max_value-(int)src[(o*axis+a)*inner+i]];
    for(int a=0;a<axis;a++) {
      float value=exp_lut[max_value-(int)src[(o*axis+a)*inner+i]]/sum;
      dst[(o*axis+a)*inner+i]=quantize_float(value,ds);
    }
  }
}

static void stage4_select_dfl_candidates(const elem_t *classes, float class_scale,
    float score_threshold);

static void stage4_class_heads_i8(
    const elem_t *src0, int count0, float scale0,
    const elem_t *src1, int count1, float scale1,
    const elem_t *src2, int count2, float scale2,
    elem_t *logits, elem_t *scores, float concat_scale,
    const elem_t sigmoid_lut[256], float class_scale,
    float score_threshold) {
  const elem_t *sources[3] = {src0, src1, src2};
  const int counts[3] = {count0, count1, count2};
  const float scales[3] = {scale0, scale1, scale2};
  int output_position = 0;
  uint64_t phase_start = yolo_profile_clock();
  for (int head = 0; head < 3; head++) {
    requant_copy(sources[head], logits + output_position * 80,
      counts[head] * 80, scales[head], concat_scale);
    output_position += counts[head];
  }
  head_class_requant_cycles = yolo_profile_clock() - phase_start;
  phase_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT) && defined(__riscv_vector)
  yolov5nu_rvv_sigmoid_lut_i8(logits, scores,
    (uintptr_t)(output_position * 80), sigmoid_lut);
#else
  for (int i = 0; i < output_position * 80; i++)
    scores[i] = sigmoid_lut[(uint8_t)logits[i]];
#endif
  head_class_sigmoid_cycles = yolo_profile_clock() - phase_start;
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  phase_start = yolo_profile_clock();
  stage4_select_dfl_candidates(scores, class_scale, score_threshold);
  head_class_candidate_cycles = yolo_profile_clock() - phase_start;
#else
  head_class_candidate_cycles = 0;
#endif
}

static void stage4_dfl_heads_i8(
    const elem_t *src0, int count0, float scale0,
    const elem_t *src1, int count1, float scale1,
    const elem_t *src2, int count2, float scale2,
    elem_t *logits_buffer, elem_t *distances,
    float concat_scale, float softmax_scale,
    float weight_scale, float output_scale, const elem_t weights[16],
    const float exp_lut[256]) {
  const elem_t *sources[3] = {src0, src1, src2};
  const int counts[3] = {count0, count1, count2};
  const float scales[3] = {scale0, scale1, scale2};
  int output_position = 0;
  uint64_t phase_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  head_dfl_candidate_cycles = 0;
#endif
  for (int head = 0; head < 3; head++) {
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    for (int local = 0; local < counts[head]; local++) {
      int position = output_position + local;
      if (dfl_candidate_mask[position])
        requant_copy(sources[head] + local * 64, logits_buffer + position * 64,
          64, scales[head], concat_scale);
    }
#else
    requant_copy(sources[head], logits_buffer + output_position * 64,
      counts[head] * 64, scales[head], concat_scale);
#endif
    output_position += counts[head];
  }
  head_dfl_requant_cycles = yolo_profile_clock() - phase_start;
  phase_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL) && defined(__riscv_vector)
  const int rvv_dfl_supported = yolov5nu_rvv_dfl_vl16_supported();
  head_dfl_rvv_enabled = rvv_dfl_supported;
#else
  head_dfl_rvv_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL_BATCH) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_SCALAR_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#else
  head_dfl_batch_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_ORDERED_SUM) && defined(__riscv_vector)
  head_dfl_ordered_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_ordered_sum_enabled = 0;
#endif
#if (defined(YOLOV5NU_HEAD_KERNEL_DFL_GATHER) || defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER)) && defined(__riscv_vector)
  head_dfl_gather_enabled = rvv_dfl_supported;
#else
  head_dfl_gather_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM) && defined(__riscv_vector)
  head_dfl_elementwise_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_elementwise_sum_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM) && defined(__riscv_vector)
  head_dfl_unordered_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_unordered_sum_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM) && defined(__riscv_vector)
  head_dfl_interleaved_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_interleaved_sum_enabled = 0;
#endif
  for (int position = 0; position < output_position; position++) {
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    if (!dfl_candidate_mask[position]) continue;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER) && defined(__riscv_vector)
    if (rvv_dfl_supported) {
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4] = {0.0f, 0.0f, 0.0f, 0.0f};
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++) {
        yolov5nu_rvv_dfl_exp_gather_f32x16(
          position_logits + edge * 16, maxima[edge], exp_lut,
          exponentials4[edge]);
        for (int bin = 0; bin < 16; bin++)
          sums[edge] += exponentials4[edge][bin];
      }
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sum0 = 0.0f, sum1 = 0.0f, sum2 = 0.0f, sum3 = 0.0f;
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int bin = 0; bin < 16; bin++) {
        float value0 = exp_lut[(int)maxima[0] - (int)position_logits[bin]];
        float value1 = exp_lut[(int)maxima[1] - (int)position_logits[16 + bin]];
        float value2 = exp_lut[(int)maxima[2] - (int)position_logits[32 + bin]];
        float value3 = exp_lut[(int)maxima[3] - (int)position_logits[48 + bin]];
        exponentials4[0][bin] = value0;
        exponentials4[1][bin] = value1;
        exponentials4[2][bin] = value2;
        exponentials4[3][bin] = value3;
        asm volatile(
          "fadd.s %[sum0], %[sum0], %[value0]\n\t"
          "fadd.s %[sum1], %[sum1], %[value1]\n\t"
          "fadd.s %[sum2], %[sum2], %[value2]\n\t"
          "fadd.s %[sum3], %[sum3], %[value3]"
          : [sum0] "+f" (sum0), [sum1] "+f" (sum1),
            [sum2] "+f" (sum2), [sum3] "+f" (sum3)
          : [value0] "f" (value0), [value1] "f" (value1),
            [value2] "f" (value2), [value3] "f" (value3));
      }
      float sums[4] = {sum0, sum1, sum2, sum3};
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4];
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++)
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
      yolov5nu_rvv_dfl_unordered_sum_f32x4x16(exponentials4, sums);
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4];
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++)
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
      yolov5nu_rvv_dfl_elementwise_sum_f32x4x16(exponentials4, sums);
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_SCALAR_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4] = {0.0f, 0.0f, 0.0f, 0.0f};
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++) {
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
          sums[edge] += exponentials4[edge][bin];
        }
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL_BATCH) && defined(__riscv_vector)
    if (rvv_dfl_supported) {
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4];
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++)
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
      yolov5nu_rvv_dfl_ordered_sum_f32x4x16(exponentials4, sums);
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }
#endif
    for (int edge = 0; edge < 4; edge++) {
        const elem_t *logits = logits_buffer + position * 64 + edge * 16;
        int max_value = -128;
        float sum = 0.0f;
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
        float exponentials[16];
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          max_value = yolov5nu_rvv_dfl_max_i8x16(logits);
        else
#endif
        {
        for (int bin = 0; bin < 16; bin++) {
          elem_t value = logits[bin];
          if (value > max_value) max_value = value;
        }
        }
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_GATHER) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          yolov5nu_rvv_dfl_exp_gather_f32x16(
            logits, (int8_t)max_value, exp_lut, exponentials);
        else
#endif
        for (int bin = 0; bin < 16; bin++) {
          exponentials[bin] = exp_lut[max_value - (int)logits[bin]];
        }
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_ORDERED_SUM) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          sum = yolov5nu_rvv_dfl_ordered_sum_f32x16(exponentials);
        else
#endif
        for (int bin = 0; bin < 16; bin++) {
          sum += exponentials[bin];
        }
        float reciprocal = 1.0f / (sum * softmax_scale);
#else
        for (int bin = 0; bin < 16; bin++)
          sum += exp_lut[max_value - (int)logits[bin]];
#endif
        int accumulator = 0;
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          accumulator = yolov5nu_rvv_dfl_probability_dot_i8x16(
            exponentials, reciprocal, weights);
        else
#endif
        {
        for (int bin = 0; bin < 16; bin++) {
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
          int probability_i = round_nearest_even(exponentials[bin] * reciprocal);
          if (probability_i > 127) probability_i = 127;
          if (probability_i < -128) probability_i = -128;
          elem_t probability = (elem_t)probability_i;
#else
          elem_t probability = quantize_float(
            exp_lut[max_value - (int)logits[bin]] / sum, softmax_scale);
#endif
          accumulator += (int)probability * (int)weights[bin];
        }
        }
        distances[position * 4 + edge] = quantize_float(
          (float)accumulator * softmax_scale * weight_scale, output_scale);
      }
  }
  head_dfl_core_cycles = yolo_profile_clock() - phase_start;
}

static void print_checkpoint(int index, const char *name, const elem_t *data, int count) {
#if YOLOV5NU_LAYER_STATS
  long checksum=0; int min_value=127,max_value=-128;
  for(int i=0;i<count;i++) { int value=data[i]; checksum+=value; if(value<min_value)min_value=value; if(value>max_value)max_value=value; }
#if 0
  unsigned long long sum_sq=0, hash=1469598103934665603ULL;
  for(int i=0;i<count;i++) {
    unsigned long long value=(unsigned char)data[i];
    sum_sq += (unsigned long long)((int)data[i] * (int)data[i]);
    hash ^= value;
    hash *= 1099511628211ULL;
  }
  printf("op%d %s elems=%d checksum=%ld min=%d max=%d sum_sq=%llu fnv1a=%016llx\n",
    index,name,count,checksum,min_value,max_value,sum_sq,hash);
#else
  printf("op%d %s elems=%d checksum=%ld min=%d max=%d\n",index,name,count,checksum,min_value,max_value);
#endif
#else
  (void)index; (void)name; (void)data; (void)count;
#endif
}

static void print_tensor_summary(const char *name, const elem_t *data, int count) {
#if YOLOV5NU_FINAL_TENSOR_STATS
  long checksum=0; int min_value=127,max_value=-128,saturated=0;
  for(int i=0;i<count;i++) {
    int value=data[i]; checksum+=value;
    if(value<min_value) min_value=value;
    if(value>max_value) max_value=value;
    if(value==127 || value==-128) saturated++;
  }
  printf("%s elems=%d checksum=%ld min=%d max=%d saturated=%d\n",
    name,count,checksum,min_value,max_value,saturated);
#else
  (void)name; (void)data; (void)count;
#endif
}

static void print_sparse_dfl_summary(const char *name, const elem_t *data,
    const uint8_t *mask, int positions) {
#if YOLOV5NU_FINAL_TENSOR_STATS
  long checksum = 0; int min_value = 127, max_value = -128, saturated = 0;
  int elems = 0;
  for (int position = 0; position < positions; position++) if (mask[position])
    for (int edge = 0; edge < 4; edge++) {
      int value = data[position * 4 + edge];
      checksum += value; elems++;
      if (value < min_value) min_value = value;
      if (value > max_value) max_value = value;
      if (value == 127 || value == -128) saturated++;
    }
  printf("%s sparse_positions=%d elems=%d checksum=%ld min=%d max=%d saturated=%d\n",
    name, head_dfl_candidate_count, elems, checksum, min_value, max_value, saturated);
#else
  (void)name; (void)data; (void)mask; (void)positions;
#endif
}

struct Detection { float score,cx,cy,w,h; int cls,index; };
static const char *coco_names[80] = {
  "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush"
};

static struct Detection decode_candidate(const elem_t *dfl, float dfl_scale,
    const elem_t *classes, float class_scale, int index) {
#if defined(YOLOV5NU_HEAD_LOWERING_LOCATION_MAJOR)
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV) && defined(__riscv_vector)
    int cls;
    elem_t best = yolov5nu_rvv_class_max_i8(classes + index * 80, 80, &cls);
#else
    int cls=0; elem_t best=classes[index*80];
    for(int c=1;c<80;c++) { elem_t value=classes[index*80+c]; if(value>best){best=value;cls=c;} }
#endif
#else
    int cls=0; elem_t best=classes[index];
    for(int c=1;c<80;c++) { elem_t value=classes[c*6300+index]; if(value>best){best=value;cls=c;} }
#endif
    float score=(float)best*class_scale;
    int level,local,width,stride;
    if(index<4800){level=0;local=index;width=80;stride=8;}
    else if(index<6000){level=1;local=index-4800;width=40;stride=16;}
    else{level=2;local=index-6000;width=20;stride=32;}
    (void)level;
    int x=local%width,y=local/width;
#if defined(YOLOV5NU_HEAD_LOWERING_LOCATION_MAJOR)
    float l=(float)dfl[index*4]*dfl_scale,t=(float)dfl[index*4+1]*dfl_scale;
    float r=(float)dfl[index*4+2]*dfl_scale,b=(float)dfl[index*4+3]*dfl_scale;
#else
    float l=(float)dfl[index]*dfl_scale,t=(float)dfl[6300+index]*dfl_scale;
    float r=(float)dfl[12600+index]*dfl_scale,b=(float)dfl[18900+index]*dfl_scale;
#endif
    struct Detection value={score,((float)x+0.5f+(r-l)*0.5f)*stride,
      ((float)y+0.5f+(b-t)*0.5f)*stride,(l+r)*stride,(t+b)*stride,cls,index};
    return value;
}

static float detection_iou(const struct Detection *a, const struct Detection *b) {
  float ax0=a->cx-a->w*0.5f, ay0=a->cy-a->h*0.5f;
  float ax1=a->cx+a->w*0.5f, ay1=a->cy+a->h*0.5f;
  float bx0=b->cx-b->w*0.5f, by0=b->cy-b->h*0.5f;
  float bx1=b->cx+b->w*0.5f, by1=b->cy+b->h*0.5f;
  float ix0=ax0>bx0?ax0:bx0, iy0=ay0>by0?ay0:by0;
  float ix1=ax1<bx1?ax1:bx1, iy1=ay1<by1?ay1:by1;
  float iw=ix1-ix0, ih=iy1-iy0;
  if(iw<=0.0f || ih<=0.0f) return 0.0f;
  float inter=iw*ih, area_a=a->w*a->h, area_b=b->w*b->h;
  float uni=area_a+area_b-inter;
  return uni>0.0f ? inter/uni : 0.0f;
}

static void print_detection(const char *prefix, int rank, const struct Detection *value) {
  printf("%s#%d %s score_milli=%d bbox_cxcywh=(%d,%d,%d,%d) index=%d\n",
    prefix,rank,coco_names[value->cls],(int)(value->score*1000.0f+0.5f),
    (int)value->cx,(int)value->cy,(int)value->w,(int)value->h,value->index);
}

static void decode_top_compute(const elem_t *dfl, float dfl_scale, const elem_t *classes,
    float class_scale, struct Detection top[10]) {
  for(int i=0;i<10;i++) top[i]=(struct Detection){0};
  for(int index=0;index<6300;index++) {
    struct Detection value=decode_candidate(dfl,dfl_scale,classes,class_scale,index);
    if(value.score<=top[9].score) continue;
    int pos=9; while(pos>0 && value.score>top[pos-1].score){top[pos]=top[pos-1];pos--;} top[pos]=value;
  }
}

static struct Detection decoded_candidates[6300];

#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
static void stage4_select_dfl_candidates(const elem_t *classes, float class_scale,
    float score_threshold) {
  int best_scores[6300];
#if defined(YOLOV5NU_HEAD_CANDIDATE_KERNEL_RVV) && defined(__riscv_vector)
  head_dfl_candidate_rvv_enabled = 1;
#else
  head_dfl_candidate_rvv_enabled = 0;
#endif
  for (int index = 0; index < 6300; index++) {
#if defined(YOLOV5NU_HEAD_CANDIDATE_KERNEL_RVV) && defined(__riscv_vector)
    int best = (int)yolov5nu_rvv_class_score_max_i8(
      classes + index * 80, 80);
#else
    int best = classes[index * 80];
    for (int cls = 1; cls < 80; cls++) {
      int value = classes[index * 80 + cls];
      if (value > best) best = value;
    }
#endif
    best_scores[index] = best;
    dfl_candidate_mask[index] = ((float)best * class_scale >= score_threshold);
  }
  int top[10];
  int top_scores[10];
  for (int rank = 0; rank < 10; rank++) { top[rank] = -1; top_scores[rank] = -129; }
  for (int index = 0; index < 6300; index++) {
    int score = best_scores[index];
    if (score <= top_scores[9]) continue;
    int pos = 9;
    while (pos > 0 && score > top_scores[pos - 1]) {
      top[pos] = top[pos - 1];
      top_scores[pos] = top_scores[pos - 1];
      pos--;
    }
    top[pos] = index;
    top_scores[pos] = score;
  }
  for (int rank = 0; rank < 10; rank++)
    if (top[rank] >= 0) dfl_candidate_mask[top[rank]] = 1;
  head_dfl_candidate_count = 0;
  for (int index = 0; index < 6300; index++)
    head_dfl_candidate_count += dfl_candidate_mask[index] != 0;
  head_dfl_sparse_enabled = 1;
}
#else
static void stage4_select_dfl_candidates(const elem_t *classes, float class_scale,
    float score_threshold) {
  (void)classes; (void)class_scale; (void)score_threshold;
  head_dfl_sparse_enabled = 0;
  head_dfl_candidate_count = 6300;
  head_dfl_candidate_cycles = 0;
  head_class_candidate_cycles = 0;
  head_dfl_candidate_rvv_enabled = 0;
}
#endif

static void decode_all_compute(const elem_t *dfl, float dfl_scale,
    const elem_t *classes, float class_scale) {
  for (int index = 0; index < 6300; index++) {
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    if (!dfl_candidate_mask[index]) {
      decoded_candidates[index] = (struct Detection){0};
      continue;
    }
#endif
    decoded_candidates[index] = decode_candidate(
      dfl, dfl_scale, classes, class_scale, index);
  }
}

static void decode_top_from_candidates(struct Detection top[10]) {
  for (int i = 0; i < 10; i++) top[i] = (struct Detection){0};
  for (int index = 0; index < 6300; index++) {
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    if (!dfl_candidate_mask[index]) continue;
#endif
    struct Detection value = decoded_candidates[index];
    if (value.score <= top[9].score) continue;
    int pos = 9;
    while (pos > 0 && value.score > top[pos - 1].score) {
      top[pos] = top[pos - 1];
      pos--;
    }
    top[pos] = value;
  }
}

static void print_top_detections(const struct Detection top[10]) {
  printf("YOLOv5nu top detections for %s (no NMS)\n",YOLOV5NU_IMAGE_NAME);
  for(int i=0;i<10;i++) print_detection("",i,&top[i]);
}

static int decode_nms_compute(const elem_t *dfl, float dfl_scale, const elem_t *classes,
    float class_scale, float score_threshold, float iou_threshold, struct Detection output[10]) {
  static struct Detection candidates[6300];
  static uint8_t suppressed[6300];
  int count=0;
  for(int index=0;index<6300;index++) {
    struct Detection value=decode_candidate(dfl,dfl_scale,classes,class_scale,index);
    if(value.score>=score_threshold) candidates[count++]=value;
  }
  memset(suppressed,0,sizeof(suppressed));
  int emitted=0;
  while(emitted<10) {
    int best=-1;
    for(int i=0;i<count;i++)
      if(!suppressed[i] && (best<0 || candidates[i].score>candidates[best].score)) best=i;
    if(best<0) break;
    output[emitted]=candidates[best];
    suppressed[best]=1;
    for(int i=0;i<count;i++)
      if(!suppressed[i] && candidates[i].cls==candidates[best].cls &&
          detection_iou(&candidates[i],&candidates[best])>iou_threshold) suppressed[i]=1;
    emitted++;
  }
  return emitted;
}

static int decode_nms_from_candidates(float score_threshold,
    float iou_threshold, struct Detection output[10]) {
  static int candidate_indices[6300];
  static uint8_t suppressed[6300];
  int count = 0;
  for (int index = 0; index < 6300; index++)
    if (
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
        dfl_candidate_mask[index] &&
#endif
        decoded_candidates[index].score >= score_threshold)
      candidate_indices[count++] = index;
  memset(suppressed, 0, sizeof(suppressed));
  int emitted = 0;
  while (emitted < 10) {
    int best = -1;
    for (int i = 0; i < count; i++)
      if (!suppressed[i] && (best < 0 ||
          decoded_candidates[candidate_indices[i]].score >
          decoded_candidates[candidate_indices[best]].score)) best = i;
    if (best < 0) break;
    const struct Detection *best_value =
      &decoded_candidates[candidate_indices[best]];
    output[emitted] = *best_value;
    suppressed[best] = 1;
    for (int i = 0; i < count; i++) {
      const struct Detection *value =
        &decoded_candidates[candidate_indices[i]];
      if (!suppressed[i] && value->cls == best_value->cls &&
          detection_iou(value, best_value) > iou_threshold) suppressed[i] = 1;
    }
    emitted++;
  }
  return emitted;
}

static void print_nms_detections(const struct Detection output[10], int count,
    float score_threshold, float iou_threshold) {
  printf("YOLOv5nu NMS detections for %s score_threshold=%.2f iou_threshold=%.2f\n",
    YOLOV5NU_IMAGE_NAME,score_threshold,iou_threshold);
  for(int i=0;i<count;i++) print_detection("",i,&output[i]);
}

static void yolo_profile_print_report(uint64_t graph_cycles, uint64_t decode_cycles,
    uint64_t nms_cycles) {
#if YOLOV5NU_PROFILE
  uint64_t totals[PROFILE_KIND_COUNT]={0};
  for(int i=0;i<yolo_profile_record_count;i++) {
    struct YoloProfileRecord *record=&yolo_profile_records[i];
    totals[record->kind]+=record->cycles;
    printf("YOLOV5NU_PROFILE record=%d kind=%s name=%s cycles=%lu\n",
      i,record->kind_name,record->name,(unsigned long)record->cycles);
  }
  uint64_t conv_cycles=totals[PROFILE_CONV_TOTAL];
  uint64_t cpu_cycles=0;
  for(int kind=PROFILE_SIGMOID;kind<=PROFILE_HEAD_DFL;kind++) cpu_cycles+=totals[kind];
  uint64_t layout_cycles=totals[PROFILE_CONV_IN_LAYOUT]+totals[PROFILE_CONV_OUT_LAYOUT];
  printf("YOLOV5NU_PROFILE records=%d graph_cycles=%lu decode_cycles=%lu nms_cycles=%lu\n",
    yolo_profile_record_count,(unsigned long)graph_cycles,(unsigned long)decode_cycles,
    (unsigned long)nms_cycles);
  printf("YOLOV5NU_PROFILE conv_cycles=%lu cpu_operator_cycles=%lu conv_layout_cycles=%lu gemmini_conv_cycles=%lu\n",
    (unsigned long)conv_cycles,(unsigned long)cpu_cycles,(unsigned long)layout_cycles,
    (unsigned long)totals[PROFILE_CONV_GEMMINI]);
  printf("YOLOV5NU_PROFILE maxpool_cycles=%lu resize_cycles=%lu concat_cycles=%lu sigmoid_cycles=%lu\n",
    (unsigned long)totals[PROFILE_MAXPOOL],(unsigned long)totals[PROFILE_RESIZE],
    (unsigned long)totals[PROFILE_CONCAT],(unsigned long)totals[PROFILE_SIGMOID]);
  printf("YOLOV5NU_PROFILE silu_fused_cycles=%lu mul_cycles=%lu add_cycles=%lu\n",
    (unsigned long)totals[PROFILE_SILU_FUSED_LUT],(unsigned long)totals[PROFILE_MUL],
    (unsigned long)totals[PROFILE_ADD]);
  printf("YOLOV5NU_PROFILE head_class_cycles=%lu head_dfl_cycles=%lu\n",
    (unsigned long)totals[PROFILE_HEAD_CLASS],(unsigned long)totals[PROFILE_HEAD_DFL]);
  printf("YOLOV5NU_HEAD_CANDIDATES sparse_enabled=%d rvv_max_enabled=%d count=%d "
    "select_cycles=%lu\n",
    head_dfl_sparse_enabled, head_dfl_candidate_rvv_enabled,
    head_dfl_candidate_count,
    (unsigned long)(head_class_candidate_cycles + head_dfl_candidate_cycles));
  printf("YOLOV5NU_HEAD_PHASE class_requant_cycles=%lu class_sigmoid_cycles=%lu "
    "dfl_requant_cycles=%lu dfl_core_cycles=%lu dfl_rvv_enabled=%d "
    "dfl_batch_enabled=%d dfl_ordered_sum_enabled=%d "
    "dfl_gather_enabled=%d dfl_elementwise_sum_enabled=%d "
    "dfl_unordered_sum_enabled=%d dfl_interleaved_sum_enabled=%d\n",
    (unsigned long)head_class_requant_cycles,
    (unsigned long)head_class_sigmoid_cycles,
    (unsigned long)head_dfl_requant_cycles,
    (unsigned long)head_dfl_core_cycles,head_dfl_rvv_enabled,
    head_dfl_batch_enabled,head_dfl_ordered_sum_enabled,
    head_dfl_gather_enabled,head_dfl_elementwise_sum_enabled,
    head_dfl_unordered_sum_enabled,head_dfl_interleaved_sum_enabled);
#else
  (void)graph_cycles; (void)decode_cycles; (void)nms_cycles;
#endif
}

int main(void) {
  printf("YOLOv5nu Gemmini baremetal image decode test\n");
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  printf("Input: 480x640x3, output: class[80x6300]+sparse DFL, image: %s\n",YOLOV5NU_IMAGE_NAME);
#else
  printf("Input: 480x640x3, output: 84x6300, image: %s\n",YOLOV5NU_IMAGE_NAME);
#endif
  printf("Physical feature layout: nhwc\n");
  printf("SiLU mode: fused-lut\n");
  printf("SiLU kernel: gemmini-lut\n");
  printf("Stage 3 kernel mode: rvv\n");
  printf("Stage 3 kernels: copy=rvv add=rvv-ratio "
    "maxpool=rvv resize=rvv\n");
  printf("Detection head lowering: location-major\n");
  printf("Detection head kernel: optimized-rvv-lut-dfl-batch-interleaved-scalar-sum\n");
  printf("Memory plan stage: 5d\n");
  gemmini_flush(0);
  yolo_profile_reset();
  uint64_t silu_config_cycles[69] = {0};
  uint64_t graph_start = yolo_profile_clock();
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut0);
    gemmini_fence();
    silu_config_cycles[0] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 480, 640, 3, 16, 240, 320, 2, 1, 1, 2, 6, false, false, false, false, false, yolov5nu_input, yolov5nu_conv0_weights, yolov5nu_conv0_bias, tensor_3, SILU_LUT, 0.002008917537f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.0/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.0/act/Mul", silu_config_cycles[0]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut1);
    gemmini_fence();
    silu_config_cycles[1] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 240, 320, 16, 32, 120, 160, 2, 1, 1, 1, 3, false, false, false, false, false, tensor_3, yolov5nu_conv1_weights, yolov5nu_conv1_bias, tensor_6, SILU_LUT, 0.006296144211f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.1/act/Mul", silu_config_cycles[1]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut2);
    gemmini_fence();
    silu_config_cycles[2] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 120, 160, 32, 16, 120, 160, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_6, yolov5nu_conv2_weights, yolov5nu_conv2_bias, tensor_11, SILU_LUT, 0.008815106758f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut3);
    gemmini_fence();
    silu_config_cycles[3] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 120, 160, 32, 16, 120, 160, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_6, yolov5nu_conv3_weights, yolov5nu_conv3_bias, tensor_12, SILU_LUT, 0.01388227474f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/cv1/act/Mul", silu_config_cycles[2]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/cv2/act/Mul", silu_config_cycles[3]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut4);
    gemmini_fence();
    silu_config_cycles[4] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 120, 160, 16, 16, 120, 160, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_11, yolov5nu_conv4_weights, yolov5nu_conv4_bias, tensor_15, SILU_LUT, 0.02706060747f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/m/m.0/cv1/act/Mul", silu_config_cycles[4]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut5);
    gemmini_fence();
    silu_config_cycles[5] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 120, 160, 16, 16, 120, 160, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_15, yolov5nu_conv5_weights, yolov5nu_conv5_bias, tensor_18, SILU_LUT, 0.005251460152f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/m/m.0/cv2/act/Mul", silu_config_cycles[5]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.2/m/m.0/Add");
  add_gemmini_shared_resadd_i8(tensor_11, tensor_18, tensor_11, 19200, 16, 0.9812775003f);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.2/m/m.0/Add", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.2/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.2/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.2/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut6);
    gemmini_fence();
    silu_config_cycles[6] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.2/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_11, tensor_12, yolov5nu_conv6_weights, yolov5nu_conv6_bias, tensor_23, 19200, 16, 32, 0.1644798517f, 0.2913527489f, 0.2913527489f, SILU_LUT, 0.008279219314f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/cv3/act/Mul", silu_config_cycles[6]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut7);
    gemmini_fence();
    silu_config_cycles[7] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 120, 160, 32, 64, 60, 80, 2, 1, 1, 1, 3, false, false, false, false, false, tensor_23, yolov5nu_conv7_weights, yolov5nu_conv7_bias, tensor_26, SILU_LUT, 0.005127142187f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.3/act/Mul", silu_config_cycles[7]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut8);
    gemmini_fence();
    silu_config_cycles[8] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 32, 60, 80, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_26, yolov5nu_conv8_weights, yolov5nu_conv8_bias, tensor_31, SILU_LUT, 0.004353244259f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut9);
    gemmini_fence();
    silu_config_cycles[9] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 32, 60, 80, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_26, yolov5nu_conv9_weights, yolov5nu_conv9_bias, tensor_32, SILU_LUT, 0.008580376805f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/cv1/act/Mul", silu_config_cycles[8]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/cv2/act/Mul", silu_config_cycles[9]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut10);
    gemmini_fence();
    silu_config_cycles[10] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 32, 32, 60, 80, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_31, yolov5nu_conv10_weights, yolov5nu_conv10_bias, tensor_35, SILU_LUT, 0.01429130881f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.0/cv1/act/Mul", silu_config_cycles[10]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut11);
    gemmini_fence();
    silu_config_cycles[11] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 32, 32, 60, 80, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_35, yolov5nu_conv11_weights, yolov5nu_conv11_bias, tensor_38, SILU_LUT, 0.00494680457f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.0/cv2/act/Mul", silu_config_cycles[11]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.4/m/m.0/Add");
  add_gemmini_shared_resadd_i8(tensor_31, tensor_38, tensor_31, 4800, 32, 0.5677252519f);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.4/m/m.0/Add", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut12);
    gemmini_fence();
    silu_config_cycles[12] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.1/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 32, 32, 60, 80, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_31, yolov5nu_conv12_weights, yolov5nu_conv12_bias, tensor_42, SILU_LUT, 0.01520132196f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.1/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.1/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.1/cv1/act/Mul", silu_config_cycles[12]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut13);
    gemmini_fence();
    silu_config_cycles[13] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.1/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 32, 32, 60, 80, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_42, yolov5nu_conv13_weights, yolov5nu_conv13_bias, tensor_45, SILU_LUT, 0.004127477181f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.1/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.1/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.1/cv2/act/Mul", silu_config_cycles[13]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.4/m/m.1/Add");
  add_gemmini_shared_resadd_i8(tensor_31, tensor_45, tensor_31, 4800, 32, 0.8500633558f);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.4/m/m.1/Add", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.4/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.4/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.4/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut14);
    gemmini_fence();
    silu_config_cycles[14] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.4/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_31, tensor_32, yolov5nu_conv14_weights, yolov5nu_conv14_bias, tensor_50, 4800, 32, 64, 0.09039246291f, 0.09101042151f, 0.09101042151f, SILU_LUT, 0.01170961727f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/cv3/act/Mul", silu_config_cycles[14]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.5/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut15);
    gemmini_fence();
    silu_config_cycles[15] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.5/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 128, 30, 40, 2, 1, 1, 1, 3, false, false, false, false, false, tensor_50, yolov5nu_conv15_weights, yolov5nu_conv15_bias, tensor_53, SILU_LUT, 0.007052777546f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.5/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.5/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.5/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.5/act/Mul", silu_config_cycles[15]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut16);
    gemmini_fence();
    silu_config_cycles[16] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 128, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_53, yolov5nu_conv16_weights, yolov5nu_conv16_bias, tensor_58, SILU_LUT, 0.005202484798f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut17);
    gemmini_fence();
    silu_config_cycles[17] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 128, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_53, yolov5nu_conv17_weights, yolov5nu_conv17_bias, tensor_59, SILU_LUT, 0.01175433058f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/cv1/act/Mul", silu_config_cycles[16]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/cv2/act/Mul", silu_config_cycles[17]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut18);
    gemmini_fence();
    silu_config_cycles[18] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_58, yolov5nu_conv18_weights, yolov5nu_conv18_bias, tensor_62, SILU_LUT, 0.0283545171f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.0/cv1/act/Mul", silu_config_cycles[18]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut19);
    gemmini_fence();
    silu_config_cycles[19] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_62, yolov5nu_conv19_weights, yolov5nu_conv19_bias, tensor_65, SILU_LUT, 0.005016636715f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.0/cv2/act/Mul", silu_config_cycles[19]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.6/m/m.0/Add");
  add_gemmini_shared_resadd_i8(tensor_58, tensor_65, tensor_58, 1200, 64, 0.8582346726f);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.6/m/m.0/Add", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut20);
    gemmini_fence();
    silu_config_cycles[20] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.1/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_58, yolov5nu_conv20_weights, yolov5nu_conv20_bias, tensor_69, SILU_LUT, 0.009295667033f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.1/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.1/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.1/cv1/act/Mul", silu_config_cycles[20]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut21);
    gemmini_fence();
    silu_config_cycles[21] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.1/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_69, yolov5nu_conv21_weights, yolov5nu_conv21_bias, tensor_72, SILU_LUT, 0.01178147757f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.1/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.1/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.1/cv2/act/Mul", silu_config_cycles[21]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.6/m/m.1/Add");
  add_gemmini_shared_resadd_i8(tensor_58, tensor_72, tensor_58, 1200, 64, 0.6842259746f);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.6/m/m.1/Add", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut22);
    gemmini_fence();
    silu_config_cycles[22] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.2/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_58, yolov5nu_conv22_weights, yolov5nu_conv22_bias, tensor_76, SILU_LUT, 0.009779870048f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.2/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.2/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.2/cv1/act/Mul", silu_config_cycles[22]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut23);
    gemmini_fence();
    silu_config_cycles[23] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.2/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_76, yolov5nu_conv23_weights, yolov5nu_conv23_bias, tensor_79, SILU_LUT, 0.00713480734f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.2/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.2/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.2/cv2/act/Mul", silu_config_cycles[23]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.6/m/m.2/Add");
  add_gemmini_shared_resadd_i8(tensor_58, tensor_79, tensor_58, 1200, 64, 0.8418630253f);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.6/m/m.2/Add", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.6/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.6/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.6/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut24);
    gemmini_fence();
    silu_config_cycles[24] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.6/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_58, tensor_59, yolov5nu_conv24_weights, yolov5nu_conv24_bias, tensor_84, 1200, 64, 128, 0.09763175249f, 0.0971769914f, 0.09763175249f, SILU_LUT, 0.006165039474f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/cv3/act/Mul", silu_config_cycles[24]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.7/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut25);
    gemmini_fence();
    silu_config_cycles[25] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.7/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 128, 256, 15, 20, 2, 1, 1, 1, 3, false, false, false, false, false, tensor_84, yolov5nu_conv25_weights, yolov5nu_conv25_bias, tensor_87, SILU_LUT, 0.003748494126f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.7/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.7/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.7/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.7/act/Mul", silu_config_cycles[25]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut26);
    gemmini_fence();
    silu_config_cycles[26] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 256, 128, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_87, yolov5nu_conv26_weights, yolov5nu_conv26_bias, tensor_92, SILU_LUT, 0.004340344677f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut27);
    gemmini_fence();
    silu_config_cycles[27] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 256, 128, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_87, yolov5nu_conv27_weights, yolov5nu_conv27_bias, tensor_93, SILU_LUT, 0.008855748756f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/cv1/act/Mul", silu_config_cycles[26]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/cv2/act/Mul", silu_config_cycles[27]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut28);
    gemmini_fence();
    silu_config_cycles[28] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 128, 128, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_92, yolov5nu_conv28_weights, yolov5nu_conv28_bias, tensor_96, SILU_LUT, 0.03369805816f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/m/m.0/cv1/act/Mul", silu_config_cycles[28]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut29);
    gemmini_fence();
    silu_config_cycles[29] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 128, 128, 15, 20, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_96, yolov5nu_conv29_weights, yolov5nu_conv29_bias, tensor_99, SILU_LUT, 0.003076439201f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/m/m.0/cv2/act/Mul", silu_config_cycles[29]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.8/m/m.0/Add");
  add_gemmini_shared_resadd_i8(tensor_92, tensor_99, tensor_92, 300, 128, 1.006423881f);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.8/m/m.0/Add", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.8/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.8/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.8/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut30);
    gemmini_fence();
    silu_config_cycles[30] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.8/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_92, tensor_93, yolov5nu_conv30_weights, yolov5nu_conv30_bias, tensor_104, 300, 128, 256, 0.1487267315f, 0.1015850231f, 0.1487267315f, SILU_LUT, 0.01036427706f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/cv3/act/Mul", silu_config_cycles[30]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut31);
    gemmini_fence();
    silu_config_cycles[31] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.9/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 256, 128, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_104, yolov5nu_conv31_weights, yolov5nu_conv31_bias, tensor_107, SILU_LUT, 0.007808852375f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.9/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.9/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.9/cv1/act/Mul", silu_config_cycles[31]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_MAXPOOL, "MaxPool", "/model.9/m/MaxPool");
  maxpool_nhwc_i8(tensor_107, tensor_108, 1, 128, 15, 20, 15, 20, 5, 5, 1, 1, 2, 2, 0.05828123912f, 0.05828123912f);

    yolo_profile_add(PROFILE_MAXPOOL, "MaxPool", "/model.9/m/MaxPool", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_1/MaxPool");
  maxpool_nhwc_i8(tensor_108, tensor_109, 1, 128, 15, 20, 15, 20, 5, 5, 1, 1, 2, 2, 0.05828123912f, 0.05828123912f);

    yolo_profile_add(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_1/MaxPool", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_2/MaxPool");
  maxpool_nhwc_i8(tensor_109, tensor_110, 1, 128, 15, 20, 15, 20, 5, 5, 1, 1, 2, 2, 0.05828123912f, 0.05828123912f);

    yolo_profile_add(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_2/MaxPool", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.9/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.9/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.9/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut32);
    gemmini_fence();
    silu_config_cycles[32] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.9/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.9/Concat */
    const elem_t *stage8_inputs[] = {tensor_107, tensor_108, tensor_109, tensor_110};
    const int stage8_channels[] = {128, 128, 128, 128};
    const float stage8_scales[] = {0.05828123912f, 0.05828123912f, 0.05828123912f, 0.05828123912f};
    gemmini_splitk_1x1_multi_slice_i8(stage8_inputs, stage8_channels, stage8_scales, 4, yolov5nu_conv32_weights, yolov5nu_conv32_bias, tensor_114, 300, 256, 0.05828123912f, SILU_LUT, 0.006750067428f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.9/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.9/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.9/cv2/act/Mul", silu_config_cycles[32]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.10/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut33);
    gemmini_fence();
    silu_config_cycles[33] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.10/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 256, 128, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_114, yolov5nu_conv33_weights, yolov5nu_conv33_bias, tensor_117, SILU_LUT, 0.005819611447f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.10/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.10/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.10/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.10/act/Mul", silu_config_cycles[33]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_RESIZE, "Resize", "/model.11/Resize");
  resize_nearest_nhwc_i8(tensor_117, tensor_118, 1, 128, 15, 20, 30, 40, 0.1213865206f, 0.1213865206f);

    yolo_profile_add(PROFILE_RESIZE, "Resize", "/model.11/Resize", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.12/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.12/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.12/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut34);
    gemmini_fence();
    silu_config_cycles[34] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.12/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.12/Concat consumer2 */
    gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(tensor_118, tensor_84, yolov5nu_conv34_weights, yolov5nu_conv34_bias, tensor_124, yolov5nu_silu_lut34, 64, 0.01855855302f, yolov5nu_conv35_weights, yolov5nu_conv35_bias, tensor_125, yolov5nu_silu_lut35, 64, 0.007141524604f, 1200, 128, 0.1213865206f, 0.08279894292f, 0.1213865206f, SILU_LUT);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/cv1/act/Mul", silu_config_cycles[34]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/cv2/act/Mul", silu_config_cycles[35]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut36);
    gemmini_fence();
    silu_config_cycles[36] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_124, yolov5nu_conv36_weights, yolov5nu_conv36_bias, tensor_128, SILU_LUT, 0.007897585344f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/m/m.0/cv1/act/Mul", silu_config_cycles[36]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut37);
    gemmini_fence();
    silu_config_cycles[37] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_128, yolov5nu_conv37_weights, yolov5nu_conv37_bias, tensor_131, SILU_LUT, 0.004006242932f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/m/m.0/cv2/act/Mul", silu_config_cycles[37]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.13/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.13/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.13/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut38);
    gemmini_fence();
    silu_config_cycles[38] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.13/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_131, tensor_125, yolov5nu_conv38_weights, yolov5nu_conv38_bias, tensor_135, 1200, 64, 128, 0.05149115995f, 0.06069298461f, 0.06069298461f, SILU_LUT, 0.006135813777f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/cv3/act/Mul", silu_config_cycles[38]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.14/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut39);
    gemmini_fence();
    silu_config_cycles[39] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.14/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 128, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_135, yolov5nu_conv39_weights, yolov5nu_conv39_bias, tensor_138, SILU_LUT, 0.004522892681f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.14/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.14/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.14/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.14/act/Mul", silu_config_cycles[39]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_RESIZE, "Resize", "/model.15/Resize");
  resize_nearest_nhwc_i8(tensor_138, tensor_139, 1, 64, 30, 40, 60, 80, 0.05789077654f, 0.05789077654f);

    yolo_profile_add(PROFILE_RESIZE, "Resize", "/model.15/Resize", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.16/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.16/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.16/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut40);
    gemmini_fence();
    silu_config_cycles[40] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.16/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.16/Concat consumer2 */
    gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(tensor_139, tensor_50, yolov5nu_conv40_weights, yolov5nu_conv40_bias, tensor_145, yolov5nu_silu_lut40, 32, 0.005177699727f, yolov5nu_conv41_weights, yolov5nu_conv41_bias, tensor_146, yolov5nu_silu_lut41, 32, 0.01157049023f, 4800, 64, 0.05789077654f, 0.07490173727f, 0.07490173727f, SILU_LUT);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/cv1/act/Mul", silu_config_cycles[40]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/cv2/act/Mul", silu_config_cycles[41]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut42);
    gemmini_fence();
    silu_config_cycles[42] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 32, 32, 60, 80, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_145, yolov5nu_conv42_weights, yolov5nu_conv42_bias, tensor_149, SILU_LUT, 0.01096224029f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/m/m.0/cv1/act/Mul", silu_config_cycles[42]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut43);
    gemmini_fence();
    silu_config_cycles[43] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 32, 32, 60, 80, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_149, yolov5nu_conv43_weights, yolov5nu_conv43_bias, tensor_152, SILU_LUT, 0.007997243001f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/m/m.0/cv2/act/Mul", silu_config_cycles[43]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.17/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.17/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.17/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut44);
    gemmini_fence();
    silu_config_cycles[44] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.17/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_152, tensor_146, yolov5nu_conv44_weights, yolov5nu_conv44_bias, tensor_156, 4800, 32, 64, 0.04420842975f, 0.03035970405f, 0.04420842975f, SILU_LUT, 0.006948814567f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/cv3/act/Mul", silu_config_cycles[44]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.18/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut45);
    gemmini_fence();
    silu_config_cycles[45] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.18/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 64, 30, 40, 2, 1, 1, 1, 3, false, false, false, false, false, tensor_156, yolov5nu_conv45_weights, yolov5nu_conv45_bias, tensor_163, SILU_LUT, 0.003387071316f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.18/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.18/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.18/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut46);
    gemmini_fence();
    silu_config_cycles[46] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.0/cv2.0.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 64, 60, 80, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_156, yolov5nu_conv46_weights, yolov5nu_conv46_bias, tensor_164, SILU_LUT, 0.00524313854f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.0/cv2.0.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.0/cv2.0.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.0/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut47);
    gemmini_fence();
    silu_config_cycles[47] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.0/cv3.0.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 80, 60, 80, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_156, yolov5nu_conv47_weights, yolov5nu_conv47_bias, tensor_165, SILU_LUT, 0.005355681244f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.0/cv3.0.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.0/cv3.0.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.0/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.18/act/Mul", silu_config_cycles[45]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.0/cv2.0.0/act/Mul", silu_config_cycles[46]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.0/cv3.0.0/act/Mul", silu_config_cycles[47]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.19/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.19/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.19/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut48);
    gemmini_fence();
    silu_config_cycles[48] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.0/cv2.0.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 64, 60, 80, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_164, yolov5nu_conv48_weights, yolov5nu_conv48_bias, tensor_175, SILU_LUT, 0.007350884262f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.0/cv2.0.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.0/cv2.0.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut49);
    gemmini_fence();
    silu_config_cycles[49] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.0/cv3.0.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 80, 80, 60, 80, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_165, yolov5nu_conv49_weights, yolov5nu_conv49_bias, tensor_176, SILU_LUT, 0.004613805264f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.0/cv3.0.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.0/cv3.0.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut50);
    gemmini_fence();
    silu_config_cycles[50] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.19/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.19/Concat consumer2 */
    gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(tensor_163, tensor_138, yolov5nu_conv50_weights, yolov5nu_conv50_bias, tensor_177, yolov5nu_silu_lut50, 64, 0.008054941389f, yolov5nu_conv51_weights, yolov5nu_conv51_bias, tensor_178, yolov5nu_silu_lut51, 64, 0.01073939886f, 1200, 64, 0.06576365978f, 0.05789077654f, 0.06576365978f, SILU_LUT);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.0/cv2.0.1/act/Mul", silu_config_cycles[48]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.0/cv3.0.1/act/Mul", silu_config_cycles[49]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/cv1/act/Mul", silu_config_cycles[50]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/cv2/act/Mul", silu_config_cycles[51]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.0/cv2.0.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 64, 64, 60, 80, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_175, yolov5nu_conv52_weights, yolov5nu_conv52_bias, tensor_179, NO_ACTIVATION, 0.00497773409f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.0/cv2.0.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.0/cv2.0.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.2/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.0/cv3.0.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 60, 80, 80, 80, 60, 80, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_176, yolov5nu_conv53_weights, yolov5nu_conv53_bias, tensor_180, NO_ACTIVATION, 0.003811468887f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.0/cv3.0.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.0/cv3.0.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.2/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut52);
    gemmini_fence();
    silu_config_cycles[52] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_177, yolov5nu_conv54_weights, yolov5nu_conv54_bias, tensor_185, SILU_LUT, 0.006991897853f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/m/m.0/cv1/act/Mul", silu_config_cycles[52]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut53);
    gemmini_fence();
    silu_config_cycles[53] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_185, yolov5nu_conv55_weights, yolov5nu_conv55_bias, tensor_188, SILU_LUT, 0.005644260133f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/m/m.0/cv2/act/Mul", silu_config_cycles[53]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.20/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.20/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.20/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut54);
    gemmini_fence();
    silu_config_cycles[54] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.20/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_188, tensor_178, yolov5nu_conv56_weights, yolov5nu_conv56_bias, tensor_192, 1200, 64, 128, 0.05829130486f, 0.05274593085f, 0.05829130486f, SILU_LUT, 0.0072781782f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/cv3/act/Mul", silu_config_cycles[54]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.21/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut55);
    gemmini_fence();
    silu_config_cycles[55] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.21/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 128, 128, 15, 20, 2, 1, 1, 1, 3, false, false, false, false, false, tensor_192, yolov5nu_conv57_weights, yolov5nu_conv57_bias, tensor_199, SILU_LUT, 0.003624919536f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.21/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.21/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.21/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut56);
    gemmini_fence();
    silu_config_cycles[56] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.1/cv2.1.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 128, 64, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_192, yolov5nu_conv58_weights, yolov5nu_conv58_bias, tensor_200, SILU_LUT, 0.005439083025f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.1/cv2.1.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.1/cv2.1.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.0/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut57);
    gemmini_fence();
    silu_config_cycles[57] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.1/cv3.1.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 128, 80, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_192, yolov5nu_conv59_weights, yolov5nu_conv59_bias, tensor_201, SILU_LUT, 0.002879538599f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.1/cv3.1.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.1/cv3.1.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.0/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.21/act/Mul", silu_config_cycles[55]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.1/cv2.1.0/act/Mul", silu_config_cycles[56]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.1/cv3.1.0/act/Mul", silu_config_cycles[57]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.22/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.22/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.22/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut58);
    gemmini_fence();
    silu_config_cycles[58] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.1/cv2.1.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_200, yolov5nu_conv60_weights, yolov5nu_conv60_bias, tensor_211, SILU_LUT, 0.008934123201f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.1/cv2.1.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.1/cv2.1.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut59);
    gemmini_fence();
    silu_config_cycles[59] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.1/cv3.1.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 80, 80, 30, 40, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_201, yolov5nu_conv61_weights, yolov5nu_conv61_bias, tensor_212, SILU_LUT, 0.009291129964f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.1/cv3.1.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.1/cv3.1.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut60);
    gemmini_fence();
    silu_config_cycles[60] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.22/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.22/Concat consumer2 */
    gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(tensor_199, tensor_117, yolov5nu_conv62_weights, yolov5nu_conv62_bias, tensor_213, yolov5nu_silu_lut60, 128, 0.0170837864f, yolov5nu_conv63_weights, yolov5nu_conv63_bias, tensor_214, yolov5nu_silu_lut61, 128, 0.008826090021f, 300, 128, 0.08172133565f, 0.1213865206f, 0.1213865206f, SILU_LUT);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.1/cv2.1.1/act/Mul", silu_config_cycles[58]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.1/cv3.1.1/act/Mul", silu_config_cycles[59]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/cv1/act/Mul", silu_config_cycles[60]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/cv2/act/Mul", silu_config_cycles[61]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.1/cv2.1.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 64, 64, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_211, yolov5nu_conv64_weights, yolov5nu_conv64_bias, tensor_215, NO_ACTIVATION, 0.006079990314f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.1/cv2.1.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.1/cv2.1.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.2/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.1/cv3.1.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 30, 40, 80, 80, 30, 40, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_212, yolov5nu_conv65_weights, yolov5nu_conv65_bias, tensor_216, NO_ACTIVATION, 0.004823161851f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.1/cv3.1.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.1/cv3.1.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.2/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut62);
    gemmini_fence();
    silu_config_cycles[62] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 128, 128, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_213, yolov5nu_conv66_weights, yolov5nu_conv66_bias, tensor_221, SILU_LUT, 0.008824693316f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/m/m.0/cv1/act/Mul", silu_config_cycles[62]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut63);
    gemmini_fence();
    silu_config_cycles[63] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 128, 128, 15, 20, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_221, yolov5nu_conv67_weights, yolov5nu_conv67_bias, tensor_224, SILU_LUT, 0.003316656368f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/m/m.0/cv2/act/Mul", silu_config_cycles[63]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.23/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.23/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.23/Concat", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut64);
    gemmini_fence();
    silu_config_cycles[64] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.23/Concat */
    gemmini_splitk_1x1_two_slice_i8(tensor_224, tensor_214, yolov5nu_conv68_weights, yolov5nu_conv68_bias, tensor_228, 300, 128, 256, 0.09251318872f, 0.0593306385f, 0.09251318872f, SILU_LUT, 0.01019811998f);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/cv3/act/Mul", silu_config_cycles[64]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut65);
    gemmini_fence();
    silu_config_cycles[65] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.2/cv2.2.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 256, 64, 15, 20, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_228, yolov5nu_conv69_weights, yolov5nu_conv69_bias, tensor_233, SILU_LUT, 0.003791882997f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.2/cv2.2.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.2/cv2.2.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.0/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut66);
    gemmini_fence();
    silu_config_cycles[66] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.2/cv3.2.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 256, 80, 15, 20, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_228, yolov5nu_conv70_weights, yolov5nu_conv70_bias, tensor_234, SILU_LUT, 0.003693605405f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.2/cv3.2.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.2/cv3.2.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.0/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.2/cv2.2.0/act/Mul", silu_config_cycles[65]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.2/cv3.2.0/act/Mul", silu_config_cycles[66]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut67);
    gemmini_fence();
    silu_config_cycles[67] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.2/cv2.2.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 64, 64, 15, 20, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_233, yolov5nu_conv71_weights, yolov5nu_conv71_bias, tensor_239, SILU_LUT, 0.005602139273f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.2/cv2.2.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.2/cv2.2.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    gemmini_config_silu_lut(yolov5nu_silu_lut68);
    gemmini_fence();
    silu_config_cycles[68] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.2/cv3.2.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 80, 80, 15, 20, 1, 1, 1, 1, 3, false, false, false, false, false, tensor_234, yolov5nu_conv72_weights, yolov5nu_conv72_bias, tensor_240, SILU_LUT, 0.007345166871f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.2/cv3.2.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.2/cv3.2.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.1/conv/Conv", yolo_profile_clock() - op_start);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.2/cv2.2.1/act/Mul", silu_config_cycles[67]);
  }
  {
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.2/cv3.2.1/act/Mul", silu_config_cycles[68]);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.2/cv2.2.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 64, 64, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_239, yolov5nu_conv73_weights, yolov5nu_conv73_bias, tensor_241, NO_ACTIVATION, 0.007988214559f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.2/cv2.2.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.2/cv2.2.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.2/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.2/cv3.2.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    tiled_conv_auto(1, 15, 20, 80, 80, 15, 20, 1, 1, 1, 0, 1, false, false, false, false, false, tensor_240, yolov5nu_conv74_weights, yolov5nu_conv74_bias, tensor_242, NO_ACTIVATION, 0.004325870487f, 1, 0, 0, WS);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.2/cv3.2.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.2/cv3.2.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.2/Conv", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_HEAD_CLASS, "HEAD_CLASS", "location-major");
  stage4_class_heads_i8(tensor_180, 4800, 0.2354075164f, tensor_216, 1200, 0.3665552139f, tensor_242, 300, 0.449272126f, tensor_246, tensor_248, 0.449272126f, yolov5nu_sigmoid_lut0, 0.007530334406f, 0.25f);
    yolo_profile_add(PROFILE_HEAD_CLASS, "HEAD_CLASS", "location-major", yolo_profile_clock() - op_start);
  }
  {
    uint64_t op_start = yolo_profile_begin(PROFILE_HEAD_DFL, "HEAD_DFL", "location-major");
  stage4_dfl_heads_i8(tensor_179, 4800, 0.2151331604f, tensor_215, 1200, 0.1472641826f, tensor_241, 300, 0.1159213334f, tensor_245, tensor_252, 0.2151331604f, 0.007874015719f, 0.1181102395f, 0.1129496917f, yolov5nu_conv75_weights, yolov5nu_softmax_exp_lut0);
    yolo_profile_add(PROFILE_HEAD_DFL, "HEAD_DFL", "location-major", yolo_profile_clock() - op_start);
  }
  uint64_t graph_cycles = yolo_profile_clock() - graph_start;

  print_tensor_summary("YOLOv5nu class logits", tensor_246, 504000);
  print_tensor_summary("YOLOv5nu class sigmoid", tensor_248, 504000);
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  print_sparse_dfl_summary("YOLOv5nu DFL distances", tensor_252,
    dfl_candidate_mask, 6300);
#else
  print_tensor_summary("YOLOv5nu DFL distances", tensor_252, 25200);
#endif
  struct Detection top_detections[10];
  struct Detection nms_detections[10];
  uint64_t decode_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
  decode_all_compute(tensor_252, 0.1129496917f, tensor_248,
    0.007530334406f);
  decode_top_from_candidates(top_detections);
#else
  decode_top_compute(tensor_252, 0.1129496917f, tensor_248,
    0.007530334406f, top_detections);
#endif
  uint64_t decode_cycles = yolo_profile_clock() - decode_start;
  yolo_profile_add(PROFILE_DECODE, "DECODE", "top", decode_cycles);
  print_top_detections(top_detections);
  uint64_t nms_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
  int nms_count = decode_nms_from_candidates(0.25f,
    0.45f, nms_detections);
#else
  int nms_count = decode_nms_compute(tensor_252, 0.1129496917f,
    tensor_248, 0.007530334406f, 0.25f,
    0.45f, nms_detections);
#endif
  uint64_t nms_cycles = yolo_profile_clock() - nms_start;
  yolo_profile_add(PROFILE_NMS, "NMS", "class_aware_greedy", nms_cycles);
  print_nms_detections(nms_detections, nms_count, 0.25f,
    0.45f);
  yolo_profile_print_report(graph_cycles, decode_cycles, nms_cycles);
  printf("PASS\n");
  exit(0);
}
