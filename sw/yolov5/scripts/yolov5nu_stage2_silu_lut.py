#!/usr/bin/env python3
"""Build and validate the five-image YOLOv5nu Stage 2 fused-SiLU candidate."""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import yolov5nu_stage0_baseline as stage0


ROOT = stage0.ROOT
STAGE1_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage1_nhwc"
STAGE2_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage2_silu_lut"
NHWC_VALIDATOR = ROOT / "scripts/yolov5nu_validate_nhwc_layout.py"
SILU_VALIDATOR = ROOT / "scripts/yolov5nu_validate_silu_fusion.py"
EXPECTED_FUSED_SILU = 69
EXPECTED_PROFILE_RECORDS = stage0.EXPECTED_PROFILE_RECORDS - EXPECTED_FUSED_SILU


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all", "check-uart"))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument("--uart-log", type=Path, action="append", default=[])
    return parser.parse_args()


def stem(image_id: str) -> str:
    return f"yolov5nu-stage2-nhwc-silulut-image{image_id}-profile"


def source_path(image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(image_id)}.c"


def parameters_path(image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(image_id)}_params.h"


def elf_path(image_id: str) -> Path:
    return stage0.BUILD_DIR / f"{stem(image_id)}-baremetal-uart"


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
            "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
            "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
            "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
        })
        stage0.run([str(stage0.BUILD_SCRIPT)], cwd=ROOT, env=environment)
        paths = (source_path(image_id), parameters_path(image_id), elf_path(image_id))
        for path in paths:
            if not path.is_file():
                raise FileNotFoundError(path)
        artifacts.append({
            "image_id": image_id,
            "image": stage0.artifact_record(stage0.image_path(image_id)),
            "source": stage0.artifact_record(paths[0]),
            "parameters": stage0.artifact_record(paths[1]),
            "elf": stage0.artifact_record(paths[2]),
        })

    STAGE2_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "format": "yolov5nu-stage2-silu-lut-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "physical_layout": "nhwc",
        "silu_mode": "fused-lut",
        "fused_silu_patterns": EXPECTED_FUSED_SILU,
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "profile_cflags": stage0.PROFILE_CFLAGS,
        "model": stage0.artifact_record(stage0.MODEL),
        "graph_manifest": stage0.artifact_record(stage0.MANIFEST),
        "artifacts": artifacts,
    }
    output = STAGE2_DIR / "build_manifest.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")


def validate(python: Path) -> None:
    for image_id in stage0.IMAGE_IDS:
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


def average(runs: list[dict], key: str) -> float:
    values = [run["cycles"][key] for run in runs]
    return sum(values) / len(values)


def check_uart(logs: list[Path]) -> None:
    if not logs:
        raise ValueError("check-uart requires at least one --uart-log")
    baseline_path = STAGE1_DIR / "uart_validation.json"
    if not baseline_path.is_file():
        raise FileNotFoundError(baseline_path)
    baseline = json.loads(baseline_path.read_text())
    expected = {item["image"]: item["runs"][0] for item in baseline["images"]}
    baseline_runs = {item["image"]: item["runs"] for item in baseline["images"]}
    grouped: dict[str, list[dict]] = {}
    for log in logs:
        for run in stage0.parse_uart_runs(log.read_text(errors="replace")):
            grouped.setdefault(run["image"], []).append(run)

    failures = []
    images = []
    for image_id in stage0.IMAGE_IDS:
        image = stage0.image_path(image_id).name
        runs = grouped.get(image, [])
        if len(runs) < 2:
            failures.append(f"{image}: expected two runs, found {len(runs)}")
            continue
        signatures = []
        for index, run in enumerate(runs):
            if not run["pass"] or not run["exit_zero"]:
                failures.append(f"{image} run {index}: missing PASS or zero exit")
            if run["profile_records"] != EXPECTED_PROFILE_RECORDS:
                failures.append(
                    f"{image} run {index}: profile records={run['profile_records']}, "
                    f"expected {EXPECTED_PROFILE_RECORDS}"
                )
            signature = {key: run[key] for key in ("tensor_lines", "top_lines", "nms_lines")}
            signatures.append(signature)
            baseline_signature = {
                key: expected[image][key] for key in ("tensor_lines", "top_lines", "nms_lines")
            }
            if signature != baseline_signature:
                failures.append(f"{image} run {index}: not bit-exact with Stage 1 FPGA baseline")
        if any(signature != signatures[0] for signature in signatures[1:]):
            failures.append(f"{image}: repeated fused-SiLU runs are not deterministic")

        stage2_graph = average(runs, "graph")
        stage1_graph = average(baseline_runs[image], "graph")
        stage2_e2e = sum(
            run["cycles"]["graph"] + run["cycles"]["decode"] + run["cycles"]["nms"]
            for run in runs
        ) / len(runs)
        stage1_e2e = sum(
            run["cycles"]["graph"] + run["cycles"]["decode"] + run["cycles"]["nms"]
            for run in baseline_runs[image]
        ) / len(baseline_runs[image])
        images.append({
            "image_id": image_id,
            "image": image,
            "runs": runs,
            "graph_cycles_average": stage2_graph,
            "stage1_graph_cycles_average": stage1_graph,
            "graph_speedup_vs_stage1": stage1_graph / stage2_graph,
            "e2e_cycles_average": stage2_e2e,
            "stage1_e2e_cycles_average": stage1_e2e,
            "e2e_speedup_vs_stage1": stage1_e2e / stage2_e2e,
            "silu_fused_cycles_average": average(runs, "silu_fused"),
            "remaining_sigmoid_cycles_average": average(runs, "sigmoid"),
            "remaining_mul_cycles_average": average(runs, "mul"),
        })
        print(f"{image}: checked {len(runs)} fused-SiLU runs")

    if failures:
        raise SystemExit("Stage 2 UART check failed:\n- " + "\n- ".join(failures))
    report = {
        "format": "yolov5nu-stage2-silu-lut-uart-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "baseline": str(baseline_path.relative_to(ROOT)),
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "logs": [stage0.artifact_record(log.resolve()) for log in logs],
        "images": images,
    }
    output = STAGE2_DIR / "uart_validation.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")
    print("PASS: Stage 2 output is deterministic and bit-exact with Stage 1 FPGA")


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
