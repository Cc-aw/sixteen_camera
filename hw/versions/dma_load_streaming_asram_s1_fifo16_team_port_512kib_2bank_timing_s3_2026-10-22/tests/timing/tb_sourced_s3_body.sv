// Production SourceD and production BankedStore; byte-level external oracle.
always #5 clock = ~clock;
reg [511:0] memory_model [0:31];
reg [255:0] put_data [0:63][0:1], release_data [0:63][0:1];
reg [31:0] put_mask [0:63][0:1];
integer put_beat [0:63], release_beat [0:63];
integer ex_source [0:4095], ex_opcode [0:4095], ex_size [0:4095];
integer ex_sink [0:4095], ex_param [0:4095], ex_denied [0:4095], ex_last [0:4095];
reg [255:0] ex_data [0:4095], ex_mask [0:4095];
integer queued=0, checked=0, accepted=0, cyc=0, errors=0;
integer rd_stalls=0, wr_stalls=0, pb_stalls=0, rel_stalls=0, d_stalls=0;
integer hazard_checks=0, skid_checks=0, skid_distinct=0, run_length=0, longest_run=0;
integer unfinished [0:31];
reg active=0, perf_phase=0;

assign io_pb_beat_data=put_data[io_pb_pop_bits_index][put_beat[io_pb_pop_bits_index]];
assign io_pb_beat_mask=put_mask[io_pb_pop_bits_index][put_beat[io_pb_pop_bits_index]];
assign io_rel_beat_data=release_data[io_rel_pop_bits_index][release_beat[io_rel_pop_bits_index]];

always @(posedge clock) if(!reset) begin
  cyc=cyc+1;
  if(io_req_valid && io_req_ready) begin
    accepted=accepted+1;
    if(perf_phase) begin
      run_length=run_length+1;
      if(run_length>longest_run) longest_run=run_length;
    end
  end else run_length=0;
  if(io_pb_pop_valid && !io_pb_pop_ready) pb_stalls=pb_stalls+1;
  if(io_rel_pop_valid && !io_rel_pop_ready) rel_stalls=rel_stalls+1;
  if(io_d_valid && !io_d_ready) d_stalls=d_stalls+1;
  if(io_bs_radr_valid && !io_bs_radr_ready) rd_stalls=rd_stalls+1;
  if(io_bs_wadr_valid && !io_bs_wadr_ready) wr_stalls=wr_stalls+1;
  if(io_pb_pop_valid && io_pb_pop_ready)
    put_beat[io_pb_pop_bits_index]=io_pb_pop_bits_last?0:1;
  if(io_rel_pop_valid && io_rel_pop_ready)
    release_beat[io_rel_pop_bits_index]=io_rel_pop_bits_last?0:1;
  if(io_d_valid && io_d_ready) begin
    if(checked>=queued) $fatal(1,"unexpected or duplicate D");
    if(io_d_bits_source!==10'(ex_source[checked]) ||
       io_d_bits_sink!==6'(ex_sink[checked]) ||
       io_d_bits_opcode!==3'(ex_opcode[checked]) ||
       io_d_bits_param!==2'(ex_param[checked]) ||
       io_d_bits_size!==3'(ex_size[checked]) ||
       io_d_bits_denied!==1'(ex_denied[checked]) ||
       io_d_bits_corrupt!==1'(ex_denied[checked] && (ex_opcode[checked]&1)))
      $fatal(1,"D metadata mismatch reply=%0d src=%0d expected=%0d op=%0d expectedop=%0d",checked,io_d_bits_source,ex_source[checked],io_d_bits_opcode,ex_opcode[checked]);
    if((io_d_bits_data & ex_mask[checked]) !== (ex_data[checked] & ex_mask[checked]))
      $fatal(1,"D data mismatch reply=%0d src=%0d got=%h expected=%h mask=%h",checked,io_d_bits_source,io_d_bits_data,ex_data[checked],ex_mask[checked]);
    checked=checked+1;
  end
end

// Periodic independent stalls, including full downstream blockage. No SRAM
// writes are forged: noop reservations only test genuine bank arbitration.
always @(negedge clock) if(active) begin
  io_d_ready=perf_phase || cyc%29>=11;
  io_pb_pop_ready=perf_phase || cyc%13>=4;
  io_rel_pop_ready=perf_phase || cyc%17>=5;
  io_sinkC_adr_valid=!perf_phase && cyc%23<5;
  io_sinkC_adr_bits_set=io_bs_radr_valid?io_bs_radr_bits_set:io_bs_wadr_bits_set;
  io_sinkC_adr_bits_way=io_bs_radr_valid?io_bs_radr_bits_way:io_bs_wadr_bits_way;
  io_sinkC_adr_bits_beat=io_bs_radr_valid?io_bs_radr_bits_beat:io_bs_wadr_bits_beat;
  io_sourceC_adr_valid=!perf_phase && cyc%31<7;
  io_sourceC_adr_bits_set=io_bs_wadr_bits_set;
  io_sourceC_adr_bits_way=io_bs_wadr_bits_way;
  if(dut.pending_valid) begin
    io_evict_req_set=dut.pending_req_set;
    io_evict_req_way=dut.pending_req_way;
    io_grant_req_set=dut.pending_req_set;
    io_grant_req_way=dut.pending_req_way;
    #1;
    if(io_evict_safe || io_grant_safe) $fatal(1,"skid request lost set/way reservation");
    skid_checks=skid_checks+1;
    if(dut.pending_req_set!=io_bs_radr_bits_set || dut.pending_req_way!=io_bs_radr_bits_way)
      skid_distinct=skid_distinct+1;
  end else if(dut.busy) begin
    io_evict_req_set=io_bs_radr_bits_set;
    io_evict_req_way=io_bs_radr_bits_way;
    io_grant_req_set=io_bs_radr_bits_set;
    io_grant_req_way=io_bs_radr_bits_way;
    #1;
    if(io_evict_safe || io_grant_safe) $fatal(1,"active head lost set/way reservation");
    hazard_checks=hazard_checks+1;
  end
end

task automatic tick; @(posedge clock); @(negedge clock); #2; endtask
task automatic drain;
  integer timeout;
  begin
    timeout=0;
    while(checked!=queued || dut.busy || dut.pending_valid || dut.s2_full || dut.s3_full || dut.s4_full) begin
      tick();timeout=timeout+1;
      if(timeout>3000) $fatal(1,"SourceD failed to drain checked=%0d queued=%0d",checked,queued);
    end
    repeat(5) tick();
  end
endtask

task automatic request(input integer n, input integer mode);
  integer op, param, size, offset, line, setno, wayno, prioa, bad;
  integer beats, beatno, lowbyte, highbyte, slot, ackop, ackparam, idx;
  reg [511:0] before_line, after_line, payload;
  reg [63:0] mask64;
  begin
    // Repeated same-line updates/readbacks require forwarding across s2-s4;
    // adjacent groups also exercise a pending reservation unlike the head.
    line=(n/14)%32;
    if(n>=560 && n<592) line=n-560;
    setno=line%16;wayno=line/16;
    op=4;param=0;size=6;offset=0;prioa=1;bad=0;
    case(mode)
      0: op=4;
      1: op=0;
      2: begin op=4;size=5;offset=32;end
      3: op=1;
      4: begin op=2;param=4;size=3;offset=(n%4)*8;end
      5: begin op=3;param=n%4;size=3;offset=(n%4)*8;end
      6: op=5;
      7: begin op=6;param=0;end
      8: begin op=6;param=2;end
      9: begin op=7;param=2;end
      10: begin op=7;prioa=0;end
      11: begin op=6;prioa=0;end
      12: begin op=4;size=3;offset=24;bad=(n%3==0);end
      13: begin op=0;size=3;offset=8;end
    endcase
    before_line=memory_model[line];after_line=before_line;
    for(integer b=0;b<64;b=b+1) payload[8*b+:8]=8'(n*13+b*7+19);
    mask64=0;
    for(integer b=0;b<64;b=b+1)
      if(b>=offset && b<offset+(1<<size) && (op!=1 || (b+n)%3!=0)) mask64[b]=1;
    if(op==2) begin
      after_line[offset*8+:64]=before_line[offset*8+:64]+payload[offset*8+:64];
    end else if(op==3) begin
      case(param)
        0: after_line[offset*8+:64]=before_line[offset*8+:64]^payload[offset*8+:64];
        1: after_line[offset*8+:64]=before_line[offset*8+:64]|payload[offset*8+:64];
        2: after_line[offset*8+:64]=before_line[offset*8+:64]&payload[offset*8+:64];
        3: after_line[offset*8+:64]=payload[offset*8+:64];
      endcase
    end else if((prioa && op<2) || (!prioa && op==7)) begin
      for(integer b=0;b<64;b=b+1) if(mask64[b]) after_line[b*8+:8]=payload[b*8+:8];
    end
    if(!bad) memory_model[line]=after_line;
    idx=n%64;
    for(integer b=0;b<2;b=b+1) begin
      put_data[idx][b]=payload[b*256+:256];release_data[idx][b]=payload[b*256+:256];
      put_mask[idx][b]=mask64[b*32+:32];
    end
    // Small transactions use the requested beat in the first put-buffer slot.
    if(size<6) begin
      put_data[idx][0]=payload[(offset/32)*256+:256];
      put_mask[idx][0]=mask64[(offset/32)*32+:32];
    end
    put_beat[idx]=0;release_beat[idx]=0;
    ackop=!prioa?6:(op<2?0:(op<5?1:(op==5?2:(op==6 && param!=2?5:4))));
    ackparam=(prioa && op>=6)?(param==0?1:0):0;
    beats=(ackop==1 || ackop==5)?(size==6?2:1):1;
    for(integer b=0;b<beats;b=b+1) begin
      slot=queued;queued=queued+1;
      ex_source[slot]=n;ex_sink[slot]=n%64;ex_opcode[slot]=ackop;
      ex_param[slot]=ackparam;ex_size[slot]=size;ex_denied[slot]=bad;
      beatno=(offset/32)+b;
      ex_data[slot]=before_line[beatno*256+:256];ex_mask[slot]=0;
      if((ackop==1 || ackop==5) && !bad)
        for(integer k=0;k<32;k=k+1)
          if(beatno*32+k>=offset && beatno*32+k<offset+(1<<size)) ex_mask[slot][k*8+:8]=255;
    end
    io_req_bits_prio_0=prioa;io_req_bits_prio_2=!prioa;
    io_req_bits_opcode=3'(op);io_req_bits_param=3'(param);io_req_bits_size=3'(size);
    io_req_bits_offset=6'(offset);io_req_bits_source=10'(n);io_req_bits_sink=6'(n%64);
    io_req_bits_set=9'(setno);io_req_bits_way=3'(wayno);io_req_bits_put=6'(idx);
    io_req_bits_bad=bad;io_req_valid=1;
    // Valid and payload stay stable across every stall.
    @(posedge clock);while(!io_req_ready) @(posedge clock);
    @(negedge clock);#2;io_req_valid=0;
  end
endtask

initial begin
  reset=1;
  for(integer n=0;n<64;n=n+1) begin put_beat[n]=0;release_beat[n]=0;end
  repeat(6) tick();reset=0;
  io_sinkC_adr_bits_noop=1;io_sinkC_adr_bits_mask=15;
  io_sourceC_adr_bits_noop=1;
  io_sinkD_adr_bits_noop=0;
  for(integer n=0;n<32;n=n+1) begin
    for(integer b=0;b<64;b=b+1) memory_model[n][8*b+:8]=8'(n*11+b*3);
    io_sinkD_adr_bits_way=3'(n/16);io_sinkD_adr_bits_set=9'(n%16);
    io_sinkD_dat_data=memory_model[n];io_sinkD_adr_valid=1;
    @(posedge clock);while(!io_sinkD_adr_ready) @(posedge clock);
    @(negedge clock);#2;io_sinkD_adr_valid=0;
  end
  active=1;
  for(integer n=0;n<560;n=n+1) request(n,n%14);
  drain();
  // Read every modified line again after all writebacks have retired.
  for(integer n=560;n<592;n=n+1) request(n,0);
  drain();
  perf_phase=1;
  for(integer n=592;n<656;n=n+1) request(n,6);
  drain();
  if(accepted!=656 || checked!=queued || rd_stalls==0 || wr_stalls==0 ||
     d_stalls==0 || pb_stalls==0 || rel_stalls==0 || skid_checks==0 || skid_distinct==0 || hazard_checks==0 || longest_run<32)
    $fatal(1,"missing SourceD coverage accepted=%0d rd=%0d wr=%0d pb=%0d rel=%0d d=%0d skid=%0d hazard=%0d run=%0d",accepted,rd_stalls,wr_stalls,pb_stalls,rel_stalls,d_stalls,skid_checks,hazard_checks,longest_run);
  $display("SOURCED_BANKEDSTORE_PASS requests=%0d replies=%0d rd_stall=%0d wr_stall=%0d pb_stall=%0d rel_stall=%0d d_stall=%0d skid_hazards=%0d head_hazards=%0d consecutive_accepts=%0d",accepted,checked,rd_stalls,wr_stalls,pb_stalls,rel_stalls,d_stalls,skid_checks,hazard_checks,longest_run);
  $finish;
end
initial begin #10000000;$fatal(1,"SourceD timeout");end
