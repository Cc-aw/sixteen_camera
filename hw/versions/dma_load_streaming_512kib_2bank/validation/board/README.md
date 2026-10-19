# 流式 DMA 板测 Make 入口

该入口使用已审计的硬件 `180342787f3e6dac`、恢复生成的比特流和配套诊断 ELF。
它位于验证目录，便于保持原始生成来源、被测软件及 ELF 哈希不变。不会重新生成硬件
或编译软件。工具路径默认读取仓库 `tools/config/tools.local.mk`，也可用当前目录
`config.local.mk` 或 Make 命令行变量覆盖。

两个终端均进入本目录：

```sh
cd /mnt/data/wzr/13p/ov7670/sixteen_camera/hw/versions/dma_load_streaming_512kib_2bank/validation/board
```

先在终端 B 预检并下载比特流（已下载这一版时可跳过下载）：

```sh
make preflight
make program-bitstream RUN=streaming_01
```

终端 A 先录制首层测试，终端 B 再启动首层 ELF：

```sh
# 终端 A
make uart TEST=first RUN=streaming_01 PORT=/dev/ttyACM0
# 终端 B
make program-first
```

等待 `DMALF1,PASS,...` 后，终端 A 按 Ctrl+T、Q 结束录制，再分析：

```sh
make analyze TEST=first RUN=streaming_01
```

首层通过后，同样测试整网：

```sh
# 终端 A
make uart TEST=model RUN=streaming_01 PORT=/dev/ttyACM0
# 终端 B
make program-model
```

等待 `DMAL1,PASS,...` 后退出串口，再执行：

```sh
make analyze TEST=model RUN=streaming_01
```

日志及分析报告在 `logs/streaming_01/`。同一测试再次录制须换新的 RUN，防止覆盖旧日志。
分析核对硬件及软件身份、四模式/schema 2、完整测试顺序、输出比较、计数器和统计值；
拒绝失败、身份不符、缺失或截断的日志。解析器复制来源及哈希见 `SOURCE_ORIGINS.json`。

`preflight` 和 `check` 只做离线检查；`program-*` 才连接 JTAG；`uart` 打开串口。
下载脚本退出表示 ELF 已启动，以串口完整 PASS 和分析通过作为本次板测结果。
比特流当前 WNS 为 -5.403 ns，时序未收敛，板测结果单独记录。

JTAG 下载使用本目录 `program/` 中的临时 `hw_server`，自动选择本机空闲端口，
退出时清理自己创建的服务进程组。Digilent IPC 兼容库只加载到该服务，处理
`/tmp/digilent-adept2-*` 已有普通文件跨用户打开时的兼容问题，不删除 IPC 文件或
修改系统保护设置。此方案沿用旧 DMA 板测目录已验证的实现。
下载日志为 `logs/<RUN>/vivado_program.log`、`hw_server.log` 和 `digilent_adept.log`。
出现 `No Vivado hardware target found` 时先保留这三份日志，再检查 USB/JTAG 连接。
