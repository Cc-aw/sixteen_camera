# 快速开始

唯一组合是 `triple32_v3_tensor` + YOLOv5nu v26（3 × DIM32、100 MHz、credit=4）。

## 环境与来源

需要 Vivado 2023.2、RV64GCV/LP64D bare-metal 工具链、Icarus、Verilator、Python 3.10+，以及 Host C/C++ 编译器。
RV64 行为回归还需要 RISC-V Linux 静态编译器和 `qemu-riscv64`；缺失时必须单列 SKIP。
SoC 生成需要匹配的参考 Chipyard 和其 Java/SBT/firtool 环境；当前 shell、有效覆盖和冻结依赖来自 `hw/soc/source/`。

参考 `tools/config/tools.example.mk` 新建本机的 `tools.local.mk`，保留已有设置；不要将个人路径提交到源码。
配置 `TOOLCHAIN`、`VIVADO_BIN`、`SOC_REFERENCE`，下载时另设 OpenOCD/GDB/JTAG 选项。

```bash
python3 -m pip install -r tests/requirements.txt
make check-deps
```

## 生成与离线构建

```bash
make soc SOC_REFERENCE=/path/to/chipyard SOC_WORKSPACE=/tmp/current-chipyard
make project
make elaborate
make firmware
make benchmark
make check-v26-firmware
make test-software
make test-rtl SOC_WORKSPACE=/tmp/current-chipyard
```

`SOC_WORKSPACE` 必须是新的独立目录。生成器复制参考源码后安装仓库冻结覆盖，正常运行 SBT/Chisel/firtool，再按既有策略处理 RAM 和导出；不会修改参考源码。
`make soc ... SOC_GENERATE_ARGS=--resume` 仅用于已准备且通过源码一致性检查的工作区。
生成导出保留长 Config 目录，准确位置见 `hw/manifests/current.json`。
两个软件入口各自编译适合运行模式的对象，共享模型/生成实现；fixed plans 和 packets 应一致。

## 实现与下载

```bash
make bitstream
make program-bitstream BITSTREAM_FILE=/path/to/current.bit
make program PROGRAM_ARGS=--no-build
```

只有匹配的当前 bitstream 才能用于当前 ELF。视频 ELF 为 `build/firmware/video/video.elf`，对应 JSON 记录硬件生成记录、参数、模型来源锁和 ELF 哈希。
串口 115200 8N1；`h/v/s` 检查命令、视频和状态，`i` 启用/排空推理，并验证重启、资源回收与 overlay。

三图基准使用独立 ELF：

```bash
ELF_FILE="$PWD/build/firmware/benchmark/benchmark.elf" make program PROGRAM_ARGS=--no-build
```

依次发送 `M`（Pool/Resize 及 guard）、`t`（数值）、`a`（性能），保存 UART、bitstream/ELF/参数/计划哈希；要求数值零 mismatch。
下载前仅检查工具和 ELF 可执行 `make program PROGRAM_ARGS=--check`，不会连接开发板。
验证范围和待完成项目见 [current.md](validation/current.md)；不要把开发工程旧成绩视为当前板测。
