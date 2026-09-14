# YOLOv5nu 双 Gemmini16 最小软件包

本目录只保留当前板级 640x480 YOLOv5nu 推理所需的软件和可再生成输入，
不包含 ONNX/PT、训练/标定图片、历史 FPGA 工程、N6 版本、预编译 ELF、UART
日志、旧阶段版本或 Python 缓存。

| 路径 | 用途 |
| --- | --- |
| `dim16_dual/` | 双 worker 异步状态机、接口和生成脚本 |
| `include/` | SiLU、Stage3、Stage4 所需 RVV 算子头 |
| `model/*-profile_params.h` | INT8 权重、bias、LUT 和 image025 自检输入 |
| `model/*-profile.c` | 生成双 worker 状态机所依据的 Stage8F AOT 源码 |

默认构建：

```sh
cd ..
make
```

重新生成状态机：

```sh
cd ..
make yolov5nu-regenerate
```

板端按 `t` 执行双 Gemmini16 bit-exact 自检，按 `i` 启动真实视频流推理。
