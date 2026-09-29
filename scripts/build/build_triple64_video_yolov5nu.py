#!/usr/bin/env python3
"""Build the current PPU video runtime for three DIM64 Gemmini workers."""
from pathlib import Path
import argparse
import hashlib
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "sw"
OUTPUT = ROOT / "build/firmware/gemmini_triple64_video_yolov5nu.elf"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    output = parser.parse_args().output.resolve()
    subprocess.run([
        "make", "-C", str(SOURCE), "-j4", "AI_MODEL=yolov5nu",
        "SOC_VARIANT=triple64", f"BUILD={ROOT}/build/firmware/triple64_video", f"TARGET={ROOT}/build/firmware/triple64_video/firmware", "all",
    ], check=True)
    built = ROOT / "build/firmware/triple64_video/firmware.elf"
    output.parent.mkdir(parents=True, exist_ok=True)
    if built.resolve() != output:
        shutil.copy2(built, output)
    print(f"TRIPLE64_VIDEO_ELF={output}")
    print(f"TRIPLE64_VIDEO_SHA256={hashlib.sha256(output.read_bytes()).hexdigest()}")
    print("TRIPLE64_VIDEO_BUILD=PASS")


if __name__ == "__main__":
    main()
