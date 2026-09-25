# sixteen_camera YOLOv5nu PPU 第二阶段优化实施方案

> 项目：`Cc-aw/sixteen_camera`  
> 目标模块：YOLOv5nu Hardware Postprocessor / PPU1  
> 目标平台：Xilinx Virtex UltraScale+ VU13P，Vivado 2023.2  
> 当前基线：Head URAM-only + Local Reader + Sparse DFL + Top-256 + Class-aware NMS  
> 文档用途：作为后续 PPU 分阶段优化的实施任务书、回归门禁和板测验收依据。  
> 原则：**一次只改变一个主要性能假设；每阶段必须保持 bit-exact、可回滚、可量化。**

---

# 1. 当前生产 PPU 基线

当前生产链已经不是早期“DDR/FBus 全量读取 + CPU 后处理”架构，而是：

```text
Gemmini
   │
   │ final raw heads
   ▼
Head URAM
   │
   ├─ Local Reader（生产默认）
   └─ FBus Reader（诊断 / fallback）
   │
   ▼
YOLOv5nu PPU
   │
   ├─ 3 × Class Head
   │      ↓
   │   Class LUT
   │      ↓
   │   Class Reducer
   │      ↓
   │   Score Histogram
   │
   ├─ Top-256 cutoff selection
   │
   ├─ Sparse DFL reads
   │      ↓
   │   DFL Decoder
   │      ↓
   │   BBox Decoder
   │
   ├─ Top-K / Stable Sort
   │
   ├─ Class-aware NMS
   │
   ▼
Result RAM
   │
   ▼
CPU Result Manager
   │
   ▼
Overlay
```

当前重要事实：

- 输入为 YOLOv5nu 三尺度 raw INT8 Head；
- Class 总位置数为 `6300`；
- 每个位置 Class 数为 `80`；
- Class payload 总计：`6300 × 80 = 504000 B`；
- DFL 每位置 `4 × 16 = 64 B`；
- 当前通过 class score histogram 提前筛选最高 256 个位置，再做 Sparse DFL；
- Head 生产默认存于 URAM；
- PPU production reader 默认使用 `head_local_reader`；
- FBus reader 作为命令级 fallback / diagnostic 保留；
- 当前最终 Result Limit 为 10；
- 当前 score threshold raw 值为 34；
- 当前 NMS IoU threshold 为 0.45；
- 当前候选排序要求：score descending，score 相同时 location ascending；
- 当前 CPU 仍负责 descriptor 提交、任务调度、stale/frame/version 管理和结果发布。

当前板级 Local Reader 验证中，PPU 已达到：

```text
PPU core          ≈ 0.926 ms @100 MHz
postprocess wall  ≈ 3.273 ms @100 MHz
```

因此本轮优化不能只盯 `production_cycles`。

必须把优化目标拆为两个层面：

```text
A. PPU Core Throughput / Latency
B. Gemmini Head Complete → Detection Result Publish Wall Time
```

二者分别验收。

---

# 2. 本轮总体目标

## 2.1 Core 目标

短期目标：

```text
PPU core < 0.60 ms @100 MHz
```

中期目标：

```text
PPU core < 0.35~0.45 ms @100 MHz
```

最终 300 MHz 目标：

```text
PPU sustained II << 2 ms/frame
```

PPU 不应成为 480 FPS 总系统的吞吐瓶颈。

## 2.2 Wall-time 目标

当前：

```text
Gemmini Head 完成
      ↓
大范围 publication/cache flush
      ↓
PPU
      ↓
CPU result read
      ↓
Overlay publish
```

最终应演进为：

```text
Gemmini Head Producer
      ↓
Hardware Head Publication
      ↓
PPU descriptor queue
      ↓
PPU
      ↓
Result FIFO / Result Manager
      ↓
Overlay
```

尽量消除 CPU 大范围 flush、doorbell polling 和逐结果 MMIO 读取造成的串行气泡。

---

# 3. 不可破坏的功能契约

## 3.1 Class 语义

对每个 location：

```text
best_score = max(class[0..79])
best_class = 最早达到 best_score 的 class id
```

即 tie 时保留最低 class id。

阈值：

```text
best_score >= 34
```

才进入候选集合。

## 3.2 Top-256 语义

只允许最高 256 个位置进入 Sparse DFL。

排序规则：

```text
score descending
score 相同时 location ascending
```

优化不能改变第 256 名边界的 tie 行为。

## 3.3 DFL 语义

必须保持当前 bit-exact：

- per-head requant；
- 16-bin exponent LUT；
- max-subtraction softmax；
- probability INT8 quantization；
- nearest-even rounding；
- 16-weight projection；
- 当前 DFL scale；
- 当前 distance saturation。

不允许为了速度直接替换为 float、近似 softmax 或不同 rounding。

## 3.4 BBox 语义

保持：

```text
x0 = (grid_x + 0.5 - left_distance)  × stride
y0 = (grid_y + 0.5 - top_distance)   × stride
x1 = (grid_x + 0.5 + right_distance) × stride
y1 = (grid_y + 0.5 + bottom_distance)× stride
```

输出继续使用 `640×480` model coordinate。clip/round 规则必须保持与当前硬件及 CPU reference 一致。

## 3.5 NMS 语义

必须保持：

```text
class-aware
IoU > 0.45 才 suppress
稳定 score/location 顺序
最多输出当前 RESULT_LIMIT
```

边界必须仍为“strictly greater than 0.45”，不能错误改成 `>= 0.45`。

---

# 4. PPU-P0：先增加性能可观测性

## 4.1 目的

当前只有：

```text
production_cycles
```

无法准确判断下一步优化收益来自：

- Class；
- Head reader；
- cutoff；
- DFL；
- sort；
- NMS；
- result drain。

所以第一阶段先不改算法，先把时间拆开。

## 4.2 新增计数器

建议在 `yolov5nu_postprocessor.sv` 增加：

```text
total_cycles

hist_clear_cycles
class_read_cycles
class_compute_cycles
class_stall_cycles

cutoff_scan_cycles
dfl_select_scan_cycles

dfl_read_cycles
dfl_compute_cycles
dfl_backpressure_cycles

sort_cycles
nms_cycles
result_cycles
```

另外增加：

```text
class_candidates
selected_dfl_candidates
max_selected_dfl_candidates

local_reader_wait_cycles
reader_command_gap_cycles
```

## 4.3 实现原则

计数器不能重新污染 critical path。

建议：

```text
FSM state
   │
   └─ registered phase_event
           │
           ▼
       perf counter
```

而不是让宽计数器 carry chain 参与 FSM decision。

生产版若不需要所有统计，可通过参数控制：

```systemverilog
parameter ENABLE_PERF_COUNTERS = 1;
```

## 4.4 MMIO

建议保留当前 `0x100..0x14c` ABI，向后扩展：

```text
0x150 total cycles
0x154 class read
0x158 class compute
0x15c class stall
0x160 cutoff
0x164 dfl scan
0x168 dfl read
0x16c dfl compute
0x170 sort
0x174 nms
0x178 result
0x17c selected candidate count
```

如果不希望增加生产 CSR，可只在仿真/ILA build 暴露。

## 4.5 P0 验收

必须满足：

```text
bit-exact regression PASS
image025 PASS
random DFL PASS
NMS corpus PASS
PPU total cycles 与旧 production_cycles 一致或仅固定极小偏差
```

P0 只增加可观测性，不追求性能变化。

---

# 5. PPU-P1：Class Reducer 8B → 16B

这是当前最推荐首先实施的真正性能优化。

## 5.1 当前瓶颈

Class 数据：

```text
504000 B
```

Local Reader：

```text
256 bit = 32 B / beat
```

总 beat：

```text
504000 / 32 = 15750 beats
```

当前生产：

```systemverilog
FOLD_BYTES = 8
```

因此每个 AXI/URAM beat 需要：

```text
32 / 8 = 4 cycles
```

纯 reducer 理论约：

```text
15750 × 4 = 63000 cycles
```

它占当前约 92k PPU core cycles 的主要部分。

## 5.2 第一阶段目标

改成：

```systemverilog
FOLD_BYTES = 16
```

即：

```text
32 B beat
  ↓
16 B / cycle
  ↓
2 cycles / beat
```

理论 class fold：

```text
63000 → 31500 cycles
```

## 5.3 RTL 修改

主要文件：

```text
rtl/ai/postprocess/yolov5nu_class_reducer.sv
rtl/ai/postprocess/yolov5nu_postprocessor.sv
```

重点检查：

```text
GROUP_COUNT
GROUP_WIDTH
beat_group
final_group
fold_class_index
fold_best_score
fold_best_class
```

当前 class vector 长 80 B，32 B beat 会跨 location boundary。

必须继续支持：

```text
beat0: location N tail + location N+1 head
```

不能假设 AXI beat 与 80-byte location 对齐。

## 5.4 Comparator 结构

不要形成一条 16-deep comparator chain。

推荐：

```text
lane0..3   → group_max0
lane4..7   → group_max1
lane8..11  → group_max2
lane12..15 → group_max3
               ↓
            pipeline
               ↓
          final group max
```

同时保留最低 class id tie 语义。

第一版如果 100 MHz timing 很宽松，可以先让综合器自动 balance；若未来要 300 MHz，则应显式树化并流水。

## 5.5 验收

功能：

```text
6300 positions exact
best class exact
best score exact
candidate count exact
same cutoff
same DFL locations
same final NMS
```

性能：

```text
class_compute_cycles 至少下降 40%
total PPU cycles 明显下降
```

时序：

```text
100 MHz standalone WNS >= 0
```

不以理论 2× 为强制验收，因为可能受 reader/状态切换影响。

---

# 6. PPU-P1.5：Class Reducer 16B → 32B 全宽流水

只有 P1 已稳定后才进入。

## 6.1 目标

做到：

```text
1 × 256-bit beat / cycle
```

Class 理论：

```text
15750 cycles
```

## 6.2 不允许的实现

禁止：

```text
32 lanes
 ↓
一条超长组合 max chain
 ↓
result
```

这会直接破坏未来 300 MHz。

## 6.3 推荐架构

```text
32 mapped scores
      │
      ├─ 8 lanes → local max A
      ├─ 8 lanes → local max B
      ├─ 8 lanes → local max C
      └─ 8 lanes → local max D
                │
                ▼
             pipeline
                │
                ▼
              merge
```

因为 80-byte location 和 32-byte beat 不整除，必须保存：

```text
partial location accumulator
class_index
```

输出 latency 可以增加，但稳态目标：

```text
II = 1 beat
```

## 6.4 Go / No-Go

只有同时满足：

```text
bit-exact
WNS >= 0
资源增加可接受
total_cycles 比 P1 再明显下降
```

才进入 production。否则保持 16B 版本。

---

# 7. PPU-P2：删除重复 Top-K Heap

这是当前 PPU 最值得做的结构简化之一。

## 7.1 为什么当前 Heap 是重复工作的

当前上游已经完成：

```text
Class reducer
     ↓
score histogram
     ↓
cutoff score
     ↓
只选择最高 256 个 location
     ↓
Sparse DFL
```

因此进入 `yolov5nu_topk_nms` 的 candidate 数：

```text
<= 256
```

但 `yolov5nu_topk_nms` 又执行：

```text
Top-256 heap
 ↓
heap sort
 ↓
NMS
```

既然输入本身已经不超过 256，heap 不再承担“裁掉第 257 个”的作用，它只是用复杂随机访问结构重新排序。

---

# 8. 推荐替换：Score Bucket Stable Sort

## 8.1 Score 范围

有效 raw score：

```text
34..127
```

一共 94 buckets，非常适合 bucket sort。

## 8.2 数据结构

最多 256 candidates。

为每个 candidate 保存：

```text
candidate[127:0]
next[7:0]
```

为每个 score 保存：

```text
head[score]
tail[score]
valid[score]
```

Sparse DFL 当前按 location ascending 扫描。

因此 candidate append 到同一个 score bucket 时，天然得到：

```text
location ascending
```

不需要额外 stable sort。

## 8.3 输出排序

DFL 结束后：

```text
score = 127
while score >= cutoff:
    walk bucket[score]
```

自然得到：

```text
score descending
same score → location ascending
```

完全匹配当前语义。

## 8.4 可删除逻辑

可以删除：

```text
ST_UP
ST_UP_READ
ST_DOWN
ST_DOWN_READ
ST_SORT_SWAP
ST_SORT_DOWN
ST_SORT_DOWN_READ

heap_size
sort_size
hole
parent_entry
left_entry
right_entry
worse_child
```

Top-K/NMS 模块结构大幅简化。

## 8.5 新模块建议

建议新建：

```text
yolov5nu_candidate_buckets.sv
yolov5nu_nms.sv
```

或：

```text
yolov5nu_sorted_candidate_store.sv
yolov5nu_nms.sv
```

不要让旧 `yolov5nu_topk_nms.sv` 同时承担两种完全不同的结构。

## 8.6 P2 验收

必须使用现有 corpus 对比：

```text
candidate order exact
final detections exact
tie score exact
dense candidate case exact
0 candidate case exact
1 candidate case exact
256 candidate case exact
```

同时记录：

```text
LUT
FF
BRAM
cycles
WNS
```

预期：

```text
状态机减少
随机 RAM heap 操作减少
sort cycles 大幅下降
```

---

# 9. PPU-P3：BBox Decoder 为 300 MHz 重构

当前 `yolov5nu_bbox_decoder.sv` 在 100 MHz 可工作，但组合逻辑不适合未来高频。

## 9.1 当前高风险组合

包括：

```text
position % 80
position / 80
position % 40
position / 40
position % 20
position / 20

distance × stride × scale
score × constant
48-bit add/sub/round/clip
```

综合器能对常数除法做 strength reduction，但不能依赖它自动生成未来最优 300 MHz 结构。

---

# 10. 去除 stride multiplier

stride 只有：

```text
8
16
32
```

因此：

```text
value × stride
```

全部改成：

```text
<<3
<<4
<<5
```

不保留通用 multiplier。

---

# 11. DFL distance scale LUT 化

distance：

```text
0..127
```

head：

```text
0..2
```

完全可以预计算：

```text
scaled_offset[head][distance]
```

大小：

```text
3 × 128
```

每项保存当前 box coordinate 所需固定点 offset。

于是：

```text
distance × scale × stride
```

可替换为：

```text
ROM lookup
+
add/sub
```

---

# 12. Score Q15 LUT 化

当前：

```text
score_i8 × SCORE_SCALE_Q31
```

输入只有 256 种。

直接使用：

```text
score_q15_lut[256]
```

保持当前 exact rounding，避免 score multiplier。

---

# 13. Grid 坐标状态化

当前 BBox 根据 absolute `position` 算：

```text
local_position
grid_x
grid_y
```

更高效的方式是让 sparse scan 自身携带：

```text
head
grid_x
grid_y
location
```

DFL candidate 被选中时直接保存这些 metadata。

这样 BBox 不再做 `/80 /40 /20`。

不过这会扩大 class metadata/scan 状态，建议放在 P3 的第二子阶段。

---

# 14. BBox Pipeline

推荐：

```text
Stage 0:
position/head/grid decode

Stage 1:
distance LUT + base coordinate

Stage 2:
x/y add-sub

Stage 3:
round + clip + candidate pack
```

目标：

```text
latency 3~4 cycles
II = 1 candidate
```

---

# 15. PPU-P4：NMS 数据通路优化

NMS 不一定是当前平均热点，但它是未来 dense scene/high candidate count/300 MHz timing 的重要风险。

## 15.1 Area 预计算

当前每次 compare 都重新：

```text
area_a
area_b
intersection
union
```

应在 BBox candidate 生成时预计算：

```text
area = (x2-x1) × (y2-y1)
```

内部 candidate 格式加入 `area`，外部 128-bit result ABI 不变。

## 15.2 IoU 判定化简

原条件：

```text
intersection * 100 > union * 45
```

其中：

```text
union = areaA + areaB - intersection
```

化简：

```text
100I > 45(A+B-I)
145I > 45(A+B)
29I > 9(A+B)
```

因此硬件只需：

```text
intersection = overlap_w × overlap_h
lhs = 29 × intersection
rhs = 9 × (areaA + areaB)
suppress = lhs > rhs
```

常数乘：

```text
29x = 32x - 2x - x
9x  = 8x + x
```

可用 shift/add。

这样每次比较只保留一个真正二维面积 multiplier。

---

# 16. NMS Pipeline

当前：

```text
ST_NMS_SCAN
 ↓
RAM read
 ↓
ST_NMS_EVAL
 ↓
compare
```

至少：

```text
2 cycles / candidate
```

改为流水：

```text
Stage 0:
candidate RAM read

Stage 1:
class match
overlap x/y

Stage 2:
intersection area

Stage 3:
29I vs 9(A+B)

Stage 4:
suppressed writeback
```

虽然 latency 增加，但稳态目标：

```text
II = 1 candidate/cycle
```

---

# 17. PPU-P5：DFL 四边并行

这一阶段主要解决 worst-case candidate 多时的 PPU 延迟。

## 17.1 当前 DFL 结构

一个 location：

```text
4 edges × 16 bins
```

当前 FSM：

```text
MAXIMUM
SUM
DOT_LOAD
DIVIDE
DOT_STORE
```

虽然已经双 bin 并行，但四条 edge 仍共享主要状态机。

典型候选少时影响不大；但 256 candidate worst-case 会显著增长。

---

# 18. 四 Edge 并行架构

按 bin 同步推进四条边：

```text
bin0:
 left / top / right / bottom

bin1:
 left / top / right / bottom
...
bin15
```

硬件：

```text
4 × max accumulator
4 × sum accumulator
4 × dot accumulator
```

LUT/exp 可以：

- 复制 4 份；
- 或 2×2 分两拍；
- 根据资源与 300 MHz timing 选择。

第一版建议真正 4-edge parallel。

## 18.1 预期周期

概念上：

```text
MAX: 64 → 16 cycles
SUM: 64 → 16 cycles
DOT: 约 4× 加速
```

目标：

```text
~400+ cycles/candidate
→
~100 cycles/candidate
```

以实际 RTL perf counter 为准。

---

# 19. DFL Divider 第二阶段

当前 restoring divide 是多拍 bit-serial。

后续可做：

```text
pipelined divider
latency N
II=1
```

允许连续 bin 进入。

这个阶段资源成本比四 edge 并行更大，因此：

```text
先 4-edge
再 divider pipeline
```

不要同时做。

---

# 20. PPU-P6：Head Publication 与 Flush 消除

这是**系统 wall-time 收益最大**、但正确性风险最高的一项。

## 20.1 当前问题

当前 PPU Local Reader 使用 URAM，但软件仍必须：

```text
cache_flush_range(head, 907200 B)
```

因为板测已经证明：

```text
Gemmini fence != Head fully visible to URAM reader
```

因此目前 flush 是正确性边界，不能直接删除。

---

# 21. 正确方向：Hardware Publication Boundary

目标：

```text
Head Slot
FREE
 ↓
WRITING
 ↓
DRAINING
 ↓
READY
 ↓
PPU_READING
 ↓
FREE
```

关键是：

```text
READY
```

只能在所有属于该 Head Slot 的写事务真正达到定义的完成边界之后发布。

## 21.1 必须跟踪

至少：

```text
slot_id
generation/version
write_started
write_last_seen
write_outstanding
write_error
published
```

若写通路经过 AXI：

```text
最后 WLAST 接受
```

不能直接等价于：

```text
Head Ready
```

必须根据当前 AXI router 的 completion 语义确定：

```text
B response / local write completion
```

---

# 22. 更进一步：Per-Head Ready

六个 Head 不一定要一起 READY。

可以：

```text
ready_mask[0] = class0
ready_mask[1] = class1
ready_mask[2] = class2
ready_mask[3] = dfl0
ready_mask[4] = dfl1
ready_mask[5] = dfl2
```

PPU：

```text
Class0 READY → 开始处理 Class0
Class1 READY → 继续
...
```

而 Gemmini 同时继续产生后续 Head。

这样形成 producer/consumer overlap。

---

# 23. Per-Head Ready 的风险

必须保证 PPU 读某 Head 时 producer 不会再写该 Head 的任何 byte。

所以 ready 必须关联：

```text
head index
slot
version
worker
```

不能只是 6-bit 无代次 mask。

推荐逻辑概念：

```text
HeadReadyRecord {
    worker
    slot
    version
    head_id
}
```

至少 software-visible lifecycle 中必须能区分旧任务和新任务。

---

# 24. PPU-P7：Descriptor FIFO

当前：

```text
write START
if !production_busy
    accept
```

本质是单命令接口。

未来多 Gemmini：

```text
Gemmini0 complete
Gemmini1 complete
Gemmini2 complete
```

可能在相近时间产生 Head。

CPU 不应该等待 PPU idle 再逐个提交。

## 24.1 Descriptor

建议：

```text
worker_id
slot_id
stream_id
frame_id
version

class0
class1
class2
dfl0
dfl1
dfl2

flags
```

如果 Head URAM 地址可以完全由：

```text
worker + slot
```

推导，甚至无需六个 33-bit 地址全部放入 descriptor。

## 24.2 FIFO 深度

第一版：

```text
4
```

足够。

未来：

```text
8
```

不建议一开始做过深，因为 PPU throughput 若跟不上，队列越深只会让 result 更 stale。

---

# 25. Descriptor 调度原则

PPU 第一版应遵循：

```text
FIFO order
```

不要在硬件里立刻引入复杂 EDF。

AI runtime 已有 frame freshness 策略；PPU FIFO 只负责消除 CPU submission bubble。

如果 descriptor 到 PPU 时已经 stale，应由 Result Manager 或 descriptor admission 做丢弃，而不是让 NMS 内部感知显示策略。

---

# 26. PPU-P8：Result FIFO / Result Manager

当前结果由 CPU：

```text
poll done
 ↓
write result index
 ↓
read 4 × 32-bit
 ↓
重复
 ↓
overlay
```

这是后处理尾部的软件串行化。

## 26.1 推荐 Result Record

```text
stream_id
frame_id
version
detection_count
status
cycles
```

后接：

```text
Detection[0..N-1]
```

## 26.2 结果通路

最终：

```text
PPU
 ↓
Result FIFO
 ↓
Hardware Result Manager
 ├→ Overlay commit
 └→ CPU observation / logging
```

这样 PPU 的最终目标更符合系统定义：AI 的结果最终服务 Display，而不是先必须经过 CPU 再回来。

---

# 27. 推荐的最终 PPU 架构

```text
             Gemmini / Head Producer
                       │
                       ▼
               Head URAM Slot Manager
                       │
             per-head READY/version
                       │
                       ▼
                 Descriptor FIFO
                       │
                       ▼
┌──────────────────────────────────────────────┐
│                  PPU Engine                  │
│                                              │
│  Class Local Reader                          │
│        │                                     │
│        ▼                                     │
│  16B/32B Class Reducer                       │
│        │                                     │
│        ▼                                     │
│  Score Histogram                             │
│        │                                     │
│        ▼                                     │
│  Top-256 Cutoff                              │
│        │                                     │
│        ▼                                     │
│  Sparse Position Scan                        │
│        │                                     │
│        ▼                                     │
│  4-edge Parallel DFL                         │
│        │                                     │
│        ▼                                     │
│  Pipelined BBox                              │
│        │                                     │
│        ▼                                     │
│  Score Bucket Stable Ordering                │
│        │                                     │
│        ▼                                     │
│  Pipelined Class-aware NMS                   │
│        │                                     │
│        ▼                                     │
│  Result FIFO                                 │
└──────────────────────────────────────────────┘
                       │
                       ▼
                Result Manager
                 │           │
                 ▼           ▼
              Overlay       CPU
```

---

# 28. 实施顺序总表

| 阶段 | 内容 | 主要收益 | 风险 |
|---|---|---|---|
| P0 | phase/perf counters | 建立真实性能基线 | 低 |
| P1 | Class 8B→16B | 当前 core 最大直接收益 | 低 |
| P1.5 | Class 16B→32B pipeline | 进一步压缩 class | 中 |
| P2 | Heap→Score Bucket | 简化排序，降低随机访问 | 中 |
| P3 | BBox LUT/shift/pipeline | 为 300 MHz 收时序 | 中 |
| P4 | NMS area预计算 + II=1 pipeline | dense case + timing | 中 |
| P5 | 4-edge DFL | worst-case latency | 中 |
| P6 | Hardware Head Publication | 去掉大 flush | 高 |
| P6.5 | per-head ready overlap | 降 graph-to-result latency | 高 |
| P7 | Descriptor FIFO | 消除多 Gemmini submit bubble | 低~中 |
| P8 | Result FIFO/Manager | 消除结果读取软件串行 | 中 |

---

# 29. 推荐的实际开发顺序

不要完全按编号机械执行。

推荐实际顺序：

```text
第一轮：低风险 Core 优化
P0
→ P1
→ P2

第二轮：高频准备
P3
→ P4
→ P5

第三轮：系统级 wall-time
P6
→ P6.5

第四轮：多 Gemmini 调度
P7
→ P8
```

原因：

- 先把 PPU core 结构变干净；
- 再动 producer/consumer ownership；
- 避免同时调试算法和 publication coherence。

---

# 30. 每阶段 Git 提交建议

建议严格分提交：

```text
perf(ppu): add phase-level cycle counters

perf(ppu): widen class reducer to 16 bytes per cycle

refactor(ppu): replace redundant top-k heap with score buckets

opt(ppu): pipeline bbox decode and replace constant multiplies

opt(ppu): precompute bbox area and pipeline nms comparisons

perf(ppu): decode four dfl edges in parallel

refactor(ppu): add hardware head publication tracking

perf(ppu): overlap per-head production with postprocess

feat(ppu): add descriptor fifo

feat(ppu): add result fifo and overlay result manager
```

不要一个 commit 同时改：

```text
DFL
+
NMS
+
Head ownership
+
software scheduler
```

---

# 31. 仿真回归矩阵

每阶段至少跑：

```text
scripts/run_yolov5nu_postprocess_tests.sh
scripts/run_ai_postprocessor_tests.sh
```

必须继续覆盖：

## Class

```text
all 6300 positions
ties
threshold-1
threshold
threshold+1
beat crossing 80-byte boundary
input bubbles
output backpressure
```

## Cutoff

```text
0 candidate
1 candidate
255
256
257+
大量同 score tie
```

## DFL

```text
现有 random 48 locations
所有 head
distance min/max
nearest-even boundary
```

## NMS

```text
same class overlap
different class overlap
IoU exactly threshold
IoU just below
IoU just above
tie score/location
RESULT_LIMIT
```

---

# 32. 新增专项测试

建议新增：

```text
tb_yolov5nu_class_reducer_width.sv
tb_yolov5nu_bucket_sort.sv
tb_yolov5nu_nms_pipeline.sv
tb_yolov5nu_dfl_parallel.sv
tb_head_publication_manager.sv
tb_ppu_descriptor_fifo.sv
tb_ppu_result_fifo.sv
```

---

# 33. 性能回归 Gate

每次优化必须输出统一格式：

```text
PPU_PROFILE
total=
class_read=
class_compute=
class_stall=
cutoff=
dfl_scan=
dfl_read=
dfl_compute=
sort=
nms=
result=
candidates=
```

然后保存基线 CSV。

不要只看：

```text
总 cycles 降了
```

必须知道为什么。

---

# 34. 时序 Gate

当前 standalone 100 MHz PPU 已有正裕量。

后续每阶段：

```text
100 MHz:
WNS >= 0
```

中期：

```text
150 MHz standalone synthesis PASS
```

最终候选：

```text
300 MHz standalone synthesis
```

注意：

```text
standalone synthesis PASS
!=
full SoC routed PASS
```

每次资源明显变化后仍需看完整 SoC：

```text
SLR
routing
DSP
BRAM
URAM
WNS/TNS
```

---

# 35. 资源 Gate

记录：

```text
LUT
FF
DSP
BRAM36
URAM
```

特别关注：

### Class 32B

可能显著增加 comparator network。

### DFL 4-edge

可能增加：

```text
exp LUT copies
divider logic
multiply
```

### NMS

应尽量通过：

```text
area precompute
shift/add constants
```

降低 multiplier 数。

---

# 36. 板测 Gate

每个真正进入 production 的阶段，都必须至少：

```text
固定 image025 连续 3 次
当前多图 corpus
live camera
```

检查：

```text
PPU status
positions=6300
candidate count
NMS count
result count
class
score
bbox
cycles
error=0
```

并保存：

```text
bitstream SHA
ELF SHA
Git commit
UART log
```

避免之后再次出现“已经测过但文档没有记录”的情况。

---

# 37. P6 Head Publication 专项 Gate

这是最高风险阶段。

必须单独覆盖：

```text
producer 写完前 PPU 不可读
最后 W accepted 但 completion 未到
outstanding > 0
B response 乱序
slot A/B 交替
worker0/worker1 交替
abort/error
reset
generation wrap
PPU backpressure
```

验收核心：

> **READY 之后读到的 Head 必须永远完整；READY 之前 PPU 永远不能访问。**

只有这个 Gate 通过，才能删除当前 907200 B publication flush。

---

# 38. P7/P8 多任务 Gate

Descriptor FIFO：

```text
4 tasks back-to-back
producer fast / PPU slow
PPU fast / producer slow
FIFO full
stale task
reset
```

Result FIFO：

```text
multi-result
zero-result
CPU 不读
Overlay 慢
Result FIFO 满
frame/version mismatch
```

必须明确 overflow 策略。

建议：

```text
descriptor FIFO 满 → upstream admission/drop
result FIFO 满 → 不允许覆盖未消费结果
```

---

# 39. 与未来 3×Gemmini64 的关系

最终：

```text
Gemmini0 ─┐
Gemmini1 ─┼→ Head Slot Manager → Descriptor FIFO → single PPU
Gemmini2 ─┘
```

先不要复制 3 个 PPU。

原因：如果单 PPU 优化后已经具备足够 II，那么单实例就可以服务多个 Gemmini。

只有真实 profile 证明：

```text
PPU utilization 接近100%
Descriptor queue 持续积压
result stale
```

才考虑双 PPU。

---

# 40. 推荐首先实现的三个阶段

如果从现在开始实施，建议严格按：

```text
① PPU-P0
   加分阶段 cycle counters

② PPU-P1
   Class Reducer 8B → 16B

③ PPU-P2
   删除重复 Heap，改 Score Bucket Stable Ordering
```

完成这三步以后重新测：

```text
PPU core
postprocess wall
LUT/FF/BRAM
WNS
```

再决定是否马上进入 32B Class 或 DFL 4-edge。

---

# 41. 预期优化趋势

下面只是架构预期，不作为验收结果：

```text
当前：
core ≈ 92.6k cycles

P1 16B Class：
可能降到约 60k~70k

P2 bucket：
进一步减少 sort/heap cycles

P3/P4：
主要改善高频 timing + NMS worst case

P5 4-edge DFL：
主要改善 dense candidate worst-case

P6：
core cycles 可能变化不大
但 wall time 显著下降
```

所以不能把：

```text
P6 没有降低 production_cycles
```

错误理解成“没有收益”。

P6 的指标是：

```text
Head complete → Result available
```

而不是 PPU 内部 cycle counter。

---

# 42. 最终验收指标

## Core

```text
bit-exact = PASS
PPU error = 0
core latency 满足目标
dense candidate case bounded
```

## Publication

```text
无 stale / partial Head
无需 907200 B CPU publication flush
```

## 调度

```text
Descriptor FIFO 无死锁
多 Gemmini 可连续提交
```

## Display integration

```text
result stream/frame/version 正确
overlay 不发布 stale box
```

## Timing

```text
PPU standalone positive
full SoC routed signoff separately完成
```

---

# 43. 最终设计原则

PPU 后续优化应始终遵守四条原则。

## 1. 不用 approximation 换性能

当前项目已有 bit-exact baseline。

优先：

```text
parallelism
pipeline
LUT
ownership
stream overlap
```

而不是改数学。

## 2. 平均快和最坏情况都要管

典型图 10 candidates 很轻；但 256 candidate 才决定系统 worst-case 是否稳定。

## 3. Core latency 和系统 wall-time 分开优化

```text
Class/DFL/NMS → Core
Publication/Queue/Result → Wall
```

两者不能混为一个数字。

## 4. PPU 最终服务于视频显示闭环

最终目标不是：

```text
PPU 跑完
```

而是：

```text
正确帧
→ 正确检测
→ 正确 result version
→ 正确 Overlay
→ 用户看到正确框
```

因此后期 Result Manager、frame/version 和 Overlay commit 与 PPU core 本身同样重要。
