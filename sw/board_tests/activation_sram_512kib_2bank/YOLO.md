# YOLOv5nu 推理移植与 DDR／ASRAM 对照

沿用 `dma_load_512kib_2bank` 的完整冻结模型、FP16 scale、DIM32 tiling、B reuse、
三张输入 025／036／142、六次原生 PAD/copy HOST、六次 Head HOST 和硬件 PPU。
复制的模型和权重在本目录 `model/`，原始 SHA 见 `SOURCE_ORIGINS.json`；构建不读取
其他板测目录。仅 activation arena 改用显式 CPU／DMA view，每 lane 逻辑容量
`0x21d680`；scratch、PAD／intermediate、权重、输入、命令表和 Head 保持原路径。

本包继续使用硬件 ID `e684b3d0484a9424` 的现有比特流。启动先核对全部 lane 的 ID、
frontend ABI、四种 DMA 模式和 ASRAM 能力页，再访问本地存储；不在未知旧硬件上
试探能力页。PMP 包含本地窗口，IRQ 单独以 `rv64gc` 编译，不修改正在执行的 RVV 状态。

## 两份整网 ELF

| 文件 | 用途 |
| --- | --- |
| `build/yolov5_asram_model.elf` | 同硬件周期／PPU 对照，原始字节诊断关闭 |
| `build/yolov5_asram_diagnostic.elf` | 每帧另逐字节核对完整 907,200 B Head 和六次 PAD 源，共 230,400 B；周期仅作诊断 |

两份程序先用 `ddr_arena + legacy + direct_serial` 跑 12 帧，保存不可覆盖的 PPU 黄金。
诊断 ELF 同时建立三图的原始 Head 与 PAD 源黄金，并检查重复帧是否一致。
之后运行以下完整矩阵：

- 两种 storage：`ddr_arena`、`local_arena`。
- 四种 DMA 模式：0 legacy、1 read_coalesced、2 read_assembled、3 spad_assembled。
- 三种 executor：0 direct_serial、1 frontend_serial、2 frontend_parallel。
- 每组合先预热 3 帧，正式执行 12 帧；并行分配为 4／4／4。

默认一轮，24 个正式窗口、25 个预热／黄金窗口，共 372 次 PPU 提交。可在构建时设置
`YOLO_ROUNDS=2` 或 `3`，同一会话编号始终递增；奇数轮反转 storage 顺序。
storage 切换要求 frontend、Gemmini、CPU／RVV、PPU 排空，重新绑定并重建全部 18 张
命令表；不热改已运行的表。所有 tensor 偏移及 RAW／DRAIN／HOST 均保留。

主机检查将两种 storage 的完整归一化表与原生 worker_start／worker_poll 生成的表
逐项比较，包含所有非地址操作数、阶段与 HOST 参数。每帧仍有 10,870 条表项、
10,478 RAW、462 Conv、224 WS、380 DRAIN 和 12 HOST。

CPU／RVV 发布通过已绑定的 `activation_memory_commit()` 完成回调，覆盖原生 HOST
PAD 产生的 DDR 写；具体硬件完成链见 [完成边界证据](validation/yolo_completion.md)。

## 构建、下载和日志

从仓库根目录执行，工具配置沿用本目录 `config.local.mk`：

```sh
make -C sw/board_tests/activation_sram_512kib_2bank test
make -C sw/board_tests/activation_sram_512kib_2bank preflight
```

可选重复次数须在构建和下载时保持一致，例如 `make ... all YOLO_ROUNDS=3`，随后
`make ... program-model YOLO_ROUNDS=3 RUN=yolo_03`。

已配置当前 `.bit` 且处于空闲时，先在终端 A 记录串口：

```sh
make -C sw/board_tests/activation_sram_512kib_2bank uart TEST=model RUN=yolo_01 PORT=/dev/ttyACM0
```

终端 B 加载整网对照 ELF：

```sh
make -C sw/board_tests/activation_sram_512kib_2bank program-model RUN=yolo_01
```

默认一轮的完整通过标志为：

```text
ASRY1,PASS,rounds=1,diagnostic=0,measured_records=24,warmup_records=25,ppu_runs=372,ppu_bit_exact=1,guards=1
```

收到 PASS／FAIL 后退出 tio，再解析：

```sh
make -C sw/board_tests/activation_sram_512kib_2bank analyze TEST=model LOG=logs/yolo_01/model.log
```

运行原始字节诊断时，使用新的 RUN、`uart TEST=diagnostic`、`program-diagnostic` 和
`analyze TEST=diagnostic LOG=logs/<RUN>/diagnostic.log`。下载同时保存对应 manifest，
便于后续构建更新后仍解析旧日志；原有 `program` 仍下载 ASRAM 通路小 ELF。

上次 FAIL／TRAP 或中断运行后，先 `program-bitstream RUN=<新的标识>` 重置状态。
软件移植不要求重新综合／实现比特流。

## 判定、计时与限制

全部帧比较 PPU 检测数量和全部 40 个结果字，包括 direct_serial 的重复运行；发现差异
保留逐字 expected／actual 和失败批次计数。诊断 ELF 另检查全部原始 Head 字节及六次
PAD 输入，覆盖一部分中间激活，并不等于逐一比较全部中间 tensor。

每窗口在准备／清零／建表之后开始计时，到所有 PPU 结果收回结束；包含启动、尾部、
HOST、PPU 和调度。比较、UART、计数器读取与 guard 检查在计时之后；诊断 ELF 的
原始字节读取在运行中，因此单独标成 `DIAGNOSTIC_ONLY`，不能作为正式性能样本。
准备周期单独报告，两种 storage 使用相同边界。

每批输出三 lane 的 Gemmini 8～34 计数和 ASRAM 两端口各 20 个计数。
local 模式必须有本 lane DMA Get／Put 和 CPU／RVV 服务 Get，错误与 outstanding 均
为零；DDR 模式以及未使用 lane 必须没有本地请求。所有逻辑 arena 都完整初始化；
DDR 两侧 64 B guard、本地从逻辑末端到物理容量末端的全部 141,696 B guard 均检查。
guard 检查在计数快照后完成，不混入模型流量或性能。

离线的 `build/activation_access_inventory.json` 记录阶段、原生命令地址、tensor 别名、
六次 HOST 完整范围及可解码的普通 DMA 跨距范围。LoopConv／LoopWS 尚未展开的聚合
访问跨度明确标成 unknown；这份计划清单不是逐周期流量，也不据此计算精确 DDR 节省。

正式日志必须完整覆盖所有帧、模式、executor、两种 storage、计数器与单调编号，
仅有 PASS 一行不接受。主机假设备日志带 `hardware=0`，正式解析拒绝。
数值对照均相对同模型的 DDR direct 路径，不能证明独立检测精度。当前负时序余量
及历史 DMA 候选的偶发数值差异仍须通过这版整网板测和重复运行评估，不预设提速。
