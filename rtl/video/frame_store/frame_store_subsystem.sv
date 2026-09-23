`timescale 1ns/1ps

// Frame ownership and capture-write data plane.  Display is connected through
// the reader lease interface; tensor/overlay/control semantics do not enter
// this subsystem.
module frame_store_subsystem #(
    parameter integer CHANNELS = 16,
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer FRAME_STRIDE_BYTES = FRAME_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer WRITE_OUTSTANDING = 8,
    parameter integer WRITE_DESCRIPTOR_DEPTH = 16
) (
    input  wire                    clk,
    input  wire                    resetn,
    video_stream_if.sink           capture_channels [CHANNELS],
    axi4_if.master                 writer_axi,
    input  wire                    cfg_request_toggle,
    output wire                    cfg_ack_toggle,
    input  wire                    cfg_enable,
    input  wire [31:0]             cfg_width,
    input  wire [31:0]             cfg_height,
    input  wire [31:0]             cfg_stride_bytes,
    input  wire [31:0]             cfg_buffers_per_channel,
    input  wire [CHANNELS*32-1:0]  cfg_channel_bases,
    input  wire [31:0]             cfg_buffer_stride_bytes,
    input  wire [((CHANNELS <= 1) ? 1 : $clog2(CHANNELS))-1:0]
                                         cfg_display_channel,
    input  wire                    cfg_display_mode,
    input  wire                    reader_acquire,
    output wire                    reader_grant,
    output wire [31:0]             reader_base,
    output wire [CHANNELS*32-1:0]  reader_bases,
    output wire [CHANNELS-1:0]     reader_valid_mask,
    output wire                    reader_mode,
    input  wire                    reader_done,
    input  wire                    reader_underflow,
    output wire [31:0]             active_width,
    output wire [31:0]             active_height,
    output wire [31:0]             active_stride_bytes,
    output wire [CHANNELS*32-1:0]  writer_frame_counts,
    output wire [31:0]             reader_frame_count,
    output wire [CHANNELS*32-1:0]  drop_counts,
    output wire [31:0]             underflow_count,
    output wire [31:0]             manager_status,
    output wire                    writer_error,
    output wire [15:0]             perf_outstanding_current,
    output wire [15:0]             perf_outstanding_max,
    output wire [31:0]             perf_aw_stall_cycles,
    output wire [31:0]             perf_w_stall_cycles,
    output wire [31:0]             perf_b_stall_cycles,
    output wire [31:0]             perf_bursts_issued,
    output wire [31:0]             perf_bursts_completed,
    output wire [31:0]             perf_response_errors
);
    wire [CHANNELS-1:0] writer_acquire;
    wire [CHANNELS-1:0] writer_grant;
    wire [CHANNELS-1:0] writer_drop;
    wire [CHANNELS*32-1:0] writer_base;
    wire [CHANNELS-1:0] frame_done;
    wire [CHANNELS-1:0] frame_error;

    multi_channel_frame_manager #(.CHANNELS(CHANNELS)) u_manager (
        .ui_clk(clk), .ui_resetn(resetn),
        .cfg_request_toggle(cfg_request_toggle),
        .cfg_ack_toggle(cfg_ack_toggle), .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .writer_acquire(writer_acquire), .writer_grant(writer_grant),
        .writer_drop(writer_drop), .writer_base(writer_base),
        .writer_done(frame_done), .writer_error(frame_error),
        .reader_acquire(reader_acquire), .reader_grant(reader_grant),
        .reader_base(reader_base), .reader_done(reader_done),
        .reader_bases(reader_bases),
        .reader_valid_mask(reader_valid_mask), .reader_mode(reader_mode),
        .reader_underflow(reader_underflow),
        .active_width(active_width), .active_height(active_height),
        .active_stride_bytes(active_stride_bytes),
        .writer_frame_counts(writer_frame_counts),
        .reader_frame_count(reader_frame_count), .drop_counts(drop_counts),
        .underflow_count(underflow_count), .status(manager_status)
    );

    multi_channel_video_dma #(
        .CHANNELS(CHANNELS), .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .FRAME_STRIDE_BYTES(FRAME_STRIDE_BYTES),
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .WRITE_OUTSTANDING(WRITE_OUTSTANDING),
        .DESCRIPTOR_DEPTH(WRITE_DESCRIPTOR_DEPTH)
    ) u_writer (
        .channels(capture_channels), .m_axi(writer_axi),
        .buffer_acquire(writer_acquire), .buffer_grant(writer_grant),
        .buffer_drop(writer_drop), .buffer_base(writer_base),
        .frame_done(frame_done), .frame_error(frame_error),
        .channel_active(), .fifo_levels(),
        .active_frame_ids(),
        .perf_outstanding_current(perf_outstanding_current),
        .perf_outstanding_max(perf_outstanding_max),
        .perf_aw_stall_cycles(perf_aw_stall_cycles),
        .perf_w_stall_cycles(perf_w_stall_cycles),
        .perf_b_stall_cycles(perf_b_stall_cycles),
        .perf_bursts_issued(perf_bursts_issued),
        .perf_bursts_completed(perf_bursts_completed),
        .perf_response_errors(perf_response_errors)
    );

    assign writer_error = |frame_error;
endmodule
