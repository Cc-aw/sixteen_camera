#!/usr/bin/env python3
"""Replay checked traffic through generated SBUS/coherence/MemoryBus and S1 Head.

The generated SystemBus and CoherenceManagerWrapper perform all bank routing,
arbitration, source/sink translation, cache scheduling and CacheCork operations.
Only the requesters and delayed AXI memory endpoint are behavioral. No ELF,
Gemmini arithmetic, DDR controller/PHY or DDR register slice is modeled.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "tools/soc"))
from l2_geometry import L2Geometry
from run_memory_path_compare import ports


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def make_bench(rtl, geometry):
    modules = {"sb": "SystemBus", "coh": "CoherenceManagerWrapper", "mb": "MemoryBus"}
    interfaces = {prefix: ports(rtl, module) for prefix, module in modules.items()}
    lines = ["`timescale 1ns/1ps", "module tb_banked_memory;",
             "logic clock=0,reset=1; always #5 clock=~clock;",
             "logic [3:0] a_valid,a_ready,d_valid,d_ready;",
             "logic [2:0] a_opcode[4],d_opcode[4];",
             "logic [5:0] a_source[4],d_source[4];",
             "logic [32:0] a_address[4]; logic [255:0] a_data[4],d_data[4];",
             "logic [3:0] d_denied,d_corrupt;"]
    for prefix, interface in interfaces.items():
        for name, (_, width) in interface.items():
            lines.append(f"wire {width} {prefix}_{name};")
        connections = ",\n".join(f".{name}({prefix}_{name})" for name in interface)
        lines.append(f"{modules[prefix]} {prefix}({connections});")
    connected = set()

    def assign(destination, value):
        assert destination not in connected, destination
        connected.add(destination)
        lines.append(f"assign {destination}={value};")

    def couple(left_prefix, left_group, right_prefix, right_group):
        left, right = interfaces[left_prefix], interfaces[right_prefix]
        for name, (direction, _) in left.items():
            if not name.startswith(left_group):
                continue
            other = right_group + name[len(left_group):]
            assert other in right, other
            assert right[other][0] != direction, (name, other)
            if direction == "input":
                assign(f"{left_prefix}_{name}", f"{right_prefix}_{other}")
            else:
                assign(f"{right_prefix}_{other}", f"{left_prefix}_{name}")

    for bank in range(geometry.banks):
        couple("sb", f"auto_coupler_to_bus_named_coh_widget_anon_out_{bank}_",
               "coh", f"auto_coherent_jbar_anon_in_{bank}_")
        couple("coh", f"auto_coupler_to_bus_named_mbus_bus_xing_out_{bank}_",
               "mb", f"auto_bus_xing_in_{bank}_")
    for lane in range(4):
        prefix = f"auto_coupler_from_rockettile_tl_master_clock_xing_in_{lane}_"
        for name, (direction, _) in interfaces["sb"].items():
            if not name.startswith(prefix):
                continue
            field = name[len(prefix):]
            values = {"a_valid": f"a_valid[{lane}]", "a_bits_opcode": f"a_opcode[{lane}]",
                      "a_bits_source": f"a_source[{lane}]", "a_bits_address": f"a_address[{lane}]",
                      "a_bits_data": f"a_data[{lane}]", "a_bits_size": "6",
                      "a_bits_mask": "'1", "d_ready": f"d_ready[{lane}]", "b_ready": "1"}
            returns = {"a_ready": f"a_ready[{lane}]", "d_valid": f"d_valid[{lane}]",
                       "d_bits_source": f"d_source[{lane}]", "d_bits_data": f"d_data[{lane}]",
                       "d_bits_opcode": f"d_opcode[{lane}]", "d_bits_denied": f"d_denied[{lane}]",
                       "d_bits_corrupt": f"d_corrupt[{lane}]"}
            if direction == "input":
                assign("sb_" + name, values.get(field, "'0"))
            elif field in returns:
                assign(returns[field], "sb_" + name)
            elif field == "b_valid":
                lines.append(f'always @(posedge clock) if(!reset && sb_{name}) $fatal(1,"Unexpected CPU probe");')
    lines += ["axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(512),.ID_WIDTH(2)) axi();",
              "axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(512),.ID_WIDTH(2)) memory();",
              "assign axi.aclk=clock; assign axi.aresetn=~reset;",
              "assign memory.aclk=clock; assign memory.aresetn=~reset;"]
    axi_prefix = "auto_coupler_to_memory_controller_port_named_axi4_axi4yank_out_"
    for name, (direction, _) in interfaces["mb"].items():
        if name.startswith(axi_prefix):
            field = name[len(axi_prefix):].replace("_bits_", "").replace("_", "")
            if direction == "input":
                assign("mb_" + name, "axi." + field)
            else:
                assign("axi." + field, "mb_" + name)
    for prefix, interface in interfaces.items():
        for name, (direction, _) in interface.items():
            destination = prefix + "_" + name
            if direction != "input" or destination in connected:
                continue
            if name.endswith("_clock") or name == "clock":
                value = "clock"
            elif name.endswith("_reset") or name == "reset":
                value = "reset"
            elif name.endswith("_acknowledge"):
                value = prefix + "_" + name.replace("acknowledge", "request")
            elif name.endswith("_available") or name.endswith("_ready"):
                value = "1"
            else:
                value = "'0"
            assign(destination, value)
            # Any transaction to an unmodeled peripheral is a test failure.
            if name.endswith("_a_ready") and "coh" not in name and prefix != "coh":
                valid = name[:-5] + "valid"
                if valid in interface and not name.startswith("auto_coupler_from_"):
                    lines.append(f'always @(posedge clock) if(!reset && {prefix}_{valid}) $fatal(1,"Non-DDR request: {name}");')
    lines.append("""axi4_head_uram_router_v3 #(.ADDR_WIDTH(33),.DATA_WIDTH(512),
      .LOCAL_DATA_WIDTH(256),.ID_WIDTH(2),.DDR_OUTSTANDING(32),.SLOT_BYTES(512)) head(
      .clk(clock),.resetn(~reset),.s_axi(axi),.m_ddr_axi(memory),
      .local_read_bank(3'd0),.local_read_req_valid(1'b0),.local_read_req_ready(),
      .local_read_req_word_addr(4'd0),.local_read_rsp_data(),.local_read_rsp_valid(),
      .local_read_rsp_ready(1'b1),.perf_events());""")
    lines += ['`include "banked_memory_workload.svh"', "endmodule"]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    product = json.loads((ROOT / "hw/manifests/current.json").read_text())
    parser.add_argument("--rtl", type=Path, default=ROOT / product["collateral_directory"])
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--lanes", type=int, nargs="+", choices=(1, 3, 4), default=[1, 3, 4])
    parser.add_argument("--cases", type=int, nargs="+", choices=range(6), default=list(range(6)))
    parser.add_argument("--count", type=int, default=512)
    parser.add_argument("--seeds", type=int, nargs="+", default=[151034, 151035])
    parser.add_argument("--delays", type=int, nargs="+", default=[16, 128])
    parser.add_argument("--stalls", choices=("auto", "on", "off"), default="auto")
    parser.add_argument("--results-name", default="results.json", help="Separate JSON file for additional scenarios")
    parser.add_argument("--verilator", default=os.environ.get("HEAD_VERILATOR", shutil.which("verilator") or "verilator"))
    parser.add_argument("--reuse", action="store_true")
    args = parser.parse_args()
    assert re.fullmatch(r"[A-Za-z0-9_.-]+\.json", args.results_name)
    rtl, out = args.rtl.resolve(), args.output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    metadata = list(rtl.parent.glob("*.l2.json"))
    assert len(metadata) == 1
    geometry = L2Geometry.from_metadata(metadata[0])
    bench = make_bench(rtl, geometry)
    modules = {}
    for path in sorted(rtl.iterdir()):
        if path.suffix in (".v", ".sv"):
            for module in re.findall(r"^module\s+(\w+)", path.read_text(), re.M):
                modules[module] = path
    sources = set()

    def visit(module):
        path = modules[module]
        if path in sources:
            return
        sources.add(path)
        for child in re.findall(r"^\s+(\w+)\s+\w+\s*\(", path.read_text(), re.M):
            if child in modules:
                visit(child)

    for module in ("SystemBus", "CoherenceManagerWrapper", "MemoryBus"):
        visit(module)
    sources.update(ROOT / name for name in ("hw/rtl/interfaces/axi4_if.sv",
                   "hw/rtl/ai/postprocess/head_uram_store.sv", "hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv"))
    identity = dict(rtl_sha256={p.name: sha(p) for p in sorted(sources)},
                    bench_sha256=hashlib.sha256(bench.encode()).hexdigest(),
                    workload_sha256=sha(HERE / "banked_memory_workload.svh"), geometry=geometry.describe())
    manifest = out / "compiled_sources.json"
    target = out / "tb_banked_memory.sv"
    if args.reuse:
        assert json.loads(manifest.read_text()) == identity, "Compiled source identity changed"
    else:
        manifest.unlink(missing_ok=True)
        frozen = out / "rtl"
        frozen.mkdir(exist_ok=True)
        assert len({p.name for p in sources}) == len(sources)
        for path in sorted(sources):
            shutil.copyfile(path, frozen / path.name)
        shutil.copyfile(HERE / "banked_memory_workload.svh", out / "banked_memory_workload.svh")
        target.write_text(bench)
        with (out / "compile.log").open("w") as log:
            subprocess.run([args.verilator, "--binary", "--timing", "--assert", "-Wno-fatal", "-j", "4",
                            "--top-module", "tb_banked_memory", "--Mdir", str(out / "obj"),
                            "-I" + str(out), "-y", str(frozen), str(frozen / "axi4_if.sv"), str(target),
                            *map(str, frozen.glob("*.top.mems.v"))], stdout=log, stderr=subprocess.STDOUT, check=True)
        manifest.write_text(json.dumps(identity, indent=2) + "\n")
    rows = []
    for lanes in args.lanes:
        for delay in args.delays:
            for seed in args.seeds:
                for case in args.cases:
                    command = [out / "obj/Vtb_banked_memory", f"+LANES={lanes}", f"+CASE={case}",
                               f"+DELAY={delay}", f"+COUNT={args.count}", f"+SEED={seed}"]
                    stalls = args.stalls == "on" or (args.stalls == "auto" and delay > min(args.delays))
                    if stalls:
                        command.append("+STALLS")
                    result = subprocess.run(list(map(str, command)), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
                    log = out / f"case{case}_lanes{lanes}_delay{delay}_stalls{int(stalls)}_seed{seed}.log"
                    log.write_text(result.stdout)
                    assert result.returncode == 0 and "BANKED_MEMORY_SCOREBOARD=PASS" in result.stdout, str(log)
                    row = next(line for line in result.stdout.splitlines() if line.startswith("BANKED_MEMORY_PERF "))
                    rows.append({key: int(value) for key, value in re.findall(r"(\w+)=(\d+)", row)})
                    print(f"BANKED_MEMORY_CASE=PASS banks={geometry.banks} {row}", flush=True)
    report = dict(geometry=geometry.describe(), results=rows, compiled_sources_sha256=sha(manifest),
                  binary_sha256=sha(out / "obj/Vtb_banked_memory"),
                  path="generated SystemBus -> CoherenceManagerWrapper (TLJbar, L2, CacheCork) -> MemoryBus -> S1 Head",
                  requesters="synthetic traffic on three Gemmini DMA ports and optional CPU port",
                  memory="checked delayed AXI behavioral endpoint; full-line reads/writes",
                  DDR_CONTROLLER_PHY_REGISTER_SLICE="NOT_MODELED", ELF_GEMMINI_ARITHMETIC="NOT_RUN", BOARD_PERFORMANCE="NOT_MEASURED")
    (out / args.results_name).write_text(json.dumps(report, indent=2) + "\n")
    print(f"BANKED_MEMORY_COMPARISON=PASS banks={geometry.banks} scenarios={len(rows)}")


if __name__ == "__main__":
    main()
