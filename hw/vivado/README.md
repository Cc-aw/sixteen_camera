# Vivado 源码入口

仓库只跟踪 Tcl 和约束，不跟踪 XPR、BD、XCI、IP 输出、缓存和运行目录。本地已有工程继续保留，Vivado 自行管理生成物；`.gitignore` 避免这些文件进入提交。

`make project` 调用 `create_project.tcl`，默认创建或打开本目录的 `sixteen_camera.xpr`，然后根据 `../manifests/` 注册 RTL、选中 SoC、重建十个 standalone IP、DDR BD 和 wrapper。Vivado 版本为 2023.2，器件为 `xcvu13p-fhga2104-2-i`。

```bash
make project SOC_VARIANT=single4
make project VIVADO_PROJECT=/path/to/local/example.xpr
make elaborate VIVADO_PROJECT=/path/to/local/example.xpr
make bitstream VIVADO_PROJECT=/path/to/local/example.xpr
```

GUI 可 source 本目录的 `create_project.tcl` 来重建默认工程；打开自己的工程后，source `setup_vivado.tcl` 可直接合并底座。更换 SoC 后重新执行 setup，选择器使用 `SOC_VARIANT` / `SOC_CONFIG` 环境变量。

`create_design_1.tcl` 定义 DDR4、AXI interconnect、寄存器切片、时钟/复位连接和地址映射。standalone IP 参数在 `../ip/*.tcl`。所有 IP 输出路径采用 Vivado 默认值，不复制旧生成物，不要求目录位于 `build/`。
