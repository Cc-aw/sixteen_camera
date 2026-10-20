# MyBoard OpenOCD 调试记录

最新 DDR/JTAG 调试交接状态见 `README-ddr-debug-handoff.md`。继续调试前优先阅读该文件。

这份文档记录当前 MyBoard/VU13P bitstream 的 RISC-V OpenOCD 调试流程。目标是每次重新生成 bitstream 后，可以按顺序确认 JTAG、Debug Module 和 DDR 是否正常。

## 当前文件

- OpenOCD 配置：
  `fpga/src/main/resources/myboard/openocd-bscan.cfg`
- Chipyard 配置：
  `TinyRocketDDRMyBoardConfig`
- Vivado 工程目录：
  `/home/wzr/chipyard_vivado/testTin`

如果实际 Vivado 目录名是 `testTiny` 或其他名字，下面命令里的路径按实际工程修改。

## 1. 确认 bitstream 是新生成的

OpenOCD 能连上并不代表连到的是最新 bitstream。每次重新导入 RTL、综合实现并下载后，先确认 Vivado 下载的是当前工程生成的 bitstream。

常见 bitstream 路径类似：

```bash
/home/wzr/chipyard_vivado/testTin/prj/testTin.runs/impl_1/top_wrapper.bit
```

在 Vivado Tcl Console 可以检查当前硬件目标：

```tcl
get_hw_targets
report_property [current_hw_target]
```

当前 OpenOCD cfg 固定使用 FTDI serial：

```tcl
adapter serial 210357A7D00E
```

如果 Vivado 实际连接的是另一根线，例如 `FTBED6DV`，需要把 `openocd-bscan.cfg` 里的 serial 改成对应值。

Linux 下查看 FTDI serial：

```bash
lsusb -v -d 0403:6010 | grep -i seria
```

## 2. 启动 OpenOCD

先关闭已经占用端口的旧 OpenOCD，再启动新的：

```bash
pkill -f riscv-openocd
```

```bash
/home/wzr/riscv-openocd/src/openocd \
  -f /home/wzr/chipyard/fpga/src/main/resources/myboard/openocd-bscan.cfg
```

成功时应看到类似输出：

```text
Info : Nested Tap based Bscan Tunnel Selected
Info : Bscan tunnel IR 0x8e4924 selected
Info : JTAG tap: riscv.cpu tap/device found: 0x04b51093
Info : [riscv.cpu.0] Examined RISC-V core
[riscv.cpu.0] Target successfully examined.
Info : Listening on port 3333 for gdb connections
Info : Listening on port 4444 for telnet connections
```

对 TinyRocketDDRMyBoardConfig，重点检查 `XLEN`。如果当前生成的是 RV32 Tiny Rocket，OpenOCD 应显示：

```text
XLEN=32
```

如果显示 `XLEN=64`，通常说明 Vivado 下载的不是当前 Tiny bitstream，或者 OpenOCD 连到了另一块板/另一根 FTDI。

## 3. 连接 telnet

另开一个终端：

```bash
telnet localhost 4444
```

注意端口是 `4444`，不是 `444`。

如果 telnet 卡住，先退出当前终端输入：

```text
Ctrl-]
quit
```

如果还是不行，直接杀掉 OpenOCD：

```bash
pkill -f riscv-openocd
```

再重新启动 OpenOCD。

## 4. DDR 基本读写测试

进入 telnet 后先 halt：

```tcl
halt
```

测试 DDR 起始地址：

```tcl
mww 0x80000000 0x12345678
mdw 0x80000000 1
```

期望看到：

```text
0x80000000: 12345678
```

测试 256 MiB 边界附近：

```tcl
mww 0x8ffffffc 0x8ffffffc
mdw 0x8ffffffc 1
```

测试 256 MiB 以外：

```tcl
mww 0x90000000 0x90000000
mdw 0x90000000 1
```

如果 `0x80000000`、`0x8ffffffc` 成功，但 `0x90000000` 失败，先不要直接判断是 DDR 容量问题。当前工程设计目标是 2 GiB DDR 窗口，优先检查：

1. OpenOCD 是否显示正确的 `XLEN`。
2. Vivado 是否下载了最新 `testTin/testTiny` 工程 bitstream。
3. OpenOCD cfg 里的 `adapter serial` 是否和 Vivado 下载使用的是同一个 FTDI。
4. Block Design address map 是否仍是 2 GiB。

当前 top wrapper 的地址映射逻辑是把 CPU 侧 `0x80000000..0xffffffff` 映射到 BD 侧 `0x0..0x7fffffff`。因此 CPU 侧 `0x90000000` 应该进入 DDR 窗口，而不是越界。

## 5. 常见错误

### 端口被占用

现象：

```text
Error: couldn't bind gdb to socket on port 3333: Address already in use
Error: couldn't bind tcl to socket on port 6666: Address already in use
```

处理：

```bash
pkill -f riscv-openocd
```

然后重新启动 OpenOCD。

### USB 设备断开

现象：

```text
libusb_handle_events() failed with LIBUSB_ERROR_NO_DEVICE
unable to purge ftdi rx buffers: LIBUSB_ERROR_NO_DEVICE
error while flushing MPSSE queue: -4
failed jtag scan: -4
```

含义：OpenOCD 侧看到 FTDI/JTAG 设备消失。常见原因是 USB 线松动、板卡掉电、Vivado 抢占/重枚举 FTDI、或者插了两根 FTDI 但 serial 选错。

处理顺序：

```bash
pkill -f riscv-openocd
lsusb | grep 0403
lsusb -v -d 0403:6010 | grep -i seria
```

确认 serial 后，重新下载 bitstream，再启动 OpenOCD。

### IR capture error

现象：

```text
IR capture error
Could not read dtmcontrol
```

处理：

1. 确认 bitstream 已经下载。
2. 确认 `adapter serial` 是 Vivado 使用的同一根 FTDI。
3. 降低 JTAG 速度，例如：

```tcl
adapter speed 1000
```

4. 确认 cfg 里有：

```tcl
riscv use_bscan_tunnel 5
riscv set_bscan_tunnel_ir 0x8e4924
```

### 写 DDR 失败

现象：

```text
Failed to write memory
progbuf=failed (progbuf startup failed), sysbus=disabled, abstract=disabled
```

处理：

1. 先执行 `halt`。
2. 先测 `0x80000000`，再测 `0x8ffffffc`，最后测 `0x90000000`。
3. 检查 OpenOCD 输出的 `XLEN` 是否符合当前 bitstream。
4. 如果 `XLEN` 不对，先解决 bitstream/FTDI 连接问题。
5. 如果 `XLEN` 正确但高地址仍失败，再检查 Vivado BD 地址窗口和 MIG 配置。

## 6. GDB 连接方式

OpenOCD 启动成功后会监听 GDB 端口 `3333`。

有 ELF 时：

```bash
riscv64-unknown-elf-gdb your_program.elf
```

GDB 内执行：

```gdb
target remote localhost:3333
monitor halt
load
continue
```

如果只是测试 DDR，不需要 ELF，直接用 telnet 的 `mww`/`mdw` 更快。

## 7. 当前 cfg 关键参数

```tcl
adapter speed 1000
adapter driver ftdi
transport select jtag
ftdi vid_pid 0x0403 0x6010
adapter serial 210357A7D00E
ftdi channel 0
jtag newtap riscv cpu -irlen 24 -ignore-version -expected-id 0x04b51093
riscv use_bscan_tunnel 5
riscv set_bscan_tunnel_ir 0x8e4924
```

`0x04b51093` 是当前 VU13P JTAG IDCODE。`irlen 24` 和 `0x8e4924` 对应 Xilinx UltraScale+ 的 BSCAN tunnel USER 指令。
