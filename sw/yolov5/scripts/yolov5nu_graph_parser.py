#!/usr/bin/env python3
"""Convert the fixed-shape YOLOv5nu QDQ ONNX graph into a compiler manifest.

The manifest deliberately preserves ONNX tensor names and QDQ boundaries.  It
is an intermediate representation for the baremetal generator, not another
ONNX serializer.  Keeping the quantized initializer names in the manifest
makes it possible to reproduce a parameter header from exactly the checked
ONNX file.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any

import numpy as np
import onnx
from onnx import numpy_helper, shape_inference


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MODEL = (
    ROOT
    / "generators/gemmini/software/gemmini-ort/models/detection/"
    "yolov5nu-gemmini-int8-img320.onnx"
)
DEFAULT_OUTPUT = DEFAULT_MODEL.with_suffix(".graph.json")

COMPUTE_OPS = {
    "Conv",
    "Sigmoid",
    "Mul",
    "Add",
    "Concat",
    "MaxPool",
    "Resize",
    "Reshape",
    "Transpose",
    "Softmax",
    "Shape",
    "Gather",
    "Div",
    "Slice",
    "Sub",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--allow-unsupported",
        action="store_true",
        help="record unexpected non-QDQ ops rather than rejecting the graph",
    )
    return parser.parse_args()


def numeric_shape(value: onnx.ValueInfoProto) -> list[int | str]:
    return [
        int(dim.dim_value) if dim.dim_value else (dim.dim_param or "?")
        for dim in value.type.tensor_type.shape.dim
    ]


def attr_value(attribute: onnx.AttributeProto) -> Any:
    value = onnx.helper.get_attribute_value(attribute)
    if isinstance(value, onnx.TensorProto):
        return numpy_helper.to_array(value).reshape(-1).tolist()
    if isinstance(value, bytes):
        return value.decode("utf-8")
    if isinstance(value, np.ndarray):
        return value.tolist()
    if isinstance(value, (np.generic,)):
        return value.item()
    return value


def scalar(array: np.ndarray, context: str) -> float | int:
    if array.size != 1:
        raise ValueError(f"{context} must be scalar, got shape {array.shape}")
    return array.reshape(-1)[0].item()


def logical_layout(shape: list[int | str]) -> str:
    if len(shape) == 4:
        return "NCHW"
    if len(shape) == 3:
        return "NCL"
    return f"RANK{len(shape)}"


def nhwc_candidate_layout(
    shape: list[int | str], producer_name: str | None, producer_op: str | None
) -> dict[str, Any]:
    numeric = all(isinstance(dim, int) for dim in shape)
    feature_map = (
        len(shape) == 4
        and numeric
        and not (producer_name or "").startswith("/model.24/dfl/")
        and producer_op not in {"Reshape", "Transpose", "Softmax"}
    )
    if feature_map:
        n, c, h, w = shape
        return {
            "physical_layout": "NHWC",
            "physical_shape": [n, h, w, c],
            "logical_to_physical_axis": [0, 3, 1, 2],
        }
    return {
        "physical_layout": logical_layout(shape),
        "physical_shape": shape,
        "logical_to_physical_axis": list(range(len(shape))),
    }


def main() -> None:
    args = parse_args()
    if not args.model.is_file():
        raise FileNotFoundError(f"ONNX model not found: {args.model}")

    model = onnx.load(args.model, load_external_data=True)
    onnx.checker.check_model(model)
    inferred = shape_inference.infer_shapes(model)
    graph = inferred.graph
    arrays = {item.name: numpy_helper.to_array(item) for item in graph.initializer}
    producer = {output: node for node in graph.node for output in node.output if output}

    shapes = {
        value.name: numeric_shape(value)
        for value in list(graph.input) + list(graph.output) + list(graph.value_info)
    }
    initializers = set(arrays)
    graph_inputs = [value for value in graph.input if value.name not in initializers]

    quant_by_float: dict[str, dict[str, Any]] = {}
    dq_by_output: dict[str, dict[str, Any]] = {}
    for node in graph.node:
        if node.op_type not in {"QuantizeLinear", "DequantizeLinear"}:
            continue
        if len(node.input) < 3:
            raise ValueError(f"{node.name} lacks explicit scale/zero point")
        scale_name, zero_name = node.input[1], node.input[2]
        if scale_name not in arrays or zero_name not in arrays:
            raise ValueError(f"{node.name} scale or zero point is not an initializer")
        scale = scalar(arrays[scale_name], f"{node.name} scale")
        zero = scalar(arrays[zero_name], f"{node.name} zero point")
        if zero != 0:
            raise ValueError(f"{node.name} violates Gemmini symmetric quantization: zero_point={zero}")
        record = {
            "quantized_tensor": node.output[0] if node.op_type == "QuantizeLinear" else node.input[0],
            "scale_initializer": scale_name,
            "zero_point_initializer": zero_name,
            "scale": float(scale),
            "zero_point": int(zero),
            "dtype": str(arrays[zero_name].dtype),
        }
        if node.op_type == "QuantizeLinear":
            quant_by_float[node.input[0]] = record
        else:
            dq_by_output[node.output[0]] = record

    def qdq_input(tensor: str, context: str) -> dict[str, Any]:
        if tensor in dq_by_output:
            return dq_by_output[tensor]
        raise ValueError(f"{context}: expected DequantizeLinear input, got {tensor}")

    def quantized_initializer(tensor: str, context: str) -> dict[str, Any]:
        record = qdq_input(tensor, context)
        name = record["quantized_tensor"]
        if name not in arrays:
            raise ValueError(f"{context}: {name} is not an initializer")
        value = arrays[name]
        return {
            **record,
            "initializer": name,
            "shape": list(value.shape),
            "dtype": str(value.dtype),
            "elements": int(value.size),
        }

    ops: list[dict[str, Any]] = []
    unsupported: list[str] = []
    conv_index = 0
    for index, node in enumerate(graph.node):
        if node.op_type in {"Constant", "QuantizeLinear", "DequantizeLinear"}:
            continue
        if node.op_type not in COMPUTE_OPS:
            unsupported.append(f"{index}:{node.op_type}:{node.name}")
            continue

        record: dict[str, Any] = {
            "index": index,
            "op": node.op_type,
            "name": node.name,
            "inputs": [name for name in node.input if name],
            "outputs": [name for name in node.output if name],
            "attributes": {item.name: attr_value(item) for item in node.attribute},
        }
        for output in record["outputs"]:
            if output in shapes:
                record.setdefault("output_shapes", {})[output] = shapes[output]
            if output in quant_by_float:
                record.setdefault("output_quantization", {})[output] = quant_by_float[output]

        if node.op_type == "Conv":
            if len(node.input) not in {2, 3}:
                raise ValueError(f"{node.name}: expected 2 or 3 Conv inputs")
            weight = quantized_initializer(node.input[1], node.name + " weight")
            if weight["dtype"] != "int8":
                raise ValueError(f"{node.name}: expected int8 weight, got {weight['dtype']}")
            if len(weight["shape"]) != 4:
                raise ValueError(f"{node.name}: expected OIHW weight, got {weight['shape']}")
            record["conv_index"] = conv_index
            record["input_quantization"] = qdq_input(node.input[0], node.name + " activation")
            record["weight"] = weight
            record["bias"] = (
                quantized_initializer(node.input[2], node.name + " bias")
                if len(node.input) == 3
                else None
            )
            if record["bias"] and record["bias"]["dtype"] != "int32":
                raise ValueError(f"{node.name}: expected int32 bias, got {record['bias']['dtype']}")
            if not record.get("output_quantization"):
                raise ValueError(f"{node.name}: Conv output has no QuantizeLinear boundary")
            conv_index += 1
        ops.append(record)

    if unsupported and not args.allow_unsupported:
        raise ValueError("unsupported nodes: " + "; ".join(unsupported))

    tensor_layouts: dict[str, dict[str, Any]] = {}
    for value in graph_inputs:
        quantization = quant_by_float.get(value.name)
        if not quantization:
            continue
        shape = shapes[value.name]
        tensor_layouts[quantization["quantized_tensor"]] = {
            "logical_shape": shape,
            "logical_layout": logical_layout(shape),
            "nhwc_resident": nhwc_candidate_layout(shape, None, "Input"),
            "producer": "graph_input",
        }
    for op in ops:
        for output, quantization in op.get("output_quantization", {}).items():
            shape = op.get("output_shapes", {}).get(output)
            if not shape:
                continue
            tensor_layouts[quantization["quantized_tensor"]] = {
                "logical_shape": shape,
                "logical_layout": logical_layout(shape),
                "nhwc_resident": nhwc_candidate_layout(shape, op["name"], op["op"]),
                "producer": op["name"],
            }

    manifest = {
        "format": "yolov5nu-gemmini-qnn-manifest-v1",
        "source_model": str(args.model.resolve()),
        "input": [
            {"name": value.name, "shape": shapes[value.name], "quantization": quant_by_float.get(value.name)}
            for value in graph_inputs
        ],
        "output": [
            {"name": value.name, "shape": shapes[value.name], "quantization": dq_by_output.get(value.name)}
            for value in graph.output
        ],
        "node_counts": dict(Counter(node.op_type for node in graph.node)),
        "conv_count": conv_index,
        "tensor_quantization": {
            name: record for name, record in sorted(dq_by_output.items())
        },
        "tensor_layouts": tensor_layouts,
        "ops": ops,
        "unsupported": unsupported,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"Wrote {args.output}")
    print(f"Conv nodes: {conv_index}; compute nodes: {len(ops)}")
    print("Node counts: " + ", ".join(f"{name}={count}" for name, count in sorted(manifest["node_counts"].items())))


if __name__ == "__main__":
    main()
