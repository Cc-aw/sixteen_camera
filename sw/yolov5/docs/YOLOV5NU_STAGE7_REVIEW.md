# YOLOv5nu Stage 7 复盘

## 定位

Stage 7 基于 Stage 6 H4A，优化 7 个 Add 和 13 个 feature-map Concat。所有候选都不修改 ONNX 量化模型、检测头语义、RTL 或 bitstream。

开始时：

```text
Concat：1,371,325 cycles
Add：    773,895 cycles
Graph： 约 8.856M cycles
FPS：   5.561
```

## 7A：Concat producer-direct write

将满足单消费者、生命周期、scale、stride 和 offset 条件的 producer 直接写入 Concat channel slice。主要处理 MaxPool/Resize producer：

```text
direct_concat：9 -> 11
```

五图平均 Graph 为 `8,842,678 cycles`，相对 H4A 改善约 `0.144%`，保持 bit-exact。

## 7B：Add 与 Concat 融合

尝试把 3 条 Add 直接写入 Concat slice。原始 7B 删除了 Add output scale 的第一次 RNE/int8 量化，只按 Concat scale 量化，因此：

- 性能提高；
- checksum、DFL、Top-10、bbox 和 NMS 变化；
- 判定为非 bit-exact，拒绝部署。

## 7B-exact

恢复两阶段量化：

```text
Add output scale RNE/int8
    -> Concat output scale requant
```

使用 `yolov5nu_rvv_add_two_step_i8()`，对 `3 x 256 x 256 = 196,608` 组输入验证零差异。

五图平均：

```text
Concat：640,617 cycles
Add：1,114,874 cycles
Graph：8,465,384 cycles
End-to-end：8,600,632 cycles
FPS：5.814
```

## 7B-LUT 和 7B-LUT-register

7B-LUT 将第二次 requant 改为 3 张 256-entry LUT，但 `vluxei8.v` indexed gather 在 Saturn 上很慢，Graph 退化到 `10.422M cycles`。

7B-LUT-register 将 LUT 一次加载到 `e8,m8` 寄存器，使用 `vrgather.vv`：

```text
Add：996,076 cycles
Graph：8,357,832 cycles
End-to-end：8,492,431 cycles
FPS：5.888
```

该版本 bit-exact，优于 indexed LUT。

## 7C：专用 NHWC Concat RVV kernel

针对 16/32/64/128 channel slice 专门化：

- 同 scale：RVV copy；
- 不同 scale：RVV widening/requant；
- 固定 VL 和地址步进，减少短向量循环开销。

独立 smoke `5,760/5,760` 通过。五图平均：

```text
Concat：904,281 cycles
Add：773,555 cycles
Graph：8,405,701 cycles
End-to-end：8,540,184 cycles
FPS：5.855
```

Concat 相对 H4A 减少约 `34.06%`。

## 7BC 组合

组合：

- 7B-register Add-Concat 融合；
- 7A producer-direct write；
- 7C 剩余 Concat 专用 kernel。

结果：

```text
Add：996,241 cycles
Concat：493,204 cycles
Graph：8,199,625 cycles
End-to-end：8,333,712 cycles
FPS：5.999
```

## 7D：Gemmini resadd 评估

Gemmini resadd 本身约快 5.31x，但 Gemmini 的 mvin/mvout scale 会引入与 RVV 不同的 RNE 边界。真实模型出现 checksum、bbox、候选数和 NMS 变化。

结果：

```text
Add：139,504 cycles
Graph：8,238,543 cycles
End-to-end：8,375,343 cycles
FPS：5.970
```

7D 是非 bit-exact 性能候选，不进入部署 baseline。

## 7E：整数定点 Add

使用编译期搜索得到的 Q22 multiplier/shift，RVV 执行：

```asm
vmul.vx
vadd.vv
vnclip.wi
```

设置 `vxrm=RNE`，替代 FP32 scale/div 路径，同时保持 RNE 和 int8 saturation。

验证：

```text
普通 Add：458,752/458,752
两步 Add register-LUT：49,152/49,152
```

五图全部双跑 bit-exact，平均：

```text
Add：748,018 cycles
Concat：492,900 cycles
Graph：7,954,706 cycles
End-to-end：8,089,036 cycles
FPS：6.181
```

## 结论

Stage 7 冻结 `7E` 为最终 bit-exact baseline，包含：

```text
7A producer-direct write
7B-register Add-Concat
7C 专用 NHWC Concat RVV
7E 整数定点 Add
```

Stage 8 以 7E 作为回退基线。

