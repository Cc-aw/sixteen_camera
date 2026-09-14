# YOLOv5nu 640x480 算子与数据流

本文档记录当前 `yolov5nu.pt -> 640x480 -> Stage 8F` 版本的完整算子、执行顺序、
输入输出格式和执行单元。模型对应目录为：

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/
```

精确的节点名称、属性、逻辑 shape、量化 scale 和 initializer 以以下 manifest 为准：

```text
yolov5nu-hw-aware-shared-scale-img640x480.graph.json
```

## 1. 总体格式

### 1.1 模型输入

原始图片经过：

```text
JPEG/BGR
  -> RGB
  -> Ultralytics letterbox 到 640x480，padding value=114
  -> float32 / 255.0
  -> NCHW
  -> signed int8 quantize
```

输入 tensor：

```text
逻辑 shape : [N,C,H,W] = [1,3,480,640]
逻辑 dtype : float32（量化前）/ int8（量化后）
量化       : per-tensor signed int8
zero_point : 0
scale      : 0.007874015718698502
```

ONNX 的 `Conv` 仍按标准 NCHW 语义解释输入。AOT generator 在加载后将输入和
中间 feature map 变为 NHWC 常驻物理布局：

```text
[N,C,H,W] logical int8
  -> [N,H,W,C] physical int8
```

NHWC 的线性地址顺序是 `((n * H + y) * W + x) * C + c`，因此同一个像素位置的
通道数据连续存放，适合当前 Gemmini 的卷积 tile 和 RVV element-wise kernel。

### 1.2 模型输出

ONNX 逻辑输出：

```text
shape : [1,84,6300]
dtype : signed int8
含义  : 4 个 DFL bbox distance + 80 个 class score
```

三个检测头按空间分辨率从大到小排列：

| Head | stride | 空间尺寸 | locations | box channels | class channels |
|---|---:|---:|---:|---:|---:|
| P3 | 8 | 60x80 | 4800 | 64 = 4x16 | 80 |
| P4 | 16 | 30x40 | 1200 | 64 = 4x16 | 80 |
| P5 | 32 | 15x20 | 300 | 64 = 4x16 | 80 |
| 合计 | - | - | 6300 | 64 | 80 |

检测头在裸机中使用 location-major 中间格式：

```text
class logits : [6300,80] 逻辑含义，最终存储/打印为 [80,6300]
box logits   : [6300,4,16]
DFL output   : [4,6300]
```

`index` 的顺序是：

```text
0..4799   : P3，先 y 后 x，x 范围 0..79，stride=8
4800..5999: P4，先 y 后 x，x 范围 0..39，stride=16
6000..6299: P5，先 y 后 x，x 范围 0..19，stride=32
```

## 2. 算子总表

这是 manifest 中的计算节点统计。Q/DQ 节点是量化图基础设施，不是额外的模型
神经网络层；裸机 generator 会把它们降低为 int8 buffer、scale 和 Gemmini 参数。

| 算子 | 数量 | 逻辑作用 | 当前裸机实现 |
|---|---:|---|---|
| Conv | 76 | 主干、neck、检测头卷积 | Gemmini int8 x int8 -> int32 accumulator |
| Sigmoid | 70 | 69 个 SiLU 内部 sigmoid，1 个检测头 class sigmoid | 69 个融合进动态 SiLU LUT；class 用 int8 LUT |
| Mul | 72 | 69 个 SiLU `x*sigmoid(x)`，其余模型乘法 | 69 个融合 SiLU LUT；非融合项按生成器路径执行 |
| Add | 10 | 7 个残差 Add，3 个检测框几何 Add | 7 个 shared-scale Gemmini resadd；几何 Add 在 decode 中执行 |
| Concat | 17 | CSP/neck 特征拼接和检测头拼接 | 13 个 feature Concat 被 Stage 8 split-K 消除；检测头按 head lowering 处理 |
| MaxPool | 3 | SPPF 的三个串联池化 | RVV NHWC kernel |
| Resize | 2 | neck 上采样 | RVV NHWC nearest-neighbor kernel |
| Reshape | 8 | 检测头展平、DFL 重排 | 安全 view 或受控重排 |
| Transpose | 1 | DFL 维度变换 | head lowering 中按 location-major 处理 |
| Softmax | 1 | DFL 每边 16-bin 概率 | int8 exp LUT、float32 sum/reciprocal、int8 概率 |
| Shape/Gather | 各1 | 动态输出 shape 和 decode 辅助 | AOT 中使用固定 640x480 geometry |
| Slice | 2 | DFL bbox 左右/上下分割 | decode lowering |
| Sub | 2 | bbox 边界运算 | decode lowering |
| Div | 2 | stride/中心相关运算 | decode lowering |
| Q/DQ | Q=265,DQ=416 | 量化边界 | 离线 scale + 裸机 int8 lowering |

注意：manifest 的 17 个 `Concat` 包含 13 个 feature Concat 和 4 个检测头/最终
输出 Concat。`Concat` 节点数量不等于实际会执行的内存复制数量。

## 3. 主干网络执行顺序

下表按网络阶段列出计算顺序。每个 Conv 的输出都经过新的 Conv output scale
重新量化；除检测头末端外，Conv 后的激活是 fused SiLU。

### 3.1 Stem 与 P3 主干

| 顺序 | 节点/模块 | 主要算子序列 | 输出逻辑 shape |
|---:|---|---|---|
| 1 | `/model.0` | Conv 6x6,s2 -> SiLU | `[1,16,240,320]` |
| 2 | `/model.1` | Conv 3x3,s2 -> SiLU | `[1,32,120,160]` |
| 3 | `/model.2/cv1` | Conv 1x1 -> SiLU | `[1,16,120,160]` |
| 4 | `/model.2/cv2` | Conv 1x1 -> SiLU | `[1,16,120,160]` |
| 5 | `/model.2/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,16,120,160]` |
| 6 | `/model.2/m/m.0/Add` | 两个 16-channel 分支相加 | `[1,16,120,160]` |
| 7 | `/model.2/Concat` | residual 分支与 bypass 拼接，逻辑 32 channels | `[1,32,120,160]` |
| 8 | `/model.2/cv3` | Conv 1x1 -> SiLU | `[1,32,120,160]` |
| 9 | `/model.3` | Conv 3x3,s2 -> SiLU | `[1,64,60,80]` |

在 Stage 8F AOT 中，`/model.2/Concat` 不单独形成完整输出 buffer；其两个 slice
直接作为 `/model.2/cv3/conv/Conv` 的两个 K-partial 输入。

### 3.2 P3/P4 中间主干

| 顺序 | 节点/模块 | 主要算子序列 | 输出逻辑 shape |
|---:|---|---|---|
| 10 | `/model.4/cv1` | Conv 1x1 -> SiLU | `[1,32,60,80]` |
| 11 | `/model.4/cv2` | Conv 1x1 -> SiLU | `[1,32,60,80]` |
| 12 | `/model.4/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,32,60,80]` |
| 13 | `/model.4/m/m.0/Add` | residual Add | `[1,32,60,80]` |
| 14 | `/model.4/m/m.1` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,32,60,80]` |
| 15 | `/model.4/m/m.1/Add` | residual Add | `[1,32,60,80]` |
| 16 | `/model.4/Concat` | 两个 32-channel slice 拼为 64 channels | `[1,64,60,80]` |
| 17 | `/model.4/cv3` | Conv 1x1 -> SiLU | `[1,64,60,80]` |
| 18 | `/model.5` | Conv 3x3,s2 -> SiLU | `[1,128,30,40]` |

`/model.4/Concat -> /model.4/cv3/conv/Conv` 是 Stage 8 split-K consumer edge。

### 3.3 P4/P5 主干

| 顺序 | 节点/模块 | 主要算子序列 | 输出逻辑 shape |
|---:|---|---|---|
| 19 | `/model.6/cv1` | Conv 1x1 -> SiLU | `[1,64,30,40]` |
| 20 | `/model.6/cv2` | Conv 1x1 -> SiLU | `[1,64,30,40]` |
| 21 | `/model.6/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,64,30,40]` |
| 22 | `/model.6/m/m.0/Add` | residual Add | `[1,64,30,40]` |
| 23 | `/model.6/m/m.1` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,64,30,40]` |
| 24 | `/model.6/m/m.1/Add` | residual Add | `[1,64,30,40]` |
| 25 | `/model.6/m/m.2` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,64,30,40]` |
| 26 | `/model.6/m/m.2/Add` | residual Add | `[1,64,30,40]` |
| 27 | `/model.6/Concat` | 64+64 channels | `[1,128,30,40]` |
| 28 | `/model.6/cv3` | Conv 1x1 -> SiLU | `[1,128,30,40]` |
| 29 | `/model.7` | Conv 3x3,s2 -> SiLU | `[1,256,15,20]` |
| 30 | `/model.8/cv1` | Conv 1x1 -> SiLU | `[1,128,15,20]` |
| 31 | `/model.8/cv2` | Conv 1x1 -> SiLU | `[1,128,15,20]` |
| 32 | `/model.8/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,128,15,20]` |
| 33 | `/model.8/m/m.0/Add` | residual Add | `[1,128,15,20]` |
| 34 | `/model.8/Concat` | 128+128 channels | `[1,256,15,20]` |
| 35 | `/model.8/cv3` | Conv 1x1 -> SiLU | `[1,256,15,20]` |

### 3.4 SPPF

| 顺序 | 节点/模块 | 主要算子序列 | 输出逻辑 shape |
|---:|---|---|---|
| 36 | `/model.9/cv1` | Conv 1x1 -> SiLU | `[1,128,15,20]` |
| 37 | `/model.9/m` | MaxPool 5x5,s1,p2 | `[1,128,15,20]` |
| 38 | `/model.9/m_1` | MaxPool 5x5,s1,p2 | `[1,128,15,20]` |
| 39 | `/model.9/m_2` | MaxPool 5x5,s1,p2 | `[1,128,15,20]` |
| 40 | `/model.9/Concat` | 原始输入 + 3 个池化结果，共 512 channels | `[1,512,15,20]` |
| 41 | `/model.9/cv2` | Conv 1x1 -> SiLU | `[1,256,15,20]` |

SPPF 的四路 Concat 使用 multi-slice split-K helper，仍保留每个 consumer 的
accumulator 累加语义。

## 4. Neck 执行顺序

### 4.1 P5 到 P4

| 顺序 | 节点/模块 | 主要算子序列 | 输出逻辑 shape |
|---:|---|---|---|
| 42 | `/model.10` | Conv 1x1 -> SiLU | `[1,128,15,20]` |
| 43 | `/model.11` | Resize x2，nearest | `[1,128,30,40]` |
| 44 | `/model.12/Concat` | 上采样 P5 与 P4 lateral 拼接 | `[1,256,30,40]` |
| 45 | `/model.13/cv1` | Conv 1x1 -> SiLU | `[1,64,30,40]` |
| 46 | `/model.13/cv2` | Conv 1x1 -> SiLU | `[1,64,30,40]` |
| 47 | `/model.13/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,64,30,40]` |
| 48 | `/model.13/Concat` | 两个 64-channel slice 拼接 | `[1,128,30,40]` |
| 49 | `/model.13/cv3` | Conv 1x1 -> SiLU | `[1,128,30,40]` |
| 50 | `/model.14` | Conv 1x1 -> SiLU | `[1,64,30,40]` |

`/model.12/Concat` 有两个消费者 `/model.13/cv1` 和 `/model.13/cv2`。Stage 8F
使用双消费者输入 slice Scratchpad reuse，使同一输入 slice 在两个 Conv 中复用。

### 4.2 P4 到 P3

| 顺序 | 节点/模块 | 主要算子序列 | 输出逻辑 shape |
|---:|---|---|---|
| 51 | `/model.15` | Resize x2，nearest | `[1,64,60,80]` |
| 52 | `/model.16/Concat` | 上采样 P4 与 P3 lateral 拼接 | `[1,128,60,80]` |
| 53 | `/model.17/cv1` | Conv 1x1 -> SiLU | `[1,32,60,80]` |
| 54 | `/model.17/cv2` | Conv 1x1 -> SiLU | `[1,32,60,80]` |
| 55 | `/model.17/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,32,60,80]` |
| 56 | `/model.17/Concat` | 两个 32-channel slice 拼接 | `[1,64,60,80]` |
| 57 | `/model.17/cv3` | Conv 1x1 -> SiLU | `[1,64,60,80]` |
| 58 | `/model.18` | Conv 3x3,s2 -> SiLU | `[1,64,30,40]` |

`/model.16/Concat` 和 `/model.17/Concat` 均属于双消费者/后续 Conv 融合候选，
对应两个 1x1 consumer 的 K-slice 输入。

### 4.3 P4/P5 回流分支

| 顺序 | 节点/模块 | 主要算子序列 | 输出逻辑 shape |
|---:|---|---|---|
| 59 | `/model.19/Concat` | `/model.18` 与 `/model.14` 拼接 | `[1,128,30,40]` |
| 60 | `/model.20/cv1` | Conv 1x1 -> SiLU | `[1,64,30,40]` |
| 61 | `/model.20/cv2` | Conv 1x1 -> SiLU | `[1,64,30,40]` |
| 62 | `/model.20/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,64,30,40]` |
| 63 | `/model.20/Concat` | 两个 64-channel slice 拼接 | `[1,128,30,40]` |
| 64 | `/model.20/cv3` | Conv 1x1 -> SiLU | `[1,128,30,40]` |
| 65 | `/model.21` | Conv 3x3,s2 -> SiLU | `[1,128,15,20]` |
| 66 | `/model.22/Concat` | `/model.21` 与 `/model.10` 拼接 | `[1,256,15,20]` |
| 67 | `/model.23/cv1` | Conv 1x1 -> SiLU | `[1,128,15,20]` |
| 68 | `/model.23/cv2` | Conv 1x1 -> SiLU | `[1,128,15,20]` |
| 69 | `/model.23/m/m.0` | Conv 1x1 -> SiLU -> Conv 3x3 -> SiLU | `[1,128,15,20]` |
| 70 | `/model.23/Concat` | 两个 128-channel slice 拼接 | `[1,256,15,20]` |
| 71 | `/model.23/cv3` | Conv 1x1 -> SiLU | `[1,256,15,20]` |

`/model.19/Concat`、`/model.22/Concat` 也有双消费者，Stage 8F 对对应输入
slice 做 Scratchpad reuse。至此，主干和 neck 产生 P3/P4/P5 三个检测特征图。

## 5. 检测头执行顺序与格式

三个检测头都从相应 P-level feature 出发，分别计算 box 分支和 class 分支。
在每个分支中，Conv 输出先经过 fused SiLU；检测头末端的 1x1 Conv 输出不再使用
SiLU，而是产生 logits。

### 5.1 P3 head

输入：`[1,60,80,64]` NHWC physical，逻辑为 `[1,64,60,80]`。

```text
box branch:
  3x3 Conv -> SiLU -> 3x3 Conv -> SiLU -> 1x1 Conv
  [1,64,60,80] -> [1,64,60,80]

class branch:
  3x3 Conv -> SiLU -> 3x3 Conv -> SiLU -> 1x1 Conv
  [1,64,60,80] -> [1,80,60,80]

reshape:
  box   [1,64,60,80] -> [1,64,4800] -> [4800,4,16]
  class [1,80,60,80] -> [1,80,4800] -> [4800,80]
```

### 5.2 P4 head

输入：`[1,30,40,128]` NHWC physical，逻辑为 `[1,128,30,40]`。

```text
box branch:
  3x3 Conv -> SiLU -> 3x3 Conv -> SiLU -> 1x1 Conv
  [1,128,30,40] -> [1,64,30,40]

class branch:
  3x3 Conv -> SiLU -> 3x3 Conv -> SiLU -> 1x1 Conv
  [1,128,30,40] -> [1,80,30,40]

reshape:
  box   [1,64,30,40] -> [1,64,1200] -> [1200,4,16]
  class [1,80,30,40] -> [1,80,1200] -> [1200,80]
```

### 5.3 P5 head

输入：`[1,15,20,256]` NHWC physical，逻辑为 `[1,256,15,20]`。

```text
box branch:
  3x3 Conv -> SiLU -> 3x3 Conv -> SiLU -> 1x1 Conv
  [1,256,15,20] -> [1,64,15,20]

class branch:
  3x3 Conv -> SiLU -> 3x3 Conv -> SiLU -> 1x1 Conv
  [1,256,15,20] -> [1,80,15,20]

reshape:
  box   [1,64,15,20] -> [1,64,300] -> [300,4,16]
  class [1,80,15,20] -> [1,80,300] -> [300,80]
```

### 5.4 三头合并

三个 head 按 P3、P4、P5 顺序合并：

```text
box:
  [1,64,4800] + [1,64,1200] + [1,64,300]
  -> [1,64,6300]

class:
  [1,80,4800] + [1,80,1200] + [1,80,300]
  -> [1,80,6300]
```

对应 manifest 节点为：

```text
/model.24/Concat
/model.24/Concat_1
```

在 AOT 的 detection-only 模式中，class logits 会保留为 `[80,6300]`，DFL 只对
候选位置计算，不额外物化所有位置的完整 DFL 输出。

## 6. DFL、class、decode 与 NMS

### 6.1 HEAD_CLASS

输入：`class logits [80,6300] int8`。

每个位置执行：

```text
80 class logits
  -> 对每个位置做 class max reduction
  -> RVV candidate selection
  -> signed int8 sigmoid LUT
  -> 保存 class score 和 best class
```

当前 Stage 8F 使用：

- class logits：位置数 `6300`，每位置 80 个 int8 值；
- sigmoid：共享 256-entry int8 LUT；
- candidate selection：RVV class-max 路径；
- sparse mask：保留 score 达到阈值的位置，并强制保留 Top-10；
- 输出：class score `[80,6300]`，同时建立共享 decoded-candidate 索引。

### 6.2 HEAD_DFL

输入：`box logits [64,6300]`，每个位置拆成 4 条边、每边 16 个 bin。

硬件感知整数路径为：

```text
每个候选位置
  -> 4 条 edge，各取 16 个 int8 logits
  -> 每条 edge 减去 16 项最大值
  -> exp difference LUT
  -> float32 累加 16 项
  -> 一次 reciprocal
  -> 16 项 int8 probability
  -> int32 dot(probability, DFL weight)
  -> Gemmini/模型 scale requant 到 int8 distance
```

输出：

```text
DFL distances [4,6300] int8 逻辑格式
```

Stage 8F 的 detection-only lowering 只对 sparse candidate 位置执行 DFL，因而 UART
中显示的实际 DFL 数量通常是：

```text
10 candidates -> 40 elements
21 candidates -> 84 elements
```

### 6.3 Decode

Decode 对每个候选位置将 DFL distance 转为 bbox：

```text
grid_x = index % head_width
grid_y = index / head_width

left/top/right/bottom = DFL distance * stride
center_x = (grid_x + 0.5 + (right-left)/2) * stride
center_y = (grid_y + 0.5 + (bottom-top)/2) * stride
width    = (left+right) * stride
height   = (top+bottom) * stride
```

Decode 输出一个 `Detection`：

```text
score, class_id, class_name, index, cx, cy, w, h
```

Stage 6 以后，Top-10 和 NMS 共用同一份 `decoded_candidates`，避免重复解码。

### 6.4 NMS

当前是 CPU class-aware greedy NMS：

```text
1. 从候选中筛选 score >= 0.25
2. 选择当前最高分框
3. 只对相同 class 计算 IoU
4. IoU > 0.45 的框标记 suppressed
5. 重复直到输出 10 个或候选耗尽
```

NMS 不改变 class logits、DFL 或 decode 的数值，只决定最终显示的框。

## 7. Gemmini、RVV 与 CPU 分工

### 7.1 Gemmini

Gemmini 实际承担：

```text
76 个 Conv
7 个 feature-map shared-scale residual Add
Concat -> Conv 的 17 条 split-K consumer edge
4 组双消费者 Concat 输入 slice Scratchpad reuse
69 个 Conv fused SiLU 的动态 LUT 配置和查表 store
```

Conv 的数值流程是：

```text
int8 activation x int8 weight
  -> int32 accumulator
  -> bias int32
  -> requant = input_scale * weight_scale / output_scale
  -> RNE + int8 saturation
  -> 可选 fused SiLU LUT
  -> mvout
```

对于 split-K Conv，同一输出 tile 的多个输入 slice 依次累加到同一 accumulator，
最后一个 partial 才执行 requant、SiLU 和 mvout。`gemmini_fence()` 保证 Gemmini
写入完成后 CPU/RVV 才读取数据。

### 7.2 RVV

RVV 主要承担：

```text
NHWC copy/requant 辅助
NHWC MaxPool
NHWC nearest Resize
HEAD_CLASS 的 80-class max/candidate selection
部分 detection-head 的向量化 requant/LUT 路径
```

当前板上配置为 DSP Saturn：VLEN=256、DLEN=128、`VectorParams.dspParams`。Spike
使用的 VLEN 可能不同，因此 Spike 适合做功能检查，不能直接代表 FPGA cycle。

### 7.3 CPU 标量部分

CPU 仍承担或参与：

```text
DFL 中 16-bin 的标量累加/交错累加部分
Decode
NMS
部分 scale、边界和控制逻辑
```

当前 profile 中，`cpu_operator_cycles` 是多个 CPU/RVV 阶段的汇总，不应与
`HEAD_CLASS`、`HEAD_DFL` 再重复相加；后两者已经包含在 graph 子统计中。

## 8. Stage 8F 的实际 AOT 数据流

逻辑图看起来包含完整 Concat，但裸机实际调度如下：

```text
NCHW logical int8 input
  -> NHWC resident feature map
  -> Gemmini Conv
  -> Gemmini fused SiLU LUT
  -> Gemmini shared-scale Add
  -> split-K 输入 slice 直接进入后续 Conv accumulator
  -> 双消费者 slice 在 Scratchpad 中复用
  -> gemmini_fence()
  -> RVV MaxPool/Resize/Head-Class
  -> sparse HEAD_DFL
  -> shared Decode candidates
  -> CPU NMS
```

Stage 8F 固定 contract：

```text
Conv                         : 76
fused SiLU                   : 69
shared-scale Gemmini Add     : 7
split-K Concat-Conv edges    : 17
dual-consumer SPAD reuse     : 4 groups
materialized target Concat   : 0
arena                        : 2,217,600 bytes
```

“materialized target Concat=0”只适用于 Stage 8 选定的 feature Concat。检测头的
逻辑合并仍由 head lowering 处理，不能据此认为整个 ONNX 图的所有 Concat 节点都
被删除。

## 9. 端到端 profile 参考

来自五张 640x480 图片的板级平均值，50 MHz：

| 阶段 | 平均 cycles | 端到端占比 |
|---|---:|---:|
| Conv total | 13,754,837 | 80.34% |
| Gemmini Conv | 13,739,758 | 80.26% |
| CPU/RVV operator 汇总 | 2,950,620 | 17.24% |
| HEAD_CLASS | 1,842,070 | 10.76% |
| HEAD_DFL | 147,714 | 0.86% |
| fused SiLU LUT | 170,102 | 0.99% |
| shared Add | 239,805 | 1.40% |
| MaxPool | 350,059 | 2.04% |
| Resize | 200,858 | 1.17% |
| Decode | 324,764 | 1.90% |
| NMS | 78,439 | 0.46% |
| Graph | 16,716,657 | 97.64% |
| End-to-end | 17,119,860 | 100% |

640x480 相比 320x320 有 3 倍像素和 3 倍检测位置。实测端到端约为 2.80 倍，
与当前 tile、固定控制开销和不同边界填充共同作用的结果一致。

## 10. 代码与复现入口

模型、manifest 和 reference：

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/
```

AOT 生成器：

```text
generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py
scripts/yolov5nu_stage8f_spad_reuse.py
```

量化、解析和验证：

```text
scripts/yolov5nu_stage8_hardware_aware.py
scripts/yolov5nu_graph_parser.py
scripts/yolov5nu_validate_stage4_heads.py
```

对应的五图 AOT 文件在：

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/aot/
```

五图板级 UART 日志在：

```text
fpga/xcvu13p/tests/yolov5nu_stage8/uart/640x480-image025.txt
fpga/xcvu13p/tests/yolov5nu_stage8/uart/640x480-image036.txt
fpga/xcvu13p/tests/yolov5nu_stage8/uart/640x480-image142.txt
fpga/xcvu13p/tests/yolov5nu_stage8/uart/640x480-image404.txt
fpga/xcvu13p/tests/yolov5nu_stage8/uart/640x480-image650.txt
```

本文件描述的是当前 640x480 Stage 8F 软件/AOT 数据流。若后续进入 Stage 9 做
Conv tile 调优，必须从该数据流和硬件感知量化模型重新建立候选，不应把逻辑 ONNX
shape、NHWC physical layout 或检测头 location order 隐式改变。
