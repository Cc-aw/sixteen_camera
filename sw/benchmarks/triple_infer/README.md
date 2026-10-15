# 三图推理基准

本目录负责 image025/036/142 输入、串口 `M/t/a`、原始 Head/PPU 比较和计时。
Makefile 引入 `sw/models/yolov5nu/model.mk`，复用视频固件的模型源码、冻结输入、权重、生成器及参数。`ppu.h` 等共享接口位于模型 `include/`。

根目录运行 `make benchmark`，产物为 `build/firmware/benchmark/benchmark.elf`，身份/输入/计划/源码哈希见同目录 `capacity_manifest.json`。
`M` 测试硬件 Pool/Resize 与 guard，`t` 比较数值，`a` 记录性能；必须使用当前匹配 bitstream。

对照和诊断使用 `make -C sw/benchmarks/triple_infer credit-cap3 credit-cap4-diag`；正式版保持 credit=4、diagnostic=0。
日志检查使用 `python3 tools/analyze/yolov5nu/check_log.py` 或 `analyze_log.py`。
