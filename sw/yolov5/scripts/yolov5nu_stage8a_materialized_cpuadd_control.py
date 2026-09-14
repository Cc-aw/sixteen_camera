#!/usr/bin/env python3
"""Build the materialized-Concat, CPU/RVV-Add control for five FPGA images."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

import yolov5nu_stage0_baseline as stage0


ROOT = stage0.ROOT
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
MODEL_BASE = MODEL_DIR / "stage8_all_shared_adds"
MODEL = MODEL_BASE / "yolov5nu-stage8-all-shared-adds.onnx"
MANIFEST = MODEL_BASE / "yolov5nu-stage8-all-shared-adds.graph.json"
OUTPUT_DIR = MODEL_DIR / "stage8a_materialized_cpuadd_control"
IMAGE_IDS = ("025", "036", "142", "404", "650")
STAGE8_MODE = "8a-materialized-cpuadd-control"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command", choices=("build", "elf", "all"), default="all", nargs="?"
    )
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def source_stem(image_id: str) -> str:
    return f"yolov5nu-stage8a-materialized-cpuadd-control-image{image_id}-profile"


def build_source(python: Path, image_id: str) -> str:
    stem = source_stem(image_id)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    run([
        str(python),
        str(ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"),
        "--model", str(MODEL), "--manifest", str(MANIFEST),
        "--image", str(stage0.image_path(image_id)),
        "--output-dir", str(OUTPUT_DIR), "--stem", stem,
        "--physical-layout", "nhwc", "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut", "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio", "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only", "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e", "--stage8-mode", STAGE8_MODE,
        "--stage8-add-name", "/model.2/m/m.0/Add", "--memory-stage", "5d",
    ])
    source = (OUTPUT_DIR / f"{stem}.c").read_text()
    feature_add_names = (
        "/model.2/m/m.0/Add", "/model.4/m/m.0/Add", "/model.4/m/m.1/Add",
        "/model.6/m/m.0/Add", "/model.6/m/m.1/Add", "/model.6/m/m.2/Add",
        "/model.8/m/m.0/Add",
    )
    memory = json.loads((OUTPUT_DIR / f"{stem}_memory.json").read_text())
    contract = {
        "shared_resadd_calls": source.count("add_gemmini_shared_resadd_i8(") - 1,
        "fixed_add_calls": source.count("add_fixed_i8(") - 1,
        "feature_fixed_add_calls": sum(
            source.count(f'yolo_profile_add(PROFILE_ADD, "Add", "{name}"')
            for name in feature_add_names
        ),
        "splitk_calls": (
            source.count("gemmini_splitk_1x1_two_slice_i8(") - 1
            + source.count("gemmini_splitk_1x1_multi_slice_i8(") - 1
        ),
        "concat_elided_markers": source.count("STAGE8_CONCAT_ELIDED:"),
        "direct_concat": len(memory["direct_concat"]),
        "arena_bytes": int(memory["arena_bytes"]),
    }
    expected = {
        "shared_resadd_calls": 0,
        "fixed_add_calls": 9,
        "feature_fixed_add_calls": 7,
        "splitk_calls": 0,
        "concat_elided_markers": 0,
        "direct_concat": 0,
        "arena_bytes": int(memory["arena_bytes"]),
    }
    if contract != expected:
        raise RuntimeError(
            f"invalid materialized CPU-Add control contract: {contract}, expected {expected}"
        )
    (OUTPUT_DIR / f"{stem}_contract.json").write_text(
        json.dumps(contract, indent=2) + "\n"
    )
    print(f"PASS: materialized CPU-Add control {image_id} {contract}")
    return stem


def build_elf(python: Path, image_id: str, stem: str) -> None:
    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python), "YOLOV5NU_MODEL": str(MODEL),
        "YOLOV5NU_MANIFEST": str(MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path(image_id)), "YOLOV5NU_STEM": stem,
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc", "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut", "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio", "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "YOLOV5NU_HEAD_OUTPUT_MODE": "detection-only", "YOLOV5NU_HEAD_CANDIDATE_KERNEL": "rvv",
        "YOLOV5NU_STAGE7_MODE": "7e", "YOLOV5NU_STAGE8_MODE": STAGE8_MODE,
        "YOLOV5NU_STAGE8_ADD_NAME": "/model.2/m/m.0/Add", "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_CFLAGS": (
            "-DYOLOV5NU_PROFILE=1 -DYOLOV5NU_LAYER_STATS=0 "
            "-DYOLOV5NU_FINAL_TENSOR_STATS=1"
        ),
    })
    run([str(ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh")], env=environment)


def main() -> None:
    args = parse_args()
    python = args.python.resolve()
    for image_id in IMAGE_IDS:
        stem = source_stem(image_id)
        if args.command in {"build", "all"}:
            stem = build_source(python, image_id)
        if args.command in {"elf", "all"}:
            build_elf(python, image_id, stem)


if __name__ == "__main__":
    main()
