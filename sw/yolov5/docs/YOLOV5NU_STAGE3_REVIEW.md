# YOLOv5nu Stage 3 复盘

## 定位

Stage 3 基于 Stage 2 的 NHWC + fused scalar SiLU LUT，首次将四类 NHWC feature-map 算子改为 RVV kernel：

```text
Concat/requant copy
Add
SPPF MaxPool
Resize
```

模型、量化参数、SiLU LUT、DFL、Decode 和 NMS 均不变。

## 实现

公共 kernel 位于：

`generators/gemmini/software/gemmini-rocc-tests/include/yolov5nu_stage3_rvv.h`

主要函数：

- `yolov5nu_rvv_copy_i8()`
- `yolov5nu_rvv_requant_i8()`
- `yolov5nu_rvv_concat_slice_i8()`
- `yolov5nu_rvv_add_i8()`
- `yolov5nu_rvv_maxpool_nhwc_i8()`
- `yolov5nu_rvv_resize_nearest_nhwc_i8()`

### Concat

连续 channel block 使用 `vle8.v/vse8.v`。scale 相同时只 copy；scale 不同时使用 RVV widening、FP32 ratio、RNE 和 int8 saturation。

### Add

使用 int8 -> int16 -> int32 -> FP32 的 widening 路径，执行两路 scale、add、除以目标 scale、RNE 和饱和窄化。

### MaxPool

沿 NHWC 连续 channel 维执行 `vmax.vv`。每个输出向量从第一个有效输入像素初始化，避免全负窗口被错误的 zero padding 污染。

### Resize

标量计算 nearest-neighbor 源坐标，RVV 只负责连续 channel block copy，保留 ONNX 坐标公式。

## 涉及文件

- `include/yolov5nu_stage3_rvv.h`
- `generate_yolov5nu_baremetal.py`
- `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`
- `scripts/yolov5nu_stage3_rvv.py`
- `bareMetalC/yolov5nu_stage3_rvv_smoke.c`
- `scripts/xcvu13p_build_yolov5nu_stage3_rvv_smoke.sh`

归档：`fpga/xcvu13p/tests/yolov5nu_stage3_rvv/`。

## 验证

Spike、`LargeGemminiRocketRVVConfig` Verilator smoke 和 FPGA 均通过。反汇编确认包含 `vsext.vf2`、FP32 vector conversion、`vnclip.wi`、`vmax.vv` 和 `e8,m8` 设置。五图共 11 次 FPGA 运行，均为 `413` records、`PASS`、zero exit 和 bit-exact。

## 性能

五图平均：

```text
Stage 2 graph：162,747,682 cycles
Stage 3 graph：100,301,612 cycles
节省：        62,446,070 cycles
graph 加速：  1.6226x

Stage 2 端到端：3,313.721 ms
Stage 3 端到端：2,058.024 ms
端到端加速：  1.6101x
吞吐率：      0.4859 FPS
```

| 算子 | Stage 2 | Stage 3 | 加速 |
|---|---:|---:|---:|
| Concat/copy | 36.66M | 3.71M | 9.89x |
| Add | 16.88M | 10.33M | 1.63x |
| SPPF MaxPool | 16.97M | 0.158M | 约 107.6x |
| Resize | 7.26M | 0.074M | 约 97.7x |

## 结论

Stage 3 证明了 NHWC 连续访问适合 RVV，并将检测头、DFL、Decode/NMS 留给后续 Stage 4。

