#!/usr/bin/env python3
"""Generate RTL vectors from the frozen hardware-aware YOLOv5nu corpus."""

import argparse
import re
from pathlib import Path

import numpy as np


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reference", type=Path, required=True)
    parser.add_argument("--image", default="025")
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    archive = np.load(args.reference)
    scores = archive[f"{args.image}__class_scores"]
    if scores.shape != (80, 6300) or scores.dtype != np.int8:
        raise SystemExit(f"unexpected class score tensor {scores.shape} {scores.dtype}")

    # The reference archive is class-major.  The board runtime explicitly
    # transposes the three heads into location-major tensor_248.
    location_major = scores.T.copy()
    best_class = location_major.argmax(axis=1)
    best_score = location_major[np.arange(6300), best_class]
    candidates = best_score >= 34

    args.output_dir.mkdir(parents=True, exist_ok=True)
    with (args.output_dir / "scores.mem").open("w", encoding="ascii") as out:
        for value in location_major.reshape(-1):
            out.write(f"{int(value) & 0xff:02x}\n")
    with (args.output_dir / "expected.mem").open("w", encoding="ascii") as out:
        for position in range(6300):
            word = (
                (int(candidates[position]) << 15)
                | (int(best_class[position]) << 8)
                | (int(best_score[position]) & 0xff)
            )
            out.write(f"{word:04x}\n")

    distances = archive[f"{args.image}__dfl"]
    if distances.shape != (4, 6300) or distances.dtype != np.int8:
        raise SystemExit("unexpected DFL output")
    with (args.output_dir / "candidates.mem").open("w", encoding="ascii") as out:
        for position in np.flatnonzero(candidates):
            word = (int(position) << 47) | (int(best_class[position]) << 40) | (
                (int(best_score[position]) & 255) << 32
            )
            for edge in range(4):
                word |= (int(distances[edge, position]) & 255) << (edge * 8)
            out.write(f"{word:015x}\n")

    # Invert the generated per-head LUT for an end-to-end *raw head* stream.
    # Every score in the independently frozen corpus must be realizable by
    # its corresponding actual Gemmini output head.
    rom = (Path(__file__).resolve().parents[1] /
           "rtl/ai/postprocess/yolov5nu_raw_class_lut.sv").read_text()
    inverse = [{} for _ in range(3)]
    for address, score in re.findall(
        r"10'h([0-9a-f]{3}): score = 8'd(\d+)", rom
    ):
        address_i = int(address, 16)
        inverse[address_i // 256].setdefault(int(score), address_i % 256)
    with (args.output_dir / "raw_classes.mem").open("w", encoding="ascii") as out:
        for head, (begin, end) in enumerate(((0, 4800), (4800, 6000),
                                              (6000, 6300))):
            for score in location_major[begin:end].reshape(-1):
                raw = inverse[head].get(int(score))
                if raw is None:
                    raise SystemExit(f"corpus score {score} absent from head {head}")
                out.write(f"{raw:02x}\n")

    print(
        f"image={args.image} positions=6300 candidates={int(candidates.sum())} "
        f"score_sum={int(scores.astype(np.int64).sum())}"
    )


if __name__ == "__main__":
    main()
