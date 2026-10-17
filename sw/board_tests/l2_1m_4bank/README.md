# S1 L2 1 MiB／4 bank 独立板测

此目录可以整目录复制使用。所有工程源码、头文件、模型、输入、下载脚本和
目标比特流均已复制到本目录；构建及运行不读取仓库其他目录，不依赖 Git。
固定兼容基线为 `d7cbd61836cc2f4336e07c42d7ca2cd3a741a35b`，不随正在开发的
DMA 合并、S2D 或其他软件功能变化。来源和原文件哈希见 `SOURCE_ORIGINS.json`。

目标是 S1 Head、S1 组合 L2、1 MiB／4 bank、TensorIngress、DDR mode1、三颗
DIM32 Gemmini、frontend ABI2、100 MHz；MPV3 ABI1.2，16 个统计块。
本次 bitstream 的 SHA-256 为
`b7290308c35b81961cb847cd9f538c508ebeffadaf9366407baf4436d5a8499a`。
已生成比特流，但布线 WNS −7.159 ns、WHS 0 ns，时序没有通过。板测只能记录
本次运行观察，不能用一次成功运行证明时序稳定或提前宣称性能提升。

## 目录与程序

| 路径／程序 | 用途 |
| --- | --- |
| `src/`、`include/` | 新增的板测入口、CPU 基础测试及本地头文件 |
| `reference/`、`model/` | 复制的固定 V33／V34 实现和约19 MiB模型／输入；无外部源依赖 |
| `hardware/` | 本地 `top_wrapper.bit`、参数头、统计寄存器、L2 元数据和目标版本 |
| `program/`、`scripts/` | 本地 Vivado／OpenOCD／GDB 下载及日志解析代码 |
| `tests/` | MMIO／数据故障注入、真实 C 报告契约和日志完整性测试，均离线 |
| `build/l2_smoke.elf` | 检查4 bank几何；2 MiB地址相关数据、顺序读取、字节写、逐bank同set的16个tag；4份完整16×32快照 |
| `build/yolov5_reference.elf` | 冻结V33完整模型：direct、单前端、三前端各12帧；正式周期比较使用此程序 |
| `build/yolov5_diagnostic.elf` | 固定V34：HOST边界、Gemmini等待、四bank L2、Head／AXI／DDR／MIG统计；诊断开销不作为正式性能 |

CPU 基础测试覆盖 CPU 缓存／L2／DDR 路径，不等同于独立验证 TensorIngress、
并发四bank峰值吞吐或全部 TileLink 一致性状态。完整模型内部比较检测数及40个
PPU字，保留 `independent_accuracy=not_proven`，不宣称独立黄金检测精度通过。
快照原样保存全部16块；9–11块为300 MHz，其余为100 MHz。各域快照握手并非
同一时刻，计数器之间及重叠HOST等待不能直接相加成可节省周期。

## 离线准备

进入本目录。所需工具是 Python3.10+、host C、RV64GCV/LP64D 工具链、Vivado
2023.2，以及支持本地BSCAN配置的OpenOCD／GDB；串口使用 `tio`。

```bash
cp config.example.mk config.local.mk  # 本机若已配置则保留原文件
# 编辑 config.local.mk 中的已安装工具路径与 BOARD_JTAG_SERIAL
make all
make test
make preflight
```

这些命令均不连接板卡。构建记录源文件、编译器、硬件和三个ELF的哈希，审计
编译依赖不得指向其他工程目录。`make check` 检查本目录的已有产物；修改本目录
输入后需重新 `make all`。仓库其他目录的改动不会使本目录审计过期。
离线测试中的模拟计数器和时序不能记为板测结果。

`hardware/top_wrapper.bit`、`build/`、`logs/`、`config.local.mk` 默认不进入Git。
给别人使用时直接复制完整目录，保留比特流与测试ELF，不生成压缩包。
不要只复制Git中的源码部分。工具本身由使用者安装，不复制完整工具链。

## 板测顺序

1. 板卡上电，连接JTAG和UART。关闭占用JTAG的Vivado Hardware Manager／OpenOCD。
   本目录脚本只配置FPGA SRAM，不烧写Flash。串口设为115200、8N1、无流控。
2. 下载本目录固定比特流：

   ```bash
   make program-bitstream RUN=new_bit
   ```

3. 先打开串口记录，**另一个终端**再下载基础测试。两个终端均进入本目录：

   ```bash
   # 终端A：PORT按实际设备修改，RUN每次使用新名字
   make uart TEST=smoke RUN=new_smoke_01 PORT=/dev/ttyACM0
   # 终端B：与终端A使用相同RUN
   make program-smoke RUN=new_smoke_01
   ```

   看到 `L2BTEST,PASS,test=smoke,...marker=ALL_SMOKE_COMPLETE` 才算完整。
   终端A按Ctrl+T再Q结束记录，然后解析：

   ```bash
   make analyze LOG=logs/new_smoke_01/smoke.log
   ```

4. 基础测试通过后，按同样的双终端方式运行完整模型：

   ```bash
   # 终端A
   make uart TEST=reference RUN=new_reference_01 PORT=/dev/ttyACM0
   # 终端B
   make program-reference RUN=new_reference_01
   # 结束串口记录后
   python3 scripts/analyze.py logs/new_reference_01/reference.log --group new_4bank
   ```

   必须等到 `ATSOFT1,PASS,...marker=ALL_COMPLETE`，解析应输出
   `L2_BOARD_LOG=PASS`。解析会检查每组12帧、三路各4帧、PPU一致性和周期计算。

5. 需要分析慢在哪里时，运行 `TEST=diagnostic`、`program-diagnostic`：

   ```bash
   # 终端A
   make uart TEST=diagnostic RUN=new_diag_01 PORT=/dev/ttyACM0
   # 终端B
   make program-diagnostic RUN=new_diag_01
   # 结束串口记录后
   make analyze LOG=logs/new_diag_01/diagnostic.log
   ```

   第一条 `ATSOFT1,PASS` 不是诊断结束，需继续录制到
   `ATSOFT1,DIAG_COMPLETE,version=34,boundary_records=468,short_window_pairs=13,memory_available=1,marker=ALL_DIAGNOSTICS_COMPLETE`。
   本程序额外检查ABI1.2、4 bank、mask0x3000和1 MiB，错误硬件会明确失败。

每份UART日志、OpenOCD日志、下载回执、解析JSON和文本报告均留在对应的
`logs/<RUN>/`。下载回执记录实际ELF哈希及最近一次通过本脚本下载的bitstream；
它是主机下载记录，不能冒充板上可读的bitstream指纹。用GUI下载过硬件后，应
重新经本脚本下载后再留正式回执。卡死、TRAP、FAIL、PPU不一致或日志截断均
不算通过；失败后先重新下载bitstream，再重测，避免沿用未排空的前端状态。

如果终端曾报 `No Vivado hardware target found`，本目录的下载脚本现在会启动
自己的临时 `hw_server`，使用空闲的本地端口，结束后自动关闭。它带有仅作用于
该进程的 Digilent IPC 兼容库：旧 Adept 对 `/tmp` 中其他用户创建的已知共享文件
以 `O_CREAT` 打开被系统拒绝时，仅尝试普通读写打开已有常规文件；不创建替代
文件，不跟随软链接。无需 sudo；系统参数和已有共享文件均不修改。
详细诊断保存在同一 RUN 的 `hw_server.log` 和 `digilent_adept.log`。
仍需释放正在占用同一 JTAG 的 OpenOCD／Hardware Manager；脚本不会关闭他人的进程。

## 新旧硬件速度对比

先固定本目录 `build/yolov5_reference.elf`，记录 `build/manifest.json` 的ELF
SHA；两个bitstream使用同一文件，期间不重新编译，也不启用SW-P3／S2D／DMA
候选。基础测试及四bank诊断只针对新硬件；旧两bank只运行相同reference ELF，
并确认其frontend ABI2、模型指令、Head／PPU地址兼容。

旧比特流若要由本目录下载，先把文件**复制**到本目录 `hardware/baseline.bit`：

```bash
python3 scripts/program.py bitstream --run old_bit --bitstream hardware/baseline.bit
```

按上述双终端方法运行reference，使用独立RUN并解析时传 `--group old_2bank`。
至少重复三轮，建议新／旧／旧／新顺序，保持视频负载、输入和复位方式相同。
比较两组的整组三前端绝对周期、中位数和波动，不能只比较“单路／三路”的比值：

```bash
python3 scripts/analyze.py --compare \
  logs/new_reference_01/reference.json logs/old_reference_01/reference.json
```

比较器要求通过本目录下载脚本生成的ELF回执，拒绝不同ELF或诊断程序；没有
回执的日志可以检查完整性，但不能认定已证实使用同一ELF。历史S1比特流的Tensor／DDR设置与本候选不同，
用它比较只能报告整机组合差异，不能把差异全部归为L2容量。此候选时序未过，
即使某次结果正确也不代表已达到稳定运行条件。

## 版本和清理

首次离线验证记录保存在 `validation/acceptance.json`，包含本地 ELF／比特流哈希、
28项自动测试、模型计划比对、下载预检查和复制到仓库外重新构建的结果。
终端下载修复记录在 `validation/jtag_download_fix.json`，另增加5项兼容行为及进程
清理测试，记录修复后构建和实际下载的结果。原始输出在本目录 `build/`、`logs/`。
模拟日志均为离线测试输入；成功下载比特流不能代替板上基础测试、模型正确性
或性能测量。

新功能新建自己的 `sw/board_tests/<功能名>/`，复制需要的依赖并记录来源；
不往此目录追加别的功能，也不回写共享frontend目录。此目录的模型、源码副本
和大文件先保留，确认复盘与复现需求后再按功能目录清理。
