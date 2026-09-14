#!/usr/bin/env python3
"""Build and validate Stage 8 single- and dual-consumer Concat-Conv fusions."""

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
OUTPUT_DIR = MODEL_DIR / "stage8c_single_consumer_splitk"
STEM = "yolov5nu-stage8c-single-consumer-splitk-image025-profile"
IMAGE_IDS = ("025", "036", "142", "404", "650")
FUSIONS = {
    "/model.2/Concat": "/model.2/cv3/conv/Conv",
    "/model.4/Concat": "/model.4/cv3/conv/Conv",
    "/model.6/Concat": "/model.6/cv3/conv/Conv",
    "/model.8/Concat": "/model.8/cv3/conv/Conv",
    "/model.9/Concat": "/model.9/cv2/conv/Conv",
    "/model.13/Concat": "/model.13/cv3/conv/Conv",
    "/model.17/Concat": "/model.17/cv3/conv/Conv",
    "/model.20/Concat": "/model.20/cv3/conv/Conv",
    "/model.23/Concat": "/model.23/cv3/conv/Conv",
}
DUAL_FUSIONS = {
    "/model.12/Concat#cv1": "/model.13/cv1/conv/Conv",
    "/model.12/Concat#cv2": "/model.13/cv2/conv/Conv",
    "/model.16/Concat#cv1": "/model.17/cv1/conv/Conv",
    "/model.16/Concat#cv2": "/model.17/cv2/conv/Conv",
    "/model.19/Concat#cv1": "/model.20/cv1/conv/Conv",
    "/model.19/Concat#cv2": "/model.20/cv2/conv/Conv",
    "/model.22/Concat#cv1": "/model.23/cv1/conv/Conv",
    "/model.22/Concat#cv2": "/model.23/cv2/conv/Conv",
}
ACTIVE_FUSIONS = FUSIONS
STAGE8_MODE = "8c-single-consumer-splitk"
IMAGE_ID = "025"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command", choices=("build", "validate", "elf", "all", "dual"),
        default="all", nargs="?",
    )
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument(
        "--image-id", choices=("025", "036", "142", "404", "650"),
        default="025", help="embedded image used for the generated ELF",
    )
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


def canonical_concat_name(name: str) -> str:
    return name.split("#", 1)[0]


def output_record(op: dict[str, Any]) -> dict[str, Any]:
    return op["output_quantization"][op["outputs"][0]]


def compare_qdq(
    name: str, actual: np.ndarray, expected: np.ndarray, max_allowed_error: int
) -> dict[str, int]:
    actual = np.asarray(actual, dtype=np.int8).reshape(-1)
    expected = np.asarray(expected, dtype=np.int8).reshape(-1)
    delta = np.abs(actual.astype(np.int16) - expected.astype(np.int16))
    result = {
        "elements": int(actual.size),
        "mismatches": int(np.count_nonzero(delta)),
        "max_error": int(delta.max(initial=0)),
        "checksum": int(actual.astype(np.int64).sum()),
    }
    if result["max_error"] > max_allowed_error:
        raise ValueError(
            f"{name}: QDQ reference max_error={result['max_error']}, "
            f"mismatches={result['mismatches']}/{result['elements']}"
        )
    return result


def compare_accumulators(
    name: str, actual: np.ndarray, expected: np.ndarray
) -> dict[str, int]:
    actual = np.asarray(actual, dtype=np.int64).reshape(-1)
    expected = np.asarray(expected, dtype=np.int64).reshape(-1)
    mismatch = np.flatnonzero(actual != expected)
    result = {
        "elements": int(actual.size),
        "mismatches": int(mismatch.size),
        "max_error": int(np.abs(actual - expected).max(initial=0)),
        "checksum": int(actual.sum()),
    }
    if mismatch.size:
        first = int(mismatch[0])
        raise ValueError(
            f"{name}: accumulator mismatch at {first}: "
            f"{int(actual[first])} != {int(expected[first])}"
        )
    return result


def build(python: Path) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    generator = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"
    run([
        str(python), str(generator), "--model", str(MODEL),
        "--manifest", str(MANIFEST), "--image", str(stage0.image_path(IMAGE_ID)),
        "--output-dir", str(OUTPUT_DIR), "--stem", STEM,
        "--physical-layout", "nhwc", "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut", "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio", "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only", "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e", "--stage8-mode", STAGE8_MODE,
        "--stage8-add-name", "/model.2/m/m.0/Add", "--memory-stage", "5d",
    ])
    source = (OUTPUT_DIR / f"{STEM}.c").read_text()
    memory = json.loads((OUTPUT_DIR / f"{STEM}_memory.json").read_text())
    inactive = set(memory["inactive_tensors"])
    contract = {
        "shared_resadd_calls": source.count("add_gemmini_shared_resadd_i8(") - 1,
        "two_slice_calls": source.count("gemmini_splitk_1x1_two_slice_i8(") - 1,
        "multi_slice_calls": source.count("gemmini_splitk_1x1_multi_slice_i8(") - 1,
        "concat_elided_markers": source.count("STAGE8_CONCAT_ELIDED:"),
        "splitk_markers": source.count("STAGE8_SPLITK_CONCAT_CONV:"),
        "direct_concat": len(memory["direct_concat"]),
        "arena_bytes": int(memory["arena_bytes"]),
        "inactive_fused_concats": sum(
            output_record(
                operation(json.loads(MANIFEST.read_text()), canonical_concat_name(name))
            )["quantized_tensor"]
            in inactive for name in {canonical_concat_name(name) for name in ACTIVE_FUSIONS}
        ),
    }
    expected = {
        "shared_resadd_calls": 7,
        "two_slice_calls": 8 if len(ACTIVE_FUSIONS) == 9 else 16,
        "multi_slice_calls": 1,
        "concat_elided_markers": len({canonical_concat_name(name) for name in ACTIVE_FUSIONS}),
        "splitk_markers": len(ACTIVE_FUSIONS),
        "direct_concat": 2 if len(ACTIVE_FUSIONS) == 9 else 0,
        "arena_bytes": 784000 if len(ACTIVE_FUSIONS) == 9 else 739200,
        "inactive_fused_concats": 9 if len(ACTIVE_FUSIONS) == 9 else 13,
    }
    if contract != expected:
        raise ValueError(f"invalid single-consumer AOT contract: {contract}, expected {expected}")
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
    print(f"PASS: single-consumer AOT contract {contract}")


def fusion_record(manifest: dict[str, Any], arrays: dict[str, np.ndarray],
                  concat_name: str, conv_name: str) -> dict[str, Any]:
    quantization = manifest["tensor_quantization"]
    layouts = manifest["tensor_layouts"]
    concat = operation(manifest, canonical_concat_name(concat_name))
    conv = operation(manifest, conv_name)
    activation_base = conv_name.removesuffix("/conv/Conv")
    sigmoid = operation(manifest, activation_base + "/act/Sigmoid")
    mul = operation(manifest, activation_base + "/act/Mul")
    slices = [quantization[name] for name in concat["inputs"]]
    channels = [
        int(layouts[item["quantized_tensor"]]["logical_shape"][1]) for item in slices
    ]
    concat_q = output_record(concat)
    conv_q = output_record(conv)
    sigmoid_q = output_record(sigmoid)
    mul_q = output_record(mul)
    out_channels, in_channels, kh, kw = map(int, conv["weight"]["shape"])
    if kh != 1 or kw != 1 or sum(channels) != in_channels:
        raise ValueError(f"{concat_name}: unsupported geometry")
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
    output_shape = [int(item) for item in conv["output_shapes"][conv["outputs"][0]]]
    return {
        "concat_name": concat_name, "conv_name": conv_name,
        "slice_records": slices, "slice_channels": channels,
        "concat": concat_q, "conv": conv_q, "mul": mul_q,
        "weight": weight, "bias": bias, "conv_requant": conv_requant,
        "silu_lut": stage8c.quantize(silu_real, float(mul_q["scale"])),
        "out_channels": out_channels,
        "positions": output_shape[0] * output_shape[2] * output_shape[3],
    }


def validate() -> None:
    manifest = json.loads(MANIFEST.read_text())
    model = onnx.load(MODEL, load_external_data=True)
    arrays = {item.name: numpy_helper.to_array(item) for item in model.graph.initializer}
    records = [
        fusion_record(manifest, arrays, concat, conv)
        for concat, conv in ACTIVE_FUSIONS.items()
    ]
    results_by_image: dict[str, list[dict[str, Any]]] = {
        image_id: [] for image_id in IMAGE_IDS
    }
    # Keep each fusion in an independent debug graph. Exposing dozens of QDQ
    # intermediates at once can change ORT's float Conv fusion/accumulation
    # plan and move a tie by one LSB, which makes the observer alter the target.
    for record in records:
        requested = [
            *(item["quantized_tensor"] for item in record["slice_records"]),
            record["concat"]["quantized_tensor"],
            record["conv"]["quantized_tensor"],
            record["mul"]["quantized_tensor"],
        ]
        debug = copy.deepcopy(model)
        existing = {item.name for item in debug.graph.output}
        for name in requested:
            if name not in existing:
                debug.graph.output.append(
                    helper.make_tensor_value_info(name, onnx.TensorProto.INT8, None)
                )
        with tempfile.NamedTemporaryFile(suffix=".onnx") as temporary:
            onnx.save(debug, temporary.name)
            session = ort.InferenceSession(
                temporary.name, providers=["CPUExecutionProvider"]
            )
            input_name = session.get_inputs()[0].name
            for image_id in IMAGE_IDS:
                outputs = dict(zip(
                    requested,
                    session.run(
                        requested,
                        {input_name: stage0.letterbox(
                            stage0.image_path(image_id), 320, 320
                        )},
                    ),
                ))
                positions = record["positions"]
                slices = [
                    outputs[item["quantized_tensor"]].transpose(0, 2, 3, 1).reshape(
                        positions, channels
                    )
                    for item, channels in zip(
                        record["slice_records"], record["slice_channels"]
                    )
                ]
                material = outputs[record["concat"]["quantized_tensor"]].transpose(
                    0, 2, 3, 1
                ).reshape(positions, sum(record["slice_channels"]))
                split_material = np.concatenate([
                    stage8c.requantize(
                        values, float(item["scale"]), float(record["concat"]["scale"])
                    )
                    for values, item in zip(slices, record["slice_records"])
                ], axis=1)
                concat_check = stage8c.compare(
                    record["concat_name"] + " Concat", split_material, material
                )
                material_accumulator = (
                    material.astype(np.int32) @ record["weight"] + record["bias"]
                )
                accumulator = np.broadcast_to(
                    record["bias"], material_accumulator.shape
                ).copy()
                weight_offset = 0
                for values, item, channels in zip(
                    slices, record["slice_records"], record["slice_channels"]
                ):
                    requantized = stage8c.requantize(
                        values,
                        float(item["scale"]),
                        float(record["concat"]["scale"]),
                    )
                    accumulator += (
                        requantized.astype(np.int32)
                        @ record["weight"][weight_offset:weight_offset + channels]
                    )
                    weight_offset += channels
                accumulator_check = compare_accumulators(
                    record["conv_name"] + " accumulator",
                    accumulator,
                    material_accumulator,
                )
                material_conv = np.clip(
                    np.rint(
                        material_accumulator.astype(np.float32)
                        * record["conv_requant"]
                    ),
                    -128, 127,
                ).astype(np.int8)
                predicted_conv = np.clip(
                    np.rint(accumulator.astype(np.float32) * record["conv_requant"]),
                    -128, 127,
                ).astype(np.int8)
                hardware_conv_check = stage8c.compare(
                    record["conv_name"] + " material-vs-split Conv",
                    predicted_conv,
                    material_conv,
                )
                target_conv = outputs[record["conv"]["quantized_tensor"]].transpose(
                    0, 2, 3, 1
                ).reshape(positions, record["out_channels"])
                conv_check = compare_qdq(
                    record["conv_name"] + " Conv", predicted_conv, target_conv, 1
                )
                predicted_silu = record["silu_lut"][predicted_conv.view(np.uint8)]
                material_silu = record["silu_lut"][material_conv.view(np.uint8)]
                hardware_silu_check = stage8c.compare(
                    record["conv_name"] + " material-vs-split SiLU",
                    predicted_silu,
                    material_silu,
                )
                target_silu = outputs[record["mul"]["quantized_tensor"]].transpose(
                    0, 2, 3, 1
                ).reshape(positions, record["out_channels"])
                silu_check = compare_qdq(
                    record["conv_name"] + " SiLU", predicted_silu, target_silu, 2
                )
                results_by_image[image_id].append({
                    "concat": record["concat_name"], "conv": record["conv_name"],
                    "slices": len(slices), "channels": record["slice_channels"],
                    "positions": positions, "out_channels": record["out_channels"],
                    "concat_check": concat_check,
                    "hardware_conv_check": hardware_conv_check,
                    "conv_qdq_check": conv_check,
                    "accumulator_check": accumulator_check, "silu_check": silu_check,
                    "hardware_silu_check": hardware_silu_check,
                })
    image_results = []
    for image_id in IMAGE_IDS:
        checks = results_by_image[image_id]
        image_results.append({"image_id": image_id, "fusions": checks})
        print(
            f"image{image_id}: PASS {len(ACTIVE_FUSIONS)} Concat, Conv and SiLU checks"
        )
    report = {
        "format": "yolov5nu-stage8c-single-consumer-splitk-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass", "fence_between_partials": True,
        "images": image_results,
        "hardware_note": "Four-slice model9 scheduling requires FPGA validation.",
    }
    path = OUTPUT_DIR / "validation.json"
    path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {path}")


def build_elf(python: Path) -> None:
    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python), "YOLOV5NU_MODEL": str(MODEL),
        "YOLOV5NU_MANIFEST": str(MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path(IMAGE_ID)), "YOLOV5NU_STEM": STEM,
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc", "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut", "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio", "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "YOLOV5NU_HEAD_OUTPUT_MODE": "detection-only",
        "YOLOV5NU_HEAD_CANDIDATE_KERNEL": "rvv", "YOLOV5NU_STAGE7_MODE": "7e",
        "YOLOV5NU_STAGE8_MODE": STAGE8_MODE,
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
    global ACTIVE_FUSIONS, OUTPUT_DIR, STEM, STAGE8_MODE, IMAGE_ID
    IMAGE_ID = args.image_id
    if args.command == "dual":
        ACTIVE_FUSIONS = {**FUSIONS, **DUAL_FUSIONS}
        OUTPUT_DIR = MODEL_DIR / "stage8c_all_consumer_splitk"
        STEM = f"yolov5nu-stage8c-all-consumer-splitk-image{IMAGE_ID}-profile"
        STAGE8_MODE = "8c-dual-consumer-splitk"
        args.command = "all"
    python = args.python.resolve()
    if args.command in {"build", "all"}:
        build(python)
    if args.command in {"validate", "all"}:
        validate()
    if args.command in {"elf", "all"}:
        build_elf(python)


if __name__ == "__main__":
    main()
