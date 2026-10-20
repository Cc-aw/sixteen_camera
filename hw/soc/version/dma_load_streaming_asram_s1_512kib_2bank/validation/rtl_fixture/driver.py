#!/usr/bin/env python3
"""Real Reader -> FP16 scale -> SPAD -> mvout; poison, RAW and write counts."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import re

ROOT=Path('/mnt/data/wzr/13p/ov7670/sixteen_camera/hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank')


def write_evidence(out,rtl,matrix,isolated_case):
    log=(out/'result.log').read_text()
    expected_cases={isolated_case} if isolated_case is not None else set(range(6 if matrix else 1))
    assert 'REAL_CLUSTER_PASS,DMA_SPAD=1' in log and not re.search(r'Fatal:|Error:|Assertion failed:',log)
    records=[]
    for line in log.splitlines():
        if 'DMA_SPAD_PASS,' not in line:continue
        fields=dict(re.findall(r'(\w+)=([a-zA-Z0-9]+)',line))
        row={k:int(fields[k]) for k in ('lane','mode','sram_writes','dma_gets')}
        row['case']=int(fields.get('case',0))
        row['compared_bytes']=(int(fields['rows'])+int(fields['pixels'])+1)*32 if matrix else int(fields['bytes'])
        assert all(fields[k]=='checked' for k in ('poison','RAW','zero'))
        records.append(row)
    mode_count=len(json.loads((rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())['dma_load_supported_modes'])
    keys={(r['case'],r['mode'],r['lane']) for r in records}
    assert len(records)==len(keys)==3*mode_count*len(expected_cases)
    assert keys=={(c,2,l)for c in expected_cases for l in range(3)}
    context=json.loads((rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())
    report=dict(status='REAL_SPAD_RAW_POISON_PASS',build_id=context['dma_load_build_id'],
        modes=mode_count,lanes=3,compared_bytes=sum(r['compared_bytes']for r in records),
        parameter_cases=len(expected_cases),traffic=records,
        log_sha256=hashlib.sha256(log.encode()).hexdigest())
    (out/'evidence.json').write_text(json.dumps(report,indent=2)+'\n')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--rtl',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--matrix',action='store_true',help='Also exercise ordinary mvin widths/scales unrelated to model layer numbers')
    p.add_argument('--case',type=int,choices=range(6),help='Isolate one matrix case for diagnosis')
    p.add_argument('--verify-only',action='store_true',help='Recheck complete existing results without rerunning simulation')
    args=p.parse_args();out=args.output.resolve()
    if args.case is not None and not args.matrix:p.error('--case requires --matrix')
    if args.verify_only:
        write_evidence(out,args.rtl,args.matrix,args.case);return
    out.mkdir(parents=True,exist_ok=False)
    original=ROOT/'tests/rtl/command_frontend';feature=out/'feature'
    (feature/'reference').mkdir(parents=True)
    for name in ('MemoryLane.sv','tb_real_cluster.sv'):
        (feature/'reference'/name).write_bytes((original/'reference'/name).read_bytes())
    code=r'''
task prepare_conv;endtask
task check_conv;endtask
reg [31:0] previous_writes=0;
integer observed_writes[0:3];integer observed_gets[0:3];integer previous_gets=0;
integer actual_gets=0;integer actual_return_bytes=0;
always @(posedge clock)if(!reset)begin
  if(g_a_valid && g_a_ready && g_a_opcode==4)actual_gets=actual_gets+1;
  if(g_d_valid && g_d_ready && g_d_opcode==1)actual_return_bytes=actual_return_bytes+32;
end
task initialize_raw;
  command_count=0;reads=0;writes=0;acks=0;fetches=0;
  for(integer i=0;i<65536;i=i+1)memory[i]=8'ha5;
  for(integer i=0;i<96;i=i+1)memory['h103f+i]=8'(i*7+11+ID*3);
  raw(0,64'h00003c0000200101,32,0);
  raw(2,64'(BASE)+'h2000,64'h002000200000003b,0);
  raw(2,64'(BASE)+'h2400,64'h000700200000005b,0);
  entry(256'd1);
  raw(0,64'h00003c0000200601,3,0);
  raw(2,64'(BASE)+'h103f,64'h0020000300000040,0);
  raw(2,0,64'h0002000300000060,0);
  raw(0,2,64'h00003c0000000020,0);
  // Reads depend on the preceding loads; no extra DRAIN before mvout.
  raw(3,64'(BASE)+'h5000,64'h002000200000003b,0);
  raw(3,64'(BASE)+'h5400,64'h000700200000005b,0);
  entry(256'd1);
endtask
task check_raw;
  integer expected,actual,offset,p;
  if(writes!=acks || gem_busy)$fatal(1,"RAW/store completion before ACK");
  for(integer row=59;row<98;row=row+1)for(integer byte_index=0;byte_index<32;byte_index=byte_index+1)begin
    expected='ha5;
    // Golden is the original repeated masked writes, never a sliding window.
    for(integer input_row=0;input_row<32;input_row=input_row+1)
      for(integer repeat_index=5;repeat_index>=0;repeat_index=repeat_index-1)
        if(row==64+input_row-repeat_index && byte_index>=repeat_index*3 && byte_index<repeat_index*3+3)
          expected=(input_row*3+byte_index-repeat_index*3)*7+11+ID*3;
    for(integer input_row=0;input_row<2;input_row=input_row+1)
      for(integer repeat_index=5;repeat_index>=0;repeat_index=repeat_index-1)
        if(row==96+input_row-repeat_index && byte_index>=repeat_index*3 && byte_index<repeat_index*3+3)expected=0;
    offset='h5000+(row-59)*32+byte_index;actual=memory[offset];
    if(actual!==(expected&255))$fatal(1,"SPAD poison/RAW mismatch mode=%0d lane=%0d row=%0d byte=%0d expected=%h actual=%h",dma_load_mode,ID,row,byte_index,expected&255,actual);
  end
  observed_writes[dma_load_mode]=gemmini.dut.spad.io_counter_external_values_22-previous_writes;
  previous_writes=gemmini.dut.spad.io_counter_external_values_22;
  observed_gets[dma_load_mode]=actual_gets-previous_gets;previous_gets=actual_gets;
  if(observed_writes[dma_load_mode]!=(dma_load_mode==0?255:dma_load_mode==1?243:83))
    $fatal(1,"actual SRAM write count differs mode=%0d writes=%0d",dma_load_mode,observed_writes[dma_load_mode]);
  if(observed_gets[dma_load_mode]!=(dma_load_mode==0?73:42))
    $fatal(1,"actual Get count differs mode=%0d gets=%0d",dma_load_mode,observed_gets[dma_load_mode]);
  $display("DMA_SPAD_PASS,lane=%0d,mode=%0d,bytes=1248,sram_writes=%0d,dma_gets=%0d,poison=checked,RAW=checked,zero=checked",ID,dma_load_mode,observed_writes[dma_load_mode],observed_gets[dma_load_mode]);
endtask
'''
    cases=1
    if args.matrix:
        cases=6
        declarations=r'''
integer parameter_case=0,channels=3,repetitions=6,input_rows=32,source_stride=3,scale_bits='h3c00;
integer output_rows,first_row,fragments,expected_writes,expected_gets,unknown_value;
reg [7:0] baseline[0:24575];
function integer request_count(input [63:0] address,input integer bytes);
  reg [63:0] cursor;integer left,n32,n64,n;
  cursor=address;left=bytes;request_count=0;
  while(left>0)begin
    n32=(left<32-cursor[4:0])?left:32-cursor[4:0];
    n64=(left<64-cursor[5:0])?left:64-cursor[5:0];
    n=n64>n32?n64:n32;cursor=cursor+n;left=left-n;request_count=request_count+1;
  end
endfunction
task select_parameters(input integer index);
  parameter_case=index;
  case(index)
    0:begin channels=3;repetitions=6;input_rows=32;source_stride=3;scale_bits='h3c00;end
    1:begin channels=1;repetitions=32;input_rows=2;source_stride=1;scale_bits='h3c00;end
    2:begin channels=8;repetitions=4;input_rows=32;source_stride=8;scale_bits='h4000;end
    3:begin channels=12;repetitions=2;input_rows=32;source_stride=12;scale_bits='h3c00;end
    4:begin channels=16;repetitions=2;input_rows=32;source_stride=16;scale_bits='h4000;end
    5:begin channels=12;repetitions=2;input_rows=3;source_stride=32;scale_bits='h7e00;end
  endcase
  first_row=64-repetitions+1;output_rows=input_rows+repetitions-1+2;
endtask
'''
        code=declarations+code
        start=code.index('  for(integer i=0;i<96;i=i+1)')
        end=code.index('\nendtask',start)
        code=code[:start]+r'''
  for(integer row=0;row<input_rows;row=row+1)for(integer c=0;c<channels;c=c+1)
    memory['h103f+row*source_stride+c]=8'((row*channels+c)*7+11+ID*3);
  raw(0,64'h00003c0000200101,32,0);
  for(integer offset=0;offset<output_rows;offset=offset+32)
    raw(2,64'(BASE)+'h2000+offset*32,(64'((output_rows-offset)>32?32:(output_rows-offset))<<48)|(64'd32<<32)|64'(first_row+offset),0);
  entry(256'd1);
  raw(0,(64'(scale_bits)<<32)|(64'd32<<16)|(64'(repetitions)<<8)|1,64'(source_stride),0);
  raw(2,64'(BASE)+'h103f,(64'(input_rows)<<48)|(64'(channels)<<32)|64'd64,0);
  raw(2,0,(64'd2<<48)|(64'(channels)<<32)|64'(64+input_rows),0);
  raw(0,2,64'h00003c0000000020,0);
  for(integer offset=0;offset<output_rows;offset=offset+32)
    raw(3,64'(BASE)+'h5000+offset*32,(64'((output_rows-offset)>32?32:(output_rows-offset))<<48)|(64'd32<<32)|64'(first_row+offset),0);
  entry(256'd1);'''+code[end:]
        a=code.index('  for(integer row=59;');b=code.index('  observed_writes[dma_load_mode]',a)
        code=code[:a]+r'''
  for(integer row=first_row;row<first_row+output_rows;row=row+1)for(integer byte_index=0;byte_index<32;byte_index=byte_index+1)begin
    expected='ha5;unknown_value=0;
    for(integer input_row=0;input_row<input_rows;input_row=input_row+1)
      for(integer k=repetitions-1;k>=0;k=k-1)
        if(row==64+input_row-k && byte_index>=k*channels && byte_index<k*channels+channels)begin
          expected=((input_row*channels+byte_index-k*channels)*7+11+ID*3)&255;
          if(expected>=128)expected=expected-256;
          if(scale_bits=='h4000)begin
            expected=expected*2;if(expected>127)expected=127;if(expected< -128)expected= -128;
          end
          unknown_value=(scale_bits=='h7e00);
        end
    for(integer input_row=0;input_row<2;input_row=input_row+1)
      for(integer k=repetitions-1;k>=0;k=k-1)
        if(row==64+input_rows+input_row-k && byte_index>=k*channels && byte_index<k*channels+channels)begin expected=0;unknown_value=0;end
    offset=(row-first_row)*32+byte_index;actual=memory['h5000+offset];
    if(dma_load_mode==0)baseline[parameter_case*4096+offset]=actual;
    // HardFloat RecFNToIN maps NaN to signed INT8 maximum (excSign=false).
    // The fixed-mode test has no legacy-mode run to populate a baseline.
    if(unknown_value)expected=127;
    if(actual!==(expected&255))$fatal(1,"parameterized SPAD mismatch case=%0d mode=%0d lane=%0d row=%0d byte=%0d expected=%h actual=%h",parameter_case,dma_load_mode,ID,row,byte_index,expected&255,actual);
  end
'''+code[b:]
        a=code.index('  if(observed_writes[dma_load_mode]!=');b=code.index('\nendtask',a)
        code=code[:a]+r'''
  fragments=0;
  for(integer row=0;row<input_rows;row=row+1)fragments=fragments+request_count(64'(BASE)+'h103f+row*source_stride,channels);
  expected_writes=output_rows+fragments*repetitions+2*repetitions;
  expected_gets=output_rows+fragments;
  if(dma_load_mode!=0 && source_stride==channels)begin
    if(dma_load_mode!=3)expected_gets=output_rows+request_count(64'(BASE)+'h103f,input_rows*channels);
    expected_writes=output_rows+input_rows*repetitions+2*repetitions;
  end
  if(dma_load_mode>=2)expected_writes=output_rows+input_rows+repetitions-1+2+repetitions-1;
  if(observed_writes[dma_load_mode]!=expected_writes || observed_gets[dma_load_mode]!=expected_gets)
    $fatal(1,"parameterized traffic mismatch case=%0d mode=%0d writes=%0d/%0d gets=%0d/%0d",parameter_case,dma_load_mode,observed_writes[dma_load_mode],expected_writes,observed_gets[dma_load_mode],expected_gets);
  $display("DMA_SPAD_PASS,lane=%0d,case=%0d,mode=%0d,channels=%0d,rows=%0d,pixels=%0d,scale=%h,sram_writes=%0d,dma_gets=%0d,poison=checked,RAW=checked,zero=checked",ID,parameter_case,dma_load_mode,channels,input_rows,repetitions,scale_bits,observed_writes[dma_load_mode],observed_gets[dma_load_mode]);'''+code[b:]
    if args.case is not None:
        code += r'''
always @(posedge clock)if(!reset && ID==0)begin
  if(cmd_valid && cmd_ready)$display("SPAD_DEBUG_CMD,f=%0d,a=%h,b=%h",cmd_funct,cmd_rs1,cmd_rs2);
  if(gemmini.dut.load_controller.io_dma_req_valid && gemmini.dut.load_controller.io_dma_req_ready)
    $display("SPAD_DEBUG_ROW,idx=%0d,c=%0d,p=%0d,addr=%h,spad=%0d",gemmini.dut.load_controller.io_dma_req_bits_row_index,gemmini.dut.load_controller.io_dma_req_bits_cols,gemmini.dut.load_controller.io_dma_req_bits_pixel_repeats,gemmini.dut.load_controller.io_dma_req_bits_vaddr,gemmini.dut.load_controller.io_dma_req_bits_laddr_data);
  if(gemmini.dut.load_controller.io_dma_resp_valid)
    $display("SPAD_DEBUG_RESP,id=%0d,bytes=%0d",gemmini.dut.load_controller.io_dma_resp_bits_cmd_id,gemmini.dut.load_controller.io_dma_resp_bits_bytesRead);
  if(cycles%1000==0)$display("SPAD_DEBUG_STALL,cycles=%0d,rs=%0d,ldstate=%0d,row=%0d,ledger=%0d,reads=%0d,writes=%0d",cycles,gemmini.dut.reservation_station.cycles_since_issue,gemmini.dut.load_controller.control_state,gemmini.dut.load_controller.row_counter,gemmini.dut.spad.legacyBytes,reads,writes);
  if(cycles%1000==0)$display("SPAD_DEBUG_VSM,reader=%b/%b,vsm_in=%b/%b,vsm_out=%b/%b,pixel=%b/%b,head=%b,tail=%b",gemmini.dut.spad.reader.io_resp_valid,gemmini.dut.spad.reader.io_resp_ready,gemmini.dut.spad.vsm.io_req_valid,gemmini.dut.spad.vsm.io_req_ready,gemmini.dut.spad.vsm.io_resp_valid,gemmini.dut.spad.vsm.io_resp_ready,gemmini.dut.spad.mvin_scale_pixel_repeater.io_resp_valid,gemmini.dut.spad.mvin_scale_pixel_repeater.io_resp_ready,gemmini.dut.spad.vsm.head_oh,gemmini.dut.spad.vsm.tail_oh);
end
'''
    (feature/'ConvWorkload.svh').write_text(code)

    if args.matrix:
        # Delay the transactions covering the final input bytes of C=3/N=32
        # and C=12/N=32. This changes only the test memory endpoint.
        lane_path=feature/'reference/MemoryLane.sv'
        lane=lane_path.read_text().replace('response_delay<=7+ID*3;',
            "response_delay<=(a_source!=31 && ((a_address-BASE)=='h1080 || (a_address-BASE)=='h1180))?200:7+ID*3;")
        lane_path.write_text(lane)
        monitor=r"""
integer stream_received=0,stream_group=0,stream_early_rows=0,stream_early_writes=0;
integer stream_previous_writes=0;reg stream_active=0;
always @(posedge clock)if(!reset)begin
  if(gemmini.dut.spad.group.io_in_valid && gemmini.dut.spad.group.io_in_ready &&
     gemmini.dut.spad.group.io_in_bits_cmd_first && !gemmini.dut.spad.group.io_in_bits_all_zeros)begin
    stream_received=0;stream_early_rows=0;stream_early_writes=0;stream_active=1;
  end
  if(stream_active && gemmini.dut.spad.group.io_replay_valid && gemmini.dut.spad.group.io_replay_ready &&
     !gemmini.dut.spad.group.io_replay_bits_group_zeros && stream_received<input_rows*channels)
    stream_early_rows=stream_early_rows+1;
  if(stream_active && stream_received<input_rows*channels &&
     gemmini.dut.spad.io_counter_external_values_22!=stream_previous_writes)
    stream_early_writes=stream_early_writes+gemmini.dut.spad.io_counter_external_values_22-stream_previous_writes;
  stream_previous_writes=gemmini.dut.spad.io_counter_external_values_22;
  if(stream_active && gemmini.dut.spad.group.io_fragment_valid)
    stream_received=stream_received+gemmini.dut.spad.group.io_fragment_bits_bytes;
end
"""
        code+=monitor
        code=code.replace('  command_count=0;reads=0;writes=0;acks=0;fetches=0;',
            '  command_count=0;reads=0;writes=0;acks=0;fetches=0;stream_active=0;')
        anchor_check='  $display("DMA_SPAD_PASS,'
        check=r"""  if(dma_load_mode!=0 && (parameter_case==0 || parameter_case==3))begin
    if(stream_early_rows==0 || stream_early_writes==0)$fatal(1,"Streaming did not write before final input return");
    $display("DMA_STREAMING_SPAD_PASS,lane=%0d,mode=%0d,case=%0d,early_rows=%0d,early_sram_writes=%0d",ID,dma_load_mode,parameter_case,stream_early_rows,stream_early_writes);
  end
"""
        streaming=json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text()).get('dma_load_streaming_enable',False)
        if not streaming:
            check=check.replace('stream_early_rows==0 || stream_early_writes==0','stream_early_rows!=0 || stream_early_writes!=0').replace('Streaming did not write before final input return','Buffered control replayed before all returns')
        code=code.replace(anchor_check,check+anchor_check)
        (feature/'ConvWorkload.svh').write_text(code)

    runner=(Path('/mnt/data/wzr/13p/ov7670/sixteen_camera/hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/tests/merged_dma')/'test_real_gemmini.py').read_text()
    runner=runner.replace('feature = Path(__file__).resolve().parent',f'feature = Path({str(feature)!r})')
    runner=runner.replace('project = feature.parents[1]',f'project = Path({str(ROOT)!r})')
    body=r'''
  initial begin
    repeat(20)@(negedge clock);reset=0;repeat(64)@(negedge clock);
    for(runtime_mode=0;runtime_mode<3;runtime_mode=runtime_mode+1)begin
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)ctl(lane_id,9,64'(runtime_mode),0);
      lanes[0].lane.initialize_raw();lanes[1].lane.initialize_raw();lanes[2].lane.initialize_raw();
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
        ctl(lane_id,0,64'h80008000+lane_id*65536,lanes[0].lane.command_count);
        ctl(lane_id,1,64'h80000000+lane_id*65536,1000000);
      end
      ctl(3,7,7,7);wait(&dut.complete);@(negedge clock);
      lanes[0].lane.check_raw();lanes[1].lane.check_raw();lanes[2].lane.check_raw();
      ctl(0,5,0,0);ctl(1,5,0,0);ctl(2,5,0,0);
    end
    $display("REAL_CLUSTER_PASS,DMA_SPAD=1,modes=3,lanes=3");$finish;
  end
  initial begin #20000000;$fatal(1,"DMA SPAD timeout");end
endmodule
'''
    if args.matrix:
        body=body.replace('      lanes[0].lane.initialize_raw();',
            '      for(integer parameter_case=0;parameter_case<6;parameter_case=parameter_case+1)begin\n'
            '      lanes[0].lane.select_parameters(parameter_case);lanes[1].lane.select_parameters(parameter_case);lanes[2].lane.select_parameters(parameter_case);\n'
            '      lanes[0].lane.initialize_raw();')
        body=body.replace('ctl(0,5,0,0);ctl(1,5,0,0);ctl(2,5,0,0);',
            'ctl(0,5,0,0);ctl(1,5,0,0);ctl(2,5,0,0);\n      end')
        if args.case is not None:
            body=body.replace('integer parameter_case=0;parameter_case<6;',f'integer parameter_case={args.case};parameter_case<{args.case+1};')
            cases=1
    mode_count=len(json.loads((args.rtl.resolve().parent/'GENERATION_CONTEXT.json').read_text())['dma_load_supported_modes'])
    body=body.replace('runtime_mode=0;runtime_mode<3', 'runtime_mode=2;runtime_mode<3').replace('modes=3',f'modes={mode_count}')
    body=body.replace('    for(runtime_mode=2;', '    for(integer profile=0;profile<4;profile=profile+1)begin\n      lanes[0].lane.storage_profile=profile;lanes[1].lane.storage_profile=profile;lanes[2].lane.storage_profile=profile;\n    for(runtime_mode=2;')
    body=body.replace('    $display("REAL_CLUSTER_PASS,DMA_SPAD', '    end\n    $display("REAL_CLUSTER_PASS,DMA_SPAD')
    anchor='(out/"tb_real_cluster.sv").write_text(tb)'
    assert runner.count(anchor)==1
    runner=runner.replace(anchor,'tb=tb[:tb.index("  initial begin")]+ '+repr(body)+'\n'+anchor)
    (out/'run.py').write_text(runner)
    subprocess.run([sys.executable,str(out/'run.py'),'--rtl',str(args.rtl.resolve()),
                    '--output',str(out),'--dma-load-mode','all'],check=True)


if __name__=='__main__':main()
