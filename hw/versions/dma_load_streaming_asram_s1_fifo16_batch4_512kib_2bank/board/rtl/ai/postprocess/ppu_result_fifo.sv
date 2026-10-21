`timescale 1ns/1ps
// Lossless ready/valid records. CPU/Overlay stalls propagate to the engine.
module ppu_result_fifo #(parameter WIDTH=1568,DEPTH=4)(
 input wire clk,resetn,in_valid,output wire in_ready,input wire [WIDTH-1:0] in_data,
 output wire out_valid,input wire out_ready,output wire [WIDTH-1:0] out_data,
 output wire [$clog2(DEPTH+1)-1:0] count
);
 wire [31:0] unused;
 ppu_descriptor_fifo #(.WIDTH(WIDTH),.DEPTH(DEPTH)) storage(
  .clk(clk),.resetn(resetn),.in_valid(in_valid&&in_ready),.in_ready(in_ready),.in_data(in_data),
  .out_valid(out_valid),.out_ready(out_ready),.out_data(out_data),.count(count),.rejected(unused));
endmodule
