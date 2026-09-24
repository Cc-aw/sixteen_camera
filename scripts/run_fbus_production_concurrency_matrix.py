#!/usr/bin/env python3
"""Run the production-shaped read/write FBus concurrency matrix."""

import argparse
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


repo = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument(
    "--collateral",
    type=Path,
    default=next((repo / "rtl/soc").glob("tsmc*/gen-collateral")),
)
parser.add_argument("--bytes", type=int, default=65536)
parser.add_argument("--latency", type=int, default=18)
parser.add_argument("--min-read-mbps", type=int, default=435)
parser.add_argument("--min-write-mbps", type=int, default=442)
parser.add_argument("--jobs", type=int, default=4)
default_verilator = repo.parent / "chipyard/.conda-env/bin/verilator"
parser.add_argument(
    "--verilator",
    type=Path,
    default=default_verilator if default_verilator.exists() else Path(shutil.which("verilator") or "verilator"),
)
parser.add_argument("--case", choices=["all", "16_16", "18_14", "20_12", "shared"], default="all")
parser.add_argument("--acceptance", choices=["all", "1", "8"], default="all")
args = parser.parse_args()

top = "TLInterconnectCoupler_fbus_from_port_named_slave_port_axi4"
seen: set[str] = set()


def dependencies(name: str) -> None:
    if name in seen:
        return
    path = args.collateral / f"{name}.sv"
    if not path.exists():
        raise SystemExit(f"Missing generated module {name}")
    seen.add(name)
    for child in re.findall(r"^  (\w+) \w+ \(", path.read_text(), re.M):
        dependencies(child)


dependencies(top)
coupler_text = (args.collateral / f"{top}.sv").read_text()
width_match = re.search(
    r"input\s+\[(\d+):0\]\s+auto_tl_out_d_bits_data", coupler_text
)
id_match = re.search(
    r"input\s+\[(\d+):0\]\s+auto_axi4index_in_ar_bits_id", coupler_text
)
if not width_match or not id_match:
    raise SystemExit("Cannot determine generated FBus widths")
memory_width = int(width_match[1]) + 1
axi_id_width = int(id_match[1]) + 1

connections = []
tl = {
    "a_ready": "a_ready",
    "a_valid": "a_valid",
    "a_bits_opcode": "a_opcode",
    "a_bits_size": "a_size",
    "a_bits_source": "a_source",
    "a_bits_address": "a_address",
    "d_ready": "d_ready",
    "d_valid": "d_valid",
    "d_bits_opcode": "d_opcode",
    "d_bits_param": "2'd0",
    "d_bits_size": "4'd6",
    "d_bits_source": "d_source",
    "d_bits_sink": "5'd0",
    "d_bits_denied": "1'b0",
    "d_bits_data": "d_data",
    "d_bits_corrupt": "1'b0",
}
for direction, name in re.findall(
    r"^\s*(input|output)\s+(?:\[[^]]+\]\s+)?(\w+)\s*[,\t]",
    coupler_text,
    re.M,
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
output wire fixer_stall,
output wire d_ready, input wire d_valid, input wire [2:0] d_opcode,
input wire [6:0] d_source, input wire [{memory_width - 1}:0] d_data);
{top} dut(
""" + ",\n".join(connections) + "\n);\nassign fixer_stall = dut.fixer.stall;\nendmodule\n"

cases = {
    "16_16": (16, 16, 16, True),
    "18_14": (18, 18, 14, True),
    "20_12": (20, 20, 12, True),
    # Reproduce the pre-partition configuration: reader 0..30 and writer 0..31.
    "shared": (31, 0, 32, False),
}
selected_cases = cases.items() if args.case == "all" else [(args.case, cases[args.case])]
acceptances = [1, 8] if args.acceptance == "all" else [int(args.acceptance)]
results = []

with tempfile.TemporaryDirectory(prefix="fbus-production-matrix-") as directory:
    temp = Path(directory)
    (temp / "wrapper.sv").write_text(wrapper)
    for case_name, (read_ids, first_write_id, write_ids, disjoint) in selected_cases:
        for acceptance in acceptances:
            build = temp / f"obj_{case_name}_a{acceptance}"
            command = [
                str(args.verilator),
                "--binary",
                "--timing",
                "--assert",
                "-Wno-fatal",
                "--top-module",
                "tb_fbus_production_concurrency",
                "-j",
                str(args.jobs),
                f"-GAXI_ID_WIDTH={axi_id_width}",
                f"-GMEMORY_DATA_WIDTH={memory_width}",
                f"-GREAD_ID_COUNT={read_ids}",
                f"-GFIRST_WRITE_ID={first_write_id}",
                f"-GWRITE_ID_COUNT={write_ids}",
                f"-GREAD_BYTES={args.bytes}",
                f"-GWRITE_BYTES={args.bytes}",
                f"-GMEMORY_LATENCY={args.latency}",
                f"-GREAD_ACCEPTANCE={acceptance}",
                f"-GWRITE_ACCEPTANCE={acceptance}",
                f"-GMIN_READ_MBPS={args.min_read_mbps if acceptance == 8 else 0}",
                f"-GMIN_WRITE_MBPS={args.min_write_mbps if acceptance == 8 else 0}",
                f"-GEXPECT_DISJOINT_IDS={int(disjoint)}",
                "--Mdir",
                str(build),
                str(repo / "rtl/interfaces/axi4_if.sv"),
                str(repo / "rtl/bus/cdc_payload_fifo.sv"),
                str(repo / "rtl/bus/axi4_write_cdc.sv"),
                str(repo / "rtl/bus/axi4_channel_join.sv"),
                str(repo / "rtl/ai/postprocess/fbus_read_engine.sv"),
                *[str(args.collateral / f"{name}.sv") for name in sorted(seen)],
                str(temp / "wrapper.sv"),
                str(repo / "sim/tb_fbus_production_concurrency.sv"),
            ]
            print(
                f"MATRIX_CASE name={case_name} acceptance={acceptance} "
                f"read_ids={read_ids} write_ids={first_write_id}.."
                f"{first_write_id + write_ids - 1}",
                flush=True,
            )
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
            run = subprocess.run(
                [str(build / "Vtb_fbus_production_concurrency")],
                text=True,
                capture_output=True,
            )
            print(run.stdout, end="")
            if run.stderr:
                print(run.stderr, end="")
            run.check_returncode()
            bandwidth = re.search(
                r"FBUS_PRODUCTION_BW read=(\d+)MBps write=(\d+)MBps", run.stdout
            )
            if not bandwidth:
                raise SystemExit(f"Missing bandwidth result for {case_name}/a{acceptance}")
            results.append(
                (case_name, acceptance, int(bandwidth[1]), int(bandwidth[2]))
            )

print("FBUS_PRODUCTION_MATRIX_SUMMARY")
for case_name, acceptance, read_mbps, write_mbps in results:
    print(
        f"{case_name:>7} acceptance={acceptance} "
        f"read={read_mbps}MBps write={write_mbps}MBps"
    )
print("FBUS_PRODUCTION_MATRIX=PASS")
