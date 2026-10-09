`timescale 1ns/1ps

// Serialize all camera initialization traffic. Each camera owns separate
// pins, but only the granted controller may issue IIC writes. A terminal
// failure releases the grant so one missing camera cannot block later ones.
module ov7670_init_scheduler (
    input  wire       clk,
    input  wire       rstn,
    input  wire [7:0] request,
    input  wire [7:0] terminal,
    output reg  [7:0] grant
);
    reg active;
    reg [2:0] active_channel;

    always @(posedge clk) begin
        if (!rstn) begin
            grant <= 8'd0;
            active <= 1'b0;
            active_channel <= 3'd0;
        end else if (active) begin
            if (terminal[active_channel]) begin
                grant <= 8'd0;
                active <= 1'b0;
            end
        end else if (request[0]) begin
            grant <= 8'b00000001;
            active <= 1'b1;
            active_channel <= 3'd0;
        end else if (request[1]) begin
            grant <= 8'b00000010;
            active <= 1'b1;
            active_channel <= 3'd1;
        end else if (request[2]) begin
            grant <= 8'b00000100;
            active <= 1'b1;
            active_channel <= 3'd2;
        end else if (request[3]) begin
            grant <= 8'b00001000;
            active <= 1'b1;
            active_channel <= 3'd3;
        end else if (request[4]) begin
            grant <= 8'b00010000;
            active <= 1'b1;
            active_channel <= 3'd4;
        end else if (request[5]) begin
            grant <= 8'b00100000;
            active <= 1'b1;
            active_channel <= 3'd5;
        end else if (request[6]) begin
            grant <= 8'b01000000;
            active <= 1'b1;
            active_channel <= 3'd6;
        end else if (request[7]) begin
            grant <= 8'b10000000;
            active <= 1'b1;
            active_channel <= 3'd7;
        end
    end
endmodule
