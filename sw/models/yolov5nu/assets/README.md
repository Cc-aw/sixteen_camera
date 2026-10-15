# 模型材料

保留 Stage8F 640×480 AOT 原始程序及 image025 profile 参数/权重，内容与基线一致。
当前生成器使用冻结 native 图及这里的参数；image025/036/142 基准输入和 golden 位于 `tests/data/yolov5nu/`。
来源哈希由模型根 `sources.lock.json` 和 `make check-deps` 校验；数值/packet 回归使用 `make test-model`。
