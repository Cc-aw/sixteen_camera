# V3 SoC 生成源包

本目录保存当前仓库拥有的 V3 生成输入；V4 未引入。
Rocket/Chipyard/L2 核心源码按开发工程 V3 的有效 Scala 哈希恢复。
当前活动覆盖启用三路 MaxPool、L2 五通道寄存缓冲和请求 one-hot front 指针；保留独立 Tensor 写入口统计块13和 ABI1.1。reference 保存构建所需冻结依赖，生产仅导出当前三路 TensorIngress 配置。

使用 [统一生成入口](../../../../tools/soc/build_triple32_v3_tensor.py)；接口和验证说明见
[集成文档](../../../../docs/integration/triple32-v3-tensor.md)。
历史脚本和说明保留来源，其旧工程路径不作为当前仓库的构建入口。
