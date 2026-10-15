# 当前硬件

唯一交付为 `triple32_v3_tensor`：1 Rocket、1 RVV、3 × Gemmini32，100 MHz，
保留十六路视频采集、TensorIngress、双 bank L2、DDR、Head/PPU 与显示叠加。
交付身份及实际生成目录见 [current.json](manifests/current.json)。

- `rtl/`：手写板级集成；入口 `rtl/top_wrapper.sv`，生产闭包由 `manifests/rtl_manifest.tcl` 列出。
- [soc/](soc/README.md)：SoC 生成源码、冻结依赖和唯一导出。
- `constraints/`：板级及 CDC/实现约束；保持既有层级和时序策略。
- `ip/`、`vivado/`：Vivado 2023.2 IP、BD 和工程重建 Tcl。
- `manifests/`：RTL/IP/XDC/SoC 生产清单及硬件/模型配对契约。

根目录执行 `make check`、`make soc SOC_WORKSPACE=<新工作区>`、`make project`、
`make elaborate` 和 `make bitstream`。定向回归见 `make help-tests`。
离线仿真与整机实现/板测分开记录于 [实施验收](../docs/validation/single-version-refactor.md)。
