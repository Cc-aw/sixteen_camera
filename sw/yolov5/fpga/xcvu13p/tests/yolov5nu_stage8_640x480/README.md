# YOLOv5nu 640x480 Stage 8F

该目录对应从 `yolov5nu.pt` 重新生成的非方形输入版本：宽 640、高 480。
它是独立候选，不覆盖现有 320x320 Stage 8F baseline，也没有修改 RTL、Scala、
Vivado 工程或 FPGA bitstream。

## 结果状态

- 640x480 FP32 ONNX：已从 `yolov5nu.pt` 重新导出。
- 校准：已使用 COCO128 目录中的 128 张图片。
- 激活：per-tensor signed QInt8，`zero_point=0`。
- 权重：per-tensor signed QInt8，`zero_point=0`。
- 7 个 Add shared scale：已重新计算并应用。
- 受影响 Conv bias：由新的 input/weight scale 重新量化。
- Conv requant：由新 manifest 和新的 Conv output scale 生成。
- 动态 SiLU：69 张真实 256-entry LUT 已重新生成。
- hardware-aware integer reference：128 张图片已生成。
- Stage 8F AOT：已生成五张图片的 C、参数头和 memory plan。
- ELF：五张图片均已成功链接。

## 模型与量化产物

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/
  yolov5nu-fp32-img640x480.onnx
  yolov5nu-hw-aware-full-int8-img640x480.onnx
  yolov5nu-hw-aware-full-int8-img640x480.quant.json
  yolov5nu-hw-aware-shared-scale-int8-img640x480.onnx
  yolov5nu-hw-aware-shared-scale-img640x480.graph.json
  hardware_aware_quantization_audit.json
  hardware_silu_luts.json
  hardware_integer_reference.json
  hardware_integer_reference.npz
```

模型 shape：

```text
input : [1, 3, 480, 640] BCHW
output: [1, 84, 6300]
P3    : 60 x 80 = 4800 locations
P4    : 30 x 40 = 1200 locations
P5    : 15 x 20 =  300 locations
```

导出和完整硬件感知量化流程：

```bash
./.conda-env/bin/python scripts/yolov5nu_stage8_hardware_aware.py all \
  --width 640 --height 480 --calibration-samples 128 \
  --output-dir generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware
```

该命令依次执行 FP32 导出、QDQ 量化、7 组 shared scale、manifest、69 张 SiLU LUT
和 128 张 hardware integer reference。FP32 中间模型由 `--keep-fp32` 保存在独立目录。

## Stage 8F AOT

生成器使用：

```text
scripts/yolov5nu_stage8f_spad_reuse.py
generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py
scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh
```

保留的 Stage 8F contract：

```text
shared Gemmini resadd calls : 7
Concat -> Conv split-K edges: 17
dual-consumer SPAD reuse    : 4 groups
direct materialized Concat  : 0
arena                       : 2,217,600 bytes
```

AOT 文件位于：

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/aot/
```

每张图包含：

```text
*_profile.c
*_profile_params.h
*_profile_memory.json
```

## 五张图片 ELF

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/
  yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile-baremetal-uart
  yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image036-profile-baremetal-uart
  yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image142-profile-baremetal-uart
  yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image404-profile-baremetal-uart
  yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image650-profile-baremetal-uart
```

五个 ELF 均使用 `-march=rv64gcv`，链接成功。链接器报告的 RWX LOAD segment
warning 与既有 baremetal ELF 相同，不是本次模型错误。

## Host validation

Stage 4 head geometry 和 7 个 ratio Add 的 host 检查：

```bash
./.conda-env/bin/python scripts/yolov5nu_validate_stage4_heads.py \
  --model generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/yolov5nu-hw-aware-shared-scale-int8-img640x480.onnx \
  --manifest generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/yolov5nu-hw-aware-shared-scale-img640x480.graph.json \
  --image-id 025 --image-id 036 --image-id 142 --image-id 404 --image-id 650 \
  --optimized-kernels
```

已通过：7 组 Add 的 `458752` 个输入 pair exhaustive check，以及 image025、036、
142 的 location-major class/DFL 检查。image404/650 在浮点 `exp / sum` 与
`exp * reciprocal` 的最后舍入路径上出现极少量 `+/-1` 差异；这不是 shape 或量化
配置错误，板级判定应以 hardware integer reference 为准。

## Spike

image025 的非 UART ELF 已构建并通过完整 Gemmini Spike：

```bash
make -B -C generators/gemmini/software/gemmini-rocc-tests/build/imagenet \
  -f /mnt/data/fff/chipyard/generators/gemmini/software/gemmini-rocc-tests/imagenet/Makefile \
  abs_top_srcdir=/mnt/data/fff/chipyard/generators/gemmini/software/gemmini-rocc-tests \
  src_dir=/mnt/data/fff/chipyard/generators/gemmini/software/gemmini-rocc-tests/imagenet \
  XLEN=64 CC_BAREMETAL=/mnt/data/fff/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc \
  RVV=1 \
  yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile-baremetal

./scripts/run_spike_gemmini.sh --isa=rv64gcv_zicntr \
  generators/gemmini/software/gemmini-rocc-tests/build/imagenet/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile-baremetal
```

Spike 结果：`PASS`，执行到 `80x6300` class head、sparse DFL、decode/NMS 和 Stage
8F Gemmini 调度。Spike 的 RVV VLEN 为 128，因而 DFL 的部分路径会 fallback；它
不能代表 DSP Saturn VLEN=256 的性能。

## Verilator

已有可执行仿真器：

```text
sims/verilator/simulator-chipyard.harness-LargeGemminiRocketDspRVVSiluLUTConfig
```

使用该仿真器运行完整 640x480 image025 时，进程正常启动、DRAM 模型正常加载，
但在 15 分钟上限内没有产生完整 UART 输出，最终因 timeout 返回 124。因此本次
不能宣称完整 640x480 Verilator PASS；动态 LUT、RVV 和 Gemmini 的算子级 Verilator
覆盖仍沿用既有 Stage 2/6/8 验证结果。

## 上板

当前 bitstream 可复用，但 640x480 ELF 尚未完成 FPGA 上板验证。加载命令：

```bash
sudo ./scripts/xcvu13p_openocd_load_elf.sh \
  generators/gemmini/software/gemmini-rocc-tests/build/imagenet/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile-baremetal-uart \
  0x80000000
```

串口监视命令：

```bash
sudo ./scripts/xcvu13p_uart_monitor.sh /dev/ttyACM0
```

其他图片只需替换 ELF 文件名中的 `025` 为 `036`、`142`、`404` 或 `650`。
