# 当前 S1 软件架构

默认软件包 `sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank/` 自带模型、BSP 和运行工具。
`src/main.c` 初始化视频及 Runtime，循环调用 video_service_poll、rt_poll 和 UART 服务。
根目录 `make firmware` 与 `make -C sw` 均选择本包，旧 v26 默认入口已删除。

以下路径均相对本包：

| 层 | 位置 | 责任 |
| --- | --- | --- |
| 应用 | `src/main.c` | 连续运行、约 100 帧采样、串口、统计 |
| Core / Resources | `runtime/ai/runtime/` | Pipeline、job/Tensor/activation/Head 租约与状态 |
| Scheduler / Services | `runtime/ai/runtime/scheduler/`、`services/` | 16 路 latest-frame 调度、派发、结果及 overlay 生命周期 |
| Backend | `src/live_backend.inc` | S1 前端、IRQ13、三核执行、双 Head、PPU 结果身份 |
| Model | `model/`、`scripts/prepare_yolo.py` | 冻结算术、命令规划和生成 |
| HAL | `runtime/drivers/` | Tensor、完整帧计数和 overlay 协议 |
| BSP | `bsp/` | 板级时钟、IIC 与 AMD 视频驱动 |

软件每 100 ms 观察实际完整视频帧，候选输入最近 1 秒内有活动才接纳。
每帧从真实 Tensor 槽执行，六张运行命令表仅修补输入地址，保留原模型运算。
12 个 HOST 边界、DONE 计数和 ACK 完成后才释放计算资源；PPU 可继续持有独立 Head 槽。
结果通过 stream/frame/version、job 和 generation 验证后交给 Runtime，硬件负责绘制检测框。

停止时保留 READY Tensor，先让每路两槽填满、写响应排空，再关闭生产者并回收，
避免冻结硬件的中途取消错误。超时保留无法证明安全释放的资源并报告故障。
无新结果超过 3 秒且该通道没有在途任务时清除旧框。

默认连续推理。`board-live` 持续运行并捕获串口，Ctrl-C 请求排空；
`board-run` 自动发送 b，约 100 帧合计后停止。UART 使用 Python 标准库。
ELF/flags/源清单与匹配比特流 SHA 在下载前校验，离线与板测证据分开保存。
