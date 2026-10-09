# IP 重建 Tcl

十个脚本由现有配置经 Vivado 2023.2 `write_ip_tcl` 导出，保留 IP VLNV、模块名和用户参数。脚本需要已打开的 Vivado 工程，使用 `create_ip` 默认生成位置；已有同名、同版本 IP 会重用并设置对应用户参数。

完整底座由 `../vivado/setup_vivado.tcl` 按 `../manifests/ip_manifest.tcl` 创建 IP 并生成输出。单独集成某个 IP 时，在自己的工程内 source 对应脚本，再运行 `generate_target all [get_ips <名称>]`。

本地旧 IP 目录可以继续保留，目录已加入 Git 忽略。XCI、HDL 包装、厂商源码、仿真网表和综合输出均由 Vivado 重新生成，不作为仓库交付内容。
