# S1 实时视频 Runtime

将已上板验证的 S1 DMA mode 2 + 3 路私有 ASRAM YOLO 软件接入视频 Runtime。
本包现为项目默认软件，根目录 `make firmware / program-bitstream / board-live / board-run` 均调用这里。
软件独立冻结在本目录；构建不读取其他板测包。硬件仍使用
`hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/bitstream/top_wrapper.bit`，
硬件 ID `e037701c8d7cfc59`，不需要重新综合。

## 上板命令

从仓库根目录进入：

```sh
cd sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank
make all
make program-bitstream RUN=video_bit_01
make board-live RUN=video_live_01 PORT=/dev/ttyACM0
```

`board-live` 持续推理并采集日志，按 Ctrl-C 后排空并停止。它不会自动发送 100 帧采样命令。

只做约 100 帧验收时使用：

```sh
make board-run RUN=video_01 PORT=/dev/ttyACM0
```

`board-run` 使用 Python 标准库 `termios/select`，不需要安装 `pyserial`；串口会独占打开，退出时恢复终端设置。

`board-run` 先打开串口再加载 `build/s1_video_runtime.elf`，自动发送 `b`，
完成约 100 帧实时推理后停止接纳并排空已提交任务。
这里的 100 是所有通道合计的推理数，不是每路 100 帧；正常情况下数秒后自动停止。
三核在途任务可能使最终数量略多于 100。日志位于 `logs/video_01/video.log`，
汇总位于 `logs/video_01/result.json`。每次测试使用新 RUN。
`make all/test/check/preflight` 均不连接板卡；下载操作仅由显式 program/board-run 发起。

第一次从原固定图片 benchmark 切换时先重新下载同一个 S1 比特流，
清空原有 PPU 队列、发布状态和帧身份。异常停机后也应重新下载。
普通 `s` 停止完成后可用 `a` 继续，无需重新下载。
旧软件在捕获中途直接关闭生产者会触发冻结 S1 RTL 的取消错误，ERROR 会被持续重置而无法释放。
若旧日志已有反复增长的 `last_error_magnitude=50`，先重新下载同一比特流清空该状态，再加载新软件。
新停止流程会先保留 READY 槽，让采集自然填满每路两组缓冲并排空写响应，随后关闭生产者并回收。
若采集不能在 3 秒内完成此过程，则报告故障并保留生产状态，不以强制取消冒充成功排空。

持续看 HDMI 画面时，用两个终端：

```sh
# 终端一：采集日志并发送单字符命令
make uart RUN=video_live_01 PORT=/dev/ttyACM0
# 终端二：下载实时软件
make program RUN=video_live_01
```

默认连续运行。串口命令：`s` 停止并排空、`a` 重新启动、`t` 汇总、
`v` 查看 16 路帧数与检测数、`b` 再采样约 100 帧后停止。
HDMI 输出沿用原有 4×4 拼接画面和硬件 PPU overlay。
本地 OV7670 为 stream 0–7；HDMI 4K30 空间复用输入为 stream 8–15。
无 HDMI 输入时仍可验证已接的 OV7670。`VIDEO_STREAM_MASK` 是允许接纳的候选集合，默认 `0xffff`。
软件每 100 ms 观察 16 路视频完成帧计数，只接纳最近 1 秒内有新完整帧的通道；
因此只接本地 8 路时实际掩码为 `0xff`，未接入的 HDMI 不占采集许可。
热插拔或断流改变实际集合时，软件先停止接纳、等待采集进入安全状态并排空 Tensor/Head 所有权，再配置新掩码并恢复。
可用 `make all VIDEO_STREAM_MASK=0xff` 固定候选集合为本地 8 路。
`STATS` 的 capture_mask/admission_mask/hw_admission/hw_control 用于对照实际采集状态。

## 接入方式

- 保留现有 `rt_poll()`、16 路 latest-frame 调度、Tensor 元数据验证和停止排空逻辑。
- 新增 S1 `AiRtBackendOps`，使用 custom3 命令前端、IRQ13 和三个 DIM32 Gemmini。
- 规划阶段保留原 YOLO 数学计算与 10870 条命令；每帧只修改输入地址字段，直接读取实时 Tensor 槽，不复制固定图片。
- 计算的 12 个 HOST 边界完成、DONE 计数验证及 ACK 后，才向 Runtime 提供计算完成证明，释放 Tensor/激活区。
- 每核两个 Head 槽独立归 PPU 所有；按真实 stream/frame/version 和硬件 generation 校验结果，回收后发布 Runtime 结果。
- 最近 3 秒没有新推理结果且没有在途任务时，清除该通道的旧框；输入恢复后新结果重新绘制。
- 异常保留所有无法证明停止的资源；不将超时视为完成。
- 激活区使用 ASRAM；SPPF 临时缓冲保持 S1 板测默认 DDR 配置。模型权重及算术未改变。
- ELF 链接区间为 `0x82000000–0x87ffffff`，避开 `0x88000000` 起的视频帧缓冲 CPU 别名；作为默认生产软件入口；S1 固定图片板测包独立保留。

## 离线验证与板测判据

```sh
make test
make preflight
# 单独运行冻结 S1 采集 RTL 的缺失输入回归
make test-input-rtl
```

Host 测试链接实际规划器、S1 backend 和视频 Runtime，只替换设备层：覆盖
6 张运行命令表 × 32 个输入槽的原模型命令一致性、16 路真实帧身份、三核并发、
双 Head 背压、PPU 延迟期间输入释放、停止/排空/重启，以及元数据、generation、
PPU 错误和前端故障时的资源保留。另覆盖通道断开/重连时排空重配、运行期间旧框清除，
以及真实 Tensor HAL 对完整帧计数、过期和候选掩码的处理。Host mock 不代表硬件运算或实际识别准确率。

冻结 S1 采集 RTL 回归保留 16 通道和单许可，只给前 8 路输入：全掩码会保留空闲 HDMI
的许可而停滞，限制为实际输入掩码后可持续生产超过 32 帧。仅使用缩小帧形状加速协议测试，
不代替真实 640×480 输入与识别准确率的板测。
同一冻结 RTL 回归还验证“填满槽后停止”可完整回收，并复现旧的中途取消后 ERROR 无法释放问题。

板上应出现 `S1RT,READY`，随后 `STATS` 中 completed/published 增长、errors=0；
采样完成出现 `SAMPLE_END`，idle=1、held_tensor=0、heads=0。
同时观察 HDMI 拼接画面和检测框是否跟随实时输入。只有实际有输入的通道应有推理计数。
用户已确认功能正常。归档的 `s1_live_01` 连续日志完成/发布 16,950 帧，软件 errors=0、fault=0，
实际输入掩码 0xff；证据见 `validation/board_s1_live_01.json`。未把历史失败日志或 Host mock 计作板上通过证据。

分析日志：`make analyze LOG=logs/video_01/video.log`。
采样判据还要求 ASRAM 尾部保护区检查通过。
