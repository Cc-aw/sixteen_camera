#!/usr/bin/env python3
"""Validate the YOLOv5nu Stage 1 NHWC physical-layout contract."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
DEFAULT_MANIFEST = MODEL_DIR / "yolov5nu-gemmini-int8-img320.graph.json"
DEFAULT_SOURCE = (
    ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/"
    "yolov5nu-stage1-nhwc-image025-profile.c"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    return parser.parse_args()


def product(shape: list[int]) -> int:
    result = 1
    for dim in shape:
        result *= dim
    return result


def requant(values: np.ndarray, source_scale: float, destination_scale: float) -> np.ndarray:
    real = values.astype(np.float32) * np.float32(source_scale / destination_scale)
    return np.clip(np.rint(real), -128, 127).astype(np.int8)


def validate_random_layout_kernels() -> None:
    rng = np.random.default_rng(20260821)

    # NHWC channel concat must equal logical NCHW concat after one layout transform.
    left = rng.integers(-128, 128, (1, 3, 5, 7), dtype=np.int16).astype(np.int8)
    right = rng.integers(-128, 128, (1, 2, 5, 7), dtype=np.int16).astype(np.int8)
    logical = np.concatenate([requant(left, 0.25, 0.125), requant(right, 0.5, 0.125)], axis=1)
    left_nhwc = left.transpose(0, 2, 3, 1)
    right_nhwc = right.transpose(0, 2, 3, 1)
    physical = np.concatenate(
        [requant(left_nhwc, 0.25, 0.125), requant(right_nhwc, 0.5, 0.125)], axis=3
    )
    np.testing.assert_array_equal(physical, logical.transpose(0, 2, 3, 1))

    # The six detection-head boundaries must reconstruct N,C,H*W logical storage.
    feature = rng.integers(-128, 128, (1, 4, 3, 5), dtype=np.int16).astype(np.int8)
    nhwc = feature.transpose(0, 2, 3, 1)
    ncl = requant(nhwc.transpose(0, 3, 1, 2).reshape(1, 4, 15), 0.25, 0.125)
    expected_ncl = requant(feature.reshape(1, 4, 15), 0.25, 0.125)
    np.testing.assert_array_equal(ncl, expected_ncl)

    # Nearest-neighbor Resize indexes spatial dimensions identically in either layout.
    source = rng.integers(-128, 128, (1, 3, 2, 4), dtype=np.int16).astype(np.int8)
    y_index = (np.arange(5) * source.shape[2]) // 5
    x_index = (np.arange(7) * source.shape[3]) // 7
    logical_resize = source[:, :, y_index[:, None], x_index[None, :]]
    physical_resize = source.transpose(0, 2, 3, 1)[:, y_index[:, None], x_index[None, :], :]
    np.testing.assert_array_equal(physical_resize, logical_resize.transpose(0, 2, 3, 1))

    # SAME MaxPool over H/W must preserve the channel permutation.
    source = rng.integers(-128, 128, (1, 5, 4, 6), dtype=np.int16).astype(np.int8)
    padded = np.pad(source, ((0, 0), (0, 0), (1, 1), (1, 1)), constant_values=-128)
    logical_pool = np.empty_like(source)
    for y in range(source.shape[2]):
        for x in range(source.shape[3]):
            logical_pool[:, :, y, x] = padded[:, :, y:y + 3, x:x + 3].max(axis=(2, 3))
    source_nhwc = source.transpose(0, 2, 3, 1)
    physical_pool = np.empty_like(source_nhwc)
    for y in range(source.shape[2]):
        for x in range(source.shape[3]):
            y0, y1 = max(0, y - 1), min(source.shape[2], y + 2)
            x0, x1 = max(0, x - 1), min(source.shape[3], x + 2)
            physical_pool[:, y, x, :] = source_nhwc[:, y0:y1, x0:x1, :].max(axis=(1, 2))
    np.testing.assert_array_equal(physical_pool, logical_pool.transpose(0, 2, 3, 1))


def main() -> None:
    options = parse_args()
    manifest = json.loads(options.manifest.read_text())
    layouts = manifest.get("tensor_layouts")
    if not layouts:
        raise ValueError("manifest lacks tensor_layouts")

    shapes: dict[str, list[int]] = {}
    input_record = manifest["input"][0]
    input_name = input_record["quantization"]["quantized_tensor"]
    shapes[input_name] = input_record["shape"]
    selected = []
    for op in manifest["ops"]:
        selected.append(op)
        for output, quantization in op.get("output_quantization", {}).items():
            shapes[quantization["quantized_tensor"]] = op["output_shapes"][output]
        if op["name"] == "/model.24/dfl/Reshape_1":
            break

    def q_name(float_name: str) -> str:
        return manifest["tensor_quantization"][float_name]["quantized_tensor"]

    def layout(name: str) -> str:
        return layouts[name]["nhwc_resident"]["physical_layout"]

    direct_convs = 0
    bridged_convs = 0
    reshape_boundaries = 0
    feature_concats = 0
    for op in selected:
        output_name = next(iter(op["output_quantization"].values()))["quantized_tensor"]
        quantized_inputs = [q_name(name) for name in op["inputs"] if name in manifest["tensor_quantization"]]
        if op["op"] == "Conv":
            input_name = q_name(op["inputs"][0])
            if layout(input_name) == layout(output_name) == "NHWC":
                direct_convs += 1
            elif layout(input_name) != "NHWC" and layout(output_name) != "NHWC":
                bridged_convs += 1
            else:
                raise ValueError(f"unsupported Conv layout boundary: {op['name']}")
        elif op["op"] in {"Sigmoid", "Mul", "Add"}:
            if any(layout(name) != layout(output_name) for name in quantized_inputs):
                raise ValueError(f"elementwise layout mismatch: {op['name']}")
        elif op["op"] == "Concat":
            axis = int(op["attributes"]["axis"])
            if axis < 0:
                axis += len(shapes[output_name])
            if layout(output_name) == "NHWC":
                if axis != 1 or any(layout(name) != "NHWC" for name in quantized_inputs):
                    raise ValueError(f"invalid NHWC Concat: {op['name']}")
                feature_concats += 1
            elif any(layout(name) == "NHWC" for name in quantized_inputs):
                raise ValueError(f"logical Concat consumes NHWC input: {op['name']}")
        elif op["op"] in {"MaxPool", "Resize"}:
            if any(layout(name) != layout(output_name) for name in quantized_inputs):
                raise ValueError(f"spatial operator layout mismatch: {op['name']}")
        elif op["op"] == "Reshape":
            input_name = q_name(op["inputs"][0])
            if layout(input_name) == "NHWC":
                in_shape, out_shape = shapes[input_name], shapes[output_name]
                if out_shape != [in_shape[0], in_shape[1], in_shape[2] * in_shape[3]]:
                    raise ValueError(f"invalid NHWC-to-NCL boundary: {op['name']}")
                reshape_boundaries += 1
            elif layout(output_name) == "NHWC":
                raise ValueError(f"logical-to-NHWC Reshape is unsupported: {op['name']}")
        elif op["op"] in {"Transpose", "Softmax"}:
            if layout(output_name) == "NHWC" or any(layout(name) == "NHWC" for name in quantized_inputs):
                raise ValueError(f"DFL logical operator became NHWC: {op['name']}")

    if (direct_convs, bridged_convs, reshape_boundaries) != (75, 1, 6):
        raise ValueError(
            f"unexpected schedule: direct_convs={direct_convs}, bridged_convs={bridged_convs}, "
            f"reshape_boundaries={reshape_boundaries}"
        )

    source = options.source.read_text()
    call_count = lambda pattern: len(re.findall(pattern, source))
    source_contract = {
        "direct_conv_zero_in_layout": call_count(r"PROFILE_CONV_IN_LAYOUT[^\n]+, 0\);"),
        "nchw_to_nhwc_calls": call_count(r"nchw_to_nhwc\(") - 1,
        "nhwc_to_nchw_calls": call_count(r"nhwc_to_nchw\(") - 1,
        "nhwc_to_ncl_calls": call_count(r"nhwc_to_ncl_i8\(") - 1,
        "tiled_conv_calls": call_count(r"tiled_conv_auto\(") + call_count(r"tiled_conv_stride_auto\("),
        "gemmini_silu_direct_concat": call_count(r"GEMMINI_SILU_DIRECT_CONCAT"),
    }
    stage4_heads = "Detection head lowering: location-major" in source
    gemmini_lut = "SiLU kernel: gemmini-lut" in source
    expected_contract = ({
        "direct_conv_zero_in_layout": 75,
        "nchw_to_nhwc_calls": 0,
        "nhwc_to_nchw_calls": 0,
        "nhwc_to_ncl_calls": 0,
        "tiled_conv_calls": 75,
        "gemmini_silu_direct_concat": 8 if gemmini_lut else 0,
    } if stage4_heads else {
        "direct_conv_zero_in_layout": 75,
        "nchw_to_nhwc_calls": 1,
        "nhwc_to_nchw_calls": 1,
        "nhwc_to_ncl_calls": 6,
        "tiled_conv_calls": 76,
        "gemmini_silu_direct_concat": 0,
    })
    if source_contract != expected_contract:
        raise ValueError(f"generated source contract mismatch: {source_contract}")
    if "Physical feature layout: nhwc" not in source:
        raise ValueError("generated source is not marked as NHWC")

    validate_random_layout_kernels()
    print(
        "PASS: NHWC layout contract; "
        f"direct_convs={direct_convs} bridged_convs={bridged_convs} "
        f"head_reorders={0 if stage4_heads else reshape_boundaries} "
        f"feature_concats={feature_concats} stage4_heads={stage4_heads}"
    )
    print("PASS: randomized NHWC Concat/Reshape/Resize/MaxPool index checks")


if __name__ == "__main__":
    main()
