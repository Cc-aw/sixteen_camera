#!/usr/bin/env python3
"""Synthesize changed subsystems only, using their actual generated dependencies."""
import argparse
import importlib.util
import os
from pathlib import Path
import re
import resource
import subprocess

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("generator", ROOT / "tools/soc/build_triple32_v3_tensor.py")
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--targets", nargs="+", choices=["tensor", "l2", "sbus", "head", "counters", "pool-store", "pool-dma"],
                    default=["tensor", "l2", "sbus", "head", "counters"])
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
rtl = ROOT / "hw/soc" / generator.NAME / "gen-collateral"
modules = {}
for path in sorted(rtl.glob("*")):
    if path.suffix in {".v", ".sv"}:
        for module in re.findall(r"^module\s+(\w+)", path.read_text(), re.M):
            modules[module] = path


def dependencies(top):
    seen = set()
    def visit(module):
        path = modules[module]
        if path in seen:
            return
        seen.add(path)
        for child in re.findall(r"^\s+(\w+)\s+(?:#\s*\(.*?\)\s*)?\w+\s*\(", path.read_text(), re.M):
            if child in modules:
                visit(child)
    visit(top)
    return sorted(seen)


args.output.resolve().mkdir(parents=True, exist_ok=False)
tops = {"tensor": "TaihangTensorIngress", "l2": "InclusiveCache", "sbus": "SystemBus",
        "pool-store": "StoreController", "pool-dma": "StreamWriter"}
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
for kind in args.targets:
    out = args.output.resolve() / kind
    out.mkdir()
    if kind in tops:
        sources = dependencies(tops[kind])
    elif kind == "head":
        sources = [ROOT / p for p in ["hw/rtl/interfaces/axi4_if.sv", "hw/rtl/ai/postprocess/head_uram_store.sv",
                   "hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv", "tests/rtl/benches/memory/memory_v3_head_ooc.sv"]]
    else:
        sources = [ROOT / "hw/rtl/memory/memory_perf_counters.sv"]
    filelist = out / "sources.txt"
    filelist.write_text("".join(str(p) + "\n" for p in sources))
    with (out / "console.log").open("w") as log:
        subprocess.run([os.environ.get("VIVADO_BIN", "vivado"), "-mode", "batch", "-source",
                        str(ROOT / "tools/check/synth_triple32_v3_tensor_ooc.tcl"), "-tclargs",
                        kind, str(out), str(filelist)], cwd=out, stdout=log, stderr=subprocess.STDOUT, check=True)
    print((out / "result.txt").read_text(), flush=True)
