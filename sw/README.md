# 视频与 AI 底座裸机软件

`src/` 提供板级初始化、视频服务、Tensor/Head 槽管理、YOLOv5nu 流式调度、PPU、overlay 和串口诊断。`models/yolov5nu/` 保存当前模型运行时、生成输入与参数；`third_party/` 保存已验证的编译依赖。host 测试统一放在 `../tests/host/`。

## 构建与下载

在仓库根目录运行：

```bash
make firmware SOC_VARIANT=dual16
make firmware SOC_VARIANT=single4
make program PROGRAM_ARGS=--check
make test-software
```

交付 ELF 为 `build/firmware/gemmini_<配置>_video_yolov5nu.elf`。直接 `make -C sw` 生成 `build/firmware/<配置>/hdmi_tx_test.*`。工具从 PATH 或根 Makefile 的 `tools/config/tools.local.mk` 获取；直接调用 `sw/Makefile` 时用环境变量或命令行设置 `TOOLCHAIN`。

当前支持 YOLOv5nu：dual16 为两个 DIM16 worker，single4 为一个 DIM4 worker。每个构建目录只保存对应配置；更改编译选项后应清理该配置重编译。

## 接入点

- `src/platform/platform.h`：地址、时钟、寄存器和内存布局。
- `src/board/xparameters.h`：本板 AMD BSP 配置。
- `src/ai/backend/ai_model_abi.h`、`ai_model_backend.h`：请求、完成事件和后端接口。
- `src/ai/runtime/`：Tensor/Head 所有权、调度、TTL、drain 和任务生命周期。
- `src/ai/postprocess/`：PPU 发布、队列、结果管理和 overlay。
- `src/diagnostics/`：固定输入、后处理和带宽诊断。

新 SoC 需匹配 Gemmini 参数、opcode、busy/credit CSR、缓存发布和复位协议。硬件 `SOC_CONFIG` 不会自动调整这些软件契约。

共享 `ai_batch_runtime.h` 和 `ai_frame_snapshot.h` 保留当前流式运行时使用的统计及帧元数据类型，旧批处理和 snapshot 实现已退出源码。队列 host 回归还覆盖三 worker 的通用容量，当前模型运行时支持一或两个 worker。

下载前 FPGA 需加载匹配 bitstream。串口为 115200 8N1，`h` 查看帮助，`v` 查看视频，`s` 查看 AI，`i` 启用或排空推理，`t` 运行固定 image025 自检。依赖来源见 [third_party/README.md](third_party/README.md)。
