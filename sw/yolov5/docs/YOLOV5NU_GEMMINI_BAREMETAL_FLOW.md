# YOLOv5nu Gemmini Baremetal Flow

This is a separate 320x320 YOLOv5nu path. It does not modify the optimized
TinyYOLOv2 implementation.

## Inputs

- Quantized model: `generators/gemmini/software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.onnx`
- Model export: `generators/gemmini/software/gemmini-ort/models/detection/export_yolov5nu_gemmini_int8.py`
- Calibration images: `generators/gemmini/software/gemmini-ort/models/detection/calibration/coco128/images/train2017/`

The model is fixed `[1, 3, 320, 320]`, QDQ format, signed per-tensor INT8
activations and weights, zero point 0, and INT32 biases. Its output is
`[1, 84, 2100]`, the Ultralytics anchor-free DFL head.

## Build

Run from the Chipyard root with a Python environment containing `onnx`,
`onnxruntime`, `numpy`, and `Pillow`:

```bash
PYTHON=./.conda-env/bin/python ./scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh
```

Select another COCO image or output name without editing generated files:

```bash
YOLOV5NU_IMAGE=generators/gemmini/software/gemmini-ort/models/detection/calibration/coco128/images/train2017/000000000025.jpg \
YOLOV5NU_STEM=yolov5nu-gemmini-img320-image25 \
PYTHON=./.conda-env/bin/python ./scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh
```

Artifacts:

- Graph manifest: `generators/gemmini/software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.graph.json`
- Generated parameters: `generators/gemmini/software/gemmini-rocc-tests/imagenet/yolov5nu-gemmini-img320_params.h`
- Generated source: `generators/gemmini/software/gemmini-rocc-tests/imagenet/yolov5nu-gemmini-img320.c`
- ELF: `generators/gemmini/software/gemmini-rocc-tests/build/imagenet/yolov5nu-gemmini-img320-baremetal-uart`

Load the ELF with the existing external FT2232H/OpenOCD flow:

```bash
sudo ./scripts/xcvu13p_openocd_load_elf.sh \
  generators/gemmini/software/gemmini-rocc-tests/build/imagenet/yolov5nu-gemmini-img320-baremetal-uart \
  0x80000000
```

## Generated Execution Plan

`scripts/yolov5nu_graph_parser.py` checks every QDQ boundary used by the
model. It rejects non-zero zero points, non-scalar scales, unsupported nodes,
and non-INT8 Conv weights/non-INT32 Conv biases. It records all tensor names,
shapes, operator attributes, scales, and initializer names in the manifest.

`generate_yolov5nu_baremetal.py` consumes only the ONNX plus that manifest:

- All 76 `Conv` nodes call `tiled_conv_auto()` on Gemmini.
- Weights are repacked from ONNX `OIHW` to Gemmini `[kh * kw * in_channels,
  out_channels]`; biases remain INT32 accumulator-domain values.
- The Gemmini requant factor is exactly `input_scale * weight_scale /
  output_scale`.
- NCHW model tensors are converted through temporary NHWC buffers around each
  Conv. This is correctness-first and is the largest current performance cost.
- `Sigmoid` uses generated exact INT8 lookup tables. `Softmax` uses a generated
  INT8-difference exponential table. `Mul`, `Add`, `Concat`, `MaxPool`,
  nearest-neighbor `Resize`, `Reshape`, and DFL `Transpose` run in generated C.
- Equal-scale copies use RVV `vsetvli`, `vle8.v`, and `vse8.v`; other CPU
  elementwise operators are scalar in this first version.
- The ONNX exporter's dynamic Shape/Gather/Slice grid construction is replaced
  with an equivalent fixed 320x320 three-level (40x40, 20x20, 10x10) DFL decode.
  UART prints top-10 COCO detections without NMS.

## Current Verification

Run the Conv contract check before FPGA execution:

```bash
./.conda-env/bin/python scripts/yolov5nu_validate_baremetal_reference.py
```

The checker exports quantized ONNX Runtime boundary tensors and recomputes all
76 Conv nodes with the generated integer contract. The checked model passes;
Conv0 has four values within one LSB of ONNX Runtime at a rounding boundary and
the remaining 75 Conv nodes are bit-exact. The ELF links as RV64GCV, contains
Gemmini RoCC instructions, has about 3 MiB initialized load data and about
13.9 MiB BSS.

## Remaining Risks

- This is a buildable, parameter-correct first baremetal implementation, not a
  performance baseline. Keeping all 252 intermediate tensors costs roughly
  13.4 MiB and every Conv has NCHW/NHWC conversion.
- The complete CPU implementations for QDQ non-Conv operators and DFL decode
  must still be compared with UART checkpoints from actual hardware. Enable
  `-DYOLOV5NU_LAYER_STATS=1` in the compile flags when diagnosing a mismatch.
- Current scalar `Mul/Add/MaxPool/Resize/Transpose/Softmax` are intentionally
  conservative. RVV vectorization, tensor lifetime allocation, fusion of
  Conv-SiLU, and direct NCHW/Gemmini scheduling are subsequent optimization
  work, not correctness prerequisites.
