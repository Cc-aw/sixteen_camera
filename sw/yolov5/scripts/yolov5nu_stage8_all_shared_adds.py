#!/usr/bin/env python3
"""Build the cumulative seven-Add shared-scale Stage 8 candidate."""

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
from onnx import helper

import yolov5nu_stage0_baseline as stage0
import yolov5nu_stage8a_shared_scale as stage8a


ROOT = stage0.ROOT
MODEL_DIR = stage0.MODEL_DIR
SOURCE_MODEL = stage0.MODEL
OUTPUT_DIR = MODEL_DIR / "stage8_all_shared_adds"
MODEL = OUTPUT_DIR / "yolov5nu-stage8-all-shared-adds.onnx"
MANIFEST = OUTPUT_DIR / "yolov5nu-stage8-all-shared-adds.graph.json"
REFERENCE = OUTPUT_DIR / "ort_reference.json"
AUDIT = OUTPUT_DIR / "audit.json"
AOT_DIR = OUTPUT_DIR / "aot"
STEM = "yolov5nu-stage8c-model2-alladds-image025-profile"
IMAGE_IDS = ("025", "036", "142", "404", "650")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command", choices=("model", "validate", "aot", "elf", "all"),
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


def add_debug_outputs(model: onnx.ModelProto, names: list[str]) -> onnx.ModelProto:
    result = copy.deepcopy(model)
    existing = {item.name for item in result.graph.output}
    for name in names:
        if name not in existing:
            result.graph.output.append(
                helper.make_tensor_value_info(name, onnx.TensorProto.INT8, None)
            )
    return result


def output_record(manifest: dict[str, Any], op_name: str) -> dict[str, Any]:
    op = next(item for item in manifest["ops"] if item["name"] == op_name)
    return op["output_quantization"][op["outputs"][0]]


def create_model(python: Path) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    source = onnx.load(SOURCE_MODEL, load_external_data=True)
    onnx.checker.check_model(source)
    initial_groups = stage8a.feature_add_groups(source)
    candidate = source
    changes = []
    applied = []

    # Re-read groups after every edit. In the model.4/model.6 chains, changing
    # an earlier Add output also changes the next Add's first input scale.
    for add_name in stage8a.FEATURE_ADD_NAMES:
        groups = stage8a.feature_add_groups(candidate)
        group = next(item for item in groups if item["add_name"] == add_name)
        before = [float(item["scale"]) for item in group["inputs"]]
        shared = max(before)
        candidate, current_changes = stage8a.update_graph(candidate, group, shared)
        after_group = next(
            item for item in stage8a.feature_add_groups(candidate)
            if item["add_name"] == add_name
        )
        after = [float(item["scale"]) for item in after_group["inputs"]]
        if after[0] != after[1]:
            raise ValueError(f"failed to share {add_name}: {after}")
        changes.extend(current_changes)
        applied.append({
            "add_name": add_name,
            "input_scales_before": before,
            "shared_scale": shared,
            "output_scale": float(after_group["output"]["scale"]),
            "changed_initializers": current_changes,
        })

    onnx.checker.check_model(candidate)
    onnx.save(candidate, MODEL)
    run([
        str(python), str(ROOT / "scripts/yolov5nu_graph_parser.py"),
        "--model", str(MODEL), "--output", str(MANIFEST),
    ])
    final_groups = stage8a.feature_add_groups(candidate)
    report = {
        "format": "yolov5nu-stage8-all-shared-adds-audit-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "source_model": stage8a.artifact(SOURCE_MODEL),
        "candidate_model": stage8a.artifact(MODEL),
        "initial_groups": initial_groups,
        "applied_groups": applied,
        "final_groups": final_groups,
        "changed_initializer_records": changes,
        "policy": "topological cumulative max",
        "zero_point": 0,
    }
    AUDIT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {MODEL}")
    for group in final_groups:
        scales = [item["scale"] for item in group["inputs"]]
        print(f"{group['add_name']}: {scales} -> {group['output']['scale']}")


def validate_model() -> None:
    manifest = json.loads(MANIFEST.read_text())
    model = onnx.load(MODEL, load_external_data=True)
    groups = stage8a.feature_add_groups(model)
    debug_names = []
    for group in groups:
        debug_names.extend(item["q_tensor"] for item in group["inputs"])
        debug_names.append(group["output"]["q_tensor"])
    class_logits = output_record(manifest, "/model.24/Concat_1")
    classes_record = output_record(manifest, "/model.24/Sigmoid")
    dfl_record = output_record(manifest, "/model.24/dfl/Reshape_1")
    final_names = [
        class_logits["quantized_tensor"], classes_record["quantized_tensor"],
        dfl_record["quantized_tensor"],
    ]
    requested = list(dict.fromkeys(debug_names + final_names))
    debug = add_debug_outputs(model, requested)
    results = []
    exhaustive = []
    signed = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
    left = signed[:, None]
    right = signed[None, :]
    for group in groups:
        scales = [float(item["scale"]) for item in group["inputs"]]
        if scales[0] != scales[1]:
            raise ValueError(f"non-shared Add: {group['add_name']} {scales}")
        output_scale = float(group["output"]["scale"])
        expected = np.clip(
            np.rint((left + right) * np.float32(scales[0]) / np.float32(output_scale)),
            -128, 127,
        ).astype(np.int8)
        gemmini = np.clip(
            np.rint((left + right) * np.float32(scales[0] / output_scale)),
            -128, 127,
        ).astype(np.int8)
        delta = np.abs(expected.astype(np.int16) - gemmini.astype(np.int16))
        mismatches = int(np.count_nonzero(delta))
        if mismatches:
            raise ValueError(f"{group['add_name']}: host Gemmini contract mismatches={mismatches}")
        exhaustive.append({
            "add_name": group["add_name"], "cases": 65536,
            "mismatches": mismatches, "max_error": int(delta.max()),
        })

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
            logits = outputs[final_names[0]]
            classes = outputs[final_names[1]].reshape(80, 2100)
            dfl = outputs[final_names[2]].reshape(4, 2100)
            top = stage0.top_detections(
                dfl, float(dfl_record["scale"]), classes, float(classes_record["scale"])
            )
            nms = stage0.nms_detections(
                dfl, float(dfl_record["scale"]), classes, float(classes_record["scale"])
            )
            add_summaries = {}
            for group in groups:
                name = group["output"]["q_tensor"]
                add_summaries[group["add_name"]] = stage0.tensor_summary(outputs[name])
            record = {
                "image_id": image_id,
                "image": stage0.image_path(image_id).name,
                "class_logits": stage0.tensor_summary(logits),
                "class_scores": stage0.tensor_summary(classes),
                "dfl": stage0.tensor_summary(dfl),
                "top_lines": [stage0.detection_line(i, item) for i, item in enumerate(top)],
                "nms_lines": [stage0.detection_line(i, item) for i, item in enumerate(nms)],
                "add_outputs": add_summaries,
            }
            results.append(record)
            print(
                f"image{image_id}: logits={record['class_logits']['checksum']} "
                f"classes={record['class_scores']['checksum']} top={record['top_lines'][0]}"
            )
    REFERENCE.write_text(json.dumps({
        "format": "yolov5nu-stage8-all-shared-adds-reference-v1",
        "model": stage8a.artifact(MODEL),
        "exhaustive_add_contract": exhaustive,
        "images": results,
    }, indent=2) + "\n")
    print(f"PASS: 7 Add groups x 65536 host contract cases; wrote {REFERENCE}")


def generate_aot(python: Path) -> None:
    AOT_DIR.mkdir(parents=True, exist_ok=True)
    generator = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"
    run([
        str(python), str(generator), "--model", str(MODEL),
        "--manifest", str(MANIFEST), "--image", str(stage0.image_path("025")),
        "--output-dir", str(AOT_DIR), "--stem", STEM,
        "--physical-layout", "nhwc", "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut", "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio", "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only", "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e", "--stage8-mode", "8c-model2-alladds",
        "--stage8-add-name", "/model.2/m/m.0/Add", "--memory-stage", "5d",
    ])
    source = (AOT_DIR / f"{STEM}.c").read_text()
    memory = json.loads((AOT_DIR / f"{STEM}_memory.json").read_text())
    contract = {
        "shared_resadd_calls": source.count("add_gemmini_shared_resadd_i8(") - 1,
        "splitk_calls": source.count("gemmini_splitk_1x1_two_slice_i8(") - 1,
        "model2_concat_elided": source.count("STAGE8_CONCAT_ELIDED: /model.2/Concat"),
        "direct_concat": len(memory["direct_concat"]),
        "arena_bytes": int(memory["arena_bytes"]),
    }
    expected = {
        "shared_resadd_calls": 7, "splitk_calls": 1,
        "model2_concat_elided": 1, "direct_concat": 9,
        "arena_bytes": 846400,
    }
    if contract != expected:
        raise ValueError(f"invalid all-Add AOT contract: {contract}, expected {expected}")
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_baremetal_reference.py"),
        "--model", str(MODEL), "--manifest", str(MANIFEST),
        "--image", str(stage0.image_path("025")),
    ], log=OUTPUT_DIR / "conv_qdq_validation.log")
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_silu_fusion.py"),
        "--manifest", str(MANIFEST), "--source", str(AOT_DIR / f"{STEM}.c"),
        "--parameters", str(AOT_DIR / f"{STEM}_params.h"),
    ], log=OUTPUT_DIR / "silu_lut_validation.log")
    (OUTPUT_DIR / "aot_contract.json").write_text(json.dumps(contract, indent=2) + "\n")
    print(f"PASS: AOT contract {contract}")


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
        "YOLOV5NU_STAGE8_MODE": "8c-model2-alladds",
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
    if args.command in {"model", "all"}:
        create_model(python)
    if args.command in {"validate", "all"}:
        validate_model()
    if args.command in {"aot", "all"}:
        generate_aot(python)
    if args.command in {"elf", "all"}:
        build_elf(python)


if __name__ == "__main__":
    main()
