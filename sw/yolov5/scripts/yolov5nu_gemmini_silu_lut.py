#!/usr/bin/env python3
"""Build and validate the first YOLOv5nu Gemmini dynamic-SiLU-LUT candidate."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import yolov5nu_stage0_baseline as stage0
import yolov5nu_stage3_rvv as stage3


ROOT = stage0.ROOT
IMAGE_ID = "025"
STEM = "yolov5nu-stage5d-hwsilu-v1-image025-profile"
SOURCE = stage0.GENERATOR_DIR / f"{STEM}.c"
PARAMETERS = stage0.GENERATOR_DIR / f"{STEM}_params.h"
MEMORY_PLAN = stage0.GENERATOR_DIR / f"{STEM}_memory.json"
ELF = stage0.BUILD_DIR / f"{STEM}-baremetal-uart"
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_gemmini_silu_lut"
SILU_VALIDATOR = ROOT / "scripts/yolov5nu_validate_silu_fusion.py"
MEMORY_VALIDATOR = ROOT / "scripts/yolov5nu_validate_memory_plan.py"
SMOKE_BUILD = ROOT / "scripts/xcvu13p_build_gemmini_uart_baremetal.sh"
EXPECTED_PROFILE_RECORDS = 398


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all"))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def build(python: Path) -> None:
    for target in (
        "silu_lut_store-baremetal-uart",
        "silu_lut_loop_conv-baremetal-uart",
        "silu_lut_yolov5nu-baremetal-uart",
    ):
        run([str(SMOKE_BUILD), target])

    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python),
        "YOLOV5NU_MODEL": str(stage0.MODEL),
        "YOLOV5NU_MANIFEST": str(stage0.MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path(IMAGE_ID)),
        "YOLOV5NU_STEM": STEM,
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
        "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut",
        "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio",
        "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv",
        "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
        "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
        "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
    })
    run([str(stage0.BUILD_SCRIPT)], env=environment)


def validate(python: Path) -> dict:
    for path in (SOURCE, PARAMETERS, MEMORY_PLAN, ELF):
        if not path.is_file():
            raise FileNotFoundError(path)
    run([
        str(python), str(stage3.NHWC_VALIDATOR), "--manifest", str(stage0.MANIFEST),
        "--source", str(SOURCE),
    ])
    run([
        str(python), str(SILU_VALIDATOR), "--manifest", str(stage0.MANIFEST),
        "--source", str(SOURCE), "--parameters", str(PARAMETERS),
    ])
    run([
        str(python), str(MEMORY_VALIDATOR), "--source", str(SOURCE),
        "--parameters", str(PARAMETERS), "--memory-plan", str(MEMORY_PLAN),
    ])

    source = SOURCE.read_text()
    profile_records = len(re.findall(r"\byolo_profile_add\(", source)) - 2
    if profile_records != EXPECTED_PROFILE_RECORDS:
        raise ValueError(f"profile contract changed: {profile_records}")
    if source.count("gemmini_config_silu_lut(") != 69:
        raise ValueError("expected 69 dynamic LUT configurations")
    if len(re.findall(r"\bSILU_LUT\s*,", source)) != 69:
        raise ValueError("expected 69 Gemmini SILU_LUT Conv activations")
    if source.count("GEMMINI_SILU_DIRECT_CONCAT") != 8:
        raise ValueError("expected 8 Gemmini SiLU direct-Concat Conv calls")
    if re.search(r"\bsilu_lut_i8\(", source):
        raise ValueError("CPU SiLU calls remain in the Gemmini candidate")

    size = subprocess.check_output([
        str(ROOT / ".conda-env/riscv-tools/bin/riscv64-unknown-elf-size"), str(ELF)
    ], text=True).splitlines()[-1].split()
    result = {
        "format": "yolov5nu-gemmini-dynamic-silu-lut-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": "fpga/xcvu13p/tests/yolov5nu_stage5/current_baseline.json",
        "image_id": IMAGE_ID,
        "source": stage0.artifact_record(SOURCE),
        "parameters": stage0.artifact_record(PARAMETERS),
        "memory_plan": stage0.artifact_record(MEMORY_PLAN),
        "elf": stage0.artifact_record(ELF),
        "elf_sections": {
            "text": int(size[0]), "data": int(size[1]), "bss": int(size[2]),
            "total": int(size[3]),
        },
        "contract": {
            "activation": 6,
            "config_funct": 26,
            "lut_entries": 256,
            "entries_per_command": 8,
            "commands_per_layer": 32,
            "silu_layers": 69,
            "exhaustive_lut_cases": 17664,
            "profile_records": profile_records,
            "cpu_silu_calls": 0,
            "direct_concat": 9,
            "gemmini_silu_direct_concat": 8,
        },
    }
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUTPUT_DIR / "build_manifest.json"
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"Wrote {output}")
    return result


def main() -> None:
    options = parse_args()
    python = options.python.resolve()
    if options.command in {"build", "all"}:
        build(python)
    if options.command in {"validate", "all"}:
        validate(python)


if __name__ == "__main__":
    main()
