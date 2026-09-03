#include "gemcc_kernel_ops.h"

#include <math.h>
#include <stdint.h>

/* I: 任意非负 double
 * P: Python round-half-even 到非负整数并夹到 [0, 127]
 * O: LUT 元素
 * A: shiroha_suki
 * T: 2026-08-29
 */
static int py_round_nonneg(double y) {
  double fl = floor(y);
  double frac = y - fl;
  int v;
  if (frac < 0.5)
    v = (int)fl;
  else if (frac > 0.5)
    v = (int)fl + 1;
  else {
    int fi = (int)fl;
    v = (fi % 2 == 0) ? fi : fi + 1;
  }
  if (v < 0)
    return 0;
  if (v > 127)
    return 127;
  return v;
}

/* I: lut[256]，siluc=output_scale/127
 * P: 填 INT8 SiLU sigmoid LUT，索引 u 对应 q=u-128
 * O: 写入 lut；元素落在 [0,127]
 * A: shiroha_suki
 * T: 2026-08-29
 */
static void fill_silu_lut(int8_t lut[256], float siluc) {
  double lut_scale = (double)siluc * 127.0;
  for (int u = 0; u < 256; ++u) {
    double x = (double)(u - 128) * lut_scale;
    double s = 1.0 / (1.0 + exp(-x));
    lut[u] = (int8_t)py_round_nonneg(s * 127.0);
  }
}

/* I: 任意 int
 * P: 饱和到 INT8 激活范围 [-128, 127]
 * O: 饱和后的 int
 * A: shiroha_suki
 * T: 2026-08-29
 */
static int saturate_i8(int value) {
  if (value > 127)
    return 127;
  if (value < -128)
    return -128;
  return value;
}

/* I: 任意 double
 * P: 远离零的最近整数
 * O: 四舍五入结果
 * A: shiroha_suki
 * T: 2026-08-29
 */
static int round_away(double x) {
  return (int)(x >= 0.0 ? floor(x + 0.5) : ceil(x - 0.5));
}

/* I: dst/src NHWC i8，尺寸 n/h/w/c，siluc=output_scale/127；允许 dst==src
 * P: 按 LUT 做 INT8 SiLU：(q*lut+64)>>7。非法尺寸或空指针直接返回
 * O: 写入 dst；src 仅在非别名时保持不变
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_kernel_silu_i8_scalar(int8_t *dst, const int8_t *src, int64_t n,
                                 int64_t h, int64_t w, int64_t c, float siluc) {
  if (!dst || !src || n <= 0 || h <= 0 || w <= 0 || c <= 0)
    return;
  int8_t lut[256];
  fill_silu_lut(lut, siluc);
  int64_t nhw = n * h * w;
  for (int64_t i = 0; i < nhw; ++i) {
    for (int64_t j = 0; j < c; ++j) {
      int q32 = (int)src[i * c + j];
      int s8 = (int)lut[q32 + 128];
      dst[i * c + j] = (int8_t)saturate_i8((q32 * s8 + 64) >> 7);
    }
  }
}

/* I: dst NHWC f32，src NHWC i8，尺寸 n/h/w/c，siluc=output_scale/127；
 *    dst 与 src 必须是不重叠的缓冲，由 op verifier 保证
 * P: 与 gemcc_kernel_silu_i8_scalar 同一张 LUT，但结果留在 f32：
 *    q * lut(q) * siluc，不再量化回 i8
 * O: 写入 dst；空指针、同指针或非法尺寸不写。同指针只是兜底，部分重叠在这里
 *    看不出来，真正的防线在 verifier
 * A: shiroha_suki, shiroha_suki
 * T: 2026-08-30, 2026-08-30
 */
void gemcc_kernel_silu_dequant_i8_f32_scalar(float *dst, const int8_t *src,
                                             int64_t n, int64_t h, int64_t w,
                                             int64_t c, float siluc) {
  if (!dst || !src || (const void *)dst == (const void *)src || n <= 0 ||
      h <= 0 || w <= 0 || c <= 0)
    return;
  int8_t lut[256];
  fill_silu_lut(lut, siluc);
  int64_t nhw = n * h * w;
  for (int64_t i = 0; i < nhw; ++i) {
    for (int64_t j = 0; j < c; ++j) {
      int q32 = (int)src[i * c + j];
      int s8 = (int)lut[q32 + 128];
      dst[i * c + j] = (float)q32 * (float)s8 * siluc;
    }
  }
}

/* @layerN sigmoid_f32.py stores v/127.0 as `{fp:.8f}` MLIR f32 literals.
 * Same bit patterns as snprintf("%.8f") + strtof, without libc. */
static const float kDiv127Dot8f[128] = {
    0.00000000e+00f, 7.87402038e-03f, 1.57480296e-02f, 2.36220509e-02f,
    3.14960591e-02f, 3.93700786e-02f, 4.72440906e-02f, 5.51181100e-02f,
    6.29921332e-02f, 7.08661377e-02f, 7.87401572e-02f, 8.66141692e-02f,
    9.44881886e-02f, 1.02362201e-01f, 1.10236220e-01f, 1.18110240e-01f,
    1.25984251e-01f, 1.33858263e-01f, 1.41732275e-01f, 1.49606302e-01f,
    1.57480314e-01f, 1.65354326e-01f, 1.73228353e-01f, 1.81102365e-01f,
    1.88976377e-01f, 1.96850389e-01f, 2.04724416e-01f, 2.12598428e-01f,
    2.20472440e-01f, 2.28346467e-01f, 2.36220464e-01f, 2.44094491e-01f,
    2.51968503e-01f, 2.59842515e-01f, 2.67716527e-01f, 2.75590539e-01f,
    2.83464581e-01f, 2.91338593e-01f, 2.99212605e-01f, 3.07086617e-01f,
    3.14960629e-01f, 3.22834641e-01f, 3.30708653e-01f, 3.38582695e-01f,
    3.46456677e-01f, 3.54330719e-01f, 3.62204731e-01f, 3.70078743e-01f,
    3.77952754e-01f, 3.85826766e-01f, 3.93700778e-01f, 4.01574790e-01f,
    4.09448832e-01f, 4.17322844e-01f, 4.25196856e-01f, 4.33070868e-01f,
    4.40944880e-01f, 4.48818892e-01f, 4.56692904e-01f, 4.64566916e-01f,
    4.72440928e-01f, 4.80314970e-01f, 4.88188982e-01f, 4.96062994e-01f,
    5.03937006e-01f, 5.11811018e-01f, 5.19685030e-01f, 5.27559042e-01f,
    5.35433054e-01f, 5.43307066e-01f, 5.51181078e-01f, 5.59055150e-01f,
    5.66929102e-01f, 5.74803174e-01f, 5.82677186e-01f, 5.90551198e-01f,
    5.98425210e-01f, 6.06299222e-01f, 6.14173234e-01f, 6.22047246e-01f,
    6.29921257e-01f, 6.37795269e-01f, 6.45669281e-01f, 6.53543293e-01f,
    6.61417305e-01f, 6.69291317e-01f, 6.77165329e-01f, 6.85039341e-01f,
    6.92913413e-01f, 7.00787425e-01f, 7.08661437e-01f, 7.16535449e-01f,
    7.24409461e-01f, 7.32283473e-01f, 7.40157485e-01f, 7.48031497e-01f,
    7.55905509e-01f, 7.63779521e-01f, 7.71653533e-01f, 7.79527545e-01f,
    7.87401557e-01f, 7.95275569e-01f, 8.03149581e-01f, 8.11023593e-01f,
    8.18897665e-01f, 8.26771677e-01f, 8.34645689e-01f, 8.42519701e-01f,
    8.50393713e-01f, 8.58267725e-01f, 8.66141737e-01f, 8.74015749e-01f,
    8.81889760e-01f, 8.89763772e-01f, 8.97637784e-01f, 9.05511796e-01f,
    9.13385808e-01f, 9.21259820e-01f, 9.29133832e-01f, 9.37007844e-01f,
    9.44881916e-01f, 9.52755928e-01f, 9.60629940e-01f, 9.68503952e-01f,
    9.76377964e-01f, 9.84251976e-01f, 9.92125988e-01f, 1.00000000e+00f};

/* I: dst NHWC f32，src NHWC i8，尺寸 n/h/w/c，out_scale 为输入激活 scale；
 *    dst 与 src 必须是不重叠的缓冲，由 op verifier 保证
 * P: detect head sigmoid：LUT 算 sigmoid(q*out_scale)，half-even 落到 0..127
 *    栅格，再取该栅格的 /127 f32 值（@layerN q127_f32 编码）
 * O: 写入 dst，值域 [0,1]；空指针、同指针或非法尺寸不写。同指针只是兜底，
 *    部分重叠看不出来，真正的防线在 verifier
 * A: shiroha_suki, shiroha_suki
 * T: 2026-08-30, 2026-08-30
 */
void gemcc_kernel_sigmoid_dequant_i8_f32_scalar(float *dst, const int8_t *src,
                                                int64_t n, int64_t h,
                                                int64_t w, int64_t c,
                                                float out_scale) {
  if (!dst || !src || (const void *)dst == (const void *)src || n <= 0 ||
      h <= 0 || w <= 0 || c <= 0)
    return;
  float lut[256];
  double scale = (double)out_scale;
  for (int u = 0; u < 256; ++u) {
    double x = (double)(u - 128) * scale;
    double s = 0.5 + 0.5 * tanh(x / 2.0);
    lut[u] = kDiv127Dot8f[py_round_nonneg(s * 127.0)];
  }
  int64_t nhw = n * h * w;
  for (int64_t i = 0; i < nhw; ++i) {
    for (int64_t j = 0; j < c; ++j) {
      int q32 = (int)src[i * c + j];
      dst[i * c + j] = lut[q32 + 128];
    }
  }
}

/* I: 两个 i8
 * P: 取较大值
 * O: max(a, b)
 * A: shiroha_suki
 * T: 2026-08-29
 */
static int8_t max2_i8(int8_t a, int8_t b) { return a > b ? a : b; }

/* I: dst/src NHWC i8，h/w 为 SAME_UPPER 输出（等于输入）；禁止 dst==src
 * P: 2x2 stride-1 SAME_UPPER：内部 max4，右/下边 max2，角点 copy
 * O: 写入 dst；别名或非法尺寸不写
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_kernel_pool_same_upper_i8_scalar(int8_t *dst, const int8_t *src,
                                            int64_t n, int64_t h, int64_t w,
                                            int64_t c) {
  if (!dst || !src || dst == src || n <= 0 || h <= 0 || w <= 0 || c <= 0)
    return;
  const int64_t row_stride = w * c;
  const int64_t plane = h * w * c;
  const int64_t last_row = h - 1;
  const int64_t last_col = w - 1;
  for (int64_t ni = 0; ni < n; ++ni) {
    const int8_t *in = src + ni * plane;
    int8_t *out = dst + ni * plane;
    for (int64_t row = 0; row < last_row; ++row) {
      const int8_t *row0 = in + row * row_stride;
      const int8_t *row1 = row0 + row_stride;
      int8_t *dst_row = out + row * row_stride;
      for (int64_t col = 0; col < last_col; ++col) {
        const int8_t *p00 = row0 + col * c;
        const int8_t *p01 = p00 + c;
        const int8_t *p10 = row1 + col * c;
        const int8_t *p11 = p10 + c;
        int8_t *d = dst_row + col * c;
        for (int64_t ch = 0; ch < c; ++ch)
          d[ch] = max2_i8(max2_i8(p00[ch], p01[ch]), max2_i8(p10[ch], p11[ch]));
      }
      const int8_t *r0 = row0 + last_col * c;
      const int8_t *r1 = row1 + last_col * c;
      int8_t *dlast = dst_row + last_col * c;
      for (int64_t ch = 0; ch < c; ++ch)
        dlast[ch] = max2_i8(r0[ch], r1[ch]);
    }
    const int8_t *bottom = in + last_row * row_stride;
    int8_t *bottom_out = out + last_row * row_stride;
    for (int64_t col = 0; col < last_col; ++col) {
      const int8_t *p0 = bottom + col * c;
      const int8_t *p1 = p0 + c;
      int8_t *d = bottom_out + col * c;
      for (int64_t ch = 0; ch < c; ++ch)
        d[ch] = max2_i8(p0[ch], p1[ch]);
    }
    const int8_t *corner = bottom + last_col * c;
    int8_t *corner_out = bottom_out + last_col * c;
    for (int64_t ch = 0; ch < c; ++ch)
      corner_out[ch] = corner[ch];
  }
}

/* I: dst/src i8 缓冲，元素个数，input/output scale
 * P: 对称 per-tensor INT8 requant，round_away + i8 饱和。非法 count 不写
 * O: 写入 dst
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_kernel_requantize_i8_scalar(int8_t *dst, const int8_t *src,
                                       int64_t count, float input_scale,
                                       float output_scale) {
  if (!dst || !src || count <= 0 || !(input_scale > 0.f) ||
      !(output_scale > 0.f))
    return;
  double ratio = (double)input_scale / (double)output_scale;
  for (int64_t i = 0; i < count; ++i) {
    int v = round_away((double)src[i] * ratio);
    dst[i] = (int8_t)saturate_i8(v);
  }
}

/* I: 原地 i8 缓冲与元素个数
 * P: MyBoard leaky：x>=0 ? x : (x-5)/10，向零截断。非法输入不写
 * O: 原地写入 buf
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_kernel_leaky_relu_i8_scalar(int8_t *buf, int64_t n) {
  if (!buf || n <= 0)
    return;
  for (int64_t i = 0; i < n; ++i) {
    int32_t x = (int32_t)buf[i];
    if (x < 0)
      x = (x - 5) / 10;
    buf[i] = (int8_t)x;
  }
}

/* I: dst/src NHWC i8，h/w 为 VALID 输入空间尺寸；禁止 dst==src
 * P: 2x2 stride-2 VALID maxpool。奇数尾边丢弃；非法尺寸或别名不写
 * O: 写入 dst，空间为 (h/2, w/2)
 * A: shiroha_suki
 * T: 2026-08-29
 */
void gemcc_kernel_maxpool_valid_s2_i8_scalar(int8_t *dst, const int8_t *src,
                                             int64_t n, int64_t h, int64_t w,
                                             int64_t c) {
  if (!dst || !src || dst == src || n <= 0 || h < 2 || w < 2 || c <= 0)
    return;
  const int64_t out_h = h / 2;
  const int64_t out_w = w / 2;
  const int64_t in_stride = w * c;
  const int64_t in_plane = h * w * c;
  const int64_t out_plane = out_h * out_w * c;
  for (int64_t ni = 0; ni < n; ++ni) {
    const int8_t *in = src + ni * in_plane;
    int8_t *out = dst + ni * out_plane;
    for (int64_t oh = 0; oh < out_h; ++oh) {
      const int8_t *row0 = in + (2 * oh) * in_stride;
      const int8_t *row1 = row0 + in_stride;
      int8_t *dst_row = out + oh * out_w * c;
      for (int64_t ow = 0; ow < out_w; ++ow) {
        const int8_t *p00 = row0 + (2 * ow) * c;
        const int8_t *p01 = p00 + c;
        const int8_t *p10 = row1 + (2 * ow) * c;
        const int8_t *p11 = p10 + c;
        int8_t *d = dst_row + ow * c;
        for (int64_t ch = 0; ch < c; ++ch)
          d[ch] = max2_i8(max2_i8(p00[ch], p01[ch]), max2_i8(p10[ch], p11[ch]));
      }
    }
  }
}
