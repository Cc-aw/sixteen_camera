`timescale 1ns/1ps

module cdc_snapshot #(
    parameter integer WIDTH = 32
) (
    input  wire             request_clk,
    input  wire             request_resetn,
    input  wire             request,
    output wire             busy,
    output reg  [WIDTH-1:0] snapshot,
    output reg              snapshot_valid,
    input  wire             data_clk,
    input  wire             data_resetn,
    input  wire [WIDTH-1:0] data
);
    reg request_toggle;
    reg request_seen;
    reg acknowledge_toggle;
    reg acknowledge_pending;
    reg [WIDTH-1:0] snapshot_hold;
    (* ASYNC_REG = "TRUE" *) reg [1:0] request_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] acknowledge_sync;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] snapshot_sync1;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] snapshot_sync2;

    assign busy = request_toggle != acknowledge_sync[1];

    always @(posedge request_clk) begin
        if (!request_resetn) begin
            request_toggle <= 1'b0;
            acknowledge_sync <= 2'b00;
            snapshot_sync1 <= {WIDTH{1'b0}};
            snapshot_sync2 <= {WIDTH{1'b0}};
            snapshot <= {WIDTH{1'b0}};
            snapshot_valid <= 1'b0;
        end else begin
            acknowledge_sync <= {acknowledge_sync[0], acknowledge_toggle};
            snapshot_sync1 <= snapshot_hold;
            snapshot_sync2 <= snapshot_sync1;
            snapshot_valid <= acknowledge_sync[0] != acknowledge_sync[1];
            if (acknowledge_sync[0] != acknowledge_sync[1])
                snapshot <= snapshot_sync2;
            if (request && !busy)
                request_toggle <= ~request_toggle;
        end
    end

    always @(posedge data_clk) begin
        if (!data_resetn) begin
            request_sync <= 2'b00;
            request_seen <= 1'b0;
            acknowledge_toggle <= 1'b0;
            acknowledge_pending <= 1'b0;
            snapshot_hold <= {WIDTH{1'b0}};
        end else begin
            request_sync <= {request_sync[0], request_toggle};
            if (request_sync[1] != request_seen && !acknowledge_pending) begin
                snapshot_hold <= data;
                request_seen <= request_sync[1];
                acknowledge_pending <= 1'b1;
            end else if (acknowledge_pending) begin
                acknowledge_toggle <= request_seen;
                acknowledge_pending <= 1'b0;
            end
        end
    end
endmodule
