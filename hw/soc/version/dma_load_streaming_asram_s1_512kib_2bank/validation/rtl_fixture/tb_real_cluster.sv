`timescale 1ns/1ps
module tb_real_cluster;
  glbl glbl();
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
  wire [1:0] dma_load_mode_0,dma_load_mode_1,dma_load_mode_2;
wire [31:0] dma_load_capabilities_0,dma_load_capabilities_1,dma_load_capabilities_2;
wire [1:0] load_modes[0:2];wire [31:0] load_caps[0:2];
assign load_modes[0]=dma_load_mode_0;assign load_modes[1]=dma_load_mode_1;assign load_modes[2]=dma_load_mode_2;
assign dma_load_capabilities_0=load_caps[0];assign dma_load_capabilities_1=load_caps[1];assign dma_load_capabilities_2=load_caps[2];
integer runtime_mode;integer triple_cycles=0,cpu_cycles=0;reg [63:0] v;
  GemminiFrontendCluster dut(.*);
  genvar g;
  generate for(g=0;g<3;g=g+1)begin: lanes
    MemoryLane #(.ID(g)) lane(
      .dma_load_mode(load_modes[g]),.dma_load_capabilities(load_caps[g]),.clock(clock),.reset(reset),.cmd_valid(gemmini_cmd_valid[g]),.cmd_ready(gemmini_cmd_ready[g]),
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
    repeat(20)@(negedge clock);reset=0;repeat(64)@(negedge clock);
    for(integer profile=0;profile<4;profile=profile+1)begin
      lanes[0].lane.storage_profile=profile;lanes[1].lane.storage_profile=profile;lanes[2].lane.storage_profile=profile;
    for(runtime_mode=2;runtime_mode<3;runtime_mode=runtime_mode+1)begin
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)ctl(lane_id,9,64'(runtime_mode),0);
      for(integer parameter_case=0;parameter_case<6;parameter_case=parameter_case+1)begin
      lanes[0].lane.select_parameters(parameter_case);lanes[1].lane.select_parameters(parameter_case);lanes[2].lane.select_parameters(parameter_case);
      fork begin lanes[0].lane.initialize_raw();lanes[0].lane.local_prepare();end begin lanes[1].lane.initialize_raw();lanes[1].lane.local_prepare();end begin lanes[2].lane.initialize_raw();lanes[2].lane.local_prepare();end join
      for(integer lane_id=0;lane_id<3;lane_id=lane_id+1)begin
        ctl(lane_id,0,64'h80008000+lane_id*65536,lanes[0].lane.command_count);
        ctl(lane_id,1,64'h80000000+lane_id*65536,1000000);
      end
      ctl(3,7,7,7);wait(&dut.complete);@(negedge clock);
      fork begin lanes[0].lane.local_collect();lanes[0].lane.check_raw();end begin lanes[1].lane.local_collect();lanes[1].lane.check_raw();end begin lanes[2].lane.local_collect();lanes[2].lane.check_raw();end join
      ctl(0,5,0,0);ctl(1,5,0,0);ctl(2,5,0,0);
      end
    end
    end
    $display("REAL_CLUSTER_PASS,DMA_SPAD=1,modes=1,lanes=3");$finish;
  end
  initial begin #20000000;$fatal(1,"DMA SPAD timeout");end
endmodule
