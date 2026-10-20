`timescale 1ns/1ps

module cdc_toggle_handshake #(
    parameter integer SYNC_STAGES = 2
) (
    input  wire src_clk,
    input  wire src_resetn,
    input  wire src_request,
    output wire src_busy,
    output reg  src_done,
    input  wire dst_clk,
    input  wire dst_resetn,
    output reg  dst_pulse
);
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] req_sync;
    (* ASYNC_REG = "TRUE" *) reg [SYNC_STAGES-1:0] ack_sync;
    reg request_toggle;
    reg request_seen;
    reg acknowledge_toggle;

    assign src_busy = request_toggle != ack_sync[SYNC_STAGES-1];

    always @(posedge src_clk) begin
        if (!src_resetn) begin
            request_toggle <= 1'b0;
            ack_sync <= {SYNC_STAGES{1'b0}};
            src_done <= 1'b0;
        end else begin
            ack_sync <= {ack_sync[SYNC_STAGES-2:0], acknowledge_toggle};
            src_done <= request_toggle == ack_sync[SYNC_STAGES-2] &&
                        request_toggle != ack_sync[SYNC_STAGES-1];
            if (src_request && !src_busy)
                request_toggle <= ~request_toggle;
        end
    end

    always @(posedge dst_clk) begin
        if (!dst_resetn) begin
            req_sync <= {SYNC_STAGES{1'b0}};
            request_seen <= 1'b0;
            acknowledge_toggle <= 1'b0;
            dst_pulse <= 1'b0;
        end else begin
            req_sync <= {req_sync[SYNC_STAGES-2:0], request_toggle};
            dst_pulse <= req_sync[SYNC_STAGES-1] != request_seen;
            if (req_sync[SYNC_STAGES-1] != request_seen) begin
                request_seen <= req_sync[SYNC_STAGES-1];
                acknowledge_toggle <= req_sync[SYNC_STAGES-1];
            end
        end
    end

    initial begin
        if (SYNC_STAGES < 2)
            $error("cdc_toggle_handshake requires SYNC_STAGES >= 2");
    end
endmodule
