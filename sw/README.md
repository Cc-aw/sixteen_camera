# 视频与 AI 底座裸机软件

`src/` 提供板级初始化、视频服务、Tensor/Head 槽管理、YOLOv5nu 流式调度、PPU、overlay 和串口诊断。`models/yolov5nu/` 保存当前模型运行时、生成输入与参数；`third_party/` 保存已验证的编译依赖。通用 host 测试放在 `../tests/host/`，V17 A 的生成器与原生 ABI 回归保存在 `models/yolov5nu/triple32/tests/`。

## 构建与下载

在仓库根目录运行：

```bash
make firmware SOC_VARIANT=dual16
make firmware SOC_VARIANT=single4
make program PROGRAM_ARGS=--check
make test-software
```

交付 ELF 为 `build/firmware/gemmini_<配置>_video_yolov5nu.elf`。直接 `make -C sw` 生成 `build/firmware/<配置>/hdmi_tx_test.*`。工具从 PATH 或根 Makefile 的 `tools/config/tools.local.mk` 获取；直接调用 `sw/Makefile` 时用环境变量或命令行设置 `TOOLCHAIN`。

当前支持 YOLOv5nu：dual16 为两个 DIM16 worker，single4 为一个 DIM4 worker，triple32_v3_tensor 为三个 DIM32 worker。每个构建目录只保存对应配置；更改编译选项后应清理该配置重编译。

## 接入点

- `src/platform/platform.h`：地址、时钟、寄存器和内存布局。
- `src/drivers/tensor/`：Tensor 描述符、release ack、Producer 控制与设备计数；`src/platform/cycle.h` 提供独立计时接口。
- `src/drivers/ppu/`：PPU 发布、队列、receipt 和原始结果读取；旧 postprocess 文件保留兼容接口及编译入口。
- `src/drivers/overlay/`：busy、box/label 写入及 commit；`src/platform/cache_ops.h` 集中 alias、Flush64、可见性和屏障能力。
- `src/board/xparameters.h`：本板 AMD BSP 配置。
- `src/ai/backend/ai_model_abi.h`、`ai_model_backend.h`：请求、完成事件和后端接口。
- `src/ai/runtime/`：Tensor/Head 所有权、调度、TTL、drain 和任务生命周期。
- `src/ai/postprocess/`：PPU 发布、队列、结果管理和 overlay。
- `src/diagnostics/`：固定输入、后处理和带宽诊断。

新 SoC 需匹配 Gemmini 参数、opcode、busy/credit CSR、缓存发布和复位协议。硬件 `SOC_CONFIG` 不会自动调整这些软件契约。

共享 `ai_batch_runtime.h` 和 `ai_frame_snapshot.h` 保留当前流式运行时使用的统计及帧元数据类型，旧批处理和 snapshot 实现已退出源码。队列 host 回归还覆盖三 worker 的通用容量，旧变体模型支持一或两个 worker，V17 A 模型支持三个 worker。

下载前 FPGA 需加载匹配 bitstream。串口为 115200 8N1，`h` 查看帮助，`v` 查看视频，`s` 查看 AI，`i` 启用或排空推理，旧变体的 `t` 运行固定 image025 自检；V17 A 的固定输入测试使用独立三图基准 ELF。依赖来源见 [third_party/README.md](third_party/README.md)。

## V3 + Tensor 三 worker 固件

`make firmware SOC_VARIANT=triple32_v3_tensor` 构建 V17 A DIM32/FP16 实时视频后端；
`make firmware-benchmark` 构建 image025/036/142 三图基准，`make test-v17a` 运行移植回归。
硬件参数来自匹配 SoC 的生成目录，源码与输入全部冻结在当前仓库。
详见 [软件移植说明](../docs/integration/triple32-v17a-software.md)。

## Runtime 重构基线

分阶段方案见 [Runtime 重构设计](../docs/architecture/sw-runtime-refactor.md)，当前 R0 审计见
[基线与约束](../docs/architecture/sw-runtime-baseline.md)。`make runtime-baseline` 保存构建、
Host/QEMU 回归与产物到忽略的 `build/`；`make test-runtime-baseline` 运行 ABI、身份 trace
及现有错误路径/版本回绕的 characterization。已知缺口在报告中独立记为 FAIL。

R1a 已将流式 Runtime 的 Tensor CSR 访问抽到设备层，保留调度、超时和同步等待语义。
`make test-tensor-device test-runtime-tensor-hal` 比对冻结 R0 的设备协议与 Runtime 轨迹。
详见 [R1a 实施记录](../docs/architecture/sw-runtime-r1a.md)。

R1b 已抽离 PPU 设备操作，保留 Head 所有权、结果身份匹配和原两个对象的特殊屏障配置。
`make test-ppu-device test-runtime-ppu-hal` 对照冻结 R1a 的 publication/queue 与三配置后端路径。
详见 [R1b 实施记录](../docs/architecture/sw-runtime-r1b.md)。

R1c 已完成 overlay 设备边界与 cache 能力定义，旧标签格式、结果排序、TTL 和 Flush64 协议保持。
`make test-overlay-device test-runtime-overlay-hal test-cache-ops` 运行 R1b 对照、真实 overlay/Runtime
集成和 Host/RV64 cache 验证。详见 [R1c 与完整 R1 离线验收](../docs/architecture/sw-runtime-r1c.md)。
R1 已完成离线结构等价验收；R2 已接入资源身份和安全回收，无停止证明时保留占有。
`make test-runtime-resources test-runtime-faults` 验证 32 Tensor、6 Head、1/2/3 worker 及故障路径。
详见 [R2 验收](../docs/architecture/sw-runtime-r2.md)。版本回绕及板测仍待完成。
R3 已将纯选择、派发事务、Pipeline、Tensor/结果/overlay 服务与状态机分开；旧公开入口保留。
`make test-runtime-scheduler test-runtime-r3` 运行 Host/RV64 纯策略及冻结 R2 的 47 组完整事件对照。
详见 [R3 验收](../docs/architecture/sw-runtime-r3.md)。R4a 已接入 `AiRtBackendOps` 与一次性事件桥，编译时显式选择 legacy/V17A profile。
`make test-runtime-backend test-runtime-r4a` 验证 Host/RV64 事件语义、配置负例和真实后端对照。
详见 [R4a 验收](../docs/architecture/sw-runtime-r4a.md)。
`make test-runtime-r4b` 验证独立后处理服务的完成证明（Host/RV64）及冻结 R4a 的 27 组完整轨迹。
详见 [R4b 验收](../docs/architecture/sw-runtime-r4b.md)。
R5 已将启动/事件循环、UART 命令、模式状态、带宽与 Tensor 诊断分开。
新应用使用 `ai/runtime/rt.h`；`ai_batch_runtime_*` 为现有诊断和测试保留无状态迁移 shim，
旧 no-op bridge 已删除。通用帧指标通过 Facade 查询，设备/模型计数通过 `diagnostics/runtime_diagnostics.h` 输出。
`make test-runtime-r5` 验证 91 组应用/UART、47 组真实 Facade 对照及 Host/RV64 指标/占有测试。
详见 [R5 验收](../docs/architecture/sw-runtime-r5.md)。R0–R5 离线结构迁移已完成；
板测与性能未验证，R6 需先取得匹配硬件/软件的板上稳定性和测量基线。
