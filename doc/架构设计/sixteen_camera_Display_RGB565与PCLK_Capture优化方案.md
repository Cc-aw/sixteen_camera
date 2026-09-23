# sixteen_camera 外围视频架构优化方案：Display RGB565 + PCLK Capture Island

> 项目：`Cc-aw/sixteen_camera`  
> 目标器件：Xilinx Virtex UltraScale+ VU13P `xcvu13p-fhga2104-2-i`  
> 工具：Vivado 2023.2  
> 文档目标：在不改变当前 AI 推理主路径的前提下，优化 SoC 外围视频数据流，重点解决两类问题：
>
> 1. Display Frame 仍使用 `640×480 XRGB8888`，造成不必要的 DDR 带宽、地址空间和 Mosaic Reader 复杂度；
> 2. OV7670 板级 DVP 信号质量较差，必须保留约 300 MHz 过采样与 PCLK 恢复，但 capture 域仍存在时序和物理布局压力。

---

# 1. 总体结论

本轮不改变以下核心事实：

- OV7670 板级采样不稳定，**不能取消 300 MHz 过采样恢复**；
- `cam_pclk` 继续作为异步数据处理，不能直接作为 fabric clock；
- AI 输入继续从 canonical 640×480 视频流直接生成 Tensor；
- AI Tensor 继续保持 `640×480×3 NHWC INT8`；
- 未来如需要 Snapshot，可从 Tensor Slot 恢复近似 RGB888 原图，不要求 Display Frame 保存完整 640×480；
- Display 与 AI 应继续沿独立生命周期演进；
- Frame/Slot 只有在真实事务完成边界后才能发布或释放；
- 不通过扩大 `false_path`、降低真实时钟约束或伪造 multicycle 来“修复”时序。

本轮目标架构：

```text
                           8 × OV7670
                               │
                               ▼
                ┌─────────────────────────┐
                │ 300 MHz Capture Island  │
                │ IOB → sync → recovery   │
                │ → registered sample     │
                │ → event encoder         │
                └───────────┬─────────────┘
                            │
                     300 → 150 event FIFO
                            │
                            ▼
                     RGB565 assembler
                            │
                            ▼
                     Canonical Video
                       640×480
                            │
                    ┌───────┴────────┐
                    │                │
                    ▼                ▼
                AI Path          Display Path
             640×480 RGB       stream scaler
                    │          640×480→360×270
                    ▼                │
             Tensor packer           ▼
             RGB INT8           RGB565 pack
                    │                │
                    ▼                ▼
              Tensor Slot       Display Frame
                                   DDR Pool
                                     │
                                     ▼
                               Mosaic Reader
                                     │
                              RGB565→RGB888
                                     │
                                     ▼
                                  Overlay
                                     │
                                     ▼
                                HDMI 1080p60
```

核心原则：

> **PCLK 路径保留高鲁棒性，通过局部化、流水化、缩短控制锥来收时序。**

> **Display 路径主动降低 representation，通过提前 resize + RGB565 大幅降低 DDR 带宽和逻辑复杂度。**

---

# 2. 当前架构中需要保留的设计

## 2.1 AI Tensor 继续直接从视频流产生

当前生产路径已经避免：

```text
Video → Framebuffer DDR → DDR Read → Preprocess → Tensor
```

而采用：

```text
Video accepted stream
        │
        ▼
RGB INT8 pack
        │
        ▼
Tensor DMA
        │
        ▼
Tensor Slot
```

该结构必须保留。

原因：

- 避免完整 framebuffer read-back；
- AI 生命周期与显示 framebuffer 解耦；
- 后续换 Gemmini 数量、阵列尺寸或调度器，不影响视频输入 representation；
- Tensor Slot 可以作为未来 Snapshot 的候选源数据。

## 2.2 PCLK 继续使用高速异步过采样恢复

当前设计原则正确：

```text
PCLK + DATA + HREF + VSYNC
          │
          ▼
300 MHz IOB sample
          │
          ▼
metastability/alignment
          │
          ▼
PCLK recovery
          │
          ▼
pixel_ce / aligned byte
```

禁止改成：

```text
always @(posedge cam_pclk)
```

也禁止把恢复后的 `pixel_ce` 作为新时钟。

当前板级链路存在真实的抖动、串扰、毛刺和采样不稳定问题，因此过采样恢复是功能必需，不是可以删除的“冗余逻辑”。

---

# 3. Display RGB565 优化目标

## 3.1 当前问题

当前 Display Frame 约为：

```text
640 × 480 × XRGB8888
```

单帧有效 payload：

```text
640 × 480 × 4
= 1,228,800 Bytes
≈ 1.17 MiB
```

16 路、30 FPS 的 framebuffer 写带宽约：

```text
640 × 480 × 4 × 30 × 16
≈ 589.8 MB/s
```

当前 Mosaic Reader 为输出 1080p60，还需要不断从完整 640×480 framebuffer 读取源行，再做 640→360 缩放。

因此 Display 支路承担了两类浪费：

1. DDR 中保存最终不会显示的高分辨率像素；
2. Mosaic Reader 每次输出都重复执行 resize。

---

# 4. Display 目标 Representation

Display 不再保存 AI representation，而保存专用显示 representation：

```text
有效分辨率：360 × 270
颜色格式：RGB565
物理存储宽度：368 pixels
行步长：736 Bytes
```

原因：

```text
RGB565 = 2 Bytes / pixel
256-bit AXI beat = 32 Bytes
1 beat = 16 RGB565 pixels
```

`360 / 16 = 22.5`，不能整 beat 对齐。

因此采用：

```text
DISPLAY_ACTIVE_W = 360
DISPLAY_STORE_W  = 368
DISPLAY_H        = 270

DISPLAY_STRIDE = 368 × 2
               = 736 Bytes
               = 23 × 32 Bytes
```

每行：

```text
[360 valid pixels][8 padding pixels]
```

Reader 只输出前 360 像素。

不建议为了节省 16 Bytes/line 引入 partial WSTRB、partial beat packer 和特殊 reader 尾拍逻辑。

---

# 5. Display DDR 带宽收益

## 5.1 新 framebuffer 写带宽

```text
368 × 270 × 2 × 30 × 16
≈ 95.4 MB/s
```

若仅按有效像素计：

```text
360 × 270 × 2 × 30 × 16
≈ 93.3 MB/s
```

## 5.2 新 framebuffer 读带宽

1080p60 4×4 Mosaic 每路每输出帧读取 360×270 RGB565：

```text
368 × 270 × 2 × 60 × 16
≈ 190.8 MB/s
```

有效像素约：

```text
186.6 MB/s
```

## 5.3 对比

当前 Display 侧约：

```text
Framebuffer Write ≈ 590 MB/s
Mosaic Read       ≈ 664 MB/s
--------------------------------
Total             ≈ 1.25 GB/s
```

优化后约：

```text
Display Write ≈ 95 MB/s
Display Read  ≈ 191 MB/s
----------------------------
Total         ≈ 286 MB/s
```

理论减少接近：

```text
≈ 0.97 GB/s
≈ 77%
```

该收益不依赖 SoC 内部 Gemmini 优化，是独立的外围带宽收益。

---

# 6. Display 新数据流

推荐：

```text
Canonical 640×480 Video
          │
          ▼
   Display Scaler
  640×480 → 360×270
          │
          ▼
    RGB888 → RGB565
          │
          ▼
   256-bit RGB565 pack
  16 pixels / AXI beat
          │
          ▼
      Display DMA
          │
          ▼
       DDR Pool
          │
          ▼
     Mosaic Reader
          │
          ▼
   RGB565 → RGB888
          │
          ▼
 Detection Overlay
          │
          ▼
       HDMI TX
```

---

# 7. Scaler 的位置

Scaler 必须放在：

```text
Ingress / Fanout
       ↓
Display branch
       ↓
Scaler
       ↓
Frame Store
```

不能放在：

```text
Framebuffer DDR
       ↓
Scaler
```

否则 DDR 带宽不会真正减少。

推荐：

```text
                         ┌── Tensor Path 640×480
Canonical Video ────────┤
                         └── Display Scaler 640×480→360×270
```

---

# 8. Scaler 第一版建议

第一版不要实现复杂插值。

采用与当前 Mosaic Reader 等价的 nearest-neighbor/fixed-ratio 方案即可。

目标比例：

```text
640 → 360 = 9/16
480 → 270 = 9/16
```

因此 X/Y 都是相同固定比例。

推荐使用相位累加器而不是乘法/除法：

```text
source step = 16
output step = 9
```

要求：

- 不使用通用乘法器；
- 不在 150 MHz 热路径放除法；
- 输入连续时支持稳定吞吐；
- 一帧严格产生 360×270 有效像素；
- 行尾自动补 8 个 storage padding pixel 或由 packer 直接补零；
- SOF/EOL/EOF 必须重新生成并与缩放后图像一致。

---

# 9. RGB565 转换

Canonical video 保持现有 RGB888 语义。

Display branch 内单独转换：

```systemverilog
rgb565 = {
    r[7:3],
    g[7:2],
    b[7:3]
};
```

读取后恢复：

```systemverilog
r8 = {r5, r5[4:2]};
g8 = {g6, g6[5:4]};
b8 = {b5, b5[4:2]};
```

不为了 Display 优化而修改 AI 或 Camera canonical stream 格式。

---

# 10. Display Frame Pool 建议

一帧 physical payload：

```text
368 × 270 × 2
= 198,720 Bytes
≈ 194 KiB
```

推荐：

```text
DISPLAY_SLOT_STRIDE = 256 KiB = 0x0004_0000
DISPLAY_SLOTS       = 4
```

每路：

```text
4 × 256 KiB = 1 MiB
```

16 路：

```text
16 MiB
```

相比当前约 32 MiB/channel 的大地址窗口，可显著缩小 Display 地址空间。

第一阶段先保留 4 slot，完成压力测试后再判断是否可降至 3 slot。

---

# 11. Display Frame Manager 状态

继续保留清晰所有权：

```text
FREE
  ↓
WRITING
  ↓
READY
  ↓
READING
  ↓
FREE
```

必须维持：

- Writer 只能申请 FREE；
- 只有最后一个对应 AXI B 成功返回后才能发布 READY；
- Reader 在完整输出帧开始时锁定一组 buffer；
- Mosaic 一帧输出期间不切换其中任一路 framebuffer；
- Writer 不得覆盖当前 Display 正在持有的 slot；
- AXI error / malformed / overflow 的帧不能发布 READY。

---

# 12. Mosaic Reader 简化

优化后 Mosaic Reader 不再负责：

```text
640→360 X scaling
480→270 Y scaling
```

只负责：

```text
4×4 tile mapping
60 pixel left padding
360 pixel image
60 pixel right padding
```

Tile：

```text
480 × 270
```

布局：

```text
| 60 black | 360 image | 60 black |
```

可以删除/简化当前与 source scaling 相关的：

- X 方向 16/9 coordinate phase；
- source pair conversion；
- Y source phase；
- 640-pixel source line缓存相关逻辑；
- resize 和 tile 混合控制。

新的 Reader 更接近纯 framebuffer compositor。

---

# 13. Overlay 保持在 framebuffer 之后

推荐：

```text
DDR RGB565
    ↓
RGB565 → RGB888
    ↓
Overlay
    ↓
HDMI
```

不要把框写回 RGB565 framebuffer。

优势：

- 不污染显示原图；
- AI result 更新不需要重写 framebuffer；
- shadow → frame boundary commit 机制可继续沿用；
- label、confidence 和 class color 继续在 RGB888 域完成。

---

# 14. Snapshot 兼容性

未来如增加 Snapshot，不要求恢复 640×480 Display framebuffer。

AI Tensor 已保存：

```text
640×480×3 INT8
R_tensor = R >> 1
G_tensor = G >> 1
B_tensor = B >> 1
```

可恢复近似 RGB888：

```text
R ≈ R_tensor << 1
G ≈ G_tensor << 1
B ≈ B_tensor << 1
```

因此未来 Snapshot 可设计为：

```text
Tensor Slot
    ↓
RGB recover
    ↓
bbox renderer
    ↓
Snapshot DDR / CPU storage
```

Display Frame 与 Snapshot 生命周期分离。

---

# 15. PCLK 优化背景

板级 DVP 采样质量不稳定，必须继续依赖高频过采样和恢复。

当前方向已经正确：

- IOB 首拍；
- metastability catching；
- alignment；
- high/low confirm；
- SEARCH / ACQUIRE / LOCK / HOLDOVER；
- period/phase estimator；
- history-based sample tap；
- 300→150 event FIFO；
- fault/resync。

因此本轮不改变恢复能力，重点优化：

1. Capture Island 物理局部性；
2. Recovery 内部 decision pipeline；
3. Diagnostic 与 functional core 分离；
4. 减少 reset/CE 高扇出；
5. 缩短 300 MHz raw bus 的物理距离；
6. 让跨 SLR 发生在 event/FIFO 边界而不是 raw sample 边界。

---

# 16. PCLK 时序历史基线

项目旧 routed 基线曾出现：

```text
WNS = -1.291 ns
TNS = -6258.903 ns
20800 setup endpoints
```

全部主要位于约 300.120 MHz 域。

后续 P4 routed 已降至：

```text
22 negative endpoints
WNS = -0.182 ns
TNS ≈ -1.576 ns
```

其中：

```text
PCLK/frontend:
18 endpoints
WNS ≈ -0.138 ns
```

当前 main 已进一步实施 P5：

- payload/alignment 寄存器不再使用运行时 reset；
- snapshot payload 不再被大范围 reset；
- sync stage 采用 clock-region locality 引导；
- recovery/event producer 按通道组做 soft SLR placement；
- 继续保留 IOB→sync 1.5 ns physical budget。

因此后续优化应以新的 P5 routed timing 为真实基线，而不能直接照旧 P4 报告继续修。

---

# 17. PCLK Capture Island 目标架构

每路：

```text
DVP pins
  │
  ▼
IOB Sample
  │
  ▼
Metastability FF
  │
  ▼
Alignment FF
  │
  ▼
Edge Filter
  │
  ▼
Edge Snapshot
  │
  ▼
Classification Pipeline
  │
  ▼
Recovery FSM
  │
  ▼
Sample History
  │
  ▼
Registered Final Tap
  │
  ▼
Event Encoder
  │
  ▼
Async Event FIFO
300 MHz → 150 MHz
```

Capture Island 之外：

```text
150 MHz:
RGB565 byte assembly
RGB888 canonical stream
frame normalization
Display/Tensor fanout
```

---

# 18. 物理布局目标

优先避免：

```text
IOB
 ↓
sync
 ↓
300 MHz raw 11-bit bus
 ===== SLR crossing =====
 ↓
large recovery logic
```

长期目标：

```text
IOB region
  │
  ▼
sync
  │
  ▼
alignment
  │
  ▼
recovery
  │
  ▼
event encoder
  │
  ▼
event FIFO
 ===== SLR / clock boundary =====
  │
  ▼
150 MHz video
```

其中 raw 11-bit sampled bus 包含：

```text
DATA[7:0]
PCLK
HREF
VSYNC
```

应该尽可能在靠近 IO 的区域完成恢复，而不是长期以 300 MHz 穿越大范围 fabric。

---

# 19. 通道物理分组建议

优化原则：

- `IOB + sync` 必须强局部；
- `alignment + recovery + event producer` 优先放置在对应 IO 邻近 SLR；
- event FIFO 作为跨 SLR/跨时钟边界；
- 不强制整个 camera channel 进硬 pblock；
- 不把 150 MHz 大 FIFO/Frame Store 拉进 300 MHz Capture Island。

第一版继续采用 soft pblock；只有确认当前 P5 routed 仍存在 IOB→sync 几十 ps 级违例时，才考虑只对 sync stage 提高约束强度。

---

# 20. IOB → sync 约束原则

当前：

```tcl
set_max_delay 1.500 -datapath_only
```

具有实际意义：

> 限制第一级 IOB 到 metastability-catching stage 的物理距离，给亚稳态解析留出足够时间。

不得通过直接放宽为：

```text
1.6 ns
2.0 ns
```

来让报告变绿。

若仍失败，优先：

1. 检查 sync FF 是否真的在对应 IO clock region；
2. 限制只针对 sync stage 的位置；
3. 检查 placer 是否因过度拥塞把 sync 拉远；
4. 检查 pblock 约束是否被忽略或冲突；
5. 重新 route 比较；
6. 保持第一 metastability stage 物理优先级高于后续恢复逻辑的布局美观。

---

# 21. Recovery Core 与 Telemetry 分离

当前 `dvp_pclk_recovery` 同时承担：

- functional recovery；
- 大量 32/64-bit counters；
- min/max；
- loss snapshot；
- stable/unstable 统计；
- software-visible diagnostics。

建议拆成：

```text
dvp_pclk_recovery_core.sv
dvp_pclk_telemetry.sv
```

Core 仅保留：

```text
filtered_pclk
candidate_edge
period estimator
phase estimator
SEARCH / ACQUIRE / LOCK / HOLDOVER
lock score
sample history
pixel_ce
pixel_data
pixel_href
pixel_vsync
diag_event
```

Telemetry 负责：

```text
candidate_count
valid_count
glitch_count
missing_count
holdover_count
lock_loss_count
phase max
interval min/max
64-bit totals
snapshot
```

---

# 22. Diagnostic 事件化

Recovery Core 输出窄事件：

```text
diag_candidate
diag_valid
diag_glitch
diag_missing
diag_holdover
diag_holdover_recovered
diag_harmonic_reject
diag_lock_loss
diag_period_fault
diag_too_early
diag_too_late
diag_invalid_interval
```

能在 150 MHz 统计的尽量移到 150 MHz：

```text
pixel/byte valid totals
event totals
frame/line totals
部分 overflow/malformed 统计
```

确实必须按 capture-cycle 语义统计的事件才留在 capture 侧。

目标是减少：

```text
300 MHz wide counters
saturating add carry
wide reset
wide CE
local routing congestion
```

---

# 23. Recovery 三阶段流水

当前 PCLK 一个真实周期约有多个 300 MHz cycle，可利用其时间裕量把恢复决策拆流水。

## Stage A：Edge Snapshot

在 candidate edge 时锁存：

```text
edge_phase_now
edge_expected_phase
edge_candidate_interval
edge_raw_interval
edge_period_est
edge_candidate_period_est
edge_recovery_state
```

## Stage B：Classification

只计算：

```text
phase_error
phase_abs
phase_good
phase_early
phase_late
raw_period_good
raw_near_double
search_interval_good
harmonic
physical_edge
```

输出注册 flag。

## Stage C：Recovery FSM

FSM 仅消费已注册 flag：

```text
physical_edge_q
phase_good_q
phase_early_q
phase_late_q
raw_good_q
harmonic_q
missing_due_q
```

然后更新：

```text
recovery_state
lock_score
period_est
expected_phase
holdover
```

目标：

> 不再让 24-bit phase 算术和多级 compare 直接控制 `lock_score` 或 FSM register enable。

---

# 24. Pipeline 后必须保留真实采样相位语义

增加处理延迟不等于允许改变采样相位。

因此 Stage A 必须记录：

```text
edge_phase_now_q
```

后续重新锚定应优先使用：

```text
expected_phase_next =
    edge_phase_now_q + estimated_period
```

而不是使用已经晚一两拍的实时 `phase_now_fp`。

原则：

```text
processing latency 可以增加
sampling phase 不能漂移
```

---

# 25. Data History 深度

当前 history 深度较小，pipeline 增加后建议：

```text
DATA_HISTORY_DEPTH = 8
```

额外两级资源约：

```text
10 bits/stage/channel
× 2 stages
× 8 channels
≈ 160 FF
```

资源代价很小，换来更自由的 pipeline 对齐空间。

---

# 26. Final Tap Register

不要让动态 history mux 直接驱动 event generator。

建议：

```text
History
  │
  ▼
sample_index mux
  │
  ▼
tap_data_q
tap_href_q
tap_vsync_q
tap_ce_q
  │
  ▼
event encoder
```

接口：

```systemverilog
assign pixel_data  = tap_data_q;
assign pixel_href  = tap_href_q;
assign pixel_vsync = tap_vsync_q;
assign pixel_ce    = tap_ce_q;
```

这样 recovery module 的输出全部是寄存器边界。

---

# 27. History Payload 不复位

以下 payload 没必要使用大范围运行时 reset：

```text
data_history
href_history
vsync_history
tap_data payload
diagnostic shadow payload
```

只要 validity 控制为 0，payload 内容无功能意义。

应重点 reset：

```text
FSM state
valid flags
lock state
recovered_history/CE valid
small control state
```

目标继续减少：

```text
reset pin fanout
control set
reset routing
```

---

# 28. Fast Core 位宽优化

这一项放到第二阶段，不能与 pipeline 第一次修改同时进行。

当前部分 functional counter 使用 16 bit，但核心只关心：

```text
PERIOD_MIN ~ 8
PERIOD_MAX ~ 18
2T
late timeout
```

可以考虑改成 6~7 bit saturating counter。

例如：

```text
0...63
63 = saturated/too late
```

软件需要的长时间统计放到 Telemetry，不让 fast core 背负无必要位宽。

---

# 29. Phase/Period 位宽优化

当前 Q16.8 24 bit 对实际：

```text
8~18 cycles
```

明显宽裕。

理论上可压缩为约：

```text
Q5.8 ~ 13 bit
```

考虑裕量后可选择：

```text
Q7.8 ~ 15 bit
```

这样可缩短：

- phase subtract；
- abs；
- compare；
- IIR add/sub；
- expected phase add；
- harmonic compare。

但此优化会改变 recovery 数学表示，必须单独阶段验证。

第一轮禁止同时：

```text
pipeline + width reduction + threshold change
```

---

# 30. PCLK 优化实施顺序

## PCLK-P0：建立当前 P5 routed 基线

必须重新生成当前 main 的 routed timing。

记录：

```text
WNS
TNS
negative endpoints
endpoint pin type
start/end hierarchy
SLR pair
IOB→sync 1.5 ns constraint
PCLK recovery internal path
```

当前仓库已有 P5 synth structural proof，但后续优化必须以实际 P5 routed 结果为准。

## PCLK-P1：低风险 pipeline

实施：

1. final tap register；
2. edge snapshot；
3. classification 再增加清晰 pipeline；
4. `edge_phase_now_q` 锁存；
5. history 6→8；
6. history payload remove reset；
7. 保持原 threshold 和 recovery policy。

验收：

- 原仿真全部通过；
- byte count 不变；
- frame/line 边界不变；
- board tap=2 的物理采样语义保持；
- missing-edge/holdover 行为一致；
- routed WNS/TNS 改善。

## PCLK-P2：Telemetry 解耦

实施：

```text
dvp_pclk_recovery_core
dvp_pclk_telemetry
```

要求：

- telemetry 绝不反压 core；
- diagnostics 允许比 functional event 晚若干拍；
- 软件可见统计语义尽量保持；
- 非必要 64-bit counter 迁离 300 MHz。

验收：

- core resource 明显下降；
- core placement 更集中；
- 300 MHz reset/CE endpoint 数下降；
- capture 功能不变。

## PCLK-P3：Capture Island 物理局部化

目标：

```text
raw sample → recovery
```

尽量在 IO 邻近区域完成。

跨 SLR 优先发生在：

```text
event FIFO / 150 MHz boundary
```

而不是：

```text
raw DVP bus @300 MHz
```

只对必要模块设置 soft region；sync stage 可比 core 更严格。

## PCLK-P4：Core 位宽优化

在前面稳定后再做：

```text
16-bit fast interval → 6/7 bit saturating
24-bit phase/period → 14~15 bit internal representation
```

每个子修改独立验证。

---

# 31. Display 优化实施顺序

## DISP-P0：保持行为，建立测试

新增/完善测试：

- 640×480→360×270 scaler；
- RGB888→RGB565；
- line padding；
- RGB565 pack/unpack；
- Display slot manager；
- 4×4 Mosaic；
- overlay 前后帧边界。

## DISP-P1：新增 Display Scaler

只接一条测试支路：

```text
canonical stream
→ scaler
→ RGB565
```

先不替换生产 Frame Store。

## DISP-P2：新增 RGB565 Display Frame DMA

新 DDR layout：

```text
active: 360×270
storage: 368×270
stride: 736 B
slot stride: 256 KiB
```

第一版 4 slot/channel。

## DISP-P3：替换 Mosaic Reader

Reader 改为直接消费 360×270 framebuffer：

```text
60 black + 360 image + 60 black
```

删除 read-side resize。

## DISP-P4：切换生产路径

生产 Display 改为：

```text
Video
→ scaler
→ RGB565
→ Display DDR
→ Mosaic
```

AI Tensor 路径保持不变。

## DISP-P5：评估 4→3 slots

用真实压力数据判断：

```text
drop_count
writer fifo peak
reader underflow
AXI stall
frame age
```

没有证据时保持 4 slot。

---

# 32. 两类优化不能互相污染

Display 与 PCLK 应独立提交。

推荐 Git commit 粒度：

```text
feat(display): add 640x480 to 360x270 streaming scaler
feat(display): add rgb565 display frame packer
feat(display): add compact display frame pool
refactor(display): remove resize from mosaic reader

refactor(camera): register final recovered sample tap
refactor(camera): pipeline pclk edge classification
refactor(camera): separate pclk recovery telemetry
opt(camera): localize capture islands near DVP IO
opt(camera): reduce recovery fast-counter width
```

禁止一次提交同时：

```text
Display format change
+
PCLK recovery math change
+
DDR address remap
+
physical pblock change
```

否则板测出问题时很难定位。

---

# 33. 验证要求

## 33.1 PCLK 功能验证

至少覆盖：

```text
normal PCLK
short high glitch
short low glitch
too-early edge
too-late edge
single missing edge
holdover recovery
PCLK blanking gap
HREF restart
VSYNC/frame boundary
frame truncation
event FIFO overflow
capture disable/enable
```

必须检查：

```text
pixel byte sequence
line byte count
frame byte count
SOF/EOL
fault/resync
pixel_ce count
no duplicated/missing byte
```

## 33.2 Display 功能验证

至少覆盖：

```text
640×480 known pattern
360×270 scaled output
RGB565 round trip
padding bytes
all 16 channels
missing channel black tile
frame switch
DDR stall
reader underflow
overlay box mapping
```

---

# 34. 时序验收

最终不能只看 Bitstream 是否生成。

PCLK Capture：

```text
capture_clk WNS >= 0
capture_clk TNS = 0
IOB→sync physical budget satisfied
no new reset/CDC methodology error
```

Display：

```text
video_clk WNS >= 0
video_clk TNS = 0
no new long ready chain
no remote ready driving RAM enable
```

全系统：

```text
WNS >= 0
TNS = 0
WHS >= 0
THS = 0
```

如果 SoC/DDR 其他区域仍有违例，则必须按 hierarchy 独立报告，不能把 PCLK/Display 局部通过误写为 full-system signoff。

---

# 35. 性能/资源验收指标

## Display

重点记录：

```text
DDR write MB/s
DDR read MB/s
writer outstanding
reader outstanding
AW/W/AR/R stall
reader underflow
drop count
Display LUT/FF/BRAM
Mosaic Reader LUT/FF/BRAM
```

目标：

```text
Display DDR traffic ≈ 从 ~1.25 GB/s 降至 ~0.29 GB/s
```

## PCLK

重点记录：

```text
recovery core LUT
recovery core FF
telemetry LUT/FF
capture reset fanout
capture CE fanout
negative endpoint count
WNS/TNS
cross-SLR path count
IOB→sync delay
```

目标不是降低 300 MHz，而是：

```text
同样的 300 MHz recovery 能力
+
更少的 fast-domain logic
+
更局部的 placement
+
更短的 critical path
```

---

# 36. 最终模块建议

```text
rtl/
├── video/
│   ├── camera/
│   │   ├── dvp_input_sampler.sv
│   │   ├── dvp_pclk_recovery_core.sv
│   │   ├── dvp_pclk_telemetry.sv
│   │   ├── dvp_event_bridge.sv
│   │   ├── camera_pixel_assembler.sv
│   │   └── camera_channel.sv
│   │
│   ├── display/
│   │   ├── display_scaler.sv
│   │   ├── rgb888_to_rgb565.sv
│   │   ├── rgb565_to_rgb888.sv
│   │   ├── display_frame_packer.sv
│   │   ├── display_frame_dma.sv
│   │   ├── display_frame_manager.sv
│   │   ├── mosaic_frame_reader.sv
│   │   └── display_subsystem.sv
│   │
│   └── frame_store/
│
└── ai/
    └── tensor/
```

实际重构时不强制一次完成目录移动，优先保证行为和验证连续性。

---

# 37. 最终目标架构

```text
                                 ┌────────────────────────────┐
OV7670 DVP ─────────────────────▶│ 300 MHz Capture Island     │
                                 │                            │
                                 │ IOB / sync                 │
                                 │ PCLK recovery core         │
                                 │ registered sample tap      │
                                 │ event encoder              │
                                 └─────────────┬──────────────┘
                                               │
                                         300→150 FIFO
                                               │
                                               ▼
                                      RGB565 assembler
                                               │
                                               ▼
                                      Canonical 640×480
                                               │
                          ┌────────────────────┴──────────────────┐
                          │                                       │
                          ▼                                       ▼
                    AI Representation                       Display Representation
                    640×480 RGB INT8                       360×270 RGB565
                          │                                       │
                          ▼                                       ▼
                     Tensor Slots                          Compact Display FB
                          │                                       │
                          ▼                                       ▼
                         SoC                                Mosaic Reader
                                                                  │
                                                           RGB565→RGB888
                                                                  │
                                                                  ▼
                                                               Overlay
                                                                  │
                                                                  ▼
                                                               HDMI TX
```

---

# 38. 最终设计原则

本轮优化完成后，外围视频系统应形成三个明确边界：

### Capture Representation

```text
异步板级 DVP
→ 可靠有序视频事件
```

目标：

```text
robustness first
```

### AI Representation

```text
640×480 RGB INT8 Tensor
```

目标：

```text
preserve inference information
```

### Display Representation

```text
360×270 RGB565
```

目标：

```text
minimize bandwidth and display complexity
```

三者不再被强迫使用同一种 framebuffer representation。

这使得后续：

- Gemmini 数量变化；
- SoC 频率提升；
- Snapshot 功能；
- 新的后处理器；
- HDMI 显示结构；
- DDR 带宽优化；

都可以在清晰边界内独立演进，而不会重新侵入 DVP capture hot path。
