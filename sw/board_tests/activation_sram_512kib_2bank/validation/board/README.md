# ASRAM 板测归档

硬件 ID：`e684b3d0484a9424`，100 MHz，512 KiB / 2 bank L2。
比特流 SHA256：`539bce5ed42429ca07a4a5c125e533e5aad2cf06599dc9ef934bfdcc63d894b0`。
下载记录见 [programmed_bitstream.json](programmed_bitstream.json)，物理实现报告见
[硬件验证目录](../../../../../hw/versions/activation_sram_512kib_2bank/validation/physical_04/)。
WNS 为 -3.100 ns，WHS 为 0.000 ns；功能板测通过不等于时序收敛。

`asram_02`：schema 2 的真实板测通过，覆盖 15 项存储测试、432 项四模式 DMA
搬运、4 项三路并行和 12 次空洞拒绝。软件 ID 为
`52ec2f0ae01ed649dfef115f01fd48c49c6ccffaacbc31e92aa0e68a1634342c`。
原始日志见 [asram.txt](asram_02/asram.txt)，对应 ELF 身份保存在 manifest 和 load 记录。
该诊断性能不能代替整网性能。历史 `asram_01` 的同步 CPU trap 断言失败分析仍保留在
[诊断记录](../asram_01_diagnosis.md)。

`yolo_01`：完整 YOLOv5nu DDR/ASRAM、四种 DMA 模式、三种执行器的真实板测通过。
软件 ID 为 `83a191f5a6cd5b2a6dbad2a6a2fc0a1b5559ecc7a3327fa8f93c6e6355696cb5`。
24 个正式窗口共 288 帧，基准与预热 84 帧，总共 372 次 PPU 运行。
检测数量和全部 40 个结果字对照初始 DDR legacy direct 基准一致，guard 检查通过。
完整日志见 [model.txt](yolo_01/model.txt)，计算结果见
[model.analysis.json](yolo_01/model.analysis.json)。

前端执行器结果如下，单位 ms/帧；三路列是 12 帧批次总时间除以 12 的吞吐摊销，
不是单帧延迟。计时包含启动、HOST、PPU、调度和尾部，准备及比较等在计时之外。

| DMA 模式 | DDR 串行 | ASRAM 串行 | DDR 三路 | ASRAM 三路 |
| --- | ---: | ---: | ---: | ---: |
| legacy | 92.52 | 90.51 | 36.29 | 30.88 |
| read_coalesced | 96.68 | 94.44 | 36.97 | 31.90 |
| read_assembled | 79.27 | 76.99 | 31.36 | 26.12 |
| spad_assembled | 84.58 | 82.32 | 33.43 | 27.97 |

最佳 ASRAM 三路吞吐为 38.28 FPS，相比同模式 DDR 为 1.2006 倍；
ASRAM 三路相对串行扩展为 2.9472 倍，DDR 为 2.5276 倍。
这是单轮、每窗口 12 帧、三张输入重复运行的结果，没有统计误差或长期稳定性结论。
本次 `diagnostic=0`，原始 Head/PAD 字节诊断尚未板测；独立检测精度没有验证。
DMA/ASRAM 接口计数不等于外部 DDR 实际流量。

从仓库根目录重验归档日志：

```sh
python3 -B sw/board_tests/activation_sram_512kib_2bank/scripts/analyze.py \
  sw/board_tests/activation_sram_512kib_2bank/validation/board/asram_02/asram.txt
python3 -B sw/board_tests/activation_sram_512kib_2bank/scripts/analyze_yolo.py \
  sw/board_tests/activation_sram_512kib_2bank/validation/board/yolo_01/model.txt
```

串口原始字节保留，文件后缀由 `.log` 改为 `.txt` 以归档；路径映射、字节数和 SHA256
见 [archives.json](archives.json)。ELF、比特流和生成工程留在本地忽略的输出目录。
`validation/offline*.json`、`yolo_offline.json` 和构建 manifest 的 `NOT_RUN` 是构建时快照，
本目录记录其后完成的板测结果，不修改历史构建身份。
