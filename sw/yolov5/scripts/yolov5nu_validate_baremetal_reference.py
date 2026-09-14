#!/usr/bin/env python3
"""Validate the Gemmini Conv quantization contract against QDQ ONNX Runtime.

This is intentionally a per-Conv check: each Conv consumes the QDQ model's
quantized activation tensor, then recomputes integer convolution plus int32
bias and the exact Gemmini output requant factor.  It isolates parameter
packing/scale errors before testing the generated baremetal scheduler.
"""

from __future__ import annotations

import argparse
import copy
import json
import tempfile
from pathlib import Path

import numpy as np
import onnx
import onnxruntime as ort
from onnx import helper, numpy_helper
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
DEFAULT_MODEL = MODEL_DIR / "yolov5nu-gemmini-int8-img320.onnx"
DEFAULT_MANIFEST = MODEL_DIR / "yolov5nu-gemmini-int8-img320.graph.json"
DEFAULT_IMAGE = MODEL_DIR / "calibration/coco128/images/train2017/000000000009.jpg"


def args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--image", type=Path, default=DEFAULT_IMAGE)
    parser.add_argument("--max-convs", type=int, default=76)
    parser.add_argument("--max-allowed-error", type=int, default=1)
    return parser.parse_args()


def letterbox(path: Path, height: int, width: int) -> np.ndarray:
    image = Image.open(path).convert("RGB")
    source_width, source_height = image.size
    ratio = min(width / source_width, height / source_height)
    resized = (round(source_width * ratio), round(source_height * ratio))
    image = image.resize(resized, Image.Resampling.BILINEAR)
    canvas = Image.new("RGB", (width, height), (114, 114, 114))
    canvas.paste(image, (round((width - resized[0]) / 2 - 0.1), round((height - resized[1]) / 2 - 0.1)))
    return np.asarray(canvas, dtype=np.float32).transpose(2, 0, 1)[None] / 255.0


def conv2d_numpy(
    input_q: np.ndarray,
    weight: np.ndarray,
    bias: np.ndarray | None,
    strides: list[int],
    pads: list[int],
    dilations: list[int],
    groups: int,
) -> np.ndarray:
    if groups != 1 or dilations != [1, 1] or pads[0] != pads[2] or pads[1] != pads[3]:
        raise ValueError("reference Conv currently supports group=1, dilation=1, symmetric padding")
    kh, kw = weight.shape[2:]
    padded = np.pad(input_q, ((0, 0), (0, 0), (pads[0], pads[2]), (pads[1], pads[3])))
    windows = np.lib.stride_tricks.sliding_window_view(padded, (kh, kw), axis=(2, 3))
    windows = windows[:, :, ::strides[0], ::strides[1], :, :]
    output = np.einsum("ncyxkl,ockl->noyx", windows, weight, optimize=True)
    if bias is not None:
        output += bias.reshape(1, -1, 1, 1)
    return output


def main() -> None:
    options = args()
    manifest = json.loads(options.manifest.read_text())
    model = onnx.load(options.model, load_external_data=True)
    initializers = {item.name: numpy_helper.to_array(item) for item in model.graph.initializer}
    convs = [op for op in manifest["ops"] if op["op"] == "Conv"][:options.max_convs]
    if not convs:
        raise ValueError("no Conv nodes selected")

    output_names = {manifest["input"][0]["quantization"]["quantized_tensor"]}
    for op in convs:
        output_names.add(manifest["tensor_quantization"][op["inputs"][0]]["quantized_tensor"])
        output_names.add(op["output_quantization"][op["outputs"][0]]["quantized_tensor"])

    debug_model = copy.deepcopy(model)
    graph_outputs = {item.name for item in debug_model.graph.output}
    for name in sorted(output_names - graph_outputs):
        debug_model.graph.output.append(helper.make_tensor_value_info(name, onnx.TensorProto.INT8, None))
    with tempfile.NamedTemporaryFile(suffix=".onnx") as output:
        onnx.save(debug_model, output.name)
        session = ort.InferenceSession(output.name, providers=["CPUExecutionProvider"])
        input_meta = session.get_inputs()[0]
        input_shape = input_meta.shape
        values = session.run(None, {input_meta.name: letterbox(options.image, input_shape[2], input_shape[3])})
        q_values = dict(zip((item.name for item in session.get_outputs()), values))

    failures = 0
    for op in convs:
        attrs = {item.name: onnx.helper.get_attribute_value(item) for item in next(n for n in model.graph.node if n.name == op["name"]).attribute}
        input_record = manifest["tensor_quantization"][op["inputs"][0]]
        output_record = op["output_quantization"][op["outputs"][0]]
        input_q = q_values[input_record["quantized_tensor"]].astype(np.float32)
        target = q_values[output_record["quantized_tensor"]].astype(np.int16)
        weight = initializers[op["weight"]["initializer"]].astype(np.float32)
        bias = initializers[op["bias"]["initializer"]].astype(np.float32) if op["bias"] else None
        pads = attrs.get("pads", [0, 0, 0, 0])
        strides = attrs.get("strides", [1, 1])
        dilations = attrs.get("dilations", [1, 1])
        groups = int(attrs.get("group", 1))
        computed = conv2d_numpy(input_q, weight, bias, list(strides), list(pads), list(dilations), groups)
        requant = float(input_record["scale"]) * float(op["weight"]["scale"]) / float(output_record["scale"])
        predicted = np.clip(np.rint(computed * requant), -128, 127).astype(np.int16)
        delta = np.abs(predicted - target)
        max_error = int(delta.max())
        mismatches = int(np.count_nonzero(delta))
        status = "PASS" if max_error <= options.max_allowed_error else "FAIL"
        print(f"conv{op['conv_index']:02d} {status} max_error={max_error} mismatches={mismatches}/{target.size}")
        failures += status == "FAIL"

    if failures:
        raise SystemExit(f"{failures} Conv quantization checks failed")
    print(f"PASS: {len(convs)} Conv quantization checks against QDQ ONNX Runtime")


if __name__ == "__main__":
    main()
