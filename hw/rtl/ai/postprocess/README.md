# Head publication 与 PPU

本目录保存当前 Head URAM、缓存发布、任务/结果队列和 YOLOv5nu 硬件后处理实现。

- `axi4_head_uram_router.sv` / `head_uram_store.sv`：三个 worker 各 A/B 两槽，共六个物理窗口，保留 Head 写入与读取的所有权边界。
- `head_publication_manager.sv` / `ppu_cache_publish_engine.sv`：缓存发布及完成事件。
- `head_local_reader.sv` / `ppu_publication_gate.sv`：本地 Head 读取和发布完成门控。
- `yolov5nu_postprocessor.sv` 及 class、DFL、BBox、bucket/NMS 模块：六个 raw heads 的硬件处理。
- descriptor、command、result、CSR 模块：任务排队、结果发布与 MMIO 控制。

描述符及窗口布局以 [Head 软件布局](../../../../sw/models/yolov5nu/include/runtime/yolov5nu_head_layout.h)、[平台寄存器](../../../../sw/src/platform/platform.h) 和本目录 CSR 源码为准。当前模型使用三个 DIM32 worker、六个 Head 槽；回归同时保留一或两个 worker 活跃、稀疏负载和槽位复用场景。

在仓库根运行 `make test-ppu`、`make test-cache`，或 `bash tests/rtl/run_yolov5nu_postprocess_tests.sh`。完整板级 RTL elaboration 使用 `make elaborate`；standalone 综合检查位于 `tools/check/`。

架构见 [overview.md](../../../../docs/architecture/overview.md)，交接见 [SoC 合并指南](../../../../docs/integration/soc-integration.md)，已有测量结果与本次验收见 [文档导航](../../../../docs/README.md)。
