#!/usr/bin/env python3
"""Exercise the production 512-bit Head router, DDR ordering and CDC counters."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
out = ROOT / "build/sim/memory_parallel_v3"
out.mkdir(parents=True, exist_ok=True)
common = [ROOT / "hw/rtl/interfaces/axi4_if.sv",
          ROOT / "hw/rtl/ai/postprocess/head_uram_store.sv",
          ROOT / "hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv"]
for name in ("head", "outstanding", "counters"):
    top = "tb_memory_v3_" + name
    sources = [ROOT / "hw/rtl/memory/memory_perf_counters.sv"] if name == "counters" else common
    with (out / (name + ".compile.log")).open("w") as log:
        subprocess.run(["verilator", "--binary", "--timing", "--assert", "-Wno-fatal", "-j", "4",
                        "--top-module", top, "--Mdir", str(out / name),
                        *map(str, sources), str(ROOT / "tests/rtl/benches/memory" / (top + ".sv"))],
                       stdout=log, stderr=subprocess.STDOUT, check=True)
    with (out / (name + ".log")).open("w") as log:
        subprocess.run([str(out / name / ("V" + top))], stdout=log, stderr=subprocess.STDOUT, check=True)
    print((out / (name + ".log")).read_text())
