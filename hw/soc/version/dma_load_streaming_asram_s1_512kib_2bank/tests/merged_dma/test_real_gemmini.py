#!/usr/bin/env python3
"""Three REAL DIM32/FP16 Gemminis + Chisel frontend/MemoryMux + delayed DDR model.

The tiny 4x4 matrix workload is retained, not the old 4x4 compute hardware.
Only simulation ties and test constants are generated; production RTL is read-only.
"""
from pathlib import Path
import os
import re
import subprocess
import json
import sys
import shutil
import argparse
import hashlib

feature = Path(__file__).resolve().parent
project = feature.parents[1]
import json
product = {"collateral_directory":"generated/gen-collateral"}
rtl = project / product["collateral_directory"]
out = project / "build/sim/command_frontend/real32"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--rtl', type=Path)
parser.add_argument('--output', type=Path)
parser.add_argument('--dma-load-mode', choices=('legacy', 'read_coalesced', 'read_assembled', 'spad_assembled', 'all'))
args = parser.parse_args()
if args.rtl is not None:
    rtl = args.rtl.resolve()
    if args.output is None:
        parser.error('--output is required for private candidate RTL')
    out = args.output.resolve()
    context = json.loads((rtl.parent / 'GENERATION_CONTEXT.json').read_text())
    for name, expected in context['final_rtl_sha256'].items():
        assert hashlib.sha256((rtl / name).read_bytes()).hexdigest() == expected, name
    if args.dma_load_mode is not None:
        assert context.get('dma_load_runtime_enable') and context['l2_banks'] == 2
elif args.dma_load_mode is not None:
    parser.error('--dma-load-mode requires explicit candidate --rtl')
out.mkdir(parents=True,exist_ok=True)

def ports(file):
    h = re.sub(r"//[^\n]*","",file.read_text().split(");",1)[0])
    return re.findall(r"^\s*(input|output)\s+(\[[^]]+\]\s*)?(\w+)\s*[,\n]",h,re.M)

# Wrap the generated native cluster/mux using the established flat port names.
wrappers = []
for native,alias in [("CommandFrontendCluster","GemminiFrontendCluster"),
                     ("CommandFrontendMemoryMux","GemminiFrontendMemoryMux")]:
    ps = ports(rtl/f"{native}.sv")
    decls = []; bindings = []
    for direction,width,name in ps:
        external = name.removeprefix("io_")
        decls.append(f"{direction} wire {width} {external}")
        bindings.append(f".{name}({external})")
    fixed_modes = []
    if "Cluster" in native:
        names = {name for _, _, name in ps}
        for i in range(3):
            if f'io_dma_load_mode_{i}' not in names:
                decls.append(f'output wire [1:0] dma_load_mode_{i}')
                fixed_modes.append(f"assign dma_load_mode_{i}=2'd2;\n")
            if f'io_dma_load_capabilities_{i}' not in names:
                decls.append(f'input wire [31:0] dma_load_capabilities_{i}')
    body = f"module {alias}(\n"+",\n".join(decls)+");\n"
    body += f"{native} native_dut("+",".join(bindings)+");\n"
    body += ''.join(fixed_modes)
    if "Cluster" in native:
        # All test observations derive from public ABI queries/status.
        body += "wire [2:0] host_wait=native_dut.hostWait;\n"
        body += "wire [2:0] complete=native_dut.complete;\nwire [2:0] fault=native_dut.fault;\n"
    wrappers.append(body+"endmodule\n")
(out/"FrontendWrappers.sv").write_text("\n".join(wrappers))

text = (rtl/"Gemmini.sv").read_text()
ps = ports(rtl/"Gemmini.sv")
decls=[]; bindings=[]
for direction,width,name in ps:
    if name in ("clock","reset","io_cmd_ready","io_cmd_valid","io_cmd_bits_inst_funct",
                "io_cmd_bits_rs1","io_cmd_bits_rs2","io_busy","io_interrupt") or name.startswith("auto_spad_id_out_") or (args.dma_load_mode is not None and name in ('io_dma_load_mode','io_dma_load_capabilities')):
        decls.append(f"{direction} wire {width} {name}"); value=name
    elif direction=="output": value=""
    else:
        value="'0"
        if name in ("io_cmd_bits_status_dprv","io_cmd_bits_status_prv","io_cmd_bits_status_mpp"): value="2'd3"
        if name=="io_cmd_bits_inst_opcode": value="7'h0b"
        if name in ("io_cmd_bits_inst_xs1","io_cmd_bits_inst_xs2","io_resp_ready"): value="1'b1"
        if name=="io_loopconv_request_accept": value="io_cmd_valid && io_cmd_ready && io_cmd_bits_inst_funct==15"
    bindings.append(f".{name}({value})")
extra=""
if not any(n=='io_dma_load_mode' for _,_,n in ps):
    decls.append('input wire [1:0] io_dma_load_mode')
if args.dma_load_mode is not None and not any(n=='io_dma_load_capabilities' for _,_,n in ps):
    # Whole-SoC constant propagation folds this worker output into the real
    # frontend. Preserve that verified constant at the simulation wrapper.
    capability=int(context['dma_load_capability_word'], 0)
    assert f"64'h{capability:x}" in (rtl/'CommandFrontendCluster.sv').read_text().lower()
    decls.append('output wire [31:0] io_dma_load_capabilities')
    extra += f"assign io_dma_load_capabilities=32'h{capability:x};\n"
if not any(n=="io_interrupt" for _,_,n in ps):
    # Physical bare-address Gemmini has no fault-producing DTLB; firtool folded
    # the constant-false output away. Reflect that constant, do not invent IRQ.
    decls.append("output wire io_interrupt")
    extra+="assign io_interrupt=1'b0;\n"
(out/"TestGemmini.sv").write_text("module TestGemmini(\n"+",\n".join(decls)+");\nGemmini dut("+",".join(bindings)+");\n"+extra+"endmodule\n")

lane=(feature/"reference/MemoryLane.sv").read_text()
replacements={
 "wire [4:0] g_a_source,g_d_source,g_d_sink;":"wire [5:0] g_a_source,g_d_source; wire [6:0] g_d_sink;",
 "wire [31:0] g_a_address,g_a_mask;":"wire [32:0] g_a_address; wire [31:0] g_a_mask;",
 "wire [4:0] a_source;":"wire [5:0] a_source;",
 "wire [31:0] a_address,a_mask;":"wire [32:0] a_address; wire [31:0] a_mask;",
 "reg [4:0] d_source=0;":"reg [5:0] d_source=0;",
 "wire [4:0] d_sink=0;":"wire [6:0] d_sink=0;",
 "64'h3f80000000040101":"64'h00003c0000200101",
 "64'h3f80000000010004":"64'h00003c0000010004",
 "64'h3f80000000000010":"64'h00003c0000000010",
 "64'h0004000400000004":"64'h0004000400000020",
 "if(a_source==31)fetches<=fetches+1;":"",
 "if(gem_fault) $fatal":"if(f_req_valid && f_req_ready)fetches<=fetches+1;\n      if(gem_fault) $fatal",
}
for a,b in replacements.items():
    assert a in lane,a
    lane=lane.replace(a,b)
(out/"MemoryLane.sv").write_text(lane)
tb=(feature/"reference/tb_real_cluster.sv").read_text()
tb=tb.replace("100000);","1000000);").replace("#2000000;","#20000000;")
lane=lane.replace("matmul('h2100);", "matmul('h2100); prepare_conv();")
lane=lane.replace("endmodule",(feature/"ConvWorkload.svh").read_text()+"\nendmodule")
(out/"MemoryLane.sv").write_text(lane)
tb=tb.replace("i==0?41:40", "i==0?116:115").replace("fetches!=41", "fetches!=116").replace("fetches!=40", "fetches!=115")
tb=tb.replace("reset=0;", "reset=0; repeat(64)@(negedge clock);")
tb=tb.replace("if(triple_cycles==0)","lanes[0].lane.check_conv();lanes[1].lane.check_conv();lanes[2].lane.check_conv();\n    if(triple_cycles==0)")
tb=tb.replace("REAL_CLUSTER_PASS,gemmini=3","REAL_CLUSTER_PASS,dim=32,scale=fp16,conv_chunks=6,silu_lut=checked,gemmini=3")
tb=tb.replace("module tb_real_cluster;", "module tb_real_cluster;\n  glbl glbl();")
if args.dma_load_mode is not None:
    lane = lane.replace('input wire clock,reset,',
        'input wire clock,reset,input wire [1:0] dma_load_mode,output wire [31:0] dma_load_capabilities,')
    lane = lane.replace('.clock(clock),.reset(reset),.io_cmd_ready',
        '.io_dma_load_mode(dma_load_mode),.io_dma_load_capabilities(dma_load_capabilities),.clock(clock),.reset(reset),.io_cmd_ready')
    lane = lane.replace('task initialize;', 'task initialize;\n command_count=0;reads=0;writes=0;acks=0;fetches=0;')
    (out/'MemoryLane.sv').write_text(lane)
    tb = tb.replace('integer triple_cycles=0,',
        'wire [1:0] dma_load_mode_0,dma_load_mode_1,dma_load_mode_2;\n'
        'wire [31:0] dma_load_capabilities_0,dma_load_capabilities_1,dma_load_capabilities_2;\n'
        'wire [1:0] load_modes[0:2];wire [31:0] load_caps[0:2];\n'
        'assign load_modes[0]=dma_load_mode_0;assign load_modes[1]=dma_load_mode_1;assign load_modes[2]=dma_load_mode_2;\n'
        'assign dma_load_capabilities_0=load_caps[0];assign dma_load_capabilities_1=load_caps[1];assign dma_load_capabilities_2=load_caps[2];\n'
        'integer runtime_mode;integer triple_cycles=0,')
    tb = tb.replace('.clock(clock),.reset(reset),.cmd_valid',
        '.dma_load_mode(load_modes[g]),.dma_load_capabilities(load_caps[g]),.clock(clock),.reset(reset),.cmd_valid')
    # One elaboration, one simulation, no reset between runtime modes.
    begin = tb.index('    lanes[0].lane.initialize();')
    end = tb.index('    for(integer i=0;i<3;i=i+1)begin', begin)
    selected = context['dma_load_mode_ids']
    tb = tb[:begin] + ('    repeat(20)@(negedge clock);reset=0;repeat(64)@(negedge clock);\n'
        f'    for(runtime_mode={selected[0]};runtime_mode<={selected[-1]};runtime_mode=runtime_mode+1)begin\n'
        '      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin\n'
        '        ctl(lane_id,9,64\'(runtime_mode),0);read(lane_id,8,v);\n'
        '        if(v!==64\'(runtime_mode))$fatal(1,"runtime mode readback");\n'
        '      end\n'
        '      lanes[0].lane.initialize();lanes[1].lane.initialize();lanes[2].lane.initialize();\n') + tb[end:]
    tb = tb.replace('    $finish;',
        '    $display("DMA_LOAD_REAL_MODE_PASS,mode=%0d",runtime_mode);\n'
        '    end\n    $display("DMA_LOAD_REAL_RUNTIME_PASS");\n    $finish;')
    tb = tb.replace('#20000000;', '#100000000;')
if os.environ.get("STREAM_ASRAM_SIM") == "1":
    sys.path.insert(0,str(project/"tests/asram"))
    from asram_sim import install, instrument_tb
    lane=install((out/"MemoryLane.sv").read_text(),out,rtl,ports)
    (out/"MemoryLane.sv").write_text(lane)
(out/"tb_real_cluster.sv").write_text(tb)
if os.environ.get("STREAM_ASRAM_SIM") == "1":
    (out/"tb_real_cluster.sv").write_text(instrument_tb((out/"tb_real_cluster.sv").read_text()))

# Transitive module closure includes generated memories and resource blackboxes.
mapping={};contents={}
for file in rtl.rglob("*"):
    if file.suffix not in (".sv",".v"):continue
    contents[file]=file.read_text()
    for name in re.findall(r"^module\s+(\w+)",contents[file],re.M): mapping[name]=file
seen=set()
def visit(name):
    file=mapping[name]
    if file in seen:return
    seen.add(file)
    for dep in re.findall(r"^\s+(\w+)\s+(?:#\s*\(|\w+\s*\()",contents[file],re.M):
        if dep in mapping:visit(dep)
for name in ("Gemmini","CommandFrontendCluster","CommandFrontendMemoryMux"):visit(name)
if os.environ.get("STREAM_ASRAM_SIM") == "1":
    for name in ("ActivationSramTL","ActivationSramTL_1","ActivationSramTL_2"):visit(name)
sources=sorted(seen)+[out/n for n in ("FrontendWrappers.sv","TestGemmini.sv","MemoryLane.sv","tb_real_cluster.sv")]
if os.environ.get("STREAM_ASRAM_SIM") == "1":sources.append(out/"TestAsramBank.sv")
# Use Xilinx's unmodified functional primitive and the project's existing
# sandbox-compatible XSim kernel launcher; no substitute for production BRAM.
vivado_bin = shutil.which(os.environ.get("VIVADO_BIN", "vivado"))
if not vivado_bin:
    raise SystemExit("Set VIVADO_BIN to the installed Vivado executable")
vivado = Path(vivado_bin).resolve().parents[1]
sources += [vivado/"data/verilog/src/glbl.v"]
assert all(f.is_file() for f in sources), "Vivado simulation sources unavailable"
prj=out/"simulation.prj"
prj.write_text("\n".join(f'sv work "{f}"' for f in sources)+"\n")
# Chisel RRArbiter deliberately leaves lastGrant unreset. Give such registers
# concrete power-up values using firtool's own initialization blocks; leaving
# them X in a four-state simulator stalls the first non-identity scale. This
# define is simulation-only and does not change the candidate RTL/bitstream.
defines=["-d","RANDOMIZE_REG_INIT"] if args.dma_load_mode is not None else []
(out/'simulation_options.json').write_text(json.dumps(dict(register_initialization=defines,
    rationale='Generated RRArbiter has an intentionally unreset lastGrant',
    runtime_modes=args.dma_load_mode),indent=2)+'\n')
for command in ([str(vivado/"bin/xvlog"),"--incr","--relax",*defines,"-prj",str(prj)],
                [str(vivado/"bin/xelab"),"tb_real_cluster","-L","unisims_ver","--relax","--mt","4","-s","real32"]):
    subprocess.run(command,check=True,cwd=out)
os.environ["VIVADO_ROOT"]=str(vivado)
sys.path.insert(0,str(project/"tests/rtl"))
from run_ddr_axi_crossbar_throughput_test import run_snapshot
result=run_snapshot("real32",out)
(out/"result.log").write_text(result)
print(result)
if not any(marker in result for marker in ("REAL_CLUSTER_PASS", "REAL_TRACE_LAYERS_PASS")) or "Fatal:" in result or "Error:" in result:
    raise SystemExit("REAL_CLUSTER_FAIL: see result.log")
