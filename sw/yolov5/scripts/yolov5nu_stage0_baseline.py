#!/usr/bin/env python3
"""Build and validate the fixed five-image YOLOv5nu Stage 0 baseline."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import onnx
import onnxruntime as ort
from onnx import helper


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
MODEL = MODEL_DIR / "yolov5nu-gemmini-int8-img320.onnx"
MANIFEST = MODEL.with_suffix(".graph.json")
IMAGE_DIR = MODEL_DIR / "calibration/coco128/images/train2017"
GENERATOR_DIR = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet"
BUILD_DIR = ROOT / "generators/gemmini/software/gemmini-rocc-tests/build/imagenet"
STAGE0_DIR = ROOT / "fpga/xcvu13p/tests/yolov5nu_stage0"
REFERENCE_DIR = STAGE0_DIR / "reference"
CONV_LOG_DIR = STAGE0_DIR / "conv_validation"
BUILD_SCRIPT = ROOT / "scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh"
GRAPH_PARSER = ROOT / "scripts/yolov5nu_graph_parser.py"
CONV_VALIDATOR = ROOT / "scripts/yolov5nu_validate_baremetal_reference.py"

IMAGE_IDS = ("025", "142", "036", "404", "650")
PROFILE_CFLAGS = (
    "-DYOLOV5NU_PROFILE=1 "
    "-DYOLOV5NU_LAYER_STATS=0 "
    "-DYOLOV5NU_FINAL_TENSOR_STATS=1"
)
NMS_SCORE_THRESHOLD = 0.25
NMS_IOU_THRESHOLD = 0.45
EXPECTED_PROFILE_RECORDS = 482

COCO_NAMES = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck",
    "boat", "traffic light", "fire hydrant", "stop sign", "parking meter", "bench",
    "bird", "cat", "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra",
    "giraffe", "backpack", "umbrella", "handbag", "tie", "suitcase", "frisbee",
    "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove",
    "skateboard", "surfboard", "tennis racket", "bottle", "wine glass", "cup", "fork",
    "knife", "spoon", "bowl", "banana", "apple", "sandwich", "orange", "broccoli",
    "carrot", "hot dog", "pizza", "donut", "cake", "chair", "couch", "potted plant",
    "bed", "dining table", "toilet", "tv", "laptop", "mouse", "remote", "keyboard",
    "cell phone", "microwave", "oven", "toaster", "sink", "refrigerator", "book",
    "clock", "vase", "scissors", "teddy bear", "hair drier", "toothbrush",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "command",
        choices=("build", "manifest", "reference", "validate-convs", "all", "check-uart"),
    )
    parser.add_argument(
        "--python",
        type=Path,
        default=Path(sys.executable),
        help="Python executable passed to existing build and validation scripts",
    )
    parser.add_argument(
        "--uart-log",
        type=Path,
        action="append",
        default=[],
        help="UART log containing at least two runs; repeat for multiple files",
    )
    parser.add_argument(
        "--require-ort-match",
        action="store_true",
        help="Fail check-uart when FPGA output is not bit-exact with ORT",
    )
    return parser.parse_args()


def image_path(image_id: str) -> Path:
    return IMAGE_DIR / f"000000000{image_id}.jpg"


def stem(image_id: str) -> str:
    return f"yolov5nu-stage0-image{image_id}-profile"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def run(command: list[str], **kwargs: Any) -> subprocess.CompletedProcess[str]:
    print("+", " ".join(command), flush=True)
    return subprocess.run(command, check=True, text=True, **kwargs)


def command_output(command: list[str], cwd: Path | None = None) -> str:
    return subprocess.run(
        command,
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    ).stdout.strip()


def require_inputs() -> None:
    required = [MODEL, BUILD_SCRIPT, GRAPH_PARSER, CONV_VALIDATOR]
    required.extend(image_path(image_id) for image_id in IMAGE_IDS)
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        raise FileNotFoundError("missing Stage 0 inputs:\n" + "\n".join(missing))


def ensure_manifest(python: Path) -> None:
    run([
        str(python),
        str(GRAPH_PARSER),
        "--model",
        str(MODEL),
        "--output",
        str(MANIFEST),
    ])


def git_state(path: Path) -> dict[str, Any]:
    try:
        revision = command_output(["git", "rev-parse", "HEAD"], cwd=path)
        return {"revision": revision, "dirty": "not-scanned"}
    except subprocess.CalledProcessError as error:
        return {"error": error.stdout}


def build_baselines(python: Path) -> None:
    require_inputs()
    STAGE0_DIR.mkdir(parents=True, exist_ok=True)
    artifacts: list[dict[str, Any]] = []

    for image_id in IMAGE_IDS:
        current_stem = stem(image_id)
        environment = os.environ.copy()
        environment.update({
            "PYTHON": str(python),
            "YOLOV5NU_MODEL": str(MODEL),
            "YOLOV5NU_MANIFEST": str(MANIFEST),
            "YOLOV5NU_IMAGE": str(image_path(image_id)),
            "YOLOV5NU_STEM": current_stem,
            "YOLOV5NU_CFLAGS": PROFILE_CFLAGS,
            "YOLOV5NU_NMS_SCORE_THRESHOLD": str(NMS_SCORE_THRESHOLD),
            "YOLOV5NU_NMS_IOU_THRESHOLD": str(NMS_IOU_THRESHOLD),
        })
        run([str(BUILD_SCRIPT)], cwd=ROOT, env=environment)

        source = GENERATOR_DIR / f"{current_stem}.c"
        parameters = GENERATOR_DIR / f"{current_stem}_params.h"
        elf = BUILD_DIR / f"{current_stem}-baremetal-uart"
        for path in (source, parameters, elf):
            if not path.is_file():
                raise FileNotFoundError(path)
        artifacts.append({
            "image_id": image_id,
            "image": str(image_path(image_id).relative_to(ROOT)),
            "image_sha256": sha256(image_path(image_id)),
            "stem": current_stem,
            "source": artifact_record(source),
            "parameters": artifact_record(parameters),
            "elf": artifact_record(elf),
        })

    write_build_manifest(python, artifacts)


def collect_existing_artifacts() -> list[dict[str, Any]]:
    artifacts: list[dict[str, Any]] = []
    for image_id in IMAGE_IDS:
        current_stem = stem(image_id)
        source = GENERATOR_DIR / f"{current_stem}.c"
        parameters = GENERATOR_DIR / f"{current_stem}_params.h"
        elf = BUILD_DIR / f"{current_stem}-baremetal-uart"
        for path in (source, parameters, elf):
            if not path.is_file():
                raise FileNotFoundError(path)
        artifacts.append({
            "image_id": image_id,
            "image": str(image_path(image_id).relative_to(ROOT)),
            "image_sha256": sha256(image_path(image_id)),
            "stem": current_stem,
            "source": artifact_record(source),
            "parameters": artifact_record(parameters),
            "elf": artifact_record(elf),
        })
    return artifacts


def write_build_manifest(python: Path, artifacts: list[dict[str, Any]]) -> None:
    STAGE0_DIR.mkdir(parents=True, exist_ok=True)
    riscv_root = Path(os.environ.get("RISCV", ROOT / ".conda-env/riscv-tools"))
    compiler = riscv_root / "bin/riscv64-unknown-elf-gcc"
    manifest_data = {
        "format": "yolov5nu-stage0-build-manifest-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "model": artifact_record(MODEL),
        "graph_manifest": artifact_record(MANIFEST),
        "images": list(IMAGE_IDS),
        "profile_cflags": PROFILE_CFLAGS,
        "nms_score_threshold": NMS_SCORE_THRESHOLD,
        "nms_iou_threshold": NMS_IOU_THRESHOLD,
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "python": str(python),
        "compiler": str(compiler),
        "compiler_version": command_output([str(compiler), "--version"]).splitlines()[0],
        "chipyard_git": git_state(ROOT),
        "gemmini_git": git_state(ROOT / "generators/gemmini"),
        "artifacts": artifacts,
    }
    output = STAGE0_DIR / "build_manifest.json"
    output.write_text(json.dumps(manifest_data, indent=2) + "\n")
    print(f"Wrote {output}")


def artifact_record(path: Path) -> dict[str, Any]:
    return {
        "path": str(path.relative_to(ROOT)),
        "size": path.stat().st_size,
        "sha256": sha256(path),
    }


def letterbox(path: Path, height: int, width: int) -> np.ndarray:
    # Keep preprocessing byte-for-byte aligned with the baremetal generator.
    from PIL import Image

    image = Image.open(path).convert("RGB")
    source_width, source_height = image.size
    ratio = min(width / source_width, height / source_height)
    resized = (round(source_width * ratio), round(source_height * ratio))
    image = image.resize(resized, Image.Resampling.BILINEAR)
    canvas = Image.new("RGB", (width, height), (114, 114, 114))
    left = round((width - resized[0]) / 2 - 0.1)
    top = round((height - resized[1]) / 2 - 0.1)
    canvas.paste(image, (left, top))
    return np.asarray(canvas, dtype=np.float32).transpose(2, 0, 1)[None] / 255.0


def output_quantization(manifest: dict[str, Any], op_name: str) -> dict[str, Any]:
    operation = next(op for op in manifest["ops"] if op["name"] == op_name)
    output = operation["outputs"][0]
    return operation["output_quantization"][output]


def add_int8_outputs(model: onnx.ModelProto, names: list[str]) -> onnx.ModelProto:
    result = copy.deepcopy(model)
    existing = {item.name for item in result.graph.output}
    for name in names:
        if name not in existing:
            result.graph.output.append(helper.make_tensor_value_info(name, onnx.TensorProto.INT8, None))
    return result


def tensor_summary(values: np.ndarray) -> dict[str, int]:
    flat = values.astype(np.int64, copy=False).reshape(-1)
    return {
        "elems": int(flat.size),
        "checksum": int(flat.sum()),
        "min": int(flat.min()),
        "max": int(flat.max()),
        "saturated": int(np.count_nonzero((flat == 127) | (flat == -128))),
    }


def candidate(dfl: np.ndarray, dfl_scale: float, classes: np.ndarray,
              class_scale: float, index: int) -> dict[str, Any]:
    class_values = classes[:, index]
    class_id = int(np.argmax(class_values))
    score = float(np.float32(class_values[class_id]) * np.float32(class_scale))
    if index < 1600:
        local, width, stride = index, 40, 8
    elif index < 2000:
        local, width, stride = index - 1600, 20, 16
    else:
        local, width, stride = index - 2000, 10, 32
    x, y = local % width, local // width
    sides = dfl[:, index].astype(np.float32) * np.float32(dfl_scale)
    left, top, right, bottom = (float(value) for value in sides)
    return {
        "score": score,
        "class_id": class_id,
        "class_name": COCO_NAMES[class_id],
        "index": index,
        "cx": (x + 0.5 + (right - left) * 0.5) * stride,
        "cy": (y + 0.5 + (bottom - top) * 0.5) * stride,
        "w": (left + right) * stride,
        "h": (top + bottom) * stride,
    }


def top_detections(dfl: np.ndarray, dfl_scale: float, classes: np.ndarray,
                   class_scale: float) -> list[dict[str, Any]]:
    top = [empty_detection() for _ in range(10)]
    for index in range(2100):
        value = candidate(dfl, dfl_scale, classes, class_scale, index)
        if value["score"] <= top[9]["score"]:
            continue
        position = 9
        while position > 0 and value["score"] > top[position - 1]["score"]:
            top[position] = top[position - 1]
            position -= 1
        top[position] = value
    return top


def empty_detection() -> dict[str, Any]:
    return {
        "score": 0.0,
        "class_id": 0,
        "class_name": COCO_NAMES[0],
        "index": 0,
        "cx": 0.0,
        "cy": 0.0,
        "w": 0.0,
        "h": 0.0,
    }


def iou(first: dict[str, Any], second: dict[str, Any]) -> float:
    first_x0, first_y0 = first["cx"] - first["w"] * 0.5, first["cy"] - first["h"] * 0.5
    first_x1, first_y1 = first["cx"] + first["w"] * 0.5, first["cy"] + first["h"] * 0.5
    second_x0, second_y0 = second["cx"] - second["w"] * 0.5, second["cy"] - second["h"] * 0.5
    second_x1, second_y1 = second["cx"] + second["w"] * 0.5, second["cy"] + second["h"] * 0.5
    intersect_w = min(first_x1, second_x1) - max(first_x0, second_x0)
    intersect_h = min(first_y1, second_y1) - max(first_y0, second_y0)
    if intersect_w <= 0.0 or intersect_h <= 0.0:
        return 0.0
    intersection = intersect_w * intersect_h
    union = first["w"] * first["h"] + second["w"] * second["h"] - intersection
    return intersection / union if union > 0.0 else 0.0


def nms_detections(dfl: np.ndarray, dfl_scale: float, classes: np.ndarray,
                   class_scale: float) -> list[dict[str, Any]]:
    candidates = [
        value
        for index in range(2100)
        if (value := candidate(dfl, dfl_scale, classes, class_scale, index))["score"]
        >= NMS_SCORE_THRESHOLD
    ]
    suppressed = [False] * len(candidates)
    output: list[dict[str, Any]] = []
    while len(output) < 10:
        best = -1
        for index, value in enumerate(candidates):
            if not suppressed[index] and (best < 0 or value["score"] > candidates[best]["score"]):
                best = index
        if best < 0:
            break
        output.append(candidates[best])
        suppressed[best] = True
        for index, value in enumerate(candidates):
            if (
                not suppressed[index]
                and value["class_id"] == candidates[best]["class_id"]
                and iou(value, candidates[best]) > NMS_IOU_THRESHOLD
            ):
                suppressed[index] = True
    return output


def detection_line(rank: int, value: dict[str, Any]) -> str:
    score_milli = int(value["score"] * 1000.0 + 0.5)
    return (
        f"#{rank} {value['class_name']} score_milli={score_milli} "
        f"bbox_cxcywh=({int(value['cx'])},{int(value['cy'])},"
        f"{int(value['w'])},{int(value['h'])}) index={value['index']}"
    )


def summary_line(name: str, summary: dict[str, int]) -> str:
    return (
        f"{name} elems={summary['elems']} checksum={summary['checksum']} "
        f"min={summary['min']} max={summary['max']} saturated={summary['saturated']}"
    )


def generate_references(python: Path) -> None:
    require_inputs()
    ensure_manifest(python)
    manifest = json.loads(MANIFEST.read_text())
    class_logits_record = output_quantization(manifest, "/model.24/Concat_1")
    classes_record = output_quantization(manifest, "/model.24/Sigmoid")
    dfl_record = output_quantization(manifest, "/model.24/dfl/Reshape_1")
    records = {
        "class_logits": class_logits_record,
        "classes": classes_record,
        "dfl": dfl_record,
    }
    output_names = [record["quantized_tensor"] for record in records.values()]
    debug_model = add_int8_outputs(onnx.load(MODEL, load_external_data=True), output_names)

    REFERENCE_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".onnx") as temporary:
        onnx.save(debug_model, temporary.name)
        session = ort.InferenceSession(temporary.name, providers=["CPUExecutionProvider"])
        input_meta = session.get_inputs()[0]
        height, width = int(input_meta.shape[2]), int(input_meta.shape[3])
        results: list[dict[str, Any]] = []
        for image_id in IMAGE_IDS:
            image = image_path(image_id)
            values = session.run(output_names, {input_meta.name: letterbox(image, height, width)})
            tensors = dict(zip(records, values))
            summaries = {name: tensor_summary(value) for name, value in tensors.items()}
            classes = tensors["classes"].reshape(80, 2100)
            dfl = tensors["dfl"].reshape(4, 2100)
            top = top_detections(dfl, float(dfl_record["scale"]), classes, float(classes_record["scale"]))
            nms = nms_detections(dfl, float(dfl_record["scale"]), classes, float(classes_record["scale"]))
            tensor_lines = [
                summary_line("YOLOv5nu class logits", summaries["class_logits"]),
                summary_line("YOLOv5nu class sigmoid", summaries["classes"]),
                summary_line("YOLOv5nu DFL distances", summaries["dfl"]),
            ]
            top_lines = [detection_line(index, value) for index, value in enumerate(top)]
            nms_lines = [detection_line(index, value) for index, value in enumerate(nms)]
            result = {
                "image_id": image_id,
                "image": image.name,
                "image_sha256": sha256(image),
                "tensors": summaries,
                "tensor_lines": tensor_lines,
                "top_detections": top,
                "top_lines": top_lines,
                "nms_detections": nms,
                "nms_lines": nms_lines,
            }
            results.append(result)
            lines = [
                f"YOLOv5nu Stage 0 ONNX Runtime reference for {image.name}",
                *tensor_lines,
                f"YOLOv5nu top detections for {image.name} (no NMS)",
                *top_lines,
                (
                    f"YOLOv5nu NMS detections for {image.name} "
                    f"score_threshold={NMS_SCORE_THRESHOLD:.2f} "
                    f"iou_threshold={NMS_IOU_THRESHOLD:.2f}"
                ),
                *nms_lines,
            ]
            output = REFERENCE_DIR / f"image{image_id}.txt"
            output.write_text("\n".join(lines) + "\n")
            print(f"Wrote {output}")

    reference_manifest = {
        "format": "yolov5nu-stage0-reference-v1",
        "model": artifact_record(MODEL),
        "graph_manifest": artifact_record(MANIFEST),
        "nms_score_threshold": NMS_SCORE_THRESHOLD,
        "nms_iou_threshold": NMS_IOU_THRESHOLD,
        "images": results,
    }
    output = REFERENCE_DIR / "reference.json"
    output.write_text(json.dumps(reference_manifest, indent=2) + "\n")
    print(f"Wrote {output}")


def validate_convs(python: Path) -> None:
    require_inputs()
    ensure_manifest(python)
    CONV_LOG_DIR.mkdir(parents=True, exist_ok=True)
    summary: list[dict[str, Any]] = []
    for image_id in IMAGE_IDS:
        command = [
            str(python),
            str(CONV_VALIDATOR),
            "--model",
            str(MODEL),
            "--manifest",
            str(MANIFEST),
            "--image",
            str(image_path(image_id)),
        ]
        print("+", " ".join(command), flush=True)
        completed = subprocess.run(
            command,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        print(completed.stdout, end="")
        output = CONV_LOG_DIR / f"image{image_id}.txt"
        output.write_text(completed.stdout)
        summary.append({
            "image_id": image_id,
            "returncode": completed.returncode,
            "log": str(output.relative_to(ROOT)),
            "sha256": sha256(output),
        })
        if completed.returncode:
            raise subprocess.CalledProcessError(completed.returncode, command, completed.stdout)
    output = CONV_LOG_DIR / "summary.json"
    output.write_text(json.dumps({"images": summary}, indent=2) + "\n")
    print(f"Wrote {output}")


def parse_uart_runs(text: str) -> list[dict[str, Any]]:
    marker = "YOLOv5nu Gemmini baremetal image decode test"
    chunks = text.split(marker)[1:]
    runs: list[dict[str, Any]] = []
    for chunk in chunks:
        body = marker + chunk
        image_match = re.search(r"image: (\d{12}\.jpg)", body)
        if not image_match:
            continue
        image = image_match.group(1)
        tensor_lines = re.findall(
            r"^YOLOv5nu (?:class logits|class sigmoid|DFL distances) elems=.*$",
            body,
            flags=re.MULTILINE,
        )
        top_match = re.search(
            r"YOLOv5nu top detections.*?\n(?P<lines>(?:#\d+ .*\n){10})",
            body,
        )
        nms_match = re.search(
            r"YOLOv5nu NMS detections.*?\n(?P<lines>(?:#\d+ .*\n){0,10})",
            body,
        )
        records_match = re.search(r"YOLOV5NU_PROFILE records=(\d+)", body)
        cycle_match = re.search(
            r"YOLOV5NU_PROFILE records=\d+ graph_cycles=(\d+) "
            r"decode_cycles=(\d+) nms_cycles=(\d+)",
            body,
        )
        conv_match = re.search(
            r"YOLOV5NU_PROFILE conv_cycles=(\d+) cpu_operator_cycles=(\d+) "
            r"conv_layout_cycles=(\d+) gemmini_conv_cycles=(\d+)",
            body,
        )
        operator_match = re.search(
            r"YOLOV5NU_PROFILE maxpool_cycles=(\d+) resize_cycles=(\d+) "
            r"concat_cycles=(\d+) sigmoid_cycles=(\d+)",
            body,
        )
        fused_match = re.search(
            r"YOLOV5NU_PROFILE silu_fused_cycles=(\d+) mul_cycles=(\d+) "
            r"add_cycles=(\d+)",
            body,
        )
        head_match = re.search(
            r"YOLOV5NU_PROFILE head_class_cycles=(\d+) head_dfl_cycles=(\d+)",
            body,
        )
        runs.append({
            "image": image,
            "tensor_lines": tensor_lines,
            "top_lines": top_match.group("lines").splitlines() if top_match else [],
            "nms_lines": nms_match.group("lines").splitlines() if nms_match else [],
            "profile_records": int(records_match.group(1)) if records_match else None,
            "cycles": {
                "graph": int(cycle_match.group(1)),
                "decode": int(cycle_match.group(2)),
                "nms": int(cycle_match.group(3)),
                "conv": int(conv_match.group(1)),
                "cpu_operator": int(conv_match.group(2)),
                "conv_layout": int(conv_match.group(3)),
                "gemmini_conv": int(conv_match.group(4)),
                "maxpool": int(operator_match.group(1)),
                "resize": int(operator_match.group(2)),
                "concat": int(operator_match.group(3)),
                "sigmoid": int(operator_match.group(4)),
                "silu_fused": int(fused_match.group(1)) if fused_match else 0,
                "mul": int(fused_match.group(2)) if fused_match else 0,
                "add": int(fused_match.group(3)) if fused_match else 0,
                "head_class": int(head_match.group(1)) if head_match else 0,
                "head_dfl": int(head_match.group(2)) if head_match else 0,
            } if cycle_match and conv_match and operator_match else None,
            "pass": bool(re.search(r"^PASS$", body, flags=re.MULTILINE)),
            "exit_zero": "[baremetal exit 0x0000000000000000]" in body,
        })
    return runs


def check_uart(logs: list[Path], require_ort_match: bool) -> None:
    if not logs:
        raise ValueError("check-uart requires at least one --uart-log")
    reference_path = REFERENCE_DIR / "reference.json"
    if not reference_path.is_file():
        raise FileNotFoundError(f"run the reference command first: {reference_path}")
    expected_data = json.loads(reference_path.read_text())
    expected = {item["image"]: item for item in expected_data["images"]}
    grouped: dict[str, list[dict[str, Any]]] = {}
    reference_differences: list[str] = []
    log_records = [artifact_record(log.resolve()) for log in logs]
    for log in logs:
        for result in parse_uart_runs(log.read_text(errors="replace")):
            grouped.setdefault(result["image"], []).append(result)

    failures: list[str] = []
    for image_id in IMAGE_IDS:
        image = image_path(image_id).name
        runs = grouped.get(image, [])
        if len(runs) < 2:
            failures.append(f"{image}: expected at least two runs, found {len(runs)}")
            continue
        signatures = []
        for index, result in enumerate(runs):
            if not result["pass"] or not result["exit_zero"]:
                failures.append(f"{image} run {index}: missing PASS or zero exit")
            if result["profile_records"] != EXPECTED_PROFILE_RECORDS:
                failures.append(
                    f"{image} run {index}: profile records={result['profile_records']}, "
                    f"expected {EXPECTED_PROFILE_RECORDS}"
                )
            signature = {
                "tensor_lines": result["tensor_lines"],
                "top_lines": result["top_lines"],
                "nms_lines": result["nms_lines"],
            }
            signatures.append(signature)
            expected_signature = {
                "tensor_lines": expected[image]["tensor_lines"],
                "top_lines": expected[image]["top_lines"],
                "nms_lines": expected[image]["nms_lines"],
            }
            if signature != expected_signature:
                difference = f"{image} run {index}: output differs from ORT reference"
                if require_ort_match:
                    failures.append(difference)
                else:
                    reference_differences.append(difference)
        if any(signature != signatures[0] for signature in signatures[1:]):
            failures.append(f"{image}: repeated FPGA runs are not deterministic")
        print(f"{image}: checked {len(runs)} runs")

    if failures:
        raise SystemExit("Stage 0 UART check failed:\n- " + "\n- ".join(failures))
    report_images = []
    for image_id in IMAGE_IDS:
        image = image_path(image_id).name
        runs = grouped[image]
        graph_cycles = [result["cycles"]["graph"] for result in runs if result["cycles"]]
        report_images.append({
            "image_id": image_id,
            "image": image,
            "runs": runs,
            "deterministic": True,
            "ort_bit_exact": not any(
                difference.startswith(image) for difference in reference_differences
            ),
            "graph_cycles_average": sum(graph_cycles) / len(graph_cycles),
            "graph_cycles_spread_percent": (
                (max(graph_cycles) - min(graph_cycles))
                / (sum(graph_cycles) / len(graph_cycles)) * 100.0
            ),
        })
    report = {
        "format": "yolov5nu-stage0-uart-validation-v1",
        "validated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "clock_hz": 50_000_000,
        "expected_profile_records": EXPECTED_PROFILE_RECORDS,
        "logs": log_records,
        "images": report_images,
        "ort_comparison_notes": reference_differences,
    }
    output = STAGE0_DIR / "uart_validation.json"
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Wrote {output}")
    if reference_differences:
        print("ORT comparison notes:")
        for difference in reference_differences:
            print(f"- {difference}")
    print("PASS: five-image Stage 0 UART baseline is deterministic")


def main() -> None:
    options = parse_args()
    python = options.python.resolve()
    if options.command in {"build", "all"}:
        build_baselines(python)
    if options.command == "manifest":
        write_build_manifest(python, collect_existing_artifacts())
    if options.command in {"reference", "all"}:
        generate_references(python)
    if options.command in {"validate-convs", "all"}:
        validate_convs(python)
    if options.command == "check-uart":
        check_uart(options.uart_log, options.require_ort_match)


if __name__ == "__main__":
    main()
