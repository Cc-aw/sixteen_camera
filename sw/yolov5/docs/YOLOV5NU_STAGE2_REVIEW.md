# YOLOv5nu Stage 2 复盘

## 定位

Stage 2 基于 Stage 1 的 NHWC 常驻布局，优化 YOLOv5nu 中大量独立的 `Sigmoid + Mul` SiLU 计算。

原始路径：

```text
x -> quantized Sigmoid -> int8
x 与 Sigmoid(x) -> Mul -> int8
```

Stage 2 路径：

```text
x -> 单次 fused INT8 LUT
```

这是软件 scalar LUT 版本，不是后续 Gemmini 动态 LUT RTL 版本。

## Pattern matching

只融合满足以下条件的安全模式：

- Sigmoid 输出只有一个 Mul 消费者；
- Mul 的两个输入正好是原始输入和 Sigmoid 输出；
- 输入、Sigmoid 输出和 Mul 输出均为 signed int8；
- zero point 均为 0；
- shape 和物理布局一致。

固定图识别出：

```text
安全 SiLU pattern：69
每组 LUT：          256 项
总映射：            17,664 项
LUT 大小：          约 18 KiB
剩余 Sigmoid：      1 个最终分类 Sigmoid
剩余 Mul：          0 个
```

## LUT 数学语义

每张 LUT 都模拟原来的两步量化，而不是使用新的浮点近似：

```text
input int8
 -> input_scale 下的 sigmoid
 -> sigmoid_scale 量化
 -> 与原输入实值相乘
 -> mul/output_scale 量化
 -> fused int8 output
```

因此 69 张 LUT 分别对应各层的 input、Sigmoid 和 output scale。

## 涉及文件

- `generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`
- `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`
- `scripts/yolov5nu_validate_silu_fusion.py`
- `scripts/yolov5nu_stage2_silu_lut.py`

归档：`fpga/xcvu13p/tests/yolov5nu_stage2_silu_lut/`。

由于 69 个 Sigmoid 中间 tensor 不再需要，image025 的 BSS 从 `14,612,660` bytes 降至 `11,051,060` bytes。

## 验证和性能

五图共完成 11 次 FPGA 运行，全部为 `413` records、`PASS`、zero exit，输出与 Stage 1 bit-exact。

```text
Stage 1 graph：356,624,734 cycles
Stage 2 graph：162,747,682 cycles
graph 加速：  2.1913x

Stage 1 端到端：7,191.218 ms
Stage 2 端到端：3,313.721 ms
端到端加速：  2.1701x
吞吐率：      0.3018 FPS
```

SiLU 相关 cycles 从约 `230.61M` 降至约 `37.90M`，节省约 `192.71M cycles`。

## 候选比较

| 实现 | cycles/element | 结论 |
|---|---:|---|
| scalar fused INT8 LUT | 10.6405 | 保留为 Stage 2 baseline |
| RVV indexed LUT e8,m1 | 11.4872 | 不晋级 |
| RVV indexed LUT e8,m2 | 11.3106 | 不晋级 |
| OpenCV RVV FP32 two-step | 111.363 | 不晋级 |

RVV indexed gather 在当时 Saturn 上的开销高于 scalar LUT；OpenCV FP32 路径增加了反量化、exp、除法和再量化，且直接 FP32 Swish 会破坏原始中间量化语义。

## 结论

Stage 2 关闭了独立 SiLU Mul 热点，后续 Stage 3 转向 NHWC Concat、Add、MaxPool 和 Resize 的 RVV 化。Gemmini 动态 SiLU LUT 属于 Stage 5D 之后的独立硬件扩展。

