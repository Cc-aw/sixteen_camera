#!/usr/bin/env python3
"""Build independent YOLOv5nu Stage 7A and Stage 7B Concat/Add candidates."""

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
IMAGE_IDS = ("025", "036", "142", "404", "650")
VARIANTS = ("7a", "7b", "7b-lut", "7b-register", "7c", "7d", "7bc", "7e")
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage7"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all"))
    parser.add_argument("--variant", action="append", choices=VARIANTS)
    parser.add_argument("--image-id", action="append", choices=IMAGE_IDS)
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def run(command: list[str], *, env: dict[str, str] | None = None) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, env=env, check=True)


def stem(variant: str, image_id: str) -> str:
    if variant == "7c":
        return f"yolov5nu-stage7c-concat-rvv-h4a-rvvlut-hwsilu-image{image_id}-profile"
    if variant == "7d":
        return f"yolov5nu-stage7d-gemmini-resadd-h4a-rvvlut-hwsilu-image{image_id}-profile"
    if variant == "7bc":
        return f"yolov5nu-stage7bc-register-concat-exact-h4a-rvvlut-hwsilu-image{image_id}-profile"
    if variant == "7e":
        return f"yolov5nu-stage7e-fixed-add-7bc-h4a-rvvlut-hwsilu-image{image_id}-profile"
    label = {
        "7b": "7b-exact",
        "7b-lut": "7b-lut-exact",
        "7b-register": "7b-lut-register-exact",
        "7c": "7c-concat-rvv",
    }.get(variant, variant)
    return f"yolov5nu-stage{label}-concat-add-h4a-rvvlut-hwsilu-image{image_id}-profile"


def paths(variant: str, image_id: str) -> dict[str, Path]:
    name = stem(variant, image_id)
    return {
        "source": stage0.GENERATOR_DIR / f"{name}.c",
        "parameters": stage0.GENERATOR_DIR / f"{name}_params.h",
        "memory_plan": stage0.GENERATOR_DIR / f"{name}_memory.json",
        "elf": stage0.BUILD_DIR / f"{name}-baremetal-uart",
    }


def build(variant: str, image_id: str, python: Path) -> None:
    environment = os.environ.copy()
    environment.update({
        "PYTHON": str(python),
        "YOLOV5NU_MODEL": str(stage0.MODEL),
        "YOLOV5NU_MANIFEST": str(stage0.MANIFEST),
        "YOLOV5NU_IMAGE": str(stage0.image_path(image_id)),
        "YOLOV5NU_STEM": stem(variant, image_id),
        "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
        "YOLOV5NU_SILU_MODE": "fused-lut",
        "YOLOV5NU_SILU_KERNEL": "gemmini-lut",
        "YOLOV5NU_KERNEL_MODE": "rvv",
        "YOLOV5NU_ADD_KERNEL": "rvv-ratio",
        "YOLOV5NU_HEAD_LOWERING": "location-major",
        "YOLOV5NU_HEAD_KERNEL": "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "YOLOV5NU_HEAD_OUTPUT_MODE": "detection-only",
        "YOLOV5NU_HEAD_CANDIDATE_KERNEL": "rvv",
        "YOLOV5NU_STAGE7_MODE": variant,
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
        "vfadd_vv": len(re.findall(r"\bvfadd\.vv\b", text)),
        "vwmul_vv": len(re.findall(r"\bvwmul\.vv\b", text)),
        "vmul_vx": len(re.findall(r"\bvmul\.vx\b", text)),
        "vredsum_vs": len(re.findall(r"\bvredsum\.vs\b", text)),
        "vluxei8_v": len(re.findall(r"\bvluxei8\.v\b", text)),
    }


def validate_one(variant: str, image_id: str, python: Path) -> dict:
    item = paths(variant, image_id)
    for path in item.values():
        if not path.is_file():
            raise FileNotFoundError(path)
    source = item["source"].read_text()
    parameters = item["parameters"].read_text()
    memory_plan = json.loads(item["memory_plan"].read_text())
    direct_count = len(memory_plan.get("direct_concat", []))
    expected_direct = 9 if variant in {"7c", "7d"} else (11 if variant == "7a" else 14)
    if direct_count != expected_direct:
        raise ValueError(
            f"{variant}/{image_id}: expected {expected_direct} direct writes, got {direct_count}"
        )
    if variant in {"7b", "7b-lut", "7b-register", "7bc", "7e"} and direct_count <= 11:
        raise ValueError(f"{variant}/{image_id}: Add+Concat did not add direct writes: {direct_count}")
    for marker in (
        "YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY 1",
        "YOLOV5NU_HEAD_CANDIDATE_KERNEL_RVV 1",
        f"YOLOV5NU_STAGE7_MODE_{variant.replace('-', '_').upper()} 1",
        "YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM 1",
    ):
        if marker not in parameters:
            raise ValueError(f"{variant}/{image_id}: missing marker {marker}")
    contract = {
        "profile_records": len(re.findall(r"\byolo_profile_add\(", source)) - 2,
        "gemmini_silu_direct_concat": source.count("GEMMINI_SILU_DIRECT_CONCAT"),
        "stage7_strided_maxpool": source.count("maxpool_nhwc_i8_strided("),
        "stage7_strided_resize": source.count("resize_nearest_nhwc_i8_strided("),
        "stage7_strided_add": source.count("add_ratio_i8_strided("),
        "stage7_two_step_add": source.count("add_two_step_i8_strided("),
        "stage7_two_step_lut_add": source.count("add_two_step_lut_i8_strided("),
        "stage7_two_step_register_add": source.count("add_two_step_register_i8_strided("),
        "stage7_two_step_register_fixed_add": source.count("add_two_step_register_fixed_i8_strided("),
        "stage7_fixed_add": source.count("add_fixed_i8("),
        "stage7_concat_slice": source.count("concat_nhwc_slice_strided_i8("),
        "stage7_gemmini_resadd": source.count("add_gemmini_resadd_i8("),
        "stage7_gemmini_resadd_strided": source.count("add_gemmini_resadd_strided_i8("),
    }
    if contract["profile_records"] != 398 or contract["gemmini_silu_direct_concat"] != 8:
        raise ValueError(f"{variant}/{image_id}: profile/fusion contract {contract}")
    if contract["stage7_strided_maxpool"] < 1 or contract["stage7_strided_resize"] < 1:
        raise ValueError(f"{variant}/{image_id}: missing producer-direct helper {contract}")
    if variant == "7b" and contract["stage7_two_step_add"] < 4:
        raise ValueError(f"{variant}/{image_id}: missing exact Add+Concat calls {contract}")
    if variant == "7b-lut" and contract["stage7_two_step_lut_add"] < 4:
        raise ValueError(f"{variant}/{image_id}: missing LUT Add+Concat calls {contract}")
    if variant == "7b-register" and contract["stage7_two_step_register_add"] < 4:
        raise ValueError(f"{variant}/{image_id}: missing register-LUT Add calls {contract}")
    if variant == "7c" and contract["stage7_concat_slice"] < 2:
        raise ValueError(f"{variant}/{image_id}: missing dedicated Concat calls {contract}")
    if variant == "7bc" and (
            contract["stage7_two_step_register_add"] < 4 or
            contract["stage7_concat_slice"] < 2):
        raise ValueError(f"{variant}/{image_id}: incomplete register+Concat fusion {contract}")
    if variant == "7e" and (
            contract["stage7_two_step_register_fixed_add"] < 4 or
            contract["stage7_fixed_add"] < 6):
        raise ValueError(f"{variant}/{image_id}: incomplete integer Add path {contract}")
    if variant == "7d" and (
            contract["stage7_gemmini_resadd"] != 7 or
            contract["stage7_gemmini_resadd_strided"] != 4):
        raise ValueError(f"{variant}/{image_id}: expected seven Gemmini resadds {contract}")
    if variant in {"7b-lut", "7b-register", "7bc", "7e"}:
        lut_count = len(re.findall(
            r"static const elem_t yolov5nu_add_requant_lut\d+\[256\]",
            parameters,
        ))
        if lut_count != 3:
            raise ValueError(f"{variant}/{image_id}: expected 3 Add requant LUTs, got {lut_count}")
    counts = disassembly_counts(item["elf"])
    required_disassembly = ["vrgather_vv", "vredmax_vs", "vwmul_vv", "vredsum_vs"]
    if variant not in {"7d", "7e"}:
        required_disassembly.append("vfadd_vv")
    for key in required_disassembly:
        if counts[key] == 0:
            raise ValueError(f"{variant}/{image_id}: missing {key}: {counts}")
    if variant == "7b-lut" and counts["vluxei8_v"] == 0:
        raise ValueError(f"{variant}/{image_id}: missing requant LUT gather: {counts}")
    if variant in {"7b-register", "7bc", "7e"} and counts["vluxei8_v"] != 0:
        raise ValueError(f"{variant}/{image_id}: unexpected indexed LUT gather: {counts}")
    if variant in {"7b-register", "7bc", "7e"} and counts["vrgather_vv"] < 2:
        raise ValueError(f"{variant}/{image_id}: missing register LUT gather: {counts}")
    if variant == "7e" and counts["vmul_vx"] < 2:
        raise ValueError(f"{variant}/{image_id}: missing fixed-point vector multiply: {counts}")
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_nhwc_layout.py"),
        "--manifest", str(stage0.MANIFEST), "--source", str(item["source"]),
    ])
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_silu_fusion.py"),
        "--manifest", str(stage0.MANIFEST), "--source", str(item["source"]),
        "--parameters", str(item["parameters"]),
    ])
    run([
        str(python), str(ROOT / "scripts/yolov5nu_validate_memory_plan.py"),
        "--source", str(item["source"]), "--parameters", str(item["parameters"]),
        "--memory-plan", str(item["memory_plan"]),
    ])
    return {
        "variant": variant,
        "image_id": image_id,
        "image": stage0.artifact_record(stage0.image_path(image_id)),
        "direct_concat_count": direct_count,
        "source": stage0.artifact_record(item["source"]),
        "parameters": stage0.artifact_record(item["parameters"]),
        "memory_plan": stage0.artifact_record(item["memory_plan"]),
        "elf": stage0.artifact_record(item["elf"]),
        "contract": contract,
        "disassembly": counts,
    }


def validate(variants: list[str], image_ids: list[str], python: Path) -> None:
    result = {
        "format": "yolov5nu-stage7-concat-add-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": "fpga/xcvu13p/tests/yolov5nu_stage6/uart/stage6-h4-rvvclassmax-sparse-dfl-h3g-rvvlut-hwsilu-image025.txt",
        "variants": variants,
        "image_ids": image_ids,
        "images": [
            validate_one(variant, image_id, python)
            for variant in variants for image_id in image_ids
        ],
    }
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUTPUT_DIR / "build_manifest.json").write_text(json.dumps(result, indent=2) + "\n")
    print(f"Wrote {OUTPUT_DIR / 'build_manifest.json'}")


def main() -> None:
    options = parse_args()
    python = options.python.resolve()
    variants = options.variant or list(VARIANTS)
    image_ids = options.image_id or list(IMAGE_IDS)
    if options.command in {"build", "all"}:
        for variant in variants:
            for image_id in image_ids:
                build(variant, image_id, python)
    if options.command in {"validate", "all"}:
        validate(variants, image_ids, python)


if __name__ == "__main__":
    main()
