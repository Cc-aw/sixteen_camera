#!/usr/bin/env python3
"""Independent float32 model for randomized three-head DFL RTL regression."""

import argparse
import re
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
PARAMS = ROOT / "sw/yolov5/generators/gemmini/software/gemmini-rocc-tests/imagenet/yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-image025-profile_params.h"
WEIGHTS = np.array([0, 8, 17, 25, 34, 42, 51, 59,
                    68, 76, 85, 93, 102, 110, 119, 127], dtype=np.int32)
SCALES = [0.2151331604, 0.1472641826, 0.1159213334]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    source = PARAMS.read_text()
    match = re.search(r"yolov5nu_softmax_exp_lut0\[256\]\s*=\s*\{([^}]+)\}", source)
    exp = np.asarray([float(x) for x in re.findall(
        r"(?:\d+\.\d*|\d*\.\d+|\d+)(?:e[+-]?\d+)?", match.group(1)
    )], dtype=np.float32)
    assert len(exp) == 256
    rng = np.random.default_rng(20260509)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    with (args.output_dir / "dfl_raw.mem").open("w") as raw_file, \
         (args.output_dir / "dfl_expected.mem").open("w") as expected_file:
        for trial in range(48):
            head = trial % 3
            raw = rng.integers(-75, 76, size=(4, 16), dtype=np.int16).astype(np.int8)
            # Preserve nonuniform four-edge softmax, max clipping and mixed
            # positive/negative logits; these are not generated from RTL ROM.
            quant = np.rint(np.float32(raw.astype(np.float32) *
                                      np.float32(SCALES[head])) /
                            np.float32(SCALES[0])).clip(-128, 127).astype(np.int32)
            output = bytearray()
            for edge in range(4):
                maximum = max(quant[edge])
                values = exp[maximum - quant[edge]]
                total = np.float32(0)
                for value in values:
                    total = np.float32(total + value)
                reciprocal = np.float32(1 / np.float32(
                    total * np.float32(0.007874015719)))
                accum = 0
                for weight, value in zip(WEIGHTS, values):
                    probability = int(np.rint(np.float32(value * reciprocal)))
                    accum += probability * int(weight)
                converted = np.float32(np.float32(np.float32(accum) *
                    np.float32(0.007874015719)) * np.float32(0.1181102395))
                distance = int(np.rint(np.float32(
                    converted / np.float32(0.1129496917))))
                output.append(max(-128, min(127, distance)) & 255)
            raw_file.write(f"{int.from_bytes(raw.tobytes(), 'little'):0128x}\n")
            expected_file.write(f"{int.from_bytes(output, 'little'):08x}\n")


if __name__ == "__main__":
    main()
