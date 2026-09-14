#!/usr/bin/env python3
"""Export YOLOv5n-U to a statically quantized symmetric INT8 QDQ ONNX model.

The command-line dimensions are WIDTH x HEIGHT. The default 640 x 480 model
therefore has the fixed ONNX input shape [1, 3, 480, 640].
"""

from __future__ import annotations

import argparse
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
        description="Export YOLOv5n-U as a fixed-shape symmetric INT8 QDQ ONNX model."
    )
    parser.add_argument(
        "--weights",
        type=Path,
        default=script_dir / "yolov5nu.pt",
        help="source Ultralytics .pt checkpoint",
    )
    parser.add_argument(
        "--calibration-data",
        type=Path,
        required=True,
        help="an image file or directory containing representative images",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=script_dir / "yolov5nu-int8-symmetric-img640x480.onnx",
        help="output INT8 ONNX path",
    )
    parser.add_argument("--width", type=int, default=640, help="input width")
    parser.add_argument("--height", type=int, default=480, help="input height")
    parser.add_argument(
        "--calibration-samples",
        type=int,
        default=100,
        help="maximum number of calibration images",
    )
    parser.add_argument("--opset", type=int, default=13, help="ONNX opset")
    parser.add_argument(
        "--calibration-method",
        choices=("minmax", "entropy", "percentile"),
        default="minmax",
        help="ONNX Runtime calibration algorithm",
    )
    parser.add_argument(
        "--keep-fp32",
        type=Path,
        help="optionally retain the intermediate FP32 ONNX at this path",
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
        raise ValueError("output must not overwrite the source checkpoint")


def find_images(path: Path, limit: int) -> list[Path]:
    if path.is_file():
        images = [path] if path.suffix.lower() in IMAGE_SUFFIXES else []
    else:
        images = sorted(
            p for p in path.rglob("*") if p.is_file() and p.suffix.lower() in IMAGE_SUFFIXES
        )
    if not images:
        raise ValueError(f"no supported calibration images found in {path}")

    # Sample the full sorted data set instead of taking only its first entries.
    if len(images) > limit:
        indices = np.linspace(0, len(images) - 1, num=limit, dtype=int)
        images = [images[index] for index in indices]
    return images


def letterbox(image: np.ndarray, height: int, width: int) -> np.ndarray:
    """Apply Ultralytics-compatible, centered letterbox resizing."""
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
        image,
        top,
        bottom,
        left,
        right,
        cv2.BORDER_CONSTANT,
        value=(114, 114, 114),
    )


def preprocess_image(path: Path, height: int, width: int) -> np.ndarray:
    image = cv2.imread(str(path), cv2.IMREAD_COLOR)
    if image is None:
        raise ValueError(f"failed to decode calibration image: {path}")
    image = letterbox(image, height, width)
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image = np.ascontiguousarray(image.transpose(2, 0, 1), dtype=np.float32) / 255.0
    return image[np.newaxis]


class YoloCalibrationReader(CalibrationDataReader):
    def __init__(self, input_name: str, images: list[Path], height: int, width: int):
        self.input_name = input_name
        self.images = images
        self.height = height
        self.width = width
        self._iterator = iter(())
        self.rewind()

    def _samples(self):
        for image in self.images:
            yield {self.input_name: preprocess_image(image, self.height, self.width)}

    def get_next(self) -> dict[str, np.ndarray] | None:
        return next(self._iterator, None)

    def rewind(self) -> None:
        self._iterator = iter(self._samples())


def export_fp32(weights: Path, destination: Path, height: int, width: int, opset: int) -> None:
    # Ultralytics writes beside the checkpoint, so use a temporary checkpoint copy.
    temporary_weights = destination.parent / weights.name
    shutil.copy2(weights, temporary_weights)
    exported = YOLO(str(temporary_weights)).export(
        format="onnx",
        imgsz=(height, width),
        batch=1,
        opset=opset,
        dynamic=False,
        simplify=False,
        device="cpu",
    )
    exported_path = Path(exported)
    if exported_path.resolve() != destination.resolve():
        shutil.move(exported_path, destination)


def model_input_name(model_path: Path) -> str:
    model = onnx.load(model_path, load_external_data=False)
    initializer_names = {item.name for item in model.graph.initializer}
    inputs = [item.name for item in model.graph.input if item.name not in initializer_names]
    if len(inputs) != 1:
        raise ValueError(f"expected one model input, found {inputs}")
    return inputs[0]


def quantize(fp32_path: Path, output: Path, reader: YoloCalibrationReader, method: str) -> None:
    methods = {
        "minmax": CalibrationMethod.MinMax,
        "entropy": CalibrationMethod.Entropy,
        "percentile": CalibrationMethod.Percentile,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    quantize_static(
        model_input=fp32_path,
        model_output=output,
        calibration_data_reader=reader,
        quant_format=QuantFormat.QDQ,
        activation_type=QuantType.QInt8,
        weight_type=QuantType.QInt8,
        per_channel=True,
        calibrate_method=methods[method],
        extra_options={
            "ActivationSymmetric": True,
            "WeightSymmetric": True,
        },
    )


def tensor_shape(value_info: onnx.ValueInfoProto) -> list[int | str]:
    return [dimension.dim_value or dimension.dim_param for dimension in value_info.type.tensor_type.shape.dim]


def verify_model(path: Path, sample_image: Path, height: int, width: int) -> None:
    model = onnx.load(path)
    onnx.checker.check_model(model)
    input_shape = tensor_shape(model.graph.input[0])
    expected_shape = [1, 3, height, width]
    if input_shape != expected_shape:
        raise ValueError(f"unexpected input shape {input_shape}; expected {expected_shape}")

    initializers = {initializer.name: initializer for initializer in model.graph.initializer}
    zero_point_names = {
        node.input[2]
        for node in model.graph.node
        if node.op_type in {"QuantizeLinear", "DequantizeLinear"} and len(node.input) >= 3
    }
    for name in zero_point_names:
        zero_point = initializers.get(name)
        if zero_point is None:
            continue
        values = onnx.numpy_helper.to_array(zero_point)
        if np.any(values != 0):
            raise ValueError(f"quantization zero point is not symmetric: {name}")
        if zero_point.data_type not in {onnx.TensorProto.INT8, onnx.TensorProto.INT32}:
            raise ValueError(f"unexpected symmetric zero-point data type: {name}")

    # Creating a session also checks that ONNX Runtime accepts the quantized graph.
    session = ort.InferenceSession(str(path), providers=["CPUExecutionProvider"])
    output_shapes = [output.shape for output in session.get_outputs()]
    outputs = session.run(None, {session.get_inputs()[0].name: preprocess_image(sample_image, height, width)})
    if not outputs or not all(np.isfinite(output).all() for output in outputs):
        raise ValueError("ONNX Runtime inference produced an empty or non-finite output")
    operators = Counter(node.op_type for node in model.graph.node)
    print(f"Created: {path.resolve()}")
    print(f"Input:   {session.get_inputs()[0].name} {input_shape}")
    print(f"Output:  {output_shapes}")
    print(f"Nodes:   {len(model.graph.node)}")
    print(f"Quant:   symmetric INT8 (all {len(zero_point_names)} zero points are 0)")
    print(
        "QDQ:     "
        f"QuantizeLinear={operators['QuantizeLinear']}, "
        f"DequantizeLinear={operators['DequantizeLinear']}, Conv={operators['Conv']}"
    )


def main() -> None:
    args = parse_args()
    validate_args(args)
    images = find_images(args.calibration_data, args.calibration_samples)
    print(f"Using {len(images)} calibration image(s)")

    with tempfile.TemporaryDirectory(prefix="yolov5nu-export-") as temporary_directory:
        fp32_path = Path(temporary_directory) / "yolov5nu-fp32.onnx"
        export_fp32(args.weights.resolve(), fp32_path, args.height, args.width, args.opset)

        input_name = model_input_name(fp32_path)
        reader = YoloCalibrationReader(input_name, images, args.height, args.width)
        quantize(fp32_path, args.output.resolve(), reader, args.calibration_method)

        if args.keep_fp32:
            args.keep_fp32.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(fp32_path, args.keep_fp32)
            print(f"Retained FP32 model: {args.keep_fp32.resolve()}")

    verify_model(args.output.resolve(), images[0], args.height, args.width)


if __name__ == "__main__":
    main()
