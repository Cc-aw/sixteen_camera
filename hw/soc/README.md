# 三 Gemmini32 SoC

- `source/shell/`：当前 Scala/Chisel shell、MemoryParallelV3 覆盖、冻结 Rocket/Chipyard/L2 依赖和来源记录。
- `source/tensor_ingress/TensorIngress.scala`：当前 TensorIngress 生成源码。
- `tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig/`：唯一生成导出，包含 `gen-collateral/include/` 参数头和 `GENERATION_CONTEXT.json`。

本轮保留导出的长目录和内部相对布局；[交付清单](../manifests/current.json)提供唯一映射。
完整 Scala Config 类名、RoCC opcode、SAFE_MAX、RTL 和约束不随源码迁移改变。

生成入口仍为 [tools/soc/build_triple32_v3_tensor.py](../../tools/soc/build_triple32_v3_tensor.py)。
从仓库根执行 `make soc SOC_REFERENCE=<参考 Chipyard> SOC_WORKSPACE=<新工作区>`，在独立 Chipyard 副本中正常编译和生成，
随后执行 RAM 处理、结构检查和导出。共享的参考工具链通过本机路径配置；
参与当前覆盖的源码以仓库内冻结版本为准，参考工程的源文件不被修改。

`source/shell` 内保留的原始说明/脚本用于来源追溯；正式入口只有根 `make soc`。
验收使用生成器的 `validate_workspace_sources`、当前 RTL 结构检查、TensorIngress/L2、
MemoryParallelV3 和 timing repair 回归；最终整机时序及板测另行验收。
