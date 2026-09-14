#!/usr/bin/env python3
"""Build a fully recalibrated Gemmini-aware YOLOv5nu Stage 8 reference.

The existing Stage 8 ORT graph reference is intentionally left untouched.
This script creates a fresh symmetric per-tensor QDQ model from yolov5nu.pt,
applies the seven shared-scale residual groups, and evaluates the quantized
graph with Gemmini's integer Conv/Add/requant semantics.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import numpy as np
import onnx
from onnx import numpy_helper

import yolov5nu_stage0_baseline as stage0
import yolov5nu_stage8a_shared_scale as stage8a


ROOT = stage0.ROOT
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
CALIBRATION = MODEL_DIR / "calibration/coco128/images/train2017"
WEIGHTS = MODEL_DIR / "yolov5nu.pt"
OUTPUT_DIR = MODEL_DIR / "stage8_hardware_aware"
FP32_MODEL = OUTPUT_DIR / "yolov5nu-fp32-img320x320.onnx"
FRESH_MODEL = OUTPUT_DIR / "yolov5nu-hw-aware-full-int8-img320.onnx"
MODEL = OUTPUT_DIR / "yolov5nu-hw-aware-shared-scale-int8-img320.onnx"
MANIFEST = OUTPUT_DIR / "yolov5nu-hw-aware-shared-scale.graph.json"
QUANT_REPORT = OUTPUT_DIR / "yolov5nu-hw-aware-full-int8-img320.quant.json"
AUDIT = OUTPUT_DIR / "hardware_aware_quantization_audit.json"
REFERENCE = OUTPUT_DIR / "hardware_integer_reference.json"
SILU_LUTS = OUTPUT_DIR / "hardware_silu_luts.json"
IMAGE_IDS = ("025", "036", "142", "404", "650")
FEATURE_ADDS = tuple(stage8a.FEATURE_ADD_NAMES)
WIDTH = 320
HEIGHT = 320


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("quantize", "model", "reference", "all"), default="all", nargs="?")
    parser.add_argument("--python", type=Path, default=Path(sys.executable))
    parser.add_argument("--calibration-samples", type=int, default=128)
    parser.add_argument("--width", type=int, default=320)
    parser.add_argument("--height", type=int, default=320)
    parser.add_argument(
        "--output-dir", type=Path, default=OUTPUT_DIR,
        help="independent output directory for the model and references",
    )
    return parser.parse_args()


def run_quantization(python: Path, samples: int) -> None:
    from subprocess import run

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    run([
        str(python), str(MODEL_DIR / "export_yolov5nu_gemmini_int8.py"),
        "--weights", str(WEIGHTS), "--calibration-data", str(CALIBRATION),
        "--calibration-samples", str(samples), "--width", str(WIDTH), "--height", str(HEIGHT),
        "--calibration-method", "minmax", "--output", str(FRESH_MODEL),
        "--keep-fp32", str(FP32_MODEL), "--force",
        "--report", str(QUANT_REPORT),
    ], cwd=ROOT, check=True)


def artifact(path: Path) -> dict[str, Any]:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    return {"path": str(path.resolve()), "size": path.stat().st_size, "sha256": digest}


def build_shared_model(python: Path) -> None:
    import subprocess

    source = onnx.load(str(FRESH_MODEL), load_external_data=True)
    candidate = source
    changes: list[dict[str, Any]] = []
    applied: list[dict[str, Any]] = []
    for add_name in FEATURE_ADDS:
        group = next(item for item in stage8a.feature_add_groups(candidate) if item["add_name"] == add_name)
        shared = max(float(item["scale"]) for item in group["inputs"])
        candidate, current = stage8a.update_graph(candidate, group, shared)
        changes.extend(current)
        updated = next(item for item in stage8a.feature_add_groups(candidate) if item["add_name"] == add_name)
        applied.append({
            "add_name": add_name,
            "input_scales_before": [float(x["scale"]) for x in group["inputs"]],
            "shared_scale": shared,
            "output_scale": float(updated["output"]["scale"]),
        })
    onnx.checker.check_model(candidate)
    onnx.save(candidate, str(MODEL))
    subprocess.run([
        str(python), str(ROOT / "scripts/yolov5nu_graph_parser.py"),
        "--model", str(MODEL), "--output", str(MANIFEST),
    ], cwd=ROOT, check=True)
    write_silu_luts(manifest_path=MANIFEST, model=candidate)
    AUDIT.write_text(json.dumps({
        "format": "yolov5nu-stage8-hardware-aware-quantization-audit-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "source_checkpoint": artifact(WEIGHTS),
        "fresh_quantized_model": artifact(FRESH_MODEL),
        "shared_scale_model": artifact(MODEL),
        "manifest": artifact(MANIFEST),
        "dynamic_silu_luts": artifact(SILU_LUTS),
        "calibration_images": [str(x.resolve()) for x in sorted(CALIBRATION.glob("*.jpg"))],
        "calibration_samples": 128,
        "activation": "per-tensor signed QInt8, zero_point=0",
        "weight": "per-tensor signed QInt8, zero_point=0",
        "shared_scale_policy": "topological cumulative max after full recalibration",
        "feature_add_groups": applied,
        "changed_initializers": changes,
    }, indent=2) + "\n")
    print("PASS: fresh full quantization plus seven shared-scale Add groups")
    for item in applied:
        print(item["add_name"], item["shared_scale"], "->", item["output_scale"])


def write_silu_luts(manifest_path: Path, model: onnx.ModelProto) -> None:
    manifest = json.loads(manifest_path.read_text())
    arrays = {x.name: numpy_helper.to_array(x) for x in model.graph.initializer}
    by_name = {op["name"]: op for op in manifest["ops"]}
    luts = []
    signed = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
    for op in manifest["ops"]:
        if op["op"] != "Mul" or not op["name"].endswith("/act/Mul"):
            continue
        base = op["name"].removesuffix("/act/Mul")
        sigmoid = by_name[base + "/act/Sigmoid"]
        input_float = sigmoid["inputs"][0]
        input_scale = float(manifest["tensor_quantization"][input_float]["scale"])
        sigmoid_scale = float(output_record(sigmoid)["scale"])
        output_scale = float(output_record(op)["scale"])
        logits = np.clip(signed * np.float32(input_scale), -80.0, 80.0)
        sigmoid_q = np.clip(
            np.rint((1.0 / (1.0 + np.exp(-logits))) / np.float32(sigmoid_scale)),
            -128, 127,
        ).astype(np.float32)
        lut = np.clip(
            np.rint(
                signed * np.float32(input_scale)
                * sigmoid_q * np.float32(sigmoid_scale)
                / np.float32(output_scale)
            ),
            -128, 127,
        ).astype(np.int8)
        luts.append({
            "mul_name": op["name"],
            "input_scale": input_scale,
            "sigmoid_scale": sigmoid_scale,
            "output_scale": output_scale,
            "entries": [int(x) for x in lut],
        })
    if len(luts) != 69:
        raise ValueError(f"expected 69 dynamic SiLU LUTs, found {len(luts)}")
    SILU_LUTS.write_text(json.dumps({
        "format": "yolov5nu-stage8-hardware-silu-luts-v1",
        "model": artifact(MODEL),
        "entries": luts,
    }, indent=2) + "\n")


def rne(values: np.ndarray) -> np.ndarray:
    return np.rint(values.astype(np.float32, copy=False))


def quantize(values: np.ndarray, scale: float) -> np.ndarray:
    return np.clip(rne(values / np.float32(scale)), -128, 127).astype(np.int8)


def conv_integer(x: np.ndarray, w: np.ndarray, bias: np.ndarray, pads: list[int], strides: list[int], out_shape: list[int], input_scale: float, weight_scale: float, output_scale: float) -> np.ndarray:
    n, c, h, width = map(int, x.shape)
    oc, ic, kh, kw = map(int, w.shape)
    if ic != c or pads[0] != pads[2] or pads[1] != pads[3] or strides[0] != strides[1]:
        raise ValueError(
            f"unsupported Conv geometry in hardware evaluator: "
            f"shape={x.shape} weight={w.shape} pads={pads} strides={strides}"
        )
    ph, pw = int(pads[0]), int(pads[1])
    sh = sw = int(strides[0])
    oh, ow = int(out_shape[2]), int(out_shape[3])
    padded = np.pad(x.astype(np.int32), ((0, 0), (0, 0), (ph, ph), (pw, pw)))
    windows = np.lib.stride_tricks.sliding_window_view(padded, (kh, kw), axis=(2, 3))
    windows = windows[:, :, ::sh, ::sw, :, :]
    acc = np.einsum("ncyxkl,ockl->noyx", windows, w.astype(np.int32), optimize=True)
    acc += bias.astype(np.int32).reshape(1, -1, 1, 1)
    ratio = np.float32(input_scale) * np.float32(weight_scale) / np.float32(output_scale)
    return np.clip(rne(acc * ratio), -128, 127).astype(np.int8)


def load_manifest() -> tuple[dict[str, Any], onnx.ModelProto, dict[str, np.ndarray]]:
    manifest = json.loads(MANIFEST.read_text())
    model = onnx.load(str(MODEL), load_external_data=True)
    arrays = {x.name: numpy_helper.to_array(x) for x in model.graph.initializer}
    return manifest, model, arrays


def q_record(manifest: dict[str, Any], float_name: str) -> dict[str, Any]:
    return manifest["tensor_quantization"][float_name]


def output_record(op: dict[str, Any]) -> dict[str, Any]:
    return op["output_quantization"][op["outputs"][0]]


def head_geometry(manifest: dict[str, Any]) -> tuple[list[int], list[int], int]:
    reshapes = {
        op["name"]: op for op in manifest["ops"]
        if op["op"] == "Reshape" and op["name"].startswith("/model.24/Reshape")
    }
    box = [reshapes[f"/model.24/Reshape{suffix}"] for suffix in ("", "_1", "_2")]
    class_heads = [reshapes[f"/model.24/Reshape{suffix}"] for suffix in ("_3", "_4", "_5")]
    box.sort(key=lambda op: op["output_shapes"][op["outputs"][0]][2], reverse=True)
    class_heads.sort(key=lambda op: op["output_shapes"][op["outputs"][0]][2], reverse=True)
    def source_shape(op: dict[str, Any]) -> list[int]:
        qname = manifest["tensor_quantization"][op["inputs"][0]]["quantized_tensor"]
        return [int(x) for x in manifest["tensor_layouts"][qname]["logical_shape"]]

    counts = [int(op["output_shapes"][op["outputs"][0]][2]) for op in box]
    class_counts = [int(op["output_shapes"][op["outputs"][0]][2]) for op in class_heads]
    if counts != class_counts or not counts:
        raise ValueError(f"class/box head geometry mismatch: {counts} != {class_counts}")
    return counts, [source_shape(op)[3] for op in box], sum(counts)


def detection_candidate(
    dfl: np.ndarray, dfl_scale: float, classes: np.ndarray,
    class_scale: float, index: int, counts: list[int], widths: list[int],
) -> dict[str, Any]:
    class_values = classes[:, index]
    class_id = int(np.argmax(class_values))
    score = float(np.float32(class_values[class_id]) * np.float32(class_scale))
    if index < counts[0]:
        local, width, stride = index, widths[0], 8
    elif index < counts[0] + counts[1]:
        local, width, stride = index - counts[0], widths[1], 16
    else:
        local, width, stride = index - counts[0] - counts[1], widths[2], 32
    x, y = local % width, local // width
    left, top, right, bottom = dfl[:, index].astype(np.float32) * np.float32(dfl_scale)
    return {
        "score": score, "class_id": class_id, "class_name": stage0.COCO_NAMES[class_id],
        "index": index,
        "cx": float((x + 0.5 + (right - left) * 0.5) * stride),
        "cy": float((y + 0.5 + (bottom - top) * 0.5) * stride),
        "w": float((left + right) * stride), "h": float((top + bottom) * stride),
    }


def detections_for_image(
    dfl: np.ndarray, dfl_scale: float, classes: np.ndarray,
    class_scale: float, counts: list[int], widths: list[int],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    total = sum(counts)
    top: list[dict[str, Any]] = []
    candidates = []
    for index in range(total):
        value = detection_candidate(dfl, dfl_scale, classes, class_scale, index, counts, widths)
        if len(top) < 10 or value["score"] > top[-1]["score"]:
            top.append(value)
            top.sort(key=lambda item: (-item["score"], item["index"]))
            del top[10:]
        if value["score"] >= 0.25:
            candidates.append(value)
    suppressed = [False] * len(candidates)
    nms: list[dict[str, Any]] = []
    while len(nms) < 10:
        best = next((i for i in range(len(candidates)) if not suppressed[i]), None)
        if best is None:
            break
        for i in range(len(candidates)):
            if not suppressed[i] and candidates[i]["score"] > candidates[best]["score"]:
                best = i
        selected = candidates[best]
        nms.append(selected)
        suppressed[best] = True
        for i, value in enumerate(candidates):
            if not suppressed[i] and value["class_id"] == selected["class_id"] and stage0.iou(value, selected) > 0.45:
                suppressed[i] = True
    return top, nms


def constants(model: onnx.ModelProto) -> dict[str, np.ndarray]:
    result: dict[str, np.ndarray] = {}
    for node in model.graph.node:
        if node.op_type != "Constant" or not node.output:
            continue
        value = next((a.t for a in node.attribute if a.name == "value"), None)
        if value is not None:
            result[node.output[0]] = numpy_helper.to_array(value)
    return result


def evaluate_image(manifest: dict[str, Any], model: onnx.ModelProto, arrays: dict[str, np.ndarray], image: Path) -> dict[str, Any]:
    const = constants(model)
    values: dict[str, np.ndarray] = {}
    input_info = manifest["input"][0]
    input_q = input_info["quantization"]["quantized_tensor"]
    input_scale = float(input_info["quantization"]["scale"])
    image_float = stage0.letterbox(image, HEIGHT, WIDTH)
    input_values = quantize(image_float, input_scale)
    if manifest["tensor_layouts"].get(input_q, {}).get("nhwc_resident", {}).get(
        "physical_layout"
    ) == "NHWC":
        input_values = input_values.transpose(0, 2, 3, 1)
    values[input_q] = input_values
    node_by_name = {n.name: n for n in model.graph.node}
    q_by_float = manifest["tensor_quantization"]
    op_by_name = {op["name"]: op for op in manifest["ops"]}
    add_names = set(FEATURE_ADDS)
    fused_mul_names = {
        op["name"] for op in manifest["ops"]
        if op["op"] == "Mul" and op["name"].endswith("/act/Mul")
    }

    def input_value(name: str) -> np.ndarray:
        if name in q_by_float:
            return values[q_by_float[name]["quantized_tensor"]]
        if name in const:
            return const[name]
        if name in arrays:
            return arrays[name]
        raise KeyError(f"missing evaluator input {name}")

    def output_q(op: dict[str, Any]) -> tuple[str, float, list[int]]:
        rec = output_record(op)
        return rec["quantized_tensor"], float(rec["scale"]), list(op["output_shapes"][op["outputs"][0]])

    def is_nhwc(qname: str) -> bool:
        return manifest["tensor_layouts"].get(qname, {}).get(
            "nhwc_resident", {}
        ).get("physical_layout") == "NHWC"

    for op in manifest["ops"]:
        name, kind = op["name"], op["op"]
        if not op.get("output_quantization"):
            continue
        qout, out_scale, out_shape = output_q(op)
        if kind == "Conv":
            x = input_value(op["inputs"][0])
            w = arrays[op["weight"]["initializer"]]
            bias = arrays[op["bias"]["initializer"]] if op.get("bias") else np.zeros((w.shape[0],), dtype=np.int32)
            x_scale = float(op["input_quantization"]["scale"])
            attrs = op["attributes"]
            conv_input = x.transpose(0, 3, 1, 2) if is_nhwc(op["input_quantization"]["quantized_tensor"]) else x
            conv_output = conv_integer(
                conv_input, w, bias,
                list(attrs.get("pads", [0, 0, 0, 0])),
                list(attrs.get("strides", [1, 1])), out_shape,
                x_scale, float(op["weight"]["scale"]), out_scale,
            )
            values[qout] = conv_output.transpose(0, 2, 3, 1) if is_nhwc(qout) else conv_output
        elif kind == "Sigmoid":
            x = input_value(op["inputs"][0]); x_scale = float(q_record(manifest, op["inputs"][0])["scale"])
            values[qout] = quantize(1.0 / (1.0 + np.exp(-np.clip(x.astype(np.float32) * np.float32(x_scale), -80, 80))), out_scale)
        elif kind == "Mul":
            left, right = [input_value(x) for x in op["inputs"]]
            if name in fused_mul_names:
                sigmoid = op_by_name[name.removesuffix("/act/Mul") + "/act/Sigmoid"]
                conv_input = input_value(sigmoid["inputs"][0])
                in_scale = float(q_record(manifest, sigmoid["inputs"][0])["scale"])
                sig_op = output_record(sigmoid)
                sig_scale = float(sig_op["scale"])
                sig_q = values[sig_op["quantized_tensor"]]
                real = conv_input.astype(np.float32) * np.float32(in_scale) * sig_q.astype(np.float32) * np.float32(sig_scale)
                values[qout] = quantize(real, out_scale)
            else:
                a = input_value(op["inputs"][0]).astype(np.float32) * np.float32(q_record(manifest, op["inputs"][0])["scale"])
                b = input_value(op["inputs"][1]).astype(np.float32) * np.float32(q_record(manifest, op["inputs"][1])["scale"])
                values[qout] = quantize(a * b, out_scale)
        elif kind == "Add":
            a, b = [input_value(x) for x in op["inputs"]]
            sa, sb = [float(q_record(manifest, x)["scale"]) for x in op["inputs"]]
            values[qout] = quantize(a.astype(np.float32) * np.float32(sa) + b.astype(np.float32) * np.float32(sb), out_scale)
        elif kind == "Concat":
            axis = int(op["attributes"]["axis"])
            chunks = []
            for x in op["inputs"]:
                q = input_value(x); s = float(q_record(manifest, x)["scale"])
                chunks.append(quantize(q.astype(np.float32) * np.float32(s), out_scale))
            values[qout] = np.concatenate(chunks, axis=3 if is_nhwc(qout) else axis)
        elif kind == "MaxPool":
            x = input_value(op["inputs"][0]); attrs = op["attributes"]; k = attrs["kernel_shape"]; st = attrs.get("strides", [1, 1]); p = attrs.get("pads", [0, 0, 0, 0])
            if is_nhwc(qout):
                padded = np.pad(x, ((0, 0), (p[0], p[2]), (p[1], p[3]), (0, 0)), constant_values=-128)
                windows = np.lib.stride_tricks.sliding_window_view(padded, (k[0], k[1]), axis=(1, 2))[:, ::st[0], ::st[1], :, :, :]
                values[qout] = np.max(windows, axis=(-1, -2)).astype(np.int8)
            else:
                padded = np.pad(x, ((0, 0), (0, 0), (p[0], p[2]), (p[1], p[3])), constant_values=-128)
                windows = np.lib.stride_tricks.sliding_window_view(padded, (k[0], k[1]), axis=(2, 3))[:, :, ::st[0], ::st[1], :, :]
                values[qout] = np.max(windows, axis=(-1, -2)).astype(np.int8)
        elif kind == "Resize":
            x = input_value(op["inputs"][0]); oh, ow = out_shape[2], out_shape[3]
            if is_nhwc(qout):
                ih, iw = x.shape[1], x.shape[2]
                yy = np.minimum((np.arange(oh) * ih // oh), ih - 1)
                xx = np.minimum((np.arange(ow) * iw // ow), iw - 1)
                values[qout] = x[:, yy[:, None], xx[None, :], :]
            else:
                ih, iw = x.shape[2], x.shape[3]
                yy = np.minimum((np.arange(oh) * ih // oh), ih - 1)
                xx = np.minimum((np.arange(ow) * iw // ow), iw - 1)
                values[qout] = x[:, :, yy[:, None], xx[None, :]]
        elif kind == "Reshape":
            x = input_value(op["inputs"][0]); in_scale = float(q_record(manifest, op["inputs"][0])["scale"])
            if is_nhwc(op["inputs"][0]) and not is_nhwc(qout):
                values[qout] = quantize(
                    x.transpose(0, 3, 1, 2).astype(np.float32) * np.float32(in_scale),
                    out_scale,
                ).reshape(out_shape)
            else:
                values[qout] = quantize(x.astype(np.float32) * np.float32(in_scale), out_scale).reshape(out_shape)
        elif kind == "Transpose":
            values[qout] = np.transpose(input_value(op["inputs"][0]), op["attributes"]["perm"])
        elif kind == "Softmax":
            # Match the baremetal softmax_i8 path: integer max, float32
            # exp-LUT indexed by max(input)-input, float32 sum order, then RNE.
            x = input_value(op["inputs"][0]).astype(np.int8)
            in_scale = float(q_record(manifest, op["inputs"][0])["scale"])
            axis = int(op["attributes"].get("axis", -1))
            axis += x.ndim if axis < 0 else 0
            moved = np.moveaxis(x, axis, -1)
            output = np.empty_like(moved, dtype=np.int8)
            exp_lut = np.exp(-np.arange(256, dtype=np.float32) * np.float32(in_scale))
            for index in np.ndindex(moved.shape[:-1]):
                row = moved[index].astype(np.int16)
                max_value = int(row.max())
                total = np.float32(0.0)
                for value in row:
                    total = np.float32(total + exp_lut[max_value - int(value)])
                for j, value in enumerate(row):
                    probability = np.float32(
                        exp_lut[max_value - int(value)] / total
                    )
                    output[index + (j,)] = quantize(
                        np.asarray(probability, dtype=np.float32), out_scale
                    ).item()
            values[qout] = np.moveaxis(output, -1, axis)
        else:
            raise ValueError(f"unsupported quantized evaluator op: {kind} {name}")

        if name == "/model.24/dfl/Reshape_1":
            break

    class_logits_op = op_by_name["/model.24/Concat_1"]
    class_op = op_by_name["/model.24/Sigmoid"]
    dfl_op = op_by_name["/model.24/dfl/Reshape_1"]

    # Reproduce the board's H4/H3G head lowering directly. The FPGA path
    # requants the three 80-channel class heads, applies the sigmoid LUT, and
    # computes DFL as exp-LUT -> float32 sum/reciprocal -> int8 probability
    # -> int32 dot -> final requant. It does not materialize a generic QDQ
    # Softmax tensor before the DFL 1x1 dot.
    reshape_ops = [
        op for op in manifest["ops"]
        if op["op"] == "Reshape" and op["name"].startswith("/model.24/Reshape")
    ]
    box_heads = [op for op in reshape_ops if op["output_shapes"][op["outputs"][0]][1] == 64]
    class_heads = [op for op in reshape_ops if op["output_shapes"][op["outputs"][0]][1] == 80]
    # The baremetal head lowering concatenates the three heads from largest to
    # smallest spatial area.
    box_heads.sort(key=lambda op: op["output_shapes"][op["outputs"][0]][2], reverse=True)
    class_heads.sort(key=lambda op: op["output_shapes"][op["outputs"][0]][2], reverse=True)
    class_concat_scale = float(output_record(class_logits_op)["scale"])
    class_scale = float(output_record(class_op)["scale"])
    class_chunks = []
    for head in class_heads:
        source = input_value(head["inputs"][0])
        source_scale = float(q_record(manifest, head["inputs"][0])["scale"])
        positions = int(head["output_shapes"][head["outputs"][0]][2])
        source_nhwc = source[0].reshape(positions, 80)
        class_chunks.append(quantize(source_nhwc.astype(np.float32) * np.float32(source_scale), class_concat_scale))
    logits = np.concatenate(class_chunks, axis=0).T.astype(np.int8)
    signed = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
    sigmoid_lut = quantize(
        1.0 / (1.0 + np.exp(-np.clip(signed * np.float32(class_concat_scale), -80, 80))),
        class_scale,
    )
    classes = sigmoid_lut[logits.view(np.uint8)].astype(np.int8)

    box_concat_op = op_by_name["/model.24/Concat"]
    box_concat_scale = float(output_record(box_concat_op)["scale"])
    box_chunks = []
    for head in box_heads:
        source = input_value(head["inputs"][0])
        source_scale = float(q_record(manifest, head["inputs"][0])["scale"])
        positions = int(head["output_shapes"][head["outputs"][0]][2])
        source_nhwc = source[0].reshape(positions, 64)
        box_chunks.append(quantize(source_nhwc.astype(np.float32) * np.float32(source_scale), box_concat_scale))
    box_logits = np.concatenate(box_chunks, axis=0)
    softmax_op = op_by_name["/model.24/dfl/Softmax"]
    softmax_scale = float(output_record(softmax_op)["scale"])
    dfl_scale = float(output_record(dfl_op)["scale"])
    dfl_conv = op_by_name["/model.24/dfl/conv/Conv"]
    dfl_weight = arrays[dfl_conv["weight"]["initializer"]].reshape(-1).astype(np.int32)
    dfl_weight_scale = float(dfl_conv["weight"]["scale"])
    exp_lut = np.exp(-np.arange(256, dtype=np.float32) * np.float32(box_concat_scale))
    head_counts, head_widths, total_positions = head_geometry(manifest)
    dfl = np.empty((4, total_positions), dtype=np.int8)
    for position in range(total_positions):
        for edge in range(4):
            row = box_logits[position, edge * 16:(edge + 1) * 16]
            maximum = int(row.max())
            total = np.float32(0.0)
            for value in row:
                total = np.float32(total + exp_lut[maximum - int(value)])
            reciprocal = np.float32(1.0 / np.float32(total * np.float32(softmax_scale)))
            accumulator = 0
            for bin_index, value in enumerate(row):
                probability = np.float32(exp_lut[maximum - int(value)] * reciprocal)
                probability_i = int(np.rint(probability))
                probability_i = min(127, max(-128, probability_i))
                accumulator += probability_i * int(dfl_weight[bin_index])
            dfl[edge, position] = quantize(
                np.asarray(np.float32(accumulator) * np.float32(softmax_scale) * np.float32(dfl_weight_scale)),
                dfl_scale,
            ).item()
    top, nms = detections_for_image(
        dfl, float(output_record(dfl_op)["scale"]), classes,
        float(output_record(class_op)["scale"]), head_counts, head_widths,
    )
    best_scores = classes.max(axis=0)
    top_indices = np.argsort(-best_scores, kind="stable")[:10]
    sparse_mask = best_scores.astype(np.float32) * np.float32(class_scale) >= np.float32(0.25)
    sparse_mask[top_indices] = True
    sparse_summary = stage0.tensor_summary(dfl[:, sparse_mask])
    return {
        "image_id": image.stem[-3:], "image": image.name,
        "class_logits": stage0.tensor_summary(logits), "class_scores": stage0.tensor_summary(classes), "dfl": stage0.tensor_summary(dfl),
        "dfl_sparse": {
            **sparse_summary,
            "candidate_count": int(np.count_nonzero(sparse_mask)),
        },
        "top_lines": [stage0.detection_line(i, x) for i, x in enumerate(top)],
        "nms_lines": [stage0.detection_line(i, x) for i, x in enumerate(nms)],
        "_tensors": {
            "class_logits": logits.copy(), "class_scores": classes.copy(), "dfl": dfl.copy()
        },
    }


def generate_reference() -> None:
    manifest, model, arrays = load_manifest()
    records = []
    npz_values: dict[str, np.ndarray] = {}
    for image_id in sorted(set(IMAGE_IDS) | {p.stem[-3:] for p in CALIBRATION.glob("*.jpg")}):
        image = CALIBRATION / f"000000000{image_id}.jpg"
        if not image.is_file():
            continue
        record = evaluate_image(manifest, model, arrays, image)
        records.append(record)
        tensors = record.pop("_tensors")
        for tensor_name, tensor in tensors.items():
            npz_values[f"{image_id}__{tensor_name}"] = tensor
        if len(records) % 10 == 0:
            print(f"hardware reference: {len(records)} images", flush=True)
    npz_path = OUTPUT_DIR / "hardware_integer_reference.npz"
    np.savez_compressed(npz_path, **npz_values)
    REFERENCE.write_text(json.dumps({
        "format": "yolov5nu-stage8-hardware-integer-reference-v1",
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "model": artifact(MODEL), "manifest": artifact(MANIFEST),
        "npz": artifact(npz_path),
        "semantics": {
            "conv": "int8 x int8 + int32 bias, float32 Gemmini requant, RNE, int8 saturation",
            "add": "shared-scale Gemmini resadd, float32 accumulator output scale, RNE",
            "activation": "per-tensor signed int8, zero_point=0",
            "weight": "per-tensor signed int8, zero_point=0",
            "silu": "quantized sigmoid LUT followed by int8 output LUT semantics",
        }, "images": records,
    }, indent=2) + "\n")
    print(f"PASS: wrote {REFERENCE} ({len(records)} images)")


def main() -> None:
    args = parse_args(); python = args.python.resolve()
    global OUTPUT_DIR, FP32_MODEL, FRESH_MODEL, MODEL, MANIFEST, QUANT_REPORT, AUDIT, REFERENCE, SILU_LUTS, WIDTH, HEIGHT
    OUTPUT_DIR = args.output_dir.resolve()
    WIDTH, HEIGHT = args.width, args.height
    if WIDTH <= 0 or HEIGHT <= 0 or WIDTH % 32 or HEIGHT % 32:
        raise ValueError("width and height must be positive multiples of 32")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    FP32_MODEL = OUTPUT_DIR / f"yolov5nu-fp32-img{WIDTH}x{HEIGHT}.onnx"
    FRESH_MODEL = OUTPUT_DIR / f"yolov5nu-hw-aware-full-int8-img{WIDTH}x{HEIGHT}.onnx"
    MODEL = OUTPUT_DIR / f"yolov5nu-hw-aware-shared-scale-int8-img{WIDTH}x{HEIGHT}.onnx"
    MANIFEST = OUTPUT_DIR / f"yolov5nu-hw-aware-shared-scale-img{WIDTH}x{HEIGHT}.graph.json"
    QUANT_REPORT = OUTPUT_DIR / f"yolov5nu-hw-aware-full-int8-img{WIDTH}x{HEIGHT}.quant.json"
    AUDIT = OUTPUT_DIR / "hardware_aware_quantization_audit.json"
    REFERENCE = OUTPUT_DIR / "hardware_integer_reference.json"
    SILU_LUTS = OUTPUT_DIR / "hardware_silu_luts.json"
    if args.command in {"quantize", "all"}:
        run_quantization(python, args.calibration_samples)
    if args.command in {"model", "all"}:
        build_shared_model(python)
    if args.command in {"reference", "all"}:
        generate_reference()


if __name__ == "__main__":
    main()
