# MyBoard 视频 AI SoC 计划

最后更新：2026-07-07。

本文档是将当前的 MyBoard Rocket DDR 基础设计转变为视频 AI 推理 SoC 的工作计划。近期目标不是运行 Linux。CPU 作为控制核心，负责启动、调试、调度、DMA 配置、Gemmini 配置以及结果检查。

## 1. 当前已验证的基线

在添加 Gemmini、DMA、UART 或视频 IO 之前，以此基线作为回滚点。

```text
Board/project: /home/wzr/chipyard_vivado/gemmini
Chipyard tree: /home/wzr/chipyard
SUB_PROJECT: chipyard.fpga.myboard
CONFIG: RocketMyBoardConfig
Harness: chipyard.fpga.myboard.MyBoardFPGATestHarness
```

已验证功能：

```text
通过 OpenOCD 和 GDB 的 JTAG/BSCAN 调试正常。
CPU 能够执行由 GDB 从 DDR 加载的 ELF。
CPU 冒烟测试通过。
DDR 低地址读写测试通过。
DDR 高地址探测在 0x100000000 和 0x17fff0000 通过。
当前 DDR 窗口为 0x80000000 - 0x17fffffff，大小 4 GiB。
当前 AXI DDR 接口为 128 位数据，33 位 SoC 物理地址。
Vivado BD S00_AXI 为 128 位数据，32 位 DDR 偏移地址，3 位 ID。
```

当前重要的源文件：

```text
fpga/src/main/scala/myboard/Configs.scala
fpga/src/main/scala/myboard/TestHarness.scala
fpga/src/main/scala/myboard/IOBinders.scala
fpga/src/main/scala/myboard/HarnessBinders.scala
tests/cpu-smoke.c
tests/ddr-memtest.c
```

当前 Vivado 顶层：

```text
/home/wzr/chipyard_vivado/gemmini/rtl/top_wrapper.sv
```

## 2. 目标 SoC 方向

高层目标：

```text
Rocket 控制 CPU
+ Gemmini 矩阵加速器
+ 通过 128 位 AXI 连接的 4 GiB DDR
+ JTAG/GDB 调试
+ UART 控制台
+ DMA 引擎
+ MMIO 状态/控制寄存器
+ 帧缓冲/视频输入输出通路
```

CPU 应保持相对简单。性能关键的数据搬移和计算应交给 Gemmini、DMA 和视频专用硬件。

## 3. CPU 角色

Rocket 核心预计处理：

```text
早期启动和裸机运行时
Gemmini 配置
DMA 描述符设置
中断处理
帧缓冲指针管理
早期调试期间的轻量级预处理/后处理
调试/状态报告
```

在最终设计中，不要使用 CPU 加载/存储循环来处理完整的视频帧移动。该方式仅在早期调试时可接受。

## 4. 近期里程碑：Gemmini

创建一个 MyBoard 专用的 Gemmini 配置，例如：

```text
GemminiRocketMyBoardConfig
```

预期配置方向：

```text
WithMyBoardTweaks
+ Gemmini 配置片段
+ Rocket 控制核心
+ AbstractConfig
```

启动顺序：

```text
1. 为 GemminiRocketMyBoardConfig 生成 Verilog。
2. 确认 DDR 范围仍为 4 GiB。
3. 确认顶层 AXI 仍为 33 位地址和 128 位数据。
4. 将生成的 RTL 导入 /home/wzr/chipyard_vivado/gemmini。
5. 综合，暂不添加视频 IO。
6. 通过 GDB 运行最小 Gemmini 裸机测试。
```

首批 Gemmini 测试不应依赖 UART。使用类似 `cpu-smoke` 和 `ddr-memtest` 的 DDR 状态块。

## 5. UART 计划

UART 应该添加，但当前的 JTAG/GDB 测试方式并不需要它。物理 UART 适配器预计稍后才到，因此顶层连接可以先注释掉，直到硬件就绪。

初始 UART 目标：

```text
从 SoC 暴露 Chipyard UART。
在 top_wrapper.sv 中添加顶层 UART RX/TX 端口。
在适配器连接之前，将顶层 UART 端口注释掉或拉成固定电平。
在电气调试完成后使用 UART 输出人类可读的日志。
保留 GDB/状态块测试作为权威的早期验证方法。
```

建议的顶层占位：

```verilog
// UART 适配器尚未连接。
// input  wire uart_rx,
// output wire uart_tx,
```

在 Chipyard 中启用 UART 时，从相关 MyBoard 配置路径中移除 `WithNoUART`，或者创建一个新的配置片段，使其仅在 AI SoC 配置中保留 UART 使能。

## 6. DMA 计划

最终的视频 AI SoC 需要 DMA。它应被视为核心功能，而非可选优化。

DMA 职责：

```text
在 DDR 和加速器可见缓冲区之间搬移帧/图块数据
支持双缓冲
减少 CPU 拷贝循环
描述符完成时触发中断
通过 MMIO 状态上报错误
```

目标数据通路：

```text
DDR 帧缓冲 -> DMA -> Gemmini / 预处理缓冲区 -> DDR 输出缓冲
```

早期 DMA 验证：

```text
1. CPU 在 DDR 中写入源缓冲区。
2. CPU 配置 DMA 描述符。
3. DMA 将源数据拷贝到目的地址。
4. CPU 或 GDB 验证目的数据。
5. 轮询模式工作正常后，添加完成中断。
```

## 7. 中断和 MMIO 状态计划

最终 SoC 不应仅依赖轮询。

需要的中断源：

```text
Gemmini 完成/错误
DMA 完成/错误
视频帧就绪
可选的 UART 中断
```

有用的 MMIO 状态寄存器：

```text
全局状态
上次错误码
上次描述符地址
DMA 已传输字节数
Gemmini 繁忙周期数
帧计数器
DDR 等待或超时计数器
```

在早期调试阶段，通过 GDB 读取 DDR 状态块仍然是可以接受的，而且通常比中断驱动的软件更容易调试。

## 8. 视频通路计划

不要从真实的摄像头或显示 IO 开始。从 DDR 中的合成帧开始。

启动顺序：

```text
1. 在 DDR 中放置一帧假数据。
2. CPU 配置预处理/Gemmini 任务。
3. Gemmini 或预处理硬件从 DDR 读取数据。
4. 输出张量/结果写回 DDR。
5. GDB 读取状态和选定的结果字。
6. 仅在此工作正常后，再连接真实的视频 IO。
```

可能的未来视频 IO：

```text
HDMI RX/TX
MIPI CSI
并行摄像头输入
AXI4-Stream 视频
帧缓冲控制器
```

## 9. 预处理/后处理

Gemmini 处理矩阵密集型部分，但视频推理通常还需要：

```text
缩放
裁剪
RGB/YUV 转换
归一化
布局变换，如 NHWC/NCHW
量化/反量化
argmax、阈值或 NMS
```

早期版本可以在 CPU 上运行其中一些操作以验证正确性。最终版本应将重复的帧级操作转移到 DMA 友好的硬件模块中。

## 10. 验证顺序

按此顺序操作，避免混入过多未知因素。

```text
1. 保留当前 RocketMyBoardConfig 基线。
2. 添加 Gemmini，不添加 UART、DMA 或视频 IO。
3. 使用 GDB 状态块运行 Gemmini 最小测试。
4. 添加 UART 顶层占位符，保持禁用/注释状态直到适配器就绪。
5. 硬件连接后，在单独的配置中启用 UART。
6. 以轮询模式添加 DMA。
7. 添加 DMA 中断模式。
8. 运行 DDR 帧缓冲 -> Gemmini -> DDR 输出测试。
9. 添加预处理/后处理模块。
10. 添加真实视频 IO。
```

## 11. 当前测试命令

CPU 冒烟测试：

```bash
cd /home/wzr/chipyard
source env.sh
riscv64-unknown-elf-gdb tests/build/cpu-smoke.riscv
```

在 GDB 内部：

```gdb
target extended-remote localhost:3333
monitor reset halt
load
set $pc = 0x80000000
continue
```

读取状态：

```gdb
x/8wx 0x80001200
```

DDR 测试：

```bash
cd /home/wzr/chipyard
source env.sh
riscv64-unknown-elf-gdb tests/build/ddr-memtest.riscv
```

读取状态：

```gdb
x/8wx 0x80001500
```

预期通过状态：

```text
state = 0x000000ff
```
