# 3×Gemmini64 十六路 YOLOv5nu 流式推理 SoC 架构设计

**目标器件：** Xilinx Virtex UltraScale+ VU13P  
**目标模型：** YOLOv5nu INT8，640×480  
**目标输入：** 16 路 640×480 视频  
**目标帧率：** 每路 30 FPS，总推理吞吐 480 FPS  
**目标计算架构：** 1 Rocket + 1 RVV + 3×Gemmini64 + Tensor Transform Engine + PPU V2  
**设计关键词：**

> **流式输入 + Slot 粒度 + Accelerator-owned Memory + 三 Worker 数据并行 + 异步 PPU + QoS DMA Fabric**

---

# 1. 文档目的

本文定义下一阶段 16 路实时 YOLOv5nu 推理系统的目标架构。

当前生产系统已经实现视频采集、DDR 帧池、snapshot、硬件预处理、双 Tensor Arena、双 Gemmini worker、YOLOv5nu AOT 推理、PPU1 后处理和 16 路 mosaic 显示。当前计算系统实际为 **1 Rocket + 1 Saturn RVV + 2×16×16 Gemmini**，而非本文设计的三颗 64×64 Gemmini。

当前系统已经具备较完整的正确性基础，但下一阶段的主要目标从“链路可以正确运行”转变为：

> **保证 16 路独立 640×480 视频流平均每路持续达到 30 FPS 推理吞吐，并在 DDR、CPU、PPU 和三颗 Gemmini 同时工作时仍维持稳定实时性。**

因此，新架构重点不是单纯增加 PE 数量，而是重新设计 AI 数据通路、任务生命周期、内存所有权和加速器间异步协作机制。

---

# 2. 当前架构基础

当前系统数据流大致为：

```text
Video Input
    │
    ▼
DDR Framebuffer
    │
    ▼
Snapshot / ai_ref
    │
    ▼
Hardware Preprocess
    │
    ▼
Double Tensor Arena
    │
    ▼
Single CPU Scheduler
    │
    ├───────────────┐
    ▼               ▼
Gemmini16 #0    Gemmini16 #1
    │               │
    └──────┬────────┘
           ▼
      Raw YOLO Heads
           │
           ▼
       Cache Flush
           │
           ▼
          PPU1
           │
           ▼
     Result Manager
           │
           ▼
        Overlay
```

当前输入链中，预处理引擎从 DDR framebuffer 读取 640×480 XRGB8888 图像，再生成紧凑的 640×480×3 INT8 Tensor。YOLOv5nu 在线生产路径不执行 resize 或 letterbox，只进行 RGB 提取和 `>>1` 定点量化。

当前双 Tensor Arena 每个包含 16 个成员，两个 Arena 交替工作。一个 Arena 中所有有效成员全部完成或跳过之后，整个 Arena 才能回收。

当前 worker 使用单 CPU cooperative runtime。YOLOv5nu AOT 图包含 167 个 stage，其中 78 个 stage 提交加速器运算；两个 worker 共享 CPU/RVV 软件执行时间。

当前后处理器由两个 worker 共享。Gemmini 产生的六路 raw head 保存在 worker activation arena 中，在 PPU 完成读取前对应 arena 不能复用。

当前系统已经具备良好的所有权和结果一致性设计，因此下一代架构应优先保留以下设计思想：

- 五 slot framebuffer 与独立 AI 引用；
- frame_id / version / stream_id 的结果一致性检查；
- latest-frame 服务策略；
- 独立 worker 运行 Batch=1 图像；
- AOT concat 消物化、split-K 与 scratchpad reuse；
- 硬件后处理；
- display 与 AI 结果解耦。

---

# 3. 性能目标与系统预算

## 3.1 总吞吐目标

目标：

\[
16\times30=480\ images/s
\]

因此整个系统平均必须：

\[
T_{system}=\frac{1}{480}=2.083ms/image
\]

这里的 2.083 ms 是**系统完成间隔**，不是要求一张图从进入系统到输出结果只有 2.083 ms。

系统可以利用多级流水并行：

```text
Frame N     : Gemmini0
Frame N+1   : Gemmini1
Frame N+2   : Gemmini2
Frame N-1   : PPU
Frame N+3   : Tensor input generation
```

从而允许单图端到端 latency 大于 2.083 ms，只要系统能够平均每 2.083 ms 完成一个新结果。

---

## 3.2 每颗 Gemmini 的预算

三颗 Gemmini 均匀分担：

\[
480/3=160\ images/s/Gemmini
\]

所以每颗 Gemmini 平均 worker occupancy 必须：

\[
T_{worker}\leq6.25ms
\]

如果 Gemmini 实际运行频率为 300 MHz：

\[
6.25ms\times300MHz=1.875M cycles
\]

因此推荐设计目标不是刚好 1.875M cycles，而是：

\[
1.5M\sim1.65M cycles/image
\]

即约：

\[
5.0\sim5.5ms/image
\]

留下约 12%～20% 的吞吐余量。

该余量用于吸收：

- DDR 延迟波动；
- 多 master 仲裁；
- PPU 堵塞；
- command queue 抖动；
- tensor slot 短期不足；
- 部分视频通道同时到达；
- FPGA 时序导致的频率变化。

---

# 4. 新系统总体架构

目标数据流：

```text
                 ┌────────────────────────────┐
                 │        Rocket CPU          │
                 │ Scheduler / Control Plane  │
                 └─────────────┬──────────────┘
                               │ Job Descriptor
                               │
16 Video Streams               ▼
       │                Global Job Scheduler
       │                       │
       ▼                       │
Video Frontend                 │
       │                       │
       ├─────────────┐         │
       │             │         │
       ▼             ▼         │
Framebuffer      AI Tensor     │
Writer           Stream Packer │
       │             │         │
       ▼             ▼         │
Display DDR     Tensor Slot Pool
                     │
                     ▼
             Ready Job Queue
                     │
           ┌─────────┼─────────┐
           │         │         │
           ▼         ▼         ▼
      Gemmini64  Gemmini64  Gemmini64
        Worker0    Worker1    Worker2
           │         │         │
           └─────────┼─────────┘
                     ▼
               Head Slot Pool
                     │
                     ▼
                  PPU V2
          Class → TopK → Sparse DFL
                     │
                     ▼
               Result Manager
                     │
                     ▼
                  Overlay
```

共享底层：

```text
                  AI Memory Fabric

        ┌──────────────┼──────────────┐
        │              │              │
 Gemmini Demand     PPU DMA     Tensor Writer
        │              │              │
        └──────────────┼──────────────┘
                       │
                QoS / Credit Control
                       │
                       ▼
                      DDR
```

---

# 5. 核心设计原则

新架构遵循六个原则。

| 原则 | 含义 |
|---|---|
| 流式输入 | AI Tensor 尽可能在视频进入系统时直接产生 |
| Slot 粒度 | Tensor、Head 等资源以单帧 slot 管理，不以 Batch16 为生命周期 |
| Accelerator-owned Memory | 大 Tensor 不由 CPU 缓存拥有 |
| Frame-level Data Parallel | 三颗 Gemmini 分别运行完整独立图像 |
| Asynchronous Postprocess | PPU 不阻塞 Gemmini worker 生命周期 |
| QoS DMA Fabric | demand、video、PPU、prefetch 有明确优先级和 credit |

这些原则最终共同实现：

> **CPU 只负责控制面，计算和数据搬运全部进入硬件数据面。**

---

# 6. 流式 AI 输入架构

## 6.1 当前问题

当前路径：

```text
Camera
   │
   ▼
DDR Framebuffer Write
   │
   ▼
Snapshot
   │
   ▼
DDR Framebuffer Read
   │
   ▼
Preprocess
   │
   ▼
INT8 Tensor DDR Write
```

单帧 framebuffer：

\[
640\times480\times4
=1,228,800B
\]

480 FPS 下 framebuffer preprocess read：

\[
1,228,800\times480
=
589.824MB/s
\]

这部分读取本质上是对刚刚写入 DDR 的视频重新读取一次。

---

# 7. AI Tensor Stream Sidecar

新设计直接在视频 pixel stream 上分叉：

```text
                       ┌──→ XRGB8888 → Framebuffer Writer
Video RGB Pipeline ────┤
                       └──→ INT8 RGB → AI Tensor Writer
```

AI Tensor pipeline：

```text
RGB Pixel
   │
   ├── R[7:0] >> 1
   ├── G[7:0] >> 1
   └── B[7:0] >> 1
        │
        ▼
   RGB888 INT8
        │
        ▼
   Pack 256-bit
        │
        ▼
   Tensor DMA Writer
```

生产 YOLOv5nu 的输入保持：

```text
640 × 480 × 3
NHWC
INT8
```

单帧：

\[
921600B
\]

Sidecar 不改变当前模型输入合同。

---

## 7.1 带宽收益

旧路径至少涉及：

\[
589.824MB/s
\]

framebuffer write，

加：

\[
589.824MB/s
\]

preprocess read，

加：

\[
442.368MB/s
\]

tensor write。

合计：

\[
1.622GB/s
\]

新路径：

```text
Framebuffer Write
+
Tensor Write
```

约：

\[
589.824+442.368
=
1.032GB/s
\]

直接减少：

\[
\boxed{589.824MB/s}
\]

DDR 逻辑流量。

---

## 7.2 保留旧 Preprocessor

旧硬件 preprocess 不建议删除。

它保留用于：

```text
TinyYOLOv2 416×416
debug
offline framebuffer inference
未来 resize / letterbox 模式
fallback
```

生产 YOLOv5nu 则使用：

```text
PREPROCESS_BYPASS=1
```

直接采用 Tensor Sidecar。

---

# 8. Tensor Slot Pool

## 8.1 放弃 Batch16 生命周期

当前：

```text
Arena0
 ├─ member0
 ├─ member1
 ...
 └─ member15

Arena1
 ├─ member0
 ...
 └─ member15
```

生命周期为：

```text
FREE
 ↓
PREPROCESS
 ↓
READY
 ↓
RUNNING
 ↓
所有成员结束
 ↓
FREE
```

新的逻辑改为：

```text
Tensor Slot Pool
32 independent slots
```

仍然可以复用当前两块 Arena 的物理地址空间，只改变管理方式。

---

# 9. Tensor Slot Descriptor

每个 slot 保存：

```c
struct AiTensorSlot {
    uint64_t tensor_addr;

    uint8_t  stream_id;
    uint64_t frame_id;
    uint64_t timestamp;
    uint32_t version;

    uint32_t byte_count;

    enum {
        SLOT_FREE,
        SLOT_WRITING,
        SLOT_READY,
        SLOT_RUNNING,
        SLOT_ERROR
    } state;

    uint8_t owner_worker;
};
```

slot 状态机：

```text
              new video frame
                    │
                    ▼
                  FREE
                    │
                    ▼
                 WRITING
                    │
          DMA B response complete
                    │
                    ▼
                  READY
                    │
             scheduler acquire
                    │
                    ▼
                 RUNNING
                    │
            Gemmini input done
                    │
                    ▼
                  FREE
```

注意：

Tensor Slot 不需要等待整个 Gemmini inference 完成。

只要 Gemmini 已经完成对 input tensor 的最后一次 DMA 读取，并且后续不会重新访问该 slot，就可以释放。

因此长期可以进一步增加：

```text
RUNNING_INPUT
      ↓
INPUT_CONSUMED
      ↓
FREE
```

减少输入 slot 生命周期。

---

# 10. 最新帧策略

16 路实时检测不需要保存历史视频推理 backlog。

如果某 stream 已出现：

```text
frame 100
frame 101
frame 102
```

但尚未被 Gemmini 获取，应：

```text
discard frame100
discard frame101
run frame102
```

而不是按 FIFO 全部执行。

Tensor Pool 应支持：

```text
latest_ready_slot[16]
```

同一 stream 新帧 READY 时，如果旧 READY slot 尚未 RUNNING：

```text
old_slot → SUPERSEDED → FREE
new_slot → READY
```

这样 backlog 深度天然保持有界。

---

# 11. 三 Gemmini Worker

三颗 Gemmini 采用：

# Frame-level Data Parallel

即：

```text
Frame A → Gemmini0 → Complete YOLOv5nu
Frame B → Gemmini1 → Complete YOLOv5nu
Frame C → Gemmini2 → Complete YOLOv5nu
```

禁止默认设计为：

```text
G0 Backbone
 ↓
G1 Neck
 ↓
G2 Head
```

因为模型流水会增加：

- 中间 activation DDR 写回；
- accelerator 间同步；
- 模型 stage imbalance；
- buffer ownership；
- pipeline bubble；
- 跨 SLR 数据路径。

16 路独立输入已经提供足够多的天然帧级并行，不需要人工把单图拆开。

---

# 12. Worker Context

每颗 worker 保存：

```c
struct GemminiWorker {
    uint8_t worker_id;

    uint64_t activation_base;
    uint64_t scratch_base;

    JobQueue command_queue;
    CompletionQueue completion_queue;

    uint32_t credits;

    enum {
        WORKER_IDLE,
        WORKER_ACTIVE,
        WORKER_WAIT_TTE,
        WORKER_HEAD_PENDING,
        WORKER_ERROR
    } state;

    uint64_t current_job_id;
};
```

worker0 / worker1 / worker2：

```text
独立 activation arena
独立 scratchpad logical ownership
独立 job queue
独立 completion
独立 performance counters
```

权重仍可以共享。

---

# 13. Job Descriptor

CPU 不直接控制每次细粒度 DMA。

CPU 只产生：

```c
struct AiJobDescriptor {
    uint64_t job_id;

    uint8_t  stream_id;
    uint64_t frame_id;
    uint32_t version;

    uint64_t input_addr;

    uint64_t activation_addr;
    uint64_t head_slot_addr;

    uint64_t submit_cycle;
    uint64_t deadline_cycle;

    uint32_t flags;
};
```

然后：

```text
CPU
 ↓
Job Queue
 ↓
Worker Runtime / Microsequencer
 ↓
Gemmini Commands
```

---

# 14. Worker Command Queue

每颗 Gemmini 前增加独立 queue：

```text
Rocket
  │
  ├→ Worker0 Queue → Gemmini0
  ├→ Worker1 Queue → Gemmini1
  └→ Worker2 Queue → Gemmini2
```

推荐最初：

```text
Queue depth = 16
```

后续 sweep：

```text
8 / 16 / 32
```

command queue 的主要作用不是缓存整张网络的全部命令，而是：

> **消除 CPU 和 RoCC ready/valid 的细粒度同步。**

---

# 15. CPU 调度器

新 CPU Scheduler 采用：

# Deadline-aware Latest-frame Scheduling

每个 stream 保存：

```c
struct StreamState {
    uint64_t last_completed_frame;
    uint64_t last_complete_cycle;

    uint64_t next_deadline;

    int ready_slot;
    bool inflight;
};
```

目标周期：

\[
T_{stream}=33.333ms
\]

因此：

```text
next_deadline =
last_complete_cycle
+
33.333 ms
```

---

# 16. 调度优先级

worker 变为 IDLE 时：

```text
所有 READY stream
       │
       ▼
排除 inflight stream
       │
       ▼
deadline 最早优先
       │
       ▼
相同 deadline：
frame_id 最大优先
       │
       ▼
dispatch
```

因此调度优先级相当于：

```text
Earliest Deadline First
        +
Latest Frame First
```

它比简单 Round-Robin 更适合实时视频。

---

# 17. 每 stream inflight 限制

保持当前优秀设计：

```text
一个 stream
最多一个 inference job inflight
```

原因是避免：

```text
CH1 frame N
CH1 frame N+1
```

同时占据两个 Gemmini，而其他通道饿死。

如果 CH1 新帧到来时已有 inflight：

```text
记录 latest frame
不立即新增 inflight
```

待当前任务完成：

```text
如果 latest frame 更新
下一次直接处理最新 frame
```

---

# 18. Gemmini64 数据通路

每颗 Gemmini 的目标运行模式：

```text
              Tile N+1
DMA LOAD  ───────────────────

              Tile N
EXECUTE       ───────────────

              Tile N-1
DMA STORE         ───────────────
```

实现：

```text
LOAD(N+1)
EXEC(N)
STORE(N-1)
```

并行。

---

# 19. DMA Outstanding 设计

不采用：

```text
outstanding 越多越好
```

而采用：

```text
Credit-based Outstanding
```

推荐首轮参数 sweep：

| 项目 | 测试范围 |
|---|---:|
| Gemmini Load outstanding | 4 / 8 / 16 |
| Gemmini Store outstanding | 4 / 8 |
| Load queue | 8 / 16 / 32 |
| Store queue | 4 / 8 / 16 |
| Execute queue | 8 / 16 |
| ROB | 16 / 32 / 64 |
| DMA burst | 64 / 128 / 256 B |

选择标准不是 throughput 单测最高，而是完整系统下：

```text
PE utilization ↑
load stall ↓
store stall ↓
DDR queue latency ↓
video underflow = 0
```

---

# 20. Gemmini64 Profiling

每颗 Gemmini 应新增以下计数器：

```text
total_cycles
execute_cycles
array_active_cycles

load_active_cycles
load_wait_cycles

store_active_cycles
store_wait_cycles

spad_bank_conflict_cycles
acc_bank_conflict_cycles

rocc_wait_cycles

tl_a_stall
tl_d_wait

dma_read_bytes
dma_write_bytes

max_read_outstanding
max_write_outstanding
```

核心指标：

\[
PE\ Utilization
=
\frac{array\_active\_cycles}
{worker\_active\_cycles}
\]

并进一步拆分：

```text
Compute Bound
Memory Bound
Bank Conflict Bound
CPU Submission Bound
```

---

# 21. 64×64 阵列利用率问题

YOLOv5nu 包含：

```text
16
32
64
128
256
```

等输出通道。

对于固定 64 列输出阵列：

```text
Cout = 16 → 25%
Cout = 32 → 50%
Cout = 64 → 100%
```

因此 DIM64 不能自动保证高 PE 利用率。

这也是后续 Scale Window、Virtual-I、Elastic-J 等优化的主要意义。

---

# 22. Elastic-J / J-direction Partition

未来高级版本支持：

```text
Mode 0:

┌────────────────────────┐
│        64 × 64         │
└────────────────────────┘
```

以及：

```text
Mode 1:

┌────────────┬────────────┐
│   64×32    │   64×32    │
└────────────┴────────────┘
```

以及：

```text
Mode 2:

┌──────┬──────┬──────┬──────┐
│64×16 │64×16 │64×16 │64×16 │
└──────┴──────┴──────┴──────┘
```

例如 Cout=16：

```text
Image A → partition0
Image B → partition1
Image C → partition2
Image D → partition3
```

而四个 partition 可以：

```text
共享当前 layer weights
```

从而理论上将输出通道方向利用率由：

\[
25\%
\]

提升至接近：

\[
100\%
\]

该功能属于高级优化，不是第一版 3×Gemmini64 bring-up 的前置要求。

---

# 23. Tensor Transform Engine

当前部分操作仍在 RVV：

```text
MaxPool
Resize
Copy
Requant
Tensor Transform
```

未来三颗 Gemmini 同时工作时，一个 RVV 可能成为共享串行节点。

因此设计：

# TTE — Tensor Transform Engine

负责：

```text
Nearest Resize
Copy
Requant
Layout Transform
Slice
Simple Merge
Padding
```

数据通路：

```text
DDR
 │
 ▼
DMA Reader
 │
 ▼
Line Buffer
 │
 ▼
Transform Pipeline
 │
 ▼
DMA Writer
 │
 ▼
DDR / SPAD
```

---

# 24. TTE 与 worker 异步协作

例如 Resize：

```text
Gemmini produces feature
        │
        ▼
       TTE
        │
  asynchronous operation
        │
        ▼
completion event
        │
        ▼
Gemmini continues
```

worker 状态：

```text
ACTIVE
 ↓
WAIT_TTE
 ↓
ACTIVE
```

CPU 不执行实际 tensor loop，只负责 command submission。

---

# 25. Accelerator-Owned Memory

这是下一代架构最重要的内存模型变化。

当前部分数据通过 CPU/L2 一致性路径管理。

未来定义专门：

# AI Device Memory Region

包括：

```text
Tensor Slot Pool
Worker Activation Arena
Head Slot Pool
TTE Temporary Buffer
```

这些区域：

```text
CPU 不读 payload
CPU 不写 payload
CPU 只操作 descriptor
```

所有权只在 accelerator 之间传递。

---

# 26. Memory Ownership

例如 Tensor Slot：

```text
Video Tensor Writer
       │
       ▼
   producer owns
       │
   B response done
       │
       ▼
   descriptor READY
       │
       ▼
   Gemmini owns
       │
input no longer needed
       │
       ▼
      FREE
```

Head Slot：

```text
Gemmini owns
      │
last head store response complete
      │
      ▼
HEAD_READY
      │
      ▼
PPU owns
      │
PPU done
      │
      ▼
FREE
```

整个过程 CPU 不需要：

```text
memcpy
cache flush
cache invalidate
```

---

# 27. 短期 Cache Maintenance Engine

如果早期版本暂时无法完成 device-owned memory 改造，则增加：

```text
L2 Range Maintenance Engine
```

CPU：

```c
flush_range(addr, length);
```

硬件：

```text
addr
addr+64
addr+128
...
```

直到：

```text
done
```

避免当前 CPU 逐 64-byte line MMIO flush。

---

# 28. Head Slot Pool

当前 raw head 与 worker activation arena 生命周期耦合。

新架构为每颗 Gemmini 至少配置两个独立 Head Slot：

```text
Worker0:
    Head0-A
    Head0-B

Worker1:
    Head1-A
    Head1-B

Worker2:
    Head2-A
    Head2-B
```

一共：

```text
6 slots
```

---

# 29. Head Slot 状态机

```text
FREE
 │
 ▼
WRITING
 │
 Gemmini head store complete
 ▼
READY
 │
 PPU acquire
 ▼
PROCESSING
 │
 PPU complete
 ▼
FREE
```

于是：

```text
Gemmini frame N
 ↓
Head A
 ↓
PPU

同时：

Gemmini frame N+1
 ↓
Head B
```

Gemmini 不再等待 PPU。

---

# 30. PPU V2 总体架构

```text
Head Descriptor
       │
       ▼
Class Reader
       │
       ▼
Class Requant / Sigmoid
       │
       ▼
Per-location Class Reduction
       │
       ▼
Threshold
       │
       ▼
Streaming Top-K
       │
       ▼
Candidate Location RAM
       │
       ▼
Sparse DFL Request Generator
       │
       ▼
DFL Decoder
       │
       ▼
BBox Decoder
       │
       ▼
Class-aware NMS
       │
       ▼
Result RAM
```

---

# 31. PPU Sparse DFL

当前 raw head：

\[
504000B\ class
\]

加：

\[
403200B\ DFL
\]

合计：

\[
907200B
\]

当前虽然只对 candidate 执行 DFL decode，但 DFL tensor 本身仍全部读取。

新 PPU：

```text
首先只读 Class
      ↓
筛候选
      ↓
只读 candidate 对应的 DFL
```

---

# 32. DFL 地址计算

每个 location：

```text
4 edges × 16 bins × 1B
=
64 bytes
```

因此：

```text
dfl_addr =
head_dfl_base
+
local_position × 64
```

候选位置生成 burst descriptors：

```text
candidate0
candidate1
candidate2
...
```

相邻位置：

```text
merge into burst
```

分散位置：

```text
multiple outstanding reads
```

---

# 33. PPU 流量收益

最坏 Top-256：

\[
256\times64
=
16384B
\]

所以：

\[
504000+16384
=
520384B
\]

相对：

\[
907200B
\]

下降：

\[
42.6\%
\]

480 FPS 时：

旧：

\[
435.456MB/s
\]

新：

\[
249.784MB/s
\]

---

# 34. PPU Class Reducer

当前 PPU reducer 每周期消费：

```text
4 bytes
```

新版本建议：

```text
16 bytes/cycle
```

结构：

```text
16×INT8
 │
 ▼
Comparator Tree
 │
 ▼
local class max
 │
 ▼
running max
```

如果时序困难：

```text
8 bytes/cycle
```

作为 PPU V2 第一版。

---

# 35. PPU 性能目标

目标：

\[
T_{PPU}<1.5ms/image
\]

而系统允许平均：

\[
2.083ms/image
\]

因此 PPU 应保留约 25% 以上余量。

只有在单 PPU 实测无法达到目标之后，才考虑：

```text
PPU ×2
```

不建议一开始就配置三个 PPU。

---

# 36. AI Memory Fabric

新架构需要建立一个统一的：

# AI Memory Fabric

主要 master：

```text
Gemmini0 Load/Store
Gemmini1 Load/Store
Gemmini2 Load/Store

Tensor Writer

PPU Reader

TTE Reader/Writer

Weight Prefetch
```

---

# 37. DMA QoS

定义四级优先级。

| Priority | Master | 原因 |
|---|---|---|
| P0 | Video capture / display | 有真实视频 deadline |
| P1 | Gemmini demand load/store | PE 正在等待 |
| P2 | Tensor writer / PPU / TTE | 有 buffer 可吸收有限延迟 |
| P3 | Prefetch | 可以 throttle |

---

# 38. Demand 与 Prefetch 分离

Gemmini：

```text
Demand Request Queue
Prefetch Request Queue
```

仲裁：

```text
if demand_pending:
    issue demand
else if bandwidth_available:
    issue prefetch
```

禁止：

```text
prefetch outstanding
```

填满整个 DDR command queue。

---

# 39. Prefetch Credit

例如每颗 Gemmini：

```text
demand_credit   = 8
prefetch_credit = 2
```

三个 worker：

```text
max prefetch outstanding
=
6
```

而不是：

```text
每颗 16
→ 总共 48
```

通过：

```text
DDR queue depth
average latency
demand stall
```

动态控制 prefetch。

---

# 40. Memory Traffic Monitor

AI Fabric 增加实时计数器：

```text
read_bytes[master]
write_bytes[master]

read_requests
write_requests

average_latency
max_latency

outstanding_high_watermark

ar_stall
r_wait
aw_stall
w_stall
b_wait

qos_block_cycles
```

同时记录：

```text
video
gemmini0
gemmini1
gemmini2
ppu
tte
prefetch
```

使之后优化有实际数据依据。

---

# 41. Weight Traffic Optimization

三颗 Gemmini 运行同一个 YOLOv5nu，因此同一时刻可能重复读取：

```text
相同 layer weights
```

第一阶段：

```text
依赖 shared L2 / cache reuse
```

第二阶段：

```text
Shared Weight Cache
```

架构：

```text
DDR
 │
 ▼
Shared Weight Cache
 │
 ├→ Gemmini0
 ├→ Gemmini1
 └→ Gemmini2
```

第三阶段可以考虑：

```text
Layer Weight Residency
```

某些频繁访问或尺寸合适的 layer weight 长驻片上。

---

# 42. Cross-layer Scratchpad Reuse

当前 AOT 已经支持：

```text
concat 消物化
split-K
dual-consumer scratchpad reuse
```

下一版继续扩展：

```text
Conv N
 │
 ▼
SPAD
 │
 ▼
Conv N+1
```

减少：

```text
Conv N
 ↓
DDR
 ↓
Conv N+1
```

特别针对：

```text
60×80×64
30×40×128
15×20×256
```

这些中后层 tensor。

---

# 43. Worker 内存规划

建议每 worker：

```text
Activation Arena
Conv Input Scratch
Conv Output Scratch
SPAD-resident temporary region
```

三 worker 完全独立。

权重：

```text
read-only shared
```

Head：

```text
独立 Head Pool
```

Tensor Input：

```text
Global Tensor Slot Pool
```

从而形成：

```text
Input Pool
       ↓
Worker-local Intermediate
       ↓
Head Pool
```

三个清晰生命周期。

---

# 44. CPU 最终角色

CPU 最终只承担：

```text
16 stream metadata
Deadline Scheduler
Job Descriptor Submission
Completion Handling
Fault Recovery
Result Manager
Overlay Control
UART/debug
```

CPU 不应该长期执行：

```text
Tensor copy
Resize
Pooling
Large cache flush
Decode
NMS
DMA polling loop
```

理想软件路径：

```c
job = scheduler_pick();

worker_submit(worker, job);
```

之后：

```c
if (worker_completion()) {
    scheduler_complete(job);
}
```

而不再直接参与 tensor 数据计算。

---

# 45. Completion Queue

每个 worker 输出：

```c
struct AiCompletion {
    uint64_t job_id;

    uint8_t worker_id;
    uint8_t stream_id;

    uint64_t frame_id;
    uint32_t version;

    uint64_t head_slot_addr;

    uint64_t start_cycle;
    uint64_t finish_cycle;

    uint32_t error_flags;
};
```

PPU completion：

```c
struct PpuCompletion {
    uint64_t job_id;

    uint32_t detection_count;

    Detection detection[10];

    uint64_t start_cycle;
    uint64_t finish_cycle;

    uint32_t error_flags;
};
```

---

# 46. Result Freshness

每路保存：

```text
last_completed_frame_id
last_result_time
latest_detection
```

建议增加：

```text
RESULT_TTL
```

例如超过：

```text
100 ms
```

未获得新推理结果，则：

```text
overlay clear
```

避免旧检测框长期覆盖在新画面上。

---

# 47. 故障恢复

当前软件 timeout 并不保证 DMA 已真正停止，因此新架构需要明确 hardware quiesce。当前系统也明确存在“软件 timeout 不等于硬件已停止”的限制。

每个 worker 增加：

```text
STOP_ISSUE
DRAIN
QUIESCENT
RESET
```

状态。

错误恢复：

```text
ERROR
 │
 ▼
Stop new command
 │
 ▼
Drain outstanding DMA
 │
 ▼
Confirm no read/write outstanding
 │
 ▼
Invalidate affected slots
 │
 ▼
Reset worker
 │
 ▼
IDLE
```

禁止直接：

```text
timeout
→ buffer FREE
```

否则旧 DMA 可能写入已经重新分配的 slot。

---

# 48. 性能指标体系

未来不能只看：

```text
total FPS
```

必须同时记录以下指标。

## 48.1 Stream Level

```text
input_frames
valid_frames
inferred_frames
superseded_frames
dropped_frames

FPS per stream

capture_to_tensor_latency
tensor_to_inference_latency
inference_latency
postprocess_latency
end_to_end_latency
```

---

## 48.2 Worker Level

```text
jobs
cycles/image

PE utilization

load stall
store stall
bank conflict
TTE wait
PPU wait
queue starvation
```

---

## 48.3 System Level

```text
Total inference FPS
Minimum stream FPS
P50/P95/P99 latency

DDR read bandwidth
DDR write bandwidth

video underflow
capture drop

CPU utilization

PPU utilization
Gemmini utilization
TTE utilization
```

---

# 49. 达标条件

不能只使用：

```text
Total FPS >= 480
```

作为成功标准。

应该要求：

\[
FPS_i\ge30
\]

对：

\[
i=0...15
\]

同时：

```text
display underflow = 0
```

并限制：

```text
持续 inference error = 0
```

推荐完整验收：

```text
30 minute continuous run
16 streams active
3 Gemmini active
PPU active
display active
```

记录：

```text
min stream FPS
average FPS
P99 latency
DDR errors
AI errors
video drops
```

---

# 50. 第一阶段 Bring-up 架构

第一阶段不要一次实现全部优化。

先做：

```text
1 CPU
1 RVV
3×Gemmini64

保留：
当前 preprocess
当前 Tensor Arena
当前 PPU
```

重点验证：

```text
3 Gemmini 是否可以同时运行
```

以及：

```text
资源
时序
SystemBus
DMA
CPU submit
```

---

# 51. Phase 0：单 Gemmini64

必须首先完成：

```text
1×Gemmini64
+
YOLOv5nu
```

测试。

需要得到：

```text
Fmax
LUT
FF
DSP
BRAM
URAM

cycles/image

per-layer cycles

load wait
store wait
array utilization
```

这是整个设计的第一道 Gate。

---

# 52. Phase 1：3×Gemmini64

实现：

```text
G0
G1
G2
```

独立 worker。

先保持旧数据通路不变。

验证：

```text
single worker FPS

2 workers FPS

3 workers FPS
```

理想情况：

```text
1× = X

2× ≈ 2X

3× ≈ 3X
```

实际 scaling 可以定义：

\[
Scaling_3=
\frac{FPS_{3}}
{3\times FPS_1}
\]

推荐目标：

\[
Scaling_3>0.8
\]

如果只有：

```text
0.5
```

说明已经受：

```text
DDR
CPU
RoCC
SystemBus
```

限制。

---

# 53. Phase 2：Stream Tensor Input

加入：

```text
Video Tensor Sidecar
```

保留旧 preprocess 作为 fallback。

比较：

```text
Legacy preprocess mode
```

和：

```text
Stream input mode
```

需要验证：

```text
bit-exact tensor
```

即：

```text
同一 framebuffer
```

旧 preprocess 输出：

```text
tensor_A
```

新 sidecar 输出：

```text
tensor_B
```

要求：

```text
memcmp(A,B)==0
```

---

# 54. Phase 3：Tensor Slot Pool

将：

```text
Arena0 + Arena1
```

逻辑重构为：

```text
32 independent Tensor Slots
```

优先只修改：

```text
metadata
ready
ownership
scheduler
```

物理地址暂时保持不变。

这样可以最小化验证风险。

---

# 55. Phase 4：Head Slot Pool

增加：

```text
6 head slots
```

首先只实现：

```text
Gemmini head → dedicated head slot
```

PPU 保持当前算法。

确认：

```text
Gemmini can start next job
before PPU completes previous job
```

---

# 56. Phase 5：PPU V2

依次完成：

```text
Reducer 8/16B cycle
        ↓
Sparse DFL
        ↓
burst merge
        ↓
multiple outstanding
```

验证必须包括：

```text
normal case
dense candidate case
>256 candidate case
tie case
IoU threshold boundary
```

---

# 57. Phase 6：Device-owned Memory

完成：

```text
Tensor Pool
Head Pool
TTE Buffer
```

全部 accelerator-owned。

逐步删除：

```text
CPU cache maintenance
```

在这一阶段正式定义：

```text
producer / consumer ownership protocol
```

并做 assertion。

---

# 58. Phase 7：TTE

将：

```text
Resize
Copy
Requant
```

逐步迁移。

如果 Gemmini 内部 pooling 能满足当前数值合同，则继续将部分 MaxPool 从 RVV 移除。

---

# 59. Phase 8：Advanced Gemmini64

最后才进入：

```text
Scale Window
Virtual-I
Elastic-J
cross-layer SPAD reuse
weight residency
shared weight cache
```

这些属于提高：

```text
effective TOPS
```

而前面的优化主要负责：

```text
让已有 TOPS 真正被使用
```

两类优化不能颠倒顺序。

---

# 60. 资源风险

VU13P 上三颗 64×64 是一个资源和 routing 都非常激进的配置。

因此最重要的硬件 Gate 是：

```text
3×Gemmini64
+
Rocket
+
RVV
+
L2
+
Video
+
DDR
+
PPU
```

完整实现之后：

```text
post-route timing
```

而不是单独 Gemmini synthesis。

必须监控：

```text
DSP occupancy
LUT occupancy
BRAM
URAM
SLR crossing
routing congestion
WNS
TNS
```

---

# 61. 频率策略

不要把：

```text
300 MHz
```

作为不可改变的硬指标。

实际应该比较：

```text
3×64 @ 200 MHz
3×64 @ 250 MHz
3×64 @ 300 MHz
```

分别计算：

\[
FPS_{actual}
\]

因为：

```text
300 MHz + routing stall
```

不一定优于：

```text
250 MHz + clean timing + higher utilization
```

目标始终应该是：

> **实际端到端 FPS，而不是名义时钟。**

---

# 62. 推荐最终模块层次

```text
top_wrapper
│
├── Video Subsystem
│   │
│   ├── Camera Frontends
│   ├── HDMI Demux
│   ├── Pixel Recovery
│   ├── Framebuffer Writer
│   └── AI Tensor Stream Sidecar
│
├── AI Input Manager
│   │
│   ├── Tensor Slot Pool
│   ├── Slot Metadata RAM
│   └── Ready Queue
│
├── SoC
│   │
│   ├── Rocket
│   ├── RVV
│   ├── Scheduler
│   │
│   ├── Gemmini64 Worker0
│   ├── Gemmini64 Worker1
│   └── Gemmini64 Worker2
│
├── Tensor Transform Engine
│
├── Head Buffer Manager
│   │
│   └── 6× Head Slot
│
├── PPU V2
│   │
│   ├── Class Reader
│   ├── Class Reducer
│   ├── Top-K
│   ├── Sparse DFL Reader
│   ├── DFL Decoder
│   ├── BBox Decoder
│   └── NMS
│
├── AI Memory Fabric
│   │
│   ├── QoS Arbiter
│   ├── Credit Manager
│   ├── Traffic Monitor
│   └── DDR Interfaces
│
└── Display
    │
    ├── Result Manager
    ├── Overlay
    └── HDMI TX
```

---

# 63. 推荐的任务关键路径

从视频帧产生到显示结果：

```text
Video frame
     │
     ▼
Tensor Slot WRITING
     │
     ▼
Tensor Slot READY
     │
     ▼
Deadline Scheduler
     │
     ▼
Gemmini Worker
     │
     ▼
Head Slot READY
     │
     ├───────────── Gemmini immediately accepts next job
     │
     ▼
PPU V2
     │
     ▼
Result Manager
     │
     ▼
Overlay
```

理想情况下：

```text
Tensor Generation
Gemmini Inference
PPU
Display
```

四个阶段长期同时工作。

---

# 64. 目标流水示例

达到稳定状态后：

```text
Time →

Tensor :
F0  F1  F2  F3  F4  F5 ...

G0 :
    F0          F3          F6

G1 :
        F1          F4          F7

G2 :
            F2          F5          F8

PPU:
                F0 F1 F2 F3 F4 F5 ...

Display:
                       results...
```

系统吞吐由最慢 stage 的：

```text
service interval
```

决定，而不是单帧总 latency。

---

# 65. 设计目标总结

最终目标不是简单构建：

```text
3×Gemmini64
```

而是构建：

# 一个真正流式的数据面

其核心思想为：

```text
Video
 ↓
Tensor Stream
 ↓
Slot Pool
 ↓
Dynamic Scheduler
 ↓
3×Independent Gemmini64
 ↓
Head Pool
 ↓
Asynchronous PPU
 ↓
Result
```

所有大 tensor：

```text
accelerator → accelerator
```

所有 CPU 交互：

```text
descriptor / completion
```

所有 DMA：

```text
QoS + Credit
```

所有 stream：

```text
deadline aware
```

---

# 66. 最终目标架构定义

最终系统应满足以下结构性条件：

| 模块 | 最终状态 |
|---|---|
| 视频输入 | 16 路持续采集 |
| AI Input | 流式 Tensor Sidecar |
| Tensor Buffer | 独立 slot pool |
| CPU | Control Plane |
| Gemmini | 3×64×64，帧级数据并行 |
| Worker Queue | 独立 queue |
| DMA | 多 outstanding + credit |
| Intermediate Tensor | 尽量 SPAD reuse |
| Tensor Operations | Gemmini / TTE |
| Head Storage | 独立 Head Pool |
| PPU | 异步、Sparse DFL |
| AI Memory | accelerator-owned |
| Memory Fabric | QoS-aware |
| Scheduler | EDF + Latest Frame |
| Result | 每 stream 独立 version/frame 管理 |
| Display | latest frame + latest valid result |

整个设计最终应从当前：

```text
CPU-centric accelerator system
```

转变为：

```text
Streaming heterogeneous inference pipeline
```

CPU 负责：

```text
什么时候算
算哪一路
出现异常怎么办
```

硬件数据面负责：

```text
数据怎么搬
卷积怎么算
tensor 怎么变换
head 怎么处理
结果怎么输出
```

---

# 67. 最终性能目标

项目最终验收建议定义为：

```text
Input:
16 × 640×480

Inference:
YOLOv5nu INT8

Target:
>= 30 FPS / stream

Aggregate:
>= 480 successful inference results/s
```

同时满足：

```text
minimum per-stream FPS >= 30

video capture overflow = 0
display underflow = 0

persistent Gemmini error = 0
persistent PPU error = 0

no ownership violation
no stale DMA write

bounded tensor queue
bounded head queue
```

并要求长期板测：

```text
>= 30 min
```

稳定通过。

---

# 68. 一句话架构总结

下一代系统不是：

> **“给现在的设计再增加一颗 Gemmini，并把 DIM 从 16 改成 64。”**

而应该是：

> **“以视频流为生产者，以 Tensor Slot 为任务单位，以三颗 Gemmini64 为异步计算 Worker，以 Head Slot 解耦后处理，以 PPU V2 完成稀疏硬件后处理，以 accelerator-owned memory 和 QoS DMA Fabric 构成整个 AI 数据面。”**

最终结构可以概括为：

```text
Streaming Input
      +
Fine-grained Slot Ownership
      +
3-way Frame Parallelism
      +
Accelerator-to-Accelerator Zero Copy
      +
Asynchronous Postprocessing
      +
QoS-controlled Memory System
```

这才是面向 **16 路 640×480@30 FPS YOLOv5nu** 的目标 SoC 架构。