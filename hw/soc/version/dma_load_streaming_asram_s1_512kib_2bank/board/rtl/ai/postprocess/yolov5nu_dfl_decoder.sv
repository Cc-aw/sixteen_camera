`timescale 1ns/1ps
// Four exact edge engines operate concurrently on the same sparse location.
module yolov5nu_dfl_decoder (
    input wire clk,resetn,start,
    input wire [1:0] head,
    input wire [511:0] logits,
    output wire busy,valid,
    input wire ready,
    output wire [31:0] distances
);
    wire [3:0] edge_busy,edge_valid;
    assign busy=|edge_busy;
    assign valid=&edge_valid;
    wire accept=start && !busy && (!valid || ready);
    for(genvar e=0;e<4;e=e+1) begin : g_edge
        yolov5nu_dfl_edge u_edge(
            .clk(clk),.resetn(resetn),.start(accept),.head(head),
            .logits(logits[e*128+:128]),.busy(edge_busy[e]),.valid(edge_valid[e]),
            .ready(ready && valid),.distance_out(distances[e*8+:8]));
    end
endmodule
