#!/usr/bin/env python3
"""Validate fused Stage 4 location-major heads against the QDQ ONNX graph."""

from __future__ import annotations

import argparse
import copy
import json
import tempfile
from pathlib import Path

import numpy as np
import onnx
import onnxruntime as ort
from onnx import helper, numpy_helper

import yolov5nu_stage0_baseline as stage0


BOX_RESHAPES = ("/model.24/Reshape", "/model.24/Reshape_1", "/model.24/Reshape_2")
CLASS_RESHAPES = ("/model.24/Reshape_3", "/model.24/Reshape_4", "/model.24/Reshape_5")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, default=stage0.MODEL)
    parser.add_argument("--manifest", type=Path, default=stage0.MANIFEST)
    parser.add_argument("--image-id", action="append", default=[])
    parser.add_argument("--optimized-kernels", action="store_true")
    return parser.parse_args()


def q_output(op: dict) -> tuple[str, float]:
    record = op["output_quantization"][op["outputs"][0]]
    return record["quantized_tensor"], float(record["scale"])


def head_geometry(operations: dict[str, dict]) -> tuple[list[int], int]:
    """Return each detection head's location count and their combined total."""
    geometry = []
    for name in CLASS_RESHAPES:
        shapes = operations[name].get("output_shapes", {})
        shape = next(iter(shapes.values()), None)
        if shape is None or len(shape) != 3:
            raise ValueError(f"{name}: expected [N,80,locations] output shape, got {shape}")
        locations = int(shape[2])
        geometry.append(locations)
    return geometry, sum(geometry)


def quantize(value: np.ndarray | np.float32, scale: float) -> np.ndarray:
    scaled = np.asarray(value, dtype=np.float32) / np.float32(scale)
    return np.clip(np.rint(scaled), -128, 127).astype(np.int8)


def requantize(value: np.ndarray, src_scale: float, dst_scale: float) -> np.ndarray:
    real = value.astype(np.float32) * np.float32(src_scale)
    return quantize(real, dst_scale)


def sigmoid_lut(input_scale: float, output_scale: float) -> np.ndarray:
    values = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
    logits = np.clip(values * np.float32(input_scale), -80.0, 80.0)
    sigmoid = np.float32(1.0) / (np.float32(1.0) + np.exp(-logits))
    return quantize(sigmoid, output_scale)


def compare(name: str, actual: np.ndarray, expected: np.ndarray) -> None:
    actual = np.asarray(actual, dtype=np.int8).reshape(-1)
    expected = np.asarray(expected, dtype=np.int8).reshape(-1)
    if actual.shape != expected.shape:
        raise ValueError(f"{name}: shape mismatch {actual.shape} != {expected.shape}")
    mismatch = np.flatnonzero(actual != expected)
    if mismatch.size:
        index = int(mismatch[0])
        delta = np.abs(actual.astype(np.int16) - expected.astype(np.int16))
        raise ValueError(
            f"{name}: {mismatch.size}/{actual.size} mismatches, max_error={int(delta.max())}, "
            f"first={index} actual={int(actual[index])} expected={int(expected[index])}"
        )


def main() -> None:
    options = parse_args()
    image_ids = options.image_id or list(stage0.IMAGE_IDS)
    manifest = json.loads(options.manifest.read_text())
    operations = {op["name"]: op for op in manifest["ops"]}
    quantization = manifest["tensor_quantization"]
    model = onnx.load(options.model, load_external_data=True)
    arrays = {item.name: numpy_helper.to_array(item) for item in model.graph.initializer}
    geometry, total_positions = head_geometry(operations)

    if options.optimized_kernels:
        signed = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
        left_values = signed[:, None]
        right_values = signed[None, :]
        add_count = 0
        for op in manifest["ops"]:
            if op["name"] == "/model.24/dfl/Reshape_1":
                break
            if op["op"] != "Add" or not op.get("output_quantization"):
                continue
            input_records = [quantization[name] for name in op["inputs"] if name in quantization]
            if len(input_records) != 2:
                continue
            output_record = op["output_quantization"][op["outputs"][0]]
            left_scale = np.float32(input_records[0]["scale"])
            right_scale = np.float32(input_records[1]["scale"])
            output_scale = np.float32(output_record["scale"])
            baseline = quantize(
                (left_values * left_scale + right_values * right_scale),
                float(output_scale),
            )
            left_ratio = np.float32(float(
                f"{float(input_records[0]['scale']) / float(output_record['scale']):.10g}"
            ))
            right_ratio = np.float32(float(
                f"{float(input_records[1]['scale']) / float(output_record['scale']):.10g}"
            ))
            optimized = quantize(
                left_values * left_ratio + right_values * right_ratio,
                1.0,
            )
            compare(f"ratio Add {op['name']}", optimized, baseline)
            add_count += 1
        if add_count != 7:
            raise ValueError(f"expected 7 pre-DFL Add operators, found {add_count}")
        print("PASS: 7 ratio Add operators match 458752 exhaustive input pairs")

    def input_q(op: dict) -> tuple[str, float]:
        record = quantization[op["inputs"][0]]
        return record["quantized_tensor"], float(record["scale"])

    box_sources = [input_q(operations[name]) for name in BOX_RESHAPES]
    class_sources = [input_q(operations[name]) for name in CLASS_RESHAPES]
    box_concat_name, box_concat_scale = q_output(operations["/model.24/Concat"])
    class_logits_name, class_concat_scale = q_output(operations["/model.24/Concat_1"])
    class_scores_name, class_scale = q_output(operations["/model.24/Sigmoid"])
    softmax_name, softmax_scale = q_output(operations["/model.24/dfl/Softmax"])
    dfl_name, dfl_scale = q_output(operations["/model.24/dfl/Reshape_1"])
    dfl_conv = operations["/model.24/dfl/conv/Conv"]
    weights = arrays[dfl_conv["weight"]["initializer"]].reshape(16).astype(np.int8)
    weight_scale = float(dfl_conv["weight"]["scale"])

    requested = {
        *(name for name, _ in box_sources),
        *(name for name, _ in class_sources),
        box_concat_name,
        class_logits_name,
        class_scores_name,
        softmax_name,
        dfl_name,
    }
    debug_model = copy.deepcopy(model)
    existing = {item.name for item in debug_model.graph.output}
    for name in sorted(requested - existing):
        debug_model.graph.output.append(helper.make_tensor_value_info(name, onnx.TensorProto.INT8, None))

    with tempfile.NamedTemporaryFile(suffix=".onnx") as temporary:
        onnx.save(debug_model, temporary.name)
        session = ort.InferenceSession(temporary.name, providers=["CPUExecutionProvider"])
        input_meta = session.get_inputs()[0]
        output_names = [item.name for item in session.get_outputs()]
        class_lut = sigmoid_lut(class_concat_scale, class_scale)
        signed = np.arange(256, dtype=np.uint8).view(np.int8).astype(np.float32)
        exp_lut = np.exp(-signed * np.float32(box_concat_scale)).astype(np.float32)

        for image_id in image_ids:
            image = stage0.letterbox(
                stage0.image_path(image_id), int(input_meta.shape[2]), int(input_meta.shape[3])
            )
            outputs = dict(zip(output_names, session.run(None, {input_meta.name: image})))

            class_heads = []
            box_heads = []
            for name, scale in class_sources:
                nhwc = outputs[name].transpose(0, 2, 3, 1).reshape(-1, 80)
                class_heads.append(requantize(nhwc, scale, class_concat_scale))
            for name, scale in box_sources:
                nhwc = outputs[name].transpose(0, 2, 3, 1).reshape(-1, 4, 16)
                box_heads.append(requantize(nhwc, scale, box_concat_scale))

            class_logits = np.concatenate(class_heads, axis=0)
            class_scores = class_lut[class_logits.view(np.uint8)]
            target_class_logits = outputs[class_logits_name].reshape(80, total_positions).T
            target_class_scores = outputs[class_scores_name].reshape(80, total_positions).T
            compare("class logits", class_logits, target_class_logits)
            compare("class scores", class_scores, target_class_scores)

            box_logits = np.concatenate(box_heads, axis=0)
            softmax = np.empty_like(box_logits)
            distances = np.empty((total_positions, 4), dtype=np.int8)
            for position in range(total_positions):
                for edge in range(4):
                    logits = box_logits[position, edge]
                    maximum = int(logits.max())
                    exponentials = exp_lut[maximum - logits.astype(np.int16)]
                    total = np.float32(0.0)
                    for item in exponentials:
                        total = np.float32(total + np.float32(item))
                    if options.optimized_kernels:
                        reciprocal = np.float32(1.0) / np.float32(
                            total * np.float32(softmax_scale)
                        )
                        probabilities = quantize(exponentials * reciprocal, 1.0)
                    else:
                        probabilities = quantize(exponentials / total, softmax_scale)
                    softmax[position, edge] = probabilities
                    accumulator = int(
                        np.dot(probabilities.astype(np.int32), weights.astype(np.int32))
                    )
                    real = np.float32(accumulator) * np.float32(softmax_scale)
                    real = np.float32(real * np.float32(weight_scale))
                    distances[position, edge] = quantize(real, dfl_scale)

            target_box_logits = outputs[box_concat_name].reshape(64, total_positions).T.reshape(total_positions, 4, 16)
            target_softmax = outputs[softmax_name].reshape(16, 4, total_positions).transpose(2, 1, 0)
            target_distances = outputs[dfl_name].reshape(4, total_positions).T
            compare("box logits", box_logits, target_box_logits)
            compare("DFL softmax", softmax, target_softmax)
            compare("DFL distances", distances, target_distances)
            print(f"image{image_id}: PASS location-major class and DFL tensors are bit-exact")

    print(f"PASS: validated {len(image_ids)} Stage 4 image(s)")


if __name__ == "__main__":
    main()
