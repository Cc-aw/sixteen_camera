# S1 默认版本快速开始

当前硬件/固件身份见 [current.json](../hw/manifests/current.json)。
在 `tools/config/tools.local.mk` 配置 TOOLCHAIN（或 CROSS）、VIVADO_BIN、OPENOCD_BIN、GDB_BIN，
必要时配置 GDB_PYTHONHOME、BOARD_JTAG_SERIAL；工具版本和路径示例见 `tools/config/tools.example.mk`。
使用 Vivado 2023.2、RV64GCV/LP64D 工具链、Python 3.10+、Verilator 和 Icarus Verilog。

仓库根目录：

```sh
make help
make check
make check-deps
make firmware
make preflight
make program-bitstream RUN=s1_bit_01
make board-live RUN=s1_live_02 PORT=/dev/ttyACM0
```

`preflight` 不连接板卡。比特流必须位于当前硬件包的 bitstream/top_wrapper.bit，SHA 与当前清单一致。
`board-live` 连续推理、UART 留档，Ctrl-C 安全停止并排空。约 100 帧合计验收使用：

```sh
make board-run RUN=s1_sample_01 PORT=/dev/ttyACM0
```

每次使用新的 RUN。日志和下载记录在当前软件包 logs/RUN/ 下。
串口单字符：s 停止、a 启动、t 汇总、v 通道统计、b 采样约 100 帧。
缺失输入通过视频完整帧计数动态剔除；只接本地 OV7670 时实际 mask=0xff。

离线验证：`make test` 运行固件构建、8 个 Runtime 场景、工具/HAL 单元测试及冻结 S1 采集 RTL；
`make test-rtl RTL_RUN=rtl_acceptance_02` 在新输出目录运行三路原生 Gemmini/ASRAM 数值仿真。
固定图片基准使用 `make benchmark`，独立入口见 `sw/board_tests/dma_load_streaming_asram_s1_512kib_2bank/`。

根目录 `make project / elaborate / synth / bitstream` 重建并运行 S1 Vivado 工程，
默认目录在 S1 包 build/production/；可使用 PROJECT_OUTPUT 选择该包 build/ 内的新目录。
`make soc SOC_WORKSPACE=<新目录> SOC_OUTPUT=<新目录>` 重新生成 SoC；两者均须位于 S1 包 build/ 下。
生成的新硬件/比特流保留在 build/，不会自动覆盖已验证产物或更改软件绑定。
导入实现 WNS −3.068 ns，未新增 write_bitstream 前的时序检查。
