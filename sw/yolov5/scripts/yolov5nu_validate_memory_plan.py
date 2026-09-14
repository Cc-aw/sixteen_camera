#!/usr/bin/env python3
"""Validate one generated YOLOv5nu Stage 5 arena plan and C source."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


EXPECTED = {
    "5a": {"dead": 0, "inplace": 0, "direct": 0},
    "5b": {"dead": 79, "inplace": 0, "direct": 0},
    "5c": {"dead": 79, "inplace": 76, "direct": 0},
    "5d": {"dead": 88, "inplace": 67, "direct": 9},
}

GEMMINI_LUT_EXPECTED = {
    "5d": {"dead": 157, "inplace": 6, "direct": 9},
}

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--parameters", type=Path, required=True)
    parser.add_argument("--memory-plan", type=Path, required=True)
    return parser.parse_args()


def main() -> None:
    options = parse_args()
    source = options.source.read_text()
    parameters = options.parameters.read_text()
    plan = json.loads(options.memory_plan.read_text())
    stage = plan["stage"]
    if stage not in EXPECTED:
        raise ValueError(f"unexpected memory stage: {stage}")
    gemmini_lut = "YOLOV5NU_SILU_KERNEL_GEMMINI_LUT 1" in parameters
    stage7a = "YOLOV5NU_STAGE7_MODE_7A 1" in parameters
    stage7b = "YOLOV5NU_STAGE7_MODE_7B 1" in parameters
    stage7b_lut = "YOLOV5NU_STAGE7_MODE_7B_LUT 1" in parameters
    stage7b_register = "YOLOV5NU_STAGE7_MODE_7B_REGISTER 1" in parameters
    stage7c = "YOLOV5NU_STAGE7_MODE_7C 1" in parameters
    stage7d = "YOLOV5NU_STAGE7_MODE_7D 1" in parameters
    stage7bc = "YOLOV5NU_STAGE7_MODE_7BC 1" in parameters
    stage7e = "YOLOV5NU_STAGE7_MODE_7E 1" in parameters
    stage7 = stage7a or stage7b or stage7b_lut or stage7b_register or stage7c or stage7d or stage7bc or stage7e
    expected = None if stage7 else (GEMMINI_LUT_EXPECTED.get(stage) if gemmini_lut else EXPECTED[stage])
    if expected is None and not stage7:
        raise ValueError(f"Gemmini LUT memory contract is not defined for {stage}")
    actual = {
        "dead": len(plan["dead_tensors"]),
        "inplace": len(plan["inplace"]),
        "direct": len(plan["direct_concat"]),
    }
    if not stage7 and actual != expected:
        raise ValueError(f"{stage}: plan contract {actual} != {expected}")
    if stage7:
        expected_direct = 9 if (stage7c or stage7d) else (11 if stage7a else 14)
        if actual["direct"] != expected_direct:
            raise ValueError(f"{stage}: Stage 7 direct-Concat contract {actual}")
    if plan["arena_elements"] <= 0 or plan["arena_elements"] % plan["alignment_elements"]:
        raise ValueError("arena size is empty or misaligned")
    if len(re.findall(r"^static elem_t activation_arena\[", source, re.MULTILINE)) != 1:
        raise ValueError("source must contain exactly one activation arena")
    if re.search(r"^static elem_t tensor_\d+\[", source, re.MULTILINE):
        raise ValueError("source still contains independent tensor arrays")
    if f"Memory plan stage: {stage}" not in source:
        raise ValueError("source lacks the memory-stage UART marker")
    if f"YOLOV5NU_MEMORY_STAGE_{stage.upper()} 1" not in parameters:
        raise ValueError("parameter header lacks memory-stage marker")

    roots: dict[str, dict] = {}
    for tensor in plan["tensors"]:
        roots.setdefault(tensor["root"], tensor)
        if tensor["offset"] % plan["alignment_elements"]:
            raise ValueError(f"misaligned tensor: {tensor['name']}")
        if tensor["offset"] + tensor["root_size"] > plan["arena_elements"]:
            raise ValueError(f"tensor exceeds arena: {tensor['name']}")
    values = list(roots.values())
    for index, left in enumerate(values):
        for right in values[index + 1:]:
            live_overlap = not (
                left["last_use"] < right["birth"] or
                right["last_use"] < left["birth"]
            )
            memory_overlap = max(left["offset"], right["offset"]) < min(
                left["offset"] + left["root_size"],
                right["offset"] + right["root_size"],
            )
            if live_overlap and memory_overlap:
                raise ValueError(
                    f"live arena overlap: {left['root']} and {right['root']}"
                )

    if stage == "5d":
        for record in plan["direct_concat"]:
            if record["offset"] < 0 or record["offset"] + record["channels"] > record["output_stride"]:
                raise ValueError(f"invalid direct Concat slice: {record}")
        expected_strided_silu = 0 if gemmini_lut else 8
        if source.count("silu_lut_i8_strided(") - 1 != expected_strided_silu:
            raise ValueError(f"expected {expected_strided_silu} strided SiLU calls")
        expected_strided_add = 0 if stage7d or stage7e else 1
        if source.count("add_ratio_i8_strided(") - 1 != expected_strided_add:
            raise ValueError(f"expected {expected_strided_add} strided Add calls")
        expected_gemmini_direct = 8 if gemmini_lut else 0
        if source.count("GEMMINI_SILU_DIRECT_CONCAT") != expected_gemmini_direct:
            raise ValueError(
                f"expected {expected_gemmini_direct} Gemmini direct-Concat Conv calls"
            )
        if stage7 and not (stage7c or stage7d):
            if source.count("maxpool_nhwc_i8_strided(") - 1 < 1:
                raise ValueError("Stage 7 requires a strided MaxPool producer write")
            if source.count("resize_nearest_nhwc_i8_strided(") - 1 < 1:
                raise ValueError("Stage 7 requires a strided Resize producer write")
            if source.count("add_ratio_i8_strided(") - 1 < expected_strided_add:
                raise ValueError(
                    f"Stage 7 expected {expected_strided_add} ratio strided Add calls"
                )
            if stage7b and source.count("add_two_step_i8_strided(") - 1 < 3:
                raise ValueError("Stage 7B expected three exact two-step Add calls")
            if stage7b_lut and source.count("add_two_step_lut_i8_strided(") - 1 < 3:
                raise ValueError("Stage 7B-LUT expected three LUT two-step Add calls")
            if stage7b_register and source.count("add_two_step_register_i8_strided(") - 1 < 3:
                raise ValueError("Stage 7B-register expected three register-LUT Add calls")
            if stage7bc and source.count("add_two_step_register_i8_strided(") - 1 < 3:
                raise ValueError("Stage 7BC expected three register-LUT Add calls")
            if stage7e and source.count("add_two_step_register_fixed_i8_strided(") - 1 < 3:
                raise ValueError("Stage 7E expected three fixed register-LUT Add calls")
        if (stage7c or stage7bc) and source.count("concat_nhwc_slice_strided_i8(") - 1 < 1:
            raise ValueError("Stage 7C expected dedicated NHWC Concat calls")
        if stage7d and (
                source.count("add_gemmini_resadd_i8(") - 1 != 6 or
                source.count("add_gemmini_resadd_strided_i8(") != 4):
            raise ValueError("Stage 7D expected six contiguous and one strided Gemmini resadd")
    print(
        f"PASS: Stage {stage} arena={plan['arena_bytes']} bytes "
        f"saved={plan['reduction_percent']:.2f}% dead={actual['dead']} "
        f"inplace={actual['inplace']} direct={actual['direct']}"
    )


if __name__ == "__main__":
    main()
