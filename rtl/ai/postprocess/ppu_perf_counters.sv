`timescale 1ns/1ps
// Events are registered before entering the independent counter carry chains.
// Counts overlap (e.g. reader and compute); they are not a partition of total.
// Values settle one clock after busy falls and remain until the next command.
module ppu_perf_counters #(
    parameter ENABLE = 1,
    parameter integer COUNT = 17
)(
    input wire clk, resetn, clear,
    input wire [COUNT-1:0] events,
    output wire [(COUNT+1)*32-1:0] values
);
    reg [COUNT-1:0] pending;
    reg [31:0] counters [0:COUNT-1];
    reg [31:0] max_selected;
    always @(posedge clk) begin
        if (!resetn) begin
            pending <= 0;
            max_selected <= 0;
            for (integer i=0;i<COUNT;i=i+1) counters[i] <= 0;
        end else if (clear) begin
            pending <= 0;
            for (integer i=0;i<COUNT;i=i+1) counters[i] <= 0;
        end else if (ENABLE) begin
            pending <= events;
            for (integer i=0;i<COUNT;i=i+1)
                if (pending[i]) counters[i] <= counters[i]+1'b1;
            if (counters[11] > max_selected) max_selected <= counters[11];
        end
    end
    for (genvar i=0;i<COUNT;i=i+1) begin : g_values
        assign values[i*32+:32] = counters[i];
    end
    assign values[COUNT*32+:32] = max_selected;
endmodule
