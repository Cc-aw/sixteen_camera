# S1 推理约定

默认每份模型/诊断 ELF 运行 102 次推理，只使用 DMA mode 2。DDR direct 是本次包内的
数学基准；不称为 legacy mode。两种 storage 的归一化命令、模型参数与阶段保持一致。

正式计时包含调度、HOST、padding、Head 发布和 PPU 完成；初始化、UART 报告、guard
和结果比较在计时之外。并行 ms/帧是吞吐摊销。诊断 ELF 额外逐字节比较每张图的
907200 B Head 和六次 PAD 源（每帧合计 230400 B），不能用它的周期报告性能。

保留 SPPF 工作区开关：0 时两个临时缓冲在 DDR；1 时 local storage 在每路 ASRAM
尾部分配 PAD 47872 B 和 intermediate 38400 B，全部未分配的 55424 B 检查 guard。
activation arena 始终为 2217600 B，物理 ASRAM 为每路 2359296 B。

性能、完整 Head/PAD、模型精度和时序收敛分别记录。PPU 计数及全部 40 个结果字
匹配只证明当前输入对照通过，不作为独立检测精度证明。
