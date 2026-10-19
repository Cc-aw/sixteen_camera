#!/usr/bin/env python3
"""Run Head, outstanding/order and asynchronous performance-counter tests."""
import argparse
import subprocess
from pathlib import Path

v3 = Path(__file__).resolve().parents[1]
root = v3.parents[1]
p = argparse.ArgumentParser()
p.add_argument("output", type=Path)
a = p.parse_args()
out = a.output.resolve()
out.mkdir(parents=True, exist_ok=False)
common = [v3 / "overlay/rtl/interfaces/axi4_if.sv",
          root / "rtl/ai/postprocess/head_uram_store.sv",
          v3 / "overlay/rtl/ai/postprocess/axi4_head_uram_router.sv"]
for name in ("head", "outstanding", "counters"):
    top = "tb_memory_v3_" + name
    sources = [v3 / "overlay/rtl/memory/memory_perf_counters.sv"] if name == "counters" else common
    cmd = ["verilator", "--binary", "--timing", "--assert", "-Wno-fatal", "-j", "4",
           "--top-module", top, "--Mdir", str(out / name),
           *map(str, sources), str(v3 / "tests" / (top + ".sv"))]
    with (out / (name + ".compile.log")).open("w") as log:
        subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, check=True)
    with (out / (name + ".log")).open("w") as log:
        subprocess.run([str(out / name / ("V" + top))], stdout=log, stderr=subprocess.STDOUT, check=True)
    print((out / (name + ".log")).read_text())
