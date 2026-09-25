`timescale 1ns/1ps
// Four immutable descriptors in admission order. Full rejects a doorbell;
// dequeue is exclusively a ready/valid handshake. No overwrite or bypass.
module ppu_descriptor_fifo #(parameter WIDTH=364, DEPTH=4)(
    input wire clk,resetn,
    input wire in_valid, output wire in_ready,
    input wire [WIDTH-1:0] in_data,
    output wire out_valid,input wire out_ready,
    output wire [WIDTH-1:0] out_data,
    output reg [$clog2(DEPTH+1)-1:0] count,
    output reg [31:0] rejected
);
    localparam PW=$clog2(DEPTH);
    reg [WIDTH-1:0] memory[0:DEPTH-1];
    reg [PW-1:0] wr,rd;
    assign in_ready=count<DEPTH;
    assign out_valid=count!=0;
    assign out_data=memory[rd];
    wire push=in_valid&&in_ready, pop=out_valid&&out_ready;
    always @(posedge clk) begin
        if(!resetn) begin count<=0;wr<=0;rd<=0;rejected<=0;end
        else begin
            if(in_valid&&!in_ready) rejected<=rejected+1'b1;
            if(push) begin memory[wr]<=in_data;wr<=wr==DEPTH-1?0:wr+1'b1;end
            if(pop) rd<=rd==DEPTH-1?0:rd+1'b1;
            case({push,pop}) 2'b10:count<=count+1'b1;2'b01:count<=count-1'b1;default:;endcase
        end
    end
endmodule
