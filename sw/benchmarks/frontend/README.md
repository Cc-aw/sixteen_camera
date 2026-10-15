# V33 自主前端三图基准

独立裸机入口，复现供体 V33；不适配或链接当前实时 Runtime。网络、权重、分块及 FP16 命令保留冻结 v32 计算基线，执行控制使用 V33 的命令表、IRQ13 和 HOST/DONE。

从仓库根执行：

```bash
make benchmark
make test-v33
make check-v33-firmware
make program-benchmark PROGRAM_ARGS=--check
```

`make benchmark` 同时生成正式版与 V33 诊断版，不含 V34 边界/访存诊断：

| 产物 | 路径 |
| --- | --- |
| 正式版 | `build/firmware/frontend/yolov5_three_way_12.elf` |
| 诊断版 | `build/firmware/frontend/yolov5_frontend_diag_12.elf` |
| 配对与输入哈希 | `build/firmware/frontend/frontend_manifest.json` |
| 派生图和参数 | `build/firmware/frontend/generated/` |

工具使用根 `tools/config/tools.local.mk` 的 TOOLCHAIN；独立 Make 可用 CROSS 覆盖。编译目标 RV64GCV/LP64D，IRQ 单独按 RV64GC 编译。入口 `0x82000000`，链接范围到 `0xa0000000`，启动配置 M-mode/PMP 和中断入口；不初始化摄像头或显示。

启动后自动运行 `direct_serial`、`frontend_serial`、`frontend_parallel`，每组12帧，共36帧，图片025/036/142循环。前两组只用物理 lane0，三路组每路4帧。custom0/1/2 对应物理 lane0/1/2，custom3 是控制；这与实时 Runtime 的既有逻辑 worker 编号不同，不能套用旧 custom3/2/1 映射。

初始化建立 `3 lanes × 2 Head slots × 3 images` 的18张只读表。每帧10870项：10478 RAW、380 DRAIN、12 HOST。HOST 包括6次原生池化填充和6次检测头发布；CPU 发布写入后按标签 RESUME，DONE 核对游标和命令数后 ACK。每路等全图及 PPU 结果完成后再接下一帧，三路之间没有批次屏障。

正式版与诊断版执行相同计算和调度，诊断增加 HOST/PPU 服务时间观测。两版都逐帧比较检测数和10槽全部40个PPU结果字，输出三组周期及比值；不声明原始 Head 逐字节相等或独立检测精度，当前仓库板测尚未执行。

串口115200 8N1。保存完整串口日志后：

```bash
python3 tools/analyze/frontend/analyze_log.py uart.log --json result.json --report result.txt
```

解析器拒绝缺行、重复行、错误配额、时序边界和伪PASS。成功标志 `ATSOFT1,PASS,modes=3,...,marker=ALL_COMPLETE`。

用户先加载匹配的前端 bitstream，然后可用 `make program-benchmark` 下载正式版，或 `make program-benchmark PROGRAM_ARGS=--diagnostic` 下载诊断版。此入口复用本仓库 OpenOCD/GDB，只下载软件；`--check` 不访问开发板。实时视频的 `make firmware` / `make program` 仍受未适配 Runtime 的 ABI 保护。

模型输入通过 `sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json` 锁定，字节相同的公共输入和权重复用当前目录，其余 v32 快照保存在该冻结目录。构建仅从本仓库重建 `build/firmware/frontend/native/`，不读取供体、不提交历史 ELF，也不沿用供体的过期构建清单。PPU 的原生队列/发布小模块作为 V33 冻结执行契约保留，不替换当前 Runtime 的设备分层。

详细来源见 `IMPORT_MANIFEST.json`，验收见 [v33-frontend.md](../../../docs/validation/v33-frontend.md)。
