# 模型生成器

`generate_parallel.py` 从 `../frozen/native/`、唯一 Gemmini ABI 和当前 SoC 参数生成三 worker 模型。
`fixed_plans.py`、`fixed_packets.py`、`prepared_packets.py` 与相邻 `.inc` 共同固化几何、指令操作数、WS/LUT；memory kernels 和 wait reuse 沿用现有证明和批次边界。

通过上层 `model.mk` 使用；输入由模型根来源锁校验，参数必须匹配当前 SoC。
输出在各入口 BUILD/v26 中；视频与基准的 plans/packets 等价性由原生回归覆盖。根目录执行 `make test-model`。
动态引用但正式版禁用的实验分支暂留，不能仅按文件名删除。
