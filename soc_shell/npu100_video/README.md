# 100 MHz 三颗 Gemmini64 视频 SoC 源码

计算源码来自 `/home/zw/0918/npu-zw-100-timing`；生成环境来自用户的
`/home/wzr/chipyard`。完整保留用户环境的 Rocket-Chip，包括 LazyRoCC、RocketCore、
HasTiles、FBus 和 MMIO 配套修改。0918 LazyRoCC 仅保存在 `reference/` 供对照，
不参与同步、编译和生成。当前视频工程生产 manifest 已选择此三 worker 配置。

## 已完成的适配

- 保留 100 MHz、三颗 64×64、INT24 部分和、每 worker 64 个 FP16 scale 单元、
  50% Tile 解包、原 SLR 提示和 0918 除法器请求寄存器。
- 使用用户当前 LazyRoCC 的 replay 修复；显式关闭诊断逃生、busy CSR 写旁路和
  MBUS 直连选项。新增加的 ingress debug 是由 Rocket-Chip 驱动的观察输入，
  0918 Gemmini 不使用该输入，不需要伪造输出或改动功能握手。
- 外部 FBus：256-bit 数据、5-bit AXI ID、`source_bits=7`、`fifo_bits=5`；
  与视频读 ID 0～17、Tensor 写 ID 18～31 对齐。
- 内部 `FrontBusKey.beatBytes=32`，避免外部 256-bit 接口内部又被窄化。
- MMIO：基址 `0x10040000`，大小 `0x200000`，64-bit 数据、4-bit ID。
  包含视频、摄像头和 PPU 的全部当前软件偏移。
- 移除当前配置的 SPI 实例及绑定；保留 UART 和内部 JTAG tunnel。
- 使用 `SUB_PROJECT=taihang_soc`，顶层为现有 wrapper 使用的
  `TaihangSoCFPGATestHarness`；配置为
  `tsmcchip.fpga.taihangsoc.TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig`。
  Taihang harness 继承已适配的视频 harness，保持原计算配置。

## 验证与生成

源码编译、有效配置检查和三个 worker 的 replay 恢复仿真：

```bash
bash soc_shell/npu100_video/validate_source.sh
```

先从当前 Chipyard 创建专用构建快照。源码、SBT 输出和依赖缓存独立复制，
只共享工具链可执行文件。快照保留未提交的源码修改，不是 Git worktree。
不要在快照中执行 Git 操作，也不要 source 原 `env.sh`（其中含原目录绝对路径）；
生成入口自动设置 Java、RISCV、Coursier 和临时目录。

```bash
python3 soc_shell/npu100_video/prepare_workspace.py \
  --reference /home/wzr/chipyard \
  --destination /tmp/npu100-video-chipyard

set -o pipefail
CHIPYARD_ROOT=/tmp/npu100-video-chipyard \
  bash soc_shell/npu100_video/generate_video_soc.sh \
  2>&1 | tee /tmp/npu100-video-generate.log
```

工作区准备仅执行一次；已有工作区可直接重跑生成入口：

```bash
CHIPYARD_ROOT=/tmp/npu100-video-chipyard \
  bash soc_shell/npu100_video/generate_video_soc.sh
```

默认 JVM 堆 12 GiB、8 个可用处理器，可用 `NPU_JAVA_HEAP` 和 `NPU_BUILD_CPUS` 调整。
准备脚本不复制旧 assembly 或生成 RTL；通过 SBT 源码依赖重新构建生成器。
FPGA 编译源限定为本配置包，避免无关实验板配置依赖其他版本 Gemmini API。
同步脚本只接受带 `.npu100-video-workspace.json` 标记的专用快照，
检查当前 Rocket-Chip 接口后，替换该快照中的 Gemmini 源码和四个 Saturn 文件。
它不会覆盖原 `/home/wzr/chipyard`，也不会替换快照中的 Rocket-Chip。

生成入口复用 0918 的 URAM/BRAM 后处理，再检查 worker 数量、计算结构、
视频 AXI 端口位宽、实际 FBus 的 32 组 ID 和两个修复，最后写入当前源码指纹。
通过检查后自动导出到当前工程：

```text
generated/soc/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig/gen-collateral
```

配置目录同时保存 `EFFECTIVE_SCALA.sha256` 和 `GENERATION_CONTEXT.json`，记录完整
生成环境中的 Scala 指纹及构建来源。重复生成将上一版移至 `generated/soc-backups/`。
可用 `NPU_SOC_EXPORT_ROOT` 改变导出父目录；入口不改 `build/soc_manifest.tcl`。
`check_video_rtl.py` 是生成后的验收入口；源码检查通过不代表已经生成或实现。

## 集成边界

六个 Head 槽属于外部 `axi4_head_uram_router`、publication manager、PPU 和软件资源管理，
不在本 SoC Scala 覆盖层中。板级工程已同步扩到六槽，并选择新生成 RTL；
视频固件使用三 worker 调度，详见 `doc/three_worker_video.md`。
原 standalone Vivado wrapper 若连接 SPI 端口，不能直接用于本配置。
旧 0918 的 5 ps 时序通过结果不适用于修改后的 SoC，仍需重新实现。
