# YOLOv5nu Stage 0 复盘

## 定位

Stage 0 是 YOLOv5nu 上板优化前的 correctness-first 基线。目标是固定模型、量化、输入图片、检测后处理和 profile 格式，为后续所有优化提供可重复的功能与性能对照。

## 固定条件

- 模型：`generators/gemmini/software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.onnx`
- 输入尺寸：`320x320`
- 逻辑布局：NCHW
- Gemmini Conv 前后保留 NCHW/NHWC bridge
- 图片：`025/142/036/404/650`
- NMS score threshold：`0.25`
- NMS IoU threshold：`0.45`
- 开启 `YOLOV5NU_PROFILE=1`
- 每次运行：`482` 条 profile records

## 执行路径

- Conv：Gemmini
- Conv 前后：NCHW/NHWC 转换
- SiLU：独立 Sigmoid + Mul
- Add、Concat、MaxPool、Resize：原始 CPU/scalar 路径
- DFL、Decode、NMS：原始逻辑布局和 CPU 路径

Stage 0 没有使用 NHWC 常驻、SiLU fused LUT、RVV 专用 kernel、内存复用或检测头专用 lowering。

## 主机侧工作

主要入口：

- `scripts/yolov5nu_stage0_baseline.py`
- `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`
- `scripts/yolov5nu_validate_baremetal_reference.py`
- `scripts/yolov5nu_graph_parser.py`

完成了五图 ELF 构建、ORT reference 生成、Conv contract 检查、模型/图片/源码/参数/ELF SHA256 归档，以及 UART 日志解析。

归档目录：

- `fpga/xcvu13p/tests/yolov5nu_stage0/README.md`
- `fpga/xcvu13p/tests/yolov5nu_stage0/build_manifest.json`
- `fpga/xcvu13p/tests/yolov5nu_stage0/uart_validation.json`
- `fpga/xcvu13p/tests/yolov5nu_stage0/reference/`
- `fpga/xcvu13p/tests/yolov5nu_stage0/conv_validation/`

## FPGA 验证

五张图片各运行两次。全部满足：

- `482` 条 profile records
- `PASS`
- baremetal exit code `0`
- 同一 ELF 重复运行确定
- final tensor、Top-10 和 NMS 重复运行一致

五图平均：

```text
graph cycles：429,906,990
端到端时间：约 8.66 s
吞吐率：    约 0.1155 FPS
```

全部 76 个 Conv contract 检查通过，最大差异为 `1 LSB`。少量 1 LSB 差异来自浮点累加顺序和定点舍入边界，不是 FPGA 非确定性故障。

## 结论

Stage 0 作为历史 correctness baseline 关闭。Stage 1 以它的 FPGA 输出和 reference 为 bit-exact comparison target。

