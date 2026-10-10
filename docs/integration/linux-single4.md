# single4 Linux 配置与 RTL

新增配置为 `tsmcchip.fpga.taihangsoc.TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitLinuxConfig`。配置源码快照在 [LinuxConfigs.scala](../../hw/configs/taihang_soc/LinuxConfigs.scala)，编译时放到 Chipyard 的 `fpga/src/main/scala/taihang_soc/`，与原有 `Configs.scala` 一起使用。

## 硬件配置

沿用 single4 的一个 Rocket、Saturn RVV（VLEN=256、DLEN=128）、一个 packed 逻辑 4×4 Gemmini，以及视频底座现有的 AXI、UART 和 JTAG 接口。明确设置 RV64、Sv39、M/S/U、内存原子操作和 8 个 PMP。系统时钟为 100 MHz，CLINT 时基为 100 kHz；硬件每 1000 个外设总线周期产生一个 tick，设备树使用相同频率。

Linux 配置单独生成 `gemmini_params_taihang_single_4x4_packed_linux.h`。原有 worker0 opcode、busy/credit/计数和 trace CSR 地址保持兼容，未新增用户态 CSR 映射。RTL 配置只提供运行 Linux 所需的硬件，启动软件和板级设备树另行适配。

## 生成命令

以下为本机 Chipyard 路径示例，在本项目根目录先安装新增配置，再从 Chipyard `fpga/` 生成：

```bash
install -m 644 hw/configs/taihang_soc/LinuxConfigs.scala \
  /home/wzr/chipyard/fpga/src/main/scala/taihang_soc/LinuxConfigs.scala
cd /home/wzr/chipyard/fpga
source ../env.sh
taihang_runtime_dir=$(mktemp -d /tmp/taihang-linux.XXXXXX)
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR="$taihang_runtime_dir" \
  make SUB_PROJECT=taihang_soc \
  CONFIG=TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitLinuxConfig verilog
```

独立的 `XDG_RUNTIME_DIR` 避免复用由其他用户创建的 `/tmp/.sbt` socket 目录。生成目录为 `fpga/generated-src/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitLinuxConfig/`。

项目内的交付目录为 `hw/soc/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitLinuxConfig/`。它可通过现有硬件选择器检查：

```bash
make check SOC_CONFIG=tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitLinuxConfig
```

`SOC_CONFIG` 只选择硬件，没有新增 Linux 固件构建别名。

## busy、credit 和完成计数

| 接口 | 含义 | 软件是否必须读取 |
| --- | --- | --- |
| busy CSR | Gemmini 内部是否有未完成工作；当前 worker 调度器据此做非阻塞轮询 | 可改为 `gemmini_fence()` 阻塞等待，但须修改现有运行时 |
| credit/status CSR | 是否可提前提交完整 LoopConv 请求、在途数量及队列状态 | 入口硬件已有背压时，可关闭软件 credit 轮询 |
| accepted/retired CSR | 完整卷积请求的接受次数和实际 slot 退休次数 | 当前模型主流程未使用读取函数，可只保留诊断用途 |
| RoCC `io.busy` | CPU 与加速器之间的硬件忙信号 | 必须保留；当前 Rocket 的 `fence` 等待 RoCC 和向量工作完成 |

`RegisteredIngressAtomicReserve` 将 CONFIG1..CONFIG6、RUN 组装为完整请求；完整请求队列满时阻塞 RUN，容量恢复后释放 Rocket 重放。队列满不会依赖软件 credit 来防止丢请求。软件仍须遵守七条命令的组包顺序，并串行管理单个 worker 的提交。

背压只解决接收容量，不代表计算已经完成。读取输出或复用缓冲区前仍须同步。busy CSR 只反映 Gemmini 内部状态，RoCC 的整体 busy 还覆盖入口的暂存/排队请求，因此保留最终 `fence` 才能覆盖完整提交路径。

现有 `sw/Makefile` 显式开启 `GEMMINI_LOOPCONV_CREDIT_ADMISSION=1`，模型运行时还直接读取机器态 `0x7c2/0x7c3`。将模型迁移到 Linux 用户态时，需关闭 credit 轮询并替换 busy 读取；仅停止导出 CSR 会破坏现有软件。内部计数、断言和背压逻辑与 CSR 导出是不同部分，不应一起删除。

## 后续 Linux 启动工作

本机 `software/firemarshal` 已包含 Linux/OpenSBI/Buildroot，以及 Linux 的 RoCC 上下文切换支持，可以复用。初期无 SPI/SD，可使用 JTAG 加载 OpenSBI + 内核 + initramfs。

生成 DTS 仍是 SoC 设备树，后续需加入启动参数、UART 控制台和视频/张量 DDR 的 `reserved-memory`，核对 OpenSBI PMP 与实际 DDR 地址范围；移植 MMIO、内存锁页和 RoCC 软件同步，再验证启动与模型运行。当前视频中断尚未连接到 SoC 的 PLIC，初期软件可轮询外设。

本次范围止于 RTL 生成和静态检查，不包含内核镜像、Vivado 综合、bitstream 或板上 Linux 启动验证。

## 本次验证

- Chipyard `make ... verilog` 返回 0，Scala 编译、Chisel elaboration 和 firtool 1.75.0 转换完成，共生成 668 个 `.sv` 文件。
- 新配置与现有 single4 的 `TaihangSoCFPGATestHarness` 端口名称、方向和位宽一致。
- 交付目录中的 `sim_files.common.f` 使用相对路径，所有引用文件均存在；独立参数头确认 DIM=4、custom3。
- DTS 编译通过，确认 CPU 100 MHz、Sv39、PMP=8、CLINT 100 kHz、PLIC 和 UART。dtc 对 `/soc` 下五个 fixed-clock 节点给出 `simple_bus_reg` 警告。
- 本项目 `make check SOC_CONFIG=<Linux 配置目录名>` 通过。

交付目录的 `generation.json` 记录检查结果和配置源码校验值，`sha256.json` 记录 collateral 校验值。完整生成日志保存在本机 `build/reports/linux_single4/generate.log`。
