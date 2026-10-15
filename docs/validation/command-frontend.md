# 硬件命令前端移植验收

2026-10-15，基线 `ad356e4`。按用户要求只同步硬件，`sw/`、模型生成器、权重和调度器未修改；现有固件不可与新 opcode ABI 配对。生产构建及下载入口会明确拒绝该组合，下一次工作适配软件。

供体来源、bit SHA256、源码哈希和未满足时序的报告摘要见 `hw/soc/source/command_frontend/IMPORT_MANIFEST.json`。供体综合 Tcl 使用 FrontendConfig 的 RTL，bitgen 于 2026-10-15 08:48 成功；最终 postroute_physopt 报告 WNS=-1.990 ns、TNS=-35843.008 ns、65287 个 setup 失败端点。本轮不将其作为时序通过的证据。

当前唯一 Config 保留 TensorIngress，在其上启用三路原生 Scala 前端。Gemmini native opcode 为 custom0/1/2，custom3 为控制；原逻辑 worker 0/1/2 对应前端 lane 2/1/0，CSR/SLR 不变。旧 RegisteredIngressAtomicReserve 不再存在于生成的路由中，RUN accept 改为实际 Gemmini handshake。来源及协议见 [架构说明](../architecture/command-frontend.md)。

| 验证 | 结果 |
| --- | --- |
| 新工作区完整 SBT/Chisel/firtool 生成与原 RAM 后处理 | PASS；784 个 collateral 文件，含当前 TensorIngress |
| 有效 Scala 范围审计 | PASS；仅新增4个前端文件、修改4个接入/配置文件，其余与基线哈希一致 |
| 供体前端 RTL 对照 | PASS；Engine/Cluster/MemoryMux/TL 四个文件逐字节一致 |
| 生产结构与来源/工具检查 | PASS；三路前端与仲裁、三路 MaxPool、双 bank 512 KiB L2、512-bit/ID2 DDR、256-bit/ID5 Tensor、统计 ABI1.1 |
| 引擎、三路 cluster、mux 与冻结参考逐周期对照 | PASS；补充队列、地址/格式错误、超时排空、权限、响应反压、HOST 隔离、ACK 隔离、错峰启动 |
| 生产宽度 DMA 仲裁 | PASS；33 位地址含 bit32、全部64 source、7位 sink、source31 冲突、多拍、反压、零延迟响应 |
| 三路实际 DIM32/FP16 Gemmini 计算 | PASS；矩阵乘、每路6次 LoopConv、非恒等 SiLU LUT、HOST/写确认/中断隔离 |
| 当前 TensorIngress protocol core + 真实 L2 | PASS；3374 周期，tensor overlap=72，dirty flush/eviction，32个 tensor source |
| Vivado 工程重建 | PASS；`build/projects/triple32_v3_tensor/sixteen_camera.xpr` |
| 视频 / 时序边界 / Tensor DMA / MemoryParallelV3 / PPU / cache | PASS |
| V3 timing repair：registered secondary pool、cache、DDR slice | PASS |
| 整机 Vivado elaboration | PASS；`TENSOR_PRODUCTION_TOP_ELABORATION=PASS`，exit=0 |
| 本仓库整机综合/实现/bitstream、板测、完整 CPU/DDR/摄像头并行推理 | 未执行 |

真实计算仿真结果：

```text
REAL_CLUSTER_PASS,dim=32,scale=fp16,conv_chunks=6,silu_lut=checked,gemmini=3,matmul=correct,host_isolation=1,write_ack_checked=1,irq_isolation=1,triple_busy_cycles=318,cpu_cycles=18355
```

它使用三份实际计算 RTL、真实前端及内存仲裁、Vivado 原厂 RAMB36E2 模型及带反压/写确认的内存模型；不代表完整 SoC、YOLO 精度或板端性能。

复现：

```bash
make soc SOC_REFERENCE=<参考Chipyard> SOC_WORKSPACE=<新目录>
make check-deps
make test-frontend SOC_WORKSPACE=<已生成目录>
make test-tensor-ingress SOC_WORKSPACE=<已生成目录>
make test-video test-video-pipeline test-tensor test-memory-v3 test-ppu test-cache
make test-v3-timing-repair SOC_WORKSPACE=<已生成目录>
make project
make elaborate
```

本轮工作区为 `/tmp/sixteen-camera-command-frontend-chipyard`。日志、范围审计、供体 RTL 哈希对照和供体时序报告副本位于 `build/reports/command_frontend/`；机器清单见 [command-frontend.json](command-frontend.json)。旧导出已由生成器备份至 `build/soc_backups/`，旧固件产物保留，不作为新 ABI 的交付。
