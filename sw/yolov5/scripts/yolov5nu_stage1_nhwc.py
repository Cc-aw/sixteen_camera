#!/usr/bin/env python3
"""Build and validate the five-image YOLOv5nu Stage 1 NHWC candidate."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import yolov5nu_stage0_baseline as stage0


ROOT = stage0.ROOT
STAGE1_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage1_nhwc"
VALIDATOR = ROOT / "scripts/yolov5nu_validate_nhwc_layout.py"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all", "check-uart"))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument("--uart-log", type=Path, action="append", default=[])
    return parser.parse_args()


def stem(image_id: str) -> str:
    return f"yolov5nu-stage1-nhwc-image{image_id}-profile"


def source_path(image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(image_id)}.c"


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
            "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
            "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
            "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
        })
        stage0.run([str(stage0.BUILD_SCRIPT)], cwd=ROOT, env=environment)
        source = source_path(image_id)
        parameters = stage0.GENERATOR_DIR / f"{stem(image_id)}_params.h"
        elf = elf_path(image_id)
        for path in (source, parameters, elf):
            if not path.is_file():
                raise FileNotFoundError(path)
        artifacts.append({
            "image_id": image_id,
            "image": stage0.artifact_record(stage0.image_path(image_id)),
            "source": stage0.artifact_record(source),
            "parameters": stage0.artifact_record(parameters),
            "elf": stage0.artifact_record(elf),
        })
    STAGE1_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "format": "yolov5nu-stage1-nhwc-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "physical_layout": "nhwc",
        "profile_cflags": stage0.PROFILE_CFLAGS,
        "model": stage0.artifact_record(stage0.MODEL),
        "graph_manifest": stage0.artifact_record(stage0.MANIFEST),
        "artifacts": artifacts,
    }
    output = STAGE1_DIR / "build_manifest.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")


def validate(python: Path) -> None:
    for image_id in stage0.IMAGE_IDS:
        stage0.run([
            str(python), str(VALIDATOR),
            "--manifest", str(stage0.MANIFEST),
            "--source", str(source_path(image_id)),
        ], cwd=ROOT)


def check_uart(logs: list[Path]) -> None:
    if not logs:
        raise ValueError("check-uart requires at least one --uart-log")
    baseline_report = stage0.STAGE0_DIR / "uart_validation.json"
    if not baseline_report.is_file():
        raise FileNotFoundError(baseline_report)
    baseline = json.loads(baseline_report.read_text())
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
            if run["profile_records"] != stage0.EXPECTED_PROFILE_RECORDS:
                failures.append(f"{image} run {index}: expected 482 profile records")
            signature = {key: run[key] for key in ("tensor_lines", "top_lines", "nms_lines")}
            signatures.append(signature)
            baseline_signature = {
                key: expected[image][key] for key in ("tensor_lines", "top_lines", "nms_lines")
            }
            if signature != baseline_signature:
                failures.append(f"{image} run {index}: not bit-exact with Stage 0 FPGA baseline")
        if any(signature != signatures[0] for signature in signatures[1:]):
            failures.append(f"{image}: repeated NHWC runs are not deterministic")
        graph = [run["cycles"]["graph"] for run in runs]
        baseline_graph = sum(
            run["cycles"]["graph"] for run in baseline_runs[image]
        ) / len(baseline_runs[image])
        stage1_graph = sum(graph) / len(graph)
        stage0_e2e = sum(
            run["cycles"]["graph"] + run["cycles"]["decode"] + run["cycles"]["nms"]
            for run in baseline_runs[image]
        ) / len(baseline_runs[image])
        stage1_e2e = sum(
            run["cycles"]["graph"] + run["cycles"]["decode"] + run["cycles"]["nms"]
            for run in runs
        ) / len(runs)
        images.append({
            "image_id": image_id,
            "image": image,
            "runs": runs,
            "graph_cycles_average": stage1_graph,
            "stage0_graph_cycles_average": baseline_graph,
            "graph_speedup_vs_stage0": baseline_graph / stage1_graph,
            "e2e_cycles_average": stage1_e2e,
            "stage0_e2e_cycles_average": stage0_e2e,
            "e2e_speedup_vs_stage0": stage0_e2e / stage1_e2e,
            "conv_layout_cycles_average": sum(
                run["cycles"]["conv_layout"] for run in runs
            ) / len(runs),
            "stage0_conv_layout_cycles_average": sum(
                run["cycles"]["conv_layout"] for run in baseline_runs[image]
            ) / len(baseline_runs[image]),
        })
        print(f"{image}: checked {len(runs)} NHWC runs")
    if failures:
        raise SystemExit("Stage 1 UART check failed:\n- " + "\n- ".join(failures))
    report = {
        "format": "yolov5nu-stage1-nhwc-uart-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "baseline": str(baseline_report.relative_to(ROOT)),
        "logs": [stage0.artifact_record(log.resolve()) for log in logs],
        "images": images,
    }
    output = STAGE1_DIR / "uart_validation.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")
    print("PASS: Stage 1 NHWC output is deterministic and bit-exact with Stage 0 FPGA")


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
