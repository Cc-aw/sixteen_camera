# 当前 YOLOv5nu 模型材料

这里保存已验证的 640×480 Stage8F image025 AOT 源码/参数、四个 RVV 辅助头，以及由此生成的协作运行时。图与参数供 dual16 和 single4 使用，Gemmini ABI/配置头位于 `sw/third_party/gemmini/`。

- `aot/`：生成器输入及模型权重/参考输入参数。
- `include/`：当前运行时实际包含的 SiLU、Stage3、Stage4 RVV 代码。
- `runtime/`：生产 C/H、Head 布局、profile 模板和生成脚本。
- `sources.lock.json`：保留材料的重构前路径、基线提交和 SHA-256。

整数 corpus 和 LUT 参考数据在 `tests/data/yolov5nu/`。训练权重、校准照片、其他 AOT 图、历史优化和导出环境已移出当前交付范围。

生成运行时使用 `make -C sw yolov5nu-regenerate`；LUT 生成器在 `tools/generate/`。重构验收检查运行时生成一致、LUT 数据一致和 128 图 NMS corpus 无差异。
