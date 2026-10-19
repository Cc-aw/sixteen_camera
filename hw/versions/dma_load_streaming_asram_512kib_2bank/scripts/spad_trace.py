#!/usr/bin/env python3
"""Simulation-only probes for a known-state, real SPAD execution trace (lane 0)."""

def probe():
    p='gemmini.dut.spad'
    text=r'''
integer trace_fd=0,trace_seq=0,trace_cmd=0,trace_request=1000000,trace_epoch=0,trace_start_writes=0;
integer trace_owner[0:255];integer trace_credit[0:255];integer trace_rob_owner[0:255];
reg trace_on=0;
task trace_event(input string event_name,input integer bank,row,input [31:0] mask,
                 input [255:0] data,input integer owner,aux);
  $fdisplay(trace_fd,"%0d,%0d,%s,%0d,%0d,%0d,%0d,%0d,%h,%h,%0d,%0d",
    trace_seq,cycles,event_name,trace_epoch,dma_load_mode,layer_case,bank,row,mask,data,owner,aux);
  trace_seq=trace_seq+1;
endtask
initial if(ID==0)begin
  trace_fd=$fopen("spad_events_lane0.csv","w");
  for(integer i=0;i<256;i=i+1)begin trace_owner[i]=-1;trace_credit[i]=0;end
  #1;
'''
    for bank in range(8):
        for byte in range(32):
            text+=f"  for(integer r=0;r<2048;r=r+1){p}.spad_mems_{bank}.mem.mem_ext.mem_0_{byte}.ram[r]=8'ha5;\n"
    text+='end\ntask trace_begin;\n  if(ID==0 && dma_load_mode==2)begin\n    trace_on=1;trace_epoch=layer_case;\n'
    text+=f'    trace_start_writes={p}.io_counter_external_values_22;\n'
    text+='    if(layer_case==0)begin\n      trace_event("BEGIN",-1,0,0,0,0,0);\n'
    for bank in range(8):
        data='{'+','.join(f'{p}.spad_mems_{bank}.mem.mem_ext.mem_0_{byte}.ram[r]' for byte in reversed(range(32)))+'}'
        text+=f'      for(integer r=0;r<2048;r=r+1)trace_event("SNAPSHOT",{bank},r,32\'hffffffff,{data},0,0);\n'
    text+='    end\n  end\nendtask\ntask trace_end;\n  if(trace_on)begin\n'
    text+=f'    trace_event("BOUNDARY",-1,0,0,0,0,{p}.io_counter_external_values_22-trace_start_writes);\n'
    text+='    if(layer_case==7)begin trace_event("END",-1,0,0,0,0,0);$fclose(trace_fd);end\n    trace_on=0;\n  end\nendtask\n'
    # Complete command lifetime is separate from physical bank queue ownership.
    r='gemmini.dut.load_controller.io_dma_req'
    c='gemmini.dut.load_controller.io_dma_resp'
    text+=f'''always @(posedge clock)if(!reset && trace_on)begin
  if(gemmini.dut.load_controller.io_completed_valid && gemmini.dut.load_controller.io_completed_ready)
    trace_event("CMD_COMPLETE",-1,0,0,0,trace_rob_owner[gemmini.dut.load_controller.io_completed_bits],gemmini.dut.load_controller.io_completed_bits);
  if({c}_valid)begin
    trace_event("LOAD_CREDIT",-1,0,0,0,trace_owner[{c}_bits_cmd_id],{c}_bits_bytesRead);
    trace_credit[{c}_bits_cmd_id]=trace_credit[{c}_bits_cmd_id]-{c}_bits_bytesRead;
    if(trace_credit[{c}_bits_cmd_id]<0)$fatal(1,"trace credit underflow");
  end
  if({r}_valid && {r}_ready && {r}_bits_cmd_first)begin
    if(trace_credit[{r}_bits_cmd_id]!=0)$fatal(1,"trace command ID reused before credit");
    trace_cmd=trace_cmd+1;trace_owner[{r}_bits_cmd_id]=trace_cmd;
    trace_rob_owner[gemmini.dut.load_controller._cmd_q_io_deq_bits_rob_id_bits]=trace_cmd;
    trace_credit[{r}_bits_cmd_id]={r}_bits_cols*{r}_bits_cmd_rows*({r}_bits_has_acc_bitwidth?4:1);
    trace_event("LOAD_ACCEPT",-1,{r}_bits_laddr_data,0,
      {{16'(gemmini.dut.load_controller._cmd_q_io_deq_bits_rob_id_bits),{r}_bits_vaddr,32'({r}_bits_laddr_data),{r}_bits_cols,6'({r}_bits_cmd_rows),
        {r}_bits_pixel_repeats,{r}_bits_cmd_stride_bytes,{r}_bits_scale}},trace_cmd,trace_credit[{r}_bits_cmd_id]);
  end

end
'''
    for bank in range(8):
        q=p+('.pending' if bank==0 else f'.pending_{bank}')
        b=p+f'.spad_mems_{bank}'
        ex=p+('.ex_read_skid' if bank==0 else f'.ex_read_skid_{bank}')
        dma=p+('.dmawrite' if bank==0 else f'.dmawrite_{bank}')
        emask='{'+','.join(f'{q}.io_enq_bits_mask_{j}' for j in reversed(range(32)))+'}'
        dmask='{'+','.join(f'{q}.io_deq_bits_mask_{j}' for j in reversed(range(32)))+'}'
        text+=f'''
integer tq_cmd_{bank}[0:15];integer tq_rd_{bank}=0,tq_wr_{bank}=0;
integer tr_ids_{bank}[0:255];integer tr_rd_{bank}=0,tr_wr_{bank}=0;
integer ex_id_{bank}=0,dma_id_{bank}=0;reg ex_live_{bank}=0,dma_live_{bank}=0;
always @(posedge clock)if(!reset && trace_on)begin
  if({ex}.io_deq_valid && !ex_live_{bank})begin
    trace_request=trace_request+1;ex_id_{bank}=trace_request;ex_live_{bank}=1;
    trace_event("READ_INTENT",{bank},{ex}.io_deq_bits_addr,0,0,ex_id_{bank},0);
  end
  if({dma} && !dma_live_{bank})begin
    trace_request=trace_request+1;dma_id_{bank}=trace_request;dma_live_{bank}=1;
    trace_event("READ_INTENT",{bank},{p}._write_dispatch_q_q_io_deq_bits_laddr_data[10:0],0,0,dma_id_{bank},1);
  end
  // The SPAD bank write READY is elaborated constant true in this candidate.
  if({q}.io_deq_valid)begin
    trace_event("BANK_COMMIT",{bank},{q}.io_deq_bits_addr,{dmask},{q}.io_deq_bits_data,
      tq_cmd_{bank}[tq_rd_{bank}%16],{q}.io_deq_bits_ex?1:({q}.io_deq_bits_zero?2:0));
    tq_rd_{bank}=tq_rd_{bank}+1;
  end
  if({b}.io_read_req_valid && {b}.io_read_req_ready)begin
    tr_ids_{bank}[tr_wr_{bank}%256]={b}.io_read_req_bits_fromDMA?dma_id_{bank}:ex_id_{bank};
    trace_event("READ_ACCEPT",{bank},{b}.io_read_req_bits_addr,32'hffffffff,0,tr_ids_{bank}[tr_wr_{bank}%256],0);
    tr_wr_{bank}=tr_wr_{bank}+1;
    if({b}.io_read_req_bits_fromDMA)dma_live_{bank}=0;else ex_live_{bank}=0;
  end
  if({b}.io_read_resp_valid && {b}.io_read_resp_ready)begin
    trace_event("READ_DATA",{bank},0,32'hffffffff,{b}.io_read_resp_bits_data,tr_ids_{bank}[tr_rd_{bank}%256],0);
    tr_rd_{bank}=tr_rd_{bank}+1;
  end
  if({q}.io_enq_valid && !{q}.io_enq_bits_ex && !{q}.io_enq_bits_zero)
    trace_event("DMA_CANDIDATE",{bank},{q}.io_enq_bits_addr,{emask},{q}.io_enq_bits_data,
      trace_owner[{p}._mvinWriteBuffer_io_deq_bits_tag_cmd_id],{q}.io_enq_ready);
  if({q}.io_enq_valid && {q}.io_enq_ready)begin
    tq_cmd_{bank}[tq_wr_{bank}%16]=({q}.io_enq_bits_ex || {q}.io_enq_bits_zero)?-1:
      trace_owner[{p}._mvinWriteBuffer_io_deq_bits_tag_cmd_id];
    trace_event("BANK_ACCEPT",{bank},{q}.io_enq_bits_addr,{emask},{q}.io_enq_bits_data,
      tq_cmd_{bank}[tq_wr_{bank}%16],{q}.io_enq_bits_ex?1:({q}.io_enq_bits_zero?2:0));
    tq_wr_{bank}=tq_wr_{bank}+1;
  end
end
'''
    return text
