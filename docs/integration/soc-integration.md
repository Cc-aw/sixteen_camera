# SoC 合并指南

本仓库是视频与 AI 外设底座。计算侧开发人员可以将底座合并到自己的 SoC 工程，也可以把生成 RTL 交给本工程集成。完整 Chipyard、Scala 生成环境和训练导出环境由计算侧维护。

`triple32_v3_tensor` 已导入 V3 shell 和冻结核心源码，可在本仓库重新生成；
其他 Chipyard 构建依赖仍由兼容环境提供，详见 [V3 Tensor 集成](triple32-v3-tensor.md)。

## 硬件入口

以 [top_wrapper.sv](../../hw/rtl/top_wrapper.sv) 和 [control_soc_subsystem.sv](../../hw/rtl/control/control_soc_subsystem.sv) 为连接契约。当前适配模块直接实例化 `TaihangSoCFPGATestHarness`。

| 接口 | 底座与计算侧关系 |
| --- | --- |
| memory AXI | SoC master，底座 DDR slave；旧配置 256-bit，V3 配置 512-bit |
| MMIO AXI | SoC master，底座外设 slave，64-bit 数据 |
| FBus AXI | 底座视频 Tensor/缓存发布 master，SoC coherent slave，256-bit 数据 |
| UART / 中断 | UART 收发与 8-bit 视频中断向量 |
| 时钟 / 复位 | 当前 SoC 为板级 100 MHz；DDR 初始化完成经同步后释放 SoC 复位 |

地址、ID、burst 和每个端口的具体位宽以 [顶层实例](../../hw/rtl/top_wrapper.sv)、[AXI 接口定义](../../hw/rtl/interfaces/axi4_if.sv) 和生成 harness 为准。当前 MMIO 将 Taihang 的 29-bit 地址零扩展，保留软件可见 `0x1004_0000` 映射。

## 放入新的生成 RTL

1. 在外部 SoC 工程生成完整 collateral，将 RTL、头文件、memory 初始化文件放入 `hw/soc/<配置名>/gen-collateral/`。
2. 兼容当前 harness 的情况下执行 `make check SOC_CONFIG=<配置名>` 和 `make elaborate SOC_CONFIG=<配置名>`；选择器只接受直接子目录名。
3. 接口变化时先适配 `control_soc_subsystem.sv` 及顶层总线、时钟、复位和中断，再更新约束。新增底座 RTL 必须进入 `hw/manifests/rtl_manifest.tcl`。
4. 按新 SoC 更新裸机后端、参数头和缓存协议，单独增加匹配的软件配置。`SOC_CONFIG` 只选择硬件；当前固件别名为 `triple32_v3_tensor`，使用 v26，硬件启用 MaxPool 和 TensorIngress。
5. 完成综合、时序、DRC 和板级验证，并保留对应 ELF、bitstream 和 UART 日志。

`hw/manifests/` 是生产输入清单。`hw/ip/` 保存十个 standalone IP 的重建 Tcl；DDR BD 由 `hw/vivado/create_design_1.tcl` 重建。只交付源码、约束和 Tcl，XPR、XCI、BD 及其输出由本地 Vivado 管理并忽略。

合并到已有 Vivado 工程时，在该工程 Tcl 控制台执行 `source /path/to/repository/hw/vivado/setup_vivado.tcl`。仅需某个 IP 时可直接 source `hw/ip/<名称>.tcl`，然后用 Vivado 的 `generate_target` 生成输出。脚本使用 Vivado 默认输出位置。

## 软件与缓存契约

请求和完成 ABI 见 [ai_model_abi.h](../../sw/src/ai/backend/ai_model_abi.h)，地址/寄存器见 [platform.h](../../sw/src/platform/platform.h)，Head 布局见 [yolov5nu_head_layout.h](../../sw/models/yolov5nu/include/runtime/yolov5nu_head_layout.h)。

必须一起核对 Gemmini DIM、worker 数、RoCC opcode、busy/credit CSR、RVV 能力、指针地址、MMIO、L2 和缓存发布完成事件。Tensor READY、计算完成、Head 发布完成和 PPU 结果完成是不同事件，槽位只能在对应所有权释放后复用。

底座保留多 worker 的通用队列和 PPU 容量；容量并不规定新 SoC 的阵列尺寸。当前 YOLOv5nu 运行时只支持一或两个 worker。

## 工具与交付

只需复制本仓库源码并安装工具，固件不再读取外部 HDMI/BSP/Gemmini 源目录。执行 `make check-deps` 检查快照校验值、已构建固件的依赖闭包与工具可用性。依赖出处见 [third_party](../../sw/third_party/README.md)。

本机路径写在忽略的 `tools/config/tools.local.mk`，不要交付个人工具环境。OpenOCD BSCAN 配置和 GDB 下载命令在 `tools/program/openocd/`；适配器序列号通过 `BOARD_JTAG_SERIAL` 提供。固件、报告和板测产物保存在忽略的 `build/`；Vivado 生成目录随本地工程位置，不强制放入 `build/`。
