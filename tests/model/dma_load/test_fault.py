#!/usr/bin/env python3
"""Real three-lane DMA fault propagation, no DONE, coordinated reset."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[3]


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rtl',type=Path,required=True)
    p.add_argument('--output',type=Path,required=True)
    args=p.parse_args();out=args.output.resolve();out.mkdir(parents=True,exist_ok=False)
    original=ROOT/'tests/rtl/command_frontend';feature=out/'feature'
    (feature/'reference').mkdir(parents=True)
    lane=(original/'reference/MemoryLane.sv').read_text()
    lane=lane.replace('wire d_denied=0,d_corrupt=0;', 'reg d_denied=0,d_corrupt=0;integer inject_fault=0;')
    lane=lane.replace('if(!reset) begin', '''if(reset)begin
      d_valid<=0;remaining<=0;response_delay<=0;write_beat<=0;d_denied<=0;d_corrupt<=0;
    end else begin''')
    lane=lane.replace('d_size<=a_size;d_source<=a_source;', '''d_size<=a_size;d_source<=a_source;
        d_denied<=inject_fault==1 && a_opcode==4 && a_source!=31;
        d_corrupt<=inject_fault!=0 && a_opcode==4 && a_source!=31;''')
    (feature/'reference/MemoryLane.sv').write_text(lane)
    tb=(original/'reference/tb_real_cluster.sv').read_text()
    tb=tb.replace('if(|dut.fault)$fatal(1,"frontend fault mask=%b",dut.fault);','')
    (feature/'reference/tb_real_cluster.sv').write_text(tb)
    workload=r'''
task prepare_conv;endtask
task check_conv;endtask
task initialize_fault;
  command_count=0;reads=0;writes=0;acks=0;fetches=0;
  for(integer i=0;i<65536;i=i+1)memory[i]=8'ha5;
  for(integer i=0;i<6;i=i+1)memory['h103f+i]=8'(11+i+ID);
  raw(0,64'h00003c0000200101,3,0);
  raw(2,64'(BASE)+'h103f,64'h0002000300000040,0);
  entry(256'd1);
  raw(0,2,64'h00003c0000000003,0);
  raw(3,64'(BASE)+'h5000,64'h0002000300000040,0);
  entry(256'd1);
endtask
task check_recovered;
  if(gem_busy || gem_fault || writes!=acks)$fatal(1,"Recovery did not drain");
  for(integer i=0;i<6;i=i+1)if(memory['h5000+i]!==8'(11+i+ID))$fatal(1,"Recovery bytes differ");
endtask
'''
    (feature/'ConvWorkload.svh').write_text(workload)
    body=r'''
  initial begin
    repeat(20)@(negedge clock);reset=0;repeat(64)@(negedge clock);
    for(integer fault_kind=1;fault_kind<=2;fault_kind=fault_kind+1)begin
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)ctl(lane_id,9,2,0);
      lanes[0].lane.inject_fault=fault_kind;lanes[1].lane.inject_fault=fault_kind;lanes[2].lane.inject_fault=fault_kind;
      lanes[0].lane.initialize_fault();lanes[1].lane.initialize_fault();lanes[2].lane.initialize_fault();
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
        ctl(lane_id,0,64'h80008000+lane_id*65536,6);
        ctl(lane_id,1,64'h80000000+lane_id*65536,1000000);
      end
      ctl(3,7,7,7);wait(&gemmini_fault && &dut.fault);
      repeat(128)begin
        @(negedge clock);
        if(gemmini_fault!==3'b111 || gemmini_busy!==3'b111 || dut.complete!==0)$fatal(1,"Fault must hold busy without DONE");
      end
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
        @(negedge clock);control_valid=1;control_funct=7'((lane_id<<5)|9);control_rs1=0;control_rs2=0;
        do @(posedge clock);while(!control_ready);
        @(negedge clock);control_valid=0;
        if(!response_valid || response_data!==4)$fatal(1,"Fault mode switch must be rejected");
        read(lane_id,8,v);if(v!==2)$fatal(1,"Fault changed mode");
      end
      $display("DMA_FAULT_HOLD_PASS,kind=%0d,lanes=3,no_done=checked,mode_reject=checked",fault_kind);
      // Reset every participant, including the memory endpoint.
      reset=1;repeat(20)@(negedge clock);reset=0;repeat(64)@(negedge clock);
      lanes[0].lane.inject_fault=0;lanes[1].lane.inject_fault=0;lanes[2].lane.inject_fault=0;
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
        read(lane_id,8,v);if(v!==0)$fatal(1,"Reset must restore legacy");
        ctl(lane_id,9,2,0);
      end
      lanes[0].lane.initialize_fault();lanes[1].lane.initialize_fault();lanes[2].lane.initialize_fault();
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
        ctl(lane_id,0,64'h80008000+lane_id*65536,6);
        ctl(lane_id,1,64'h80000000+lane_id*65536,1000000);
      end
      ctl(3,7,7,7);wait(&dut.complete);@(negedge clock);
      lanes[0].lane.check_recovered();lanes[1].lane.check_recovered();lanes[2].lane.check_recovered();
      ctl(0,5,0,0);ctl(1,5,0,0);ctl(2,5,0,0);
      $display("DMA_FAULT_RECOVERY_PASS,kind=%0d,lanes=3,bytes=18",fault_kind);
    end
    $display("REAL_CLUSTER_PASS,DMA_FAULT=1,kinds=2,lanes=3");$finish;
  end
  initial begin #5000000;$fatal(1,"Fault propagation/recovery timeout");end
endmodule
'''
    runner=(original/'test_real_gemmini.py').read_text()
    runner=runner.replace('feature = Path(__file__).resolve().parent',f'feature = Path({str(feature)!r})')
    runner=runner.replace('project = feature.parents[2]',f'project = Path({str(ROOT)!r})')
    runner=runner.replace('(out/"MemoryLane.sv").write_text(lane)',
        'lane=lane.replace(\'if(gem_fault) $fatal(1,"Gemmini %0d fault",ID);\',\'\')\n(out/"MemoryLane.sv").write_text(lane)')
    anchor='(out/"tb_real_cluster.sv").write_text(tb)'
    runner=runner.replace(anchor,'tb=tb[:tb.index("  initial begin")]+ '+repr(body)+'\n'+anchor)
    (out/'run.py').write_text(runner)
    subprocess.run([sys.executable,str(out/'run.py'),'--rtl',str(args.rtl.resolve()),'--output',str(out),'--dma-load-mode','all'],check=True)
    log=(out/'result.log').read_text()
    assert log.count('DMA_FAULT_HOLD_PASS,')==2 and log.count('DMA_FAULT_RECOVERY_PASS,')==2
    context=json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())
    (out/'evidence.json').write_text(json.dumps(dict(status='REAL_FAULT_RECOVERY_PASS',
        build_id=context['dma_load_build_id'],kinds=['denied','corrupt'],lanes=3,
        log_sha256=hashlib.sha256(log.encode()).hexdigest()),indent=2)+'\n')


if __name__=='__main__':main()
