`timescale 1ns/1ps
// Exact restoring division, seven spatial stages, II=1. The edge accumulator
// always accepts output; backpressure is handled at the complete-location port.
module yolov5nu_probability_pipeline (
    input wire clk,resetn,in_valid,
    input wire [24:0] exponent,
    input wire [29:0] total,
    input wire [3:0] in_bin,
    output wire out_valid,
    output wire [3:0] out_bin,
    output wire [7:0] probability
);
    reg [7:0] valid;
    reg [32:0] rem [0:7];
    reg [29:0] divisor[0:7];
    reg [6:0] quotient[0:7];
    reg [3:0] tags[0:7];
    always @(posedge clk) begin
        if(!resetn) valid[0]<=0;
        else begin
            valid[0]<=in_valid;
            rem[0]<=({8'd0,exponent}<<7)-{8'd0,exponent};
            divisor[0]<=total;quotient[0]<=0;tags[0]<=in_bin;
        end
    end
    for(genvar i=0;i<7;i=i+1) begin : g_divide
        localparam integer BIT=6-i;
        wire [36:0] shifted={7'd0,divisor[i]}<<BIT;
        wire take={4'd0,rem[i]}>=shifted;
        always @(posedge clk) begin
            if(!resetn) valid[i+1]<=0;
            else begin
                valid[i+1]<=valid[i];divisor[i+1]<=divisor[i];tags[i+1]<=tags[i];
                rem[i+1]<=take?33'({4'd0,rem[i]}-shifted):rem[i];
                quotient[i+1]<=quotient[i] | (take ? (7'd1<<BIT):7'd0);
            end
        end
    end
    wire [33:0] twice={1'b0,rem[7]}<<1;
    wire round_up=twice>{4'd0,divisor[7]} ||
                  (twice=={4'd0,divisor[7]} && quotient[7][0]);
    wire [7:0] rounded={1'b0,quotient[7]}+{7'd0,round_up};
    assign out_valid=valid[7];assign out_bin=tags[7];
    assign probability=rounded>127?8'd127:rounded;
endmodule
