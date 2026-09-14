# YOLOv5nu Stage 4 复盘

## 定位

Stage 4 基于 Stage 3，专门优化检测头和 DFL 的数据布局，核心是 `location-major` lowering。

## Stage 4 location-major

三个 box head 从 NHWC `[H][W][64]` 直接组织为：

```text
[2100][4][16]
```

三个 class head 直接组织为：

```text
[2100][80]
```

这样每个 location 的 16 个 DFL bin 和 80 个类别连续存储。

删除或绕开：

- 6 个检测头 NHWC-to-NCL Reshape
- 2 个检测头 logical Concat
- DFL Reshape/Transpose
- generic Softmax
- DFL projection Conv bridge
- 最终 head Reshape

新增：

```c
stage4_class_heads_i8()
stage4_dfl_heads_i8()
```

profile records 从 `413` 降至 `398`，Conv 调用数从 76 降至 75。

## 数学语义

- class：保留原 class Sigmoid LUT 和 requant。
- DFL：保留原 256-entry exp LUT、16-bin Softmax、量化 scale 和 projection 语义。
- Decode/NMS：只改变物理索引，bbox 公式、阈值和 UART 格式不变。

## 涉及文件

- `generate_yolov5nu_baremetal.py`
- `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`
- `scripts/yolov5nu_validate_stage4_heads.py`
- `scripts/yolov5nu_stage4_heads.py`
- `scripts/yolov5nu_validate_nhwc_layout.py`
- `scripts/yolov5nu_validate_silu_fusion.py`

归档：`fpga/xcvu13p/tests/yolov5nu_stage4_heads/`。

## Stage 4 验证和性能

五图各双跑，全部 `398` records、`PASS`、zero exit、重复确定，并与 Stage 3 bit-exact。

```text
Stage 3 graph：100.302M cycles
Stage 4 graph： 71.299M cycles
graph 加速：   1.4068x

Stage 3 端到端：2.0580 s
Stage 4 端到端：1.4915 s
Stage 4 FPS：   0.6705
```

检测头从约 `42.985M` 降至 `13.946M cycles`，加速约 `3.082x`。

## Stage 4.1

Stage 4.1 在 location-major 基础上继续优化：

1. 缓存每条边的 16 个 exp 结果，并使用一次 reciprocal。
2. 预计算 7 个 Add 的 `a_scale/dst_scale` 和 `b_scale/dst_scale`，删除 `vfdiv.vf`。
3. 2100 个 candidate 只生成一次，Top-10 和 NMS 共享。
4. 使用 RVV `vredmax.vs + vfirst.m` 完成 80-class max，并保持 first-tie 语义。

涉及文件：

- `include/yolov5nu_stage4_rvv.h`
- `bareMetalC/yolov5nu_stage41_rvv_smoke.c`
- `scripts/yolov5nu_stage41_opt.py`
- `scripts/xcvu13p_build_yolov5nu_stage41_rvv_smoke.sh`

Stage 4.1 验证了 `7 x 256 x 256 = 458,752` 组 Add 输入，Spike/Verilator 和 FPGA 均 bit-exact。

性能：

```text
Stage 4 graph：  71.299M cycles
Stage 4.1 graph：62.395M cycles
Stage 4.1 端到端：1.2573 s
Stage 4.1 吞吐率：0.7954 FPS
```

Stage 4.1 随后作为 Stage 5 内存规划的历史基线。
