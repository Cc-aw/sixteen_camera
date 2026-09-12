#!/usr/bin/env python3
"""Compare float-coordinate CPU NMS to integer-coordinate RTL NMS on corpus."""

from pathlib import Path

import numpy as np

ARCHIVE = Path(__file__).resolve().parents[1] / (
    "sw/yolov5/generators/gemmini/software/gemmini-ort/models/detection/"
    "stage8_640x480_hardware_aware/hardware_integer_reference.npz"
)


def reduce_detections(boxes, scores, classes, positions):
    chosen = []
    suppressed = np.zeros(len(scores), dtype=bool)
    order = sorted(range(len(scores)), key=lambda k: (-scores[k], positions[k]))
    for a in order:
        if suppressed[a]:
            continue
        chosen.append(positions[a])
        if len(chosen) == 10:
            break
        for b in order:
            if suppressed[b] or classes[a] != classes[b]:
                continue
            inter = max(0, min(boxes[a, 2], boxes[b, 2]) - max(boxes[a, 0], boxes[b, 0])) * max(
                0, min(boxes[a, 3], boxes[b, 3]) - max(boxes[a, 1], boxes[b, 1]))
            area_a = (boxes[a, 2] - boxes[a, 0]) * (boxes[a, 3] - boxes[a, 1])
            area_b = (boxes[b, 2] - boxes[b, 0]) * (boxes[b, 3] - boxes[b, 1])
            union = area_a + area_b - inter
            if union > 0 and inter > .45 * union:
                suppressed[b] = True
    return chosen


def main():
    archive = np.load(ARCHIVE)
    mismatches = []
    for key in archive.files:
        if not key.endswith("__class_scores"):
            continue
        image = key.split("__")[0]
        scores = archive[key]
        best_class = scores.argmax(axis=0)
        best_score = scores[best_class, np.arange(6300)]
        positions = np.flatnonzero(best_score >= 34)
        if len(positions) == 0:
            continue
        distances = archive[f"{image}__dfl"][:, positions].astype(np.float64)
        boxes = np.zeros((len(positions), 4), dtype=np.float64)
        for index, position in enumerate(positions):
            if position < 4800:
                stride, x, y = 8, position % 80, position // 80
            elif position < 6000:
                stride, x, y = 16, (position - 4800) % 40, (position - 4800) // 40
            else:
                stride, x, y = 32, (position - 6000) % 20, (position - 6000) // 20
            left, top, right, bottom = distances[:, index] * .1129496917
            boxes[index] = [(x+.5-left)*stride, (y+.5-top)*stride,
                            (x+.5+right)*stride, (y+.5+bottom)*stride]
        integer_boxes = np.floor(np.clip(boxes, [0, 0, 0, 0],
            [640, 480, 640, 480]) + .5)
        a = reduce_detections(boxes, best_score[positions], best_class[positions], positions)
        b = reduce_detections(integer_boxes, best_score[positions], best_class[positions], positions)
        if a != b:
            mismatches.append((image, a, b))
    print(f"NMS corpus images={len(archive.files)//3} float_vs_pixel_mismatches={len(mismatches)}")
    for item in mismatches[:8]:
        print(item)
    if mismatches:
        raise SystemExit("integer bbox rounding changed NMS selections")


if __name__ == "__main__":
    main()
