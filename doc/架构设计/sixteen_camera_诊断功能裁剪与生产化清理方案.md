# sixteen_camera 诊断功能裁剪与生产化清理方案

> 项目：`Cc-aw/sixteen_camera`
> 目标：在现有功能已经基本完成、关键问题已经完成定位的前提下，删除大量阶段性诊断逻辑，减少 RTL 规模、CDC 数量、寄存器数量、软件复杂度和 300 MHz 热路径负担，为后续架构重构与 3×Gemmini64 性能优化建立更干净的生产基线。

---

# 1. 总体原则

当前工程中大量诊断逻辑是在以下阶段逐步加入的：

- OV7670 / PCLK bring-up；
- HREF / VSYNC 抗干扰；
- Camera CDC 调试；
- DDR writer 性能分析；
- framebuffer snapshot；
- Tensor sidecar；
- FBus coherence；
- FBus bandwidth；
- PPU reader；
- YOLOv5nu 后处理板测；
- 双 Gemmini 调度验证。

这些诊断在问题定位阶段非常有价值，但现在很多已经不再属于生产功能。

本轮原则：

```text
生产系统只保留：
1. 能判断系统当前是否正常；
2. 能定位真实运行故障；
3. 对当前性能优化仍然必要的指标。
```

其余：

```text
阶段性诊断
实验型统计
板级 bring-up 功能
压力测试
BIST
独立 benchmark
历史兼容功能
```

应从生产 RTL / firmware 中删除或移入独立 diagnostic build。

---

# 2. 分类

所有诊断划分为四类：

```text
S：立即删除
A：从 production 剥离，保留到 diagnostic/test
B：当前可删，但收益低于前两类
KEEP：当前仍需保留
```

---

# 3. S 级：立即删除 `camera_axis_diag[479:0]`

当前链路：

```text
camera_subsystem
    ↓
camera_axis_diag[479:0]
    ↓
camera_hdmi_subsystem
    ↓
top_wrapper
    ↓
ddr_memory_subsystem
    ↓
unused_status
```

最终没有生产消费者。

因此直接删除：

```text
camera_axis_diag
camera_axis_diag_cam
camera_axis_diag_ddr
axis_diag
```

以及仅用于生成该总线的：

```text
camera_cdc_fire_count
camera_cdc_sof_count
camera_cdc_eol_count
```

涉及文件：

```text
rtl/top_wrapper.sv
rtl/memory/ddr_memory_subsystem.sv
rtl/video/camera_hdmi_subsystem.sv
rtl/video/camera/camera_subsystem.sv
rtl/video/camera/ov7670_frontend.sv
rtl/video/camera/camera_axis_cdc.sv
```

风险极低，适合作为第一笔 commit。

---

# 4. S 级：删除 Camera 40×32-bit PCLK Snapshot

当前 `ov7670_frontend.sv` 中存在完整的 40×32-bit PCLK long-test snapshot。

删除：

```text
pclk_snapshot_live
pclk_snapshot_video
pclk_snapshot_axil
stats_snapshot_toggle
stats_snapshot_video_sync1
stats_snapshot_video_sync2
stats_snapshot_video_seen
stats_snapshot_ack_video
stats_snapshot_ack_axil

u_pclk_snapshot_cdc_low
u_pclk_snapshot_cdc_high
u_pclk_snapshot_ack_cdc
```

当前 snapshot 包含大量 bring-up/长时间稳定性统计：

```text
candidate_count64
valid_count64
pixel_ce_count64
candidate_period
period_estimate
lock score
recovery state
period range fault
half-period candidate
too early
too late
invalid interval
data stable
data unstable
line good
line short
line long
line min/max
short high
short low
harmonic reject
glitch
missing
holdover
holdover recovered
lock loss
phase max
interval min/max
period at loss
candidate period at loss
phase at loss
interval at loss
line count at loss
pixel count at loss
```

这些已经不适合继续保留在 production。

历史 routed report 中，单 Camera 仅：

```text
u_pclk_snapshot_cdc_low    ≈ 2048 FF
u_pclk_snapshot_cdc_high   ≈ 512 FF
```

即约：

```text
2560 FF / Camera
```

8 路复制成本很高，因此这是最值得优先裁剪的模块之一。

---

# 5. S 级：删除 Camera BIST / Pad Monitor / Probe

删除独立 100 MHz input monitor：

```text
sample_async
sample_sync_1
sample_sync_2
sample_sync_d

os_sample_count
os_pclk_edges
os_vsync_edges
os_href_edges
os_href_pclk_edges
os_vh_overlap

os_seen_high
os_seen_low
os_data_toggle
os_data_previous

os_current_line_pclks
os_last_line_pclks
os_current_frame_lines
os_last_frame_lines

os_pclk_period
os_pclk_period_min
os_pclk_period_max
os_period_valid
```

删除 Pad 回读监控：

```text
pad_async
pad_sync_1
pad_sync_2
pad_sync_d

pad_seen_high
pad_seen_low

pad_xclk_edges
pad_reset_edges
pad_pwdn_edges
pad_scl_edges
pad_sda_edges
```

删除顶层用于 pad 回读的：

```text
cam_xclk_pad
cam_reset_n_pad
cam_pwdn_pad
cam_scl_pad
```

删除 `probe_control` 及其强制：

```text
XCLK
RESET
PWDN
SCL
SDA
```

删除 production firmware 的：

```text
b = Camera BIST
```

如仍希望保留，可移动到：

```text
sw/diag/
```

---

# 6. A 级：PCLK Recovery 诊断大幅收缩

`dvp_pclk_recovery.sv` 中目前同时包含 functional state 和大量诊断 counter。

## 必须保留

参与算法或功能路径的：

```text
pclk_locked
recovery_state
period_est_fp
lock_score
recovery_confirm_count
loss_event
```

以及 recovery FSM 内部状态。

## 建议删除

```text
candidate_count
valid_count

glitch_count
missing_count

holdover_count
holdover_recovered_count

harmonic_reject_count

short_high_count
short_low_count

phase_error_max_fp

interval_min
interval_max

data_unstable_count
data_stable_count

period_range_fault_count
half_period_candidate_count

too_early_count
too_late_count
invalid_interval_count

candidate_count64
valid_count64
pixel_ce_count64

period_at_loss
candidate_period_at_loss
phase_error_at_loss
interval_at_loss
```

注意：

```text
loss_event
```

不能删除，因为当前：

```text
event_fault = pclk_loss_event
```

它属于生产恢复功能。

最终建议只暴露一个紧凑 `PCLK_STATUS`，包含：

```text
locked
state
period_estimate
lock_loss_sticky
```

必要时再保留：

```text
lock_loss_count
```

---

# 7. A 级：删除 Camera 大量 Diagnostic CDC

当前 `ov7670_frontend` 中包括：

```text
u_pclk_diag_cdc
u_href_diag_cdc
u_vsync_diag_cdc
u_cdc_diag_cdc

u_stream_diag_cdc
u_rejected_vsync_diag_cdc
u_line_flush_diag_cdc
u_href_guard_diag_cdc
u_timeout_abort_diag_cdc

u_pclk_quality_diag_cdc
u_pclk_extended_diag_cdc

u_pclk_snapshot_cdc_low
u_pclk_snapshot_cdc_high
```

凡属于：

```text
源域产生大量 counter
    ↓
巨宽 CDC
    ↓
AXI-Lite
    ↓
偶尔通过 UART 打印
```

都不适合长期存在于 production。

历史 report 中单 Camera 可见的诊断 CDC 已经达到数千 FF 量级，8 路复制后会显著增加 routing 和 fanout。

---

# 8. A 级：Camera 120-word CSR 缩减

当前：

```systemverilog
ov7670_axil_regs #(.WORDS(120))
```

每 Camera 暴露 120 个 diagnostic words。

历史 report 中：

```text
u_diagnostics ≈ 1974 LUT / Camera
```

主要用于 read decode / read mux / diagnostic word assembly。

建议最终缩到约 8~16 个寄存器，例如：

```text
0x00 ID

0x04 CONTROL
     reinit
     force reset/pwdn（如仍需要）

0x08 STATUS
     init_done
     init_failed
     capture_enable
     pclk_locked
     pclk_state
     overflow_sticky
     malformed_sticky

0x0C FRAME_COUNT

0x10 ERROR_COUNT

0x14 GEOMETRY
     last_line_bytes
     last_frame_lines

0x18 LOCK_LOSS_COUNT

0x1C SCCB_ERROR
     failed_reg
     failed_phase
```

从：

```text
120 words
```

降低到：

```text
8~16 words
```

---

# 9. A 级：HREF / VSYNC 详细统计删除

删除：

```text
raw_href_count
qualified_href_count
short_href_count
min_href_high_width
last_href_high_width

raw_vsync_edges
filtered_vsync_edges
short_vsync_count
min_vsync_high_width
```

功能逻辑必须保留：

```text
HREF filter
VSYNC filter
frame qualification
frame resync
```

生产版不需要长期统计具体过滤次数和历史脉宽。

---

# 10. A 级：HREF Line Guard 详细诊断删除

删除：

```text
href_guard_gap_last
href_guard_gap_max
href_guard_flush_position
href_guard_recovered_count
href_guard_flush_count
```

保留：

```text
dvp_href_line_guard
```

本身的恢复功能。

原则：

```text
算法继续恢复
不再统计恢复细节
```

---

# 11. A 级：`camera_axis_cdc` 诊断裁剪

当前包含：

```text
diag_fire_count
diag_sof_count
diag_eol_count

diag_fifo_full_stall_count
diag_ready_low_count
diag_fifo_max_level
diag_line_flush_count
```

建议删除：

```text
diag_fire_count
diag_sof_count
diag_eol_count
diag_ready_low_count
diag_fifo_max_level
diag_line_flush_count
```

`diag_fifo_full_stall_count` 也无需继续保留完整 counter。

真正需要判断的是：

```text
是否发生过 event overflow
```

已有：

```text
camera_event_overflow_count
```

足够承担该职责。

最终甚至可以只保留：

```text
event_overflow_sticky
```

---

# 12. A 级：`camera_axis_to_stream` 统计合并

当前存在：

```text
unexpected_sof_count
early_eol_count
missing_eol_count
aborted_frame_count
discarded_beat_count
padded_beat_count
good_frame_count
resync_frame_count
timeout_abort_count
malformed_frame_count
```

建议保留：

```text
malformed_frame_count
timeout_abort_count（可选）
```

删除：

```text
unexpected_sof_count
early_eol_count
missing_eol_count
aborted_frame_count
discarded_beat_count
padded_beat_count
good_frame_count
resync_frame_count
```

内部 recovery FSM 行为保持不变。

---

# 13. S 级：删除 framebuffer AI Snapshot 路径

当前默认 YOLOv5nu 输入已经是：

```text
accepted video
    ↓
stream tensor packer
    ↓
Tensor DMA
    ↓
Tensor Slot
```

framebuffer snapshot 已不再是生产推理入口。

建议从 production RTL 删除：

```text
ai_snapshot_req_toggle
ai_snapshot_ack_toggle

ai_release_req_toggle
ai_release_ack_toggle

ai_meta_req_toggle
ai_meta_ack_toggle

ai_snapshot_active
ai_snapshot_valid_mask
ai_snapshot_fresh_mask
ai_held_mask

ai_snapshot_addrs
ai_snapshot_frame_ids
ai_snapshot_source_frame_ids
ai_snapshot_timestamps
ai_snapshot_versions
ai_snapshot_batch_id

ai_ref
```

并删除相关：

```text
snapshot CDC
metadata CDC
release CDC
CSR
```

生产软件删除：

```text
sw/src/ai_frame_snapshot.c
sw/src/ai_frame_snapshot.h
```

production UART 删除：

```text
a = framebuffer snapshot
```

如 TinyYOLOv2 历史路径仍需要，移动至：

```text
legacy/
```

---

# 14. S 级：删除 Retired Preprocess CSR / CDC

旧 preprocess 数据面已经失效，但仍保留大量 compatibility CSR/CDC。

若不要求旧 firmware binary compatibility，则整体删除。

删除 CSR：

```text
PRE_CONTROL
PRE_STATUS
PRE_RECYCLE_MASK
PRE_PROGRESS
PRE_ACTIVE_BASE

PRE_ARENA0_BATCH
PRE_ARENA1_BATCH

PRE_ARENA_VALID
PRE_ARENA_FRESH

PRE_LAST_CYCLES
PRE_LAST_READ
PRE_LAST_WRITE

PRE_START_COUNT
PRE_COMPLETE_COUNT
PRE_ERROR_COUNT

PRE_ARENA0_BASE
PRE_ARENA1_BASE
PRE_MEMBER_STRIDE
PRE_MEMBER_BYTES
PRE_FORMAT
```

删除 CDC：

```text
preprocess_start_req_toggle
preprocess_start_ack_toggle

preprocess_recycle_req_toggle
preprocess_recycle_ack_toggle

preprocess_status_cdc
preprocess config CDC
```

---

# 15. S 级：删除 Tensor Sidecar

当前生产 Tensor 链：

```text
video stream
→ packer
→ per-channel FIFO
→ shared Tensor DMA
→ 32 Tensor Slots
```

单路 sidecar 已完成阶段性验证使命。

删除：

```text
tensor_sidecar_req_toggle
tensor_sidecar_channel
tensor_sidecar_addr

tensor_sidecar_busy
tensor_sidecar_completed
tensor_sidecar_error

tensor_sidecar_done_channel
tensor_sidecar_frame_id
tensor_sidecar_bytes
tensor_sidecar_overflows
```

删除 CSR：

```text
0x2B0 TENSOR_CONTROL
0x2B4 TENSOR_CHANNEL
0x2B8 TENSOR_ADDR
0x2BC TENSOR_STATUS
0x2C0 TENSOR_FRAME_ID
0x2C4 TENSOR_BYTES
0x2C8 TENSOR_OVERFLOWS
```

删除软件：

```text
tensor_sidecar_begin_test()
tensor_sidecar_service()
tensor_sidecar_test_active
tensor_sidecar_channel
TENSOR_SIDECAR_DIAG_PHYS_BASE
```

删除 UART：

```text
n = stream tensor capture
N = next tensor channel
```

---

# 16. A 级：PPU/FBus Diagnostic 从 Production 剥离

当前：

```text
postprocess_read_diagnostic.sv
```

不能整个删除，因为它同时承担 production reader 和 PPU。

必须保留：

```text
fbus_read_engine
head_local_reader
yolov5nu_postprocessor

production descriptor
production start/done/error
PPU result RAM
PPU status
reader selection（如果当前架构仍需要）
```

最终建议改名：

```text
postprocess_subsystem.sv
```

---

# 17. PPU/FBus Diagnostic 部分删除

从 production 删除：

```text
DIAG_ID
DIAG_CAPABILITY

DIAG_CONTROL
DIAG_STATUS

tensor_addr_q
tensor_bytes_q
burst_beats_q

result_crc
crc_state
byte_sum
nonzero_count

diagnostic completion_count
diagnostic error_count

bandwidth sweep
coherence stress
```

以及：

```text
crc32_byte()
crc32_chunk64()
chunk64_byte_sum()
chunk64_nonzero_count()
```

生产 PPU 不需要计算 CRC。

保留测试代码到：

```text
rtl/diag/
sw/diag/
```

默认 production manifest 不加入。

---

# 18. A 级：Production UART 命令大幅精简

当前：

```text
s p o d t T g u U a n N m v w W i b r c h
```

建议 production firmware 只保留：

```text
s = compact system status
i = AI enable / disable
p = inference profile
r = restart / reinit
c = clock / basic platform status
h = help
```

`m = 16-stream soak` 如果近期还用于性能验证，可暂时保留。

移出 production：

```text
o = fixed overlay test
d = TinyYOLOv2 dog test
t = YOLOv5nu correctness selftest
T = postprocess compare
g = Graph + PPU benchmark
u = PPU reader status
U = toggle PPU reader
a = framebuffer snapshot
n = Tensor sidecar
N = next sidecar channel
v = FBus coherence stress
w = bandwidth
W = burst sweep
b = Camera BIST
```

这些功能进入独立 diagnostic firmware。

---

# 19. KEEP：当前不要删除 Tensor DMA Performance

当前后续仍需优化：

```text
Tensor DMA
FBus
DDR
Gemmini
```

因此继续保留：

```text
outstanding current
outstanding max
source starvation
AW stall
W stall
W transfer
B wait
bursts issued
bursts completed
response errors
```

至少保留到：

```text
3×Gemmini64
+
目标吞吐性能
```

完成性能收敛以后再进一步裁剪。

---

# 20. KEEP：Gemmini Runtime Performance

当前保留：

```text
jobs submitted
jobs completed

scheduler cycles
RoCC cycles

Gemmini busy
load stall
exec cycles
store stall

error count
```

这些是后续 3×Gemmini64 优化的重要依据。

---

# 21. B 级：Video Writer Performance 可进一步删除

当前：

```text
writer outstanding current/max
AW stall
W stall
B stall
bursts issued
bursts completed
response errors
```

视频 framebuffer DMA 已比较成熟。

建议最终只保留：

```text
writer_response_errors
drop_count
malformed_count
```

如果近期不再优化 video writer，可删除：

```text
current outstanding
max outstanding
AW stall
W stall
B stall
bursts issued
bursts completed
```

也可临时用：

```systemverilog
`ifdef VIDEO_PERF_DIAG
...
`endif
```

控制。

---

# 22. KEEP：HDMI 保留少量诊断

HDMI 是外部输入协议，需要最低限度可观测性。

保留：

```text
capture_enable
transport_malformed_count
channel_overflow_count
```

可以删除：

```text
每通道详细 frame count
过多历史 delta
重复 transport 统计
```

如果 framebuffer writer 已有 frame count，则没必要再维护重复 HDMI frame count。

---

# 23. 最终 Production Telemetry 目标

## Camera 每路

```text
init_done
init_failed

pclk_locked
pclk_state
lock_loss_count

frame_count
malformed_count
event_overflow_count

last_line_bytes
last_frame_lines
```

## HDMI

```text
capture_enable
transport_malformed
channel_overflow[8]
```

## Video DDR

```text
written_frame_count[16]
drop_count[16]
AXI_response_error
underflow
```

## Tensor

当前阶段保留：

```text
slot_state
frame_id
version

no_slot
overflow
missed
admission_skip

DMA outstanding
DMA stall
DMA response error
```

## Gemmini

```text
job submitted/completed
cycles
load stall
store stall
error
```

## PPU

```text
busy
done
error
result_count
cycles
```

---

# 24. 删除优先级总表

| 等级 | 功能 | 处理方式 |
|---|---|---|
| S | `camera_axis_diag[479:0]` | 立即删除 |
| S | 40×32 PCLK snapshot | 立即删除 |
| S | Camera BIST | 立即删除 |
| S | Pad monitor | 立即删除 |
| S | `probe_control` | 立即删除 |
| S | framebuffer AI snapshot | 整条删除 |
| S | retired preprocess CSR/CDC | 整条删除 |
| S | Tensor sidecar | 整条删除 |
| A | PCLK extended statistics | 大幅删除 |
| A | PCLK quality CDC | 收缩为 compact status |
| A | HREF detailed diagnostics | 删除 |
| A | VSYNC detailed diagnostics | 删除 |
| A | HREF guard diagnostics | 删除 |
| A | stream recovery 8 counters | 合并 |
| A | PPU CRC diagnostic | production 剥离 |
| A | FBus coherence test | diagnostic build |
| A | FBus bandwidth sweep | diagnostic build |
| A | UART `a/n/N/v/w/W/b/o/u/U` | production 删除 |
| B | Video writer detailed perf | 可删/可编译裁剪 |
| KEEP | Tensor DMA perf | 当前保留 |
| KEEP | Gemmini perf | 当前保留 |
| KEEP | malformed / overflow / drop / error | 保留 |
| KEEP | compact PCLK health | 保留 |
| KEEP | HDMI malformed / overflow | 保留 |

---

# 25. 推荐实施顺序

## Commit 1：零功能影响清理

删除：

```text
camera_axis_diag
axis_diag
camera_cdc_fire_count
camera_cdc_sof_count
camera_cdc_eol_count
```

验收：

```text
camera simulation
video regression
synthesis
```

---

## Commit 2：Camera Diagnostic Trim

删除：

```text
40×32 snapshot
BIST
pad monitor
probe_control
PCLK extended diag
HREF/VSYNC detail
stream detail counters
```

保留：

```text
compact Camera health
malformed
overflow
lock loss
geometry
```

这是资源收益最大的一步。

---

## Commit 3：Historical AI Paths

整条删除：

```text
framebuffer AI snapshot
retired preprocess
Tensor sidecar
```

并同步删除：

```text
CSR
CDC
software
UART commands
```

---

## Commit 4：PPU Diagnostic Separation

把：

```text
postprocess_read_diagnostic
```

拆为生产：

```text
postprocess_subsystem
```

生产只保留：

```text
reader
PPU
production MMIO
```

CRC / bandwidth / coherence 转移到：

```text
diagnostic build
```

---

# 26. 与架构重构的关系

建议先裁剪诊断，再做大规模 subsystem 重构：

```text
诊断裁剪
    ↓
RTL / CDC 规模下降
    ↓
拆 subsystem
    ↓
hierarchy 清晰
    ↓
timing / resource 优化
```

特别是 Camera。

删除大量 diagnostics 后：

```text
ov7670_frontend
```

会从：

```text
采集
+ recovery
+ CSR
+ BIST
+ telemetry
+ snapshot
+ probe
```

缩减为：

```text
Camera control
+
DVP capture
+
PCLK recovery
+
minimal health
```

然后再进行 Camera 分层会容易很多。

---

# 27. 最终判断原则

如果一个计数器或诊断功能：

```text
- 不参与功能控制；
- 不用于当前性能优化；
- 不用于判断 production fault；
- 只为了历史 bring-up 或阶段性验证；
```

那么它不应该继续存在于 production RTL。

本轮裁剪完成后预期获得：

```text
RTL 行数下降
LUT 下降
FF 下降
CDC 数量下降
高扇出网络下降
routing 压力下降
CSR 数量下降
软件复杂度下降
后续重构难度下降
```

并为后续：

```text
3×Gemmini64
300 MHz SoC
480 FPS 目标
Memory hierarchy 优化
MLIR / compiler integration
```

建立更干净的生产基线。
