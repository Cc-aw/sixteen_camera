# 16 路视频 1CPU + 1RVV + 3×64×64 Gemmini 固定模型推理系统总体架构

> **版本：V5.0**  
> **日期：2026-08-28**  
> **目标平台：XCVU13P + Rocket RV64 + Saturn RVV + 3×Gemmini 64×64**  
> **视频规模：16 路 640×480，目标 30 FPS/路**  
> **模型形态：固定 YOLOv5nu，模型 Batch = 1**  
> **主要数据类型：INT8**  
> **Gemmini 目标频率：200 MHz，最终以 Post-Route Timing 为准**  
> **架构定位：5-Buffer Video Plane / Hardware Preprocess / 3×B1 Gemmini Frame-Level Parallelism / Static Runtime**

---

# 1. 文档定位

V5.0 不重新设计已经验证的视频链路，而是在当前已经实现的系统上继续演进。

当前工程已经完成并验证：

- OV7670/HDMI RX 输入框架；
- 多通道 DDR framebuffer；
- 每路 5 个 framebuffer；
- snapshot acquire / release；
- 硬件预处理 `frame_preprocess_accel`；
- 多通道 `batch_preprocess_engine`；
- 双 Tensor Arena；
- 软件 AI batch runtime；
- 3 个 logical worker 的 runtime 框架；
- YOLOv5nu scalar postprocess；
- Result Manager；
- HDMI 4×4 mosaic 与 overlay；
- worker timeout / abort / stale-result 检测接口。

当前尚未完成：

- 真实 3×64×64 Gemmini backend；
- 真实 Gemmini command / completion 并行；
- Saturn RVV 的正式运行时角色；
- Gemmini 权重、activation、scratchpad/accumulator 的最终静态规划；
- 三 Gemmini 并发 DDR 行为验证；
- 16 路输入的完整板上验证。

因此 V5.0 的原则是：

```text
保留已经验证的视频与预处理数据面
            +
保持现有软件接口
            +
只替换模型 backend
            +
逐步接入 3×Gemmini / RVV
```

---

# 2. V5.0 核心设计决策

V5.0 固定以下架构决策。

## 2.1 每路 5 个 Framebuffer

```text
CH0  : F0 F1 F2 F3 F4
CH1  : F0 F1 F2 F3 F4
...
CH15 : F0 F1 F2 F3 F4
```

总计：

```text
16 × 5 = 80 Frame Buffers
```

5 Buffer 是 V5.0 的系统设计约束，不降回 Triple Buffer。

原因是系统中同时存在：

```text
Camera Writer
Display Reader
Latest Completed Frame
AI Snapshot Hold
Next Writer Candidate
```

并且跨越 camera pixel clock、DDR UI clock、CPU AXI-Lite clock、HDMI clock 等多个时钟域。

板上已经观察到较少 Buffer 时存在 drop 风险，因此 V5.0 以 5 Buffer 为稳定基线。

---

## 2.2 模型 Batch 固定为 1

V5.0 第一阶段：

```text
Model Batch = 1
```

不实现：

```text
B2
B4
B16
Dynamic Micro-Batch
```

三个 Gemmini 的并行方式是：

```text
Frame A / B1 -> Gemmini0
Frame B / B1 -> Gemmini1
Frame C / B1 -> Gemmini2
```

而不是：

```text
16 Frames
   ↓
Batch16
   ↓
One Model Invocation
```

因此系统并行方式定义为：

```text
3 Workers
×
1 Sample / Worker
=
最多 3 个独立 B1 推理同时进行
```

---

## 2.3 16-Channel Preprocess 不等于 Batch16 Inference

当前 `batch_preprocess_engine` 最大支持 16 个 channel member。

该能力在 V5.0 中定义为：

```text
Multi-Channel Hardware Preprocess Capability
```

而不是：

```text
Model Batch = 16
```

每个 preprocess member 最终都转换为一个独立的：

```text
AiModelFrameRequest
```

模型端仍然始终看到：

```text
N = 1
```

---

## 2.4 RVV 不负责图像前处理

图像前处理已经由 RTL 完成：

```text
DDR Source Frame
      ↓
frame_preprocess_accel
      ↓
Resize / RGB Pack / INT8 Tensor
      ↓
Tensor Arena
```

V5.0 不再增加：

```text
RVV Resize
RVV Color Convert
RVV Quantization
```

Saturn RVV 定位为共享向量辅助计算资源，用于：

- Gemmini 不适合或暂未硬化的模型内部向量算子；
- Profiling 证明值得向量化的 decode / candidate filter；
- 其他低控制复杂度、高 SIMD 收益任务。

第一版后处理仍允许全部由 Rocket scalar path 完成。

---

## 2.5 已实现模块优先复用

V5.0 保持以下接口不变：

```text
AiModelFrameRequest
AiModelFrameCompletion
ai_postprocess_yolov5nu()
```

真实 Gemmini 接入时优先替换：

```text
ai_model_backend_stub
        ↓
ai_model_backend_gemmini
```

避免同时重构视频、预处理、runtime、后处理和模型 backend。

---

# 3. V5.0 总体数据流

```text
 OV7670 CH1~CH8 -------------------+
                                  |
 HDMI RX CH9~CH16 ----------------+
                                  |
                                  v
                       Input / Stream Normalizer
                                  |
                                  v
                            Async FIFO
                                  |
                                  v
                  Multi-Channel DDR Video Pipeline
                                  |
                                  v
             +-----------------------------------------+
             |  5 Frame Buffers / Channel             |
             |                                         |
             |  CH0  : F0 F1 F2 F3 F4                 |
             |  CH1  : F0 F1 F2 F3 F4                 |
             |  ...                                    |
             |  CH15 : F0 F1 F2 F3 F4                 |
             +-------------------+---------------------+
                                 |
                                 v
                       Latest Frame / Snapshot
                                 |
                                 v
                     Snapshot Admission Manager
                                 |
                                 v
                  Multi-Channel HW Preprocess
                  frame_preprocess_accel
                  batch_preprocess_engine
                                 |
                                 v
                      Tensor Arena 0 / Arena 1
                                 |
                         member = one B1 tensor
                                 |
                                 v
                       Model Request Queue
                                 |
                    +------------+------------+
                    |            |            |
                    v            v            v
              Gemmini Worker0 Gemmini Worker1 Gemmini Worker2
                  64×64          64×64          64×64
                    |            |            |
                    +------------+------------+
                                 |
                    optional Shared RVV Assist
                                 |
                                 v
                        Model Output Arena
                                 |
                                 v
                    YOLOv5nu Postprocess Queue
                                 |
                       Rocket / optional RVV
                                 |
                                 v
                         Result Manager
                                 |
                                 v
                    Per-Stream Latest Result
                                 |
                                 v
                           Overlay MMIO
                                 |
                                 v
                         HDMI TX 4×4 Mosaic
```

---

# 4. 架构分层

V5.0 划分为六个逻辑平面：

```text
1. Video Ingress Plane
2. Video Frame Memory / Ownership Plane
3. Hardware Preprocess Plane
4. B1 Multi-Gemmini Execution Plane
5. Postprocess / Result Plane
6. Control / Observability Plane
```

其中：

## Video Plane

负责：

```text
持续采集
帧完整性
DDR 写入
Display
5-buffer ownership
Latest Frame
Snapshot
```

## AI Plane

负责：

```text
Snapshot消费
硬件预处理
B1 Model Request
3 Worker Dispatch
Gemmini执行
后处理
结果发布
```

两者必须保持：

```text
Gemmini Busy
!=
Camera Backpressure
```

AI 性能不足时允许：

```text
Skip Old Frame
Supersede Old Candidate
降低单路 AI FPS
```

但不允许因为 AI Worker Busy 直接阻塞视频输入。

---

# 5. Video Ingress Plane

目标输入规模：

```text
CH0 ~ CH15
16 Streams
640 × 480
目标 30 FPS / Stream
```

当前板上已经实际验证 8 路 OV7670。

HDMI RX CH9~CH16 已有通路，但需要作为 V5.0 的独立验收项完成真实输入验证。

视频写入统一进入：

```text
video_stream_if
        ↓
multi_channel_ddr_video_pipeline
```

Camera 侧继续保留：

- PCLK/HREF/VSYNC 稳定性检测；
- 短线异常统计；
- FIFO / CDC；
- DMA response error；
- dropped frame counter；
- 串口状态观测。

---

# 6. 五缓冲 Frame Store

## 6.1 Buffer 不绑定固定角色

物理 Frame Buffer 不永久绑定：

```text
F0 = Writer
F1 = Display
F2 = AI
```

而采用动态 Ownership。

建议状态：

```text
FREE
WRITING
COMPLETE
DISPLAY_HELD
AI_SNAPSHOT_HELD
```

逻辑属性：

```text
LATEST
DISPLAY_PENDING
```

典型状态：

```text
F0 : WRITING
F1 : DISPLAY_HELD
F2 : AI_SNAPSHOT_HELD
F3 : COMPLETE / LATEST
F4 : FREE
```

下一帧可以安全切换到：

```text
F4 -> WRITING
```

---

## 6.2 Writer 选择约束

下一 Writer Buffer 必须排除：

```text
当前 WRITING
DISPLAY_HELD
DISPLAY_PENDING
AI_SNAPSHOT_HELD
任何尚未安全释放的 Buffer
```

目标：

```text
No Ownership Collision
No Partial Frame Read
No Writer Starvation
Minimum Drop
```

---

## 6.3 Latest Frame 原则

AI 不维护无限增长的 Frame Queue。

每路只需要：

```text
Latest Safe Frame
```

当新的完整帧到达：

```text
New Complete Frame
        ↓
更新 Latest Candidate
        ↓
旧的未消费 Candidate 可被 Supersede
```

因此：

```text
Capture Rate > AI Service Rate
```

时不产生无限积压。

---

# 7. Snapshot Plane

Snapshot 是 Video Plane 与 AI Plane 之间的主要 Ownership 边界。

每个 Snapshot Member 必须记录：

```text
stream_id
frame_id
timestamp
version
frame_addr
valid
fresh
```

V5.0 保持当前：

```text
snapshot acquire
snapshot release
request/ack toggle CDC
```

机制。

---

## 7.1 Snapshot 生命周期优化

当前系统流程中 snapshot 可能一直保持到 inference/postprocess 结束。

V5.0 推荐将 Source Frame 生命周期缩短为：

```text
Acquire Snapshot
       ↓
Hardware Preprocess读取完整 Source Frame
       ↓
Tensor写入 Arena
       ↓
Preprocess Done
       ↓
Release Snapshot
```

后续：

```text
Gemmini
Postprocess
Result Publish
```

只依赖 Tensor 和 metadata，不再依赖原始 framebuffer。

这样能够减少：

```text
AI_SNAPSHOT_HELD 时间
```

提高 5-buffer pool 的可用余量。

P0 若现有协议只能整组 release，则至少在整个 preprocess transaction 完成后立即 release 整组 Snapshot，而不等待模型和后处理结束。

---

# 8. Hardware Preprocess Plane

继续使用现有 RTL：

```text
rtl/ai/preprocess/frame_preprocess_accel.sv
rtl/ai/preprocess/batch_preprocess_engine.sv
```

当前输入输出合同：

```text
Source:
640 × 480
XRGB8888
4 Byte / Pixel

Output:
640 × 480
RGB
INT8
3 Byte / Pixel
```

单 member：

```text
640 × 480 × 3
=
921600 Byte
=
0x000E1000
```

---

## 8.1 Preprocess Engine 职责

Hardware Preprocess 负责：

```text
DDR Source Read
Nearest Mapping
RGB Extraction / Packing
INT8 Tensor Generation
Tensor Arena Write
```

Rocket 不执行大规模逐像素预处理。

Saturn RVV 不参与图像预处理主路径。

---

## 8.2 Multi-Channel Engine 与 B1 模型的关系

`batch_preprocess_engine` 可以维护最多 16 个 channel member。

但是：

```text
Preprocess Member Count
!=
Model Batch
```

V5.0 Runtime 必须将：

```text
Arena Member i
```

转换成一个独立的：

```text
AiModelFrameRequest
```

请求内容至少包含：

```c
stream_id
frame_id
timestamp
version
input_tensor_addr
output_tensor_addr
```

该 Request 永远表示：

```text
1 Frame
1 Stream
Batch = 1
```

---

# 9. Tensor Arena

当前已经实现：

```text
Tensor Arena0 : 0x30000000
Tensor Arena1 : 0x31000000
```

每个 Arena 支持：

```text
16 × member_stride
```

现有状态：

```text
FREE
PROCESSING
READY
RECYCLE
```

V5.0 第一阶段继续保留 Dual Arena，不为了 B1 立即重写为新的 Slot Pool。

---

## 9.1 Arena Member 解释

V5.0 中：

```text
Arena0 Member0
Arena0 Member1
Arena0 Member2
...
```

不是一个 Batch16 模型 Tensor。

而是多个独立的：

```text
B1 Input Tensor
```

例如：

```text
Arena0/member3 -> CH3 Frame 108 -> Worker0
Arena0/member7 -> CH7 Frame 219 -> Worker1
Arena0/member12 -> CH12 Frame 96 -> Worker2
```

三个 Worker 分别执行三个独立模型调用。

---

## 9.2 Arena 回收条件

一个 Arena 不能因为 preprocess 完成就立即回收。

必须满足：

```text
该 Arena 中所有已经提交的有效 Member
均不再被 Gemmini Worker 读取
```

才能：

```text
READY / IN_USE
        ↓
RECYCLE
        ↓
FREE
```

因此 V5.0 Runtime 需要为每个 Arena 维护：

```text
valid_mask
fresh_mask
submitted_mask
inflight_mask
completed_mask
```

推荐回收条件：

```text
(inflight_mask == 0)
AND
所有需要提交的 member 已完成或被取消
```

---

# 10. Model Batch = 1 执行模型

V5.0 模型执行基线：

```text
N = 1
```

一个 Model Job 对应：

```text
一个 Stream
一个 Frame
一个 Input Tensor
一个 Output Tensor
一个 Worker
```

不建立：

```text
Batch16 Model Job
Cross-Frame Layer Fusion
Inter-Batch Layer Scheduler
```

---

# 11. Three-Gemmini Execution Plane

目标硬件：

```text
Gemmini0 : 64×64 INT8
Gemmini1 : 64×64 INT8
Gemmini2 : 64×64 INT8
```

三个 Gemmini 作为三个独立 Worker。

核心并行方式：

```text
Frame A -> G0
Frame B -> G1
Frame C -> G2
```

不是：

```text
Frame A Layer0 -> G0
Frame A Layer1 -> G1
Frame A Layer2 -> G2
```

V5.0 第一阶段禁止跨 Gemmini 拆分同一个 Frame 的 Layer。

---

# 12. Worker 抽象

建议：

```c
typedef enum {
    WORKER_IDLE,
    WORKER_RESERVED,
    WORKER_RUNNING,
    WORKER_WAIT_ASSIST,
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

    uintptr_t input_addr;
    uintptr_t output_addr;
    uintptr_t activation_arena_base;

    uint32_t current_stage;

    uint64_t dispatch_cycle;
    uint64_t start_cycle;
    uint64_t end_cycle;
} GemminiWorker;
```

系统固定：

```c
GemminiWorker workers[3];
```

Scheduler 只关心：

```text
哪个 Worker Idle
```

不把 Stream 固定绑定到某个 Gemmini。

---

# 13. Model Backend 边界

现有：

```text
ai_model_backend_stub
```

替换为：

```text
ai_model_backend_gemmini
```

保持上层接口：

```text
AiModelFrameRequest
        ↓
backend_submit()
        ↓
AiModelFrameCompletion
```

这样：

```text
Snapshot
Preprocess
Runtime
Postprocess
Result Manager
Overlay
```

都不需要因 Gemmini 接入而大规模改写。

---

# 14. Gemmini 静态模型执行

模型为固定 YOLOv5nu。

V5.0 推荐使用：

```text
Static Model Plan
Static Weight Table
Static Tensor Table
Static Kernel Entry
```

运行时不执行：

```text
Graph Parser
Dynamic Shape Inference
Dynamic Operator Registry
Dynamic malloc/free
Dynamic Device Binding
```

具体哪些 YOLOv5nu 算子由：

```text
Gemmini
RVV
Rocket
```

执行，必须以实际 backend 实现和 Profiling 为准。

V5.0 不在没有实测依据时预先规定每一层的设备映射。

---

# 15. Worker Activation Arena

三个 Worker 应拥有彼此独立的 Activation Arena：

```text
Worker Arena0
Worker Arena1
Worker Arena2
```

目标：

```text
G0 activation
!=
G1 activation
!=
G2 activation
```

避免三个并发 Frame 的中间 Tensor 相互覆盖。

固定模型下应离线分析：

```text
Tensor Shape
Producer
Last Consumer
Lifetime
Reuse Group
```

然后形成：

```text
tensor_addr =
worker_arena_base
+
tensor_offset
```

Tensor Offset 只规划一次，三个 Worker 使用不同 base。

---

# 16. Weight Region

软件层只维护一个逻辑 Weight Region：

```text
DDR Weight Region
    |
    +----> G0
    +----> G1
    +----> G2
```

不因为三个 Worker 创建三份完整软件权重副本。

每个 Gemmini 自身的：

```text
Scratchpad
Internal Tile State
ACC
```

独立。

需要重点 Profile：

```text
Weight Read Bytes / Frame
Weight Reload Ratio
DMA Stall
SPAD Reuse
```

---

# 17. Model Output

当前：

```text
Model Output Arena : 0x32000000
每 Worker预留 0x00400000
```

V5.0 第一阶段继续使用 Per-Worker Output Region：

```text
Worker0 Output
Worker1 Output
Worker2 Output
```

输出必须与：

```text
job_id
stream_id
frame_id
worker_id
```

绑定。

Worker 完成顺序允许乱序。

例如：

```text
Job102
先于
Job101
完成
```

只要结果元数据正确即可。

---

# 18. Saturn RVV 定位

V5.0 将 Saturn 定义为：

```text
Shared Vector Assist Engine
```

而不是 Preprocess Engine。

优先级建议：

```text
Priority 0:
Model-Critical RVV Assist

Priority 1:
Postprocess Vector Task

Priority 2:
Non-critical Vector Utility
```

因为系统只有一个 RVV。

如果三个 Gemmini 都频繁进入：

```text
Gemmini
  ↓
RVV
  ↓
Gemmini
```

则 RVV 可能成为共享串行瓶颈。

因此目标是尽量减少模型主干对 RVV 的中间依赖。

---

# 19. Postprocess

当前固定模型合同：

```text
Input  : 640×480 INT8
Output : Q16.16
Layout : channel-anchor
Channels: 84
Anchors : 6300
Classes : 80
```

当前 scalar postprocess 已经完成：

```text
Q16.16 Decode
Objectness / Class Score
Candidate Filter
Threshold
NMS
Coordinate Clip
Frame / Stream Binding
```

V5.0 P0：

```text
Postprocess = Rocket Scalar
```

保持：

```text
ai_postprocess_yolov5nu()
```

不变。

只有 Profiling 证明 CPU 后处理成为系统瓶颈后，再迁移：

```text
Decode
Score
Candidate Filter
```

等适合向量化的部分到 RVV。

NMS 是否迁移由实测决定。

---

# 20. Result Manager

每个结果必须携带：

```text
stream_id
frame_id
timestamp
version
job_id
worker_id
detection_count
```

Result Manager 负责：

```text
Stale Result Check
Per-Stream Latest Result Update
Result Publish
Overlay Dirty Mark
```

过期结果不得覆盖更新帧对应的最新结果。

---

# 21. Overlay

继续使用现有：

```text
Result Manager
      ↓
Overlay MMIO
      ↓
HDMI TX Mosaic
```

最多提交：

```text
8 Detection Boxes
```

结果必须映射到正确的：

```text
4×4 mosaic cell
```

Overlay 不进入 Gemmini Runtime 的关键路径。

显示等待不得阻塞：

```text
下一次 Gemmini Dispatch
```

---

# 22. Scheduler

V5.0 Scheduler 处理的是：

```text
16 Streams
+
3 B1 Workers
```

而不是 Batch Builder。

第一阶段策略：

```text
Latest Frame
+
Fairness
+
No Duplicate Inflight
```

推荐使用：

```text
Oldest-Served-First
```

即优先选择：

```text
距离上次成功推理时间最长
```

的 Stream。

如果 Service Gap 接近，则优先：

```text
更新的 Frame
```

---

## 22.1 每路 Inflight 约束

P0 建议：

```text
Per Stream Inflight <= 1
```

避免：

```text
同一路连续占满三个 Worker
```

同时保证：

```text
16 路公平
```

---

## 22.2 不建立帧积压队列

不使用：

```text
CH0 Frame100
CH0 Frame101
CH0 Frame102
...
```

无限等待。

而使用：

```text
LatestFrame[CH0] = Frame102
```

旧 Candidate 自动被覆盖。

---

# 23. Runtime Job

推荐：

```c
typedef enum {
    JOB_SELECTED,
    JOB_PREPROCESSING,
    JOB_TENSOR_READY,
    JOB_DISPATCHED,
    JOB_RUNNING,
    JOB_WAIT_ASSIST,
    JOB_MODEL_DONE,
    JOB_POSTPROCESSING,
    JOB_RESULT_READY,
    JOB_PUBLISHED,
    JOB_CANCELLED,
    JOB_ERROR
} JobState;
```

一个 Job：

```c
typedef struct {
    uint64_t job_id;

    uint32_t stream_id;
    uint64_t frame_id;
    uint64_t timestamp;
    uint32_t version;

    uintptr_t input_tensor_addr;
    uintptr_t output_tensor_addr;

    uint32_t worker_id;
    JobState state;

    uint64_t select_cycle;
    uint64_t preprocess_done_cycle;
    uint64_t dispatch_cycle;
    uint64_t model_done_cycle;
    uint64_t post_done_cycle;
} FrameJob;
```

---

# 24. Runtime 主循环

推荐 Event-Driven / Non-Blocking：

```c
while (1) {

    service_video_snapshot_events();

    service_preprocess_completion();

    service_gemmini_completions();

    service_rvv_completion();

    release_preprocessed_snapshots();

    build_b1_model_requests();

    dispatch_ready_b1_jobs();

    service_postprocess();

    publish_results();

    recycle_finished_arenas();

    update_metrics();
}
```

关键原则：

```text
Gemmini Busy
!=
Rocket Busy
```

Rocket 不应该：

```text
Launch G0
Wait G0
Launch G1
Wait G1
Launch G2
Wait G2
```

而应该：

```text
Launch G0
Launch G1
Launch G2
继续调度
```

---

# 25. Gemmini Command Interface

每个 Gemmini 至少需要独立：

```text
Command State
Busy State
Completion State
Command Credit
Performance Counter
```

目标结构：

```text
                  Rocket
                     |
              Gemmini Backend
              /      |      \
             v       v       v
           Cmd0    Cmd1    Cmd2
             |       |       |
             v       v       v
            G0      G1      G2
```

P0 可以先：

```text
Non-blocking Polling
```

稳定后再引入：

```text
IRQ
+
Completion Queue
```

---

# 26. 三 Gemmini 并发硬门槛

在 16 路 Scheduler 之前，必须先证明：

```text
G0 Busy
G1 Busy
G2 Busy
```

存在真实重叠区间。

验收：

```text
1. 三个实例可以分别启动
2. 三个实例输出一致
3. 三个实例可以同时 Busy
4. CPU 不因一个 Worker 长期阻塞
5. Completion 能区分 G0/G1/G2
6. Worker Activation Arena 无覆盖
7. Output 无串扰
```

这是 V5.0 成立的硬门槛。

---

# 27. DDR / AXI 拓扑

不能把三个 Gemmini 简化理解为三个独立 DDR 物理端口。

系统逻辑上存在：

```text
Video Write
Display Read
Hardware Preprocess Read/Write
Rocket Access
RVV Access
G0 DMA
G1 DMA
G2 DMA
```

实际 Gemmini 访问最终需要通过 SoC Memory Path 汇聚到 DDR。

必须验证：

```text
G0/G1/G2 Request
       ↓
System Bus / AXI
       ↓
能否同时存在 Outstanding
```

重点不是：

```text
有没有三个 DDR Port
```

而是：

```text
三个 Gemmini 的 memory request
是否被共享前端重新串行化
```

---

# 28. DDR QoS

优先目标：

```text
Video Capture:
不得长期 Overflow

Display:
不得 Underflow

Hardware Preprocess:
保证 Tensor 生产能力

G0/G1/G2:
Weighted Fair

CPU/RVV:
避免阻塞实时数据面
```

禁止简单使用：

```text
AI 永久最高优先级
```

也禁止：

```text
Video 永久压制 AI
```

QoS 必须通过实际计数器优化。

---

# 29. Cache / Coherency

V5.0 必须明确区分：

```text
Video Framebuffer
Tensor Arena
Gemmini Weight / Activation
CPU Postprocess Output
```

不同数据路径的 Cache 属性。

硬件预处理写入 Tensor Arena 后，必须保证 Gemmini 看到的是最新 Tensor。

不能因为旧版本某条路径 coherent，就默认所有新增 Gemmini / Arena 路径天然 coherent。

每条新路径必须明确：

```text
Producer
Consumer
Cacheability
Coherency
Flush / Invalidate Requirement
```

后再实现。

---

# 30. Memory Layout

当前保留：

```text
0x30000000 : Tensor Arena0
0x31000000 : Tensor Arena1
0x32000000 : Model Output Arena
```

V5.0 新增逻辑区域：

```text
Weight Region
Worker Activation Arena0
Worker Activation Arena1
Worker Activation Arena2
Gemmini Command / Completion Metadata
Metrics / Trace
```

这些新增区域的最终物理地址：

```text
TBD
```

由 Gemmini backend 与静态内存规划共同确定，不在没有实现依据时预先虚构地址。

---

# 31. Backpressure Domain

V5.0 分离以下 Backpressure：

```text
Camera / FIFO
DDR Video Writer
Snapshot
Preprocess
Tensor Arena
Gemmini Worker
Postprocess
DDR
```

原则：

```text
Gemmini Worker Backpressure
不能直接传播到 Camera
```

当三个 Worker 全部 Busy：

```text
停止新的 Model Dispatch
```

必要时：

```text
停止新的 AI Admission
```

但：

```text
Video Capture
Frame Store
Display
Latest Frame Update
```

继续运行。

---

# 32. Stable Pipeline

V5.0 理想稳定状态：

```text
Camera / Video DMA:
持续工作

Preprocess:
准备后续 Tensor

G0:
B1 Job A

G1:
B1 Job B

G2:
B1 Job C

Rocket:
Postprocess Previous Job

RVV:
Idle 或执行必要 Assist
```

下一阶段：

```text
G1 完成
   ↓
Ready B1 Job D
   ↓
立即 Dispatch 到 G1
```

核心目标：

```text
最小化三个 Gemmini 的 Idle Gap
```

而不是追求 Batch16。

---

# 33. 性能指标

不能只看：

```text
Theoretical TOPS
```

必须建立以下指标。

## 33.1 Video

```text
Capture FPS / Stream
Framebuffer Drop
FIFO Overflow
DMA Error
Display Underflow
```

## 33.2 Snapshot / Preprocess

```text
Snapshot Hold Time
Preprocess Cycles
Preprocess Throughput
Arena Wait Time
Arena Occupancy
Fresh Mask Ratio
```

## 33.3 Worker

```text
G0 Busy Ratio
G1 Busy Ratio
G2 Busy Ratio

3-Gemmini Concurrent Busy Ratio

Jobs / Worker
Average Job Cycles
Max Job Cycles
```

## 33.4 Memory

```text
G0 DMA Stall
G1 DMA Stall
G2 DMA Stall
Outstanding Depth
Read / Write Bytes
DDR Bandwidth
DDR Arbitration Stall
```

## 33.5 Stream

```text
Inference FPS / Stream
Latest Frame Age
Average Service Gap
Max Service Gap
Superseded Frames
End-to-End Latency
```

## 33.6 CPU / RVV

```text
Rocket Busy Ratio
Postprocess Cycles
RVV Busy Ratio
RVV Wait Queue
```

---

# 34. V5.0 P0 实施顺序

## Step 1：冻结当前已验证数据面

不修改：

```text
5-buffer framebuffer
Snapshot
Hardware Preprocess
Dual Tensor Arena
YOLOv5nu Postprocess
Result Manager
Overlay
```

建立新的回归基线。

---

## Step 2：单 Gemmini64 + B1

实现：

```text
AiModelFrameRequest
      ↓
Gemmini0
      ↓
AiModelFrameCompletion
```

要求：

```text
Model Batch = 1
```

验证：

```text
输入地址
输出地址
量化
模型正确性
cycles
DDR访问
```

---

## Step 3：三个 Gemmini 分别单独验证

依次运行：

```text
G0 only
G1 only
G2 only
```

要求：

```text
相同输入
相同输出
相近 cycles
无地址映射错误
```

---

## Step 4：三个 Gemmini Concurrent B1

运行：

```text
Job A -> G0
Job B -> G1
Job C -> G2
```

确认：

```text
真实 Busy overlap
无共享状态冲突
无 Activation Arena 覆盖
无 Output 串扰
```

---

## Step 5：接入现有 3 logical worker runtime

把：

```text
ai_model_backend_stub
```

替换成：

```text
ai_model_backend_gemmini
```

保持上层 Request / Completion ABI 不变。

---

## Step 6：优化 Snapshot Release 时机

把 Snapshot ownership 从：

```text
等待整个 inference / postprocess
```

前移到：

```text
Hardware Preprocess Done
```

减少 framebuffer 被 AI 长期持有的时间。

---

## Step 7：加入 16-Stream Fair Scheduler

实现：

```text
Latest Frame
+
Oldest Served First
+
Per Stream Inflight <= 1
```

---

## Step 8：建立完整 Metrics

在做任何复杂优化之前先获得：

```text
Single Worker FPS
3 Worker Aggregate FPS
3-Gemmini Concurrent Busy Ratio
DDR Stall
Preprocess Stall
Postprocess Cycles
Per-Stream FPS
```

---

## Step 9：处理 Memory Wall

根据 Profiling 决定：

```text
Outstanding
Burst
QoS
Scratchpad Tiling
Weight Reuse
Activation Reuse
Prefetch
```

一次只修改一个主要变量。

---

## Step 10：Command Path 优化

在功能正确后再实现：

```text
Credit-Based Submission
CONFIG Persistence
Incremental Configuration
Completion Queue
IRQ
```

---

## Step 11：RVV 优化

只有在实际 Profiling 后决定：

```text
哪些模型内部算子需要 RVV
哪些 Postprocess 适合 RVV
```

RVV 不进入图像预处理主路径。

---

# 35. V5.0 第一阶段明确不做

```text
Model Batch > 1
Batch16 Inference
Dynamic Micro-Batch
Cross-Gemmini Single-Layer Split
Cross-Gemmini Operator Pipeline
General DAG Runtime
Dynamic malloc/free
Dynamic Model Switching
Complex Deadline Scheduler
Complex Work Stealing
RVV Image Preprocess
```

这些都不是当前架构成立的必要条件。

---

# 36. 验收标准

## 36.1 视频链路

```text
16 路输入最终均可稳定进入 Frame Store
每路使用 5 Buffer
无持续 Buffer Starvation
Display Underflow = 0
DMA Response Error = 0
```

---

## 36.2 Preprocess

```text
Snapshot ownership 正确
Preprocess 输出正确
Arena0/Arena1 生命周期正确
无 Tensor 覆盖
Preprocess 后可安全释放 Snapshot
```

---

## 36.3 单 Worker

```text
Gemmini B1 模型输出正确
连续运行稳定
无地址错误
无内存覆盖
```

---

## 36.4 三 Worker

```text
G0/G1/G2 可以同时 Busy
三个 B1 Job 真正并行
结果正确绑定 stream/frame
无 Worker 串扰
Aggregate FPS 明显高于 Single Worker
```

---

## 36.5 16 Stream Runtime

```text
16 路都能获得 AI Service
无 Stream 长期 Starvation
旧 Frame 可以 Supersede
同一 Stream 不重复提交相同 Frame
Result 不会回写到错误 Stream
```

---

# 37. V5.0 与 V4.0 的关键变化

| 项目 | V4.0 | V5.0 |
|---|---|---|
| Framebuffer | Triple Buffer 建议 | **每路固定 5 Buffer** |
| Preprocess | RVV Preprocess | **已实现 Hardware Preprocess** |
| 模型 Batch | B1 基线，预留 B2/B4 | **第一阶段固定 B1，不研究更大 Batch** |
| 16 路含义 | 容易与 Batch 混淆 | **16 Stream，与模型 Batch 无关** |
| Tensor 输入 | Input Ring 设计 | **优先复用已实现 Dual Tensor Arena** |
| 模型 Worker | 3 Gemmini Frame-Level | **保留，明确 3×独立 B1** |
| RVV | Pre + Post | **Shared Vector Assist，不做图像预处理** |
| Runtime 接入 | 重新设计较多 | **保持现有 Request/Completion/Postprocess ABI** |
| Snapshot | 通用 Latest Frame | **继承现有 snapshot hold/release，并前移 release 时机** |
| 后处理 | RVV 为主 | **P0 保留已验证 Rocket scalar，Profile 后再迁移 RVV** |
| Memory | 理想化多 Master | **按真实 SoC/AXI 汇聚路径验证并发** |

---

# 38. 最终 V5.0 系统定义

```text
16 × 640×480 Video Streams
        |
        v
Multi-Channel Video Pipeline
        |
        v
5 Frame Buffers / Stream
        |
        v
Latest Safe Snapshot
        |
        v
Hardware Multi-Channel Preprocess
        |
        v
Dual Tensor Arena
        |
        v
Independent B1 Model Requests
        |
        +----------------+----------------+
        |                |                |
        v                v                v
 Gemmini Worker0   Gemmini Worker1   Gemmini Worker2
      64×64             64×64             64×64
      B1                B1                B1
        |                |                |
        +----------------+----------------+
                         |
                 Optional RVV Assist
                         |
                         v
                Model Output Arena
                         |
                         v
               YOLOv5nu Postprocess
                 Rocket First
                         |
                         v
                   Result Manager
                         |
                         v
                    Overlay MMIO
                         |
                         v
                  HDMI 4×4 Mosaic
```

系统定位：

```text
1 Rocket RV64
+
1 Saturn RVV
+
3 × Gemmini 64×64
+
16-Stream Video Frontend
+
5-Buffer / Stream Frame Store
+
Hardware Preprocess
+
Dual Tensor Arena
+
Model Batch = 1
+
3 Concurrent B1 Workers
+
Frame-Level Parallelism
+
Static Fixed-Model Runtime
+
Per-Worker Activation Arena
+
Single Logical Weight Region
+
Non-Blocking Multi-Gemmini Dispatch
+
CPU-first YOLOv5nu Postprocess
```

---

# 39. V5.0 核心原则

```text
视频稳定性优先于 AI 吞吐
```

```text
5 Buffer 是视频平面的稳定基线
```

```text
16 Stream 不等于 Batch16
```

```text
模型第一阶段永远 Batch = 1
```

```text
3 个 Gemmini = 3 个独立 B1 Worker
```

```text
Hardware Preprocess 负责 Pixel -> Tensor
```

```text
Gemmini 负责主模型计算
```

```text
RVV 只承担有明确收益的共享向量任务
```

```text
Rocket 负责控制、调度和第一阶段后处理
```

```text
Gemmini Busy 不能反压 Camera
```

```text
优先复用已经板上验证的模块和软件 ABI
```

```text
任何复杂优化都必须建立在 Profiling 之后
```

最终目标不是追求一个理论上的复杂 Runtime，而是：

```text
在已经稳定的视频/DDR/预处理平台上，
让 3 个 64×64 Gemmini 持续执行三个独立的 B1 Frame，
同时保证 16 路视频公平、低积压、无错误绑定，
并通过静态内存、非阻塞调度和可观测 DDR 行为获得稳定的端侧吞吐。
```
