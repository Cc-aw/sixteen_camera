#!/usr/bin/env python3
"""Check handwritten connections against actual generated SoC and DDR port declarations."""
import argparse
import os
import shutil
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
NAME = "tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--project", type=Path, default=ROOT / "build/projects/triple32_v3_tensor")
parser.add_argument("--vivado", default=os.environ.get("VIVADO_BIN", "vivado"))
args = parser.parse_args()
vivado = shutil.which(args.vivado)
if not vivado:
    raise SystemExit("Set VIVADO_BIN or --vivado to Vivado 2023.2")
out = ROOT / "build/reports/triple32_v3_tensor_wrapper_lint"
out.mkdir(parents=True, exist_ok=True)
wrapper = next(args.project.glob("*.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v"))
text = wrapper.read_text()
(out / "ddr_ports.v").write_text(text[:text.index("  design_1 design_1_i")] + "endmodule\n")
soc = (ROOT / "hw/soc" / NAME / "gen-collateral/TaihangSoCFPGATestHarness.sv").read_text()
(out / "soc_ports.sv").write_text(soc[:soc.index("\n);")+3] + "\nendmodule\n")
# Primitives and clock-chip implementation are outside this boundary check.
primitive = (Path(vivado).resolve().parent.parent / "data/verilog/src/unisims/BUFGCE_DIV.v").read_text()
primitive = primitive[primitive.index("module BUFGCE_DIV"):]
primitive = primitive[:primitive.index(");")+2]
(out / "primitives.v").write_text(primitive + "\nendmodule\n" +
    "module IBUFDS(output O,input I,IB); endmodule\nmodule BUFG(output O,input I); endmodule\n")
chip = (ROOT / "hw/rtl/si5338/si5338top.v").read_text(errors="replace")
chip = chip.split("module si5338top",1)[1].split(");",1)[0]
(out / "si5338_ports.v").write_text("module si5338top" + chip + ");\nendmodule\n")
rtl = ROOT / "hw/rtl"
sources = sorted(rtl.rglob("*.sv")) + sorted(rtl.rglob("*.v"))
sources.remove(rtl / "si5338/si5338top.v")
sources.sort(key=lambda p: (0 if "pkg" in p.parts else 1 if "interfaces" in p.parts else 2, str(p)))
sources += [out / name for name in ["ddr_ports.v", "soc_ports.sv", "primitives.v", "si5338_ports.v"]]
decls = """axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(512),.ID_WIDTH(2)) mem();
axi4_if #(.ADDR_WIDTH(31),.DATA_WIDTH(64),.ID_WIDTH(4)) mmio();
axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) fbus(),tensor();
axi4_if #(.ADDR_WIDTH(32),.DATA_WIDTH(256),.ID_WIDTH(3)) writer(),reader(),video_tensor();
axi_lite_if #(.ADDR_WIDTH(18)) ppu();
"""
pins = {
    "control_soc_subsystem": {"mem_axi":"mem", "mmio_axi":"mmio", "fbus_axi":"fbus", "tensor_axi":"tensor"},
    "ddr_memory_subsystem": {"soc_mem_axi":"mem", "fbus_axi":"fbus", "tensor_soc_axi":"tensor",
        "writer_video_axi":"writer", "reader_video_axi":"reader", "tensor_write_video_axi":"video_tensor", "postprocess_axil":"ppu"},
}
for module, mapping in pins.items():
    top = "lint_" + module
    harness = out / (top + ".sv")
    harness.write_text("module " + top + ";\n" + decls + module + " dut(" +
                       ",".join(f".{p}({n})" for p,n in mapping.items()) + ");\nendmodule\n")
    log = out / (module + ".log")
    with log.open("w") as stream:
        subprocess.run(["verilator", "--lint-only", "--timing", "--bbox-unsup", "-Wno-fatal",
                        "-DSOC_MEMORY_PARALLEL_V3", "-DSOC_TENSOR_INGRESS", "--top-module", top,
                        *map(str, sources), str(harness)], stdout=stream, stderr=subprocess.STDOUT, check=True)
    # Missing unconnected scalar pins are expected in this interface harness.
    width = [line for line in log.read_text().splitlines() if line.startswith("%Warning-WIDTH") and
             any(name in line for name in ["control_soc_subsystem.sv", "ddr_platform.sv", "ddr_memory_subsystem.sv",
                 "memory_perf_external.sv", "postprocess_memory_bridge_v3.sv", "axi4_head_uram_router_v3.sv"])]
    if width:
        raise SystemExit("Interface width mismatch: " + "\n".join(width))
print("V3_TENSOR_WRAPPER_LINT=PASS actual_soc_and_ddr_port_declarations")
