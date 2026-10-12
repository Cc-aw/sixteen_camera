#!/usr/bin/env python3
"""Verify the emitted ingress core (protocol, not an isolated bandwidth claim)."""
import argparse
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--core-dir", type=Path, default=root / "build/sim/tensor_ingress/core")
args = parser.parse_args()
core = args.core_dir / "TaihangTensorIngressCore.sv"
if not core.is_file():
    raise SystemExit("Emit the core first: python3 tools/soc/build_tensor_ingress.py --emit-core")
text = re.search(r"module TaihangTensorIngressCore\((.*?)\);", core.read_text(), re.S)[1]
text = re.sub(r"//[^\n]*", "", text)
if "io_a_bits_last" not in text or "io_d_ready" not in text:
    raise SystemExit("Use the independently emitted protocol core; full-SoC optimization removes unused test ports")
connections = []
for declaration in text.split(","):
    name = re.findall(r"\w+", declaration)[-1]
    if name in {"clock", "reset"}:
        value = "clk" if name == "clock" else "reset"
    elif name.startswith("io_axi_"):
        value = "axi." + name.removeprefix("io_axi_").replace("_bits_", "").replace("_", "")
    elif name.startswith("io_stats_"):
        value = f"stats[{name.removeprefix('io_stats_')}]"
    elif name.startswith("io_a_") or name.startswith("io_d_"):
        value = name.removeprefix("io_").replace("_bits_", "_")
    else:
        raise SystemExit(f"Unknown generated core port: {name}")
    connections.append(f".{name}({value})")
out = root / "build/sim/tensor_ingress/protocol"
out.mkdir(parents=True, exist_ok=True)
wrapper = out / "wrapper.sv"
wrapper.write_text("""module tensor_ingress_test_wrapper(
input wire clk, reset, axi4_if.slave axi,
input wire a_ready, output wire a_valid,
output wire [4:0] a_source, output wire [32:0] a_address,
output wire [255:0] a_data, output wire a_last,
input wire d_valid, output wire d_ready,
input wire [4:0] d_source, input wire d_denied,
output wire [63:0] stats [13]);
TaihangTensorIngressCore core(
""" + ",\n".join(connections) + "\n);\nendmodule\n")
subprocess.run(["verilator", "--binary", "--timing", "--assert", "-Wno-fatal", "-j", "4",
                "--top-module", "tb_tensor_ingress", "--Mdir", str(out / "obj"),
                str(root / "hw/rtl/interfaces/axi4_if.sv"), str(core),
                *map(str, args.core_dir.glob("data_*.sv")),
                *map(str, args.core_dir.glob("*.top.mems.v")), str(wrapper),
                str(root / "tests/rtl/benches/tensor/tb_tensor_ingress.sv")], check=True)
subprocess.run([str(out / "obj/Vtb_tensor_ingress")], check=True)
