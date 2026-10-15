# 当前裸机软件

正式软件为 YOLOv5nu v26 三个 DIM32 worker、credit=4，匹配唯一 `triple32_v3_tensor` 硬件。
实时入口位于 `src/app/`，三图数值/性能入口位于 `benchmarks/triple_infer/`，共用 `models/yolov5nu/model.mk` 及模型/生成实现。

```bash
make firmware
make benchmark
make test-software
make check-v26-firmware
```

从仓库根执行上述命令。输出分别为 `build/firmware/video/video.elf` 和 `build/firmware/benchmark/benchmark.elf`。
直接 `make -C sw` 使用相同模型规则；设置 `TOOLCHAIN`，或使用本机 `tools/config/tools.local.mk`。
生产编译拒绝其他模型、旧硬件或不匹配参数，配置 stamp 继续跟踪开关并重编译受影响对象。

`src/board`、`platform`、`video` 管理板级初始化、cache/console/启动和视频；`drivers` 提供设备 HAL。
Runtime 按 `core/resources/scheduler/services` 分层，backend 适配当前模型，postprocess 处理结果和显示映射。
应用使用 `ai/runtime/rt.h`；现有无状态迁移 shim 及冻结轨迹测试保留。
模型使用 `src/include/codegen/frozen/assets`；来源由统一 `sources.lock.json` 校验，公共 ABI 位于唯一 `third_party/gemmini/`。

完整职责和资源生命周期见 [软件架构](../docs/architecture/software.md)，设备地址与 cache 契约见 [内存映射](../docs/interfaces/memory-map.md)。
测试包括 `tests/host/` 与 `tests/model/yolov5nu/`；R0–R5 命名表示冻结行为比较阶段，覆盖仍由统一入口保留。
板测流程见 [快速开始](../docs/quickstart.md)，状态见 [当前验收](../docs/validation/current.md)。
