# 16 路视频 1CPU + 1RVV + 3×64×64 Gemmini 固定模型推理系统总体架构

> **版本：V4.0**  
> **目标平台：XCVU13P + Rocket RV64 + Saturn RVV + 3×Gemmini 64×64**  
> **视频规模：16 路 640×480@30 FPS**  
> **模型形态：启动后运行一个固定模型**  
> **主要数据类型：INT8**  
> **Gemmini 目标频率：200 MHz（最终以 Post-Route Timing 为准）**  
> **核心定位：Worker-first / Frame-Level Parallelism / Static Runtime**

---

# 1. 系统目标

本系统面向 16 路实时视频 AI 推理场景。

系统硬件计算资源为：

```text
Rocket RV64 CPU ×1
Saturn RVV      ×1
Gemmini 64×64   ×3
```

系统目标：

```text
1. 16 路视频持续稳定采集
2. Capture 与 Inference 严格解耦
3. AI 始终优先处理每一路最新稳定帧
4. 3 个 Gemmini 同时执行不同 Frame / Micro-Batch
5. Rocket 仅承担控制和调度
6. RVV 主要承担 Preprocess / Postprocess
7. 固定模型采用静态执行计划
8. Tensor 地址静态规划
9. 权重全系统只保存一份逻辑副本
10. 三个 Gemmini 分别拥有独立 Activation Arena
11. Gemmini Command / Completion 必须支持异步并行
12. Video DMA / RVV / Gemmini / Postprocess 尽可能流水重叠
13. DDR 带宽和 AXI 仲裁必须可观测、可调优
14. 完整记录三 Gemmini 的 Busy / Stall / Utilization
```

---

# 2. 核心架构原则

系统遵循以下原则：

```text
Fixed Model
+
Static Tensor Plan
+
Latest Frame Scheduling
+
3 Independent Gemmini Workers
+
Frame-Level Parallelism
+
Asynchronous Dispatch
+
RVV Boundary Processing
```

系统第一版不实现：

```text
多模型动态切换
动态 Graph Parser
通用 Operator Registry
复杂 DAG Runtime
跨 Gemmini 的单层矩阵切分
跨 Gemmini 的算子流水
动态 Tensor malloc/free
复杂 Deadline Scheduler
复杂 Work Stealing
复杂 Inter-Batch Layer Scheduling
```

---

# 3. 总体数据流

```text
                Local / HDMI Video Inputs ×16
                           |
                           v
                    Stream Normalizer
                     CH0 ~ CH15
                           |
                           v
                     Async FIFO ×16
                           |
                           v
                Multi-Channel Video DMA
                           |
                           v
                     DDR Frame Store
                           |
                           v
                 LatestFrameTable[16]
                           |
                           v
                  Admission Scheduler
                           |
                           v
                     RVV Preprocess
                           |
                           v
                   Ready Tensor Queue
                           |
              +------------+------------+
              |            |            |
              v            v            v
        Gemmini Worker0 Gemmini Worker1 Gemmini Worker2
           64×64          64×64          64×64
              |            |            |
              +------------+------------+
                           |
                           v
                   Completion Queue
                           |
                           v
                    RVV Postprocess
                           |
                           v
                     Result Manager
                           |
                           v
                      CH0 ~ CH15
```

---

# 4. 架构分层

整个系统划分为七个逻辑平面：

```text
1. Video Ingress Plane
2. Video Memory Plane
3. Frame Scheduling Plane
4. RVV Pre/Post Process Plane
5. Multi-Gemmini Execution Plane
6. Memory / Interconnect Plane
7. Control / Observability Plane
```

其中：

```text
Video Plane
```

只负责稳定接收视频、写入 Frame Store，并维护最新帧状态。

```text
AI Plane
```

只消费当前算力允许处理的最新稳定帧。

二者之间不能因为 Gemmini Busy 而形成直接反压。

---

# 5. Video Ingress Plane

## 5.1 视频输入

系统包含：

```text
CH0 ~ CH15
共 16 路 Video Stream
```

每路：

```text
640 × 480 @ 30 FPS
```

总输入帧率：

```text
16 × 30
=
480 Frame/s
```

推荐统一内部格式：

```text
XRGB8888
4 Byte / Pixel
```

理论 Video Frame Store 写带宽：

```text
640 × 480 × 4 × 30 × 16
=
589,824,000 Byte/s
≈
590 MB/s
```

该数据量只包含视频写入，不包含：

```text
AI Tensor
Gemmini Weight Read
Gemmini Activation Read/Write
Display Read
RVV Read/Write
Postprocess
```

因此系统必须独立分析 AI Memory Wall。

---

# 6. Stream Normalizer

所有输入在进入 Video DMA 之前统一成相同的数据和元数据格式。

推荐：

```c
typedef struct {
    uint32_t stream_id;

    uint64_t frame_id;
    uint64_t timestamp;

    bool sof;
    bool eol;
    bool eof;

    bool valid;
    bool error;
} VideoStreamMeta;
```

Normalizer 之后：

```text
DMA
Scheduler
Runtime
```

不再区分视频源来自本地 Camera 或 HDMI 汇聚输入。

---

# 7. Async FIFO

每路独立 FIFO：

```text
CH0  -> FIFO0
CH1  -> FIFO1
...
CH15 -> FIFO15
```

职责：

```text
Clock Domain Crossing
Burst Aggregation
Traffic Buffering
Input Jitter Isolation
Short-term Backpressure Absorption
```

FIFO 不承担完整帧缓存。

---

# 8. Video Memory Plane

## 8.1 Multi-Channel Video DMA

推荐采用：

```text
16 Stream Context
+
少量共享 AXI Write Engine
```

第一版建议：

```text
16 Stream Context
+
2 AXI Write Engines
```

DMA 仲裁应考虑：

```text
FIFO Watermark
Age
Burst Length
Deadline
Per-stream Credit
AXI Outstanding
QoS
```

目标：

```text
高 AXI Efficiency
无长期 Starvation
无持续 FIFO Overflow
单路异常不影响其他 Stream
```

---

# 9. DDR Frame Store

每路使用 Triple Buffer：

```text
CH0  : F0 F1 F2
CH1  : F0 F1 F2
...
CH15 : F0 F1 F2
```

推荐元数据：

```c
typedef struct {
    uint32_t stream_id;

    uint64_t frame_id;
    uint64_t timestamp;

    uintptr_t addr;

    uint32_t version;
    uint32_t refcount;
    uint32_t state;
} FrameBufferMeta;
```

Frame Buffer 只有在：

```text
refcount == 0
且
不再作为 Latest Frame
```

时允许被 Video DMA 重用。

---

# 10. Latest Frame Table

每个 Stream 对 AI 只暴露一个最新稳定 Frame。

```c
typedef struct {
    uint32_t stream_id;

    uint64_t frame_id;
    uint64_t timestamp;

    uintptr_t frame_addr;

    uint32_t version;

    bool valid;
    bool error;
} LatestFrameEntry;
```

原则：

```text
New Frame
覆盖
Old AI Candidate
```

而不是建立无限增长的 AI Frame Queue。

AI Service Rate 低于 Capture Rate 时：

```text
旧 Frame 自动 Supersede
```

---

# 11. Capture / Inference 解耦

Video Plane：

```text
固定接收
16 × 30 FPS
=
480 FPS
```

Inference Plane：

```text
实际处理能力
由
3 Gemmini + RVV + DDR + Runtime
共同决定
```

AI 过载时允许：

```text
Frame Supersede
Frame Skip
Frame Drop
```

但不允许：

```text
Gemmini Busy
    ↓
Camera Backpressure
```

---

# 12. Frame Scheduling Plane

调度器只做 Frame-Level Admission。

核心输入：

```text
LatestFrameTable[16]
```

核心输出：

```text
FrameJob
```

第一版不建立：

```text
Per-Layer Ready Queue
Node Scheduler
Cross-Frame Layer Candidate Table
Dynamic Device Binding
```

Scheduler 只回答一个问题：

```text
“下一份可执行 AI Job 应该来自哪个 Stream？”
```

---

# 13. StreamContext

推荐：

```c
typedef struct {
    uint32_t stream_id;

    uint64_t latest_frame_id;
    uint64_t last_inferred_frame_id;

    uint64_t capture_frames;
    uint64_t inferred_frames;
    uint64_t superseded_frames;

    uint64_t last_service_cycle;
    uint64_t last_job_id;

    uint32_t inflight_jobs;

    bool enabled;
} StreamContext;
```

---

# 14. FrameJob

第一版以单 Frame Job 为基础。

```c
typedef struct {
    uint64_t job_id;

    uint32_t stream_id;
    uint64_t frame_id;
    uint64_t timestamp;

    uintptr_t frame_addr;
    uintptr_t input_tensor_addr;
    uintptr_t output_tensor_addr;

    uint32_t worker_id;

    uint64_t admit_cycle;
    uint64_t preprocess_start_cycle;
    uint64_t preprocess_end_cycle;
    uint64_t compute_start_cycle;
    uint64_t compute_end_cycle;
    uint64_t postprocess_end_cycle;

    uint32_t state;
} FrameJob;
```

后续若启用 B=2 / B=4，可扩展为：

```text
MicroBatchJob
```

但不改变总体 Worker 架构。

---

# 15. Admission Scheduler

第一版推荐采用：

```text
Latest Frame
+
Fairness
+
No Duplicate Inflight
```

基本条件：

```text
Stream Enabled
Latest Frame Valid
Latest Frame 未被当前 Inflight Job 使用
```

优先级可简单定义为：

```text
Priority
=
Service Gap
+
Fresh Frame Bonus
+
Stream Priority
```

第一版最重要的是：

```text
16 路不会长期饥饿
+
永远优先处理较新的 Frame
```

---

# 16. 推荐的公平调度策略

推荐采用：

```text
Oldest-Served-First
```

即优先选择：

```text
距离上一次成功推理时间最长
```

的 Stream。

如果多个 Stream Service Gap 接近，则优先：

```text
frame_id 更新
```

的 Stream。

这样可以避免固定划分：

```text
G0 -> CH0~CH5
G1 -> CH6~CH10
G2 -> CH11~CH15
```

所造成的负载不均衡。

三个 Gemmini Worker 都可以执行任意 Stream。

---

# 17. RVV Preprocess Plane

Saturn RVV 负责主要向量化预处理：

```text
Resize
Color Convert
Normalization
Quantization
Layout
Padding
```

推荐数据路径：

```text
DDR Frame Store
      |
      v
Saturn RVV
      |
      v
INT8 Model Input Tensor
      |
      v
Ready Tensor Queue
```

Rocket 不承担大规模 Pixel / Tensor 运算。

---

# 18. Preprocess Input Ring

为了避免 Gemmini 等待 RVV，推荐准备独立 Input Ring。

第一版推荐：

```text
InputSlot[6]
```

其意义：

```text
最多 3 个 Job
正在 Gemmini Compute

同时最多 3 个 Job
已完成或正在完成 Preprocess
```

形成：

```text
Compute Jobs
+
Ready / Preparing Jobs
```

两级流水。

Input Slot 必须有明确 Ownership。

推荐：

```text
FREE
PREPROCESSING
READY
IN_GEMMINI
RELEASING
FREE
```

---

# 19. Multi-Gemmini Execution Plane

系统包含：

```text
Gemmini0 : 64×64
Gemmini1 : 64×64
Gemmini2 : 64×64
```

三个 Gemmini 是三个独立 Inference Worker。

每个 Worker：

```text
运行相同 Fixed Model
使用相同 Layer Table
使用相同 Kernel
读取相同逻辑 Weight Region
使用独立 Activation Arena
使用独立 Execution Context
```

核心并行方式：

```text
Frame A -> Gemmini0
Frame B -> Gemmini1
Frame C -> Gemmini2
```

而不是：

```text
一个 Frame 的不同 Layer
分散到三个 Gemmini
```

---

# 20. GemminiWorker

推荐：

```c
typedef enum {
    WORKER_IDLE,
    WORKER_RESERVED,
    WORKER_RUNNING,
    WORKER_WAIT_COMPLETION,
    WORKER_DONE,
    WORKER_ERROR
} WorkerState;

typedef struct {
    uint32_t worker_id;
    uint32_t gemmini_id;

    WorkerState state;

    uint64_t job_id;

    uint32_t stream_id;
    uint64_t frame_id;

    uint32_t current_layer;

    uintptr_t arena_base;
    uintptr_t input_addr;
    uintptr_t output_addr;

    uint64_t dispatch_cycle;
    uint64_t start_cycle;
    uint64_t end_cycle;
} GemminiWorker;
```

系统：

```c
GemminiWorker workers[3];
```

---

# 21. Worker Pool

Worker Pool 提供：

```text
worker0
worker1
worker2
```

统一接口：

```c
GemminiWorker *find_idle_worker(void);

bool dispatch_job(GemminiWorker *worker,
                  FrameJob *job);

void service_worker_completion(void);
```

Scheduler 不关心：

```text
Job 必须固定去 Gemmini0 / 1 / 2
```

而只关心：

```text
哪个 Worker Idle
```

---

# 22. 固定模型执行

模型在编译期固定。

Runtime 启动后不执行：

```text
Parse Graph
Build DAG
Infer Tensor Shape
Dynamic Device Binding
Dynamic Memory Allocation
```

而直接使用：

```text
Static Layer Table
+
Static Tensor Table
+
Static Weight Table
+
Static Kernel Entry
```

---

# 23. Static Layer Table

推荐：

```c
typedef enum {
    DEV_GEMMINI,
    DEV_RVV,
    DEV_CPU
} DeviceType;

typedef struct {
    uint32_t layer_id;
    uint32_t op_type;

    DeviceType device;

    uint32_t input_h;
    uint32_t input_w;
    uint32_t input_c;

    uint32_t output_h;
    uint32_t output_w;
    uint32_t output_c;

    uint32_t kernel_h;
    uint32_t kernel_w;

    uint32_t stride_h;
    uint32_t stride_w;

    uint32_t padding;

    uint32_t input_tensor;
    uint32_t output_tensor;

    uintptr_t weight_addr;
    size_t weight_size;

    void *kernel_entry;
} LayerConfig;
```

固定：

```c
static const LayerConfig g_model_layers[NUM_LAYERS];
```

---

# 24. Gemmini Device Mapping

Layer Table 中：

```text
DEV_GEMMINI
```

只表示该 Layer 运行在当前 Worker 所绑定的 Gemmini。

实际调用：

```c
run_gemmini_layer(
    worker->gemmini_id,
    layer,
    worker->arena_base
);
```

因此：

```text
Model Definition
```

与：

```text
Gemmini Worker ID
```

保持解耦。

---

# 25. 模型内部 RVV 使用原则

推荐模型主体尽可能：

```text
Gemmini
Gemmini
Gemmini
...
Gemmini
```

RVV 主要位于模型边界：

```text
RVV Preprocess
      |
      v
Gemmini Fixed Model
      |
      v
RVV Postprocess
```

尽量避免：

```text
Gemmini
  ↓
RVV
  ↓
Gemmini
  ↓
RVV
  ↓
Gemmini
```

原因是整个系统只有一个 Saturn RVV。

如果三个 Gemmini 在模型中间频繁请求 RVV，会导致：

```text
RVV Serialization
```

并可能成为全系统共享瓶颈。

---

# 26. RVV Postprocess Plane

推荐由 Saturn RVV 承担可向量化部分：

```text
Decode
Coordinate Restore
Candidate Filter
部分 NMS
Result Packing
```

Rocket CPU 只负责：

```text
Control
Small Scalar Branch
Metadata
Result Publish
```

---

# 27. RVV Task Scheduler

RVV 至少维护两类任务：

```text
Preprocess Queue
Postprocess Queue
```

推荐优先级：

```text
如果 Gemmini 即将缺少 Ready Tensor
    ↓
优先 Preprocess

否则
    ↓
执行 Postprocess
```

优化目标：

```text
优先避免 Gemmini Starvation
```

因为三个 Gemmini 同时 Idle 的代价高于结果稍晚发布。

---

# 28. 异步 Gemmini Dispatch

Rocket 必须支持：

```text
Launch G0
Launch G1
Launch G2
```

之后继续执行其他 Runtime 工作。

不能采用：

```text
Launch G0
Wait G0
Launch G1
Wait G1
Launch G2
Wait G2
```

否则三个 Gemmini 无法形成实际并行。

---

# 29. Gemmini Command Interface

建议每个 Gemmini 具有独立：

```text
Command FIFO
Busy State
Completion State
Status Register
IRQ / Polling Interface
```

概念结构：

```text
               Rocket
                  |
          Multi-Gemmini Dispatch
          /        |        \
         v         v         v
      CmdQ0     CmdQ1     CmdQ2
         |         |         |
         v         v         v
        G0        G1        G2
```

P0 可以先采用 Polling Completion。

稳定后推荐：

```text
IRQ
+
Completion Queue
```

---

# 30. Command Credit

为避免 Rocket 对满队列发送命令：

```text
Gemmini0 Credit
Gemmini1 Credit
Gemmini2 Credit
```

CPU 发命令前检查：

```text
credit > 0
```

推荐最终形成：

```text
Credit-based Command Submission
```

以减少：

```text
RoCC Blocking
CPU Stall
Command Serialization
```

---

# 31. CONFIG Persistence

固定模型推理中大量 Layer 配置具有重复性。

推荐将：

```text
数据流模式
Stride
Scale
Activation
DMA 参数
部分 Loop 参数
```

按照实际可复用范围进行：

```text
Persistent Configuration
或
Incremental Configuration
```

目标：

```text
减少每个 Tile / Block 的重复 CONFIG Command
```

对三个 Gemmini 应分别维护：

```text
CurrentConfigState[3]
```

只有配置变化时重新发送必要字段。

---

# 32. Completion Queue

推荐：

```c
typedef struct {
    uint32_t worker_id;
    uint32_t gemmini_id;

    uint64_t job_id;

    uint32_t layer_id;
    uint32_t status;

    uint64_t start_cycle;
    uint64_t end_cycle;
} GemminiCompletion;
```

Completion Manager 负责：

```text
1. 更新 Worker State
2. 更新 Job State
3. 推进下一 Layer
4. 模型完成后进入 Postprocess Queue
5. 释放 Worker
```

---

# 33. 三 Gemmini 并行模型

稳定状态下：

```text
时间 T0

G0 : Job A
G1 : Job B
G2 : Job C

RVV : Preprocess Job D
```

随后：

```text
时间 T1

G0 : Job D
G1 : Job E
G2 : Job F

RVV : Postprocess A
或
RVV : Preprocess G
```

系统的核心目标：

```text
尽量减少任何 Worker 的 IDLE Gap
```

---

# 34. Batch 策略

第一版基线：

```text
Per Worker Batch = 1
```

即：

```text
G0 : B1
G1 : B1
G2 : B1
```

系统最多：

```text
3 Samples Concurrent
```

后续 Profiling：

```text
B = 1
B = 2
B = 4
```

如果 B=2：

```text
3 Worker × 2
=
6 Samples Concurrent
```

如果 B=4：

```text
3 Worker × 4
=
12 Samples Concurrent
```

Batch 在本架构中只是：

```text
Worker 内部 Micro-Batch 优化
```

而不是整个 Runtime 的中心结构。

---

# 35. Batch Size 选择指标

每个 B 都必须测：

```text
Total FPS
Per-stream FPS
Latency
Cycles / Frame
Array Utilization
DMA Stall
Weight Bytes / Frame
Activation Bytes / Frame
Memory Peak
RVV Pressure
```

最终寻找：

```text
Throughput
Latency
Memory
Array Utilization
```

之间的 Sweet Spot。

---

# 36. 64×64 Gemmini 理论峰值

单个 64×64：

```text
64 × 64
=
4096 MAC / cycle
```

目标频率：

```text
200 MHz
```

理论：

```text
4096 × 200M
=
819.2 GMAC/s
```

若：

```text
1 MAC = 2 OPS
```

则：

```text
1 Gemmini
=
1.6384 TOPS
```

三个：

```text
3 × 1.6384
=
4.9152 TOPS INT8
```

该数值只是 PE 峰值，不代表模型有效性能。

实际取决于：

```text
M / N / K Shape
Array Utilization
SPAD
ACC
DMA
DDR
Weight Reuse
Activation Reuse
Command Bubble
Worker Imbalance
```

---

# 37. Static Tensor Memory Plan

固定模型意味着：

```text
Tensor Shape 固定
Tensor Lifetime 固定
Tensor Dependency 固定
```

所以 Tensor 地址必须离线规划。

推荐：

```c
typedef struct {
    uint32_t tensor_id;

    size_t offset;
    size_t size;

    uint32_t producer_layer;
    uint32_t last_consumer_layer;

    uint32_t reuse_group;
} TensorDesc;
```

---

# 38. 三 Worker Activation Arena

每个 Worker 独立拥有：

```text
Worker Arena 0
Worker Arena 1
Worker Arena 2
```

每个 Arena 使用相同 Tensor Offset。

执行：

```c
tensor_addr =
    worker->arena_base
    + tensor_desc[tensor_id].offset;
```

因此：

```text
Tensor Layout
```

只需要规划一次。

三 Worker 仅使用不同：

```text
arena_base
```

---

# 39. Tensor Lifetime Reuse

固定模型允许离线分析：

```text
Producer
Last Consumer
```

当 Tensor 生命周期结束：

```text
对应 Arena 空间立即可被后续 Tensor 复用
```

目标：

```text
降低单 Worker Activation Peak
```

从而降低三个 Worker 总 DDR 占用。

---

# 40. Weight Region

全系统只维护一个逻辑 Weight Region：

```text
Storage
   |
   v
DDR Weight Region
   |
   +------> Gemmini0
   |
   +------> Gemmini1
   |
   +------> Gemmini2
```

不为三个 Worker 建立三个软件 Weight Copy。

但每个 Gemmini：

```text
SPAD / Internal Weight Buffer
```

彼此独立。

---

# 41. Weight Residency

每个 Gemmini 内部尽量：

```text
Load Weight Tile
      |
      v
Process 更多 Activation Tile
      |
      v
再切换 Weight Tile
```

Micro-Batch 可进一步增加：

```text
同一 Weight Tile
跨多个 Sample 复用
```

必须记录：

```text
Weight Reload Bytes
Weight Reload Ratio
```

---

# 42. SPAD / ACC 原则

64×64 INT8 基本 Tile：

```text
A:
64 × 64 × 1 Byte
=
4 KiB

B:
64 × 64 × 1 Byte
=
4 KiB
```

INT32 Accumulator：

```text
64 × 64 × 4 Byte
=
16 KiB
```

因此单 64×64 Worker 的片上存储压力明显低于超大阵列。

但必须结合：

```text
K Tile
Double Buffer
Weight Residency
DMA Overlap
ACC Capacity
```

确定最终 SPAD / ACC 配置。

---

# 43. SPAD Double Buffer

目标：

```text
Compute Tile N
        ||
Load Tile N+1
```

推荐：

```text
SPAD Bank A
SPAD Bank B
```

循环：

```text
A Compute
B Prefetch

B Compute
A Prefetch
```

每个 Gemmini 独立进行。

必须记录：

```text
DMA Stall Cycles
Compute Cycles
Overlap Ratio
```

---

# 44. 总体 Pipeline

稳定后目标：

```text
Stage 0
Video DMA
         ||
Stage 1
RVV Preprocess
         ||
Stage 2
Gemmini0 / Gemmini1 / Gemmini2
         ||
Stage 3
RVV Postprocess
```

理想状态：

```text
Video DMA 持续采集

RVV 正在 Preprocess Job N+3

G0 正在执行 Job N
G1 正在执行 Job N+1
G2 正在执行 Job N+2

前一 Job 正等待 / 执行 Postprocess
```

---

# 45. Runtime 主循环

Runtime 应采用 Event-driven / Non-blocking 思路。

概念代码：

```c
while (1) {

    update_latest_frames();

    service_gemmini_completions();

    service_rvv_completion();

    admit_new_frames();

    schedule_preprocess();

    dispatch_ready_jobs_to_idle_workers();

    schedule_postprocess();

    publish_completed_results();

    update_metrics();
}
```

核心原则：

```text
Gemmini Busy
!=
Rocket Busy
```

---

# 46. Runtime 禁止动态 malloc/free

运行期：

```text
禁止动态 malloc/free
```

所有主要区域 Boot 时一次性建立：

```text
Video Frame Buffer
Latest Frame Table
StreamContext
FrameJob Pool
Input Ring
Worker Arena ×3
Weight Region
Output Ring
Completion Queue
Metrics Buffer
```

运行时只改变：

```text
state
owner
version
index
```

---

# 47. Memory Layout

推荐 DDR AI 区域：

```text
DDR
|
├── Video Frame Store
|
├── Weight Region
|
├── Worker Arena 0
|
├── Worker Arena 1
|
├── Worker Arena 2
|
├── Preprocess Input Ring
|
├── Output Ring
|
├── Job / Completion Metadata
|
└── Metrics / Trace Buffer
```

---

# 48. DDR / AXI 访问主体

系统可能同时存在：

```text
Video DMA Write
Display DMA Read
RVV Read / Write
Gemmini0 DMA
Gemmini1 DMA
Gemmini2 DMA
Rocket Cached Access
```

因此 DDR / AXI 仲裁属于系统关键设计。

---

# 49. Gemmini DMA 独立性

三个 Gemmini 必须至少拥有独立：

```text
DMA State
AXI Transaction ID
Outstanding Counter
Command State
Performance Counter
```

理想：

```text
G0 DMA
G1 DMA
G2 DMA
```

可以同时产生 AXI Request。

避免：

```text
3 Compute Engines
+
1 Serial DMA Frontend
```

导致计算资源被内存前端串行化。

---

# 50. AXI Interconnect

推荐：

```text
                       DDR Controller
                             |
                        AXI Interconnect
        +---------+----------+----------+----------+
        |         |          |          |          |
     Video DMA   RVV        G0         G1         G2
```

Rocket 控制访问走独立轻量路径。

---

# 51. AXI QoS

推荐目标：

```text
Video / Display
保证实时带宽

Gemmini0 / 1 / 2
Weighted Fair

RVV
Weighted Fair
```

不建议简单地：

```text
AI 永久最高优先级
```

否则可能造成视频 FIFO Overflow / Display Underflow。

也不建议：

```text
Video 永久压制 AI
```

否则三 Gemmini 可能长期 DMA Stall。

---

# 52. Outstanding

对以下 Master 分别记录：

```text
G0 Outstanding
G1 Outstanding
G2 Outstanding
RVV Outstanding
Video DMA Outstanding
```

优化参数：

```text
Outstanding Depth
Burst Length
AXI ID
Read / Write Arbitration
QoS Weight
```

必须通过实测确定。

---

# 53. Backpressure Domain

定义：

```text
Video Ingress Backpressure
RVV Queue Backpressure
Gemmini Worker Backpressure
DDR Backpressure
```

原则：

```text
Gemmini Busy
不能传播到 Camera
```

当三个 Gemmini 全部 Busy：

```text
停止新的 Compute Dispatch
```

但：

```text
Video DMA
Frame Store
Latest Frame Table
```

继续工作。

---

# 54. Result Metadata

每个 AI Result 必须保留：

```text
stream_id
frame_id
source_timestamp
job_id
worker_id
```

推荐：

```c
typedef struct {
    uint32_t stream_id;

    uint64_t frame_id;
    uint64_t timestamp;

    uint64_t job_id;
    uint32_t worker_id;

    uint32_t detection_count;

    uintptr_t result_addr;
} InferenceResultMeta;
```

必须保证 AI Result 能准确映射回：

```text
原始 Stream
原始 Frame
```

---

# 55. Result Publish

Postprocess 完成后：

```text
Result Manager
```

执行：

```text
Result Demux
Metadata Attach
Per-stream Latest Result Update
Display / Control Publish
```

不要求结果按照 Job 提交顺序完成。

允许：

```text
Job 102
先于
Job 101
完成
```

只要元数据正确。

---

# 56. Observability

多 Gemmini 系统不能只看：

```text
Total FPS
```

必须建立完整的：

```text
Stream
Job
Worker
Layer
RVV
DDR
System
```

多级性能统计。

---

# 57. Stream 级指标

每路：

```text
Capture FPS
Inference FPS
Latest Frame Age
Superseded Frames
Average Service Gap
Max Service Gap
End-to-End Latency
```

---

# 58. Job 级指标

每个 FrameJob：

```text
Admit Time
Preprocess Queue Time
Preprocess Time
Ready Queue Time
Gemmini Dispatch Time
Compute Time
Postprocess Queue Time
Postprocess Time
Total Latency
```

---

# 59. Worker 级指标

每个 Gemmini：

```text
Busy Cycles
Idle Cycles
Compute Cycles
DMA Stall Cycles
Command Stall Cycles
Array Active Ratio
Jobs Completed
Frames / s
Weight Reload Bytes
Activation Read Bytes
Output Write Bytes
SPAD Usage
ACC Usage
```

---

# 60. 三 Worker 联合指标

必须额外记录：

```text
3 Busy Ratio
2 Busy Ratio
1 Busy Ratio
0 Busy Ratio
```

即：

```text
同时三个 Gemmini Busy 的时间比例
```

该指标定义为：

```text
3-Gemmini Concurrent Busy Ratio
```

这是系统最重要的多 Worker KPI 之一。

---

# 61. Worker Imbalance

记录：

```text
G0 Jobs
G1 Jobs
G2 Jobs

G0 Busy
G1 Busy
G2 Busy
```

计算：

```text
Worker Imbalance
```

如果长期出现：

```text
G0 90%
G1 60%
G2 45%
```

必须检查：

```text
Scheduler
DDR Arbitration
Command Queue
Worker Hardware
```

---

# 62. RVV 指标

记录：

```text
RVV Busy Ratio
Preprocess Cycles
Postprocess Cycles
Queue Depth
Preprocess Wait
Postprocess Wait
Gemmini Starvation Caused by RVV
```

关键问题：

```text
唯一 RVV 是否成为三 Gemmini 的共享瓶颈？
```

---

# 63. DDR 指标

必须能够分 Master 统计：

```text
Video Read / Write
RVV Read / Write
G0 Read / Write
G1 Read / Write
G2 Read / Write

Average Outstanding
Max Outstanding
Read Stall
Write Stall
Bandwidth
```

---

# 64. Layer 级 Profiling

每个 Gemmini Layer：

```text
Layer Cycles

M
N
K

M Tile Count
N Tile Count
K Tile Count

M Utilization
N Utilization

Mvin Bytes
Mvout Bytes
Weight Bytes

DMA Stall Cycles
Compute Cycles

SPAD Usage
ACC Usage
```

---

# 65. 核心 KPI

第一版最重要指标：

```text
1. End-to-End Total FPS
2. Per-stream Inference FPS
3. 3-Gemmini Concurrent Busy Ratio
4. G0 / G1 / G2 Busy Ratio
5. Array Utilization
6. DMA Stall Ratio
7. RVV Busy Ratio
8. RVV-caused Gemmini Starvation
9. DDR Bandwidth
10. End-to-End Latency
```

系统必须能够明确回答：

```text
“Gemmini 为什么空闲？”
```

而不是只知道：

```text
“FPS 不够。”
```

---

# 66. FPGA Physical Design 原则

三个 64×64 Gemmini 应尽量物理独立。

每个 Worker 尽量将：

```text
PE Array
SPAD
ACC
Local DMA Logic
Command Logic
```

放置在相邻区域。

目标：

```text
降低 Long Route
降低 High Fanout
降低 SLR Crossing
降低 Placement Congestion
```

---

# 67. SLR Floorplan

推荐针对 VU13P 做：

```text
Gemmini0 Region
Gemmini1 Region
Gemmini2 Region
```

三个 Region 尽量避免 PE Mesh 互相跨越。

CPU / RVV / Shared Interconnect 放置需要结合：

```text
DDR Interface
NoC / AXI Position
SLR Boundary
Clock Region
```

统一考虑。

最终必须查看：

```text
SLR Crossing
Route Congestion
WNS
TNS
Fmax
```

---

# 68. Hardware Bring-up

P0 首先验证单个 64×64 Gemmini：

```text
Elaboration
Synthesis
Implementation
Timing
```

记录：

```text
LUT
FF
DSP
BRAM
URAM
WNS
TNS
Fmax
```

随后生成：

```text
3 × 64×64 Gemmini
```

重新完成：

```text
Implementation
Timing
SLR Distribution
Routing Congestion
```

---

# 69. 三 Gemmini 并行硬门槛

在进入复杂 Runtime 优化前必须证明：

```text
Rocket
 |
 +--> Launch G0
 |
 +--> Launch G1
 |
 +--> Launch G2
```

且：

```text
G0 Busy
G1 Busy
G2 Busy
```

真实存在重叠时间。

验收：

```text
三个 Gemmini 可以独立启动
三个 Gemmini 可以同时 Busy
CPU 不因单 Worker 执行长期阻塞
Completion 可以区分 G0/G1/G2
结果不存在 Worker 串扰
```

---

# 70. P0：单 Worker Functional Baseline

首先：

```text
Latest Frame
    |
    v
RVV Preprocess
    |
    v
Gemmini0
    |
    v
RVV Postprocess
    |
    v
Result
```

目的：

```text
验证模型正确
验证量化正确
验证 Tensor Layout
验证 Static Layer Table
验证 Static Arena
验证 Gemmini Kernel
```

---

# 71. P0：三个 Worker 独立验证

依次：

```text
G0 单独运行
G1 单独运行
G2 单独运行
```

要求：

```text
输入相同
输出一致
Cycles 接近
DMA 行为一致
```

用于排除：

```text
实例配置不同
地址映射错误
RoCC ID 错误
局部硬件问题
```

---

# 72. P1：3 Worker Concurrent B1

启动：

```text
Job0 -> G0
Job1 -> G1
Job2 -> G2
```

验收：

```text
三 Worker 真并行
无共享状态冲突
无 Arena 覆盖
无 Completion 串 Worker
无 Result 串 Frame
```

并记录：

```text
1 Worker FPS
vs
3 Worker Aggregate FPS
```

---

# 73. P1：16 Stream Scheduler

加入：

```text
LatestFrameTable[16]
+
Admission Scheduler
+
3 Worker Pool
```

验收：

```text
16 路都能获得服务
异常 Camera 不阻塞系统
Old Frame 可被 Supersede
不会重复处理同一 Frame
不会长期 Starvation
```

---

# 74. P1：RVV / Gemmini Pipeline

加入：

```text
Input Ring
Preprocess Queue
Postprocess Queue
```

目标：

```text
RVV Preprocess
与
3 Gemmini Compute
真实重叠
```

验收：

```text
Gemmini 不因每帧 Preprocess 长期 Idle
Input Slot Ownership 正确
无 Tensor 覆盖
```

---

# 75. P2：Command 优化

重点：

```text
Asynchronous Dispatch
Credit-based Submission
CONFIG Persistence
Incremental Configuration
Command Queue Depth
```

目标：

```text
降低 Rocket Command Stall
降低 RoCC Blocking
降低每 Layer / Tile 控制 Bubble
```

---

# 76. P2：Memory Wall 优化

严格通过 Profiling 决定：

```text
Weight Prefetch
Activation Prefetch
SPAD Double Buffer
ACC Tuning
AXI Outstanding
Burst Length
QoS
DDR Arbitration
```

每次只修改一个主要变量。

---

# 77. P2：Batch Size Sweep

测试：

```text
Per Worker:

B = 1
B = 2
B = 4
```

记录：

```text
Total FPS
Cycles / Frame
Latency
Memory Peak
Array Utilization
Weight Traffic / Frame
DMA Stall
RVV Pressure
```

再决定是否需要：

```text
Dynamic Micro-Batch
```

---

# 78. P3：Dynamic Micro-Batch

只有 Profiling 证明：

```text
固定 B1 / B2
无法同时满足吞吐和延迟
```

才引入：

```text
Dynamic Micro-Batch Builder
```

策略可以考虑：

```text
preferred_batch
Gemmini Idle
Batch Window Expire
Frame Deadline
```

第一版不需要。

---

# 79. P3：高级 QoS

只有基本架构稳定后再考虑：

```text
target_ai_fps
stream_priority
max_service_gap
deadline
camera class
```

第一版：

```text
Latest Frame
+
Fairness
+
No Blocking
```

即可。

---

# 80. Boot 生命周期

```text
System Boot
    |
    v
Load Hardware Facts
    |
    v
Verify CPU / RVV / 3 Gemmini
    |
    v
Init Gemmini Command Interface
    |
    v
Load Fixed Weights
    |
    v
Init Static Layer Table
    |
    v
Init Tensor Table
    |
    v
Init Worker Arena ×3
    |
    v
Init Input / Output Ring
    |
    v
Init Video Plane
    |
    v
Start Capture
    |
    v
Start Runtime Scheduler
```

---

# 81. Runtime 生命周期

```text
Latest Frame Update
        |
        v
Admission
        |
        v
RVV Preprocess
        |
        v
Ready Queue
        |
        v
Find Idle Worker
        |
        v
Async Gemmini Dispatch
        |
        v
G0 / G1 / G2 Compute
        |
        v
Completion
        |
        v
RVV Postprocess
        |
        v
Publish Result
        |
        v
Release Frame / Tensor
        |
        v
Next Job
```

多个 Job 可以同时处于不同阶段。

---

# 82. Runtime 目录建议

```text
runtime/
├── include/
│   ├── hw_facts.h
│   ├── stream.h
│   ├── frame_job.h
│   ├── worker.h
│   ├── model.h
│   ├── memory.h
│   ├── rvv.h
│   └── metrics.h
│
├── video/
│   ├── stream_normalizer.c
│   ├── video_dma.c
│   ├── frame_store.c
│   └── latest_frame.c
│
├── scheduler/
│   ├── admission.c
│   ├── fairness.c
│   ├── ready_queue.c
│   └── job_pool.c
│
├── preprocess/
│   ├── preprocess.c
│   ├── resize_rvv.c
│   ├── quant_rvv.c
│   └── input_ring.c
│
├── model/
│   ├── fixed_model.c
│   ├── layer_table.c
│   ├── tensor_table.c
│   └── weight_table.c
│
├── exec/
│   ├── worker_pool.c
│   ├── gemmini_exec.c
│   ├── gemmini_cmd.c
│   ├── completion.c
│   └── config_cache.c
│
├── rvv/
│   ├── rvv_scheduler.c
│   └── rvv_completion.c
│
├── mem/
│   ├── arena.c
│   ├── tensor_layout.c
│   ├── weight_region.c
│   └── ring_buffer.c
│
├── postprocess/
│   ├── decode_rvv.c
│   ├── nms.c
│   ├── result_manager.c
│   └── result_demux.c
│
├── metrics/
│   ├── trace.c
│   ├── stream_metrics.c
│   ├── worker_metrics.c
│   ├── layer_metrics.c
│   ├── rvv_metrics.c
│   ├── ddr_metrics.c
│   └── export.c
│
└── main.c
```

---

# 83. Static Model Build Flow

推荐：

```text
Fixed Model
   |
   v
Offline Converter / Compiler
   |
   +--> weights.bin
   |
   +--> model_layers.c
   |
   +--> model_layers.h
   |
   +--> tensor_layout.h
   |
   +--> quant_params.h
   |
   +--> gemmini_kernels.o
   |
   `--> rvv_kernels.o
```

Runtime 不解析复杂模型格式。

---

# 84. Compiler / Runtime 边界

编译器负责：

```text
Fixed Model Graph
Operator Lowering
Tiling
Mvin / Mvout
Scratchpad Planning
Weight Layout
Tensor Lifetime
Tensor Offset
Quantization Parameter
Gemmini Kernel Generation
RVV Kernel Generation
```

Runtime 负责：

```text
Frame Admission
Latest Frame Selection
RVV Preprocess
Worker Dispatch
Completion Handling
Static Model Execution
RVV Postprocess
Result Publish
Performance Metrics
```

---

# 85. 第一阶段验收指标

## Video

```text
16 × 640×480@30 FPS 稳定输入
无持续 FIFO Overflow
无系统性 Frame Corruption
单路异常不拖死其他通道
```

## Scheduler

```text
Latest Frame 正确
16 Stream 公平
无重复 Frame Job
无长期 Starvation
```

## RVV

```text
Preprocess 正确
Postprocess 正确
Pre/Post Queue 正确
不会造成严重 Gemmini Starvation
```

## Gemmini

```text
G0 正确
G1 正确
G2 正确
三 Worker 可以同时 Busy
```

## Memory

```text
Worker Arena 相互独立
Weight Region 地址正确
无 Tensor 覆盖
无非法 Frame 覆盖
```

---

# 86. 性能验收

必须得到：

```text
Single Worker FPS
3 Worker Aggregate FPS

G0 Busy Ratio
G1 Busy Ratio
G2 Busy Ratio

3-Gemmini Concurrent Busy Ratio

RVV Busy Ratio
DDR Bandwidth
DMA Stall Ratio

Per-stream FPS
End-to-End Latency
```

系统最终性能不能只用：

```text
理论 4.9152 TOPS
```

评价。

必须以：

```text
有效 FPS
有效 Array Utilization
有效并发比例
Memory Stall
End-to-End Latency
```

评价。

---

# 87. 当前最关键的工程问题

当前优先级最高的五个问题：

```text
1. Rocket 能否非阻塞地同时驱动三个 Gemmini？
2. 三个 Gemmini 的 DMA 是否真正可以并行访问 DDR？
3. 一个 Saturn RVV 是否能够及时为三个 Gemmini 提供 Preprocess？
4. DDR / AXI 是否能够支撑 Video + RVV + G0/G1/G2 的并发流量？
5. 三个 64×64 Gemmini 在 VU13P 上能否实现合理的 Placement / Timing？
```

其中第一项属于架构成立的硬门槛。

---

# 88. 当前推荐实施顺序

```text
Step 1
单 Gemmini64 + B1 Fixed Model

Step 2
三个 Gemmini 分别单独验证

Step 3
三个 Gemmini 异步同时运行

Step 4
建立 Worker Pool

Step 5
接入 16 Stream Latest Frame Scheduler

Step 6
接入 RVV Preprocess

Step 7
建立 Input Ring / Pipeline

Step 8
接入 RVV Postprocess

Step 9
建立完整 Metrics

Step 10
分析 DDR / DMA Stall

Step 11
CONFIG Persistence / Credit Scheduler

Step 12
Weight / Activation Prefetch

Step 13
B1 / B2 / B4 Sweep

Step 14
根据 Profiling 决定是否增加 Dynamic Micro-Batch / 高级 QoS
```

---

# 89. 最终系统定义

```text
16 路 Video
    |
    v
Video DMA / Triple Frame Store
    |
    v
LatestFrameTable[16]
    |
    v
Fair Admission Scheduler
    |
    v
Saturn RVV Preprocess
    |
    v
Ready Tensor Queue
    |
    +----------------+----------------+
    |                |                |
    v                v                v
Gemmini0          Gemmini1          Gemmini2
64×64             64×64             64×64
    |                |                |
    +----------------+----------------+
                     |
                     v
              Completion Manager
                     |
                     v
             Saturn RVV Postprocess
                     |
                     v
               Result Manager
                     |
                     v
                 CH0~CH15
```

系统定位：

```text
1 Rocket RV64
+
1 Saturn RVV
+
3 × Gemmini 64×64
+
16-Stream Latest-Frame Runtime
+
3-Worker Frame-Level Parallelism
+
Static Fixed-Model Execution
+
Per-Worker Static Tensor Arena
+
Single Logical Weight Region
+
Asynchronous Gemmini Dispatch
+
RVV / Gemmini Pipeline
+
B1 Baseline
+
Optional B2 / B4 Micro-Batch
```

核心目标：

```text
让三个 Gemmini 尽可能持续同时 Busy，
同时保证 16 路视频公平、低积压、始终处理最新帧，
并通过 RVV / DDR / DMA 流水消除计算资源等待。
```
