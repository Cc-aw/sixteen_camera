# PCLK/视频时序重构接口契约

本文随 P0～P6 更新，定义重构时不得破坏的语义。

## 像素和帧事件

- OV7670 输入是不可反压的异步 DVP 源。`pixel_ready=0` 不能让传感器停钟，只能触发显式 overflow/fault/abort；禁止静默拼接残帧。
- 一个有效 RGB888 像素携带 `frame_start`、`line_last`，独立 `line_end` 必须在无有效像素时仍可传播。
- 两像素 AXIS beat 为 `{pixel1[23:0], pixel0[23:0]}`，`tuser` 表示 SOF，`tlast` 表示 EOL。`valid && !ready` 时 data/sideband 保持稳定。
- framebuffer stream 继续携带 `data/valid/ready/sof/eol/eof/stream_id/frame_id/error`。普通 disable、overflow、失锁和 reset 都必须在完整新帧处重同步。

## FIFO 和容量不变量

- 接受数减发送数等于占用，且占用不得越界。
- RAM 已发读但未返回的 beat 必须计入 reserved/pending 容量。
- FWFT/standard 模式、读延迟和 reset-busy 都是实现契约的一部分，不允许仅按仿真模型猜测。
- 远端 writer READY/容量状态不得再组合驱动摄像头 RAM enable；跨层边界使用注册弹性缓冲或明确队列。

## 复位与启停

- 硬件 reset 仅用于域级异步断言、同步释放。运行时 capture enable 是同步事务控制，不得经 LUT 组合驱动异步 CLR。
- disable 发生在行中、帧中或半像素时，当前帧作废并清空局部拼接状态；重新 enable 后只从完整 SOF 发布。
- FIFO 任一侧处于 reset busy 时不产生读写握手；跨域 reset 的释放分别在各目的时钟域同步。

### P1 已实现边界

- `ov7670_frontend.pixel_resetn` 现在只表达 `video_resetn` 域级复位；新增 `pixel_enable` 单独表达已同步的运行时采集使能。
- `camera_axis_cdc.camera_enable` 只在 `camera_clk` 上同步清除输入寄存器和两像素 packer 状态，不再进入异步敏感表。
- disable、camera reset 或已同步的 DDR reset 会装载四拍本地 `fifo_reset_pipe`，冲洗 FIFO 中可能属于旧帧的 beat；重新使能后等待本地 run qualifier 和 FIFO reset-busy 均释放才拉高 `pixel_ready`。
- P1 仍保持 `camera_clk == ddr_clk == MIG UI clock` 的现状；真正 capture→video 异步事件边界属于 P3，不能把本阶段结构误称为最终 CDC。

### P2 已实现边界

- 在当前同钟前提下，`camera_axis_cdc` 内部使用单时钟 `xpm_fifo_sync`；外部端口名保持兼容，但 `ddr_clk` 不是独立 FIFO 读时钟。P3 改变 capture 时钟前必须同时换成真实事件 CDC，不能继续沿用本结构跨域。
- FIFO 保持 50-bit `{eol, sof, pixel1, pixel0}` beat 和原配置深度。两个本地预取寄存器属于 FIFO 已发送、AXIS 尚未接受的占用，诊断高水位将它们计入。
- FIFO RAM read enable 仅由本地 `empty`、reset-busy、reset 和 skid-slot 状态决定；`m_axis.tready` 只消费已寄存的 AXIS 输出，不得被重新接回 RAM enable 组合锥。
- `m_axis.tvalid && !m_axis.tready` 时 data/sof/eol 保持稳定；持续 ready 且已有数据时允许每个 `camera_clk` 发送一个 beat。

### P3 已实现边界

- MIG UI 的 3.332 ns 时钟继续作为 `capture_clk`；新增 `BUFGCE_DIV` `/2` 输出形成 6.664 ns 的 `video_clk`。`video_resetn` 在该域异步断言、三级同步释放。HDMI 和尚未迁移的 DDR writer 仍使用 `capture_clk`。
- `ov7670_frontend` 只在 capture 域完成 DVP 输入同步、PCLK 恢复、VSYNC/HREF 过滤和行保护，并发布 14-bit 有序字节/控制事件；RGB565 拼接、RGB888 扩展、两像素 packer、本地 camera FIFO 和 stream 封装已迁到 video 域。
- `dvp_event_bridge` 是每路 capture→video 的真实 `xpm_fifo_async` 边界，深度 1024。物理 DVP 不可反压；FIFO 满或恢复故障后进入 drop-until-frame，独立 toggle/ack fault 通道通知 video 域，只允许在后续完整 frame boundary 处发布 resync。
- `camera_pixel_assembler` 在 fault/resync 后丢弃半像素和未完成帧；fault 与数据事件同拍时 fault 优先，不能泄漏一个旧像素。独立 `line_end` 事件仍能在无 pixel-valid 时传播。
- P4 尚未迁移 DDR writer，因此 P3 使用深度 1024 的 `video_stream_cdc` 将完整 88-bit stream 从 video 域送回 capture/UI 域；数据及 `sof/eol/eof/stream_id/frame_id/error` 原子跨越并在反压时保持稳定。P4 完成 writer 边界迁移后删除该临时桥。

## DDR 帧事务

- 16 个 capture client：channel 0..7 为 OV7670，8..15 为 HDMI demux。
- 一帧从 FREE→WRITING→READY；被 display/preprocess 持有时不得被 writer 重分配。
- abort 后，迟到的 AXI write response/读返回安全排空前，相关 buffer 不可复用。
- AXI AW/W/B 与 AR/R 的关联、burst 长度和 ID 语义在 video↔UI 边界保持；发读前为所有不可反压返回预留空间。
- 当前功能参数保持 640×480、stride 2560 bytes；不能通过降分辨率、降帧率或关闭现有客户端换取时序通过。

## CDC 分类

| crossing | payload | 方法 | 验证重点 |
|---|---|---|---|
| DVP pad→capture | PCLK/HREF/VSYNC/DATA | IOB sample + metastability stage + protocol recovery | 外部采样窗口、sync 局部放置、max/min coverage |
| camera control→capture | enable/config/toggle | 两级同步；bundled data 用 req/ack | 第一同步级例外命中、源数据保持 |
| capture→video | 有序像素/边界/fault event | 异步 FIFO/可靠 fault channel | 顺序、overflow、reset、完整帧重同步 |
| video→DDR UI | AXI command/write/read response | AXI clock converter/显式队列 | 返回预留、关联、abort/drain |
| diagnostic snapshot | counter snapshot/toggle | Gray 或 bundled req/ack | 不反压数据面、连续 clear/snapshot |

P3 新增 crossing 位于每路 `g_camera_frontend[*].u_event_bridge` 和 `g_camera_frontend[*].u_writer_bridge`。综合级 CDC、clock interaction 和层次资源报告保存在 `reports/video_timing_refactor/P3/synth/`；300/150 时钟仍按真实 2:1 关系计时，没有用 clock group 或扩大 false path 隔离。

### P4 已实现 DDR/UI 边界

- P3 临时的八路 `u_writer_bridge` 已删除。camera stream 原生进入 video 域 pipeline；八路 HDMI demux stream 分别通过 88-bit `video_stream_cdc` 从 capture/UI 域进入 video 域，数据和全部帧 sideband 保持原子顺序。
- `multi_channel_ddr_video_pipeline` 的 frame manager、writer、display reader/overlay、batch preprocess 及其事务状态统一在 `camera_video_clk`。内部历史 `_ddr` 后缀仅是兼容命名，不再表示这些寄存器仍运行于 UI 时钟。
- S01 在 UI 侧仍是一个 256-bit、ID3 AXI slave：write-only bridge 提供独立 AW(32)、W(512)、B(32) async FIFO；read-only bridge 提供 AR(32)、R(512) FIFO。S02 用同样的 read/write bridge 对承载 preprocess。括号内为生产 FIFO 深度，未改变 AXI ID、burst 或 MIG/BD 接口宽度。
- 各 channel FIFO 单独保序。AW 与 W 允许独立承压但不会在各自序列内重排；B/R 携带 ID/response/last 返回。FIFO 输出遵守 ready/valid stalled 稳定性，FIFO reset 由两域 reset 协调后才允许握手。
- writer 仍以最终 burst 的 B handshake 作为 frame 完成安全边界；错误响应或帧数据错误在同一边界产生 `frame_error`。manager 只在收到 done/error 后释放 WRITING 所有权，因此在途写响应期间不会把该槽分给下一帧。
- reader 原有 `used + reserved_not_yet_returned <= capacity` 规则不变，在发出 AR 前为 burst 全部返回拍预留本地 FIFO；UI→video R FIFO 是额外吸收容量，不作为超发依据。display、preprocess、AI 的 held mask 仍阻止 writer 复用相同槽。
- capture/UI 时钟与 video 时钟仍按真实 2:1 关系约束；本阶段没有添加 `set_clock_groups`、false path 或 multicycle。综合级证据在 `reports/video_timing_refactor/P4/synth/`。
