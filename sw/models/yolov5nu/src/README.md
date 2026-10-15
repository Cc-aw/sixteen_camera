# v26 执行核心

`model.c` 执行当前模型并维护层级完成证明；`independent.c` 管理三个 worker 的提交、等待、credit 和退休协作。
`task_switch.S` 与 `task_context_config.h` 共同定义上下文布局，正式构建保持 light FP/VCSR context。
诊断观察源与正式编译开关沿用迁移前实现，默认关闭诊断。

构建统一使用 [model.mk](../model.mk)；接口见 `../include/`，生成输入见 `../frozen/native/`，生成器见 `../codegen/`。
应用、摄像头帧队列、串口基准分别由 Runtime 和 `sw/benchmarks/triple_infer/` 负责。
