# Tensor、Head、PPU 与 overlay

设备 HAL 位于 `sw/src/drivers/`，资源所有权位于 `sw/src/ai/runtime/resources/`，后处理由 `services/rt_postprocess_service.c` 管理。

Tensor 有 32 个槽。描述符包含 tensor 地址、stream/frame/timestamp/version、字节数、状态和错误码。
HAL 只接受稳定 READY 元数据，读取失败不修改输出；release 需要 ack。超时后的观察和重发受原身份检查约束，不能因为调用返回就推断 consumer 已停止。
每帧的 job、Tensor lease 和 activation 所有权分别管理；生产者开关和 release 顺序保持现有实现。

三个 worker 各有两个 Head 槽。六个 raw tensor 的有效位按局部完成发布，整图完成后才进入 PPU 队列。
publication generation 与 receipt 用于检查选择的 bank/版本；compute release 与结果/Head release 是不同事件。
设备描述符携带 stream/frame/version，PPU 结果还包含 bank/generation；超时、错误和不确定提交不得跳过完成证明释放资源。

正式固件的 PPU 对象保留 `YOLO32_PPU_ORDERED_MMIO=1`，使用已有 readback barrier。
普通 CPU fence 和 cache Flush64 保持各自语义；PPU readback 不能证明 RoCC/DMA 已停止。
结果经版本/身份校验和 TTL 后映射为显示坐标，overlay 在 busy 检查后写 box/label 并 commit。

定向回归：`make test-tensor-device test-ppu-device test-overlay-device test-cache-ops`，
以及 `make test-runtime-resources test-runtime-faults test-runtime-scheduler`。
`make test-software` 包含全部 Host/RV64 轨迹和模型回归；`make test-rtl` 包含硬件 Tensor/PPU/视频测试。
现有版本回绕的 characterization 不代表该正确性缺口已修复，详见 [验收](../validation/current.md)。
