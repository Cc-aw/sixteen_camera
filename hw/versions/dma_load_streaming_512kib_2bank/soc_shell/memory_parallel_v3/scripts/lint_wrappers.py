#!/usr/bin/env python3
"""Port/width lint using the actual generated IP and SoC module declarations.

Only the generated internals are stubbed; their independent functional tests
and DDR IP validation are separate checks, not replaced by this wiring lint.
"""
import argparse
import re
import subprocess
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("source", type=Path)
p.add_argument("soc_rtl", type=Path)
p.add_argument("ddr_ip", type=Path)
p.add_argument("output", type=Path)
a = p.parse_args()
out = a.output.resolve()
out.mkdir(parents=True, exist_ok=False)
wrapper = next(a.ddr_ip.glob("*.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v"))
(out / "design_1_wrapper.v").write_text(wrapper.read_text().split("  design_1 design_1_i")[0] + "endmodule\n")
soc = (a.soc_rtl / "TaihangSoCFPGATestHarness.sv").read_text()
(out / "soc_ports.sv").write_text(soc[:soc.index("\n);")+3] + "\nendmodule\n")
unisims = Path("/mnt/data/Vivado/Vivado/2023.2/data/verilog/src/unisims")
# Use the actual primitive declaration. Vendor functional models are not
# portable lint inputs and add no information to the module boundary check.
primitive = (unisims / "BUFGCE_DIV.v").read_text()
primitive = primitive[primitive.index("module BUFGCE_DIV"):]
primitive = primitive[:primitive.index(");")+2]
(out / "primitive_ports.v").write_text(primitive + "\nendmodule\n" +
    "module IBUFDS(output O,input I,IB); endmodule\nmodule BUFG(output O,input I); endmodule\n")
rtl = a.source.resolve() / "rtl"
sources = sorted(rtl.rglob("*.sv")) + sorted(rtl.rglob("*.v"))
si5338 = rtl / "si5338/si5338top.v"
decl = si5338.read_text(errors="replace").split("module si5338top",1)[1].split(");",1)[0]
(out / "si5338_ports.v").write_text("module si5338top" + decl + ");\nendmodule\n")
sources.remove(si5338)
sources.sort(key=lambda f: (0 if "pkg" in f.parts else 1 if "interfaces" in f.parts else 2, str(f)))
sources += [out / name for name in ("design_1_wrapper.v", "soc_ports.sv", "primitive_ports.v", "si5338_ports.v")]
board = (rtl / "top_wrapper.sv").read_text()
decls = re.findall(r"    axi(?:4|_lite)_if #\(.*?;", board, re.S)
interfaces = {
    "ddr_memory_subsystem": {n:n for n in ("soc_mem_axi", "postprocess_axil", "writer_video_axi", "reader_video_axi", "tensor_write_video_axi")},
    "control_soc_subsystem": {"mem_axi":"soc_mem_axi", "mmio_axi":"soc_mmio_axi"},
}
for top, connections in interfaces.items():
    connections["fbus_axi"] = "soc_fbus_axi"
    text = "module lint_" + top + ";\n" + "\n".join(decls) + "\n"
    text += top + " dut(" + ",".join("."+pin+"("+net+")" for pin,net in connections.items()) + ");\nendmodule\n"
    path = out / ("lint_"+top+".sv")
    path.write_text(text)
    sources.append(path)
report = {}
for top in ("ddr_memory_subsystem", "control_soc_subsystem"):
    cmd = ["verilator", "--lint-only", "--timing", "--bbox-unsup", "-Wno-fatal",
           "--top-module", "lint_"+top, *map(str, sources)]
    with (out / (top + ".log")).open("w") as log:
        subprocess.run(cmd, cwd=out, stdout=log, stderr=subprocess.STDOUT, check=True)
    warnings = re.findall(r"^%Warning-([^:]+): (.*)", (out / (top + ".log")).read_text(), re.M)
    # New sideband and widened AXI connections must have exact port widths.
    errors = [line for kind, line in warnings if kind.startswith("WIDTH") and
              any(x in line for x in ("/control/control_soc_subsystem", "/memory/ddr_platform",
                  "/memory/ddr_memory_subsystem", "/memory/memory_perf", "/memory/postprocess_memory_bridge"))]
    if errors:
        raise SystemExit("New interface width warning: " + "\n".join(errors))
    report[top] = len(warnings)
(out / "result.txt").write_text("MEMORY_V3_WRAPPER_LINT_PASS\n" + repr(report) + "\n")
print((out / "result.txt").read_text())
