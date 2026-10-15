# 当前软件架构

实时入口由 `sw/src/main.c` 驱动 video → Runtime → app 主循环。应用使用 `ai/runtime/rt.h` Facade，串口和模式互斥位于 `app/`；固定三图 `M/t/a` 位于独立 benchmark。

| 层 | 位置 | 责任 |
| --- | --- | --- |
| 应用 | `sw/src/app/` | 启动、事件循环、串口、模式管理 |
| Core | `sw/src/ai/runtime/core/` | Pipeline、生命周期、状态和统计 |
| Resources | `sw/src/ai/runtime/resources/` | job/Tensor/activation/Head 租约与回收 |
| Scheduler | `sw/src/ai/runtime/scheduler/` | 帧选择、EDF、worker 派发 |
| Services | `sw/src/ai/runtime/services/` | Tensor、结果、PPU、overlay 服务 |
| Backend | `sw/src/ai/backend/` | 通用 job/event 与当前模型接合 |
| Model | `sw/models/yolov5nu/src/` | v26 图、三 worker 提交/等待/退休协作 |
| HAL | `sw/src/drivers/` | Tensor/PPU/overlay 设备协议 |

`model.mk` 同时服务实时固件和三图基准；共同使用 codegen、frozen/native、assets 和唯一 Gemmini ABI。
实时编译设置 `YOLO32_LIVE=1`；正式版保持 credit=4、submit burst=1、quantum=200 µs、light FP/VCSR context、fixed/prepared packets、wait reuse 和硬件 Pool/Resize。
当前适配器名称中的 V17A 是 ABI family，实际交付为 v26。冻结 native 的 dim16 名称也不决定当前 DIM，参数由配对构建显式锁定。

Tensor、activation、Head 各自拥有租约；compute completion 不代表 PPU 已释放 Head。
Head 局部完成后发布，整图完成后入队；job/frame/version、publication generation、receipt 共同约束结果身份及安全回收。
异常可能保留资源，drain/restart 不能在缺少设备完成证明时强制释放。
单 worker 活跃、入口拒绝、延迟退休和长期空闲仍需有界返回视频循环；现有稀疏/故障回归保留。

测试入口为 `make test-software`；协议细节见 [Tensor/PPU](../interfaces/tensor-ppu.md) 和 [Gemmini ABI](../interfaces/gemmini-abi.md)。
R0 版本回绕 characterization 的已知正确性缺口见 [当前验收](../validation/current.md)。
