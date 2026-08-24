# sixteen_camera

基于 Xilinx Virtex UltraScale+ VU13P 的 16 路视频采集、DDR 帧缓存与 HDMI
输出工程。当前版本已经完成真实硬件上板验证。

系统同时接收：

- CH0~CH7：8 路本地 OV7670 DVP，640×480 RGB565；
- CH8~CH15：从一路 3840×2160p30 HDMI RGB888、2 PPC transport 中实时裁剪
  得到的 8 路 640×480 视频。

16 路视频分别写入 DDR 帧缓存，最终在 1920×1080p60 HDMI 输出上组成 4×4
mosaic。每个格子为 480×270，源图像保持 4:3 比例缩放到 360×270，两侧各填充
60 像素黑边。

## 数据通路

本地 8 路 OV7670 依次经过 300 MHz DVP 接收与 PCLK 恢复、HREF/VSYNC
滤波和 CDC。HDMI RX 输入在 AXI4-Stream 域按固定坐标拆分，黑边不会写入
DDR。两组视频共同进入 16 路 DMA 和独立帧缓存，最后由 4×4 mosaic reader
合成为 1080p60 HDMI 输出。

```text
8 × OV7670 640×480 ── DVP/PCLK recovery ──┐
                                          ├─ 16-channel DMA/DDR ─ 4×4 mosaic ─ HDMI TX 1080p60
4K30 HDMI transport ─ spatial demux ─ 8ch ┘
```

主要特性：

- 8 路 OV7670 独立 SCCB/IIC 初始化，写入 NACK 自动重试并报告明确失败状态；
- 300 MHz 对 PCLK、DATA、HREF 和 VSYNC 进行 IOB 首拍采样；
- PCLK 周期/相位恢复，将摄像头 PCLK 转换为单一 300 MHz 域内的 `pixel_ce`；
- PCLK 毛刺拒绝、单边沿丢失恢复、lock/loss/missing/glitch 诊断；
- HREF 8 周期滤波、VSYNC 256 周期滤波及最小帧间隔门控；
- 行边界 CDC、坏帧补齐、下一帧 SOF 重新同步；
- 4K30 HDMI transport 模式校验和固定 4×2 空间裁剪；
- HDMI 输入 8 路独立 overflow、frame 和 malformed 诊断；
- 16 路 AXI DMA、三缓冲帧管理和独立 DDR 地址空间；
- 1080p60、4×4 mosaic 显示，并保持 VGA 图像宽高比；
- 裸机软件提供 HDMI、摄像头初始化和简洁串口诊断。

## 4K HDMI 输入封装

HDMI RX 必须为 3840×2160、progressive、30 FPS、RGB、8 bit/component、
48-bit AXI4-Stream（2 pixels/clock）。软件只有在检测到这一完整模式后才允许
CH8~CH15 写入 DDR；模式不匹配或 RX 断开时自动关闭 HDMI 捕获。

4K transport 使用 4 列×2 行的 960×1080 槽位，每幅 640×480 图像位于槽位
中央。接收端直接在 AXI4-Stream 域裁剪以下区域：

| 系统通道 | X 范围 | Y 范围 |
| --- | --- | --- |
| CH8  | 160..799 | 300..779 |
| CH9  | 1120..1759 | 300..779 |
| CH10 | 2080..2719 | 300..779 |
| CH11 | 3040..3679 | 300..779 |
| CH12 | 160..799 | 1380..1859 |
| CH13 | 1120..1759 | 1380..1859 |
| CH14 | 2080..2719 | 1380..1859 |
| CH15 | 3040..3679 | 1380..1859 |

完整协议见
[`doc/8路640x480视频在4K30_HDMI中的空间封装规范.md`](doc/8路640x480视频在4K30_HDMI中的空间封装规范.md)。

## 目录

| 路径 | 内容 |
| --- | --- |
| `rtl/video/camera/` | OV7670 前端、PCLK 恢复与摄像头 CDC |
| `rtl/video/hdmi/` | HDMI RX/TX 子系统与 4K 空间解包器 |
| `rtl/video/framebuffer/` | 多通道 DMA、帧管理和 mosaic reader |
| `rtl/soc/` | Rocket/Chipyard 控制 SoC 生成 RTL |
| `xdc/` | VU13P、FMC、摄像头、DDR 和 HDMI 约束 |
| `sim/` | PCLK、IIC、CDC、帧管理和 reader 测试平台 |
| `sw/` | 裸机控制软件、OpenOCD/GDB 下载脚本 |
| `prj/` | Vivado 工程、BD 源和构建 Tcl |
| `doc/` | 接收恢复设计、修复规范和硬件方案记录 |

## 环境

- Vivado 2023.2
- iverilog（摄像头接收单元仿真）
- RISC-V GCC/GDB 工具链
- OpenOCD，使用 FPGA BSCAN 连接 Rocket Debug Module
- 串口：115200 8N1

工程中的脚本默认使用本机 `/mnt/data/Vivado/Vivado/2023.2` 和 Chipyard 工具链
路径；在其他环境中使用时需要调整对应路径或通过软件脚本的环境变量覆盖。

## 生成比特流

```bash
cd prj
/mnt/data/Vivado/Vivado/2023.2/bin/vivado \
  -mode batch -source build_bitstream.tcl
```

输出文件：

```text
prj/sixteen_camera.runs/impl_1/top_wrapper.bit
```

Vivado 的 runs、cache、DCP 和 bitstream 均属于生成文件，不提交到 Git。

> 当前版本已成功生成 bitstream 并通过功能上板验证，但实现报告仍有
> `WNS=-1.220 ns` 的 setup 违例；hold 已通过。最差路径位于 300 MHz DDR
> AXI Interconnect 到 MIG 的跨 SLR 路径，正式交付前仍需完成时序签核。

## 软件编译与运行

编译裸机程序：

```bash
make -C sw
```

只检查工具和固件路径：

```bash
cd sw
./run.sh --check
```

下载并启动软件：

```bash
cd sw
./run.sh
```

执行软件前必须先将本工程 bitstream 下载到 FPGA，并释放 Vivado Hardware
Manager 对 JTAG 的占用。`run.sh` 支持通过 `OPENOCD_BIN`、`OPENOCD_CFG`、
`GDB_BIN`、`GDB_PYTHONHOME` 和 `ELF_FILE` 覆盖默认路径。

## 串口诊断

启动后在串口输入 `s` 获取状态。CH1~CH8 对应内部 CH0~CH7 本地摄像头，
CH9~CH16 对应内部 CH8~CH15 HDMI 裁剪通道。每路主要输出格式为：

```text
CAM CHn init=OK frames=... size=1280x480
  line(ok/short/last)=... vs(ok/short)=...
  pclk(c/v/g/m/l)=... lock/state=... period=...
```

其中：

- `c/v/g/m/l`：candidate / valid / glitch / missing / lock-loss；
- `line short`、`mal` 持续增加通常表示输入行宽或 PCLK 接收仍不稳定；
- 未连接摄像头时出现 IIC 初始化失败属于预期现象；
- 连续两次输入 `s` 可获得区间增量，建议采样间隔约 5 秒且不超过 12 秒。

HDMI RX 额外输出：

```text
HDMI transport(total/malformed)=.../... capture=1
```

`capture=1` 表示输入模式已经通过校验并允许写入 CH8~CH15。`malformed` 或
各 HDMI 通道 overflow 持续增加时，应检查发送端分辨率、颜色格式、2 PPC
设置以及接收侧 DDR 吞吐。

其他命令：

- `r`：重新初始化视频链路；
- `c`：读取板载时钟芯片 ID。

## 仿真示例

PCLK 恢复回归：

```bash
iverilog -g2012 -s tb_dvp_pclk_recovery \
  -o /tmp/tb_dvp_pclk_recovery.vvp \
  rtl/video/camera/dvp_pclk_recovery.sv \
  sim/tb_dvp_pclk_recovery.sv
vvp /tmp/tb_dvp_pclk_recovery.vvp
```

通过时输出：

```text
TB_DVP_PCLK_RECOVERY=PASS
```

## 当前状态

已完成并验证的重点包括：

- 8 路摄像头独立、顺序 IIC 初始化；
- 300 MHz PCLK 恢复和 DATA tap 2 采样；
- HREF/VSYNC 毛刺过滤；
- 行边界 CDC 和坏帧恢复；
- 4K30 HDMI 固定空间封装接收和 8 路实时拆分；
- 16 路 DDR DMA、帧管理和寄存器控制；
- 16 路 4×4、1080p60 HDMI mosaic 显示；
- PCLK Q16.8 相位累加器回绕和精确 1280-byte 行仿真。

验证状态：

- 4K 空间解包 testbench 通过；
- 16 路 mosaic reader testbench 通过；
- 裸机软件使用 `-Werror` 编译通过；
- Vivado 综合、布局布线、DRC 和 Bitgen 完成；
- 16 路版本已成功下载 FPGA 并完成实际显示验证。

硬件信号质量仍会受摄像头模块、杜邦线、FMC 转接板和 PCLK 串扰影响。建议判断
稳定性时优先观察 5 秒 DELTA 中的 `mal`、`missing`、`lock-loss` 和 `line_flush`，
不要只依据上电以来的累计计数。
