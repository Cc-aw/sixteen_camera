# ASRAM1 独立下板测试

对应 `activation_sram_512kib_2bank` 私有硬件版本，基于 DMA 优化的
512 KiB／2 bank L2。这里的 512 KiB 指 L2；新增的三块 ASRAM **每块物理容量
2.25 MiB**，逻辑 arena 为 `0x21d680` 字节。

目标比特流由 [hardware/target.json](hardware/target.json) 固定：

- 硬件 build ID：`e684b3d0484a9424`，时钟 100 MHz。
- 比特流：仓库根目录下
  `build/experiments/activation_sram/512kib_2bank/bitstream_e684b3d0484a9424_physical_04/activation_sram_512kib_2bank.bit`。
- SHA-256：`539bce5ed42429ca07a4a5c125e533e5aad2cf06599dc9ef934bfdcc63d894b0`。
- 已布线 WNS 为 −3.100 ns；本包记录实际板测结果，不添加下载前时序门禁。

本目录包含自己的源码、头文件、链接脚本、下载工具和日志解析器，不在构建时引用
其他板测目录。复制来源记录在 [SOURCE_ORIGINS.json](SOURCE_ORIGINS.json)。
`activation_sram_test.elf` 是不带模型权重的小型诊断 ELF，入口 `0x82000000`，占用独立的 512 KiB DDR
区域；运行会覆盖三块 ASRAM、测试用 Gemmini SPAD 区域及自身 DDR 缓冲区。

完整 YOLOv5nu 推理已加入本目录，提供 DDR／ASRAM 两种 storage、四种 DMA 模式和
串行／三路并行对照；模型 ELF 的内存与下载方法见 [YOLO 推理说明](YOLO.md)。
原通路测试入口 `program` 保留，推理入口为 `program-model`／`program-diagnostic`。

## 测试内容

启动先检查三路硬件 ID、frontend 状态、四模式能力、ASRAM 能力页和地址布局，
不匹配就停止。三块 SRAM 基址分别是 `0x20000000`、`0x20400000`、`0x20800000`，
控制页为 `0x20c00000`。

| 测试 | 内容 |
| --- | --- |
| 全容量标量访问 | 每块完整 2.25 MiB，两组互补地址／lane 相关数据；先写完所有块再校验，检测块间别名 |
| 部分写与边界 | 首尾及全部 128 KiB 深度组边界，共 19 个区间；逐字节写校验相邻字节，再检查 16／32／64 位写 |
| RVV | 真实 `vle8.v`／`vse8.v` 全容量往返，标量交叉校验，另有非对齐 93 字节尾段 |
| CPU 空洞 | 每块物理末端和 4 MiB 保留窗口末端，共 12 次读写；逐次核对服务端口 denied=1、accepted=retired=1、物理读写=0 |
| DMA | 3 lane × 4 模式 × 3 布局 × 3 地址位置 × 4 路由，共 432 项；检查结果、源数据、两侧 guard 和计数器 |
| 三路提交 | 每个模式先提交三路自主命令表，再等待完成；使用不同数据检查各自 SRAM，合计 4 项 |

模式编号：0 legacy、1 read_coalesced、2 read_assembled、3 spad_assembled。
布局编号：0 连续短行（C=12/N=32/P=2/stride=12）、1 跨距短行（stride=64）、
2 完整行（C=32/N=32/P=1）。三个位置覆盖低地址、128 KiB 边界和物理容量尾部。
路由编号：0 DDR→DDR、1 ASRAM→DDR、2 DDR→ASRAM、3 ASRAM→ASRAM。
路由 3 使用 RVV 准备本地输入；本地 DMA 输出还通过 RVV 读回。

自主命令表始终在 DDR。测试检查本地 DMA Get／Put 是否符合路由，检查两端口
accepted=retired、denied=corrupt=outstanding=0；DDR→DDR 时本地 DMA 端口必须无请求。
每个成功的 DMA 样本包含周期数，测量范围为命令表 mvin 提交到完成，再到直接 mvout
完成，包含控制开销，排除数据准备、校验及串口输出，不能作为整网推理性能。

## 构建与离线验证

从仓库根目录执行：

```sh
cp sw/board_tests/activation_sram_512kib_2bank/config.example.mk sw/board_tests/activation_sram_512kib_2bank/config.local.mk
# 编辑 config.local.mk 中的 CROSS、OPENOCD_BIN、GDB_BIN 等本机路径
make -C sw/board_tests/activation_sram_512kib_2bank test
make -C sw/board_tests/activation_sram_512kib_2bank preflight
```

已有 `config.local.mk` 时直接编辑即可。输出为 `build/activation_sram_test.elf`、
`.bin`、`.map`、`.dis` 和 `manifest.json`。构建记录本目录源码、目标硬件、编译器与
编译选项的身份，审计 ELF 的地址范围、三路 native opcode、真实 RVV 指令及 PMP／
异常返回指令；源码或 ELF 修改后，下载检查要求重新构建。

`test` 在主机假设备上执行同一套 C 测试流程，并注入错误 ID、块别名、RVV 错误、
空洞未 denied、空洞错误启动物理访问／返回非零／路由错误／未完成、数据错误、
guard 错误、计数器错误和超时。它还测试日志缺项、重复项
及错误字段的拒绝行为。假设备日志带 `hardware=0`，正式解析器拒绝作为板测结果。
这些检查不模拟 RTL、真实 RVV 执行或真实总线异常。

`preflight` 核对目标比特流 SHA-256，并检查文件与工具路径，不启动 Vivado／
OpenOCD／GDB，不访问 JTAG 或串口。
原通路测试 `logs/asram_02/` 已严格解析为 `BOARD_PASS`：15 项内存、432 项 DMA、
4 项三路提交和 12 次空洞拒绝完整通过。该运行的 manifest／ELF 已归档在同一 RUN；
完整 YOLO 推理仍待独立下板，不能由通路测试代替。

本次硬件的 Rocket DCache 不把 uncached TileLink denied 转换成同步 Load／Store
access fault。空洞测试必须通过服务端口的拒绝计数和零物理访问验收，不能仅检查读到零，
也不能以缺少异常码 5／7 判失败。每次探测输出一条 `ASRAM1,HOLE`；任意意外 CPU
异常仍立即失败。原 `asram_01` 日志的 `hole_did_not_trap` 是 schema 1 测试判据错误，
定位证据见 [故障记录](validation/asram_01_diagnosis.md)。schema 2 已修正判据，需重新
下载测试 ELF 并使用新 `RUN` 记录；当前比特流无需重新构建。

可额外对本次比特流的冻结端口 RTL 复现 18 项边界／空洞仿真，先核对各 RTL 与构建
输入 SHA，再使用 Icarus 检查全部 12 个空洞拒绝、D 通道背压和零物理操作：

```sh
python3 -B sw/board_tests/activation_sram_512kib_2bank/scripts/check_hole_rtl.py \
  --rtl build/experiments/activation_sram/512kib_2bank/candidate_03/gen-collateral \
  --build-input build/experiments/activation_sram/512kib_2bank/bitstream_e684b3d0484a9424_physical_04/build_input_sha256.json
```

该补充仿真不执行 CPU 或 URAM 原语；结果在 `build/hole_rtl/evidence.json`。

## 手动下板

先下载比特流，目标名称与其他板测目录一致：

```sh
make -C sw/board_tests/activation_sram_512kib_2bank program-bitstream RUN=bit_01
```

该命令读取 `hardware/target.json`，从仓库的 `build/experiments/` 中选择上面的 `.bit`，
核对 SHA-256 后调用本目录的 Vivado 下载脚本。使用独立的临时 `hw_server` 和与其他
板测目录相同的 Adept IPC 兼容库，结束后清理自身服务；下载日志与回执在
`logs/bit_01/`。工具路径通过 `config.local.mk` 的 `VIVADO_BIN` 配置，板卡通过
`BOARD_JTAG_SERIAL` 选择。此命令下载已有文件，不重新构建比特流。

本目录的 `program` 通过 BSCAN 加载并启动 ELF。重新运行测试应先重新配置 FPGA，
确保 frontend 没有残留状态。下载前关闭 Vivado Hardware Manager 的 JTAG 连接，
串口使用 115200 8N1。

先在终端 A 开始记录串口：

```sh
make -C sw/board_tests/activation_sram_512kib_2bank uart RUN=asram_01 PORT=/dev/ttyACM0
```

再在终端 B 加载固件，串口出现 PASS 或 FAIL 后退出终端 A 的 tio：

```sh
make -C sw/board_tests/activation_sram_512kib_2bank program RUN=asram_01
make -C sw/board_tests/activation_sram_512kib_2bank analyze LOG=logs/asram_01/asram.log
```

每次换一个 `RUN`，保留旧日志。加载记录含 ELF SHA 和软件 build ID；日志还必须匹配
当前 `manifest.json` 的软件／硬件 ID。完整通过应出现：

```text
ASRAM1,PASS,cases=15,dma=432,parallel=4,denied=12,traps=0
```

解析器还要求所有中间记录完整，最终输出 `ASRAM_LOG=BOARD_PASS` 并生成同名
`.summary.json`。只有汇总 PASS 行、存在 FAIL／意外 TRAP、缺失测试项或身份不符，
都不接受为通过。若构建已更新，需保留旧构建和 manifest 才能解析对应的旧日志。

## 验证边界

通路小 ELF 验证内存与 DMA 通路，不运行 GEMM 算术或 YOLO 整网，也不测试会令 frontend
进入粘滞故障的跨 lane 非法 DMA 访问。三路提交不保证每一时刻都有三路总线请求重叠。

`fence rw,rw` 用于本诊断的发布步骤；真实 RVV→DMA／DMA→RVV 数据校验是本次测试
的观测证据。通路小 ELF 没有绑定生产 Runtime 的 `activation_memory_commit` 完成回调，
不能据此宣称所有生产访问序列的 RVV 排序已得到证明。离线测试也不能代替上板验证
当前负时序余量下的稳定性。
