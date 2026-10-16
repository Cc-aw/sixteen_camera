#!/usr/bin/env python3
"""Exercise the current two-bank V3 L2 with Tensor and coherent clients."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--workspace", type=Path)
parser.add_argument("--output", type=Path)
args = parser.parse_args()
workspace = args.workspace
if workspace is None:
    contexts = list((ROOT / "hw/soc").glob("*/GENERATION_CONTEXT.json"))
    if len(contexts) != 1:
        raise SystemExit("Select a rebuilt V3 workspace with --workspace")
    workspace = Path(json.loads(contexts[0].read_text())["source_workspace"])
if not (workspace / ".classpath_cache/chipyard_fpga.jar").is_file():
    raise SystemExit("Rebuild the SoC workspace, then pass --workspace <path>")
command = [sys.executable, str(ROOT / "tests/rtl/run_memory_v3_tensor_cache_test.py"),
           "--workspace", str(workspace)]
if args.output is not None:
    command += ["--output", str(args.output)]
subprocess.run(command, check=True)
