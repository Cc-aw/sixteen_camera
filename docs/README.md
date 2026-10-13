# 文档导航

当前交接与实现入口：

- [SoC 合并指南](integration/soc-integration.md)
- [专用 Tensor 整行写入口与板测统计](integration/tensor-ingress.md)
- [V3 三路 Gemmini32 与 Tensor 写入口](integration/triple32-v3-tensor.md)
- [single4 Linux 配置与 RTL](integration/linux-single4.md)
- [视频与 AI 底座架构](architecture/overview.md)
- [SW Runtime R0 基线与约束](architecture/sw-runtime-baseline.md)：调用图、ABI、离线验证、已知失败及 R1 最小计划。
- [SW Runtime R1a Tensor HAL 实施记录](architecture/sw-runtime-r1a.md)：设备接口、R0 等价轨迹、三配置构建和后续边界。
- [SW Runtime R1b PPU HAL 实施记录](architecture/sw-runtime-r1b.md)：发布/队列/receipt、特殊屏障、三配置后端对照和离线验证。
- [SW Runtime 分层重构设计与实施方案](architecture/sw-runtime-refactor.md)：R0–R6 分阶段计划，R0、R1a、R1b 已完成离线验证。
- [HDMI 八路视频空间封装](integration/8路640x480视频在4K30_HDMI中的空间封装规范.md)
- [PCLK 接口约定](integration/pclk_timing_refactor_interfaces.md)
- [本次目录重构验收](validation/structure-refactor.md)
- [Vivado Tcl 交付验收](validation/vivado-tcl-delivery.md)

`validation/` 中其余文件保留已有视频、FBus、PPU 和物理时序验证证据。它们对应各自测试版本；旧命令和本机路径作为历史上下文保留，不能代替本次重构或新 SoC 的验收。已退休的方案和实现可从 Git 历史查询。

- [V3 + Tensor 的 V17 A 软件移植](integration/triple32-v17a-software.md)：共享基准/实时核心、构建、Head 生命周期及验证边界。
