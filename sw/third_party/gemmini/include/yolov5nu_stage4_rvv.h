#ifndef YOLOV5NU_STAGE4_RVV_H
#define YOLOV5NU_STAGE4_RVV_H

#include <stdint.h>

#ifdef __riscv_vector
static inline void yolov5nu_rvv_sigmoid_lut_i8(const int8_t *src,
    int8_t *dst, uintptr_t count, const int8_t lut[256]) {
  if (count == 0) return;
  uintptr_t table_vl;
  asm volatile(
    "vsetvli %[vl], %[n], e8, m8, ta, ma"
    : [vl] "=&r" (table_vl)
    : [n] "r" ((uintptr_t)256));

  if (table_vl != 256) {
    for (uintptr_t i = 0; i < count; i++)
      dst[i] = lut[(uint8_t)src[i]];
    return;
  }

  uintptr_t remaining = count;
  uintptr_t vl;
  asm volatile(
    "vsetvli zero, %[entries], e8, m8, ta, ma\n\t"
    "vle8.v v8, (%[lut])\n\t"
    "1:\n\t"
    "vsetvli %[vl], %[remaining], e8, m8, ta, ma\n\t"
    "vle8.v v16, (%[src])\n\t"
    "vrgather.vv v24, v8, v16\n\t"
    "vse8.v v24, (%[dst])\n\t"
    "add %[src], %[src], %[vl]\n\t"
    "add %[dst], %[dst], %[vl]\n\t"
    "sub %[remaining], %[remaining], %[vl]\n\t"
    "bnez %[remaining], 1b"
    : [src] "+r" (src), [dst] "+r" (dst),
      [remaining] "+r" (remaining), [vl] "=&r" (vl)
    : [lut] "r" (lut), [entries] "r" ((uintptr_t)256)
    : "memory", "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15",
      "v16", "v17", "v18", "v19", "v20", "v21", "v22", "v23",
      "v24", "v25", "v26", "v27", "v28", "v29", "v30", "v31");
}

static inline int yolov5nu_rvv_dfl_vl16_supported(void) {
  uintptr_t vl;
  asm volatile(
    "vsetvli %[vl], %[n], e32, m2, ta, ma"
    : [vl] "=&r" (vl)
    : [n] "r" ((uintptr_t)16));
  return vl == 16;
}

static inline int8_t yolov5nu_rvv_dfl_max_i8x16(const int8_t logits[16]) {
  long maximum;
  asm volatile(
    "vsetvli zero, %[n], e8, m1, ta, ma\n\t"
    "vle8.v v8, (%[logits])\n\t"
    "vmv.s.x v0, %[seed]\n\t"
    "vredmax.vs v0, v8, v0\n\t"
    "vmv.x.s %[maximum], v0"
    : [maximum] "=&r" (maximum)
    : [n] "r" ((uintptr_t)16), [logits] "r" (logits), [seed] "r" (-128L)
    : "memory", "v0", "v8");
  return (int8_t)maximum;
}

static inline int32_t yolov5nu_rvv_dfl_probability_dot_i8x16(
    const float exponentials[16], float reciprocal,
    const int8_t weights[16]) {
  long accumulator;
  asm volatile(
    "csrwi frm, 0\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vle32.v v2, (%[exponentials])\n\t"
    "vfmul.vf v2, v2, %[reciprocal]\n\t"
    "vfcvt.x.f.v v2, v2\n\t"
    "vmax.vx v2, v2, zero\n\t"
    "vmin.vx v2, v2, %[maximum]\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vnclip.wi v4, v2, 0\n\t"
    "vsetvli zero, %[n], e8, mf2, ta, ma\n\t"
    "vle8.v v6, (%[weights])\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vsext.vf2 v8, v6\n\t"
    "vwmul.vv v10, v4, v8\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vmv.s.x v0, zero\n\t"
    "vredsum.vs v2, v10, v0\n\t"
    "vmv.x.s %[accumulator], v2"
    : [accumulator] "=&r" (accumulator)
    : [n] "r" ((uintptr_t)16), [exponentials] "r" (exponentials),
      [reciprocal] "f" (reciprocal), [weights] "r" (weights),
      [maximum] "r" (127L)
    : "memory", "v0", "v2", "v3", "v4", "v6", "v8", "v10", "v11");
  return (int32_t)accumulator;
}

static inline void yolov5nu_rvv_dfl_max_i8x4x16(
    const int8_t logits[64], int8_t maxima[4]) {
  long max0, max1, max2, max3;
  asm volatile(
    "vsetvli zero, %[n], e8, m1, ta, ma\n\t"
    "vle8.v v8, (%[edge0])\n\t"
    "vmv.s.x v0, %[seed]\n\t"
    "vredmax.vs v0, v8, v0\n\t"
    "vmv.x.s %[max0], v0\n\t"
    "vle8.v v8, (%[edge1])\n\t"
    "vmv.s.x v0, %[seed]\n\t"
    "vredmax.vs v0, v8, v0\n\t"
    "vmv.x.s %[max1], v0\n\t"
    "vle8.v v8, (%[edge2])\n\t"
    "vmv.s.x v0, %[seed]\n\t"
    "vredmax.vs v0, v8, v0\n\t"
    "vmv.x.s %[max2], v0\n\t"
    "vle8.v v8, (%[edge3])\n\t"
    "vmv.s.x v0, %[seed]\n\t"
    "vredmax.vs v0, v8, v0\n\t"
    "vmv.x.s %[max3], v0"
    : [max0] "=&r" (max0), [max1] "=&r" (max1),
      [max2] "=&r" (max2), [max3] "=&r" (max3)
    : [n] "r" ((uintptr_t)16), [edge0] "r" (logits),
      [edge1] "r" (logits + 16), [edge2] "r" (logits + 32),
      [edge3] "r" (logits + 48), [seed] "r" (-128L)
    : "memory", "v0", "v8");
  maxima[0] = (int8_t)max0;
  maxima[1] = (int8_t)max1;
  maxima[2] = (int8_t)max2;
  maxima[3] = (int8_t)max3;
}

static inline void yolov5nu_rvv_dfl_ordered_sum_f32x4x16(
    const float exponentials[4][16], float sums[4]) {
  const float zero = 0.0f;
  float sum0, sum1, sum2, sum3;
  asm volatile(
    "csrwi frm, 0\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge0])\n\t"
    "vfredosum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum0], v4\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge1])\n\t"
    "vfredosum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum1], v4\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge2])\n\t"
    "vfredosum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum2], v4\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge3])\n\t"
    "vfredosum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum3], v4"
    : [sum0] "=&f" (sum0), [sum1] "=&f" (sum1),
      [sum2] "=&f" (sum2), [sum3] "=&f" (sum3)
    : [n] "r" ((uintptr_t)16), [zero] "f" (zero),
      [edge0] "r" (exponentials[0]), [edge1] "r" (exponentials[1]),
      [edge2] "r" (exponentials[2]), [edge3] "r" (exponentials[3])
    : "memory", "v0", "v2", "v3", "v4");
  sums[0] = sum0;
  sums[1] = sum1;
  sums[2] = sum2;
  sums[3] = sum3;
}

static inline void yolov5nu_rvv_dfl_unordered_sum_f32x4x16(
    const float exponentials[4][16], float sums[4]) {
  const float zero = 0.0f;
  float sum0, sum1, sum2, sum3;
  asm volatile(
    "csrwi frm, 0\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge0])\n\t"
    "vfredusum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum0], v4\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge1])\n\t"
    "vfredusum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum1], v4\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge2])\n\t"
    "vfredusum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum2], v4\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[edge3])\n\t"
    "vfredusum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum3], v4"
    : [sum0] "=&f" (sum0), [sum1] "=&f" (sum1),
      [sum2] "=&f" (sum2), [sum3] "=&f" (sum3)
    : [n] "r" ((uintptr_t)16), [zero] "f" (zero),
      [edge0] "r" (exponentials[0]), [edge1] "r" (exponentials[1]),
      [edge2] "r" (exponentials[2]), [edge3] "r" (exponentials[3])
    : "memory", "v0", "v2", "v3", "v4");
  sums[0] = sum0;
  sums[1] = sum1;
  sums[2] = sum2;
  sums[3] = sum3;
}

static inline float yolov5nu_rvv_dfl_ordered_sum_f32x16(
    const float exponentials[16]) {
  const float zero = 0.0f;
  float sum;
  asm volatile(
    "csrwi frm, 0\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vfmv.s.f v0, %[zero]\n\t"
    "vle32.v v2, (%[values])\n\t"
    "vfredosum.vs v4, v2, v0\n\t"
    "vfmv.f.s %[sum], v4"
    : [sum] "=&f" (sum)
    : [n] "r" ((uintptr_t)16), [zero] "f" (zero),
      [values] "r" (exponentials)
    : "memory", "v0", "v2", "v3", "v4");
  return sum;
}

static inline void yolov5nu_rvv_dfl_elementwise_sum_f32x4x16(
    const float exponentials[4][16], float sums[4]) {
  const float *values = &exponentials[0][0];
  uintptr_t bins = 16;
  asm volatile(
    "csrwi frm, 0\n\t"
    "vsetvli zero, %[lanes], e32, m1, ta, ma\n\t"
    "vmv.v.i v8, 0\n\t"
    "1:\n\t"
    "vlse32.v v10, (%[values]), %[edge_stride]\n\t"
    "vfadd.vv v8, v8, v10\n\t"
    "addi %[values], %[values], 4\n\t"
    "addi %[bins], %[bins], -1\n\t"
    "bnez %[bins], 1b\n\t"
    "vse32.v v8, (%[sums])"
    : [values] "+r" (values), [bins] "+r" (bins)
    : [lanes] "r" ((uintptr_t)4), [edge_stride] "r" ((uintptr_t)64),
      [sums] "r" (sums)
    : "memory", "v8", "v10");
}

static inline void yolov5nu_rvv_dfl_exp_gather_f32x16(
    const int8_t logits[16], int8_t maximum, const float exp_lut[256],
    float exponentials[16]) {
  long max_value = maximum;
  asm volatile(
    "vsetvli zero, %[n], e8, mf2, ta, ma\n\t"
    "vle8.v v2, (%[logits])\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vsext.vf2 v4, v2\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vsext.vf2 v6, v4\n\t"
    "vrsub.vx v6, v6, %[maximum]\n\t"
    "vsll.vi v6, v6, 2\n\t"
    "vluxei32.v v8, (%[lut]), v6\n\t"
    "vse32.v v8, (%[output])"
    :: [n] "r" ((uintptr_t)16), [logits] "r" (logits),
      [maximum] "r" (max_value), [lut] "r" (exp_lut),
      [output] "r" (exponentials)
    : "memory", "v2", "v4", "v6", "v7", "v8", "v9");
}

static inline void yolov5nu_rvv_dfl_probability_dot_i8x4x16(
    const float exponentials[4][16], const float reciprocals[4],
    const int8_t weights[16], int32_t accumulators[4]) {
  long acc0, acc1, acc2, acc3;
  asm volatile(
    "csrwi frm, 0\n\t"
    "vsetvli zero, %[n], e8, mf2, ta, ma\n\t"
    "vle8.v v6, (%[weights])\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vsext.vf2 v8, v6\n\t"

    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vle32.v v2, (%[edge0])\n\t"
    "vfmul.vf v2, v2, %[reciprocal0]\n\t"
    "vfcvt.x.f.v v2, v2\n\t"
    "vmax.vx v2, v2, zero\n\t"
    "vmin.vx v2, v2, %[maximum]\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vnclip.wi v4, v2, 0\n\t"
    "vwmul.vv v10, v4, v8\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vmv.s.x v0, zero\n\t"
    "vredsum.vs v2, v10, v0\n\t"
    "vmv.x.s %[acc0], v2\n\t"

    "vle32.v v2, (%[edge1])\n\t"
    "vfmul.vf v2, v2, %[reciprocal1]\n\t"
    "vfcvt.x.f.v v2, v2\n\t"
    "vmax.vx v2, v2, zero\n\t"
    "vmin.vx v2, v2, %[maximum]\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vnclip.wi v4, v2, 0\n\t"
    "vwmul.vv v10, v4, v8\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vmv.s.x v0, zero\n\t"
    "vredsum.vs v2, v10, v0\n\t"
    "vmv.x.s %[acc1], v2\n\t"

    "vle32.v v2, (%[edge2])\n\t"
    "vfmul.vf v2, v2, %[reciprocal2]\n\t"
    "vfcvt.x.f.v v2, v2\n\t"
    "vmax.vx v2, v2, zero\n\t"
    "vmin.vx v2, v2, %[maximum]\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vnclip.wi v4, v2, 0\n\t"
    "vwmul.vv v10, v4, v8\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vmv.s.x v0, zero\n\t"
    "vredsum.vs v2, v10, v0\n\t"
    "vmv.x.s %[acc2], v2\n\t"

    "vle32.v v2, (%[edge3])\n\t"
    "vfmul.vf v2, v2, %[reciprocal3]\n\t"
    "vfcvt.x.f.v v2, v2\n\t"
    "vmax.vx v2, v2, zero\n\t"
    "vmin.vx v2, v2, %[maximum]\n\t"
    "vsetvli zero, %[n], e16, m1, ta, ma\n\t"
    "vnclip.wi v4, v2, 0\n\t"
    "vwmul.vv v10, v4, v8\n\t"
    "vsetvli zero, %[n], e32, m2, ta, ma\n\t"
    "vmv.s.x v0, zero\n\t"
    "vredsum.vs v2, v10, v0\n\t"
    "vmv.x.s %[acc3], v2"
    : [acc0] "=&r" (acc0), [acc1] "=&r" (acc1),
      [acc2] "=&r" (acc2), [acc3] "=&r" (acc3)
    : [n] "r" ((uintptr_t)16), [weights] "r" (weights),
      [edge0] "r" (exponentials[0]), [edge1] "r" (exponentials[1]),
      [edge2] "r" (exponentials[2]), [edge3] "r" (exponentials[3]),
      [reciprocal0] "f" (reciprocals[0]), [reciprocal1] "f" (reciprocals[1]),
      [reciprocal2] "f" (reciprocals[2]), [reciprocal3] "f" (reciprocals[3]),
      [maximum] "r" (127L)
    : "memory", "v0", "v2", "v3", "v4", "v6", "v8", "v10", "v11");
  accumulators[0] = (int32_t)acc0;
  accumulators[1] = (int32_t)acc1;
  accumulators[2] = (int32_t)acc2;
  accumulators[3] = (int32_t)acc3;
}

static inline void yolov5nu_rvv_add_ratio_i8(const int8_t *a,
    const int8_t *b, int8_t *dst, uintptr_t count, float a_ratio,
    float b_ratio) {
  asm volatile("csrwi frm, 0" ::: "memory");
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v1, (%[a])\n\t"
      "vle8.v v8, (%[b])\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vsext.vf2 v2, v1\n\t"
      "vsext.vf2 v10, v8\n\t"
      "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vsext.vf2 v12, v10\n\t"
      "vfcvt.f.x.v v4, v4\n\t"
      "vfcvt.f.x.v v12, v12\n\t"
      "vfmul.vf v4, v4, %[ar]\n\t"
      "vfmul.vf v12, v12, %[br]\n\t"
      "vfadd.vv v4, v4, v12\n\t"
      "vfcvt.x.f.v v4, v4\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vnclip.wi v16, v4, 0\n\t"
      "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
      "vnclip.wi v18, v16, 0\n\t"
      "vse8.v v18, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [a] "r" (a), [b] "r" (b), [dst] "r" (dst),
        [ar] "f" (a_ratio), [br] "f" (b_ratio)
      : "memory", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8",
        "v9", "v10", "v11", "v12", "v13", "v14", "v15", "v16",
        "v17", "v18");
    a += vl;
    b += vl;
    dst += vl;
    count -= vl;
  }
}

/* Q22 integer Add. Coefficients are generated per scale pair and exhaustively
 * checked against the FP32 RNE reference over the complete int8 input domain. */
static inline void yolov5nu_rvv_add_fixed_i8(const int8_t *a,
    const int8_t *b, int8_t *dst, uintptr_t count, int32_t a_multiplier,
    int32_t b_multiplier) {
  asm volatile("csrwi vxrm, 1" ::: "memory");
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v1, (%[a])\n\t"
      "vle8.v v8, (%[b])\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vsext.vf2 v2, v1\n\t"
      "vsext.vf2 v10, v8\n\t"
      "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vsext.vf2 v12, v10\n\t"
      "vmul.vx v4, v4, %[am]\n\t"
      "vmul.vx v12, v12, %[bm]\n\t"
      "vadd.vv v4, v4, v12\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vnclip.wi v16, v4, 22\n\t"
      "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
      "vnclip.wi v18, v16, 0\n\t"
      "vse8.v v18, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [a] "r" (a), [b] "r" (b), [dst] "r" (dst),
        [am] "r" ((long)a_multiplier), [bm] "r" ((long)b_multiplier)
      : "memory", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8",
        "v9", "v10", "v11", "v12", "v13", "v14", "v15", "v16",
        "v17", "v18");
    a += vl;
    b += vl;
    dst += vl;
    count -= vl;
  }
}

/* Preserve the original Add quantization and the following Concat requant. */
static inline void yolov5nu_rvv_add_two_step_i8(const int8_t *a,
    const int8_t *b, int8_t *dst, uintptr_t count, float a_ratio,
    float b_ratio, float requant_ratio) {
  asm volatile("csrwi frm, 0" ::: "memory");
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v1, (%[a])\n\t"
      "vle8.v v8, (%[b])\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vsext.vf2 v2, v1\n\t"
      "vsext.vf2 v10, v8\n\t"
      "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vsext.vf2 v12, v10\n\t"
      "vfcvt.f.x.v v4, v4\n\t"
      "vfcvt.f.x.v v12, v12\n\t"
      "vfmul.vf v4, v4, %[ar]\n\t"
      "vfmul.vf v12, v12, %[br]\n\t"
      "vfadd.vv v4, v4, v12\n\t"
      "vfcvt.x.f.v v4, v4\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vnclip.wi v16, v4, 0\n\t"
      "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
      "vnclip.wi v18, v16, 0\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vsext.vf2 v2, v18\n\t"
      "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vfcvt.f.x.v v4, v4\n\t"
      "vfmul.vf v4, v4, %[rr]\n\t"
      "vfcvt.x.f.v v4, v4\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vnclip.wi v16, v4, 0\n\t"
      "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
      "vnclip.wi v18, v16, 0\n\t"
      "vse8.v v18, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [a] "r" (a), [b] "r" (b), [dst] "r" (dst),
        [ar] "f" (a_ratio), [br] "f" (b_ratio), [rr] "f" (requant_ratio)
      : "memory", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8",
        "v9", "v10", "v11", "v12", "v13", "v14", "v15", "v16",
        "v17", "v18");
    a += vl;
    b += vl;
    dst += vl;
    count -= vl;
  }
}

/* Preserve Add quantization, replacing only the following requant with a LUT. */
static inline void yolov5nu_rvv_add_two_step_lut_i8(const int8_t *a,
    const int8_t *b, int8_t *dst, uintptr_t count, float a_ratio,
    float b_ratio, const int8_t requant_lut[256]) {
  asm volatile("csrwi frm, 0" ::: "memory");
  while (count) {
    uintptr_t vl;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
      "vle8.v v1, (%[a])\n\t"
      "vle8.v v8, (%[b])\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vsext.vf2 v2, v1\n\t"
      "vsext.vf2 v10, v8\n\t"
      "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
      "vsext.vf2 v4, v2\n\t"
      "vsext.vf2 v12, v10\n\t"
      "vfcvt.f.x.v v4, v4\n\t"
      "vfcvt.f.x.v v12, v12\n\t"
      "vfmul.vf v4, v4, %[ar]\n\t"
      "vfmul.vf v12, v12, %[br]\n\t"
      "vfadd.vv v4, v4, v12\n\t"
      "vfcvt.x.f.v v4, v4\n\t"
      "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
      "vnclip.wi v16, v4, 0\n\t"
      "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
      "vnclip.wi v18, v16, 0\n\t"
      "vluxei8.v v18, (%[lut]), v18\n\t"
      "vse8.v v18, (%[dst])"
      : [vl] "=&r" (vl)
      : [n] "r" (count), [a] "r" (a), [b] "r" (b), [dst] "r" (dst),
        [ar] "f" (a_ratio), [br] "f" (b_ratio), [lut] "r" (requant_lut)
      : "memory", "v1", "v2", "v3", "v4", "v5", "v6", "v7", "v8",
        "v9", "v10", "v11", "v12", "v13", "v14", "v15", "v16",
        "v17", "v18");
    a += vl;
    b += vl;
    dst += vl;
    count -= vl;
  }
}

/* Load the full table once per strided Add and use register gather for lookup. */
static inline void yolov5nu_rvv_add_two_step_register_strided_i8(
    const int8_t *a, const int8_t *b, int8_t *dst, uintptr_t positions,
    uintptr_t channels, uintptr_t dst_stride, float a_ratio, float b_ratio,
    float requant_ratio, const int8_t requant_lut[256]) {
  uintptr_t table_vl;
  asm volatile(
    "vsetvli %[vl], %[entries], e8, m8, ta, ma"
    : [vl] "=&r" (table_vl)
    : [entries] "r" ((uintptr_t)256));
  if (table_vl != 256) {
    for (uintptr_t position = 0; position < positions; position++) {
      yolov5nu_rvv_add_two_step_i8(a, b, dst, channels, a_ratio, b_ratio,
        requant_ratio);
      a += channels;
      b += channels;
      dst += dst_stride;
    }
    return;
  }
  asm volatile(
    "csrwi frm, 0\n\t"
    "vsetvli zero, %[entries], e8, m8, ta, ma\n\t"
    "vle8.v v8, (%[lut])"
    :: [entries] "r" ((uintptr_t)256), [lut] "r" (requant_lut)
    : "memory", "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15");
  for (uintptr_t position = 0; position < positions; position++) {
    uintptr_t remaining = channels;
    while (remaining) {
      uintptr_t vl;
      asm volatile(
        "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
        "vle8.v v0, (%[a])\n\t"
        "vle8.v v1, (%[b])\n\t"
        "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
        "vsext.vf2 v2, v0\n\t"
        "vsext.vf2 v4, v1\n\t"
        "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
        "vsext.vf2 v16, v2\n\t"
        "vsext.vf2 v20, v4\n\t"
        "vfcvt.f.x.v v16, v16\n\t"
        "vfcvt.f.x.v v20, v20\n\t"
        "vfmul.vf v16, v16, %[ar]\n\t"
        "vfmul.vf v20, v20, %[br]\n\t"
        "vfadd.vv v16, v16, v20\n\t"
        "vfcvt.x.f.v v16, v16\n\t"
        "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
        "vnclip.wi v2, v16, 0\n\t"
        "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
        "vnclip.wi v0, v2, 0\n\t"
        "vsetvli zero, %[vl], e8, m8, ta, ma\n\t"
        "vrgather.vv v24, v8, v0\n\t"
        "vse8.v v24, (%[dst])"
        : [vl] "=&r" (vl)
        : [n] "r" (remaining), [a] "r" (a), [b] "r" (b),
          [dst] "r" (dst), [ar] "f" (a_ratio), [br] "f" (b_ratio)
        : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7",
          "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15",
          "v16", "v17", "v18", "v19", "v20", "v21", "v22", "v23",
          "v24", "v25", "v26", "v27", "v28", "v29", "v30", "v31");
      a += vl;
      b += vl;
      dst += vl;
      remaining -= vl;
    }
    dst += dst_stride - channels;
  }
}

static inline void yolov5nu_rvv_add_two_step_register_fixed_strided_i8(
    const int8_t *a, const int8_t *b, int8_t *dst, uintptr_t positions,
    uintptr_t channels, uintptr_t dst_stride, int32_t a_multiplier,
    int32_t b_multiplier, const int8_t requant_lut[256]) {
  uintptr_t table_vl;
  asm volatile(
    "vsetvli %[vl], %[entries], e8, m8, ta, ma"
    : [vl] "=&r" (table_vl)
    : [entries] "r" ((uintptr_t)256));
  if (table_vl != 256) {
    for (uintptr_t position = 0; position < positions; position++) {
      yolov5nu_rvv_add_fixed_i8(a, b, dst, channels,
        a_multiplier, b_multiplier);
      for (uintptr_t channel = 0; channel < channels; channel++)
        dst[channel] = requant_lut[(uint8_t)dst[channel]];
      a += channels;
      b += channels;
      dst += dst_stride;
    }
    return;
  }
  asm volatile(
    "csrwi vxrm, 1\n\t"
    "vsetvli zero, %[entries], e8, m8, ta, ma\n\t"
    "vle8.v v8, (%[lut])"
    :: [entries] "r" ((uintptr_t)256), [lut] "r" (requant_lut)
    : "memory", "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15");
  for (uintptr_t position = 0; position < positions; position++) {
    uintptr_t remaining = channels;
    while (remaining) {
      uintptr_t vl;
      asm volatile(
        "vsetvli %[vl], %[n], e8, m1, ta, ma\n\t"
        "vle8.v v0, (%[a])\n\t"
        "vle8.v v1, (%[b])\n\t"
        "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
        "vsext.vf2 v2, v0\n\t"
        "vsext.vf2 v4, v1\n\t"
        "vsetvli zero, %[vl], e32, m4, ta, ma\n\t"
        "vsext.vf2 v16, v2\n\t"
        "vsext.vf2 v20, v4\n\t"
        "vmul.vx v16, v16, %[am]\n\t"
        "vmul.vx v20, v20, %[bm]\n\t"
        "vadd.vv v16, v16, v20\n\t"
        "vsetvli zero, %[vl], e16, m2, ta, ma\n\t"
        "vnclip.wi v2, v16, 22\n\t"
        "vsetvli zero, %[vl], e8, m1, ta, ma\n\t"
        "vnclip.wi v0, v2, 0\n\t"
        "vsetvli zero, %[vl], e8, m8, ta, ma\n\t"
        "vrgather.vv v24, v8, v0\n\t"
        "vse8.v v24, (%[dst])"
        : [vl] "=&r" (vl)
        : [n] "r" (remaining), [a] "r" (a), [b] "r" (b),
          [dst] "r" (dst), [am] "r" ((long)a_multiplier),
          [bm] "r" ((long)b_multiplier)
        : "memory", "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7",
          "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15",
          "v16", "v17", "v18", "v19", "v20", "v21", "v22", "v23",
          "v24", "v25", "v26", "v27", "v28", "v29", "v30", "v31");
      a += vl;
      b += vl;
      dst += vl;
      remaining -= vl;
    }
    dst += dst_stride - channels;
  }
}

static inline int8_t yolov5nu_rvv_class_max_i8(const int8_t *src,
    uintptr_t count, int *class_id) {
  int best = -128;
  int best_index = 0;
  uintptr_t offset = 0;
  while (count) {
    uintptr_t vl;
    long chunk_best;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m8, ta, ma\n\t"
      "vle8.v v8, (%[src])\n\t"
      "vmv.s.x v0, %[seed]\n\t"
      "vredmax.vs v0, v8, v0\n\t"
      "vmv.x.s %[best], v0"
      : [vl] "=&r" (vl), [best] "=&r" (chunk_best)
      : [n] "r" (count), [src] "r" (src), [seed] "r" (-128L)
      : "memory", "v0", "v8", "v9", "v10", "v11", "v12", "v13",
        "v14", "v15");
    if ((int8_t)chunk_best > best) {
      long first;
      asm volatile(
        "vmseq.vx v0, v8, %[best]\n\t"
        "vfirst.m %[first], v0"
        : [first] "=&r" (first)
        : [best] "r" (chunk_best)
        : "memory", "v0");
      best = (int8_t)chunk_best;
      best_index = (int)(offset + (uintptr_t)first);
    }
    src += vl;
    offset += vl;
    count -= vl;
  }
  *class_id = best_index;
  return (int8_t)best;
}

static inline int8_t yolov5nu_rvv_class_score_max_i8(const int8_t *src,
    uintptr_t count) {
  int best = -128;
  while (count) {
    uintptr_t vl;
    long chunk_best;
    asm volatile(
      "vsetvli %[vl], %[n], e8, m4, ta, ma\n\t"
      "vle8.v v8, (%[src])\n\t"
      "vmv.s.x v0, %[seed]\n\t"
      "vredmax.vs v0, v8, v0\n\t"
      "vmv.x.s %[best], v0"
      : [vl] "=&r" (vl), [best] "=&r" (chunk_best)
      : [n] "r" (count), [src] "r" (src), [seed] "r" (-128L)
      : "memory", "v0", "v8", "v9", "v10", "v11");
    if ((int8_t)chunk_best > best) best = (int8_t)chunk_best;
    src += vl;
    count -= vl;
  }
  return (int8_t)best;
}
#endif

#endif
