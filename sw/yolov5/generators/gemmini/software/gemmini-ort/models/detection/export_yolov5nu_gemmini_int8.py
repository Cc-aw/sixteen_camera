#!/usr/bin/env python3
"""Export YOLOv5n-U for the signed-int8 Gemmini baremetal compiler path.

The output is a fixed-shape QDQ ONNX reference model, not a directly executable
Gemmini program. It enforces the first compiler target:

* input and activations: per-tensor symmetric QInt8, zero point 0
* weights: per-tensor symmetric QInt8, zero point 0
* bias: QDQ-generated Int32 where applicable
* preprocessing: Ultralytics-compatible RGB letterbox and /255 normalization
"""

from __future__ import annotations

import argparse
import json
import shutil
import tempfile
from collections import Counter
from pathlib import Path

import cv2
import numpy as np
import onnx
import onnxruntime as ort
from onnxruntime.quantization import (
    CalibrationDataReader,
    CalibrationMethod,
    QuantFormat,
    QuantType,
    quantize_static,
)
from ultralytics import YOLO


IMAGE_SUFFIXES = {".bmp", ".jpeg", ".jpg", ".png", ".tif", ".tiff", ".webp"}


def parse_args() -> argparse.Namespace:
    script_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(
        description="Export YOLOv5n-U as fixed-shape Gemmini-targeted symmetric INT8 QDQ ONNX."
    )
    parser.add_argument(
        "--weights",
        type=Path,
        default=script_dir / "yolov5nu.pt",
        help="source Ultralytics YOLOv5n-U checkpoint",
    )
    parser.add_argument(
        "--calibration-data",
        type=Path,
        default=script_dir / "calibration/coco128/images/train2017",
        help="representative image file or directory",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=script_dir / "yolov5nu-gemmini-int8-img320.onnx",
        help="output QDQ ONNX path",
    )
    parser.add_argument(
        "--report",
        type=Path,
        help="output JSON quantization audit path; defaults beside --output",
    )
    parser.add_argument(
        "--keep-fp32",
        type=Path,
        help="optionally retain the intermediate fixed-shape FP32 ONNX",
    )
    parser.add_argument("--width", type=int, default=320, help="fixed input width")
    parser.add_argument("--height", type=int, default=320, help="fixed input height")
    parser.add_argument(
        "--calibration-samples",
        type=int,
        default=128,
        help="maximum calibration images sampled across the sorted data set",
    )
    parser.add_argument("--opset", type=int, default=13, help="ONNX opset")
    parser.add_argument(
        "--calibration-method",
        choices=("minmax", "entropy", "percentile"),
        default="minmax",
        help="ONNX Runtime calibration algorithm",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="replace an existing ONNX/report output",
    )
    return parser.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    if not args.weights.is_file():
        raise FileNotFoundError(f"weights not found: {args.weights}")
    if not args.calibration_data.exists():
        raise FileNotFoundError(f"calibration data not found: {args.calibration_data}")
    if args.width <= 0 or args.height <= 0:
        raise ValueError("width and height must be positive")
    if args.width % 32 or args.height % 32:
        raise ValueError("YOLOv5 input width and height must be divisible by stride 32")
    if args.calibration_samples <= 0:
        raise ValueError("calibration-samples must be positive")
    if args.output.resolve() == args.weights.resolve():
        raise ValueError("output must not overwrite source weights")


def find_images(path: Path, limit: int) -> list[Path]:
    if path.is_file():
        images = [path] if path.suffix.lower() in IMAGE_SUFFIXES else []
    else:
        images = sorted(
            image for image in path.rglob("*")
            if image.is_file() and image.suffix.lower() in IMAGE_SUFFIXES
        )
    if not images:
        raise ValueError(f"no supported calibration images found in {path}")

    if len(images) > limit:
        indices = np.linspace(0, len(images) - 1, num=limit, dtype=int)
        images = [images[index] for index in indices]
    return images


def letterbox(image: np.ndarray, height: int, width: int) -> np.ndarray:
    """Apply centered Ultralytics-compatible letterboxing."""
    source_height, source_width = image.shape[:2]
    ratio = min(height / source_height, width / source_width)
    resized_width = round(source_width * ratio)
    resized_height = round(source_height * ratio)

    if (resized_width, resized_height) != (source_width, source_height):
        image = cv2.resize(image, (resized_width, resized_height), interpolation=cv2.INTER_LINEAR)

    pad_width = (width - resized_width) / 2
    pad_height = (height - resized_height) / 2
    left, right = round(pad_width - 0.1), round(pad_width + 0.1)
    top, bottom = round(pad_height - 0.1), round(pad_height + 0.1)
    return cv2.copyMakeBorder(
        image, top, bottom, left, right, cv2.BORDER_CONSTANT, value=(114, 114, 114)
    )


def preprocess_image(path: Path, height: int, width: int) -> np.ndarray:
    image = cv2.imread(str(path), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(f"failed to decode image: {path}")
    image = letterbox(image, height, width)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    nchw = np.ascontiguousarray(image.transpose(2, 0, 1), dtype=np.float32) / 255.0
    return nchw[np.newaxis]


class CalibrationReader(CalibrationDataReader):
    def __init__(self, input_name: str, images: list[Path], height: int, width: int):
        self.input_name = input_name
        self.images = images
        self.height = height
        self.width = width
        self.rewind()

    def get_next(self) -> dict[str, np.ndarray] | None:
        return next(self._iterator, None)

    def rewind(self) -> None:
        self._iterator = iter(
            {
                self.input_name: preprocess_image(image, self.height, self.width)
            }
            for image in self.images
        )


def export_fp32(weights: Path, destination: Path, height: int, width: int, opset: int) -> None:
    """Export beside a temporary checkpoint so the source checkpoint remains untouched."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary_weights = destination.parent / weights.name
    shutil.copy2(weights, temporary_weights)
    exported = Path(
        YOLO(str(temporary_weights)).export(
            format="onnx",
            imgsz=(height, width),
            batch=1,
            opset=opset,
            dynamic=False,
            simplify=False,
            device="cpu",
        )
    )
    if not exported.is_file():
        raise RuntimeError(f"Ultralytics export did not create {exported}")
    if exported.resolve() != destination.resolve():
        shutil.move(str(exported), str(destination))


def model_input_name(model_path: Path) -> str:
    model = onnx.load(model_path, load_external_data=False)
    initializers = {initializer.name for initializer in model.graph.initializer}
    inputs = [item.name for item in model.graph.input if item.name not in initializers]
    if len(inputs) != 1:
        raise ValueError(f"expected one model input, found {inputs}")
    return inputs[0]


def quantize(fp32_path: Path, output: Path, reader: CalibrationReader, method: str) -> None:
    methods = {
        "minmax": CalibrationMethod.MinMax,
        "entropy": CalibrationMethod.Entropy,
        "percentile": CalibrationMethod.Percentile,
    }
    quantize_static(
        model_input=fp32_path,
        model_output=output,
        calibration_data_reader=reader,
        quant_format=QuantFormat.QDQ,
        activation_type=QuantType.QInt8,
        weight_type=QuantType.QInt8,
        per_channel=False,
        calibrate_method=methods[method],
        extra_options={
            "ActivationSymmetric": True,
            "WeightSymmetric": True,
        },
    )


def shape(value_info: onnx.ValueInfoProto) -> list[int | str]:
    return [
        dimension.dim_value or dimension.dim_param or "?"
        for dimension in value_info.type.tensor_type.shape.dim
    ]


def audit_quantization(
    model_path: Path,
    sample_image: Path,
    height: int,
    width: int,
    calibration_images: list[Path],
) -> dict[str, object]:
    model = onnx.load(model_path, load_external_data=False)
    onnx.checker.check_model(model)

    initializers = {initializer.name: initializer for initializer in model.graph.initializer}
    arrays = {
        name: onnx.numpy_helper.to_array(initializer)
        for name, initializer in initializers.items()
    }
    graph_inputs = [item for item in model.graph.input if item.name not in initializers]
    if len(graph_inputs) != 1:
        raise ValueError(f"expected one graph input, found {[item.name for item in graph_inputs]}")

    expected_input_shape = [1, 3, height, width]
    if shape(graph_inputs[0]) != expected_input_shape:
        raise ValueError(
            f"unexpected input shape {shape(graph_inputs[0])}; expected {expected_input_shape}"
        )

    qdq_nodes = [
        node for node in model.graph.node
        if node.op_type in {"QuantizeLinear", "DequantizeLinear"}
    ]
    if not qdq_nodes:
        raise ValueError("missing QDQ nodes")

    zero_point_names = set()
    non_scalar_scale_nodes = []
    nonzero_zero_points = []
    unexpected_zero_point_types = []
    weight_scale_shapes = []

    for node in qdq_nodes:
        if len(node.input) < 3:
            raise ValueError(f"QDQ node has no zero point: {node.name}")
        scale = arrays.get(node.input[1])
        zero_point = arrays.get(node.input[2])
        if scale is None or zero_point is None:
            raise ValueError(f"QDQ node has non-initializer quantization parameters: {node.name}")

        zero_point_names.add(node.input[2])
        # ONNX Runtime serializes a per-tensor Conv bias scale as [1]. It is
        # semantically scalar and does not imply per-output-channel scaling.
        is_bias = node.op_type == "DequantizeLinear" and "bias" in node.input[0]
        if scale.shape != () and not (is_bias and scale.shape == (1,)):
            non_scalar_scale_nodes.append((node.name, node.input[1], list(scale.shape)))
        if np.any(zero_point != 0):
            nonzero_zero_points.append(node.input[2])
        if zero_point.dtype not in (np.dtype(np.int8), np.dtype(np.int32)):
            unexpected_zero_point_types.append((node.input[2], str(zero_point.dtype)))

        if node.op_type == "DequantizeLinear" and "weight" in node.input[0]:
            weight_scale_shapes.append(list(scale.shape))

    if nonzero_zero_points:
        raise ValueError(f"nonzero QDQ zero points: {sorted(set(nonzero_zero_points))}")
    if unexpected_zero_point_types:
        raise ValueError(f"unexpected QDQ zero point types: {unexpected_zero_point_types}")
    if non_scalar_scale_nodes:
        raise ValueError(
            "per-channel or non-scalar QDQ scale found: "
            f"{non_scalar_scale_nodes[:4]}"
        )
    if not weight_scale_shapes:
        raise ValueError("could not find quantized convolution weights")
    if any(weight_shape != [] for weight_shape in weight_scale_shapes):
        raise ValueError(f"weight quantization is not per-tensor: {weight_scale_shapes[:4]}")

    session = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
    outputs = session.run(
        None,
        {session.get_inputs()[0].name: preprocess_image(sample_image, height, width)},
    )
    if not outputs or not all(np.isfinite(output).all() for output in outputs):
        raise ValueError("ONNX Runtime inference produced an empty or non-finite output")

    operators = Counter(node.op_type for node in model.graph.node)
    return {
        "model": str(model_path.resolve()),
        "input": {
            "name": graph_inputs[0].name,
            "shape": expected_input_shape,
            "preprocess": "RGB letterbox pad=114, NCHW float32 / 255.0",
        },
        "outputs": [
            {
                "name": value.name,
                "shape": list(output.shape),
                "dtype": str(output.dtype),
                "min": float(output.min()),
                "max": float(output.max()),
            }
            for value, output in zip(session.get_outputs(), outputs)
        ],
        "calibration_images": [str(image.resolve()) for image in calibration_images],
        "quantization": {
            "format": "QDQ",
            "activation": "per-tensor symmetric QInt8",
            "weight": "per-tensor symmetric QInt8",
            "zero_point": 0,
            "q_nodes": sum(node.op_type == "QuantizeLinear" for node in qdq_nodes),
            "dq_nodes": sum(node.op_type == "DequantizeLinear" for node in qdq_nodes),
            "zero_point_tensors": len(zero_point_names),
            "weight_qdq_tensors": len(weight_scale_shapes),
        },
        "operators": dict(sorted(operators.items())),
        "verification_image": str(sample_image.resolve()),
    }


def main() -> None:
    args = parse_args()
    validate_args(args)

    output = args.output.resolve()
    report = (args.report or output.with_suffix(".quant.json")).resolve()
    if not args.force:
        existing = [path for path in (output, report) if path.exists()]
        if existing:
            raise FileExistsError(
                f"refusing to overwrite {', '.join(str(path) for path in existing)}; use --force"
            )

    images = find_images(args.calibration_data.resolve(), args.calibration_samples)
    print(f"Using {len(images)} calibration images")
    print("Quantization: activation=per-tensor QInt8, weight=per-tensor QInt8, zero_point=0")
    print(f"Export target: {output}")

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="yolov5nu-gemmini-export-") as temp_dir:
        fp32_path = Path(temp_dir) / "yolov5nu-fp32.onnx"
        export_fp32(args.weights.resolve(), fp32_path, args.height, args.width, args.opset)
        input_name = model_input_name(fp32_path)
        quantize(
            fp32_path,
            output,
            CalibrationReader(input_name, images, args.height, args.width),
            args.calibration_method,
        )
        if args.keep_fp32:
            keep_fp32 = args.keep_fp32.resolve()
            if keep_fp32.exists() and not args.force:
                raise FileExistsError(f"refusing to overwrite {keep_fp32}; use --force")
            keep_fp32.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(fp32_path, keep_fp32)
            print(f"Retained FP32 model: {keep_fp32}")

    audit = audit_quantization(output, images[0], args.height, args.width, images)
    report.write_text(json.dumps(audit, indent=2) + "\n", encoding="utf-8")
    print(f"Verified QDQ model: {output}")
    print(f"Audit report: {report}")
    print(
        "QDQ summary: "
        f"Q={audit['quantization']['q_nodes']} "
        f"DQ={audit['quantization']['dq_nodes']} "
        f"Conv={audit['operators'].get('Conv', 0)}"
    )


if __name__ == "__main__":
    main()
