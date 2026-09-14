#!/usr/bin/env python3
"""Build and validate the optimized YOLOv5nu Stage 4.1 candidate."""

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
BASELINE_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage4_heads"
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage41_opt"
HEAD_VALIDATOR = ROOT / "scripts/yolov5nu_validate_stage4_heads.py"
EXPECTED_PROFILE_RECORDS = 398


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all", "check-uart"))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument("--uart-log", type=Path, action="append", default=[])
    return parser.parse_args()


def stem(image_id: str) -> str:
    return f"yolov5nu-stage41-opt-rvv-nhwc-silulut-image{image_id}-profile"


def source_path(image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(image_id)}.c"


def parameters_path(image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(image_id)}_params.h"


def elf_path(image_id: str) -> Path:
    return stage0.BUILD_DIR / f"{stem(image_id)}-baremetal-uart"


def source_contract(image_id: str) -> dict[str, int]:
    source = source_path(image_id).read_text()
    contract = {
        "class_calls": len(re.findall(r"^  stage4_class_heads_i8\(", source, re.MULTILINE)),
        "dfl_calls": len(re.findall(r"^  stage4_dfl_heads_i8\(", source, re.MULTILINE)),
        "ratio_add_calls": len(re.findall(r"^  add_ratio_i8\(", source, re.MULTILINE)),
        "baseline_add_calls": len(re.findall(r"^  add_i8\(", source, re.MULTILINE)),
        "old_head_calls": sum(len(re.findall(pattern, source, re.MULTILINE)) for pattern in (
            r"^  nhwc_to_ncl_i8\(", r"^  transpose4_i8\(", r"^  softmax_i8\(",
        )),
    }
    expected = {
        "class_calls": 1,
        "dfl_calls": 1,
        "ratio_add_calls": 7,
        "baseline_add_calls": 0,
        "old_head_calls": 0,
    }
    if contract != expected:
        raise ValueError(f"image{image_id}: Stage 4.1 source contract {contract} != {expected}")
    for marker in (
        "Stage 3 kernels: copy=rvv add=rvv-ratio",
        "maxpool=rvv resize=rvv",
        "Detection head lowering: location-major",
        "Detection head kernel: optimized-rvv",
        "YOLOV5NU_ADD_KERNEL_RVV_RATIO 1",
        "YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV 1",
    ):
        if marker not in source and marker not in parameters_path(image_id).read_text():
            raise ValueError(f"image{image_id}: missing marker: {marker}")
    return contract


def disassembly_contract(elf: Path) -> dict[str, int]:
    disassembly = subprocess.check_output([str(stage3.OBJDUMP), "-d", str(elf)], text=True)
    patterns = {
        "vredmax_vs": r"\bvredmax\.vs\b",
        "vfirst_m": r"\bvfirst\.m\b",
        "vfadd_vv": r"\bvfadd\.vv\b",
        "vfdiv_vf": r"\bvfdiv\.vf\b",
    }
    counts = {name: len(re.findall(pattern, disassembly)) for name, pattern in patterns.items()}
    if counts["vredmax_vs"] == 0 or counts["vfirst_m"] == 0 or counts["vfadd_vv"] == 0:
        raise ValueError(f"{elf}: missing optimized RVV instructions: {counts}")
    if counts["vfdiv_vf"] != 0:
        raise ValueError(f"{elf}: ratio Add still contains vfdiv.vf: {counts}")
    return counts


def run_common_validation(python: Path, image_id: str) -> None:
    stage0.run([
        str(python), str(stage3.NHWC_VALIDATOR), "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(image_id)),
    ], cwd=ROOT)
    stage0.run([
        str(python), str(stage3.SILU_VALIDATOR), "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(image_id)), "--parameters", str(parameters_path(image_id)),
    ], cwd=ROOT)


def run_math_validation(python: Path) -> None:
    stage0.run([str(python), str(HEAD_VALIDATOR), "--optimized-kernels"], cwd=ROOT)


def build(python: Path) -> None:
    run_math_validation(python)
    artifacts = []
    for image_id in stage0.IMAGE_IDS:
        environment = os.environ.copy()
        environment.update({
            "PYTHON": str(python),
            "YOLOV5NU_MODEL": str(stage0.MODEL),
            "YOLOV5NU_MANIFEST": str(stage0.MANIFEST),
            "YOLOV5NU_IMAGE": str(stage0.image_path(image_id)),
            "YOLOV5NU_STEM": stem(image_id),
            "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
            "YOLOV5NU_SILU_MODE": "fused-lut",
            "YOLOV5NU_SILU_KERNEL": "scalar",
            "YOLOV5NU_KERNEL_MODE": "rvv",
            "YOLOV5NU_ADD_KERNEL": "rvv-ratio",
            "YOLOV5NU_HEAD_LOWERING": "location-major",
            "YOLOV5NU_HEAD_KERNEL": "optimized-rvv",
            "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
            "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
            "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
        })
        stage0.run([str(stage0.BUILD_SCRIPT)], cwd=ROOT, env=environment)
        for path in (source_path(image_id), parameters_path(image_id), elf_path(image_id)):
            if not path.is_file():
                raise FileNotFoundError(path)
        run_common_validation(python, image_id)
        artifacts.append({
            "image_id": image_id,
            "image": stage0.artifact_record(stage0.image_path(image_id)),
            "source": stage0.artifact_record(source_path(image_id)),
            "parameters": stage0.artifact_record(parameters_path(image_id)),
            "elf": stage0.artifact_record(elf_path(image_id)),
            "source_contract": source_contract(image_id),
            "stage3_disassembly": stage3.disassembly_record(elf_path(image_id)),
            "stage41_disassembly": disassembly_contract(elf_path(image_id)),
        })
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "format": "yolov5nu-stage41-opt-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": str((BASELINE_DIR / "uart_validation.json").relative_to(ROOT)),
        "add_kernel": "rvv-ratio",
        "head_lowering": "location-major",
        "head_kernel": "optimized-rvv",
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "artifacts": artifacts,
    }
    output = OUTPUT_DIR / "build_manifest.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")


def validate(python: Path) -> None:
    run_math_validation(python)
    for image_id in stage0.IMAGE_IDS:
        for path in (source_path(image_id), parameters_path(image_id), elf_path(image_id)):
            if not path.is_file():
                raise FileNotFoundError(path)
        run_common_validation(python, image_id)
        print(f"image{image_id}: source={source_contract(image_id)} elf={disassembly_contract(elf_path(image_id))}")


def average(runs: list[dict], key: str) -> float:
    return sum(run["cycles"][key] for run in runs) / len(runs)


def check_uart(logs: list[Path]) -> None:
    if not logs:
        raise ValueError("check-uart requires at least one --uart-log")
    baseline_path = BASELINE_DIR / "uart_validation.json"
    baseline = json.loads(baseline_path.read_text())
    expected = {item["image"]: item["runs"][0] for item in baseline["images"]}
    baseline_runs = {item["image"]: item["runs"] for item in baseline["images"]}
    grouped: dict[str, list[dict]] = {}
    failures = []
    for log in logs:
        text = log.read_text(errors="replace")
        for marker in (
            "Stage 3 kernels: copy=rvv add=rvv-ratio maxpool=rvv resize=rvv",
            "Detection head kernel: optimized-rvv",
        ):
            if marker not in text:
                failures.append(f"{log}: missing marker: {marker}")
        for run in stage0.parse_uart_runs(text):
            grouped.setdefault(run["image"], []).append(run)
    images = []
    for image_id in stage0.IMAGE_IDS:
        image = stage0.image_path(image_id).name
        runs = grouped.get(image, [])
        if len(runs) < 2:
            failures.append(f"{image}: expected two runs, found {len(runs)}")
            continue
        expected_signature = {key: expected[image][key] for key in ("tensor_lines", "top_lines", "nms_lines")}
        signatures = []
        for index, run in enumerate(runs):
            if not run["pass"] or not run["exit_zero"]:
                failures.append(f"{image} run {index}: missing PASS or zero exit")
            if run["profile_records"] != EXPECTED_PROFILE_RECORDS:
                failures.append(f"{image} run {index}: expected 398 profile records")
            signature = {key: run[key] for key in expected_signature}
            signatures.append(signature)
            if signature != expected_signature:
                failures.append(f"{image} run {index}: not bit-exact with Stage 4")
        if any(signature != signatures[0] for signature in signatures[1:]):
            failures.append(f"{image}: repeated runs are not deterministic")
        graph = average(runs, "graph")
        baseline_graph = average(baseline_runs[image], "graph")
        images.append({
            "image_id": image_id,
            "image": image,
            "runs": runs,
            "graph_cycles_average": graph,
            "stage4_graph_cycles_average": baseline_graph,
            "graph_speedup_vs_stage4": baseline_graph / graph,
        })
        print(f"{image}: checked {len(runs)} Stage 4.1 runs")
    if failures:
        raise SystemExit("Stage 4.1 UART check failed:\n- " + "\n- ".join(failures))
    report = {
        "format": "yolov5nu-stage41-opt-uart-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "baseline": str(baseline_path.relative_to(ROOT)),
        "logs": [stage0.artifact_record(log.resolve()) for log in logs],
        "images": images,
    }
    output = OUTPUT_DIR / "uart_validation.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")
    print("PASS: Stage 4.1 is deterministic and bit-exact with Stage 4")


def main() -> None:
    options = parse_args()
    python = options.python.resolve()
    if options.command in {"build", "all"}:
        build(python)
    if options.command in {"validate", "all"}:
        validate(python)
    if options.command == "check-uart":
        check_uart(options.uart_log)


if __name__ == "__main__":
    main()
