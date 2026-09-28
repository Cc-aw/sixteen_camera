# 100 MHz 三 worker 视频工程

生成器与 RTL 基线提交为 `56e7383`。当前 `build/soc_manifest.tcl` 选择
`TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig`，顶层名称仍为
`TaihangSoCFPGATestHarness`。视频、PPU 和 SoC 保持 100 MHz SoC 接口配置。

## Worker 与 Head 槽

软件逻辑 worker 编号沿用原有 custom3/custom2 顺序，新增 custom1：

| 软件 worker | 指令 | busy CSR | credit/status | accepted / retired | A / B 物理地址 | bank |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | custom3 | 0x7c2 | 0x7c4 | 0x7c6 / 0x7c7 | 0x32000000 / 0x32100000 | 0 / 1 |
| 1 | custom2 | 0x7c3 | 0x7c5 | 0x7c8 / 0x7c9 | 0x32400000 / 0x32500000 | 2 / 3 |
| 2 | custom1 | 0x7ca | 0x7cb | 0x7cc / 0x7cd | 0x32800000 / 0x32900000 | 4 / 5 |

每槽 1 MiB，共六槽，综合推断为 192 个 URAM288。CPU 的 `0xb...` 地址别名
与表中设备物理地址对应。诊断区间仍送 DDR，bank 6/7 不能分配或读取。
生产模式使用本地 URAM，DDR shadow 模式仍有仿真覆盖。

publication manager、CSR、gate、local reader bank、descriptor 和结果回读
均保留完整的三位 bank。descriptor 增至 365 位：原字段位置不变，bit 364
存 bank 高位；结果 record 的 bit 1542 对应此高位。寄存器 `0x250` 返回完整
bank 0～5。命令 FIFO 深度增至六；结果 FIFO 保留背压，CPU 慢读不覆盖结果。

三 worker 分别拥有激活缓冲区和计算状态。计算完成可释放 worker，PPU 继续消费
它之前提交的 Head 槽；槽由 generation/lease 管理，处理结束后才允许复用。

## 固件

```bash
python3 scripts/build_triple64_video_yolov5nu.py
bash scripts/download_triple64_video.sh --check
```

输出为 `sw/build/gemmini_triple64_video_yolov5nu.elf`。`sw/run.sh`、
`download_software.sh` 默认选择 triple64。下载前需先生成并烧写匹配的新 bitstream；
本次操作未连接开发板、未下载软件或 bitstream。

`make -C sw` 默认构建 triple64 YOLOv5nu。旧 single4/dual16 构建脚本仍可用，
分别使用独立构建目录和对应的参数头。triple64 入口不支持旧 YOLOv2 后端。

三路固件使用已生成 RTL 附带的 DIM64 参数头，以及 0918 软件层的 FP16 缩放编码、
三路 custom 指令和 credit CSR 分派。不能只替换 DIM 宏而继续使用原 FP32 缩放编码。
Split-K 的 J 尾块按实际输出通道数设置 padding，支持 DIM64 下的 32/80 等非整块通道。

`generate_runtime.py` 同步保留三 worker 分派、profiling 与每个 Head 的发布回调；
重新生成结果与当前 `.c` 一致。`worker_profile.c.inc` 是生成器使用的 profiling 模板。
历史 `dim16_dual` API/文件名保留，实际 DIM 和 worker 数由构建配置决定。

## 已执行验证

- Scala/RTL 的三 worker 结构、AXI 宽度与 FBus 32 组 ID 检查通过。
- 六槽 publication 全链路通过：36 个 Head、85,050 个 cache line、37,800 个分类位置。
- publication 的 generation、abort、错误和 reset 回归通过；bank 6/7 拒绝测试通过。
- 六槽 router 的本地读、CPU 物理地址/别名、DDR 旁路和 shadow 模式测试通过。
- 命令/结果 FIFO、慢消费者和完整标签测试通过。
- 软件六槽分配回收、publication MMIO bank 4/5、三 worker 调度测试通过。
  第三路计算完成后可在旧结果未回收时承接新任务。
- triple64、single4、dual16 视频 ELF 编译通过，默认下载入口 `--check` 通过。
- 六槽 router 的 Vivado 2023.2 独立综合通过：192 URAM、0 BRAM，100 MHz
  综合 WNS +6.765 ns。此数据仅对应 router，不代表整机布线时序。

尚未完成整机 place/route、bitstream 生成和板上推理验证。0918 使用 FP16 缩放，
现有 image025 的旧 DIM16 bit-exact 参考值仍作为严格回归，未替换为未经实测的新值；
需在板上核对三路结果以及与旧参考之间的量化差异。串口验证脚本默认检查三路，
缺少任意一路结果不能判 PASS；旧镜像使用 `--workers 1` 或 `--workers 2`。

整机 `check_postprocess_elaboration.tcl` 已完成网表生成和 XDC 解析，
`POSTPROCESS_TOP_ELABORATION=PASS`，耗时约 13 分 28 秒。
本轮日志为 `/tmp/three-worker-top-elab.log`。日志包含未改动的视频模块
`video_memory_ports.sv` 的未用 AXI 返回通道多驱动警告、HDMI IP 常量网警告，
以及原 `camera_video_clk` 对自动派生时钟的覆盖警告。它们尚未在本轮消除，
最终实现时需检查 DRC，不能将“网表可生成”视为整机无警告或时序已收敛。
