# 目录重构验收（2026-10-09）

重构基线为 `3715539`；外部依赖本地化提交为 `054a7a4`。本次整理面向 SoC 底座交接。

本文记录 `08cb230` 的目录重构验收。后续 Vivado 交付改为源码加 Tcl，工程及生成物取消跟踪，输出位置由 Vivado 管理；当前入口见 [Vivado 说明](../../hw/vivado/README.md)。下文工作副本描述仅对应当时验收。

## 交付范围

顶层统一为 `hw / sw / tools / tests / docs`，本地产物集中于忽略的 `build/`。保留双 DIM16 和单 DIM4 的生成 SoC 示例、当前 YOLOv5nu 模型与外设 RTL。移除旧 YOLOv2、历史软件快照、退休旁路实现、训练/校准/旧导出材料和 SoC 生成环境。历史源代码仍可从 Git 查询，本地旧抓取和结果移至 `build/history/`。

板级 IIC/clock、AMD 2023.2 BSP 与 Gemmini ABI 在 `sw/third_party/`；模型和整数参考材料分别在 `sw/models/yolov5nu/` 与 `tests/data/yolov5nu/`。校验值与出处记录在两份 `sources.lock.json`。外部安装依赖仅为编译器、Vivado、下载工具和仿真/Python 环境。

## 固件与模型

两种配置均在空构建目录重新编译，并在 `/tmp/sixteen-camera-handoff` 源码副本再次构建。副本不包含原来的 build、DCP、本机配置或外部源码；编译工具通过环境变量指定。118 个 `-MMD` 依赖文件均指向副本内部；86 份保留源码/参数/参考快照校验通过。

`objcopy -O binary` 的加载字节与重构前完全一致：

| 配置 | SHA-256 |
| --- | --- |
| dual16 | `2a7be96e7a0415d9467ce081f72d3ecf2c359f93a0d3716ff90079081f7bd4dc` |
| single4 | `d8c74b7737d83d2e88b8401b7a708ec65dcd4f13ca926be9e62cc41cc385895f` |

完整 ELF 带源码路径和调试信息，不以 ELF 文件整体相同作为验收标准。运行时生成 C 与基线逐字节一致；分类/DFL、BBox LUT 和 overlay 标签生成内容均与基线一致，来源路径注释按新目录更新。128 图 NMS 检查 `float_vs_pixel_mismatches=0`。

## 回归结果

| 检查 | 结果 |
| --- | --- |
| dual16 / single4 生产输入清单 | PASS：120 底座输入（118 HDL、2 MIF）、10 IP、6 XDC |
| 六组 host 软件回归 | PASS：流式调度、Head/PPU 队列、Tensor 槽、后处理及调度 |
| 视频定向回归 | PASS：采样/恢复、CDC、DMA、CSR、frame manager 与 mosaic |
| Tensor DMA 定向回归 | PASS：128 帧压力、overflow、abort/drain、stall 恢复 |
| PPU 发布回归 | PASS：publication、缓存完成、异常/排队/多任务；六任务覆盖三 worker/六槽 |
| dual16 / single4 真实生成 L2 控制回归 | PASS：publication completion，8 lines |
| YOLOv5nu 后处理回归 | PASS：class、Top-K/NMS、48 组随机 DFL、image025、空/密集整链、BBox 和概率流水线 |
| 两种固件下载预检查 | PASS：工具、内置配置与 ELF；不连接板卡 |
| 两种 bitstream 构建预检查 | PASS：Vivado 2023.2、工程与输入清单 |
| Vivado OOC run 建立检查 | PASS：standalone IP 与 BD 通过各自入口建立，共 26 个综合 run |
| Python / Bash 语法、文档相对链接 | PASS |
| 两种 Vivado RTL elaboration | PASS：源码独立副本，顶层 `top_wrapper` |

仿真结果来自独立源码副本，输出未复用原工程 build。通用队列三 worker 的容量检查与当前模型一/两个 worker 配置分别验证。

## Vivado 工作工程

命令行构建先将 XPR、BD 和 standalone IP 准备到 `build/vivado/<配置>/` 再打开。直接在已打开项目中替换 IP 引用会触发 Vivado 2023.2 崩溃，因此准备阶段完成路径调整。

RTL elaboration 关闭 IP/BD 的 OOC checkpoint 依赖，展开可用 RTL 并检查顶层连接；部分厂商加密核按 Vivado 规则保留黑盒。bitstream 构建恢复正常 OOC 模式，并先建立、执行 IP 综合 run，再执行顶层综合和实现。这样可在不携带历史 DCP 的副本中建立工程。日志、`.Xil`、BD/IP 生成物均位于 `build/`。

Vivado elaboration 两种配置均以 `TENSOR_PRODUCTION_TOP_ELABORATION=PASS` 结束；有厂商 IP 和既存时钟约束警告。最终日志汇总在本地 `build/reports/refactor/`。

本次未执行完整布局布线，也未下载 FPGA 或操作串口。历史板测与时序记录对应各自原版本，新 SoC 合并后需要重新完成物理实现和板级验收。
