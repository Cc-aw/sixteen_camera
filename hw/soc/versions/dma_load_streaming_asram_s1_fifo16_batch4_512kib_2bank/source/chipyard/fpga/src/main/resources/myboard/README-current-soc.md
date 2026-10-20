# 当前 MyBoard SoC 说明

最新 DDR/JTAG 调试交接状态见 `README-ddr-debug-handoff.md`。继续调试前优先阅读该文件。

本文档记录当前用于 VU13P/MyBoard 的 Chipyard SoC 配置，主要对应：

```text
SUB_PROJECT=myboard
CONFIG=TinyRocketDDRMyBoardConfig
Harness=chipyard.fpga.myboard.MyBoardFPGATestHarness
```

当前目标不是完整外设系统，而是一版尽量小、便于上板验证 DDR 和 JTAG Debug 的 Rocket SoC。

## 1. 代码位置

MyBoard 相关 Chipyard 代码：

```text
fpga/src/main/scala/myboard/Configs.scala
fpga/src/main/scala/myboard/TestHarness.scala
fpga/src/main/scala/myboard/IOBinders.scala
fpga/src/main/scala/myboard/HarnessBinders.scala
```

OpenOCD 配置：

```text
fpga/src/main/resources/myboard/openocd-bscan.cfg
```

OpenOCD 调试流程：

```text
fpga/src/main/resources/myboard/README-openocd-debug.md
```

生成产物目录：

```text
fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.TinyRocketDDRMyBoardConfig/
```

Vivado 当前工程目录：

```text
/home/wzr/chipyard_vivado/testTiny
```

## 2. 生成命令

从 Chipyard FPGA 目录执行：

```bash
cd /home/wzr/chipyard/fpga
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS make SUB_PROJECT=myboard CONFIG=TinyRocketDDRMyBoardConfig verilog
```

如果 SBT 需要代理，推荐把代理写进 `JAVA_TOOL_OPTIONS`，并确认变量是一行，不要中间换行：

```bash
export JAVA_TOOL_OPTIONS="-Xmx8G -Xss8M -Djava.io.tmpdir=/home/wzr/chipyard/.java_tmp -Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=7897 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=7897"
```

生成成功后重点产物：

```text
chipyard.fpga.myboard.MyBoardFPGATestHarness.TinyRocketDDRMyBoardConfig.fir
chipyard.fpga.myboard.MyBoardFPGATestHarness.TinyRocketDDRMyBoardConfig.dts
chipyard.fpga.myboard.MyBoardFPGATestHarness.TinyRocketDDRMyBoardConfig.memmap.json
```

如果需要重新导入 Vivado，使用生成目录中的 Verilog/SystemVerilog 文件以及 Vivado 工程里的 `rtl/top_wrapper.sv`。

## 3. SoC 总体结构

当前 SoC 配置链：

```scala
class TinyRocketDDRMyBoardConfig extends Config(
  new WithMyBoardTweaks ++
  new WithNoRocketDCacheScratchpad ++
  new testchipip.soc.WithNoScratchpads ++
  new chipyard.config.WithBroadcastManager ++
  new freechips.rocketchip.rocket.With1TinyCore ++
  new chipyard.config.AbstractConfig)
```

含义：

- 一个 Tiny Rocket core。
- RV32，而不是 RV64。
- 外部 DDR 作为主内存。
- 关闭 UART。
- 关闭 SerialTL。
- 关闭 scratchpad。
- 使用 BroadcastManager，让 Tiny core 的缓存路径能正常访问外部内存。
- 关闭 TL monitors，减少 FPGA 综合负担。
- 所有 SoC bus 频率按 50 MHz 配置。

当前 DTS 中 CPU ISA：

```text
rv32imaczicsr_zifencei_zihpm_xrocket
```

因此 OpenOCD 连接正确时应显示：

```text
XLEN=32
```

如果 OpenOCD 显示 `XLEN=64`，说明当前连接/下载的不是这版 TinyRocketDDRMyBoardConfig bitstream。

## 4. CPU 和缓存

当前 CPU 是 `With1TinyCore` 生成的 Tiny Rocket：

```text
CPU: 1 个 Rocket core
XLEN: 32
I-cache: 4 KiB
D-cache: 16 KiB
D-cache block: 64 bytes
PMP regions: 8
hardware breakpoints: 1
```

DTS 中对应信息：

```text
i-cache-size = 4096
d-cache-size = 16384
riscv,isa = "rv32imaczicsr_zifencei_zihpm_xrocket"
```

`WithNoRocketDCacheScratchpad` 和 `WithNoScratchpads` 的目的，是避免 Tiny 配置里使用片上 scratchpad，把主存访问统一导到外部 DDR。

## 5. 时钟和复位

Chipyard 侧配置：

```scala
new chipyard.harness.WithHarnessBinderClockFreqMHz(50.0)
new chipyard.harness.WithAllClocksFromHarnessClockInstantiator
new chipyard.config.WithUniformBusFrequencies(50.0)
new chipyard.clocking.WithPassthroughClockGenerator
```

含义：

- SoC/harness 参考频率按 50 MHz 处理。
- cbus/sbus/mbus/pbus/fbus 在 DTS 中都显示 50 MHz fixed-clock。
- Chipyard 内部使用 passthrough clock generator，不额外生成复杂时钟。

Vivado `top_wrapper.sv` 中：

- `clk_100m_p/n` 输入到 `clk_wiz_0`。
- `clk_wiz_0.clk_out1` 输出 `soc_clk`。
- `soc_clk_locked` 解除 SoC reset。
- SoC reset 接法是 `reset = ~soc_clk_locked`。

DDR4 MIG 使用独立的 `c0_sys_clk_p/n`。

## 6. DDR 和地址空间

Chipyard 配置中 DDR 大小：

```scala
new freechips.rocketchip.subsystem.WithExtMemSize(BigInt(2) << 30)
```

也就是 2 GiB。

DTS 中主存：

```text
memory@80000000 {
  reg = <0x80000000 0x80000000>;
}
```

所以 CPU 侧地址范围是：

```text
0x8000_0000 - 0xffff_ffff
```

大小：

```text
2 GiB
```

Vivado BD 侧 AXI 地址窗口是：

```text
0x0000_0000 - 0x7fff_ffff
```

大小也是 2 GiB。

`top_wrapper.sv` 中做了地址截断映射：

```verilog
assign bd_awaddr = axi4_mem_aw_addr[30:0];
assign bd_araddr = axi4_mem_ar_addr[30:0];
```

因此换算关系是：

```text
CPU 0x8000_0000 -> BD/MIG 0x0000_0000
CPU 0x8fff_fffc -> BD/MIG 0x0fff_fffc
CPU 0x9000_0000 -> BD/MIG 0x1000_0000
CPU 0xffff_fffc -> BD/MIG 0x7fff_fffc
```

这也是为什么 `0x90000000` 理论上应该能访问。如果 `0x80000000` 和 `0x8ffffffc` 成功，但 `0x90000000` 失败，优先检查 bitstream 是否真的是当前这版、OpenOCD 是否显示 `XLEN=32`、FTDI serial 是否选对。

## 7. AXI DDR 接口

Chipyard SoC 通过 `WithMyBoardAXI4MemPunchthrough` 导出一个 AXI4 memory port：

```text
axi4_mem
```

`HarnessBinders.scala` 中再把它变成 harness 顶层 IO。

当前 `top_wrapper.sv` 连接到 Vivado BD 的 `S00_AXI`：

```text
AXI ID:    SoC 4 bit -> BD 3 bit
AXI addr:  SoC 32 bit -> BD 31 bit
AXI data:  64 bit
AXI strb:  8 bit
```

ID 映射：

```verilog
assign bd_awid = axi4_mem_aw_id[2:0];
assign bd_arid = axi4_mem_ar_id[2:0];
assign axi4_mem_b_id = {1'b0, bd_bid};
assign axi4_mem_r_id = {1'b0, bd_rid};
```

地址映射：

```verilog
assign bd_awaddr = axi4_mem_aw_addr[30:0];
assign bd_araddr = axi4_mem_ar_addr[30:0];
```

## 8. JTAG Debug

当前没有把 RISC-V JTAG 直接引到 FPGA 管脚，而是走 Xilinx BSCAN/JTAGTUNNEL。也就是说：

- Vivado 下载 bitstream 用的 JTAG 链。
- OpenOCD/GDB 调 RISC-V 也走同一条物理 JTAG 链。
- OpenOCD 通过 Xilinx BSCAN tunnel 进入 SoC 内部的 RISC-V Debug Module。

`IOBinders.scala` 中核心逻辑：

```scala
JTAGTUNNEL(tck, tms, tdi, tdo, tdoEn)
debug.systemjtag.foreach { j => ... }
```

OpenOCD cfg 关键参数：

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

`0x04b51093` 是当前 VU13P 的 JTAG IDCODE。`irlen 24` 和 `0x8e4924` 对应 UltraScale+ BSCAN tunnel 的 USER 指令。

## 9. 当前内存映射

来自生成的 `memmap.json` 和 DTS：

| 地址范围 | 大小 | 设备 |
|---|---:|---|
| `0x0000_0000 - 0x0000_0fff` | 4 KiB | Debug Controller |
| `0x0000_1000 - 0x0000_1fff` | 4 KiB | Boot Address Register |
| `0x0000_3000 - 0x0000_3fff` | 4 KiB | Error Device |
| `0x0001_0000 - 0x0001_ffff` | 64 KiB | Boot ROM |
| `0x0010_0000 - 0x0010_0fff` | 4 KiB | Clock Gater |
| `0x0011_0000 - 0x0011_0fff` | 4 KiB | Tile Reset Setter |
| `0x0200_0000 - 0x0200_ffff` | 64 KiB | CLINT |
| `0x0c00_0000 - 0x0fff_ffff` | 64 MiB | PLIC |
| `0x8000_0000 - 0xffff_ffff` | 2 GiB | External DDR |

当前 PLIC 的 `riscv,ndev = <0>`，因为这版没有接外部中断设备。

## 10. 当前裁剪掉的功能

这版为了先验证 DDR/JTAG，上板风险尽量小，裁剪了：

- UART。
- SerialTL。
- Scratchpad。
- 复杂外设。
- 外部中断源。

所以这版不适合直接当完整 Linux/外设平台。它更适合：

- 验证 FPGA 时钟/复位。
- 验证 DDR4 MIG。
- 验证 RISC-V Debug Module。
- 用 OpenOCD/GDB 做裸机程序加载和单步调试。

## 11. 最小上板验收流程

1. 生成 Verilog：

```bash
cd /home/wzr/chipyard/fpga
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS make SUB_PROJECT=myboard CONFIG=TinyRocketDDRMyBoardConfig verilog
```

2. Vivado 重新导入当前 RTL，综合、实现、生成 bitstream。

3. 下载 bitstream 后确认 DDR 校准信号：

```text
c0_init_calib_complete = 1
```

4. 启动 OpenOCD：

```bash
/home/wzr/riscv-openocd/src/openocd \
  -f /home/wzr/chipyard/fpga/src/main/resources/myboard/openocd-bscan.cfg
```

5. 确认 OpenOCD 输出：

```text
Target successfully examined
XLEN=32
```

6. telnet 测 DDR：

```bash
telnet localhost 4444
```

```tcl
halt
mww 0x80000000 0x12345678
mdw 0x80000000 1
mww 0x8ffffffc 0x8ffffffc
mdw 0x8ffffffc 1
mww 0x90000000 0x90000000
mdw 0x90000000 1
```

7. 有 ELF 后再用 GDB：

```bash
riscv64-unknown-elf-gdb your_program.elf
```

```gdb
target remote localhost:3333
monitor halt
load
continue
```

## 12. 后续扩展建议

当前这版验证稳定后，下一步可以按需求逐个加功能：

1. 加 UART，方便裸机 `printf`。
2. 加 BootROM/裸机启动流程文档。
3. 加 ILA，观察 AXI `awaddr/araddr/bresp/rresp` 和 MIG `init_calib_complete`。
4. 确认 DDR 全 2 GiB 高地址读写。
5. 如需跑更大程序，再考虑 SmallRocket/RV64 或更完整的外设配置。

每次只加一个功能，先保持 OpenOCD 能显示正确 `XLEN`，DDR 基本读写能过，再继续扩展。
