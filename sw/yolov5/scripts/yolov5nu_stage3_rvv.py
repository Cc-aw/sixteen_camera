#!/usr/bin/env python3
"""Build and validate the five-image YOLOv5nu Stage 3 RVV candidate."""

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


ROOT = stage0.ROOT
BASELINE_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage2_silu_lut"
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage3_rvv"
NHWC_VALIDATOR = ROOT / "scripts/yolov5nu_validate_nhwc_layout.py"
SILU_VALIDATOR = ROOT / "scripts/yolov5nu_validate_silu_fusion.py"
OBJDUMP = ROOT / ".conda-env/riscv-tools/bin/riscv64-unknown-elf-objdump"
EXPECTED_PROFILE_RECORDS = 413
KERNELS = ("copy", "add", "maxpool", "resize")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all", "check-uart"))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument("--uart-log", type=Path, action="append", default=[])
    return parser.parse_args()


def stem(image_id: str) -> str:
    return f"yolov5nu-stage3-rvv-nhwc-silulut-image{image_id}-profile"


def source_path(image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(image_id)}.c"


def parameters_path(image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(image_id)}_params.h"


def elf_path(image_id: str) -> Path:
    return stage0.BUILD_DIR / f"{stem(image_id)}-baremetal-uart"


def validate_one(python: Path, image_id: str) -> None:
    stage0.run([
        str(python), str(NHWC_VALIDATOR),
        "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(image_id)),
    ], cwd=ROOT)
    stage0.run([
        str(python), str(SILU_VALIDATOR),
        "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(image_id)),
        "--parameters", str(parameters_path(image_id)),
    ], cwd=ROOT)


def disassembly_record(elf: Path) -> dict[str, int]:
    if not OBJDUMP.is_file():
        raise FileNotFoundError(OBJDUMP)
    disassembly = subprocess.check_output([str(OBJDUMP), "-d", str(elf)], text=True)
    patterns = {
        "vsext_vf2": r"\bvsext\.vf2\b",
        "vfcvt_f_x": r"\bvfcvt\.f\.x\.v\b",
        "vfcvt_x_f": r"\bvfcvt\.x\.f\.v\b",
        "vnclip_wi": r"\bvnclip\.wi\b",
        "vmax_vv": r"\bvmax\.vv\b",
        "e8_m8_vsetvli": r"\bvsetvli\b[^\n]*\be8,m8,ta,ma\b",
    }
    counts = {name: len(re.findall(pattern, disassembly)) for name, pattern in patterns.items()}
    missing = [name for name, count in counts.items() if count == 0]
    if missing:
        raise RuntimeError(f"{elf} is missing Stage 3 RVV instructions: {', '.join(missing)}")
    return counts


def build(python: Path) -> None:
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
            "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
            "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
            "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
        })
        stage0.run([str(stage0.BUILD_SCRIPT)], cwd=ROOT, env=environment)
        paths = (source_path(image_id), parameters_path(image_id), elf_path(image_id))
        for path in paths:
            if not path.is_file():
                raise FileNotFoundError(path)
        validate_one(python, image_id)
        artifacts.append({
            "image_id": image_id,
            "image": stage0.artifact_record(stage0.image_path(image_id)),
            "source": stage0.artifact_record(paths[0]),
            "parameters": stage0.artifact_record(paths[1]),
            "elf": stage0.artifact_record(paths[2]),
            "disassembly": disassembly_record(paths[2]),
        })

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "format": "yolov5nu-stage3-rvv-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": str((BASELINE_DIR / "uart_validation.json").relative_to(ROOT)),
        "physical_layout": "nhwc",
        "silu_mode": "fused-lut",
        "silu_kernel": "scalar",
        "stage3_kernels": {name: "rvv" for name in KERNELS},
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "profile_cflags": stage0.PROFILE_CFLAGS,
        "model": stage0.artifact_record(stage0.MODEL),
        "graph_manifest": stage0.artifact_record(stage0.MANIFEST),
        "artifacts": artifacts,
    }
    output = OUTPUT_DIR / "build_manifest.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")


def validate(python: Path) -> None:
    for image_id in stage0.IMAGE_IDS:
        for path in (source_path(image_id), parameters_path(image_id), elf_path(image_id)):
            if not path.is_file():
                raise FileNotFoundError(path)
        validate_one(python, image_id)
        counts = disassembly_record(elf_path(image_id))
        print(f"image{image_id}: Stage 3 RVV instructions {counts}")


def average(runs: list[dict], key: str) -> float:
    return sum(run["cycles"][key] for run in runs) / len(runs)


def check_uart(logs: list[Path]) -> None:
    if not logs:
        raise ValueError("check-uart requires at least one --uart-log")
    baseline_path = BASELINE_DIR / "uart_validation.json"
    if not baseline_path.is_file():
        raise FileNotFoundError(baseline_path)
    baseline = json.loads(baseline_path.read_text())
    expected = {item["image"]: item["runs"][0] for item in baseline["images"]}
    baseline_runs = {item["image"]: item["runs"] for item in baseline["images"]}
    grouped: dict[str, list[dict]] = {}
    failures = []
    for log in logs:
        text = log.read_text(errors="replace")
        marker = "Stage 3 kernels: copy=rvv add=rvv maxpool=rvv resize=rvv"
        if marker not in text:
            failures.append(f"{log}: missing all-RVV Stage 3 marker")
            continue
        for run in stage0.parse_uart_runs(text):
            grouped.setdefault(run["image"], []).append(run)

    images = []
    for image_id in stage0.IMAGE_IDS:
        image = stage0.image_path(image_id).name
        runs = grouped.get(image, [])
        if len(runs) < 2:
            failures.append(f"{image}: expected two runs, found {len(runs)}")
            continue
        baseline_signature = {
            key: expected[image][key] for key in ("tensor_lines", "top_lines", "nms_lines")
        }
        signatures = []
        for index, run in enumerate(runs):
            if not run["pass"] or not run["exit_zero"]:
                failures.append(f"{image} run {index}: missing PASS or zero exit")
            if run["profile_records"] != EXPECTED_PROFILE_RECORDS:
                failures.append(
                    f"{image} run {index}: profile records={run['profile_records']}, "
                    f"expected {EXPECTED_PROFILE_RECORDS}"
                )
            signature = {key: run[key] for key in baseline_signature}
            signatures.append(signature)
            if signature != baseline_signature:
                failures.append(f"{image} run {index}: not bit-exact with scalar Stage 2")
        if any(signature != signatures[0] for signature in signatures[1:]):
            failures.append(f"{image}: repeated Stage 3 runs are not deterministic")

        operator_cycles = {
            key: average(runs, key) for key in ("concat", "add", "maxpool", "resize")
        }
        baseline_operator_cycles = {
            key: average(baseline_runs[image], key)
            for key in ("concat", "add", "maxpool", "resize")
        }
        graph = average(runs, "graph")
        baseline_graph = average(baseline_runs[image], "graph")
        images.append({
            "image_id": image_id,
            "image": image,
            "runs": runs,
            "graph_cycles_average": graph,
            "stage2_graph_cycles_average": baseline_graph,
            "graph_speedup_vs_stage2": baseline_graph / graph,
            "operator_cycles_average": operator_cycles,
            "stage2_operator_cycles_average": baseline_operator_cycles,
            "operator_speedup_vs_stage2": {
                key: baseline_operator_cycles[key] / operator_cycles[key]
                for key in operator_cycles
            },
        })
        print(f"{image}: checked {len(runs)} Stage 3 runs")

    if failures:
        raise SystemExit("Stage 3 UART check failed:\n- " + "\n- ".join(failures))
    report = {
        "format": "yolov5nu-stage3-rvv-uart-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "baseline": str(baseline_path.relative_to(ROOT)),
        "stage3_kernels": {name: "rvv" for name in KERNELS},
        "logs": [stage0.artifact_record(log.resolve()) for log in logs],
        "images": images,
    }
    output = OUTPUT_DIR / "uart_validation.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")
    print("PASS: Stage 3 is deterministic and bit-exact with scalar Stage 2")


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
