# Vivado 输入工程

`sixteen_camera.xpr` 保存 dual16 板级集成示例。`sixteen_camera.srcs/` 与 `create_design_1.tcl` 保存 DDR Block Design；`setup_vivado.tcl` 根据 `../manifests/` 注册手写 RTL、选中 SoC、IP 和约束。

在仓库根运行 `make check`、`make elaborate` 或 `make bitstream`。命令行构建通过 `tools/build/open_build_project.tcl` 创建 `build/vivado/<配置>/` 工作副本，BD 和 standalone IP 在工作副本中生成，日志和 `.Xil` 位于 `build/`。

GUI 可直接打开 XPR，然后 source 同目录的 `setup_vivado.tcl`。更换 `SOC_VARIANT` / `SOC_CONFIG` 后重新执行建立脚本；其相对路径以脚本位置为基准。
