#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define GEMMINI_POOL_RUNTIME_DISPATCH 1
#include "include/gemmini.h"
#include "fixed_plans_guard.inc"
#include "fixed_conv_packets.inc"
#include "prepared_packets.inc"
#include "software_batch_packets.inc"
#include "include/gemmini_nn.h"
#include "include/yolov5nu_silu_opencv_rvv.h"
#include "include/yolov5nu_silu_lut_rvv.h"
#include "include/yolov5nu_stage3_rvv.h"
#include "include/yolov5nu_stage4_rvv.h"
#include "memory_kernels_runtime.inc"
#include "yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h"
#include "yolov5nu_dim16_dual.h"
#include "yolov5nu_head_layout.h"
struct yolo32_splitk_tile { size_t row, rows, i_blocks, pad_i; };
struct yolo32_splitk_plan {
  unsigned tile_count;
  const struct yolo32_splitk_tile *tiles;
  size_t j_blocks[2], channels[4], k_blocks[4], pad_k[4];
};
static const struct yolo32_splitk_tile splitk_tiles_14[] = {{0,1024,32,0},{1024,1024,32,0},{2048,1024,32,0},{3072,1024,32,0},{4096,1024,32,0},{5120,1024,32,0},{6144,1024,32,0},{7168,1024,32,0},{8192,1024,32,0},{9216,1024,32,0},{10240,1024,32,0},{11264,1024,32,0},{12288,1024,32,0},{13312,1024,32,0},{14336,1024,32,0},{15360,1024,32,0},{16384,1024,32,0},{17408,1024,32,0},{18432,768,24,0}};
static const struct yolo32_splitk_plan splitk_plan_14 = {19, splitk_tiles_14, {1,0},{16,16,0,0},{1,1,0,0},{16,16,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_33[] = {{0,512,16,0},{512,512,16,0},{1024,512,16,0},{1536,512,16,0},{2048,512,16,0},{2560,512,16,0},{3072,512,16,0},{3584,512,16,0},{4096,512,16,0},{4608,192,6,0}};
static const struct yolo32_splitk_plan splitk_plan_33 = {10, splitk_tiles_33, {2,0},{32,32,0,0},{1,1,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_57[] = {{0,256,8,0},{256,256,8,0},{512,256,8,0},{768,256,8,0},{1024,176,6,16}};
static const struct yolo32_splitk_plan splitk_plan_57 = {5, splitk_tiles_57, {4,0},{64,64,0,0},{2,2,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_71[] = {{0,128,4,0},{128,128,4,0},{256,44,2,20}};
static const struct yolo32_splitk_plan splitk_plan_71 = {3, splitk_tiles_71, {8,0},{128,128,0,0},{4,4,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_79[] = {{0,128,4,0},{128,128,4,0},{256,44,2,20}};
static const struct yolo32_splitk_plan splitk_plan_79 = {3, splitk_tiles_79, {8,0},{128,128,128,128},{4,4,4,4},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_85[] = {{0,512,16,0},{512,512,16,0},{1024,176,6,16}};
static const struct yolo32_splitk_plan splitk_plan_85 = {3, splitk_tiles_85, {2,2},{128,128,0,0},{4,4,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_93[] = {{0,256,8,0},{256,256,8,0},{512,256,8,0},{768,256,8,0},{1024,176,6,16}};
static const struct yolo32_splitk_plan splitk_plan_93 = {5, splitk_tiles_93, {4,0},{64,64,0,0},{2,2,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_99[] = {{0,1024,32,0},{1024,1024,32,0},{2048,1024,32,0},{3072,1024,32,0},{4096,704,22,0}};
static const struct yolo32_splitk_plan splitk_plan_99 = {5, splitk_tiles_99, {1,1},{64,64,0,0},{2,2,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_107[] = {{0,512,16,0},{512,512,16,0},{1024,512,16,0},{1536,512,16,0},{2048,512,16,0},{2560,512,16,0},{3072,512,16,0},{3584,512,16,0},{4096,512,16,0},{4608,192,6,0}};
static const struct yolo32_splitk_plan splitk_plan_107 = {10, splitk_tiles_107, {2,0},{32,32,0,0},{1,1,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_118[] = {{0,512,16,0},{512,512,16,0},{1024,176,6,16}};
static const struct yolo32_splitk_plan splitk_plan_118 = {3, splitk_tiles_118, {2,2},{64,64,0,0},{2,2,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_130[] = {{0,256,8,0},{256,256,8,0},{512,256,8,0},{768,256,8,0},{1024,176,6,16}};
static const struct yolo32_splitk_plan splitk_plan_130 = {5, splitk_tiles_130, {4,0},{64,64,0,0},{2,2,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_141[] = {{0,256,8,0},{256,44,2,20}};
static const struct yolo32_splitk_plan splitk_plan_141 = {2, splitk_tiles_141, {4,4},{128,128,0,0},{4,4,0,0},{0,0,0,0}};
static const struct yolo32_splitk_tile splitk_tiles_153[] = {{0,128,4,0},{128,128,4,0},{256,44,2,20}};
static const struct yolo32_splitk_plan splitk_plan_153 = {3, splitk_tiles_153, {8,0},{128,128,0,0},{4,4,0,0},{0,0,0,0}};

#if DIM != YOLOV5NU_GEMMINI_DIM
#error "Gemmini parameters do not match the selected video SoC"
#endif

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

static struct yolov5nu_dim16_profile
  frame_profiles[YOLOV5NU_DIM16_WORKER_COUNT];

static inline uint64_t yolo_frame_profile_clock(void) {
  uint64_t value;
  if (!analysis_enabled) return 0;
  asm volatile("rdcycle %0" : "=r"(value));
  return value;
}

#if YOLOV5NU_PROFILE
#define YOLOV5NU_PROFILE_MAX_RECORDS 512
static struct YoloProfileRecord yolo_profile_records[YOLOV5NU_PROFILE_MAX_RECORDS];
static int yolo_profile_record_count;

static inline void yolo_profile_reset(void) {
  yolo_profile_record_count = 0;
}

static inline uint64_t yolo_profile_clock(void) {
  return yolo_frame_profile_clock();
}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {
  (void)kind; (void)kind_name; (void)name;
  return yolo_profile_clock();
}

static void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {
  struct yolov5nu_dim16_profile *profile =
    &frame_profiles[gemmini_pool_active_worker];
  if (kind == PROFILE_CONV_GEMMINI)
    profile->rocc_submit_cycles += cycles;
  else if (kind == PROFILE_MAXPOOL)
    profile->rvv_maxpool_cycles += cycles;
  else if (kind == PROFILE_RESIZE)
    profile->rvv_resize_cycles += cycles;
  else if (kind == PROFILE_ADD || kind == PROFILE_CONCAT ||
           kind == PROFILE_RESHAPE || kind == PROFILE_TRANSPOSE ||
           kind == PROFILE_CONV_IN_LAYOUT ||
           kind == PROFILE_CONV_OUT_LAYOUT ||
           kind == PROFILE_HEAD_CLASS || kind == PROFILE_HEAD_DFL)
    profile->rvv_copy_requant_cycles += cycles;
  if (yolo_profile_record_count < YOLOV5NU_PROFILE_MAX_RECORDS) {
    yolo_profile_records[yolo_profile_record_count++] = (struct YoloProfileRecord){
      kind, kind_name, name, cycles
    };
  }
}
#else
static inline void yolo_profile_reset(void) {}

static inline uint64_t yolo_profile_clock(void) {
  return yolo_frame_profile_clock();
}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {
  (void)kind; (void)kind_name; (void)name;
  return yolo_profile_clock();
}
static inline void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {
  struct yolov5nu_dim16_profile *profile =
    &frame_profiles[gemmini_pool_active_worker];
  (void)kind_name; (void)name;
  if (kind == PROFILE_CONV_GEMMINI)
    profile->rocc_submit_cycles += cycles;
  else if (kind == PROFILE_MAXPOOL)
    profile->rvv_maxpool_cycles += cycles;
  else if (kind == PROFILE_RESIZE)
    profile->rvv_resize_cycles += cycles;
  else if (kind == PROFILE_ADD || kind == PROFILE_CONCAT ||
           kind == PROFILE_RESHAPE || kind == PROFILE_TRANSPOSE ||
           kind == PROFILE_CONV_IN_LAYOUT ||
           kind == PROFILE_CONV_OUT_LAYOUT ||
           kind == PROFILE_HEAD_CLASS || kind == PROFILE_HEAD_DFL)
    profile->rvv_copy_requant_cycles += cycles;
}
#endif

static inline void yolo_profile_fence(void) {
  uint64_t start = yolo_frame_profile_clock();
  if (yolo32_independent_enabled) yolo32_independent_wait();
  else asm volatile("fence" ::: "memory");
  frame_profiles[gemmini_pool_active_worker].fence_cycles +=
    yolo_frame_profile_clock() - start;
}

#undef gemmini_fence
#define gemmini_fence() yolo_profile_fence()

enum {
  FRAME_COUNTER_BUSY = 0,
  FRAME_COUNTER_LOAD_DMA_WAIT,
  FRAME_COUNTER_LOAD_SPAD_WAIT,
  FRAME_COUNTER_EXEC_ACTIVE,
  FRAME_COUNTER_STORE_DMA_WAIT,
  FRAME_COUNTER_STORE_SPAD_WAIT
};

static uint32_t frame_counter_access(uint32_t worker_id, uint32_t config) {
  uint32_t result;
  uint32_t placeholder = 0U;
  if (worker_id == 0U) {
    ROCC_INSTRUCTION(3, result, config, placeholder, k_COUNTER);
  } else if (worker_id == 1U) {
    ROCC_INSTRUCTION(2, result, config, placeholder, k_COUNTER);
  } else {
    ROCC_INSTRUCTION(1, result, config, placeholder, k_COUNTER);
  }
  return result;
}

static void frame_counter_reset(uint32_t worker_id) {
  (void)frame_counter_access(worker_id, 0x1U);
}

static void frame_counter_configure(uint32_t worker_id, uint32_t index,
                                    uint32_t event) {
  uint32_t config = ((index & 7U) << 4) | 0x8U |
                    ((event & 0x3fU) << 12);
  (void)frame_counter_access(worker_id, config);
}

static uint32_t frame_counter_read(uint32_t worker_id, uint32_t index) {
  return frame_counter_access(worker_id, (index & 7U) << 4);
}

static void frame_counter_start(uint32_t worker_id) {
  memset(&frame_profiles[worker_id], 0, sizeof(frame_profiles[worker_id]));
  if (!analysis_enabled) return;
  frame_counter_reset(worker_id);
  frame_counter_configure(worker_id, FRAME_COUNTER_BUSY,
                          RESERVATION_STATION_ACTIVE_CYCLES);
  frame_counter_configure(worker_id, FRAME_COUNTER_LOAD_DMA_WAIT,
                          LOAD_DMA_WAIT_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_LOAD_SPAD_WAIT,
                          LOAD_SCRATCHPAD_WAIT_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_EXEC_ACTIVE,
                          EXE_ACTIVE_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_STORE_DMA_WAIT,
                          STORE_DMA_WAIT_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_STORE_SPAD_WAIT,
                          STORE_SCRATCHPAD_WAIT_CYCLE);
}

static void frame_counter_finish(uint32_t worker_id) {
  if (!analysis_enabled) return;
  struct yolov5nu_dim16_profile *profile = &frame_profiles[worker_id];
  (void)frame_counter_access(worker_id, 0x4U);
  profile->rs_active = frame_counter_read(worker_id, FRAME_COUNTER_BUSY);
  profile->load_dma_wait = frame_counter_read(worker_id, FRAME_COUNTER_LOAD_DMA_WAIT);
  profile->load_spad_wait = frame_counter_read(worker_id, FRAME_COUNTER_LOAD_SPAD_WAIT);
  profile->exec_active = frame_counter_read(worker_id, FRAME_COUNTER_EXEC_ACTIVE);
  profile->store_dma_wait = frame_counter_read(worker_id, FRAME_COUNTER_STORE_DMA_WAIT);
  profile->store_spad_wait = frame_counter_read(worker_id, FRAME_COUNTER_STORE_SPAD_WAIT);
  profile->gemmini_busy_cycles = profile->rs_active;
  profile->gemmini_load_stall_cycles = profile->load_dma_wait + profile->load_spad_wait;
  profile->gemmini_exec_cycles = profile->exec_active;
  profile->gemmini_store_stall_cycles = profile->store_dma_wait + profile->store_spad_wait;
}

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

static elem_t activation_arenas[YOLOV5NU_DIM16_WORKER_COUNT][2217600] __attribute__((aligned(64)));
static elem_t *activation_arena;
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
static elem_t conv_input_scratches[YOLOV5NU_DIM16_WORKER_COUNT][YOLOV5NU_CONV_INPUT_SCRATCH] row_align(1);
static elem_t *conv_input_scratch;
static elem_t conv_output_scratches[YOLOV5NU_DIM16_WORKER_COUNT][YOLOV5NU_CONV_OUTPUT_SCRATCH] row_align(1);
static elem_t *conv_output_scratch;
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
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled && i + i_tile == (size_t)positions) yolo32_independent_arm_tail_wait(8U);
#endif
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
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled && i + i_tile == (size_t)positions) yolo32_independent_arm_tail_wait(8U);
#endif
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
    int act, float output_scale, const struct yolo32_splitk_plan *fixed_plan) {
  if (slice_channels <= 0 || out_channels <= 0) {
    printf("Stage 8C split-K geometry mismatch\n");
    exit(1);
  }
  const size_t j_blocks = fixed_plan->j_blocks[0];
  const size_t k_blocks = fixed_plan->k_blocks[0];
  const size_t pad_k = fixed_plan->pad_k[0];


  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended_config_st((size_t)out_channels * sizeof(elem_t),
    act & 7, output_scale);
  gemmini_extended3_config_ld((size_t)out_channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (unsigned tile = 0; tile < fixed_plan->tile_count; ++tile) {
    const struct yolo32_splitk_tile *geometry = &fixed_plan->tiles[tile];
    const size_t row = geometry->row;
    const size_t i_blocks = geometry->i_blocks;
    const size_t pad_i = geometry->pad_i;

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      a0 + row * slice_channels, weights, bias, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, j_blocks * DIM - out_channels, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, false, true, act, 0, 0);
    // The load scale is global state. Complete partial 0 before changing it;
    // the accumulator contents survive the fence because no mvout was issued.
    gemmini_fence();

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      a1 + row * slice_channels,
      weights + slice_channels * out_channels, NULL,
      output + row * out_channels,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, j_blocks * DIM - out_channels, pad_k,
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
  if (slice_channels <= 0 || out_channels <= 0) {
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
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      reuse_a ? NULL : a0 + row * slice_channels, weights, bias, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, j_blocks * DIM - out_channels, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, false, true, act, a0_spad_id, 0);
    gemmini_fence();

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      reuse_a ? NULL : a1 + row * slice_channels,
      weights + slice_channels * out_channels, NULL,
      output + row * out_channels,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, j_blocks * DIM - out_channels, pad_k,
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
    float concat_scale, int act, const struct yolo32_splitk_plan *fixed_plan) {
  if (slice_channels <= 0 || out_channels0 <= 0 || out_channels1 <= 0) {
    printf("Stage 8F pair split-K geometry mismatch\n");
    exit(1);
  }
  const size_t j_blocks0 = fixed_plan->j_blocks[0];
  const size_t j_blocks1 = fixed_plan->j_blocks[1];
  const size_t k_blocks = fixed_plan->k_blocks[0];
  const size_t pad_k = fixed_plan->pad_k[0];


  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended3_config_ld((size_t)out_channels0 * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (unsigned tile = 0; tile < fixed_plan->tile_count; ++tile) {
    const struct yolo32_splitk_tile *geometry = &fixed_plan->tiles[tile];
    const size_t row = geometry->row;
    const size_t i_blocks0 = geometry->i_blocks;
    const size_t i_blocks1 = geometry->i_blocks;
    const size_t pad_i = geometry->pad_i;

    // Consumer 0 loads each A slice once and keeps its private accumulator.
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      a0 + row * slice_channels, weights0, bias0, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks0, j_blocks0, k_blocks, pad_i, j_blocks0 * DIM - out_channels0, pad_k,
      slice_channels, out_channels0, out_channels0, out_channels0,
      false, false, false, false, false, true, act, 1, 0);
    gemmini_fence();

    gemmini_config_silu_lut(silu_lut0);
    gemmini_fence();
    gemmini_extended_config_st((size_t)out_channels0 * sizeof(elem_t),
      act & 7, requant0);
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      a1 + row * slice_channels,
      weights0 + slice_channels * out_channels0, NULL,
      output0 + row * out_channels0,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks0, j_blocks0, k_blocks, pad_i, j_blocks0 * DIM - out_channels0, pad_k,
      slice_channels, out_channels0, out_channels0, out_channels0,
      false, false, false, false, true, false, act, 2, 0);
    gemmini_fence();

    // Consumer 1 reuses both A partitions; only B, bias, accumulator and
    // output differ.  A=NULL is translated to the skip-A loop macro.
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      NULL, weights1, bias1, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks1, j_blocks1, k_blocks, pad_i, j_blocks1 * DIM - out_channels1, pad_k,
      slice_channels, out_channels1, out_channels1, out_channels1,
      false, false, false, false, false, true, act, 1, 0);
    gemmini_fence();

    gemmini_config_silu_lut(silu_lut1);
    gemmini_fence();
    gemmini_extended_config_st((size_t)out_channels1 * sizeof(elem_t),
      act & 7, requant1);
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
#if YOLO32_TAIL_WAIT
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
    sp_tiled_matmul_ws(
      NULL, weights1 + slice_channels * out_channels1, NULL,
      output1 + row * out_channels1,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks1, j_blocks1, k_blocks, pad_i, j_blocks1 * DIM - out_channels1, pad_k,
      slice_channels, out_channels1, out_channels1, out_channels1,
      false, false, false, false, true, false, act, 2, 0);
    gemmini_fence();
  }
}

static void gemmini_splitk_1x1_multi_slice_i8(
    const elem_t *const inputs[], const int slice_channels[],
    const float input_scales[], int slice_count, const elem_t *weights,
    const acc_t *bias, elem_t *output, int positions, int out_channels,
    float concat_scale, int act, float output_scale, const struct yolo32_splitk_plan *fixed_plan) {
  if (slice_count <= 1 || out_channels <= 0) {
    printf("Stage 8C multi-slice geometry mismatch\n");
    exit(1);
  }
  const size_t j_blocks = fixed_plan->j_blocks[0];


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

  for (unsigned tile = 0; tile < fixed_plan->tile_count; ++tile) {
    const struct yolo32_splitk_tile *geometry = &fixed_plan->tiles[tile];
    const size_t row = geometry->row;
    const size_t i_blocks = geometry->i_blocks;
    const size_t pad_i = geometry->pad_i;
    size_t weight_channel_offset = 0;
    for (int slice = 0; slice < slice_count; slice++) {
      const size_t channels = fixed_plan->channels[slice];
      const size_t k_blocks = fixed_plan->k_blocks[slice];
      const size_t pad_k = fixed_plan->pad_k[slice];
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
  #if YOLO32_TAIL_WAIT
#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
    if (yolo32_independent_enabled &&
        (last || input_scales[slice] != input_scales[slice + 1]))
        yolo32_independent_arm_tail_wait(8U);
#else
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
#endif
#endif
    sp_tiled_matmul_ws(
        inputs[slice] + row * channels,
        weights + weight_channel_offset * out_channels,
        first ? bias : NULL,
        last ? output + row * out_channels : NULL,
        input_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
        i_blocks, j_blocks, k_blocks, pad_i, j_blocks * DIM - out_channels, pad_k,
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



unsigned gemmini_pool_active_worker;

enum { YOLOV5NU_GRAPH_STAGE_COUNT = 167U };

struct yolov5nu_worker_context {
  const elem_t *input;
  elem_t *head_slot;
  uint32_t stage;
  uint32_t active;
  uint32_t waiting;
  uint32_t poll_armed;
  uint32_t hardware_head;
  uint64_t silu_config_cycles[69];
};

static struct yolov5nu_worker_context
  worker_contexts[YOLOV5NU_DIM16_WORKER_COUNT];

static elem_t *head_pointer(elem_t *slot, uintptr_t offset,
                            elem_t *legacy) {
  return slot != NULL ? slot + offset : legacy;
}

#define raw_class0 head_pointer(context->head_slot, \
    YOLOV5NU_HEAD_CLASS0_OFFSET, tensor_180)
#define raw_class1 head_pointer(context->head_slot, \
    YOLOV5NU_HEAD_CLASS1_OFFSET, tensor_216)
#define raw_class2 head_pointer(context->head_slot, \
    YOLOV5NU_HEAD_CLASS2_OFFSET, tensor_242)
#define raw_dfl0 head_pointer(context->head_slot, \
    YOLOV5NU_HEAD_DFL0_OFFSET, tensor_179)
#define raw_dfl1 head_pointer(context->head_slot, \
    YOLOV5NU_HEAD_DFL1_OFFSET, tensor_215)
#define raw_dfl2 head_pointer(context->head_slot, \
    YOLOV5NU_HEAD_DFL2_OFFSET, tensor_241)

static inline uint64_t read_worker_busy(uint32_t worker_id) {
  uint64_t value;
  if (worker_id == 0U)
    __asm__ volatile ("csrr %0, 0x7c2" : "=r" (value) :: "memory");
  else if (worker_id == 1U)
    __asm__ volatile ("csrr %0, 0x7c3" : "=r" (value) :: "memory");
  else
    __asm__ volatile ("csrr %0, 0x7ca" : "=r" (value) :: "memory");
  return value & 1U;
}

static void select_worker_memory(uint32_t worker_id) {
  gemmini_pool_active_worker = worker_id;
  activation_arena = activation_arenas[worker_id];
  conv_input_scratch = conv_input_scratches[worker_id];
  conv_output_scratch = conv_output_scratches[worker_id];
}

static void yolo32_batch_bind_init(void);
static void yolo32_batch_bind_start(unsigned);
static void (*head_callback)(unsigned, unsigned);
void yolov5nu_dim16_set_head_callback(void (*callback)(unsigned, unsigned)) { head_callback = callback; }
void yolov5nu_dim16_dual_init(void) {
  memset(worker_contexts, 0, sizeof(worker_contexts));
  yolo32_batch_bind_init();
  gemmini_pool_active_worker = 0U;
}

int yolov5nu_dim16_worker_is_idle(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT &&
         worker_contexts[worker_id].active == 0U;
}

void yolov5nu_dim16_worker_use_hardware(uint32_t worker_id, int enabled) {
  if (worker_id < YOLOV5NU_DIM16_WORKER_COUNT)
    worker_contexts[worker_id].hardware_head = enabled != 0;
}

uintptr_t yolov5nu_dim16_worker_arena(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT ?
         (uintptr_t)activation_arenas[worker_id] : 0;
}

void yolov5nu_dim16_worker_set_head_slot(uint32_t worker_id,
    uintptr_t head_slot_addr) {
  if (worker_id < YOLOV5NU_DIM16_WORKER_COUNT)
    worker_contexts[worker_id].head_slot = (elem_t *)head_slot_addr;
}

uintptr_t yolov5nu_dim16_worker_head_slot(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT ?
         (uintptr_t)worker_contexts[worker_id].head_slot : 0;
}

void yolov5nu_dim16_worker_finish_hardware(uint32_t worker_id) {
  if (worker_id < YOLOV5NU_DIM16_WORKER_COUNT) {
    worker_contexts[worker_id].active = 0;
    worker_contexts[worker_id].waiting = 0;
  }
}

int yolov5nu_dim16_worker_finish_software(uint32_t worker_id,
    struct yolov5nu_dim16_result *result) {
  if (worker_id >= YOLOV5NU_DIM16_WORKER_COUNT || result == NULL ||
      worker_contexts[worker_id].active == 0U ||
      worker_contexts[worker_id].stage != YOLOV5NU_GRAPH_STAGE_COUNT ||
      worker_contexts[worker_id].hardware_head == 0U)
    return YOLOV5NU_DIM16_ERROR;
  worker_contexts[worker_id].hardware_head = 0U;
  worker_contexts[worker_id].stage = 165U;
  return yolov5nu_dim16_worker_poll(worker_id, result);
}

int yolov5nu_dim16_worker_start(uint32_t worker_id, const int8_t *input) {
  struct yolov5nu_worker_context *context;
  if (worker_id >= YOLOV5NU_DIM16_WORKER_COUNT || input == NULL ||
      !yolov5nu_dim16_worker_is_idle(worker_id))
    return YOLOV5NU_DIM16_ERROR;
  context = &worker_contexts[worker_id];
  memset(context, 0, sizeof(*context));
  context->input = (const elem_t *)input;
  context->active = 1U;
  select_worker_memory(worker_id);
  frame_counter_start(worker_id);
  gemmini_flush(0);
  return YOLOV5NU_DIM16_RUNNING;
}

int yolov5nu_dim16_worker_start_reference(uint32_t worker_id) {
  return yolov5nu_dim16_worker_start(worker_id,
                                     (const int8_t *)yolov5nu_input);
}

uint64_t yolov5nu_dim16_worker_busy(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT ?
         read_worker_busy(worker_id) : 0U;
}

int yolov5nu_dim16_worker_get_profile(
    uint32_t worker_id, struct yolov5nu_dim16_profile *profile) {
  if (worker_id >= YOLOV5NU_DIM16_WORKER_COUNT || profile == NULL)
    return -1;
  *profile = frame_profiles[worker_id];
  return 0;
}

uint32_t yolov5nu_dim16_worker_stage(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT ?
         worker_contexts[worker_id].stage : YOLOV5NU_GRAPH_STAGE_COUNT;
}

static struct yolo32_conv_binding batch_conv_bindings[3][58];
static struct yolo32_ws_binding batch_ws_bindings[3][20];
static uint32_t batch_binding_generation[3];
static uint64_t batch_bind_once_cycles, batch_bind_cycles[3];
static void yolo32_batch_bind_init(void) {
  uint64_t begin=read_cycle();
  memset(batch_binding_generation,0,sizeof(batch_binding_generation));
  memset(batch_bind_cycles,0,sizeof(batch_bind_cycles));
  for (unsigned worker=0;worker<3;++worker) {
    select_worker_memory(worker);
  batch_conv_bindings[worker][0].weights=yolov5nu_conv0_weights;
  batch_conv_bindings[worker][0].bias=yolov5nu_conv0_bias;
  batch_conv_bindings[worker][0].output=tensor_3;
  batch_conv_bindings[worker][1].input=tensor_3;
  batch_conv_bindings[worker][1].weights=yolov5nu_conv1_weights;
  batch_conv_bindings[worker][1].bias=yolov5nu_conv1_bias;
  batch_conv_bindings[worker][1].output=tensor_6;
  batch_conv_bindings[worker][2].input=tensor_6;
  batch_conv_bindings[worker][2].weights=yolov5nu_conv2_weights;
  batch_conv_bindings[worker][2].bias=yolov5nu_conv2_bias;
  batch_conv_bindings[worker][2].output=tensor_11;
  batch_conv_bindings[worker][3].input=tensor_6;
  batch_conv_bindings[worker][3].weights=yolov5nu_conv3_weights;
  batch_conv_bindings[worker][3].bias=yolov5nu_conv3_bias;
  batch_conv_bindings[worker][3].output=tensor_12;
  batch_conv_bindings[worker][4].input=tensor_11;
  batch_conv_bindings[worker][4].weights=yolov5nu_conv4_weights;
  batch_conv_bindings[worker][4].bias=yolov5nu_conv4_bias;
  batch_conv_bindings[worker][4].output=tensor_15;
  batch_conv_bindings[worker][5].input=tensor_15;
  batch_conv_bindings[worker][5].weights=yolov5nu_conv5_weights;
  batch_conv_bindings[worker][5].bias=yolov5nu_conv5_bias;
  batch_conv_bindings[worker][5].output=tensor_18;
  batch_conv_bindings[worker][6].input=tensor_23;
  batch_conv_bindings[worker][6].weights=yolov5nu_conv7_weights;
  batch_conv_bindings[worker][6].bias=yolov5nu_conv7_bias;
  batch_conv_bindings[worker][6].output=tensor_26;
  batch_conv_bindings[worker][7].input=tensor_26;
  batch_conv_bindings[worker][7].weights=yolov5nu_conv8_weights;
  batch_conv_bindings[worker][7].bias=yolov5nu_conv8_bias;
  batch_conv_bindings[worker][7].output=tensor_31;
  batch_conv_bindings[worker][8].input=tensor_26;
  batch_conv_bindings[worker][8].weights=yolov5nu_conv9_weights;
  batch_conv_bindings[worker][8].bias=yolov5nu_conv9_bias;
  batch_conv_bindings[worker][8].output=tensor_32;
  batch_conv_bindings[worker][9].input=tensor_31;
  batch_conv_bindings[worker][9].weights=yolov5nu_conv10_weights;
  batch_conv_bindings[worker][9].bias=yolov5nu_conv10_bias;
  batch_conv_bindings[worker][9].output=tensor_35;
  batch_conv_bindings[worker][10].input=tensor_35;
  batch_conv_bindings[worker][10].weights=yolov5nu_conv11_weights;
  batch_conv_bindings[worker][10].bias=yolov5nu_conv11_bias;
  batch_conv_bindings[worker][10].output=tensor_38;
  batch_conv_bindings[worker][11].input=tensor_31;
  batch_conv_bindings[worker][11].weights=yolov5nu_conv12_weights;
  batch_conv_bindings[worker][11].bias=yolov5nu_conv12_bias;
  batch_conv_bindings[worker][11].output=tensor_42;
  batch_conv_bindings[worker][12].input=tensor_42;
  batch_conv_bindings[worker][12].weights=yolov5nu_conv13_weights;
  batch_conv_bindings[worker][12].bias=yolov5nu_conv13_bias;
  batch_conv_bindings[worker][12].output=tensor_45;
  batch_conv_bindings[worker][13].input=tensor_50;
  batch_conv_bindings[worker][13].weights=yolov5nu_conv15_weights;
  batch_conv_bindings[worker][13].bias=yolov5nu_conv15_bias;
  batch_conv_bindings[worker][13].output=tensor_53;
  batch_conv_bindings[worker][14].input=tensor_53;
  batch_conv_bindings[worker][14].weights=yolov5nu_conv16_weights;
  batch_conv_bindings[worker][14].bias=yolov5nu_conv16_bias;
  batch_conv_bindings[worker][14].output=tensor_58;
  batch_conv_bindings[worker][15].input=tensor_53;
  batch_conv_bindings[worker][15].weights=yolov5nu_conv17_weights;
  batch_conv_bindings[worker][15].bias=yolov5nu_conv17_bias;
  batch_conv_bindings[worker][15].output=tensor_59;
  batch_conv_bindings[worker][16].input=tensor_58;
  batch_conv_bindings[worker][16].weights=yolov5nu_conv18_weights;
  batch_conv_bindings[worker][16].bias=yolov5nu_conv18_bias;
  batch_conv_bindings[worker][16].output=tensor_62;
  batch_conv_bindings[worker][17].input=tensor_62;
  batch_conv_bindings[worker][17].weights=yolov5nu_conv19_weights;
  batch_conv_bindings[worker][17].bias=yolov5nu_conv19_bias;
  batch_conv_bindings[worker][17].output=tensor_65;
  batch_conv_bindings[worker][18].input=tensor_58;
  batch_conv_bindings[worker][18].weights=yolov5nu_conv20_weights;
  batch_conv_bindings[worker][18].bias=yolov5nu_conv20_bias;
  batch_conv_bindings[worker][18].output=tensor_69;
  batch_conv_bindings[worker][19].input=tensor_69;
  batch_conv_bindings[worker][19].weights=yolov5nu_conv21_weights;
  batch_conv_bindings[worker][19].bias=yolov5nu_conv21_bias;
  batch_conv_bindings[worker][19].output=tensor_72;
  batch_conv_bindings[worker][20].input=tensor_58;
  batch_conv_bindings[worker][20].weights=yolov5nu_conv22_weights;
  batch_conv_bindings[worker][20].bias=yolov5nu_conv22_bias;
  batch_conv_bindings[worker][20].output=tensor_76;
  batch_conv_bindings[worker][21].input=tensor_76;
  batch_conv_bindings[worker][21].weights=yolov5nu_conv23_weights;
  batch_conv_bindings[worker][21].bias=yolov5nu_conv23_bias;
  batch_conv_bindings[worker][21].output=tensor_79;
  batch_conv_bindings[worker][22].input=tensor_84;
  batch_conv_bindings[worker][22].weights=yolov5nu_conv25_weights;
  batch_conv_bindings[worker][22].bias=yolov5nu_conv25_bias;
  batch_conv_bindings[worker][22].output=tensor_87;
  batch_conv_bindings[worker][23].input=tensor_87;
  batch_conv_bindings[worker][23].weights=yolov5nu_conv26_weights;
  batch_conv_bindings[worker][23].bias=yolov5nu_conv26_bias;
  batch_conv_bindings[worker][23].output=tensor_92;
  batch_conv_bindings[worker][24].input=tensor_87;
  batch_conv_bindings[worker][24].weights=yolov5nu_conv27_weights;
  batch_conv_bindings[worker][24].bias=yolov5nu_conv27_bias;
  batch_conv_bindings[worker][24].output=tensor_93;
  batch_conv_bindings[worker][25].input=tensor_92;
  batch_conv_bindings[worker][25].weights=yolov5nu_conv28_weights;
  batch_conv_bindings[worker][25].bias=yolov5nu_conv28_bias;
  batch_conv_bindings[worker][25].output=tensor_96;
  batch_conv_bindings[worker][26].input=tensor_96;
  batch_conv_bindings[worker][26].weights=yolov5nu_conv29_weights;
  batch_conv_bindings[worker][26].bias=yolov5nu_conv29_bias;
  batch_conv_bindings[worker][26].output=tensor_99;
  batch_conv_bindings[worker][27].input=tensor_104;
  batch_conv_bindings[worker][27].weights=yolov5nu_conv31_weights;
  batch_conv_bindings[worker][27].bias=yolov5nu_conv31_bias;
  batch_conv_bindings[worker][27].output=tensor_107;
  batch_conv_bindings[worker][28].input=tensor_114;
  batch_conv_bindings[worker][28].weights=yolov5nu_conv33_weights;
  batch_conv_bindings[worker][28].bias=yolov5nu_conv33_bias;
  batch_conv_bindings[worker][28].output=tensor_117;
  batch_conv_bindings[worker][29].input=tensor_124;
  batch_conv_bindings[worker][29].weights=yolov5nu_conv36_weights;
  batch_conv_bindings[worker][29].bias=yolov5nu_conv36_bias;
  batch_conv_bindings[worker][29].output=tensor_128;
  batch_conv_bindings[worker][30].input=tensor_128;
  batch_conv_bindings[worker][30].weights=yolov5nu_conv37_weights;
  batch_conv_bindings[worker][30].bias=yolov5nu_conv37_bias;
  batch_conv_bindings[worker][30].output=tensor_131;
  batch_conv_bindings[worker][31].input=tensor_135;
  batch_conv_bindings[worker][31].weights=yolov5nu_conv39_weights;
  batch_conv_bindings[worker][31].bias=yolov5nu_conv39_bias;
  batch_conv_bindings[worker][31].output=tensor_138;
  batch_conv_bindings[worker][32].input=tensor_145;
  batch_conv_bindings[worker][32].weights=yolov5nu_conv42_weights;
  batch_conv_bindings[worker][32].bias=yolov5nu_conv42_bias;
  batch_conv_bindings[worker][32].output=tensor_149;
  batch_conv_bindings[worker][33].input=tensor_149;
  batch_conv_bindings[worker][33].weights=yolov5nu_conv43_weights;
  batch_conv_bindings[worker][33].bias=yolov5nu_conv43_bias;
  batch_conv_bindings[worker][33].output=tensor_152;
  batch_conv_bindings[worker][34].input=tensor_156;
  batch_conv_bindings[worker][34].weights=yolov5nu_conv45_weights;
  batch_conv_bindings[worker][34].bias=yolov5nu_conv45_bias;
  batch_conv_bindings[worker][34].output=tensor_163;
  batch_conv_bindings[worker][35].input=tensor_156;
  batch_conv_bindings[worker][35].weights=yolov5nu_conv46_weights;
  batch_conv_bindings[worker][35].bias=yolov5nu_conv46_bias;
  batch_conv_bindings[worker][35].output=tensor_164;
  batch_conv_bindings[worker][36].input=tensor_156;
  batch_conv_bindings[worker][36].weights=yolov5nu_conv47_weights;
  batch_conv_bindings[worker][36].bias=yolov5nu_conv47_bias;
  batch_conv_bindings[worker][36].output=tensor_165;
  batch_conv_bindings[worker][37].input=tensor_164;
  batch_conv_bindings[worker][37].weights=yolov5nu_conv48_weights;
  batch_conv_bindings[worker][37].bias=yolov5nu_conv48_bias;
  batch_conv_bindings[worker][37].output=tensor_175;
  batch_conv_bindings[worker][38].input=tensor_165;
  batch_conv_bindings[worker][38].weights=yolov5nu_conv49_weights;
  batch_conv_bindings[worker][38].bias=yolov5nu_conv49_bias;
  batch_conv_bindings[worker][38].output=tensor_176;
  batch_conv_bindings[worker][39].input=tensor_175;
  batch_conv_bindings[worker][39].weights=yolov5nu_conv52_weights;
  batch_conv_bindings[worker][39].bias=yolov5nu_conv52_bias;
  batch_conv_bindings[worker][40].input=tensor_176;
  batch_conv_bindings[worker][40].weights=yolov5nu_conv53_weights;
  batch_conv_bindings[worker][40].bias=yolov5nu_conv53_bias;
  batch_conv_bindings[worker][41].input=tensor_177;
  batch_conv_bindings[worker][41].weights=yolov5nu_conv54_weights;
  batch_conv_bindings[worker][41].bias=yolov5nu_conv54_bias;
  batch_conv_bindings[worker][41].output=tensor_185;
  batch_conv_bindings[worker][42].input=tensor_185;
  batch_conv_bindings[worker][42].weights=yolov5nu_conv55_weights;
  batch_conv_bindings[worker][42].bias=yolov5nu_conv55_bias;
  batch_conv_bindings[worker][42].output=tensor_188;
  batch_conv_bindings[worker][43].input=tensor_192;
  batch_conv_bindings[worker][43].weights=yolov5nu_conv57_weights;
  batch_conv_bindings[worker][43].bias=yolov5nu_conv57_bias;
  batch_conv_bindings[worker][43].output=tensor_199;
  batch_conv_bindings[worker][44].input=tensor_192;
  batch_conv_bindings[worker][44].weights=yolov5nu_conv58_weights;
  batch_conv_bindings[worker][44].bias=yolov5nu_conv58_bias;
  batch_conv_bindings[worker][44].output=tensor_200;
  batch_conv_bindings[worker][45].input=tensor_192;
  batch_conv_bindings[worker][45].weights=yolov5nu_conv59_weights;
  batch_conv_bindings[worker][45].bias=yolov5nu_conv59_bias;
  batch_conv_bindings[worker][45].output=tensor_201;
  batch_conv_bindings[worker][46].input=tensor_200;
  batch_conv_bindings[worker][46].weights=yolov5nu_conv60_weights;
  batch_conv_bindings[worker][46].bias=yolov5nu_conv60_bias;
  batch_conv_bindings[worker][46].output=tensor_211;
  batch_conv_bindings[worker][47].input=tensor_201;
  batch_conv_bindings[worker][47].weights=yolov5nu_conv61_weights;
  batch_conv_bindings[worker][47].bias=yolov5nu_conv61_bias;
  batch_conv_bindings[worker][47].output=tensor_212;
  batch_conv_bindings[worker][48].input=tensor_211;
  batch_conv_bindings[worker][48].weights=yolov5nu_conv64_weights;
  batch_conv_bindings[worker][48].bias=yolov5nu_conv64_bias;
  batch_conv_bindings[worker][49].input=tensor_212;
  batch_conv_bindings[worker][49].weights=yolov5nu_conv65_weights;
  batch_conv_bindings[worker][49].bias=yolov5nu_conv65_bias;
  batch_conv_bindings[worker][50].input=tensor_213;
  batch_conv_bindings[worker][50].weights=yolov5nu_conv66_weights;
  batch_conv_bindings[worker][50].bias=yolov5nu_conv66_bias;
  batch_conv_bindings[worker][50].output=tensor_221;
  batch_conv_bindings[worker][51].input=tensor_221;
  batch_conv_bindings[worker][51].weights=yolov5nu_conv67_weights;
  batch_conv_bindings[worker][51].bias=yolov5nu_conv67_bias;
  batch_conv_bindings[worker][51].output=tensor_224;
  batch_conv_bindings[worker][52].input=tensor_228;
  batch_conv_bindings[worker][52].weights=yolov5nu_conv69_weights;
  batch_conv_bindings[worker][52].bias=yolov5nu_conv69_bias;
  batch_conv_bindings[worker][52].output=tensor_233;
  batch_conv_bindings[worker][53].input=tensor_228;
  batch_conv_bindings[worker][53].weights=yolov5nu_conv70_weights;
  batch_conv_bindings[worker][53].bias=yolov5nu_conv70_bias;
  batch_conv_bindings[worker][53].output=tensor_234;
  batch_conv_bindings[worker][54].input=tensor_233;
  batch_conv_bindings[worker][54].weights=yolov5nu_conv71_weights;
  batch_conv_bindings[worker][54].bias=yolov5nu_conv71_bias;
  batch_conv_bindings[worker][54].output=tensor_239;
  batch_conv_bindings[worker][55].input=tensor_234;
  batch_conv_bindings[worker][55].weights=yolov5nu_conv72_weights;
  batch_conv_bindings[worker][55].bias=yolov5nu_conv72_bias;
  batch_conv_bindings[worker][55].output=tensor_240;
  batch_conv_bindings[worker][56].input=tensor_239;
  batch_conv_bindings[worker][56].weights=yolov5nu_conv73_weights;
  batch_conv_bindings[worker][56].bias=yolov5nu_conv73_bias;
  batch_conv_bindings[worker][57].input=tensor_240;
  batch_conv_bindings[worker][57].weights=yolov5nu_conv74_weights;
  batch_conv_bindings[worker][57].bias=yolov5nu_conv74_bias;
  batch_ws_bindings[worker][0].base[0]=tensor_11;
  batch_ws_bindings[worker][0].base[1]=tensor_18;
  batch_ws_bindings[worker][0].base[2]=NULL;
  batch_ws_bindings[worker][0].base[3]=NULL;
  batch_ws_bindings[worker][0].base[4]=NULL;
  batch_ws_bindings[worker][0].base[5]=NULL;
  batch_ws_bindings[worker][0].base[6]=NULL;
  batch_ws_bindings[worker][0].base[7]=NULL;
  batch_ws_bindings[worker][0].base[8]=tensor_11;
  batch_ws_bindings[worker][0].base[9]=NULL;
  batch_ws_bindings[worker][1].base[0]=tensor_11;
  batch_ws_bindings[worker][1].base[1]=tensor_12;
  batch_ws_bindings[worker][1].base[2]=NULL;
  batch_ws_bindings[worker][1].base[3]=NULL;
  batch_ws_bindings[worker][1].base[4]=yolov5nu_conv6_weights;
  batch_ws_bindings[worker][1].base[5]=NULL;
  batch_ws_bindings[worker][1].base[6]=yolov5nu_conv6_bias;
  batch_ws_bindings[worker][1].base[7]=NULL;
  batch_ws_bindings[worker][1].base[8]=tensor_23;
  batch_ws_bindings[worker][1].base[9]=NULL;
  batch_ws_bindings[worker][2].base[0]=tensor_31;
  batch_ws_bindings[worker][2].base[1]=tensor_38;
  batch_ws_bindings[worker][2].base[2]=NULL;
  batch_ws_bindings[worker][2].base[3]=NULL;
  batch_ws_bindings[worker][2].base[4]=NULL;
  batch_ws_bindings[worker][2].base[5]=NULL;
  batch_ws_bindings[worker][2].base[6]=NULL;
  batch_ws_bindings[worker][2].base[7]=NULL;
  batch_ws_bindings[worker][2].base[8]=tensor_31;
  batch_ws_bindings[worker][2].base[9]=NULL;
  batch_ws_bindings[worker][3].base[0]=tensor_31;
  batch_ws_bindings[worker][3].base[1]=tensor_45;
  batch_ws_bindings[worker][3].base[2]=NULL;
  batch_ws_bindings[worker][3].base[3]=NULL;
  batch_ws_bindings[worker][3].base[4]=NULL;
  batch_ws_bindings[worker][3].base[5]=NULL;
  batch_ws_bindings[worker][3].base[6]=NULL;
  batch_ws_bindings[worker][3].base[7]=NULL;
  batch_ws_bindings[worker][3].base[8]=tensor_31;
  batch_ws_bindings[worker][3].base[9]=NULL;
  batch_ws_bindings[worker][4].base[0]=tensor_31;
  batch_ws_bindings[worker][4].base[1]=tensor_32;
  batch_ws_bindings[worker][4].base[2]=NULL;
  batch_ws_bindings[worker][4].base[3]=NULL;
  batch_ws_bindings[worker][4].base[4]=yolov5nu_conv14_weights;
  batch_ws_bindings[worker][4].base[5]=NULL;
  batch_ws_bindings[worker][4].base[6]=yolov5nu_conv14_bias;
  batch_ws_bindings[worker][4].base[7]=NULL;
  batch_ws_bindings[worker][4].base[8]=tensor_50;
  batch_ws_bindings[worker][4].base[9]=NULL;
  batch_ws_bindings[worker][5].base[0]=tensor_58;
  batch_ws_bindings[worker][5].base[1]=tensor_65;
  batch_ws_bindings[worker][5].base[2]=NULL;
  batch_ws_bindings[worker][5].base[3]=NULL;
  batch_ws_bindings[worker][5].base[4]=NULL;
  batch_ws_bindings[worker][5].base[5]=NULL;
  batch_ws_bindings[worker][5].base[6]=NULL;
  batch_ws_bindings[worker][5].base[7]=NULL;
  batch_ws_bindings[worker][5].base[8]=tensor_58;
  batch_ws_bindings[worker][5].base[9]=NULL;
  batch_ws_bindings[worker][6].base[0]=tensor_58;
  batch_ws_bindings[worker][6].base[1]=tensor_72;
  batch_ws_bindings[worker][6].base[2]=NULL;
  batch_ws_bindings[worker][6].base[3]=NULL;
  batch_ws_bindings[worker][6].base[4]=NULL;
  batch_ws_bindings[worker][6].base[5]=NULL;
  batch_ws_bindings[worker][6].base[6]=NULL;
  batch_ws_bindings[worker][6].base[7]=NULL;
  batch_ws_bindings[worker][6].base[8]=tensor_58;
  batch_ws_bindings[worker][6].base[9]=NULL;
  batch_ws_bindings[worker][7].base[0]=tensor_58;
  batch_ws_bindings[worker][7].base[1]=tensor_79;
  batch_ws_bindings[worker][7].base[2]=NULL;
  batch_ws_bindings[worker][7].base[3]=NULL;
  batch_ws_bindings[worker][7].base[4]=NULL;
  batch_ws_bindings[worker][7].base[5]=NULL;
  batch_ws_bindings[worker][7].base[6]=NULL;
  batch_ws_bindings[worker][7].base[7]=NULL;
  batch_ws_bindings[worker][7].base[8]=tensor_58;
  batch_ws_bindings[worker][7].base[9]=NULL;
  batch_ws_bindings[worker][8].base[0]=tensor_58;
  batch_ws_bindings[worker][8].base[1]=tensor_59;
  batch_ws_bindings[worker][8].base[2]=NULL;
  batch_ws_bindings[worker][8].base[3]=NULL;
  batch_ws_bindings[worker][8].base[4]=yolov5nu_conv24_weights;
  batch_ws_bindings[worker][8].base[5]=NULL;
  batch_ws_bindings[worker][8].base[6]=yolov5nu_conv24_bias;
  batch_ws_bindings[worker][8].base[7]=NULL;
  batch_ws_bindings[worker][8].base[8]=tensor_84;
  batch_ws_bindings[worker][8].base[9]=NULL;
  batch_ws_bindings[worker][9].base[0]=tensor_92;
  batch_ws_bindings[worker][9].base[1]=tensor_99;
  batch_ws_bindings[worker][9].base[2]=NULL;
  batch_ws_bindings[worker][9].base[3]=NULL;
  batch_ws_bindings[worker][9].base[4]=NULL;
  batch_ws_bindings[worker][9].base[5]=NULL;
  batch_ws_bindings[worker][9].base[6]=NULL;
  batch_ws_bindings[worker][9].base[7]=NULL;
  batch_ws_bindings[worker][9].base[8]=tensor_92;
  batch_ws_bindings[worker][9].base[9]=NULL;
  batch_ws_bindings[worker][10].base[0]=tensor_92;
  batch_ws_bindings[worker][10].base[1]=tensor_93;
  batch_ws_bindings[worker][10].base[2]=NULL;
  batch_ws_bindings[worker][10].base[3]=NULL;
  batch_ws_bindings[worker][10].base[4]=yolov5nu_conv30_weights;
  batch_ws_bindings[worker][10].base[5]=NULL;
  batch_ws_bindings[worker][10].base[6]=yolov5nu_conv30_bias;
  batch_ws_bindings[worker][10].base[7]=NULL;
  batch_ws_bindings[worker][10].base[8]=tensor_104;
  batch_ws_bindings[worker][10].base[9]=NULL;
  batch_ws_bindings[worker][11].base[0]=tensor_107;
  batch_ws_bindings[worker][11].base[1]=tensor_108;
  batch_ws_bindings[worker][11].base[2]=tensor_109;
  batch_ws_bindings[worker][11].base[3]=tensor_110;
  batch_ws_bindings[worker][11].base[4]=yolov5nu_conv32_weights;
  batch_ws_bindings[worker][11].base[5]=NULL;
  batch_ws_bindings[worker][11].base[6]=yolov5nu_conv32_bias;
  batch_ws_bindings[worker][11].base[7]=NULL;
  batch_ws_bindings[worker][11].base[8]=tensor_114;
  batch_ws_bindings[worker][11].base[9]=NULL;
  batch_ws_bindings[worker][12].base[0]=tensor_118;
  batch_ws_bindings[worker][12].base[1]=tensor_84;
  batch_ws_bindings[worker][12].base[2]=NULL;
  batch_ws_bindings[worker][12].base[3]=NULL;
  batch_ws_bindings[worker][12].base[4]=yolov5nu_conv34_weights;
  batch_ws_bindings[worker][12].base[5]=yolov5nu_conv35_weights;
  batch_ws_bindings[worker][12].base[6]=yolov5nu_conv34_bias;
  batch_ws_bindings[worker][12].base[7]=yolov5nu_conv35_bias;
  batch_ws_bindings[worker][12].base[8]=tensor_124;
  batch_ws_bindings[worker][12].base[9]=tensor_125;
  batch_ws_bindings[worker][13].base[0]=tensor_131;
  batch_ws_bindings[worker][13].base[1]=tensor_125;
  batch_ws_bindings[worker][13].base[2]=NULL;
  batch_ws_bindings[worker][13].base[3]=NULL;
  batch_ws_bindings[worker][13].base[4]=yolov5nu_conv38_weights;
  batch_ws_bindings[worker][13].base[5]=NULL;
  batch_ws_bindings[worker][13].base[6]=yolov5nu_conv38_bias;
  batch_ws_bindings[worker][13].base[7]=NULL;
  batch_ws_bindings[worker][13].base[8]=tensor_135;
  batch_ws_bindings[worker][13].base[9]=NULL;
  batch_ws_bindings[worker][14].base[0]=tensor_139;
  batch_ws_bindings[worker][14].base[1]=tensor_50;
  batch_ws_bindings[worker][14].base[2]=NULL;
  batch_ws_bindings[worker][14].base[3]=NULL;
  batch_ws_bindings[worker][14].base[4]=yolov5nu_conv40_weights;
  batch_ws_bindings[worker][14].base[5]=yolov5nu_conv41_weights;
  batch_ws_bindings[worker][14].base[6]=yolov5nu_conv40_bias;
  batch_ws_bindings[worker][14].base[7]=yolov5nu_conv41_bias;
  batch_ws_bindings[worker][14].base[8]=tensor_145;
  batch_ws_bindings[worker][14].base[9]=tensor_146;
  batch_ws_bindings[worker][15].base[0]=tensor_152;
  batch_ws_bindings[worker][15].base[1]=tensor_146;
  batch_ws_bindings[worker][15].base[2]=NULL;
  batch_ws_bindings[worker][15].base[3]=NULL;
  batch_ws_bindings[worker][15].base[4]=yolov5nu_conv44_weights;
  batch_ws_bindings[worker][15].base[5]=NULL;
  batch_ws_bindings[worker][15].base[6]=yolov5nu_conv44_bias;
  batch_ws_bindings[worker][15].base[7]=NULL;
  batch_ws_bindings[worker][15].base[8]=tensor_156;
  batch_ws_bindings[worker][15].base[9]=NULL;
  batch_ws_bindings[worker][16].base[0]=tensor_163;
  batch_ws_bindings[worker][16].base[1]=tensor_138;
  batch_ws_bindings[worker][16].base[2]=NULL;
  batch_ws_bindings[worker][16].base[3]=NULL;
  batch_ws_bindings[worker][16].base[4]=yolov5nu_conv50_weights;
  batch_ws_bindings[worker][16].base[5]=yolov5nu_conv51_weights;
  batch_ws_bindings[worker][16].base[6]=yolov5nu_conv50_bias;
  batch_ws_bindings[worker][16].base[7]=yolov5nu_conv51_bias;
  batch_ws_bindings[worker][16].base[8]=tensor_177;
  batch_ws_bindings[worker][16].base[9]=tensor_178;
  batch_ws_bindings[worker][17].base[0]=tensor_188;
  batch_ws_bindings[worker][17].base[1]=tensor_178;
  batch_ws_bindings[worker][17].base[2]=NULL;
  batch_ws_bindings[worker][17].base[3]=NULL;
  batch_ws_bindings[worker][17].base[4]=yolov5nu_conv56_weights;
  batch_ws_bindings[worker][17].base[5]=NULL;
  batch_ws_bindings[worker][17].base[6]=yolov5nu_conv56_bias;
  batch_ws_bindings[worker][17].base[7]=NULL;
  batch_ws_bindings[worker][17].base[8]=tensor_192;
  batch_ws_bindings[worker][17].base[9]=NULL;
  batch_ws_bindings[worker][18].base[0]=tensor_199;
  batch_ws_bindings[worker][18].base[1]=tensor_117;
  batch_ws_bindings[worker][18].base[2]=NULL;
  batch_ws_bindings[worker][18].base[3]=NULL;
  batch_ws_bindings[worker][18].base[4]=yolov5nu_conv62_weights;
  batch_ws_bindings[worker][18].base[5]=yolov5nu_conv63_weights;
  batch_ws_bindings[worker][18].base[6]=yolov5nu_conv62_bias;
  batch_ws_bindings[worker][18].base[7]=yolov5nu_conv63_bias;
  batch_ws_bindings[worker][18].base[8]=tensor_213;
  batch_ws_bindings[worker][18].base[9]=tensor_214;
  batch_ws_bindings[worker][19].base[0]=tensor_224;
  batch_ws_bindings[worker][19].base[1]=tensor_214;
  batch_ws_bindings[worker][19].base[2]=NULL;
  batch_ws_bindings[worker][19].base[3]=NULL;
  batch_ws_bindings[worker][19].base[4]=yolov5nu_conv68_weights;
  batch_ws_bindings[worker][19].base[5]=NULL;
  batch_ws_bindings[worker][19].base[6]=yolov5nu_conv68_bias;
  batch_ws_bindings[worker][19].base[7]=NULL;
  batch_ws_bindings[worker][19].base[8]=tensor_228;
  batch_ws_bindings[worker][19].base[9]=NULL;
  }
  batch_bind_once_cycles=read_cycle()-begin;
}
static void yolo32_batch_bind_start(unsigned worker) {
  uint64_t begin=read_cycle();
  select_worker_memory(worker);
  struct yolov5nu_worker_context *context=&worker_contexts[worker];
  const elem_t *model_input=context->input;
  if (!model_input) yolo32_fail("batch_binding_input");
  batch_conv_bindings[worker][0].input=model_input;
  batch_conv_bindings[worker][39].output=raw_dfl0;
  batch_conv_bindings[worker][40].output=raw_class0;
  batch_conv_bindings[worker][48].output=raw_dfl1;
  batch_conv_bindings[worker][49].output=raw_class1;
  batch_conv_bindings[worker][56].output=raw_dfl2;
  batch_conv_bindings[worker][57].output=raw_class2;
  if (++batch_binding_generation[worker]==0) ++batch_binding_generation[worker];
  batch_bind_cycles[worker]=read_cycle()-begin;
}

int yolov5nu_dim16_worker_poll(uint32_t worker_id,
    struct yolov5nu_dim16_result *result) {
  struct yolov5nu_worker_context *context;
  const elem_t *model_input;
  uint64_t *silu_config_cycles;
  if (worker_id >= YOLOV5NU_DIM16_WORKER_COUNT || result == NULL)
    return YOLOV5NU_DIM16_ERROR;
  context = &worker_contexts[worker_id];
  if (context->active == 0U)
    return YOLOV5NU_DIM16_ERROR;
  select_worker_memory(worker_id);
  model_input = context->input;
  silu_config_cycles = context->silu_config_cycles;

  if (yolo32_independent_enabled) context->waiting = context->poll_armed = 0;
  if (context->waiting != 0U) {
    if (context->poll_armed == 0U) {
      context->poll_armed = 1U;
      return YOLOV5NU_DIM16_RUNNING;
    }
    if (read_worker_busy(worker_id) != 0U)
      return YOLOV5NU_DIM16_RUNNING;
    gemmini_fence();
    context->waiting = 0U;
  }

  for (;;) {
    switch (context->stage) {
    case 0U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[0]);
    gemmini_fence();
    silu_config_cycles[0] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_0,&batch_conv_bindings[worker_id][0]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.0/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 1U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.0/act/Mul", silu_config_cycles[0]);
  }
      context->stage++;
      break;
    case 2U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[1]);
    gemmini_fence();
    silu_config_cycles[1] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_2,&batch_conv_bindings[worker_id][1]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 3U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.1/act/Mul", silu_config_cycles[1]);
  }
      context->stage++;
      break;
    case 4U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[2]);
    gemmini_fence();
    silu_config_cycles[2] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_4,&batch_conv_bindings[worker_id][2]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 5U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[3]);
    gemmini_fence();
    silu_config_cycles[3] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_5,&batch_conv_bindings[worker_id][3]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 6U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/cv1/act/Mul", silu_config_cycles[2]);
  }
      context->stage++;
      break;
    case 7U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/cv2/act/Mul", silu_config_cycles[3]);
  }
      context->stage++;
      break;
    case 8U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[4]);
    gemmini_fence();
    silu_config_cycles[4] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_8,&batch_conv_bindings[worker_id][4]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 9U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/m/m.0/cv1/act/Mul", silu_config_cycles[4]);
  }
      context->stage++;
      break;
    case 10U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[5]);
    gemmini_fence();
    silu_config_cycles[5] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_10,&batch_conv_bindings[worker_id][5]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 11U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/m/m.0/cv2/act/Mul", silu_config_cycles[5]);
  }
      context->stage++;
      break;
    case 12U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.2/m/m.0/Add");
  yolo32_batch_ws_12(&batch_ws_bindings[worker_id][0]);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.2/m/m.0/Add", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 13U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.2/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.2/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.2/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 14U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[6]);
    gemmini_fence();
    silu_config_cycles[6] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.2/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.2/Concat */
    yolo32_batch_ws_14(&batch_ws_bindings[worker_id][1]);
    yolo32_reused_fence(14U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.2/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.2/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.2/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 15U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.2/cv3/act/Mul", silu_config_cycles[6]);
  }
      context->stage++;
      break;
    case 16U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[7]);
    gemmini_fence();
    silu_config_cycles[7] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_16,&batch_conv_bindings[worker_id][6]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 17U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.3/act/Mul", silu_config_cycles[7]);
  }
      context->stage++;
      break;
    case 18U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[8]);
    gemmini_fence();
    silu_config_cycles[8] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_18,&batch_conv_bindings[worker_id][7]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 19U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[9]);
    gemmini_fence();
    silu_config_cycles[9] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_19,&batch_conv_bindings[worker_id][8]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 20U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/cv1/act/Mul", silu_config_cycles[8]);
  }
      context->stage++;
      break;
    case 21U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/cv2/act/Mul", silu_config_cycles[9]);
  }
      context->stage++;
      break;
    case 22U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[10]);
    gemmini_fence();
    silu_config_cycles[10] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_22,&batch_conv_bindings[worker_id][9]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 23U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.0/cv1/act/Mul", silu_config_cycles[10]);
  }
      context->stage++;
      break;
    case 24U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[11]);
    gemmini_fence();
    silu_config_cycles[11] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_24,&batch_conv_bindings[worker_id][10]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 25U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.0/cv2/act/Mul", silu_config_cycles[11]);
  }
      context->stage++;
      break;
    case 26U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.4/m/m.0/Add");
  yolo32_batch_ws_26(&batch_ws_bindings[worker_id][2]);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.4/m/m.0/Add", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 27U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[12]);
    gemmini_fence();
    silu_config_cycles[12] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.1/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_27,&batch_conv_bindings[worker_id][11]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.1/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.1/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 28U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.1/cv1/act/Mul", silu_config_cycles[12]);
  }
      context->stage++;
      break;
    case 29U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[13]);
    gemmini_fence();
    silu_config_cycles[13] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/m/m.1/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_29,&batch_conv_bindings[worker_id][12]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/m/m.1/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/m/m.1/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/m/m.1/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 30U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/m/m.1/cv2/act/Mul", silu_config_cycles[13]);
  }
      context->stage++;
      break;
    case 31U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.4/m/m.1/Add");
  yolo32_batch_ws_31(&batch_ws_bindings[worker_id][3]);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.4/m/m.1/Add", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 32U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.4/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.4/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.4/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 33U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[14]);
    gemmini_fence();
    silu_config_cycles[14] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.4/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.4/Concat */
    yolo32_batch_ws_33(&batch_ws_bindings[worker_id][4]);
    yolo32_reused_fence(33U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.4/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.4/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.4/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 34U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.4/cv3/act/Mul", silu_config_cycles[14]);
  }
      context->stage++;
      break;
    case 35U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.5/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[15]);
    gemmini_fence();
    silu_config_cycles[15] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.5/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_35,&batch_conv_bindings[worker_id][13]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.5/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.5/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.5/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 36U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.5/act/Mul", silu_config_cycles[15]);
  }
      context->stage++;
      break;
    case 37U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[16]);
    gemmini_fence();
    silu_config_cycles[16] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_37,&batch_conv_bindings[worker_id][14]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 38U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[17]);
    gemmini_fence();
    silu_config_cycles[17] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_38,&batch_conv_bindings[worker_id][15]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 39U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/cv1/act/Mul", silu_config_cycles[16]);
  }
      context->stage++;
      break;
    case 40U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/cv2/act/Mul", silu_config_cycles[17]);
  }
      context->stage++;
      break;
    case 41U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[18]);
    gemmini_fence();
    silu_config_cycles[18] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_41,&batch_conv_bindings[worker_id][16]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 42U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.0/cv1/act/Mul", silu_config_cycles[18]);
  }
      context->stage++;
      break;
    case 43U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[19]);
    gemmini_fence();
    silu_config_cycles[19] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_43,&batch_conv_bindings[worker_id][17]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 44U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.0/cv2/act/Mul", silu_config_cycles[19]);
  }
      context->stage++;
      break;
    case 45U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.6/m/m.0/Add");
  yolo32_batch_ws_45(&batch_ws_bindings[worker_id][5]);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.6/m/m.0/Add", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 46U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[20]);
    gemmini_fence();
    silu_config_cycles[20] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.1/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_46,&batch_conv_bindings[worker_id][18]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.1/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.1/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 47U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.1/cv1/act/Mul", silu_config_cycles[20]);
  }
      context->stage++;
      break;
    case 48U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[21]);
    gemmini_fence();
    silu_config_cycles[21] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.1/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_48,&batch_conv_bindings[worker_id][19]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.1/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.1/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.1/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 49U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.1/cv2/act/Mul", silu_config_cycles[21]);
  }
      context->stage++;
      break;
    case 50U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.6/m/m.1/Add");
  yolo32_batch_ws_50(&batch_ws_bindings[worker_id][6]);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.6/m/m.1/Add", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 51U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[22]);
    gemmini_fence();
    silu_config_cycles[22] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.2/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_51,&batch_conv_bindings[worker_id][20]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.2/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.2/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 52U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.2/cv1/act/Mul", silu_config_cycles[22]);
  }
      context->stage++;
      break;
    case 53U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[23]);
    gemmini_fence();
    silu_config_cycles[23] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/m/m.2/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_53,&batch_conv_bindings[worker_id][21]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/m/m.2/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/m/m.2/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/m/m.2/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 54U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/m/m.2/cv2/act/Mul", silu_config_cycles[23]);
  }
      context->stage++;
      break;
    case 55U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.6/m/m.2/Add");
  yolo32_batch_ws_55(&batch_ws_bindings[worker_id][7]);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.6/m/m.2/Add", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 56U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.6/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.6/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.6/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 57U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[24]);
    gemmini_fence();
    silu_config_cycles[24] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.6/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.6/Concat */
    yolo32_batch_ws_57(&batch_ws_bindings[worker_id][8]);
    yolo32_reused_fence(57U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.6/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.6/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.6/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 58U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.6/cv3/act/Mul", silu_config_cycles[24]);
  }
      context->stage++;
      break;
    case 59U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.7/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[25]);
    gemmini_fence();
    silu_config_cycles[25] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.7/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_59,&batch_conv_bindings[worker_id][22]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.7/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.7/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.7/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 60U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.7/act/Mul", silu_config_cycles[25]);
  }
      context->stage++;
      break;
    case 61U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[26]);
    gemmini_fence();
    silu_config_cycles[26] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_61,&batch_conv_bindings[worker_id][23]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 62U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[27]);
    gemmini_fence();
    silu_config_cycles[27] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_62,&batch_conv_bindings[worker_id][24]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 63U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/cv1/act/Mul", silu_config_cycles[26]);
  }
      context->stage++;
      break;
    case 64U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/cv2/act/Mul", silu_config_cycles[27]);
  }
      context->stage++;
      break;
    case 65U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[28]);
    gemmini_fence();
    silu_config_cycles[28] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_65,&batch_conv_bindings[worker_id][25]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 66U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/m/m.0/cv1/act/Mul", silu_config_cycles[28]);
  }
      context->stage++;
      break;
    case 67U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[29]);
    gemmini_fence();
    silu_config_cycles[29] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_67,&batch_conv_bindings[worker_id][26]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 68U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/m/m.0/cv2/act/Mul", silu_config_cycles[29]);
  }
      context->stage++;
      break;
    case 69U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_ADD, "Add", "/model.8/m/m.0/Add");
  yolo32_batch_ws_69(&batch_ws_bindings[worker_id][9]);

    yolo_profile_add(PROFILE_ADD, "Add", "/model.8/m/m.0/Add", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 70U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.8/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.8/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.8/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 71U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[30]);
    gemmini_fence();
    silu_config_cycles[30] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.8/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.8/Concat */
    yolo32_batch_ws_71(&batch_ws_bindings[worker_id][10]);
    yolo32_reused_fence(71U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.8/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.8/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.8/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 72U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.8/cv3/act/Mul", silu_config_cycles[30]);
  }
      context->stage++;
      break;
    case 73U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[31]);
    gemmini_fence();
    silu_config_cycles[31] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.9/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_73,&batch_conv_bindings[worker_id][27]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.9/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.9/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 74U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.9/cv1/act/Mul", silu_config_cycles[31]);
  }
      context->stage++;
      break;
    case 75U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_MAXPOOL, "MaxPool", "/model.9/m/MaxPool");
  yolo32_memory_pool5(tensor_107, tensor_108, 15, 20, 128);

    yolo_profile_add(PROFILE_MAXPOOL, "MaxPool", "/model.9/m/MaxPool", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 76U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_1/MaxPool");
  yolo32_memory_pool5(tensor_108, tensor_109, 15, 20, 128);

    yolo_profile_add(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_1/MaxPool", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 77U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_2/MaxPool");
  yolo32_memory_pool5(tensor_109, tensor_110, 15, 20, 128);

    yolo_profile_add(PROFILE_MAXPOOL, "MaxPool", "/model.9/m_2/MaxPool", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 78U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.9/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.9/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.9/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 79U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[32]);
    gemmini_fence();
    silu_config_cycles[32] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.9/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.9/Concat */
    const elem_t *stage8_inputs[] = {tensor_107, tensor_108, tensor_109, tensor_110};
    const int stage8_channels[] = {128, 128, 128, 128};
    const float stage8_scales[] = {0.05828123912f, 0.05828123912f, 0.05828123912f, 0.05828123912f};
    yolo32_batch_ws_79(&batch_ws_bindings[worker_id][11]);
    yolo32_reused_fence(79U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.9/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.9/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.9/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 80U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.9/cv2/act/Mul", silu_config_cycles[32]);
  }
      context->stage++;
      break;
    case 81U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.10/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[33]);
    gemmini_fence();
    silu_config_cycles[33] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.10/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_81,&batch_conv_bindings[worker_id][28]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.10/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.10/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.10/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 82U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.10/act/Mul", silu_config_cycles[33]);
  }
      context->stage++;
      break;
    case 83U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_RESIZE, "Resize", "/model.11/Resize");
  yolo32_memory_resize2(tensor_117, tensor_118, 15, 20, 128);

    yolo_profile_add(PROFILE_RESIZE, "Resize", "/model.11/Resize", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 84U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.12/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.12/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.12/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 85U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[34]);
    gemmini_fence();
    silu_config_cycles[34] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.12/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.12/Concat consumer2 */
    yolo32_batch_ws_85(&batch_ws_bindings[worker_id][12]);
    yolo32_reused_fence(85U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 86U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/cv1/act/Mul", silu_config_cycles[34]);
  }
      context->stage++;
      break;
    case 87U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/cv2/act/Mul", silu_config_cycles[35]);
  }
      context->stage++;
      break;
    case 88U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[36]);
    gemmini_fence();
    silu_config_cycles[36] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_88,&batch_conv_bindings[worker_id][29]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 89U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/m/m.0/cv1/act/Mul", silu_config_cycles[36]);
  }
      context->stage++;
      break;
    case 90U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[37]);
    gemmini_fence();
    silu_config_cycles[37] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_90,&batch_conv_bindings[worker_id][30]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 91U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/m/m.0/cv2/act/Mul", silu_config_cycles[37]);
  }
      context->stage++;
      break;
    case 92U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.13/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.13/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.13/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 93U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[38]);
    gemmini_fence();
    silu_config_cycles[38] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.13/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.13/Concat */
    yolo32_batch_ws_93(&batch_ws_bindings[worker_id][13]);
    yolo32_reused_fence(93U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.13/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.13/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.13/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 94U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.13/cv3/act/Mul", silu_config_cycles[38]);
  }
      context->stage++;
      break;
    case 95U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.14/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[39]);
    gemmini_fence();
    silu_config_cycles[39] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.14/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_95,&batch_conv_bindings[worker_id][31]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.14/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.14/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.14/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 96U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.14/act/Mul", silu_config_cycles[39]);
  }
      context->stage++;
      break;
    case 97U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_RESIZE, "Resize", "/model.15/Resize");
  yolo32_memory_resize2(tensor_138, tensor_139, 30, 40, 64);

    yolo_profile_add(PROFILE_RESIZE, "Resize", "/model.15/Resize", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 98U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.16/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.16/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.16/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 99U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[40]);
    gemmini_fence();
    silu_config_cycles[40] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.16/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.16/Concat consumer2 */
    yolo32_batch_ws_99(&batch_ws_bindings[worker_id][14]);
    yolo32_reused_fence(99U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 100U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/cv1/act/Mul", silu_config_cycles[40]);
  }
      context->stage++;
      break;
    case 101U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/cv2/act/Mul", silu_config_cycles[41]);
  }
      context->stage++;
      break;
    case 102U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[42]);
    gemmini_fence();
    silu_config_cycles[42] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_102,&batch_conv_bindings[worker_id][32]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 103U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/m/m.0/cv1/act/Mul", silu_config_cycles[42]);
  }
      context->stage++;
      break;
    case 104U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[43]);
    gemmini_fence();
    silu_config_cycles[43] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_104,&batch_conv_bindings[worker_id][33]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 105U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/m/m.0/cv2/act/Mul", silu_config_cycles[43]);
  }
      context->stage++;
      break;
    case 106U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.17/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.17/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.17/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 107U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[44]);
    gemmini_fence();
    silu_config_cycles[44] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.17/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.17/Concat */
    yolo32_batch_ws_107(&batch_ws_bindings[worker_id][15]);
    yolo32_reused_fence(107U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.17/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.17/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.17/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 108U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.17/cv3/act/Mul", silu_config_cycles[44]);
  }
      context->stage++;
      break;
    case 109U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.18/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[45]);
    gemmini_fence();
    silu_config_cycles[45] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.18/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_109,&batch_conv_bindings[worker_id][34]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.18/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.18/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.18/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 110U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[46]);
    gemmini_fence();
    silu_config_cycles[46] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.0/cv2.0.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_110,&batch_conv_bindings[worker_id][35]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.0/cv2.0.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.0/cv2.0.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.0/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 111U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[47]);
    gemmini_fence();
    silu_config_cycles[47] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.0/cv3.0.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_111,&batch_conv_bindings[worker_id][36]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.0/cv3.0.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.0/cv3.0.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.0/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 112U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.18/act/Mul", silu_config_cycles[45]);
  }
      context->stage++;
      break;
    case 113U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.0/cv2.0.0/act/Mul", silu_config_cycles[46]);
  }
      context->stage++;
      break;
    case 114U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.0/cv3.0.0/act/Mul", silu_config_cycles[47]);
  }
      context->stage++;
      break;
    case 115U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.19/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.19/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.19/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 116U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[48]);
    gemmini_fence();
    silu_config_cycles[48] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.0/cv2.0.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_116,&batch_conv_bindings[worker_id][37]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.0/cv2.0.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.0/cv2.0.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 117U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[49]);
    gemmini_fence();
    silu_config_cycles[49] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.0/cv3.0.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_117,&batch_conv_bindings[worker_id][38]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.0/cv3.0.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.0/cv3.0.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 118U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[50]);
    gemmini_fence();
    silu_config_cycles[50] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.19/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.19/Concat consumer2 */
    yolo32_batch_ws_118(&batch_ws_bindings[worker_id][16]);
    yolo32_reused_fence(118U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 119U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.0/cv2.0.1/act/Mul", silu_config_cycles[48]);
  }
      context->stage++;
      break;
    case 120U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.0/cv3.0.1/act/Mul", silu_config_cycles[49]);
  }
      context->stage++;
      break;
    case 121U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/cv1/act/Mul", silu_config_cycles[50]);
  }
      context->stage++;
      break;
    case 122U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/cv2/act/Mul", silu_config_cycles[51]);
  }
      context->stage++;
      break;
    case 123U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.0/cv2.0.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_123,&batch_conv_bindings[worker_id][39]);
    gemmini_fence();
    if (context->hardware_head && head_callback) yolo32_publish_head(worker_id, 3);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.0/cv2.0.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.0/cv2.0.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.0/cv2.0.2/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 124U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.0/cv3.0.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_124,&batch_conv_bindings[worker_id][40]);
    gemmini_fence();
    if (context->hardware_head && head_callback) yolo32_publish_head(worker_id, 0);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.0/cv3.0.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.0/cv3.0.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.0/cv3.0.2/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 125U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[52]);
    gemmini_fence();
    silu_config_cycles[52] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_125,&batch_conv_bindings[worker_id][41]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 126U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/m/m.0/cv1/act/Mul", silu_config_cycles[52]);
  }
      context->stage++;
      break;
    case 127U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[53]);
    gemmini_fence();
    silu_config_cycles[53] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_127,&batch_conv_bindings[worker_id][42]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 128U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/m/m.0/cv2/act/Mul", silu_config_cycles[53]);
  }
      context->stage++;
      break;
    case 129U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.20/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.20/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.20/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 130U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[54]);
    gemmini_fence();
    silu_config_cycles[54] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.20/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.20/Concat */
    yolo32_batch_ws_130(&batch_ws_bindings[worker_id][17]);
    yolo32_reused_fence(130U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.20/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.20/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.20/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 131U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.20/cv3/act/Mul", silu_config_cycles[54]);
  }
      context->stage++;
      break;
    case 132U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.21/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[55]);
    gemmini_fence();
    silu_config_cycles[55] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.21/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_132,&batch_conv_bindings[worker_id][43]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.21/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.21/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.21/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 133U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[56]);
    gemmini_fence();
    silu_config_cycles[56] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.1/cv2.1.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_133,&batch_conv_bindings[worker_id][44]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.1/cv2.1.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.1/cv2.1.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.0/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 134U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[57]);
    gemmini_fence();
    silu_config_cycles[57] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.1/cv3.1.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_134,&batch_conv_bindings[worker_id][45]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.1/cv3.1.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.1/cv3.1.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.0/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 135U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.21/act/Mul", silu_config_cycles[55]);
  }
      context->stage++;
      break;
    case 136U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.1/cv2.1.0/act/Mul", silu_config_cycles[56]);
  }
      context->stage++;
      break;
    case 137U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.1/cv3.1.0/act/Mul", silu_config_cycles[57]);
  }
      context->stage++;
      break;
    case 138U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.22/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.22/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.22/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 139U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[58]);
    gemmini_fence();
    silu_config_cycles[58] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.1/cv2.1.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_139,&batch_conv_bindings[worker_id][46]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.1/cv2.1.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.1/cv2.1.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 140U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[59]);
    gemmini_fence();
    silu_config_cycles[59] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.1/cv3.1.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_140,&batch_conv_bindings[worker_id][47]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.1/cv3.1.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.1/cv3.1.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 141U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[60]);
    gemmini_fence();
    silu_config_cycles[60] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.22/Concat */
    /* STAGE8_SPLITK_CONCAT_CONV: /model.22/Concat consumer2 */
    yolo32_batch_ws_141(&batch_ws_bindings[worker_id][18]);
    yolo32_reused_fence(141U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 142U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.1/cv2.1.1/act/Mul", silu_config_cycles[58]);
  }
      context->stage++;
      break;
    case 143U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.1/cv3.1.1/act/Mul", silu_config_cycles[59]);
  }
      context->stage++;
      break;
    case 144U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/cv1/act/Mul", silu_config_cycles[60]);
  }
      context->stage++;
      break;
    case 145U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/cv2/act/Mul", silu_config_cycles[61]);
  }
      context->stage++;
      break;
    case 146U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.1/cv2.1.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_146,&batch_conv_bindings[worker_id][48]);
    gemmini_fence();
    if (context->hardware_head && head_callback) yolo32_publish_head(worker_id, 4);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.1/cv2.1.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.1/cv2.1.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.1/cv2.1.2/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 147U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.1/cv3.1.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_147,&batch_conv_bindings[worker_id][49]);
    gemmini_fence();
    if (context->hardware_head && head_callback) yolo32_publish_head(worker_id, 1);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.1/cv3.1.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.1/cv3.1.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.1/cv3.1.2/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 148U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[62]);
    gemmini_fence();
    silu_config_cycles[62] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/m/m.0/cv1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_148,&batch_conv_bindings[worker_id][50]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/m/m.0/cv1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/m/m.0/cv1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 149U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/m/m.0/cv1/act/Mul", silu_config_cycles[62]);
  }
      context->stage++;
      break;
    case 150U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv2/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[63]);
    gemmini_fence();
    silu_config_cycles[63] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/m/m.0/cv2/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_150,&batch_conv_bindings[worker_id][51]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/m/m.0/cv2/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/m/m.0/cv2/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/m/m.0/cv2/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 151U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/m/m.0/cv2/act/Mul", silu_config_cycles[63]);
  }
      context->stage++;
      break;
    case 152U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONCAT, "Concat", "/model.23/Concat");
  /* STAGE8_CONCAT_ELIDED: /model.23/Concat */

    yolo_profile_add(PROFILE_CONCAT, "Concat", "/model.23/Concat", yolo_profile_clock() - op_start);
  }
      context->stage++;
      break;
    case 153U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv3/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[64]);
    gemmini_fence();
    silu_config_cycles[64] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.23/cv3/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    /* STAGE8_SPLITK_CONCAT_CONV: /model.23/Concat */
    yolo32_batch_ws_153(&batch_ws_bindings[worker_id][19]);
    yolo32_reused_fence(153U);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.23/cv3/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.23/cv3/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.23/cv3/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 154U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.23/cv3/act/Mul", silu_config_cycles[64]);
  }
      context->stage++;
      break;
    case 155U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[65]);
    gemmini_fence();
    silu_config_cycles[65] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.2/cv2.2.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_155,&batch_conv_bindings[worker_id][52]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.2/cv2.2.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.2/cv2.2.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.0/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 156U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.0/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[66]);
    gemmini_fence();
    silu_config_cycles[66] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.2/cv3.2.0/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_156,&batch_conv_bindings[worker_id][53]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.2/cv3.2.0/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.2/cv3.2.0/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.0/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 157U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.2/cv2.2.0/act/Mul", silu_config_cycles[65]);
  }
      context->stage++;
      break;
    case 158U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.2/cv3.2.0/act/Mul", silu_config_cycles[66]);
  }
      context->stage++;
      break;
    case 159U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[67]);
    gemmini_fence();
    silu_config_cycles[67] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.2/cv2.2.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_159,&batch_conv_bindings[worker_id][54]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.2/cv2.2.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.2/cv2.2.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 160U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.1/conv/Conv");

    uint64_t silu_config_start = yolo_profile_clock();
    yolo32_packed_silu_lut(packed_silu_luts[68]);
    gemmini_fence();
    silu_config_cycles[68] = yolo_profile_clock() - silu_config_start;
    op_start = yolo_profile_clock();

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.2/cv3.2.1/conv/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_160,&batch_conv_bindings[worker_id][55]);
    gemmini_fence();
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.2/cv3.2.1/conv/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.2/cv3.2.1/conv/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.1/conv/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 161U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv2.2/cv2.2.1/act/Mul", silu_config_cycles[67]);
  }
      context->stage++;
      break;
    case 162U:
{
    yolo_profile_add(PROFILE_SILU_FUSED_LUT, "SILU_FUSED_LUT", "/model.24/cv3.2/cv3.2.1/act/Mul", silu_config_cycles[68]);
  }
      context->stage++;
      break;
    case 163U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv2.2/cv2.2.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_163,&batch_conv_bindings[worker_id][56]);
    gemmini_fence();
    if (context->hardware_head && head_callback) yolo32_publish_head(worker_id, 5);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv2.2/cv2.2.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv2.2/cv2.2.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv2.2/cv2.2.2/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 164U:
{
    uint64_t op_start = yolo_profile_begin(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.2/Conv");

    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, "CONV_IN_LAYOUT", "/model.24/cv3.2/cv3.2.2/Conv", 0);
    uint64_t phase_start = yolo_profile_clock();
    yolo32_bound_conv(&conv_packet_plan_164,&batch_conv_bindings[worker_id][57]);
    gemmini_fence();
    if (context->hardware_head && head_callback) yolo32_publish_head(worker_id, 2);
    yolo_profile_add(PROFILE_CONV_GEMMINI, "CONV_GEMMINI", "/model.24/cv3.2/cv3.2.2/Conv", yolo_profile_clock() - phase_start);
    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, "CONV_OUT_LAYOUT", "/model.24/cv3.2/cv3.2.2/Conv", 0);

    yolo_profile_add(PROFILE_CONV_TOTAL, "Conv", "/model.24/cv3.2/cv3.2.2/Conv", yolo_profile_clock() - op_start);
  }
      context->stage++;
      context->waiting = 1U;
      context->poll_armed = 0U;
      return YOLOV5NU_DIM16_RUNNING;
    case 165U:
      gemmini_fence();
      frame_counter_finish(worker_id);
      context->stage = YOLOV5NU_GRAPH_STAGE_COUNT;
      return YOLOV5NU_DIM16_HEAD_READY;
    default: return YOLOV5NU_DIM16_ERROR;
    }
    if (parallel_mode || yolo32_independent_enabled || analysis_enabled) return YOLOV5NU_DIM16_RUNNING;
#if YOLO32_BOTTLENECK_DIAG
    if (yolo32_mpv3_requested()) return YOLOV5NU_DIM16_RUNNING;
#endif
  }
}
