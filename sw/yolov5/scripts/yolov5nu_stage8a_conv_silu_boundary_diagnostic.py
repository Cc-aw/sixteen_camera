#!/usr/bin/env python3
"""Build a targeted raw-Conv versus separate-SiLU diagnostic ELF."""

from __future__ import annotations

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
OUTPUT_DIR = MODEL_DIR / "stage8a_conv_silu_boundary_diagnostic"
IMAGE_ID = "142"
TARGET_CONV = "/model.6/m/m.0/cv2/conv/Conv"
TARGET_MUL = "/model.6/m/m.0/cv2/act/Mul"
STAGE8_MODE = "8a-materialized-cpuadd-control"
STEM = f"yolov5nu-stage8a-conv-silu-boundary-image{IMAGE_ID}-layerstats"


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def build_source(python: Path) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    run([
        str(python),
        str(ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"),
        "--model", str(MODEL), "--manifest", str(MANIFEST),
        "--image", str(stage0.image_path(IMAGE_ID)),
        "--output-dir", str(OUTPUT_DIR), "--stem", STEM,
        "--physical-layout", "nhwc", "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut", "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio", "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only", "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e", "--stage8-mode", STAGE8_MODE,
        "--stage8-add-name", "/model.2/m/m.0/Add", "--memory-stage", "5d",
        "--diagnostic-layer-stats", "--disable-fused-silu-conv", TARGET_CONV,
    ])
    source = (OUTPUT_DIR / f"{STEM}.c").read_text()
    memory = json.loads((OUTPUT_DIR / f"{STEM}_memory.json").read_text())
    contract = {
        "disabled_conv": TARGET_CONV,
        "disabled_mul": TARGET_MUL,
        "gemmini_silu_config_calls": source.count("gemmini_config_silu_lut(") ,
        "target_separate_silu_calls": source.count("silu_lut_i8(") - 1,
        "shared_resadd_calls": source.count("add_gemmini_shared_resadd_i8(") - 1,
        "feature_fixed_add_calls": sum(
            source.count(f'yolo_profile_add(PROFILE_ADD, "Add", "{name}"')
            for name in (
                "/model.2/m/m.0/Add", "/model.4/m/m.0/Add", "/model.4/m/m.1/Add",
                "/model.6/m/m.0/Add", "/model.6/m/m.1/Add", "/model.6/m/m.2/Add",
                "/model.8/m/m.0/Add",
            )
        ),
        "splitk_calls": source.count("gemmini_splitk_1x1_two_slice_i8(") - 1 + source.count(
            "gemmini_splitk_1x1_multi_slice_i8("
        ) - 1,
        "concat_elided_markers": source.count("STAGE8_CONCAT_ELIDED:"),
        "direct_concat": len(memory["direct_concat"]),
        "arena_bytes": int(memory["arena_bytes"]),
    }
    expected = {
        "disabled_conv": TARGET_CONV,
        "disabled_mul": TARGET_MUL,
        "gemmini_silu_config_calls": 68,
        "target_separate_silu_calls": 1,
        "shared_resadd_calls": 0,
        "feature_fixed_add_calls": 7,
        "splitk_calls": 0,
        "concat_elided_markers": 0,
        "direct_concat": 0,
        "arena_bytes": 835200,
    }
    if contract != expected:
        raise RuntimeError(f"invalid boundary diagnostic contract: {contract}, expected {expected}")
    (OUTPUT_DIR / f"{STEM}_contract.json").write_text(
        json.dumps(contract, indent=2) + "\n"
    )
    print(f"PASS: boundary diagnostic source contract {contract}")


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
        "YOLOV5NU_HEAD_OUTPUT_MODE": "detection-only", "YOLOV5NU_HEAD_CANDIDATE_KERNEL": "rvv",
        "YOLOV5NU_STAGE7_MODE": "7e", "YOLOV5NU_STAGE8_MODE": STAGE8_MODE,
        "YOLOV5NU_STAGE8_ADD_NAME": "/model.2/m/m.0/Add", "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_DIAGNOSTIC_LAYER_STATS": "1",
        "YOLOV5NU_DIAGNOSTIC_FINGERPRINT": "1",
        "YOLOV5NU_DISABLE_FUSED_SILU_CONV": TARGET_CONV,
        "YOLOV5NU_CFLAGS": (
            "-DYOLOV5NU_PROFILE=1 -DYOLOV5NU_LAYER_STATS=1 "
            "-DYOLOV5NU_DIAGNOSTIC_LAYER_STATS=1 -DYOLOV5NU_FINAL_TENSOR_STATS=1"
            " -DYOLOV5NU_DIAGNOSTIC_FINGERPRINT=1"
        ),
    })
    run([str(ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh")], env=environment)


def main() -> None:
    python = Path(sys.executable).resolve()
    build_source(python)
    build_elf(python)


if __name__ == "__main__":
    main()
