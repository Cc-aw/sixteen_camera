# AI Hardware Postprocessor Architecture
## TinyYOLOv2 / YOLOv5 可扩展专用 Decode 前端与硬件后处理器架构文档

**版本**：v1.0

**目标平台**：当前 Gemmini SoC / FPGA 平台

**目标模型**：TinyYOLOv2 首发支持，接口兼容后续 YOLOv5

**工作频率基线**：100 MHz
**最终系统目标**：面向多 Gemmini、多视频流的异步硬件后处理

---

# 1. 文档目标

本文定义一个独立的 **AI Hardware Postprocessor**，用于从 Gemmini 产生的最终检测头原始张量中完成：

- Tensor 读取；
- 模型专用 Decode；
- 置信度计算与阈值过滤；
- Top-K 候选筛选；
- 确定性排序；
- Class-aware NMS；
- 最终检测结果缓存与 MMIO 导出。

该模块第一阶段支持 **TinyYOLOv2**，但从接口、descriptor、内部 Candidate Stream 和配置机制上避免硬编码为单一模型，以便后续增加 **YOLOv5 前端**而不修改共享的 Top-K、Sort、NMS、Result ABI。

设计目标不是实现一个仅适配当前 dog 测试或 TinyYOLOv2 的临时模块，而是形成 SoC 内长期可复用的：

> **Tensor → Detection Result 硬件后处理流水线。**

---

# 2. 设计目标

## 2.1 功能目标

第一阶段：

- 支持 TinyYOLOv2：
  - 13×13×5 anchors；
  - 25 attributes / anchor；
  - INT8 NHWC；
  - 20 classes。
- 完成定点 Decode；
- 完成阈值过滤；
- 保留最高 256 个候选；
- 执行 class-aware NMS；
- 最多输出 32 个检测结果；
- CPU 不再执行 Decode / Top-K / NMS。

第二阶段：

- 增加 YOLOv5 当前项目输出合同；
- 支持：
  - 84 × 6300；
  - Q16.16；
  - channel-major；
  - anchor-major；
  - 640×480 输入；
  - 80 classes。

## 2.2 架构目标

- 后处理器独立于 Gemmini；
- 通过 FBus Read 读取最终 tensor；
- 与现有 preprocess FBus Write 通道级解耦；
- 使用独立 AXI-Lite MMIO 区域；
- 支持 descriptor FIFO；
- 支持 result FIFO / result slot；
- 保留 done_irq 输出；
- 当前系统第一版使用轮询；
- 支持 frame/job/stream/config 标识；
- 支持未来多 Gemmini 并发提交；
- 支持未来双输出 buffer，使 Gemmini compute 与 postprocess 重叠。

## 2.3 性能目标

TinyYOLOv2：

- 目标后处理 latency：**< 1 ms**；
- 推荐争取：0.3–0.8 ms；
- 不要求大规模并行。

YOLOv5：

- 功能版允许先以 1 lane 实现；
- 最终面向 16×30 FPS 时：
  - 系统总吞吐 = 480 frame/s；
  - 单实例后处理器应满足：

\[
II < \frac{1}{480} \approx 2.083\text{ ms/frame}
\]

最终目标：

> **YOLOv5 sustained initiation interval < 2 ms/frame**

而不是仅要求单帧 latency < 5–8 ms。

---

# 3. 系统总体架构

```text
Gemmini0 / Gemmini1 / Gemmini2
              │
              │ raw output tensor in memory
              ▼
      Coherent FBus Read
              │
              ▼
┌──────────────────────────────────────────────────────────────┐
│                  AI Hardware Postprocessor                   │
│                                                              │
│  Descriptor FIFO                                             │
│         │                                                    │
│         ▼                                                    │
│  Scheduler / Config Loader                                   │
│         │                                                    │
│         ▼                                                    │
│  Multi-Outstanding FBus / AXI Burst Reader                   │
│         │                                                    │
│         ▼                                                    │
│  Layout Unpacker                                             │
│         │                                                    │
│    ┌────┴───────────────┬────────────────────────────┐       │
│    │                    │                            │       │
│    ▼                    ▼                            ▼       │
│ YOLOv2 Decoder   YOLOv5 Channel-major      YOLOv5 Anchor-   │
│                  Frontend                    major Frontend   │
│                         │                            │       │
│                  4-bank Best RAM                     │       │
│    └────────────────────┴──────────────┬─────────────┘       │
│                                       ▼                     │
│                         Unified Candidate Stream             │
│                                       │                     │
│                                       ▼                     │
│                              Threshold Filter                │
│                                       │                     │
│                                       ▼                     │
│                                Top-256 Retain                │
│                                       │                     │
│                                       ▼                     │
│                          Deterministic Descending Sort        │
│                                       │                     │
│                                       ▼                     │
│                              Class-aware NMS                 │
│                                       │                     │
│                                       ▼                     │
│                                  Result RAM                  │
│                                       │                     │
│                                  Result FIFO                 │
└──────────────────────────────────────────────────────────────┘
              │
              │ MMIO
              ▼
      Result Manager
              │
              ▼
  Source Coordinate Mapping
              │
              ▼
           Overlay
```

---

# 4. CPU 与硬件职责划分

## 4.1 CPU 负责

CPU 仅负责：

1. Gemmini 推理任务调度；
2. 等待网络计算完成；
3. 获取最终 tensor 地址；
4. 提交 Postprocessor descriptor；
5. 轮询完成状态；
6. 读取最终最多 32 个检测结果；
7. 执行：
   - stale result 检查；
   - frame/job/version 管理；
   - 原图坐标映射；
   - overlay 调度；
   - 结果发布。

## 4.2 硬件负责

Postprocessor 负责：

- Tensor burst read；
- Tensor layout 解析；
- TinyYOLOv2 Decode；
- YOLOv5 Decode；
- sigmoid / exp / reciprocal 等定点函数；
- class reduction；
- objectness / class probability / score；
- network-input 坐标生成；
- 阈值过滤；
- Top-K；
- Sort；
- Class-aware NMS；
- 最终结果缓存。

生产路径不再依赖 CPU/RVV 执行 Decode 与 NMS。

---

# 5. 存储访问架构

# 5.1 FBus Read

采用：

```text
FBus Write : preprocess 独占
FBus Read  : postprocessor 独占
```

原因：

- 当前 preprocess 已使用 FBus Write；
- FBus Read 当前为空闲资源；
- 不需要增加 MIG S03；
- 避免使用非一致性的 S02 读取 Gemmini 输出；
- 便于复用现有互连与地址空间。

但必须注意：

> AXI Read/Write 通道逻辑独立，不代表底层 DDR 资源完全独立。

两者仍可能共享：

- AXI bridge；
- interconnect；
- DDR controller；
- MIG；
- DDR bank；
- command queue。

因此必须进行并发压力测试。

---

# 5.2 Producer → Consumer Ordering

必须明确 Gemmini 输出完成到 Postprocessor 读取之间的 memory ordering。

推荐软件序列：

```text
Gemmini compute
     ↓
Gemmini Store DMA complete
     ↓
memory visibility established
     ↓
release / fence
     ↓
write postprocess descriptor
     ↓
doorbell
     ↓
Postprocessor read tensor
```

不能仅仅依赖：

```c
gemmini_done();
postprocess_doorbell = 1;
```

而假设所有 store 已对其他 master 可见。

对应结果返回方向：

```text
Postprocessor Result RAM write
     ↓
result commit
     ↓
done status visible
     ↓
CPU observes done
     ↓
CPU reads results
```

---

# 5.3 AXI Reader

## P1 功能版本

最小版本允许：

```text
1 AR request
→ wait complete R burst
→ next AR request
```

仅用于 CRC 与协议正确性验证。

## Production 版本

建议支持：

- 4–8 outstanding bursts；
- 后续根据实测扩展到 8–16；
- 支持 backpressure；
- 支持 RRESP error；
- 支持地址跨 cache line；
- 支持合法拆分 4 KiB 边界；
- 支持 33-bit physical address；
- 支持 burst length 参数化。

建议模块：

```text
Burst Generator
      │
      ├── AR0
      ├── AR1
      ├── AR2
      ├── AR3
      ▼
Outstanding Tracker
      ▼
AXI R Stream
      ▼
Unpacker
```

---

# 6. FBus 验证 Gate

在 Decode RTL 开发前，必须先完成 FBus coherent-read 诊断。

# 6.1 基础 CRC 测试

测试：

```text
CPU / Gemmini produce tensor
       ↓
Postprocessor AXI Read
       ↓
bytes / sum / nonzero / hash / CRC
       ↓
CPU reference
```

验收：

> 连续多次运行，RTL 与 CPU hash/CRC 完全一致。

---

# 6.2 必测 Case

| Case | 要求 |
|---|---|
| CPU 写 DDR → PP 读 | 必须 |
| Gemmini 写 DDR → PP 读 | 必须 |
| 连续运行 1000+ 次 | 必须 |
| 非 cache-line 对齐起始地址 | 必须 |
| burst 跨 cache line | 必须 |
| burst 靠近 4 KiB 边界 | 必须 |
| >4 GiB / 33-bit address | 必须 |
| AXI RRESP error 注入 | 推荐 |
| AXI backpressure | 必须 |
| preprocess 同时写 FBus | 必须 |
| Gemmini DMA 同时工作 | 必须 |

---

# 6.3 并发压力测试

必须测试：

```text
16 路 preprocess 持续写
          +
Gemmini 持续 DMA
          +
Postprocessor 持续 read
```

采集：

- bytes_read；
- average read bandwidth；
- AR stall cycles；
- R stall cycles；
- burst efficiency；
- timeout；
- AXI error；
- CRC mismatch。

---

# 6.4 YOLOv5 带宽 Gate

当前 YOLOv5 tensor：

\[
84 \times 6300 \times 4 = 2,116,800\text{ bytes}
\]

约：

> 2.02 MiB / frame

若最终系统目标：

\[
16 \times 30 = 480 FPS
\]

仅 Postprocessor tensor read 带宽需求约：

\[
2.1168MB \times 480 \approx 1.016GB/s
\]

因此生产版本建议要求：

> **Sustained FBus Read ≥ 1.2 GB/s**

以留出 burst、仲裁、refresh 和其他 DDR traffic 余量。

若 FBus 为：

- 64-bit @100 MHz：理论 0.8 GB/s，无法达到最终目标；
- 128-bit @100 MHz：理论 1.6 GB/s，需要较高有效率；
- 256-bit @100 MHz：理论 3.2 GB/s，余量充足。

---

# 7. 独立 MMIO 区域

推荐使用当前空闲 64 KiB 外设窗口：

```text
CPU address     : 0x1017_0000
canonical addr  : 0x4013_0000
size            : 64 KiB
```

需要扩展：

```text
rtl/bus/video_peripheral_fabric.sv
```

增加：

```text
postprocess_axil
```

独立 target。

不要继续将大量寄存器放入 framebuffer controller。

---

# 8. 建议寄存器布局

| Offset | Function |
|---:|---|
| 0x000 | ID / version |
| 0x004 | capability |
| 0x008 | control |
| 0x00C | status |
| 0x010–0x05C | descriptor staging |
| 0x060 | descriptor doorbell |
| 0x064 | descriptor FIFO status |
| 0x068 | result FIFO status |
| 0x06C | error code |
| 0x070 | irq status / mask |
| 0x080–0x0BC | current result metadata |
| 0x100–0x1FF | performance counters |
| 0x400–0x7FF | config / LUT / anchor access |
| 0x800–0x9FF | result RAM window |

---

# 9. Descriptor ABI

推荐 descriptor 从一开始按模型合同设计，而不是 TinyYOLOv2 专用寄存器。

示例：

```c
struct PostprocessDesc {
    uint64_t tensor_addr;

    uint32_t frame_id;
    uint32_t job_id;

    uint16_t stream_id;
    uint16_t worker_id;

    uint16_t model_config_id;

    uint16_t width;
    uint16_t height;
    uint16_t channels;
    uint16_t anchors;

    uint8_t dtype;
    uint8_t layout;
    uint8_t decoder_type;
    uint8_t flags;

    int32_t quant_scale;
    int32_t zero_point;

    uint16_t score_threshold_q15;
    uint16_t nms_threshold_q15;

    uint16_t input_w;
    uint16_t input_h;

    uint32_t tensor_bytes;
};
```

实际硬件 ABI 必须固定每个字段：

- offset；
- bit width；
- signedness；
- endian；
- alignment。

---

# 10. Config Slot

不建议每帧 descriptor 携带全部 anchor / scale / LUT。

使用：

```text
model_config_id
       ↓
Config Slot RAM
```

例如：

```text
slot0 = TinyYOLOv2
slot1 = YOLOv5-current
slot2 = future model
slot3 = debug
```

CPU 在初始化时配置一次。

每帧 descriptor 只引用 config ID。

---

# 11. Config 原子更新

禁止 CPU 在 Postprocessor 使用某组参数时直接修改 active anchor/LUT。

使用：

```text
Config Shadow
      ↓
CONFIG_COMMIT
      ↓
Active Config
```

或直接使用 immutable config slots。

descriptor 提交后，该 job 使用的 config 内容必须在整个处理期间保持不变。

---

# 12. Unified Candidate ABI

两个 Decoder 最终都输出统一 Candidate Stream。

逻辑定义：

```c
struct HwCandidateLogical {
    uint16_t x_min;
    uint16_t y_min;
    uint16_t x_max;
    uint16_t y_max;
    uint16_t score_q15;
    uint8_t  class_id;
    uint16_t original_index;
};
```

但 RTL ABI 不直接依赖 C struct padding。

建议定义固定 16-byte wire format：

```text
WORD0
[31:16] y_min
[15:0 ] x_min

WORD1
[31:16] y_max
[15:0 ] x_max

WORD2
[31:24] flags
[23:16] class_id
[15:0 ] score_q15

WORD3
[31:16] reserved
[15:0 ] original_index
```

软件驱动将 wire ABI 转换为当前 `AiDetection`。

---

# 13. Candidate Stream 接口

建议 Decode frontend 与共享后端之间采用 ready/valid 流接口：

```text
candidate_valid
candidate_ready

candidate_x_min
candidate_y_min
candidate_x_max
candidate_y_max
candidate_score_q15
candidate_class_id
candidate_original_index

candidate_frame_start
candidate_frame_end
```

这样：

- TinyYOLOv2 Decoder；
- YOLOv5 channel-major；
- YOLOv5 anchor-major；

都可以复用：

```text
Threshold
→ Top-K
→ Sort
→ NMS
→ Result
```

---

# 14. TinyYOLOv2 Tensor Contract

当前 TinyYOLOv2 输出：

```text
13 × 13 × 5 × 25
INT8
NHWC
```

总元素：

\[
13\times13\times5\times25 = 21125
\]

总大小：

> 21,125 bytes

每个 anchor：

```text
tx
ty
tw
th
objectness
class0
...
class19
```

P0 必须冻结：

- INT8 scale；
- zero point；
- attribute 顺序；
- anchor 顺序；
- grid 顺序；
- NHWC physical layout；
- anchor width/height；
- sigmoid 定义；
- exp 定义；
- softmax 定义；
- rounding；
- saturation；
- threshold 判定是否包含等号；
- bbox clipping。

---

# 15. TinyYOLOv2 Decode Pipeline

每个 anchor 执行：

```text
Read 25 × INT8
      │
      ├─ bbox attrs
      │
      ├─ objectness
      │
      └─ 20 class logits
             │
             ▼
         Find Max Class
             │
             ▼
        exp(logit-best)
             │
             ▼
             Sum
             │
             ▼
        Reciprocal / LUT
             │
             ▼
      Best Class Probability
             │
             ▼
 objectness × class_probability
             │
             ▼
          score_q15
             │
        threshold filter
             │
             ▼
       bbox transform
             │
             ▼
         unified candidate
```

---

# 16. TinyYOLOv2 Softmax

不能只实现：

```text
exp(logit-best)
```

完整公式：

\[
P(best)=
\frac{e^{x_{best}-x_{best}}}
{\sum_i e^{x_i-x_{best}}}
\]

因此需要：

```text
20 logits
    ↓
find max
    ↓
20 × exp(logit-best)
    ↓
sum
    ↓
1 / sum
    ↓
best class probability
```

不使用通用除法器。

推荐：

- exp LUT；
- normalization；
- reciprocal LUT；
- 必要时增加一次小规模定点修正。

---

# 17. exp LUT Index

因为：

```text
logit : INT8
best  : INT8
```

其差值范围不是 INT8。

定义：

```text
diff = best - logit
```

则：

```text
diff ∈ [0, 255]
```

因此 256-entry LUT 合理：

```text
exp_lut[diff]
```

若量化：

\[
real = scale \times (q-zero\_point)
\]

则 LUT 表示：

\[
e^{-scale\times diff}
\]

因此：

> Tensor scale 是模型 ABI，而不是纯软件内部参数。

---

# 18. TinyYOLOv2 bbox

硬件负责：

```text
tx,ty,tw,th
      ↓
sigmoid / exp
      ↓
grid + anchor
      ↓
cxcywh
      ↓
xyxy
      ↓
clip to network input
```

输出坐标仍是：

> **network-input coordinate**

例如 TinyYOLOv2：

```text
0..415
```

原始摄像头坐标、resize/crop/letterbox 逆变换继续由 Result Manager 完成。

---

# 19. TinyYOLOv2 性能估计

845 anchors：

\[
13\times13\times5=845
\]

类别比较：

\[
845\times20=16900
\]

若：

```text
1 class / cycle
100 MHz
```

则 class reduction：

\[
16900 / 100M \approx 0.169ms
\]

因此 TinyYOLOv2：

> < 1 ms 非常现实。

不建议为 TinyYOLOv2 单独增加大量并行 DSP。

---

# 20. YOLOv5 Tensor Contract

当前项目计划支持：

```text
84 channels × 6300 anchors
Q16.16
640×480
80 classes
```

必须特别注意：

```text
84 = 4 + 80
```

这不是传统 YOLOv5 raw head 常见的：

```text
4 + 1 + 80 = 85
```

因此 P0 必须明确当前 84-channel tensor 的真实语义。

必须冻结：

```text
channel0 = ?
channel1 = ?
channel2 = ?
channel3 = ?

channel4..83 = ?
```

还必须明确：

- bbox 是 cxcywh 还是 xyxy；
- bbox 是否已经 decode；
- 坐标是 pixel / normalized / grid；
- class 是 logits / sigmoid output / probability；
- objectness 是否已融合；
- anchor 是否已应用；
- stride 是否已应用；
- 是否经过 DFL 或其他转换；
- Q16.16 的 saturation/rounding；
- channel-major / anchor-major 具体 physical stride。

---

# 21. 6300 的结构

对 640×480，三层 feature map：

```text
80×60 = 4800
40×30 = 1200
20×15 = 300
```

总计：

\[
4800+1200+300=6300
\]

说明当前合同更像：

> 每个 spatial point 一个 prediction entry

而不是传统 anchor-based 输出。

因此内部前端建议使用：

```text
YOLO84x6300Frontend
```

或：

```text
DecodeFrontendV5Contract0
```

避免把所有未来 YOLOv5 export 都误认为同一种 tensor contract。

---

# 22. YOLOv5 Channel-Major

布局：

```text
channel0:
  anchor0
  anchor1
  ...
  anchor6299

channel1:
  anchor0
  ...
```

若按 anchor 读取所有 80 classes，会产生 6300 stride 的跨平面访问，DDR 效率低。

因此采用：

```text
Class Plane Sequential Burst
          │
          ▼
    best_score[6300]
    best_class[6300]
          │
          ▼
    coordinate planes
          │
          ▼
    unified candidate
```

---

# 23. YOLOv5 Best-Class RAM

每个 anchor 保存：

```text
best_score
best_class
valid
```

若：

```text
score  = 32 bit
class  = 7 bit
valid  = 1 bit
```

约：

\[
6300\times40 = 252000bit
\]

即约：

> 31 KiB

资源可接受。

---

# 24. YOLOv5 4-Lane SIMD Frontend

若 FBus 为 128-bit，Q16.16 每个 score 为 32-bit：

```text
128-bit RDATA
       │
       ├── score0
       ├── score1
       ├── score2
       └── score3
```

推荐：

> 4 scores / cycle

结构：

```text
          128-bit AXI RDATA
                 │
       ┌─────────┼─────────┐
       ▼         ▼         ▼
     score0    score1   score2/3
       │         │         │
      CMP       CMP       CMP
       │         │         │
      RAM0      RAM1      RAM2/3
```

---

# 25. YOLOv5 Best RAM Banking

为了支持 4 updates / cycle，Best RAM 从一开始按 bank 组织。

定义：

```text
bank = anchor_index % 4
```

例如：

```text
anchor0 → bank0
anchor1 → bank1
anchor2 → bank2
anchor3 → bank3
anchor4 → bank0
...
```

每个 128-bit beat：

```text
4 reads
4 compares
4 writes
```

避免 comparator 并行后被单 BRAM 端口重新限速。

---

# 26. YOLOv5 性能估算

Class comparison 数：

\[
80\times6300=504000
\]

## 1 lane

\[
504000 / 100M = 5.04ms
\]

无法满足 480 FPS 单实例吞吐。

## 4 lane

\[
504000 / 4 / 100M = 1.26ms
\]

因此 Production 版本至少推荐：

> **4-lane class reducer**

并使 class reduction 与 AXI streaming 尽可能重叠。

---

# 27. YOLOv5 Anchor-Major

Anchor-major：

```text
anchor0:
  x y w h class0 ... class79
anchor1:
  ...
```

此时一个 anchor 的信息连续。

因此无需 6300-entry Best RAM。

路径：

```text
burst one or multiple anchors
        ↓
stream class reduction
        ↓
bbox
        ↓
candidate
```

建议两个 layout 使用不同微架构：

```text
                    ┌─ Channel-major → Best RAM ──┐
Layout Unpacker ────┤                             ├→ Candidate
                    └─ Anchor-major Stream ───────┘
```

而不是强迫两个 layout 共享同一数据访问方式。

---

# 28. Threshold Filter

Threshold 必须定义：

- Q 格式；
- inclusive / exclusive；
- saturation；
- invalid candidate 行为。

推荐：

```text
keep if score_q15 >= threshold_q15
```

一旦定义后，Fixed C 与 RTL 必须完全一致。

低于阈值的 candidate 尽早丢弃，以降低后端压力。

---

# 29. Top-K

默认：

```text
K = 256
```

使用 BRAM 保存 candidate。

维护最低 score entry，推荐最小堆。

关键点：

> Top-K 只负责保留最高 256 个，不保证最终按 score 有序。

---

# 30. Candidate 排序

Top-K 后必须执行：

> **Deterministic Descending Sort**

不能直接将 min-heap 内容送入 NMS。

建议统一比较 key：

```text
Primary   : score DESC
Secondary : class_id ASC
Tertiary  : original_index ASC
```

不用再比较 coordinate。

这样：

- heap；
- sort；
- regression；
- NMS；

全部使用统一 comparator。

---

# 31. Class-Aware NMS

最多输入：

```text
256 candidates
```

最多输出：

```text
32 detections
```

同 class 才做 suppress。

计算：

```text
intersection
union
```

不使用除法：

\[
intersection \times 32768
\ge
union \times nms\_iou\_q15
\]

若满足，则认为 IoU 达到阈值。

---

# 32. NMS 位宽

若坐标为 uint16：

```text
width  : 16-bit
height : 16-bit
area   : up to ~32-bit
union  : up to ~33-bit
```

NMS compare：

```text
union × threshold_q15
```

可能需要约 49 bit。

SystemVerilog 中必须显式规定：

- signedness；
- multiply operand width；
- result width；
- zero extension。

不能依赖 implicit expression width。

---

# 33. NMS 性能

最坏比较量：

\[
256\times32=8192
\]

100 MHz：

若 1 comparison / cycle：

\[
8192/100M \approx 82\mu s
\]

即使每次比较 3–4 cycle：

> 仍远低于 0.5 ms。

因此：

> NMS 不需要大规模并行阵列。

推荐顺序复用少量 DSP。

---

# 34. Result RAM

建议直接映射 result window，而不是使用：

```text
write detection index
read x
read y
read score
...
```

推荐：

```text
0x800 result[0].word0
0x804 result[0].word1
0x808 result[0].word2
0x80C result[0].word3

0x810 result[1].word0
...
```

32 detection：

```text
32 × 16 bytes = 512 bytes
```

占用很小。

---

# 35. Result Metadata

每个结果集必须带：

```text
frame_id
job_id
stream_id
worker_id
model_config_id
result_count
status
error_code
tensor_addr_tag / optional
```

用于：

- stale result check；
- 多 worker 乱序完成；
- 多视频流；
- overlay 防止旧结果回滚；
- 调试。

---

# 36. Descriptor FIFO / Result FIFO

第一版就建议支持：

```text
Descriptor FIFO depth = 4~8
Result FIFO / slots   = 4~8
```

不能只设计：

```text
busy
+
current job
```

否则多个 Gemmini 完成时间接近时，会把 Postprocessor 重新变成同步瓶颈。

---

# 37. Output Buffer Ownership

TinyYOLOv2 第一版：

```text
Gemmini finishes
       ↓
worker output buffer locked
       ↓
Postprocessor consumes
       ↓
result done
       ↓
worker buffer released
```

这种方式适合最初调试。

因为 TinyYOLOv2 后处理预计 <1 ms，相对 Gemmini 推理较短。

---

# 38. Double Buffer

YOLOv5 阶段将双输出 buffer 升级为正式需求：

```text
Gemmini worker:

Buffer A → compute N+1
Buffer B → postprocess N
```

最终：

```text
Compute frame N+1
      ||
Postprocess frame N
```

否则 YOLOv5 postprocess latency 会直接反压 Gemmini。

---

# 39. 坐标职责划分

必须区分两种坐标转换。

## Postprocessor 负责

```text
tensor representation
      ↓
cxcywh / raw attrs
      ↓
xyxy
      ↓
network-input coordinate
```

例如：

TinyYOLOv2：

```text
0..415
```

YOLOv5：

```text
0..639
0..479
```

## Result Manager 负责

```text
network-input coordinate
      ↓
inverse resize
inverse crop
inverse letterbox
      ↓
source camera coordinate
      ↓
overlay coordinate
```

禁止两个模块都执行同一层 scale。

---

# 40. Fixed-Point Golden Reference

旧浮点代码不再是 RTL bit-exact reference。

正确 reference chain：

```text
Existing Float Implementation
            │
            │ semantic validation
            ▼
Fixed-Point C Golden Model
            │
            │ bit exact
            ▼
RTL
```

第一层：

> RTL == Fixed C，逐 bit 一致。

第二层：

> Fixed C 与原 Float 结果语义一致。

允许 Float 与 Fixed 在 score/box 存在定义好的量化误差。

---

# 41. P0 必须冻结的数学规则

所有数学行为必须在 C reference 中确定，RTL 不得自行决定。

包括：

- Q format；
- signedness；
- round-to-nearest / truncate；
- tie-breaking；
- saturation；
- overflow；
- underflow；
- sigmoid LUT 输入范围；
- exp LUT 输入范围；
- reciprocal；
- softmax；
- bbox rounding；
- clipping；
- threshold `>=` / `>`；
- NMS threshold `>=` / `>`；
- sort tie；
- invalid box；
- zero-area box。

---

# 42. Regression Corpus

不能只使用 dog 图。

至少包括：

## 普通样例

- dog；
- 单目标；
- 多目标；
- 无目标；
- 多类别。

## 边界样例

- >256 候选；
- score = threshold；
- score = threshold ± 1 LSB；
- IoU = NMS threshold；
- 同 class 高重叠；
- 不同 class 高重叠；
- box 越界；
- width = 0；
- height = 0；
- INT8 = -128；
- INT8 = +127；
- exp saturation；
- score 完全相同；
- class 完全相同；
- original_index tie path。

## Synthetic tensor

必须构造人工 tensor 验证：

- 每个 LUT point；
- rounding；
- saturation；
- Top-K cutoff；
- NMS threshold；
- sort stability。

---

# 43. Performance Counters

推荐至少提供：

```text
total_cycles
tensor_read_cycles
decode_cycles
topk_cycles
sort_cycles
nms_cycles

bytes_read
ar_requests
ar_stall_cycles
r_stall_cycles

anchors_seen
candidates_before_threshold
candidates_after_threshold
topk_replacements
nms_compare_count
nms_suppressed_count
result_count

descriptor_fifo_high_watermark
result_fifo_high_watermark

axi_error_count
timeout_count
```

这些 counter 对后续判断瓶颈位置非常关键。

---

# 44. Error Model

建议错误码至少包括：

```text
ERR_NONE

ERR_BAD_DESCRIPTOR
ERR_BAD_CONFIG_ID
ERR_UNSUPPORTED_DTYPE
ERR_UNSUPPORTED_LAYOUT
ERR_ADDRESS_ALIGN
ERR_ADDRESS_RANGE

ERR_AXI_RRESP
ERR_AXI_TIMEOUT
ERR_TENSOR_SIZE

ERR_INTERNAL_FIFO_OVERFLOW
ERR_RESULT_OVERFLOW
ERR_CONFIG_CHANGED

ERR_PROTOCOL
```

错误发生后：

- 当前 job 标记 failed；
- 结果 metadata 保存 error；
- 不影响后续 descriptor；
- 必要时支持 soft reset。

---

# 45. IRQ

虽然当前 SoC 未接外部中断，RTL 仍保留：

```text
done_irq
error_irq
```

第一版软件继续 polling。

未来无需修改后处理器核心即可接入 PLIC / interrupt fabric。

---

# 46. 推荐 RTL 模块拆分

```text
ai_postprocessor_top.sv

postprocess_axil_regs.sv
postprocess_desc_fifo.sv
postprocess_scheduler.sv
postprocess_config_ram.sv

fbus_read_engine.sv
axi_burst_issuer.sv
axi_outstanding_tracker.sv
tensor_unpacker.sv

yolov2_decode_frontend.sv
yolov2_math_lut.sv
fixed_reciprocal.sv

yolov5_channel_frontend.sv
yolov5_anchor_frontend.sv
yolov5_best_ram.sv

candidate_filter.sv
candidate_topk.sv
candidate_sort.sv
candidate_nms.sv

result_ram.sv
result_fifo.sv
postprocess_perf_counter.sv
```

---

# 47. 推荐软件拆分

```text
sw/
├── postprocess/
│   ├── postprocess_hw.h
│   ├── postprocess_hw.c
│   ├── postprocess_desc.h
│   ├── postprocess_result.h
│   ├── postprocess_config.c
│   └── fixed_ref/
│       ├── yolov2_fixed_ref.c
│       ├── yolov5_fixed_ref.c
│       ├── fixed_math.c
│       └── regression_vectors.h
```

TinyYOLOv2 现有代码改造：

```text
tinyyolov2_worker_poll()
      ↓
只完成网络计算
      ↓
暴露 final tensor address
      ↓
ai_batch_runtime
      ↓
submit postprocess descriptor
      ↓
read AiDetectionResult
      ↓
Result Manager
```

---

# 48. 软件 Backend 改造

当前 backend：

```text
AI_TENSOR_DTYPE_CUSTOM
```

应改为返回真实 tensor description。

至少包含：

```text
addr
dtype
shape
layout
scale
zero_point
tensor_bytes
model_contract
```

后处理 runtime 再转换为 PostprocessDesc。

---

# 49. 实施阶段

# P0 — Contract Freeze + Golden Data

任务：

- 导出通过测试的 dog raw tensor；
- 保存当前 CPU Decode 中间 candidate；
- 保存最终 result；
- 建立 fixed-point C reference；
- 冻结：
  - tensor ABI；
  - address；
  - quantization；
  - LUT；
  - rounding；
  - saturation；
  - anchor；
  - result ABI；
  - sort；
  - NMS。

验收：

> 所有数学规则不存在“RTL 自己决定”的情况。

---

# P1A — FBus Basic Reader

任务：

- 实现最小 AXI burst reader；
- 读取 CPU test data；
- 读取 Gemmini tensor；
- 输出：
  - bytes；
  - sum；
  - nonzero；
  - hash/CRC；
- 支持 33-bit address。

验收：

> RTL readback hash 与 CPU reference 完全一致。

---

# P1B — Coherence / Ordering

任务：

- 验证 Gemmini store 完成后数据可见；
- 验证 CPU cache / fence 路径；
- 验证快速 buffer reuse；
- 验证 descriptor doorbell ordering。

验收：

> 连续运行无旧数据、半更新数据和随机 CRC mismatch。

---

# P1C — Concurrent Bandwidth Stress

同时运行：

```text
preprocess write
+
Gemmini DMA
+
Postprocessor read
```

记录：

- sustained GB/s；
- AR stall；
- R stall；
- CRC；
- timeout；
- AXI error。

YOLOv5 Gate：

> 建议 sustained FBus read ≥ 1.2 GB/s。

---

# P2 — TinyYOLOv2 Decode

实现：

- 25-byte anchor loader；
- sigmoid LUT；
- exp LUT；
- softmax accumulator；
- reciprocal；
- objectness；
- class probability；
- score；
- bbox；
- threshold；
- Candidate Stream。

暂时可以不做 Top-K/NMS。

验收：

> 845 anchors 的中间结果与 Fixed C reference 逐项 bit-exact。

---

# P3 — Top-K + Sort + NMS

实现：

- Top-256 retain；
- deterministic descending sort；
- class-aware NMS；
- max 32 result；
- Result RAM。

验收：

dog：

```text
dog
car
bicycle
```

类别、bbox、score 按 Fixed C reference 一致。

同时全部 synthetic regression 通过。

---

# P4 — Runtime Integration

实现：

- descriptor FIFO；
- result FIFO；
- frame/job/stream/worker/config id；
- worker buffer ownership；
- stale result check；
- serial performance log；
- error diagnostic；
- polling interface；
- irq reserve。

验收：

> 16 路持续运行，无 tensor overwrite、无旧 result rollback、无 overlay 异常。

---

# P5A — YOLOv5 Functional Frontend

先实现正确性：

- Q16.16；
- channel-major；
- anchor-major；
- 6300-entry best-class RAM；
- candidate；
- reuse Top-K / Sort / NMS。

第一版允许：

```text
1 score / cycle
```

验收重点：

> 与 Fixed C / 当前 scalar reference 一致。

---

# P5B — YOLOv5 Throughput Frontend

升级：

```text
128-bit FBus
      ↓
4 × Q16.16
      ↓
4-lane compare
      ↓
4-bank Best RAM
```

目标：

> sustained II < 2 ms/frame

并确认：

- FBus sustained bandwidth；
- DDR contention；
- descriptor queue；
- Gemmini + postprocessor overlap。

---

# P6 — Double Buffer / Full Pipeline

在每个 Gemmini worker 上增加双输出 buffer：

```text
compute N+1
||
postprocess N
```

验证：

- 无 buffer reuse race；
- 无旧 tensor；
- worker 可以乱序完成；
- PP queue 不反压 Gemmini。

---

# 50. 验收 Gate 汇总

| Phase | Go / No-Go 条件 |
|---|---|
| P0 | Fixed C spec 完整，无未定义数学行为 |
| P1A | CPU/Gemmini tensor CRC 100% 一致 |
| P1B | 无 ordering / coherence 随机错误 |
| P1C | 并发压力下带宽满足需求 |
| P2 | Tiny 845 anchor bit-exact |
| P3 | Top-K/Sort/NMS regression 通过 |
| P4 | 16 路 runtime 长时间稳定 |
| P5A | YOLOv5 功能正确 |
| P5B | YOLOv5 II < 2 ms |
| P6 | compute/postprocess 可持续重叠 |

---

# 51. 资源预算

## TinyYOLOv2

主要资源：

- sigmoid LUT；
- exp LUT；
- reciprocal LUT；
- Candidate RAM；
- Top-K；
- Result RAM。

整体资源应较小。

## Candidate RAM

```text
256 × 16 bytes = 4 KiB
```

## YOLOv5 Best RAM

约：

```text
31 KiB
```

## Result RAM

```text
32 × 16 bytes = 512 bytes
```

## DSP

不引入浮点核。

DSP 主要用于：

- bbox multiply；
- score multiply；
- area；
- NMS threshold compare。

推荐：

> 总 DSP 控制在个位数到十几个。

不应设计成几十到上百 DSP 的大规模并行后处理器。

---

# 52. 第一版明确不做

为了控制风险，第一版不做：

- F32 Decode；
- 通用神经网络后处理 ISA；
- 动态任意类别数完全可编程；
- 大规模并行 NMS；
- 多套复杂 sigmoid/exp 算法；
- 片上完整 tensor buffer；
- YOLOv5 全 tensor 拷贝进 BRAM；
- 中断软件链路；
- 一开始就双 buffer；
- 一开始同时开发 TinyYOLOv2 与 YOLOv5。

---

# 53. 关键设计原则

## 53.1 Decoder 可替换

共享边界是：

```text
Model-Specific Tensor
       ↓
Decoder Frontend
       ↓
Unified Candidate Stream
```

模型差异截止在 Candidate Stream 之前。

---

## 53.2 Shared Backend 不感知模型

以下模块不关心 YOLOv2 / YOLOv5：

```text
Threshold
Top-K
Sort
NMS
Result RAM
Result FIFO
```

---

## 53.3 Fixed C 是 RTL Specification

浮点代码用于语义对照。

Fixed C 用于：

> bit-exact specification。

---

## 53.4 Correctness Before Throughput

开发顺序：

```text
正确读 tensor
    ↓
正确 decode
    ↓
正确 Top-K/NMS
    ↓
runtime integration
    ↓
最后增加 lane / outstanding / banking
```

---

## 53.5 吞吐设计看 II，不只看 latency

最终 16×30 FPS 系统必须关注：

> Initiation Interval

而不是“单帧后处理需要几毫秒”。

即使单帧 latency 较高，只要前后阶段可 pipeline 且 II 达标，系统仍然可持续运行。

---

# 54. 最终推荐架构

```text
Gemmini output DDR
       │
       ▼
FBus Multi-Outstanding Reader
       │
       ▼
Layout Unpacker
       │
       ├───────────────┬──────────────────┐
       ▼               ▼                  ▼
TinyYOLOv2       V5 Channel-major    V5 Anchor-major
Decoder          4-lane reducer      Stream reducer
       │               │                  │
       │         4-bank Best RAM           │
       └───────────────┴──────────┬───────┘
                                  ▼
                      Unified Candidate Stream
                                  │
                                  ▼
                           Threshold Filter
                                  │
                                  ▼
                            Top-256 Retain
                                  │
                                  ▼
                       Deterministic Sort
                                  │
                                  ▼
                        Class-aware NMS
                                  │
                                  ▼
                           Result RAM/FIFO
                                  │
                                  ▼
                                MMIO
                                  │
                                  ▼
                         Result Manager
                                  │
                                  ▼
                  Source Coordinate Mapping
                                  │
                                  ▼
                               Overlay
```

---

# 55. 最终结论

该方案具有明确的工程可行性。

TinyYOLOv2 阶段不存在明显架构性障碍，20 KiB 级 tensor、845 anchors 与有限类别数使得 Decode + Top-K + NMS 在 100 MHz 下实现 `<1 ms` 具有较高可行性。

整个项目最大的技术风险不在 sigmoid、NMS 或 Top-K，而在：

1. Gemmini 输出到 FBus Read 的一致性；
2. producer-consumer memory ordering；
3. 并发 preprocess / Gemmini / Postprocessor 下的真实 DDR 带宽；
4. Fixed-point 数学定义是否冻结；
5. YOLOv5 当前 84×6300 tensor contract 是否定义完整；
6. YOLOv5 480 FPS 目标下单实例 Postprocessor 的 throughput 是否达到 `II < 2 ms`。

因此开发顺序必须坚持：

```text
P0 Contract
    ↓
P1 FBus
    ↓
P2 Tiny Decode
    ↓
P3 Top-K + Sort + NMS
    ↓
P4 Runtime
    ↓
P5 YOLOv5
    ↓
P6 Full Pipeline
```

只要 P1 的 coherence、ordering 与 bandwidth Gate 能通过，该模块非常适合作为当前 Gemmini SoC 中长期保留的正式 AI 后处理器，而不是 TinyYOLOv2 的一次性优化模块。
