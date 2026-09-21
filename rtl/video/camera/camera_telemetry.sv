`timescale 1ns/1ps

// Low-rate camera diagnostics are transported as indexed 32-bit records.
// This replaces wide continuously-changing CDC arrays while preserving the
// existing AXI register map at the destination.
module camera_telemetry (
    input  wire         ctrl_clk,
    input  wire         ctrl_resetn,
    input  wire [31:0]  ctrl_status0_src,
    input  wire [31:0]  ctrl_status1_src,

    input  wire         capture_clk,
    input  wire         capture_resetn,
    input  wire         capture_enable,
    input  wire         pclk_locked,
    input  wire [1:0]   pclk_state,
    input  wire [23:0]  pclk_period,
    input  wire [31:0]  frame_count,
    input  wire [31:0]  overflow_count,
    input  wire [31:0]  lock_loss_count,
    input  wire [31:0]  geometry,

    input  wire         axil_clk,
    input  wire         axil_resetn,
    output reg  [31:0]  ctrl_status0,
    output reg  [31:0]  ctrl_status1,
    output reg  [31:0]  capture_status0,
    output reg  [31:0]  capture_frame_count,
    output reg  [31:0]  capture_overflow_count,
    output reg  [31:0]  capture_lock_loss_count,
    output reg  [31:0]  capture_geometry
);
    reg ctrl_index;
    wire ctrl_ready;
    wire ctrl_valid;
    wire [32:0] ctrl_record_dst;
    wire [31:0] ctrl_value = ctrl_index ? ctrl_status1_src :
                                           ctrl_status0_src;

    cdc_mailbox #(.WIDTH(33)) u_ctrl_mailbox (
        .src_clk(ctrl_clk), .src_resetn(ctrl_resetn),
        .src_data({ctrl_index, ctrl_value}), .src_valid(1'b1),
        .src_ready(ctrl_ready), .src_done(),
        .dst_clk(axil_clk), .dst_resetn(axil_resetn),
        .dst_data(ctrl_record_dst), .dst_valid(ctrl_valid)
    );

    always @(posedge ctrl_clk) begin
        if (!ctrl_resetn)
            ctrl_index <= 1'b0;
        else if (ctrl_ready)
            ctrl_index <= ~ctrl_index;
    end

    reg [2:0] capture_index;
    reg [31:0] capture_value;
    wire capture_ready;
    wire capture_valid;
    wire [34:0] capture_record_dst;

    always @* begin
        case (capture_index)
            3'd0: capture_value = {4'd0, pclk_period, pclk_state,
                                    pclk_locked, capture_enable};
            3'd1: capture_value = frame_count;
            3'd2: capture_value = overflow_count;
            3'd3: capture_value = lock_loss_count;
            default: capture_value = geometry;
        endcase
    end

    cdc_mailbox #(.WIDTH(35)) u_capture_mailbox (
        .src_clk(capture_clk), .src_resetn(capture_resetn),
        .src_data({capture_index, capture_value}), .src_valid(1'b1),
        .src_ready(capture_ready), .src_done(),
        .dst_clk(axil_clk), .dst_resetn(axil_resetn),
        .dst_data(capture_record_dst), .dst_valid(capture_valid)
    );

    always @(posedge capture_clk) begin
        if (!capture_resetn)
            capture_index <= 3'd0;
        else if (capture_ready)
            capture_index <= capture_index == 3'd4 ? 3'd0 :
                             capture_index + 1'b1;
    end

    always @(posedge axil_clk) begin
        if (!axil_resetn) begin
            ctrl_status0 <= 32'd0;
            ctrl_status1 <= 32'd0;
            capture_status0 <= 32'd0;
            capture_frame_count <= 32'd0;
            capture_overflow_count <= 32'd0;
            capture_lock_loss_count <= 32'd0;
            capture_geometry <= 32'd0;
        end else begin
            if (ctrl_valid) begin
                if (ctrl_record_dst[32])
                    ctrl_status1 <= ctrl_record_dst[31:0];
                else
                    ctrl_status0 <= ctrl_record_dst[31:0];
            end
            if (capture_valid) begin
                case (capture_record_dst[34:32])
                    3'd0: capture_status0 <= capture_record_dst[31:0];
                    3'd1: capture_frame_count <= capture_record_dst[31:0];
                    3'd2: capture_overflow_count <= capture_record_dst[31:0];
                    3'd3: capture_lock_loss_count <= capture_record_dst[31:0];
                    3'd4: capture_geometry <= capture_record_dst[31:0];
                    default: begin end
                endcase
            end
        end
    end
endmodule
