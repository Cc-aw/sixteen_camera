# YOLOv5nu NHWC/RVV Optimization Plan

本文档记录 YOLOv5nu 320x320 INT8 baremetal 版本从 Stage 0 到 Stage 8 的完整
优化历程、代码入口、验证结果和后续边界。ONNX 始终保留标准 NCHW 逻辑语义，
AOT generator 将裸机执行计划降低为 NHWC 常驻物理布局；这样既复用
TinyYOLOv2 的验证经验，也避免修改标准 ONNX Conv 语义。

## 0. 文档状态（2026-09-03）

当前阶段已经结束 Stage 8，冻结版本为：

```text
Stage 8F dual-consumer Scratchpad reuse
```

它是当前 YOLOv5nu 上板任务的最终 bit-exact baseline。Stage 8F 已完成：

- Stage 8 hardware-aware integer model 的五图 FPGA 双跑；
- 7 个 feature-map Add 的 Gemmini shared-scale resadd；
- 17 条 Concat -> 1x1 Conv split-K consumer edge；
- 4 组双消费者 Concat 的 A-side Scratchpad slice reuse；
- class logits、sigmoid、sparse DFL、Top-10、bbox 和 NMS 对照；
- Spike 五图仿真、FPGA 五图双跑、zero exit 和确定性检查。

当前硬件配置为 `LargeGemminiRocketDspRVVSiluLUTXCVU13PConfig`（定义于
`fpga/src/main/scala/xcvu13p/Configs.scala`）：Gemmini 大配置
配合 Saturn DSP RVV（VLEN=256、DLEN=128、`VectorParams.dspParams`）。Stage 8
没有修改 RTL/Scala、Vivado 工程或 bitstream；Stage 8 的变化集中在硬件感知量化
模型、AOT generator 和裸机执行调度。

各阶段独立复盘文档：

- `docs/YOLOV5NU_STAGE0_REVIEW.md`
- `docs/YOLOV5NU_STAGE1_REVIEW.md`
- `docs/YOLOV5NU_STAGE2_REVIEW.md`
- `docs/YOLOV5NU_STAGE3_REVIEW.md`
- `docs/YOLOV5NU_STAGE4_REVIEW.md`
- `docs/YOLOV5NU_STAGE5_REVIEW.md`
- `docs/YOLOV5NU_STAGE6_REVIEW.md`
- `docs/YOLOV5NU_STAGE7_REVIEW.md`
- `docs/YOLOV5NU_STAGE8_REVIEW.md`

Stage 8F 的固定五图是 `025/036/142/404/650`，对应结果为：

```text
image025: class=-6457179 sigmoid=884  DFL=845  top=giraffe
image036: class=-6349811 sigmoid=2202 DFL=2090 top=umbrella
image142: class=-6121235 sigmoid=2339 DFL=2128 top=cup
image404: class=-6505866 sigmoid=905  DFL=801  top=boat
image650: class=-6358397 sigmoid=1110 DFL=809  top=cat
```

Stage 8H 随后验证了 `/model.9` 的 split-K config/fence 合并，功能上 bit-exact，
但端到端没有收益，因此不替代 Stage 8F。Stage 8G 的 Add accumulator ->
`mvout_spad` 链路因量化舍入边界和有限收益放弃。

短时间内不进入 Stage 9 Conv tile 调优。Stage 9 的文档计划保留，但当前工作
停留在 Stage 8F baseline；任何新的 Conv 调优都必须从该版本重新建立独立候选，
不能覆盖 Stage 8F 产物。

### 0.1 从头到 Stage 8 的结果总览

| 阶段 | 核心工作 | 最终结论 |
|---|---|---|
| Stage 0 | NCHW bridge、五图 profile、ORT/FPGA 对照 | 关闭，作为历史 correctness baseline |
| Stage 1 | NHWC 常驻 feature map | 关闭 Conv layout 转换热点 |
| Stage 2 | 融合 69 组 SiLU 为动态 INT8 LUT | 关闭，scalar Gemmini LUT 为稳定路径 |
| Stage 3 | NHWC Concat/Add/MaxPool/Resize 的 RVV kernel | 关闭，全部 bit-exact |
| Stage 4 | location-major HEAD_CLASS/HEAD_DFL、decode/NMS 共享 candidates | 关闭 |
| Stage 5 | arena 生命周期、死 tensor、原地覆盖、direct-Concat | 关闭，5D 为内存基线 |
| Stage 6 | H0-H4A，RVV DFL/class-max 和 sparse DFL | H4A 为历史 detection-only baseline |
| Stage 7 | Concat/Add 的 direct write、LUT-register、整数定点 Add | 7E 为上一阶段 bit-exact baseline |
| Stage 8A-B | 共享 Add scale、Gemmini shared resadd | 形成硬件感知量化模型 |
| Stage 8C-E | Concat 融合后续 Conv、split-K、全消费者扩展 | 形成 Stage 8 全消费者路径 |
| Stage 8F | 双消费者输入 slice Scratchpad reuse | 冻结为当前最终 bit-exact baseline |
| Stage 8G | Add 到后续 Conv 的 `mvout_spad` | 放弃 |
| Stage 8H | split-K config/fence 合并 | bit-exact 候选，不晋升 |

本文档后续章节中出现的“当前基线”若属于更早阶段，均按对应小节的历史时间点
解释；当前部署基线以本节和 Stage 8F 小节为准。

## 1. 当前基线

### 1.1 模型与量化约束

- 原始 Gemmini ONNX：`generators/gemmini/software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.onnx`
- 当前 Stage 8F ONNX：`generators/gemmini/software/gemmini-ort/models/detection/stage8_hardware_aware/yolov5nu-hw-aware-shared-scale-int8-img320.onnx`
- 当前 Stage 8F manifest：`generators/gemmini/software/gemmini-ort/models/detection/stage8_hardware_aware/yolov5nu-hw-aware-shared-scale.graph.json`
- 输入：`[1, 3, 320, 320]`，逻辑布局 NCHW
- 检测输出：`[1, 84, 2100]`
- Conv 数量：76
- activation：per-tensor symmetric signed INT8，zero point 0
- weight：per-tensor symmetric signed INT8，zero point 0
- bias：INT32，scale 为 `input_scale * weight_scale`
- 编译 ISA：RV64GCV

导出、解析、生成和构建入口：

- 导出脚本：`generators/gemmini/software/gemmini-ort/models/detection/export_yolov5nu_gemmini_int8.py`
- graph parser：`scripts/yolov5nu_graph_parser.py`
- baremetal generator：`generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`
- 构建脚本：`scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`
- reference 检查：`scripts/yolov5nu_validate_baremetal_reference.py`
- 当前流程说明：`docs/YOLOV5NU_GEMMINI_BAREMETAL_FLOW.md`

### 1.2 当前执行方式

当前板级执行方式是 Stage 8F、hardware-aware shared-scale model、DSP Saturn、
Gemmini 动态 SiLU LUT 和 Stage 5D arena。ONNX 保持 NCHW 逻辑语义，裸机 feature
tensor 常驻 NHWC：

```text
NCHW logical ONNX
  -> AOT离线NHWC lowering
  -> 76个 Gemmini Conv
  -> 69个 Conv 融合动态 SiLU LUT
  -> 7个 Gemmini shared-scale Add
  -> 17条 Concat-Conv split-K consumer edge
  -> 4组双消费者 A-side Scratchpad reuse
  -> gemmini_fence()
  -> RVV/CPU detection head、decode 和 NMS
```

`gemmini_fence()` 是正确性要求，CPU 读取 Gemmini 输出前不能删除。后续优化的
目标不是跳过同步。

当前其他算子状态：

- Conv：76 个 Gemmini Conv，Conv layout 转换为 0 cycles；
- SiLU：69 组 Sigmoid+Mul 融合为 Gemmini 动态 256-entry LUT；
- Add：7 个 Gemmini shared-scale resadd，保持 hardware-aware 量化语义；
- Concat：目标 feature Concat 不再物化，后续 Conv 使用 split-K slice；
- MaxPool：3 个 RVV NHWC kernel；
- Resize：2 个 RVV NHWC nearest-neighbor kernel；
- Reshape/Transpose：由安全 view、受控布局转换和 location-major head lowering 处理；
- HEAD_CLASS：RVV requant、RVV LUT/sparse candidate selection 和共享 candidates；
- HEAD_DFL：RVV requant、16-bin softmax/投影和 H3G 交错标量累加；
- Decode：共享 candidates 的 CPU/RVV bbox decode；
- NMS：CPU class-aware greedy NMS。

### 1.3 50 MHz 性能基线

以下 Stage 5D 数据是历史热点分析基线，不代表当前版本：

`fpga/xcvu13p/tests/yolov5nu_stage5/uart/yolov5nu-stage5d-hwsilu-v1-image025_direct_concat.txt`。
image025 连续两次均值：

```text
graph cycles        20,788,719      415.774 ms
decode cycles          413,984        8.280 ms
NMS cycles              43,289        0.866 ms
end-to-end           21,245,991      424.920 ms
throughput                                 2.353 FPS
```

主要算子占比：

| 类别 | cycles | graph 占比 |
|---|---:|---:|
| HEAD_DFL | 10,633,108 | 51.15% |
| Conv total | 5,698,510 | 27.41% |
| HEAD_CLASS | 1,935,505 | 9.31% |
| Concat | 1,371,315 | 6.60% |
| Add | 773,598 | 3.72% |
| SiLU LUT配置 | 180,383 | 0.87% |
| MaxPool | 114,595 | 0.55% |
| Resize | 69,505 | 0.33% |

该表只用于说明 Stage 5D 时的热点：HEAD_DFL、Concat 和 Add 后续分别由 Stage 6、
Stage 7 和 Stage 8 处理。Stage 8 完成后暂不恢复 Stage 9 Conv 调优。

Stage 8F 的 canonical 结果和五图输出记录在：

```text
docs/YOLOV5NU_STAGE8_SUMMARY.md
docs/YOLOV5NU_STAGE8F_SPAD_REUSE.md
fpga/xcvu13p/tests/yolov5nu_stage8/uart/dual-consumer-spad-reuse-image025.txt
```

归档的 Stage 8F 端到端平均值为约 `6.123M cycles`、`8.166 FPS @ 50 MHz`；不同
板级批次的 profile 文件存在运行波动，性能比较必须使用同一 bitstream、同一 ELF
和同一批次的双跑数据，不能把不同归档批次的 cycles 混为一个基线。

### 1.4 Stage 0历史基线

最初NCHW bridge版本记录为`fpga/xcvu13p/tests/result_yolov5nu_cycles.txt`：

```text
graph cycles       429,727,561    8,594.6 ms
decode cycles        1,519,617       30.4 ms
NMS cycles           1,468,682       29.4 ms
end-to-end          432,715,860    8,654.3 ms
throughput                               0.116 FPS
```

该数据只作为完整优化历程的历史对照，不再代表当前执行方式。

## 2. 总体架构

优化后的数据流应为：

```text
standard NCHW ONNX logical graph
  -> graph parser records logical shape and quantization
  -> AOT backend chooses physical layout
  -> image and weights are repacked offline
  -> NHWC-resident baremetal feature tensors
  -> Gemmini NHWC Conv + RVV/CPU NHWC kernels
  -> detection-head-specific layout
  -> existing UART decode/NMS format
```

不要把标准 ONNX 强行导出成“NHWC Conv ONNX”。标准 ONNX Conv 的逻辑语义是
NCHW，强行改变通常会产生额外 Transpose 或自定义算子。布局选择应该属于
baremetal backend lowering。

每个 tensor descriptor 至少记录：

```text
logical_shape
logical_layout
physical_shape
physical_layout
element_type
scale
zero_point
storage/lifetime information
```

四维 feature map 的基础 axis 映射为：

| ONNX logical axis | 含义 | NHWC physical axis |
|---:|---|---:|
| 0 | N | 0 |
| 1 | C | 3 |
| 2 | H | 1 |
| 3 | W | 2 |

Reshape、Transpose 和 DFL 不能只做上述机械映射，必须按算子语义单独 lowering。

## 3. 对照版本和开关

历史实现通过 generator 保留 scalar/RVV、布局、内存和 Stage 7/8 候选开关。当前
Stage 8F baseline 的完整构建参数必须固定保存；新候选只能增加独立 mode，不能
覆盖已冻结产物：

```text
--physical-layout nchw-bridge | nhwc
--silu-mode       separate     | fused-lut
--kernel-mode     scalar       | rvv
--head-lowering   generic | location-major
--head-output-mode full | detection-only
--head-kernel     baseline | optimized-rvv-...
--memory-stage    none | 5a | 5b | 5c | 5d
--stage7-mode     none | 7a | 7b | 7b-register | 7c | 7d | 7bc | 7e
--stage8-mode     none | 8a... | 8c... | 8f-dual-consumer-spad-reuse | 8h...
```

构建脚本对应提供环境变量，避免手工编辑生成的 C 文件：

```text
YOLOV5NU_PHYSICAL_LAYOUT
YOLOV5NU_SILU_MODE
YOLOV5NU_KERNEL_MODE
YOLOV5NU_MEMORY_STAGE
YOLOV5NU_STAGE7_MODE
YOLOV5NU_STAGE8_MODE
YOLOV5NU_STAGE8_ADD_NAME
```

建议保留以下候选版本：

```text
yolov5nu-baseline
yolov5nu-nhwc
yolov5nu-nhwc-silulut
yolov5nu-nhwc-silulut-rvv
yolov5nu-nhwc-silulut-rvv-memory-stage
```

版本名描述实际启用的优化。不能让 `baseline` 名称随开发进度改变。

## 4. Stage 0：冻结基线与自动比较

Stage 0 的固定五图编排和归档入口：

- `scripts/yolov5nu_stage0_baseline.py`
- `fpga/xcvu13p/tests/yolov5nu_stage0/README.md`

固定图片为 25、142、36、404 和 650。脚本负责批量构建 profile ELF、生成
ONNX Runtime final-tensor/detection reference、执行五图 Conv contract 检查，并
在取得板上 UART 日志后检查双次运行确定性和 482 条 profile records。

截至 2026-08-21，Stage 0 已关闭。五个 profile ELF、构建哈希清单、五图 ORT
reference、五图 76-Conv contract 检查和每图两次 FPGA UART 运行均已完成。
所有 Conv 检查通过，最大误差为 1 LSB；十次板上运行均包含 482 条 profile
records、`PASS` 和 zero exit。同图双跑的 final tensors、top-10 和 NMS 完全一致。
归档报告为 `fpga/xcvu13p/tests/yolov5nu_stage0/uart_validation.json`。

五图平均 graph cycles 为 429,906,990；平均端到端计算约 8.66 秒，约 0.1155
FPS。同图双跑 graph cycles 波动为 0.0011% 至 0.0039%。Stage 1 NHWC
layout-only 版本以这份 FPGA 输出作为 bit-exact 比较目标。

### 4.1 工作内容

1. 固定当前 profile ELF 的构建参数和测试图片。
2. 保存 image 25、image 142 以及另外三张不同类别图片的输出。
3. 保存 final class tensor、DFL tensor 的 checksum/min/max。
4. 保留无 NMS top-10 和 class-aware NMS 输出。
5. 确认 profile 每次从空记录开始，完整输出 482 条 record。

### 4.2 涉及文件

- `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`
- `generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`
- `scripts/yolov5nu_validate_baremetal_reference.py`
- `fpga/xcvu13p/tests/result_yolov5nu_cycles.txt`

### 4.3 通过条件

- 同一 ELF 连续运行两次 tensor stats 和 detections 一致。
- FPGA 双次运行的 final tensors 必须一致；与量化 ONNX Runtime 的差异单独记录。
- 当前允许已知的逐算子 1 LSB 舍入差异，但 NHWC layout-only 版本必须对 FPGA
  baseline bit-exact。
- UART `printf` 不计入 graph/decode/NMS cycles。

## 5. Stage 1：NHWC 常驻计算图

本阶段只改变物理布局，不改变算子的数学实现。这样可以把 layout 问题与后续
SiLU/RVV 问题分开定位。

实现入口和状态：

- `scripts/yolov5nu_stage1_nhwc.py`
- `scripts/yolov5nu_validate_nhwc_layout.py`
- `fpga/xcvu13p/tests/yolov5nu_stage1_nhwc/README.md`

截至 2026-08-21，Stage 1 已完成五图 FPGA 验证，可作为 NHWC layout baseline。
静态合约和板上结果均通过：75 个普通 Conv 直接使用 NHWC，1 个 DFL Conv 保留
bridge，检测头存在 6 次 NHWC-to-NCL 边界，13 个 feature Concat 使用 NHWC
channel concat。每图双跑共十次，均有 482 records、`PASS` 和 zero exit；final
tensors、top-10、NMS 与 Stage 0 FPGA baseline bit-exact。

五图平均 graph 从 429,906,990 降至 356,624,734 cycles，减少 73,282,255
cycles，graph 加速 1.2055x。平均端到端从 8,656.866 ms 降至 7,191.218 ms，
加速 1.2038x，吞吐率从约 0.1155 提升到 0.1391 FPS。

Conv layout 从 95,507,749 降至 1,124,484 cycles，减少 94,383,265 cycles。
六次检测头 NHWC-to-NCL 重排使 Reshape 增加约 17,723,851 cycles；NHWC 标量
MaxPool/Concat 也分别增加约 1.92M/1.35M cycles，Resize 减少约 2.63M cycles。
这些结果说明常驻 NHWC 方向正确，同时给 Stage 3/4 留出了明确目标。

### 5.1 Parser 和 manifest

修改 `scripts/yolov5nu_graph_parser.py`：

1. 保留 ONNX logical shape/axis。
2. 为 feature tensor 推导 NHWC physical shape。
3. 记录每个算子的 logical-to-physical axis mapping。
4. 对不支持 NHWC lowering 的节点立即报错，不能静默回退为错误布局。
5. manifest 中明确记录 layout，便于检查生成代码。

### 5.2 Generator

修改
`generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`：

1. 输入图片在生成 params 时直接保存为 `[H][W][C]`。
2. Conv 权重继续离线从 OIHW 转为 `[KH * KW * IC][OC]`。
3. 所有 Conv 输入、输出直接使用 NHWC tensor buffer。
4. 删除每层 `nchw_to_nhwc()` 和 `nhwc_to_nchw()` 调用。
5. 保留 `gemmini_fence()`。
6. Add、Mul、Sigmoid 第一版使用相同标量算法，只改 NHWC 地址解释。
7. Concat 的 channel axis 从 logical axis 1 映射到 physical axis 3。
8. MaxPool 和 Resize 先提供 bit-exact NHWC 标量实现。

### 5.3 检测头布局

主干 feature map 使用 NHWC。检测头内部建议逐步降低为：

```text
class logits/scores: [2100][80]
DFL logits:          [2100][4][16]
DFL distances:       [2100][4]
```

三个尺度的位置数量不变：

```text
40 x 40 = 1600, stride 8
20 x 20 =  400, stride 16
10 x 10 =  100, stride 32
total       2100
```

第一版可以先在检测头边界做一次受控重排；主干 76 个 Conv 周围的转换必须全部
消失。检测头专用布局在 Stage 4 继续优化。

### 5.4 新增验证建议

建议新增：

- `scripts/yolov5nu_validate_nhwc_reference.py`

它负责把 NCHW reference tensor 转为对应 physical layout，并逐节点比较。比较时
必须先根据 layout descriptor 恢复逻辑索引，不能只比较裸内存 checksum。

### 5.5 通过条件

- 76 个 Conv 的逻辑输出与 baseline 相同。
- layout-only 版本 final tensors bit-exact。
- top detections、NMS detections 与 baseline 相同。
- profile 中 `CONV_IN_LAYOUT` 和 `CONV_OUT_LAYOUT` cycles 降为零或完全删除。
- Gemmini Conv cycles 不出现明显回退。

### 5.6 Stage 1 预期收益（历史目标）

目标消除约 95.5M cycles，graph 从 429.7M 降到约 320M 至 340M cycles。

## 6. Stage 2：融合量化 SiLU LUT（已完成，历史复盘）

截至 2026-08-21，Stage 2 的独立实现、主机验证和 FPGA 五图验证均已完成；以下
内容是该阶段的历史记录，不再代表当前 fused-SiLU baseline。实现入口如下：

- 五图构建与 UART 对照：`scripts/yolov5nu_stage2_silu_lut.py`
- pattern/LUT 验证：`scripts/yolov5nu_validate_silu_fusion.py`
- 归档说明：`fpga/xcvu13p/tests/yolov5nu_stage2_silu_lut/README.md`

固定图中识别出 69 组安全 SiLU pattern。五个 RV64GCV ELF 均已构建成功；每份
生成物均通过 69 x 256 项 exhaustive 检查、Stage 1 NHWC layout contract 检查，
并确认只剩最终分类输出的 1 个 Sigmoid，SiLU 对应的独立 Mul 已全部消失。
每次 profile records 从 Stage 1 的 482 降至 413。五图共完成 11 次 FPGA 运行，
全部 `PASS`、zero exit；重复运行确定，final tensors、top-10 和 NMS 与 Stage 1
FPGA bit-exact。五图平均 graph 从 356,624,734 降至 162,747,682 cycles，减少
193,877,052 cycles，加速 2.1913x；端到端从 7,191.218 ms 降至 3,313.721 ms，
加速 2.1701x，吞吐率达到 0.3018 FPS。

Stage 1 中 SiLU 对应的 Sigmoid+Mul 约为 230.61M cycles，Stage 2 fused LUT 约为
37.90M cycles，单项回收约 192.71M cycles。当前最大项变为 fused SiLU 37.90M、
Concat 36.67M、Reshape 18.13M、MaxPool 16.97M 和 Add 16.88M，因此当时进入了
Stage 3 NHWC RVV kernels；这些热点随后分别在 Stage 3-5 被处理。

YOLOv5nu 中大量 SiLU 被表示为：

```text
x -> Sigmoid(x)
x, Sigmoid(x) -> Mul
```

当前 Sigmoid 已使用逐元素 LUT，但仍会生成中间 tensor，并由 Mul 再次遍历。
计划把符合模式的 Sigmoid+Mul 融合为单次输入到输出的 INT8 LUT。

### 6.1 Pattern matching

在 parser 中识别以下安全模式：

1. Sigmoid 输入和 Mul 的另一输入是同一个 tensor。
2. Sigmoid 输出只被该 Mul 消费。
3. 输入、Sigmoid 输出和 Mul 输出的 scale/zero point 已知。
4. 所有 zero point 为 0。

不满足条件的 Sigmoid/Mul 继续走原路径。

### 6.2 LUT 生成

每个融合节点离线生成 256 项 LUT。LUT 必须模拟当前两步量化路径，而不是直接
使用一个未经验证的浮点近似：

```text
input int8
  -> current quantized Sigmoid result
  -> current quantized Mul/requant result
  -> fused int8 output
```

这样理论上可以做到与当前 Sigmoid+Mul bit-exact。约 69 个 SiLU 节点的 LUT
总量约为 18 KiB。

### 6.3 通过条件

- 每个融合节点对全部 256 个 int8 输入做 exhaustive comparison。
- 所有 SiLU 输出与 separate 模式 bit-exact。
- final tensors 和 detections 不变。
- profile 单独记录 `SILU_FUSED_LUT`，原 SiLU 对应的 Sigmoid/Mul records 消失。

### 6.4 预期收益

当前 Mul 和 Sigmoid 合计约 230M cycles，其中绝大部分来自 SiLU。目标先降到
10M 至 40M cycles；实际结果由 DDR/cache 行为决定，以上板 profile 为准。

### 6.5 Stage 2 结论和后续研究方向

截至 2026-08-22，scalar fused INT8 LUT 仍是正式 Stage 2 实现。已完成的候选
及五图/单图 FPGA 结论如下：

| 实现 | SiLU cycles/element | 相对 scalar LUT | 结论 |
|---|---:|---:|---|
| scalar fused INT8 LUT | 10.6405 | 1.000x | Stage 2 历史 baseline |
| RVV indexed LUT `e8,m1` | 11.4872 | 1.080x | 不晋级 |
| RVV indexed LUT `e8,m2` | 11.3106 | 1.063x | 不晋级 |
| OpenCV RVV FP32 two-step SiLU | 111.363 | 10.468x | 不晋级 |

OpenCV 候选保持了中间 Sigmoid INT8 量化和最终 Mul 量化语义，输出 bit-exact，
但 FP32 `exp` 多项式、`vfdiv`、反量化/量化转换使 graph 由 162.743M 增至
522.797M cycles。直接 FP32 Swish 还会绕过中间量化，17664 个映射中有 1049
项不一致，因此不作为可替换实现。

当前 `LargeGemminiRocketRVVXCVU13PConfig` 使用 `VectorParams()`、VLEN=128、
DLEN=64。普通 `vluxei8.v` 没有接入 Saturn 为 Shuttle+SGTCM 准备的 fast
scatter/gather engine；VLMAX 从 16 增至 32 只带来约 1.54% 的 kernel 改善，
说明 indexed memory 地址生成是主要限制。

Stage 2 暂停继续迭代，但保留以下独立研究方向，不能混入 Stage 4：

1. scalar LUT 4/8 路展开，要求完整模型稳定低于 10.6405 cycles/element。
2. register-resident `vrgather` 分块 LUT，先解决 256-byte 表跨寄存器选择问题。
3. 新建 Rocket+Saturn+SGTCM 配置，把 LUT 放入至少 32 KiB SGTCM，并接入
   8-port fast scatter/gather；先做普通/fast `vluxei8` 微基准。
4. 单独评估 `dspParams + VLEN=256 + DLEN=128`。它有利于连续 RVV 算子和
   segmented FMA，但不会自动修复普通 indexed load，scalar LUT 也不会受益。
5. ncnn/CSI-NN2 FP16 RVV SiLU 仅作为数学实验；必须先通过 69 x 256 误差审计，
   且微基准快于 scalar LUT 才允许生成全模型。
6. TensorFlow Lite/gemmlowp fixed-point logistic 仅保留为低优先级参考。它包含
   定点 exp、条件乘法和 Newton-Raphson，运行工作量明显高于最终 256-entry LUT。
7. 长期硬件方向是在 Gemmini 写回或专用 activation 单元中增加可配置 INT8 LUT。

统一准入条件是：不改变当前量化语义时必须 bit-exact；任何近似实现必须建立
独立 accuracy baseline；性能必须稳定超过 scalar LUT，且收益足以覆盖新增 RTL、
SGTCM、链接布局或模型部署复杂度。

## 7. Stage 3：NHWC RVV kernels（已完成，历史复盘）

RVV 实现必须使用 strip-mining，不假设固定 VLEN。编译继续使用 RV64GCV。

截至 2026-08-21，Stage 3 candidate 已实现：Concat/requant copy、Add、SPPF
MaxPool 和 Resize 均有独立的 scalar/RVV 开关。五图 ELF、NHWC/SiLU 静态验证、
Spike smoke 和 `LargeGemminiRocketRVVConfig` Verilator smoke 均已通过。11 次
FPGA 运行也已通过 bit-exact、确定性和零退出检查。Graph 平均由 Stage 2 的
162.748M 降至 100.302M cycles，速度提升 1.6226x；端到端达到 2.058 s、
0.4859 FPS。实现、详细分算子结果和上板步骤见
`fpga/xcvu13p/tests/yolov5nu_stage3_rvv/README.md`。

优先顺序：

1. Concat/copy
2. Add
3. SPPF MaxPool
4. Resize
5. DFL Softmax/Transpose

### 7.1 Concat

第一步用 RVV 搬运连续 channel block。第二步在 memory planner 中让生产者直接
写入目标 Concat 的 channel offset，取消复制。

### 7.2 Add

实现 RVV widening、scale、rounding、saturation 和 narrowing。输出必须复现当前
标量 requant 规则。之后可与 Gemmini `tiled_resadd_auto()` 单独对照；不能默认
Gemmini 一定更快。

### 7.3 MaxPool

YOLOv5nu 的 SPPF 包含三次独立 `5x5, stride=1, SAME` MaxPool，中间结果都参与
Concat，因此不能简单融合成一次 Gemmini Conv+Pool。

复用 TinyYOLOv2 RVV SAME_UPPER pool 的思路，沿 NHWC 连续 channel 维执行向量
max。边界 padding 必须与 ONNX MaxPool 语义一致。

### 7.4 Resize

保持 ONNX nearest-neighbor 坐标规则。标量计算源像素位置，RVV 负责复制完整
channel block。

### 7.5 代码位置

初期 kernel 可以继续由
`generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`
生成，便于快速验证。稳定后再考虑抽出公共头文件，例如：

```text
generators/gemmini/software/gemmini-rocc-tests/include/yolov5nu_rvv_kernels.h
```

不要在验证前同时移动代码和改变算法。

### 7.6 通过条件

- 每个 RVV kernel 都有 scalar/RVV 两种模式。
- 小尺寸 exhaustive/random unit test 通过。
- Spike 验证 RVV 指令合法；FPGA 验证 cycles 和完整模型结果。
- final tensors 与 scalar NHWC 版本一致。

## 8. Stage 4：DFL 和检测头专用 lowering（已完成，历史复盘）

DFL 输入的 64 个 box channel 表示四条边、每边 16 个 bin：

```text
[1, 64, 2100]
  -> [1, 4, 16, 2100]
  -> Softmax over 16 bins
  -> projection by 0..15
  -> [1, 4, 2100]
```

裸机物理布局改为 `[2100][4][16]` 后，每次 16-bin Softmax 都连续，可以避免
当前大规模 DFL Transpose。分类输出使用 `[2100][80]`，方便每个 location 直接
查找最大类别。

本阶段要求：

- 不构造无必要的 `[1,84,2100]` 临时输出。
- 保持当前 bbox decode 公式和 UART 格式。
- 保持无 NMS top-10 和 class-aware NMS 两套输出。
- Decode/NMS 目前仅约 60 ms，不在主图优化前投入复杂 RVV NMS。

截至 2026-08-22，Stage 4 独立 candidate 已实现并完成主机构建验证。生成器新增
`--head-lowering generic|location-major`；默认 `generic` 保持 Stage 0 至 Stage 3
输出不变。`location-major` 必须建立在 NHWC、fused LUT 和全 RVV Stage 3 上。

当前 lowering 将三个 box head 的 NHWC `[H][W][64]` 直接拼成
`[2100][4][16]`，将三个 class head 的 `[H][W][80]` 直接拼成
`[2100][80]`。连续 requant 复用 Stage 3 RVV kernel；class Sigmoid 保持原 LUT；
DFL 仍使用原 256-entry exp LUT、16-bin Softmax 中间 INT8 量化和原 Conv75 权重
投影，因此没有改变数学或量化语义。decode 只改变物理索引，UART 格式不变。

被替换的 generic 节点包括 6 个检测头 Reshape、2 个检测头 Concat、DFL
Reshape/Transpose/Softmax/Conv/final Reshape 和最终 class Sigmoid。生成程序从 76
个 `tiled_conv_auto()` 降为 75 个，profile records 从 413 降为 398，并新增
`HEAD_CLASS`、`HEAD_DFL` 两项。五张固定图片已由 ONNX Runtime 中间 tensor
逐元素验证：class logits、class sigmoid、box logits、DFL softmax 和最终
distances 全部 bit-exact。五份 UART ELF 和 build manifest 位于
`fpga/xcvu13p/tests/yolov5nu_stage4_heads/`。

FPGA 验证已于 2026-08-22 完成：五图各运行两次，十次运行全部 398 records、
`PASS`、zero exit，重复运行确定，final tensors、Top-10 和 NMS 与 Stage 3
bit-exact。五图平均 graph 由 100.301M 降至 71.299M cycles，加速 1.4068x；
端到端由 2.0580s 降至 1.4915s，加速 1.3798x，吞吐率由 0.4859 提升至
0.6705 FPS。旧 generic head 平均 42.984M cycles，新 `HEAD_CLASS+HEAD_DFL`
平均 13.946M，head path 加速 3.082x。因此 Stage 4 在当时晋级为 performance
baseline。decode/NMS 因物理访问模式变化合计增加约 0.676M cycles，留作后续
独立 RVV reduction 优化，不回滚本阶段。

### 8.1 Stage 4.1 进一步计算优化 candidate

按要求暂不进入 Stage 5。2026-08-22 已建立独立 Stage 4.1 candidate，包含：

1. DFL 每条边缓存 16 个 exp 结果，并将 16 次 probability 除法改为一次 reciprocal。
2. 七个图内 Add 预计算 `as/ds`、`bs/ds`，RVV 内核删除 `vfdiv.vf`。
3. Decode 只生成一次 2100 个 candidate，Top-10 和 NMS 共享。
4. location-major 的 80 类使用 RVV `e8,m8` `vredmax.vs + vfirst.m`，保持首个
   最大类别的 tie 语义。

数值验证已通过：7 x 256 x 256 Add 穷举零差异，五图 optimized DFL 中间结果
逐元素 bit-exact。Spike 与 `LargeGemminiRocketRVVConfig` Verilator smoke 均通过；
五份 UART ELF 已构建，反汇编包含 `vredmax.vs/vfirst.m`，且 `vfdiv.vf=0`。
实现和上板步骤见 `fpga/xcvu13p/tests/yolov5nu_stage41_opt/README.md`。该版本仍是
candidate，等待 FPGA 五图 cycles 和输出验证后再决定是否替换 Stage 4 baseline。

FPGA 验证已于 2026-08-23 完成：五图各运行两次，十次运行全部 398 records、
`PASS`、zero exit，重复运行确定，final tensors、Top-10 和 NMS 与 Stage 4
bit-exact。五图平均 graph 由 71.299M 降至 62.395M cycles，加速 1.1427x；
端到端由 1.4915s 降至 1.2573s，加速 1.1863x，吞吐率由 0.6705 提升至
0.7954 FPS。Add 由 10.328M 降至 2.118M（4.8776x），HEAD_DFL 由 11.420M
降至 10.538M（1.0837x），decode/NMS 合计由 3.276M 降至 0.470M。因此
Stage 4.1 在当时晋级为 performance baseline；详细结果见
`fpga/xcvu13p/tests/yolov5nu_stage4_1/PERFORMANCE_ANALYSIS.md`。

## 9. Stage 5：Tensor lifetime 和 memory planning（已完成，历史复盘）

当前 correctness-first generator 保留大量中间 tensor。布局和 kernel 稳定后，
增加静态 arena planner：

1. 根据拓扑计算 tensor 第一次产生和最后一次消费位置。
2. 生命周期不重叠的 tensor 复用内存。
3. Reshape 尽可能作为 view。
4. SiLU 在输入不再被其他节点使用时允许原地覆盖。
5. Add 在满足生命周期条件时允许复用输入 buffer。
6. Concat 尽可能让各生产者直接写入最终 channel slice。
7. 保持 Gemmini 所需的地址和 `DIM` 对齐。

通过条件：

- 生成 manifest 中输出每个 tensor 的 arena offset 和 lifetime。
- 检查任何同时存活 tensor 不发生区间重叠。
- ELF BSS 明显下降。
- 输出和前一版本一致。

### 9.1 实现状态（2026-08-24）

Stage 5A 至 5D 已生成独立候选，Stage 4.1 baseline 未被覆盖：

| 候选 | 已实现内容 | Arena | ELF BSS |
|---|---|---:|---:|
| 5A | 实际 call schedule 生命周期分析和静态 arena 复用 | 819,200 B | 905,012 B |
| 5B | 删除 79 个死/不活跃 tensor，尝试安全 Reshape view | 819,200 B | 905,012 B |
| 5C | 69 个 SiLU 和 7 个 Add 原地覆盖 | 835,200 B | 921,012 B |
| 5D | 8 个 SiLU 和 1 个 Add 直接写入 Concat slice | 835,200 B | 921,012 B |

Stage 4.1 BSS 为 9,526,228 bytes，因此 5A/5B 降低 90.50%，5C/5D 降低
90.33%。当前图在 location-major head lowering 后没有剩余的安全独立 Reshape
buffer，故 5B 的 `reshape_views=0`。5A 保留的不活跃符号没有 live interval，
统一 alias 到未使用 offset 0，因此删除符号后的 5B 与 5A BSS 相同。

5C/5D 比 5B 多 16,000-byte arena，是 alias root 生命周期变长后区间装箱碎片增加
所致；它们优化的是 SiLU/Add/Concat 内存流量，不能在 FPGA 测量前宣称 cycles
收益。8 个 ELF 的构建、memory-plan validator、Spike smoke 和 Verilator quick
smoke 已通过。FPGA 上 Stage 5A-D image025 和 Stage 5D 五图均保持 bit-exact。
Stage 5C image025 graph 为 60.195M cycles，是 scalar-SiLU 性能对照；Stage 5D
虽然将 Concat 降低 9.761%，但 strided SiLU 增加 1.549%，当前 graph 比 5C 慢
0.487%。考虑下一步要将 SiLU 移至 Gemmini 或与 producer 融合，2026-08-24 决定
固化 Stage 5D 为当时的部署和硬件 SiLU 开发基线，避免后续重新引入临时 tensor 与
Concat copy。Stage 4.1 保留为历史 bit-exact 参考，5C 保留为 scalar 性能对照。
详细定义、复现和性能分析见 `fpga/xcvu13p/tests/yolov5nu_stage5/BASELINE.md`、
`fpga/xcvu13p/tests/yolov5nu_stage5_memory/README.md` 与
`fpga/xcvu13p/tests/yolov5nu_stage5/PERFORMANCE_ANALYSIS.md`。

### 9.2 Gemmini动态 SiLU LUT V1

基于 Stage 5D 的后续硬件 SiLU candidate 已实现第一版动态256-entry LUT。新增
`SILU_LUT=6`、RoCC funct 26，每层用32条命令加载对应 LUT，并在 accumulator
scale、RNE、int8 clip 后查询。69张真实 LUT 的17,664项 Verilator exhaustive
测试、LoopConv smoke和 LeakyReLU回归均通过；完整 image025 Spike 与 Stage 5D
bit-exact。当时的软件 candidate 已恢复8条 SiLU Conv direct-Concat，不修改 RTL；
两次板级输出 bit-exact，graph均值减少132,784 cycles。详见
`docs/YOLOV5NU_GEMMINI_DYNAMIC_SILU_LUT.md`。

## 10. Stage 6：HEAD_CLASS 和 HEAD_DFL 计算优化（已完成，历史复盘）

Stage 6 开始时的 `Stage 5D + Gemmini动态SiLU LUT + 8条SiLU Conv direct-Concat`
image025 两次板级均值为20,788,719 graph cycles。当时 Head 已成为主要瓶颈：

| 算子 | cycles | graph占比 | 当前主体实现 |
|---|---:|---:|---|
| HEAD_DFL | 10,633,108 | 51.15% | RVV requant + CPU标量16-bin DFL |
| HEAD_CLASS | 1,935,505 | 9.31% | RVV requant + CPU标量sigmoid LUT |

Stage 6保持当前量化参数、`[2100][80]` class布局、`[2100][4][16]` DFL布局、
UART输出和现有RTL不变。新候选必须复用当前比特流。

### 10.1 H0：低扰动Head子阶段计时

第一版增加以下四项汇总，不增加profile record数量，也不在8400个DFL edge内部读取
cycle，避免计时本身改变热点：

- `head_class_requant_cycles`
- `head_class_sigmoid_cycles`
- `head_dfl_requant_cycles`
- `head_dfl_core_cycles`

DFL core内部的 max/exp/sum 与 probability/dot 将在H2重写kernel时再分开计时。

### 10.2 H1：HEAD_CLASS RVV寄存器LUT

当前168,000项class sigmoid使用CPU标量256-entry LUT。DSP Saturn配置的
`VLEN=256`，在`e8,m8`下一个寄存器组恰好容纳全部256项，因此H1采用：

1. 以`VL=256`将LUT一次装入`v8-v15`；
2. 每批最多256个INT8 logits装入`v16-v23`；
3. 使用`vrgather.vv`按原始uint8索引查表；
4. 将结果从`v24-v31`写回scores；
5. 当`VLMAX<256`时自动退回标量路径。

该方案不是indexed memory gather，必须对全部256个输入值穷举bit-exact，并在ELF
反汇编中确认存在`vrgather.vv`。

### 10.3 后续H2-H4

- H2：对DFL连续16-bin数据向量化max reduction、概率量化和INT8权重点积；第一版
  保留标量exp LUT读取、原顺序FP32 sum和reciprocal。
- H3：根据H2结果再评估RVV ordered sum、exp gather或可证明bit-exact的定点softmax。
- H4：可选检测专用模式，只为Top-10和NMS候选计算DFL；该模式不再提供完整
  `84x2100`输出，不能混入full-output baseline。

Stage 6第一轮只实现H0+H1。通过条件：final tensors、Top-10、NMS bit-exact，
连续两次运行确定，`HEAD_CLASS`和graph cycles稳定下降。

H0+H1已于2026-08-25完成FPGA验证：smoke两次均走VLEN256寄存器LUT路径并
777/777 PASS；完整image025两次输出bit-exact。`HEAD_CLASS`由1,935,505降至
410,351 cycles（4.717x），graph由20,788,719降至19,082,196（1.0894x），端到端
FPS由2.353升至2.558。H0显示`DFL core=10,355,836 cycles`，占新graph 54.27%，
因此H1晋级，下一步进入H2。详细结果见
`fpga/xcvu13p/tests/yolov5nu_stage6/PERFORMANCE_ANALYSIS.md`。

H2第一版已完成软件实现和本地验证。为严格保持当前数学语义，实际保留标量exp
LUT读取、原顺序FP32 sum和每边一次reciprocal；RVV负责16-bin `vredmax.vs`、
`vfcvt.x.f.v` RNE概率量化、`vwmul.vv`和INT32 `vredsum.vs`点积。VLEN不足256时
整条edge回退标量。DSP Saturn Verilator使用真实DFL指数衰减范围完成128组随机
全范围INT8对照，RVV与标量bit-exact；完整ELF合同和反汇编验证通过，等待FPGA
image025双跑决定是否晋级。详见`fpga/xcvu13p/tests/yolov5nu_stage6_h2/README.md`。

H2已于2026-08-25完成FPGA双跑：smoke两次均走RVV DFL路径并128/128 PASS；完整
image025两次均`dfl_rvv_enabled=1`且输出bit-exact。`HEAD_DFL`由10,438,800降至
3,915,273 cycles（2.666x），graph由19,082,196降至12,553,471（1.5201x），端到端
FPS由2.558升至3.841。H2在当时晋级为Stage 6软件基线。当时graph热点为Conv 45.38%、
HEAD_DFL 31.19%、Concat 11.01%；H3只研究剩余exp/sum/reciprocal，然后进入Stage 7。

H3A+H3B组合candidate已完成软件与本地验证。每个location一次处理4条edge，复用
权重加载并减少`vsetvli`；标量exp LUT写出四组连续16项后，由`vfredosum.vs`执行
有序FP32 sum。VLEN256 Verilator对32个location、128条edge逐项比较max、sum位模式、
probability和dot，全部bit-exact。完整ELF合同与反汇编通过，等待FPGA双跑；若H3
没有稳定降低DFL core，则保留H2并结束Stage 6。详见
`fpga/xcvu13p/tests/yolov5nu_stage6_h3/README.md`。

H3 FPGA双跑功能bit-exact，但`HEAD_DFL`由3,915,273增加到4,380,461 cycles
（+11.881%），graph由12,553,471增加到13,003,541（+3.585%），端到端FPS由
3.841降至3.715。组合candidate按停止条件拒绝，H2继续作为full-output Stage 6
基线。H3产物保留用于历史分析，不进入后续默认构建。

### 10.4 H3 reduction拆分结果与未来RTL方向

2026-08-26将原H3组合拆为独立候选。H3A四边batch max/dot将DFL core降至
3,499,019 cycles（相对H2 -8.697%）；H3C indexed exp gather降至3,710,371
（-3.181%）。`vfredosum.vs`独立H3B增至4,611,160（+20.324%），确认ordered
FP reduction是原组合退化主因。H3D四边lane普通`vfadd.vv`和H3E
`vfredusum.vs`均未超过H3A；H3E最大误差2 ULP，但最终INT8 DFL、Top-10和NMS
不变。完整数据见`fpga/xcvu13p/tests/yolov5nu_stage6_h3_split/README.md`。

短期保持当前RTL，不修改已验证比特流。后续若需要通用提升Saturn reduction，
优先研究复用现有FP FMA流水线的多partial-accumulator方案，而不是专用组合FP
加法树。当前源码没有accumulator数量配置；Backend只实例化一个
`SpecialSequencer`，其中只有一份DLEN-wide `acc_reg/acc_busy`。

计划中的RTL接口为新增参数（当前尚不存在）：

```scala
VectorParams.dspParams.copy(reductionAccumulators = 4)
```

实现范围：

1. `common/Parameters.scala`增加`reductionAccumulators`，默认1以保持现有RTL；
2. `backend/SpecialSequencer.scala`将单accumulator改为带busy位的slot数组；
3. reduction micro-op携带`acc_slot`，流水线结果按slot返回；
4. `backend/Backend.scala`按slot路由accumulator writeback，并修改单write假设；
5. `backend/ExecuteSequencer.scala`在所有partial accumulators完成后执行最终fold；
6. 汇总各slot的mask、tail和FP exception flags；
7. 仅对允许重排的`vfredusum.vs`启用多slot，`vfredosum.vs`继续保持严格有序。

四个slot与当前四级FP FMA pipeline匹配，目标是让DLEN chunk连续发射，而不是每个
chunk等待前一个结果返回。`MultiFMA`、增加`vpissqEntries`或仅改`dLen`都不会自动
产生多个reduction accumulator。未来验证必须包含Saturn官方reduction tests、
H3E ULP smoke、五图DFL checksum/检测结果和综合资源/时序；若whole-graph收益不足
1%或资源时序代价过高，则不进入FPGA baseline。

软件当时继续推进两个互相隔离的候选：H3F组合H3A+H3C；H3G在H3A上测试bin外层、
四个独立标量累加器交错执行。两者均不修改RTL。

H3F/H3G于2026-08-27完成FPGA双跑，输出均bit-exact。H3F的indexed gather在
batch路径中没有叠加独立收益：DFL core为3,526,439，比H3A慢0.784%，因此拒绝。
H3G将循环改为bin外层，每轮完成4次LUT load/store后紧邻发射4条使用不同FP
寄存器的`fadd.s`；反汇编确认调度未被编译器破坏。H3G的DFL core降至2,616,713，
相对H3A降低25.216%、相对H2降低31.719%；graph为11,337,653，端到端为
11,797,385 cycles，50 MHz下4.238 FPS。final checksum、Top-10和NMS均不变，
H3G在当时晋级为Stage 6最佳软件baseline。随后不再尝试将gather并入H3G。

### 10.5 H4：detection-only sparse DFL candidate

H4基于H3G，不改变RTL和HEAD_CLASS完整`2100x80`输出。先扫描class score，构造
`score >= NMS threshold`与全局Top-10的并集，只对并集位置执行DFL logits requant
和4条DFL边计算；Top-10和NMS复用同一批已解码candidate。保留Top-10并集是必要
条件，否则只按阈值筛选会漏掉低分但仍属于Top-10的location。H4输出不再是完整
`84x2100`，只能用于检测部署候选，不能混入full-output baseline。

H4已完成软件构建、NHWC/SiLU/Stage 5D验证和ELF反汇编检查，等待XCVU13P双跑。
主要记录candidate count、候选选择cycles、HEAD_DFL、DFL core、Top-10和NMS；
完整说明及ELF路径见`fpga/xcvu13p/tests/yolov5nu_stage6_h4/README.md`。

Image025双跑已通过，candidate count均为10，Top-10/NMS与H3G完全一致。H4平均
DFL core为34,422（相对H3G -98.685%），HEAD_DFL为1,513,362（-43.947%），
graph为10,143,581（-10.532%），端到端为10,275,948 cycles（-12.896%），
50 MHz下4.866 FPS。候选选择平均1,460,228 cycles，占H4 HEAD_DFL的96.49%，
成为新热点。由于candidate count具有图片依赖性，H4暂不固化，必须补跑固定五图中
的`036/142/404/650`，每图两次；全部检测等价且不同candidate count下仍稳定获益后
才能晋级。H3G继续作为full-output和H4回退baseline。

固定五图已于2026-08-27完成双跑，共10次均为398 records、PASS和zero exit。
candidate count分别为10、19、21、10、10；所有class checksum及Top-10/NMS逐项
匹配既有full-output参考。五图平均Graph为10,150,876，HEAD_DFL为1,521,607，
DFL core为39,268，端到端为10,285,364 cycles，50 MHz下4.861 FPS。相对H3G
image025基线，Graph降低10.468%，端到端降低12.817%，吞吐率提高14.701%。H4
正式晋级为detection-only部署基线；H3G保留为full-output基线。下一独立热点为
class max/候选选择，五图平均1,463,205 cycles。

H4A五图双跑已于2026-08-27完成。候选选择从`stage4_dfl_heads_i8()`移动到
`stage4_class_heads_i8()`的完整sigmoid之后，使用RVV `e8,m4` score-only
`vredmax.vs`；mask、Top-10 tie和NMS语义不变。独立smoke和五图共10次完整运行
全部PASS/zero exit，五图class checksum、candidate count、sparse DFL、Top-10和
NMS逐项匹配H4。candidate select由1,463,205降至176,667 cycles（-87.926%，约
8.28x）；HEAD_CLASS为587,078，HEAD_DFL为57,907，两个Head合计由1,931,976降至
644,985（-66.615%）。Graph为8,855,691，端到端为8,990,851 cycles，50 MHz下
5.561 FPS；相对H4端到端降低12.586%，相对H3G full-output降低23.789%。H4A替换
H4成为detection-only部署基线，H3G继续负责full-output。下一热点转为Concat、Add
和Gemmini Conv，详见`fpga/xcvu13p/tests/yolov5nu_stage6_h4/README.md`。

## 11. Stage 7：Concat 和 Add 优化（已完成，历史复盘）

Stage 6 结束时曾保留两条用途不同的历史基线：

- H3G：full-output基线，提供完整`84x2100`输出；
- H4A：detection-only部署基线，使用稀疏DFL和RVV class-max。

Stage 7只优化Concat和Add，不修改量化参数、检测头候选语义、RTL或Gemmini Conv
tile。H4A五图平均端到端为8,990,851 cycles，其中：

| 算子 | cycles | 端到端占比 | 当前实现 |
|---|---:|---:|---|
| Concat | 1,371,325 | 15.25% | CPU循环控制 + RVV copy/requant |
| Add | 773,895 | 8.61% | CPU循环控制 + RVV FP32 ratio kernel |

两者合计约2.145M cycles，占端到端约23.86%。Stage 7每轮只修改一个优化点，
保留H4A原始ELF和UART profile作为对照。

### 11.1 Stage 7A：Concat producer-direct write

将仍然写入独立中间buffer、随后又复制到Concat slice的producer，改为直接写入
最终NHWC Concat目标地址。优先检查：

1. `/model.2/Concat`，当前约524,966 cycles；
2. `/model.4/Concat`，当前约132,861 cycles；
3. `/model.6/Concat`，当前约49,271 cycles；
4. 已有9条SiLU/producer direct-Concat路径，先分析剩余路径为什么不能安全直写。

必须检查producer的最后消费者、Concat目标生命周期、channel offset、scale和
`row_align`要求。直接写入不能改变输出地址解释或引入重叠写入。

### 11.2 Stage 7B：Add 与 Concat 融合

对紧接Concat的Add，将：

```text
Add写入独立buffer -> Concat再次读取并复制
```

改为：

```text
Add直接写入Concat目标slice
```

该方向可能同时删除Add输出写入、Concat输入读取和Concat requant。必须先从
Stage 5D lifetime/memory plan中确认Add输入不会被其他消费者继续使用；不能为了
省一次copy而破坏原地Add的正确性。

### 11.3 Stage 7B-LUT：Add第二次requant的256-entry LUT

7B-exact已经证明：保留两次RNE量化可以保持bit-exact，但第二次Concat requant
会增加Add cycles。7B-LUT只把第二次requant改成查表：对每个实际的
`(add_scale, concat_scale)` pair，离线生成`int8 -> int8`的256-entry表，运行时
以第一次Add量化结果作为索引，用RVV `vluxei8.v`写入最终Concat slice。第一步
Add的FP32计算、RNE和int8饱和不变；当前YOLOv5nu图生成3张表，覆盖3个scale
不一致的Add节点。

它与Stage 7C不同：7B-LUT只优化融合Add路径的第二次requant，不能消除其他
Concat的通用遍历；它与Stage 7E不同：7B-LUT不把Add的scale运算改成整数乘加，
因此bit-exact风险较低，但仍需验证RVV indexed LUT在Saturn上的实际cycles。

### 11.4 Stage 7C：专用NHWC Concat RVV kernel

当前通用Concat对每个pixel、每个channel slice调用`requant_copy()`，反复产生
`vsetvli`、短向量load/store和地址计算。新增按固定形状或slice宽度专门化的RVV
内核，优先覆盖：

- 16/16、32/32、64/64和128/128 channel slice；
- 输入scale等于输出scale的纯copy路径；
- 输入scale不同的RVV requant路径；
- 每个Concat调用内固定VL和地址步进。

NHWC跨pixel不是连续channel slice，不能未经验证地把整个tensor替换成一次
`memcpy`。专用kernel必须保留当前量化RNE、int8饱和和channel顺序。

### 11.5 Stage 7D：Gemmini resadd评估

Gemmini支持resadd，但当前图内Add尚未映射到Gemmini。先做独立benchmark和单层
candidate，不直接替换全部Add。优先测试`/model.2/m/m.0/Add`的102,400元素，
再测试51,200和25,600元素规模，比较：

- Gemmini配置、mvin/mvout和DMA启动开销；
- 32x32阵列利用率；
- input/output scale、RNE和int8饱和是否匹配；
- 原地输出是否安全；
- 与当前RVV ratio kernel的cycles和资源代价。

小Add很可能被DMA和启动开销抵消，因此只有板级稳定收益才进入候选。resadd
benchmark不能与Concat融合、整数定点或Conv tile sweep同时修改。

### 11.6 Stage 7E：Add整数定点实现

当前`add_ratio_i8()`流程为：

```text
int8 -> int16/int32 -> FP32 -> 两次乘法 -> FP32加法
     -> FP32转整数RNE -> int8饱和
```

候选实现使用预计算整数乘数和shift：

```text
int8 -> int32乘加 -> round-to-nearest-even -> int8饱和
```

该方向可能删除FP32转换和两次向量FP乘法，但bit-exact风险最高。必须对7个Add
分别验证输入范围`[-128,127] x [-128,127]`、RNE边界、负数、饱和边界，并与当前
FP32实现逐项比较。不能因为平均误差很小就直接替换部署基线。

### 11.7 Stage 7验收条件

每个Stage 7 candidate都必须满足：

1. H3G full-output和H4A detection-only路径不被意外改变；
2. H4A五图Top-10、bbox、NMS和class checksum保持一致；
3. full-output路径的tensor checksum保持一致，或对detection-only明确记录未计算区域；
4. Stage 5D arena无非法重叠，所有Gemmini地址满足对齐；
5. 每图至少双跑，记录Concat节点、Add节点、Graph和端到端cycles；
6. 只有稳定降低cycles且没有明显代码/BSS增长的方案才能合并。

Stage 7完成后再重新确定热点。`gemmini_fence()`继续保留在CPU/RVV第一次消费
Gemmini输出之前；异步重叠属于独立实验，不与本阶段的Concat/Add算子优化混合。

### 11.8 Stage 7软件候选状态（2026-08-28）

#### 11.8.1 Stage 7A/7B

Stage 7A和7B已完成固定五图ELF生成及静态验证，均基于H4A且不修改RTL。Stage 7A
只将两个满足单消费者、scale一致和生命周期安全条件的MaxPool/Resize producer
直接写入Concat slice，Stage 5D `direct_concat=11`。原始Stage 7B在此基础上将3条
Add直接写入Concat slice，并预计算相对最终Concat scale，`direct_concat=14`、
`inplace=3`，但删除了原Add output scale上的第一次RNE/int8量化，因此只是非
bit-exact历史性能候选。

实现和ELF清单见`fpga/xcvu13p/tests/yolov5nu_stage7/README.md`及
`fpga/xcvu13p/tests/yolov5nu_stage7/build_manifest.json`。

2026-08-28五图双跑结果：7A的Concat为1,366,085、Add为773,828、Graph为
8,842,678、端到端为8,977,875 cycles（5.569 FPS），与H4A逐项bit-exact，
但整图仅改善0.144%，保留为安全producer-direct候选。原始7B的Concat降至645,792、
Graph降至8,222,896、端到端降至8,358,328 cycles（5.982 FPS），但Add升至866,343，
且五图class/DFL checksum和Top-10/bbox发生变化。原因是Add output scale与Concat
output scale不同，原始7B删除了原本的第一次RNE量化，属于非bit-exact量化改变，
拒绝进入部署基线。随后生成了7B-exact：对3条scale不一致的Add使用
`yolov5nu_rvv_add_two_step_i8()`，按原顺序执行Add output scale量化和Concat
output scale requant；`/model.8`的scale一致路径仍使用单步Add。独立RVV smoke
在Spike上完成`196608/196608`组逐元素对照，静态验证和五图ELF均通过。

7B-exact随后完成XCVU13P五张图片各两次上板测试，class checksum、sparse DFL
checksum、Top-10、bbox和NMS均与H4A逐项一致。五图双跑平均：Concat `640,617`、
Add `1,114,874`、Graph `8,465,384`、Decode `107,012`、NMS `28,237`，
Graph+Decode+NMS为`8,600,632` cycles，约`5.814 FPS`。相对H4A，Graph减少
`390,307` cycles（`4.407%`），端到端减少`390,219` cycles（`4.340%`）。
因此7B-exact已经满足bit-exact候选条件，可以与H4A并列记录；是否替换部署基线
仍需考虑Add cycles增加约44.1%后的整体收益。

在此基础上已生成独立的7B-LUT-exact候选。它为当前图的3个
`(add_scale, concat_scale)`组合生成3张256-entry int8 requant LUT，用RVV
`vluxei8.v`替代第二次FP32 requant；第一步Add量化和7B direct-Concat布局不变。
五张图ELF、3张表、`direct_concat=14`及反汇编合同验证均已通过，独立
`yolov5nu_add_two_step_lut_rvv` smoke 在Spike上完成`196608/196608`对照，
随后完成XCVU13P五张图片各两次测试，class/DFL checksum、Top-10、bbox和NMS均
与7B-exact一致。但7B-LUT-exact的五图平均 Add 为`3,071,824` cycles、Graph 为
`10,422,136` cycles、Graph+Decode+NMS 为`10,557,467` cycles（约`4.736 FPS`），
相比7B-exact分别恶化约175.5%、23.12%和22.75%。结论是当前Saturn的
`vluxei8.v` indexed gather不适合该热点；7B-LUT-exact保留为bit-exact负优化
对照，不进入部署基线。源码核对显示Rocket集成实例化Saturn frontend/memory unit
时未传入`sgSize`，未启用fast scatter/gather路径；`dspParams.vsgPorts`在该接法下
不能把本次indexed load变成快速SG访问。

后续已生成7B-LUT-register-exact：每个strided Add节点将256-byte LUT一次加载到
`e8,m8`寄存器组，循环内使用`vrgather.vv`，不再走indexed memory。VLEN不足
256时回退到7B-exact。独立Spike smoke完成`196608/196608`对照，五图ELF、
`direct_concat=14`、3张表及反汇编合同均通过。五图各双跑结果全部bit-exact；
平均 Add `996,076`、Concat `651,134`、Graph `8,357,832`、
Graph+Decode+NMS `8,492,431` cycles（约`5.888 FPS`）。相对7B-exact，Add减少
10.66%、Graph减少1.27%、端到端减少1.26%；相对indexed-LUT，Add减少67.57%。
7B-LUT-register-exact在当时晋级为Stage 7最快的bit-exact候选。

Stage 7C也已作为独立H4A分支生成，不叠加7A/7B：保留`direct_concat=9`和原Add，
仅将普通NHWC Concat改为每slice一次调用的strided RVV kernel。同scale走`e8,m8`
copy，不同scale走`e8,m2/e16,m4/e32,m8` requant。独立Spike smoke覆盖4种channel
宽度和3种ratio，`5760/5760`通过；五图各双跑全部bit-exact。平均 Concat
`904,281`、Add `773,555`、Graph `8,405,701`、Graph+Decode+NMS `8,540,184`
cycles（约`5.855 FPS`）。相对H4A，Concat减少34.06%、Graph减少5.08%、端到端
减少5.01%，Add基本不变。7C独立实验通过，但与7B-register组合时不能直接叠加
收益，因为`/model.2/4/6`的Concat在7B中已经被producer-direct消除。

Stage 7BC组合候选已生成：同时启用7B-LUT-register的3条Add direct-Concat、
Stage 7A的MaxPool/Resize direct write和7C剩余Concat strided kernel。五图ELF的
静态合同均为`arena=846400 bytes`、`dead=162`、`inplace=3`、
`direct_concat=14`；反汇编包含`vrgather.vv`且不含`vluxei8.v`。独立Add与Concat
smoke分别保持`196608/196608`和`5760/5760`通过。该版本预计约`8.34M cycles / 6.0
FPS`，等待五图板级双跑确认bit-exact和实际收益后再冻结Stage 7。五图各双跑全部
bit-exact，平均 Add `996,241`、Concat `493,204`、Graph `8,199,625`、
Graph+Decode+NMS `8,333,712` cycles（约`5.999 FPS`）。相对7B-register，Graph
减少约1.89%、端到端减少约1.86%；相对7C，端到端减少约2.41%。7BC在当时晋级为
Stage 7最佳bit-exact候选，并作为Stage 8的回退基线。

Stage 7E已基于7BC生成：对7组Add ratio使用Q22乘数，RVV执行`e32 vmul.vx +
vadd.vv + vnclip.wi`并设置`vxrm=RNE`；3条direct-Concat保留register LUT第二步。
主机系数搜索和Spike实测均bit-exact，普通Add全域`458752/458752`、定点第一步加
register-LUT补充`49152/49152`通过。五图ELF保持`arena=846400 bytes`、
`direct_concat=14`，反汇编确认整数Add路径。五图各双跑共10次均bit-exact，平均
Add `748,018`、Concat `492,900`、Graph `7,954,706`、Graph+Decode+NMS
`8,089,036` cycles（约`6.181 FPS`）。相对7BC，Add减少24.92%、Graph减少2.99%、
端到端减少2.95%；相对H4A端到端减少10.03%。7E在当时晋级为Stage 7最快
bit-exact baseline，并作为Stage 8回退基线。

Stage 7D Gemmini resadd也已作为独立H4A分支生成，替换全部7个Add，保留
`direct_concat=9`、6个原地输出和`/model.8`独立输出stride。Gemmini的mvin
scaler会先分别执行RNE/int8量化，不能复现RVV“FP32相加后一次RNE”的语义；采用
`A_scale=ar/br, B_scale=1, C_scale=br`后，主机穷举仍有约18.7%-23.7%的组合相差
1 LSB。因此7D明确是非bit-exact性能/精度候选。小型Verilator七组1024-element
smoke通过，Gemmini约2.7x-4.6x快，`max_error=1`、`inplace_errors=0`。真实尺寸
UART smoke双跑中七层合计RVV `774,135`、Gemmini `145,808` cycles，约`5.31x`。
五图模型各双跑共10次，平均 Add `139,504`、Graph `8,238,543`、
Graph+Decode+NMS `8,375,343` cycles（约`5.970 FPS`），相对H4A端到端减少6.85%。
但checksum、分数、bbox、排序及候选数均变化，image142的NMS类别集合也发生变化。
因此7D只保留为近似量化性能分支，不进入bit-exact组合基线；若要部署仍需扩大
准确率验证集。

## 12. Stage 8：共享Scale ResAdd与Concat-Conv融合

Stage 8将“重新对齐残差分支量化scale的Gemmini resadd”和“Concat融入后续
1x1 Conv”定义为一个新的模型量化/AOT调度阶段。它不再以旧版H4A tensor为
bit-exact目标，而是先导出一份明确包含共享scale语义的新ONNX模型，再要求Gemmini
裸机执行与该新模型逐层bit-exact。Stage 7E 是进入 Stage 8 时的回退基线，Stage 8F
完成后取代它，成为当前 Stage 8 最终 bit-exact baseline。

### 12.1 目标执行图

每个Residual Add的两个输入先在导出/校准阶段共享输入scale，Gemmini执行：

```text
A_scale = B_scale = shared_scale
Gemmini resadd = Q((A + B) * shared_scale / output_scale)
```

Feature Concat不再生成独立tensor。后续1x1 Conv按输入channel拆分权重和K维：

```text
C_acc  = bias + Conv(slice0_requant, weight_slice0)
C_acc +=        Conv(slice1_requant, weight_slice1)
...
C = final_requant_and_SiLU(C_acc)
```

当输入scale不等于`concat_scale`时，requant数学语义仍保留，但由Gemmini mvin
scaler完成，不再执行独立RVV Concat requant/copy。bias只加入一次，所有partial-K
结果必须保留在int32 accumulator，最后一个slice完成后才能mvout、requant和激活。

### 12.2 可融合范围

当前13个feature Concat的后继全部是1x1 Conv，共17条consumer Conv边：

- 单消费者：`/model.2/4/6/8/9/13/17/20/23/Concat`；
- 双消费者：`/model.12/16/19/22/Concat`，分别进入后续C2f的`cv1`和`cv2`；
- 检测头`/model.24/Concat`和`Concat_1`已由Stage 4 location-major lowering消除，
  不纳入Stage 8。

单消费者第一验证层固定为：

```text
/model.17/Concat -> /model.17/cv3/conv/Conv
```

它具有两个输入、一个consumer、64x64的1x1 Conv，能同时覆盖per-slice mvin
requant、split-K accumulator、bias-once和final-SiLU语义。

### 12.3 实施步骤

1. `[完成] Stage 8A`：建立共享scale ONNX候选，识别全部7个feature-map Add
   scale group，重新生成QDQ常量、受影响Conv bias/bias-scale、Conv输出requant、
   69张动态SiLU LUT和ORT reference。默认单层候选及累计七Add候选均保留在独立目录。
2. `[完成] Stage 8B`：将单个共享scale Add映射到Gemmini resadd，使用两路
   `MVIN_SCALE_IDENTITY`和`C_scale`完成image025 FPGA bit-exact验证。
3. `[完成] Stage 8C 首层`：完成`/model.2/Concat -> /model.2/cv3/conv/Conv`
   的两片split-K 1x1 Conv，保留partial-K之间fence，并完成FPGA验证。
4. `[完成] Stage 8C 扩展`：完成`/model.4/6/8`、`/model.9`四片SPPF以及
   `/model.13/17/20/23`五个单消费者Concat的split-K融合。
5. `[完成] Stage 8C 全单消费者`：确认9个单消费者Concat均不再物化，AOT
   `direct_concat=2`、`arena=784000 bytes`，并完成五图主机逐元素验证。
6. `[完成] Stage 8D`：处理`/model.12/16/19/22`四个双消费者Concat的8个
   后继Conv，每个consumer独立维护accumulator并保留partial fence；完成五图17条
   consumer edge主机验证和image025双跑FPGA验证。
7. `[完成] Stage 8E 软件收尾`：删除13个目标Concat tensor，重算arena生命周期、
   alias和对齐，最终AOT为`direct_concat=0`、`arena=739200 bytes`。
8. `[完成] Stage 8E 部署准入`：全消费者 hardware-aware ELF 已在
   `025/036/142/404/650`上连续双跑，并与最新`hardware_integer_reference.json`
   逐图比较通过。五图的 class logits、sigmoid、稀疏DFL、Top-10、bbox 和 NMS 均一致。
9. `[冻结] Stage 8F`：双消费者输入 slice Scratchpad reuse 已完成五图 FPGA 双跑，
   五图 class/sigmoid/稀疏DFL/Top-10/NMS 均与 hardware-aware reference 一致；平均
   端到端`6123155 cycles`，比8C baseline约低`0.45%`。Stage 8F为当前Stage 8最终
   bit-exact baseline，8C仅作为历史回退基线。
10. `[暂缓] Stage 9`：未来以冻结的Stage 8F全消费者候选为唯一Conv调优基线，
   按`CONV_GEMMINI` cycles排序，先对最慢的普通Conv和split-K Conv分别做tile
   sweep。当前不执行Stage 9，首轮仍只允许软件AOT调度，不修改RTL或Scala。

每次只新增一个scale group或一个Concat-Conv fusion，不能一次修改全部7个Add和
13个Concat，否则中间tensor差异无法定位。

### 12.3.1 Stage 8结束状态

Stage 8F的全消费者 hardware-aware 候选已经完成五图 FPGA 双跑，并冻结为当前
Stage 8最终 bit-exact baseline。Stage 8的实施顺序和收尾状态如下；Stage 9暂缓。

1. `[完成]` 全消费者 hardware-aware ELF 五图双跑准入完成，作为Stage 8F的
   bit-exact baseline。对应 ELF 位于`generators/gemmini/software/gemmini-rocc-tests/build/imagenet/`。
2. `[冻结]` Stage 8F 双消费者输入 slice Scratchpad reuse 已完成 Spike 五图仿真和
   FPGA 五图双跑，验证了复用 resident slice 时的 A-side mvin、mvin scale、
   accumulator 隔离和 bit-exact 结果。对应 ELF 与文档位于 Stage 8F 独立目录。
3. `[放弃]` Stage 8G：Add accumulator到后续Conv的`mvout_spad`片上链接。单链路理论
   收益约`0.1%~0.5%`，但当前单次requant无法保持Add->Concat两阶段bit-exact舍入，
   不进入FPGA验证。
4. `[完成候选验证]` Stage 8H：split-K配置/fence合并。五图Spike/FPGA均bit-exact，
   `/model.9`局部Conv约减少`3.4K cycles`，但端到端平均比8F高约`0.02%`，因此不固化
   为新baseline，保留为局部调度研究候选。
5. Stage 8F冻结为Stage 8最终bit-exact baseline；Stage 8H不替代8F。Stage 9 Conv
   调优暂缓，未来从Stage 8F重新建立独立候选后，再对普通Conv和split-K Conv分别
   进行系统tile sweep。

这里的后续优化不再修改Add/Concat数学模型；Stage 8现有候选和RTL保持不变。

### 12.5.1 Stage 8A first implementation

Stage 8A的第一版实现位于`scripts/yolov5nu_stage8a_shared_scale.py`，产物独立保存在
`generators/gemmini/software/gemmini-ort/models/detection/stage8a_shared_scale/`，不覆盖
Stage 7E模型和AOT文件。脚本已经结构化识别全部7个feature-map Add scale group，默认只修改
`/model.2/m/m.0/Add`，将两支输入scale从
`0.06295188516378403/0.15322692692279816`统一为较大的
`0.15322692692279816`，Add输出scale保持`0.1639299839735031`。

改变SiLU输出scale后，若该输出直接进入后续Conv，脚本同时按
`new_bias_scale = new_input_scale * weight_scale`重新量化该Conv的Int32 bias；否则只改
Add两输入的Q/DQ共享scale会使Conv整数reference失配。脚本还从新manifest重新生成所有Conv
输出requant和69张动态SiLU LUT，并生成五图ORT reference、QDQ常量审计和AOT源文件。
76个Conv QDQ校验和69张LUT的`17664`项穷举校验均已通过。该候选只保证相对新Stage 8A
ONNX的bit-exact，不能直接宣称与Stage 7E bit-exact；Stage 8B的Gemmini resadd软件候选
已实现，硬件bit-exact仍待验证。

### 12.5.2 Stage 8B software candidate

Stage 8B的第一版位于`scripts/yolov5nu_stage8b_shared_resadd.py`，调用
`generate_yolov5nu_baremetal.py --stage8-mode 8b`，产物独立保存在
`generators/gemmini/software/gemmini-ort/models/detection/stage8b_shared_resadd/`。
它只替换`/model.2/m/m.0/Add`：两路输入使用`MVIN_SCALE_IDENTITY`，store scale使用
`shared_scale/add_output_scale = 0.9347095828`，目标语义为
`Q((A+B)*shared_scale/add_output_scale)`。选定Add故意保留独立的Add output，再由
Concat执行原有的Add-output-to-Concat-output requant，因此没有跳过QDQ边界。其余六个
Add仍使用Stage 7E的RVV fixed-point实现。

生成检查已通过：单个shared Gemmini resadd call、选定Add未direct-Concat、内存计划
`direct_concat=13`；Stage 8A的`76/76` Conv QDQ和`17664/17664` SiLU LUT校验继续通过。
但目前仍只是软件/AOT候选，必须在仿真或上板逐层对照Stage 8A ORT reference后，才能判定
Gemmini硬件是否bit-exact。Stage 8B不修改RTL或Scala。

### 12.5.3 Stage 8C `/model.2` first candidate

为直接确认Stage 8B的完整收益，Stage 8C首层从原计划的`/model.17`调整为
`/model.2/Concat -> /model.2/cv3/conv/Conv`。实现位于
`scripts/yolov5nu_stage8c_model2_splitk.py`和AOT generator的
`--stage8-mode 8c-model2`。原`6400x32 * 32x32`的1x1 Conv拆成两个
`6400x16 * 16x32` partial-K：第一片加载bias且不mvout，第二片在同一accumulator
继续累加，最后才执行Conv requant和动态SiLU LUT。每片通过独立mvin scale复现原
Concat requant，`/model.2/Concat` tensor已从arena中删除。

五图主机逐元素验证已通过：两片requant等于原QDQ Concat、split-K int32累加等于
原Conv quantized output、final SiLU等于原QDQ SiLU。内存计划为`arena=846400 bytes`、
`direct_concat=12`，model.2 Concat为inactive。V1为避免全局mvin scale切换时序歧义，
每个tile的两次partial loop之间保留fence；板级bit-exact通过后再评估无fence调度。
该候选不修改RTL、Scala或bitstream。

### 12.5.4 Seven-Add shared-scale expansion

在model2单Add和split-K板级bit-exact通过后，新增
`scripts/yolov5nu_stage8_all_shared_adds.py`，按拓扑顺序将全部7个feature Add转换为
共享输入scale并映射Gemmini resadd。model4两级和model6三级残差链会把前级Add输出scale
对齐到后级Add输入scale，并同步重算受影响Conv的Int32 bias/bias-scale、requant和动态
SiLU LUT。该模型独立保存在`stage8_all_shared_adds/`，不覆盖单Add最佳候选。

该阶段的AOT曾包含7次shared Gemmini resadd和1次model2 split-K，split-K partial loop
之间的fence保持不变；其余Concat-Conv随后逐步扩展。七组共`458752`个host输入组合、
76个Conv QDQ、69张SiLU LUT和五图ORT reference均通过，最终演进为Stage 8F全消费者
路径。

### 12.5.5 Backbone Concat-Conv expansion

在7个Gemmini Add和model2 split-K板级通过后，Stage 8C继续扩展
`/model.4/6/8/Concat -> cv3/conv/Conv`，实现位于
`scripts/yolov5nu_stage8c_backbone_splitk.py`和AOT generator的
`--stage8-mode 8c-backbone-splitk`。通用helper支持`16/32/64/128` slice channel和
`32/64/128/256` output channel，按accumulator容量自动选择空间tile。每个tile仍保持
“partial0+bias、fence、partial1 accumulate、final requant+SiLU、fence”的保守调度。

四个Concat tensor均已删除，AOT契约为7次shared resadd、4次split-K、
`direct_concat=7`、`arena=846400 bytes`。五图对4层共20组materialized Concat、Conv、
SiLU逐元素检查全部bit-exact；76 Conv QDQ、69张SiLU LUT和旧model2-only模式回归通过。
该扩展随后通过板级匹配并进入全消费者 Stage 8C/8D 路径；这里的“全Add+仅model2
fusion”仅是该小节对应时间点的历史 baseline。

### 12.5.6 All single-consumer Concat-Conv fusions

在4条backbone split-K板级bit-exact并晋级后，Stage 8C继续处理剩余5个单消费者：
`/model.9/13/17/20/23/Concat`。实现位于
`scripts/yolov5nu_stage8c_single_consumer_splitk.py`和AOT generator的
`--stage8-mode 8c-single-consumer-splitk`。其中model9为4片SPPF输入，使用独立
multi-slice helper；其余8条使用two-slice helper。两者均只在第一片加载bias、最后一片
mvout+requant+SiLU，并保留每片后的fence。

AOT契约为7次shared resadd、8次two-slice、1次four-slice、9个inactive Concat、
`direct_concat=2`、`arena=784000 bytes`。五图九层的slice requant、int32 accumulator、
materialized-vs-split Conv和SiLU硬件数学路径均逐元素完全一致；76 Conv QDQ、69张LUT和
旧4-fusion模式回归通过。ORT debug graph在model17少数浮点累加tie上有1 LSB Conv/
2 LSB SiLU观测差异，但materialized与split-K硬件路径完全一致，最终板级仍须匹配正常
ORT reference。完成该候选后只剩`/model.12/16/19/22/Concat`四个双消费者节点。

### 12.4 Stage 8 性能预期与实际结果

以H4A端到端`8.991M cycles`为历史估算起点：Gemmini resadd目标约`120k-150k`，
独立Concat目标接近0。完全不计split-K开销的理论上限约为`6.985M cycles / 7.16 FPS`。
17个后续1x1 Conv当前合计约`1.336M cycles`，考虑额外命令、mvin scaler和
accumulator调度后，现实目标为：

```text
端到端 7.1M-7.4M cycles
吞吐   6.8-7.05 FPS @ 50 MHz
```

历史估算阶段曾设定：如果split-K额外开销超过约500k cycles，或共享scale候选的准确率不可接受，则停止
全图扩展并保留已验证的单层实验。

### 12.5 正确性与准入条件

- Gemmini结果必须相对Stage 8新ONNX模型逐层bit-exact；
- 必须区分“相对新ONNX bit-exact”和“相对H4A bit-exact”，不得混写；
- mvin requant必须穷举验证RNE、负数和int8饱和；
- partial-K期间禁止中间mvout、激活或截断，bias只能加入一次；
- 五图每图双跑必须确定，Top-10、bbox和NMS必须匹配新ONNX reference；
- 共享scale必须经过coco128校准；若准备部署，需要QAT或mAP验证；
- Stage 8第一版只修改软件、ONNX和AOT生成器，不修改RTL。

### 12.5.8 Stage 8 completion status

Stage 8的共享scale、7个Gemmini Add、9个单消费者Concat-Conv和4个双消费者
Concat-Conv已经完成软件实现、主机验证和FPGA验证。最终冻结候选为 Stage 8F：
它包含17条split-K consumer edge、13个inactive Concat tensor、`direct_concat=0`
和`arena=739200 bytes`，所有partial-K之间保留fence；四组双消费者输入 slice
驻留在独立Scratchpad分区，第二个consumer跳过A-side DDR mvin。

Stage 8F 五图 FPGA 双跑的 class/sigmoid/DFL/Top-10/bbox/NMS 均与最新
hardware-aware integer reference 一致，平均端到端约`6.123M cycles`、约`8.166 FPS
@ 50 MHz`，相对 Stage 8C 约降低`0.45%`。Stage 8H 的局部 config/fence 合并也
通过五图 bit-exact，但端到端平均比8F高约`0.02%`，因此不替代8F。完整文件与路径
见`docs/YOLOV5NU_STAGE8_SUMMARY.md`和`docs/YOLOV5NU_STAGE8F_SPAD_REUSE.md`。

## 13. Stage 9：Gemmini Conv调优（暂缓）

原Gemmini Conv tile调优整体后移为Stage 9。Stage 8F已经冻结量化scale、split-K
边界和arena计划，但短时间内暂不执行Stage 9。未来重新开始时，必须以Stage 8F
作为唯一AOT baseline，重新profile 76个Conv和split-K Conv，避免混用Stage 7或
Stage 8H的算子边界。

工作顺序：

1. 按`CONV_GEMMINI` cycles排序，区分普通Conv和Stage 8 partial-K Conv；
2. 只对最慢层做LoopConv tile sweep；
3. 分析`tiled_conv_auto()`的自动tile与spad/acc容量利用率；
4. 比较`DIM`、`och`、`kch`和空间tile对DMA、scratchpad、accumulator的影响；
5. 对partial-K单独比较slice顺序、accumulator驻留和mvin scale吞吐；
6. 每次只改变一个层或一组同形状层，并保留自动tile对照；
7. 记录Gemmini Conv、Graph、端到端cycles及资源/时序变化。

Stage 9 candidate必须复用冻结的Stage 8F分支，保持`gemmini_fence()`、量化和
split-K语义不变，并对该分支reference bit-exact。Conv tile优化不能同时改变激活、
量化、Concat融合边界或Add实现。

## 14. 每阶段统一验证矩阵

### 14.1 Host/ORT

- parser layout/axis 检查
- Conv contract 检查
- 每个新 kernel 的 scalar reference
- final class/DFL tensor 对照
- 五张图片的 detections 对照

建议固定至少以下图片：

- `000000000025.jpg`
- `000000000142.jpg`
- 从 coco128 再选择三个不同主体、不同检测尺度的样本

### 14.2 Spike/Verilator

- Spike：验证生成 ELF、RVV 指令和小型 kernel smoke test
- Verilator：验证修改涉及的 Gemmini/RVV 硬件路径
- 完整 YOLOv5nu 仿真很慢，因此主要作为定点 smoke，而不是每次迭代的性能平台

### 14.3 FPGA

- 连续运行两次，结果必须一致
- graph/decode/NMS 分开计时
- UART 输出不计入性能
- profile record 数量正确且不跨 JTAG 运行残留
- 比较 graph 总 cycles 和各算子类别 cycles

### 14.4 正确性门槛

| 优化类型 | 要求 |
|---|---|
| layout-only | bit-exact |
| fused SiLU LUT | 对当前 separate 实现 bit-exact |
| RVV kernel | 对 scalar kernel bit-exact |
| memory planning | bit-exact |
| Gemmini tile | bit-exact |
| Stage 8共享scale | 对Stage 8新ONNX逐层bit-exact，并单独建立accuracy baseline |
| Stage 8 split-K | 对物化Concat的新ONNX reference逐层bit-exact |
| 后续更改量化方案 | 单独建立accuracy baseline，不与Stage 8F结果混写 |

## 15. 预计收益和停止条件

| 版本 | graph cycles 目标 | 说明 |
|---|---:|---|
| Stage 0 baseline | 429.7M | 历史 NCHW bridge 测量值 |
| NHWC resident | 320M-340M | 消除 Conv layout bridge |
| NHWC + fused SiLU | 120M-170M | 消除大部分 Sigmoid/Mul 成本 |
| NHWC + fused SiLU + RVV | 70M-120M | 优化内存算子和 DFL |
| memory/Conv tuned | 50M-90M | 后续目标，不作第一轮承诺 |
| Stage 7历史最好 | 约7.95M | 7E bit-exact graph实测 |
| Stage 8F融合实测 | 约6.123M | 共享scale resadd + 17条Concat-Conv split-K + 双消费者 SPAD reuse，约8.166 FPS |
| Stage 8H局部候选 | 约5.989M | `/model.9`局部优化，端到端不优于8F，不晋升 |
| Stage 9 Conv tuned | 暂缓 | 重新启动时从Stage 8F建立独立候选 |

以上是工程目标范围，不是结果保证。每阶段以上板测量决定是否继续。如果某项
优化满足以下任一条件，应停止合入并保留为实验分支：

- 输出不再对当前阶段reference bit-exact且无法解释差异；
- Stage 8共享scale相对float/原量化模型的accuracy下降不可接受；
- cycles 没有稳定改善；
- 引入的 BSS/代码尺寸明显超过收益；
- 依赖特定 VLEN 或破坏现有 RVV/Gemmini 配置兼容性。

## 16. 实施顺序（已执行记录）

按以下顺序执行，不并行混入多个数学变化：

1. `[完成]` 冻结 Stage 0 baseline 和五图结果。
2. `[完成]` 增加 physical layout metadata 和 NHWC layout-only 候选版。
3. `[完成]` 删除 76 个 Conv 周围的 NCHW/NHWC bridge。
4. `[完成]` 完成 NHWC scalar 算子并通过 bit-exact 检查。
5. `[完成]` 融合 Sigmoid+Mul 为 SiLU LUT。
6. `[完成]` 依次加入 RVV Concat、Add、MaxPool、Resize、DFL kernels。
7. `[完成]` 加入检测头专用布局，消除 DFL Transpose。
8. `[完成]` 加入 tensor lifetime/arena planner。
9. `[完成]` 完成Stage 6 Head H0/H1，并根据板级结果推进DFL H2。
10. `[完成]` 以H3G为full-output、H4A为detection-only baseline结束Stage 6。
11. `[完成]` Stage 7A：Concat producer-direct write。
12. `[完成]` Stage 7B：Add与Concat融合。
13. `[完成]` Stage 7C：专用NHWC Concat RVV kernel。
14. `[完成]` Stage 7D：Gemmini resadd评估；仅保留为非bit-exact对照。
15. `[完成]` Stage 7E：Add整数定点实现，并冻结为Stage 7 bit-exact baseline。
16. `[完成]` 完成Stage 7E并将其作为Stage 8的输入回退基线；Stage 7D仅保留为近似性能对照。
17. `[完成]` Stage 8A：建立单层Residual Add共享scale ONNX和独立accuracy baseline。
18. `[完成]` Stage 8B：映射共享scale Gemmini resadd，对新ONNX逐元素bit-exact。
19. `[完成]` Stage 8C：实现`/model.2/4/6/8`及9个单消费者Concat的split-K 1x1 Conv。
20. `[完成]` Stage 8D：处理`/model.12/16/19/22`四个双消费者Concat，保持partial fence。
21. `[完成]` Stage 8E：完成arena重算、全消费者hardware-aware reference和五图部署准入。
22. `[冻结]` Stage 8F：完成四组双消费者输入slice的Scratchpad reuse，五图Spike/FPGA双跑
    bit-exact，冻结为Stage 8最终baseline。
23. `[放弃]` Stage 8G：评估Add accumulator到后续Conv的`mvout_spad`链接；因有限收益和
    两阶段requant bit-exact边界问题放弃。
24. `[完成候选验证]` Stage 8H：评估split-K config/fence合并；五图bit-exact但端到端无收益，不晋升。
25. `[暂缓]` Stage 9 Conv tile sweep，未来从Stage 8F重新建立独立候选。

### 12.5.7 Dual-consumer Concat expansion

新增`--stage8-mode 8c-dual-consumer-splitk`，通过
`scripts/yolov5nu_stage8c_single_consumer_splitk.py dual`生成双消费者候选。该模式保留
此前9个单消费者融合，并将`/model.12/16/19/22/Concat`的两个后继Conv分别执行
split-K，共17条consumer edge。四个双消费者Concat不物化，源slice保留在producer tensor
中，由两个consumer各自mvin；每个consumer都保持bias-once、partial之间fence和最终
requant+SiLU。AOT契约为7次shared resadd、16次two-slice、1次model9 four-slice、
`direct_concat=0`、`arena=739200 bytes`。五图17条edge的硬件数学路径均通过主机逐元素
验证，随后已完成五图 FPGA 双跑并进入 Stage 8F 的最终 baseline。该候选不修改 RTL、
Scala 或 bitstream。

第一项实际代码任务是建立 `yolov5nu-nhwc` 对照版。它只改变物理布局，保留
当前量化参数、算子数学实现、decode、NMS 和 UART 输出格式。
