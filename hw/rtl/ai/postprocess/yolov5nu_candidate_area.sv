`timescale 1ns/1ps
// Compute area once per candidate. Internal metadata grows; result ABI stays 128b.
module yolov5nu_candidate_area (
    input wire clk,resetn,in_valid,
    output wire in_ready,
    input wire [127:0] in_data,
    input wire [7:0] in_score,
    output wire out_valid,busy,
    input wire out_ready,
    output reg [159:0] out_data,
    output reg [7:0] out_score
);
    reg [1:0] valid;
    reg [127:0] data0;
    reg [7:0] score0;
    reg [15:0] width0,height0;
    wire advance=!valid[1]||out_ready;
    assign in_ready=advance;
    assign out_valid=valid[1];
    assign busy=|valid;
    always @(posedge clk) begin
        if(!resetn) begin valid<=0;out_data<=0;out_score<=0;end
        else if(advance) begin
            valid<={valid[0],in_valid};data0<=in_data;score0<=in_score;
            width0<=in_data[47:32]>in_data[15:0]?in_data[47:32]-in_data[15:0]:16'd0;
            height0<=in_data[63:48]>in_data[31:16]?in_data[63:48]-in_data[31:16]:16'd0;
            out_data<={32'(width0*height0),data0};out_score<=score0;
        end
    end
endmodule
