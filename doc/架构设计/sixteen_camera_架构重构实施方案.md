# sixteen_camera 架构重构实施方案

> 项目：`Cc-aw/sixteen_camera`
> 目标：在现有功能基本完成并已多轮上板验证的基础上，对工程进行一次以 **架构分层、代码层级、去冗余、时序优化、资源优化、可维护性提升** 为核心的系统性重构。
> 原则：**不重新设计已验证功能，不推倒重写；先拆边界，再优化微架构。**

---

## 1. 重构背景

当前工程已经实现并验证了较完整的系统功能，包括：

- 8 路 OV7670 DVP 摄像头输入；
- 1 路 4K HDMI transport 拆分为 8 路 640×480 输入；
- 16 路视频 DDR 帧缓存；
- 4×4 mosaic 1080p60 HDMI 输出；
- 视频流直接生成 YOLOv5nu Tensor；
- Tensor Slot 管理与共享 DMA；
- 双 Gemmini 推理；
- Head Slot；
- 硬件 PPU；
- 检测结果管理与 overlay；
- 多级诊断和板级验证。

最近多轮快速开发使功能不断叠加，导致几个集成模块逐渐承担过多职责：

- `multi_channel_ddr_video_pipeline.sv`
- `ov7670_frontend.sv`
- `multi_channel_framebuffer_ctrl.sv`
- `ddr_memory_subsystem.sv`

目前主要问题已经从“功能缺失”转变为：

1. 数据面、控制面、CDC、诊断面互相耦合；
2. 大量宽状态总线跨时钟域；
3. 300 MHz Camera 热路径包含过多非实时诊断逻辑；
4. 顶层集成模块过大；
5. 生产 RTL 与历史代码、生成代码、Vivado import 文件边界不清；
6. 后续继续增加 Gemmini、Tensor、PPU 功能时容易再次侵入视频核心；
7. 层次不清导致时序、资源和拥塞问题难以定位。

因此本轮重构的核心目标不是新增功能，而是建立一个长期稳定的系统骨架。

---

# 2. 总体目标架构

最终希望将系统明确拆成以下六类：

```text
Data Plane      数据面
Control Plane   控制面
Telemetry       诊断/统计面
Platform        FPGA/DDR/SoC 平台层
Generated       自动生成代码/IP
Legacy          历史兼容代码
```

推荐最终 RTL 层次：

```text
rtl/
├── top/
│   └── sixteen_camera_top.sv
│
├── common/
│   ├── pkg/
│   │   ├── system_cfg_pkg.sv
│   │   ├── video_types_pkg.sv
│   │   ├── frame_types_pkg.sv
│   │   └── ai_types_pkg.sv
│   │
│   ├── interfaces/
│   │   ├── axi4_if.sv
│   │   ├── axi_lite_if.sv
│   │   ├── video_stream_if.sv
│   │   └── axis_video_if.sv
│   │
│   ├── cdc/
│   │   ├── cdc_toggle_handshake.sv
│   │   ├── cdc_mailbox.sv
│   │   ├── cdc_snapshot.sv
│   │   └── stream_cdc.sv
│   │
│   └── bus/
│
├── platform/
│   ├── board_io/
│   ├── clock_reset/
│   ├── ddr/
│   └── soc/
│
├── video/
│   ├── ingress/
│   │   ├── camera/
│   │   └── hdmi/
│   │
│   ├── frame_store/
│   └── display/
│
├── ai/
│   ├── tensor/
│   └── postprocess/
│
└── control/
    ├── csr/
    ├── telemetry/
    └── compat/
```

生成代码和历史代码移出生产 RTL：

```text
generated/
├── xilinx_ip/
└── soc/

legacy/
├── rtl/
└── preprocess/
```

---

# 3. 重构原则

## 3.1 不推倒重写

本轮重构必须尽量保持已经验证过的功能行为：

- DVP PCLK recovery 算法不主动重写；
- Frame ownership 协议保持；
- Tensor Slot READY 发布必须继续以最后一个 AXI B 成功返回为准；
- RUNNING Tensor Slot 在 compute completion 后才能释放；
- Head Slot 在 PPU completion 后才能释放；
- PPU doorbell 前继续保持 fence / flush；
- AXI ordering、4 KiB boundary 等协议约束保持；
- FBus bit31 alias 语义保持；
- Overlay 仍只在输出帧边界原子更新。

---

## 3.2 每次只改变一种东西

所有重构遵循：

```text
MOVE
 ↓
TEST
 ↓
OPTIMIZE
 ↓
TEST
```

禁止一次同时：

```text
MOVE + REWRITE + CDC CHANGE + TIMING OPT
```

推荐 commit 粒度：

```text
refactor: extract frame store subsystem
refactor: extract tensor ingress subsystem
refactor: isolate video control CDC
opt: replace wide tensor status CDC with indexed snapshot
```

这样能够通过 Git bisect 快速定位问题。

---

# 4. 新的实施阶段

由于当前时间紧迫，不再单独执行完整 R0 / R1。

采用：

```text
R1-fast
   ↓
R2
   ↓
R3
   ↓
R4
   ↓
R5
   ↓
R6
   ↓
R7
   ↓
R1-final
```

---

# 5. R1-fast：建立生产源码边界

这一阶段只做后续重构必须具备的最低基础。

## 5.1 建立 production manifest

当前 `setup_vivado.tcl` 仍通过递归扫描：

```text
rtl/video
rtl/ai
...
```

再依靠 blacklist 排除 retired 模块。

需要改为显式白名单：

```text
build/
├── rtl_manifest.tcl
├── ip_manifest.tcl
├── soc_manifest.tcl
└── xdc_manifest.tcl
```

原则：

```text
manifest 中的文件 = production source
manifest 外的文件 = 默认不参与综合
```

例如：

```tcl
set RTL_SOURCES {
    rtl/top/sixteen_camera_top.sv

    rtl/common/interfaces/axi4_if.sv
    rtl/common/interfaces/axi_lite_if.sv
    rtl/common/interfaces/video_stream_if.sv

    rtl/video/ingress/camera/camera_subsystem.sv
    ...
}
```

禁止后续继续通过递归 glob 自动决定生产源码。

---

## 5.2 立即清理的内容

### 删除 Vivado import RTL 副本

移除：

```text
prj/sixteen_camera.srcs/sources_1/imports/rtl/
```

生产源码只保留唯一 canonical source：

```text
rtl/
```

---

### 移出 `rtl_old`

将：

```text
rtl/rtl_old/
```

移动为：

```text
legacy/rtl/
```

`rtl/` 应只表示当前生产 RTL。

---

### retired preprocess 移出生产树

当前已退出生产路径的：

```text
batch_preprocess_engine.sv
frame_preprocess_accel.sv
```

移动为：

```text
legacy/preprocess/
```

删除 `setup_vivado.tcl` 中针对它们的 blacklist 逻辑。

---

## 5.3 暂时不处理

为了避免在当前阶段投入过多时间，先保留：

```text
rtl/ip/
rtl/soc/
artifacts/
sw/yolov5/生成文件
```

这些内容最后在 `R1-final` 中统一处理。

---

# 6. R2：建立 Common 基础设施

R2 不追求大而全，只建立当前项目已经重复使用的公共设施。

---

## 6.1 Package

建立：

```text
rtl/common/pkg/
├── system_cfg_pkg.sv
├── video_types_pkg.sv
├── frame_types_pkg.sv
└── ai_types_pkg.sv
```

逐步减少大量无语义宽总线，例如：

```text
[CHANNELS*32-1:0]
[CHANNELS*64-1:0]
[223:0]
```

推荐使用结构体：

```systemverilog
typedef struct packed {
    logic [31:0] addr;
    logic [31:0] frame_id;
    logic [63:0] timestamp;
    logic [31:0] version;
    logic [31:0] bytes;
    logic [7:0]  state;
    logic [7:0]  error;
} tensor_slot_meta_t;
```

---

## 6.2 CDC primitives

建立：

```text
rtl/common/cdc/
├── cdc_toggle_handshake.sv
├── cdc_mailbox.sv
└── cdc_snapshot.sv
```

### `cdc_toggle_handshake`

统一实现：

```text
req toggle
→ synchronizer
→ seen
→ destination pulse
→ ack toggle
→ synchronizer back
→ busy
```

用于替代工程中大量重复代码。

---

### `cdc_mailbox`

用于需要稳定 payload 的跨域命令：

```text
source payload
+
request
↓
destination stable capture
↓
ack
```

典型用途：

- AI metadata；
- Tensor Slot metadata；
- 配置；
- Overlay command；
- descriptor。

---

### `cdc_snapshot`

用于：

- performance counter；
- diagnostic；
- status。

原则：

> CPU 需要时请求一次 snapshot，而不是所有状态永远通过巨宽 CDC 实时同步。

---

# 7. R3：拆分 `multi_channel_ddr_video_pipeline`

这是整个重构的核心阶段。

当前该模块约 1354 行，同时承担：

```text
frame manager
video DMA
display reader
Tensor DMA
AI snapshot
AI metadata
preprocess compatibility
overlay
MMIO status
CPU ↔ video CDC
performance counter CDC
HDMI diagnostics
```

需要重构为：

```text
video_pipeline_subsystem
│
├── frame_store_subsystem
├── tensor_ingress_subsystem
├── display_subsystem
├── video_control_bridge
└── legacy_compat
```

---

## 7.1 Frame Store

建立：

```text
frame_store_subsystem.sv
```

内部：

```text
multi_channel_frame_manager
multi_channel_video_dma
display_reader_subsystem
```

只负责：

```text
capture stream
frame ownership
DDR writer
DDR display reader
```

禁止认识：

```text
Tensor Slot
PPU
CPU CSR
Overlay labels
```

---

## 7.2 Tensor Ingress

建立：

```text
tensor_ingress_subsystem.sv
```

内部数据流：

```text
accepted video stream
      ↓
tensor packer[16]
      ↓
per-channel elastic FIFO
      ↓
shared tensor scheduler
      ↓
Tensor DMA
      ↓
Tensor Slot Manager
```

只负责视频到 Tensor Slot。

---

## 7.3 Display

建立：

```text
display_subsystem.sv
```

内部：

```text
mosaic_frame_reader
detection_overlay
```

Display 只接受标准 overlay command，不直接知道 AI runtime。

---

## 7.4 Video Control Bridge

建立：

```text
video_control_bridge.sv
```

职责：

```text
100 MHz CPU / AXI-Lite
        ↕
        CDC
        ↕
150 MHz video domain
```

最终保证：

```text
frame_store_subsystem
tensor_ingress_subsystem
display_subsystem
```

都成为纯 150 MHz 数据面模块。

---

## 7.5 R3 分两步完成

### R3-A：只搬 CDC

先把现有：

```text
u_writer_count_cdc
u_drop_count_cdc
u_malformed_count_cdc
u_overlay_payload_cdc
...
```

原样移动到 `video_control_bridge`。

协议暂时不改变。

---

### R3-B：再优化 CDC

等模块拆分稳定之后，再执行：

```text
continuous wide CDC
        ↓
indexed snapshot / mailbox
```

典型优化：

```text
32 × frame_id
32 × timestamp
32 × version
32 × state
```

不要持续跨域。

改成：

```text
CPU select index
      ↓
request
      ↓
video domain metadata RAM
      ↓
single metadata snapshot
      ↓
CPU
```

---

## 7.6 R3 验收目标

原：

```text
multi_channel_ddr_video_pipeline.sv
≈1354 lines
≈50 XPM CDC
```

目标：

```text
video_pipeline_subsystem.sv
≈200~300 lines
```

该文件只负责 subsystem integration。

---

# 8. R4：Camera 热路径重构

当前：

```text
ov7670_frontend.sv
≈2049 lines
```

同时包含：

```text
ov7670_ztachip_ctrl
ov7670_axil_regs
ov7670_frontend
```

以及大量：

```text
PCLK recovery
DVP sampling
HREF / VSYNC
geometry
line statistics
frame statistics
PCLK diagnostics
snapshot
AXI-Lite
CDC
```

它位于当前最敏感的约 300 MHz capture 域，因此是 R3 之后的最高优先级。

---

## 8.1 推荐层次

```text
video/ingress/camera/
├── control/
│   ├── ov7670_init_ctrl.sv
│   └── ov7670_regs.sv
│
├── capture/
│   ├── dvp_input_sampler.sv
│   ├── dvp_pclk_recovery.sv
│   ├── dvp_sync_guard.sv
│   └── dvp_event_encoder.sv
│
├── bridge/
│   └── dvp_event_bridge.sv
│
├── video/
│   └── camera_pixel_assembler.sv
│
├── telemetry/
│   └── camera_telemetry.sv
│
└── camera_channel.sv
```

---

## 8.2 300 MHz 域最终只保留实时 datapath

```text
IOB
 │
 ▼
DVP input sampler
 │
 ▼
PCLK recovery
 │
 ▼
HREF / VSYNC qualification
 │
 ▼
event encoder
 │
 ▼
event FIFO
======================== CDC boundary
 │
 ▼
150 MHz
```

---

## 8.3 300 MHz 域不再承担

尽量移出：

```text
大量 32/64-bit diagnostic counters
宽 snapshot
CPU-readable register logic
复杂运行配置
非实时统计
```

---

## 8.4 Telemetry 下沉

当前大量：

```text
pclk_candidate_count
pclk_valid_count
pclk_glitch_count
pclk_missing_count
pclk_holdover_count
...
```

改成：

```text
300 MHz hot path
 │
 ├ glitch_event
 ├ missing_event
 ├ lock_loss_event
 ├ line_good_event
 └ frame_event
       │
       ▼
150 MHz telemetry accumulator
       │
       ▼
100 MHz CPU snapshot
```

注意：

> 第一轮不要主动重写 `dvp_pclk_recovery` 核心算法。

它已经经过真实板级验证，本轮优先优化其周围结构。

---

# 9. R5：Memory 层重构

完成 R3/R4 后再拆：

```text
ddr_memory_subsystem.sv
```

最终目标：

```text
memory_subsystem
│
├── ddr_platform
│   ├── MIG
│   ├── clock
│   └── reset
│
├── video_memory_ports
│   ├── writer CDC
│   └── reader CDC
│
├── tensor_memory_bridge
│
└── postprocess_memory_bridge
```

Memory 层只负责：

> 谁访问 memory，以及怎样跨 domain / 接入 AXI。

Memory 层不应该理解：

```text
YOLO
overlay
camera diagnostic
frame result semantics
```

---

# 10. R6：CSR / Control 重构

当前：

```text
multi_channel_framebuffer_ctrl.sv
≈920 lines
```

包含一个超大的 sequential CSR block，同时管理：

```text
framebuffer
display
AI snapshot
Tensor
preprocess compatibility
overlay
performance counters
HDMI diagnostics
```

在架构稳定后拆成：

```text
control/csr/
├── video_csr.sv
├── frame_csr.sv
├── tensor_csr.sv
├── overlay_csr.sv
└── telemetry_csr.sv
```

---

## 10.1 CSR generator 暂缓

长期推荐通过：

```text
config/video_regs.yaml
```

生成：

```text
RTL register package
AXI-Lite register bank
C header
Markdown register documentation
```

但由于当前时间紧，CSR generator 不作为前期重构阻塞项。

优先：

```text
先拆模块
后自动生成
```

---

# 11. R7：资源与时序优化

完成架构分层后，再基于新 hierarchy 报告做真正的物理优化。

重点使用：

```tcl
report_timing_summary
report_timing
report_utilization -hierarchical
report_high_fanout_nets
report_design_analysis
report_cdc
```

---

## 11.1 优先资源优化方向

### 宽 CDC → snapshot/mailbox

预期：

```text
FF ↓
routing ↓
high-fanout ↓
timing ↑
```

---

### Camera telemetry 下沉

预期：

```text
300 MHz FF ↓
300 MHz enable/reset fanout ↓
SLR routing ↓
timing ↑
```

---

### FIFO 深度按真实 occupancy 收缩

所有关键 FIFO 增加：

```text
current_level
max_level
full_cycles
empty_cycles
overflow_count
stall_cycles
```

实际压力测试后：

```text
new_depth >= measured_max × safety_margin
```

再缩深度。

禁止仅凭感觉直接：

```text
1024 → 512 → 256
```

---

### Generated LUT ROM → inferred BRAM

重点关注：

```text
yolov5nu_dfl_lut.sv
yolov5nu_raw_class_lut.sv
```

当前是大规模 combinational case ROM。

先检查 synthesis mapping。

若主要映射为 LUT mux，可考虑：

```text
constant ROM / inferred BRAM
+
1 cycle pipeline
```

以 BRAM 换 LUT 和路由。

---

### AXI / SLR boundary pipeline

对跨 SLR 的：

```text
ready
valid
enable
reset
descriptor
```

优先增加局部 register boundary，而不是继续扩大 timing exception。

---

# 12. 最后的 R1-final

核心架构稳定后再统一整理仓库。

包括：

```text
rtl/ip/
rtl/soc/
artifacts/
reports/
prj/
legacy/
generated/
sw generated files
```

目标：

- Xilinx IP 只保留必要配置；
- SoC collateral 明确 current/frozen；
- 旧 collateral 归档；
- Vivado 工程完全可重建；
- `.gitignore` 完善；
- 历史架构文档归档；
- README 更新；
- 生产源码唯一；
- Generated / Legacy / Production 三类边界清晰。

---

# 13. 当前不优先重写的模块

以下模块的基本架构方向已经较合理：

```text
multi_channel_video_dma
yolov5nu_multi_channel_tensor_dma
fbus_read_engine
Tensor Slot lifecycle
Head Slot queue
PPU compute/result split
frame ownership
```

本轮原则：

> 先把成熟“发动机”从过大的集成模块里拆出来，不重新设计已经验证过的发动机。

---

# 14. 实际开发顺序

当前直接按以下顺序执行：

1. 建立 `build/rtl_manifest.tcl`，停止递归扫描 RTL；
2. 删除 `prj/.../imports/rtl`；
3. `rtl_old → legacy/rtl`；
4. retired preprocess 移出生产树；
5. 建立 `common/pkg`；
6. 建立 `common/cdc`；
7. 拆 `frame_store_subsystem`；
8. 拆 `tensor_ingress_subsystem`；
9. 拆 `display_subsystem`；
10. 建立 `video_control_bridge`；
11. 将现有 CDC 原样集中进去；
12. 将宽 CDC 改成 snapshot/mailbox；
13. 拆 `ov7670_frontend`；
14. Camera telemetry 下沉；
15. 拆 `ddr_memory_subsystem`；
16. 拆 CSR；
17. 基于新 hierarchy 做 timing/resource 优化；
18. 完成 R1-final 仓库清理。

---

# 15. 三个近期里程碑

## Milestone 1：生产源码唯一

```text
生产源码只有一份
Vivado 只认 manifest
Legacy 不可能误入综合
```

---

## Milestone 2：Video Pipeline 不再是 God Module

```text
multi_channel_ddr_video_pipeline
            ↓
video_pipeline_subsystem
├ frame_store
├ tensor_ingress
├ display
└ control_bridge
```

集成 shell 不再承担复杂业务逻辑。

---

## Milestone 3：300 MHz Camera 域只保留实时 datapath

```text
DVP sampling
→ PCLK recovery
→ sync guard
→ event encoder
→ CDC
```

所有非必要 telemetry 尽量移至 150/100 MHz。

---

# 16. 最终目标结构

最终全系统的核心结构应清晰为：

```text
                     ┌── frame_store ─── display ─── overlay
Camera / HDMI ───────┤
                     └── tensor_ingress ─── SoC / Gemmini
                                              │
                                              ▼
                                          head_store
                                              │
                                              ▼
                                             PPU

Control ───── command / mailbox ───────────────┘
Telemetry ◀── snapshot / events ───────────────┘
```

这样以后增加：

```text
3×Gemmini64
1×128×128 Gemmini
新的 Tensor 调度
新的 Head Slot
新的 PPU
MLIR/编译器调度
```

主要影响：

```text
ai/
control/
memory bridge
```

而不会再次侵入：

```text
Camera
Display
Framebuffer core
```

---

# 17. 重构完成后的验收要求

## 功能回归

```text
video regression PASS
Tensor regression PASS
PPU regression PASS
software -Werror PASS
```

---

## CDC

```text
无新增无法解释的 CDC warning
```

---

## Timing

最终目标：

```text
WNS >= 0
TNS = 0
WHS >= 0
THS = 0
```

---

## 板级

至少重新验证：

```text
8 路 Camera
HDMI 8 路输入
16 路 DDR
4×4 mosaic
Tensor production
双 Gemmini
Head Slot
PPU
Overlay
长时间运行
```

---

# 18. 核心结论

本轮重构最重要的不是把代码写得更漂亮，而是重新建立明确的系统边界：

```text
Data Plane
Control Plane
CDC Boundary
Telemetry
Platform
Generated
Legacy
```

优先解决三个问题：

1. **生产源码唯一，Vivado 只通过 manifest 构建设计；**
2. **拆掉 `multi_channel_ddr_video_pipeline` 的 God Module 结构；**
3. **将 300 MHz Camera 域恢复为纯实时数据路径。**

只要这三个目标完成，后续继续开发 Gemmini、Tensor DMA、PPU 或 MLIR，都不再需要反复侵入视频核心，整个工程才会真正进入可持续迭代状态。
