#!/usr/bin/env python3
"""Build and validate /model.2 Concat-to-Conv split-K Stage 8C."""

from __future__ import annotations

import argparse
import copy
import json
import os
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import onnx
import onnxruntime as ort
from onnx import helper, numpy_helper

import yolov5nu_stage0_baseline as stage0


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
STAGE8A_DIR = MODEL_DIR / "stage8a_shared_scale"
MODEL = STAGE8A_DIR / "yolov5nu-stage8a-shared-scale.onnx"
MANIFEST = STAGE8A_DIR / "yolov5nu-stage8a-shared-scale.graph.json"
OUTPUT_DIR = MODEL_DIR / "stage8c_model2_splitk"
IMAGE_IDS = ("025", "036", "142", "404", "650")
STEM = "yolov5nu-stage8c-model2-splitk-image025-profile"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command", choices=("build", "validate", "elf", "all"),
        default="all", nargs="?",
    )
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def operation(manifest: dict[str, Any], name: str) -> dict[str, Any]:
    return next(item for item in manifest["ops"] if item["name"] == name)


def output_record(op: dict[str, Any]) -> dict[str, Any]:
    return op["output_quantization"][op["outputs"][0]]


def quantize(values: np.ndarray, scale: float) -> np.ndarray:
    return np.clip(
        np.rint(values.astype(np.float32) / np.float32(scale)), -128, 127
    ).astype(np.int8)


def requantize(values: np.ndarray, source_scale: float, target_scale: float) -> np.ndarray:
    real = values.astype(np.float32) * np.float32(source_scale)
    return quantize(real, target_scale)


def compare(name: str, actual: np.ndarray, expected: np.ndarray) -> dict[str, int]:
    actual = np.asarray(actual, dtype=np.int8).reshape(-1)
    expected = np.asarray(expected, dtype=np.int8).reshape(-1)
    delta = np.abs(actual.astype(np.int16) - expected.astype(np.int16))
    result = {
        "elements": int(actual.size),
        "mismatches": int(np.count_nonzero(delta)),
        "max_error": int(delta.max(initial=0)),
        "checksum": int(actual.astype(np.int64).sum()),
    }
    if result["mismatches"]:
        first = int(np.flatnonzero(delta)[0])
        raise ValueError(
            f"{name}: {result['mismatches']}/{result['elements']} mismatches, "
            f"max_error={result['max_error']}, first={first}, "
            f"actual={int(actual[first])}, expected={int(expected[first])}"
        )
    return result


def build(python: Path) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    generator = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"
    run([
        str(python), str(generator),
        "--model", str(MODEL), "--manifest", str(MANIFEST),
        "--image", str(stage0.image_path("025")),
        "--output-dir", str(OUTPUT_DIR), "--stem", STEM,
        "--physical-layout", "nhwc", "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut", "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio", "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only", "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e", "--stage8-mode", "8c-model2",
        "--stage8-add-name", "/model.2/m/m.0/Add", "--memory-stage", "5d",
    ])


def build_elf(python: Path) -> None:
    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python),
        "YOLOV5NU_MODEL": str(MODEL),
        "YOLOV5NU_MANIFEST": str(MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path("025")),
        "YOLOV5NU_STEM": STEM,
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
        "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut",
        "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio",
        "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "YOLOV5NU_HEAD_OUTPUT_MODE": "detection-only",
        "YOLOV5NU_HEAD_CANDIDATE_KERNEL": "rvv",
        "YOLOV5NU_STAGE7_MODE": "7e",
        "YOLOV5NU_STAGE8_MODE": "8c-model2",
        "YOLOV5NU_STAGE8_ADD_NAME": "/model.2/m/m.0/Add",
        "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_CFLAGS": (
            "-DYOLOV5NU_PROFILE=1 -DYOLOV5NU_LAYER_STATS=0 "
            "-DYOLOV5NU_FINAL_TENSOR_STATS=1"
        ),
    })
    run([str(ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh")], env=environment)


def validate() -> dict[str, Any]:
    manifest = json.loads(MANIFEST.read_text())
    model = onnx.load(MODEL, load_external_data=True)
    arrays = {item.name: numpy_helper.to_array(item) for item in model.graph.initializer}
    quantization = manifest["tensor_quantization"]
    add = operation(manifest, "/model.2/m/m.0/Add")
    concat = operation(manifest, "/model.2/Concat")
    conv = operation(manifest, "/model.2/cv3/conv/Conv")
    sigmoid = operation(manifest, "/model.2/cv3/act/Sigmoid")
    mul = operation(manifest, "/model.2/cv3/act/Mul")

    add_q = output_record(add)
    slice1_q = quantization[concat["inputs"][1]]
    concat_q = output_record(concat)
    conv_q = output_record(conv)
    sigmoid_q = output_record(sigmoid)
    mul_q = output_record(mul)
    requested = [
        add_q["quantized_tensor"], slice1_q["quantized_tensor"],
        concat_q["quantized_tensor"], conv_q["quantized_tensor"],
        sigmoid_q["quantized_tensor"], mul_q["quantized_tensor"],
    ]

    debug = copy.deepcopy(model)
    existing = {item.name for item in debug.graph.output}
    for name in requested:
        if name not in existing:
            debug.graph.output.append(helper.make_tensor_value_info(name, onnx.TensorProto.INT8, None))

    weight = arrays[conv["weight"]["initializer"]].reshape(32, 32).T.astype(np.int32)
    bias = arrays[conv["bias"]["initializer"]].reshape(1, 32).astype(np.int32)
    conv_requant = (
        np.float32(concat_q["scale"]) * np.float32(conv["weight"]["scale"])
        / np.float32(conv_q["scale"])
    )
    signed = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
    logits = np.clip(signed * np.float32(conv_q["scale"]), -80.0, 80.0)
    sigmoid_lut = quantize(
        np.float32(1.0) / (np.float32(1.0) + np.exp(-logits)),
        float(sigmoid_q["scale"]),
    ).astype(np.float32)
    silu_real = signed * np.float32(conv_q["scale"])
    silu_real *= sigmoid_lut * np.float32(sigmoid_q["scale"])
    silu_lut = quantize(silu_real, float(mul_q["scale"]))

    source_path = OUTPUT_DIR / f"{STEM}.c"
    memory_path = OUTPUT_DIR / f"{STEM}_memory.json"
    source = source_path.read_text()
    memory = json.loads(memory_path.read_text())
    source_contract = {
        "splitk_calls": source.count("gemmini_splitk_1x1_two_slice_i8(") - 1,
        "shared_resadd_calls": source.count("add_gemmini_shared_resadd_i8(") - 1,
        "concat_elided_markers": source.count("STAGE8_CONCAT_ELIDED: /model.2/Concat"),
        "splitk_markers": source.count("STAGE8_SPLITK_CONCAT_CONV: /model.2/Concat"),
        "direct_concat": len(memory["direct_concat"]),
        "arena_bytes": int(memory["arena_bytes"]),
        "model2_concat_inactive": concat_q["quantized_tensor"] in memory["inactive_tensors"],
    }
    expected_contract = {
        "splitk_calls": 1,
        "shared_resadd_calls": 1,
        "concat_elided_markers": 1,
        "splitk_markers": 1,
        "direct_concat": 12,
        "arena_bytes": 846400,
        "model2_concat_inactive": True,
    }
    if source_contract != expected_contract:
        raise ValueError(f"invalid Stage 8C source contract: {source_contract}")

    image_results = []
    with tempfile.NamedTemporaryFile(suffix=".onnx") as temporary:
        onnx.save(debug, temporary.name)
        session = ort.InferenceSession(temporary.name, providers=["CPUExecutionProvider"])
        input_name = session.get_inputs()[0].name
        for image_id in IMAGE_IDS:
            values = session.run(
                requested,
                {input_name: stage0.letterbox(stage0.image_path(image_id), 320, 320)},
            )
            outputs = dict(zip(requested, values))
            slice0 = outputs[add_q["quantized_tensor"]].transpose(0, 2, 3, 1).reshape(6400, 16)
            slice1 = outputs[slice1_q["quantized_tensor"]].transpose(0, 2, 3, 1).reshape(6400, 16)
            material = outputs[concat_q["quantized_tensor"]].transpose(0, 2, 3, 1).reshape(6400, 32)
            split_material = np.concatenate([
                requantize(slice0, float(add_q["scale"]), float(concat_q["scale"])),
                requantize(slice1, float(slice1_q["scale"]), float(concat_q["scale"])),
            ], axis=1)
            concat_check = compare("materialized Concat", split_material, material)

            accumulator = split_material.astype(np.int32) @ weight + bias
            predicted_conv = np.clip(
                np.rint(accumulator.astype(np.float32) * conv_requant), -128, 127
            ).astype(np.int8)
            target_conv = outputs[conv_q["quantized_tensor"]].transpose(0, 2, 3, 1).reshape(6400, 32)
            conv_check = compare("split-K Conv", predicted_conv, target_conv)
            predicted_silu = silu_lut[predicted_conv.view(np.uint8)]
            target_silu = outputs[mul_q["quantized_tensor"]].transpose(0, 2, 3, 1).reshape(6400, 32)
            silu_check = compare("split-K Conv+SiLU", predicted_silu, target_silu)
            image_results.append({
                "image_id": image_id,
                "concat": concat_check,
                "conv": conv_check,
                "silu": silu_check,
            })
            print(f"image{image_id}: PASS material Concat, split-K Conv and SiLU")

    report = {
        "format": "yolov5nu-stage8c-model2-splitk-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "model": str(MODEL),
        "source_contract": source_contract,
        "scales": {
            "slice0": add_q["scale"],
            "slice1": slice1_q["scale"],
            "concat": concat_q["scale"],
            "conv_output": conv_q["scale"],
            "conv_requant": float(conv_requant),
        },
        "images": image_results,
        "hardware_note": "Accumulator persistence and mvin rounding still require target validation.",
    }
    path = OUTPUT_DIR / "validation.json"
    path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {path}")
    return report


def main() -> None:
    args = parse_args()
    if args.command in {"build", "all"}:
        build(args.python.resolve())
    if args.command in {"validate", "all"}:
        validate()
    if args.command in {"elf", "all"}:
        build_elf(args.python.resolve())


if __name__ == "__main__":
    main()
