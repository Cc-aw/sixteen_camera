#!/usr/bin/env python3
"""Build the first YOLOv5nu Stage 8A shared-scale quantization candidate.

Stage 8A changes one residual feature-map Add at a time.  The two quantized
feature tensors consumed by that Add are assigned one common per-tensor
activation scale.  The Add output scale remains unchanged in this first
candidate so that only the resadd input contract is being tested.

The script keeps the original QDQ model untouched and emits:

* an independent QDQ ONNX model;
* a graph manifest parsed from that exact ONNX file;
* QDQ/Conv-requant audit JSON;
* ORT intermediate/output references for the five board images; and
* an independent baremetal parameter/source pair containing regenerated
  dynamic SiLU LUTs.

This is a software/model preparation step.  It does not modify RTL, Scala,
Chisel, or the existing Stage 7E artifacts.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import onnx
import onnxruntime as ort
from onnx import helper, numpy_helper
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
DEFAULT_MODEL = MODEL_DIR / "yolov5nu-gemmini-int8-img320.onnx"
DEFAULT_OUTPUT_DIR = MODEL_DIR / "stage8a_shared_scale"
IMAGE_DIR = MODEL_DIR / "calibration/coco128/images/train2017"
DEFAULT_IMAGE_IDS = ("025", "036", "142", "404", "650")
FEATURE_ADD_NAMES = (
    "/model.2/m/m.0/Add",
    "/model.4/m/m.0/Add",
    "/model.4/m/m.1/Add",
    "/model.6/m/m.0/Add",
    "/model.6/m/m.1/Add",
    "/model.6/m/m.2/Add",
    "/model.8/m/m.0/Add",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument(
        "--add-name",
        default=FEATURE_ADD_NAMES[0],
        choices=FEATURE_ADD_NAMES,
        help="one feature-map Add to change in this candidate",
    )
    scale = parser.add_mutually_exclusive_group()
    scale.add_argument(
        "--shared-scale-policy",
        choices=("max", "min", "add-output"),
        default="max",
        help="derive the shared input scale from the selected Add group",
    )
    scale.add_argument(
        "--shared-scale-value",
        type=float,
        help="explicit positive shared input scale",
    )
    parser.add_argument(
        "--calibration-data",
        type=Path,
        default=IMAGE_DIR,
        help="directory of images used for range/saturation audit",
    )
    parser.add_argument("--calibration-samples", type=int, default=128)
    parser.add_argument(
        "--reference-image",
        type=Path,
        action="append",
        help="ORT reference image; repeat for multiple images (defaults to 025,036,142,404,650)",
    )
    parser.add_argument(
        "--skip-aot",
        action="store_true",
        help="skip the baremetal generator; useful when only the ONNX candidate is needed",
    )
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def artifact(path: Path) -> dict[str, Any]:
    return {
        "path": str(path.resolve()),
        "size": path.stat().st_size,
        "sha256": sha256(path),
    }


def scalar(array: np.ndarray, context: str) -> float:
    if array.size != 1:
        raise ValueError(f"{context} must be scalar, got shape {array.shape}")
    return float(array.reshape(-1)[0])


def set_scalar_initializer(
    initializer: onnx.TensorProto, value: float, context: str
) -> None:
    current = numpy_helper.to_array(initializer)
    if current.size != 1:
        raise ValueError(f"{context} is not scalar: {current.shape}")
    if not np.isfinite(value) or value <= 0.0:
        raise ValueError(f"{context} must be finite and positive, got {value}")
    replacement = np.full(current.shape, value, dtype=current.dtype)
    initializer.CopyFrom(numpy_helper.from_array(replacement, initializer.name))


def letterbox(path: Path, height: int, width: int) -> np.ndarray:
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


def find_images(path: Path, limit: int) -> list[Path]:
    images = sorted(
        item for item in path.rglob("*")
        if item.is_file() and item.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp"}
    )
    if not images:
        raise ValueError(f"no calibration images found in {path}")
    if limit <= 0:
        raise ValueError("--calibration-samples must be positive")
    if len(images) > limit:
        indices = np.linspace(0, len(images) - 1, num=limit, dtype=int)
        images = [images[index] for index in indices]
    return images


def qdq_maps(
    model: onnx.ModelProto,
) -> tuple[dict[str, np.ndarray], dict[str, dict[str, Any]], dict[str, dict[str, Any]]]:
    arrays = {item.name: numpy_helper.to_array(item) for item in model.graph.initializer}
    quantized: dict[str, dict[str, Any]] = {}
    dequantized: dict[str, dict[str, Any]] = {}
    for node in model.graph.node:
        if node.op_type not in {"QuantizeLinear", "DequantizeLinear"}:
            continue
        if len(node.input) < 3 or node.input[1] not in arrays or node.input[2] not in arrays:
            raise ValueError(f"{node.name}: QDQ scale/zero point is not an initializer")
        zero = scalar(arrays[node.input[2]], f"{node.name} zero point")
        if zero != 0:
            raise ValueError(f"{node.name}: expected symmetric zero point 0, got {zero}")
        record = {
            "node": node.name,
            "op": node.op_type,
            "quantized_tensor": (
                node.output[0] if node.op_type == "QuantizeLinear" else node.input[0]
            ),
            "scale_initializer": node.input[1],
            "zero_point_initializer": node.input[2],
            "scale": scalar(arrays[node.input[1]], f"{node.name} scale"),
            "zero_point": int(zero),
            "dtype": str(arrays[node.input[2]].dtype),
        }
        if node.op_type == "QuantizeLinear":
            quantized[node.input[0]] = record
        else:
            dequantized[node.output[0]] = record
    return arrays, quantized, dequantized


def feature_add_groups(model: onnx.ModelProto) -> list[dict[str, Any]]:
    arrays, quantized, dequantized = qdq_maps(model)
    nodes = {node.name: node for node in model.graph.node}
    producers = {output: node for node in model.graph.node for output in node.output if output}
    groups = []
    for add_name in FEATURE_ADD_NAMES:
        if add_name not in nodes or nodes[add_name].op_type != "Add":
            raise ValueError(f"missing feature-map Add: {add_name}")
        node = nodes[add_name]
        inputs = []
        for tensor in node.input:
            dq = dequantized.get(tensor)
            if dq is None:
                raise ValueError(f"{add_name}: input {tensor} is not a QDQ tensor")
            producer = producers.get(dq["node"])
            # The DQ node consumes the Q output; its float input producer is
            # found by following the QuantizeLinear node that owns that output.
            q_node = next(
                (
                    candidate
                    for candidate in model.graph.node
                    if candidate.op_type == "QuantizeLinear"
                    and candidate.output[0] == dq["quantized_tensor"]
                ),
                None,
            )
            if q_node is None:
                raise ValueError(f"{add_name}: cannot find Q node for {tensor}")
            float_producer = producers.get(q_node.input[0])
            if float_producer is None:
                raise ValueError(f"{add_name}: cannot find producer for {q_node.input[0]}")
            inputs.append({
                "dequantize_node": dq["node"],
                "q_node": q_node.name,
                "q_tensor": dq["quantized_tensor"],
                "scale_initializer": dq["scale_initializer"],
                "scale": float(dq["scale"]),
                "zero_point_initializer": dq["zero_point_initializer"],
                "float_tensor": q_node.input[0],
                "producer_op": float_producer.op_type,
                "producer_name": float_producer.name,
            })
        output = node.output[0]
        output_q = quantized.get(output)
        if output_q is None:
            raise ValueError(f"{add_name}: missing output QuantizeLinear")
        groups.append({
            "add_name": add_name,
            "inputs": inputs,
            "output": {
                "float_tensor": output,
                "q_tensor": output_q["quantized_tensor"],
                "scale_initializer": output_q["scale_initializer"],
                "scale": float(output_q["scale"]),
                "zero_point_initializer": output_q["zero_point_initializer"],
            },
        })
    return groups


def update_graph(
    source: onnx.ModelProto,
    group: dict[str, Any],
    shared_scale: float,
) -> tuple[onnx.ModelProto, list[dict[str, Any]]]:
    candidate = copy.deepcopy(source)
    source_arrays = {
        item.name: numpy_helper.to_array(item) for item in source.graph.initializer
    }
    initializers = {item.name: item for item in candidate.graph.initializer}
    source_nodes = list(source.graph.node)
    candidate_nodes = {node.name: node for node in candidate.graph.node}
    changed = []
    for item in group["inputs"]:
        initializer = initializers[item["scale_initializer"]]
        before = scalar(numpy_helper.to_array(initializer), initializer.name)
        set_scalar_initializer(initializer, shared_scale, initializer.name)
        # Q and DQ intentionally share this initializer in the source model;
        # audit all nodes to make the invariant explicit.
        users = [
            node.name
            for node in candidate.graph.node
            if len(node.input) > 1 and node.input[1] == initializer.name
        ]
        changed.append({
            "initializer": initializer.name,
            "before": before,
            "after": shared_scale,
            "users": users,
            "q_tensor": item["q_tensor"],
            "float_tensor": item["float_tensor"],
            "producer_name": item["producer_name"],
        })

    # A Conv bias is quantized using input_scale * weight_scale.  Changing a
    # feature-map QDQ scale therefore requires regenerating the downstream
    # Conv's Int32 bias QDQ pair; otherwise the graph's float Conv and the
    # integer Gemmini reference disagree (usually by a large amount).
    changed_q_tensors = {item["q_tensor"]: item for item in changed}
    source_q_nodes = {
        node.output[0]: node for node in source_nodes
        if node.op_type == "QuantizeLinear" and node.output
    }
    source_dq_nodes = {
        node.output[0]: node for node in source_nodes
        if node.op_type == "DequantizeLinear" and node.output
    }
    for q_tensor, item in changed_q_tensors.items():
        q_node = source_q_nodes.get(q_tensor)
        if q_node is None:
            raise ValueError(f"{q_tensor}: missing QuantizeLinear node")
        dq_node = next(
            (node for node in source_nodes
             if node.op_type == "DequantizeLinear" and node.input[0] == q_tensor),
            None,
        )
        if dq_node is None:
            raise ValueError(f"{q_tensor}: missing DequantizeLinear node")
        consumer_convs = [
            node for node in source_nodes
            if node.op_type == "Conv" and dq_node.output[0] in node.input
        ]
        for conv in consumer_convs:
            if len(conv.input) < 3:
                raise ValueError(f"{conv.name}: changed input requires a bias")
            bias_dq = source_dq_nodes.get(conv.input[2])
            if bias_dq is None:
                raise ValueError(f"{conv.name}: cannot find bias DequantizeLinear")
            bias_q_tensor = bias_dq.input[0]
            # ONNX Runtime emits Conv bias as a direct Int32 initializer into
            # DequantizeLinear, unlike activation QDQ tensors which have an
            # explicit QuantizeLinear node.
            bias_initializer_name = bias_q_tensor
            if bias_initializer_name not in source_arrays:
                raise ValueError(f"{conv.name}: bias initializer is missing")

            weight_dq = source_dq_nodes.get(conv.input[1])
            if weight_dq is None:
                raise ValueError(f"{conv.name}: cannot find weight DequantizeLinear")
            weight_scale = scalar(
                source_arrays[weight_dq.input[1]], weight_dq.name + " scale"
            )
            old_bias_scale = scalar(
                source_arrays[bias_dq.input[1]], bias_dq.name + " scale"
            )
            old_bias_q = source_arrays[bias_initializer_name]
            bias_real = old_bias_q.astype(np.float32) * np.float32(old_bias_scale)
            new_bias_scale = float(item["after"]) * weight_scale
            new_bias_q = np.rint(bias_real / np.float32(new_bias_scale))
            new_bias_q = np.clip(new_bias_q, -2147483648, 2147483647).astype(old_bias_q.dtype)

            candidate_bias_initializer = initializers[bias_initializer_name]
            candidate_bias_initializer.CopyFrom(
                numpy_helper.from_array(new_bias_q, bias_initializer_name)
            )
            candidate_bias_scale = initializers[bias_dq.input[1]]
            set_scalar_initializer(
                candidate_bias_scale, new_bias_scale, bias_dq.input[1] + " scale"
            )
            candidate_conv = candidate_nodes[conv.name]
            if list(candidate_conv.input) != list(conv.input):
                raise ValueError(f"unexpected graph mutation at {conv.name}")

            changed.append({
                "initializer": bias_initializer_name,
                "before_dtype": str(old_bias_q.dtype),
                "after_dtype": str(new_bias_q.dtype),
                "before_checksum": int(old_bias_q.astype(np.int64).sum()),
                "after_checksum": int(new_bias_q.astype(np.int64).sum()),
                "q_tensor": bias_q_tensor,
                "producer_name": conv.name,
                "kind": "consumer_conv_bias_quantized",
            })
            changed.append({
                "initializer": bias_dq.input[1],
                "before": old_bias_scale,
                "after": new_bias_scale,
                "users": [
                    node.name for node in candidate.graph.node
                    if len(node.input) > 1 and node.input[1] == bias_dq.input[1]
                ],
                "q_tensor": bias_q_tensor,
                "producer_name": conv.name,
                "kind": "consumer_conv_bias_scale",
            })
    onnx.checker.check_model(candidate)
    return candidate, changed


def add_debug_outputs(model: onnx.ModelProto, names: list[str]) -> onnx.ModelProto:
    result = copy.deepcopy(model)
    existing = {value.name for value in result.graph.output}
    known = {
        output: node
        for node in result.graph.node
        for output in node.output
        if output
    }
    for name in names:
        if name in existing:
            continue
        node = known.get(name)
        if node is None:
            raise ValueError(f"cannot add unknown graph output {name}")
        elem_type = onnx.TensorProto.INT8
        if node.op_type == "QuantizeLinear":
            elem_type = onnx.TensorProto.INT8
        result.graph.output.append(helper.make_tensor_value_info(name, elem_type, None))
    return result


def tensor_summary(values: np.ndarray) -> dict[str, Any]:
    flat = values.reshape(-1)
    numeric = flat.astype(np.float64, copy=False)
    result: dict[str, Any] = {
        "elems": int(flat.size),
        "dtype": str(values.dtype),
        "min": float(numeric.min()),
        "max": float(numeric.max()),
        "mean": float(numeric.mean()),
        "checksum": int(flat.astype(np.int64).sum()) if np.issubdtype(values.dtype, np.integer) else None,
    }
    if np.issubdtype(values.dtype, np.integer):
        result["saturated"] = int(np.count_nonzero((flat == 127) | (flat == -128)))
    return result


def run_reference(
    base: onnx.ModelProto,
    candidate: onnx.ModelProto,
    group: dict[str, Any],
    images: list[Path],
    output_dir: Path,
) -> dict[str, Any]:
    debug_names = [item["q_tensor"] for item in group["inputs"]]
    debug_names.append(group["output"]["q_tensor"])
    base_debug = add_debug_outputs(base, debug_names)
    candidate_debug = add_debug_outputs(candidate, debug_names)
    base_path = output_dir / "_ort_base_debug.onnx"
    candidate_path = output_dir / "_ort_candidate_debug.onnx"
    onnx.save(base_debug, base_path)
    onnx.save(candidate_debug, candidate_path)
    base_session = ort.InferenceSession(str(base_path), providers=["CPUExecutionProvider"])
    candidate_session = ort.InferenceSession(str(candidate_path), providers=["CPUExecutionProvider"])
    base_names = [item.name for item in base_session.get_outputs()]
    candidate_names = [item.name for item in candidate_session.get_outputs()]
    npz_values: dict[str, np.ndarray] = {}
    records = []
    for image in images:
        input_name = base_session.get_inputs()[0].name
        data = {input_name: letterbox(image, 320, 320)}
        base_outputs = dict(zip(base_names, base_session.run(None, data)))
        candidate_outputs = dict(zip(candidate_names, candidate_session.run(None, data)))
        base_final = base_outputs["output0"]
        candidate_final = candidate_outputs["output0"]
        delta = np.abs(candidate_final.astype(np.float64) - base_final.astype(np.float64))
        image_key = image.stem
        for name in debug_names + ["output0"]:
            safe = image_key + "__" + name.replace("/", "_").replace(":", "_")
            npz_values[safe] = candidate_outputs[name]
        records.append({
            "image": str(image.resolve()),
            "base_output": tensor_summary(base_final),
            "candidate_output": tensor_summary(candidate_final),
            "candidate_vs_base": {
                "max_abs_diff": float(delta.max()),
                "mean_abs_diff": float(delta.mean()),
                "changed_elements": int(np.count_nonzero(delta)),
            },
            "intermediates": {
                name: {
                    "base": tensor_summary(base_outputs[name]),
                    "candidate": tensor_summary(candidate_outputs[name]),
                    "changed_elements": int(
                        np.count_nonzero(base_outputs[name] != candidate_outputs[name])
                    ),
                }
                for name in debug_names
            },
        })
    np.savez_compressed(output_dir / "ort_reference.npz", **npz_values)
    base_path.unlink()
    candidate_path.unlink()
    return {
        "format": "yolov5nu-stage8a-ort-reference-v1",
        "images": records,
        "npz": str((output_dir / "ort_reference.npz").resolve()),
    }


def calibration_audit(
    model: onnx.ModelProto,
    group: dict[str, Any],
    images: list[Path],
) -> dict[str, Any]:
    names = [item["q_tensor"] for item in group["inputs"]] + [group["output"]["q_tensor"]]
    debug = add_debug_outputs(model, names)
    path = MODEL_DIR / ".stage8a_calibration_debug.onnx"
    onnx.save(debug, path)
    try:
        session = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
        output_names = [item.name for item in session.get_outputs()]
        ranges = {name: [] for name in names}
        for image in images:
            values = dict(zip(output_names, session.run(None, {"images": letterbox(image, 320, 320)})))
            for name in names:
                ranges[name].append(values[name])
        result = {}
        for name, values in ranges.items():
            merged = np.concatenate([value.reshape(-1) for value in values])
            result[name] = {
                "elems": int(merged.size),
                "min": int(merged.min()),
                "max": int(merged.max()),
                "saturated": int(np.count_nonzero((merged == 127) | (merged == -128))),
                "images": len(values),
            }
        return result
    finally:
        path.unlink(missing_ok=True)


def conv_requant_audit(
    model: onnx.ModelProto,
    changed: list[dict[str, Any]],
    old_group: dict[str, Any],
    shared_scale: float,
) -> list[dict[str, Any]]:
    arrays, _, dequantized = qdq_maps(model)
    nodes = {node.name: node for node in model.graph.node}
    records = []
    for item, old_item in zip(
        [item for item in changed if item.get("kind") is None], old_group["inputs"]
    ):
        producer = nodes[item["producer_name"]]
        if producer.op_type != "Mul":
            raise ValueError(f"{producer.name}: expected SiLU Mul producer, got {producer.op_type}")
        conv_input = producer.input[0]
        conv_dq = next(
            (record for tensor, record in dequantized.items() if tensor == conv_input), None
        )
        if conv_dq is None:
            raise ValueError(f"{producer.name}: cannot find Conv input quantization")
        conv_q_tensor = conv_dq["quantized_tensor"]
        conv_q_node = next(
            node for node in model.graph.node
            if node.op_type == "QuantizeLinear" and node.output[0] == conv_q_tensor
        )
        conv_node = next(
            node for node in model.graph.node
            if node.op_type == "Conv" and node.output[0] == conv_q_node.input[0]
        )
        weight_dq = next(
            node for node in model.graph.node
            if node.op_type == "DequantizeLinear" and node.output[0] == conv_node.input[1]
        )
        weight_scale = scalar(arrays[weight_dq.input[1]], weight_dq.name + " scale")
        input_scale = float(conv_dq["scale"])
        old_output_scale = float(old_item["scale"])
        records.append({
            "kind": "fused_silu_output",
            "mul_name": producer.name,
            "conv_name": conv_node.name,
            "conv_input_scale": input_scale,
            "weight_scale": weight_scale,
            "old_silu_output_scale": old_output_scale,
            "new_silu_output_scale": shared_scale,
            "old_fused_conv_requant": input_scale * weight_scale / old_output_scale,
            "new_fused_conv_requant": input_scale * weight_scale / shared_scale,
        })

        # The changed SiLU output is also the input to a later Conv in some
        # residual blocks.  Its bias was regenerated above, while this record
        # exposes the new output requant factor used by the AOT generator.
        q_node = next(
            node for node in model.graph.node
            if node.op_type == "QuantizeLinear" and node.output[0] == item["q_tensor"]
        )
        dq_output = next(
            node.output[0] for node in model.graph.node
            if node.op_type == "DequantizeLinear" and node.input[0] == item["q_tensor"]
        )
        consumer = next(
            (node for node in model.graph.node
             if node.op_type == "Conv" and dq_output in node.input),
            None,
        )
        if consumer is not None:
            consumer_output_q = next(
                node for node in model.graph.node
                if node.op_type == "QuantizeLinear" and node.input[0] == consumer.output[0]
            )
            consumer_output_scale = scalar(
                arrays[consumer_output_q.input[1]], consumer_output_q.name + " scale"
            )
            consumer_weight_dq = next(
                node for node in model.graph.node
                if node.op_type == "DequantizeLinear" and node.output[0] == consumer.input[1]
            )
            consumer_weight_scale = scalar(
                arrays[consumer_weight_dq.input[1]], consumer_weight_dq.name + " scale"
            )
            records.append({
                "kind": "consumer_conv_output",
                "conv_name": consumer.name,
                "input_scale_before": old_item["scale"],
                "input_scale_after": shared_scale,
                "weight_scale": consumer_weight_scale,
                "output_scale": consumer_output_scale,
                "old_conv_requant": old_item["scale"] * consumer_weight_scale / consumer_output_scale,
                "new_conv_requant": shared_scale * consumer_weight_scale / consumer_output_scale,
            })
    return records


def run_graph_parser(python: Path, model: Path, manifest: Path) -> None:
    subprocess.run(
        [str(python), str(ROOT / "scripts/yolov5nu_graph_parser.py"),
         "--model", str(model), "--output", str(manifest)],
        cwd=ROOT,
        check=True,
    )


def run_aot_generator(
    python: Path,
    model: Path,
    manifest: Path,
    image: Path,
    output_dir: Path,
    stem: str,
) -> None:
    generator = ROOT / "generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py"
    command = [
        str(python), str(generator),
        "--model", str(model),
        "--manifest", str(manifest),
        "--image", str(image),
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
        "--memory-stage", "5d",
    ]
    subprocess.run(command, cwd=ROOT, check=True)


def run_command_log(command: list[str], output: Path) -> dict[str, Any]:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    output.write_text(completed.stdout)
    if completed.returncode != 0:
        raise RuntimeError(
            f"validation failed with exit {completed.returncode}; see {output}"
        )
    return {
        "command": command,
        "log": artifact(output),
        "exit_code": completed.returncode,
    }


def main() -> None:
    args = parse_args()
    source_path = args.model.resolve()
    if not source_path.is_file():
        raise FileNotFoundError(source_path)
    if args.shared_scale_value is not None and args.shared_scale_value <= 0.0:
        raise ValueError("--shared-scale-value must be positive")
    calibration_images = find_images(args.calibration_data.resolve(), args.calibration_samples)
    reference_images = [
        path.resolve() for path in (args.reference_image or [
            IMAGE_DIR / f"000000000{image_id}.jpg" for image_id in DEFAULT_IMAGE_IDS
        ])
    ]
    for path in reference_images:
        if not path.is_file():
            raise FileNotFoundError(path)

    base = onnx.load(source_path, load_external_data=True)
    onnx.checker.check_model(base)
    groups = feature_add_groups(base)
    selected = next(group for group in groups if group["add_name"] == args.add_name)
    old_scales = [item["scale"] for item in selected["inputs"]]
    if args.shared_scale_value is not None:
        shared_scale = float(args.shared_scale_value)
        policy = "explicit"
    elif args.shared_scale_policy == "max":
        shared_scale = max(old_scales)
        policy = "max"
    elif args.shared_scale_policy == "min":
        shared_scale = min(old_scales)
        policy = "min"
    else:
        shared_scale = float(selected["output"]["scale"])
        policy = "add-output"

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    model_path = output_dir / "yolov5nu-stage8a-shared-scale.onnx"
    manifest_path = output_dir / "yolov5nu-stage8a-shared-scale.graph.json"
    audit_path = output_dir / "yolov5nu-stage8a-shared-scale.audit.json"
    constants_path = output_dir / "yolov5nu-stage8a-shared-scale.qdq-constants.json"
    reference_json_path = output_dir / "ort_reference.json"

    candidate, changed = update_graph(base, selected, shared_scale)
    onnx.save(candidate, model_path)
    onnx.checker.check_model(candidate)
    run_graph_parser(args.python.resolve(), model_path, manifest_path)

    calibration = calibration_audit(candidate, selected, calibration_images)
    requant = conv_requant_audit(base, changed, selected, shared_scale)
    reference = run_reference(base, candidate, selected, reference_images, output_dir)
    reference_json_path.write_text(json.dumps(reference, indent=2) + "\n")

    constants = {
        "format": "yolov5nu-stage8a-qdq-constants-v1",
        "source_model": artifact(source_path),
        "candidate_model": artifact(model_path),
        "add_name": args.add_name,
        "shared_scale_policy": policy,
        "shared_scale": shared_scale,
        "input_scales_before": old_scales,
        "add_output_scale_unchanged": selected["output"]["scale"],
        "changed_initializers": changed,
        "feature_add_groups": groups,
        "zero_point_contract": 0,
        "activation_quantization": "per-tensor symmetric int8",
        "weight_quantization": "per-tensor symmetric int8",
    }
    constants_path.write_text(json.dumps(constants, indent=2) + "\n")

    aot = None
    validations = []
    if not args.skip_aot:
        aot_dir = output_dir / "aot"
        aot_dir.mkdir(parents=True, exist_ok=True)
        stem = "yolov5nu-stage8a-shared-scale-image025-profile"
        run_aot_generator(
            args.python.resolve(), model_path, manifest_path,
            reference_images[0], aot_dir, stem,
        )
        aot = {
            "directory": str(aot_dir.resolve()),
            "source": artifact(aot_dir / f"{stem}.c"),
            "parameters": artifact(aot_dir / f"{stem}_params.h"),
            "memory_plan": artifact(aot_dir / f"{stem}_memory.json"),
            "dynamic_silu_lut_entries": 69,
            "kernel": "gemmini-lut",
        }
        validations.append(run_command_log([
            str(args.python.resolve()),
            str(ROOT / "scripts/yolov5nu_validate_baremetal_reference.py"),
            "--model", str(model_path),
            "--manifest", str(manifest_path),
            "--image", str(reference_images[0]),
        ], output_dir / "conv_qdq_validation.log"))
        validations.append(run_command_log([
            str(args.python.resolve()),
            str(ROOT / "scripts/yolov5nu_validate_silu_fusion.py"),
            "--manifest", str(manifest_path),
            "--source", str(aot_dir / f"{stem}.c"),
            "--parameters", str(aot_dir / f"{stem}_params.h"),
        ], output_dir / "silu_lut_validation.log"))

    audit = {
        "format": "yolov5nu-stage8a-shared-scale-audit-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "status": "pass",
        "stage": "8A",
        "description": "One residual Add input scale group changed; Add output scale retained",
        "source_model": artifact(source_path),
        "candidate_model": artifact(model_path),
        "manifest": artifact(manifest_path),
        "add_name": args.add_name,
        "shared_scale_policy": policy,
        "shared_scale": shared_scale,
        "input_scales_before": old_scales,
        "input_scales_after": [shared_scale, shared_scale],
        "add_output_scale": selected["output"]["scale"],
        "changed_initializers": changed,
        "conv_output_requant": requant,
        "calibration_images": [str(path.resolve()) for path in calibration_images],
        "calibration_range_audit": calibration,
        "ort_reference": {
            "json": str(reference_json_path.resolve()),
            "npz": reference["npz"],
            "images": [str(path.resolve()) for path in reference_images],
        },
        "aot": aot,
        "validations": validations,
        "note": (
            "This candidate is expected to differ from Stage 7E/H4A. "
            "Bit-exactness is defined against this candidate ONNX model, not the old model."
        ),
    }
    audit_path.write_text(json.dumps(audit, indent=2) + "\n")

    print(f"Stage 8A Add: {args.add_name}")
    print(f"Input scales: {old_scales} -> [{shared_scale}, {shared_scale}]")
    print(f"Add output scale retained: {selected['output']['scale']}")
    print(f"Wrote candidate: {model_path}")
    print(f"Wrote manifest: {manifest_path}")
    print(f"Wrote QDQ audit: {constants_path}")
    print(f"Wrote ORT reference: {reference_json_path}")
    print(f"Wrote audit: {audit_path}")
    if aot:
        print(f"Wrote AOT artifacts: {aot['directory']}")
        for validation in validations:
            print(f"PASS: {validation['log']['path']}")
    print("Feature Add groups:")
    for item in groups:
        values = ", ".join(f"{value:.10g}" for value in [x["scale"] for x in item["inputs"]])
        marker = " <-- selected" if item["add_name"] == args.add_name else ""
        print(f"  {item['add_name']}: [{values}] -> {item['output']['scale']:.10g}{marker}")


if __name__ == "__main__":
    main()
