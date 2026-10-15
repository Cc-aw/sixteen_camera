# V3 + Tensor 硬件的软件移植

本文记录 V17 A 阶段；当前默认固件已升级为 [v26](triple32-v26-software.md)，构建与下载请使用新说明。

`SOC_VARIANT=triple32_v3_tensor` 的视频固件使用 V17 A 原生 DIM32 ABI、三 worker
独立协作调度器和逐 Head 发布。使用与硬件阶段同名的 SoC 变体；
`SOC_CONFIG` 仍只选择硬件，软件必须显式选择匹配的 `SOC_VARIANT`。

## 构建及下载入口

```sh
make firmware SOC_VARIANT=triple32_v3_tensor
make firmware-benchmark
make check-v17a-firmware
make test-v17a
make test-software
make check-deps SOC_VARIANT=triple32_v3_tensor
make program SOC_VARIANT=triple32_v3_tensor PROGRAM_ARGS=--check
```

视频 ELF：`build/firmware/gemmini_triple32_v3_tensor_video_yolov5nu.elf`。
同名 JSON 记录 SoC、V17 A 策略和 ELF SHA-256。
三图基准 ELF：`build/firmware/triple32_v17a_benchmark/yolo32.elf`。
工具路径放在忽略的 `tools/config/tools.local.mk`；新增脚本不引用开发目录。

最后一条只检查工具、配置与 ELF，不连接开发板。真正下载前，板上必须是
匹配的 V3 + Tensor 位流。下载视频固件可使用已有的 `make program` 入口；
基准下载使用 `ELF_FILE` 指定上述基准 ELF，并保持 `SOC_VARIANT=triple32_v3_tensor`。
本次移植未生成完整位流，未执行开发板下载。

## 固定的 V17 A 策略

| 参数 | 值 |
| --- | --- |
| worker / DIM / 时钟 | 3 / 32 / 100 MHz |
| worker opcode | custom3、custom2、custom1 |
| 提交 / 时间量子 | 1 个完整包 / 200 µs |
| 上下文 / 调度 | light / fixed |
| 指令准备 | fixed plans、fixed packets、prepared WS/LUT |
| 优先级 / 等待 | idle priority、tail wait |
| PPU | early service、逐 Head clean；整图完成后入队 |
| 信用轮询 / layer profiling | 关闭 / 关闭 |

模型与任务切换、包生成器、PPU 基准源码保存在 `sw/models/yolov5nu/triple32/`，
FP16 V3 ABI 保存在 `sw/third_party/gemmini/`。硬件参数直接使用此次 SoC
重新生成的 custom3 参数头，模型编译检查 DIM、bank、accumulator 和 FP16 宽度。
三个量化输入为 image025、036、142，各 921600 字节；权重只使用一份现有 AOT。

## 接入实时视频

实时后端沿用 `AiModelFrameRequest`、Tensor 输入所有权、六槽 Head queue、
PPU 结果元数据及 overlay。原开发目录的 `live/reference` 没有 V17 A 调度器，
本次在当前后端接入共享的 V17 A 核心，没有使用该旧参考程序。

任务在完整包、CPU stage 或原生局部依赖边界协作切换。完成证明同时检查
本 worker 的 accepted/retired 请求计数、ingress/outstanding 状态和 DMA busy；
不能仅凭 busy 清零发布 Head。每个 Head 的事件记录对应 stage、请求数和完成周期。
后端验证事件和槽所有权后发布，并读取 generation 与 producer mask 确认接收。
A 配置不会在 Class0 就将描述符入队，六个 Head 和整图完成证明齐备后才入队。

PPU 的两个驱动对象使用 uncached MMIO 读回顺序屏障，避免全局 RoCC fence。
其他驱动沿用原有 fence。数据一致性依靠局部 DMA 完成和硬件 Flush64。

实时池按 worker 启动和复用：新帧重置该 worker 的栈、计数基线及 Head 事件，
不重置其他任务。旧帧在发出新帧初始化指令前，独立确认完成并释放调度所有权，
避免新帧的 `gemmini_flush` 干扰旧帧的完成证明；全部 WAITING 时一次扫描后返回视频循环；没有可运行 peer
时也按包/时间预算返回。超时按单个活动帧计算，长时间空闲不触发批次超时。
计算完成释放输入和 activation；Head 槽保持到对应 generation 的 PPU 结果出队，
两个槽都被占用时返回提交背压。PPU 结果继续携带 job/frame/stream/version 元数据。

新变体的视频 UART 保留视频、推理、Tensor 浸泡和统计命令。`t/u/U/T` 明确提示
使用独立的 V17 A 三图基准 ELF：原 DIM16 诊断会直接驱动旧 graph/CPU 后处理路径，
不适合常驻的协作调度器。基准保留开发工程的串行黄金输出、原始 Head 字节、
PPU 128-bit 结果字和五轮测量检查；下载后按基准 UART 提示运行并保存完整日志。
可用迁入的 `hardware_log.py`、`ppu_early_log.py`、`ppu_head_log.py` 检查日志。

`dual16` 和 `single4` 保留原来的 ABI、模型及诊断行为。

## Runtime 与应用分层（R5）

实时应用使用 `ai/runtime/rt.h`；原 batch 入口为无状态迁移 shim，旧 no-op bridge 已移除。
`main.c` 保留原启动及 video → Runtime → diagnostics/command 轮询次序。
UART、模式状态、Tensor-only 与带宽诊断分开；命令及输出字段保持不变，日志解析器沿用原格式。
后端计算与 `rt_postprocess_service` 的 Head/PPU 占有独立；Application 不直接包含模型 Backend 或 Head 内部结构。

通用帧指标提供只读、按时间排序的副本；专属 Gemmini/RVV/PPU 指标仍由 `p/P/s` 诊断输出。
没有新增 native scheduler pump、调整包/时间量子或加入新的 hot-path 测量。
[R5 离线验收](../architecture/sw-runtime-r5.md) 包含冻结入口轨迹、Host/RV64 和实际 ELF 构建，不能代替板测。

## 已完成的离线验证

- V17 A 基准 ELF、V3 + Tensor 视频 ELF 均构建成功。
- `make test-v17a` 检查原生与生成指令参数/顺序、Split-K、WS/LUT、FP16、局部完成
  及错误/超时；使用 QEMU 执行真实 RVV256 和 full/light 汇编上下文切换。
- 新实时调度回归覆盖稀疏 worker、全部 WAITING 返回、延迟退休、计数回绕、
  独立复用、新帧 flush 与旧帧完成证明的隔离、Head 证明和长空闲；主机及真实 RISC-V light 上下文均通过。
- 实时后端回归使用生产 PPU 驱动和 Head queue，验证 A 入队策略、计算与结果
  分离、六槽背压、generation 复用和对应帧元数据。
- ELF 反汇编检查确认三个 PPU 驱动调用读回屏障、没有全局 fence；light context
  保存 FP/VCSR 环境，ELF、源码快照及硬件参数哈希一致。
- 原软件主机套件、`dual16`/`single4` 构建及依赖闭包检查通过。

主机模型和 QEMU 不模拟 Gemmini/PPU 数值计算；日志解析测试使用构造日志。
当前开发目录没有提供可用的原始 `uart_ppu_head_clean.log`，未以历史日志冒充
本次板上验证。尚未测量移植后的三图数值、连续视频和性能，不能将开发目录的
历史性能直接作为本版结果。
