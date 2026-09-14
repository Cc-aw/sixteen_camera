# YOLOv5nu Stage 8A Shared-Scale Candidate

Stage 8A is the first software-only Stage 8 candidate. It changes one
residual feature-map Add scale group so that both int8 Add inputs have the
same per-tensor symmetric scale. It does not modify RTL, Scala, Chisel, the
Stage 7E baseline, or the source QDQ model.

## Source and output paths

Source model:

`generators/gemmini/software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.onnx`

Builder:

`scripts/yolov5nu_stage8a_shared_scale.py`

Default output directory:

`generators/gemmini/software/gemmini-ort/models/detection/stage8a_shared_scale/`

Important outputs:

- `yolov5nu-stage8a-shared-scale.onnx`: independent QDQ candidate;
- `yolov5nu-stage8a-shared-scale.graph.json`: manifest parsed from that ONNX;
- `yolov5nu-stage8a-shared-scale.qdq-constants.json`: changed initializer audit;
- `yolov5nu-stage8a-shared-scale.audit.json`: complete scale, requant, calibration,
  ORT and validation audit;
- `ort_reference.json` and `ort_reference.npz`: five-image ORT references;
- `aot/yolov5nu-stage8a-shared-scale-image025-profile.c`: generated baremetal source;
- `aot/yolov5nu-stage8a-shared-scale-image025-profile_params.h`: weights, scales and
  regenerated 69 dynamic SiLU LUTs;
- `conv_qdq_validation.log`: 76-Conv integer reference validation;
- `silu_lut_validation.log`: 69-LUT and generated-source validation.

## Reproduce

Run from the Chipyard root:

```bash
python3 scripts/yolov5nu_stage8a_shared_scale.py
```

The default candidate modifies only:

`/model.2/m/m.0/Add`

Its input scales change from:

```text
0.06295188516378403, 0.15322692692279816
```

to the shared maximum scale:

```text
0.15322692692279816, 0.15322692692279816
```

The Add output scale remains `0.1639299839735031`. A different one of the
seven groups can be selected with `--add-name`; the complete supported list
is recorded in the audit JSON. The scale policy can be changed with
`--shared-scale-policy max|min|add-output`, or an explicit value can be passed
with `--shared-scale-value`.

## What is regenerated

For both Add inputs, the script updates the scale initializer used by the
matching QuantizeLinear and DequantizeLinear nodes. If a changed SiLU output
feeds a later Conv, that Conv bias is regenerated as follows:

```text
new_bias_scale = new_input_scale * weight_scale
bias_real      = old_bias_int32 * old_bias_scale
new_bias_int32 = RNE(bias_real / new_bias_scale)
```

This is required because a Conv bias QDQ scale is tied to its activation input
scale. The candidate's fused Conv requant is derived from the new model
manifest, and all 69 dynamic Gemmini SiLU LUTs are regenerated from the new
input, sigmoid and output scales.

## Validation boundary

The candidate must be bit-exact against its own QDQ ONNX reference. It is
expected to differ from Stage 7E because one branch is requantized at a new
shared scale. It must not be described as bit-exact with the old Stage 7E
model until a separate comparison proves that property.

The builder performs these checks automatically:

1. ONNX checker and graph parser validation;
2. 76-Conv integer QDQ reference validation;
3. 69 SiLU LUT exhaustive validation over 17,664 int8 cases;
4. five-image ORT output and changed-intermediate reference generation.

Stage 8B, Gemmini resadd mapping, is intentionally not implemented here.
