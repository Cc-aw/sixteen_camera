# 当前已实现的视频采集与 AI 输入架构

> 历史基线说明：本文记录 2026-09-03 的“视频采集 + AI 输入”阶段，其中关于
> 单 worker、S02 tensor 写回和未接入推理 backend 的描述已过时。当前完整实现请以
> [`当前系统完整架构.md`](当前系统完整架构.md) 为准。

> 版本：1.0
> 日期：2026-09-03
> 平台：Xilinx Virtex UltraScale+ VU13P，Rocket RV64 控制 CPU
> 状态：以当前 RTL、裸机软件和仿真测试为准

## 1. 文档范围

本文记录工程中已经写入代码并完成接口验证的架构，不描述尚未签核的
Gemmini 推理实现，也不把后续 YOLOv5 推理当作当前功能。

已实现的功能边界是：

- 8 路 OV7670 本地视频输入；
- 4K HDMI transport 解包为另外 8 路 640x480 输入；
- 16 路 DDR 帧缓存、显示读取和 4x4 mosaic；
- CPU 通过 MMIO 获取原子帧快照并在处理完成后释放帧引用；
- DDR 时钟域硬件预处理，输出两种可选的 NHWC INT8 输入；
- 双 Tensor Arena、批量预处理完成通知和回收协议；
- 裸机软件对上述硬件的非阻塞控制和状态诊断。

当前不属于已实现功能：

- Gemmini 内部卷积/矩阵乘法实现及其正确性、性能签核；
- 640x480 输入下启动 TinyYOLOv2 推理；
- YOLOv5 模型执行、量化参数和最终后处理链路；
- 多 Gemmini 并行推理。

## 2. 顶层数据通路

```text
8 x OV7670 DVP (640x480 RGB565)
          |
          +-- camera clock/PCLK recovery, CDC, RGB stream normalization --+
                                                                            |
4K30 HDMI RGB888 2-PPC -- fixed 4x2 spatial demux (8 x 640x480) -----------+
                                                                            v
                         16 x normalized video streams
                                      |
                                      v
                         channel_write_fifo / AXI writer
                                      |
                                      v
                            DDR frame manager
                         (5 buffers/channel, default)
                           /          |          \
                          /           |           \
                    display       snapshot       writer
                      |              |             |
                      v              v             v
                 full/mosaic     CPU MMIO      next free buffer
                 AXI reader       metadata
                                      |
                                      v
                         batch_preprocess_engine
                         (DDR AXI S02, 2 Tensor Arenas)
                                      |
             +------------------------+------------------------+
             |                                                 |
       416x416x3 NHWC INT8                         640x480x3 NHWC INT8
       TinyYOLOv2 input contract                    later model input
```

### 2.1 输入通道

系统统一使用 16 个逻辑通道，软件编号为 CH1~CH16，RTL 内部编号为
CH0~CH15。

- CH0~CH7：OV7670 DVP 接收。摄像头前端完成 PCLK 恢复、HREF/VSYNC
  滤波、帧边界识别和时钟域转换。
- CH8~CH15：一路 3840x2160p30、RGB888、2 pixels/clock 的 HDMI transport
  经过固定空间裁剪，拆出 8 个 640x480 stream。裁剪协议见
  `doc/接口规范/8路640x480视频在4K30_HDMI中的空间封装规范.md`。
- 进入 `multi_channel_ddr_video_pipeline` 前，所有输入都已经位于 DDR
  时钟域的统一 stream 接口；该模块不再承担摄像头 PCLK CDC。

### 2.2 帧缓存和显示

`multi_channel_frame_manager` 为每个通道维护独立 buffer pool。默认配置为
640x480、XRGB8888、5 个 buffer/channel。每个 slot 有四种状态：

```text
FREE -> WRITING -> READY -> READING -> FREE
                    |
                    +-> AI hold (ai_ref) -> release -> FREE
```

写入端只取得 FREE slot；没有可用 slot 时报告 drop。显示端一次只借用一个
完整 buffer，配置为 mosaic 时由 `mosaic_frame_reader` 读取 16 路并输出
1920x1080p60 4x4 mosaic；调试模式可以切换到单路 full-frame reader。

帧管理器为每个 READY slot 保存 `frame_id`、时间戳和版本号。AI snapshot
取得的是这些已完成帧的引用，不复制图像数据，因此写入端不会覆盖正在被 AI
预处理读取的 slot。

## 3. 时钟域和 CDC

工程至少包含以下独立时钟域：摄像头 PCLK/恢复时钟、HDMI RX/transport
时钟、DDR UI 时钟、CPU AXI-Lite 时钟和 HDMI TX 时钟。

跨域控制采用两类机制：

1. 单比特请求/应答使用 toggle mailbox，再由 `xpm_cdc_single` 同步。适用于
   配置提交、snapshot、release、preprocess start/recycle 和 overlay commit。
2. 稳定载荷使用 `xpm_cdc_array_single` 同步。预处理配置为 129 bit，
   包含两个 arena base、member stride、member bytes 和格式位；释放 mask、
   arena 状态等也通过稳定数组同步。

AI 元数据不把全部 16 路的宽总线持续跨域，而是使用 indexed mailbox：CPU
写入 `META_INDEX` 后，DDR 域返回所选通道的地址、frame id、timestamp 和
version。

请求的 payload 在匹配 ack 之前保持稳定，软件在每次 MMIO 写后执行
`mmio_fence()`；硬件只在对应 busy 清除后接受下一次命令。

## 4. AI snapshot 协议

### 4.1 获取

软件调用 `ai_frame_snapshot_acquire()` 时：

1. 检查 snapshot/release 未忙；
2. 向 `FRAMEBUFFER_AI_CONTROL` 写 `SNAPSHOT`；
3. 等待 snapshot busy 清除并确认 active；
4. 读取 `batch_id`、valid mask、fresh mask；
5. 对 CH0~CH15 逐个读取 indexed metadata。

硬件在一次 capture 中锁定每个通道当前 latest READY slot，并置 `ai_ref`。
因此这一批的 frame address、frame id 和版本是一致的快照，即使摄像头继续
写入后续帧也不会改变本批输入。

### 4.2 释放

预处理完成后，软件将原始帧的 valid mask 写入
`FRAMEBUFFER_AI_RELEASE_MASK`，再写 `AI_CONTROL=RELEASE`。硬件清除对应
slot 的 `ai_ref`，软件等待 held mask 清除后才认为释放完成。无效通道不会
产生 DDR 读请求；预处理输出中相应 member 会被置零。

## 5. 硬件预处理

### 5.1 单帧加速器

`frame_preprocess_accel` 通过 256-bit AXI4 master 从 XRGB8888 源帧读取，按
32-byte beat 组织读写，并限制 burst 不跨 4 KiB 边界。目标数据是紧凑排列的
RGB 三通道 NHWC INT8：

```text
dst[(y * width + x) * 3 + 0] = R
dst[(y * width + x) * 3 + 1] = G
dst[(y * width + x) * 3 + 2] = B
```

源像素的无符号分量按当前模型约定压到非负 INT8 范围，硬件输出不带额外
row padding。

格式位在 start 时锁存，运行中不能改变：

| 格式 | 几何变换 | 单 member 字节数 | 用途 |
| --- | --- | ---: | --- |
| `0` | 640x480 -> 416x416 最近邻缩放 | 416 x 416 x 3 = 519168 | TinyYOLOv2 |
| `1` | 640x480 -> 640x480 1:1 | 640 x 480 x 3 = 921600 | 后续 YOLOv5 输入 |

416x416 模式使用整数 base step 加 remainder 累加器完成横纵坐标映射；
640x480 模式使用 1:1 步进。每行先在片上 row buffer 中完成 RGB 打包，再
以 AXI burst 写回目标 arena。

### 5.2 批量引擎和双 arena

`batch_preprocess_engine` 在一次 start 中接收完整 snapshot 的地址、有效
mask、fresh mask 和 batch id，并顺序复用一个单帧加速器处理最多 16 个 member。
它不是模型 Batch=16；每个 member 仍然是一个独立模型输入。

双 arena 位于设备侧 DDR：

```text
Arena 0: 0x30000000
Arena 1: 0x31000000
member stride: 当前格式的 member bytes
```

引擎只选择未 ready 且未 busy 的 arena。批次完成后置相应 ready bit，并锁存
batch id、valid/fresh mask、实际读写 beat 数和耗时。软件读取完成批次后，
通过 recycle mask 回收 arena；回收完成前该 arena 不会被覆写。

格式切换时软件同时更新 arena base、member stride、member bytes 和 format
寄存器。硬件拒绝未对齐、stride/bytes 不一致或与格式预期大小不一致的 start。

### 5.3 DDR 端口边界

DDR AXI Interconnect 的当前连接关系为：

```text
S00_AXI <- Rocket/SoC memory AXI
S01_AXI <- video writer (write channels) + display reader (read channels)
S02_AXI <- preprocess_axi
```

`S02_AXI` 给预处理器提供独立的 DDR 仲裁入口，使其可以直接读源帧并写 Tensor
Arena。它是普通 AXI4 数据端口，不是 CPU cache coherence 接口，也不表达
模型加速器的完成状态。预处理完成由 `batch_preprocess_engine` 的 done、ready
mask 和计数器协议报告；未来模型 backend 与 CPU cache 的一致性属于另一层
接口，不能由 `S02_AXI` 替代。

## 6. MMIO 编程接口

寄存器基址为 `FRAMEBUFFER_BASE = VIDEO_MMIO_BASE + 0x100000`。
以下偏移为 `platform.h` 中的实现值，均为 32-bit MMIO：

| 偏移 | 名称 | 说明 |
| ---: | --- | --- |
| 0x1c0 | `AI_CONTROL` | bit0 snapshot，bit1 release |
| 0x1c8 | `AI_RELEASE_MASK` | 要释放的通道 mask |
| 0x1cc/1d0/1d4 | valid/fresh/held mask | snapshot 和引用状态 |
| 0x1d8 | `AI_META_INDEX` | 选择 metadata 通道并触发 mailbox |
| 0x1dc~0x1f0 | metadata | 地址、frame id、timestamp、version |
| 0x200 | `PRE_CONTROL` | bit0 start，bit1 recycle |
| 0x204 | `PRE_STATUS` | start/recycle/engine busy，bit[4:3] ready mask |
| 0x208 | `PRE_RECYCLE_MASK` | arena bit0/bit1 回收选择 |
| 0x20c | `PRE_PROGRESS` | 当前通道进度 |
| 0x210 | `PRE_ACTIVE_BASE` | 当前运行 arena 的 tensor base |
| 0x220~0x23c | arena batch/mask | 两个 arena 的结果元数据 |
| 0x240~0x254 | preprocess stats | cycles、读写 beats、计数器和错误数 |
| 0x280/284 | arena base | Arena 0/1 设备地址 |
| 0x288/28c | stride/bytes | member 间距和有效字节数 |
| 0x290 | `PRE_FORMAT` | 0=416x416，1=640x480 |

所有配置寄存器只能在 preprocess 空闲且没有 start 命令 pending 时修改。
格式切换不会自动清空 ready arena；软件必须先停用 AI runtime，并等待现有
批次 drain/recycle 后再切换。

## 7. 裸机软件状态机

软件入口在 `sw/src/main.c`，预处理封装在 `ai_preprocess.c`，帧快照封装在
`ai_frame_snapshot.c`，批量调度在 `ai_batch_runtime.c`。

输入运行时的实际顺序为：

```text
IDLE
  -> snapshot acquire
  -> preprocess start/poll
  -> retain Tensor Arena metadata
  -> release source-frame snapshot
  -> submit model-backend request
  -> poll completion / publish result
  -> recycle Tensor Arena
  -> IDLE
```

当前软件编译配置只有一个 AI worker；backend 通过
`AiModelFrameRequest/AiModelFrameCompletion` 接口接入，输入地址使用设备
DDR 地址的 CPU alias。该接口是稳定边界，不代表 Gemmini 后端已经通过验证。

TinyYOLOv2 的输入契约固定为 416x416x3 INT8。因此：

- 默认启动格式是 416x416；
- `i` 命令在 640x480 格式下被拒绝；
- 运行时切到 640x480 会先要求停用并 drain，TinyYOLOv2 不会在该格式下提交；
- `f` 命令只在 runtime idle 时在两个格式之间切换。

串口命令如下：

| 命令 | 功能 |
| --- | --- |
| `s` | 打印视频、snapshot、预处理和 AI runtime 状态 |
| `a` | snapshot smoke test（仅 idle 时） |
| `p` | preprocess smoke test（仅 idle 时） |
| `f` | 切换 416x416 / 640x480 预处理格式 |
| `i` | 启停 AI input runtime；仅 416x416 允许启用 |
| `r` | 重启 HDMI/视频服务 |
| `b` | OV7670 BIST |
| `c` | 读取时钟芯片 ID |
| `h` 或 `?` | 打印帮助 |

## 8. 地址和容量

| 区域 | 设备地址 | 说明 |
| --- | ---: | --- |
| Arena 0 | `0x30000000` | 16 个 member 的输出区 |
| Arena 1 | `0x31000000` | 16 个 member 的输出区 |
| 模型输出区 | `0x32000000` | backend 自行管理，本文不定义内容 |
| CPU alias | `device_address | 0x80000000` | Rocket 访问同一 DDR 存储 |

416x416 模式每个 arena 实际使用约 7.92 MiB；640x480 模式每个 arena
实际使用约 14.06 MiB。两种模式都小于 16 MiB arena 地址间隔。

## 9. 已完成的验证

当前代码已经有以下可重复的验证证据：

- `TB_FRAME_PREPROCESS_ACCEL=PASS`，覆盖 416x416 和 640x480 两种格式；
- `TB_BATCH_PREPROCESS_ENGINE=PASS`，覆盖 arena 选择、ready/recycle、
  member 配置校验和批次完成；
- framebuffer AI MMIO 仿真覆盖默认格式、格式写入、busy 期间拒绝写入；
- `TEST_AI_BATCH_RUNTIME=PASS`；
- `TEST_AI_POSTPROCESS=PASS`；
- 按 Chipyard 环境初始化后执行 `make -C sw -j4` 通过。

这些测试证明的是视频/快照/预处理/软件接口的正确性，不等价于 Gemmini
模型推理已通过，也不等价于最终 FPGA 时序已经签核。

## 10. 当前已知限制和后续边界

1. 预处理引擎目前按 channel 顺序复用一个加速器，吞吐量受 16 个 member
   的总 DDR 读写量限制；这是确定性的功能实现，不是并行预处理架构。
2. 640x480 结果只定义了输入数据格式和内存协议，尚未绑定可运行的 YOLOv5
   backend。
3. Gemmini backend 的命令、完成和缓存一致性问题单独处理；在其验证完成前，
   不能据本文宣称 TinyYOLOv2 已完成板上推理。
4. 本文不修改 `demo/ai`，也不依赖其中的算法实现。
