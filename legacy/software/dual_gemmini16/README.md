# 双 Gemmini16 YOLOv5nu / TinyYOLOv2 软件栈源码包

本目录固化当前工程中“双 Gemmini16 并行 YOLOv5nu / TinyYOLOv2”相关的软件源码，不包含
任何 RTL、Vivado 生成物、目标文件或固件二进制。

这里的 `batch=2` 是两个 Gemmini16 worker 同时处理两个独立的 Batch=1 图像，
不是把 TinyYOLOv2 网络的模型 batch 维度改成 2：

- worker0 使用 `custom3`；
- worker1 使用 `custom2`；
- `ai_batch_runtime.c` 从 16 路输入成员中公平选择两个 job；
- 每个 worker 拥有独立网络中间缓冲和检测结果；
- TinyYOLOv2 单个 job 的输入仍为 `1x416x416x3 NHWC INT8`。

## 目录

- `software/src/`：板级软件、AI snapshot/preprocess、双 batch context、双 worker
  调度、YOLOv5nu/TinyYOLOv2 backend、结果管理及 overlay 接口。
- `software/yolov5/`：已经通过双 Gemmini16 bit-exact 自检和真实视频流验证的
  YOLOv5nu 源码、参数、DIM16 双 worker 状态机、image025 自检输入及生成工具；
  已移除训练模型、标定集、历史实现、预编译程序和日志等非运行依赖。
- `software/yolov2/`：TinyYOLOv2 网络、模型参数、双 worker pool、Decode/NMS 和
  Gemmini 软件接口副本。
- `software/postprocess/`：定点参考后处理实现。
- `software/Makefile`、`software/linker*.ld`：当前生产固件构建和链接配置快照。
- `scripts/`：YOLOv5nu 构建/JTAG 下载与离线日志检查脚本；自动脚本不占用串口。
- `tests/`：AI batch runtime、后处理和定点 Decode/NMS host tests。
- `tests/include/mmio.h`：host tests 使用的非 RISC-V MMIO stub。
- `dependencies/gemmini/`：当前生产构建实际使用的 Gemmini16 RoCC 头文件及
  `gemmini_params_taihang_16x16_packed_gemmini0.h`。
- `dependencies/platform/include/mmio.h`：AI 软件直接依赖的 MMIO helper。

## 生产路径

主要调用链为：

```text
main/video_service
  -> ai_batch_runtime
  -> ai_frame_snapshot + ai_preprocess
  -> ai_model_backend_yolov5nu（默认）或 ai_model_backend_yolov2
  -> YOLOv5nu/TinyYOLOv2 worker pool
     (worker0/custom3 + worker1/custom2)
  -> forward + Decode/NMS
  -> ai_result_manager + ai_display_map + ai_overlay
```

默认 `make` 构建 640x480 YOLOv5nu；执行 `make AI_MODEL=yolov2` 可构建
416x416 TinyYOLOv2。`software/src/ai_model_backend_gemcc.c` 和
`software/src/ai_model_backend_stub.c` 是同一 ABI 的替代 backend，不是当前生产
生产路径；保留它们是为了完整保存本版本软件接口。

## 外部构建依赖

当前 `software/Makefile` 已调整为从包内 `dependencies/gemmini/` 读取 Gemmini
头文件。完整板级固件仍依赖：

- RISC-V RV64GCV bare-metal toolchain；
- Chipyard/Gemmini 环境；
- 原工程引用的板级 IIC/clock 软件；
- AMD HDMI/VPHY BSP 源码。

其中推理所需的 Gemmini 头文件已经固化在 `dependencies/gemmini/`；AMD BSP 与
板级 HDMI 驱动不是 YOLOv2 推理实现本身，因此未复制进本目录。
