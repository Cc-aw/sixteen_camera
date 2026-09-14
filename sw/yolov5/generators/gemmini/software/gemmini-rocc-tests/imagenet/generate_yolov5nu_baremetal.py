#!/usr/bin/env python3
"""Generate a fixed-shape YOLOv5nu Gemmini baremetal inference program.

The logical ONNX graph remains NCHW. The physical-layout option either keeps
that conservative Conv bridge or lowers regular feature tensors to resident
NHWC storage. The SiLU options independently select separate quantized
Sigmoid/Mul operators or a bit-exact fused int8 LUT, and select the scalar or
RVV indexed-load LUT kernel. The fixed-shape anchor-free decode replaces the
exporter's dynamic grid construction.
"""

from __future__ import annotations

import argparse
import json
import math
import re
from pathlib import Path
from typing import Any

import numpy as np
import onnx
from onnx import numpy_helper, shape_inference
from PIL import Image


ROOT = Path(__file__).resolve().parents[5]
MODEL_DIR = ROOT / "generators/gemmini/software/gemmini-ort/models/detection"
OUT_DIR = Path(__file__).resolve().parent
DEFAULT_MODEL = MODEL_DIR / "yolov5nu-gemmini-int8-img320.onnx"
DEFAULT_MANIFEST = MODEL_DIR / "yolov5nu-gemmini-int8-img320.graph.json"
DEFAULT_IMAGE = MODEL_DIR / "calibration/coco128/images/train2017/000000000009.jpg"
DEFAULT_STEM = "yolov5nu-gemmini-img320"

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
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--image", type=Path, default=DEFAULT_IMAGE)
    parser.add_argument("--output-dir", type=Path, default=OUT_DIR)
    parser.add_argument("--stem", default=DEFAULT_STEM)
    parser.add_argument(
        "--physical-layout",
        choices=("nchw-bridge", "nhwc"),
        default="nchw-bridge",
        help="runtime feature-map layout; nhwc keeps regular Conv tensors resident in NHWC",
    )
    parser.add_argument(
        "--silu-mode",
        choices=("separate", "fused-lut"),
        default="separate",
        help="lower SiLU as separate Sigmoid/Mul operators or one bit-exact int8 LUT",
    )
    parser.add_argument(
        "--silu-kernel",
        choices=("scalar", "rvv-e8m1", "rvv-e8m2", "opencv-rvv", "gemmini-lut"),
        default="scalar",
        help="implementation of the fused int8 SiLU LUT",
    )
    parser.add_argument(
        "--kernel-mode",
        choices=("scalar", "rvv"),
        default="scalar",
        help="default implementation of all Stage 3 kernels",
    )
    for kernel in ("copy", "add", "maxpool", "resize"):
        parser.add_argument(
            f"--{kernel}-kernel",
            choices=("scalar", "rvv", "rvv-ratio") if kernel == "add" else ("scalar", "rvv"),
            default=None,
            help=f"override the Stage 3 {kernel} implementation",
        )
    parser.add_argument(
        "--head-lowering",
        choices=("generic", "location-major"),
        default="generic",
        help="generic ONNX lowering or fused Stage 4 location-major detection heads",
    )
    parser.add_argument(
        "--head-kernel",
        choices=(
            "baseline", "optimized-rvv", "optimized-rvv-lut",
            "optimized-rvv-lut-dfl", "optimized-rvv-lut-dfl-batch",
            "optimized-rvv-lut-dfl-batch-scalar-sum",
            "optimized-rvv-lut-dfl-batch-elementwise-sum",
            "optimized-rvv-lut-dfl-batch-unordered-sum",
            "optimized-rvv-lut-dfl-batch-gather",
            "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
            "optimized-rvv-lut-dfl-ordered-sum",
            "optimized-rvv-lut-dfl-gather",
        ),
        default="baseline",
        help="Stage 4 location-major DFL/decode implementation",
    )
    parser.add_argument(
        "--head-output-mode",
        choices=("full", "detection-only"),
        default="full",
        help="full DFL tensor or sparse DFL for Top-10/NMS candidates",
    )
    parser.add_argument(
        "--head-candidate-kernel",
        choices=("scalar", "rvv"),
        default="scalar",
        help="class-max implementation used by detection-only H4",
    )
    parser.add_argument(
        "--stage7-mode",
        choices=("none", "7a", "7b", "7b-lut", "7b-register", "7c", "7d", "7bc", "7e"),
        default="none",
        help="Stage 7 Concat/Add optimization candidate",
    )
    parser.add_argument(
        "--stage8-mode",
        choices=(
            "none", "8a-materialized-control", "8a-materialized-cpuadd-control",
            "8b", "8c-model2", "8c-model2-alladds",
            "8c-backbone-splitk", "8c-single-consumer-splitk",
            "8c-dual-consumer-splitk", "8f-dual-consumer-spad-reuse",
            "8h-splitk-config-fence-merge",
        ),
        default="none",
        help="Stage 8 shared-scale resadd and split-K Concat-Conv candidate",
    )
    parser.add_argument(
        "--stage8-add-name",
        choices=(
            "/model.2/m/m.0/Add", "/model.4/m/m.0/Add", "/model.4/m/m.1/Add",
            "/model.6/m/m.0/Add", "/model.6/m/m.1/Add", "/model.6/m/m.2/Add",
            "/model.8/m/m.0/Add",
        ),
        default="/model.2/m/m.0/Add",
        help="feature-map Add selected by Stage 8B",
    )
    parser.add_argument(
        "--memory-stage",
        choices=("none", "5a", "5b", "5c", "5d"),
        default="none",
        help="progressive Stage 5 static memory-planning level",
    )
    parser.add_argument(
        "--diagnostic-layer-stats",
        action="store_true",
        help="retain per-op checkpoints with arena planning for diagnostic builds",
    )
    parser.add_argument(
        "--disable-fused-silu-conv",
        default=None,
        help="diagnostic-only Conv name whose fused Gemmini SiLU is split out",
    )
    parser.add_argument(
        "--diagnostic-fingerprint",
        action="store_true",
        help="print sum-of-squares and FNV-1a fingerprints for diagnostic checkpoints",
    )
    parser.add_argument("--nms-score-threshold", type=float, default=0.25)
    parser.add_argument("--nms-iou-threshold", type=float, default=0.45)
    return parser.parse_args()


def c_id(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value).strip("_")


def c_float(value: float) -> str:
    literal = f"{float(value):.10g}"
    if "." not in literal and "e" not in literal:
        literal += ".0"
    return literal + "f"


def c_array(values: np.ndarray, per_line: int = 24) -> str:
    flat = values.reshape(-1)
    lines = [
        ",".join(str(int(item)) for item in flat[index:index + per_line])
        for index in range(0, flat.size, per_line)
    ]
    return "{\n" + ",\n".join(lines) + "\n}"


def c_float_array(values: np.ndarray, per_line: int = 8) -> str:
    flat = values.reshape(-1)
    lines = [
        ",".join(c_float(float(item)) for item in flat[index:index + per_line])
        for index in range(0, flat.size, per_line)
    ]
    return "{\n" + ",\n".join(lines) + "\n}"


def product(shape: list[int]) -> int:
    result = 1
    for dim in shape:
        result *= dim
    return result


def align_up(value: int, alignment: int) -> int:
    return (value + alignment - 1) // alignment * alignment


def allocate_arena(
    intervals: dict[str, tuple[int, int]],
    sizes: dict[str, int],
    alignment: int,
) -> tuple[dict[str, int], int]:
    def allocate(ordered: list[str], best_fit: bool) -> tuple[dict[str, int], int]:
        offsets: dict[str, int] = {}
        active: list[tuple[int, int, int, str]] = []
        peak = 0
        for name in ordered:
            birth, death = intervals[name]
            active = [entry for entry in active if entry[0] >= birth]
            occupied = sorted((offset, offset + size) for _, offset, size, _ in active)
            gaps: list[tuple[int, int]] = []
            cursor = 0
            for start, end in occupied:
                candidate = align_up(cursor, alignment)
                if candidate + sizes[name] <= start:
                    gaps.append((candidate, start - candidate - sizes[name]))
                cursor = max(cursor, end)
            end_offset = align_up(cursor, alignment)
            if gaps:
                offset = min(gaps, key=(lambda gap: (gap[1], gap[0])) if best_fit else (lambda gap: gap[0]))[0]
            else:
                offset = end_offset
            offsets[name] = offset
            active.append((death, offset, sizes[name], name))
            peak = max(peak, offset + sizes[name])
        return offsets, align_up(peak, alignment)

    order_keys = (
        lambda name: (intervals[name][0], -sizes[name], intervals[name][1], name),
        lambda name: (intervals[name][0], intervals[name][1], -sizes[name], name),
        lambda name: (intervals[name][0], -intervals[name][1], -sizes[name], name),
        lambda name: (intervals[name][0], sizes[name], intervals[name][1], name),
    )
    candidates = [
        allocate(sorted(intervals, key=key), best_fit)
        for key in order_keys for best_fit in (False, True)
    ]
    return min(candidates, key=lambda item: item[1])


def attributes(node: onnx.NodeProto) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for attribute in node.attribute:
        value = onnx.helper.get_attribute_value(attribute)
        if isinstance(value, bytes):
            value = value.decode("utf-8")
        result[attribute.name] = value
    return result


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
    return np.asarray(canvas, dtype=np.float32).transpose(2, 0, 1) / 255.0


def gemmini_weight(weight_oihw: np.ndarray) -> np.ndarray:
    out_channels, in_channels, kh, kw = weight_oihw.shape
    return weight_oihw.transpose(2, 3, 1, 0).reshape(kh * kw * in_channels, out_channels)


def main() -> None:
    args = parse_args()
    gemmini_lut = args.silu_kernel == "gemmini-lut"
    splitk_conv_by_concat = {}
    if args.stage8_mode in {"8c-model2", "8c-model2-alladds"}:
        splitk_conv_by_concat = {
            "/model.2/Concat": "/model.2/cv3/conv/Conv",
        }
    elif args.stage8_mode in {
        "8c-backbone-splitk", "8c-single-consumer-splitk",
        "8c-dual-consumer-splitk", "8f-dual-consumer-spad-reuse",
        "8h-splitk-config-fence-merge",
    }:
        splitk_conv_by_concat = {
            "/model.2/Concat": "/model.2/cv3/conv/Conv",
            "/model.4/Concat": "/model.4/cv3/conv/Conv",
            "/model.6/Concat": "/model.6/cv3/conv/Conv",
            "/model.8/Concat": "/model.8/cv3/conv/Conv",
        }
        if args.stage8_mode in {"8c-single-consumer-splitk", "8c-dual-consumer-splitk", "8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"}:
            splitk_conv_by_concat.update({
                "/model.9/Concat": "/model.9/cv2/conv/Conv",
                "/model.13/Concat": "/model.13/cv3/conv/Conv",
                "/model.17/Concat": "/model.17/cv3/conv/Conv",
                "/model.20/Concat": "/model.20/cv3/conv/Conv",
                "/model.23/Concat": "/model.23/cv3/conv/Conv",
            })
        if args.stage8_mode in {"8c-dual-consumer-splitk", "8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"}:
            splitk_conv_by_concat.update({
                "/model.12/Concat": "/model.13/cv1/conv/Conv",
                "/model.12/Concat#2": "/model.13/cv2/conv/Conv",
                "/model.16/Concat": "/model.17/cv1/conv/Conv",
                "/model.16/Concat#2": "/model.17/cv2/conv/Conv",
                "/model.19/Concat": "/model.20/cv1/conv/Conv",
                "/model.19/Concat#2": "/model.20/cv2/conv/Conv",
                "/model.22/Concat": "/model.23/cv1/conv/Conv",
                "/model.22/Concat#2": "/model.23/cv2/conv/Conv",
            })
    splitk_concat_names = set(splitk_conv_by_concat)
    splitk_concat_names = {
        name.removesuffix("#2") for name in splitk_concat_names
    }
    splitk_concat_by_conv = {
        conv: concat.removesuffix("#2")
        for concat, conv in splitk_conv_by_concat.items()
    }
    splitk_conv_names = set(splitk_concat_by_conv)
    spad_reuse_second_consumers = set()
    if args.stage8_mode in {"8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"}:
        spad_reuse_second_consumers = {
            "/model.13/cv2/conv/Conv",
            "/model.17/cv2/conv/Conv",
            "/model.20/cv2/conv/Conv",
            "/model.23/cv2/conv/Conv",
        }
    spad_reuse_consumers = set()
    spad_reuse_first_to_second = {}
    if args.stage8_mode in {"8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"}:
        spad_reuse_first_to_second = {
            "/model.13/cv1/conv/Conv": "/model.13/cv2/conv/Conv",
            "/model.17/cv1/conv/Conv": "/model.17/cv2/conv/Conv",
            "/model.20/cv1/conv/Conv": "/model.20/cv2/conv/Conv",
            "/model.23/cv1/conv/Conv": "/model.23/cv2/conv/Conv",
        }
        spad_reuse_consumers = spad_reuse_second_consumers | set(spad_reuse_first_to_second)
    stage3_kernels = {
        name: getattr(args, f"{name}_kernel") or args.kernel_mode
        for name in ("copy", "add", "maxpool", "resize")
    }
    if not 0.0 <= args.nms_score_threshold <= 1.0:
        raise ValueError("--nms-score-threshold must be between 0 and 1")
    if not 0.0 <= args.nms_iou_threshold <= 1.0:
        raise ValueError("--nms-iou-threshold must be between 0 and 1")
    if args.silu_kernel != "scalar" and args.silu_mode != "fused-lut":
        raise ValueError("alternate SiLU kernels require --silu-mode fused-lut")
    if any(mode.startswith("rvv") for mode in stage3_kernels.values()):
        if args.physical_layout != "nhwc" or args.silu_mode != "fused-lut":
            raise ValueError("Stage 3 RVV kernels require NHWC plus fused-lut Stage 2")
        if args.silu_kernel not in {"scalar", "gemmini-lut"}:
            raise ValueError("Stage 3 keeps the validated scalar fused-SiLU kernel")
    if args.head_lowering == "location-major":
        if args.physical_layout != "nhwc" or args.silu_mode != "fused-lut":
            raise ValueError("Stage 4 location-major heads require NHWC plus fused-lut")
        if any(not mode.startswith("rvv") for mode in stage3_kernels.values()):
            raise ValueError("Stage 4 location-major heads must build on all-RVV Stage 3")
    if args.head_kernel != "baseline" and args.head_lowering != "location-major":
        raise ValueError("optimized Stage 4 head kernels require location-major lowering")
    if args.head_output_mode == "detection-only":
        if (args.head_lowering != "location-major" or
                args.head_kernel != "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum"):
            raise ValueError("detection-only mode requires the H3G location-major kernel")
    if args.stage7_mode != "none" and args.memory_stage != "5d":
        raise ValueError("Stage 7 candidates require Stage 5d memory planning")
    if args.stage8_mode != "none":
        if args.memory_stage != "5d" or args.stage7_mode != "7e":
            raise ValueError("Stage 8 requires Stage 7E memory/layout lowering")
        if args.physical_layout != "nhwc" or args.silu_kernel != "gemmini-lut":
            raise ValueError("Stage 8 requires NHWC hardware SiLU lowering")
    if args.stage8_mode in {
        "8c-model2", "8c-model2-alladds", "8c-backbone-splitk"
        , "8c-single-consumer-splitk", "8f-dual-consumer-spad-reuse",
          "8h-splitk-config-fence-merge"
    } and args.stage8_add_name != "/model.2/m/m.0/Add":
        raise ValueError("Stage 8C model2 currently requires /model.2/m/m.0/Add")
    if args.memory_stage != "none":
        if (args.head_lowering != "location-major" or
                args.head_kernel not in {
                    "optimized-rvv", "optimized-rvv-lut", "optimized-rvv-lut-dfl",
                    "optimized-rvv-lut-dfl-batch",
                    "optimized-rvv-lut-dfl-batch-scalar-sum",
                    "optimized-rvv-lut-dfl-batch-elementwise-sum",
                    "optimized-rvv-lut-dfl-batch-unordered-sum",
                    "optimized-rvv-lut-dfl-batch-gather",
                    "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
                    "optimized-rvv-lut-dfl-ordered-sum",
                    "optimized-rvv-lut-dfl-gather",
                }):
            raise ValueError("Stage 5 requires the optimized Stage 4.1 location-major baseline")
        if stage3_kernels["add"] != "rvv-ratio":
            raise ValueError("Stage 5 requires the validated rvv-ratio Add kernel")
    for path in (args.model, args.manifest, args.image):
        if not path.is_file():
            raise FileNotFoundError(path)

    manifest = json.loads(args.manifest.read_text())
    if manifest.get("format") != "yolov5nu-gemmini-qnn-manifest-v1":
        raise ValueError(f"unsupported manifest format: {manifest.get('format')}")
    if manifest.get("conv_count") != 76 or manifest.get("unsupported"):
        raise ValueError("manifest does not describe the expected fully supported 76-Conv graph")

    model = shape_inference.infer_shapes(onnx.load(args.model, load_external_data=True))
    arrays = {item.name: numpy_helper.to_array(item) for item in model.graph.initializer}
    nodes = {node.name: node for node in model.graph.node}
    shape_map = {
        value.name: [int(dim.dim_value) for dim in value.type.tensor_type.shape.dim]
        for value in list(model.graph.input) + list(model.graph.output) + list(model.graph.value_info)
        if all(dim.dim_value for dim in value.type.tensor_type.shape.dim)
    }
    dq = manifest["tensor_quantization"]

    selected: list[dict[str, Any]] = []
    for op in manifest["ops"]:
        selected.append(op)
        if op["name"] == "/model.24/dfl/Reshape_1":
            break
    else:
        raise ValueError("DFL terminal reshape was not found")

    def input_q(tensor: str) -> tuple[str, float]:
        if tensor not in dq:
            raise ValueError(f"{tensor} is not a QDQ activation input")
        record = dq[tensor]
        return record["quantized_tensor"], float(record["scale"])

    def output_q(op: dict[str, Any]) -> tuple[str, float, list[int]]:
        output = op["outputs"][0]
        records = op.get("output_quantization", {})
        if output not in records:
            raise ValueError(f"{op['name']} has no quantized output")
        record = records[output]
        shape = shape_map.get(output)
        if not shape:
            raise ValueError(f"no static shape for {output}")
        return record["quantized_tensor"], float(record["scale"]), shape

    input_record = manifest["input"][0]
    input_float_name = input_record["name"]
    input_q_name = input_record["quantization"]["quantized_tensor"]
    input_scale = float(input_record["quantization"]["scale"])
    input_shape = [int(item) for item in input_record["shape"]]
    image = letterbox(args.image, input_shape[2], input_shape[3])
    image_q = np.clip(np.rint(image / input_scale), -128, 127).astype(np.int8)

    tensor_shapes: dict[str, list[int]] = {input_q_name: input_shape}
    tensor_scales: dict[str, float] = {input_q_name: input_scale}
    for op in selected:
        name, scale, shape = output_q(op)
        tensor_shapes[name] = shape
        tensor_scales[name] = scale

    layout_records = manifest.get("tensor_layouts", {})
    if args.physical_layout == "nhwc" and not layout_records:
        raise ValueError("manifest lacks tensor_layouts; rerun yolov5nu_graph_parser.py")

    def tensor_layout(name: str) -> str:
        if args.physical_layout != "nhwc":
            return "NCHW" if len(tensor_shapes[name]) == 4 else f"RANK{len(tensor_shapes[name])}"
        if name not in layout_records:
            raise ValueError(f"manifest lacks physical layout for {name}")
        return layout_records[name]["nhwc_resident"]["physical_layout"]

    def is_nhwc(name: str) -> bool:
        return tensor_layout(name) == "NHWC"

    def output_record(op: dict[str, Any]) -> dict[str, Any]:
        output = op["outputs"][0]
        return op["output_quantization"][output]

    consumers: dict[str, list[dict[str, Any]]] = {}
    for op in selected:
        for name in op["inputs"]:
            if name in dq:
                q_name, _ = input_q(name)
                consumers.setdefault(q_name, []).append(op)

    fused_sigmoid_to_mul: dict[str, dict[str, Any]] = {}
    fused_mul_to_sigmoid: dict[str, dict[str, Any]] = {}
    if args.silu_mode == "fused-lut":
        for sigmoid in selected:
            if sigmoid["op"] != "Sigmoid":
                continue
            sigmoid_input_name, _ = input_q(sigmoid["inputs"][0])
            sigmoid_output_name, _, sigmoid_shape = output_q(sigmoid)
            output_consumers = consumers.get(sigmoid_output_name, [])
            if len(output_consumers) != 1 or output_consumers[0]["op"] != "Mul":
                continue
            mul = output_consumers[0]
            mul_inputs = [input_q(name)[0] for name in mul["inputs"] if name in dq]
            if len(mul_inputs) != 2 or sorted(mul_inputs) != sorted(
                [sigmoid_input_name, sigmoid_output_name]
            ):
                continue
            mul_output_name, _, mul_shape = output_q(mul)
            records = [dq[sigmoid["inputs"][0]], output_record(sigmoid), output_record(mul)]
            if any(
                record.get("dtype") != "int8" or int(record.get("zero_point", 1)) != 0
                for record in records
            ):
                continue
            if tensor_shapes[sigmoid_input_name] != sigmoid_shape or sigmoid_shape != mul_shape:
                continue
            layouts = {
                tensor_layout(sigmoid_input_name),
                tensor_layout(sigmoid_output_name),
                tensor_layout(mul_output_name),
            }
            if len(layouts) != 1:
                continue
            fused_sigmoid_to_mul[sigmoid["name"]] = mul
            fused_mul_to_sigmoid[mul["name"]] = sigmoid
        if len(fused_mul_to_sigmoid) != 69:
            raise ValueError(
                f"expected 69 safe SiLU patterns, found {len(fused_mul_to_sigmoid)}"
            )

    if args.physical_layout == "nhwc":
        image_storage = image_q.transpose(1, 2, 0).copy()
    else:
        image_storage = image_q

    tensor_ids = {name: f"tensor_{index}" for index, name in enumerate(tensor_shapes)}

    def tensor_ptr(name: str) -> str:
        return "yolov5nu_input" if name == input_q_name else tensor_ids[name]

    sigmoid_luts: dict[str, tuple[int, np.ndarray]] = {}
    silu_luts: dict[str, tuple[int, np.ndarray]] = {}
    softmax_luts: dict[str, tuple[int, np.ndarray]] = {}
    add_requant_luts: dict[tuple[float, float], tuple[int, np.ndarray]] = {}
    signed_raw = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)

    def sigmoid_quantized(op: dict[str, Any]) -> np.ndarray:
        _, in_scale = input_q(op["inputs"][0])
        _, out_scale, _ = output_q(op)
        logits = np.clip(signed_raw * np.float32(in_scale), -80.0, 80.0)
        values = 1.0 / (1.0 + np.exp(-logits))
        return np.clip(
            np.rint(values / np.float32(out_scale)), -128, 127
        ).astype(np.int8)

    for op in selected:
        if op["op"] not in {"Sigmoid", "Softmax"}:
            continue
        _, in_scale = input_q(op["inputs"][0])
        if op["op"] == "Sigmoid":
            if op["name"] not in fused_sigmoid_to_mul:
                sigmoid_luts[op["name"]] = (len(sigmoid_luts), sigmoid_quantized(op))
        else:
            values = np.exp(-np.arange(256, dtype=np.float32) * np.float32(in_scale))
            softmax_luts[op["name"]] = (len(softmax_luts), values)

    for mul_name, sigmoid in fused_mul_to_sigmoid.items():
        mul = fused_sigmoid_to_mul[sigmoid["name"]]
        _, input_scale = input_q(sigmoid["inputs"][0])
        _, sigmoid_scale, _ = output_q(sigmoid)
        _, mul_scale, _ = output_q(mul)
        sigmoid_values = sigmoid_quantized(sigmoid).astype(np.float32)
        real = signed_raw * np.float32(input_scale)
        real = real * sigmoid_values
        real = real * np.float32(sigmoid_scale)
        quantized = np.clip(
            np.rint(real / np.float32(mul_scale)), -128, 127
        ).astype(np.int8)
        silu_luts[mul_name] = (len(silu_luts), quantized)

    def add_requant_lut(add_scale: float, concat_scale: float) -> np.ndarray:
        # Keep the scalar reference's float32 multiply-then-divide ordering.
        values = signed_raw * np.float32(add_scale)
        return np.clip(
            np.rint(values / np.float32(concat_scale)), -128, 127
        ).astype(np.int8)

    def fixed_multiplier(ratio: float) -> int:
        return int(np.rint(np.float32(ratio) * np.float32(1 << 22)))

    producer_by_tensor: dict[str, dict[str, Any]] = {}
    for op in selected:
        producer_by_tensor[output_q(op)[0]] = op

    add_requant_lut_by_producer: dict[str, int] = {}
    if args.stage7_mode in {"7b-lut", "7b-register", "7bc", "7e"}:
        for op in selected:
            if op["op"] != "Add":
                continue
            add_output, add_scale, _ = output_q(op)
            concat_consumers = [
                consumer for consumer in consumers.get(add_output, [])
                if consumer["op"] == "Concat"
            ]
            if len(concat_consumers) != 1:
                continue
            _, concat_scale, _ = output_q(concat_consumers[0])
            if add_scale == concat_scale:
                continue
            key = (add_scale, concat_scale)
            if key not in add_requant_luts:
                add_requant_luts[key] = (
                    len(add_requant_luts), add_requant_lut(add_scale, concat_scale)
                )
            add_requant_lut_by_producer[op["name"]] = add_requant_luts[key][0]

    hardware_silu_by_conv: dict[str, dict[str, Any]] = {}
    disabled_fused_silu_mul_names: set[str] = set()
    if gemmini_lut:
        for mul_name, sigmoid in fused_mul_to_sigmoid.items():
            input_name, _ = input_q(sigmoid["inputs"][0])
            producer = producer_by_tensor.get(input_name)
            if producer is None or producer["op"] != "Conv":
                raise ValueError(f"Gemmini SiLU input is not a Conv output: {mul_name}")
            mul = fused_sigmoid_to_mul[sigmoid["name"]]
            output_name, _, output_shape = output_q(mul)
            if tensor_shapes[input_name] != output_shape:
                raise ValueError(f"Gemmini SiLU changes shape: {mul_name}")
            hardware_silu_by_conv[producer["name"]] = {
                "mul": mul,
                "lut_index": silu_luts[mul_name][0],
                "output_name": output_name,
            }
        if args.disable_fused_silu_conv is not None:
            disabled = hardware_silu_by_conv.pop(args.disable_fused_silu_conv, None)
            if disabled is None:
                raise ValueError(
                    f"cannot disable fused SiLU for unknown Conv: {args.disable_fused_silu_conv}"
                )
            disabled_fused_silu_mul_names.add(disabled["mul"]["name"])
        expected_hardware_silu = 69 - len(disabled_fused_silu_mul_names)
        if len(hardware_silu_by_conv) != expected_hardware_silu:
            raise ValueError(
                f"expected {expected_hardware_silu} Conv-backed Gemmini SiLU patterns, "
                f"found {len(hardware_silu_by_conv)}"
            )

    conv_ops = [op for op in selected if op["op"] == "Conv"]
    max_conv_input = 0
    max_conv_output = 0
    for op in conv_ops:
        in_name, _ = input_q(op["inputs"][0])
        out_name, _, _ = output_q(op)
        max_conv_input = max(max_conv_input, product(tensor_shapes[in_name]))
        max_conv_output = max(max_conv_output, product(tensor_shapes[out_name]))

    header_path = args.output_dir / f"{args.stem}_params.h"
    source_path = args.output_dir / f"{args.stem}.c"
    guard = c_id(args.stem).upper() + "_PARAMS_H"
    args.output_dir.mkdir(parents=True, exist_ok=True)

    with header_path.open("w") as header:
        header.write(f"#ifndef {guard}\n#define {guard}\n\n")
        header.write(f"#define YOLOV5NU_INPUT_ELEMS {image_storage.size}\n")
        header.write(f"#define YOLOV5NU_CONV_INPUT_SCRATCH {max_conv_input}\n")
        header.write(f"#define YOLOV5NU_CONV_OUTPUT_SCRATCH {max_conv_output}\n")
        header.write(f"#define YOLOV5NU_IMAGE_NAME \"{args.image.name}\"\n\n")
        header.write(f"#define YOLOV5NU_PHYSICAL_LAYOUT_{args.physical_layout.replace('-', '_').upper()} 1\n\n")
        header.write(f"#define YOLOV5NU_SILU_MODE_{args.silu_mode.replace('-', '_').upper()} 1\n\n")
        header.write(f"#define YOLOV5NU_SILU_KERNEL_{args.silu_kernel.replace('-', '_').upper()} 1\n\n")
        header.write(f"#define YOLOV5NU_KERNEL_MODE_{args.kernel_mode.upper()} 1\n\n")
        for name, mode in stage3_kernels.items():
            header.write(
                f"#define YOLOV5NU_{name.upper()}_KERNEL_{mode.replace('-', '_').upper()} 1\n"
            )
        header.write(
            f"#define YOLOV5NU_HEAD_LOWERING_{args.head_lowering.replace('-', '_').upper()} 1\n"
        )
        header.write(
            f"#define YOLOV5NU_HEAD_KERNEL_{args.head_kernel.replace('-', '_').upper()} 1\n"
        )
        header.write(
            f"#define YOLOV5NU_HEAD_OUTPUT_MODE_{args.head_output_mode.replace('-', '_').upper()} 1\n"
        )
        header.write(
            f"#define YOLOV5NU_HEAD_CANDIDATE_KERNEL_{args.head_candidate_kernel.upper()} 1\n"
        )
        header.write(
            f"#define YOLOV5NU_STAGE7_MODE_{args.stage7_mode.replace('-', '_').upper()} 1\n"
        )
        header.write(
            f"#define YOLOV5NU_STAGE8_MODE_{args.stage8_mode.replace('-', '_').upper()} 1\n"
        )
        if args.head_kernel in {
                "optimized-rvv-lut", "optimized-rvv-lut-dfl",
                "optimized-rvv-lut-dfl-batch",
                "optimized-rvv-lut-dfl-batch-scalar-sum",
                "optimized-rvv-lut-dfl-batch-elementwise-sum",
                "optimized-rvv-lut-dfl-batch-unordered-sum",
                "optimized-rvv-lut-dfl-batch-gather",
                "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
                "optimized-rvv-lut-dfl-ordered-sum",
                "optimized-rvv-lut-dfl-gather"}:
            header.write("#define YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV 1\n")
        if args.head_kernel in {
                "optimized-rvv-lut-dfl", "optimized-rvv-lut-dfl-batch",
                "optimized-rvv-lut-dfl-batch-scalar-sum",
                "optimized-rvv-lut-dfl-batch-elementwise-sum",
                "optimized-rvv-lut-dfl-batch-unordered-sum",
                "optimized-rvv-lut-dfl-batch-gather",
                "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
                "optimized-rvv-lut-dfl-ordered-sum",
                "optimized-rvv-lut-dfl-gather"}:
            header.write("#define YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-batch":
            header.write("#define YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL 1\n")
        if args.head_kernel in {
                "optimized-rvv-lut-dfl-batch-scalar-sum",
                "optimized-rvv-lut-dfl-batch-elementwise-sum",
                "optimized-rvv-lut-dfl-batch-unordered-sum",
                "optimized-rvv-lut-dfl-batch-gather",
                "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum",
                "optimized-rvv-lut-dfl-ordered-sum",
                "optimized-rvv-lut-dfl-gather"}:
            header.write("#define YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-batch-scalar-sum":
            header.write("#define YOLOV5NU_HEAD_KERNEL_DFL_BATCH_SCALAR_SUM 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-batch-elementwise-sum":
            header.write("#define YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-batch-unordered-sum":
            header.write("#define YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-batch-gather":
            header.write("#define YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-batch-interleaved-scalar-sum":
            header.write("#define YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-ordered-sum":
            header.write("#define YOLOV5NU_HEAD_KERNEL_DFL_ORDERED_SUM 1\n")
        if args.head_kernel == "optimized-rvv-lut-dfl-gather":
            header.write("#define YOLOV5NU_HEAD_KERNEL_DFL_GATHER 1\n")
        header.write(
            f"#define YOLOV5NU_MEMORY_STAGE_{args.memory_stage.upper()} 1\n"
        )
        header.write("\n")
        header.write("static const elem_t yolov5nu_input[YOLOV5NU_INPUT_ELEMS] row_align(1) = ")
        header.write(c_array(image_storage))
        header.write(";\n\n")
        for _, (index, values) in sigmoid_luts.items():
            header.write(f"static const elem_t yolov5nu_sigmoid_lut{index}[256] = ")
            header.write(c_array(values))
            header.write(";\n")
        for _, (index, values) in silu_luts.items():
            header.write(f"static const elem_t yolov5nu_silu_lut{index}[256] = ")
            header.write(c_array(values))
            header.write(";\n")
        for _, (index, values) in softmax_luts.items():
            header.write(f"static const float yolov5nu_softmax_exp_lut{index}[256] = ")
            header.write(c_float_array(values))
            header.write(";\n")
        for _, (index, values) in add_requant_luts.items():
            header.write(f"static const elem_t yolov5nu_add_requant_lut{index}[256] = ")
            header.write(c_array(values))
            header.write(";\n")
        header.write("\n")
        for op in conv_ops:
            index = int(op["conv_index"])
            weight = arrays[op["weight"]["initializer"]].astype(np.int8)
            transformed = gemmini_weight(weight)
            header.write(
                f"static const elem_t yolov5nu_conv{index}_weights[{transformed.size}] row_align(1) = "
            )
            header.write(c_array(transformed))
            header.write(";\n")
            bias = op.get("bias")
            if bias:
                bias_array = arrays[bias["initializer"]].astype(np.int32)
                header.write(f"static const acc_t yolov5nu_conv{index}_bias[{bias_array.size}] row_align_acc(1) = ")
                header.write(c_array(bias_array))
                header.write(";\n")
            header.write("\n")
        header.write(f"#endif /* {guard} */\n")

    declarations = []
    for name, shape in tensor_shapes.items():
        if name == input_q_name:
            continue
        declarations.append(f"static elem_t {tensor_ids[name]}[{product(shape)}] row_align(1);")

    stage4_skip_names: set[str] = set()
    stage4_inject_name = "/model.24/Reshape_5"
    stage4_class_call = ""
    stage4_dfl_call = ""
    head_reshape_names = [
        "/model.24/Reshape", "/model.24/Reshape_1", "/model.24/Reshape_2",
        "/model.24/Reshape_3", "/model.24/Reshape_4", "/model.24/Reshape_5",
    ]

    def selected_op(name: str) -> dict[str, Any]:
        return next(op for op in selected if op["name"] == name)

    head_source_shapes = []
    for name in head_reshape_names:
        op = selected_op(name)
        source_q_name, _ = input_q(op["inputs"][0])
        head_source_shapes.append(tensor_shapes[source_q_name])
    head_position_counts = [int(shape[2]) * int(shape[3]) for shape in head_source_shapes[:3]]
    head_grid_heights = [int(shape[2]) for shape in head_source_shapes[:3]]
    head_grid_widths = [int(shape[3]) for shape in head_source_shapes[:3]]
    head_position_offsets = [0]
    for count in head_position_counts:
        head_position_offsets.append(head_position_offsets[-1] + count)
    total_head_positions = head_position_offsets[-1]
    class_position_counts = [int(shape[2]) * int(shape[3]) for shape in head_source_shapes[3:]]
    if total_head_positions <= 0 or class_position_counts != head_position_counts:
        raise ValueError(
            f"invalid detection-head spatial shapes: box={head_position_counts} "
            f"class={class_position_counts}"
        )
    if args.head_lowering == "location-major":
        box_reshapes = [
            selected_op("/model.24/Reshape"),
            selected_op("/model.24/Reshape_1"),
            selected_op("/model.24/Reshape_2"),
        ]
        class_reshapes = [
            selected_op("/model.24/Reshape_3"),
            selected_op("/model.24/Reshape_4"),
            selected_op("/model.24/Reshape_5"),
        ]
        box_sources = [input_q(op["inputs"][0]) for op in box_reshapes]
        class_sources = [input_q(op["inputs"][0]) for op in class_reshapes]
        box_positions = [product(tensor_shapes[name][2:]) for name, _ in box_sources]
        class_positions = [product(tensor_shapes[name][2:]) for name, _ in class_sources]
        if box_positions != head_position_counts or class_positions != box_positions:
            raise ValueError(
                f"unexpected Stage 4 detection-head positions: {box_positions}, {class_positions}"
            )
        if any(tensor_shapes[name][1] != 64 for name, _ in box_sources):
            raise ValueError("Stage 4 box heads must have 64 channels")
        if any(tensor_shapes[name][1] != 80 for name, _ in class_sources):
            raise ValueError("Stage 4 class heads must have 80 channels")

        box_concat = selected_op("/model.24/Concat")
        class_concat = selected_op("/model.24/Concat_1")
        class_sigmoid = selected_op("/model.24/Sigmoid")
        dfl_softmax = selected_op("/model.24/dfl/Softmax")
        dfl_conv = selected_op("/model.24/dfl/conv/Conv")
        dfl_final = selected_op("/model.24/dfl/Reshape_1")
        box_concat_name, box_concat_scale, _ = output_q(box_concat)
        class_logits_name, class_concat_scale, _ = output_q(class_concat)
        class_name, class_scale, _ = output_q(class_sigmoid)
        _, softmax_scale, _ = output_q(dfl_softmax)
        dfl_name, dfl_scale, _ = output_q(dfl_final)
        class_lut_index = sigmoid_luts[class_sigmoid["name"]][0]
        softmax_lut_index = softmax_luts[dfl_softmax["name"]][0]
        weight_scale = float(dfl_conv["weight"]["scale"])
        conv_index = int(dfl_conv["conv_index"])

        class_args = []
        box_args = []
        for (name, scale), positions in zip(class_sources, class_positions):
            class_args.extend([tensor_ptr(name), str(positions), c_float(scale)])
        for (name, scale), positions in zip(box_sources, box_positions):
            box_args.extend([tensor_ptr(name), str(positions), c_float(scale)])
        stage4_class_call = (
            "  stage4_class_heads_i8(" + ", ".join(class_args) + ", "
            f"{tensor_ptr(class_logits_name)}, {tensor_ptr(class_name)}, "
            f"{c_float(class_concat_scale)}, yolov5nu_sigmoid_lut{class_lut_index}, "
            f"{c_float(class_scale)}, {c_float(args.nms_score_threshold)});"
        )
        stage4_dfl_call = (
            "  stage4_dfl_heads_i8(" + ", ".join(box_args) + ", "
            f"{tensor_ptr(box_concat_name)}, {tensor_ptr(dfl_name)}, "
            f"{c_float(box_concat_scale)}, {c_float(softmax_scale)}, "
            f"{c_float(weight_scale)}, {c_float(dfl_scale)}, yolov5nu_conv{conv_index}_weights, "
            f"yolov5nu_softmax_exp_lut{softmax_lut_index});"
        )
        stage4_skip_names = {
            *(op["name"] for op in box_reshapes),
            *(op["name"] for op in class_reshapes),
            "/model.24/Concat",
            "/model.24/Concat_1",
            "/model.24/dfl/Reshape",
            "/model.24/Sigmoid",
            "/model.24/dfl/Transpose",
            "/model.24/dfl/Softmax",
            "/model.24/dfl/conv/Conv",
            "/model.24/dfl/Reshape_1",
        }

    gemmini_direct_concat_by_mul: dict[str, dict[str, Any]] = {}
    if gemmini_lut and args.memory_stage == "5d":
        for concat in selected:
            if concat["op"] != "Concat" or concat["name"] in stage4_skip_names:
                continue
            if concat["name"] in splitk_concat_names:
                continue
            concat_name, concat_scale, concat_shape = output_q(concat)
            if not is_nhwc(concat_name):
                continue
            offset = 0
            for input_name in concat["inputs"]:
                if input_name not in dq:
                    continue
                input_tensor, input_scale = input_q(input_name)
                shape = tensor_shapes[input_tensor]
                channels = shape[1]
                producer = producer_by_tensor[input_tensor]
                effective_consumers = [
                    item for item in consumers.get(input_tensor, [])
                    if item["name"] not in fused_sigmoid_to_mul
                ]
                if args.stage8_mode not in {
                    "8a-materialized-control", "8a-materialized-cpuadd-control"
                } and (
                    producer["op"] == "Mul" and
                    producer["name"] in fused_mul_to_sigmoid and
                    len(effective_consumers) == 1 and
                    effective_consumers[0]["name"] == concat["name"] and
                    input_scale == concat_scale
                ):
                    gemmini_direct_concat_by_mul[producer["name"]] = {
                        "concat_name": concat_name,
                        "offset": offset,
                        "channels": channels,
                        "output_stride": concat_shape[1],
                    }
                offset += channels
        expected_direct_silu = 0 if args.stage8_mode in {
            "8a-materialized-control", "8a-materialized-cpuadd-control",
            "8c-dual-consumer-splitk", "8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"
        } else (
            1 if args.stage8_mode == "8c-single-consumer-splitk" else (
                5 if args.stage8_mode == "8c-backbone-splitk" else (
                    7 if args.stage8_mode in {"8c-model2", "8c-model2-alladds"} else 8
                )
            )
        )
        if len(gemmini_direct_concat_by_mul) != expected_direct_silu:
            raise ValueError(
                f"expected {expected_direct_silu} Gemmini SiLU direct-Concat candidates, "
                f"found {len(gemmini_direct_concat_by_mul)}"
            )

    calls: list[str] = []
    checkpoints: list[str] = []

    def add_checkpoint(statement: str) -> None:
        if args.diagnostic_layer_stats:
            calls.append(statement)
        else:
            checkpoints.append(statement)

    for serial, op in enumerate(selected):
        kind = op["op"]
        if (
            args.stage8_mode in {"8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"}
            and op["name"] in spad_reuse_second_consumers
        ):
            # The paired helper below computes this consumer while the two
            # input slices are still resident for the current spatial tile.
            continue
        if kind == "Sigmoid" and op["name"] in fused_sigmoid_to_mul:
            continue
        if op["name"] in stage4_skip_names:
            if op["name"] == stage4_inject_name:
                calls.append(
                    "  {\n"
                    "    uint64_t op_start = yolo_profile_begin(PROFILE_HEAD_CLASS, "
                    '"HEAD_CLASS", "location-major");\n'
                    f"{stage4_class_call}\n"
                    "    yolo_profile_add(PROFILE_HEAD_CLASS, \"HEAD_CLASS\", \"location-major\", "
                    "yolo_profile_clock() - op_start);\n"
                    "  }"
                )
                calls.append(
                    "  {\n"
                    "    uint64_t op_start = yolo_profile_begin(PROFILE_HEAD_DFL, "
                    '"HEAD_DFL", "location-major");\n'
                    f"{stage4_dfl_call}\n"
                    "    yolo_profile_add(PROFILE_HEAD_DFL, \"HEAD_DFL\", \"location-major\", "
                    "yolo_profile_clock() - op_start);\n"
                    "  }"
                )
            continue
        node = nodes[op["name"]]
        out_name, out_scale, out_shape = output_q(op)
        out = tensor_ids[out_name]
        checkpoint_out = out
        attrs = attributes(node)
        prefix = f"op{serial}"

        q_inputs: list[tuple[str, float]] = []
        for name in op["inputs"]:
            if name in dq:
                q_name, scale = input_q(name)
                if q_name in tensor_shapes:
                    q_inputs.append((tensor_ptr(q_name), scale))

        fused_silu = kind == "Mul" and op["name"] in fused_mul_to_sigmoid
        profile_kind = "PROFILE_SILU_FUSED_LUT" if fused_silu else {
            "Conv": "PROFILE_CONV_TOTAL",
            "Sigmoid": "PROFILE_SIGMOID",
            "Mul": "PROFILE_MUL",
            "Add": "PROFILE_ADD",
            "Concat": "PROFILE_CONCAT",
            "MaxPool": "PROFILE_MAXPOOL",
            "Resize": "PROFILE_RESIZE",
            "Reshape": "PROFILE_RESHAPE",
            "Transpose": "PROFILE_TRANSPOSE",
            "Softmax": "PROFILE_SOFTMAX",
        }.get(kind)
        profile_label = "SILU_FUSED_LUT" if fused_silu else kind
        if profile_kind is None:
            raise ValueError(f"no profiling category for {kind}")
        if fused_silu and gemmini_lut and op["name"] not in disabled_fused_silu_mul_names:
            lut_index = silu_luts[op["name"]][0]
            calls.append(
                f"  {{\n"
                f"    yolo_profile_add({profile_kind}, \"{profile_label}\", \"{op['name']}\", "
                f"silu_config_cycles[{lut_index}]);\n"
                f"  }}"
            )
            add_checkpoint(
                f"  print_checkpoint({serial}, \"{op['name']}\", {checkpoint_out}, {product(out_shape)});"
            )
            continue

        calls.append(
            f"  {{\n"
            f"    uint64_t op_start = yolo_profile_begin({profile_kind}, \"{profile_label}\", \"{op['name']}\");"
        )

        if kind == "Conv":
            in_q_name, in_scale = input_q(op["inputs"][0])
            inp = tensor_ptr(in_q_name)
            in_shape = tensor_shapes[in_q_name]
            weight_shape = op["weight"]["shape"]
            oc, ic, kh, kw = map(int, weight_shape)
            if int(attrs.get("group", 1)) != 1 or ic != in_shape[1]:
                raise ValueError(f"unsupported grouped Conv: {op['name']}")
            strides = list(attrs.get("strides", [1, 1]))
            dilations = list(attrs.get("dilations", [1, 1]))
            pads = list(attrs.get("pads", [0, 0, 0, 0]))
            if strides[0] != strides[1] or dilations != [1, 1] or pads[0] != pads[2] or pads[1] != pads[3] or pads[0] != pads[1]:
                raise ValueError(f"unsupported asymmetric Conv geometry: {op['name']}")
            weight_scale = float(op["weight"]["scale"])
            requant = in_scale * weight_scale / out_scale
            bias = f"yolov5nu_conv{op['conv_index']}_bias" if op.get("bias") else "NULL"
            hardware_silu = hardware_silu_by_conv.get(op["name"])
            conv_output = out
            conv_activation = "NO_ACTIVATION"
            if hardware_silu is not None:
                if not (is_nhwc(in_q_name) and is_nhwc(out_name)):
                    raise ValueError(f"first Gemmini SiLU version requires NHWC Conv: {op['name']}")
                lut_index = hardware_silu["lut_index"]
                conv_output = tensor_ids[hardware_silu["output_name"]]
                checkpoint_out = conv_output
                conv_activation = "SILU_LUT"
                calls.append(
                    f"\n    uint64_t silu_config_start = yolo_profile_clock();\n"
                    f"    gemmini_config_silu_lut(yolov5nu_silu_lut{lut_index});\n"
                    f"    gemmini_fence();\n"
                    f"    silu_config_cycles[{lut_index}] = yolo_profile_clock() - silu_config_start;\n"
                    f"    op_start = yolo_profile_clock();"
                )
            if is_nhwc(in_q_name) and is_nhwc(out_name):
                stage8c_split = (
                    op["name"] in splitk_conv_names
                )
                if stage8c_split:
                    concat_name_for_conv = splitk_concat_by_conv[op["name"]]
                    concat = selected_op(concat_name_for_conv)
                    slices = [input_q(name) for name in concat["inputs"]]
                    concat_name, concat_scale, concat_shape = output_q(concat)
                    slice_channels = [tensor_shapes[name][1] for name, _ in slices]
                    positions = concat_shape[0] * concat_shape[2] * concat_shape[3]
                    if (
                        in_q_name != concat_name or len(slices) not in {2, 4}
                        or len(set(slice_channels)) != 1
                        or sum(slice_channels) != ic or oc % 32 != 0
                        or [kh, kw] != [1, 1]
                        or strides != [1, 1] or pads != [0, 0, 0, 0]
                        or hardware_silu is None
                    ):
                        raise ValueError(f"unexpected split-K Conv geometry: {op['name']}")
                    marker = f"    /* STAGE8_SPLITK_CONCAT_CONV: {concat['name']} */\n"
                    if len(slices) == 2:
                        if op["name"] in spad_reuse_first_to_second:
                            second_name = spad_reuse_first_to_second[op["name"]]
                            second = selected_op(second_name)
                            second_hw_silu = hardware_silu_by_conv[second_name]
                            _, second_out_scale, _ = output_q(second)
                            second_out_name = second_hw_silu["output_name"]
                            second_bias = (
                                f"yolov5nu_conv{second['conv_index']}_bias"
                                if second.get("bias") else "NULL"
                            )
                            second_oc = int(second["weight"]["shape"][0])
                            second_requant = (
                                concat_scale * float(second["weight"]["scale"])
                                / second_out_scale
                            )
                            conv_call = (
                                marker
                                + f"    /* STAGE8_SPLITK_CONCAT_CONV: {concat['name']} consumer2 */\n"
                                + "    gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8("
                                f"{tensor_ptr(slices[0][0])}, {tensor_ptr(slices[1][0])}, "
                                f"yolov5nu_conv{op['conv_index']}_weights, {bias}, {conv_output}, "
                                f"yolov5nu_silu_lut{hardware_silu['lut_index']}, {oc}, "
                                f"{c_float(requant)}, "
                                f"yolov5nu_conv{second['conv_index']}_weights, {second_bias}, "
                                f"{tensor_ids[second_out_name]}, yolov5nu_silu_lut{second_hw_silu['lut_index']}, "
                                f"{second_oc}, {c_float(second_requant)}, "
                                f"{positions}, {slice_channels[0]}, "
                                f"{c_float(slices[0][1])}, {c_float(slices[1][1])}, "
                                f"{c_float(concat_scale)}, {conv_activation});"
                            )
                        else:
                            conv_call = (
                                marker
                                + f"    gemmini_splitk_1x1_two_slice_i8("
                                f"{tensor_ptr(slices[0][0])}, {tensor_ptr(slices[1][0])}, "
                                f"yolov5nu_conv{op['conv_index']}_weights, {bias}, {conv_output}, "
                                f"{positions}, {slice_channels[0]}, {oc}, {c_float(slices[0][1])}, "
                                f"{c_float(slices[1][1])}, {c_float(concat_scale)}, "
                                f"{conv_activation}, {c_float(requant)});"
                            )
                    else:
                        input_literals = ", ".join(
                            tensor_ptr(name) for name, _ in slices
                        )
                        scale_literals = ", ".join(
                            c_float(scale) for _, scale in slices
                        )
                        channel_literals = ", ".join(
                            str(channels) for channels in slice_channels
                        )
                        conv_call = (
                            marker
                            + f"    const elem_t *stage8_inputs[] = {{{input_literals}}};\n"
                            f"    const int stage8_channels[] = {{{channel_literals}}};\n"
                            f"    const float stage8_scales[] = {{{scale_literals}}};\n"
                            f"    gemmini_splitk_1x1_multi_slice_i8(stage8_inputs, "
                            f"stage8_channels, stage8_scales, {len(slices)}, "
                            f"yolov5nu_conv{op['conv_index']}_weights, {bias}, {conv_output}, "
                            f"{positions}, {oc}, {c_float(concat_scale)}, "
                            f"{conv_activation}, {c_float(requant)});"
                        )
                else:
                    direct_concat = None if hardware_silu is None else (
                        gemmini_direct_concat_by_mul.get(hardware_silu["mul"]["name"])
                    )
                    if direct_concat is not None:
                        conv_output = (
                            f"{tensor_ids[direct_concat['concat_name']]} + "
                            f"{direct_concat['offset']}"
                        )
                        conv_call = (
                            f"    /* GEMMINI_SILU_DIRECT_CONCAT: {hardware_silu['mul']['name']} */\n"
                            f"    tiled_conv_stride_auto({in_shape[0]}, {in_shape[2]}, {in_shape[3]}, {in_shape[1]}, "
                            f"{oc}, {out_shape[2]}, {out_shape[3]}, {strides[0]}, 1, 1, {pads[0]}, {kh}, "
                            f"{in_shape[1]}, {oc}, {direct_concat['output_stride']}, "
                            f"false, false, false, false, false, {inp}, "
                            f"yolov5nu_conv{op['conv_index']}_weights, {bias}, {conv_output}, "
                            f"{conv_activation}, {c_float(requant)}, 1, 0, 0, WS);"
                        )
                    else:
                        conv_call = (
                            f"    tiled_conv_auto({in_shape[0]}, {in_shape[2]}, {in_shape[3]}, {in_shape[1]}, "
                            f"{oc}, {out_shape[2]}, {out_shape[3]}, {strides[0]}, 1, 1, {pads[0]}, {kh}, "
                            f"false, false, false, false, false, {inp}, "
                            f"yolov5nu_conv{op['conv_index']}_weights, {bias}, {conv_output}, "
                            f"{conv_activation}, {c_float(requant)}, 1, 0, 0, WS);"
                        )
                calls.append(
                    f"\n    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, \"CONV_IN_LAYOUT\", \"{op['name']}\", 0);\n"
                    f"    uint64_t phase_start = yolo_profile_clock();\n"
                    f"{conv_call}\n"
                    f"    gemmini_fence();\n"
                    f"    yolo_profile_add(PROFILE_CONV_GEMMINI, \"CONV_GEMMINI\", \"{op['name']}\", yolo_profile_clock() - phase_start);\n"
                    f"    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, \"CONV_OUT_LAYOUT\", \"{op['name']}\", 0);"
                )
            elif not is_nhwc(in_q_name) and not is_nhwc(out_name):
                calls.append(
                    f"\n    uint64_t phase_start = yolo_profile_clock();\n"
                    f"    nchw_to_nhwc({inp}, conv_input_scratch, {in_shape[0]}, {in_shape[1]}, {in_shape[2]}, {in_shape[3]});\n"
                    f"    yolo_profile_add(PROFILE_CONV_IN_LAYOUT, \"CONV_IN_LAYOUT\", \"{op['name']}\", yolo_profile_clock() - phase_start);\n"
                    f"    phase_start = yolo_profile_clock();\n"
                    f"    tiled_conv_auto({in_shape[0]}, {in_shape[2]}, {in_shape[3]}, {in_shape[1]}, "
                    f"{oc}, {out_shape[2]}, {out_shape[3]}, {strides[0]}, 1, 1, {pads[0]}, {kh}, "
                    f"false, false, false, false, false, conv_input_scratch, "
                    f"yolov5nu_conv{op['conv_index']}_weights, {bias}, conv_output_scratch, "
                    f"NO_ACTIVATION, {c_float(requant)}, 1, 0, 0, WS);\n"
                    f"    gemmini_fence();\n"
                    f"    yolo_profile_add(PROFILE_CONV_GEMMINI, \"CONV_GEMMINI\", \"{op['name']}\", yolo_profile_clock() - phase_start);\n"
                    f"    phase_start = yolo_profile_clock();\n"
                    f"    nhwc_to_nchw(conv_output_scratch, {out}, {out_shape[0]}, {out_shape[1]}, {out_shape[2]}, {out_shape[3]});\n"
                    f"    yolo_profile_add(PROFILE_CONV_OUT_LAYOUT, \"CONV_OUT_LAYOUT\", \"{op['name']}\", yolo_profile_clock() - phase_start);"
                )
            else:
                raise ValueError(
                    f"Conv crosses an unsupported physical-layout boundary: {op['name']} "
                    f"{tensor_layout(in_q_name)} -> {tensor_layout(out_name)}"
                )
        elif kind == "Sigmoid":
            inp, _ = q_inputs[0]
            in_q_name, _ = input_q(op["inputs"][0])
            if tensor_layout(in_q_name) != tensor_layout(out_name):
                raise ValueError(f"Sigmoid layout mismatch: {op['name']}")
            lut_index = sigmoid_luts[op["name"]][0]
            calls.append(f"  sigmoid_i8({inp}, {out}, {product(out_shape)}, yolov5nu_sigmoid_lut{lut_index});")
        elif kind in {"Mul", "Add"}:
            if len(q_inputs) != 2:
                raise ValueError(f"unsupported pre-DFL broadcast {kind}: {op['name']}")
            (left, left_scale), (right, right_scale) = q_inputs
            input_layouts = [tensor_layout(input_q(name)[0]) for name in op["inputs"] if name in dq]
            if any(layout != tensor_layout(out_name) for layout in input_layouts):
                raise ValueError(f"{kind} layout mismatch: {op['name']}")
            if kind == "Mul":
                if fused_silu:
                    sigmoid = fused_mul_to_sigmoid[op["name"]]
                    fused_input_name, fused_input_scale = input_q(sigmoid["inputs"][0])
                    _, sigmoid_scale, _ = output_q(sigmoid)
                    if args.silu_kernel == "opencv-rvv":
                        calls.append(
                            f"  opencv_rvv_silu_two_step_i8({tensor_ptr(fused_input_name)}, {out}, "
                            f"{product(out_shape)}, {c_float(fused_input_scale)}, "
                            f"{c_float(sigmoid_scale)}, {c_float(out_scale)});"
                        )
                    else:
                        lut_index = silu_luts[op["name"]][0]
                        calls.append(
                            f"  silu_lut_i8({tensor_ptr(fused_input_name)}, {out}, {product(out_shape)}, "
                            f"yolov5nu_silu_lut{lut_index});"
                        )
                else:
                    calls.append(f"  mul_i8({left}, {right}, {out}, {product(out_shape)}, {c_float(left_scale)}, {c_float(right_scale)}, {c_float(out_scale)});")
            else:
                shared_stage8_add = (
                    args.stage8_mode in {
                        "8b", "8c-model2", "8c-dual-consumer-splitk",
                        "8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"
                    }
                    and op["name"] == args.stage8_add_name
                ) or (
                    args.stage8_mode in {
                        "8a-materialized-control", "8c-model2-alladds", "8c-backbone-splitk",
                        "8c-single-consumer-splitk", "8c-dual-consumer-splitk",
                        "8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge",
                    }
                    and op["name"] in {
                        "/model.2/m/m.0/Add",
                        "/model.4/m/m.0/Add", "/model.4/m/m.1/Add",
                        "/model.6/m/m.0/Add", "/model.6/m/m.1/Add",
                        "/model.6/m/m.2/Add", "/model.8/m/m.0/Add",
                    }
                )
                if shared_stage8_add:
                    if left_scale != right_scale:
                        raise ValueError(
                            f"Stage 8 shared Add scales differ: {op['name']} "
                            f"{left_scale} != {right_scale}"
                        )
                    positions = out_shape[0] * out_shape[2] * out_shape[3]
                    channels = out_shape[1]
                    calls.append(
                        f"  add_gemmini_shared_resadd_i8({left}, {right}, {out}, "
                        f"{positions}, {channels}, {c_float(left_scale / out_scale)});"
                    )
                elif stage3_kernels["add"] == "rvv-ratio":
                    if args.stage7_mode == "7d":
                        positions = out_shape[0] * out_shape[2] * out_shape[3]
                        channels = out_shape[1]
                        calls.append(
                            f"  add_gemmini_resadd_i8({left}, {right}, {out}, "
                            f"{positions}, {channels}, {c_float(left_scale / out_scale)}, "
                            f"{c_float(right_scale / out_scale)});"
                        )
                    elif args.stage7_mode == "7e":
                        a_ratio = left_scale / out_scale
                        b_ratio = right_scale / out_scale
                        calls.append(
                            f"  add_fixed_i8({left}, {right}, {out}, {product(out_shape)}, "
                            f"{c_float(a_ratio)}, {c_float(b_ratio)}, "
                            f"{fixed_multiplier(a_ratio)}, {fixed_multiplier(b_ratio)});"
                        )
                    else:
                        calls.append(
                            f"  add_ratio_i8({left}, {right}, {out}, {product(out_shape)}, "
                            f"{c_float(left_scale / out_scale)}, {c_float(right_scale / out_scale)});"
                        )
                else:
                    calls.append(f"  add_i8({left}, {right}, {out}, {product(out_shape)}, {c_float(left_scale)}, {c_float(right_scale)}, {c_float(out_scale)});")
        elif kind == "Concat":
            axis = int(attrs["axis"])
            rank = len(out_shape)
            if axis < 0:
                axis += rank
            if op["name"] in splitk_concat_names:
                calls.append(f"  /* STAGE8_CONCAT_ELIDED: {op['name']} */")
            if is_nhwc(out_name):
                if op["name"] in splitk_concat_names:
                    pass
                elif axis != 1 or rank != 4:
                    raise ValueError(f"NHWC Concat must be rank-4 channel concat: {op['name']}")
                else:
                    positions = out_shape[0] * out_shape[2] * out_shape[3]
                    calls.append(f"  /* NHWC channel Concat: {op['name']} */")
                    if args.stage7_mode not in {"7c", "7bc", "7e"}:
                        calls.append(f"  for (int position = 0; position < {positions}; position++) {{")
                    out_axis_offset = 0
                    for input_name in op["inputs"]:
                        q_name, in_scale = input_q(input_name)
                        if not is_nhwc(q_name):
                            raise ValueError(f"NHWC Concat input is not NHWC: {op['name']}")
                        inp = tensor_ptr(q_name)
                        channels = tensor_shapes[q_name][1]
                        if args.stage7_mode in {"7c", "7bc", "7e"}:
                            calls.append(
                                f"  concat_nhwc_slice_strided_i8({inp}, "
                                f"{out} + {out_axis_offset}, {positions}, {channels}, "
                                f"{out_shape[1]}, {c_float(in_scale)}, {c_float(out_scale)});"
                            )
                        else:
                            calls.append(
                                f"    requant_copy({inp} + position * {channels}, "
                                f"{out} + position * {out_shape[1]} + {out_axis_offset}, {channels}, "
                                f"{c_float(in_scale)}, {c_float(out_scale)});"
                            )
                        out_axis_offset += channels
                    if args.stage7_mode not in {"7c", "7bc", "7e"}:
                        calls.append("  }")
            else:
                outer = product(out_shape[:axis])
                inner = product(out_shape[axis + 1:])
                calls.append(f"  /* logical-layout Concat: {op['name']} */")
                calls.append(f"  for (int outer = 0; outer < {outer}; outer++) {{")
                out_axis_offset = 0
                for input_name in op["inputs"]:
                    q_name, in_scale = input_q(input_name)
                    if is_nhwc(q_name):
                        raise ValueError(f"logical Concat input is NHWC: {op['name']}")
                    inp = tensor_ptr(q_name)
                    in_shape = tensor_shapes[q_name]
                    axis_size = in_shape[axis]
                    block = axis_size * inner
                    calls.append(
                        f"    requant_copy({inp} + outer * {block}, {out} + outer * {out_shape[axis] * inner} + {out_axis_offset * inner}, "
                        f"{block}, {c_float(in_scale)}, {c_float(out_scale)});"
                    )
                    out_axis_offset += axis_size
                calls.append("  }")
        elif kind == "MaxPool":
            inp, in_scale = q_inputs[0]
            in_q_name, _ = input_q(op["inputs"][0])
            in_shape = tensor_shapes[in_q_name]
            kernels = list(attrs["kernel_shape"])
            strides = list(attrs.get("strides", [1, 1]))
            pads = list(attrs.get("pads", [0, 0, 0, 0]))
            if is_nhwc(in_q_name) and is_nhwc(out_name):
                calls.append(
                    f"  maxpool_nhwc_i8({inp}, {out}, {in_shape[0]}, {in_shape[1]}, {in_shape[2]}, {in_shape[3]}, "
                    f"{out_shape[2]}, {out_shape[3]}, {kernels[0]}, {kernels[1]}, {strides[0]}, {strides[1]}, "
                    f"{pads[0]}, {pads[1]}, {c_float(in_scale)}, {c_float(out_scale)});"
                )
            elif not is_nhwc(in_q_name) and not is_nhwc(out_name):
                calls.append(
                    f"  maxpool_nchw_i8({inp}, {out}, {in_shape[0]}, {in_shape[1]}, {in_shape[2]}, {in_shape[3]}, "
                    f"{out_shape[2]}, {out_shape[3]}, {kernels[0]}, {kernels[1]}, {strides[0]}, {strides[1]}, "
                    f"{pads[0]}, {pads[1]}, {c_float(in_scale)}, {c_float(out_scale)});"
                )
            else:
                raise ValueError(f"MaxPool layout mismatch: {op['name']}")
        elif kind == "Resize":
            inp, in_scale = q_inputs[0]
            in_q_name, _ = input_q(op["inputs"][0])
            in_shape = tensor_shapes[in_q_name]
            if is_nhwc(in_q_name) and is_nhwc(out_name):
                calls.append(
                    f"  resize_nearest_nhwc_i8({inp}, {out}, {in_shape[0]}, {in_shape[1]}, {in_shape[2]}, {in_shape[3]}, "
                    f"{out_shape[2]}, {out_shape[3]}, {c_float(in_scale)}, {c_float(out_scale)});"
                )
            elif not is_nhwc(in_q_name) and not is_nhwc(out_name):
                calls.append(
                    f"  resize_nearest_nchw_i8({inp}, {out}, {in_shape[0]}, {in_shape[1]}, {in_shape[2]}, {in_shape[3]}, "
                    f"{out_shape[2]}, {out_shape[3]}, {c_float(in_scale)}, {c_float(out_scale)});"
                )
            else:
                raise ValueError(f"Resize layout mismatch: {op['name']}")
        elif kind == "Reshape":
            inp, in_scale = q_inputs[0]
            in_q_name, _ = input_q(op["inputs"][0])
            in_shape = tensor_shapes[in_q_name]
            if is_nhwc(in_q_name) and not is_nhwc(out_name):
                if len(in_shape) != 4 or len(out_shape) != 3 or out_shape != [in_shape[0], in_shape[1], in_shape[2] * in_shape[3]]:
                    raise ValueError(f"unsupported NHWC Reshape boundary: {op['name']}")
                calls.append(
                    f"  nhwc_to_ncl_i8({inp}, {out}, {in_shape[0]}, {in_shape[1]}, {in_shape[2]}, {in_shape[3]}, "
                    f"{c_float(in_scale)}, {c_float(out_scale)});"
                )
            elif not is_nhwc(in_q_name) and not is_nhwc(out_name):
                calls.append(f"  requant_copy({inp}, {out}, {product(out_shape)}, {c_float(in_scale)}, {c_float(out_scale)});")
            else:
                raise ValueError(f"unsupported Reshape layout transition: {op['name']}")
        elif kind == "Transpose":
            inp, in_scale = q_inputs[0]
            in_q_name, _ = input_q(op["inputs"][0])
            if is_nhwc(in_q_name) or is_nhwc(out_name):
                raise ValueError(f"DFL Transpose must stay in logical layout: {op['name']}")
            in_shape = tensor_shapes[in_q_name]
            perm = list(attrs["perm"])
            if len(in_shape) != 4:
                raise ValueError("only rank-4 Transpose is supported")
            calls.append(
                f"  transpose4_i8({inp}, {out}, {in_shape[0]}, {in_shape[1]}, {in_shape[2]}, {in_shape[3]}, "
                f"{perm[0]}, {perm[1]}, {perm[2]}, {perm[3]}, {c_float(in_scale)}, {c_float(out_scale)});"
            )
        elif kind == "Softmax":
            inp, in_scale = q_inputs[0]
            in_q_name, _ = input_q(op["inputs"][0])
            if is_nhwc(in_q_name) or is_nhwc(out_name):
                raise ValueError(f"DFL Softmax must stay in logical layout: {op['name']}")
            axis = int(attrs.get("axis", -1))
            if axis < 0:
                axis += len(out_shape)
            outer = product(out_shape[:axis])
            axis_size = out_shape[axis]
            inner = product(out_shape[axis + 1:])
            lut_index = softmax_luts[op["name"]][0]
            calls.append(
                f"  softmax_i8({inp}, {out}, {outer}, {axis_size}, {inner}, {c_float(out_scale)}, yolov5nu_softmax_exp_lut{lut_index});"
            )
        else:
            raise ValueError(f"unexpected op before fixed decode: {kind} {op['name']}")

        calls.append(
            f"\n    yolo_profile_add({profile_kind}, \"{profile_label}\", \"{op['name']}\", yolo_profile_clock() - op_start);\n"
            f"  }}"
        )
        add_checkpoint(
            f"  print_checkpoint({serial}, \"{op['name']}\", {checkpoint_out}, {product(out_shape)});"
        )

    memory_rank = {"none": 0, "5a": 1, "5b": 2, "5c": 3, "5d": 4}[args.memory_stage]
    tensor_aliases: dict[str, str] = {}
    direct_concat_outputs: set[str] = set()
    direct_concat_records: list[dict[str, Any]] = []

    def resolve_alias(name: str) -> str:
        while name in tensor_aliases:
            name = tensor_aliases[name]
        return name

    def replace_tensor_identifier(old: str, new: str) -> None:
        pattern = re.compile(rf"\b{re.escape(old)}\b")
        for index in range(len(calls)):
            calls[index] = pattern.sub(new, calls[index])
        for index in range(len(checkpoints)):
            checkpoints[index] = pattern.sub(new, checkpoints[index])

    if memory_rank >= 4:
        for concat in selected:
            if concat["op"] != "Concat" or concat["name"] in stage4_skip_names:
                continue
            if concat["name"] in splitk_concat_names:
                continue
            concat_name, concat_scale, concat_shape = output_q(concat)
            if not is_nhwc(concat_name):
                continue
            offset = 0
            for input_name in concat["inputs"]:
                if input_name not in dq:
                    continue
                input_tensor, input_scale = input_q(input_name)
                shape = tensor_shapes[input_tensor]
                channels = shape[1]
                positions = shape[0] * shape[2] * shape[3]
                producer = producer_by_tensor[input_tensor]
                effective_consumers = [
                    item for item in consumers.get(input_tensor, [])
                    if item["name"] not in fused_sigmoid_to_mul
                ]
                stage7_direct_producer = (
                    args.stage7_mode in {"7a", "7b", "7b-lut", "7b-register", "7bc", "7e"} and
                    input_scale == concat_scale and
                    producer["op"] in {"MaxPool", "Resize"}
                )
                stage7_fused_add = (
                    args.stage7_mode in {"7b", "7b-lut", "7b-register", "7bc", "7e"}
                    and producer["op"] == "Add"
                    and not (
                        args.stage8_mode in {"8b", "8c-model2"}
                        and producer["name"] == args.stage8_add_name
                    )
                )
                direct = (
                    len(effective_consumers) == 1 and
                    effective_consumers[0]["name"] == concat["name"] and
                    ((input_scale == concat_scale and
                      (producer["op"] == "Add" or
                       (producer["op"] == "Mul" and
                        producer["name"] in fused_mul_to_sigmoid))) or
                     stage7_direct_producer or stage7_fused_add)
                    and (producer["op"] == "Add" or
                         stage7_direct_producer or
                         (producer["op"] == "Mul" and
                          producer["name"] in fused_mul_to_sigmoid))
                )
                if args.stage8_mode in {
                    "8c-model2-alladds", "8c-backbone-splitk",
                    "8c-single-consumer-splitk",
                    "8c-dual-consumer-splitk", "8f-dual-consumer-spad-reuse",
                    "8h-splitk-config-fence-merge",
                } and producer["op"] == "Add":
                    direct = False
                if args.stage8_mode in {"8c-dual-consumer-splitk", "8f-dual-consumer-spad-reuse", "8h-splitk-config-fence-merge"} and concat["name"] in {
                    "/model.12/Concat", "/model.16/Concat",
                    "/model.19/Concat", "/model.22/Concat",
                }:
                    direct = False
                if args.stage8_mode == "8a-materialized-control":
                    direct = False
                if args.stage8_mode == "8a-materialized-cpuadd-control":
                    direct = False
                if direct:
                    source_id = tensor_ids[input_tensor]
                    destination = f"{tensor_ids[concat_name]} + {offset}"
                    gemmini_silu_direct = (
                        gemmini_lut and producer["op"] == "Mul" and
                        producer["name"] in gemmini_direct_concat_by_mul
                    )
                    if producer["op"] in {"MaxPool", "Resize"}:
                        function_name = (
                            "maxpool_nhwc_i8" if producer["op"] == "MaxPool"
                            else "resize_nearest_nhwc_i8"
                        )
                        producer_index = next(
                            i for i, call in enumerate(calls)
                            if f"{function_name}(" in call and source_id in call
                        )
                        calls[producer_index] = calls[producer_index].replace(
                            f"{function_name}(", f"{function_name}_strided(", 1
                        )
                        calls[producer_index] = calls[producer_index].replace(
                            f", {c_float(concat_scale)});",
                            f", {c_float(concat_scale)}, {concat_shape[1]});",
                            1,
                        )
                        calls[producer_index] = calls[producer_index].replace(
                            f", {source_id},", f", {destination},", 1
                        )
                        count = 1
                    elif gemmini_silu_direct:
                        marker = f"GEMMINI_SILU_DIRECT_CONCAT: {producer['name']}"
                        producer_index = next(
                            i for i, call in enumerate(calls) if marker in call
                        )
                    else:
                        producer_index = next(
                            i for i, call in enumerate(calls)
                            if source_id in call and (
                                "silu_lut_i8(" in call or "add_ratio_i8(" in call or
                                "add_gemmini_resadd_i8(" in call or "add_fixed_i8(" in call
                            )
                        )
                    concat_index = next(
                        i for i, call in enumerate(calls)
                        if source_id in call and (
                            "requant_copy(" in call or
                            "concat_nhwc_slice_strided_i8(" in call
                        )
                    )
                    if gemmini_silu_direct or producer["op"] in {"MaxPool", "Resize"}:
                        count = 1
                    elif producer["op"] == "Mul":
                        pattern = re.compile(
                            rf"silu_lut_i8\(([^,]+), {re.escape(source_id)}, {positions * channels}, ([^)]+)\);"
                        )
                        replacement = (
                            rf"silu_lut_i8_strided(\1, {destination}, {positions}, "
                            rf"{channels}, {concat_shape[1]}, \2);"
                        )
                    else:
                        if args.stage7_mode == "7d":
                            pattern = re.compile(
                                rf"add_gemmini_resadd_i8\(([^,]+), ([^,]+), "
                                rf"{re.escape(source_id)}, {positions}, {channels}, "
                                rf"([^,]+), ([^)]+)\);"
                            )
                            replacement = (
                                rf"add_gemmini_resadd_strided_i8(\1, \2, {destination}, "
                                rf"{positions}, {channels}, {concat_shape[1]}, \3, \4);"
                            )
                        elif args.stage7_mode == "7e":
                            pattern = re.compile(
                                rf"add_fixed_i8\(([^,]+), ([^,]+), {re.escape(source_id)}, "
                                rf"{positions * channels}, ([^,]+), ([^,]+), ([^,]+), ([^)]+)\);"
                            )
                        else:
                            pattern = re.compile(
                                rf"add_ratio_i8\(([^,]+), ([^,]+), {re.escape(source_id)}, "
                                rf"{positions * channels}, ([^,]+), ([^)]+)\);"
                            )
                        if args.stage7_mode == "7d":
                            pass
                        elif args.stage7_mode in {"7b", "7b-lut", "7b-register", "7bc", "7e"} and input_scale != concat_scale:
                            left_scale = input_q(producer["inputs"][0])[1]
                            right_scale = input_q(producer["inputs"][1])[1]
                            add_scale = output_q(producer)[1]
                            if args.stage7_mode in {"7b-lut", "7b-register", "7bc", "7e"}:
                                lut_index = add_requant_lut_by_producer[producer["name"]]
                                if args.stage7_mode in {"7e"}:
                                    function_name = "add_two_step_register_fixed_i8_strided"
                                    replacement = (
                                        rf"{function_name}(\1, \2, {destination}, "
                                        rf"{positions}, {channels}, {concat_shape[1]}, "
                                        rf"{fixed_multiplier(left_scale / add_scale)}, "
                                        rf"{fixed_multiplier(right_scale / add_scale)}, "
                                        rf"yolov5nu_add_requant_lut{lut_index});"
                                    )
                                else:
                                    function_name = (
                                        "add_two_step_register_i8_strided"
                                        if args.stage7_mode in {"7b-register", "7bc"}
                                        else "add_two_step_lut_i8_strided"
                                    )
                                    replacement = (
                                        rf"{function_name}(\1, \2, {destination}, "
                                        rf"{positions}, {channels}, {concat_shape[1]}, "
                                        rf"{c_float(left_scale)}, {c_float(right_scale)}, "
                                        rf"{c_float(add_scale)}, {c_float(concat_scale)}, "
                                        rf"yolov5nu_add_requant_lut{lut_index});"
                                    )
                            else:
                                replacement = (
                                    rf"add_two_step_i8_strided(\1, \2, {destination}, {positions}, "
                                    rf"{channels}, {concat_shape[1]}, {c_float(left_scale)}, "
                                    rf"{c_float(right_scale)}, {c_float(add_scale)}, "
                                    rf"{c_float(concat_scale)});"
                                )
                        else:
                            if args.stage7_mode == "7e":
                                left_scale = input_q(producer["inputs"][0])[1]
                                right_scale = input_q(producer["inputs"][1])[1]
                                replacement = (
                                    rf"add_fixed_i8_strided(\1, \2, {destination}, {positions}, "
                                    rf"{channels}, {concat_shape[1]}, \3, \4, "
                                    rf"{fixed_multiplier(left_scale / concat_scale)}, "
                                    rf"{fixed_multiplier(right_scale / concat_scale)});"
                                )
                            else:
                                replacement = (
                                    rf"add_ratio_i8_strided(\1, \2, {destination}, {positions}, "
                                    rf"{channels}, {concat_shape[1]}, \3, \4);"
                                )
                    if (not gemmini_silu_direct and
                            producer["op"] not in {"MaxPool", "Resize"}):
                        calls[producer_index], count = pattern.subn(
                            replacement, calls[producer_index]
                        )
                    if count != 1:
                        raise ValueError(f"failed to direct-write {producer['name']} into {concat['name']}")
                    concat_lines = calls[concat_index].splitlines()
                    concat_lines = [line for line in concat_lines if source_id not in line]
                    calls[concat_index] = "\n".join(concat_lines)
                    direct_concat_outputs.add(input_tensor)
                    direct_concat_records.append({
                        "producer": producer["name"],
                        "tensor": input_tensor,
                        "concat": concat["name"],
                        "offset": offset,
                        "channels": channels,
                        "output_stride": concat_shape[1],
                    })
                offset += channels

    inplace_records: list[dict[str, str]] = []
    if memory_rank >= 3:
        for op in selected:
            if op["name"] in stage4_skip_names:
                continue
            output_name, _, output_shape = output_q(op)
            if output_name in direct_concat_outputs:
                continue
            eligible = op["op"] == "Add" or (not gemmini_lut and
                op["op"] == "Mul" and op["name"] in fused_mul_to_sigmoid
            )
            if not eligible:
                continue
            output_id = tensor_ids[output_name]
            output_occurrences = [
                i for i, call in enumerate(calls)
                if re.search(rf"\b{re.escape(output_id)}\b", call)
            ]
            if not output_occurrences:
                continue
            call_index = min(output_occurrences)
            if op["op"] == "Mul":
                sigmoid = fused_mul_to_sigmoid[op["name"]]
                candidates = [input_q(sigmoid["inputs"][0])[0]]
            else:
                candidates = [input_q(name)[0] for name in op["inputs"] if name in dq]
            for candidate in candidates:
                root = resolve_alias(candidate)
                root_id = tensor_ids[root]
                occurrences = [i for i, call in enumerate(calls) if re.search(rf"\b{re.escape(root_id)}\b", call)]
                if not occurrences or max(occurrences) != call_index:
                    continue
                if product(output_shape) > product(tensor_shapes[root]):
                    continue
                replace_tensor_identifier(output_id, root_id)
                tensor_aliases[output_name] = root
                inplace_records.append({
                    "operator": op["name"],
                    "output": output_name,
                    "input": root,
                })
                break

    if memory_rank > 0:
        if not args.diagnostic_layer_stats:
            checkpoints = []
        id_to_name = {identifier: name for name, identifier in tensor_ids.items()}
        intervals: dict[str, tuple[int, int]] = {}
        for call_index, call in enumerate(calls):
            for identifier in set(re.findall(r"\btensor_\d+\b", call)):
                name = resolve_alias(id_to_name[identifier])
                birth, death = intervals.get(name, (call_index, call_index))
                intervals[name] = (min(birth, call_index), max(death, call_index))

        final_names = [class_logits_name, class_name, dfl_name]
        final_step = len(calls)
        for name in final_names:
            root = resolve_alias(name)
            if root in intervals:
                intervals[root] = (intervals[root][0], final_step)

        group_members: dict[str, list[str]] = {}
        for name in tensor_shapes:
            if name == input_q_name:
                continue
            group_members.setdefault(resolve_alias(name), []).append(name)
        sizes = {
            root: max(product(tensor_shapes[name]) for name in members)
            for root, members in group_members.items() if root in intervals
        }
        offsets, arena_elems = allocate_arena(intervals, sizes, 32)
        declarations = [f"static elem_t activation_arena[{arena_elems}] row_align(1);"]
        allocated_names: set[str] = set()
        inactive_names = sorted(
            name for name in tensor_shapes
            if name != input_q_name and resolve_alias(name) not in intervals
        )
        for name in tensor_shapes:
            if name == input_q_name:
                continue
            root = resolve_alias(name)
            if root not in offsets and memory_rank != 1:
                continue
            offset = offsets.get(root, 0)
            declarations.append(
                f"#define {tensor_ids[name]} (activation_arena + {offset})"
            )
            allocated_names.add(name)

        for left, (left_birth, left_death) in intervals.items():
            for right, (right_birth, right_death) in intervals.items():
                if left >= right or left_death < right_birth or right_death < left_birth:
                    continue
                left_range = (offsets[left], offsets[left] + sizes[left])
                right_range = (offsets[right], offsets[right] + sizes[right])
                if max(left_range[0], right_range[0]) < min(left_range[1], right_range[1]):
                    raise ValueError(f"arena overlap: {left} {left_range} and {right} {right_range}")

        dead_names = [] if memory_rank == 1 else inactive_names
        total_elems = sum(product(shape) for name, shape in tensor_shapes.items() if name != input_q_name)
        memory_report = {
            "format": "yolov5nu-static-memory-plan-v1",
            "stage": args.memory_stage,
            "alignment_elements": 32,
            "original_tensor_elements": total_elems,
            "arena_elements": arena_elems,
            "arena_bytes": arena_elems,
            "reduction_percent": 100.0 * (1.0 - arena_elems / total_elems),
            "allocated_tensors": len(allocated_names),
            "dead_tensors": dead_names,
            "inactive_tensors": inactive_names,
            "reshape_views": [],
            "inplace": inplace_records,
            "direct_concat": direct_concat_records,
            "tensors": [
                {
                    "name": name,
                    "root": root,
                    "offset": offsets[root],
                    "size": product(tensor_shapes[name]),
                    "root_size": sizes[root],
                    "birth": intervals[root][0],
                    "last_use": intervals[root][1],
                }
                for name in sorted(allocated_names)
                for root in [resolve_alias(name)]
                if root in offsets
            ],
        }
        memory_path = args.output_dir / f"{args.stem}_memory.json"
        memory_path.write_text(json.dumps(memory_report, indent=2) + "\n")
    else:
        memory_report = None

    dfl_op = next(op for op in selected if op["name"] == "/model.24/dfl/Reshape_1")
    dfl_name, dfl_scale, _ = output_q(dfl_op)
    class_logits_op = next(op for op in selected if op["name"] == "/model.24/Concat_1")
    class_logits_name, _, class_logits_shape = output_q(class_logits_op)
    class_op = next(op for op in selected if op["name"] == "/model.24/Sigmoid")
    class_name, class_scale, _ = output_q(class_op)

    if args.silu_kernel in {"opencv-rvv", "gemmini-lut"} and \
            args.disable_fused_silu_conv is None:
        silu_lut_impl = ""
    elif args.silu_kernel == "scalar" or args.disable_fused_silu_conv is not None:
        silu_lut_impl = """static void silu_lut_i8(const elem_t *src, elem_t *dst, int count,
    const elem_t lut[256]) {
  for (int i = 0; i < count; i++) dst[i] = lut[(uint8_t)src[i]];
}"""
    else:
        rvv_function = f"yolov5nu_silu_lut_{args.silu_kernel.replace('-', '_')}"
        silu_lut_impl = f"""static void silu_lut_scalar_i8(const elem_t *src, elem_t *dst, int count,
    const elem_t lut[256]) {{
  for (int i = 0; i < count; i++) dst[i] = lut[(uint8_t)src[i]];
}}

static void silu_lut_i8(const elem_t *src, elem_t *dst, int count,
    const elem_t lut[256]) {{
#ifdef __riscv_vector
  {rvv_function}(src, dst, (uintptr_t)count, lut);
#else
  silu_lut_scalar_i8(src, dst, count, lut);
#endif
}}"""

    source = f'''#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "include/gemmini.h"
#include "include/gemmini_nn.h"
#include "include/yolov5nu_silu_opencv_rvv.h"
#include "include/yolov5nu_silu_lut_rvv.h"
#include "include/yolov5nu_stage3_rvv.h"
#include "include/yolov5nu_stage4_rvv.h"
#include "{header_path.name}"

#ifndef YOLOV5NU_LAYER_STATS
#define YOLOV5NU_LAYER_STATS 0
#endif

#ifndef YOLOV5NU_FINAL_TENSOR_STATS
#define YOLOV5NU_FINAL_TENSOR_STATS 1
#endif

#ifndef YOLOV5NU_PROFILE
#define YOLOV5NU_PROFILE 0
#endif

#if defined(YOLOV5NU_MEMORY_STAGE_5A) || defined(YOLOV5NU_MEMORY_STAGE_5B) || \
    defined(YOLOV5NU_MEMORY_STAGE_5C) || defined(YOLOV5NU_MEMORY_STAGE_5D)
#if YOLOV5NU_LAYER_STATS && !defined(YOLOV5NU_DIAGNOSTIC_LAYER_STATS)
#error "Stage 5 arena planning requires YOLOV5NU_LAYER_STATS=0"
#endif
#endif

enum YoloProfileKind {{
  PROFILE_CONV_TOTAL,
  PROFILE_SIGMOID,
  PROFILE_MUL,
  PROFILE_SILU_FUSED_LUT,
  PROFILE_ADD,
  PROFILE_CONCAT,
  PROFILE_MAXPOOL,
  PROFILE_RESIZE,
  PROFILE_RESHAPE,
  PROFILE_TRANSPOSE,
  PROFILE_SOFTMAX,
  PROFILE_HEAD_CLASS,
  PROFILE_HEAD_DFL,
  PROFILE_CONV_IN_LAYOUT,
  PROFILE_CONV_GEMMINI,
  PROFILE_CONV_OUT_LAYOUT,
  PROFILE_DECODE,
  PROFILE_NMS,
  PROFILE_KIND_COUNT
}};

struct YoloProfileRecord {{
  int kind;
  const char *kind_name;
  const char *name;
  uint64_t cycles;
}};

#if YOLOV5NU_PROFILE
#define YOLOV5NU_PROFILE_MAX_RECORDS 512
static struct YoloProfileRecord yolo_profile_records[YOLOV5NU_PROFILE_MAX_RECORDS];
static int yolo_profile_record_count;

static inline void yolo_profile_reset(void) {{
  yolo_profile_record_count = 0;
}}

static inline uint64_t yolo_profile_clock(void) {{
  uint64_t value;
  asm volatile("rdcycle %0" : "=r"(value));
  return value;
}}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {{
  (void)kind; (void)kind_name; (void)name;
  return yolo_profile_clock();
}}

static void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {{
  if (yolo_profile_record_count < YOLOV5NU_PROFILE_MAX_RECORDS) {{
    yolo_profile_records[yolo_profile_record_count++] = (struct YoloProfileRecord){{
      kind, kind_name, name, cycles
    }};
  }}
}}
#else
static inline void yolo_profile_reset(void) {{}}

static inline uint64_t yolo_profile_clock(void) {{
  return 0;
}}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {{
  (void)kind; (void)kind_name; (void)name;
  return 0;
}}
static inline void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {{
  (void)kind; (void)kind_name; (void)name; (void)cycles;
}}
#endif

static uint64_t head_class_requant_cycles;
static uint64_t head_class_sigmoid_cycles;
static uint64_t head_dfl_requant_cycles;
static uint64_t head_dfl_core_cycles;
static int head_dfl_rvv_enabled;
static int head_dfl_batch_enabled;
static int head_dfl_ordered_sum_enabled;
static int head_dfl_gather_enabled;
static int head_dfl_elementwise_sum_enabled;
static int head_dfl_unordered_sum_enabled;
static int head_dfl_interleaved_sum_enabled;
static int head_dfl_sparse_enabled;
static int head_dfl_candidate_count;
static uint64_t head_dfl_candidate_cycles;
static uint64_t head_class_candidate_cycles;
static int head_dfl_candidate_rvv_enabled;

{chr(10).join(declarations)}
static elem_t conv_input_scratch[YOLOV5NU_CONV_INPUT_SCRATCH] row_align(1);
static elem_t conv_output_scratch[YOLOV5NU_CONV_OUTPUT_SCRATCH] row_align(1);
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
static uint8_t dfl_candidate_mask[{total_head_positions}];
#endif

static inline int round_nearest_even(float value) {{
  int base = (int)value;
  float fraction = value - (float)base;
  if (fraction > 0.5f || (fraction == 0.5f && (base & 1))) base++;
  if (fraction < -0.5f || (fraction == -0.5f && (base & 1))) base--;
  return base;
}}

static inline elem_t quantize_float(float value, float scale) {{
  int value_i = round_nearest_even(value / scale);
  if (value_i > 127) value_i = 127;
  if (value_i < -128) value_i = -128;
  return (elem_t)value_i;
}}

static void nchw_to_nhwc(const elem_t *src, elem_t *dst, int n, int c, int h, int w) {{
  for (int bn = 0; bn < n; bn++)
    for (int y = 0; y < h; y++)
      for (int x = 0; x < w; x++)
        for (int ch = 0; ch < c; ch++)
          dst[((bn * h + y) * w + x) * c + ch] = src[((bn * c + ch) * h + y) * w + x];
}}

static void nhwc_to_nchw(const elem_t *src, elem_t *dst, int n, int c, int h, int w) {{
  for (int bn = 0; bn < n; bn++)
    for (int ch = 0; ch < c; ch++)
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++)
          dst[((bn * c + ch) * h + y) * w + x] = src[((bn * h + y) * w + x) * c + ch];
}}

static void nhwc_to_ncl_i8(const elem_t *src, elem_t *dst, int n, int c, int h, int w,
    float ss, float ds) {{
  for (int bn = 0; bn < n; bn++)
    for (int ch = 0; ch < c; ch++)
      for (int y = 0; y < h; y++)
        for (int x = 0; x < w; x++) {{
          elem_t value = src[((bn * h + y) * w + x) * c + ch];
          dst[(bn * c + ch) * (h * w) + y * w + x] =
            quantize_float((float)value * ss, ds);
        }}
}}

static void requant_copy(const elem_t *src, elem_t *dst, int count, float src_scale, float dst_scale) {{
#if defined(YOLOV5NU_COPY_KERNEL_RVV) && defined(__riscv_vector)
  if (src_scale == dst_scale)
    yolov5nu_rvv_copy_i8(src, dst, (uintptr_t)count);
  else
    yolov5nu_rvv_requant_i8(src, dst, (uintptr_t)count, src_scale / dst_scale);
  return;
#else
  if (src_scale == dst_scale) {{
#ifdef __riscv_vector
    uintptr_t remaining=(uintptr_t)count, offset=0, vl;
    while(remaining) {{
      asm volatile("vsetvli %[vl], %[n], e8, m1, ta, ma\\n\\t"
                   "vle8.v v0, (%[src])\\n\\t" "vse8.v v0, (%[dst])"
        : [vl] "=&r" (vl) : [n] "r" (remaining), [src] "r" (src+offset), [dst] "r" (dst+offset) : "memory");
      offset+=vl; remaining-=vl;
    }}
#else
    memcpy(dst, src, count);
#endif
    return;
  }}
  for (int i = 0; i < count; i++) dst[i] = quantize_float((float)src[i] * src_scale, dst_scale);
#endif
}}

#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
static void stage8h_config_ld_if_needed(size_t stride, float scale,
    size_t *current_stride, float *current_scale, bool *valid) {{
  if (*valid && *current_stride == stride && *current_scale == scale)
    return;
  if (*valid)
    gemmini_fence();
  gemmini_extended3_config_ld(stride, scale, true, 0);
  *current_stride = stride;
  *current_scale = scale;
  *valid = true;
}}
#endif

static void concat_nhwc_slice_strided_i8(const elem_t *src, elem_t *dst,
    int positions, int channels, int dst_stride, float src_scale,
    float dst_scale) {{
#if defined(__riscv_vector)
  yolov5nu_rvv_concat_nhwc_slice_i8(src, dst, (uintptr_t)positions,
    (uintptr_t)channels, (uintptr_t)dst_stride, src_scale / dst_scale);
#else
  for (int position = 0; position < positions; position++) {{
    requant_copy(src, dst, channels, src_scale, dst_scale);
    src += channels;
    dst += dst_stride;
  }}
#endif
}}

static void sigmoid_i8(const elem_t *src, elem_t *dst, int count, const elem_t lut[256]) {{
  for (int i = 0; i < count; i++) dst[i] = lut[(uint8_t)src[i]];
}}

{silu_lut_impl}

static void silu_lut_i8_strided(const elem_t *src, elem_t *dst,
    int positions, int channels, int dst_stride, const elem_t lut[256]) {{
  for (int position = 0; position < positions; position++) {{
    for (int channel = 0; channel < channels; channel++)
      dst[channel] = lut[(uint8_t)src[channel]];
    src += channels;
    dst += dst_stride;
  }}
}}

static void mul_i8(const elem_t *a, const elem_t *b, elem_t *dst, int count, float as, float bs, float ds) {{
  for (int i = 0; i < count; i++) dst[i] = quantize_float((float)a[i] * as * (float)b[i] * bs, ds);
}}

static void add_i8(const elem_t *a, const elem_t *b, elem_t *dst, int count, float as, float bs, float ds) {{
#if defined(YOLOV5NU_ADD_KERNEL_RVV) && defined(__riscv_vector)
  yolov5nu_rvv_add_i8(a, b, dst, (uintptr_t)count, as, bs, ds);
#else
  for (int i = 0; i < count; i++) dst[i] = quantize_float((float)a[i] * as + (float)b[i] * bs, ds);
#endif
}}

static void add_ratio_i8(const elem_t *a, const elem_t *b, elem_t *dst,
    int count, float ar, float br) {{
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_ratio_i8(a, b, dst, (uintptr_t)count, ar, br);
#else
  for (int i = 0; i < count; i++)
    dst[i] = quantize_float((float)a[i] * ar + (float)b[i] * br, 1.0f);
#endif
}}

static void add_fixed_i8(const elem_t *a, const elem_t *b, elem_t *dst,
    int count, float ar, float br, int32_t am, int32_t bm) {{
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_fixed_i8(a, b, dst, (uintptr_t)count, am, bm);
#else
  for (int i = 0; i < count; i++)
    dst[i] = quantize_float((float)a[i] * ar + (float)b[i] * br, 1.0f);
#endif
}}

static void add_fixed_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br, int32_t am, int32_t bm) {{
  for (int position = 0; position < positions; position++) {{
    add_fixed_i8(a, b, dst, channels, ar, br, am, bm);
    a += channels;
    b += channels;
    dst += dst_stride;
  }}
}}

static void add_ratio_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br) {{
  for (int position = 0; position < positions; position++) {{
    add_ratio_i8(a, b, dst, channels, ar, br);
    a += channels;
    b += channels;
    dst += dst_stride;
  }}
}}

static void add_gemmini_resadd_strided_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br);

static void add_gemmini_resadd_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, float ar, float br) {{
  add_gemmini_resadd_strided_i8(
    a, b, dst, positions, channels, channels, ar, br);
}}

static void add_gemmini_resadd_strided_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float ar, float br) {{
  const size_t j_blocks = (channels + DIM - 1) / DIM;
  size_t i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (i_blocks == 0) i_blocks = 1;
  const size_t tile_i = i_blocks * DIM;
  gemmini_extended_config_st((size_t)dst_stride * sizeof(elem_t),
    NO_ACTIVATION, br);
  gemmini_config_ex(WS, 0, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    ar / br, true, DIM, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, DIM, 1);
  for (size_t i = 0; i < (size_t)positions; i += tile_i) {{
    const size_t i_tile = i + tile_i <= (size_t)positions
      ? tile_i : (size_t)positions - i;
    sp_tiled_resadd(i_tile, (size_t)channels, ar / br,
      MVIN_SCALE_IDENTITY, a + i * channels, b + i * channels,
      dst + i * dst_stride, (size_t)channels, (size_t)channels,
      (size_t)dst_stride, false);
  }}
  gemmini_fence();
}}

static void add_gemmini_shared_resadd_i8(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, float output_scale) {{
  const size_t j_blocks = (channels + DIM - 1) / DIM;
  size_t i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (i_blocks == 0) i_blocks = 1;
  const size_t tile_i = i_blocks * DIM;
  // Both inputs already use the shared scale; only the output requant remains.
  gemmini_extended_config_st((size_t)channels * sizeof(elem_t),
    NO_ACTIVATION, output_scale);
  gemmini_config_ex(WS, 0, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, DIM, 0);
  gemmini_extended4_config_ld((size_t)channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, DIM, 1);
  for (size_t i = 0; i < (size_t)positions; i += tile_i) {{
    const size_t i_tile = i + tile_i <= (size_t)positions
      ? tile_i : (size_t)positions - i;
    sp_tiled_resadd(i_tile, (size_t)channels,
      MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      a + i * channels, b + i * channels, dst + i * channels,
      (size_t)channels, (size_t)channels, (size_t)channels, false);
  }}
  gemmini_fence();
}}

static void gemmini_splitk_1x1_two_slice_i8(
    const elem_t *a0, const elem_t *a1, const elem_t *weights,
    const acc_t *bias, elem_t *output, int positions, int slice_channels,
    int out_channels, float a0_scale, float a1_scale, float concat_scale,
    int act, float output_scale) {{
  if (slice_channels <= 0 || out_channels <= 0 || out_channels % DIM != 0) {{
    printf("Stage 8C split-K geometry mismatch\\n");
    exit(1);
  }}
  const size_t j_blocks = (out_channels + DIM - 1) / DIM;
  const size_t k_blocks = (slice_channels + DIM - 1) / DIM;
  const size_t pad_k = k_blocks * DIM - slice_channels;
  const size_t max_i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (max_i_blocks == 0) {{
    printf("Stage 8C split-K accumulator capacity exceeded\\n");
    exit(1);
  }}
  const size_t tile_rows = max_i_blocks * DIM;

  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended_config_st((size_t)out_channels * sizeof(elem_t),
    act & 7, output_scale);
  gemmini_extended3_config_ld((size_t)out_channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {{
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks = (rows + DIM - 1) / DIM;
    const size_t pad_i = i_blocks * DIM - rows;

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a0 + row * slice_channels, weights, bias, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, false, true, act, 0, 0);
    // The load scale is global state. Complete partial 0 before changing it;
    // the accumulator contents survive the fence because no mvout was issued.
    gemmini_fence();

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a1 + row * slice_channels,
      weights + slice_channels * out_channels, NULL,
      output + row * out_channels,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, true, false, act, 0, 0);
    gemmini_fence();
  }}
}}

// Stage 8F: keep both input slices resident in separate A-side Scratchpad
// partitions so a second consumer can reuse them without another mvin.
static void gemmini_splitk_1x1_two_slice_i8_spad_reuse(
    const elem_t *a0, const elem_t *a1, const elem_t *weights,
    const acc_t *bias, elem_t *output, int positions, int slice_channels,
    int out_channels, float a0_scale, float a1_scale, float concat_scale,
    int act, float output_scale, bool reuse_a) {{
  if (slice_channels <= 0 || out_channels <= 0 || out_channels % DIM != 0) {{
    printf("Stage 8F split-K geometry mismatch\\n");
    exit(1);
  }}
  const size_t j_blocks = (out_channels + DIM - 1) / DIM;
  const size_t k_blocks = (slice_channels + DIM - 1) / DIM;
  const size_t pad_k = k_blocks * DIM - slice_channels;
  const size_t max_i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (max_i_blocks == 0) {{
    printf("Stage 8F split-K accumulator capacity exceeded\\n");
    exit(1);
  }}
  const size_t tile_rows = max_i_blocks * DIM;

  // A-side partitions 1 and 2 are disjoint.  The second invocation passes
  // NULL for A, which makes the loop engine skip A's DRAM load while the
  // execute engine still selects the requested resident partition.
  const int a0_spad_id = 1;
  const int a1_spad_id = 2;
  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended_config_st((size_t)out_channels * sizeof(elem_t),
    act & 7, output_scale);
  gemmini_extended3_config_ld((size_t)out_channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {{
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks = (rows + DIM - 1) / DIM;
    const size_t pad_i = i_blocks * DIM - rows;

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      reuse_a ? NULL : a0 + row * slice_channels, weights, bias, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, false, true, act, a0_spad_id, 0);
    gemmini_fence();

    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      reuse_a ? NULL : a1 + row * slice_channels,
      weights + slice_channels * out_channels, NULL,
      output + row * out_channels,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels, out_channels, out_channels,
      false, false, false, false, true, false, act, a1_spad_id, 0);
    gemmini_fence();
  }}
}}

// Stage 8F pair helper.  The two consumers are interleaved per spatial tile:
// load both A slices once, finish consumer 0, then reuse the resident slices
// for consumer 1.  Accumulators and output stores remain independent.
static void gemmini_splitk_1x1_two_slice_two_consumer_spad_reuse_i8(
    const elem_t *a0, const elem_t *a1,
    const elem_t *weights0, const acc_t *bias0, elem_t *output0,
    const elem_t *silu_lut0, int out_channels0, float requant0,
    const elem_t *weights1, const acc_t *bias1, elem_t *output1,
    const elem_t *silu_lut1, int out_channels1, float requant1,
    int positions, int slice_channels, float a0_scale, float a1_scale,
    float concat_scale, int act) {{
  if (slice_channels <= 0 || out_channels0 <= 0 || out_channels1 <= 0 ||
      out_channels0 % DIM != 0 || out_channels1 % DIM != 0) {{
    printf("Stage 8F pair split-K geometry mismatch\\n");
    exit(1);
  }}
  const size_t j_blocks0 = (out_channels0 + DIM - 1) / DIM;
  const size_t j_blocks1 = (out_channels1 + DIM - 1) / DIM;
  const size_t k_blocks = (slice_channels + DIM - 1) / DIM;
  const size_t pad_k = k_blocks * DIM - slice_channels;
  const size_t max_i_blocks0 = (ACC_ROWS / 2) / (j_blocks0 * DIM);
  const size_t max_i_blocks1 = (ACC_ROWS / 2) / (j_blocks1 * DIM);
  const size_t max_i_blocks = max_i_blocks0 < max_i_blocks1
    ? max_i_blocks0 : max_i_blocks1;
  if (max_i_blocks == 0) {{
    printf("Stage 8F pair accumulator capacity exceeded\\n");
    exit(1);
  }}
  const size_t tile_rows = max_i_blocks * DIM;

  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended3_config_ld((size_t)out_channels0 * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {{
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks0 = (rows + DIM - 1) / DIM;
    const size_t i_blocks1 = i_blocks0;
    const size_t pad_i = i_blocks0 * DIM - rows;

    // Consumer 0 loads each A slice once and keeps its private accumulator.
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a0 + row * slice_channels, weights0, bias0, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks0, j_blocks0, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels0, out_channels0, out_channels0,
      false, false, false, false, false, true, act, 1, 0);
    gemmini_fence();

    gemmini_config_silu_lut(silu_lut0);
    gemmini_fence();
    gemmini_extended_config_st((size_t)out_channels0 * sizeof(elem_t),
      act & 7, requant0);
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      a1 + row * slice_channels,
      weights0 + slice_channels * out_channels0, NULL,
      output0 + row * out_channels0,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks0, j_blocks0, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels0, out_channels0, out_channels0,
      false, false, false, false, true, false, act, 2, 0);
    gemmini_fence();

    // Consumer 1 reuses both A partitions; only B, bias, accumulator and
    // output differ.  A=NULL is translated to the skip-A loop macro.
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a0_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      NULL, weights1, bias1, NULL,
      a0_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks1, j_blocks1, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels1, out_channels1, out_channels1,
      false, false, false, false, false, true, act, 1, 0);
    gemmini_fence();

    gemmini_config_silu_lut(silu_lut1);
    gemmini_fence();
    gemmini_extended_config_st((size_t)out_channels1 * sizeof(elem_t),
      act & 7, requant1);
    gemmini_extended3_config_ld((size_t)slice_channels * sizeof(elem_t),
      a1_scale / concat_scale, true, 0);
    sp_tiled_matmul_ws(
      NULL, weights1 + slice_channels * out_channels1, NULL,
      output1 + row * out_channels1,
      a1_scale / concat_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
      i_blocks1, j_blocks1, k_blocks, pad_i, 0, pad_k,
      slice_channels, out_channels1, out_channels1, out_channels1,
      false, false, false, false, true, false, act, 2, 0);
    gemmini_fence();
  }}
}}

static void gemmini_splitk_1x1_multi_slice_i8(
    const elem_t *const inputs[], const int slice_channels[],
    const float input_scales[], int slice_count, const elem_t *weights,
    const acc_t *bias, elem_t *output, int positions, int out_channels,
    float concat_scale, int act, float output_scale) {{
  if (slice_count <= 1 || out_channels <= 0 || out_channels % DIM != 0) {{
    printf("Stage 8C multi-slice geometry mismatch\\n");
    exit(1);
  }}
  const size_t j_blocks = (out_channels + DIM - 1) / DIM;
  const size_t max_i_blocks = (ACC_ROWS / 2) / (j_blocks * DIM);
  if (max_i_blocks == 0) {{
    printf("Stage 8C multi-slice accumulator capacity exceeded\\n");
    exit(1);
  }}
  const size_t tile_rows = max_i_blocks * DIM;

#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
  size_t stage8h_current_stride = 0;
  float stage8h_current_scale = 0.0f;
  bool stage8h_scale_valid = false;
#endif

  gemmini_extended_config_ex(WS, act & 7, 0, 1, false, false);
  gemmini_extended_config_st((size_t)out_channels * sizeof(elem_t),
    act & 7, output_scale);
  gemmini_extended3_config_ld((size_t)out_channels * sizeof(elem_t),
    MVIN_SCALE_IDENTITY, true, 1);
  gemmini_extended3_config_ld(0, MVIN_SCALE_IDENTITY, false, 2);

  for (size_t row = 0; row < (size_t)positions; row += tile_rows) {{
    const size_t rows = row + tile_rows <= (size_t)positions
      ? tile_rows : (size_t)positions - row;
    const size_t i_blocks = (rows + DIM - 1) / DIM;
    const size_t pad_i = i_blocks * DIM - rows;
    size_t weight_channel_offset = 0;
    for (int slice = 0; slice < slice_count; slice++) {{
      const size_t channels = (size_t)slice_channels[slice];
      const size_t k_blocks = (channels + DIM - 1) / DIM;
      const size_t pad_k = k_blocks * DIM - channels;
      const bool first = slice == 0;
      const bool last = slice == slice_count - 1;
      const float input_scale = input_scales[slice] / concat_scale;
#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
      stage8h_config_ld_if_needed(channels * sizeof(elem_t), input_scale,
        &stage8h_current_stride, &stage8h_current_scale, &stage8h_scale_valid);
#else
      gemmini_extended3_config_ld(channels * sizeof(elem_t),
        input_scale, true, 0);
#endif
      sp_tiled_matmul_ws(
        inputs[slice] + row * channels,
        weights + weight_channel_offset * out_channels,
        first ? bias : NULL,
        last ? output + row * out_channels : NULL,
        input_scale, MVIN_SCALE_IDENTITY, MVIN_SCALE_IDENTITY,
        i_blocks, j_blocks, k_blocks, pad_i, 0, pad_k,
        channels, out_channels, out_channels, out_channels,
        false, false, false, false, !first, first, act, 0, 0);
#if defined(YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE)
      // A scale change requires a fence because mvin scale is global.  The
      // final fence remains mandatory even when the next partial has the same
      // scale, since the caller may consume the output immediately.
      if (last || input_scales[slice] != input_scales[slice + 1])
        gemmini_fence();
#else
      gemmini_fence();
#endif
      weight_channel_offset += channels;
    }}
  }}
}}

static void add_two_step_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float a_scale, float b_scale, float add_scale, float concat_scale) {{
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  for (int position = 0; position < positions; position++) {{
    yolov5nu_rvv_add_two_step_i8(a, b, dst, (uintptr_t)channels,
      a_scale / add_scale, b_scale / add_scale, add_scale / concat_scale);
    a += channels;
    b += channels;
    dst += dst_stride;
  }}
#else
  for (int position = 0; position < positions; position++) {{
    for (int channel = 0; channel < channels; channel++) {{
      int first = quantize_float(
        (float)a[channel] * a_scale + (float)b[channel] * b_scale,
        add_scale);
      dst[channel] = quantize_float((float)first * add_scale, concat_scale);
    }}
    a += channels;
    b += channels;
    dst += dst_stride;
  }}
#endif
}}

static void add_two_step_lut_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float a_scale, float b_scale, float add_scale, float concat_scale,
    const elem_t requant_lut[256]) {{
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
    for (int position = 0; position < positions; position++) {{
    yolov5nu_rvv_add_two_step_lut_i8(a, b, dst, (uintptr_t)channels,
      a_scale / add_scale, b_scale / add_scale, requant_lut);
    a += channels;
    b += channels;
    dst += dst_stride;
  }}
#else
  for (int position = 0; position < positions; position++) {{
    for (int channel = 0; channel < channels; channel++) {{
      int first = quantize_float(
        (float)a[channel] * a_scale + (float)b[channel] * b_scale,
        add_scale);
      dst[channel] = requant_lut[(uint8_t)first];
    }}
    a += channels;
    b += channels;
    dst += dst_stride;
  }}
#endif
}}

static void add_two_step_register_i8_strided(const elem_t *a, const elem_t *b,
    elem_t *dst, int positions, int channels, int dst_stride,
    float a_scale, float b_scale, float add_scale, float concat_scale,
    const elem_t requant_lut[256]) {{
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_two_step_register_strided_i8(
    a, b, dst, (uintptr_t)positions, (uintptr_t)channels,
    (uintptr_t)dst_stride, a_scale / add_scale, b_scale / add_scale,
    add_scale / concat_scale, requant_lut);
#else
  add_two_step_lut_i8_strided(a, b, dst, positions, channels, dst_stride,
    a_scale, b_scale, add_scale, concat_scale, requant_lut);
#endif
}}

static void add_two_step_register_fixed_i8_strided(const elem_t *a,
    const elem_t *b, elem_t *dst, int positions, int channels, int dst_stride,
    int32_t am, int32_t bm, const elem_t requant_lut[256]) {{
#if defined(YOLOV5NU_ADD_KERNEL_RVV_RATIO) && defined(__riscv_vector)
  yolov5nu_rvv_add_two_step_register_fixed_strided_i8(
    a, b, dst, (uintptr_t)positions, (uintptr_t)channels,
    (uintptr_t)dst_stride, am, bm, requant_lut);
#else
  for (int position = 0; position < positions; position++) {{
    for (int channel = 0; channel < channels; channel++) {{
      int64_t value = (int64_t)a[channel] * am + (int64_t)b[channel] * bm;
      int negative = value < 0;
      uint64_t magnitude = negative ? (uint64_t)(-value) : (uint64_t)value;
      int first = (int)(magnitude >> 22);
      uint64_t remainder = magnitude & ((1ULL << 22) - 1);
      if (remainder > (1ULL << 21) ||
          (remainder == (1ULL << 21) && (first & 1))) first++;
      if (negative) first = -first;
      if (first > 127) first = 127;
      if (first < -128) first = -128;
      dst[channel] = requant_lut[(uint8_t)first];
    }}
    a += channels;
    b += channels;
    dst += dst_stride;
  }}
#endif
}}

static void maxpool_nchw_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, int kh, int kw, int sh, int sw, int ph, int pw, float ss, float ds) {{
  for (int bn = 0; bn < n; bn++) for (int ch = 0; ch < c; ch++)
    for (int oy = 0; oy < oh; oy++) for (int ox = 0; ox < ow; ox++) {{
      int best = -128;
      for (int ky = 0; ky < kh; ky++) for (int kx = 0; kx < kw; kx++) {{
        int iy = oy * sh + ky - ph, ix = ox * sw + kx - pw;
        if (iy >= 0 && iy < ih && ix >= 0 && ix < iw) {{
          int value = src[((bn * c + ch) * ih + iy) * iw + ix];
          if (value > best) best = value;
        }}
      }}
      dst[((bn * c + ch) * oh + oy) * ow + ox] = quantize_float((float)best * ss, ds);
    }}
}}

static void maxpool_nhwc_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, int kh, int kw, int sh, int sw, int ph, int pw, float ss, float ds) {{
#if defined(YOLOV5NU_MAXPOOL_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {{
    yolov5nu_rvv_maxpool_nhwc_i8(src, dst, n, c, ih, iw, oh, ow,
      kh, kw, sh, sw, ph, pw);
    return;
  }}
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {{
      int best = -128;
      for (int ky = 0; ky < kh; ky++) for (int kx = 0; kx < kw; kx++) {{
        int iy = oy * sh + ky - ph, ix = ox * sw + kx - pw;
        if (iy >= 0 && iy < ih && ix >= 0 && ix < iw) {{
          int value = src[((bn * ih + iy) * iw + ix) * c + ch];
          if (value > best) best = value;
        }}
      }}
      dst[((bn * oh + oy) * ow + ox) * c + ch] = quantize_float((float)best * ss, ds);
    }}
}}

static void maxpool_nhwc_i8_strided(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, int kh, int kw, int sh, int sw, int ph, int pw,
    float ss, float ds, int dst_stride) {{
#if defined(YOLOV5NU_MAXPOOL_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {{
    yolov5nu_rvv_maxpool_nhwc_i8_strided(src, dst, n, c, ih, iw, oh, ow,
      kh, kw, sh, sw, ph, pw, dst_stride);
    return;
  }}
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {{
      int best = -128;
      for (int ky = 0; ky < kh; ky++) for (int kx = 0; kx < kw; kx++) {{
        int iy = oy * sh + ky - ph, ix = ox * sw + kx - pw;
        if (iy >= 0 && iy < ih && ix >= 0 && ix < iw) {{
          int value = src[((bn * ih + iy) * iw + ix) * c + ch];
          if (value > best) best = value;
        }}
      }}
      dst[((bn * oh + oy) * ow + ox) * dst_stride + ch] = quantize_float((float)best * ss, ds);
    }}
}}

static void resize_nearest_nchw_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, float ss, float ds) {{
  for (int bn = 0; bn < n; bn++) for (int ch = 0; ch < c; ch++)
    for (int oy = 0; oy < oh; oy++) for (int ox = 0; ox < ow; ox++) {{
      int iy = (oy * ih) / oh, ix = (ox * iw) / ow;
      elem_t value = src[((bn * c + ch) * ih + iy) * iw + ix];
      dst[((bn * c + ch) * oh + oy) * ow + ox] = quantize_float((float)value * ss, ds);
    }}
}}

static void resize_nearest_nhwc_i8(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, float ss, float ds) {{
#if defined(YOLOV5NU_RESIZE_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {{
    yolov5nu_rvv_resize_nearest_nhwc_i8(src, dst, n, c, ih, iw, oh, ow);
    return;
  }}
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {{
      int iy = (oy * ih) / oh, ix = (ox * iw) / ow;
      elem_t value = src[((bn * ih + iy) * iw + ix) * c + ch];
      dst[((bn * oh + oy) * ow + ox) * c + ch] = quantize_float((float)value * ss, ds);
    }}
}}

static void resize_nearest_nhwc_i8_strided(const elem_t *src, elem_t *dst, int n, int c, int ih, int iw,
    int oh, int ow, float ss, float ds, int dst_stride) {{
#if defined(YOLOV5NU_RESIZE_KERNEL_RVV) && defined(__riscv_vector)
  if (ss == ds) {{
    yolov5nu_rvv_resize_nearest_nhwc_i8_strided(src, dst, n, c, ih, iw, oh, ow, dst_stride);
    return;
  }}
#endif
  for (int bn = 0; bn < n; bn++) for (int oy = 0; oy < oh; oy++)
    for (int ox = 0; ox < ow; ox++) for (int ch = 0; ch < c; ch++) {{
      int iy = (oy * ih) / oh, ix = (ox * iw) / ow;
      elem_t value = src[((bn * ih + iy) * iw + ix) * c + ch];
      dst[((bn * oh + oy) * ow + ox) * dst_stride + ch] = quantize_float((float)value * ss, ds);
    }}
}}

static void transpose4_i8(const elem_t *src, elem_t *dst, int d0, int d1, int d2, int d3,
    int p0, int p1, int p2, int p3, float ss, float ds) {{
  int dims[4] = {{d0,d1,d2,d3}}, perm[4] = {{p0,p1,p2,p3}};
  int od[4] = {{dims[p0],dims[p1],dims[p2],dims[p3]}};
  for (int i0=0;i0<od[0];i0++) for(int i1=0;i1<od[1];i1++)
    for(int i2=0;i2<od[2];i2++) for(int i3=0;i3<od[3];i3++) {{
      int out_idx[4]={{i0,i1,i2,i3}}, in_idx[4];
      for(int k=0;k<4;k++) in_idx[perm[k]]=out_idx[k];
      int si=((in_idx[0]*d1+in_idx[1])*d2+in_idx[2])*d3+in_idx[3];
      int di=((i0*od[1]+i1)*od[2]+i2)*od[3]+i3;
      dst[di]=quantize_float((float)src[si]*ss,ds);
    }}
}}

static void softmax_i8(const elem_t *src, elem_t *dst, int outer, int axis, int inner,
    float ds, const float exp_lut[256]) {{
  for (int o=0;o<outer;o++) for(int i=0;i<inner;i++) {{
    int max_value=-128; float sum=0.0f;
    for(int a=0;a<axis;a++) {{ int x=src[(o*axis+a)*inner+i]; if(x>max_value)max_value=x; }}
    for(int a=0;a<axis;a++) sum += exp_lut[max_value-(int)src[(o*axis+a)*inner+i]];
    for(int a=0;a<axis;a++) {{
      float value=exp_lut[max_value-(int)src[(o*axis+a)*inner+i]]/sum;
      dst[(o*axis+a)*inner+i]=quantize_float(value,ds);
    }}
  }}
}}

static void stage4_select_dfl_candidates(const elem_t *classes, float class_scale,
    float score_threshold);

static void stage4_class_heads_i8(
    const elem_t *src0, int count0, float scale0,
    const elem_t *src1, int count1, float scale1,
    const elem_t *src2, int count2, float scale2,
    elem_t *logits, elem_t *scores, float concat_scale,
    const elem_t sigmoid_lut[256], float class_scale,
    float score_threshold) {{
  const elem_t *sources[3] = {{src0, src1, src2}};
  const int counts[3] = {{count0, count1, count2}};
  const float scales[3] = {{scale0, scale1, scale2}};
  int output_position = 0;
  uint64_t phase_start = yolo_profile_clock();
  for (int head = 0; head < 3; head++) {{
    requant_copy(sources[head], logits + output_position * 80,
      counts[head] * 80, scales[head], concat_scale);
    output_position += counts[head];
  }}
  head_class_requant_cycles = yolo_profile_clock() - phase_start;
  phase_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT) && defined(__riscv_vector)
  yolov5nu_rvv_sigmoid_lut_i8(logits, scores,
    (uintptr_t)(output_position * 80), sigmoid_lut);
#else
  for (int i = 0; i < output_position * 80; i++)
    scores[i] = sigmoid_lut[(uint8_t)logits[i]];
#endif
  head_class_sigmoid_cycles = yolo_profile_clock() - phase_start;
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  phase_start = yolo_profile_clock();
  stage4_select_dfl_candidates(scores, class_scale, score_threshold);
  head_class_candidate_cycles = yolo_profile_clock() - phase_start;
#else
  head_class_candidate_cycles = 0;
#endif
}}

static void stage4_dfl_heads_i8(
    const elem_t *src0, int count0, float scale0,
    const elem_t *src1, int count1, float scale1,
    const elem_t *src2, int count2, float scale2,
    elem_t *logits_buffer, elem_t *distances,
    float concat_scale, float softmax_scale,
    float weight_scale, float output_scale, const elem_t weights[16],
    const float exp_lut[256]) {{
  const elem_t *sources[3] = {{src0, src1, src2}};
  const int counts[3] = {{count0, count1, count2}};
  const float scales[3] = {{scale0, scale1, scale2}};
  int output_position = 0;
  uint64_t phase_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  head_dfl_candidate_cycles = 0;
#endif
  for (int head = 0; head < 3; head++) {{
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    for (int local = 0; local < counts[head]; local++) {{
      int position = output_position + local;
      if (dfl_candidate_mask[position])
        requant_copy(sources[head] + local * 64, logits_buffer + position * 64,
          64, scales[head], concat_scale);
    }}
#else
    requant_copy(sources[head], logits_buffer + output_position * 64,
      counts[head] * 64, scales[head], concat_scale);
#endif
    output_position += counts[head];
  }}
  head_dfl_requant_cycles = yolo_profile_clock() - phase_start;
  phase_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL) && defined(__riscv_vector)
  const int rvv_dfl_supported = yolov5nu_rvv_dfl_vl16_supported();
  head_dfl_rvv_enabled = rvv_dfl_supported;
#else
  head_dfl_rvv_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL_BATCH) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_SCALAR_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#elif defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM) && defined(__riscv_vector)
  head_dfl_batch_enabled = rvv_dfl_supported;
#else
  head_dfl_batch_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_ORDERED_SUM) && defined(__riscv_vector)
  head_dfl_ordered_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_ordered_sum_enabled = 0;
#endif
#if (defined(YOLOV5NU_HEAD_KERNEL_DFL_GATHER) || defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER)) && defined(__riscv_vector)
  head_dfl_gather_enabled = rvv_dfl_supported;
#else
  head_dfl_gather_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM) && defined(__riscv_vector)
  head_dfl_elementwise_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_elementwise_sum_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM) && defined(__riscv_vector)
  head_dfl_unordered_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_unordered_sum_enabled = 0;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM) && defined(__riscv_vector)
  head_dfl_interleaved_sum_enabled = rvv_dfl_supported;
#else
  head_dfl_interleaved_sum_enabled = 0;
#endif
  for (int position = 0; position < output_position; position++) {{
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    if (!dfl_candidate_mask[position]) continue;
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_GATHER) && defined(__riscv_vector)
    if (rvv_dfl_supported) {{
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4] = {{0.0f, 0.0f, 0.0f, 0.0f}};
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++) {{
        yolov5nu_rvv_dfl_exp_gather_f32x16(
          position_logits + edge * 16, maxima[edge], exp_lut,
          exponentials4[edge]);
        for (int bin = 0; bin < 16; bin++)
          sums[edge] += exponentials4[edge][bin];
      }}
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }}
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_INTERLEAVED_SCALAR_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {{
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sum0 = 0.0f, sum1 = 0.0f, sum2 = 0.0f, sum3 = 0.0f;
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int bin = 0; bin < 16; bin++) {{
        float value0 = exp_lut[(int)maxima[0] - (int)position_logits[bin]];
        float value1 = exp_lut[(int)maxima[1] - (int)position_logits[16 + bin]];
        float value2 = exp_lut[(int)maxima[2] - (int)position_logits[32 + bin]];
        float value3 = exp_lut[(int)maxima[3] - (int)position_logits[48 + bin]];
        exponentials4[0][bin] = value0;
        exponentials4[1][bin] = value1;
        exponentials4[2][bin] = value2;
        exponentials4[3][bin] = value3;
        asm volatile(
          "fadd.s %[sum0], %[sum0], %[value0]\\n\\t"
          "fadd.s %[sum1], %[sum1], %[value1]\\n\\t"
          "fadd.s %[sum2], %[sum2], %[value2]\\n\\t"
          "fadd.s %[sum3], %[sum3], %[value3]"
          : [sum0] "+f" (sum0), [sum1] "+f" (sum1),
            [sum2] "+f" (sum2), [sum3] "+f" (sum3)
          : [value0] "f" (value0), [value1] "f" (value1),
            [value2] "f" (value2), [value3] "f" (value3));
      }}
      float sums[4] = {{sum0, sum1, sum2, sum3}};
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }}
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_UNORDERED_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {{
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4];
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++)
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
      yolov5nu_rvv_dfl_unordered_sum_f32x4x16(exponentials4, sums);
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }}
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_ELEMENTWISE_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {{
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4];
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++)
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
      yolov5nu_rvv_dfl_elementwise_sum_f32x4x16(exponentials4, sums);
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }}
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_BATCH_SCALAR_SUM) && defined(__riscv_vector)
    if (rvv_dfl_supported) {{
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4] = {{0.0f, 0.0f, 0.0f, 0.0f}};
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++) {{
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
          sums[edge] += exponentials4[edge][bin];
        }}
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }}
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL_BATCH) && defined(__riscv_vector)
    if (rvv_dfl_supported) {{
      const elem_t *position_logits = logits_buffer + position * 64;
      elem_t maxima[4];
      float exponentials4[4][16];
      float sums[4];
      float reciprocals[4];
      int32_t accumulators[4];
      yolov5nu_rvv_dfl_max_i8x4x16(position_logits, maxima);
      for (int edge = 0; edge < 4; edge++)
        for (int bin = 0; bin < 16; bin++)
          exponentials4[edge][bin] = exp_lut[
            (int)maxima[edge] - (int)position_logits[edge * 16 + bin]];
      yolov5nu_rvv_dfl_ordered_sum_f32x4x16(exponentials4, sums);
      for (int edge = 0; edge < 4; edge++)
        reciprocals[edge] = 1.0f / (sums[edge] * softmax_scale);
      yolov5nu_rvv_dfl_probability_dot_i8x4x16(
        exponentials4, reciprocals, weights, accumulators);
      for (int edge = 0; edge < 4; edge++)
        distances[position * 4 + edge] = quantize_float(
          (float)accumulators[edge] * softmax_scale * weight_scale,
          output_scale);
      continue;
    }}
#endif
    for (int edge = 0; edge < 4; edge++) {{
        const elem_t *logits = logits_buffer + position * 64 + edge * 16;
        int max_value = -128;
        float sum = 0.0f;
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
        float exponentials[16];
#endif
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          max_value = yolov5nu_rvv_dfl_max_i8x16(logits);
        else
#endif
        {{
        for (int bin = 0; bin < 16; bin++) {{
          elem_t value = logits[bin];
          if (value > max_value) max_value = value;
        }}
        }}
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_GATHER) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          yolov5nu_rvv_dfl_exp_gather_f32x16(
            logits, (int8_t)max_value, exp_lut, exponentials);
        else
#endif
        for (int bin = 0; bin < 16; bin++) {{
          exponentials[bin] = exp_lut[max_value - (int)logits[bin]];
        }}
#if defined(YOLOV5NU_HEAD_KERNEL_DFL_ORDERED_SUM) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          sum = yolov5nu_rvv_dfl_ordered_sum_f32x16(exponentials);
        else
#endif
        for (int bin = 0; bin < 16; bin++) {{
          sum += exponentials[bin];
        }}
        float reciprocal = 1.0f / (sum * softmax_scale);
#else
        for (int bin = 0; bin < 16; bin++)
          sum += exp_lut[max_value - (int)logits[bin]];
#endif
        int accumulator = 0;
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV_LUT_DFL) && defined(__riscv_vector)
        if (rvv_dfl_supported)
          accumulator = yolov5nu_rvv_dfl_probability_dot_i8x16(
            exponentials, reciprocal, weights);
        else
#endif
        {{
        for (int bin = 0; bin < 16; bin++) {{
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
          int probability_i = round_nearest_even(exponentials[bin] * reciprocal);
          if (probability_i > 127) probability_i = 127;
          if (probability_i < -128) probability_i = -128;
          elem_t probability = (elem_t)probability_i;
#else
          elem_t probability = quantize_float(
            exp_lut[max_value - (int)logits[bin]] / sum, softmax_scale);
#endif
          accumulator += (int)probability * (int)weights[bin];
        }}
        }}
        distances[position * 4 + edge] = quantize_float(
          (float)accumulator * softmax_scale * weight_scale, output_scale);
      }}
  }}
  head_dfl_core_cycles = yolo_profile_clock() - phase_start;
}}

static void print_checkpoint(int index, const char *name, const elem_t *data, int count) {{
#if YOLOV5NU_LAYER_STATS
  long checksum=0; int min_value=127,max_value=-128;
  for(int i=0;i<count;i++) {{ int value=data[i]; checksum+=value; if(value<min_value)min_value=value; if(value>max_value)max_value=value; }}
#if {1 if args.diagnostic_fingerprint else 0}
  unsigned long long sum_sq=0, hash=1469598103934665603ULL;
  for(int i=0;i<count;i++) {{
    unsigned long long value=(unsigned char)data[i];
    sum_sq += (unsigned long long)((int)data[i] * (int)data[i]);
    hash ^= value;
    hash *= 1099511628211ULL;
  }}
  printf("op%d %s elems=%d checksum=%ld min=%d max=%d sum_sq=%llu fnv1a=%016llx\\n",
    index,name,count,checksum,min_value,max_value,sum_sq,hash);
#else
  printf("op%d %s elems=%d checksum=%ld min=%d max=%d\\n",index,name,count,checksum,min_value,max_value);
#endif
#else
  (void)index; (void)name; (void)data; (void)count;
#endif
}}

static void print_tensor_summary(const char *name, const elem_t *data, int count) {{
#if YOLOV5NU_FINAL_TENSOR_STATS
  long checksum=0; int min_value=127,max_value=-128,saturated=0;
  for(int i=0;i<count;i++) {{
    int value=data[i]; checksum+=value;
    if(value<min_value) min_value=value;
    if(value>max_value) max_value=value;
    if(value==127 || value==-128) saturated++;
  }}
  printf("%s elems=%d checksum=%ld min=%d max=%d saturated=%d\\n",
    name,count,checksum,min_value,max_value,saturated);
#else
  (void)name; (void)data; (void)count;
#endif
}}

static void print_sparse_dfl_summary(const char *name, const elem_t *data,
    const uint8_t *mask, int positions) {{
#if YOLOV5NU_FINAL_TENSOR_STATS
  long checksum = 0; int min_value = 127, max_value = -128, saturated = 0;
  int elems = 0;
  for (int position = 0; position < positions; position++) if (mask[position])
    for (int edge = 0; edge < 4; edge++) {{
      int value = data[position * 4 + edge];
      checksum += value; elems++;
      if (value < min_value) min_value = value;
      if (value > max_value) max_value = value;
      if (value == 127 || value == -128) saturated++;
    }}
  printf("%s sparse_positions=%d elems=%d checksum=%ld min=%d max=%d saturated=%d\\n",
    name, head_dfl_candidate_count, elems, checksum, min_value, max_value, saturated);
#else
  (void)name; (void)data; (void)mask; (void)positions;
#endif
}}

struct Detection {{ float score,cx,cy,w,h; int cls,index; }};
static const char *coco_names[80] = {{
  {', '.join(json.dumps(name) for name in COCO_NAMES)}
}};

static struct Detection decode_candidate(const elem_t *dfl, float dfl_scale,
    const elem_t *classes, float class_scale, int index) {{
#if defined(YOLOV5NU_HEAD_LOWERING_LOCATION_MAJOR)
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV) && defined(__riscv_vector)
    int cls;
    elem_t best = yolov5nu_rvv_class_max_i8(classes + index * 80, 80, &cls);
#else
    int cls=0; elem_t best=classes[index*80];
    for(int c=1;c<80;c++) {{ elem_t value=classes[index*80+c]; if(value>best){{best=value;cls=c;}} }}
#endif
#else
    int cls=0; elem_t best=classes[index];
    for(int c=1;c<80;c++) {{ elem_t value=classes[c*{total_head_positions}+index]; if(value>best){{best=value;cls=c;}} }}
#endif
    float score=(float)best*class_scale;
    int level,local,width,stride;
    if(index<{head_position_offsets[1]}){{level=0;local=index;width={head_grid_widths[0]};stride=8;}}
    else if(index<{head_position_offsets[2]}){{level=1;local=index-{head_position_offsets[1]};width={head_grid_widths[1]};stride=16;}}
    else{{level=2;local=index-{head_position_offsets[2]};width={head_grid_widths[2]};stride=32;}}
    (void)level;
    int x=local%width,y=local/width;
#if defined(YOLOV5NU_HEAD_LOWERING_LOCATION_MAJOR)
    float l=(float)dfl[index*4]*dfl_scale,t=(float)dfl[index*4+1]*dfl_scale;
    float r=(float)dfl[index*4+2]*dfl_scale,b=(float)dfl[index*4+3]*dfl_scale;
#else
    float l=(float)dfl[index]*dfl_scale,t=(float)dfl[{total_head_positions}+index]*dfl_scale;
    float r=(float)dfl[{2 * total_head_positions}+index]*dfl_scale,b=(float)dfl[{3 * total_head_positions}+index]*dfl_scale;
#endif
    struct Detection value={{score,((float)x+0.5f+(r-l)*0.5f)*stride,
      ((float)y+0.5f+(b-t)*0.5f)*stride,(l+r)*stride,(t+b)*stride,cls,index}};
    return value;
}}

static float detection_iou(const struct Detection *a, const struct Detection *b) {{
  float ax0=a->cx-a->w*0.5f, ay0=a->cy-a->h*0.5f;
  float ax1=a->cx+a->w*0.5f, ay1=a->cy+a->h*0.5f;
  float bx0=b->cx-b->w*0.5f, by0=b->cy-b->h*0.5f;
  float bx1=b->cx+b->w*0.5f, by1=b->cy+b->h*0.5f;
  float ix0=ax0>bx0?ax0:bx0, iy0=ay0>by0?ay0:by0;
  float ix1=ax1<bx1?ax1:bx1, iy1=ay1<by1?ay1:by1;
  float iw=ix1-ix0, ih=iy1-iy0;
  if(iw<=0.0f || ih<=0.0f) return 0.0f;
  float inter=iw*ih, area_a=a->w*a->h, area_b=b->w*b->h;
  float uni=area_a+area_b-inter;
  return uni>0.0f ? inter/uni : 0.0f;
}}

static void print_detection(const char *prefix, int rank, const struct Detection *value) {{
  printf("%s#%d %s score_milli=%d bbox_cxcywh=(%d,%d,%d,%d) index=%d\\n",
    prefix,rank,coco_names[value->cls],(int)(value->score*1000.0f+0.5f),
    (int)value->cx,(int)value->cy,(int)value->w,(int)value->h,value->index);
}}

static void decode_top_compute(const elem_t *dfl, float dfl_scale, const elem_t *classes,
    float class_scale, struct Detection top[10]) {{
  for(int i=0;i<10;i++) top[i]=(struct Detection){{0}};
  for(int index=0;index<{total_head_positions};index++) {{
    struct Detection value=decode_candidate(dfl,dfl_scale,classes,class_scale,index);
    if(value.score<=top[9].score) continue;
    int pos=9; while(pos>0 && value.score>top[pos-1].score){{top[pos]=top[pos-1];pos--;}} top[pos]=value;
  }}
}}

static struct Detection decoded_candidates[{total_head_positions}];

#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
static void stage4_select_dfl_candidates(const elem_t *classes, float class_scale,
    float score_threshold) {{
  int best_scores[{total_head_positions}];
#if defined(YOLOV5NU_HEAD_CANDIDATE_KERNEL_RVV) && defined(__riscv_vector)
  head_dfl_candidate_rvv_enabled = 1;
#else
  head_dfl_candidate_rvv_enabled = 0;
#endif
  for (int index = 0; index < {total_head_positions}; index++) {{
#if defined(YOLOV5NU_HEAD_CANDIDATE_KERNEL_RVV) && defined(__riscv_vector)
    int best = (int)yolov5nu_rvv_class_score_max_i8(
      classes + index * 80, 80);
#else
    int best = classes[index * 80];
    for (int cls = 1; cls < 80; cls++) {{
      int value = classes[index * 80 + cls];
      if (value > best) best = value;
    }}
#endif
    best_scores[index] = best;
    dfl_candidate_mask[index] = ((float)best * class_scale >= score_threshold);
  }}
  int top[10];
  int top_scores[10];
  for (int rank = 0; rank < 10; rank++) {{ top[rank] = -1; top_scores[rank] = -129; }}
  for (int index = 0; index < {total_head_positions}; index++) {{
    int score = best_scores[index];
    if (score <= top_scores[9]) continue;
    int pos = 9;
    while (pos > 0 && score > top_scores[pos - 1]) {{
      top[pos] = top[pos - 1];
      top_scores[pos] = top_scores[pos - 1];
      pos--;
    }}
    top[pos] = index;
    top_scores[pos] = score;
  }}
  for (int rank = 0; rank < 10; rank++)
    if (top[rank] >= 0) dfl_candidate_mask[top[rank]] = 1;
  head_dfl_candidate_count = 0;
  for (int index = 0; index < {total_head_positions}; index++)
    head_dfl_candidate_count += dfl_candidate_mask[index] != 0;
  head_dfl_sparse_enabled = 1;
}}
#else
static void stage4_select_dfl_candidates(const elem_t *classes, float class_scale,
    float score_threshold) {{
  (void)classes; (void)class_scale; (void)score_threshold;
  head_dfl_sparse_enabled = 0;
  head_dfl_candidate_count = {total_head_positions};
  head_dfl_candidate_cycles = 0;
  head_class_candidate_cycles = 0;
  head_dfl_candidate_rvv_enabled = 0;
}}
#endif

static void decode_all_compute(const elem_t *dfl, float dfl_scale,
    const elem_t *classes, float class_scale) {{
  for (int index = 0; index < {total_head_positions}; index++) {{
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    if (!dfl_candidate_mask[index]) {{
      decoded_candidates[index] = (struct Detection){{0}};
      continue;
    }}
#endif
    decoded_candidates[index] = decode_candidate(
      dfl, dfl_scale, classes, class_scale, index);
  }}
}}

static void decode_top_from_candidates(struct Detection top[10]) {{
  for (int i = 0; i < 10; i++) top[i] = (struct Detection){{0}};
  for (int index = 0; index < {total_head_positions}; index++) {{
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
    if (!dfl_candidate_mask[index]) continue;
#endif
    struct Detection value = decoded_candidates[index];
    if (value.score <= top[9].score) continue;
    int pos = 9;
    while (pos > 0 && value.score > top[pos - 1].score) {{
      top[pos] = top[pos - 1];
      pos--;
    }}
    top[pos] = value;
  }}
}}

static void print_top_detections(const struct Detection top[10]) {{
  printf("YOLOv5nu top detections for %s (no NMS)\\n",YOLOV5NU_IMAGE_NAME);
  for(int i=0;i<10;i++) print_detection("",i,&top[i]);
}}

static int decode_nms_compute(const elem_t *dfl, float dfl_scale, const elem_t *classes,
    float class_scale, float score_threshold, float iou_threshold, struct Detection output[10]) {{
  static struct Detection candidates[{total_head_positions}];
  static uint8_t suppressed[{total_head_positions}];
  int count=0;
  for(int index=0;index<{total_head_positions};index++) {{
    struct Detection value=decode_candidate(dfl,dfl_scale,classes,class_scale,index);
    if(value.score>=score_threshold) candidates[count++]=value;
  }}
  memset(suppressed,0,sizeof(suppressed));
  int emitted=0;
  while(emitted<10) {{
    int best=-1;
    for(int i=0;i<count;i++)
      if(!suppressed[i] && (best<0 || candidates[i].score>candidates[best].score)) best=i;
    if(best<0) break;
    output[emitted]=candidates[best];
    suppressed[best]=1;
    for(int i=0;i<count;i++)
      if(!suppressed[i] && candidates[i].cls==candidates[best].cls &&
          detection_iou(&candidates[i],&candidates[best])>iou_threshold) suppressed[i]=1;
    emitted++;
  }}
  return emitted;
}}

static int decode_nms_from_candidates(float score_threshold,
    float iou_threshold, struct Detection output[10]) {{
  static int candidate_indices[{total_head_positions}];
  static uint8_t suppressed[{total_head_positions}];
  int count = 0;
  for (int index = 0; index < {total_head_positions}; index++)
    if (
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
        dfl_candidate_mask[index] &&
#endif
        decoded_candidates[index].score >= score_threshold)
      candidate_indices[count++] = index;
  memset(suppressed, 0, sizeof(suppressed));
  int emitted = 0;
  while (emitted < 10) {{
    int best = -1;
    for (int i = 0; i < count; i++)
      if (!suppressed[i] && (best < 0 ||
          decoded_candidates[candidate_indices[i]].score >
          decoded_candidates[candidate_indices[best]].score)) best = i;
    if (best < 0) break;
    const struct Detection *best_value =
      &decoded_candidates[candidate_indices[best]];
    output[emitted] = *best_value;
    suppressed[best] = 1;
    for (int i = 0; i < count; i++) {{
      const struct Detection *value =
        &decoded_candidates[candidate_indices[i]];
      if (!suppressed[i] && value->cls == best_value->cls &&
          detection_iou(value, best_value) > iou_threshold) suppressed[i] = 1;
    }}
    emitted++;
  }}
  return emitted;
}}

static void print_nms_detections(const struct Detection output[10], int count,
    float score_threshold, float iou_threshold) {{
  printf("YOLOv5nu NMS detections for %s score_threshold=%.2f iou_threshold=%.2f\\n",
    YOLOV5NU_IMAGE_NAME,score_threshold,iou_threshold);
  for(int i=0;i<count;i++) print_detection("",i,&output[i]);
}}

static void yolo_profile_print_report(uint64_t graph_cycles, uint64_t decode_cycles,
    uint64_t nms_cycles) {{
#if YOLOV5NU_PROFILE
  uint64_t totals[PROFILE_KIND_COUNT]={{0}};
  for(int i=0;i<yolo_profile_record_count;i++) {{
    struct YoloProfileRecord *record=&yolo_profile_records[i];
    totals[record->kind]+=record->cycles;
    printf("YOLOV5NU_PROFILE record=%d kind=%s name=%s cycles=%lu\\n",
      i,record->kind_name,record->name,(unsigned long)record->cycles);
  }}
  uint64_t conv_cycles=totals[PROFILE_CONV_TOTAL];
  uint64_t cpu_cycles=0;
  for(int kind=PROFILE_SIGMOID;kind<=PROFILE_HEAD_DFL;kind++) cpu_cycles+=totals[kind];
  uint64_t layout_cycles=totals[PROFILE_CONV_IN_LAYOUT]+totals[PROFILE_CONV_OUT_LAYOUT];
  printf("YOLOV5NU_PROFILE records=%d graph_cycles=%lu decode_cycles=%lu nms_cycles=%lu\\n",
    yolo_profile_record_count,(unsigned long)graph_cycles,(unsigned long)decode_cycles,
    (unsigned long)nms_cycles);
  printf("YOLOV5NU_PROFILE conv_cycles=%lu cpu_operator_cycles=%lu conv_layout_cycles=%lu gemmini_conv_cycles=%lu\\n",
    (unsigned long)conv_cycles,(unsigned long)cpu_cycles,(unsigned long)layout_cycles,
    (unsigned long)totals[PROFILE_CONV_GEMMINI]);
  printf("YOLOV5NU_PROFILE maxpool_cycles=%lu resize_cycles=%lu concat_cycles=%lu sigmoid_cycles=%lu\\n",
    (unsigned long)totals[PROFILE_MAXPOOL],(unsigned long)totals[PROFILE_RESIZE],
    (unsigned long)totals[PROFILE_CONCAT],(unsigned long)totals[PROFILE_SIGMOID]);
  printf("YOLOV5NU_PROFILE silu_fused_cycles=%lu mul_cycles=%lu add_cycles=%lu\\n",
    (unsigned long)totals[PROFILE_SILU_FUSED_LUT],(unsigned long)totals[PROFILE_MUL],
    (unsigned long)totals[PROFILE_ADD]);
  printf("YOLOV5NU_PROFILE head_class_cycles=%lu head_dfl_cycles=%lu\\n",
    (unsigned long)totals[PROFILE_HEAD_CLASS],(unsigned long)totals[PROFILE_HEAD_DFL]);
  printf("YOLOV5NU_HEAD_CANDIDATES sparse_enabled=%d rvv_max_enabled=%d count=%d "
    "select_cycles=%lu\\n",
    head_dfl_sparse_enabled, head_dfl_candidate_rvv_enabled,
    head_dfl_candidate_count,
    (unsigned long)(head_class_candidate_cycles + head_dfl_candidate_cycles));
  printf("YOLOV5NU_HEAD_PHASE class_requant_cycles=%lu class_sigmoid_cycles=%lu "
    "dfl_requant_cycles=%lu dfl_core_cycles=%lu dfl_rvv_enabled=%d "
    "dfl_batch_enabled=%d dfl_ordered_sum_enabled=%d "
    "dfl_gather_enabled=%d dfl_elementwise_sum_enabled=%d "
    "dfl_unordered_sum_enabled=%d dfl_interleaved_sum_enabled=%d\\n",
    (unsigned long)head_class_requant_cycles,
    (unsigned long)head_class_sigmoid_cycles,
    (unsigned long)head_dfl_requant_cycles,
    (unsigned long)head_dfl_core_cycles,head_dfl_rvv_enabled,
    head_dfl_batch_enabled,head_dfl_ordered_sum_enabled,
    head_dfl_gather_enabled,head_dfl_elementwise_sum_enabled,
    head_dfl_unordered_sum_enabled,head_dfl_interleaved_sum_enabled);
#else
  (void)graph_cycles; (void)decode_cycles; (void)nms_cycles;
#endif
}}

int main(void) {{
  printf("YOLOv5nu Gemmini baremetal image decode test\\n");
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  printf("Input: {input_shape[2]}x{input_shape[3]}x3, output: class[80x{total_head_positions}]+sparse DFL, image: %s\\n",YOLOV5NU_IMAGE_NAME);
#else
  printf("Input: {input_shape[2]}x{input_shape[3]}x3, output: 84x{total_head_positions}, image: %s\\n",YOLOV5NU_IMAGE_NAME);
#endif
  printf("Physical feature layout: {args.physical_layout}\\n");
  printf("SiLU mode: {args.silu_mode}\\n");
  printf("SiLU kernel: {args.silu_kernel}\\n");
  printf("Stage 3 kernel mode: {args.kernel_mode}\\n");
  printf("Stage 3 kernels: copy={stage3_kernels['copy']} add={stage3_kernels['add']} "
    "maxpool={stage3_kernels['maxpool']} resize={stage3_kernels['resize']}\\n");
  printf("Detection head lowering: {args.head_lowering}\\n");
  printf("Detection head kernel: {args.head_kernel}\\n");
  printf("Memory plan stage: {args.memory_stage}\\n");
  gemmini_flush(0);
  yolo_profile_reset();
  {"uint64_t silu_config_cycles[69] = {0};" if gemmini_lut else ""}
  uint64_t graph_start = yolo_profile_clock();
{chr(10).join(calls)}
  uint64_t graph_cycles = yolo_profile_clock() - graph_start;
{chr(10).join(checkpoints)}
  print_tensor_summary("YOLOv5nu class logits", {tensor_ptr(class_logits_name)}, {product(class_logits_shape)});
  print_tensor_summary("YOLOv5nu class sigmoid", {tensor_ptr(class_name)}, {product(tensor_shapes[class_name])});
#if defined(YOLOV5NU_HEAD_OUTPUT_MODE_DETECTION_ONLY)
  print_sparse_dfl_summary("YOLOv5nu DFL distances", {tensor_ptr(dfl_name)},
    dfl_candidate_mask, {total_head_positions});
#else
  print_tensor_summary("YOLOv5nu DFL distances", {tensor_ptr(dfl_name)}, {product(tensor_shapes[dfl_name])});
#endif
  struct Detection top_detections[10];
  struct Detection nms_detections[10];
  uint64_t decode_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
  decode_all_compute({tensor_ptr(dfl_name)}, {c_float(dfl_scale)}, {tensor_ptr(class_name)},
    {c_float(class_scale)});
  decode_top_from_candidates(top_detections);
#else
  decode_top_compute({tensor_ptr(dfl_name)}, {c_float(dfl_scale)}, {tensor_ptr(class_name)},
    {c_float(class_scale)}, top_detections);
#endif
  uint64_t decode_cycles = yolo_profile_clock() - decode_start;
  yolo_profile_add(PROFILE_DECODE, "DECODE", "top", decode_cycles);
  print_top_detections(top_detections);
  uint64_t nms_start = yolo_profile_clock();
#if defined(YOLOV5NU_HEAD_KERNEL_OPTIMIZED_RVV)
  int nms_count = decode_nms_from_candidates({c_float(args.nms_score_threshold)},
    {c_float(args.nms_iou_threshold)}, nms_detections);
#else
  int nms_count = decode_nms_compute({tensor_ptr(dfl_name)}, {c_float(dfl_scale)},
    {tensor_ptr(class_name)}, {c_float(class_scale)}, {c_float(args.nms_score_threshold)},
    {c_float(args.nms_iou_threshold)}, nms_detections);
#endif
  uint64_t nms_cycles = yolo_profile_clock() - nms_start;
  yolo_profile_add(PROFILE_NMS, "NMS", "class_aware_greedy", nms_cycles);
  print_nms_detections(nms_detections, nms_count, {c_float(args.nms_score_threshold)},
    {c_float(args.nms_iou_threshold)});
  yolo_profile_print_report(graph_cycles, decode_cycles, nms_cycles);
  printf("PASS\\n");
  exit(0);
}}
'''
    source_path.write_text(source)
    print(f"Wrote {header_path} ({header_path.stat().st_size / 1024 / 1024:.2f} MiB)")
    print(f"Wrote {source_path}")
    print(
        f"Selected ops: {len(selected)}; Conv: {len(conv_ops)}; "
        f"fused SiLU: {len(fused_mul_to_sigmoid)}; "
        f"activation storage: {sum(product(x) for x in tensor_shapes.values()) / 1024 / 1024:.2f} MiB"
    )
    if memory_report is not None:
        print(
            f"Memory stage {args.memory_stage}: arena={memory_report['arena_bytes'] / 1024 / 1024:.2f} MiB; "
            f"saved={memory_report['reduction_percent']:.2f}%; dead={len(memory_report['dead_tensors'])}; "
            f"inplace={len(memory_report['inplace'])}; direct_concat={len(memory_report['direct_concat'])}"
        )
        print(f"Wrote {memory_path}")


if __name__ == "__main__":
    main()
