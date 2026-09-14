#!/usr/bin/env python3
"""Generate the Stage 8B single-Add Gemmini resadd candidate.

Stage 8B consumes the independent Stage 8A ONNX candidate.  Only the selected
shared-scale Add is lowered to Gemmini resadd; the other six Adds retain the
Stage 7E RVV fixed-point implementation.  The selected Add is deliberately
materialized at its ONNX Add output scale before the existing Concat requant,
so the candidate keeps the Stage 8A two-quantization graph semantics.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import onnx


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
STAGE8A_DIR = MODEL_DIR / "stage8a_shared_scale"
DEFAULT_MODEL = STAGE8A_DIR / "yolov5nu-stage8a-shared-scale.onnx"
DEFAULT_MANIFEST = STAGE8A_DIR / "yolov5nu-stage8a-shared-scale.graph.json"
DEFAULT_IMAGE = MODEL_DIR / "calibration/coco128/images/train2017/000000000025.jpg"
DEFAULT_OUTPUT_DIR = MODEL_DIR / "stage8b_shared_resadd"
ADD_NAME = "/model.2/m/m.0/Add"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--image", type=Path, default=DEFAULT_IMAGE)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--add-name", default=ADD_NAME, choices=(ADD_NAME,))
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def run(command: list[str]) -> None:
    print("+", " ".join(command), flush=True)
    subprocess.run(command, cwd=ROOT, check=True)


def source_contract(source: str, parameters: str, add_name: str) -> dict[str, Any]:
    def calls(name: str) -> int:
        count = len(re.findall(rf"\b{name}\(", source))
        if re.search(rf"\bstatic void {name}\(", source):
            count -= 1
        return count

    selected_call = len(re.findall(
        rf"add_gemmini_shared_resadd_i8\([^;]+\);", source
    ))
    direct_selected = (
        f"GEMMINI_SILU_DIRECT_CONCAT: {add_name}" in source
        or "add_two_step_register_fixed_i8_strided(tensor_11" in source
    )
    contract = {
        "selected_add": add_name,
        "shared_resadd_calls": selected_call,
        "rvv_fixed_add_calls": calls("add_fixed_i8"),
        "gemmini_resadd_calls": calls("add_gemmini_resadd_i8"),
        "selected_add_direct_concat": direct_selected,
        "stage8b_marker": "YOLOV5NU_STAGE8_MODE_8B 1" in parameters,
    }
    if selected_call != 1:
        raise ValueError(f"expected one shared Gemmini resadd call: {contract}")
    if direct_selected:
        raise ValueError("selected Stage 8B Add was incorrectly fused into direct Concat")
    if not contract["stage8b_marker"]:
        raise ValueError("generated source lacks Stage 8B marker")
    return contract


def main() -> None:
    args = parse_args()
    for path in (args.model, args.manifest, args.image):
        if not path.resolve().is_file():
            raise FileNotFoundError(path)
    manifest = json.loads(args.manifest.read_text())
    operation = next(
        item for item in manifest["ops"] if item["name"] == args.add_name
    )
    input_records = [
        manifest["tensor_quantization"][name]
        for name in operation["inputs"]
    ]
    input_scales = [float(item["scale"]) for item in input_records]
    output = operation["output_quantization"][operation["outputs"][0]]
    output_scale = float(output["scale"])
    if input_scales[0] != input_scales[1]:
        raise ValueError(f"Stage 8B requires shared input scales, got {input_scales}")
    if int(input_records[0]["zero_point"]) != 0 or int(output["zero_point"]) != 0:
        raise ValueError("Stage 8B requires symmetric zero points")
    onnx.checker.check_model(onnx.load(args.model, load_external_data=True))

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    stem = "yolov5nu-stage8b-shared-resadd-image025-profile"
    generator = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"
    run([
        str(args.python.resolve()), str(generator),
        "--model", str(args.model.resolve()),
        "--manifest", str(args.manifest.resolve()),
        "--image", str(args.image.resolve()),
        "--output-dir", str(output_dir),
        "--stem", stem,
        "--physical-layout", "nhwc",
        "--silu-mode", "fused-lut",
        "--silu-kernel", "gemmini-lut",
        "--kernel-mode", "rvv",
        "--add-kernel", "rvv-ratio",
        "--head-lowering", "location-major",
        "--head-kernel", "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
        "--head-output-mode", "detection-only",
        "--head-candidate-kernel", "rvv",
        "--stage7-mode", "7e",
        "--stage8-mode", "8b",
        "--stage8-add-name", args.add_name,
        "--memory-stage", "5d",
    ])
    source = output_dir / f"{stem}.c"
    parameters = output_dir / f"{stem}_params.h"
    memory = output_dir / f"{stem}_memory.json"
    contract = source_contract(source.read_text(), parameters.read_text(), args.add_name)
    report = {
        "format": "yolov5nu-stage8b-shared-resadd-build-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "8B",
        "source_model": str(args.model.resolve()),
        "manifest": str(args.manifest.resolve()),
        "selected_add": args.add_name,
        "input_scales": input_scales,
        "output_scale": output_scale,
        "gemmini_output_scale_ratio": input_scales[0] / output_scale,
        "semantics": "Q((A + B) * shared_scale / add_output_scale)",
        "direct_concat_for_selected_add": False,
        "contract": contract,
        "artifacts": {
            "source": str(source),
            "parameters": str(parameters),
            "memory_plan": str(memory),
        },
        "note": (
            "Hardware/RTL behavior is not claimed bit-exact until this source "
            "is run on the Gemmini target and compared with the Stage 8A ORT reference."
        ),
    }
    report_path = output_dir / "build_manifest.json"
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {report_path}")
    print(f"PASS: one shared Gemmini resadd call; output ratio={input_scales[0] / output_scale:.10g}")


if __name__ == "__main__":
    main()
