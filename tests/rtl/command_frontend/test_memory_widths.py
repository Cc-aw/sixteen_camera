#!/usr/bin/env python3
"""Production-width mux: all DMA IDs, high address bit, and lease/backpressure."""
from pathlib import Path
import argparse
import hashlib
import re
import subprocess

feature = Path(__file__).resolve().parent
project = feature.parents[2]
import json
product = json.loads((project / "hw/manifests/current.json").read_text())
rtl = project / product["collateral_directory"]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--rtl',type=Path)
parser.add_argument('--output',type=Path)
args=parser.parse_args()
context=None
if args.rtl:
    if not args.output:parser.error('--output is required with private --rtl')
    rtl=args.rtl.resolve()
    context=json.loads((rtl.parent/'GENERATION_CONTEXT.json').read_text())
    for name,expected in context['final_rtl_sha256'].items():
        assert hashlib.sha256((rtl/name).read_bytes()).hexdigest()==expected,name
rtl = rtl / "CommandFrontendMemoryMux.sv"
out = args.output.resolve() if args.output else project / "build/sim/command_frontend/memory_widths"
out.mkdir(parents=True,exist_ok=True)
header=re.sub(r"//[^\n]*","",rtl.read_text().split(");",1)[0])
ports=re.findall(r"^\s*(input|output)\s+(\[[^]]+\]\s*)?(\w+)\s*[,\n]",header,re.M)
decl=[];bind=[]
for direction,width,name in ports:
    external=name.removeprefix("io_")
    decl.append(f"{direction} wire {width} {external}")
    bind.append(f".{name}({external})")
(out/"wrapper.sv").write_text("module GemminiFrontendMemoryMux(\n"+",\n".join(decl)+");\nCommandFrontendMemoryMux native_dut("+",".join(bind)+");\nwire id31_busy=native_dut.idBusy;\nendmodule\n")
tb=(feature/"reference/tb_memory_mux.sv").read_text()
for a,b in {
    "[4:0]":"[5:0]",
    "wire [5:0] g_d_source,g_d_sink;":"wire [5:0] g_d_source; wire [6:0] g_d_sink;",
    "reg [5:0] d_source=0,d_sink=0;":"reg [5:0] d_source=0; reg [6:0] d_sink=0;",
    "reg [31:0] g_a_address=32'h80002000,g_a_mask='1;":"reg [32:0] g_a_address=33'h180002000;reg [31:0] g_a_mask='1;",
    "wire [31:0] a_address,a_mask;":"wire [32:0] a_address;wire [31:0] a_mask;",
}.items():
    assert a in tb,a
    tb=tb.replace(a,b)
probe='''
    // Bit32 and IDs32..63 were absent on the old DIM4 platform.
    a_ready=1;
    for(integer id=0;id<64;id=id+1)begin
      g_a_valid=1;g_a_opcode=4;g_a_source=6'(id);g_a_size=5;
      g_a_address=33'h180001000+id*32;
      #1;if(!g_a_ready || a_source!==6'(id) || a_address!==g_a_address)
        $fatal(1,"DMA request width lost id=%0d",id);
      tick();g_a_valid=0;
      d_valid=1;d_source=6'(id);d_size=5;d_opcode=1;d_sink=7'h65;
      #1;if(!g_d_valid || f_resp_valid || g_d_source!==6'(id) || g_d_sink!==7'h65)
        $fatal(1,"DMA response width lost id=%0d",id);
      tick();d_valid=0;
    end
    a_ready=0;
'''
tb=tb.replace("repeat(3) tick();reset=0;","repeat(3) tick();reset=0;\n"+probe)
tb=tb.replace("MEMORY_MUX_PASS,", "MEMORY_MUX_PASS,addr_bits=33,source_ids=64,sink_bits=7,")
(out/"tb.sv").write_text(tb)
verilator="verilator"
subprocess.run([str(verilator),"--binary","--timing","--assert","-Wno-fatal","-j","4","--top-module","tb_memory_mux","--Mdir",str(out/"obj"),str(rtl),str(out/"wrapper.sv"),str(out/"tb.sv")],check=True)
result=subprocess.check_output([str(out/"obj/Vtb_memory_mux")],text=True)
(out/'result.log').write_text(result)
print(result)
assert 'MEMORY_MUX_PASS,addr_bits=33,source_ids=64,sink_bits=7,' in result
if context is not None:
    (out/'evidence.json').write_text(json.dumps(dict(status='MEMORY_MUX_WIDTH_LEASE_PASS',
        build_id=context['dma_load_build_id'],rtl=str(rtl),rtl_sha256=hashlib.sha256(rtl.read_bytes()).hexdigest(),
        log_sha256=hashlib.sha256(result.encode()).hexdigest()),indent=2)+'\n')
