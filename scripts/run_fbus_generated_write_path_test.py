#!/usr/bin/env python3
"""Measure writes through the actual generated FBus AXI-to-TL coupling."""
import argparse
import re
import subprocess
import tempfile
from pathlib import Path

repo = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--latency", type=int, default=160)
parser.add_argument("--ids", type=int, choices=[8, 16, 32], default=8)
parser.add_argument("--bytes", type=int, default=262144)
args = parser.parse_args()
collateral = next((repo / "generated/soc").glob("tsmc*/gen-collateral"))
top = "TLInterconnectCoupler_fbus_from_port_named_slave_port_axi4"
seen = set()


def dependencies(name):
    if name in seen:
        return
    path = collateral / f"{name}.sv"
    if not path.exists():
        raise SystemExit(f"Missing generated module {name}")
    seen.add(name)
    for child in re.findall(r"^  (\w+) \w+ \(", path.read_text(), re.M):
        dependencies(child)


dependencies(top)
text = (collateral / f"{top}.sv").read_text()
width = re.search(r"input\s+\[(\d+):0\]\s+auto_tl_out_d_bits_data", text)
id_width = re.search(
    r"input\s+\[(\d+):0\]\s+auto_axi4index_in_aw_bits_id", text
)
if not width or not id_width:
    raise SystemExit("Cannot determine generated FBus widths")
memory_width = int(width[1]) + 1
axi_id_width = int(id_width[1]) + 1

connections = []
tl = {
    "a_ready": "a_ready", "a_valid": "a_valid",
    "a_bits_opcode": "a_opcode", "a_bits_size": "a_size",
    "a_bits_source": "a_source", "a_bits_address": "a_address",
    "d_ready": "d_ready", "d_valid": "d_valid",
    "d_bits_opcode": "d_opcode", "d_bits_param": "2'd0",
    "d_bits_size": "4'd6", "d_bits_source": "d_source",
    "d_bits_sink": "5'd0", "d_bits_denied": "1'b0",
    "d_bits_data": "d_data", "d_bits_corrupt": "1'b0",
}
for direction, name in re.findall(
    r"^\s*(input|output)\s+(?:\[[^]]+\]\s+)?(\w+)\s*[,\t]", text, re.M
):
    if name == "clock":
        value = "clk"
    elif name == "reset":
        value = "!resetn"
    elif name.startswith("auto_axi4index_in_"):
        value = "axi." + name.removeprefix("auto_axi4index_in_").replace(
            "_bits_", ""
        ).replace("_", "")
    elif name.startswith("auto_tl_out_"):
        key = name.removeprefix("auto_tl_out_")
        value = tl.get(key, "" if direction == "output" else "'0")
    else:
        raise SystemExit(f"Unexpected generated port {name}")
    connections.append(f".{name}({value})")

wrapper = f"""module fbus_generated_wrapper(
input wire clk, resetn, axi4_if.slave axi,
input wire a_ready, output wire a_valid,
output wire [2:0] a_opcode, output wire [3:0] a_size,
output wire [6:0] a_source, output wire [32:0] a_address,
output wire d_ready, input wire d_valid, input wire [2:0] d_opcode,
input wire [6:0] d_source, input wire [{memory_width-1}:0] d_data);
{top} dut(\n""" + ",\n".join(connections) + "\n);\nendmodule\n"

with tempfile.TemporaryDirectory(prefix="fbus-generated-write-") as directory:
    temp = Path(directory)
    (temp / "wrapper.sv").write_text(wrapper)
    command = [
        "verilator", "--binary", "--timing", "--assert", "-Wno-fatal",
        "--top-module", "tb_fbus_generated_write_path", "-j", "4",
        f"-GAXI_ID_WIDTH={axi_id_width}",
        f"-GMEMORY_DATA_WIDTH={memory_width}",
        f"-GMEMORY_LATENCY={args.latency}",
        f"-GWRITE_ID_COUNT={args.ids}",
        f"-GFIRST_WRITE_ID={32-args.ids}",
        f"-GBYTES={args.bytes}",
        "--Mdir", str(temp / "obj"),
        str(repo / "rtl/interfaces/axi4_if.sv"),
        str(repo / "rtl/bus/cdc_payload_fifo.sv"),
        str(repo / "rtl/bus/axi4_write_cdc.sv"),
        *[str(collateral / f"{name}.sv") for name in sorted(seen)],
        str(temp / "wrapper.sv"),
        str(repo / "sim/tb_fbus_generated_write_path.sv"),
    ]
    subprocess.run(command, check=True)
    subprocess.run([str(temp / "obj/Vtb_fbus_generated_write_path")], check=True)
