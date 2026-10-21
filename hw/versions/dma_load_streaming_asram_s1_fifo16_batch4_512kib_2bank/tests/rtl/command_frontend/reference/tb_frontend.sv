`timescale 1ns/1ps
module tb_frontend;
  reg clock=0; always #5 clock=~clock;
  reg reset=1;
  reg control_valid=0, control_xd=1, response_ready=1;
  reg [6:0] control_funct=0;
  reg [63:0] control_rs1=0,control_rs2=0;
  reg [4:0] control_rd=7;
  reg [1:0] control_prv=3;
  wire control_ready,response_valid,interrupt,busy;
  wire [4:0] response_rd;
  wire [63:0] response_data;
  reg legacy_valid=0;
  wire legacy_ready,stream_owner,gemmini_cmd_valid;
  reg gemmini_cmd_ready=0;
  wire [6:0] gemmini_cmd_funct;
  wire [63:0] gemmini_cmd_rs1,gemmini_cmd_rs2;
  reg gemmini_busy=0,gemmini_fault=0;
  wire tl_a_valid,tl_d_ready;
  reg tl_a_ready=0,tl_d_valid=0,tl_d_denied=0,tl_d_corrupt=0;
  wire [31:0] tl_a_address;
  reg [255:0] tl_d_data=0;
  reg [255:0] table_mem[0:127];
  integer cycle=0,delay_count=0,busy_left=0,req_index=0,checked=0,expected_index=0;
  integer read_count=0,stall_cycles=0,max_fifo=0;
  reg enable_checks=0,block_commands=0,inject_denied=0;
  reg [63:0] cpu_work=0;
  reg held_a=0,held_cmd=0,held_resp=0;
  reg [31:0] prev_addr;
  reg [134:0] prev_cmd;
  reg [68:0] prev_resp;
  GemminiFrontendRoCC dut (
    .clock(clock),.reset(reset),.control_valid(control_valid),.control_ready(control_ready),
    .control_funct(control_funct),.control_rs1(control_rs1),.control_rs2(control_rs2),
    .control_rd(control_rd),.control_xd(control_xd),.control_prv(control_prv),
    .response_valid(response_valid),.response_ready(response_ready),.response_rd(response_rd),
    .response_data(response_data),.interrupt(interrupt),.busy(busy),
    .legacy_valid(legacy_valid),.legacy_ready(legacy_ready),.legacy_funct(7'd0),
    .legacy_rs1(64'd55),.legacy_rs2(64'd66),.stream_owner(stream_owner),
    .gemmini_cmd_valid(gemmini_cmd_valid),.gemmini_cmd_ready(gemmini_cmd_ready),
    .gemmini_cmd_funct(gemmini_cmd_funct),.gemmini_cmd_rs1(gemmini_cmd_rs1),.gemmini_cmd_rs2(gemmini_cmd_rs2),
    .gemmini_busy(gemmini_busy),.gemmini_fault(gemmini_fault),
    .tl_a_valid(tl_a_valid),.tl_a_ready(tl_a_ready),.tl_a_address(tl_a_address),
    .tl_d_valid(tl_d_valid),.tl_d_ready(tl_d_ready),.tl_d_opcode(3'd1),.tl_d_size(4'd5),
    .tl_d_source(5'd0),.tl_d_data(tl_d_data),.tl_d_denied(tl_d_denied),.tl_d_corrupt(tl_d_corrupt)
  );
  always @(negedge clock) begin
    tl_a_ready = !reset && delay_count==0 && !tl_d_valid && cycle%4!=0;
    gemmini_cmd_ready = !reset && !block_commands && cycle%5!=0;
    gemmini_busy = busy_left != 0;
  end
  always @(posedge clock) begin
    cycle <= cycle+1;
    cpu_work <= cpu_work+1; // independent CPU work; never supplies a table entry
    if (cycle>60000) $fatal(1,"test watchdog");
    if (!reset) begin
      if (held_a && (!tl_a_valid || prev_addr != tl_a_address)) $fatal(1,"A changed under backpressure");
      if (held_cmd && (!gemmini_cmd_valid || prev_cmd != {gemmini_cmd_funct,gemmini_cmd_rs1,gemmini_cmd_rs2}))
        $fatal(1,"command changed under backpressure");
      if (held_resp && (!response_valid || prev_resp != {response_rd,response_data}))
        $fatal(1,"RoCC response changed under backpressure");
      held_a <= tl_a_valid && !tl_a_ready; prev_addr <= tl_a_address;
      held_cmd <= gemmini_cmd_valid && !gemmini_cmd_ready;
      prev_cmd <= {gemmini_cmd_funct,gemmini_cmd_rs1,gemmini_cmd_rs2};
      held_resp <= response_valid && !response_ready; prev_resp <= {response_rd,response_data};
      if (busy_left>0) busy_left<=busy_left-1;
      if (gemmini_cmd_valid && gemmini_cmd_ready) begin
        busy_left<=13;
        if (enable_checks) begin
          while (table_mem[expected_index][7:0]!=0) expected_index=expected_index+1;
          if (gemmini_cmd_funct != 0 || gemmini_cmd_rs1 != 64'h80002000+expected_index*8 ||
              gemmini_cmd_rs2 != 64'h1200+expected_index) $fatal(1,"command mismatch at %0d",expected_index);
          checked=checked+1; expected_index=expected_index+1;
        end
      end
      if (gemmini_cmd_valid && !gemmini_cmd_ready) stall_cycles<=stall_cycles+1;
      if (dut.fifo_level>max_fifo) max_fifo<=dut.fifo_level;
      if (tl_a_valid && tl_a_ready) begin
        if (tl_a_address[4:0] || tl_a_address < 32'h80001000 || tl_a_address >= 32'h80002000)
          $fatal(1,"invalid fetch address %h",tl_a_address);
        req_index <= (tl_a_address-32'h80001000)>>5;
        delay_count <= 2+(cycle%7);
        read_count<=read_count+1;
      end
      if (delay_count>0) begin
        delay_count<=delay_count-1;
        if (delay_count==1) begin
          tl_d_valid<=1; tl_d_data<=table_mem[req_index]; tl_d_denied<=inject_denied;
        end
      end
      if (tl_d_valid && tl_d_ready) tl_d_valid<=0;
    end else begin
      held_a<=0;held_cmd<=0;held_resp<=0;
    end
  end
  task control(input [6:0] f,input [63:0] a,b,output [63:0] result);
    begin
      @(negedge clock); control_valid=1;control_funct=f;control_rs1=a;control_rs2=b;
      do @(posedge clock); while (!control_ready);
      @(negedge clock); control_valid=0;
      while (!response_valid) @(negedge clock);
      result=response_data;
      if (response_rd!=7) $fatal(1,"bad response rd");
      @(posedge clock); @(negedge clock);
    end
  endtask
  reg [63:0] r;
  task setup(input [31:0] address,n,timeout);
    begin
      control(0,address,n,r); if(r) $fatal(1,"base rejected");
      control(1,32'h80002000,timeout,r); if(r) $fatal(1,"frame rejected");
      control(2,1,0,r); if(r) $fatal(1,"launch rejected");
    end
  endtask
  task expect_fault(input [7:0] code);
    begin
      wait(dut.engine.state_out==6); @(negedge clock);
      if (!interrupt || !dut.fault || dut.error_code!=code || dut.complete) $fatal(1,"wrong fault %0d",code);
      control(5,0,0,r); if(r) $fatal(1,"ack failed");
    end
  endtask
  integer i,saved_reads;
  initial begin
    for(i=0;i<128;i=i+1) table_mem[i]={64'd0,64'h1200+i,64'(i*8),64'h10000};
    table_mem[12]={192'd0,64'd1};
    table_mem[25]={64'd0,64'd0,64'h123456789,64'd2};
    repeat(6) @(negedge clock); reset=0;
    // The existing CPU-to-Gemmini path remains usable when the frontend is idle.
    @(negedge clock);legacy_valid=1;
    do @(posedge clock); while(!legacy_ready);
    if(gemmini_cmd_funct!=0 || gemmini_cmd_rs1!=55 || gemmini_cmd_rs2!=66)
      $fatal(1,"legacy path changed");
    @(negedge clock);legacy_valid=0;
    repeat(20) @(negedge clock);
    enable_checks=1;
    block_commands=1;
    setup(32'h80001000,64,20000);
    control(3,0,0,r); if(!r[0]) $fatal(1,"status unavailable while active");
    control(2,1,0,r); if(r==0) $fatal(1,"double launch accepted");
    repeat(200) @(negedge clock);
    if(dut.fifo_level!=8) $fatal(1,"FIFO did not fill under backpressure");
    block_commands=0;
    wait(dut.host_wait); @(negedge clock);
    if (!interrupt || busy || gemmini_busy || dut.completed_cursor!=26) $fatal(1,"bad HOST handoff");
    saved_reads=read_count; repeat(20) @(negedge clock);
    if (read_count!=saved_reads || checked!=24) $fatal(1,"HOST advanced unexpectedly");
    control(4,99,0,r); if(r==0) $fatal(1,"wrong resume tag accepted");
    control(4,64'h123456789,0,r); if(r) $fatal(1,"resume failed");
    wait(dut.complete); @(negedge clock);
    if(checked!=62 || dut.fetched!=64 || dut.issued!=62 || dut.completed_cursor!=64 ||
       !interrupt || busy || cpu_work<100 || stall_cycles==0) $fatal(1,"bad autonomous run");
    $display("PASS streaming_refill commands=%0d reads=%0d cpu_work=%0d max_fifo=%0d",checked,read_count,cpu_work,max_fifo);
    enable_checks=0;
    control(5,0,0,r);
    if(interrupt) $fatal(1,"ACK did not clear interrupt");
    setup(32'h80001001,1,1000); expect_fault(1);
    setup(32'hffffffe0,2,1000); expect_fault(1);
    table_mem[0]={192'd0,64'd99}; setup(32'h80001000,1,1000); expect_fault(3);
    table_mem[0]={64'd0,64'd0,64'd0,64'd0};
    inject_denied=1; setup(32'h80001000,1,1000); expect_fault(2); inject_denied=0;
    // Timeout while a command is stalled: preserve valid/payload, don't claim
    // completion, and only release ownership after the offered work drains.
    block_commands=1; setup(32'h80001000,1,60);
    wait(dut.fault); repeat(12) @(negedge clock);
    if (!busy || !stream_owner || !gemmini_cmd_valid || dut.complete) $fatal(1,"unsafe timeout recovery");
    block_commands=0; expect_fault(4);
    // Control response remains stable until the CPU accepts it.
    response_ready=0;
    @(negedge clock); control_valid=1;control_funct=3;control_rs1=0;control_rs2=0;
    @(posedge clock); @(negedge clock); control_valid=0;
    repeat(12) @(negedge clock); response_ready=1; repeat(3) @(negedge clock);
    // Non-M-mode launch is rejected, with no fetch.
    saved_reads=read_count; control_prv=1;control(2,1,0,r);
    if (r==0 || read_count!=saved_reads) $fatal(1,"unprivileged launch accepted");
    control_prv=3;
    $display("PASS descriptor_bounds format_error denied_response timeout_drain response_backpressure privilege");
    $display("FRONTEND_TEST_PASS"); $finish;
  end
endmodule
