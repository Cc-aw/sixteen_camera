`timescale 1ns/1ps

module cdc_mailbox #(
    parameter integer WIDTH = 32
) (
    input  wire             src_clk,
    input  wire             src_resetn,
    input  wire [WIDTH-1:0] src_data,
    input  wire             src_valid,
    output wire             src_ready,
    output reg              src_done,
    input  wire             dst_clk,
    input  wire             dst_resetn,
    output reg  [WIDTH-1:0] dst_data,
    output reg              dst_valid
);
    reg [WIDTH-1:0] payload_hold;
    reg request_toggle;
    reg request_seen;
    reg acknowledge_toggle;
    (* ASYNC_REG = "TRUE" *) reg [2:0] request_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] acknowledge_sync;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] payload_sync1;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] payload_sync2;

    assign src_ready = request_toggle == acknowledge_sync[1];

    always @(posedge src_clk) begin
        if (!src_resetn) begin
            payload_hold <= {WIDTH{1'b0}};
            request_toggle <= 1'b0;
            acknowledge_sync <= 2'b00;
            src_done <= 1'b0;
        end else begin
            acknowledge_sync <= {acknowledge_sync[0], acknowledge_toggle};
            src_done <= acknowledge_sync[0] != acknowledge_sync[1];
            if (src_valid && src_ready) begin
                payload_hold <= src_data;
                request_toggle <= ~request_toggle;
            end
        end
    end

    always @(posedge dst_clk) begin
        if (!dst_resetn) begin
            request_sync <= 3'b000;
            payload_sync1 <= {WIDTH{1'b0}};
            payload_sync2 <= {WIDTH{1'b0}};
            request_seen <= 1'b0;
            acknowledge_toggle <= 1'b0;
            dst_data <= {WIDTH{1'b0}};
            dst_valid <= 1'b0;
        end else begin
            request_sync <= {request_sync[1:0], request_toggle};
            payload_sync1 <= payload_hold;
            payload_sync2 <= payload_sync1;
            dst_valid <= request_sync[2] != request_seen;
            if (request_sync[2] != request_seen) begin
                dst_data <= payload_sync2;
                request_seen <= request_sync[2];
                acknowledge_toggle <= request_sync[2];
            end
        end
    end
endmodule
