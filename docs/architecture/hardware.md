# 当前 S1 硬件架构

默认别名 `dma_load_streaming_asram_s1_512kib_2bank`，硬件 ID `e037701c8d7cfc59`。
Config 为 `TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankDmaLoadConfig`。
正式路径由 [current.json](../../hw/manifests/current.json) 选择，顶层位于 S1 包 `board/rtl/top_wrapper.sv`。

八路 OV7670 与一路 4K30 HDMI 中封装的八路图像组成十六路输入，
RGB565 framebuffer 经 mosaic、硬件 overlay 输出 1920×1080p60。
AI 独立产生 640×480×3 NHWC RGB INT8 Tensor，每帧 921600 字节，每路两个槽，共 32 槽。

Rocket + RVV 与三颗 DIM32 Gemmini 工作在 100 MHz；custom3 控制三路自主命令前端，IRQ13。
物理 lane 0/1/2 对应 custom0/1/2，前端 FIFO 8、命令 Get 32 B。
L2 为 512 KiB / 2 bank，每 bank 8 way、512 set、64 B line，secondary entries 34。
S1 包含 ListBuffer 头/后继缓存、Scheduler 局部标签和 MSHR 并行预解码仲裁优化。

DMA 固定 mode 2（read_assembled）、能力字 0x10004、row_ready_v1 流式回放。
三路 ASRAM 各 2.25 MiB，保存模型激活；SPPF 软件临时缓冲仍位于 DDR。
每核两个 Head 槽，计算完成后可由 PPU 独立持有，不能随计算 worker 提前释放。
PPU 验证发布身份、generation、收据，检测结果经硬件 overlay 绘制到视频。

S1 包独立冻结 `source/`、`generated/`、`board/` 和实现 hook。根目录构建直接复用该包，
旧默认 SoC 导出及源已删除。导入实现 URAM 588、route errors=0、WNS −3.068 ns、WHS +0.001 ns。
负时序板测与离线验证分开记录，见 [当前验收](../validation/current.md)。
