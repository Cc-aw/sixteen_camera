#define CV_ENABLE_INTRINSICS 1
#define CV_CPU_COMPILE_RVV 1
#define CV_RVV 1

#include <riscv_vector.h>
#include <opencv2/core/hal/intrin.hpp>

#include "include/yolov5nu_silu_opencv_rvv.h"

extern "C" void opencv_rvv_silu_two_step_i8(const int8_t *src, int8_t *dst,
    size_t count, float input_scale, float sigmoid_scale, float output_scale)
{
    size_t offset = 0;
    while (offset < count)
    {
        size_t vl = __riscv_vsetvl_e8mf2(count - offset);
        vint8mf2_t x8 = __riscv_vle8_v_i8mf2(src + offset, vl);
        vint16m1_t x16 = __riscv_vsext_vf2_i16m1(x8, vl);
        vint32m2_t x32 = __riscv_vsext_vf2_i32m2(x16, vl);
        vfloat32m2_t real = __riscv_vfcvt_f_x_v_f32m2(x32, vl);
        real = __riscv_vfmul_vf_f32m2(real, input_scale, vl);

        vfloat32m2_t neg = __riscv_vfneg_v_f32m2(real, vl);
        vfloat32m2_t exponential = cv::v_exp(neg);
        vfloat32m2_t denominator =
            __riscv_vfadd_vf_f32m2(exponential, 1.0f, vl);
        vfloat32m2_t sigmoid =
            __riscv_vfrdiv_vf_f32m2(denominator, 1.0f, vl);

        vfloat32m2_t sigmoid_scaled =
            __riscv_vfdiv_vf_f32m2(sigmoid, sigmoid_scale, vl);
        vint32m2_t sigmoid_q =
            __riscv_vfcvt_x_f_v_i32m2(sigmoid_scaled, vl);
        sigmoid_q = __riscv_vmax_vx_i32m2(sigmoid_q, -128, vl);
        sigmoid_q = __riscv_vmin_vx_i32m2(sigmoid_q, 127, vl);
        vfloat32m2_t sigmoid_q_f =
            __riscv_vfcvt_f_x_v_f32m2(sigmoid_q, vl);

        vfloat32m2_t output =
            __riscv_vfmul_vv_f32m2(real, sigmoid_q_f, vl);
        output = __riscv_vfmul_vf_f32m2(
            output, sigmoid_scale / output_scale, vl);
        vint32m2_t output_q = __riscv_vfcvt_x_f_v_i32m2(output, vl);
        vint16m1_t output16 =
            __riscv_vnclip_wx_i16m1(output_q, 0, __RISCV_VXRM_RNU, vl);
        vint8mf2_t output8 =
            __riscv_vnclip_wx_i8mf2(output16, 0, __RISCV_VXRM_RNU, vl);
        __riscv_vse8_v_i8mf2(dst + offset, output8, vl);
        offset += vl;
    }
}
