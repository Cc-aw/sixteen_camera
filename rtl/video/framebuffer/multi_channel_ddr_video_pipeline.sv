`timescale 1ns/1ps

// Three-local-camera DDR capture/display pipeline.  The physical camera
// channels are normalized before this boundary; this block only sees
// DDR-clocked streams and therefore has no camera-clock CDC responsibility.
module multi_channel_ddr_video_pipeline #(
    parameter integer CHANNELS = 3,
    parameter integer GLOBAL_CHANNEL_BASE = 4,
    parameter [CHANNELS-1:0] CAMERA_PRESENT_MASK =
        {{(CHANNELS-1){1'b0}}, 1'b1},
    parameter [CHANNELS*32-1:0] DEFAULT_CHANNEL_BASES = {
        32'h0c00_0000, 32'h0a00_0000, 32'h0800_0000
    },
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080,
    parameter integer FRAME_STRIDE_BYTES = FRAME_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer WRITE_OUTSTANDING = 8,
    parameter integer WRITE_DESCRIPTOR_DEPTH = 16,
    parameter integer READ_OUTSTANDING = 8,
    parameter integer READ_DESCRIPTOR_DEPTH = 8
) (
    input wire init_done,
    input wire ddr_ui_clk,
    input wire ddr_resetn,
    axi_lite_if.slave control_axil,
    video_stream_if.sink capture_channels [CHANNELS],
    input wire [CHANNELS*32-1:0] malformed_counts,
    axi4_if.master writer_axi,
    axi4_if.master reader_axi,
    axis_video_if.source display_axis,
    output wire writer_error,
    output wire reader_error,
    output wire reader_underflow
);
    localparam integer CHANNEL_WIDTH = (CHANNELS <= 1) ? 1 : $clog2(CHANNELS);
    wire cfg_request_toggle;
    wire cfg_ack_toggle;
    wire cfg_enable;
    wire [31:0] cfg_width;
    wire [31:0] cfg_height;
    wire [31:0] cfg_stride_bytes;
    wire [31:0] cfg_buffers_per_channel;
    wire [CHANNELS*32-1:0] cfg_channel_bases;
    wire [31:0] cfg_buffer_stride_bytes;
    wire [2:0] cfg_display_channel;
    wire cfg_display_mode;
    wire [CHANNEL_WIDTH-1:0] local_display_channel =
        cfg_display_channel - GLOBAL_CHANNEL_BASE;

    wire [31:0] active_width;
    wire [31:0] active_height;
    wire [31:0] active_stride_bytes;
    wire [CHANNELS-1:0] writer_acquire;
    wire [CHANNELS-1:0] writer_grant;
    wire [CHANNELS-1:0] writer_drop;
    wire [CHANNELS*32-1:0] writer_base;
    wire [CHANNELS-1:0] frame_done;
    wire [CHANNELS-1:0] frame_error;
    wire [CHANNELS*32-1:0] writer_frame_counts;
    wire [CHANNELS*32-1:0] drop_counts;
    wire [31:0] reader_frame_count;
    wire [31:0] underflow_count;
    wire [31:0] manager_status;
    wire reader_acquire;
    wire reader_grant;
    wire [31:0] reader_base;
    wire [CHANNELS*32-1:0] reader_bases;
    wire [CHANNELS-1:0] reader_valid_mask;
    wire reader_mode;
    wire reader_done;
    wire [31:0] reader_active_base;
    wire [31:0] reader_debug_status;

    wire [31:0] manager_status_cpu;
    wire [CHANNELS*32-1:0] writer_frame_counts_cpu;
    wire [CHANNELS*32-1:0] drop_counts_cpu;
    wire [CHANNELS*32-1:0] malformed_counts_cpu;
    wire [31:0] reader_frame_count_cpu;
    wire [31:0] underflow_count_cpu;
    wire [31:0] reader_active_base_cpu;
    wire [31:0] reader_debug_status_cpu;
    wire [15:0] writer_perf_outstanding_current;
    wire [15:0] writer_perf_outstanding_max;
    wire [31:0] writer_perf_aw_stall_cycles;
    wire [31:0] writer_perf_w_stall_cycles;
    wire [31:0] writer_perf_b_stall_cycles;
    wire [31:0] writer_perf_bursts_issued;
    wire [31:0] writer_perf_bursts_completed;
    wire [31:0] writer_perf_response_errors;
    wire [31:0] writer_perf_outstanding_current_cpu;
    wire [31:0] writer_perf_outstanding_max_cpu;
    wire [31:0] writer_perf_aw_stall_cycles_cpu;
    wire [31:0] writer_perf_w_stall_cycles_cpu;
    wire [31:0] writer_perf_b_stall_cycles_cpu;
    wire [31:0] writer_perf_bursts_issued_cpu;
    wire [31:0] writer_perf_bursts_completed_cpu;
    wire [31:0] writer_perf_response_errors_cpu;

    multi_channel_framebuffer_ctrl #(
        .CHANNELS(CHANNELS),
        .GLOBAL_CHANNEL_BASE(GLOBAL_CHANNEL_BASE),
        .CAMERA_PRESENT_MASK(CAMERA_PRESENT_MASK),
        .DEFAULT_CHANNEL_BASES(DEFAULT_CHANNEL_BASES)
    ) u_control (
        .axil(control_axil),
        .cfg_request_toggle(cfg_request_toggle),
        .cfg_enable(cfg_enable),
        .cfg_width(cfg_width),
        .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .cfg_ack_toggle(cfg_ack_toggle),
        .manager_status(manager_status_cpu),
        .writer_frame_counts(writer_frame_counts_cpu),
        .drop_counts(drop_counts_cpu),
        .malformed_counts(malformed_counts_cpu),
        .reader_frame_count(reader_frame_count_cpu),
        .underflow_count(underflow_count_cpu),
        .reader_active_base(reader_active_base_cpu),
        .reader_debug_status(reader_debug_status_cpu),
        .writer_perf_outstanding_current(writer_perf_outstanding_current_cpu),
        .writer_perf_outstanding_max(writer_perf_outstanding_max_cpu),
        .writer_perf_aw_stall_cycles(writer_perf_aw_stall_cycles_cpu),
        .writer_perf_w_stall_cycles(writer_perf_w_stall_cycles_cpu),
        .writer_perf_b_stall_cycles(writer_perf_b_stall_cycles_cpu),
        .writer_perf_bursts_issued(writer_perf_bursts_issued_cpu),
        .writer_perf_bursts_completed(writer_perf_bursts_completed_cpu),
        .writer_perf_response_errors(writer_perf_response_errors_cpu)
    );

    // XPM CDC arrays are limited to 1024 bits. Keep the existing frame-status
    // snapshot separate from the 256-bit DMA performance snapshot.
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1),
        .WIDTH(32 + CHANNELS*96 + 128)
    ) u_status_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({manager_status, writer_frame_counts, drop_counts,
                 malformed_counts, reader_frame_count, underflow_count,
                 reader_active_base, reader_debug_status}),
        .dest_clk(control_axil.aclk),
        .dest_out({manager_status_cpu, writer_frame_counts_cpu,
                   drop_counts_cpu, malformed_counts_cpu,
                   reader_frame_count_cpu, underflow_count_cpu,
                   reader_active_base_cpu, reader_debug_status_cpu})
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(256)
    ) u_writer_perf_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({
                 {16'd0, writer_perf_outstanding_current},
                 {16'd0, writer_perf_outstanding_max},
                 writer_perf_aw_stall_cycles,
                 writer_perf_w_stall_cycles,
                 writer_perf_b_stall_cycles,
                 writer_perf_bursts_issued,
                 writer_perf_bursts_completed,
                 writer_perf_response_errors}),
        .dest_clk(control_axil.aclk),
        .dest_out({
                   writer_perf_outstanding_current_cpu,
                   writer_perf_outstanding_max_cpu,
                   writer_perf_aw_stall_cycles_cpu,
                   writer_perf_w_stall_cycles_cpu,
                   writer_perf_b_stall_cycles_cpu,
                   writer_perf_bursts_issued_cpu,
                   writer_perf_bursts_completed_cpu,
                   writer_perf_response_errors_cpu})
    );

    multi_channel_frame_manager #(
        .CHANNELS(CHANNELS)
    ) u_manager (
        .ui_clk(ddr_ui_clk), .ui_resetn(ddr_resetn && init_done),
        .cfg_request_toggle(cfg_request_toggle),
        .cfg_ack_toggle(cfg_ack_toggle),
        .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_display_channel(local_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .writer_acquire(writer_acquire),
        .writer_grant(writer_grant), .writer_drop(writer_drop),
        .writer_base(writer_base), .writer_done(frame_done),
        .writer_error(frame_error),
        .reader_acquire(reader_acquire), .reader_grant(reader_grant),
        .reader_base(reader_base), .reader_done(reader_done),
        .reader_bases(reader_bases),
        .reader_valid_mask(reader_valid_mask), .reader_mode(reader_mode),
        .reader_underflow(reader_underflow),
        .active_width(active_width), .active_height(active_height),
        .active_stride_bytes(active_stride_bytes),
        .writer_frame_counts(writer_frame_counts),
        .reader_frame_count(reader_frame_count),
        .drop_counts(drop_counts), .underflow_count(underflow_count),
        .status(manager_status)
    );

    multi_channel_video_dma #(
        .CHANNELS(CHANNELS),
        .FRAME_WIDTH(FRAME_WIDTH),
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
        .channel_active(), .fifo_levels(), .active_frame_ids(),
        .perf_outstanding_current(writer_perf_outstanding_current),
        .perf_outstanding_max(writer_perf_outstanding_max),
        .perf_aw_stall_cycles(writer_perf_aw_stall_cycles),
        .perf_w_stall_cycles(writer_perf_w_stall_cycles),
        .perf_b_stall_cycles(writer_perf_b_stall_cycles),
        .perf_bursts_issued(writer_perf_bursts_issued),
        .perf_bursts_completed(writer_perf_bursts_completed),
        .perf_response_errors(writer_perf_response_errors)
    );

    display_reader_subsystem #(
        .CHANNELS(CHANNELS),
        .SOURCE_WIDTH(FRAME_WIDTH),
        .SOURCE_HEIGHT(FRAME_HEIGHT),
        .SOURCE_STRIDE_BYTES(FRAME_STRIDE_BYTES),
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .READ_OUTSTANDING(READ_OUTSTANDING),
        .READ_DESCRIPTOR_DEPTH(READ_DESCRIPTOR_DEPTH)
    ) u_reader (
        .clk(ddr_ui_clk), .resetn(ddr_resetn && init_done),
        .buffer_acquire(reader_acquire), .buffer_grant(reader_grant),
        .buffer_base(reader_base), .buffer_bases(reader_bases),
        .buffer_valid_mask(reader_valid_mask), .buffer_mode(reader_mode),
        .buffer_done(reader_done),
        .frame_width(active_width), .frame_height(active_height),
        .frame_stride_bytes(active_stride_bytes), .m_axi(reader_axi),
        .m_axis(display_axis), .axi_error(reader_error),
        .fifo_underflow(reader_underflow),
        .debug_active_base(reader_active_base),
        .debug_status(reader_debug_status)
    );

    assign writer_error = |frame_error;
endmodule
