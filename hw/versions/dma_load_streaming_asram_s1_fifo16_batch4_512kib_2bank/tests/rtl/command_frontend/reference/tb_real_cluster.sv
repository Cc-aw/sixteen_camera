`timescale 1ns/1ps
module tb_real_cluster;
  reg clock=0;always #5 clock=~clock;
  reg reset=1,control_valid=0;wire control_ready;
  reg [6:0] control_funct=0;reg [63:0] control_rs1=0,control_rs2=0;
  reg [4:0] control_rd=9;reg control_xd=1;reg [1:0] control_prv=3;
  wire response_valid;reg response_ready=1;wire [4:0] response_rd;wire [63:0] response_data;
  wire interrupt,transport_busy;
  reg [2:0] legacy_valid=0;wire [2:0] legacy_ready;reg [20:0] legacy_funct=0;
  reg [191:0] legacy_rs1=0,legacy_rs2=0;wire [2:0] stream_owner,gemmini_cmd_valid,gemmini_cmd_ready;
  wire [20:0] gemmini_cmd_funct;wire [191:0] gemmini_cmd_rs1,gemmini_cmd_rs2;
  wire [2:0] gemmini_busy,gemmini_fault,mem_req_valid,mem_req_ready,mem_resp_valid,mem_resp_ready,mem_resp_error;
  wire [95:0] mem_req_address;wire [767:0] mem_resp_data;
  integer triple_cycles=0,cpu_cycles=0;reg [63:0] v;
  GemminiFrontendCluster dut(.*);
  genvar g;
  generate for(g=0;g<3;g=g+1)begin: lanes
    MemoryLane #(.ID(g)) lane(
      .clock(clock),.reset(reset),.cmd_valid(gemmini_cmd_valid[g]),.cmd_ready(gemmini_cmd_ready[g]),
      .cmd_funct(gemmini_cmd_funct[g*7+:7]),.cmd_rs1(gemmini_cmd_rs1[g*64+:64]),.cmd_rs2(gemmini_cmd_rs2[g*64+:64]),
      .gem_busy(gemmini_busy[g]),.gem_fault(gemmini_fault[g]),
      .f_req_valid(mem_req_valid[g]),.f_req_ready(mem_req_ready[g]),.f_req_address(mem_req_address[g*32+:32]),
      .f_resp_valid(mem_resp_valid[g]),.f_resp_ready(mem_resp_ready[g]),.f_resp_data(mem_resp_data[g*256+:256]),.f_resp_error(mem_resp_error[g])
    );
  end endgenerate
  always @(posedge clock) if(!reset)begin
    cpu_cycles<=cpu_cycles+1;
    if(&gemmini_busy)triple_cycles<=triple_cycles+1;
    if(|dut.fault)$fatal(1,"frontend fault mask=%b",dut.fault);
  end
  task ctl(input integer channel,op,input [63:0] a,b);
    @(negedge clock);control_valid=1;control_funct=7'((channel<<5)|op);control_rs1=a;control_rs2=b;
    do @(posedge clock);while(!control_ready);
    @(negedge clock);control_valid=0;
    if(!response_valid || response_data!==0)$fatal(1,"control error ch%0d op%0d status%h",channel,op,response_data);
  endtask
  task read(input integer channel,query,output reg [63:0] value);
    @(negedge clock);control_valid=1;control_funct=7'((channel<<5)|3);control_rs1=64'(query);control_rs2=0;
    do @(posedge clock);while(!control_ready);
    @(negedge clock);control_valid=0;value=response_data;
  endtask
  initial begin
    lanes[0].lane.initialize();lanes[1].lane.initialize();lanes[2].lane.initialize();
    repeat(20)@(negedge clock);reset=0;
    for(integer i=0;i<3;i=i+1)begin
      ctl(i,0,64'h80008000+i*65536,i==0?41:40);
      ctl(i,1,64'h80000000+i*65536,100000);
      ctl(i,6,500+i*20,0);
    end
    ctl(3,7,7,7);
    wait(dut.host_wait[0]);@(negedge clock);lanes[0].lane.check_matrix('h2000);
    // Hold R0 indefinitely; lanes1/2 must reach DONE, without extra CPU issuing.
    wait(dut.complete[1] && dut.complete[2]);@(negedge clock);
    lanes[1].lane.check_matrix('h2000);lanes[1].lane.check_matrix('h2100);
    lanes[2].lane.check_matrix('h2000);lanes[2].lane.check_matrix('h2100);
    read(3,0,v);if(v[2:0]!=7 || !interrupt)$fatal(1,"IRQ sources missing");
    ctl(1,5,0,0);read(3,0,v);if(v[2:0]!=5)$fatal(1,"IRQ ack isolation");
    lanes[0].lane.modify_input();ctl(0,4,77,0);
    wait(dut.complete[0]);@(negedge clock);lanes[0].lane.check_matrix('h2100);
    ctl(0,5,0,0);ctl(2,5,0,0);
    if(triple_cycles==0)$fatal(1,"no three-engine compute overlap");
    if(lanes[0].lane.fetches!=41 || lanes[1].lane.fetches!=40 || lanes[2].lane.fetches!=40)$fatal(1,"table fetch accounting");
    $display("REAL_CLUSTER_PASS,gemmini=3,matmul=correct,host_isolation=1,write_ack_checked=1,irq_isolation=1,triple_busy_cycles=%0d,cpu_cycles=%0d",triple_cycles,cpu_cycles);
    $finish;
  end
  initial begin #2000000;$fatal(1,"real cluster timeout busy=%b host=%b done=%b",gemmini_busy,dut.host_wait,dut.complete);end
endmodule
