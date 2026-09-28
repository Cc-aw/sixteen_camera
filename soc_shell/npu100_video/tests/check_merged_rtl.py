#!/usr/bin/env python3
"""Check emitted ports, worker count, timing datapaths and final RAM geometry."""
from pathlib import Path
import re,sys
r=Path(sys.argv[1]);count=int(sys.argv[2]) if len(sys.argv)>2 else 3
def read(name):return (r/name).read_text()
model=sys.argv[3] if len(sys.argv)>3 else 'TaihangSoCFPGATestHarness'
top=read(model+'.sv')
for port in ['axi4_fbus_aw_valid','axi4_fbus_w_bits_data','axi4_mmio_aw_valid','axi4_mem_aw_valid','uart_txd','uart_rxd']:
    assert port in top,port
assert re.search(r'input\s+\[255:0\]\s+axi4_fbus_w_bits_data',top)
assert 'inst_jtag_tunnel' in read('ChipTop.sv')
workers=re.findall(r'^  Gemmini(?:_\d+)?\s+\w+\s*\(',read('RocketTile.sv'),re.M)
assert len(workers)==count,(len(workers),count)
assert 'RegisteredIngressAtomicReserve' in read('RoccCommandRouter.sv')
assert 'NUM_READ_PORTS(64)' in read('AccumulatorScale.sv')
for name in ['AccScalePipe.sv','ScalePipe.sv']:assert 'MulRawFN' in read(name)
assert 'responseQueue' in read('StreamReader.sv')
assert 'TimingResultQueue' in read('ExecuteController.sv')
assert 'PipelinedDualMac' in read('Tile.sv')
assert any('GemminiTimingMac' in p.read_text() for p in r.glob('PipelinedDualMac*.sv'))
mems=list(r.glob('*.top.mems.v'));assert len(mems)==1
mem=mems[0].read_text()
for token in ['ram_style = "ultra"','reg [2047:0] ram [0:255]',
              '(* ram_style = "block" *) reg [199:0] ram [0:511]']:
    assert token in mem,token
assert len(re.findall(r'^  MSHR mshrs_',read('InclusiveCacheBankScheduler.sv'),re.M))==6
assert 'Queue16_GemminiCmd cmd_q' in read('LoadController.sv')
assert 'Queue8_GemminiCmd cmd_q' in read('StoreController.sv')
window=read('RegisteredCommandWindow.sv')
assert 'data_15_cmd_inst_funct' in window
station=read('ReservationStation.sv')
for token in ['entries_ld_15_valid','entries_st_7_valid','entries_ex_31_valid']:
    assert token in station,token
writer=read('StreamWriter.sv')
assert 'output [4:0]    auto_out_a_bits_source' in writer
assert 'reg  [31:0]   xactBusy' in writer
assert 'parameter integer OUTPUT_WIDTH = 20' in read('GemminiTimingMac.sv')
mac_wrappers='\n'.join(p.read_text() for p in r.glob('PipelinedDualMac*.sv'))
assert re.search(r'\.OUTPUT_WIDTH\(24\)',mac_wrappers), 'INT24 timing MAC override missing'
print(f'MERGED_RTL_STRUCTURE=PASS workers={count} DMA=256 MMIO=64 shared_scale=64 OUT=INT24 ACC=256KiB')
