#!/usr/bin/env python3
"""Validate the YOLOv5nu Stage 2 quantized SiLU LUT lowering."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
GENERATOR_DIR = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet"
DEFAULT_MANIFEST = MODEL_DIR / "yolov5nu-gemmini-int8-img320.graph.json"
DEFAULT_STEM = "yolov5nu-stage2-nhwc-silulut-image025-profile"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--source", type=Path, default=GENERATOR_DIR / f"{DEFAULT_STEM}.c")
    parser.add_argument(
        "--parameters", type=Path, default=GENERATOR_DIR / f"{DEFAULT_STEM}_params.h"
    )
    return parser.parse_args()


def output_record(op: dict[str, Any]) -> dict[str, Any]:
    output = op["outputs"][0]
    return op["output_quantization"][output]


def selected_ops(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    selected = []
    for op in manifest["ops"]:
        selected.append(op)
        if op["name"] == "/model.24/dfl/Reshape_1":
            return selected
    raise ValueError("DFL terminal reshape was not found")


def find_patterns(manifest: dict[str, Any]) -> list[tuple[dict[str, Any], dict[str, Any]]]:
    selected = selected_ops(manifest)
    quantization = manifest["tensor_quantization"]
    layouts = manifest["tensor_layouts"]
    shapes: dict[str, list[int]] = {}
    input_record = manifest["input"][0]
    input_name = input_record["quantization"]["quantized_tensor"]
    shapes[input_name] = input_record["shape"]
    for op in selected:
        record = output_record(op)
        shapes[record["quantized_tensor"]] = op["output_shapes"][op["outputs"][0]]

    def q_record(float_name: str) -> dict[str, Any]:
        return quantization[float_name]

    def q_name(float_name: str) -> str:
        return q_record(float_name)["quantized_tensor"]

    def layout(name: str) -> str:
        return layouts[name]["nhwc_resident"]["physical_layout"]

    consumers: dict[str, list[dict[str, Any]]] = {}
    for op in selected:
        for name in op["inputs"]:
            if name in quantization:
                consumers.setdefault(q_name(name), []).append(op)

    patterns = []
    for sigmoid in selected:
        if sigmoid["op"] != "Sigmoid":
            continue
        input_name = q_name(sigmoid["inputs"][0])
        sigmoid_output = output_record(sigmoid)
        sigmoid_name = sigmoid_output["quantized_tensor"]
        output_consumers = consumers.get(sigmoid_name, [])
        if len(output_consumers) != 1 or output_consumers[0]["op"] != "Mul":
            continue
        mul = output_consumers[0]
        mul_inputs = [q_name(name) for name in mul["inputs"] if name in quantization]
        if len(mul_inputs) != 2 or sorted(mul_inputs) != sorted([input_name, sigmoid_name]):
            continue
        mul_output = output_record(mul)
        records = [q_record(sigmoid["inputs"][0]), sigmoid_output, mul_output]
        if any(
            record.get("dtype") != "int8" or int(record.get("zero_point", 1)) != 0
            for record in records
        ):
            continue
        if not (
            shapes[input_name] == shapes[sigmoid_name] == shapes[mul_output["quantized_tensor"]]
        ):
            continue
        if len({layout(input_name), layout(sigmoid_name), layout(mul_output["quantized_tensor"])}) != 1:
            continue
        patterns.append((sigmoid, mul))
    return patterns


def sigmoid_quantized(values: np.ndarray, input_scale: float, output_scale: float) -> np.ndarray:
    logits = np.clip(values * np.float32(input_scale), -80.0, 80.0)
    sigmoid = 1.0 / (1.0 + np.exp(-logits))
    return np.clip(
        np.rint(sigmoid / np.float32(output_scale)), -128, 127
    ).astype(np.int8)


def separate_silu_lut(
    input_scale: float, sigmoid_scale: float, output_scale: float
) -> np.ndarray:
    values = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
    sigmoid_values = sigmoid_quantized(values, input_scale, sigmoid_scale).astype(np.float32)
    real = values * np.float32(input_scale)
    real = real * sigmoid_values
    real = real * np.float32(sigmoid_scale)
    return np.clip(
        np.rint(real / np.float32(output_scale)), -128, 127
    ).astype(np.int8)


def parse_luts(parameters: str) -> dict[int, np.ndarray]:
    pattern = re.compile(
        r"static const elem_t yolov5nu_silu_lut(\d+)\[256\] = \{(.*?)\};",
        flags=re.DOTALL,
    )
    result = {}
    for match in pattern.finditer(parameters):
        values = np.fromstring(match.group(2).replace("\n", ""), sep=",", dtype=np.int16)
        if values.size != 256:
            raise ValueError(f"LUT {match.group(1)} has {values.size} entries")
        result[int(match.group(1))] = values.astype(np.int8)
    return result


def main() -> None:
    options = parse_args()
    manifest = json.loads(options.manifest.read_text())
    source = options.source.read_text()
    parameters = options.parameters.read_text()
    patterns = find_patterns(manifest)
    if len(patterns) != 69:
        raise ValueError(f"expected 69 safe SiLU patterns, found {len(patterns)}")

    luts = parse_luts(parameters)
    if sorted(luts) != list(range(69)):
        raise ValueError(f"expected LUT indices 0..68, found {sorted(luts)}")

    quantization = manifest["tensor_quantization"]
    for index, (sigmoid, mul) in enumerate(patterns):
        input_scale = float(quantization[sigmoid["inputs"][0]]["scale"])
        sigmoid_scale = float(output_record(sigmoid)["scale"])
        output_scale = float(output_record(mul)["scale"])
        expected = separate_silu_lut(input_scale, sigmoid_scale, output_scale)
        np.testing.assert_array_equal(
            luts[index], expected, err_msg=f"fused LUT mismatch: {mul['name']}"
        )

    def calls(name: str) -> int:
        count = len(re.findall(rf"\b{name}\(", source))
        if re.search(rf"\bstatic void {name}\(", source):
            count -= 1
        return count

    contract = {
        "silu_lut_calls": calls("silu_lut_i8") + calls("silu_lut_i8_strided"),
        "gemmini_lut_configs": len(re.findall(r"\bgemmini_config_silu_lut\(", source)),
        "gemmini_silu_convs": len(re.findall(r"\bSILU_LUT\s*,", source)),
        "sigmoid_calls": calls("sigmoid_i8"),
        "mul_calls": calls("mul_i8"),
        "fused_profile_records": len(
            re.findall(r"yolo_profile_add\(PROFILE_SILU_FUSED_LUT", source)
        ),
        "total_profile_records": len(re.findall(r"\byolo_profile_add\(", source)) - 2,
    }
    stage4_heads = "Detection head lowering: location-major" in source
    gemmini_lut = "SiLU kernel: gemmini-lut" in source
    expected_contract = ({
        "silu_lut_calls": 0 if gemmini_lut else 69,
        "gemmini_lut_configs": 69 if gemmini_lut else 0,
        "gemmini_silu_convs": 69 if gemmini_lut else 0,
        "sigmoid_calls": 0,
        "mul_calls": 0,
        "fused_profile_records": 69,
        "total_profile_records": 398,
    } if stage4_heads else {
        "silu_lut_calls": 69,
        "gemmini_lut_configs": 0,
        "gemmini_silu_convs": 0,
        "sigmoid_calls": 1,
        "mul_calls": 0,
        "fused_profile_records": 69,
        "total_profile_records": 413,
    })
    if contract != expected_contract:
        raise ValueError(f"generated source fusion contract mismatch: {contract}")
    if "SiLU mode: fused-lut" not in source:
        raise ValueError("generated source is not marked as fused-lut")
    if "YOLOV5NU_SILU_MODE_FUSED_LUT 1" not in parameters:
        raise ValueError("parameter header lacks fused-lut mode marker")
    if gemmini_lut and "YOLOV5NU_SILU_KERNEL_GEMMINI_LUT 1" not in parameters:
        raise ValueError("parameter header lacks Gemmini LUT kernel marker")

    print(
        "PASS: 69 safe quantized SiLU patterns; "
        "17664 exhaustive int8 LUT mappings match separate Sigmoid+Mul"
    )
    print(
        "PASS: generated fused source contract; "
        f"69 {'Gemmini LUT Conv activations' if gemmini_lut else 'fused calls'}, "
        f"{'fused Stage 4 class head' if stage4_heads else 'one final class Sigmoid'}, "
        "zero separate Mul calls"
    )


if __name__ == "__main__":
    main()
