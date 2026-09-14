# YOLOv5nu Stage 6 复盘

## 定位

Stage 6 基于 Stage 5D + Gemmini 动态 SiLU LUT + 8 条 SiLU direct-Concat，专门优化 `HEAD_CLASS`、`HEAD_DFL` 和 candidate selection。

开始时 image025：

```text
Graph：       20,788,719 cycles
HEAD_DFL：    10,633,108 cycles
HEAD_CLASS：   1,935,505 cycles
End-to-end：  21,245,991 cycles
```

Stage 6 全部复用已有 bitstream，不修改 RTL。

## H0：检测头分阶段计时

新增：

- `head_class_requant_cycles`
- `head_class_sigmoid_cycles`
- `head_dfl_requant_cycles`
- `head_dfl_core_cycles`

确认 DFL core 是主要热点，随后进入 H2。

## H1：HEAD_CLASS 寄存器驻留 LUT

DSP Saturn 的 VLEN=256，在 `e8,m8` 下可以将 256-entry LUT 一次装入 `v8-v15`，再使用：

```asm
vrgather.vv
```

完成 class Sigmoid 查表。VLEN 不足时回退 scalar LUT。

H1 将：

```text
HEAD_CLASS：1,935,505 -> 410,351 cycles
```

约加速 `4.717x`，Graph 降至 `19,082,196 cycles`，FPS 从 `2.353` 提升至 `2.558`。

## H2：DFL 连续 16-bin RVV 化

保留：

- scalar exp LUT
- 原顺序 FP32 sum
- 每边一次 reciprocal
- 原有最终 requant

RVV 化：

- `vredmax.vs`：16-bin max
- `vfcvt.x.f.v`：RNE probability quantization
- `vwmul.vv`：INT32 weighted product
- `vredsum.vs`：weighted dot

性能：

```text
HEAD_DFL：10.4388M -> 3.9153M cycles
DFL core：10.3558M -> 3.8323M cycles
Graph：   19.0822M -> 12.5535M cycles
FPS：     2.558 -> 3.841
```

H2 成为 full-output 软件基线。

## H3：reduction 候选

测试了以下方案：

- H3A：四条 edge batch，复用权重和 vsetvli；
- H3B：`vfredosum.vs` ordered reduction；
- H3C：`vluxei32.v` exp LUT gather；
- H3D：四 lane element-wise `vfadd.vv`；
- H3E：`vfredusum.vs` unordered reduction；
- H3F：H3A + H3C；
- H3G：bin 外层 + 四个独立标量 FP32 累加器交错发射。

关键结果：

| 版本 | DFL core | Graph | End-to-end FPS |
|---|---:|---:|---:|
| H2 | 3,832,295 | 12,553,471 | 3.841 |
| H3A | 3,499,019 | 12,218,575 | 3.943 |
| H3B | 4,611,160 | 13,320,308 | 3.629 |
| H3C | 3,710,371 | 12,429,902 | 3.879 |
| H3F | 3,526,439 | 12,247,746 | 3.935 |
| H3G | **2,616,713** | **11,337,653** | **4.238** |

H3B 证明 ordered reduction 在 Saturn 上仍有严重串行开销。H3E 允许最多 2 ULP 的中间 FP32 差异，但最终 int8 DFL、Top-10 和 NMS 未变，性能仍不如 H3G。

H3G 保持每条 edge 的加法顺序，同时用四条独立累加链隐藏 FPU latency，成为 full-output 最佳软件 baseline。

## H4：稀疏 DFL

H4 先完整计算 class，再构造候选集合：

```text
{score >= NMS threshold} union {global Top-10}
```

只对候选位置执行 4 条边的 DFL，保留 Top-10 和 NMS 所需位置。

H4 五图平均：

```text
candidate count：14
DFL core：39,268 cycles
HEAD_DFL：1,521,607 cycles
Graph：10,150,876 cycles
End-to-end：10,285,364 cycles
FPS：4.861
```

H4 是 detection-only 模式，不提供完整 `84x2100` DFL tensor。

## H4A：RVV class max 融合

H4A 在完整 class Sigmoid 后立即用 RVV `vredmax.vs` 生成 candidate mask，保持 first-tie 语义。

候选选择从约 `1,463,205` 降至 `176,667 cycles`，约加速 `8.28x`。

最终 H4A 五图平均：

```text
HEAD_CLASS：587,078 cycles
HEAD_DFL：   57,907 cycles
Graph：    8,855,691 cycles
End-to-end：8,990,851 cycles
FPS：          5.561
```

## 结论

Stage 6 形成两个用途不同的基线：

- H3G：full-output，保留完整 class/DFL 输出；
- H4A：detection-only，采用稀疏 DFL，适合部署。

Stage 6 结束后热点转向 Concat、Add 和 Gemmini Conv，进入 Stage 7。

