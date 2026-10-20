`timescale 1ns/1ps

// Pure video-clock-domain display data plane.  Buffer ownership is supplied
// by the frame store and overlay updates arrive as coherent commit records
// from video_control_bridge.
module display_subsystem #(
    parameter integer CHANNELS = 16,
    parameter integer SOURCE_WIDTH = 640,
    parameter integer SOURCE_HEIGHT = 480,
    parameter integer SOURCE_STRIDE_BYTES = SOURCE_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer READ_OUTSTANDING = 8,
    parameter integer READ_DESCRIPTOR_DEPTH = 8
) (
    input  wire                    clk,
    input  wire                    resetn,
    output wire                    buffer_acquire,
    input  wire                    buffer_grant,
    input  wire [31:0]             buffer_base,
    input  wire [CHANNELS*32-1:0]  buffer_bases,
    input  wire [CHANNELS-1:0]     buffer_valid_mask,
    input  wire                    buffer_mode,
    output wire                    buffer_done,
    input  wire [31:0]             frame_width,
    input  wire [31:0]             frame_height,
    input  wire [31:0]             frame_stride_bytes,
    input  wire                    overlay_commit,
    input  wire [3:0]              overlay_stream,
    input  wire [3:0]              overlay_count,
    input  wire [8*64-1:0]         overlay_boxes,
    input  wire [8*128-1:0]        overlay_labels,
    axi4_if.master                 m_axi,
    axis_video_if.source           m_axis,
    output wire                    axi_error,
    output wire                    fifo_underflow,
    output wire [31:0]             debug_active_base,
    output wire [31:0]             debug_status
);
    display_reader_subsystem #(
        .CHANNELS(CHANNELS),
        .SOURCE_WIDTH(SOURCE_WIDTH),
        .SOURCE_HEIGHT(SOURCE_HEIGHT),
        .SOURCE_STRIDE_BYTES(SOURCE_STRIDE_BYTES),
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .READ_OUTSTANDING(READ_OUTSTANDING),
        .READ_DESCRIPTOR_DEPTH(READ_DESCRIPTOR_DEPTH)
    ) u_reader (
        .clk(clk), .resetn(resetn),
        .buffer_acquire(buffer_acquire), .buffer_grant(buffer_grant),
        .buffer_base(buffer_base), .buffer_bases(buffer_bases),
        .buffer_valid_mask(buffer_valid_mask), .buffer_mode(buffer_mode),
        .buffer_done(buffer_done),
        .frame_width(frame_width), .frame_height(frame_height),
        .frame_stride_bytes(frame_stride_bytes), .m_axi(m_axi),
        .overlay_commit(overlay_commit), .overlay_stream(overlay_stream),
        .overlay_count(overlay_count), .overlay_boxes(overlay_boxes),
        .overlay_labels(overlay_labels), .m_axis(m_axis),
        .axi_error(axi_error), .fifo_underflow(fifo_underflow),
        .debug_active_base(debug_active_base), .debug_status(debug_status)
    );
endmodule
