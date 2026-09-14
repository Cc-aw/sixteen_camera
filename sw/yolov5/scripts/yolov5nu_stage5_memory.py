#!/usr/bin/env python3
"""Build and validate progressive YOLOv5nu Stage 5 memory candidates."""

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
BASELINE_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage41_opt"
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage5_memory"
HEAD_VALIDATOR = ROOT / "scripts/yolov5nu_validate_stage4_heads.py"
MEMORY_VALIDATOR = ROOT / "scripts/yolov5nu_validate_memory_plan.py"
SIZE = ROOT / ".conda-env/riscv-tools/bin/riscv64-unknown-elf-size"
STAGES = ("5a", "5b", "5c", "5d")
BASELINE_STAGE = "5d"
EXPECTED_PROFILE_RECORDS = 398


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command",
        choices=("build", "validate", "all", "check-uart", "baseline", "check-baseline"),
    )
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument("--uart-log", type=Path, action="append", default=[])
    return parser.parse_args()


def image_ids(stage: str) -> tuple[str, ...]:
    return stage0.IMAGE_IDS if stage == "5d" else ("025",)


def stem(stage: str, image_id: str) -> str:
    return f"yolov5nu-stage{stage}-memory-image{image_id}-profile"


def source_path(stage: str, image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(stage, image_id)}.c"


def parameters_path(stage: str, image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(stage, image_id)}_params.h"


def memory_path(stage: str, image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(stage, image_id)}_memory.json"


def elf_path(stage: str, image_id: str) -> Path:
    return stage0.BUILD_DIR / f"{stem(stage, image_id)}-baremetal-uart"


def size_record(elf: Path) -> dict[str, int]:
    output = subprocess.check_output([str(SIZE), str(elf)], text=True).splitlines()[-1]
    text, data, bss, total, _hex, _name = output.split(maxsplit=5)
    return {"text": int(text), "data": int(data), "bss": int(bss), "total": int(total)}


def validate_one(python: Path, stage: str, image_id: str) -> dict:
    stage0.run([
        str(python), str(stage3.NHWC_VALIDATOR), "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(stage, image_id)),
    ], cwd=ROOT)
    stage0.run([
        str(python), str(stage3.SILU_VALIDATOR), "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(stage, image_id)),
        "--parameters", str(parameters_path(stage, image_id)),
    ], cwd=ROOT)
    stage0.run([
        str(python), str(MEMORY_VALIDATOR),
        "--source", str(source_path(stage, image_id)),
        "--parameters", str(parameters_path(stage, image_id)),
        "--memory-plan", str(memory_path(stage, image_id)),
    ], cwd=ROOT)
    source = source_path(stage, image_id).read_text()
    if len(re.findall(r"yolo_profile_add\(", source)) - 2 != EXPECTED_PROFILE_RECORDS:
        raise ValueError(f"Stage {stage} image{image_id}: profile contract changed")
    return size_record(elf_path(stage, image_id))


def build(
    python: Path,
    stages: tuple[str, ...] = STAGES,
    output_name: str = "build_manifest.json",
) -> None:
    stage0.run([str(python), str(HEAD_VALIDATOR), "--optimized-kernels"], cwd=ROOT)
    artifacts = []
    for stage in stages:
        for image_id in image_ids(stage):
            environment = os.environ.copy()
            environment.update({
                "PYTHON": str(python),
                "YOLOV5NU_MODEL": str(stage0.MODEL),
                "YOLOV5NU_MANIFEST": str(stage0.MANIFEST),
                "YOLOV5NU_IMAGE": str(stage0.image_path(image_id)),
                "YOLOV5NU_STEM": stem(stage, image_id),
                "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
                "YOLOV5NU_SILU_MODE": "fused-lut",
                "YOLOV5NU_SILU_KERNEL": "scalar",
                "YOLOV5NU_KERNEL_MODE": "rvv",
                "YOLOV5NU_ADD_KERNEL": "rvv-ratio",
                "YOLOV5NU_HEAD_LOWERING": "location-major",
                "YOLOV5NU_HEAD_KERNEL": "optimized-rvv",
                "YOLOV5NU_MEMORY_STAGE": stage,
                "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
                "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
                "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
            })
            stage0.run([str(stage0.BUILD_SCRIPT)], cwd=ROOT, env=environment)
            paths = (
                source_path(stage, image_id), parameters_path(stage, image_id),
                memory_path(stage, image_id), elf_path(stage, image_id),
            )
            for path in paths:
                if not path.is_file():
                    raise FileNotFoundError(path)
            sizes = validate_one(python, stage, image_id)
            artifacts.append({
                "stage": stage,
                "image_id": image_id,
                "image": stage0.artifact_record(stage0.image_path(image_id)),
                "source": stage0.artifact_record(paths[0]),
                "parameters": stage0.artifact_record(paths[1]),
                "memory_plan": stage0.artifact_record(paths[2]),
                "elf": stage0.artifact_record(paths[3]),
                "elf_sections": sizes,
                "stage3_disassembly": stage3.disassembly_record(paths[3]),
            })
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "format": "yolov5nu-stage5-memory-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "baseline": str((BASELINE_DIR / "uart_validation.json").relative_to(ROOT)),
        "selected_baseline": BASELINE_STAGE,
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "matrix": {stage: list(image_ids(stage)) for stage in stages},
        "artifacts": artifacts,
    }
    output = OUTPUT_DIR / output_name
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")


def validate(python: Path, stages: tuple[str, ...] = STAGES) -> None:
    stage0.run([str(python), str(HEAD_VALIDATOR), "--optimized-kernels"], cwd=ROOT)
    for stage in stages:
        for image_id in image_ids(stage):
            for path in (
                source_path(stage, image_id), parameters_path(stage, image_id),
                memory_path(stage, image_id), elf_path(stage, image_id),
            ):
                if not path.is_file():
                    raise FileNotFoundError(path)
            sizes = validate_one(python, stage, image_id)
            print(f"Stage {stage} image{image_id}: {sizes}")


def check_uart(
    logs: list[Path],
    stages: tuple[str, ...] = STAGES,
    output_name: str = "uart_validation.json",
) -> None:
    if not logs:
        raise ValueError("UART validation requires --uart-log entries")
    baseline_path = BASELINE_DIR / "uart_validation.json"
    baseline = json.loads(baseline_path.read_text())
    expected = {item["image"]: item["runs"][0] for item in baseline["images"]}
    grouped: dict[tuple[str, str], list[dict]] = {}
    failures = []
    for log in logs:
        text = log.read_text(errors="replace")
        stage_match = re.search(r"Memory plan stage: (5[abcd])", text)
        if not stage_match:
            failures.append(f"{log}: missing Stage 5 marker")
            continue
        stage = stage_match.group(1)
        for run in stage0.parse_uart_runs(text):
            grouped.setdefault((stage, run["image"]), []).append(run)
    results = []
    for stage in stages:
        for image_id in image_ids(stage):
            image = stage0.image_path(image_id).name
            runs = grouped.get((stage, image), [])
            if len(runs) < 2:
                failures.append(f"Stage {stage} {image}: expected two runs, found {len(runs)}")
                continue
            expected_signature = {key: expected[image][key] for key in ("tensor_lines", "top_lines", "nms_lines")}
            signatures = []
            for index, run in enumerate(runs):
                if not run["pass"] or not run["exit_zero"]:
                    failures.append(f"Stage {stage} {image} run {index}: missing PASS/zero exit")
                if run["profile_records"] != EXPECTED_PROFILE_RECORDS:
                    failures.append(f"Stage {stage} {image} run {index}: profile count changed")
                signature = {key: run[key] for key in expected_signature}
                signatures.append(signature)
                if signature != expected_signature:
                    failures.append(f"Stage {stage} {image} run {index}: not bit-exact")
            if any(signature != signatures[0] for signature in signatures[1:]):
                failures.append(f"Stage {stage} {image}: repeated runs differ")
            results.append({"stage": stage, "image_id": image_id, "image": image, "runs": runs})
            print(f"Stage {stage} {image}: checked {len(runs)} runs")
    if failures:
        raise SystemExit("Stage 5 UART check failed:\n- " + "\n- ".join(failures))
    report = {
        "format": "yolov5nu-stage5-memory-uart-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "baseline": str(baseline_path.relative_to(ROOT)),
        "selected_baseline": BASELINE_STAGE,
        "logs": [stage0.artifact_record(log.resolve()) for log in logs],
        "results": results,
    }
    output = OUTPUT_DIR / output_name
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")


def main() -> None:
    options = parse_args()
    python = options.python.resolve()
    if options.command in {"build", "all"}:
        build(python)
    if options.command in {"validate", "all"}:
        validate(python)
    if options.command == "check-uart":
        check_uart(options.uart_log)
    if options.command == "baseline":
        build(python, (BASELINE_STAGE,), "baseline_build_manifest.json")
        validate(python, (BASELINE_STAGE,))
    if options.command == "check-baseline":
        check_uart(
            options.uart_log,
            (BASELINE_STAGE,),
            "baseline_uart_validation.json",
        )


if __name__ == "__main__":
    main()
