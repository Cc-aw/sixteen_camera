# 当前 YOLOv5nu v26 模型

正式配置为三个 DIM32 worker、credit=4、100 MHz，启用 fixed plans、fixed/prepared packets、wait reuse 与硬件 Pool/Resize，使用 light FP/VCSR context。
视频和三图基准共用 [model.mk](model.mk)、模型源码、生成器、参数及 ABI；视频另设 `YOLO32_LIVE=1`。

- `src/`：模型、三 worker 协作、上下文切换和当前诊断源码。
- `include/`：当前公共头和平台 shim；`include/runtime/` 保留冻结轨迹测试使用的原接口默认值。
- `codegen/`：fixed plans、packets、prepared WS/LUT、memory kernels 和相邻生成模板。
- `frozen/native/`：当前生成器实际读取的原生 C/头文件，保留原 `dim16_dual` 名称和内容。
- `assets/`：Stage8F AOT 原始材料与当前权重/参数。
- `metadata/`：导入来源和 v26 源码锁；根 `sources.lock.json` 记录原模型材料来源。
- `runtime/`、`v17a.mk`：暂留待依赖审计的旧生成入口，正式构建不使用。

从仓库根运行 `make firmware`、`make benchmark`、`make test-model`。
原生回归位于 [tests/model/yolov5nu](../../../tests/model/yolov5nu/)，三图外壳位于 [sw/benchmarks/triple_infer](../../benchmarks/triple_infer/)，日志工具位于 [tools/analyze/yolov5nu](../../../tools/analyze/yolov5nu/)。
硬件参数始终来自当前 SoC 生成头，不能按原生文件名推断 worker 数或 DIM。
