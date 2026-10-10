#!/usr/bin/env python3
"""Exercise the generated Tensor ingress, CDC, real inclusive L2 and CacheCork."""
import argparse
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--collateral", type=Path, default=root / "hw/soc/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitTensorIngressConfig/gen-collateral")
args = parser.parse_args()
src = args.collateral
out = root / "build/sim/tensor_ingress/l2"
out.mkdir(parents=True, exist_ok=True)
files = set()


def ports(name):
    text = (src / f"{name}.sv").read_text()
    header = re.search(rf"module {name}\((.*?)\);", text, re.S)[1]
    header = re.sub(r"//[^\n]*", "", header)
    direction = None
    result = []
    for declaration in header.split(","):
        match = re.search(r"\b(input|output)\b", declaration)
        if match:
            direction = match[1]
        result.append((direction, re.findall(r"\w+", declaration)[-1]))
    return result


def instance(name, mapping, inst):
    connections = []
    for direction, port in ports(name):
        value = mapping.get(port)
        if value is None:
            value = "" if direction == "output" else "'0"
        connections.append(f".{port}({value})")
    return f"{name} {inst}(\n" + ",\n".join(connections) + "\n);\n"


def dependencies(name):
    path = src / f"{name}.sv"
    if path in files or not path.exists():
        return
    files.add(path)
    for child in re.findall(r"^  (\w+) \w+ \(", path.read_text(), re.M):
        dependencies(child)


wrapper = """module tensor_ingress_l2_wrapper(
input wire clk, reset, input wire video_clk, axi4_if.slave video_axi,
input wire test_a_valid, output wire test_a_ready,
input wire [2:0] test_a_opcode, test_a_param,
input wire [8:0] test_a_source, input wire [32:0] test_a_address,
output wire test_d_valid, input wire test_d_ready,
output wire [2:0] test_d_opcode, output wire [4:0] test_d_sink,
output wire [255:0] test_d_data,
output wire probe_valid, input wire probe_ready,
output wire [32:0] probe_address,
input wire c_valid, output wire c_ready, input wire [2:0] c_opcode, c_param,
input wire [32:0] c_address, input wire [255:0] c_data,
input wire e_valid, input wire [4:0] e_sink,
input wire partial_mode,
output wire mem_a_valid, input wire mem_a_ready,
output wire [2:0] mem_a_opcode, output wire [5:0] mem_a_source,
output wire [32:0] mem_a_address, output wire [255:0] mem_a_data,
input wire mem_d_valid, output wire mem_d_ready,
input wire [2:0] mem_d_opcode, input wire [5:0] mem_d_source,
input wire [255:0] mem_d_data,
input wire csr_a_valid, output wire csr_a_ready,
input wire [2:0] csr_a_opcode, input wire [25:0] csr_a_address,
input wire [63:0] csr_a_data, input wire [1:0] csr_a_size,
output wire csr_d_valid, input wire csr_d_ready, output wire [63:0] csr_d_data);
axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) axi();
tensor_coherent_write_cdc cdc(.tensor_write_axi(video_axi),.soc_clk(clk),.soc_resetn(!reset),.tensor_soc_axi(axi));
wire writer_a_valid, writer_a_ready, writer_d_valid, writer_d_denied;
// The generated writer optimizes its always-ready D pin away.
wire writer_d_ready = 1'b1;
wire [4:0] writer_a_source, writer_d_source;
wire [32:0] writer_a_address;
wire [255:0] writer_a_data;
wire [2:0] writer_d_opcode;
wire l2_a_ready, l2_d_valid, l2_d_ready, l2_d_denied;
wire [2:0] l2_d_opcode;
wire [8:0] l2_d_source;
wire [4:0] l2_d_sink;
wire [255:0] l2_d_data;
assign writer_a_ready = l2_a_ready && !test_a_valid;
assign test_a_ready = l2_a_ready && !writer_a_valid;
assign writer_d_valid = l2_d_valid && l2_d_source < 32;
assign writer_d_source = l2_d_source[4:0];
assign writer_d_opcode = l2_d_opcode;
assign writer_d_denied = l2_d_denied;
assign test_d_valid = l2_d_valid && l2_d_source >= 32;
assign test_d_opcode = l2_d_opcode;
assign test_d_sink = l2_d_sink;
assign test_d_data = l2_d_data;
assign l2_d_ready = l2_d_source < 32 ? writer_d_ready : test_d_ready;
wire outer_a_valid, outer_a_ready, outer_c_valid, outer_c_ready, outer_d_valid, outer_d_ready, outer_e_valid;
wire [2:0] outer_a_opcode, outer_a_param, outer_a_size, outer_c_opcode, outer_c_param, outer_c_size, outer_d_opcode, outer_d_size;
wire [4:0] outer_a_source, outer_c_source, outer_d_source;
wire [2:0] outer_d_sink, outer_e_sink;
wire [1:0] outer_d_param;
wire [32:0] outer_a_address, outer_c_address;
wire [31:0] outer_a_mask;
wire [255:0] outer_a_data, outer_c_data, outer_d_data;
wire outer_a_corrupt, outer_c_corrupt, outer_d_denied, outer_d_corrupt;
"""
writer = {"clock": "clk", "reset": "reset", "auto_control_in_a_valid": "csr_a_valid",
          "auto_control_in_a_ready": "csr_a_ready", "auto_control_in_a_bits_opcode": "csr_a_opcode",
          "auto_control_in_a_bits_address": "csr_a_address", "auto_control_in_a_bits_data": "csr_a_data",
          "auto_control_in_a_bits_mask": "8'hff", "auto_control_in_a_bits_size": "csr_a_size",
          "auto_control_in_d_ready": "csr_d_ready", "auto_control_in_d_valid": "csr_d_valid",
          "auto_control_in_d_bits_data": "csr_d_data"}
for _, port in ports("TaihangTensorIngress"):
    if port.startswith("io_"):
        writer[port] = "axi." + port.removeprefix("io_").replace("_bits_", "").replace("_", "")
    elif port.startswith("auto_out_"):
        writer[port] = "writer_" + port.removeprefix("auto_out_").replace("_bits_", "_")
wrapper += instance("TaihangTensorIngress", writer, "writer")
l2 = {"clock": "clk", "reset": "reset", "auto_ctrls_ctrl_in_d_ready": "1'b1",
      "auto_in_a_valid": "writer_a_valid || test_a_valid", "auto_in_a_ready": "l2_a_ready",
      "auto_in_a_bits_opcode": "test_a_valid ? test_a_opcode : (partial_mode ? 3'd1 : 3'd0)",
      "auto_in_a_bits_param": "test_a_valid ? test_a_param : 3'd0", "auto_in_a_bits_size": "3'd6",
      "auto_in_a_bits_source": "test_a_valid ? test_a_source : {4'd0,writer_a_source}",
      "auto_in_a_bits_address": "test_a_valid ? test_a_address : writer_a_address",
      "auto_in_a_bits_mask": "32'hffffffff", "auto_in_a_bits_data": "writer_a_data",
      "auto_in_b_valid": "probe_valid", "auto_in_b_ready": "probe_ready", "auto_in_b_bits_address": "probe_address",
      "auto_in_c_valid": "c_valid", "auto_in_c_ready": "c_ready", "auto_in_c_bits_opcode": "c_opcode",
      "auto_in_c_bits_param": "c_param", "auto_in_c_bits_size": "3'd6", "auto_in_c_bits_source": "9'h120",
      "auto_in_c_bits_address": "c_address", "auto_in_c_bits_data": "c_data",
      "auto_in_e_valid": "e_valid", "auto_in_e_bits_sink": "e_sink"}
for _, port in ports("InclusiveCache"):
    if port.startswith("auto_in_d_"):
        suffix = port.removeprefix("auto_in_").replace("_bits_", "_")
        if suffix not in ("d_param", "d_size", "d_corrupt"):
            l2[port] = "l2_" + suffix
    elif port.startswith("auto_out_"):
        l2[port] = "outer_" + port.removeprefix("auto_out_").replace("_bits_", "_")
wrapper += instance("InclusiveCache", l2, "l2")
cork = {"clock": "clk", "reset": "reset"}
for _, port in ports("TLCacheCork"):
    if port.startswith("auto_in_"):
        cork[port] = "outer_" + port.removeprefix("auto_in_").replace("_bits_", "_")
    elif port.startswith("auto_out_"):
        suffix = port.removeprefix("auto_out_").replace("_bits_", "_")
        if suffix not in ("a_param", "a_size", "a_mask", "a_corrupt"):
            cork[port] = "mem_" + suffix
# The memory side has no params/corrupt errors in this correctness model.
wrapper += "wire [1:0] mem_d_param = 0; wire [2:0] mem_d_size = 6; wire mem_d_denied = 0, mem_d_corrupt = 0;\n"
wrapper += instance("TLCacheCork", cork, "cork") + "endmodule\n"
(out / "wrapper.sv").write_text(wrapper)
for name in ("TaihangTensorIngress", "InclusiveCache", "TLCacheCork"):
    dependencies(name)
memory_files = list(src.glob("*.top.mems.v"))
if len(memory_files) != 1:
    raise SystemExit("Expected one generated SRAM model file")
subprocess.run(["verilator", "--binary", "--timing", "--assert", "-Wno-fatal", "-j", "4",
                "--top-module", "tb_tensor_ingress_l2", "--Mdir", str(out / "obj"),
                str(root / "hw/rtl/interfaces/axi4_if.sv"),
                str(root / "hw/rtl/bus/cdc_payload_fifo.sv"),
                str(root / "hw/rtl/bus/axi4_ui_write_cdc.sv"),
                str(root / "hw/rtl/memory/tensor_coherent_write_cdc.sv"),
                *map(str, sorted(files)), str(memory_files[0]), str(out / "wrapper.sv"),
                str(root / "tests/rtl/benches/tensor/tb_tensor_ingress_l2.sv")], check=True)
subprocess.run([str(out / "obj/Vtb_tensor_ingress_l2")], check=True)
