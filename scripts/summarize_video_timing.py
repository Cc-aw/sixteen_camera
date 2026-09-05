#!/usr/bin/env python3
"""Summarize the complete negative-endpoint TSV emitted by Vivado."""

import argparse
import csv
import json
from collections import Counter, defaultdict
from pathlib import Path


def classify(name: str) -> str:
    rules = (
        ("ddr_frame_reader", ("u_reader", "u_mosaic_reader")),
        ("pclk_recovery_frontend", (".u_camera/",)),
        ("camera_stream", ("u_camera_stream",)),
        ("camera_axis_cdc", ("u_camera_cdc",)),
        ("frame_manager", ("u_manager",)),
        ("ddr_video_writer", ("u_writer", "u_video_dma")),
        ("batch_preprocess", ("u_batch_preprocess",)),
        ("hdmi_rx", ("u_hdmi_rx", "u_rx/")),
        ("mig_ddr_ip", ("u_ddr_bd", "ddr4_0", "axi_interconnect_0")),
    )
    for category, needles in rules:
        if any(needle in name for needle in needles):
            return category
    return "other"


def endpoint_pin(name: str) -> str:
    return name.rsplit("/", 1)[-1]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("report_dir", type=Path)
    args = parser.parse_args()
    source = args.report_dir / "negative_endpoints.tsv"
    rows = list(csv.DictReader(source.open(newline=""), delimiter="\t"))

    category = defaultdict(lambda: {"count": 0, "tns_ns": 0.0, "wns_ns": 0.0})
    pins = Counter()
    clock_pairs = Counter()
    slr_pairs = Counter()
    for row in rows:
        slack = float(row["slack"])
        group = category[classify(row["endpoint"])]
        group["count"] += 1
        group["tns_ns"] += slack
        group["wns_ns"] = min(group["wns_ns"], slack)
        pins[row.get("endpoint_pin_type") or endpoint_pin(row["endpoint"])] += 1
        clock_pairs[(row["start_clock"], row["end_clock"])] += 1
        slr_pairs[(row.get("start_slr", ""), row.get("end_slr", ""))] += 1

    result = {
        "complete_rows": len(rows),
        "wns_ns": min((float(r["slack"]) for r in rows), default=None),
        "tns_ns_from_rounded_rows": sum(float(r["slack"]) for r in rows),
        "categories": dict(sorted(category.items())),
        "endpoint_pins": dict(pins.most_common()),
        "clock_pairs": {
            f"{start}->{end}": count
            for (start, end), count in sorted(clock_pairs.items())
        },
        "slr_pairs": {
            f"{start or 'unknown'}->{end or 'unknown'}": count
            for (start, end), count in sorted(slr_pairs.items())
        },
    }
    target = args.report_dir / "negative_summary.json"
    target.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")

    with (args.report_dir / "category_summary.csv").open("w", newline="") as out:
        writer = csv.writer(out)
        writer.writerow(("category", "failed_endpoints", "wns_ns", "rounded_tns_ns"))
        for name, values in sorted(category.items()):
            writer.writerow((name, values["count"], values["wns_ns"], values["tns_ns"]))
    with (args.report_dir / "control_pin_summary.csv").open("w", newline="") as out:
        writer = csv.writer(out)
        writer.writerow(("endpoint_pin_type", "failed_endpoints"))
        writer.writerows(pins.most_common())
    with (args.report_dir / "clock_pair_summary.csv").open("w", newline="") as out:
        writer = csv.writer(out)
        writer.writerow(("start_clock", "end_clock", "failed_endpoints"))
        for (start, end), count in sorted(clock_pairs.items()):
            writer.writerow((start, end, count))
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
