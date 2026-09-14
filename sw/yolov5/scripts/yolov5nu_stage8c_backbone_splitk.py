#!/usr/bin/env python3
"""Build and validate four backbone Concat-to-Conv split-K fusions."""

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
import yolov5nu_stage8c_model2_splitk as stage8c


ROOT = stage0.ROOT
MODEL_DIR = stage0.MODEL_DIR
MODEL_BASE = MODEL_DIR / "stage8_all_shared_adds"
MODEL = MODEL_BASE / "yolov5nu-stage8-all-shared-adds.onnx"
MANIFEST = MODEL_BASE / "yolov5nu-stage8-all-shared-adds.graph.json"
OUTPUT_DIR = MODEL_DIR / "stage8c_backbone_splitk"
STEM = "yolov5nu-stage8c-backbone-splitk-image025-profile"
IMAGE_IDS = ("025", "036", "142", "404", "650")
BASES = ("model.2", "model.4", "model.6", "model.8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command", choices=("build", "validate", "elf", "all"),
        default="all", nargs="?",
    )
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def run(command: list[str], *, env: dict[str, str] | None = None,
        log: Path | None = None) -> None:
    print("+", " ".join(command), flush=True)
    if log is None:
        subprocess.run(command, cwd=ROOT, env=env, check=True)
        return
    completed = subprocess.run(
        command, cwd=ROOT, env=env, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    log.write_text(completed.stdout)
    if completed.returncode:
        raise subprocess.CalledProcessError(completed.returncode, command, completed.stdout)


def operation(manifest: dict[str, Any], name: str) -> dict[str, Any]:
    return next(item for item in manifest["ops"] if item["name"] == name)


def output_record(op: dict[str, Any]) -> dict[str, Any]:
    return op["output_quantization"][op["outputs"][0]]


def build(python: Path) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    generator = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"
    run([
        str(python), str(generator), "--model", str(MODEL),
        "--manifest", str(MANIFEST), "--image", str(stage0.image_path("025")),
        "--output-dir", str(OUTPUT_DIR), "--stem", STEM,
        "--physical-layout", "nhwc", "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut", "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio", "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only", "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e", "--stage8-mode", "8c-backbone-splitk",
        "--stage8-add-name", "/model.2/m/m.0/Add", "--memory-stage", "5d",
    ])
    source = (OUTPUT_DIR / f"{STEM}.c").read_text()
    memory = json.loads((OUTPUT_DIR / f"{STEM}_memory.json").read_text())
    inactive = set(memory["inactive_tensors"])
    contract = {
        "shared_resadd_calls": source.count("add_gemmini_shared_resadd_i8(") - 1,
        "splitk_calls": source.count("gemmini_splitk_1x1_two_slice_i8(") - 1,
        "concat_elided_markers": source.count("STAGE8_CONCAT_ELIDED:"),
        "splitk_markers": source.count("STAGE8_SPLITK_CONCAT_CONV:"),
        "direct_concat": len(memory["direct_concat"]),
        "arena_bytes": int(memory["arena_bytes"]),
        "inactive_fused_concats": sum(
            f"/{base}/Concat_output_0_QuantizeLinear_Output" in inactive
            for base in BASES
        ),
    }
    expected = {
        "shared_resadd_calls": 7,
        "splitk_calls": 4,
        "concat_elided_markers": 4,
        "splitk_markers": 4,
        "direct_concat": 7,
        "arena_bytes": 846400,
        "inactive_fused_concats": 4,
    }
    if contract != expected:
        raise ValueError(f"invalid Stage 8C AOT contract: {contract}, expected {expected}")
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_baremetal_reference.py"),
        "--model", str(MODEL), "--manifest", str(MANIFEST),
        "--image", str(stage0.image_path("025")),
    ], log=OUTPUT_DIR / "conv_qdq_validation.log")
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_silu_fusion.py"),
        "--manifest", str(MANIFEST), "--source", str(OUTPUT_DIR / f"{STEM}.c"),
        "--parameters", str(OUTPUT_DIR / f"{STEM}_params.h"),
    ], log=OUTPUT_DIR / "silu_lut_validation.log")
    (OUTPUT_DIR / "aot_contract.json").write_text(json.dumps(contract, indent=2) + "\n")
    print(f"PASS: Stage 8C backbone AOT contract {contract}")


def fusion_record(manifest: dict[str, Any], arrays: dict[str, np.ndarray],
                  base: str) -> dict[str, Any]:
    quantization = manifest["tensor_quantization"]
    concat = operation(manifest, f"/{base}/Concat")
    conv = operation(manifest, f"/{base}/cv3/conv/Conv")
    sigmoid = operation(manifest, f"/{base}/cv3/act/Sigmoid")
    mul = operation(manifest, f"/{base}/cv3/act/Mul")
    slices = [quantization[name] for name in concat["inputs"]]
    concat_q = output_record(concat)
    conv_q = output_record(conv)
    sigmoid_q = output_record(sigmoid)
    mul_q = output_record(mul)
    weight_shape = [int(item) for item in conv["weight"]["shape"]]
    out_channels, in_channels, kh, kw = weight_shape
    if kh != 1 or kw != 1 or out_channels != in_channels:
        raise ValueError(f"{base}: unsupported Conv shape {weight_shape}")
    slice_channels = in_channels // 2
    weight = arrays[conv["weight"]["initializer"]].reshape(
        out_channels, in_channels
    ).T.astype(np.int32)
    bias = arrays[conv["bias"]["initializer"]].reshape(1, out_channels).astype(np.int32)
    conv_requant = (
        np.float32(concat_q["scale"]) * np.float32(conv["weight"]["scale"])
        / np.float32(conv_q["scale"])
    )
    signed = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
    logits = np.clip(signed * np.float32(conv_q["scale"]), -80.0, 80.0)
    sigmoid_lut = stage8c.quantize(
        np.float32(1.0) / (np.float32(1.0) + np.exp(-logits)),
        float(sigmoid_q["scale"]),
    ).astype(np.float32)
    silu_real = signed * np.float32(conv_q["scale"])
    silu_real *= sigmoid_lut * np.float32(sigmoid_q["scale"])
    silu_lut = stage8c.quantize(silu_real, float(mul_q["scale"]))
    output_shape = [int(item) for item in conv["output_shapes"][conv["outputs"][0]]]
    positions = output_shape[0] * output_shape[2] * output_shape[3]
    return {
        "base": base,
        "slice_records": slices,
        "concat": concat_q,
        "conv": conv_q,
        "mul": mul_q,
        "weight": weight,
        "bias": bias,
        "conv_requant": conv_requant,
        "silu_lut": silu_lut,
        "slice_channels": slice_channels,
        "out_channels": out_channels,
        "positions": positions,
    }


def validate() -> None:
    manifest = json.loads(MANIFEST.read_text())
    model = onnx.load(MODEL, load_external_data=True)
    arrays = {item.name: numpy_helper.to_array(item) for item in model.graph.initializer}
    records = [fusion_record(manifest, arrays, base) for base in BASES]
    requested = []
    for record in records:
        requested.extend(item["quantized_tensor"] for item in record["slice_records"])
        requested.extend([
            record["concat"]["quantized_tensor"],
            record["conv"]["quantized_tensor"],
            record["mul"]["quantized_tensor"],
        ])
    requested = list(dict.fromkeys(requested))
    debug = copy.deepcopy(model)
    existing = {item.name for item in debug.graph.output}
    for name in requested:
        if name not in existing:
            debug.graph.output.append(helper.make_tensor_value_info(name, onnx.TensorProto.INT8, None))

    image_results = []
    with tempfile.NamedTemporaryFile(suffix=".onnx") as temporary:
        onnx.save(debug, temporary.name)
        session = ort.InferenceSession(temporary.name, providers=["CPUExecutionProvider"])
        input_name = session.get_inputs()[0].name
        for image_id in IMAGE_IDS:
            outputs = dict(zip(
                requested,
                session.run(
                    requested,
                    {input_name: stage0.letterbox(stage0.image_path(image_id), 320, 320)},
                ),
            ))
            checks = []
            for record in records:
                channels = record["slice_channels"]
                positions = record["positions"]
                slices = [
                    outputs[item["quantized_tensor"]].transpose(0, 2, 3, 1).reshape(
                        positions, channels
                    )
                    for item in record["slice_records"]
                ]
                material = outputs[record["concat"]["quantized_tensor"]].transpose(
                    0, 2, 3, 1
                ).reshape(positions, record["out_channels"])
                split_material = np.concatenate([
                    stage8c.requantize(
                        values, float(item["scale"]), float(record["concat"]["scale"])
                    )
                    for values, item in zip(slices, record["slice_records"])
                ], axis=1)
                concat_check = stage8c.compare(
                    f"{record['base']} materialized Concat", split_material, material
                )
                accumulator = split_material.astype(np.int32) @ record["weight"] + record["bias"]
                predicted_conv = np.clip(
                    np.rint(accumulator.astype(np.float32) * record["conv_requant"]),
                    -128, 127,
                ).astype(np.int8)
                target_conv = outputs[record["conv"]["quantized_tensor"]].transpose(
                    0, 2, 3, 1
                ).reshape(positions, record["out_channels"])
                conv_check = stage8c.compare(
                    f"{record['base']} split-K Conv", predicted_conv, target_conv
                )
                predicted_silu = record["silu_lut"][predicted_conv.view(np.uint8)]
                target_silu = outputs[record["mul"]["quantized_tensor"]].transpose(
                    0, 2, 3, 1
                ).reshape(positions, record["out_channels"])
                silu_check = stage8c.compare(
                    f"{record['base']} split-K Conv+SiLU", predicted_silu, target_silu
                )
                checks.append({
                    "base": record["base"], "concat": concat_check,
                    "conv": conv_check, "silu": silu_check,
                    "slice_channels": channels, "out_channels": record["out_channels"],
                    "positions": positions,
                })
            image_results.append({"image_id": image_id, "fusions": checks})
            print(f"image{image_id}: PASS 4 materialized Concats, split-K Convs and SiLUs")

    report = {
        "format": "yolov5nu-stage8c-backbone-splitk-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "model": str(MODEL),
        "fence_between_partials": True,
        "images": image_results,
        "hardware_note": "Generalized J/K loop geometry still requires FPGA validation.",
    }
    path = OUTPUT_DIR / "validation.json"
    path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {path}")


def build_elf(python: Path) -> None:
    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python), "YOLOV5NU_MODEL": str(MODEL),
        "YOLOV5NU_MANIFEST": str(MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path("025")), "YOLOV5NU_STEM": STEM,
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc", "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut", "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio", "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "YOLOV5NU_HEAD_OUTPUT_MODE": "detection-only",
        "YOLOV5NU_HEAD_CANDIDATE_KERNEL": "rvv", "YOLOV5NU_STAGE7_MODE": "7e",
        "YOLOV5NU_STAGE8_MODE": "8c-backbone-splitk",
        "YOLOV5NU_STAGE8_ADD_NAME": "/model.2/m/m.0/Add",
        "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_CFLAGS": (
            "-DYOLOV5NU_PROFILE=1 -DYOLOV5NU_LAYER_STATS=0 "
            "-DYOLOV5NU_FINAL_TENSOR_STATS=1"
        ),
    })
    run([str(ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh")], env=environment)


def main() -> None:
    args = parse_args()
    python = args.python.resolve()
    if args.command in {"build", "all"}:
        build(python)
    if args.command in {"validate", "all"}:
        validate()
    if args.command in {"elf", "all"}:
        build_elf(python)


if __name__ == "__main__":
    main()
