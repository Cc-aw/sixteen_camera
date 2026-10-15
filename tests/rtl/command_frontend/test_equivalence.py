#!/usr/bin/env python3
"""Compare native Chisel RTL outputs cycle-by-cycle with frozen board-tested v5."""
from pathlib import Path
import re
import subprocess

feature = Path(__file__).resolve().parent
project = feature.parents[2]
import os
if not os.environ.get("SOC_WORKSPACE"):
    raise SystemExit("Set SOC_WORKSPACE to a fully rebuilt current Chipyard workspace")
cy = Path(os.environ["SOC_WORKSPACE"]).resolve()
# Refuse stale assemblies/source overlays.
import sys
sys.path.insert(0, str(project / "tools/soc"))
from build_triple32_v3_tensor import validate_workspace_sources
validate_workspace_sources(cy)
out = project / "build/sim/command_frontend/equivalence"
out.mkdir(parents=True, exist_ok=True)
classes = project / "build/sim/command_frontend/classes"
classes.mkdir(parents=True, exist_ok=True)
jar = cy / ".classpath_cache/chipyard_fpga.jar"
cache = cy / ".coursier/v1/https/repo1.maven.org/maven2"
compiler = cache / "org/scala-lang/scala-compiler/2.13.16/scala-compiler-2.13.16.jar"
plugin = cache / "org/chipsalliance/chisel-plugin_2.13.16/6.7.0/chisel-plugin_2.13.16-6.7.0.jar"
java = str(cy / ".conda-env/lib/jvm/bin/java")
env = dict(os.environ, CHISEL_FIRTOOL_PATH=str(cy / ".conda-env/riscv-tools/bin"))

def run(cmd):
    subprocess.run(list(map(str,cmd)), check=True, cwd=project, env=env)

run([java, "-cp", f"{compiler}:{jar}", "scala.tools.nsc.Main",
     "-classpath", f"{classes}:{jar}", f"-Xplugin:{plugin}",
     "-d", classes, feature / "Emit.scala"])

reference = feature / "reference"
for kind, refname, native, test in [
    ("engine", "GemminiCommandFrontend", "CommandFrontendEngine", "frontend"),
    ("cluster", "GemminiFrontendCluster", "CommandFrontendCluster", "cluster"),
    ("memory", "GemminiFrontendMemoryMux", "CommandFrontendMemoryMux", "memory_mux"),
]:
    target = out / kind
    target.mkdir(exist_ok=True)
    run([java, "-Xmx4G", "-cp", f"{classes}:{jar}", "frontendtest.Emit", target, kind])
    original = (reference / f"{refname}.sv").read_text()
    source = original.replace(f"module {refname}", f"module {refname}Reference", 1)
    (target / "reference.sv").write_text(source)
    # Parse the reference ANSI ports, including comma-shared wire declarations.
    header = original.split(");",1)[0]
    ports = []
    for match in re.finditer(r"\b(input|output)\s+(wire|reg)\s*(\[[^]]+\])?\s*([^;()]+?)(?=,\s*(?:input|output)|\s*$)", header, re.S):
        direction, _, width, names = match.groups()
        names = names.strip().rstrip(",")
        for name in names.split(","):
            name = name.strip()
            if not re.fullmatch(r"\w+", name):
                raise RuntimeError(f"bad port {name}")
            ports.append((direction, width or "", name))
    if len(ports) < 20:
        raise RuntimeError("port parser incomplete")
    declarations = ",\n".join(f"  {d} wire {w} {n}" for d,w,n in ports)
    body = [f"module {refname} (\n{declarations}\n);"]
    outs = [(w,n) for d,w,n in ports if d=="output"]
    for width,name in outs:
        body += [f"wire {width} native_{name};"]
    body += [f"{refname}Reference reference (.*);"]
    if kind == "cluster":
        # Retain only hierarchy observation aliases used by the original bench.
        for width,name,expr in [("[2:0]","host_wait","host_wait"),("[2:0]","complete","complete"),
                                ("[2:0]","fault","fault"),("[2:0]","armed","armed"),("[63:0]","cycle","cycle")]:
            body += [f"wire {width} {name} = reference.{expr};"]
    if kind == "memory":
        body += ["wire id31_busy = reference.id31_busy;"]
    bindings = []
    for direction,width,name in ports:
        pin = name if name in ("clock","reset") else "io_"+name
        signal = "native_"+name if direction=="output" else name
        bindings.append(f".{pin}({signal})")
    body += [f"{native} native_dut ("+",".join(bindings)+");"]
    # Payload bits can differ only when the relevant VALID is deasserted.
    guards = {
        "cmd_funct":"cmd_valid", "cmd_rs1":"cmd_valid", "cmd_rs2":"cmd_valid",
        "mem_req_address":"mem_req_valid", "response_rd":"response_valid", "response_data":"response_valid",
        "a_opcode":"a_valid", "a_param":"a_valid", "a_size":"a_valid", "a_source":"a_valid",
        "a_address":"a_valid", "a_mask":"a_valid", "a_data":"a_valid", "a_corrupt":"a_valid",
        "g_d_opcode":"g_d_valid", "g_d_param":"g_d_valid", "g_d_size":"g_d_valid",
        "g_d_source":"g_d_valid", "g_d_sink":"g_d_valid", "g_d_denied":"g_d_valid",
        "g_d_data":"g_d_valid", "g_d_corrupt":"g_d_valid",
        "f_resp_data":"f_resp_valid","f_resp_error":"f_resp_valid",
    }
    body += ["always @(negedge clock) if (!reset) begin", "#1;"]
    for width,name in outs:
        if name.startswith("gemmini_cmd_") and name != "gemmini_cmd_valid":
            # Check each lane's payload only while that lane is presenting it.
            bits = 7 if name.endswith("funct") else 64
            for i in range(3):
                body += [f'if (gemmini_cmd_valid[{i}] && native_{name}[{i*bits}+:{bits}] !== {name}[{i*bits}+:{bits}]) $fatal(1,"DIFF {kind} {name} lane{i}");']
        elif kind == "cluster" and name == "mem_req_address":
            for i in range(3):
                body += [f'if (mem_req_valid[{i}] && native_{name}[{i*32}+:32] !== {name}[{i*32}+:32]) $fatal(1,"DIFF cluster address");']
        else:
            guard = guards.get(name, "1'b1")
            body += [f'if (({guard}) && native_{name} !== {name}) $fatal(1,"DIFF {kind} {name}: native=%h reference=%h",native_{name},{name});']
    body += ["end", "endmodule"]
    (target / "miter.sv").write_text("\n".join(body)+"\n")
    sources = [target / "reference.sv", target / "miter.sv"] + sorted(target.glob("CommandFrontend*.sv"))
    if kind == "cluster":
        sources += [reference / "GemminiCommandFrontend.sv"]
    if kind == "engine":
        sources += [reference / "LegacyV4Adapter.sv"]
    run(["verilator","--binary","--timing","--assert","-Wno-fatal","-j","4",
         "--top-module",f"tb_{test}","--Mdir",target/"obj",*sources,reference/f"tb_{test}.sv"])
    run([target/"obj"/f"Vtb_{test}"])
    print(f"CHISEL_V5_CYCLE_EQUIVALENCE={kind}:PASS",flush=True)
