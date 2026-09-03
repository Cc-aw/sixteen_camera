// Gemmini Library ABI shim for MLIR: i64 addresses, then official
// tiled_* / tiled_*_auto from gemmini.h.  Device init owns the initial flush;
// each wrapper marks the synchronous CPU/Gemmini ownership boundary so the
// selected coherence backend can evict the Rocket L1 when required.
//
// Compile with: riscv64-unknown-linux-gnu-gcc -I<lib_dir> [-include params]

#include "gemmini_params.h"
#include "gemmini.h"
#include "gemcc_ownership.h"
#include "gemcc_trace.h"

#include <stddef.h>
#include <stdint.h>

typedef unsigned long long u64;

/* Standalone forward harnesses do not provide the board UART trace hook.
 * Keep a weak no-op implementation so the same wrappers remain reusable. */
static uint32_t gemcc_trace_sequence;

__attribute__((weak)) void gemcc_trace_reset(void) {
  gemcc_trace_sequence = 0U;
}

__attribute__((weak)) uint32_t gemcc_trace_begin(uint32_t kind, uint32_t x0,
                                                  uint32_t x1, uint32_t x2,
                                                  uint32_t x3, uint32_t x4,
                                                  uint32_t x5) {
  (void)kind;
  (void)x0;
  (void)x1;
  (void)x2;
  (void)x3;
  (void)x4;
  (void)x5;
  return gemcc_trace_sequence++;
}

__attribute__((weak)) void gemcc_trace_phase(uint32_t op, uint32_t phase) {
  (void)op;
  (void)phase;
}

/* I: MLIR i64 尺寸/步长/指针，语义同 gemmini.h tiled_matmul_auto
 * P: 转成 elem_t* 后直接调 tiled_matmul_auto。不做 page-in / flush / 驱逐。
 * O: 写入 C；无返回值
 * A: shiroha_suki, shiroha_suki
 * T: 2026-08-28, 2026-08-29
 */
void gemmini_tiled_matmul_auto(
    u64 dim_I, u64 dim_J, u64 dim_K,
    u64 A_ptr, u64 B_ptr, u64 D_ptr, u64 C_ptr,
    u64 stride_A, u64 stride_B, u64 stride_D, u64 stride_C,
    float A_scale, float B_scale, float D_scale,
    u64 act, float acc_scale, float bert_scale,
    u64 repeating_bias, u64 transpose_A, u64 transpose_B,
    u64 full_C, u64 low_D, u64 weightA, u64 dataflow_t)
{
  uint32_t trace_op = gemcc_trace_begin(
      GEMCC_TRACE_KIND_MATMUL, (uint32_t)dim_I, (uint32_t)dim_J,
      (uint32_t)dim_K, 0U, 0U, 0U);
  gemcc_cpu_to_gemmini();
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_LAUNCH);
  tiled_matmul_auto(
      (size_t)dim_I, (size_t)dim_J, (size_t)dim_K,
      (const elem_t *)(uintptr_t)A_ptr,
      (const elem_t *)(uintptr_t)B_ptr,
      (const void *)(uintptr_t)D_ptr,
      (void *)(uintptr_t)C_ptr,
      (size_t)stride_A, (size_t)stride_B,
      (size_t)stride_D, (size_t)stride_C,
      (scale_t)A_scale, (scale_t)B_scale, (scale_acc_t)D_scale,
      (int)act, (acc_scale_t)acc_scale, (acc_scale_t)bert_scale,
      (bool)repeating_bias, (bool)transpose_A, (bool)transpose_B,
      (bool)full_C, (bool)low_D,
      (uint8_t)weightA,
      (enum tiled_matmul_type_t)dataflow_t);
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_GEMMINI_DONE);
  gemcc_gemmini_to_cpu();
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_DONE);
}

/* I: MLIR i64 卷积参数与缓冲指针，语义同 gemmini.h tiled_conv_auto
 * P: 转指针后直接调 tiled_conv_auto（Chipyard 同一入口）
 * O: 写入 out；无返回值
 * A: shiroha_suki, shiroha_suki
 * T: 2026-08-28, 2026-08-29
 */
void gemmini_tiled_conv_auto(
    u64 batch,   u64 in_h,   u64 in_w,   u64 in_c,
    u64 out_c,   u64 out_h,  u64 out_w,
    u64 stride,  u64 in_dilation, u64 k_dilation,
    u64 pad,     u64 k_dim,
    u64 wrot180, u64 trans_o, u64 trans_i,
    u64 trans_w1,u64 trans_w2,
    u64 in_ptr,  u64 wt_ptr, u64 bias_ptr, u64 out_ptr,
    u64 act,     float scale,
    u64 pool_sz, u64 pool_str, u64 pool_pad, u64 dataflow_t)
{
  uint32_t trace_op = gemcc_trace_begin(
      GEMCC_TRACE_KIND_CONV, (uint32_t)in_h, (uint32_t)in_w,
      (uint32_t)in_c, (uint32_t)out_h, (uint32_t)out_w, (uint32_t)out_c);
  gemcc_cpu_to_gemmini();
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_LAUNCH);
  tiled_conv_auto(
      (int)batch, (int)in_h, (int)in_w, (int)in_c,
      (int)out_c, (int)out_h, (int)out_w,
      (int)stride, (int)in_dilation, (int)k_dilation,
      (int)pad, (int)k_dim,
      (bool)wrot180, (bool)trans_o, (bool)trans_i,
      (bool)trans_w1, (bool)trans_w2,
      (const elem_t *)(uintptr_t)in_ptr,
      (const elem_t *)(uintptr_t)wt_ptr,
      (const acc_t *)(uintptr_t)bias_ptr,
      (elem_t *)(uintptr_t)out_ptr,
      (int)act, (acc_scale_t)scale,
      (int)pool_sz, (int)pool_str, (int)pool_pad,
      (enum tiled_matmul_type_t)dataflow_t);
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_GEMMINI_DONE);
  gemcc_gemmini_to_cpu();
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_DONE);
}

/* I: 同 tiled_conv_auto，另加 porows/pocols/pochs/kchs 固定分块
 * P: 转指针后调官方 tiled_conv（非 auto）。pool_sz==0 按 gemmini.h 收成 no_pool。
 * O: 写入 out；无返回值
 * A: shiroha_suki
 * T: 2026-08-28
 */
void gemmini_tiled_conv(
    u64 batch,   u64 in_h,   u64 in_w,   u64 in_c,
    u64 out_c,   u64 out_h,  u64 out_w,
    u64 stride,  u64 in_dilation, u64 k_dilation,
    u64 pad,     u64 k_dim,
    u64 wrot180, u64 trans_o, u64 trans_i,
    u64 trans_w1,u64 trans_w2,
    u64 in_ptr,  u64 wt_ptr, u64 bias_ptr, u64 out_ptr,
    u64 act,     float scale,
    u64 pool_sz, u64 pool_str, u64 pool_pad, u64 dataflow_t,
    u64 porows,  u64 pocols,  u64 pochs,  u64 kchs)
{
  uint32_t trace_op = gemcc_trace_begin(
      GEMCC_TRACE_KIND_CONV, (uint32_t)in_h, (uint32_t)in_w,
      (uint32_t)in_c, (uint32_t)out_h, (uint32_t)out_w, (uint32_t)out_c);
  gemcc_cpu_to_gemmini();
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_LAUNCH);
  int pool_size = (int)pool_sz;
  int pool_stride = (int)pool_str;
  int pool_padding = (int)pool_pad;
  int no_pool = (pool_size == 0);
  if (no_pool) {
    pool_size = 1;
    pool_stride = 1;
    pool_padding = 0;
  }
  int pool_out_row =
      ((int)out_h + 2 * pool_padding - pool_size) / pool_stride + 1;
  int pool_out_col =
      ((int)out_w + 2 * pool_padding - pool_size) / pool_stride + 1;
  int batches = (int)batch;
  int orows = porows > 0 ? (int)porows : pool_out_row;
  int ocols = pocols > 0 ? (int)pocols : pool_out_col;
  int ochs = pochs > 0 ? (int)pochs : (int)out_c;
  int krows = (int)k_dim;
  int kcols = (int)k_dim;
  int kch = kchs > 0 ? (int)kchs : (int)in_c;
  tiled_conv(
      (int)batch, (int)in_h, (int)in_w, (int)in_c,
      (int)out_c, (int)out_h, (int)out_w,
      (int)stride, (int)in_dilation, (int)k_dilation,
      (int)pad, (int)k_dim,
      (int)in_c, (int)out_c, (int)out_c,
      (bool)wrot180, (bool)trans_o, (bool)trans_i,
      (bool)trans_w1, (bool)trans_w2,
      batches, orows, ocols, ochs, krows, kcols, kch,
      (const elem_t *)(uintptr_t)in_ptr,
      (const elem_t *)(uintptr_t)wt_ptr,
      (const acc_t *)(uintptr_t)bias_ptr,
      (elem_t *)(uintptr_t)out_ptr,
      (int)act, (acc_scale_t)scale,
      pool_size, no_pool ? 0 : pool_stride, pool_padding,
      (enum tiled_matmul_type_t)dataflow_t);
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_GEMMINI_DONE);
  gemcc_gemmini_to_cpu();
  gemcc_trace_phase(trace_op, GEMCC_TRACE_PHASE_DONE);
}
