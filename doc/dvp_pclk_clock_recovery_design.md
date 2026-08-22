# DVP PCLK 数字时钟恢复设计文档

## 1. 目标

本模块用于提高 FPGA 侧 DVP 摄像头接收的鲁棒性。

当前系统采用 `300 MHz` 时钟对摄像头 `PCLK` 进行过采样，并在输入 IOB 侧完成采样。现有方案要求 PCLK 连续稳定若干拍后再产生一次 `pixel_ce`，能够过滤部分短毛刺，但仍存在以下问题：

- PCLK 出现较宽毛刺时，可能被误认为合法边沿；
- PCLK 偶发丢失边沿时，现有逻辑无法恢复；
- 无法利用 PCLK 的周期性判断边沿是否合理；
- 未显式维护 PCLK 的周期和相位；
- DATA 的最佳采样位置尚未与恢复后的 PCLK 相位结合；
- 缺少 `lock / loss-of-lock / glitch / missing-edge` 等状态与统计信息。

本设计目标是将当前的 PCLK 去毛刺逻辑升级为一个轻量级的 **数字 PCLK Recovery / 简化 DPLL 接收前端**。

整个视频接收逻辑仍工作在唯一的内部时钟域：

```text
clk_300m
```

摄像头 PCLK 不直接作为 FPGA 内部逻辑时钟，而只作为一个需要恢复的外部时序参考。

最终输出：

```text
pixel_ce
pixel_data
pclk_locked
```

其中 `pixel_ce` 是在 `clk_300m` 时钟域中的单周期时钟使能脉冲。

---

# 2. 总体原则

## 2.1 不生成新的物理 PCLK 时钟域

不建议：

```verilog
always @(posedge cam_pclk)
```

也不建议把存在明显毛刺的 `cam_pclk` 直接送入 MMCM/PLL 后作为主要视频逻辑时钟。

推荐结构：

```text
Camera PCLK
     │
     ▼
IOB @ 300 MHz
     │
     ▼
PCLK Filter
     │
     ▼
Period / Phase Recovery
     │
     ▼
pixel_ce
```

所有 RTL 逻辑均使用：

```text
posedge clk_300m
```

`pixel_ce` 仅作为 clock enable。

---

# 3. 当前典型参数

示例参数：

```text
clk_300m = 300 MHz
Ts       = 3.333 ns

Camera PCLK ≈ 24 MHz
Tpclk       ≈ 41.667 ns
```

对应：

```text
300 / 24 = 12.5
```

因此合法 PCLK 上升沿在 `clk_300m` 域中通常表现为：

```text
12, 13, 12, 13, 12, 13 ...
```

个采样周期的间隔。

这个“周期性”是 PCLK Recovery 的核心依据。

---

# 4. 顶层架构

建议顶层模块：

```text
dvp_robust_rx
│
├── pclk_input_sampler
│
├── pclk_deglitch
│
├── pclk_period_measure
│
├── pclk_period_estimator
│
├── pclk_phase_predictor
│
├── pclk_edge_qualifier
│
├── pclk_lock_manager
│
├── data_input_sampler
│
├── data_phase_selector
│
├── href_vsync_filter
│
└── debug_monitor
```

推荐数据流：

```text
                     cam_pclk
                         │
                         ▼
                  IOB / input FF
                         │
                         ▼
                  300 MHz sampling
                         │
                         ▼
                  digital deglitch
                         │
                         ▼
                 candidate_edge
                         │
          ┌──────────────┴──────────────┐
          │                             │
          ▼                             ▼
     interval measure              phase predictor
          │                             │
          ▼                             ▼
      period_est                  predicted_edge
          │                             │
          └──────────────┬──────────────┘
                         ▼
                  edge qualifier
                         │
             ┌───────────┼───────────┐
             │           │           │
             ▼           ▼           ▼
          valid       glitch       missing
             │                       │
             └───────────┬───────────┘
                         ▼
                   recovered edge
                         │
                         ▼
                   sample offset
                         │
                         ▼
                      pixel_ce
                         │
                         ▼
                    pixel_data
```

---

# 5. PCLK 输入采样

## 5.1 输入要求

`cam_pclk` 为异步输入。

推荐输入路径：

```text
cam_pclk pin
    │
    ▼
IOB FF @ clk_300m
    │
    ▼
sync/history registers
```

具体实现需要结合 Xilinx UltraScale+ 的 IOB/输入寄存器约束。

建议：

- 第一拍尽量放在 IOB；
- 后续逻辑进入 fabric；
- PCLK 不作为 fabric clock；
- 全部逻辑基于 `clk_300m`。

---

# 6. PCLK 去毛刺

## 6.1 第一版：双向连续稳定确认

当前只做“连续 3 拍高”时，应升级为：

```text
LOW_STABLE
    │
    │ 连续 HIGH_CONFIRM 个 1
    ▼
HIGH_STABLE
    │
    │ 连续 LOW_CONFIRM 个 0
    ▼
LOW_STABLE
```

建议初值：

```text
HIGH_CONFIRM = 3
LOW_CONFIRM  = 3
```

只有：

```text
filtered_pclk : 0 -> 1
```

时产生：

```text
candidate_edge
```

这样能避免 PCLK 高电平期间短暂掉低后再次产生假上升沿。

---

## 6.2 第二版：数字滞回 / 饱和积分器

后续可以用饱和积分器替换简单连续 3 拍逻辑：

```text
sample = 1 -> acc++
sample = 0 -> acc--
```

例如：

```text
acc range = 0 ~ 7
```

阈值：

```text
acc >= 6 -> filtered_pclk = 1
acc <= 1 -> filtered_pclk = 0
2 ~ 5    -> 保持状态
```

其行为类似数字 Schmitt Trigger。

第一版 Codex 实现可以先保留连续稳定确认，后续再升级积分器。

---

# 7. PCLK 周期测量

维护一个自由运行时间戳：

```verilog
timestamp <= timestamp + 1'b1;
```

每次得到合法候选边沿：

```text
candidate_edge
```

测量：

```text
interval = timestamp_now - timestamp_prev
```

示例：

```text
edge timestamp:
100
112
125
137
150

interval:
12
13
12
13
```

---

# 8. SEARCH 阶段的基础周期过滤

在系统尚未 LOCK 时，不应接受任意 interval。

配置合理范围：

```text
SEARCH_MIN_PERIOD
SEARCH_MAX_PERIOD
```

例如若预计 PCLK 约 24 MHz：

```text
T ≈ 12.5 clk300
```

可设置相对宽松的：

```text
SEARCH_MIN_PERIOD = 8
SEARCH_MAX_PERIOD = 18
```

实际值应做成参数，而不是硬编码。

任何：

```text
interval < SEARCH_MIN_PERIOD
```

视为明显毛刺。

任何：

```text
interval > SEARCH_MAX_PERIOD
```

可能为：

- missing edge；
- PCLK 停止；
- blanking/gating；
- 信号异常。

---

# 9. Period Estimator

不能直接：

```text
period_est = interval
```

应使用低通估计。

推荐第一版：

```text
period_est_new =
period_est_old +
(interval - period_est_old) / 8
```

即：

```text
alpha = 1/8
```

RTL 可用移位实现：

```text
period_error = interval_fp - period_est_fp;
period_est_fp <= period_est_fp + (period_error >>> 3);
```

---

# 10. 定点数格式

由于：

```text
300 MHz / 24 MHz = 12.5
```

不能只使用整数周期。

建议内部使用固定小数。

推荐：

```text
Q?.8
```

即 8 位小数。

例如：

```text
12.5 * 256 = 3200
```

定义：

```text
PERIOD_FRAC_BITS = 8
```

则：

```text
period_est_fp = interval << PERIOD_FRAC_BITS
```

所有 phase/period 计算都尽量在同一个定点格式中完成。

---

# 11. 相位预测

维护：

```text
next_edge_phase
```

其单位为定点形式的 `clk_300m cycle`。

每成功接收一个合法边沿后：

```text
next_edge_phase = current_edge_phase + period_est
```

例如：

```text
100.0
112.5
125.0
137.5
150.0
```

这样即使平均周期不是整数，也不会因为简单的 12/13 拍硬编码产生长期累计偏差。

---

# 12. Edge Qualifier

这是本设计最关键的模块之一。

普通去毛刺只判断：

```text
这个电平够不够稳定？
```

PCLK Recovery 进一步判断：

```text
这个边沿在时间上合理吗？
```

在 LOCK 状态下，定义：

```text
predicted_edge
```

以及合法时间窗：

```text
predicted_edge ± LOCK_WINDOW
```

例如：

```text
T_est ≈ 12.5
LOCK_WINDOW = 2 clk300
```

预测：

```text
112.5
```

允许边沿：

```text
约 110.5 ~ 114.5
```

实际 RTL 可以基于整数/定点比较实现。

---

# 13. 假边沿判定

示例：

```text
previous valid edge = 100
predicted edge      = 112.5
```

如果出现：

```text
edge = 104
```

即使已经通过 3 拍高电平确认，也应拒绝：

```text
104 << expected 112.5
```

处理：

```text
glitch_count++
candidate_edge ignored
```

这样可以滤掉“宽到足以通过普通去毛刺器”的串扰脉冲。

---

# 14. 有效边沿判定

例如：

```text
predicted edge = 112.5
actual edge    = 112
```

在窗口范围内：

```text
valid_edge = 1
```

然后计算：

```text
phase_error = actual_edge - predicted_edge
```

例如：

```text
phase_error = -0.5 clk300
```

该误差用于进一步校准相位和周期。

---

# 15. 简化 DPLL

推荐第一版先做：

```text
period estimator
+
predicted window
```

第二版再加入二阶 DPLL。

完整形式可以采用：

```text
phase_next =
phase +
period_est +
Kp * phase_error
```

以及：

```text
period_est_next =
period_est +
Ki * phase_error
```

推荐初始参数：

```text
Kp = 1/4
Ki = 1/32
```

RTL 可以实现为：

```text
phase_correction  = phase_error >>> 2
period_correction = phase_error >>> 5
```

这些参数必须做成可配置参数，后续通过实验调节。

---

# 16. Kp / Ki 含义

## Kp

负责快速校正相位：

```text
predicted edge
      ↓
       ---> actual edge
```

---

## Ki

负责长期校正频率。

若实际边沿持续晚于预测：

```text
phase_error > 0
```

说明：

```text
period_est 可能太小
```

Ki 会逐渐增加 period。

不要把 Kp/Ki 设置得过大，否则 DPLL 会追踪每一个输入 jitter，导致恢复输出本身变得不稳定。

---

# 17. Lock Manager

推荐状态：

```text
SEARCH
ACQUIRE
LOCK
HOLDOVER
```

状态机：

```text
              ┌─────────────┐
              │   SEARCH    │
              └──────┬──────┘
                     │
                周期基本稳定
                     ▼
              ┌─────────────┐
              │   ACQUIRE   │
              └──────┬──────┘
                     │
            连续 N 个边沿有效
                     ▼
              ┌─────────────┐
          ┌──►│    LOCK     │
          │   └──────┬──────┘
          │          │ missing
          │          ▼
          │   ┌─────────────┐
          └───│  HOLDOVER   │
 edge恢复     └──────┬──────┘
                     │ timeout
                     ▼
                   SEARCH
```

---

# 18. SEARCH 状态

功能：

- PCLK 电平去毛刺；
- 测量边沿 interval；
- 丢弃明显异常 interval；
- 建立初始 `period_est`；
- 不使用严格 predicted window。

建议：

```text
连续得到若干个合理 interval
```

后进入 ACQUIRE。

例如：

```text
SEARCH_VALID_EDGES = 8
```

---

# 19. ACQUIRE 状态

已经知道大概：

```text
period_est
```

但尚未完全锁定。

使用宽窗口：

```text
ACQUIRE_WINDOW
```

例如：

```text
±3 ~ ±4 clk300
```

连续：

```text
ACQUIRE_EDGES = 8 ~ 16
```

个边沿都落在合理范围后：

```text
pclk_locked = 1
state = LOCK
```

---

# 20. LOCK 状态

进入严格预测模式。

推荐初值：

```text
LOCK_WINDOW = ±2 clk300
```

行为：

- 过早的 candidate edge -> glitch；
- 正常窗口内 edge -> valid；
- 超过窗口仍未收到 edge -> missing edge。

---

# 21. HOLDOVER

HOLDOVER 是“自己短时间创造 pixel_ce”的唯一推荐方式。

假设：

```text
previous edge = 112
period_est    = 12.5
next predicted edge ≈ 125
```

到预测窗口结束仍未检测到合法 PCLK：

```text
missing_count++
```

若之前处于 LOCK 状态，并且：

```text
holdover_count < MAX_HOLDOVER
```

则允许在预测位置产生：

```text
predicted_pixel_ce
```

推荐第一版：

```text
MAX_HOLDOVER = 1
```

最多补一个像素周期。

不建议连续预测几十个像素。

---

# 22. HOLDOVER 恢复

例如：

```text
100   valid
112   valid
125   missing -> predicted
137   actual
```

当 137 附近真实边沿重新出现，并落入预测窗口：

```text
state -> LOCK
holdover_count -> 0
```

重新进行 phase correction。

---

# 23. 丢锁条件

以下情况应考虑丢锁：

- 连续 missing edge 数超过 `MAX_HOLDOVER`；
- phase error 连续过大；
- period 测量明显失真；
- HREF active 期间 PCLK 长时间消失；
- interval 超出合理范围过多。

处理：

```text
pclk_locked = 0
lock_loss_count++
state = SEARCH
```

---

# 24. HREF 与 PCLK Recovery

PCLK Recovery 与 HREF 必须协同。

## 情况 A：PCLK 全时运行

若摄像头在 blanking 期间 PCLK 仍持续：

```text
PCLK: continuously running
HREF: active line indicator
```

则 PCLK Recovery 可以一直 LOCK。

只在：

```text
HREF = 1
```

时允许真正输出有效视频 `pixel_ce`。

---

## 情况 B：PCLK 被 HREF gate

部分摄像头可能：

```text
HREF = 0 -> PCLK 停止
```

此时不能把 blanking 期间 PCLK 停止当作 loss-of-lock。

推荐：

```text
HREF falling:
    freeze period estimator
    不累计 missing edge
    保留 period_est

HREF rising:
    使用保留的 period_est
    暂时使用较宽 acquire window
    快速重新锁定
```

具体行为需要结合摄像头实际时序确认。

---

# 25. VSYNC 处理

VSYNC 可以用于清：

```text
pixel_count
line_count
frame-local error flags
```

但一般不应该直接清：

```text
period_est
```

因为跨帧 PCLK 频率通常不会发生变化。

保留 period_est 可以提高下一帧重新锁定速度。

---

# 26. DATA 输入采样

PCLK Recovery 最终目的不是生成漂亮时钟，而是：

```text
在正确时间采 DATA
```

因此 DATA 应与 PCLK 一起进入 `clk_300m` 域。

推荐：

```text
cam_data[7:0]
     │
     ▼
IOB FF @ 300 MHz
     │
     ▼
history pipeline
```

例如：

```text
data_d0
data_d1
data_d2
data_d3
data_d4
```

---

# 27. DATA 相位选择

恢复出的 PCLK edge 不一定就是最佳数据采样时刻。

定义：

```text
DATA_SAMPLE_OFFSET
```

例如：

```text
offset = 0 -> 0 ns
offset = 1 -> 3.33 ns
offset = 2 -> 6.67 ns
offset = 3 -> 10 ns
offset = 4 -> 13.33 ns
```

通过实验找出最稳定的 DATA 采样点。

最终：

```text
recovered_edge
     │
     ▼
phase/sample offset
     │
     ▼
pixel_ce
     │
     ▼
select data_dx
```

---

# 28. 不建议 DATA 做跨像素多数投票

不要直接对多个 sample：

```text
data_d0
data_d1
data_d2
```

逐 bit majority vote。

原因是相邻两个像素的数据本身可能不同。

若投票窗口跨过真实 DATA transition：

```text
Pixel N -> Pixel N+1
```

多数投票可能人为生成一个不存在的字节。

DATA 优先使用：

```text
稳定窗口检测 + 正确相位选择
```

而不是盲目 majority vote。

---

# 29. DATA Stable Check

可以增加：

```text
data_stable
```

例如：

```text
data_d1 == data_d2
```

时认为当前窗口内数据稳定。

可用于：

- debug；
- error counter；
- 自动寻找最佳采样相位；
- 后续 eye scan。

第一版不必因为 DATA 不稳定就直接丢像素，可以先统计。

---

# 30. Debug / Monitor

强烈建议实现以下寄存器或 ILA 信号：

```text
pclk_locked
pclk_state
period_est_fp
last_interval
phase_error
glitch_count
missing_count
holdover_count
lock_loss_count
interval_min
interval_max
phase_error_max
candidate_edge_count
valid_edge_count
```

这些统计量对于排查：

```text
杜邦线
串扰
串联电阻
PCLK 走线
GND 回流
```

非常重要。

例如可以定量比较：

```text
原始连接：
glitch_count = 1500/frame

PCLK+GND 双绞：
glitch_count = 160/frame

PCLK 源端串 33Ω：
glitch_count = 3/frame
```

---

# 31. 推荐顶层接口

示例：

```verilog
module dvp_robust_rx #(
    parameter integer CLK_FREQ_HZ        = 300_000_000,
    parameter integer PERIOD_FRAC_BITS   = 8,

    parameter integer HIGH_CONFIRM       = 3,
    parameter integer LOW_CONFIRM        = 3,

    parameter integer SEARCH_MIN_PERIOD  = 8,
    parameter integer SEARCH_MAX_PERIOD  = 18,

    parameter integer SEARCH_VALID_EDGES = 8,
    parameter integer ACQUIRE_EDGES      = 8,

    parameter integer ACQUIRE_WINDOW     = 4,
    parameter integer LOCK_WINDOW        = 2,

    parameter integer MAX_HOLDOVER       = 1,

    parameter integer PERIOD_IIR_SHIFT   = 3,
    parameter integer KP_SHIFT           = 2,
    parameter integer KI_SHIFT           = 5,

    parameter integer DATA_HISTORY_DEPTH = 5,
    parameter integer DATA_SAMPLE_SEL    = 2
)(
    input  wire        clk_300m,
    input  wire        rst_n,

    input  wire        cam_pclk,
    input  wire [7:0]  cam_data,
    input  wire        cam_href,
    input  wire        cam_vsync,

    output reg  [7:0]  pixel_data,
    output reg         pixel_ce,
    output reg         pixel_valid,

    output wire        pclk_locked,

    output wire [31:0] glitch_count,
    output wire [31:0] missing_count,
    output wire [31:0] lock_loss_count
);
```

这只是接口建议，可根据工程风格调整。

---

# 32. 推荐内部模块接口

## 32.1 `pclk_deglitch`

输入：

```text
clk_300m
rst_n
pclk_sample
```

输出：

```text
filtered_pclk
candidate_rise
candidate_fall
```

---

## 32.2 `pclk_period_measure`

输入：

```text
candidate_edge
```

输出：

```text
interval
interval_valid
```

---

## 32.3 `pclk_recovery`

输入：

```text
candidate_edge
interval
href
vsync
```

输出：

```text
recovered_edge
predicted_edge_pulse
pclk_locked
period_est
phase_error
state
```

---

## 32.4 `data_sampler`

输入：

```text
cam_data
recovered_edge
sample_select
```

输出：

```text
pixel_data
pixel_ce
```

---

# 33. 推荐实现阶段

不要一次让 Codex 写完整 DPLL。

建议分阶段实现并逐级验证。

---

## Phase 1：加强现有 PCLK 去毛刺

实现：

```text
IOB 300 MHz sampling
双向 HIGH/LOW confirm
candidate_edge
dead-time
glitch counter
```

目标：

```text
保证一个真实 PCLK 周期最多产生一个 candidate edge
```

---

## Phase 2：周期测量

实现：

```text
timestamp
interval
interval_min/max
SEARCH range filter
```

ILA 检查：

```text
正常 PCLK interval 是否主要为 12/13
```

这是非常关键的一步。

---

## Phase 3：Period Estimator

实现：

```text
fixed-point period_est
IIR alpha = 1/8
```

验证：

```text
24 MHz 时 period_est 是否稳定在约 12.5
```

---

## Phase 4：Predicted Window

实现：

```text
next_edge predictor
LOCK window
early glitch reject
```

这是第一版真正的 PCLK Recovery。

验证：

```text
人为制造额外 PCLK pulse
是否被 window reject
```

---

## Phase 5：Lock Manager

实现：

```text
SEARCH
ACQUIRE
LOCK
```

暂时不做 HOLDOVER。

验证：

```text
正常启动
PCLK 短暂扰动
重新捕获
```

---

## Phase 6：单周期 HOLDOVER

实现：

```text
missing edge detection
MAX_HOLDOVER = 1
predicted pixel_ce
```

验证：

```text
人为屏蔽一个 PCLK edge
是否仍得到一次正确预测
下一个真实边沿是否恢复 LOCK
```

---

## Phase 7：DATA phase selection

实现：

```text
DATA IOB sampling
history buffer
configurable sample select
```

测试：

```text
sample_select = 0,1,2,3,4
```

比较图像错误率。

---

## Phase 8：二阶 DPLL

最后加入：

```text
Kp phase correction
Ki period correction
```

不要在前面功能未稳定时直接加入。

---

# 34. 仿真 Testbench 要求

Codex 应提供 SystemVerilog testbench。

至少覆盖以下情况。

---

## Test 1：理想 PCLK

生成：

```text
24 MHz PCLK
```

验证：

```text
period_est -> 12.5
pclk_locked -> 1
pixel_ce 数量正确
glitch_count = 0
missing_count = 0
```

---

## Test 2：12/13 sample 抖动

模拟 24 MHz 与 300 MHz 非整数比。

确保：

```text
interval = 12/13 交替或近似分布
```

Recovery 不应误报 glitch。

---

## Test 3：单次短毛刺

在两个真实 PCLK edge 中间注入：

```text
1~2 clk300 宽脉冲
```

应被 deglitch 拒绝。

---

## Test 4：较宽毛刺

注入：

```text
足以通过 HIGH_CONFIRM 的假脉冲
```

但时间位置明显过早。

应由：

```text
predicted window
```

拒绝。

这是验证 Recovery 相比普通去毛刺真正有效的关键 testcase。

---

## Test 5：单次 missing edge

删除一个真实 PCLK pulse。

期望：

```text
missing_count++
HOLDOVER 产生一次 predicted pixel_ce
下一真实 edge 回来后重新 LOCK
```

---

## Test 6：连续 missing edge

删除多个真实 PCLK。

超过：

```text
MAX_HOLDOVER
```

后：

```text
pclk_locked = 0
state -> SEARCH
```

---

## Test 7：输入 jitter

随机移动真实 PCLK edge：

```text
±1 clk300
```

Recovery 应保持 LOCK。

---

## Test 8：频率轻微漂移

例如模拟：

```text
24.0 MHz
-> 23.9 MHz
-> 24.1 MHz
```

period_est 应缓慢跟踪。

---

## Test 9：HREF gate PCLK

若目标摄像头存在 PCLK gating：

```text
HREF = 0 时停止 PCLK
```

验证 blanking 不触发错误 loss-of-lock。

---

# 35. ILA 建议抓取信号

Vivado ILA 建议至少抓：

```text
cam_pclk_sample
filtered_pclk
candidate_edge
recovered_edge
pixel_ce

period_interval
period_est_fp

predicted_phase
phase_error

pclk_state
pclk_locked

cam_href
cam_vsync

cam_data
pixel_data

glitch_count
missing_count
```

ILA 深度应覆盖至少若干行视频，以便观察锁定和异常恢复过程。

---

# 36. FPGA 物理层仍需同步优化

本设计不能代替 Signal Integrity 优化。

仍建议：

```text
PCLK 与 GND 紧邻或双绞
缩短杜邦线
增加 GND 回流路径
PCLK 源端串联 22~47Ω，优先实验 33Ω
DATA 走线尽量一致
Camera 电源做好去耦
```

PCLK Recovery 的作用是：

```text
提高接收端容错能力
```

而不是：

```text
让完全失真的信号重新变成正确数据
```

---

# 37. 第一版最重要的功能边界

第一版实现不要求：

```text
完整通用 CDR
自动 eye training
IDELAY 自动训练
复杂二阶环路
长期自由运行 PCLK
```

第一版必须完成：

```text
1. 300 MHz PCLK oversampling
2. 双向去毛刺
3. PCLK interval measurement
4. fixed-point period estimator
5. predicted edge window
6. early glitch rejection
7. SEARCH / ACQUIRE / LOCK
8. 单周期 missing-edge holdover
9. DATA history / phase select
10. debug counters
```

---

# 38. Codex 实现要求

请 Codex 按以下原则实现：

1. 不创建新的 `cam_pclk` 逻辑时钟域；
2. 所有核心逻辑只使用 `clk_300m`；
3. 不使用 `cam_pclk` 作为 `always_ff` 时钟；
4. 所有周期/相位参数必须参数化；
5. period/phase 使用定点数；
6. 避免使用不必要的乘法器；
7. `1/2^N` 系数使用 arithmetic shift；
8. counter 必须处理 overflow；
9. state transition 必须清晰；
10. debug counter 使用饱和或足够宽位数；
11. 为每个核心模块提供注释；
12. 提供独立 testbench；
13. testbench 必须包含毛刺、丢边沿、jitter 和频率漂移；
14. 第一版优先保证功能正确，不追求过度抽象；
15. 不要把 HOLDOVER 扩展为长期自由运行 PCLK。

---

# 39. 推荐开发顺序

```text
Step 1
pclk_deglitch
    ↓
Step 2
interval_measure
    ↓
Step 3
period_estimator
    ↓
Step 4
predicted_window
    ↓
Step 5
SEARCH/ACQUIRE/LOCK
    ↓
Step 6
single-edge holdover
    ↓
Step 7
DATA phase selection
    ↓
Step 8
Kp/Ki DPLL
```

每完成一步都单独跑 testbench 和 ILA，不建议一次性写完整模块后再调。

---

# 40. 最终期望效果

正常情况下：

```text
Camera PCLK
      │
      ▼
稳定恢复 period / phase
      │
      ▼
recovered pixel timing
      │
      ▼
pixel_ce
```

PCLK 出现短毛刺：

```text
glitch
  ↓
deglitch / window reject
  ↓
不产生额外 pixel_ce
```

PCLK 出现一个漏边沿：

```text
missing edge
     ↓
short holdover
     ↓
产生一次 predicted pixel_ce
     ↓
下一个真实 edge 重新锁定
```

DATA：

```text
300 MHz history
     +
recovered phase
     +
sample offset
     ↓
pixel_data
```

最终目标是形成一个：

```text
DVP Robust Receiver
```

具备：

```text
PCLK oversampling
Glitch rejection
Period estimation
Phase prediction
Digital clock recovery
Short holdover
DATA phase selection
Lock detection
Error statistics
```

的鲁棒 DVP 摄像头接收前端。

---

# 41. 核心设计结论

本设计的本质不是：

```text
“自己重新生成一个完全独立的 PCLK”
```

而是：

```text
Camera PCLK
    ↓
作为 timing reference
    ↓
300 MHz oversampling
    ↓
filter
    ↓
period estimation
    ↓
phase prediction
    ↓
edge qualification
    ↓
short holdover
    ↓
recovered pixel_ce
```

这样既能够利用真实摄像头 PCLK 保持长期同步，又能够过滤串扰造成的额外边沿，并对偶发漏边沿提供有限恢复能力。

这比单纯增加：

```text
PCLK 连续稳定 N 拍
```

更适合作为后续可扩展、可验证、可量化的 DVP 鲁棒接收方案。
