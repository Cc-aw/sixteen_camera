# 当前裸机软件

当前硬件的独立基准为 [V33 自主前端](benchmarks/frontend/README.md)，使用冻结 v32 模型计算与 V33 命令表/IRQ13 执行流程。运行三组各12帧，不链接或适配实时 Runtime，不含 V34。
实时入口 `src/app/`、旧 v26 模型/调度器和 `benchmarks/triple_infer/` 保持原样，尚未适配当前硬件 ABI。

```bash
make benchmark
make test-v33
make check-v33-firmware
make program-benchmark PROGRAM_ARGS=--check
```

从仓库根执行上述命令。V33 正式/诊断输出位于 `build/firmware/frontend/`，工具配置使用 `tools/config/tools.local.mk`。Runtime 的 `make firmware` / `make program` 仍受 ABI 保护。
以下说明适用于保留的 v26 Runtime 源码；其构建和模型测试需在后续适配时恢复当前硬件配对。
生产编译拒绝其他模型、旧硬件或不匹配参数，配置 stamp 继续跟踪开关并重编译受影响对象。

`src/board`、`platform`、`video` 管理板级初始化、cache/console/启动和视频；`drivers` 提供设备 HAL。
Runtime 按 `core/resources/scheduler/services` 分层，backend 适配当前模型，postprocess 处理结果和显示映射。
应用使用 `ai/runtime/rt.h`；现有无状态迁移 shim 及冻结轨迹测试保留。
模型使用 `src/include/codegen/frozen/assets`；来源由统一 `sources.lock.json` 校验，公共 ABI 位于唯一 `third_party/gemmini/`。

完整职责和资源生命周期见 [软件架构](../docs/architecture/software.md)，设备地址与 cache 契约见 [内存映射](../docs/interfaces/memory-map.md)。
测试包括 `tests/host/` 与 `tests/model/yolov5nu/`；R0–R5 命名表示冻结行为比较阶段，覆盖仍由统一入口保留。
板测流程见 [快速开始](../docs/quickstart.md)，状态见 [当前验收](../docs/validation/current.md)。
