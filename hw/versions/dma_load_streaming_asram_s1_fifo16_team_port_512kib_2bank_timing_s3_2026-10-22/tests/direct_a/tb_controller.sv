`timescale 1ns/1ps
module tb_controller;
    reg clock=0;always #5 clock=~clock;
    reg reset=1,cmd_valid=0,resp_valid=0;
    wire cmd_ready,req_valid,completed_valid,busy;
    reg [6:0] cmd_funct=0,cmd_rob=0;
    reg [63:0] cmd_rs1=0,cmd_rs2=0;
    reg [15:0] resp_bytes=0;
    reg [7:0] resp_id=0;
    wire [6:0] completed_rob;
    integer cycle=0;
    wire req_ready=cycle%7!=0 && cycle%11!=0;
    wire [39:0] address,stride;
    wire [13:0] local_address;
    wire [15:0] cols,repeats,scale,block_stride;
    wire [7:0] pixels,request_id;
    wire [5:0] rows;
    wire [4:0] row_index;
    wire first,last,dual,high,has_acc,zeros;
    ControllerProbe dut(.*);
    integer case_id=0,test_rows=1,request_count=0,returned_dual=0,returned_normal=0;
    integer total_cases=0,total_requests=0,completed_count=0;
    reg dual_done=0,normal_done=0;
    reg [7:0] dual_id=0,normal_id=0;
    reg [32:0] source0=0;
    reg [32:0] delta=0;
    reg [255:0] old_packet;
    wire [255:0] packet={address,stride,local_address,cols,repeats,scale,block_stride,
        pixels,request_id,rows,row_index,first,last,dual,high,has_acc,zeros};
    reg stalled=0;
    task tick;@(posedge clock);#1;@(negedge clock);endtask
    task send(input [6:0] f,input [63:0] a,b,input [6:0] rob);
        cmd_valid=1;cmd_funct=f;cmd_rs1=a;cmd_rs2=b;cmd_rob=rob;#1;
        while(!cmd_ready)tick();
        tick();cmd_valid=0;
    endtask
    task reply(input [7:0] id,input [15:0] bytes);
        resp_valid=1;resp_id=id;resp_bytes=bytes;tick();resp_valid=0;
    endtask
    always @(posedge clock)begin
        cycle<=cycle+1;
        if(!reset)begin
            if(stalled && (!req_valid || packet!==old_packet))
                $fatal(1,"DirectA request changed under backpressure case=%0d",case_id);
            stalled=req_valid&&!req_ready;old_packet=packet;
            if(req_valid&&req_ready)begin
                if(request_count<test_rows*2)begin
                    if(!dual || high!==1'(request_count%2) || cols!=16 || repeats!=0 ||
                       scale!==(request_count%2?16'h3800:16'h3c00) || block_stride!=32 || pixels!=1 ||
                       first!==(request_count==0) || last!==(request_count==test_rows*2-1) ||
                       rows!=test_rows || row_index!=request_count/2 ||
                       local_address!=64+request_count/2 || has_acc || zeros || stride!=19)
                        $fatal(1,"DirectA metadata/phase mismatch case=%0d request=%0d",case_id,request_count);
                    if(address!==40'((source0+33'((request_count/2)*19)+
                       (request_count%2?delta:33'd0))&33'h1ffffffff))
                        $fatal(1,"DirectA physical delta/address mismatch case=%0d request=%0d address=%h",case_id,request_count,address);
                    if(request_count==0)dual_id=request_id;
                    else if(request_id!==dual_id)$fatal(1,"DirectA command split into unrelated completion IDs");
                end else begin
                    if(request_count!=test_rows*2 || dual || high || cols!=7 || scale!=16'h4000 ||
                       rows!=1 || row_index!=0 || !first || !last || local_address!=2000 ||
                       address!==40'(source0+33'h80000) || stride!=32)
                        $fatal(1,"ordinary CONFIG_LD did not restore normal mode case=%0d",case_id);
                    normal_id=request_id;
                    if(normal_id==dual_id)$fatal(1,"live logical commands share completion ID");
                end
                request_count=request_count+1;total_requests=total_requests+1;
            end
            if(resp_valid)begin
                if(resp_id==dual_id)returned_dual=returned_dual+resp_bytes;
                else if(resp_id==normal_id)returned_normal=returned_normal+resp_bytes;
                else $fatal(1,"test returned an unknown command ID");
            end
            if(completed_valid)begin
                if(completed_rob==case_id)begin
                    if(returned_dual!=test_rows*32 || dual_done)
                        $fatal(1,"DirectA early/duplicate completion case=%0d bytes=%0d",case_id,returned_dual);
                    dual_done=1;
                end else if(completed_rob==case_id+64)begin
                    if(returned_normal!=7 || normal_done)$fatal(1,"ordinary completion error");
                    normal_done=1;
                end else $fatal(1,"completion ROB ownership mismatch");
                completed_count=completed_count+1;
            end
        end
    end
    reg [255:0] place_data=0;
    reg [31:0] place_mask=0;
    reg place_high=0;
    wire [255:0] placed_data;
    wire [31:0] placed_mask;
    S1MvinLanePlace placement(.io_data(place_data),.io_mask(place_mask),.io_high(place_high),
        .io_out_data(placed_data),.io_out_mask(placed_mask));
    initial begin
        for(integer i=0;i<256;i=i+1)begin
            for(integer b=0;b<32;b=b+1)place_data[b*8+:8]=8'(i+b*17);
            place_mask=32'((i*257)^16'ha55a)&32'hffff;place_high=1'(i%2);#1;
            if(placed_data!==(place_high?256'(place_data<<128):place_data) ||
               placed_mask!==(place_high?32'(place_mask<<16):place_mask))
                $fatal(1,"data and mask placement mismatch");
        end
        repeat(4)tick();reset=0;
        for(integer state_id=0;state_id<3;state_id=state_id+1)
            for(integer shape=0;shape<3;shape=shape+1)
                for(integer address_case=0;address_case<4;address_case=address_case+1)begin
                    case_id=total_cases;test_rows=shape==0?1:shape==1?31:32;
                    source0=address_case<2?33'h2000100f:33'h18000100f;
                    delta=address_case==0?33'h4000:address_case==1?33'h1ffffc000:
                        address_case==2?33'h100000000:33'h1000;
                    request_count=0;returned_dual=0;returned_normal=0;dual_done=0;normal_done=0;
                    send(0,64'h00003c0000200105|(64'(state_id)<<3),19,0);
                    send(0,64'h0000380000000085|(64'(state_id)<<3),64'(delta),0);
                    send(state_id==0?2:state_id==1?1:14,64'(source0),
                        (64'(test_rows)<<48)|(64'd32<<32)|64'd64,7'(case_id));
                    // Restore normal state while old dual completion is held.
                    send(0,64'h0000400000200105|(64'(state_id)<<3),32,0);
                    send(state_id==0?2:state_id==1?1:14,64'(source0+33'h80000),
                        (64'd1<<48)|(64'd7<<32)|64'd2000,7'(case_id+64));
                    while(request_count<test_rows*2+1)tick();
                    for(integer i=0;i<test_rows;i=i+1)reply(dual_id,16);
                    reply(normal_id,7);repeat(20)tick();
                    if(dual_done || !normal_done)$fatal(1,"one source retired the complete dual command");
                    for(integer i=0;i<test_rows;i=i+1)reply(dual_id,16);
                    while(!dual_done)tick();repeat(4)tick();
                    if(busy)$fatal(1,"controller/tracker did not drain");
                    total_cases=total_cases+1;
                end
        if(completed_count!=total_cases*2)$fatal(1,"lost completion");
        $display("S1_DIRECT_A_CONTROLLER_PASS,cases=%0d,requests=%0d,states=3,negative_delta=1,address33=1,restore=1,completion=1,placement=256",total_cases,total_requests);
        $finish;
    end
    initial begin #2000000;$fatal(1,"DirectA controller timeout case=%0d requests=%0d",case_id,request_count);end
endmodule
