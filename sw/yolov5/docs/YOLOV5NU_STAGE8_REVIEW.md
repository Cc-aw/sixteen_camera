# YOLOv5nu Stage 8 复盘

## 定位

Stage 8 将两个方向合并为一个硬件感知数据流阶段：

1. 重新对齐残差 Add 输入 scale，使用 Gemmini shared-scale resadd；
2. 将 Concat 融入后续 `1x1 Conv`，通过 split-K 保留 int32 accumulator。

由于共享 scale 会改变 QDQ 边界，Stage 8 不再直接以 Stage 7E 旧模型作为 bit-exact 目标，而是建立新的 hardware-aware integer reference。

## Stage 8A：共享 scale 和新 reference

最终流程使用 COCO128 全部 128 张图片校准：

- activation：per-tensor signed int8；
- weight：per-tensor signed int8；
- zero point：0；
- 7 个 feature-map Add 按拓扑顺序选择 shared scale；
- 受影响 Conv bias、bias scale、输出 requant、SiLU LUT 全部重算。

主要文件：

- `scripts/yolov5nu_stage8a_shared_scale.py`
- `scripts/yolov5nu_stage8_all_shared_adds.py`
- `scripts/yolov5nu_stage8_hardware_aware.py`

模型和 reference：

- `generators/gemmini/software/gemmini-ort/models/detection/stage8_hardware_aware/`
- `hardware_integer_reference.json`
- `hardware_integer_reference.npz`
- `hardware_aware_quantization_audit.json`

标准 ORT graph reference 保留用于准确率比较，FPGA bit-exact qualification 使用 hardware-aware integer reference。

## Stage 8B：Gemmini shared resadd

共享输入 scale 后，Gemmini 可以使用：

```text
mvin scale = 1
store scale = shared_scale / add_output_scale
```

目标语义：

```text
Q((A+B) * shared_scale / add_output_scale)
```

最终共有 7 个 Gemmini shared-scale Add。Add 本身相对 RVV 约快 5.3x，但 early candidate 的后续 Concat requant 仍然占用明显开销。

## Stage 8C：Concat-Conv split-K

Concat 后续全部为 `1x1 Conv`，因此不再物化 Concat tensor：

```text
slice 0 -> Conv partial-K 0
slice 1 -> Conv partial-K 1
              -> 同一个 int32 accumulator
              -> final requant + SiLU + mvout
```

原则：

- bias 只加入一次；
- 中间 partial 保持 int32；
- 中间不 requant、不截断、不执行 SiLU；
- 最后一片才执行 requant、SiLU 和 mvout；
- mvin scale 负责 slice 到 Conv 输入 scale 的 requant。

初始层：`/model.2/Concat -> /model.2/cv3/conv/Conv`。

随后扩展到：

- `/model.4/6/8/Concat -> cv3/conv/Conv`
- `/model.9/Concat` 四片 SPPF split-K
- `/model.13/17/20/23/Concat` 五个单消费者节点

## Stage 8D：双消费者 Concat

四个双消费者 Concat：

```text
/model.12 -> /model.13/cv1, cv2
/model.16 -> /model.17/cv1, cv2
/model.19 -> /model.20/cv1, cv2
/model.22 -> /model.23/cv1, cv2
```

共 8 条 consumer edge。两个 consumer 分别维护自己的 accumulator、bias 和输出，输入 slice 仍来自 producer tensor。每个 partial 边界保留 `gemmini_fence()`。

最终全消费者路径：

```text
7 个 shared Gemmini Add
17 条 split-K Conv edge
13 个 inactive Concat
arena = 739,200 bytes
```

## Stage 8E：硬件感知准入

主机端验证：

- 7 个 Add：`458,752` 组输入；
- 76 个 Conv QDQ；
- 69 张 SiLU LUT：`17,664` 项；
- 17 条 split-K consumer edge；
- slice requant；
- int32 accumulator；
- materialized Conv vs split-K Conv；
- materialized SiLU vs split-K SiLU。

五图使用 `025/036/142/404/650`，与最新 hardware-aware integer reference 逐项比较通过。

## Stage 8F：双消费者 Scratchpad reuse

四组双消费者输入 slice 复用 A-side Scratchpad：

```text
slice 0 -> Scratchpad partition 1
slice 1 -> Scratchpad partition 2
```

第一个 consumer 从 DDR mvin；第二个 consumer 通过 NULL A-side DDR pointer 直接复用 Scratchpad slice。B-side 权重和 accumulator 仍独立，不共享 accumulator 状态。

contract：

```text
shared Add：7
split-K edge：17
reuse group：4
inactive Concat：13
direct Concat：0
arena：739,200 bytes
```

五图 Spike 和 FPGA 双跑全部 bit-exact。平均：

```text
End-to-end：约 6,123,155 cycles
吞吐率：约 8.166 FPS @ 50 MHz
```

Stage 8F 相比全消费者 Stage 8C baseline 约减少 `0.45%`，冻结为 Stage 8 最终 bit-exact baseline。

## Stage 8G：放弃的 mvout_spad 链路

尝试将 Add accumulator 直接连接到后续 Conv 的 `mvout_spad`，理论收益约 `0.1%~0.5%`。但单次 mvout 无法同时保持 Add output scale 和 Concat scale 的两阶段 RNE/int8 舍入，因此放弃。

## Stage 8H：未晋级的 config/fence 合并

对 `/model.9/Concat` 四片 split-K，在 scale/stride 不变时复用 config 并删除中间 fence，scale 改变前仍保留 fence，最终 fence 保留。

局部 `/model.9/cv2/conv/Conv` 减少约 `3,397 cycles`，但端到端比 Stage 8F 高约 `0.02%`，因此不替代 Stage 8F。

## 涉及文件

- `generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`
- `scripts/yolov5nu_stage8a_shared_scale.py`
- `scripts/yolov5nu_stage8_all_shared_adds.py`
- `scripts/yolov5nu_stage8b_shared_resadd.py`
- `scripts/yolov5nu_stage8c_model2_splitk.py`
- `scripts/yolov5nu_stage8c_backbone_splitk.py`
- `scripts/yolov5nu_stage8c_single_consumer_splitk.py`
- `scripts/yolov5nu_stage8f_spad_reuse.py`
- `scripts/yolov5nu_stage8h_splitk_config_fence.py`

## 结论

Stage 8F 是当前 Stage 8 最终 baseline。Stage 9 Conv tile 调优暂缓，未来必须从 Stage 8F 重新建立独立候选，保持量化、split-K、fence 和 arena 语义不变。

