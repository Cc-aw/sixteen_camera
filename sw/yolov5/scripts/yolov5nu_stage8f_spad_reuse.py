#!/usr/bin/env python3
"""Build and contract-check the Stage 8F dual-consumer A-slice reuse candidate."""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import argparse
from pathlib import Path

import yolov5nu_stage0_baseline as stage0


ROOT = stage0.ROOT
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
MODEL_BASE = MODEL_DIR / "stage8_hardware_aware"
MODEL = MODEL_BASE / "yolov5nu-hw-aware-shared-scale-int8-img320.onnx"
MANIFEST = MODEL_BASE / "yolov5nu-hw-aware-shared-scale.graph.json"
OUTPUT_DIR = MODEL_DIR / "stage8f_dual_consumer_spad_reuse"
ELF_DIR = ROOT / "generators/gemmini/software/gemmini-rocc-tests/build/imagenet"
BUILD = ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh"
IMAGE_IDS = ("025", "036", "142", "404", "650")
STEM_SUFFIX = ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--width", type=int, default=320)
    parser.add_argument("--height", type=int, default=320)
    parser.add_argument("--model-dir", type=Path, default=MODEL_BASE)
    parser.add_argument("--output-dir", type=Path, default=OUTPUT_DIR)
    parser.add_argument("--image-id", choices=IMAGE_IDS, action="append")
    return parser.parse_args()


def generator_args(python: str, image_id: str, stem: str) -> list[str]:
    generator = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"
    return [
        python, str(generator), "--model", str(MODEL), "--manifest", str(MANIFEST),
        "--image", str(stage0.image_path(image_id)), "--output-dir", str(OUTPUT_DIR),
        "--stem", stem, "--physical-layout", "nhwc", "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut", "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio", "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only", "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e", "--stage8-mode", "8f-dual-consumer-spad-reuse",
        "--stage8-add-name", "/model.2/m/m.0/Add", "--memory-stage", "5d",
    ]


def build_source(python: str, image_id: str) -> tuple[Path, dict]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    stem = f"yolov5nu-stage8f-dual-consumer-spad-reuse{STEM_SUFFIX}-image{image_id}-profile"
    subprocess.run(generator_args(python, image_id, stem), cwd=ROOT, check=True)
    source_path = OUTPUT_DIR / f"{stem}.c"
    memory_path = OUTPUT_DIR / f"{stem}_memory.json"
    source = source_path.read_text()
    memory = json.loads(memory_path.read_text())
    reuse_calls = re.findall(
        r"gemmini_splitk_1x1_two_slice_i8_spad_reuse\([^;]+, (true|false)\);",
        source,
        flags=re.S,
    )
    contract = {
        "shared_resadd_calls": source.count("add_gemmini_shared_resadd_i8(") - 1,
        "splitk_calls": source.count("STAGE8_SPLITK_CONCAT_CONV:"),
        "pair_reuse_calls": source.count(
            "gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8("
        ) - 1,
        "direct_concat": len(memory["direct_concat"]),
        "arena_bytes": int(memory["arena_bytes"]),
    }
    expected = {
        "shared_resadd_calls": 7,
        "splitk_calls": 17,
        "pair_reuse_calls": 4,
        "direct_concat": 0,
    }
    if any(contract[key] != value for key, value in expected.items()):
        raise RuntimeError(f"invalid Stage 8F contract: {contract}, expected {expected}")
    print(f"PASS: image{image_id} Stage 8F contract {contract}")
    return source_path, memory


def build_elf(python: str, image_id: str) -> Path:
    stem = f"yolov5nu-stage8f-dual-consumer-spad-reuse{STEM_SUFFIX}-image{image_id}-profile"
    env = os.environ.copy()
    env.update({
        "PYTHON": python,
        "YOLOV5NU_MODEL": str(MODEL),
        "YOLOV5NU_MANIFEST": str(MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path(image_id)),
        "YOLOV5NU_STEM": stem,
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
        "YOLOV5NU_STAGE8_MODE": "8f-dual-consumer-spad-reuse",
        "YOLOV5NU_STAGE8_ADD_NAME": "/model.2/m/m.0/Add",
        "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_CFLAGS": (
            "-DYOLOV5NU_PROFILE=1 -DYOLOV5NU_LAYER_STATS=0 "
            "-DYOLOV5NU_FINAL_TENSOR_STATS=1"
        ),
    })
    subprocess.run([str(BUILD)], cwd=ROOT, env=env, check=True)
    elf = ELF_DIR / f"{stem}-baremetal-uart"
    if not elf.is_file():
        raise FileNotFoundError(elf)
    print(f"PASS: {elf}")
    return elf


def main() -> None:
    args = parse_args()
    global MODEL_BASE, MODEL, MANIFEST, OUTPUT_DIR, IMAGE_IDS, STEM_SUFFIX
    MODEL_BASE = args.model_dir.resolve()
    MODEL = MODEL_BASE / f"yolov5nu-hw-aware-shared-scale-int8-img{args.width}x{args.height}.onnx"
    MANIFEST = MODEL_BASE / f"yolov5nu-hw-aware-shared-scale-img{args.width}x{args.height}.graph.json"
    OUTPUT_DIR = args.output_dir.resolve()
    IMAGE_IDS = tuple(args.image_id or IMAGE_IDS)
    STEM_SUFFIX = f"-img{args.width}x{args.height}" if (args.width, args.height) != (320, 320) else ""
    if args.width <= 0 or args.height <= 0 or args.width % 32 or args.height % 32:
        raise ValueError("width and height must be positive multiples of 32")
    if not MODEL.is_file() or not MANIFEST.is_file():
        raise FileNotFoundError("Stage 8 hardware-aware model or manifest is missing")
    python = os.environ.get("PYTHON", sys.executable)
    for image_id in IMAGE_IDS:
        build_source(python, image_id)
        build_elf(python, image_id)


if __name__ == "__main__":
    main()
