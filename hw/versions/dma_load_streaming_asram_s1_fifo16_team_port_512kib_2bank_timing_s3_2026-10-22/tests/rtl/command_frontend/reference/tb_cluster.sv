`timescale 1ns/1ps
module tb_cluster;
  reg clock=0;always #5 clock=~clock;
  reg reset=1,control_valid=0;wire control_ready;
  reg [6:0] control_funct=0;reg [63:0] control_rs1=0,control_rs2=0;
  reg [4:0] control_rd=9;reg control_xd=1;reg [1:0] control_prv=3;
  wire response_valid;reg response_ready=1;wire [4:0] response_rd;wire [63:0] response_data;
  wire interrupt,transport_busy;
  reg [2:0] legacy_valid=0;wire [2:0] legacy_ready;reg [20:0] legacy_funct=0;
  reg [191:0] legacy_rs1=0,legacy_rs2=0;wire [2:0] stream_owner,gemmini_cmd_valid;
  reg [2:0] gemmini_cmd_ready=7;wire [20:0] gemmini_cmd_funct;wire [191:0] gemmini_cmd_rs1,gemmini_cmd_rs2;
  reg [2:0] gemmini_busy=0,gemmini_fault=0;
  wire [2:0] mem_req_valid;wire [2:0] mem_req_ready=~mem_resp_valid;
  wire [95:0] mem_req_address;reg [2:0] mem_resp_valid=0;wire [2:0] mem_resp_ready;
  reg [767:0] mem_resp_data=0;reg [2:0] mem_resp_error=0;
  reg [255:0] table0[0:31];reg [255:0] table1[0:31];reg [255:0] table2[0:31];
  integer i,j,cycles=0,issued[0:2];reg [63:0] v,t0,t1,t2;
  GemminiFrontendCluster dut(.*);
  always @(posedge clock) if(!reset) begin
    cycles<=cycles+1;
    for(integer n=0;n<3;n=n+1) begin
      if(mem_resp_valid[n] && mem_resp_ready[n]) mem_resp_valid[n]<=0;
      if(mem_req_valid[n] && mem_req_ready[n]) begin
        mem_resp_valid[n]<=1;
        case(n)
          0:mem_resp_data[n*256+:256]<=table0[mem_req_address[n*32+5+:5]];
          1:mem_resp_data[n*256+:256]<=table1[mem_req_address[n*32+5+:5]];
          2:mem_resp_data[n*256+:256]<=table2[mem_req_address[n*32+5+:5]];
        endcase
      end
      if(gemmini_cmd_valid[n] && gemmini_cmd_ready[n]) issued[n]<=issued[n]+1;
    end
  end
  task ctl(input integer channel,op,input [63:0] a,b,expected);
    @(negedge clock);control_valid=1;control_funct=7'((channel<<5)|op);control_rs1=a;control_rs2=b;
    do @(posedge clock);while(!control_ready);
    @(negedge clock);control_valid=0;
    if(!response_valid || response_data!==expected) $fatal(1,"control ch%0d op%0d got%h expected%h",channel,op,response_data,expected);
  endtask
  task read(input integer channel,query,output reg [63:0] value);
    @(negedge clock);control_valid=1;control_funct=7'((channel<<5)|3);control_rs1=64'(query);control_rs2=0;
    do @(posedge clock);while(!control_ready);
    @(negedge clock);control_valid=0;value=response_data;
  endtask
  initial begin
    for(i=0;i<3;i=i+1)issued[i]=0;
    for(i=0;i<32;i=i+1)begin table0[i]=0;table1[i]=0;table2[i]=0;end
    table0[10]={64'b0,64'b0,64'd77,64'd2};
    repeat(5)@(negedge clock);reset=0;
    control_prv=0;ctl(0,0,32'h80000000,24,64'hffffffffffffffff);control_prv=3;
    for(i=0;i<3;i=i+1)begin
      ctl(i,0,32'h80000000,24,0);ctl(i,1,32'h80000000,10000,0);
      ctl(i,6,300+i*20,0,0);
    end
    ctl(3,7,7,7,0);
    ctl(1,0,32'h80000000,1,64'hffffffffffffffff);
    wait(dut.host_wait[0]);
    wait(dut.complete[1] && dut.complete[2]);
    read(0,6,t0);read(1,6,t1);read(2,6,t2);
    if(t0!=300 || t1!=320 || t2!=340) $fatal(1,"scheduled starts %d %d %d",t0,t1,t2);
    if(issued[1]!=24 || issued[2]!=24 || issued[0]!=10) $fatal(1,"HOST stopped another lane");
    read(3,0,v);if(v[2:0]!=7 || !interrupt) $fatal(1,"pending IRQ mask");
    ctl(1,5,0,0,0);read(3,0,v);if(v[2:0]!=5) $fatal(1,"ACK cleared other lanes");
    ctl(0,4,99,0,64'hffffffffffffffff);
    ctl(0,4,77,0,0);wait(dut.complete[0]);
    ctl(0,5,0,0,0);ctl(2,5,0,0,0);
    // Independent CPU control responses while an unrelated accelerator is busy.
    gemmini_busy[2]=1;read(0,0,v);
    if(v[63:32]!=32'h20000 || !(v&16)) $fatal(1,"unrelated busy blocked ready");
    repeat(3)@(negedge clock);
    if(transport_busy) $fatal(1,"execution incorrectly counts as control busy");
    gemmini_busy=0;
    ctl(0,6,100000,0,0);ctl(0,7,0,0,0);ctl(0,8,0,0,0);
    read(0,0,v);if(v[7] || !v[4]) $fatal(1,"scheduled cancellation");
    // Invalid global mask cannot partially arm a subset.
    ctl(3,7,8,7,64'hffffffffffffffff);
    if(dut.armed) $fatal(1,"invalid global ARM changed ownership");
    // Descriptor fault belongs to one lane; another lane still completes.
    ctl(0,0,32'h80000001,24,0);ctl(0,2,1,0,0);
    ctl(1,2,1,0,0);wait(dut.complete[1]);
    read(3,0,v);if(v[2:0]!=3 || !dut.fault[0]) $fatal(1,"fault/IRQ isolation");
    ctl(0,5,0,0,0);read(3,0,v);if(v[2:0]!=2) $fatal(1,"fault ACK cleared another event");
    ctl(1,5,0,0,0);
    // Response register cannot change under CPU backpressure.
    repeat(2)@(negedge clock);response_ready=0;read(0,0,v);
    repeat(5)begin @(negedge clock);if(!response_valid || response_data!=v || control_ready) $fatal(1,"unstable response");end
    response_ready=1;
    $display("CLUSTER_PASS,channels=3,independent_host=1,irq_ack_isolation=1,scheduled_delta=20,response_backpressure=1");
    $finish;
  end
  initial begin #500000;$fatal(1,"cluster timeout cycle=%d armed=%b host=%b done=%b fault=%b issue=%d/%d/%d control=%d valid=%b ready=%b",dut.cycle,dut.armed,dut.host_wait,dut.complete,dut.fault,issued[0],issued[1],issued[2],control_funct,control_valid,control_ready);end
endmodule
