# RISC-V BSCAN 下载配置

`openocd-bscan.cfg` 复制自已验证的 Chipyard myboard OpenOCD 配置，保留 FTDI、24-bit JTAG IR、BSCAN tunnel 和 DDR work area 设置。适配器序列号改为可选的 `BOARD_JTAG_SERIAL` 环境变量。

`load-hdmi-tx.gdb` 来自本工程原 `sw/openocd/`，连接 localhost:3333，加载 ELF 后从 `_start` 启动。工具需支持这里使用的 RISC-V BSCAN 命令；可在 `tools/config/tools.local.mk` 指定已安装的 OpenOCD/GDB。
