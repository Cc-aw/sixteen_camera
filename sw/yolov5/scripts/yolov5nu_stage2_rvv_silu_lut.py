#!/usr/bin/env python3
"""Build and validate Stage 2 RVV indexed-load fused-SiLU candidates."""

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
STAGE2_SCALAR_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage2_silu_lut"
OUTPUT_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage2_rvv_silu_lut"
NHWC_VALIDATOR = ROOT / "scripts/yolov5nu_validate_nhwc_layout.py"
SILU_VALIDATOR = ROOT / "scripts/yolov5nu_validate_silu_fusion.py"
OBJDUMP = ROOT / ".conda-env/riscv-tools/bin/riscv64-unknown-elf-objdump"
KERNELS = ("rvv-e8m1", "rvv-e8m2")
EXPECTED_FUSED_SILU = 69
EXPECTED_PROFILE_RECORDS = stage0.EXPECTED_PROFILE_RECORDS - EXPECTED_FUSED_SILU


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("build", "validate", "all", "check-uart"))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument("--kernel", choices=KERNELS, action="append", default=[])
    parser.add_argument("--uart-log", type=Path, action="append", default=[])
    return parser.parse_args()


def selected_kernels(options: argparse.Namespace) -> tuple[str, ...]:
    return tuple(dict.fromkeys(options.kernel)) if options.kernel else KERNELS


def stem(kernel: str, image_id: str) -> str:
    return f"yolov5nu-stage2-{kernel}-nhwc-silulut-image{image_id}-profile"


def source_path(kernel: str, image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(kernel, image_id)}.c"


def parameters_path(kernel: str, image_id: str) -> Path:
    return stage0.GENERATOR_DIR / f"{stem(kernel, image_id)}_params.h"


def elf_path(kernel: str, image_id: str) -> Path:
    return stage0.BUILD_DIR / f"{stem(kernel, image_id)}-baremetal-uart"


def disassembly_record(kernel: str, elf: Path) -> dict[str, int | str]:
    if not OBJDUMP.is_file():
        raise FileNotFoundError(OBJDUMP)
    disassembly = subprocess.check_output([str(OBJDUMP), "-d", str(elf)], text=True)
    indexed_loads = len(re.findall(r"\bvluxei8\.v\b", disassembly))
    lmul = kernel.rsplit("m", 1)[1]
    selected_vsetvli = len(re.findall(rf"\bvsetvli\b[^\n]*\be8,m{lmul},ta,ma\b", disassembly))
    if indexed_loads == 0:
        raise RuntimeError(f"{elf} does not contain vluxei8.v")
    if selected_vsetvli == 0:
        raise RuntimeError(f"{elf} does not contain the expected e8,m{lmul} vsetvli")
    return {
        "kernel": kernel,
        "vluxei8_instruction_count": indexed_loads,
        "selected_vsetvli_instruction_count": selected_vsetvli,
    }


def validate_one(python: Path, kernel: str, image_id: str) -> None:
    stage0.run([
        str(python), str(NHWC_VALIDATOR),
        "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(kernel, image_id)),
    ], cwd=ROOT)
    stage0.run([
        str(python), str(SILU_VALIDATOR),
        "--manifest", str(stage0.MANIFEST),
        "--source", str(source_path(kernel, image_id)),
        "--parameters", str(parameters_path(kernel, image_id)),
    ], cwd=ROOT)


def build(python: Path, kernels: tuple[str, ...]) -> None:
    artifacts = []
    for kernel in kernels:
        for image_id in stage0.IMAGE_IDS:
            environment = os.environ.copy()
            environment.update({
                "PYTHON": str(python),
                "YOLOV5NU_MODEL": str(stage0.MODEL),
                "YOLOV5NU_MANIFEST": str(stage0.MANIFEST),
                "YOLOV5NU_IMAGE": str(stage0.image_path(image_id)),
                "YOLOV5NU_STEM": stem(kernel, image_id),
                "YOLOV5NU_PHYSICAL_LAYOUT": "nhwc",
                "YOLOV5NU_SILU_MODE": "fused-lut",
                "YOLOV5NU_SILU_KERNEL": kernel,
                "YOLOV5NU_CFLAGS": stage0.PROFILE_CFLAGS,
                "YOLOV5NU_NMS_SCORE_THRESHOLD": str(stage0.NMS_SCORE_THRESHOLD),
                "YOLOV5NU_NMS_IOU_THRESHOLD": str(stage0.NMS_IOU_THRESHOLD),
            })
            stage0.run([str(stage0.BUILD_SCRIPT)], cwd=ROOT, env=environment)
            paths = (
                source_path(kernel, image_id),
                parameters_path(kernel, image_id),
                elf_path(kernel, image_id),
            )
            for path in paths:
                if not path.is_file():
                    raise FileNotFoundError(path)
            validate_one(python, kernel, image_id)
            instructions = disassembly_record(kernel, paths[2])
            artifacts.append({
                "kernel": kernel,
                "image_id": image_id,
                "image": stage0.artifact_record(stage0.image_path(image_id)),
                "source": stage0.artifact_record(paths[0]),
                "parameters": stage0.artifact_record(paths[1]),
                "elf": stage0.artifact_record(paths[2]),
                "disassembly": instructions,
            })

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    report = {
        "format": "yolov5nu-stage2-rvv-silu-lut-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "physical_layout": "nhwc",
        "silu_mode": "fused-lut",
        "silu_kernels": list(kernels),
        "fused_silu_patterns": EXPECTED_FUSED_SILU,
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "profile_cflags": stage0.PROFILE_CFLAGS,
        "model": stage0.artifact_record(stage0.MODEL),
        "graph_manifest": stage0.artifact_record(stage0.MANIFEST),
        "artifacts": artifacts,
    }
    output = OUTPUT_DIR / "build_manifest.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")


def validate(python: Path, kernels: tuple[str, ...]) -> None:
    for kernel in kernels:
        for image_id in stage0.IMAGE_IDS:
            for path in (source_path(kernel, image_id), parameters_path(kernel, image_id),
                         elf_path(kernel, image_id)):
                if not path.is_file():
                    raise FileNotFoundError(path)
            validate_one(python, kernel, image_id)
            record = disassembly_record(kernel, elf_path(kernel, image_id))
            print(
                f"{kernel} image{image_id}: "
                f"vluxei8={record['vluxei8_instruction_count']} "
                f"vsetvli={record['selected_vsetvli_instruction_count']}"
            )


def check_uart(logs: list[Path], kernels: tuple[str, ...]) -> None:
    if not logs:
        raise ValueError("check-uart requires at least one --uart-log")
    baseline_path = STAGE2_SCALAR_DIR / "uart_validation.json"
    if not baseline_path.is_file():
        raise FileNotFoundError(baseline_path)
    baseline = json.loads(baseline_path.read_text())
    expected = {item["image"]: item["runs"][0] for item in baseline["images"]}
    grouped: dict[str, dict[str, list[dict]]] = {
        kernel: {} for kernel in kernels
    }
    failures = []
    for log in logs:
        text = log.read_text(errors="replace")
        present = [kernel for kernel in kernels if f"SiLU kernel: {kernel}" in text]
        if len(present) != 1:
            failures.append(f"{log}: expected exactly one selected SiLU kernel marker")
            continue
        kernel = present[0]
        for run in stage0.parse_uart_runs(text):
            grouped[kernel].setdefault(run["image"], []).append(run)

    images = []
    for kernel in kernels:
        for image_id in stage0.IMAGE_IDS:
            image = stage0.image_path(image_id).name
            runs = grouped[kernel].get(image, [])
            if len(runs) < 2:
                failures.append(f"{kernel} {image}: expected two runs, found {len(runs)}")
                continue
            baseline_signature = {
                key: expected[image][key] for key in ("tensor_lines", "top_lines", "nms_lines")
            }
            signatures = []
            for index, run in enumerate(runs):
                if not run["pass"] or not run["exit_zero"]:
                    failures.append(f"{kernel} {image} run {index}: missing PASS or zero exit")
                if run["profile_records"] != EXPECTED_PROFILE_RECORDS:
                    failures.append(
                        f"{kernel} {image} run {index}: profile records={run['profile_records']}"
                    )
                signature = {
                    key: run[key] for key in ("tensor_lines", "top_lines", "nms_lines")
                }
                signatures.append(signature)
                if signature != baseline_signature:
                    failures.append(f"{kernel} {image} run {index}: not bit-exact with scalar Stage 2")
            if any(signature != signatures[0] for signature in signatures[1:]):
                failures.append(f"{kernel} {image}: repeated runs are not deterministic")
            images.append({"kernel": kernel, "image_id": image_id, "image": image, "runs": runs})

    if failures:
        raise SystemExit("Stage 2 RVV UART check failed:\n- " + "\n- ".join(failures))
    report = {
        "format": "yolov5nu-stage2-rvv-silu-lut-uart-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "baseline": str(baseline_path.relative_to(ROOT)),
        "kernels": list(kernels),
        "logs": [stage0.artifact_record(log.resolve()) for log in logs],
        "images": images,
    }
    output = OUTPUT_DIR / "uart_validation.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")
    print("PASS: RVV candidates are deterministic and bit-exact with scalar Stage 2")


def main() -> None:
    options = parse_args()
    kernels = selected_kernels(options)
    python = options.python.resolve()
    if options.command in {"build", "all"}:
        build(python, kernels)
    if options.command in {"validate", "all"}:
        validate(python, kernels)
    if options.command == "check-uart":
        check_uart(options.uart_log, kernels)


if __name__ == "__main__":
    main()
