# DMA Stream A1 + ASRAM 独立测试软件

对应硬件目录 `hw/versions/dma_load_streaming_asram_512kib_2bank/`。
本包从已板测的 ASRAM 软件复制，保留模型参数、输入、tiling 与 PPU 协议，
构建时不读取其他软件功能目录。当前硬件身份见 `hardware/target.json`。
父版本的比特流不能用于本包；本阶段只生成 RTL 和执行离线验证。

```sh
make bind-candidate DMA_CONTEXT=<本版GENERATION_CONTEXT.json>
make all
make test
make preflight
```

`bind-candidate` 校验完整生成 RTL 的 SHA256、合并版配置和参数头，并绑定真实新硬件 ID。
尚未生成 bitstream 时，目标哈希使用 null，不伪造有效比特流或继承父版本身份。
`preflight` 此时只审计离线固件；下载入口拒绝无比特流候选。
本地工具路径写入忽略的 `config.local.mk`。

三个 ELF：`activation_sram_test.elf` 为全容量标量/RVV/部分写、12 次空洞拒绝、
432 个四模式 DMA 搬运及三路提交诊断；`yolov5_asram_model.elf` 为正式 DDR/local
推理对照；`yolov5_asram_diagnostic.elf` 另逐字节核对完整 Head 和六次 PAD 输入。
HOST 完成回调、全部 guard、PPU 计数及全部 40 个结果字比较保持。

源码 host 测试使用显式假设备；它验证测试流程、完整计划和错误判据，不能证明
CPU/RVV 指令执行、真实 Gemmini 全网推理、板测正确性或性能。实际范围见
`validation/status.json`。时序及板测状态不继承父版本。
