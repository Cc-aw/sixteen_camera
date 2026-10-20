# sixteen_camera

Xilinx VU13P 十六路视频与 AI 平台。默认版本为 **DMA streaming + ASRAM S1，L2 512 KiB / 2 bank**：
1 Rocket、1 RVV、3 × DIM32 Gemmini，100 MHz，custom3 命令前端与 IRQ13。
八路 OV7670 与 HDMI 的八路空间复用输入组成十六路视频，实时 YOLO 推理通过硬件 PPU 叠加检测框。

S1 视频 Runtime 已由用户确认功能正常。归档的连续运行日志完成并发布 16,950 帧，软件 errors=0、fault=0。
硬件 ID `e037701c8d7cfc59`，比特流和软件绑定见 [当前身份](hw/manifests/current.json)。
旧默认的生成 SoC、生成源码和未适配实时固件已删除，可通过 Git 历史查询。

从仓库根目录执行：

```sh
make firmware
make program-bitstream RUN=s1_bit_01
make board-live RUN=s1_live_02 PORT=/dev/ttyACM0
# 约 100 帧合计采样：
make board-run RUN=s1_sample_01 PORT=/dev/ttyACM0
```

`board-live` 持续运行，Ctrl-C 安全停止并排空；`board-run` 约 100 帧后自动停止。
每次使用新的 RUN；日志保存在软件包的 logs/RUN/。串口不依赖 pyserial。
本机工具路径放在忽略的 `tools/config/tools.local.mk`。

```sh
make check
make check-deps
make test
make test-rtl RTL_RUN=rtl_acceptance_02
```

硬件保存在 [S1 硬件包](hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/README.md)，
固件保存在 [S1 视频 Runtime](sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank/README.md)。
根目录和 `make -C sw` 均使用该版本；原版本目录命令继续可用。
`make project / elaborate / synth / bitstream` 使用 S1 的板级 RTL、IP、约束和实现 hook。
重新构建的产物保存在私有 build/，不会覆盖已验证比特流。
导入实现 WNS −3.068 ns，未宣称时序收敛，也没有写 bitstream 前的时序门禁。

详见 [快速开始](docs/quickstart.md)、[当前验证记录](docs/validation/current.md)。
其他功能版本与独立板测包保留在 `hw/versions/`、`sw/board_tests/`；历史文档不作为默认构建说明。
