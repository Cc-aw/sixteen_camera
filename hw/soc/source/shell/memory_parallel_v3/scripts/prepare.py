#!/usr/bin/env python3
"""Prepare a private build; never alter the production export or reference tree."""
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path

V3 = Path(__file__).resolve().parents[1]
ROOT = V3.parents[1]
CONFIG = "TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config"
parser = argparse.ArgumentParser()
parser.add_argument("--chipyard", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
cy = args.chipyard.resolve()
out = args.output.resolve()
if not (cy / ".npu100-video-workspace.json").is_file() or str(cy).startswith("/home/wzr/chipyard"):
    raise SystemExit("Requires a private prepare_workspace.py snapshot")
if out.exists():
    raise SystemExit("Refusing to replace an existing source snapshot")
for rel, digest in json.loads((V3 / "baseline.json").read_text()).items():
    if hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() != digest:
        raise SystemExit("Baseline changed; review before rebasing: " + rel)
for folder in ["rtl", "xdc", "prj"]:
    dest = out / folder
    dest.mkdir(parents=True)
    if folder == "prj":
        for src in (ROOT / folder).glob("*.tcl"):
            shutil.copy2(src, dest / src.name)
    else:
        shutil.copytree(ROOT / folder, dest, dirs_exist_ok=True)
shutil.copytree(V3 / "overlay", out, dirs_exist_ok=True)
manifest = json.loads((V3 / "chipyard_baseline.json").read_text())
for rel, digest in manifest.items():
    src = V3 / "chipyard" / rel
    dst = cy / rel
    if dst.exists() and hashlib.sha256(dst.read_bytes()).hexdigest() not in (digest, hashlib.sha256(src.read_bytes()).hexdigest()):
        raise SystemExit("Chipyard baseline mismatch: " + rel)
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
# Existing board source filter includes this package, so these files participate
# in the normal SBT dependency graph, including modified Rocket Chip and L2.
for src in (V3 / "scala").glob("*.scala"):
    shutil.copy2(src, cy / "fpga/src/main/scala/xcvu13p_gemmini_32x32_packed_inference_ram" / src.name)
all_sources = list((V3 / "overlay").rglob("*")) + list((V3 / "chipyard").rglob("*")) + list((V3 / "scala").glob("*.scala"))
(out / "source_manifest.json").write_text(json.dumps({
    "config": CONFIG, "chipyard": str(cy), "baseline": "memory32 timing v3, DMA experiments OFF",
    "sha256": {str(p.relative_to(V3)): hashlib.sha256(p.read_bytes()).hexdigest() for p in all_sources if p.is_file()},
}, indent=2) + "\n")
print(out)
