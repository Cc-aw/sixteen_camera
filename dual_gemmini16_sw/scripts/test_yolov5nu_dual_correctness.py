#!/usr/bin/env python3
"""Run or parse the dual-Gemmini16 YOLOv5nu image025 correctness test."""

from __future__ import annotations

import argparse
import os
import re
import select
import sys
import termios
import time
import tty
from pathlib import Path

EXPECTED = {
    "logits_sum": (-17904818) & ((1 << 64) - 1),
    "logits_fnv": 0x20012CCB8F2D3159,
    "scores_sum": 1050,
    "scores_fnv": 0x0AEB25432E02CC59,
    "dfl_sum": 1405,
    "dfl_fnv": 0xAA070E839DF35480,
    "candidates": 10,
    "nms": 1,
    "class_id": 23,
    "score_milli": 858,
    "cx": 494,
    "cy": 240,
    "width": 213,
    "height": 289,
}

WORKER_RE = re.compile(
    r"YOLOV5NU_TEST worker=(?P<worker>[01]) status=(?P<status>PASS|FAIL) "
    r"logits_sum=(?P<logits_sum>0x[0-9a-fA-F]+) "
    r"logits_fnv=(?P<logits_fnv>0x[0-9a-fA-F]+) "
    r"scores_sum=(?P<scores_sum>0x[0-9a-fA-F]+) "
    r"scores_fnv=(?P<scores_fnv>0x[0-9a-fA-F]+) "
    r"dfl_sum=(?P<dfl_sum>0x[0-9a-fA-F]+) "
    r"dfl_fnv=(?P<dfl_fnv>0x[0-9a-fA-F]+) "
    r"candidates/nms=(?P<candidates>\d+)/(?P<nms>\d+) "
    r"class/score/cx/cy/w/h=(?P<class_id>\d+)/(?P<score_milli>\d+)/"
    r"(?P<cx>\d+)/(?P<cy>\d+)/(?P<width>\d+)/(?P<height>\d+)"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--port", default="/dev/ttyACM0",
                        help="UART device (default: /dev/ttyACM0)")
    source.add_argument("--log", type=Path,
                        help="parse an already captured UART log")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--no-send", action="store_true",
                        help="do not send the 't' test command")
    parser.add_argument("--save-log", type=Path,
                        help="save captured UART bytes")
    return parser.parse_args()


def capture_uart(port: str, baud: int, timeout: float, send: bool) -> str:
    speeds = {115200: termios.B115200, 57600: termios.B57600,
              38400: termios.B38400, 9600: termios.B9600}
    if baud not in speeds:
        raise ValueError(f"unsupported baud rate: {baud}")
    descriptor = os.open(port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    try:
        tty.setraw(descriptor)
        settings = termios.tcgetattr(descriptor)
        settings[4] = speeds[baud]
        settings[5] = speeds[baud]
        termios.tcsetattr(descriptor, termios.TCSANOW, settings)
        termios.tcflush(descriptor, termios.TCIFLUSH)
        if send:
            os.write(descriptor, b"t")
        deadline = time.monotonic() + timeout
        collected = bytearray()
        while time.monotonic() < deadline:
            readable, _, _ = select.select([descriptor], [], [], 0.25)
            if not readable:
                continue
            try:
                chunk = os.read(descriptor, 4096)
            except BlockingIOError:
                continue
            if chunk:
                collected.extend(chunk)
                sys.stdout.buffer.write(chunk)
                sys.stdout.buffer.flush()
                if b"YOLOV5NU_TEST_RESULT " in collected:
                    break
        return collected.decode("utf-8", errors="replace")
    finally:
        os.close(descriptor)


def validate(text: str) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    final_pass = (
        "YOLOV5NU_TEST_RESULT PASS reference=bit_exact dual=bit_exact"
        in text
    )
    records = {int(match.group("worker")): match.groupdict()
               for match in WORKER_RE.finditer(text)}
    for worker in (0, 1):
        record = records.get(worker)
        if record is None:
            message = (f"worker {worker} detail line is missing or damaged "
                       "by UART capture")
            if final_pass:
                warnings.append(message)
            else:
                errors.append(message)
            continue
        if record["status"] != "PASS":
            errors.append(f"worker {worker} firmware status is FAIL")
        observed = {
            key: int(record[key], 16)
            for key in ("logits_sum", "logits_fnv", "scores_sum",
                        "scores_fnv", "dfl_sum", "dfl_fnv")
        }
        observed.update({key: int(record[key]) for key in
                         ("candidates", "nms", "class_id", "score_milli",
                          "cx", "cy", "width", "height")})
        for key, expected in EXPECTED.items():
            if observed[key] != expected:
                errors.append(
                    f"worker {worker} {key}: got {observed[key]:#x}, "
                    f"expected {expected:#x}")
    if not final_pass:
        errors.append("missing final bit-exact PASS marker")
    return errors, warnings


def main() -> int:
    options = parse_args()
    if options.log:
        text = options.log.read_text(errors="replace")
    else:
        text = capture_uart(options.port, options.baud, options.timeout,
                            not options.no_send)
        if options.save_log:
            options.save_log.parent.mkdir(parents=True, exist_ok=True)
            options.save_log.write_text(text)
    errors, warnings = validate(text)
    for warning in warnings:
        print(f"WARN: {warning}", file=sys.stderr)
    if errors:
        for error in errors:
            print(f"FAIL: {error}", file=sys.stderr)
        print("RESULT: FAIL - YOLOv5nu dual Gemmini16 correctness",
              file=sys.stderr)
        return 1
    print("RESULT: PASS - YOLOv5nu dual Gemmini16 bit-exact correctness")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
