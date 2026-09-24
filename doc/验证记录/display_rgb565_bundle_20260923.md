# Display RGB565 分阶段验证记录（2026-09-23）

## 实现范围

- Canonical 640×480 RGB888 流保持为 AI Tensor 输入；Display 分支在写 DDR 前缩至 360×270，并转换为 RGB565。
- 每行存储 368 像素，其中末尾 8 像素补零；256-bit AXI 每拍 16 像素、每行 23 拍、行步长 736 B。
- 4 个 256 KiB slot/通道。16 路默认基址为 `0x08000000 + channel * 0x00100000`，占用连续 16 MiB。
- Mosaic 和单路全屏均从新 RGB565 帧读取；overlay 在 RGB888 恢复之后运行。Reader 租约延续到 overlay 最后一拍被接受。
- 单 4×4 Gemmini 的新软件 ELF 为 `sw/build/gemmini_single4_video_yolov5nu_rgb565.elf`；原单 4×4 ELF 未覆盖。

## 分阶段门禁

| 阶段 | 定向仿真 | 综合或展开 |
| --- | --- | --- |
| DISP-P0 | 旧视频回归 `VIDEO_REFACTOR_TESTS=PASS`，含 16 路旧 Mosaic、writer 完成与帧管理 | 旧 Reader 独立综合通过；该旧脚本使用接口默认宽度，仅作行为基线，不作 256-bit 资源对比 |
| DISP-P1 | 连续 3 帧 460800 个输入拍，得到 145800 个输出拍；覆盖输入间歇、输出背压、帧边界与丢弃尾部的错误传播 | `DISPLAY_SCALER_SYNTHESIS=PASS`，显式 48→32-bit 接口，92 LUT、136 FF、0 DSP |
| DISP-P2 | 8 行写出 184 个完整 AXI 拍、25 个写响应；覆盖 8 个 padding 像素、4 KiB burst 边界、AW/W 停顿与 B 后完成 | `DISPLAY_FRAME_DMA_SYNTHESIS=PASS`，显式 256-bit AXI/32-bit RGB565 接口 |
| DISP-P3 | 16 路 4×4 Mosaic 整帧 1036800 输出拍逐拍比对；缺失 CH7 为黑块；长 DDR 停顿触发 1 次 underflow，恢复后完整输出 | `MOSAIC_RGB565_SYNTHESIS=PASS`，184×256-bit 双行缓存综合为 4 个 RAMB36，770 LUT、684 FF、0 DSP |
| DISP-P4 | 单路全屏整帧逐拍比对；集成 Reader 连续切换 Mosaic→全屏两帧，验证 overlay 后才释放帧；overlay 原有框绘制测试和紧凑 4-slot 帧管理测试通过 | `DISPLAY_READER_COMPACT_SYNTHESIS=PASS`，两种 Reader 加 overlay；Vivado 顶层 `synth_design -rtl` 展开通过 |

综合使用 `xcvu13p-fhga2104-2-i` 和 Vivado 2023.2。独立综合顶层显式实例化真实 256-bit AXI 接口，避免将 `axi4_if` 的 64-bit 默认宽度误当作生产宽度。

顶层 RTL 展开为 0 errors，但已有 `video_memory_ports.sv` 多驱动和约束相关 critical warnings；本记录仅确认 Display 改动能在当前工程中展开，尚不是全系统综合、时序或布线签核。

## 软件与容量

`sw/src/hdmi_tx.c` 单独编译通过。新单 4×4 ELF 构建通过，SHA-256：`bf02be32c71f722b4d8775adee37dfcce39b783432bc3e642d7dfbd8fbf50fe2`。原 ELF SHA-256 仍为 `ae4ceb372e0c65b471bd0e17adf9a86e79bef29b01304eb73956d392a2c73df0`。

按 16 路、输入 30 FPS、1080p60 Mosaic 计算，Display DDR 理论写入约 95.4 MB/s、读取约 190.8 MB/s，合计约 286.2 MB/s。该数值是布局参数推算，尚未用板上 AXI 计数器实测。

## 后续门禁

- 保持 4 slot。DISP-P5 的 4→3 评估需要上板采集 drop、writer FIFO 峰值、reader underflow、AXI stall 和 frame age；当前没有实测依据。
- 本阶段未运行布局布线、未生成比特流、未上板。与已提交的 PCLK 阶段一起做最终时序和板测。

## 2026-09-24 初次板测反馈与诊断准备

2026-09-23 23:43 新 bitstream 生成成功（`BITSTREAM_BUILD=PASS`）。
首次下载后用户反馈 HDMI 黑屏，串口反复输出
`[video] AXIS bridge underflow`。该信息只证明 HDMI 输入桥取数不足，
无法单独判断是写帧、DDR 读取、显示 reader，还是 TX 启动顺序造成。
本次 routed timing summary 为 WNS -7.988 ns、TNS -243935.109 ns、
145679 个 setup 失败端点，最坏路径在单 4×4 SoC 的 100 MHz 域；
该 bitstream 未通过时序签核。

已在 `mosaic_rgb565_reader` 和 `full_rgb565_reader` 中加入可连续每周期
发出一对像素的 BRAM/RGB 展开弹性流水。后续核对 `ddr_platform`、
`xdc/clk.xdc` 和综合日志后确认 reader 的 `video_clk` 实际为
150.06 MHz（DDR UI 300.12 MHz 的二分频），旧 reader 每对像素
至少花三个周期，上限约 50.02 M 对/秒，**低于** 1080p60 平均
62.208 M 对/秒。新流水直接消除了这个确定的吞吐缺口，
但仍需新版 bitstream 板测确认 HDMI bridge underflow 消失。
Mosaic、全屏、DDR 停顿和 overlay 集成整帧定向仿真均通过，测试新增
每行 1200 周期上限；集成 Reader 定向综合通过。该 RTL 变更尚未生成新 bitstream。

软件增加 `v` 视频状态命令，打印 TX/reader/DMA/每路写帧计数；
TX bridge underflow 串口消息限为前四次及之后的 2 的幂次，真实累计数在
`v` 状态中保留。诊断固件为
`sw/build/gemmini_single4_video_yolov5nu_rgb565_diag.elf`，SHA-256
`12d90894dc61585c21ad5cc5c1a2b1a4ccad233696ec995f619e88c9d3dba742`。
它可在当前 bitstream 上直接下载，不需要重新布局布线。
待板端 `v` 输出确认写入、读取及 HDMI 状态后，再决定 RTL 变更是否需要
进入下一次完整构建。

### 板端 `v` 状态（2026-09-24）

用户使用诊断 ELF 回报：TX 初始化、HPD、PHY、stream 均为 1；
CH1–CH8 各写入约 191–192 帧，DMA AXI 响应错误 0；
Mosaic reader 输出 386 帧、AXI 错误 0、reader underflow 0，
而 HDMI AXIS bridge underflow 累计 33838（约每输出帧 88 次）。
CH9–CH16 当前无 HDMI 输入帧且 HDMI capture=0。显示帧数约为
本地摄像头写帧数的两倍，符合 30→60 fps 复用预期。
这些数据把持续断供定位到 reader 后的 AXIS/HDMI 桥衔接，
尚不能排除瞬时读停顿、HDMI 桥时序及整体 routed 时序违例。
每路约 4335 次 malformed 计数来自上游 capture ingress 的
`camera_malformed_counts`，不是 RGB565 packer 的错误计数；
它与持续成功写帧同时出现，另行分析。

已保留旧 bitstream 于 `/tmp/sixteen_camera_rgb565_reader_20260924_102253/previous_underflow.bit`。
按用户要求，完整重建在综合过程中停止，**未启动 `impl_1`**；
因此工程默认 bitstream 路径目前为空，板上仍是上一版配置。

新增 150 MHz reader→1024 拍 HDMI FIFO→1080p60 消费节奏的
整帧速率测试。旧三周期 Mosaic reader 在该测试中出现 146438 次
模拟 bridge 欠流并失败；新弹性流水以 1036800 个像素对、0 次欠流通过。
完整 Display 定向仿真再次全部通过，集成 Reader 定向综合先前已通过。
另以 6.664 ns 时钟约束检查 Reader+overlay 综合网表，最差综合级
setup slack 为 +4.000 ns，`DISPLAY_READER_150MHZ_SYNTHESIS=PASS`。
该模拟覆盖持续吞吐及短时背压，不代替新版 bitstream 的板上验证。
