# v26 模型回归

根目录运行 `make test-model` 或 `make test-software`。覆盖原生数值/命令流、Split-K、FP16、credit、wait reuse、Pool/Resize、Head 发布、三 worker 和稀疏负载。
断言和数值 oracle 沿用迁移前实现；`paths.py` 仅将原平铺夹具路径映射到新的所属目录。

构建规则传入本机 RISC-V 工具链目录，RV64/QEMU 检查与 Host 检查分别记录。缺工具产生的 SKIP 不代表该项通过；三图硬件数值与性能仍需板测。
