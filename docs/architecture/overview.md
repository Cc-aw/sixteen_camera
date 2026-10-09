# 当前视频与 AI 底座

八路 OV7670 DVP 和一路 4K30 HDMI 输入组成十六路 640×480 视频。HDMI 的八路空间封装见 [输入规范](../integration/8路640x480视频在4K30_HDMI中的空间封装规范.md)。板级顶层为 [top_wrapper.sv](../../hw/rtl/top_wrapper.sv)。

## 显示和 Tensor

显示路径逐路缩放为 360×270，使用 RGB565、368 像素对齐行和每路四个 framebuffer 槽；mosaic 输出 1920×1080p60。视频采样、行恢复、CDC、frame manager 和显示分别位于 `hw/rtl/video/`；DDR 接口与 memory bridge 位于 `hw/rtl/memory/`。

AI 路径独立生成 640×480×3 NHWC RGB INT8，每帧 921600 字节。流式生产使用 32 个 Tensor 槽，通过当前 coherent FBus 路径写入。DMA 和遥测见 `yolov5nu_multi_channel_tensor_dma.sv`、`tensor_csr.sv` 和 `tensor_telemetry_cdc.sv`。

当前源码仍使用已有 FBus/L2 协议。合并新 SoC 时必须重新核对一致性、AXI ID 分组、burst、背压、复位和缓存完成条件。

## 推理和后处理

`sw/src/ai/runtime/ai_batch_runtime_stream.c` 管理 latest-frame、EDF、TTL、Tensor 生命周期和 drain。后端为 `ai_model_backend_yolov5nu.c`；生产模型由已验证 Stage8F AOT 图生成 167 个协作阶段。dual16 使用两个 DIM16 worker；single4 使用一个 DIM4 worker。

每个 worker 有两个 Head 槽。Head 为三路分类 raw head 加三路 DFL raw head，共 907200 字节，每槽按 1 MiB stride 分配。准确偏移、长度与对齐定义在 [Head 布局](../../sw/models/yolov5nu/runtime/yolov5nu_head_layout.h)。

Head publication、URAM、本地读取和 PPU 位于 `hw/rtl/ai/postprocess/`。PPU 完成分类筛选、DFL、BBox、候选排序与 NMS，经结果队列发布检测框和标签。输入槽、计算 activation 和 Head 槽具有独立所有权；compute completion 不代表 PPU 已释放 Head 槽。软件结果版本排序和 overlay 提交位于 `sw/src/ai/postprocess/`。

## 控制与验证入口

CSR/MMIO 及遥测位于 `hw/rtl/control/`。SoC 适配入口为 `control_soc_subsystem.sv`，软件寄存器和地址定义为 `sw/src/platform/platform.h`。接口与合并步骤见 [SoC 合并指南](../integration/soc-integration.md)。

host 回归覆盖调度、槽位、发布队列和标量后处理；RTL 回归覆盖视频恢复、Tensor DMA、缓存完成和 PPU。image025 校验使用固定参数/输入与整数参考，NumPy corpus 覆盖 128 张图像。回归通过、RTL elaboration、完整物理实现和板测分别记录，重构验收见 [structure-refactor.md](../validation/structure-refactor.md)。
