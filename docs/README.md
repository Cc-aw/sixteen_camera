# 文档导航

当前交接与实现入口：

- [SoC 合并指南](integration/soc-integration.md)
- [专用 Tensor 整行写入口与板测统计](integration/tensor-ingress.md)
- [single4 Linux 配置与 RTL](integration/linux-single4.md)
- [视频与 AI 底座架构](architecture/overview.md)
- [HDMI 八路视频空间封装](integration/8路640x480视频在4K30_HDMI中的空间封装规范.md)
- [PCLK 接口约定](integration/pclk_timing_refactor_interfaces.md)
- [本次目录重构验收](validation/structure-refactor.md)
- [Vivado Tcl 交付验收](validation/vivado-tcl-delivery.md)

`validation/` 中其余文件保留已有视频、FBus、PPU 和物理时序验证证据。它们对应各自测试版本；旧命令和本机路径作为历史上下文保留，不能代替本次重构或新 SoC 的验收。已退休的方案和实现可从 Git 历史查询。
