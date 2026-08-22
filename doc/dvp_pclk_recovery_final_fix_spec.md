# DVP PCLK Recovery 二次完善与长测前冻结规范

## 1. 文档目的

本文档用于指导 Codex 对当前 DVP PCLK Recovery 设计进行最后一轮结构性完善。

当前版本已经具备以下能力：

- 在 300 MHz 域内对 PCLK 高低电平进行连续确认；
- SEARCH 阶段只接受 8～18 拍周期；
- 约 25 拍信号判定为二次谐波，不再错误锁定到 25；
- 使用 Q16.8 相位累加器预测下一采样中心；
- 支持 12/13 拍交替周期；
- 单次缺失 PCLK 使用一次 HOLDOVER 预测采样；
- 连续第二次缺失立即失锁并重新 SEARCH；
- HREF 低期间允许 PCLK 停止，不误计 missing；
- HREF 恢复后由第一个真实 PCLK 边沿重新对齐相位；
- 默认采样 tap 改为 4，同时保留运行时切换；
- 软件已增加 lock loss、holdover、恢复成功、谐波拒绝、相位误差等诊断。

本轮目标不是继续扩大算法复杂度，而是补齐：

1. period estimator 的独立观测路径；
2. LOCK 保护机制；
3. HOLDOVER 使用边界；
4. 行级完整性检测；
5. 调试统计可靠性；
6. 每通道 DATA 采样裕量观测；
7. 长时间 soak test 所需的诊断信息。

完成本文档内容后，建议冻结 PCLK Recovery 主算法，进入长时间实机测试。

---

# 2. 当前总体架构

整个接收器仍必须只使用：

```text
clk_300m
```

作为内部真实时钟。

禁止重新引入：

```verilog
always @(posedge cam_pclk)
```

作为视频处理主逻辑。

整体结构：

```text
cam_pclk
   │
   ▼
300 MHz IOB sampling
   │
   ▼
HIGH / LOW confirm
   │
   ▼
candidate_edge
   │
   ├──────────────► raw candidate period monitor
   │
   ▼
edge qualifier / recovery
   │
   ▼
valid_edge
   │
   ▼
Q16.8 phase / period tracking
   │
   ▼
sample center
   │
   ▼
pixel_ce
```

DATA：

```text
cam_data
   │
   ▼
300 MHz IOB sampling
   │
   ▼
history taps
   │
   ▼
runtime tap select
   │
   ▼
pixel_data
```

---

# 3. P0：增加独立 Raw Candidate Period Estimator

## 3.1 问题

不能只依赖：

```text
valid_edge
```

来估计 PCLK 周期。

原因：

如果 recovery 错误锁定到错误周期，例如：

```text
真实周期 = 12.5
错误 period_est = 25
```

则 recovery 可能：

```text
接受 edge #1
拒绝 edge #2
接受 edge #3
拒绝 edge #4
```

最终 valid edge 之间仍然是 25。

此时：

```text
valid edge
```

会反过来“证明”错误 period_est 是正确的，形成闭环自证。

---

## 3.2 新增 raw candidate period

增加：

```text
candidate_period_est
```

输入来自：

```text
经过 HIGH/LOW confirm 的 candidate_edge
```

但必须发生在：

```text
predicted window qualification
```

之前。

结构：

```text
cam_pclk
   ↓
deglitch
   ↓
candidate_edge ───────────► candidate_period_est
   │
   ▼
recovery qualification
   ↓
valid_edge ───────────────► recovered_period_est
```

---

## 3.3 正常关系

正常情况：

```text
candidate_period_est ≈ recovered_period_est
```

例如：

```text
12.48 vs 12.50
```

如果出现：

```text
candidate_period_est ≈ 12.5
recovered_period_est ≈ 25
```

则明确存在：

```text
harmonic false lock
```

---

# 4. P0：Period Hard Range Guard

当前 SEARCH 已限制：

```text
8 <= interval <= 18
```

但 LOCK / ACQUIRE / DPLL 更新后的：

```text
period_est
```

也必须永久受限。

---

## 4.1 全状态 period 合法范围

增加参数：

```text
PERIOD_MIN
PERIOD_MAX
```

默认：

```text
PERIOD_MIN = 8
PERIOD_MAX = 18
```

如果确定所有摄像头 PCLK 都约 24 MHz，可进一步收紧，例如：

```text
10 ~ 15
```

但第一版建议仍保留 8～18。

---

## 4.2 period 越界处理

不要简单：

```text
period_est = clamp(period_est)
```

然后继续 LOCK。

建议：

```text
if period_next < PERIOD_MIN
or period_next > PERIOD_MAX:
    period_range_fault++
    last_loss_reason = PERIOD_RANGE
    pclk_locked = 0
    state = SEARCH
```

原因：

period 越界通常说明当前 phase/period model 已经不可信。

---

# 5. P0：完善 Harmonic Detector

当前已经能够拒绝约 25 拍周期，但建议进一步实现两种检测。

---

## 5.1 方法 A：Period Ratio Detection

判断：

```text
recovered_period_est ≈ 2 × candidate_period_est
```

条件：

```text
abs(
    recovered_period_est -
    2 * candidate_period_est
) < HARMONIC_TOLERANCE
```

持续：

```text
HARMONIC_CONFIRM_COUNT
```

次后：

```text
harmonic_detected = 1
```

建议：

```text
HARMONIC_CONFIRM_COUNT = 4~8
```

---

## 5.2 方法 B：Half-Period Rejected Edge Detection

如果当前：

```text
period_est = T
```

连续大量 candidate 出现在：

```text
T / 2
```

附近，并且被判为：

```text
too_early
```

则认为：

```text
period_est 很可能锁到了真实周期的 2 倍
```

增加：

```text
half_period_candidate_count
```

判断条件：

```text
abs(candidate_phase - T/2)
< HALF_PERIOD_WINDOW
```

连续达到阈值：

```text
harmonic_detected = 1
```

---

## 5.3 Harmonic Recovery

发生 harmonic 后：

```text
harmonic_count++
pclk_locked = 0
```

推荐：

```text
seed_period = candidate_period_est
state = ACQUIRE
```

如果 `candidate_period_est` 当前可信度不足，则：

```text
state = SEARCH
```

不要继续在错误 LOCK 状态运行。

---

# 6. P0：Lock Confidence / Hysteresis

当前不建议只使用单一：

```text
locked = 0/1
```

内部增加：

```text
lock_score
```

建议范围：

```text
0 ~ 31
```

---

## 6.1 示例评分

可以采用：

```text
valid edge:
    +1

small phase error:
    +1

normal period:
    +1

glitch:
    -1

missing:
    -4

period out of range:
    score = 0

harmonic:
    score = 0
```

所有加减必须饱和。

---

## 6.2 LOCK / LOSS 阈值

例如：

```text
LOCK_THRESHOLD = 24
LOSS_THRESHOLD = 8
```

只有：

```text
lock_score >= 24
```

才进入/保持 LOCK。

当：

```text
lock_score <= 8
```

才真正 LOSS。

这样形成迟滞，避免：

```text
LOCK
SEARCH
LOCK
SEARCH
```

快速来回震荡。

---

# 7. P0：严格限制 HOLDOVER 使用条件

当前：

```text
第一次 missing -> HOLDOVER
第二次 missing -> LOSS
```

原则正确。

但第一次 HOLDOVER 不应无条件执行。

---

## 7.1 HOLDOVER 必须满足

建议：

```text
pclk_locked == 1
AND
href_active == 1
AND
lock_score >= HOLDOVER_SCORE_MIN
AND
period_stable == 1
AND
recent_phase_error <= HOLDOVER_PHASE_LIMIT
```

才允许：

```text
predicted pixel_ce
```

---

## 7.2 不允许 HOLDOVER 的情况

以下任一情况成立：

```text
刚从 SEARCH/ACQUIRE 进入 LOCK
period_est 正在快速变化
最近连续 glitch
phase_error 很大
harmonic suspected
HREF inactive
```

则：

```text
missing -> loss/reacquire
```

而不是盲目预测像素。

---

# 8. P0：HOLDOVER 后增加 RECOVERY_CONFIRM

建议不要：

```text
HOLDOVER
↓
下一真实 edge
↓
立即完全恢复 LOCK
```

增加轻量恢复确认。

逻辑可以是独立 counter，不一定必须增加完整 FSM 状态。

---

## 8.1 推荐流程

```text
LOCK
  ↓
single missing
  ↓
HOLDOVER
  ↓
real edge returns
  ↓
RECOVERY_CONFIRM
  ↓
连续 2~4 个真实 edge 合法
  ↓
LOCK normal
```

建议：

```text
RECOVERY_CONFIRM_EDGES = 2~4
```

---

## 8.2 恢复失败

如果 recovery confirm 阶段再次出现：

```text
missing
large phase error
harmonic
period range fault
```

直接：

```text
LOSS -> SEARCH
```

---

# 9. P0：HREF Active 行完整性检查

PCLK Recovery 是否真正正确，最终必须看：

```text
一行到底收到多少 byte/pixel
```

---

## 9.1 行计数

在：

```text
HREF rising
```

清：

```text
line_sample_count = 0
```

每个有效：

```text
pixel_ce
```

增加：

```text
line_sample_count++
```

在：

```text
HREF falling
```

检查。

---

## 9.2 统计项

增加：

```text
line_good_count
line_short_count
line_long_count

line_min_samples
line_max_samples
line_last_samples
```

---

## 9.3 推荐判定

若期望：

```text
EXPECTED_LINE_SAMPLES = 1280
```

则第一版可严格：

```text
actual == expected
```

如果现实中有固定边界差异，则增加：

```text
LINE_TOLERANCE
```

例如：

```text
expected - 2 <= actual <= expected + 2
```

---

## 9.4 为什么重要

例如：

```text
glitch_count = 1000
```

不一定造成错误。

但：

```text
line_last_samples = 1144
```

明确说明：

```text
这一行已经失败
```

所以 line integrity 应成为长期健康度的核心指标。

---

# 10. P1：每通道独立 DATA Tap

默认：

```text
tap = 4
```

可以保留。

但 8 路通道必须支持：

```text
tap_ch1
tap_ch2
...
tap_ch8
```

独立配置。

原因：

不同通道的：

```text
摄像头
杜邦线
connector
FPGA pin
IOB delay
fabric routing
```

并不完全一致。

最佳 tap 很可能不同。

---

# 11. P1：DATA Stable Monitor

不建议立即做 DATA majority vote。

只增加稳定性统计。

---

## 11.1 DATA history

例如：

```text
data_d2
data_d3
data_d4
data_d5
data_d6
```

当前默认：

```text
tap = 4
```

可判断邻近 taps：

```text
data_d3 == data_d4
data_d4 == data_d5
```

---

## 11.2 统计

增加：

```text
data_stable_count
data_unstable_count
```

例如：

```text
if data_d3 == data_d4 == data_d5:
    stable++
else:
    unstable++
```

只用于诊断。

禁止直接用：

```text
bitwise majority vote
```

生成 pixel_data。

---

# 12. P1：预留 Automatic Tap Scan

当前不要求立刻自动运行，但接口应提前留好。

建议：

```text
tap_scan_start
tap_scan_active
tap_scan_done

tap_scan_frames
tap_error_count[tap]
```

测试每个 tap：

```text
tap 0
tap 1
...
tap N
```

记录：

```text
line error
malformed frame
data unstable
```

---

## 12.1 Tap 选择原则

不要只选择：

```text
错误最少的单个 tap
```

更推荐选择：

```text
连续稳定 tap 区间的中心
```

例如：

```text
tap 2 : error 5
tap 3 : error 0
tap 4 : error 0
tap 5 : error 0
tap 6 : error 8
```

推荐：

```text
tap = 4
```

即稳定眼图中心。

---

# 13. P1：失锁原因码

增加：

```text
last_loss_reason
```

建议定义：

```text
0 = NONE
1 = PERIOD_RANGE
2 = SECOND_MISSING
3 = PHASE_ERROR
4 = HARMONIC
5 = EXCESSIVE_GLITCH
6 = HREF_PROTOCOL
7 = VSYNC_PROTOCOL
8 = MANUAL_RESET
9 = RECOVERY_CONFIRM_FAIL
```

---

## 13.1 同时保存现场

发生 loss 时锁存：

```text
period_at_loss
candidate_period_at_loss
phase_error_at_loss
interval_at_loss
line_count_at_loss
pixel_count_at_loss
```

这样日志能打印：

```text
loss=27
reason=HARMONIC
period=24.98
candidate_period=12.51
phase_error=...
```

比单纯：

```text
loss=27
```

有用得多。

---

# 14. P1：Glitch 分类

当前：

```text
glitch_count
```

建议拆分为：

```text
short_high_count
short_low_count
too_early_count
too_late_count
invalid_interval_count
half_period_count
harmonic_reject_count
```

这样可以区分：

```text
物理层毛刺
```

和：

```text
算法周期误锁
```

---

# 15. P0：Debug Statistics Snapshot

当前 CPU 顺序读取硬件计数器时，可能出现：

```text
candidate = N
valid = N+1
```

这种正常的非原子读取现象。

增加：

```text
stats_snapshot_req
```

硬件收到请求后，在同一个 `clk_300m` 周期：

```text
shadow_candidate <= candidate;
shadow_valid <= valid;
shadow_glitch <= glitch;
shadow_missing <= missing;
...
```

CPU 读取：

```text
shadow registers
```

而不是直接读活动计数器。

---

# 16. P0：高频 Counter 使用 64 bit

24 MHz 事件计数：

```text
2^32 / 24 MHz ≈ 179 秒
```

即 32 位 counter 大约 3 分钟就会 wrap。

因此至少以下 counter 建议：

```text
candidate_count
valid_count
pixel_ce_count
```

使用：

```text
64 bit
```

较低频计数：

```text
lock_loss
harmonic
holdover
malformed
```

可继续 32 bit。

---

# 17. HREF Rising 后第一个 PCLK 的定义

当前：

```text
HREF 恢复后由第一个真实 PCLK 对齐相位
```

需要明确：

```text
第一个真实 edge 是否同时产生 pixel_ce
```

这个行为不能硬编码成唯一模式。

增加参数：

```text
FIRST_EDGE_IS_PIXEL
```

或者：

```text
HREF_START_OFFSET
```

建议：

```text
FIRST_EDGE_IS_PIXEL = 0/1
```

由不同摄像头时序配置决定。

---

# 18. VSYNC / Frame Boundary 状态处理

新帧开始时应该清理：

```text
line_sample_count
temporary phase violation
missing_streak
holdover_pending
recovery_confirm_count
frame-local malformed flags
```

但保留：

```text
period_est
candidate_period_est
last_good_period
long-term lock knowledge
```

原则：

```text
frame-local state -> reset
learned timing state -> preserve
```

---

# 19. HREF / VSYNC 诊断统一

建议同步增加：

```text
href_raw_edge_count
href_valid_edge_count
href_short_reject_count
href_long_fault_count

vs_raw_edge_count
vs_valid_edge_count
vs_short_reject_count
vs_period_fault_count
```

以及：

```text
lines_per_frame
lines_min
lines_max
```

形成完整三级完整性监控：

```text
PCLK
 ↓
samples / line
 ↓
lines / frame
 ↓
frames
```

---

# 20. 可选：每通道健康状态

软件可根据硬件统计生成：

```text
GOOD
DEGRADED
RECOVERING
BAD
```

例如：

```text
GOOD:
    locked
    no malformed
    low line error

DEGRADED:
    locked
    high glitch but frame still valid

RECOVERING:
    holdover/recovery confirm

BAD:
    unlocked
    malformed frame
    line size invalid
```

该功能主要放软件层实现，RTL 不必增加复杂状态。

---

# 21. 推荐最终 FSM

建议主状态：

```text
SEARCH
ACQUIRE
LOCK
HOLDOVER
```

RECOVERY_CONFIRM 可以：

- 作为独立状态；
- 或作为 LOCK 内部 substate/counter。

推荐逻辑：

```text
SEARCH
   │
   │ candidate period stable
   ▼
ACQUIRE
   │
   │ lock_score reaches threshold
   ▼
LOCK
   │
   │ one missing + eligible
   ▼
HOLDOVER
   │
   │ real edge returns
   ▼
RECOVERY_CONFIRM
   │
   │ 2~4 consecutive good edges
   ▼
LOCK
```

失败路径：

```text
harmonic
period range fault
second missing
recovery confirm fail
严重 phase error
        ↓
      SEARCH
```

---

# 22. Codex 实现顺序

不要一次全部重构。

建议：

## Step 1

实现：

```text
candidate_period_est
period hard guard
```

验证完成后再继续。

---

## Step 2

实现：

```text
harmonic ratio detector
half-period detector
harmonic recovery
```

---

## Step 3

实现：

```text
lock_score
LOCK/LOSS hysteresis
```

---

## Step 4

实现：

```text
strict HOLDOVER eligibility
RECOVERY_CONFIRM
```

---

## Step 5

实现：

```text
line integrity checker
```

---

## Step 6

实现：

```text
64-bit counters
stats snapshot
loss reason
glitch classification
```

---

## Step 7

实现：

```text
per-channel tap
data stable monitor
```

---

## Step 8

只预留：

```text
automatic tap scan
```

接口，不要求立即自动运行。

---

# 23. 必须新增的 Testbench

## Test A：正常 24 MHz

输入：

```text
candidate interval = 12/13
```

要求：

```text
LOCK
period_est ≈ 12.5
candidate_period_est ≈ 12.5
no harmonic
no loss
```

---

## Test B：强制错误初始化 period=25

这是必须加入的 regression testcase。

输入仍为：

```text
12/13/12/13...
```

人为：

```text
initial period_est = 25
```

要求新版本必须：

```text
发现 half-period candidate
或
发现 candidate_period ≈ period/2
        ↓
harmonic_detected
        ↓
退出错误 lock
        ↓
seed ≈ 12.5
        ↓
ACQUIRE
        ↓
LOCK @ 12.5
```

禁止长期：

```text
valid=50%
glitch=50%
period=25
```

---

## Test C：单次 Missing

要求：

```text
LOCK
↓
missing once
↓
eligible HOLDOVER
↓
one predicted pixel
↓
real edge returns
↓
RECOVERY_CONFIRM
↓
LOCK
```

---

## Test D：连续两次 Missing

要求：

```text
first missing -> HOLDOVER
second missing -> SEARCH
lock_loss++
reason=SECOND_MISSING
```

---

## Test E：HREF Low 时 PCLK 停止

要求：

```text
HREF=0
PCLK停止
missing不增加
lock knowledge保留
```

HREF 恢复：

```text
first real PCLK re-anchor
```

---

## Test F：Period Drift Out of Range

人为推动：

```text
period_est > PERIOD_MAX
```

要求：

```text
period_range_fault++
loss
SEARCH
```

禁止 clamp 后继续 LOCK。

---

## Test G：DATA Tap Monitor

对不同 tap 人为制造：

```text
stable / unstable
```

确认：

```text
data_stable_count
data_unstable_count
```

统计正确。

---

## Test H：Snapshot Atomicity

活动 counter 持续增长时：

```text
snapshot_req
```

确认所有 shadow register 来自同一个 snapshot 时刻。

---

# 24. 上板验收指标

完成以上修改后，建议进行：

```text
8 路同时运行
至少数小时 soak test
```

每路统计：

```text
lock_loss / hour
holdover / hour
successful_recovery / hour
harmonic_reject / hour
glitch / second
missing / second

line_short / hour
line_long / hour
malformed_frame / hour

data_unstable rate
```

---

# 25. 正常通道目标

对于稳定通道：

```text
lock_loss ~= 0
malformed ~= 0
line_short ~= 0
line_long ~= 0
```

允许存在少量：

```text
glitch
missing
```

只要最终：

```text
line/frame integrity
```

保持正确。

不要把：

```text
glitch_count 必须为 0
```

作为最终目标。

真正目标是：

```text
物理层存在有限噪声
但最终视频数据保持正确
```

---

# 26. 异常通道诊断顺序

如果某通道异常：

```text
1. 查看 candidate_period
2. 查看 recovered_period
3. 查看 harmonic
4. 查看 lock loss reason
5. 查看 line_last/min/max
6. 查看 data stable
7. 查看 HREF/VSYNC filter
```

判断：

### 情况 A

```text
candidate_period 正常
recovered_period 异常
```

优先查：

```text
recovery algorithm
harmonic
phase tracking
```

### 情况 B

```text
candidate_period 本身严重不稳定
```

优先查：

```text
PCLK 物理连接
杜邦线
GND
串扰
Camera 输出
```

### 情况 C

```text
PCLK recovery 正常
line length 正常
DATA unstable 很高
```

优先查：

```text
D[7:0] signal integrity
DATA tap
```

---

# 27. 本轮之后不建议继续增加的功能

完成以上内容后，暂时不要继续加入：

```text
复杂通用 CDR
长期自由运行 PCLK
多次连续 HOLDOVER
复杂自适应 PLL
DATA majority vote
自动 IDELAY training
复杂统计机器学习
```

这些都应该等长测结果表明“确实有需要”以后再做。

---

# 28. 最终冻结目标

本轮完成后，PCLK Recovery 应具备：

```text
✓ 300 MHz oversampling
✓ HIGH/LOW deglitch
✓ SEARCH period range
✓ Q16.8 phase prediction
✓ 12/13 period support
✓ candidate period monitor
✓ recovered period monitor
✓ hard period guard
✓ harmonic detection/rejection
✓ single HOLDOVER
✓ strict HOLDOVER eligibility
✓ second-missing loss
✓ recovery confirmation
✓ HREF gating awareness
✓ HREF re-anchor
✓ line integrity checker
✓ per-channel runtime tap
✓ DATA stability monitor
✓ loss reason
✓ glitch classification
✓ atomic statistics snapshot
✓ 64-bit high-rate counters
```

完成后进入：

```text
长期 soak test
+
真实线束/串扰实验
+
每通道统计分析
```

而不是继续扩大 recovery 算法。

---

# 29. 给 Codex 的核心原则

请严格遵守：

1. 不创建新的 `cam_pclk` 时钟域；
2. 所有核心逻辑基于 `clk_300m`；
3. candidate period 与 recovered period 必须分开；
4. period estimator 不能靠 valid edge 自我证明；
5. period 越界必须丢锁，不允许静默 clamp；
6. HOLDOVER 最多一个周期；
7. HOLDOVER 必须有资格条件；
8. HOLDOVER 后需要恢复确认；
9. harmonic 必须能够识别 `period ≈ 2 × raw candidate period`；
10. line integrity 是最终正确性的关键指标；
11. DATA stable 只做诊断，不做 majority vote；
12. 所有高频统计使用 64-bit 或可靠 wrap 方案；
13. 软件读取统计应使用 snapshot；
14. 所有新增功能必须配套 testbench；
15. 不要一次性重写整个模块，按 Step 1～Step 8 小步修改并回归。

---

# 30. 预期结果

完成本轮后，系统应能够明确区分：

```text
真实 PCLK 毛刺
真实 PCLK missing
二次谐波误锁
period estimator 漂移
HREF gating
DATA 采样相位问题
行长度错误
帧级 malformed
```

并通过：

```text
candidate period
recovered period
lock score
loss reason
harmonic count
line integrity
data stable
```

给出可量化的诊断。

最终目标不是让所有物理输入完全无噪声，而是：

```text
即使存在有限串扰和偶发边沿错误，
最终 pixel / line / frame 仍然稳定正确。
```
