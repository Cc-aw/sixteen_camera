# 16 路 640P 多 Gemmini 推理系统总体架构（Runtime 融合版）

> **版本：V2.0**  
> **目标平台：XCVU13P + Rocket RV64 + Saturn RVV + Multi-Gemmini**  
> **视频规模：8 路本地视频 + 8 路 HDMI 汇聚视频，共 16 路 640×480@30 FPS**  
> **系统目标：稳定接收 480 FPS 视频输入，在有限 AI 算力下完成低延迟、多流、公平、可扩展的多 Gemmini 推理。**

---

# 1. 架构目标

系统同时解决两类问题：

1. **系统级多路视频问题**
   - 16 路视频稳定采集；
   - Capture FPS 与 Inference FPS 解耦；
   - AI 过载时丢弃过期推理帧，不反压摄像头；
   - 多路公平调度；
   - DDR / DMA / Cache / Tensor 生命周期可控。

2. **Runtime 执行问题**
   - 将编译器产物组织为静态执行蓝图；
   - 维护每帧的 Node 执行进度；
   - 根据依赖关系产生 Ready Node；
   - 支持跨帧同 Node 合批；
   - 将 Node 派发到对应 Gemmini / RVV；
   - 管理 Activation / Weight / Output 内存；
   - 提供统一 Completion 与性能观测。

---

# 2. 总体数据流

```text
Local Video ×8                         HDMI Aggregated Video ×8
      |                                         |
      v                                         v
 RX / ISP / DVP                          HDMI RX / Spatial Demux
      |                                         |
      +--------------------+--------------------+
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
                +----------+----------+
                |                     |
                v                     v
             Display            Latest Frame Table
                                      |
                                      v
                               Frame Scheduler
                                      |
                                      v
                               Preprocess Queue
                                      |
                                      v
                              Preprocess / RVV
                                      |
                                      v
                                Tensor Pool
                                      |
                                      v
                           Runtime Frame Admission
                                      |
                                      v
                          Per-Frame Node Progress
                                      |
                                      v
                           Node Ready Scheduler
                                      |
                         +------------+------------+
                         |                         |
                         v                         v
                  Single Node Job          Cross-Frame Batcher
                         |                         |
                         +------------+------------+
                                      |
                                      v
                              Dispatch / Node ABI
                                      |
                         +------------+------------+
                         |            |            |
                         v            v            v
                      Worker0      Worker1      WorkerN
                         |            |            |
                         v            v            v
                        G0           G1           GN
                         \            |            /
                          +-----------+-----------+
                                      |
                                      v
                              Completion Queue
                                      |
                                      v
                           Node Dependency Update
                                      |
                       +--------------+--------------+
                       |                             |
                       v                             v
                 Next Ready Node                Frame Done
                                                     |
                                                     v
                                              Decode / NMS
                                                     |
                                                     v
                                                 Detection
```

---

# 3. 架构分层

系统划分为七个逻辑平面：

```text
1. Video Ingress Plane
2. Video Memory Plane
3. Frame Scheduling Plane
4. Runtime Graph Plane
5. Inference Execution Plane
6. Memory Management Plane
7. Control / Observability Plane
```

各层职责严格分离。

---

# 4. Video Ingress Plane

## 4.1 输入组成

```text
CH0  ~ CH7   : Local Video ×8
CH8  ~ CH15  : HDMI Aggregated Video ×8
```

每路：

```text
640 × 480 @ 30 FPS
```

总输入：

```text
16 × 30 = 480 Frame/s
```

统一内部视频格式：

```text
XRGB8888
4 Byte / Pixel
```

---

## 4.2 Stream Normalizer

统一输出：

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

Normalizer 之后，DMA / Scheduler / Runtime 不再关心数据来自本地摄像头还是 HDMI。

---

## 4.3 Async FIFO

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
Short-term Backpressure Absorption
Input Jitter Isolation
```

FIFO 不承担完整帧缓存。

---

# 5. Video Memory Plane

## 5.1 Multi-Channel Video DMA

推荐：

```text
16 Stream Context
+
2 AXI Write Engines
```

而不是：

```text
16 Stream = 16 AXI Master
```

DMA 仲裁考虑：

```text
FIFO Watermark
Burst Length
Age
Deadline
Per-stream Credit
AXI Outstanding
QoS Class
```

目标：

```text
高 AXI Efficiency
无长期 starvation
无持续 FIFO overflow
单路异常不影响其他通道
```

---

## 5.2 DDR Frame Store

每路采用 Triple Buffer：

```text
CH0  : F0 F1 F2
CH1  : F0 F1 F2
...
CH15 : F0 F1 F2
```

Frame Buffer 元数据：

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

只有：

```text
refcount == 0
且当前不再作为 latest frame
```

时才能复用。

---

## 5.3 Latest Frame Table

每个 Stream 仅向 AI 暴露最新稳定帧：

```c
typedef struct {
    uint32_t stream_id;
    uint64_t frame_id;
    uint64_t timestamp;

    uintptr_t frame_addr;

    uint32_t version;
    bool valid;
} LatestFrameEntry;
```

AI 不维护无限历史帧队列。

---

# 6. Frame Scheduling Plane

## 6.1 Capture / Inference 解耦

```text
Capture Rate
16 × 30 FPS
= 480 FPS
```

AI Service Rate 根据实测 Gemmini 吞吐决定，不由 Camera FPS 反推。

系统原则：

```text
Video Plane:
持续接收全部输入

AI Plane:
只消费当前有能力处理的最新帧
```

AI 过载时：

```text
Frame Supersede
Frame Drop
```

不得直接反压 Video Capture。

---

## 6.2 Stream Context

```c
typedef struct {
    uint32_t stream_id;

    uint64_t latest_frame_id;
    uintptr_t latest_frame_addr;
    uint64_t latest_timestamp;

    uint64_t last_selected_frame_id;
    uint64_t last_completed_frame_id;

    uint32_t target_ai_fps;
    uint32_t priority;

    int32_t credit;
    uint64_t last_service_cycle;
    uint64_t max_service_gap;

    bool enabled;
    bool pending;

    uint64_t capture_frames;
    uint64_t ai_selected_frames;
    uint64_t ai_completed_frames;
    uint64_t ai_dropped_frames;
} StreamContext;
```

---

## 6.3 Frame Scheduler

调度策略：

```text
Latest Frame Wins
+
Deficit / Credit Fairness
+
Priority
+
Target AI FPS
+
Max Service Gap
```

调度流程：

```text
1. 找到 enabled 且存在新帧的 Stream
2. 跳过已经处理过的 frame_id
3. 根据 credit / priority / service_age 评分
4. 对超过 Max Service Gap 的 Stream 强制提升
5. 获取 latest frame reference
6. 创建 PreprocessJob
7. 更新 last_selected / credit / statistics
```

Frame Scheduler 必须位于 Preprocess 之前。

---

# 7. Preprocess Plane

数据路径：

```text
DDR Frame Store
      |
      v
     S02
      |
      v
Preprocess / Saturn RVV
      |
      v
coherent fbus
      |
      v
Tensor Buffer Pool
```

原则：

```text
Video Full Frame
-> S01 / S02
-> Bypass Rocket Cache

AI Tensor
-> coherent fbus
-> Coherent Memory

Control / Metadata
-> Rocket Cached Memory
```

Preprocess 完成后，Frame 才进入 Runtime Graph Plane。

---

# 8. Runtime Graph Plane

Runtime 的调度粒度从“整帧”进一步细化为“Node / Layer”。

```text
Frame Scheduler
负责：
哪一帧值得进入 AI

Runtime Graph Scheduler
负责：
这一帧当前哪个 Node 可以执行
```

两级调度互不替代。

---

# 9. 编译产物与 Runtime 边界

编译器负责 Node 内部：

```text
Tiling
Mvin / Mvout
Scratchpad Address
Double Buffer
Operator Fusion
Weight Layout
RVV Vectorization
```

Runtime 负责 Node 外部：

```text
输入 / 权重 / 输出地址
什么时候调用
在哪个加速器执行
Node 依赖
跨帧合批
多帧共存
Deadline / Drop
Completion
```

推荐产物结构：

```text
kernels/
├── gemmini0/
│   ├── nodes.o
│   └── manifest.json
├── gemmini1/
│   ├── nodes.o
│   └── manifest.json
├── gemminiN/
│   ├── nodes.o
│   └── manifest.json
├── rvv/
│   └── nodes.o
└── weights.bin
```

若多个 Gemmini 配置不同，则分别生成对应产物。

---

# 10. Static Execution Plan

启动时根据 manifest 建立静态执行蓝图，运行期间只读。

```c
typedef enum {
    DEVICE_GEMMINI,
    DEVICE_RVV,
    DEVICE_CPU
} DeviceType;

typedef struct {
    uint32_t node_id;

    uint32_t pred_count;
    uint32_t succ_count;

    uint32_t pred_ids[MAX_PRED];
    uint32_t succ_ids[MAX_SUCC];

    DeviceType device_type;
    uint32_t device_id;

    uint32_t input_buf;
    uint32_t weight_buf;
    uint32_t output_buf;

    bool batchable;
    uint32_t max_batch;

    void *node_entry;
} NodePlan;
```

全模型：

```c
typedef struct {
    uint32_t node_count;
    NodePlan nodes[MAX_NODES];
} ExecutionPlan;
```

职责：

```text
Model DAG
Node Dependency
Node -> Accelerator Binding
Buffer Mapping
Batchability
Node Entry
```

---

# 11. Per-Frame Node Progress

每个进入 Runtime 的 AI Frame 建立独立进度表。

```c
typedef struct {
    uint64_t runtime_frame_id;
    uint32_t stream_id;
    uint64_t source_frame_id;

    uint32_t slot_id;

    uint64_t admit_cycle;
    uint64_t deadline_cycle;

    uint16_t pending_pred[MAX_NODES];
    uint8_t  node_state[MAX_NODES];

    uint32_t completed_nodes;

    bool dropped;
    bool finished;
} FrameProgress;
```

Node 状态：

```text
WAITING
READY
RUNNING
DONE
DROPPED
```

多个 Camera 可以同时拥有多个 FrameProgress。

---

# 12. Node Ready / Dependency

每个 Node 的可执行条件：

```text
pending_pred[node] == 0
```

完成流程：

```text
Node X Done
   |
   v
遍历 Node X 的 successors
   |
   v
pending_pred[succ]--
   |
   +-- > 0 -> WAITING
   |
   `-- = 0 -> READY
```

双 Hart 同时更新依赖计数时，使用原子操作。

Node Ready Queue 保存：

```text
真正满足依赖、
可以立即执行的 Node Job
```

---

# 13. Cross-Frame Same-Node Batching

这是 Runtime 的主要跨帧优化。

当多个 Frame 同时出现：

```text
Frame A -> Node K READY
Frame B -> Node K READY
Frame C -> Node K READY
```

并且：

```text
NodePlan[K].batchable == true
```

Batcher 可形成：

```text
BatchJob {
    node = K
    members = [A, B, C]
}
```

目标：

```text
同一 Node 的 Weight
尽可能一次加载
供多帧复用
```

---

## 13.1 Batch 条件

只有同时满足以下条件才合批：

```text
Same Node
Same Tensor Shape
Same Quantization / ABI
Node marked batchable
成员内存满足连续性要求
Deadline 允许等待
```

否则退化为 Single Node Job。

---

## 13.2 Batch Window

Batcher 不无限等待。

策略：

```text
达到 max_batch
        或
batch window 到期
        或
最早成员接近 deadline
```

立即提交。

---

## 13.3 Batch 完成

一次 Batch 执行完成后：

```text
Batch Completion
      |
      +--> Frame A / Node K DONE
      +--> Frame B / Node K DONE
      `--> Frame C / Node K DONE
```

随后分别更新各自 FrameProgress 的后继依赖。

---

# 14. Memory Management Plane

## 14.1 Frame Slot / Activation Arena

Runtime 启动时一次性建立固定内存池。

运行期间：

```text
禁止动态 malloc/free
```

逻辑布局：

```text
Runtime Arena
├── Frame Slot 0
│   ├── Buffer0
│   ├── Buffer1
│   └── ...
├── Frame Slot 1
├── Frame Slot 2
└── ...
```

通过统一接口查询：

```c
void *slot_ptr(uint32_t slot_id, uint32_t buf_id);
```

执行层不关心实际 Arena 布局。

---

## 14.2 Tensor Buffer Pool

Preprocess Tensor 的 Buffer 数量由 AI 并发决定，而不是由 Camera 数量决定。

状态：

```text
FREE
 |
 v
PREPROCESS_WRITING
 |
 v
READY
 |
 v
RUNTIME_OWNED
 |
 v
FREE
```

元数据：

```c
typedef struct {
    uint32_t state;
    uint32_t owner;
    uint32_t version;

    uint32_t stream_id;
    uint64_t frame_id;

    uintptr_t addr;
    size_t size;
} TensorBufferMeta;
```

任意时刻只允许一个逻辑 Owner 修改 Buffer。

---

## 14.3 Worker Arena

每个并发 Worker 独占运行态 Activation / Output 区。

```text
Worker0 Arena
├── Activation
└── Output

Worker1 Arena
├── Activation
└── Output

WorkerN Arena
├── Activation
└── Output
```

禁止多个并行 Worker 无保护地共享同一 Activation Arena。

---

## 14.4 Weight Region

同一模型逻辑上只保存一份权重：

```text
DDR Weight Region
       |
  +----+----+----+
  |         |    |
 G0        G1   GN
```

Runtime 优先优化：

```text
Weight Residency
Weight Reload Ratio
SPAD Reuse
Cross-Frame Batch Reuse
Phase Staggering
```

先量化，再决定是否引入 Weight Replication / Cache。

---

# 15. Node Job ABI

Runtime 内部统一使用 NodeJob：

```c
typedef struct {
    uint64_t job_id;

    uint32_t node_id;
    uint32_t member_count;

    uint64_t frame_ids[MAX_BATCH];
    uint32_t slot_ids[MAX_BATCH];

    uint32_t device_id;

    uintptr_t input_addr;
    uintptr_t weight_addr;
    uintptr_t output_addr;

    uint64_t enqueue_cycle;
    uint64_t deadline_cycle;

    uint32_t flags;
} NodeJob;
```

NodeJob 不关心：

```text
Local Camera
HDMI Camera
```

只关心：

```text
Node
Frame Members
Memory
Device
Deadline
```

---

# 16. Runtime 三条核心接口

模块之间尽量只通过固定接口连接。

```c
void *slot_ptr(uint32_t slot_id,
               uint32_t buf_id);
```

```c
void on_node_done(uint64_t frame_id,
                  uint32_t node_id);
```

```c
NodeWork next_work(void);
```

职责边界：

```text
Memory
-> 数据在哪里

Execution
-> 怎么调用 Node

Scheduler
-> 当前该调用谁
```

---

# 17. Dispatch / Node Call

执行流程：

```text
next_work()
    |
    v
取得 Single / Batch Node Job
    |
    v
读取 ExecutionPlan
    |
    v
确定 device_id
    |
    v
确认 Worker / Queue 可用
    |
    v
slot_ptr() 获取地址
    |
    v
按 node_abi 构造参数
    |
    v
调用 compiler-generated node
```

如果目标设备暂时不可用：

```text
不要阻塞等待
```

Job 保持 Ready，Worker 转去执行其他可运行任务。

---

# 18. Multi-Gemmini Worker Pool

顶层参数：

```text
NUM_GEMMINI = 2   基线
NUM_GEMMINI = 3   扩展
```

Worker Pool：

```text
                Node Ready Queue
                       |
                       v
                Worker Scheduler
                       |
          +------------+------------+
          |            |            |
          v            v            v
       Worker0      Worker1      WorkerN
          |            |            |
          v            v            v
         G0           G1           GN
```

Camera 不与 Worker 静态绑定。

Node 可以根据 ExecutionPlan 与硬件绑定关系选择目标设备。

---

# 19. Worker State

```text
IDLE
 |
 v
ASSIGNED
 |
 v
RUNNING
 |
 v
COMPLETING
 |
 v
IDLE
```

```c
typedef struct {
    uint32_t worker_id;
    uint32_t device_id;

    uint32_t state;
    uint64_t current_job;

    uint64_t start_cycle;
    uint64_t end_cycle;

    uint64_t dma_stall_cycles;
    uint64_t compute_cycles;

    uint32_t error;
} WorkerState;
```

---

# 20. RVV / CPU Node

RVV 属于 Hart 内执行资源，不作为独立异步加速器队列处理。

执行模型：

```text
Worker / Hart
    |
    v
RVV Node Function
    |
    v
Return
```

因此：

```text
RVV Busy
=
当前 Hart Busy
```

Preprocess、Decode、NMS 以及编译器生成的 RVV Node 均按该规则计入 Hart 调度。

---

# 21. Completion Queue

所有 Gemmini Worker 使用统一 Completion Queue。

```c
typedef struct {
    uint64_t job_id;

    uint32_t node_id;
    uint32_t worker_id;

    uint32_t member_count;
    uint64_t frame_ids[MAX_BATCH];

    uint64_t enqueue_cycle;
    uint64_t start_cycle;
    uint64_t end_cycle;

    uint32_t status;
} Completion;
```

Completion 顺序允许完全异步。

处理流程：

```text
Completion
    |
    v
标记 Node DONE
    |
    v
更新 successor dependency
    |
    +--> 新 Node READY
    |
    `--> Frame 完成
```

---

# 22. Frame Completion

当：

```text
completed_nodes == total_nodes
```

该 Runtime Frame 完成。

随后：

```text
Output
  |
  v
Decode / NMS
  |
  v
Detection Result
```

并释放：

```text
Frame Slot
Tensor Reference
Worker / Output Resource
```

---

# 23. Deadline / Drop

系统存在两级丢弃。

## 23.1 Frame Scheduler Drop

发生在 Preprocess 前：

```text
旧帧被更新帧覆盖
AI Budget 不足
```

优先避免无意义 Preprocess。

---

## 23.2 Runtime Drop

发生在 Frame 已进入 Runtime 后：

```text
当前时间 > deadline
且继续执行已经没有实时价值
```

则：

```text
FrameProgress -> DROPPED
```

后续未执行 Node 不再进入 Ready Queue。

已占用资源在安全点完成回收。

---

# 24. Backpressure 域

系统定义三类 Backpressure：

```text
Video Ingress Backpressure
Frame / Runtime Scheduling Backpressure
Gemmini Worker Backpressure
```

原则：

```text
AI Busy
不得直接传播到 Camera
```

AI 侧通过：

```text
Latest Frame
Drop
Queue Depth Limit
Deadline
```

吸收过载。

---

# 25. Queue 设计

推荐主要队列：

```text
Preprocess Queue
Node Ready Queue
Batch Candidate Table
Completion Queue
```

Queue 设计原则：

```text
有界
可观测
不保存无限历史
队列过深即认为系统产生过期任务
```

---

# 26. QoS

每路 Stream 支持：

```text
target_ai_fps
priority
credit
max_service_gap
deadline
```

系统保证：

```text
高优先级 Stream 可获得更高 AI Service Rate
低优先级 Stream 不允许永久 starvation
某一路异常不能拖死其他 Stream
```

Runtime 内部同时遵守 Frame Deadline。

---

# 27. Memory Wall 优化顺序

优化顺序：

```text
1. Single Worker Baseline
2. Dual Worker Scaling
3. DDR / S00 / S02 Profiling
4. DMA Stall Analysis
5. Weight Reload Ratio
6. SPAD Utilization
7. Cross-Frame Batch Reuse
8. Layer / Worker Phase Staggering
```

再考虑：

```text
Weight Prefetch
Weight Replication
Shared Read-only Cache
Double Buffer SPAD
更复杂的调度
```

不在缺少数据时直接引入复杂结构。

---

# 28. Observability

必须形成完整 latency decomposition。

## 28.1 Frame 级

```text
Camera
-> FIFO
-> DMA
-> Frame Store
-> Frame Scheduler Wait
-> Preprocess Wait
-> Preprocess Execute
-> Runtime Admission
-> Runtime Execute
-> Postprocess
```

---

## 28.2 Node 级

```text
Node Ready Time
Node Queue Wait
Batch Wait
Dispatch Time
Worker Start
Compute
DMA Stall
Completion
Dependency Update
```

---

## 28.3 Worker 级

每个 Worker 记录：

```text
Busy Cycles
Idle Cycles
Compute Cycles
DMA Stall Cycles
Completed Jobs
Batch Jobs
Average Batch Size
```

---

## 28.4 Stream 级

每路记录：

```text
Capture FPS
Selected AI FPS
Completed AI FPS
Dropped Frames
Average Service Gap
Max Service Gap
End-to-End Latency
```

---

# 29. 核心 Runtime 数据结构

```text
ExecutionPlan
    全模型唯一
    启动后只读

StreamContext[16]
    每路视频调度状态

LatestFrameEntry[16]
    每路最新稳定帧

FrameProgress[]
    每个在飞 AI Frame 一份

TensorBufferMeta[]
    Preprocess Tensor 生命周期

NodeJob[]
    Runtime 执行任务

WorkerState[NUM_GEMMINI]
    Gemmini Worker 状态

Completion[]
    异步完成事件
```

---

# 30. Runtime 生命周期

```text
System Boot
   |
   v
Load Hardware Facts
   |
   v
Load Manifest / Weights
   |
   v
Build Execution Plan
   |
   v
Bind Node -> Device
   |
   v
Verify Plan
   |
   v
Init Arena / Tensor Pool
   |
   v
Start Video Plane
   |
   v
Start Frame Scheduler
   |
   v
Start Runtime Workers
```

运行期：

```text
Latest Frame
   |
   v
Frame Scheduler
   |
   v
Preprocess
   |
   v
Runtime Admission
   |
   v
FrameProgress
   |
   v
Ready Node
   |
   v
Batch / Dispatch
   |
   v
Gemmini / RVV
   |
   v
Completion
   |
   v
Dependency Update
   |
   v
Frame Done
```

---

# 31. 模块目录建议

```text
runtime/
├── include/
│   ├── hw_facts.h
│   ├── plan.h
│   ├── node_abi.h
│   ├── memory.h
│   ├── scheduler.h
│   └── metrics.h
│
├── plan/
│   ├── plan_build.c
│   ├── plan_bind.c
│   ├── plan_batch.c
│   └── plan_verify.c
│
├── frame/
│   ├── latest_frame.c
│   ├── frame_sched.c
│   └── frame_progress.c
│
├── sched/
│   ├── ready.c
│   ├── batcher.c
│   ├── qos.c
│   └── stream.c
│
├── mem/
│   ├── arena.c
│   ├── frame_slot.c
│   ├── tensor_pool.c
│   └── weight_res.c
│
├── exec/
│   ├── worker.c
│   ├── dispatch.c
│   ├── node_call.c
│   └── completion.c
│
├── video/
│   ├── stream_normalizer.c
│   ├── video_dma.c
│   └── frame_store.c
│
├── metrics/
│   ├── trace.c
│   └── export.c
│
├── mock/
│   └── accel_mock.c
│
└── main.c
```

---

# 32. 模块职责

## 32.1 frame/

```text
只决定：
哪一帧值得进入 AI
```

---

## 32.2 plan/

```text
只决定：
模型有哪些 Node
Node 如何依赖
Node 绑哪个设备
哪些 Node 可以 Batch
```

---

## 32.3 sched/

```text
只决定：
当前哪些 Node 可以执行
要不要跨帧合批
谁先执行
```

---

## 32.4 mem/

```text
只决定：
数据放在哪里
地址是什么
什么时候可以复用
```

---

## 32.5 exec/

```text
只决定：
怎么调用目标 Node
怎么驱动 Worker
如何处理 Completion
```

---

# 33. 验收指标

## 33.1 Video Plane

```text
16 × 640×480@30 FPS 稳定输入
无持续 FIFO overflow
无系统性 frame corruption
单路异常不影响其他通道
```

---

## 33.2 Frame Scheduler

```text
Latest Frame Wins 正确
Capture / Inference 解耦
无 Stream starvation
Priority / Target FPS 生效
AI overload 不反压 Camera
```

---

## 33.3 Runtime Graph

```text
ExecutionPlan 与模型拓扑一致
Node 依赖计数正确
Node 不提前执行
FrameProgress 可独立推进
Drop 后依赖关系不会失控
```

---

## 33.4 Cross-Frame Batch

```text
Single 与 Batch 结果一致
Batch 可按 Deadline 自动退化
可观测平均 Batch Size
可观测 Weight Traffic 下降
```

---

## 33.5 Multi-Gemmini

```text
Dual Gemmini 真并行
NUM_GEMMINI 可参数化
Worker 无 Camera 静态绑定
Completion 异步
单 Worker 故障不破坏其他 Stream 状态
```

---

## 33.6 Memory

```text
Video Full Frame 绕过 Rocket Cache
Tensor coherence 正确
Buffer Ownership 正确
运行期无动态内存增长
Weight Region 逻辑单副本
Activation 不发生非法覆盖
```

---

## 33.7 Observability

必须能够回答：

```text
为什么某一路 AI FPS 低？
为什么某个 Gemmini 长时间空闲？
为什么 Dual Gemmini Scaling 不理想？
当前瓶颈在 DDR、DMA、Preprocess、Batch Wait 还是 Compute？
某个 Frame 在哪个阶段超时？
跨帧 Batch 实际节省了多少 Weight Traffic？
```

---

# 34. 开发优先级

## P0：16 路视频数据面

```text
Input Bring-up
-> Stream Normalizer
-> FIFO ×16
-> Multi-Channel DMA
-> Frame Store
-> Latest Frame Table
```

---

## P0：Frame Scheduler

```text
Scheduler-before-Preprocess
Latest Frame Wins
Per-stream Context
Capture / Inference 解耦
```

---

## P0：Runtime 最小闭环

```text
ExecutionPlan
-> FrameProgress
-> Node Ready
-> Single Node Dispatch
-> Completion
-> Dependency Update
```

第一阶段不要求 Batch。

---

## P0：Dual Gemmini

```text
Worker0 + Worker1
Node Dispatch
Per-worker Arena
Async Completion
```

---

## P0：可观测性

```text
Single Gemmini Benchmark
Dual Gemmini Benchmark
DDR / S00 / S02 Profiling
Per-stream AI FPS
Per-worker Utilization
Frame / Node Latency
```

---

## P1：Cross-Frame Batch

```text
Batchable Node Mark
Batch Candidate Table
Batch Window
Contiguous Memory Check
Batch Completion Split
```

---

## P1：QoS

```text
Credit Fairness
Priority
Target FPS
Max Service Gap
Deadline Drop
```

---

## P1：Memory Wall

```text
Weight Reload Analysis
SPAD Reuse
Cross-Frame Weight Reuse
Phase Staggering
AXI Outstanding Tuning
QoS Tuning
```

---

## P2：第三 Gemmini

在 Dual Gemmini Scaling 和 Runtime 调度稳定后：

```text
NUM_GEMMINI = 2
      ↓
NUM_GEMMINI = 3
```

重点验证：

```text
Worker Utilization
Hart Occupancy
DDR Read Contention
Weight Reload Ratio
Batch Efficiency
```

---

# 35. 最终架构原则

```text
16 路视频全部稳定进入系统
        +
Capture / Inference 解耦
        +
Latest Frame Scheduler
        +
静态 Execution Plan
        +
Per-Frame Node Progress
        +
Node Dependency Ready
        +
Cross-Frame Same-Node Batch
        +
Node -> Gemmini / RVV Dispatch
        +
固定 Arena / Weight Residency
        +
参数化 Multi-Gemmini Worker Pool
        +
异步 Completion
        +
QoS / Deadline / Drop
        +
端到端可观测 Memory Wall
```

系统的两个核心调度问题分别处理：

```text
Frame Scheduler
回答：
“哪一帧值得进入 AI？”

Runtime Scheduler
回答：
“已经进入 AI 的这些帧，现在该算哪个 Node？”
```

两者结合后，形成完整的 16 路多流推理 Runtime。
