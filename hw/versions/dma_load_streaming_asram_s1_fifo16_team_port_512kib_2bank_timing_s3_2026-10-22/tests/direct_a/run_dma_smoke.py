#!/usr/bin/env python3
"""Three native lanes: 16+16 FP16 DMA, masks, guards, mixed DDR/ASRAM sources.

This checks actual load/scale/SPAD/store hardware, not stage14 matmul or the graph.
The production RTL is read unchanged; only the external memory fixture is adapted.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts'))
from common import selected_output, sha

WORKLOAD = r'''
integer direct_case=0,direct_rows=1,direct_stride=16,direct_state=0;
reg [63:0] direct_a0,direct_a1,direct_delta;
reg [15:0] direct_scale0,direct_scale1;
reg [7:0] direct_golden[0:2047];
task prepare_conv;endtask
task check_conv;endtask
task initialize_dual(input integer c,p);
    direct_case=c;storage_profile=p;
    direct_rows=c==0?1:c==1?31:c==2?32:33;
    direct_stride=c==1?19:c==2?17:16;direct_state=c%3;
    direct_scale0=c==0?'h3c00:c==1?'h3800:c==2?'h4000:'hbc00;
    direct_scale1=c==0?'h3800:c==1?'h4000:c==2?'h3555:'h3c00;
    command_count=0;reads=0;writes=0;acks=0;fetches=0;
    for(integer i=0;i<65536;i=i+1)memory[i]='ha5;
    for(integer i=0;i<64*direct_stride+16;i=i+1)begin
        memory['h103f+i]=8'(i*7+ID*3+c*11);
        memory['h300f+i]=8'(i*13+ID*5+c*17+23);
    end
    direct_a0=64'(BASE)+(c%2?'h300f:'h103f);
    direct_a1=64'(BASE)+(c%2?'h103f:'h300f);
    direct_delta=(route_address(direct_a1,0)-route_address(direct_a0,0))&64'h1ffffffff;
    // Group -> legacy poison writes -> dual -> Group, without software drains.
    raw(0,64'h00003c0000200105,16,0);
    raw(2,64'(BASE)+'h103f,(64'd32<<48)|(64'd16<<32)|64'd4000,0);
    raw(0,64'h00003c0000200105,32,0);
    for(integer row=0;row<direct_rows+2;row=row+32)begin
        automatic integer n;
        n=(direct_rows+2-row)>32?32:direct_rows+2-row;
        raw(2,64'(BASE)+'h2000+row*32,(64'(n)<<48)|(64'd32<<32)|64'(63+row),0);
    end
    raw(0,(64'(direct_scale0)<<32)|64'h200105|(64'(direct_state)<<3),64'(direct_stride),0);
    raw(0,(64'(direct_scale1)<<32)|64'h85|(64'(direct_state)<<3),direct_delta,0);
    for(integer row=0;row<direct_rows;row=row+32)begin
        automatic integer n;
        n=(direct_rows-row)>32?32:direct_rows-row;
        raw(direct_state==0?2:direct_state==1?1:14,direct_a0+row*direct_stride,
            (64'(n)<<48)|(64'd32<<32)|64'(64+row),0);
    end
    // Ordinary configuration must clear private dual mode for this LD state.
    raw(0,64'h0000400000200105|(64'(direct_state)<<3),32,0);
    raw(0,64'h00003c0000200105,16,0);
    raw(2,64'(BASE)+'h300f,(64'd32<<48)|(64'd16<<32)|64'd5000,0);
    raw(0,2,64'h00003c0000000020,0);
    for(integer row=0;row<direct_rows+2;row=row+32)begin
        automatic integer n;
        n=(direct_rows+2-row)>32?32:direct_rows+2-row;
        raw(3,64'(BASE)+'h5000+row*32,(64'(n)<<48)|(64'd32<<32)|64'(63+row),0);
    end
    entry(256'd1);
endtask
task check_dual;
    integer expected,actual;
    if(writes!=acks || gem_busy)$fatal(1,"DirectA store/compute retired before ACK");
    $readmemh($sformatf("golden_lane%0d_case%0d.mem",ID,direct_case),direct_golden);
    for(integer i=0;i<(direct_rows+2)*32;i=i+1)begin
        expected=direct_golden[i];actual=memory['h5000+i];
        if(actual!==expected)$fatal(1,"DirectA byte/guard mismatch lane=%0d case=%0d profile=%0d byte=%0d expected=%h actual=%h",ID,direct_case,storage_profile,i,expected,actual);
    end
    $display("S1_DIRECT_A_DMA_LANE_PASS,lane=%0d,case=%0d,profile=%0d,rows=%0d,ld_state=%0d,bytes=%0d,guards=checked,mixed_sources=checked",ID,direct_case,storage_profile,direct_rows,direct_state,(direct_rows+2)*32);
endtask
'''

FIXTURE_OVERRIDE = r"""
    original_install = install
    def install(lane, out, rtl, ports):
        lane = original_install(lane, out, rtl, ports)
        old = '(storage_profile==1 || (storage_profile==2 && !store) || (storage_profile==3 && store))'
        assert lane.count(old) == 1
        # Bits 0/1 select the physical input regions; bit2 selects output.
        lane = lane.replace(old, '(store ? ((storage_profile&4)!=0) : (((address-BASE)<\'h2000) ? ((storage_profile&1)!=0) : ((storage_profile&2)!=0)))')
        lane = lane.replace('service_access(0,offset,data,unused);',
            "if(offset<'h1600 || (offset>='h2000 && offset<'h2500) || (offset>='h3000 && offset<'h3600))service_access(0,offset,data,unused);")
        lane = lane.replace('if(storage_profile==1 || storage_profile==3)begin', 'if((storage_profile&4)!=0)begin')
        start = lane.index("      for(integer offset='h2000;")
        end = lane.index("      for(integer offset='h5000;", start)
        lane = lane[:start] + lane[end:]
        lane = lane.replace("offset<'h5c00;offset=offset+32)begin\n        service_access", "offset<'h5000+(direct_rows+2)*32;offset=offset+32)begin\n        service_access")
        start = lane.index('    if(storage_profile==0 && (local_gets')
        end = lane.index('    $display("ASRAM_REAL_LANE_PASS', start)
        lane = lane[:start] + '''
    if((storage_profile&3)==0 && local_gets!=start_gets)$fatal(1,"unexpected local source read");
    if((storage_profile&3)!=0 && local_gets==start_gets)$fatal(1,"selected local source unused");
    if((storage_profile&4)==0 && local_puts!=start_puts)$fatal(1,"unexpected local store");
    if((storage_profile&4)!=0 && local_puts==start_puts)$fatal(1,"selected local output unused");
''' + lane[end:]
        return lane
"""

TB_BODY = r'''
  initial begin
    repeat(20)@(negedge clock);reset=0;repeat(64)@(negedge clock);
    for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)ctl(lane_id,9,2,0);
    for(integer p=0;p<8;p=p+1)for(integer c=0;c<4;c=c+1)begin
      fork
        begin lanes[0].lane.initialize_dual(c,p);lanes[0].lane.local_prepare();end
        begin lanes[1].lane.initialize_dual(c,p);lanes[1].lane.local_prepare();end
        begin lanes[2].lane.initialize_dual(c,p);lanes[2].lane.local_prepare();end
      join
      ctl(0,0,64'h80008000,64'(lanes[0].lane.command_count));
      ctl(1,0,64'h80018000,64'(lanes[1].lane.command_count));
      ctl(2,0,64'h80028000,64'(lanes[2].lane.command_count));
      for(integer i=0;i<3;i=i+1)begin ctl(i,1,64'h80000000+i*65536,1000000);ctl(i,6,500+i*20,0);end
      ctl(3,7,7,7);wait(dut.complete==7);@(negedge clock);
      fork
        begin lanes[0].lane.local_collect();lanes[0].lane.check_dual();end
        begin lanes[1].lane.local_collect();lanes[1].lane.check_dual();end
        begin lanes[2].lane.local_collect();lanes[2].lane.check_dual();end
      join
      for(integer i=0;i<3;i=i+1)ctl(i,5,0,0);
    end
    $display("REAL_CLUSTER_PASS,S1_DIRECT_A_DMA=1,lanes=3,cases=4,storage_combinations=8,records=96");
    $finish;
  end
  initial begin #2000000000;$fatal(1,"DirectA DMA timeout busy=%b done=%b",gemmini_busy,dut.complete);end
endmodule
'''


def scaled(value, bits):
    value = value - 256 if value >= 128 else value
    scale = struct.unpack('<e', struct.pack('<H', bits))[0]
    product = struct.unpack('<e', struct.pack('<e', value * scale))[0]
    return max(-128, min(127, round(product))) & 255


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--generated', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    out = args.output.resolve()
    if ROOT / 'build' not in out.parents:
        raise ValueError('Use a new output below this version build/')
    out.mkdir(parents=True, exist_ok=False)
    generated, context = selected_output(args.generated)
    assert context['build_parameters']['S1_DIRECT_A'] == '1'
    feature = out / 'feature'
    shutil.copytree(ROOT / 'tests/rtl/command_frontend/reference', feature / 'reference')
    lane = (feature / 'reference/MemoryLane.sv').read_text()
    start = lane.index('task initialize;')
    end = lane.index('endtask', start) + len('endtask')
    lane = lane[:start] + 'task initialize;endtask' + lane[end:]
    (feature / 'reference/MemoryLane.sv').write_text(lane)
    (feature / 'ConvWorkload.svh').write_text(WORKLOAD)
    simulation = out / 'simulation'
    simulation.mkdir()
    for lane_id in range(3):
        for case, n in enumerate((1, 31, 32, 33)):
            stride = 19 if case == 1 else 17 if case == 2 else 16
            scales = ((0x3c00, 0x3800), (0x3800, 0x4000), (0x4000, 0x3555), (0xbc00, 0x3c00))[case]
            data = [0xa5] * 32
            for row in range(n):
                for half in range(2):
                    for channel in range(16):
                        i = row*stride+channel
                        region = half ^ (case % 2)
                        value = (i*7+lane_id*3+case*11) if region == 0 else (i*13+lane_id*5+case*17+23)
                        data.append(scaled(value & 255, scales[half]))
            data += [0xa5] * 32
            (simulation / f'golden_lane{lane_id}_case{case}.mem').write_text('\n'.join(f'{v:02x}' for v in data) + '\n')
    driver = (ROOT / 'tests/merged_dma/test_real_gemmini.py').read_text()
    driver = driver.replace('feature = Path(__file__).resolve().parent', f'feature = Path({str(feature)!r})')
    driver = driver.replace('project = feature.parents[1]', f'project = Path({str(ROOT)!r})')
    anchor = '    from asram_sim import install, instrument_tb\n'
    assert driver.count(anchor) == 1
    driver = driver.replace(anchor, anchor + FIXTURE_OVERRIDE)
    anchor = '(out/"tb_real_cluster.sv").write_text(tb)'
    assert driver.count(anchor) == 1
    driver = driver.replace(anchor, "tb = tb.split('  initial begin', 1)[0] + " + repr(TB_BODY) + '\n' + anchor)
    (out / 'driver.py').write_text(driver)
    env = dict(os.environ, STREAM_ASRAM_SIM='1', STREAM_ASRAM_COMPACT='')
    subprocess.run([sys.executable, str(out / 'driver.py'), '--rtl', str(generated / 'gen-collateral'),
        '--output', str(simulation), '--dma-load-mode', 'all'], env=env, check=True)
    log = (simulation / 'result.log').read_text()
    records = re.findall(r'S1_DIRECT_A_DMA_LANE_PASS,lane=(\d+),case=(\d+),profile=(\d+)', log)
    assert len(records) == 96 and set(records) == {(str(l), str(c), str(p)) for l in range(3) for c in range(4) for p in range(8)}
    assert not re.search(r'Fatal:|Error:|Assertion failed:', log)
    (out / 'evidence.json').write_text(json.dumps(dict(status='PASS',
        hardware_build_id=context['dma_load_build_id'], records=96, lanes=3, rows=[1, 31, 32, 33],
        storage_combinations=8, native_dma=True, vendor_memory_primitives=True,
        stage14_matmul=False, full_model_executed=False, result_sha256=sha(simulation / 'result.log')),
        indent=2) + '\n')


if __name__ == '__main__':
    main()
