# PCLK/视频时序重构工程清单

更新日期：2026-09-05（Asia/Shanghai）  
目标器件：`xcvu13p-fhga2104-2-i`  
工具：Vivado 2023.2  
基线提交：`c128c3ebec1fc8872eee8a0519add5c8e79ad53a`（`恢复到无gemmini状态`）

本文记录 P0 对真实工程的核验结果。工程沿用既有 `doc/` 目录，因此没有另建 `docs/`。

## 构建与源文件

- 可复现入口：`/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source prj/build_bitstream.tcl`。
- `prj/build_bitstream.tcl` 会重置 `synth_1`/`impl_1`，关闭增量综合，以 8 jobs 运行到 `write_bitstream`；因此本轮基线不是旧 run 的继续运行。
- `prj/setup_vivado.tcl` 选择 `chipyard.fpga.vcu118.SmallRocketVideoDDR256MyBoardConfig.top.v`，移除旧 SoC 源，并递归加入手写 RTL。
- top 为 `top_wrapper`。工程清单导出到 `reports/video_timing_refactor/P0/project_inventory/`；共 333 个 compile-order source、14 个顶层 XCI/BD IP。
- 活动约束按序为 `xdc/clk.xdc`、`xdc/ddr.xdc`、`xdc/hdmi_tx.xdc`、`xdc/mipi.xdc`、`xdc/camera_sccb.xdc`、`xdc/vu13p_ov7670_8ch_fmc1_fmc2_j2_cam3_legacy_v3.xdc`，全部同时用于综合和实现。

## 时钟与复位

| 域 | 真实来源 | 当前频率/周期 | 当前用途 | 复位 |
|---|---|---:|---|---|
| board | `clk_25m` 端口 | 25 MHz / 40 ns | 板级控制 | `sys_rstn` |
| SoC | MIG `addn_ui_clkout1` | 100 MHz | Rocket、AXI-Lite/控制 | SoC 自有复位与同步器 |
| DDR UI / capture / video | MIG `c0_ddr4_ui_clk` | 约 300.12 MHz | MIG AXI、PCLK 过采样、摄像头后处理、frame manager、writer/reader/preprocess | `peripheral_aresetn && init_calib_complete` 异步断言、3 级同步释放 |
| OV7670 control | `clk_wiz_ov7670` | 24 MHz | SCCB 和 XCLK 相关控制 | `sys_rstn` |
| HDMI RX/TX | VPHY/HDMI IP | 运行时生成 | HDMI 接收、发送 | IP 定义的复位/锁定流程 |
| JTAG | BSCANE2 `INTERNAL_TCK` | 约束为 15 MHz | Rocket 调试 | 调试模块协议 |

P0 关键事实：当前没有独立 150 MHz video backbone；`ddr_memory_subsystem.video_clk` 直接等于 `ddr_ui_clk`。`camera_axis_cdc` 的 `camera_clk` 和 `ddr_clk` 在 8 个实例上也都接这一个 capture/UI 时钟，因此 XPM async FIFO 当前是同钟使用。

## DVP/视频链路

1. 8 路 OV7670 的 PCLK/HREF/VSYNC/DATA 先进入 IOB 寄存器，再由约 300 MHz 时钟过采样、同步和恢复。
2. `ov7670_frontend` 完成 PCLK 恢复、HREF/VSYNC 过滤、字节拼接、RGB565 到 RGB888，并输出逐像素事件。
3. `camera_axis_cdc` 把两像素打包为 48-bit AXIS；当前使用深度 16384、宽度 50 的 XPM async FIFO，即便两端同钟。
4. `camera_axis_to_stream` 规范化 SOF/EOL/EOF，异常帧进入 abort/补黑恢复路径。
5. 另有 8 路 HDMI demux capture；两类输入在 `ddr_memory_subsystem` 合并为 16 路，不能把“8 路 OV7670”误写成系统只有 8 个 DDR capture client。
6. `channel_write_fifo` 把 4 个 48-bit beat 整理为 1 个 256-bit XRGB8888 beat；writer、reader、frame manager 和 batch preprocess 当前都在 DDR UI 时钟域。

## MIG 与 DDR 客户端

- IP：`xilinx.com:ip:ddr4:2.2`，存储器 `MT40A512M16LY-075`。
- 物理接口 64-bit，`TimePeriod=833 ps`（DDR4-2400）；MIG AXI 数据宽度 512-bit、地址 32-bit、ID 4-bit。
- S00：256-bit、ID4、100 MHz，Rocket SoC 读写，经 clock/data-width conversion 接 UI。
- S01：256-bit、ID3、当前 300 MHz；capture writer 只写、display reader 只读，合到同一 AXI slave，burst 上限 64，写 outstanding 8。
- S02：256-bit、ID3、当前 300 MHz；batch preprocess 读写，burst 上限 128，读 outstanding 8。
- interconnect 为 3 SI→1 MI；S01 优先级 15、S02 为 14；MIG 前有全通道 512-bit AXI register slice。

## 约束核验

- DVP pad→IOB D 的 false path 是异步输入入口例外。
- IOB→第一同步级同时存在 `set_max_delay -datapath_only 1.5 ns` 和覆盖同一目标的 false path，属于 P1 必须消除的重叠；不能用继续扩大 false path 的方式处理。
- 当前 soft pblock 只覆盖若干 `dvp_*_sync/pipe` 叶子寄存器，不等于完整前端已局部化。
- control/diagnostic 多数只对第一同步级使用端点级 false path；P0 报告流水线另行导出例外 coverage/ignored，后续每阶段比较命中范围。

## 基线识别

历史报告关联 DCP 的 SHA-256 为 `50606a662c2f6a6dd5a4b3e9903e9004f1f4f39bcb23597a94e573f61ea86f0e`；它得到 WNS -1.291 ns、TNS -6258.903 ns、20,800 个 setup 失败端点、WHS +0.003 ns、WPWS +0.039 ns。由于该 DCP 早于基线提交，只作为“原报告复现值”。

当前提交的 clean rebuild routed DCP SHA-256 为 `0f2eff178e50a04467e7348b51116d5084c65a87ef7331065981addc526f7b15`，bitstream SHA-256 为 `3e0ebcb49256b818501419ea78652bc59336ff9da889344f18f992907e296f1e`。只有该项作为 P1 以后比较的“本轮核验基线”。

## P0 定位结论

- 20,800 个负 setup 端点全部在 MIG UI 的约 300 MHz clock pair 上，不是外部 PCLK 自身作为时钟的违例。
- 端点类型以 CE（12,409）和 reset/control pin（R 4,427）为主，说明长 READY/容量/复位控制锥是主要对象，不应只追逐数据位。
- 原报告分类：reader 6,668、PCLK/frontend 3,826、stream 2,927、MIG 1,998、frame manager 1,811、writer 1,662、camera FIFO 1,153、HDMI 361、preprocess 343、other 51。
- 8 路 `camera_axis_cdc` 的 `input_run_q`/`packer_run_q` 使用 `ov7670_frontend.pixel_resetn` 异步清零；而该信号由 `video_resetn && capture_enable_sync2` 组合产生。这是 P1 的 8 个已定位 LUTAR 风险源。

## P0 修改映射

| 阶段 | 主要文件 |
|---|---|
| P1 | `rtl/video/camera/ov7670_frontend.sv`、`rtl/video/camera/camera_axis_cdc.sv`、`rtl/video/camera/camera_subsystem.sv`、`xdc/clk.xdc` |
| P2 | `rtl/video/camera/camera_axis_cdc.sv`、对应自检查 testbench |
| P3 | MIG/BD 时钟源、camera event bridge、camera/HDMI clock boundary、约束和 testbench |
| P4 | `ddr_memory_subsystem.sv`、`multi_channel_ddr_video_pipeline.sv`、reader/writer/frame manager、AXI UI adapter/BD |
| P5 | 前端/reader 的局部化层次、SLR 引导、diagnostic snapshot 路径、XDC |
| P6 | 全量回归、routed report、结果与回滚文档 |

## P0 未执行项

- 板级摄像头/HDMI/DDR 压力测试：未执行。
- 真实 PCLK 抖动、模拟亚稳态概率测试：未执行；数字仿真本身也不能证明模拟亚稳态 MTBF。
- P0 routed DCP 的物理 SLR 查询：已执行。负端点主要为 SLR1→SLR1 14,199、SLR2→SLR1 2,251、SLR2→SLR2 2,814，另有 SLR1→SLR0 783、SLR1→SLR2 580 等；这些是 P5 的定位输入，不是预先扩大 pblock 的理由。
