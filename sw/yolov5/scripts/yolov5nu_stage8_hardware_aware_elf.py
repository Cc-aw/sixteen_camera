#!/usr/bin/env python3
"""Build five Stage 8 all-consumer ELFs from the hardware-aware model."""

from __future__ import annotations

import os
import sys
import subprocess
from pathlib import Path

import yolov5nu_stage0_baseline as stage0


ROOT = stage0.ROOT
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
MODEL_BASE = MODEL_DIR / "stage8_hardware_aware"
MODEL = MODEL_BASE / "yolov5nu-hw-aware-shared-scale-int8-img320.onnx"
MANIFEST = MODEL_BASE / "yolov5nu-hw-aware-shared-scale.graph.json"
IMAGE_DIR = MODEL_DIR / "calibration/coco128/images/train2017"
BUILD = ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh"
ELF_DIR = ROOT / "generators/gemmini/software/gemmini-rocc-tests/build/imagenet"
IMAGE_IDS = ("025", "036", "142", "404", "650")


def build(image_id: str) -> Path:
    stem = f"yolov5nu-stage8-hw-aware-all-consumer-image{image_id}-profile"
    env = os.environ.copy()
    env.update({
        # Preserve an explicitly supplied interpreter; otherwise use the
        # interpreter running this driver (important inside the Chipyard env).
        "PYTHON": os.environ.get("PYTHON", sys.executable),
        "YOLOV5NU_MODEL": str(MODEL),
        "YOLOV5NU_MANIFEST": str(MANIFEST),
        "YOLOV5NU_IMAGE": str(IMAGE_DIR / f"000000000{image_id}.jpg"),
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
        "YOLOV5NU_STAGE8_MODE": "8c-dual-consumer-splitk",
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
    if not MODEL.is_file() or not MANIFEST.is_file():
        raise FileNotFoundError("hardware-aware model or manifest is missing")
    for image_id in IMAGE_IDS:
        build(image_id)


if __name__ == "__main__":
    main()
