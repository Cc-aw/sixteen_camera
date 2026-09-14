#!/usr/bin/env python3
"""Build and validate independent YOLOv5nu Stage 6 H3 candidates."""

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
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage6_h3_split"
EXPECTED_PROFILE_RECORDS = 398
VARIANTS = {
    "h3a": {
        "stem": "yolov5nu-stage6-h3a-batch-rvvlut-hwsilu-image025-profile",
        "kernel": "optimized-rvv-lut-dfl-batch-scalar-sum",
        "smoke": "yolov5nu_head_dfl_h3a",
        "macro": "YOLOV5NU_HEAD_KERNEL_DFL_BATCH_SCALAR_SUM 1",
    },
    "h3b": {
        "stem": "yolov5nu-stage6-h3b-orderedsum-rvvlut-hwsilu-image025-profile",
        "kernel": "optimized-rvv-lut-dfl-ordered-sum",
        "smoke": "yolov5nu_head_dfl_h3b",
        "macro": "YOLOV5NU_HEAD_KERNEL_DFL_ORDERED_SUM 1",
    },
    "h3c": {
        "stem": "yolov5nu-stage6-h3c-gather-rvvlut-hwsilu-image025-profile",
        "kernel": "optimized-rvv-lut-dfl-gather",
        "smoke": "yolov5nu_head_dfl_h3c",
        "macro": "YOLOV5NU_HEAD_KERNEL_DFL_GATHER 1",
    },
    "h3d": {
        "stem": "yolov5nu-stage6-h3d-elementwisesum-rvvlut-hwsilu-image025-profile",
        "kernel": "optimized-rvv-lut-dfl-batch-elementwise-sum",
        "smoke": "yolov5nu_head_dfl_h3d",
        "macro": "YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM 1",
    },
    "h3e": {
        "stem": "yolov5nu-stage6-h3e-unorderedsum-rvvlut-hwsilu-image025-profile",
        "kernel": "optimized-rvv-lut-dfl-batch-unordered-sum",
        "smoke": "yolov5nu_head_dfl_h3e",
        "macro": "YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM 1",
    },
    "h3f": {
        "stem": "yolov5nu-stage6-h3f-batch-gather-rvvlut-hwsilu-image025-profile",
        "kernel": "optimized-rvv-lut-dfl-batch-gather",
        "smoke": "yolov5nu_head_dfl_h3f",
        "macro": "YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER 1",
    },
    "h3g": {
        "stem": "yolov5nu-stage6-h3g-interleavedsum-rvvlut-hwsilu-image025-profile",
        "kernel": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "smoke": "yolov5nu_head_dfl_h3g",
        "macro": "YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM 1",
    },
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all"))
    parser.add_argument("--variant", action="append", choices=tuple(VARIANTS))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def paths(name: str) -> dict[str, Path]:
    item = VARIANTS[name]
    stem = item["stem"]
    return {
        "source": stage0.GENERATOR_DIR / f"{stem}.c",
        "parameters": stage0.GENERATOR_DIR / f"{stem}_params.h",
        "memory_plan": stage0.GENERATOR_DIR / f"{stem}_memory.json",
        "elf": stage0.BUILD_DIR / f"{stem}-baremetal-uart",
        "smoke": (
            ROOT / "generators/gemmini/software/gemmini-rocc-tests/build/bareMetalC/"
            f"{item['smoke']}-baremetal-uart"
        ),
    }


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def build_smoke(name: str) -> None:
    gemmini = ROOT / "generators/gemmini/software/gemmini-rocc-tests"
    target = VARIANTS[name]["smoke"]
    run([
        "make", "-B", "-C", str(gemmini / "build/bareMetalC"),
        "-f", str(gemmini / "bareMetalC/Makefile"),
        f"abs_top_srcdir={gemmini}", f"src_dir={gemmini / 'bareMetalC'}",
        "XLEN=64", "RVV=1",
        f"CC_BAREMETAL={ROOT / '.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc'}",
        f"{target}-baremetal", f"{target}-baremetal-uart",
    ])


def build_variant(name: str, python: Path) -> None:
    item = VARIANTS[name]
    build_smoke(name)
    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python),
        "YOLOV5NU_MODEL": str(stage0.MODEL),
        "YOLOV5NU_MANIFEST": str(stage0.MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path(IMAGE_ID)),
        "YOLOV5NU_STEM": item["stem"],
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
        "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut",
        "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio",
        "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": item["kernel"],
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
        "vfredosum_vs": len(re.findall(r"\bvfredosum\.vs\b", text)),
        "vfredusum_vs": len(re.findall(r"\bvfredusum\.vs\b", text)),
        "vfadd_vv": len(re.findall(r"\bvfadd\.vv\b", text)),
        "fadd_s": len(re.findall(r"\bfadd\.s\b", text)),
        "vluxei32_v": len(re.findall(r"\bvluxei32\.v\b", text)),
        "vwmul_vv": len(re.findall(r"\bvwmul\.vv\b", text)),
        "vredsum_vs": len(re.findall(r"\bvredsum\.vs\b", text)),
    }


def validate_disassembly(name: str, path: Path, *, full_model: bool) -> dict[str, int]:
    counts = disassembly_counts(path)
    common = ("vredmax_vs", "vwmul_vv", "vredsum_vs") if full_model or name in {"h3a", "h3f"} else ()
    if full_model:
        common = ("vrgather_vv", *common)
    for key in common:
        if counts[key] == 0:
            raise ValueError(f"{path}: missing {key}: {counts}")
    expected_special = {
        "h3a": {"vfredosum_vs": 0, "vfredusum_vs": 0, "vluxei32_v": 0},
        "h3b": {"vfredosum_vs": 1, "vfredusum_vs": 0, "vluxei32_v": 0},
        "h3c": {"vfredosum_vs": 0, "vfredusum_vs": 0, "vluxei32_v": 1},
        "h3d": {"vfredosum_vs": 0, "vfredusum_vs": 0, "vluxei32_v": 0},
        "h3e": {"vfredosum_vs": 0, "vfredusum_vs": 1, "vluxei32_v": 0},
        "h3f": {"vfredosum_vs": 0, "vfredusum_vs": 0, "vluxei32_v": 1},
        "h3g": {"vfredosum_vs": 0, "vfredusum_vs": 0, "vluxei32_v": 0},
    }[name]
    for key, present in expected_special.items():
        if (counts[key] > 0) != bool(present):
            raise ValueError(f"{path}: non-isolated {name} instructions: {counts}")
    if name == "h3d" and counts["vfadd_vv"] == 0:
        raise ValueError(f"{path}: missing H3D elementwise vfadd.vv: {counts}")
    if name == "h3g" and counts["fadd_s"] < 4:
        raise ValueError(f"{path}: missing four interleaved scalar fadd.s: {counts}")
    return counts


def source_contract(name: str, source: str, parameters: str) -> dict[str, int]:
    contract = {
        "profile_records": len(re.findall(r"\byolo_profile_add\(", source)) - 2,
        "gemmini_silu_direct_concat": source.count("GEMMINI_SILU_DIRECT_CONCAT"),
    }
    if contract["profile_records"] != EXPECTED_PROFILE_RECORDS:
        raise ValueError(f"{name}: source contract mismatch: {contract}")
    if contract["gemmini_silu_direct_concat"] != 8:
        raise ValueError(f"{name}: direct-Concat contract changed")
    if VARIANTS[name]["macro"] not in parameters:
        raise ValueError(f"{name}: missing parameter marker")
    return contract


def validate_variant(name: str, python: Path) -> dict:
    item_paths = paths(name)
    for path in item_paths.values():
        if not path.is_file():
            raise FileNotFoundError(path)
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_nhwc_layout.py"),
        "--manifest", str(stage0.MANIFEST), "--source", str(item_paths["source"]),
    ])
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_silu_fusion.py"),
        "--manifest", str(stage0.MANIFEST), "--source", str(item_paths["source"]),
        "--parameters", str(item_paths["parameters"]),
    ])
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_memory_plan.py"),
        "--source", str(item_paths["source"]),
        "--parameters", str(item_paths["parameters"]),
        "--memory-plan", str(item_paths["memory_plan"]),
    ])
    source = item_paths["source"].read_text()
    parameters = item_paths["parameters"].read_text()
    return {
        "variant": name,
        "head_kernel": VARIANTS[name]["kernel"],
        **{key: stage0.artifact_record(path) for key, path in item_paths.items()},
        "source_contract": source_contract(name, source, parameters),
        "disassembly": validate_disassembly(name, item_paths["elf"], full_model=True),
        "smoke_disassembly": validate_disassembly(name, item_paths["smoke"], full_model=False),
    }


def validate(names: list[str], python: Path) -> None:
    result = {
        "format": "yolov5nu-stage6-h3-split-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": (
            "fpga/xcvu13p/tests/yolov5nu_stage6/uart/"
            "stage6-h2-rvvdfl-rvvlut-hwsilu-image025.txt"
        ),
        "image_id": IMAGE_ID,
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "variants": [validate_variant(name, python) for name in names],
    }
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output = OUTPUT_DIR / "build_manifest.json"
    output.write_text(json.dumps(result, indent=2) + "\n")
    print(f"Wrote {output}")


def main() -> None:
    options = parse_args()
    names = options.variant or list(VARIANTS)
    python = options.python.resolve()
    if options.command in {"build", "all"}:
        for name in names:
            build_variant(name, python)
    if options.command in {"validate", "all"}:
        validate(names, python)


if __name__ == "__main__":
    main()
