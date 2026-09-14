# YOLOv5nu Stage 8 Hardware-Aware Reference

The original Stage 8 ORT graph reference remains unchanged:

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_all_shared_adds/ort_reference.json
```

This hardware-aware candidate is independent:

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_hardware_aware/
```

## Quantization flow

`yolov5nu.pt` is exported at 320x320 and statically quantized with all 128
COCO128 images using ONNX Runtime MinMax calibration. Activation and weight
quantization are per-tensor signed QInt8 with zero point 0. The seven feature
residual Add groups are then processed in topological order using the maximum
of the two input scales as their shared scale. Affected Conv bias QDQ values
and scales are regenerated after every scale change.

Reproduce the model and references with:

```bash
python3 scripts/yolov5nu_stage8_hardware_aware.py all
```

The fresh model and the seven-Add shared-scale model are:

```text
yolov5nu-hw-aware-full-int8-img320.onnx
yolov5nu-hw-aware-shared-scale-int8-img320.onnx
yolov5nu-hw-aware-shared-scale.graph.json
```

## Hardware integer semantics

The reference evaluator uses:

```text
Conv: int8 * int8 + int32 quantized bias
      -> float32 Gemmini requant -> round-to-nearest-even -> int8 saturation
Add:  shared-scale int32-equivalent resadd -> float32 output requant
      -> round-to-nearest-even -> int8 saturation
SiLU: quantized sigmoid LUT followed by the fused int8 SiLU LUT mapping
DFL:  exp LUT -> float32 ordered sum/reciprocal -> int8 probability
      -> int32 probability dot -> final requant
```

The generated files are:

```text
hardware_aware_quantization_audit.json
hardware_silu_luts.json
hardware_integer_reference.json
hardware_integer_reference.npz
```

`hardware_integer_reference.json` contains 128 calibration-image records,
including full class/DFL summaries, H4 sparse DFL summaries, Top-10, and NMS.
It is the reference for FPGA bit-exact qualification. The standard ORT
reference is retained separately for model-accuracy comparison; it can differ
by one or more LSB at floating-point Conv rounding boundaries.
