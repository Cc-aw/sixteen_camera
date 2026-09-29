#!/usr/bin/env python3
"""Build the current PPU video runtime for two DIM16 Gemmini workers."""
from pathlib import Path
import argparse
import hashlib
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "sw"
OUTPUT = ROOT / "build/firmware/gemmini_dual16_video_yolov5nu.elf"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    output = parser.parse_args().output.resolve()
    subprocess.run([
        "make", "-C", str(SOURCE), "-j4", "AI_MODEL=yolov5nu",
        "SOC_VARIANT=dual16", f"BUILD={ROOT}/build/firmware/dual16_video", f"TARGET={ROOT}/build/firmware/dual16_video/firmware", "all",
    ], check=True)
    built = ROOT / "build/firmware/dual16_video/firmware.elf"
    output.parent.mkdir(parents=True, exist_ok=True)
    if built.resolve() != output:
        shutil.copy2(built, output)
    print(f"DUAL16_VIDEO_ELF={output}")
    print(f"DUAL16_VIDEO_SHA256={hashlib.sha256(output.read_bytes()).hexdigest()}")
    print("DUAL16_VIDEO_BUILD=PASS")


if __name__ == "__main__":
    main()
