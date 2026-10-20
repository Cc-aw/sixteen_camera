# S1 DMA Stream + ASRAM 独立软件栈

硬件目录：`hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/`。
绑定导入硬件 ID `e037701c8d7cfc59` 及本地比特流 SHA256；目录选择目标，
不读取其他软件版本，也不允许改绑 ASRAM 父版。模型、启动、IRQ、驱动、PPU 和输入均本地冻结。

```sh
make all test preflight
make program-bitstream RUN=s1_bit_01
make board-run TEST=asram RUN=s1_asram_01
make board-run TEST=model RUN=s1_model_01
# 可选：完整 Head/PAD 逐字节对照；这份 ELF 的周期不用于性能结论。
make board-run TEST=diagnostic RUN=s1_raw_01
```

`board-run` 先采集 115200 串口再下载 ELF，默认 `/dev/ttyACM0`，可用 `PORT=` 指定。
也可使用 `make uart` 配合 `make program` / `program-model` / `program-diagnostic`。
下载由操作者执行；离线构建、预检和测试不会连接硬件。RUN 必须使用未占用的新名字。

默认 `YOLO_ROUNDS=1`：初始 DDR direct 基准 12 帧，加上 DDR/ASRAM × 三种执行器
共六个窗口，每窗口预热 3 帧、正式 12 帧，合计 **102 次推理**、6 个正式记录、7 个预热记录。
仅支持模式 2，默认复位即 read_assembled，能力字 `0x10004`。不运行原四模式循环。
命令行可显式指定 `YOLO_ROUNDS=2/3`；旧 shell 的同名环境变量不会覆盖默认值。

默认 `YOLO_SPPF_ASRAM=0`，便于同软件设置比较整版硬件收益；可用命令行设为 1 后重新构建。
三个 ELF 分别为 `activation_sram_test.elf`、`yolov5_asram_model.elf`、`yolov5_asram_diagnostic.elf`。
SRAM 诊断覆盖 15 个内存用例、108 个单模式 DMA 用例、一次三路并发和 12 次空洞拒绝。

```sh
make analyze TEST=model LOG=logs/s1_model_01/model.log
make analyze TEST=asram LOG=logs/s1_asram_01/asram.log
```

工具路径仅配置在忽略的 `config.local.mk`。当前实际验证范围见 `validation/status.json`；
供体旧板测结果不作为本包的上板证明。硬件实际仍有负时序，时序数据来自导入报告。
