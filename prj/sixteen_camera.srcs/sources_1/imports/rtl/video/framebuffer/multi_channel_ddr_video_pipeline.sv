`timescale 1ns/1ps

// Sixteen-channel DDR capture/display pipeline. The physical inputs are
// normalized before this boundary; this block only sees DDR-clocked streams
// and therefore has no camera-clock CDC responsibility.
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
    output wire hdmi_capture_enable,
    input wire [31:0] hdmi_transport_frame_count,
    input wire [31:0] hdmi_transport_malformed_count,
    input wire [8*32-1:0] hdmi_channel_frame_counts,
    axi4_if.master writer_axi,
    axi4_if.master reader_axi,
    axi4_if.master preprocess_read_axi,
    axi4_if.master preprocess_write_axi,
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
    wire [31:0] preprocess_arena0_base_cpu;
    wire [31:0] preprocess_arena1_base_cpu;
    wire [31:0] preprocess_member_stride_cpu;
    wire [31:0] preprocess_member_bytes_cpu;
    wire        preprocess_format_640x480_cpu;
    wire [31:0] preprocess_arena0_base_ddr;
    wire [31:0] preprocess_arena1_base_ddr;
    wire [31:0] preprocess_member_stride_ddr;
    wire [31:0] preprocess_member_bytes_ddr;
    wire        preprocess_format_640x480_ddr;
    wire [CHANNEL_WIDTH-1:0] cfg_display_channel;
    wire cfg_display_mode;
    wire cfg_hdmi_capture_enable;
    wire hdmi_capture_enable_ddr;
    assign hdmi_capture_enable = hdmi_capture_enable_ddr;
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

    wire ai_snapshot_req_toggle_cpu;
    wire ai_snapshot_req_toggle_ddr;
    wire ai_snapshot_ack_toggle_ddr;
    wire ai_snapshot_ack_toggle_cpu;
    wire ai_release_req_toggle_cpu;
    wire ai_release_req_toggle_ddr;
    wire ai_release_ack_toggle_ddr;
    wire ai_release_ack_toggle_cpu;
    wire [CHANNELS-1:0] ai_release_mask_cpu;
    wire [CHANNELS-1:0] ai_release_mask_ddr;
    wire ai_meta_req_toggle_cpu;
    wire ai_meta_req_toggle_ddr;
    reg ai_meta_ack_toggle_ddr;
    wire ai_meta_ack_toggle_cpu;
    wire [CHANNEL_WIDTH-1:0] ai_meta_index_cpu;
    wire [CHANNEL_WIDTH-1:0] ai_meta_index_ddr;
    wire ai_snapshot_active_ddr;
    wire [CHANNELS-1:0] ai_snapshot_valid_mask_ddr;
    wire [CHANNELS-1:0] ai_snapshot_fresh_mask_ddr;
    wire [CHANNELS-1:0] ai_held_mask_ddr;
    wire [CHANNELS*32-1:0] ai_snapshot_addrs_ddr;
    wire [CHANNELS*64-1:0] ai_snapshot_frame_ids_ddr;
    wire [CHANNELS*64-1:0] ai_snapshot_timestamps_ddr;
    wire [CHANNELS*32-1:0] ai_snapshot_versions_ddr;
    wire [63:0] ai_snapshot_batch_id_ddr;
    wire [31:0] ai_snapshot_count_ddr;
    wire [31:0] ai_release_count_ddr;
    wire [31:0] ai_error_count_ddr;
    wire ai_snapshot_active_cpu;
    wire [CHANNELS-1:0] ai_snapshot_valid_mask_cpu;
    wire [CHANNELS-1:0] ai_snapshot_fresh_mask_cpu;
    wire [CHANNELS-1:0] ai_held_mask_cpu;
    reg [31:0] ai_meta_addr_ddr;
    reg [63:0] ai_meta_frame_id_ddr;
    reg [63:0] ai_meta_timestamp_ddr;
    reg [31:0] ai_meta_version_ddr;
    wire [31:0] ai_meta_addr_cpu;
    wire [63:0] ai_meta_frame_id_cpu;
    wire [63:0] ai_meta_timestamp_cpu;
    wire [31:0] ai_meta_version_cpu;
    reg ai_meta_req_seen_ddr;
    reg ai_meta_select_pending_ddr;
    reg ai_meta_ack_pending_ddr;
    wire [63:0] ai_snapshot_batch_id_cpu;
    wire [31:0] ai_snapshot_count_cpu;
    wire [31:0] ai_release_count_cpu;
    wire [31:0] ai_error_count_cpu;

    wire preprocess_start_req_toggle_cpu;
    wire preprocess_start_req_toggle_ddr;
    wire preprocess_start_ack_toggle_ddr;
    wire preprocess_start_ack_toggle_cpu;
    wire preprocess_recycle_req_toggle_cpu;
    wire preprocess_recycle_req_toggle_ddr;
    wire preprocess_recycle_ack_toggle_ddr;
    wire preprocess_recycle_ack_toggle_cpu;
    wire [1:0] preprocess_recycle_mask_cpu;
    wire [1:0] preprocess_recycle_mask_ddr;
    reg preprocess_start_seen_ddr;
    reg preprocess_recycle_seen_ddr;
    reg preprocess_start_pulse_ddr;
    reg preprocess_recycle_pulse_ddr;
    reg preprocess_start_ack_reg_ddr;
    reg preprocess_recycle_ack_reg_ddr;
    reg preprocess_start_pending_ddr;
    reg preprocess_recycle_pending_ddr;
    wire preprocess_command_done_ddr;
    wire preprocess_command_error_ddr;
    wire preprocess_busy_ddr;
    wire [1:0] preprocess_ready_mask_ddr;
    wire preprocess_active_arena_ddr;
    wire [4:0] preprocess_active_channel_ddr;
    wire [4:0] preprocess_completed_channels_ddr;
    wire [31:0] preprocess_active_tensor_base_ddr;
    wire [63:0] preprocess_arena0_batch_id_ddr;
    wire [63:0] preprocess_arena1_batch_id_ddr;
    wire [CHANNELS-1:0] preprocess_arena0_valid_mask_ddr;
    wire [CHANNELS-1:0] preprocess_arena1_valid_mask_ddr;
    wire [CHANNELS-1:0] preprocess_arena0_fresh_mask_ddr;
    wire [CHANNELS-1:0] preprocess_arena1_fresh_mask_ddr;
    wire [31:0] preprocess_batch_cycles_ddr;
    wire [31:0] preprocess_last_batch_cycles_ddr;
    wire [31:0] preprocess_last_read_beats_ddr;
    wire [31:0] preprocess_last_write_beats_ddr;
    wire [31:0] preprocess_start_count_ddr;
    wire [31:0] preprocess_complete_count_ddr;
    wire [31:0] preprocess_error_count_ddr;
    wire preprocess_busy_cpu;
    wire [1:0] preprocess_ready_mask_cpu;
    wire preprocess_active_arena_cpu;
    wire [4:0] preprocess_active_channel_cpu;
    wire [4:0] preprocess_completed_channels_cpu;
    wire [31:0] preprocess_active_tensor_base_cpu;
    wire [63:0] preprocess_arena0_batch_id_cpu;
    wire [63:0] preprocess_arena1_batch_id_cpu;
    wire [CHANNELS-1:0] preprocess_arena0_valid_mask_cpu;
    wire [CHANNELS-1:0] preprocess_arena1_valid_mask_cpu;
    wire [CHANNELS-1:0] preprocess_arena0_fresh_mask_cpu;
    wire [CHANNELS-1:0] preprocess_arena1_fresh_mask_cpu;
    wire [31:0] preprocess_last_batch_cycles_cpu;
    wire [31:0] preprocess_last_read_beats_cpu;
    wire [31:0] preprocess_last_write_beats_cpu;
    wire [31:0] preprocess_start_count_cpu;
    wire [31:0] preprocess_complete_count_cpu;
    wire [31:0] preprocess_error_count_cpu;
    wire overlay_commit_toggle_cpu;
    wire overlay_commit_toggle_ddr;
    reg overlay_commit_seen_ddr;
    reg overlay_commit_pulse_ddr;
    reg overlay_commit_ack_toggle_ddr;
    wire overlay_commit_ack_toggle_cpu;
    wire [3:0] overlay_stream_cpu;
    wire [3:0] overlay_stream_ddr;
    wire [3:0] overlay_count_cpu;
    wire [3:0] overlay_count_ddr;
    wire [511:0] overlay_boxes_cpu;
    wire [511:0] overlay_boxes_ddr;

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
    wire [31:0] hdmi_transport_frame_count_cpu;
    wire [31:0] hdmi_transport_malformed_count_cpu;
    wire [255:0] hdmi_channel_frame_counts_cpu;
    wire [255:0] hdmi_channel_overflow_counts_cpu =
        malformed_counts_cpu[8*32 +: 8*32];

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
        .preprocess_arena0_base(preprocess_arena0_base_cpu),
        .preprocess_arena1_base(preprocess_arena1_base_cpu),
        .preprocess_member_stride(preprocess_member_stride_cpu),
        .preprocess_member_bytes(preprocess_member_bytes_cpu),
        .preprocess_format_640x480(preprocess_format_640x480_cpu),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .cfg_hdmi_capture_enable(cfg_hdmi_capture_enable),
        .ai_snapshot_req_toggle(ai_snapshot_req_toggle_cpu),
        .ai_release_req_toggle(ai_release_req_toggle_cpu),
        .ai_release_mask(ai_release_mask_cpu),
        .ai_meta_req_toggle(ai_meta_req_toggle_cpu),
        .ai_meta_index(ai_meta_index_cpu),
        .ai_snapshot_ack_toggle(ai_snapshot_ack_toggle_cpu),
        .ai_release_ack_toggle(ai_release_ack_toggle_cpu),
        .ai_meta_ack_toggle(ai_meta_ack_toggle_cpu),
        .ai_snapshot_active(ai_snapshot_active_cpu),
        .ai_snapshot_valid_mask(ai_snapshot_valid_mask_cpu),
        .ai_snapshot_fresh_mask(ai_snapshot_fresh_mask_cpu),
        .ai_held_mask(ai_held_mask_cpu),
        .ai_meta_addr(ai_meta_addr_cpu),
        .ai_meta_frame_id(ai_meta_frame_id_cpu),
        .ai_meta_timestamp(ai_meta_timestamp_cpu),
        .ai_meta_version(ai_meta_version_cpu),
        .ai_snapshot_batch_id(ai_snapshot_batch_id_cpu),
        .ai_snapshot_count(ai_snapshot_count_cpu),
        .ai_release_count(ai_release_count_cpu),
        .ai_error_count(ai_error_count_cpu),
        .preprocess_start_req_toggle(preprocess_start_req_toggle_cpu),
        .preprocess_recycle_req_toggle(preprocess_recycle_req_toggle_cpu),
        .preprocess_recycle_mask(preprocess_recycle_mask_cpu),
        .preprocess_start_ack_toggle(preprocess_start_ack_toggle_cpu),
        .preprocess_recycle_ack_toggle(preprocess_recycle_ack_toggle_cpu),
        .preprocess_busy(preprocess_busy_cpu),
        .preprocess_ready_mask(preprocess_ready_mask_cpu),
        .preprocess_active_arena(preprocess_active_arena_cpu),
        .preprocess_active_channel(preprocess_active_channel_cpu),
        .preprocess_completed_channels(preprocess_completed_channels_cpu),
        .preprocess_active_tensor_base(preprocess_active_tensor_base_cpu),
        .preprocess_arena0_batch_id(preprocess_arena0_batch_id_cpu),
        .preprocess_arena1_batch_id(preprocess_arena1_batch_id_cpu),
        .preprocess_arena0_valid_mask(preprocess_arena0_valid_mask_cpu),
        .preprocess_arena1_valid_mask(preprocess_arena1_valid_mask_cpu),
        .preprocess_arena0_fresh_mask(preprocess_arena0_fresh_mask_cpu),
        .preprocess_arena1_fresh_mask(preprocess_arena1_fresh_mask_cpu),
        .preprocess_last_batch_cycles(preprocess_last_batch_cycles_cpu),
        .preprocess_last_read_beats(preprocess_last_read_beats_cpu),
        .preprocess_last_write_beats(preprocess_last_write_beats_cpu),
        .preprocess_start_count(preprocess_start_count_cpu),
        .preprocess_complete_count(preprocess_complete_count_cpu),
        .preprocess_error_count(preprocess_error_count_cpu),
        .overlay_commit_toggle(overlay_commit_toggle_cpu),
        .overlay_stream(overlay_stream_cpu),
        .overlay_count(overlay_count_cpu),
        .overlay_boxes(overlay_boxes_cpu),
        .overlay_commit_ack_toggle(overlay_commit_ack_toggle_cpu),
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
        .writer_perf_response_errors(writer_perf_response_errors_cpu),
        .hdmi_transport_frame_count(hdmi_transport_frame_count_cpu),
        .hdmi_transport_malformed_count(
            hdmi_transport_malformed_count_cpu),
        .hdmi_channel_frame_counts(hdmi_channel_frame_counts_cpu),
        .hdmi_channel_overflow_counts(hdmi_channel_overflow_counts_cpu)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_hdmi_enable_cdc (
        .src_clk(control_axil.aclk), .src_in(cfg_hdmi_capture_enable),
        .dest_clk(ddr_ui_clk), .dest_out(hdmi_capture_enable_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_snapshot_req_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_snapshot_req_toggle_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(ai_snapshot_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_snapshot_ack_cdc (
        .src_clk(ddr_ui_clk), .src_in(ai_snapshot_ack_toggle_ddr),
        .dest_clk(control_axil.aclk), .dest_out(ai_snapshot_ack_toggle_cpu)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_release_req_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_release_req_toggle_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(ai_release_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_release_ack_cdc (
        .src_clk(ddr_ui_clk), .src_in(ai_release_ack_toggle_ddr),
        .dest_clk(control_axil.aclk), .dest_out(ai_release_ack_toggle_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(129)
    ) u_preprocess_config_cdc (
        .src_clk(control_axil.aclk),
        .src_in({preprocess_arena0_base_cpu,
                 preprocess_arena1_base_cpu,
                 preprocess_member_stride_cpu,
                 preprocess_member_bytes_cpu,
                 preprocess_format_640x480_cpu}),
        .dest_clk(ddr_ui_clk),
        .dest_out({preprocess_arena0_base_ddr,
                   preprocess_arena1_base_ddr,
                   preprocess_member_stride_ddr,
                   preprocess_member_bytes_ddr,
                   preprocess_format_640x480_ddr})
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNELS)
    ) u_ai_release_mask_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_release_mask_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(ai_release_mask_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_meta_req_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_meta_req_toggle_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(ai_meta_req_toggle_ddr)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNEL_WIDTH)
    ) u_ai_meta_index_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_meta_index_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(ai_meta_index_ddr)
    );

    // Indexed metadata mailbox: only one 192-bit entry crosses clock domains,
    // instead of a timing-heavy 3072-bit copy of the complete Snapshot table.
    always @(posedge ddr_ui_clk) begin
        if (!ddr_resetn) begin
            ai_meta_ack_toggle_ddr <= 1'b0;
            ai_meta_req_seen_ddr <= 1'b0;
            ai_meta_select_pending_ddr <= 1'b0;
            ai_meta_ack_pending_ddr <= 1'b0;
            ai_meta_addr_ddr <= 32'd0;
            ai_meta_frame_id_ddr <= 64'd0;
            ai_meta_timestamp_ddr <= 64'd0;
            ai_meta_version_ddr <= 32'd0;
        end else begin
            if (ai_meta_ack_pending_ddr) begin
                ai_meta_ack_toggle_ddr <= ai_meta_req_seen_ddr;
                ai_meta_ack_pending_ddr <= 1'b0;
            end
            if (ai_meta_select_pending_ddr) begin
                ai_meta_addr_ddr <= ai_snapshot_addrs_ddr[
                    ai_meta_index_ddr*32 +: 32];
                ai_meta_frame_id_ddr <= ai_snapshot_frame_ids_ddr[
                    ai_meta_index_ddr*64 +: 64];
                ai_meta_timestamp_ddr <= ai_snapshot_timestamps_ddr[
                    ai_meta_index_ddr*64 +: 64];
                ai_meta_version_ddr <= ai_snapshot_versions_ddr[
                    ai_meta_index_ddr*32 +: 32];
                ai_meta_select_pending_ddr <= 1'b0;
                ai_meta_ack_pending_ddr <= 1'b1;
            end
            if ((ai_meta_req_toggle_ddr != ai_meta_req_seen_ddr) &&
                !ai_meta_select_pending_ddr && !ai_meta_ack_pending_ddr) begin
                ai_meta_req_seen_ddr <= ai_meta_req_toggle_ddr;
                ai_meta_select_pending_ddr <= 1'b1;
            end
        end
    end

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_meta_ack_cdc (
        .src_clk(ddr_ui_clk), .src_in(ai_meta_ack_toggle_ddr),
        .dest_clk(control_axil.aclk), .dest_out(ai_meta_ack_toggle_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(192)
    ) u_ai_meta_payload_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({ai_meta_version_ddr, ai_meta_timestamp_ddr,
                 ai_meta_frame_id_ddr, ai_meta_addr_ddr}),
        .dest_clk(control_axil.aclk),
        .dest_out({ai_meta_version_cpu, ai_meta_timestamp_cpu,
                   ai_meta_frame_id_cpu, ai_meta_addr_cpu})
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(209)
    ) u_ai_snapshot_status_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({ai_error_count_ddr, ai_release_count_ddr,
                 ai_snapshot_count_ddr, ai_snapshot_batch_id_ddr,
                 ai_held_mask_ddr, ai_snapshot_fresh_mask_ddr,
                 ai_snapshot_valid_mask_ddr, ai_snapshot_active_ddr}),
        .dest_clk(control_axil.aclk),
        .dest_out({ai_error_count_cpu, ai_release_count_cpu,
                   ai_snapshot_count_cpu, ai_snapshot_batch_id_cpu,
                   ai_held_mask_cpu, ai_snapshot_fresh_mask_cpu,
                   ai_snapshot_valid_mask_cpu, ai_snapshot_active_cpu})
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_preprocess_start_req_cdc (
        .src_clk(control_axil.aclk),
        .src_in(preprocess_start_req_toggle_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(preprocess_start_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_preprocess_start_ack_cdc (
        .src_clk(ddr_ui_clk), .src_in(preprocess_start_ack_toggle_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(preprocess_start_ack_toggle_cpu)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_preprocess_recycle_req_cdc (
        .src_clk(control_axil.aclk),
        .src_in(preprocess_recycle_req_toggle_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(preprocess_recycle_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_preprocess_recycle_ack_cdc (
        .src_clk(ddr_ui_clk), .src_in(preprocess_recycle_ack_toggle_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(preprocess_recycle_ack_toggle_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(2)
    ) u_preprocess_recycle_mask_cdc (
        .src_clk(control_axil.aclk),
        .src_in(preprocess_recycle_mask_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(preprocess_recycle_mask_ddr)
    );

    assign preprocess_start_ack_toggle_ddr = preprocess_start_ack_reg_ddr;
    assign preprocess_recycle_ack_toggle_ddr =
        preprocess_recycle_ack_reg_ddr;

    always @(posedge ddr_ui_clk) begin
        if (!ddr_resetn) begin
            preprocess_start_seen_ddr <= 1'b0;
            preprocess_recycle_seen_ddr <= 1'b0;
            preprocess_start_pulse_ddr <= 1'b0;
            preprocess_recycle_pulse_ddr <= 1'b0;
            preprocess_start_ack_reg_ddr <= 1'b0;
            preprocess_recycle_ack_reg_ddr <= 1'b0;
            preprocess_start_pending_ddr <= 1'b0;
            preprocess_recycle_pending_ddr <= 1'b0;
        end else begin
            preprocess_start_pulse_ddr <= 1'b0;
            preprocess_recycle_pulse_ddr <= 1'b0;
            if (preprocess_start_req_toggle_ddr !=
                preprocess_start_seen_ddr) begin
                preprocess_start_seen_ddr <= preprocess_start_req_toggle_ddr;
                preprocess_start_pulse_ddr <= 1'b1;
                preprocess_start_pending_ddr <= 1'b1;
            end
            if (preprocess_recycle_req_toggle_ddr !=
                preprocess_recycle_seen_ddr) begin
                preprocess_recycle_seen_ddr <=
                    preprocess_recycle_req_toggle_ddr;
                preprocess_recycle_pulse_ddr <= 1'b1;
                preprocess_recycle_pending_ddr <= 1'b1;
            end
            if (preprocess_command_done_ddr) begin
                if (preprocess_start_pending_ddr) begin
                    preprocess_start_ack_reg_ddr <=
                        preprocess_start_seen_ddr;
                    preprocess_start_pending_ddr <= 1'b0;
                end
                if (preprocess_recycle_pending_ddr) begin
                    preprocess_recycle_ack_reg_ddr <=
                        preprocess_recycle_seen_ddr;
                    preprocess_recycle_pending_ddr <= 1'b0;
                end
            end
        end
    end

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(366 + 4*CHANNELS)
    ) u_preprocess_status_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({preprocess_error_count_ddr,
                 preprocess_complete_count_ddr,
                 preprocess_start_count_ddr,
                 preprocess_last_write_beats_ddr,
                 preprocess_last_read_beats_ddr,
                 preprocess_last_batch_cycles_ddr,
                 preprocess_arena1_batch_id_ddr,
                 preprocess_arena0_batch_id_ddr,
                 preprocess_arena1_fresh_mask_ddr,
                 preprocess_arena0_fresh_mask_ddr,
                 preprocess_arena1_valid_mask_ddr,
                 preprocess_arena0_valid_mask_ddr,
                 preprocess_active_tensor_base_ddr,
                 preprocess_completed_channels_ddr,
                 preprocess_active_channel_ddr,
                 preprocess_active_arena_ddr,
                 preprocess_ready_mask_ddr,
                 preprocess_busy_ddr}),
        .dest_clk(control_axil.aclk),
        .dest_out({preprocess_error_count_cpu,
                   preprocess_complete_count_cpu,
                   preprocess_start_count_cpu,
                   preprocess_last_write_beats_cpu,
                   preprocess_last_read_beats_cpu,
                   preprocess_last_batch_cycles_cpu,
                   preprocess_arena1_batch_id_cpu,
                   preprocess_arena0_batch_id_cpu,
                   preprocess_arena1_fresh_mask_cpu,
                   preprocess_arena0_fresh_mask_cpu,
                   preprocess_arena1_valid_mask_cpu,
                   preprocess_arena0_valid_mask_cpu,
                   preprocess_active_tensor_base_cpu,
                   preprocess_completed_channels_cpu,
                   preprocess_active_channel_cpu,
                   preprocess_active_arena_cpu,
                   preprocess_ready_mask_cpu,
                   preprocess_busy_cpu})
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_overlay_commit_req_cdc (
        .src_clk(control_axil.aclk), .src_in(overlay_commit_toggle_cpu),
        .dest_clk(ddr_ui_clk), .dest_out(overlay_commit_toggle_ddr)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(520)
    ) u_overlay_payload_cdc (
        .src_clk(control_axil.aclk),
        .src_in({overlay_stream_cpu, overlay_count_cpu, overlay_boxes_cpu}),
        .dest_clk(ddr_ui_clk),
        .dest_out({overlay_stream_ddr, overlay_count_ddr,
                   overlay_boxes_ddr})
    );

    always @(posedge ddr_ui_clk) begin
        if (!ddr_resetn) begin
            overlay_commit_seen_ddr <= 1'b0;
            overlay_commit_pulse_ddr <= 1'b0;
            overlay_commit_ack_toggle_ddr <= 1'b0;
        end else begin
            overlay_commit_pulse_ddr <= 1'b0;
            if (overlay_commit_pulse_ddr)
                overlay_commit_ack_toggle_ddr <= overlay_commit_seen_ddr;
            if (overlay_commit_toggle_ddr != overlay_commit_seen_ddr) begin
                overlay_commit_seen_ddr <= overlay_commit_toggle_ddr;
                overlay_commit_pulse_ddr <= 1'b1;
            end
        end
    end

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_overlay_commit_ack_cdc (
        .src_clk(ddr_ui_clk), .src_in(overlay_commit_ack_toggle_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(overlay_commit_ack_toggle_cpu)
    );

    // XPM CDC arrays are limited to 1024 bits.  Keep the 16-channel counter
    // vectors in independent snapshots.
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1),
        .WIDTH(160)
    ) u_status_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({manager_status, reader_frame_count, underflow_count,
                 reader_active_base, reader_debug_status}),
        .dest_clk(control_axil.aclk),
        .dest_out({manager_status_cpu, reader_frame_count_cpu,
                   underflow_count_cpu,
                   reader_active_base_cpu, reader_debug_status_cpu})
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNELS*32)
    ) u_writer_count_cdc (
        .src_clk(ddr_ui_clk), .src_in(writer_frame_counts),
        .dest_clk(control_axil.aclk), .dest_out(writer_frame_counts_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNELS*32)
    ) u_drop_count_cdc (
        .src_clk(ddr_ui_clk), .src_in(drop_counts),
        .dest_clk(control_axil.aclk), .dest_out(drop_counts_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNELS*32)
    ) u_malformed_count_cdc (
        .src_clk(ddr_ui_clk), .src_in(malformed_counts),
        .dest_clk(control_axil.aclk), .dest_out(malformed_counts_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(320)
    ) u_hdmi_diag_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({hdmi_transport_frame_count,
                 hdmi_transport_malformed_count,
                 hdmi_channel_frame_counts}),
        .dest_clk(control_axil.aclk),
        .dest_out({hdmi_transport_frame_count_cpu,
                   hdmi_transport_malformed_count_cpu,
                   hdmi_channel_frame_counts_cpu})
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
        .ui_clk(ddr_ui_clk), .ui_resetn(ddr_resetn),
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
        .ai_snapshot_req_toggle(ai_snapshot_req_toggle_ddr),
        .ai_snapshot_ack_toggle(ai_snapshot_ack_toggle_ddr),
        .ai_release_req_toggle(ai_release_req_toggle_ddr),
        .ai_release_ack_toggle(ai_release_ack_toggle_ddr),
        .ai_release_mask(ai_release_mask_ddr),
        .ai_snapshot_active(ai_snapshot_active_ddr),
        .ai_snapshot_valid_mask(ai_snapshot_valid_mask_ddr),
        .ai_snapshot_fresh_mask(ai_snapshot_fresh_mask_ddr),
        .ai_held_mask(ai_held_mask_ddr),
        .ai_snapshot_addrs(ai_snapshot_addrs_ddr),
        .ai_snapshot_frame_ids(ai_snapshot_frame_ids_ddr),
        .ai_snapshot_timestamps(ai_snapshot_timestamps_ddr),
        .ai_snapshot_versions(ai_snapshot_versions_ddr),
        .ai_snapshot_batch_id(ai_snapshot_batch_id_ddr),
        .ai_snapshot_count(ai_snapshot_count_ddr),
        .ai_release_count(ai_release_count_ddr),
        .ai_error_count(ai_error_count_ddr),
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

    batch_preprocess_engine #(
        .CHANNELS(CHANNELS),
        .SRC_WIDTH(FRAME_WIDTH), .SRC_HEIGHT(FRAME_HEIGHT),
        .SRC_STRIDE_BYTES(FRAME_STRIDE_BYTES),
        .DST_WIDTH(416), .DST_HEIGHT(416),
        .MEMBER_BYTES(416 * 416 * 3),
        .ARENA0_BASE(32'h3000_0000),
        .ARENA1_BASE(32'h3100_0000)
    ) u_batch_preprocess (
        .clk(ddr_ui_clk), .resetn(ddr_resetn),
        .start(preprocess_start_pulse_ddr),
        .snapshot_active(ai_snapshot_active_ddr),
        .snapshot_valid_mask(ai_snapshot_valid_mask_ddr),
        .snapshot_fresh_mask(ai_snapshot_fresh_mask_ddr),
        .snapshot_addrs(ai_snapshot_addrs_ddr),
        .snapshot_batch_id(ai_snapshot_batch_id_ddr),
        .recycle(preprocess_recycle_pulse_ddr),
        .recycle_mask(preprocess_recycle_mask_ddr),
        .arena0_base_cfg(preprocess_arena0_base_ddr),
        .arena1_base_cfg(preprocess_arena1_base_ddr),
        .member_stride_cfg(preprocess_member_stride_ddr),
        .format_640x480_cfg(preprocess_format_640x480_ddr),
        .member_bytes_cfg(preprocess_member_bytes_ddr),
        .command_done(preprocess_command_done_ddr),
        .command_error(preprocess_command_error_ddr),
        .busy(preprocess_busy_ddr),
        .ready_mask(preprocess_ready_mask_ddr),
        .active_arena(preprocess_active_arena_ddr),
        .active_channel(preprocess_active_channel_ddr),
        .completed_channels(preprocess_completed_channels_ddr),
        .active_tensor_base(preprocess_active_tensor_base_ddr),
        .arena0_batch_id(preprocess_arena0_batch_id_ddr),
        .arena1_batch_id(preprocess_arena1_batch_id_ddr),
        .arena0_valid_mask(preprocess_arena0_valid_mask_ddr),
        .arena1_valid_mask(preprocess_arena1_valid_mask_ddr),
        .arena0_fresh_mask(preprocess_arena0_fresh_mask_ddr),
        .arena1_fresh_mask(preprocess_arena1_fresh_mask_ddr),
        .batch_cycles(preprocess_batch_cycles_ddr),
        .last_batch_cycles(preprocess_last_batch_cycles_ddr),
        .last_read_beats(preprocess_last_read_beats_ddr),
        .last_write_beats(preprocess_last_write_beats_ddr),
        .start_count(preprocess_start_count_ddr),
        .complete_count(preprocess_complete_count_ddr),
        .error_count(preprocess_error_count_ddr),
        .m_read_axi(preprocess_read_axi),
        .m_write_axi(preprocess_write_axi)
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
        .clk(ddr_ui_clk), .resetn(ddr_resetn),
        .buffer_acquire(reader_acquire), .buffer_grant(reader_grant),
        .buffer_base(reader_base), .buffer_bases(reader_bases),
        .buffer_valid_mask(reader_valid_mask), .buffer_mode(reader_mode),
        .buffer_done(reader_done),
        .frame_width(active_width), .frame_height(active_height),
        .frame_stride_bytes(active_stride_bytes), .m_axi(reader_axi),
        .overlay_commit(overlay_commit_pulse_ddr),
        .overlay_stream(overlay_stream_ddr),
        .overlay_count(overlay_count_ddr),
        .overlay_boxes(overlay_boxes_ddr),
        .m_axis(display_axis), .axi_error(reader_error),
        .fifo_underflow(reader_underflow),
        .debug_active_base(reader_active_base),
        .debug_status(reader_debug_status)
    );

    assign writer_error = |frame_error;
    wire unused_preprocess_command = &{1'b0, preprocess_command_done_ddr,
        preprocess_command_error_ddr, preprocess_batch_cycles_ddr};
endmodule
