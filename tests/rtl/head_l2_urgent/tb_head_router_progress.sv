`timescale 1ns/1ps
module tb_head_router_progress #(parameter bit READ_DECOUPLE = 1'b1);
    tb_head_router_ordering #(.READ_DECOUPLE(READ_DECOUPLE)) test();
endmodule
