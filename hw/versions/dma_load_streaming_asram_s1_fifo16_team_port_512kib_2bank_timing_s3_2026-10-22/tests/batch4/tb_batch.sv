`timescale 1ns/1ps
module tb_batch;
  reg clock=0; always #5 clock=~clock;
  reg reset=1,start=0,resume=0,acknowledge=0;
  reg [31:0] table_base=32'h80000000,table_count=0,frame_base=32'h80000000,timeout_cycles=0;
  reg [63:0] resume_tag=77;
  wire start_ready,owns_gemmini,fence_busy,done,host_wait,fault;
  wire [7:0] error_code; wire [31:0] fetched,issued,cursor,completed_cursor,fifo_level;
  wire [63:0] host_tag; wire [3:0] state_out;
  wire mem_req_valid,mem_req_ready,mem_resp_valid,mem_resp_ready,mem_resp_error,mem_resp_last;
  wire [31:0] mem_req_address; wire [2:0] mem_req_size; wire [255:0] mem_resp_data;
  wire cmd_valid; reg cmd_ready=0;wire [6:0] cmd_funct; wire [63:0] cmd_rs1,cmd_rs2;
  integer busy_left=0;wire gemmini_busy=busy_left!=0;reg gemmini_fault=0;
  BatchEngine engine(.*);
  wire f_req_valid=mem_req_valid,f_req_ready; wire [31:0] f_req_address=mem_req_address;
  wire [2:0] f_req_size=mem_req_size;
  wire f_resp_valid,f_resp_error,f_resp_last;wire f_resp_ready=mem_resp_ready;wire [255:0] f_resp_data;
  assign mem_req_ready=f_req_ready;assign mem_resp_valid=f_resp_valid;
  assign mem_resp_error=f_resp_error;assign mem_resp_last=f_resp_last;assign mem_resp_data=f_resp_data;
  reg g_a_valid=0;wire g_a_ready;reg [2:0] g_a_opcode=4,g_a_param=0;reg [3:0] g_a_size=5;
  reg [5:0] g_a_source=0;reg [32:0] g_a_address=33'h180001000;
  reg [31:0] g_a_mask='1;reg [255:0] g_a_data=0;reg g_a_corrupt=0;
  wire g_d_valid;reg g_d_ready=1;wire [2:0] g_d_opcode;wire [1:0] g_d_param;
  wire [3:0] g_d_size;wire [5:0] g_d_source;wire [6:0] g_d_sink;
  wire g_d_denied,g_d_corrupt;wire [255:0] g_d_data;
  wire a_valid,a_ready;wire [2:0] a_opcode,a_param;wire [3:0] a_size;wire [5:0] a_source;
  wire [32:0] a_address;wire [31:0] a_mask;wire [255:0] a_data;wire a_corrupt;
  reg d_valid=0;wire d_ready;reg [2:0] d_opcode=1;reg [1:0] d_param=0;
  reg [3:0] d_size=0;reg [5:0] d_source=0;reg [6:0] d_sink=7'h65;
  reg d_denied=0,d_corrupt=0;reg [255:0] d_data=0;
  BatchMemory memory(.*);
  integer cycle=0,delay_left=0,beats_left=0,record_idx=0,received=0,expected=0;
  integer requests=0,physical=0,batch4=0,peak=0,all_peak=0,cases=0;
  integer error_at=-1,error_kind=0,format_at=-1,case_start=0,hold_cycles=0;
  bit private_stream=0;
  integer drain_at=3,host_at=6,host_prefetch_cases=0;
  bit barriers=0,dma_enable=0,packet_frontend=0,wait_stall=0;
  integer dma_sent=0,dma_received=0;
  reg dma_accepted=0;
  reg [5:0] pending_source=0;reg [3:0] pending_size=0;
  reg [255:0] stalled_command;reg stalled_cmd=0,stalled_req=0,stalled_a=0;
  reg [34:0] old_req;reg [48:0] old_a;
  function automatic [6:0] expected_funct(input integer i);
    if(!private_stream || i%4<2)expected_funct=0;
    else expected_funct=(i%4==2)?7'd2:7'd14;
  endfunction
  function automatic [63:0] expected_rs1(input integer i);
    if(!private_stream)expected_rs1=64'(i);
    else case(i%4)
      0:expected_rs1=64'h00003c0000200101;
      1:expected_rs1=64'h0000380000000085 | (64'(i%3)<<3);
      default:expected_rs1=64'h000000002000100f+64'(i*32);
    endcase
  endfunction
  function automatic [63:0] expected_rs2(input integer i);
    if(!private_stream)expected_rs2=64'h1234567890000000+64'(i);
    else if(i%4==1)expected_rs2=64'hfffffffffffff123;
    else if(i%4==0)expected_rs2=16;
    else expected_rs2=64'h0020002000000040+64'(i);
  endfunction
  function automatic [255:0] record(input integer i);
    if(i==format_at)record=256'hff;
    else if(barriers && i==drain_at)record=256'd1;
    else if(barriers && i==host_at)record={64'd0,64'd0,64'd77,64'd2};
    else record={64'd0,expected_rs2(i),expected_rs1(i),49'd0,expected_funct(i),8'd0};
  endfunction
  assign a_ready=!reset && !d_valid && beats_left==0 && delay_left==0 && cycle%5!=0;
  task tick; @(posedge clock); #1; @(negedge clock); endtask
  always @(negedge clock) if(!reset)begin
    cmd_ready=(cycle-case_start>=hold_cycles) && cycle%7!=0;
    g_d_ready=cycle%4!=0;
    if(dma_accepted)g_a_valid=0;
    if(!g_a_valid && dma_enable && cycle%7==2)begin
      g_a_valid=1;g_a_source=6'(dma_sent%64);g_a_address=33'h180001000+33'(dma_sent*32);
    end
  end
  always @(posedge clock)begin
    cycle<=cycle+1;
    if(reset)begin
      busy_left<=0;d_valid<=0;delay_left=0;beats_left=0;dma_accepted<=0;
      stalled_cmd<=0;stalled_req<=0;stalled_a<=0;
    end else begin
      if(stalled_cmd && (!cmd_valid || {57'd0,cmd_funct,cmd_rs1,cmd_rs2}!==stalled_command))
        $fatal(1,"command changed under backpressure");
      if(stalled_req && (!mem_req_valid || {mem_req_size,mem_req_address}!==old_req))
        $fatal(1,"fetch changed under backpressure");
      if(stalled_a && (!a_valid || {a_opcode,a_size,a_source,a_address}!==old_a))
        $fatal(1,"TL A changed under backpressure");
      stalled_cmd<=cmd_valid&&!cmd_ready;stalled_command<={57'd0,cmd_funct,cmd_rs1,cmd_rs2};
      stalled_req<=mem_req_valid&&!mem_req_ready;old_req<={mem_req_size,mem_req_address};
      stalled_a<=a_valid&&!a_ready;old_a<={a_opcode,a_size,a_source,a_address};
      if(fifo_level>peak)peak=fifo_level;
      if(fifo_level>all_peak)all_peak=fifo_level;
      if(busy_left>0)busy_left<=busy_left-1;
      if(cmd_valid&&cmd_ready)begin
        while(barriers && (expected==drain_at || expected==host_at))expected=expected+1;
        if(cmd_funct!==expected_funct(expected) || cmd_rs1!==expected_rs1(expected) || cmd_rs2!==expected_rs2(expected))
          $fatal(1,"command order mismatch case%0d expected%0d actual%0d",cases,expected,cmd_rs1);
        if(expected>=table_count)$fatal(1,"extra command");
        expected=expected+1;received=received+1;busy_left<=9;
      end
      if(mem_req_valid&&mem_req_ready)begin
        requests=requests+1;if(mem_req_size==7)batch4=batch4+1;
        if({32'd0,mem_req_address}+(64'd1<<mem_req_size)>{32'd0,table_base}+table_count*64'd32)
          $fatal(1,"logical table overread");
      end
      dma_accepted<=g_a_valid&&g_a_ready;
      if(g_a_valid&&g_a_ready)dma_sent=dma_sent+1;
      if(g_d_valid&&g_d_ready)begin
        if(g_d_source!==6'(dma_received%64) || g_d_sink!==7'h65 || g_d_data!==256'hdeadcafe)
          $fatal(1,"DMA response misroute");
        dma_received=dma_received+1;
      end
      if(a_valid&&a_ready)begin
        packet_frontend=!g_a_ready;
        if(a_opcode!=4 || a_size>6)$fatal(1,"illegal physical fetch opcode/size");
        pending_source=a_source;pending_size=a_size;
        if(packet_frontend)begin
          if(a_address<{1'b0,table_base} || {31'd0,a_address}+(64'd1<<a_size)>{32'd0,table_base}+table_count*64'd32)
            $fatal(1,"physical table overread");
          if(a_source!=31 || (a_address & ((33'd1<<a_size)-1))!=0)$fatal(1,"fetch alignment/ID");
          record_idx=32'(a_address-{1'b0,table_base})/32;physical=physical+1;
        end else if(a_address[32]!==1 || a_source!==g_a_source)$fatal(1,"DMA width truncated");
        beats_left=(a_size>5)?(1<<(a_size-5)):1;
        delay_left=3+cycle%5;
      end
      if(delay_left>0)begin
        delay_left=delay_left-1;
        if(delay_left==0)begin
          d_valid<=1;d_source<=pending_source;d_size<=pending_size;d_opcode<=1;
          d_data<=packet_frontend?record(record_idx):256'hdeadcafe;
          d_denied<=packet_frontend && record_idx==error_at && error_kind==1;
          d_corrupt<=packet_frontend && record_idx==error_at && error_kind==2;
          if(packet_frontend && record_idx==error_at && error_kind==3)begin d_opcode<=0;beats_left=1;end
          if(packet_frontend && record_idx==error_at && error_kind==4)begin d_size<=5;beats_left=1;end
        end
      end
      if(d_valid&&d_ready)begin
        d_valid<=0;beats_left=beats_left-1;
        if(beats_left>0)begin record_idx=record_idx+1;delay_left=2+cycle%3;end
      end
    end
  end
  task run_case(input [31:0] addr,input integer n,input bit with_barriers,input integer err,input integer ek,
                input integer bad,input integer deadline,input integer stall,input bit dma);
    reset=1;start=0;resume=0;g_a_valid=0;dma_enable=0;tick();tick();
    table_base=addr;table_count=n;barriers=with_barriers;error_at=err;error_kind=ek;format_at=bad;
    timeout_cycles=deadline;hold_cycles=stall;case_start=cycle;expected=0;received=0;
    requests=0;physical=0;batch4=0;peak=0;dma_sent=0;dma_received=0;cases=cases+1;
    reset=0;dma_enable=dma;start=1;tick();start=0;
    begin: observe
      for(integer t=0;t<30000;t=t+1)begin
        tick();
        if(host_wait)begin
          if(host_tag!=77 || received!=host_at-1 || gemmini_busy)$fatal(1,"HOST boundary violated");
          repeat(12)begin tick();if(received!=host_at-1)$fatal(1,"execution past HOST");end
          if(private_stream && fetched>host_at+1)host_prefetch_cases=host_prefetch_cases+1;
          resume=1;tick();resume=0;
        end
        if(state_out==6 || done)disable observe;
      end
      $fatal(1,"case timeout n%0d state%0d fetch%0d cursor%0d",n,state_out,fetched,cursor);
    end
    dma_enable=0;
    if(err>=0 || bad>=0 || deadline>0)begin
      if(state_out!=6 || !fault || error_code!=(err>=0?2:bad>=0?3:4))$fatal(1,"expected fault missing");
      if(mem_req_valid || owns_gemmini || busy_left || memory.native_dut.batchActive)
        $fatal(1,"premature fault retirement");
    end else begin
      if(!done || fault || fetched!=n || cursor!=n || completed_cursor!=n ||
         issued!=n-(with_barriers?2:0) || received!=issued || gemmini_busy)
        $fatal(1,"bad completion counts n%0d fetched%0d issued%0d received%0d",n,fetched,issued,received);
      if(addr[6:0]==0 && n>=4 && batch4==0)$fatal(1,"batch4 not used");
      if(addr[6:0]==0 && n==116 && requests!=29)$fatal(1,"not 29 batches for 116 records");
    end
    while(d_valid || beats_left || g_a_valid || dma_received!=dma_sent)tick();
    acknowledge=1;tick();acknowledge=0;tick();
    if(!start_ready)$fatal(1,"channel did not recover");
  endtask
  initial begin
    for(integer offset=0;offset<4;offset=offset+1)
      for(integer n=1;n<=35;n=n+1)run_case(32'h80000000+32'(offset*32),n,0,-1,0,-1,0,400,1);
    run_case(32'h80000000,115,1,-1,0,-1,0,0,1);
    run_case(32'h80000000,116,1,-1,0,-1,0,0,1);
    run_case(32'hfffffe00,16,0,-1,0,-1,0,400,0);
    for(integer e=0;e<4;e=e+1)begin
      run_case(32'h80000000,20,0,e,1,-1,0,100,1);
      run_case(32'h80000000,20,0,e,2,-1,0,100,1);
    end
    run_case(32'h80000000,20,0,0,3,-1,0,100,1);
    run_case(32'h80000000,20,0,2,4,-1,0,100,1);
    run_case(32'h80000000,20,0,-1,0,2,0,0,1);
    run_case(32'h80000000,20,0,-1,0,-1,7,0,1);
    private_stream=1;
    for(integer boundary=1;boundary<=4;boundary=boundary+1)begin
      drain_at=boundary;host_at=boundary+4;
      run_case(32'h80000000,40,1,-1,0,-1,0,400,1);
      run_case(32'h80000020,41,1,-1,0,-1,0,0,1);
    end
    if(host_prefetch_cases!=8)$fatal(1,"HOST prefetch not exercised for all private streams");
    if(all_peak<15)$fatal(1,"FIFO16 capacity never exercised");
    $display("BATCH4_PASS,cases=%0d,fifo=16,peak=%0d,batch=4,physical_max_bytes=64,alignment_tail=1,host_drain=1,errors=1,timeout_drain=1,dma_contention=1,order=correct,private_raw=1,host_prefetch=1,barrier_batch_positions=4",cases,all_peak);
    $finish;
  end
  initial begin #200000000;$fatal(1,"global timeout");end
endmodule
