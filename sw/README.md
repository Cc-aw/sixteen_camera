# 当前裸机软件

默认固件是已验证的 [S1 实时视频 Runtime](video_runtime/dma_load_streaming_asram_s1_512kib_2bank/README.md)，
匹配硬件 ID `e037701c8d7cfc59`。三路 Gemmini 使用 custom0/1/2，custom3 前端控制、IRQ13；
ASRAM 保存激活，实时 Tensor 输入，六个 Head 槽归硬件 PPU 管理。SPPF 临时缓冲仍使用已验证的 DDR 配置。

仓库根目录 `make firmware`，或本目录 `make all`，均构建
`sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank/build/s1_video_runtime.elf`。
`make program-bitstream` 下载匹配 S1 比特流；`make board-live RUN=<新名称> PORT=/dev/ttyACM0`
加载软件并持续采集 UART，Ctrl-C 停止排空。`make board-run` 仅采样约 100 帧合计。

旧默认 `src/`、链接脚本和 v26 构建实现已移除。新软件包独立包含 runtime、BSP、模型、下载工具和测试。
`models/`、`third_party/` 和 `benchmarks/` 是历史独立基准的共享输入，不参与默认固件构建。
`board_tests/` 保留各硬件版本的独立诊断软件。
