# PCLK 架构与当前时序违例分析

## 1. 分析基线

- 分析日期：2026-09-05（Asia/Shanghai）。
- 器件：`xcvu13p-fhga2104-2-i`，Vivado 2023.2。
- 当前实现结果：`prj/sixteen_camera.runs/impl_1/top_wrapper_routed.dcp`，生成时间 2026-09-05 16:20:46。
- 当前比特流：`prj/sixteen_camera.runs/impl_1/top_wrapper.bit`，生成时间 2026-09-05 16:21:53。
- 原始时序报告：`prj/sixteen_camera.runs/impl_1/top_wrapper_timing_summary_routed.rpt`，生成时间 2026-09-05 16:20:03。
- 本文另外从上述 routed checkpoint 重新执行了 `check_timing -verbose`、`report_methodology`、`report_exceptions -coverage`，并枚举了全部负 setup 路径。结果与实现报告一致。
- 仓库根目录下 `prj/timing_summary.rpt` 的日期为 2026-09-04，属于上一次实现，不能代表本文所说的“当前时序”。

当前 RTL 实际实例化的是 **8 路 OV7670 DVP 前端**（`g_camera_frontend[0:7]`）。项目名称和后续目标虽为 16 路，本文只描述当前 routed netlist 中真实存在的 8 路结构。

## 2. 结论摘要

1. 当前实现 **没有时序收敛**：`WNS=-1.291 ns`、`TNS=-6258.903 ns`，共有 20,800 个 setup 失败端点。
2. 20,800 个 setup 失败端点全部属于 `mmcm_clkout0 -> mmcm_clkout0`，即 DDR UI 的 300.120 MHz 同步域；其他时钟域和跨时钟路径没有负裕量。
3. Hold 和 pulse-width 已通过：`WHS=+0.003 ns`、`THS=0`，`WPWS=+0.039 ns`、`TPWS=0`。
4. `cam_pclk_1` 至 `cam_pclk_8` 不是当前采集逻辑的 fabric clock。PCLK、D[7:0]、HREF、VSYNC 都被当作异步数据，由 300 MHz 时钟过采样；PCLK 恢复模块只产生 `pixel_ce`，不产生新时钟。
5. 因此不能把当前失败简单称为“PCLK 时序违例”。摄像头前端和 `camera_axis_cdc` 确实占了部分失败端点，但这些端点仍是 300 MHz 内部同步路径，主要问题是控制集高扇出、跨 SLR 往返和布线拥塞。
6. 最差路径的数据延迟为 4.153 ns，其中逻辑仅 0.248 ns，布线为 3.905 ns（94.0%）。它跨越 `SLR1 -> SLR2 -> SLR1`，说明首要矛盾是物理布局/布线，而不是组合逻辑级数。

## 3. 当前 PCLK 相关架构

### 3.1 时钟与数据流

```text
100 MHz 板级参考时钟
        |
        +--> clk_wiz_ov7670 --> 24 MHz SCCB 控制时钟
                                  |
                                  +--> 每路控制器本地分频 --> 12 MHz cam_xclk

OV7670 每路 DVP：PCLK + D[7:0] + HREF + VSYNC
        |
        +--> 顶层 IBUF
        |
        +--> 300.120 MHz IOB 第一级采样（无复位）
        |
        +--> 300.120 MHz metastability-catching 对齐级
        |
        +--> 300.120 MHz 普通跨 SLR 管线级
        |
        +--> dvp_pclk_recovery
              PCLK 边沿消抖、周期/相位估计、SEARCH/ACQUIRE/LOCK/HOLDOVER
              输出 pixel_ce + 对齐后的 data/href/vsync
        |
        +--> HREF/VSYNC 过滤、RGB565 双字节拼接、RGB888
        |
        +--> camera_axis_cdc（当前写、读两侧实际都是同一个 300.120 MHz）
        |
        +--> camera_axis_to_stream --> DDR writer --> DDR --> frame reader --> HDMI
```

### 3.2 PCLK 不是内部时钟

- 顶层对每路 `cam_pclk` 使用独立 `IBUF`，再传入摄像头子系统，见 `rtl/top_wrapper.sv:78`、`rtl/top_wrapper.sv:97` 和 `rtl/top_wrapper.sv:214`。
- `video_clk` 直接等于 MIG 的 `ddr_ui_clk`，见 `rtl/memory/ddr_memory_subsystem.sv:37-53`。实现报告给出的该时钟为 `mmcm_clkout0`，周期 3.332 ns、频率 300.120 MHz。
- 前端明确在 300 MHz 下同时采样 PCLK、数据、HREF 和 VSYNC，见 `rtl/video/camera/ov7670_frontend.sv:729-757`、`1466-1496`。
- `dvp_pclk_recovery` 的 `clk_300m` 连接 `video_clk`；恢复结果是 `pixel_ce`，见 `rtl/video/camera/ov7670_frontend.sv:1518-1577`。后续逻辑把它作为 clock enable 使用，而不是把它接到寄存器时钟脚。
- nominal PCLK 为 24 MHz，对应 41.667 ns；300.120 MHz 每个 PCLK 周期约采样 12.5 次，每个半周期约 6.25 次。当前恢复参数包括两次高/低电平确认、8 周期 dead time、8～18 周期搜索窗口、最多一次 holdover 和深度 6 的数据历史。
- 该方案避免了 8 个低质量/非专用 PCLK 直接进入全局时钟树，但它仍然是异步过采样：第一级存在亚稳态概率，可靠性依赖 IOB 采样级、对齐级、恢复算法以及数据相对于 PCLK 的稳定窗口。

### 3.3 SLR 管线意图

`xdc/clk.xdc:135-162` 使用 soft pblock 引导：

- CH1～CH4：IOB(SLR3) -> sync(SLR3) -> pipe(SLR2) -> recovery(SLR1)。
- CH5～CH8：IOB(SLR2) -> sync(SLR2) -> pipe(SLR1) -> recovery(SLR1)。

这些约束只引导 `sync` 和 `pipe` 寄存器，且 `IS_SOFT=true`，不会硬性固定完整前端、FIFO、DDR writer/reader 的位置。

### 3.4 `camera_axis_cdc` 的当前角色

在 `rtl/video/camera/camera_subsystem.sv:138-159` 中，`camera_axis_cdc.camera_clk` 与 `ddr_clk` 都连接 `capture_clk`。因此当前实例中的 XPM async FIFO并不承担真实的异步时钟跨越，而主要承担：

- RGB888 两像素拼成 48 bit；
- SOF/EOL 携带；
- 深度 16,384 的弹性缓存；
- 前端无法停顿时的溢出隔离与诊断。

保留 async FIFO 会引入较复杂的 reset-busy、指针同步、RAM enable/control 逻辑。当前最差的一批路径正好终止在这个 FIFO 的 RAM `REGCEB/ENBWREN` 脚，因此它是 300 MHz 收敛的重要优化对象。

## 4. PCLK 相关约束现状

### 4.1 外部 DVP 约束

有效物理 XDC 在 `xdc/vu13p_ov7670_8ch_fmc1_fmc2_j2_cam3_legacy_v3.xdc:215-254` 中完成：

- DVP 输入设置 `IBUF_LOW_PWR=FALSE`；
- 对 8 路 PCLK 分别创建 24 MHz 时钟 `cam_pclk_1..8`；
- D[7:0]、HREF、VSYNC 相对于 PCLK falling edge 设置 `set_input_delay -min -2 ns / -max +8 ns`。

不过功能采样寄存器的真实时钟是 300 MHz，而不是这些 24 MHz PCLK。`xdc/clk.xdc:84-92` 又将 pad 到第一级 IOB 的 DVP 路径全部设为 false path，所以实现报告把 `cam_pclk_1..8 -> mmcm_clkout0` 列入 User Ignored Paths。结论是：

- 24 MHz `create_clock/set_input_delay` 描述了外部接口时序意图；
- 它没有对当前“300 MHz 异步过采样”的 pad-to-IOB 捕获给出常规 setup/hold sign-off；
- 当前报告里不存在 `cam_pclk_*` 域的负裕量，也不能据此断言外部 DVP 接口已经由 STA 完整验证。

### 4.2 1.5 ns 约束重叠风险

`xdc/clk.xdc:98-108` 对 IOB 到第二级 sync 设置了 1.5 ns datapath-only max delay，但 `xdc/clk.xdc:114-133` 又对相同 sync 端点设置 false path，并显式覆盖 IOB 的 C/Q launch pin。

本次 `report_exceptions -coverage` 显示：

- 1.5 ns max-delay 命中 88/88 个端点；
- 后续 false-path 同样命中这些 88 个端点。

这属于重叠例外。由于 false path 的优先级高于普通 max delay，1.5 ns 物理预算很可能不会作为最终 sign-off 检查发挥预期作用。后续应把“亚稳态捕获路径不做同步 setup 检查”和“限制 IOB 到 sync 的物理距离”拆成不互相覆盖的实现约束，并用点对点 `report_timing`/`report_exceptions -ignored` 验证。

## 5. 当前全部真实时序违例

### 5.1 总体结果

| 检查 | 最差裕量 | 总负裕量 | 失败端点 | 结论 |
|---|---:|---:|---:|---|
| Setup | -1.291 ns | -6258.903 ns | 20,800 / 521,255 | 失败 |
| Hold | +0.003 ns | 0 ns | 0 / 520,087 | 通过 |
| Pulse width | +0.039 ns | 0 ns | 0 / 241,814 | 通过 |

全部 20,800 个失败端点都在：

```text
From clock: mmcm_clkout0 (300.120 MHz)
To clock:   mmcm_clkout0 (300.120 MHz)
Requirement: 3.332 ns
```

其他 intra-clock 域均无负裕量，报告中存在的 inter-clock 路径也均为正裕量。因而当前不存在 hold、pulse-width 或其他 clock pair 的实际负裕量遗漏。

### 5.2 按目的层级分类

下表由 routed checkpoint 枚举全部 `slack < 0` 的 max-delay 路径后，按 endpoint 层级分类。类别互斥，合计正好 20,800 个；分项 TNS 与 Vivado 总 TNS 的极小差异来自三位小数导出后的舍入。

| 目的层级 | 失败端点 | 分项 TNS(ns) | 该类 WNS(ns) | 含义 |
|---|---:|---:|---:|---|
| DDR frame reader | 6,668 | -2384.582 | -0.923 | DDR 读出/显示侧数据与控制 |
| PCLK recovery / frontend | 3,826 | -856.408 | -0.926 | 8 路过采样、恢复、过滤和诊断逻辑 |
| camera stream | 2,927 | -1229.692 | -1.158 | 摄像头 AXIS 到内部 stream 转换 |
| MIG / DDR IP | 1,998 | -388.409 | -0.862 | MIG 用户逻辑和基础设施 |
| frame manager | 1,811 | -255.902 | -0.617 | 帧地址/状态管理 |
| DDR video writer | 1,662 | -570.344 | -1.069 | 多路视频写 DDR |
| camera_axis_cdc | 1,153 | -445.285 | **-1.291** | 两像素打包及 XPM FIFO 控制/RAM enable |
| HDMI RX | 361 | -48.524 | -0.493 | HDMI 接收路径 |
| batch preprocess | 343 | -74.412 | -0.609 | 预处理读写路径 |
| 其他 | 51 | -5.379 | -0.400 | 其余少量端点 |
| **合计** | **20,800** | **约 -6258.94** | **-1.291** | 仅 300 MHz 域 |

注意：“PCLK recovery / frontend”表示 endpoint 位于 PCLK 处理模块内，不表示这些路径由 PCLK 时钟驱动；它们仍全部由 `mmcm_clkout0` 驱动。

### 5.3 裕量分布

| Slack 区间 | 路径数 |
|---|---:|
| `<= -1.000 ns` | 186 |
| `(-1.000, -0.750] ns` | 1,049 |
| `(-0.750, -0.500] ns` | 2,935 |
| `(-0.500, -0.250] ns` | 5,917 |
| `(-0.250, 0) ns` | 10,713 |
| **合计** | **20,800** |

186 条 `<= -1 ns` 路径也对应当前 `report_methodology` 中的 186 个 `TIMING-16 Large setup violation`。

### 5.4 endpoint 类型和控制路径特征

失败 endpoint 不是以普通 payload `D` 脚为主，而是明显集中在复位/使能/存储器控制脚：

| endpoint pin | 数量 |
|---|---:|
| `CE` | 12,409 |
| `R` | 4,427 |
| `D` | 1,568 |
| `WE` | 654 |
| `I` | 510 |
| `ENBWREN` | 307 |
| `REGCEB` | 242 |
| 其他 RAM 地址/写控制等 | 683 |

合并统计约有 12,958 个 enable 类端点，以及约 4,557 个 reset/set 类端点。约 84% 的失败端点属于这两类，说明大面积 TNS 的主要来源是 300 MHz 控制集，而不是 RGB 数据组合逻辑本身。

从 startpoint 分析，8 路 `capture_resetn_local_sync_reg[1]` 合计关联 6,354 条失败路径；`ddr_reset_sync` 关联 1,139 条。虽然 RTL 已对每路 reset 做了两级本地复制，但其释放值继续进入大量同步 reset、CE、FIFO busy/enable 和诊断计数器条件，仍形成跨层级高扇出控制锥。

### 5.5 最差路径

当前最差路径为：

```text
startpoint:
  u_ddr_memory/u_video_framebuffer/u_writer/g_channels[2].u_fifo/
  pack_count_reg[1]

endpoint:
  u_camera_hdmi/u_camera_subsystem/g_camera_frontend[2].u_camera_cdc/u_fifo/
  .../RAMB36E2/REGCEB

clock:       mmcm_clkout0 -> mmcm_clkout0
requirement: 3.332 ns
slack:       -1.291 ns
data delay:  4.153 ns
logic:       0.248 ns (5.971%，3 levels)
route:       3.905 ns (94.029%)
physical:    SLR1 -> SLR2 -> SLR1
```

最差前 10 条中，9 条由 channel 2 writer FIFO 的 `pack_count_reg[1]` 相关控制锥到 channel 2 camera FIFO RAM `REGCEB/ENBWREN`，另一条是 channel 5 的相同类型；其布线占比约 94%～96%。综合优化后的网名跨越 writer、stream 和 camera FIFO 层级，不应仅根据起终点名字推断存在设计上的直接业务依赖，但可以确定这些是 XPM RAM 控制使能的跨 SLR 长布线路径。

## 6. 约束覆盖与方法学告警

以下项目不是负 slack 本身，但会影响“时序已经完整签核”的可信度，必须与真实时序违例一起跟踪。

### 6.1 `check_timing`

| 项目 | 数量 | 说明 |
|---|---:|---|
| 无 clock 的寄存器 | 0 | 完整 |
| constant clock | 0 | 完整 |
| unconstrained max-delay endpoint | 0 | 完整 |
| 因 constant clock 未约束的内部 pin | 58 | 全部位于 HDMI VPHY clock detector 的 DRU 相关逻辑 |
| 无 input delay 的输入端口 | 22 | SCCB/I2C inout、HDMI 控制、reset、UART 等；DVP data/href/vsync 不在其中 |
| 无 output delay 的输出端口 | 57 | 摄像头控制/XCLK、SCCB、HDMI 控制、UART、DDR reset/status 等 |
| multiple clock | 0 | 完整 |
| generated clock 异常 | 0 | 完整 |
| 组合/锁存环路 | 0 | 完整 |
| partial input/output delay | 0 | 完整 |

22 个无 input delay 和 57 个无 output delay 主要是异步控制、双向开漏总线或板级状态端口，不能机械地全部添加普通同步 I/O delay；应逐类决定 `set_false_path`、虚拟时钟 I/O delay 或协议专用约束。

### 6.2 当前 `report_methodology`

本次从当前 routed checkpoint 重新运行后共有 443 条：

| 规则 | 数量 | 与本任务的关系 |
|---|---:|---|
| `TIMING-16` large setup violation | 186 | 当前最严重的 `<= -1 ns` setup 路径，必须修复 |
| `TIMING-18` missing I/O delay | 158 | I/O 覆盖缺口，需要按接口语义分类处理 |
| `LUTAR-1` LUT drives async reset | 30 | 其中 8 条直接属于 8 路 PCLK recovery 到 `camera_axis_cdc` 的 `input_run_q/packer_run_q` 异步清零，存在毛刺复位风险 |
| `TIMING-10` synchronizer 缺少 `ASYNC_REG` | 1 | 需用 `report_cdc` 定位并确认 |
| `TIMING-28` 约束引用自动生成时钟名 | 1 | `clk_out1_clk_wiz_ov7670`，应改为通过输出 pin 取得时钟对象 |
| `SYNTH-16` RAM address collision | 42 | 主要为存储结构语义告警，需结合 IP/RTL 确认 |
| `SYNTH-10` wide multiplier | 10 | 均在 Rocket divider，不是 PCLK 问题 |
| `HPDR-1` inout direction | 2 | `si5338_scl1/2` |
| `XDCB-5` 查询效率 | 7 | 仅影响 XDC 运行效率 |
| `CLKC-*` advisory | 6 | MMCM/BUFG_GT 建议项，不是当前负裕量 |

PCLK 相关的 8 个 `LUTAR-1` 很重要：`capture_resetn = video_resetn && capture_enable_sync2` 最终参与 `camera_axis_cdc` 中异步 reset 条件，综合后形成多输入 LUT 驱动 `input_run_q/packer_run_q` 的 CLR。即使该路径被时序豁免，LUT 毛刺仍可能造成意外清零。这是功能可靠性问题，不只是 STA 报告整洁问题。

## 7. 根因判断

按证据强弱排序：

1. **300 MHz 域负载过大且控制集过宽。** 该时钟驱动约 123,972 fanout；全部负裕量都在此域，且约 84% endpoint 是 enable/reset 类 pin。
2. **跨 SLR 布线主导。** 最差路径只有 3 级 LUT，但 route 占 94%，并发生 SLR1/SLR2 往返。
3. **相同时钟两侧仍使用大深度 async FIFO。** 8 个深度 16K 的 `camera_axis_cdc` 带来 XPM RAM 控制和 reset-busy 网络，最差路径直接落到其 RAM enable。
4. **复位被用作大量 300 MHz 数据/控制寄存器的同步控制条件。** per-channel reset 已本地同步，但继续扇出到前端、stream、FIFO 和诊断，形成大面积 CE/R 路径。
5. **诊断逻辑规模加重拥塞。** PCLK recovery 有大量 32/64 bit 计数器和快照状态；它不一定制造 WNS，但扩大了 300 MHz 域的寄存器、reset 和 enable 负载。
6. **PCLK 约束模型没有完整 sign-off 异步过采样接口。** 这不是当前 20,800 个负裕量的来源，但属于独立可靠性风险。

## 8. 建议的优化顺序

1. 先处理 `camera_axis_cdc`：当前同钟情况下改用 synchronous FIFO，或至少使用相同时钟模式下更简单的 BRAM FIFO/寄存切片，消除不必要的 pointer CDC、reset-busy 和复杂 RAM enable。
2. 从 300 MHz payload/计数器寄存器中移除大范围同步 reset；用局部 `valid/run` 状态屏蔽无效数据，只复位真正需要确定上电状态的控制寄存器。
3. 修复 8 路 `LUTAR-1`：不要让组合出来的 reset 条件直接驱动异步 CLR。采用异步置位/同步释放的单一原始 reset，功能 enable 只进入同步状态机或 CE。
4. 对 reset、run、FIFO enable、诊断 clear 等高扇出信号做分层本地复制，并在消费者附近增加寄存边界；逐类比较 TNS，而不是只盯 WNS。
5. 对 writer、camera FIFO 和 stream 做 SLR 物理分区，避免同一控制锥 `SLR1 -> SLR2 -> SLR1` 往返；当前 soft PCLK pblock 不足以约束完整 300 MHz 数据流。
6. 把非实时诊断统计移到较低频域，或在 300 MHz 域只保留窄事件脉冲/Gray counter，再跨域汇总。
7. 清理 DVP 例外重叠，明确 1.5 ns 物理预算是否有效；补跑 `report_cdc`，定位 `TIMING-10`。
8. 每次修改后从 routed checkpoint 导出全部负路径并按本文章节 5.2 同样分类。收敛标准应为：`WNS >= 0`、`TNS = 0`、`WHS >= 0`、`THS = 0`，同时清除 PCLK 相关 `LUTAR-1` 和关键约束覆盖缺口。

## 9. 当前状态判定

当前 bitstream 可以生成，也可能在实验室条件下正常工作，但这不等于完成时序签核。以当前报告为准，300.120 MHz 域仍有 20,800 个 setup 失败端点，在工艺、电压、温度变化下不能保证稳定。

下一阶段应先保持当前非 Gemmini SoC 不变，优先缩小 300 MHz 控制集与跨 SLR 拥塞；PCLK 外部接口约束和异步复位毛刺问题并行清理。只有基础视频系统达到零负裕量后，再重新加入 Gemmini，才能区分基础架构问题与新增计算资源带来的拥塞。
