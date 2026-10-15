# 冻结的原生输入

`native/yolov5nu_dim16_dual.c` 是当前 v26 生成器的真实输入，相邻头文件/profile 模板属于其来源闭包。
保留原始文件名、默认宏与内容；正式构建显式指定三个 DIM32 worker，并使用当前生成参数。
来源和哈希见模型根 `sources.lock.json`，验证入口为 `make check-deps test-model`。
