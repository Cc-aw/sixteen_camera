# 当前地址与可见性

权威常量为 [platform.h](../../sw/src/platform/platform.h)、[cache_ops.h](../../sw/src/platform/cache_ops.h)、SoC 生成参数和 `sw/linker_ai_video.ld`。
本表记录现有 ABI，不重新分配地址。

| 地址或范围 | 用途 |
| --- | --- |
| `0x10020000` | UART |
| `0x10040000` | CPU 可见视频 MMIO 窗口 |
| `0x10140000` | framebuffer/Tensor/overlay CSR 基址 |
| `0x10170000` | 后处理/PPU 诊断 CSR 基址 |
| `0x02010200` | Flush64 |
| `0x02012000` | SoC TensorIngress CSR |
| `0x02020000` | MemoryParallelV3 统计 CSR |
| `0x30000000`、`0x31000000` | 两个 Tensor arena，各 16 × 921600 字节 |
| `0x32000000 + worker × 0x00400000` | worker 输出/Head arena，设备侧地址 |
| `0x32200000` | worker0 输出 arena 上半部的带宽诊断区 |
| `0x80000000` 起、长度 512 MiB | 链接脚本规定的固件映像区；栈预留位于区间顶部 |

设备地址与 CPU alias 不能混用：CPU DDR alias 通过 OR `0x80000000` 构造，cache line 为 64 字节。
每个 worker 有两个 Head 槽，stride 为 1 MiB，每槽有效 payload 907200 字节。
六个 raw tensor 的偏移及 64 字节边界由 [Head layout](../../sw/models/yolov5nu/include/runtime/yolov5nu_head_layout.h) 定义。

当前 V3 Tensor READY 证明写响应之后的 L2 可见性，不证明已回写 DDR。
CPU fence、Flush64、PPU ordered readback 和 accelerator accepted/retired/local completion 各有责任，不能互相替代完成证明。
cache alias、内存布局、MMIO 顺序和故障保留策略在本轮重构中不变。
