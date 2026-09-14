#!/usr/bin/env python3
"""Build and validate the YOLOv5nu Stage 6 H2 DFL RVV candidate."""

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
STEM = "yolov5nu-stage6-h2-rvvdfl-rvvlut-hwsilu-image025-profile"
SOURCE = stage0.GENERATOR_DIR / f"{STEM}.c"
PARAMETERS = stage0.GENERATOR_DIR / f"{STEM}_params.h"
MEMORY_PLAN = stage0.GENERATOR_DIR / f"{STEM}_memory.json"
ELF = stage0.BUILD_DIR / f"{STEM}-baremetal-uart"
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage6_h2"
SMOKE = (
    ROOT / "generators/gemmini/software/gemmini-rocc-tests/build/bareMetalC/"
    "yolov5nu_head_dfl_rvv-baremetal-uart"
)
SILU_VALIDATOR = ROOT / "scripts/yolov5nu_validate_silu_fusion.py"
MEMORY_VALIDATOR = ROOT / "scripts/yolov5nu_validate_memory_plan.py"
EXPECTED_PROFILE_RECORDS = 398


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all"))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def build_smoke() -> None:
    gemmini = ROOT / "generators/gemmini/software/gemmini-rocc-tests"
    run([
        "make", "-B", "-C", str(gemmini / "build/bareMetalC"),
        "-f", str(gemmini / "bareMetalC/Makefile"),
        f"abs_top_srcdir={gemmini}", f"src_dir={gemmini / 'bareMetalC'}",
        "XLEN=64", "RVV=1",
        f"CC_BAREMETAL={ROOT / '.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc'}",
        "yolov5nu_head_dfl_rvv-baremetal",
        "yolov5nu_head_dfl_rvv-baremetal-uart",
    ])


def build(python: Path) -> None:
    build_smoke()
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
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv-lut-dfl",
        "YOLOV5NU_MEMORY_STAGE": "5d",
        "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
        "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
        "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
    })
    run([str(stage0.BUILD_SCRIPT)], env=environment)


def disassembly_counts(path: Path) -> dict[str, int]:
    text = subprocess.check_output([str(stage3.OBJDUMP), "-d", str(path)], text=True)
    return {
        "vrgather_vv": len(re.findall(r"\bvrgather\.vv\b", text)),
        "vredmax_vs": len(re.findall(r"\bvredmax\.vs\b", text)),
        "vfcvt_x_f_v": len(re.findall(r"\bvfcvt\.x\.f\.v\b", text)),
        "vwmul_vv": len(re.findall(r"\bvwmul\.vv\b", text)),
        "vredsum_vs": len(re.findall(r"\bvredsum\.vs\b", text)),
    }


def require_disassembly(path: Path, *, full_model: bool) -> dict[str, int]:
    counts = disassembly_counts(path)
    required = ("vredmax_vs", "vfcvt_x_f_v", "vwmul_vv", "vredsum_vs")
    if full_model:
        required = ("vrgather_vv", *required)
    if any(counts[name] == 0 for name in required):
        raise ValueError(f"{path}: missing Stage 6 H2 RVV instructions: {counts}")
    return counts


def source_contract() -> dict[str, int]:
    source = SOURCE.read_text()
    parameters = PARAMETERS.read_text()
    contract = {
        "class_calls": len(re.findall(r"^  stage4_class_heads_i8\(", source, re.MULTILINE)),
        "dfl_calls": len(re.findall(r"^  stage4_dfl_heads_i8\(", source, re.MULTILINE)),
        "class_rvv_lut_calls": source.count("yolov5nu_rvv_sigmoid_lut_i8("),
        "dfl_support_calls": source.count("yolov5nu_rvv_dfl_vl16_supported("),
        "dfl_max_calls": source.count("yolov5nu_rvv_dfl_max_i8x16("),
        "dfl_dot_calls": source.count("yolov5nu_rvv_dfl_probability_dot_i8x16("),
        "phase_reports": source.count("YOLOV5NU_HEAD_PHASE"),
        "profile_records": len(re.findall(r"\byolo_profile_add\(", source)) - 2,
        "gemmini_silu_direct_concat": source.count("GEMMINI_SILU_DIRECT_CONCAT"),
    }
    expected = {
        "class_calls": 1,
        "dfl_calls": 1,
        "class_rvv_lut_calls": 1,
        "dfl_support_calls": 1,
        "dfl_max_calls": 1,
        "dfl_dot_calls": 1,
        "phase_reports": 1,
        "profile_records": EXPECTED_PROFILE_RECORDS,
        "gemmini_silu_direct_concat": 8,
    }
    if contract != expected:
        raise ValueError(f"Stage 6 H2 source contract {contract} != {expected}")
    for marker in (
        "Detection head kernel: optimized-rvv-lut-dfl",
        "YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL 1",
        "YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT 1",
        "YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV 1",
    ):
        if marker not in source and marker not in parameters:
            raise ValueError(f"missing Stage 6 H2 marker: {marker}")
    return contract


def validate(python: Path) -> dict:
    for path in (SOURCE, PARAMETERS, MEMORY_PLAN, ELF, SMOKE):
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
    result = {
        "format": "yolov5nu-stage6-head-h2-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": "fpga/xcvu13p/tests/yolov5nu_stage6/uart/h01-rvvlut-hwsilu-image025.txt",
        "image_id": IMAGE_ID,
        "head_kernel": "optimized-rvv-lut-dfl",
        "source": stage0.artifact_record(SOURCE),
        "parameters": stage0.artifact_record(PARAMETERS),
        "memory_plan": stage0.artifact_record(MEMORY_PLAN),
        "elf": stage0.artifact_record(ELF),
        "smoke_elf": stage0.artifact_record(SMOKE),
        "source_contract": source_contract(),
        "disassembly": require_disassembly(ELF, full_model=True),
        "smoke_disassembly": require_disassembly(SMOKE, full_model=False),
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
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
