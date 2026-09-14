#!/usr/bin/env python3
"""Build and validate the YOLOv5nu Stage 6 H4 sparse-DFL candidate."""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import yolov5nu_stage0_baseline as stage0
import yolov5nu_stage3_rvv as stage3


ROOT = stage0.ROOT
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage6_h4"
EXPECTED_PROFILE_RECORDS = 398
SMOKE = (
    ROOT / "generators/gemmini/software/gemmini-rocc-tests/build/bareMetalC/"
    "yolov5nu_head_candidate_rvv-baremetal-uart"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all"))
    parser.add_argument("--image-id", action="append", choices=stage0.IMAGE_IDS)
    parser.add_argument("--class-max", choices=("scalar", "rvv"), default="rvv")
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
        "yolov5nu_head_candidate_rvv-baremetal",
        "yolov5nu_head_candidate_rvv-baremetal-uart",
    ])


def stem(image_id: str, class_max: str) -> str:
    suffix = "-rvvclassmax" if class_max == "rvv" else ""
    return f"yolov5nu-stage6-h4{suffix}-sparse-dfl-h3g-rvvlut-hwsilu-image{image_id}-profile"


def paths(image_id: str, class_max: str) -> dict[str, Path]:
    name = stem(image_id, class_max)
    return {
        "source": stage0.GENERATOR_DIR / f"{name}.c",
        "parameters": stage0.GENERATOR_DIR / f"{name}_params.h",
        "memory_plan": stage0.GENERATOR_DIR / f"{name}_memory.json",
        "elf": stage0.BUILD_DIR / f"{name}-baremetal-uart",
    }


def build(image_id: str, class_max: str, python: Path) -> None:
    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python),
        "YOLOV5NU_MODEL": str(stage0.MODEL),
        "YOLOV5NU_MANIFEST": str(stage0.MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path(image_id)),
        "YOLOV5NU_STEM": stem(image_id, class_max),
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
        "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut",
        "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio",
        "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "YOLOV5NU_HEAD_OUTPUT_MODE": "detection-only",
        "YOLOV5NU_HEAD_CANDIDATE_KERNEL": class_max,
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
        "vwmul_vv": len(re.findall(r"\bvwmul\.vv\b", text)),
        "vredsum_vs": len(re.findall(r"\bvredsum\.vs\b", text)),
        "fadd_s": len(re.findall(r"\bfadd\.s\b", text)),
        "vluxei32_v": len(re.findall(r"\bvluxei32\.v\b", text)),
    }


def validate_candidate_algorithm() -> dict[str, int]:
    rng = random.Random(0x4834)
    cases = 512
    for _ in range(cases):
        scores = [rng.randrange(-128, 128) for _ in range(2100)]
        threshold = rng.randrange(-128, 129)
        full_top = sorted(range(2100), key=lambda i: (-scores[i], i))[:10]
        mask = [score >= threshold for score in scores]
        for index in full_top:
            mask[index] = True
        sparse_indices = [i for i, selected in enumerate(mask) if selected]
        sparse_top = sorted(sparse_indices, key=lambda i: (-scores[i], i))[:10]
        full_nms_input = [i for i, score in enumerate(scores) if score >= threshold]
        sparse_nms_input = [i for i in sparse_indices if scores[i] >= threshold]
        if sparse_top != full_top or sparse_nms_input != full_nms_input:
            raise ValueError("H4 sparse candidate set changed Top-10 or NMS input ordering")
    return {"random_cases": cases, "locations_per_case": 2100}


def validate_image(image_id: str, class_max: str, python: Path) -> dict:
    item_paths = paths(image_id, class_max)
    source_path = item_paths["source"]
    parameters_path = item_paths["parameters"]
    memory_plan_path = item_paths["memory_plan"]
    elf_path = item_paths["elf"]
    for path in item_paths.values():
        if not path.is_file():
            raise FileNotFoundError(path)
    source = source_path.read_text()
    parameters = parameters_path.read_text()
    contract = {
        "profile_records": len(re.findall(r"\byolo_profile_add\(", source)) - 2,
        "direct_concat": source.count("GEMMINI_SILU_DIRECT_CONCAT"),
        "candidate_select": source.count("stage4_select_dfl_candidates("),
        "sparse_summary": source.count("print_sparse_dfl_summary("),
    }
    expected = {
        "profile_records": EXPECTED_PROFILE_RECORDS,
        "direct_concat": 8,
        "candidate_select": 4,
        "sparse_summary": 2,
    }
    if contract != expected:
        raise ValueError(f"H4 source contract {contract} != {expected}")
    for marker in (
        "YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM 1",
        "YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY 1",
        f"YOLOV5NU_HEAD_CANDIDATE_KERNEL_{class_max.upper()} 1",
    ):
        if marker not in parameters:
            raise ValueError(f"missing H4 marker: {marker}")
    counts = disassembly_counts(elf_path)
    for key in ("vrgather_vv", "vredmax_vs", "vwmul_vv", "vredsum_vs", "fadd_s"):
        if counts[key] == 0:
            raise ValueError(f"H4 ELF missing {key}: {counts}")
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_nhwc_layout.py"),
        "--manifest", str(stage0.MANIFEST), "--source", str(source_path),
    ])
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_silu_fusion.py"),
        "--manifest", str(stage0.MANIFEST), "--source", str(source_path),
        "--parameters", str(parameters_path),
    ])
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_memory_plan.py"),
        "--source", str(source_path), "--parameters", str(parameters_path),
        "--memory-plan", str(memory_plan_path),
    ])
    return {
        "image_id": image_id,
        "class_max": class_max,
        "image": stage0.artifact_record(stage0.image_path(image_id)),
        "source": stage0.artifact_record(source_path),
        "parameters": stage0.artifact_record(parameters_path),
        "memory_plan": stage0.artifact_record(memory_plan_path),
        "elf": stage0.artifact_record(elf_path),
        "source_contract": contract,
        "disassembly": counts,
    }


def validate(image_ids: list[str], class_max: str, python: Path) -> dict:
    if class_max == "rvv" and not SMOKE.is_file():
        raise FileNotFoundError(SMOKE)
    result = {
        "format": "yolov5nu-stage6-h4-sparse-dfl-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": "fpga/xcvu13p/tests/yolov5nu_stage6/uart/stage6-h3g-interleavedsum-rvvlut-hwsilu-image025.txt",
        "image_ids": image_ids,
        "class_max": class_max,
        "head_kernel": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "head_output_mode": "detection-only",
        "candidate_algorithm": validate_candidate_algorithm(),
        "images": [validate_image(image_id, class_max, python) for image_id in image_ids],
    }
    if class_max == "rvv":
        smoke_counts = disassembly_counts(SMOKE)
        if smoke_counts["vredmax_vs"] == 0:
            raise ValueError(f"H4A smoke missing vredmax.vs: {smoke_counts}")
        result["smoke_elf"] = stage0.artifact_record(SMOKE)
        result["smoke_disassembly"] = smoke_counts
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUTPUT_DIR / "build_manifest.json"
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"Wrote {output}")
    return result


def main() -> None:
    options = parse_args()
    python = options.python.resolve()
    image_ids = options.image_id or list(stage0.IMAGE_IDS)
    if options.command in {"build", "all"}:
        if options.class_max == "rvv":
            build_smoke()
        for image_id in image_ids:
            build(image_id, options.class_max, python)
    if options.command in {"validate", "all"}:
        validate(image_ids, options.class_max, python)


if __name__ == "__main__":
    main()
