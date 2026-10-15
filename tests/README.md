# 当前验证集合

`make test-v33` 验证当前独立 V33 前端软件：本地建表/原生 oracle、实际调度函数的假设备回归、原生PPU生命周期、10项日志契约和两份ELF；不包含实时 Runtime 适配或 V34。

实时 Runtime 尚未适配，以下 v26 模型/固件测试保留为迁移前基线，不能作为新 ABI 的软件验收。
`make test-frontend SOC_WORKSPACE=<已完整生成的工作区>` 覆盖引擎/cluster/mux 逐周期对照、33 位地址/64 source 仲裁和三路实际 DIM32/FP16 计算。
`test-frontend-memory`、`test-frontend-compute` 可独立使用当前生成 RTL；只有逐周期对照需要重建工作区内的 Scala assembly。

`make test-software` 聚合 `tests/model/yolov5nu/` 原生模型回归和全部 `tests/host/run_*_test.sh`，
覆盖应用、Facade、Backend、设备 HAL、ownership、scheduler、fault、timeout、drain/restart 和稀疏 worker。
原 R0–R5 冻结事件、版本/回收轨迹和单/双活跃 worker 场景继续保留。

`make test-rtl SOC_WORKSPACE=<已生成当前 SoC 的工作区>` 包含视频、整帧时序、Tensor DMA/Ingress、真实双 bank L2、MemoryParallelV3、PPU 和当前 cache controller。
指定工作区后会先正常导出独立 TensorIngress protocol core；工作区来源检查拒绝陈旧覆盖。
定向入口见 `make help-tests`。`test-v3-timing-repair` 另需当前生成工作区及 Vivado，覆盖 refill/reload 和 DDR slice 关键边界。

`data/` 保留 golden、LUT、image025/036/142、128 图整数 corpus 和冻结轨迹；`requirements.txt` 声明 NumPy 等依赖。
原生 RV64/QEMU 测试需要 RISC-V Linux 静态编译器；缺工具产生的 SKIP 必须分别记录。
板端 `M/t/a` 使用当前三图基准和匹配 bitstream，离线 PASS 不代替板测或最终时序。
验收身份、命令和证据见 [current.md](../docs/validation/current.md)。
