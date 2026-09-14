#!/usr/bin/env python3
"""Build and contract-check the Stage 8H split-K config/fence candidate."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

import yolov5nu_stage0_baseline as stage0


ROOT = stage0.ROOT
MODEL_BASE = ROOT / "generators/gemmini/software/gemmini-ort/models/detection/stage8_hardware_aware"
MODEL = MODEL_BASE / "yolov5nu-hw-aware-shared-scale-int8-img320.onnx"
MANIFEST = MODEL_BASE / "yolov5nu-hw-aware-shared-scale.graph.json"
SOURCE_DIR = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet"
ELF_DIR = ROOT / "generators/gemmini/software/gemmini-rocc-tests/build/imagenet"
BUILD = ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh"
IMAGE_IDS = ("025", "036", "142", "404", "650")


def build(image_id: str) -> Path:
    stem = f"yolov5nu-stage8h-splitk-config-fence-image{image_id}-profile"
    env = os.environ.copy()
    env.update({
        "PYTHON": os.environ.get("PYTHON", sys.executable),
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
        "YOLOV5NU_STAGE8_MODE": "8h-splitk-config-fence-merge",
        "YOLOV5NU_STAGE8_ADD_NAME": "/model.2/m/m.0/Add",
        "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_CFLAGS": (
            "-DYOLOV5NU_PROFILE=1 -DYOLOV5NU_LAYER_STATS=0 "
            "-DYOLOV5NU_FINAL_TENSOR_STATS=1"
        ),
    })
    subprocess.run([str(BUILD)], cwd=ROOT, env=env, check=True)
    source = SOURCE_DIR / f"{stem}.c"
    memory = SOURCE_DIR / f"{stem}_memory.json"
    source_text = source.read_text()
    memory_data = json.loads(memory.read_text())
    contract = {
        "shared_resadd_calls": source_text.count("add_gemmini_shared_resadd_i8(") - 1,
        "splitk_markers": source_text.count("STAGE8_SPLITK_CONCAT_CONV:"),
        "pair_reuse_calls": source_text.count(
            "gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8("
        ) - 1,
        "direct_concat": len(memory_data["direct_concat"]),
        "merged_config_calls": source_text.count("stage8h_config_ld_if_needed(") - 1,
    }
    expected = {
        "shared_resadd_calls": 7,
        "splitk_markers": 17,
        "pair_reuse_calls": 4,
        "direct_concat": 0,
        "merged_config_calls": 1,
    }
    if contract != expected:
        raise RuntimeError(f"invalid Stage 8H contract: {contract}, expected {expected}")
    elf = ELF_DIR / f"{stem}-baremetal-uart"
    if not elf.is_file():
        raise FileNotFoundError(elf)
    print(f"PASS: image{image_id} Stage 8H contract {contract}")
    print(f"ELF: {elf}")
    return elf


def main() -> None:
    if not MODEL.is_file() or not MANIFEST.is_file():
        raise FileNotFoundError("Stage 8 hardware-aware model or manifest is missing")
    for image_id in IMAGE_IDS:
        build(image_id)


if __name__ == "__main__":
    main()
