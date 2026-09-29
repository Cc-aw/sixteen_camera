# OV7670/OV5645 to HDMI firmware

该裸机固件控制 CH4 OV7670 并行 RGB565 输入，经 DDR 帧缓存后，以
1920x1080p60 RGB 输出到 HDMI。CH4 的 640x480 原始画面由 RTL 居中并补黑边，
不做放大。本测试构建关闭 CH5/CH6 OV5645 前端以缩短综合和布局时间。

初始化顺序：

1. GPIO 保持 OV5645 复位，释放 FMC-HDMI 时钟芯片复位；
2. 板卡 AXI IIC 配置 8T49N241，初始化 VPHY、HDMI TX 和帧缓存；
3. CH4 RTL 以精确 24 MHz 执行 ztachip 的倒计时和 SCCB 表，并输出 12 MHz XCLK；
4. 软件只读取 CH4 硬件诊断，不控制其 `pwdn/reset_n/SCCB`；
5. 收到首个完整 OV7670 摄像头帧后启动 HDMI TX。

摄像头软件寄存器窗口：

| 外设 | 地址 |
| --- | --- |
| 帧缓存控制 | `0x4010_0000` |
| CH4 OV7670 诊断 | `0x4011_1000` |
| CH5 OV5645 SCCB GPIO | `0x4012_0000` |
| CH6 OV5645 SCCB GPIO | `0x4013_0000` |

Gamma 首版写入 identity LUT，用于先验证摄像头到 HDMI 的数据链路，不改变像素值。

编译：

```bash
make clean && make
```

下载并运行：

```bash
./run.sh
```

只检查工具路径、配置文件和固件是否就绪，不连接开发板：

```bash
./run.sh --check
```

跳过编译，直接下载已有 ELF：

```bash
./run.sh --no-build
```

脚本使用 OpenOCD BSCAN 连接 Rocket Debug Module，因此执行前需要先将本工程
bitstream 下载到 FPGA。若 Vivado Hardware Manager 仍占用 JTAG，请先断开其
Hardware Target。

硬件修改后重新生成并下载 bitstream：

```bash
cd ../prj
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source build_bitstream.tcl
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch -source program_bitstream.tcl
```

串口为 115200 8N1。输入 `s` 查看 OV7670 的时钟/复位阶段、SCCB
ACK/NACK、PCLK/VSYNC/HREF、帧/行/字节/像素/溢出计数，以及其余视频链路
状态；输入 `r` 重新初始化视频链路；输入 `c` 读取时钟芯片 ID。
生成文件位于 `build/hdmi_tx_test.*`。
