`timescale 1ns/1ps

// Sixteen-channel capture/display pipeline. In P4 its frame ownership,
// writer/reader planning, overlay and preprocess engines all run in the
// 150 MHz video domain. The parent owns the queued AXI boundary to MIG UI.
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
    input wire video_clk,
    input wire video_resetn,
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
    wire tensor_sidecar_req_toggle_cpu;
    wire tensor_sidecar_req_toggle_ddr;
    reg tensor_sidecar_req_seen_ddr;
    reg tensor_sidecar_start_ddr;
    reg tensor_sidecar_ack_toggle_ddr;
    wire tensor_sidecar_ack_toggle_cpu;
    wire [3:0] tensor_sidecar_channel_cpu;
    wire [3:0] tensor_sidecar_channel_ddr;
    wire [31:0] tensor_sidecar_addr_cpu;
    wire [31:0] tensor_sidecar_addr_ddr;
    wire tensor_sidecar_busy_ddr, tensor_sidecar_completed_ddr;
    wire tensor_sidecar_error_ddr;
    wire [3:0] tensor_sidecar_done_channel_ddr;
    wire [31:0] tensor_sidecar_frame_id_ddr;
    wire [31:0] tensor_sidecar_bytes_ddr;
    wire [31:0] tensor_sidecar_overflows_ddr;
    wire tensor_sidecar_busy_cpu, tensor_sidecar_completed_cpu;
    wire tensor_sidecar_error_cpu;
    wire [3:0] tensor_sidecar_done_channel_cpu;
    wire [31:0] tensor_sidecar_frame_id_cpu;
    wire [31:0] tensor_sidecar_bytes_cpu;
    wire [31:0] tensor_sidecar_overflows_cpu;
    wire tensor_production_enable_cpu, tensor_production_enable_ddr;
    wire tensor_production_release_toggle_cpu;
    wire tensor_production_release_toggle_ddr;
    reg tensor_production_release_seen_ddr;
    reg tensor_production_release_pulse_ddr;
    reg tensor_production_release_ack_ddr;
    wire tensor_production_release_ack_cpu;
    wire [31:0] tensor_production_release_mask_cpu;
    wire [31:0] tensor_production_release_mask_ddr;
    wire [31:0] tensor_production_ready_ddr, tensor_production_ready_cpu;
    wire [31:0] tensor_production_writing_ddr, tensor_production_writing_cpu;
    wire [31:0] tensor_production_error_ddr, tensor_production_error_cpu;
    wire tensor_production_quiescent_ddr, tensor_production_quiescent_cpu;
    wire [32*32-1:0] tensor_production_frames_ddr, tensor_production_frames_cpu;
    wire [32*32-1:0] tensor_production_bytes_ddr, tensor_production_bytes_cpu;
    wire [16*32-1:0] tensor_production_no_slot_ddr, tensor_production_no_slot_cpu;
    wire [16*32-1:0] tensor_production_missed_ddr, tensor_production_missed_cpu;
    wire [16*32-1:0] tensor_production_overflows_ddr, tensor_production_overflows_cpu;
    wire [CHANNELS*48-1:0] tensor_tap_data;
    wire [CHANNELS-1:0] tensor_tap_accept;
    wire [CHANNELS-1:0] tensor_tap_sof, tensor_tap_eol;
    wire [CHANNELS-1:0] tensor_tap_eof, tensor_tap_error;
    wire [CHANNELS*32-1:0] tensor_tap_frame_id;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        tensor_sidecar_write_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        tensor_production_write_axi();
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
    wire [CHANNELS*32-1:0] writer_source_frame_ids;
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
    wire [CHANNELS*32-1:0] ai_snapshot_source_frame_ids_ddr;
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
    reg [31:0] ai_meta_source_frame_id_ddr;
    reg [63:0] ai_meta_timestamp_ddr;
    reg [31:0] ai_meta_version_ddr;
    wire [31:0] ai_meta_addr_cpu;
    wire [63:0] ai_meta_frame_id_cpu;
    wire [31:0] ai_meta_source_frame_id_cpu;
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
    wire [1023:0] overlay_labels_cpu;
    wire [1023:0] overlay_labels_ddr;

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
        .tensor_sidecar_req_toggle(tensor_sidecar_req_toggle_cpu),
        .tensor_sidecar_channel(tensor_sidecar_channel_cpu),
        .tensor_sidecar_addr(tensor_sidecar_addr_cpu),
        .tensor_sidecar_ack_toggle(tensor_sidecar_ack_toggle_cpu),
        .tensor_sidecar_busy(tensor_sidecar_busy_cpu),
        .tensor_sidecar_completed(tensor_sidecar_completed_cpu),
        .tensor_sidecar_error(tensor_sidecar_error_cpu),
        .tensor_sidecar_done_channel(tensor_sidecar_done_channel_cpu),
        .tensor_sidecar_frame_id(tensor_sidecar_frame_id_cpu),
        .tensor_sidecar_bytes(tensor_sidecar_bytes_cpu),
        .tensor_sidecar_overflows(tensor_sidecar_overflows_cpu),
        .tensor_production_enable(tensor_production_enable_cpu),
        .tensor_production_release_toggle(
            tensor_production_release_toggle_cpu),
        .tensor_production_release_mask(
            tensor_production_release_mask_cpu),
        .tensor_production_release_ack(tensor_production_release_ack_cpu),
        .tensor_production_ready_mask(tensor_production_ready_cpu),
        .tensor_production_writing_mask(tensor_production_writing_cpu),
        .tensor_production_error_mask(tensor_production_error_cpu),
        .tensor_production_quiescent(tensor_production_quiescent_cpu),
        .tensor_production_frame_ids(tensor_production_frames_cpu),
        .tensor_production_byte_counts(tensor_production_bytes_cpu),
        .tensor_production_no_slot_counts(tensor_production_no_slot_cpu),
        .tensor_production_missed_counts(tensor_production_missed_cpu),
        .tensor_production_overflow_counts(tensor_production_overflows_cpu),
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
        .ai_meta_source_frame_id(ai_meta_source_frame_id_cpu),
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
        .overlay_labels(overlay_labels_cpu),
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
        .dest_clk(video_clk), .dest_out(hdmi_capture_enable_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_tensor_sidecar_req_cdc (
        .src_clk(control_axil.aclk),
        .src_in(tensor_sidecar_req_toggle_cpu),
        .dest_clk(video_clk), .dest_out(tensor_sidecar_req_toggle_ddr)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(36)
    ) u_tensor_sidecar_command_cdc (
        .src_clk(control_axil.aclk),
        .src_in({tensor_sidecar_channel_cpu, tensor_sidecar_addr_cpu}),
        .dest_clk(video_clk),
        .dest_out({tensor_sidecar_channel_ddr, tensor_sidecar_addr_ddr})
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_tensor_sidecar_ack_cdc (
        .src_clk(video_clk), .src_in(tensor_sidecar_ack_toggle_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(tensor_sidecar_ack_toggle_cpu)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(103)
    ) u_tensor_sidecar_status_cdc (
        .src_clk(video_clk),
        .src_in({tensor_sidecar_busy_ddr, tensor_sidecar_completed_ddr,
                 tensor_sidecar_error_ddr, tensor_sidecar_done_channel_ddr,
                 tensor_sidecar_frame_id_ddr, tensor_sidecar_bytes_ddr,
                 tensor_sidecar_overflows_ddr}),
        .dest_clk(control_axil.aclk),
        .dest_out({tensor_sidecar_busy_cpu, tensor_sidecar_completed_cpu,
                   tensor_sidecar_error_cpu, tensor_sidecar_done_channel_cpu,
                   tensor_sidecar_frame_id_cpu, tensor_sidecar_bytes_cpu,
                   tensor_sidecar_overflows_cpu})
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_tensor_production_enable_cdc (
        .src_clk(control_axil.aclk), .src_in(tensor_production_enable_cpu),
        .dest_clk(video_clk), .dest_out(tensor_production_enable_ddr)
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_tensor_production_release_cdc (
        .src_clk(control_axil.aclk),
        .src_in(tensor_production_release_toggle_cpu),
        .dest_clk(video_clk),
        .dest_out(tensor_production_release_toggle_ddr)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(32)
    ) u_tensor_production_release_mask_cdc (
        .src_clk(control_axil.aclk),
        .src_in(tensor_production_release_mask_cpu),
        .dest_clk(video_clk), .dest_out(tensor_production_release_mask_ddr)
    );
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_tensor_production_release_ack_cdc (
        .src_clk(video_clk), .src_in(tensor_production_release_ack_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(tensor_production_release_ack_cpu)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(96)
    ) u_tensor_production_flags_cdc (
        .src_clk(video_clk),
        .src_in({tensor_production_ready_ddr,
                 tensor_production_writing_ddr,
                 tensor_production_error_ddr}),
        .dest_clk(control_axil.aclk),
        .dest_out({tensor_production_ready_cpu,
                   tensor_production_writing_cpu,
                   tensor_production_error_cpu})
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(1024)
    ) u_tensor_production_frame_cdc (
        .src_clk(video_clk), .src_in(tensor_production_frames_ddr),
        .dest_clk(control_axil.aclk), .dest_out(tensor_production_frames_cpu)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(1024)
    ) u_tensor_production_bytes_cdc (
        .src_clk(video_clk), .src_in(tensor_production_bytes_ddr),
        .dest_clk(control_axil.aclk), .dest_out(tensor_production_bytes_cpu)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(512)
    ) u_tensor_production_no_slot_cdc (
        .src_clk(video_clk), .src_in(tensor_production_no_slot_ddr),
        .dest_clk(control_axil.aclk), .dest_out(tensor_production_no_slot_cpu)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(512)
    ) u_tensor_production_missed_cdc (
        .src_clk(video_clk), .src_in(tensor_production_missed_ddr),
        .dest_clk(control_axil.aclk), .dest_out(tensor_production_missed_cpu)
    );
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(512)
    ) u_tensor_production_overflow_cdc (
        .src_clk(video_clk), .src_in(tensor_production_overflows_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(tensor_production_overflows_cpu)
    );
    assign tensor_production_quiescent_ddr =
        !tensor_production_enable_ddr &&
        tensor_production_writing_ddr == 0 &&
        tensor_production_ready_ddr == 0;
    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_tensor_production_quiescent_cdc (
        .src_clk(video_clk), .src_in(tensor_production_quiescent_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(tensor_production_quiescent_cpu)
    );
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            tensor_production_release_seen_ddr <= 0;
            tensor_production_release_pulse_ddr <= 0;
            tensor_production_release_ack_ddr <= 0;
        end else begin
            tensor_production_release_pulse_ddr <= 0;
            if (tensor_production_release_seen_ddr !=
                tensor_production_release_toggle_ddr) begin
                tensor_production_release_seen_ddr <=
                    tensor_production_release_toggle_ddr;
                tensor_production_release_ack_ddr <=
                    tensor_production_release_toggle_ddr;
                tensor_production_release_pulse_ddr <= 1;
            end
        end
    end
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            tensor_sidecar_req_seen_ddr <= 0;
            tensor_sidecar_start_ddr <= 0;
            tensor_sidecar_ack_toggle_ddr <= 0;
        end else begin
            tensor_sidecar_start_ddr <= 0;
            if (tensor_sidecar_req_seen_ddr !=
                tensor_sidecar_req_toggle_ddr) begin
                tensor_sidecar_req_seen_ddr <=
                    tensor_sidecar_req_toggle_ddr;
                tensor_sidecar_ack_toggle_ddr <=
                    tensor_sidecar_req_toggle_ddr;
                if (!tensor_sidecar_busy_ddr)
                    tensor_sidecar_start_ddr <= 1;
            end
        end
    end

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_snapshot_req_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_snapshot_req_toggle_cpu),
        .dest_clk(video_clk), .dest_out(ai_snapshot_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_snapshot_ack_cdc (
        .src_clk(video_clk), .src_in(ai_snapshot_ack_toggle_ddr),
        .dest_clk(control_axil.aclk), .dest_out(ai_snapshot_ack_toggle_cpu)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_release_req_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_release_req_toggle_cpu),
        .dest_clk(video_clk), .dest_out(ai_release_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_release_ack_cdc (
        .src_clk(video_clk), .src_in(ai_release_ack_toggle_ddr),
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
        .dest_clk(video_clk),
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
        .dest_clk(video_clk), .dest_out(ai_release_mask_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_ai_meta_req_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_meta_req_toggle_cpu),
        .dest_clk(video_clk), .dest_out(ai_meta_req_toggle_ddr)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNEL_WIDTH)
    ) u_ai_meta_index_cdc (
        .src_clk(control_axil.aclk), .src_in(ai_meta_index_cpu),
        .dest_clk(video_clk), .dest_out(ai_meta_index_ddr)
    );

    // Indexed metadata mailbox: only one entry crosses clock domains,
    // instead of a timing-heavy 3072-bit copy of the complete Snapshot table.
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            ai_meta_ack_toggle_ddr <= 1'b0;
            ai_meta_req_seen_ddr <= 1'b0;
            ai_meta_select_pending_ddr <= 1'b0;
            ai_meta_ack_pending_ddr <= 1'b0;
            ai_meta_addr_ddr <= 32'd0;
            ai_meta_frame_id_ddr <= 64'd0;
            ai_meta_source_frame_id_ddr <= 32'd0;
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
                ai_meta_source_frame_id_ddr <=
                    ai_snapshot_source_frame_ids_ddr[
                        ai_meta_index_ddr*32 +: 32];
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
        .src_clk(video_clk), .src_in(ai_meta_ack_toggle_ddr),
        .dest_clk(control_axil.aclk), .dest_out(ai_meta_ack_toggle_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(224)
    ) u_ai_meta_payload_cdc (
        .src_clk(video_clk),
        .src_in({ai_meta_source_frame_id_ddr, ai_meta_version_ddr,
                 ai_meta_timestamp_ddr,
                 ai_meta_frame_id_ddr, ai_meta_addr_ddr}),
        .dest_clk(control_axil.aclk),
        .dest_out({ai_meta_source_frame_id_cpu, ai_meta_version_cpu,
                   ai_meta_timestamp_cpu,
                   ai_meta_frame_id_cpu, ai_meta_addr_cpu})
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(209)
    ) u_ai_snapshot_status_cdc (
        .src_clk(video_clk),
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
        .dest_clk(video_clk), .dest_out(preprocess_start_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_preprocess_start_ack_cdc (
        .src_clk(video_clk), .src_in(preprocess_start_ack_toggle_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(preprocess_start_ack_toggle_cpu)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_preprocess_recycle_req_cdc (
        .src_clk(control_axil.aclk),
        .src_in(preprocess_recycle_req_toggle_cpu),
        .dest_clk(video_clk), .dest_out(preprocess_recycle_req_toggle_ddr)
    );

    xpm_cdc_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1)
    ) u_preprocess_recycle_ack_cdc (
        .src_clk(video_clk), .src_in(preprocess_recycle_ack_toggle_ddr),
        .dest_clk(control_axil.aclk),
        .dest_out(preprocess_recycle_ack_toggle_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(2)
    ) u_preprocess_recycle_mask_cdc (
        .src_clk(control_axil.aclk),
        .src_in(preprocess_recycle_mask_cpu),
        .dest_clk(video_clk), .dest_out(preprocess_recycle_mask_ddr)
    );

    assign preprocess_start_ack_toggle_ddr = preprocess_start_ack_reg_ddr;
    assign preprocess_recycle_ack_toggle_ddr =
        preprocess_recycle_ack_reg_ddr;

    always @(posedge video_clk) begin
        if (!video_resetn) begin
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
        .src_clk(video_clk),
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
        .dest_clk(video_clk), .dest_out(overlay_commit_toggle_ddr)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(520)
    ) u_overlay_payload_cdc (
        .src_clk(control_axil.aclk),
        .src_in({overlay_stream_cpu, overlay_count_cpu, overlay_boxes_cpu}),
        .dest_clk(video_clk),
        .dest_out({overlay_stream_ddr, overlay_count_ddr,
                   overlay_boxes_ddr})
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(1024)
    ) u_overlay_labels_cdc (
        .src_clk(control_axil.aclk), .src_in(overlay_labels_cpu),
        .dest_clk(video_clk), .dest_out(overlay_labels_ddr)
    );

    always @(posedge video_clk) begin
        if (!video_resetn) begin
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
        .src_clk(video_clk), .src_in(overlay_commit_ack_toggle_ddr),
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
        .src_clk(video_clk),
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
        .src_clk(video_clk), .src_in(writer_frame_counts),
        .dest_clk(control_axil.aclk), .dest_out(writer_frame_counts_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNELS*32)
    ) u_drop_count_cdc (
        .src_clk(video_clk), .src_in(drop_counts),
        .dest_clk(control_axil.aclk), .dest_out(drop_counts_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(CHANNELS*32)
    ) u_malformed_count_cdc (
        .src_clk(video_clk), .src_in(malformed_counts),
        .dest_clk(control_axil.aclk), .dest_out(malformed_counts_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(320)
    ) u_hdmi_diag_cdc (
        .src_clk(video_clk),
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
        .src_clk(video_clk),
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
        .ui_clk(video_clk), .ui_resetn(video_resetn),
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
        .writer_source_frame_ids(writer_source_frame_ids),
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
        .ai_snapshot_source_frame_ids(ai_snapshot_source_frame_ids_ddr),
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
        .channel_active(), .fifo_levels(),
        .active_frame_ids(writer_source_frame_ids),
        .perf_outstanding_current(writer_perf_outstanding_current),
        .perf_outstanding_max(writer_perf_outstanding_max),
        .perf_aw_stall_cycles(writer_perf_aw_stall_cycles),
        .perf_w_stall_cycles(writer_perf_w_stall_cycles),
        .perf_b_stall_cycles(writer_perf_b_stall_cycles),
        .perf_bursts_issued(writer_perf_bursts_issued),
        .perf_bursts_completed(writer_perf_bursts_completed),
        .perf_response_errors(writer_perf_response_errors)
    );

    // The batch DDR-read preprocessor is no longer part of the live design.
    // Keep its old CSR address window inert so existing register offsets stay
    // stable while the streaming tensor writer owns the input arenas.
    assign preprocess_command_done_ddr = preprocess_start_pulse_ddr;
    assign preprocess_command_error_ddr = preprocess_start_pulse_ddr;
    assign preprocess_busy_ddr = 1'b0;
    assign preprocess_ready_mask_ddr = 2'b00;
    assign preprocess_active_arena_ddr = 1'b0;
    assign preprocess_active_channel_ddr = 5'd0;
    assign preprocess_completed_channels_ddr = 5'd0;
    assign preprocess_active_tensor_base_ddr = 32'd0;
    assign preprocess_arena0_batch_id_ddr = 64'd0;
    assign preprocess_arena1_batch_id_ddr = 64'd0;
    assign preprocess_arena0_valid_mask_ddr = {CHANNELS{1'b0}};
    assign preprocess_arena1_valid_mask_ddr = {CHANNELS{1'b0}};
    assign preprocess_arena0_fresh_mask_ddr = {CHANNELS{1'b0}};
    assign preprocess_arena1_fresh_mask_ddr = {CHANNELS{1'b0}};
    assign preprocess_batch_cycles_ddr = 32'd0;
    assign preprocess_last_batch_cycles_ddr = 32'd0;
    assign preprocess_last_read_beats_ddr = 32'd0;
    assign preprocess_last_write_beats_ddr = 32'd0;
    assign preprocess_start_count_ddr = 32'd0;
    assign preprocess_complete_count_ddr = 32'd0;
    assign preprocess_error_count_ddr = 32'd0;
    assign preprocess_read_axi.aclk = video_clk;
    assign preprocess_read_axi.aresetn = video_resetn;
    assign preprocess_read_axi.awid = 3'd0;
    assign preprocess_read_axi.awaddr = 32'd0;
    assign preprocess_read_axi.awlen = 8'd0;
    assign preprocess_read_axi.awsize = 3'd0;
    assign preprocess_read_axi.awburst = 2'd0;
    assign preprocess_read_axi.awlock = 1'b0;
    assign preprocess_read_axi.awcache = 4'd0;
    assign preprocess_read_axi.awprot = 3'd0;
    assign preprocess_read_axi.awqos = 4'd0;
    assign preprocess_read_axi.awvalid = 1'b0;
    assign preprocess_read_axi.wdata = 256'd0;
    assign preprocess_read_axi.wstrb = 32'd0;
    assign preprocess_read_axi.wlast = 1'b0;
    assign preprocess_read_axi.wvalid = 1'b0;
    assign preprocess_read_axi.bready = 1'b0;
    assign preprocess_read_axi.arid = 3'd0;
    assign preprocess_read_axi.araddr = 32'd0;
    assign preprocess_read_axi.arlen = 8'd0;
    assign preprocess_read_axi.arsize = 3'd0;
    assign preprocess_read_axi.arburst = 2'd0;
    assign preprocess_read_axi.arlock = 1'b0;
    assign preprocess_read_axi.arcache = 4'd0;
    assign preprocess_read_axi.arprot = 3'd0;
    assign preprocess_read_axi.arqos = 4'd0;
    assign preprocess_read_axi.arvalid = 1'b0;
    assign preprocess_read_axi.rready = 1'b0;

    for (genvar tensor_ch = 0; tensor_ch < CHANNELS; tensor_ch++) begin : g_tensor_tap
        assign tensor_tap_data[tensor_ch*48 +: 48] =
            capture_channels[tensor_ch].data;
        assign tensor_tap_accept[tensor_ch] =
            capture_channels[tensor_ch].valid &&
            capture_channels[tensor_ch].ready;
        assign tensor_tap_sof[tensor_ch] = capture_channels[tensor_ch].sof;
        assign tensor_tap_eol[tensor_ch] = capture_channels[tensor_ch].eol;
        assign tensor_tap_eof[tensor_ch] = capture_channels[tensor_ch].eof;
        assign tensor_tap_frame_id[tensor_ch*32 +: 32] =
            capture_channels[tensor_ch].frame_id;
        assign tensor_tap_error[tensor_ch] =
            capture_channels[tensor_ch].error;
    end

    yolov5nu_tensor_capture_sidecar #(
        .CHANNELS(CHANNELS), .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT)
    ) u_tensor_sidecar (
        .clk(video_clk), .resetn(video_resetn),
        .command_start(tensor_sidecar_start_ddr), .cancel(1'b0),
        .command_channel(tensor_sidecar_channel_ddr),
        .command_addr(tensor_sidecar_addr_ddr),
        .tap_data(tensor_tap_data),
        .tap_accept(tensor_tap_accept),
        .tap_sof(tensor_tap_sof), .tap_eol(tensor_tap_eol),
        .tap_eof(tensor_tap_eof),
        .tap_frame_id(tensor_tap_frame_id),
        .tap_error(tensor_tap_error),
        .busy(tensor_sidecar_busy_ddr), .ready_for_frame(),
        .completed(tensor_sidecar_completed_ddr),
        .completion_error(tensor_sidecar_error_ddr),
        .completion_channel(tensor_sidecar_done_channel_ddr),
        .completion_frame_id(tensor_sidecar_frame_id_ddr),
        .completion_bytes(tensor_sidecar_bytes_ddr),
        .overflow_count(tensor_sidecar_overflows_ddr),
        .m_axi(tensor_sidecar_write_axi)
    );

    yolov5nu_tensor_slot_ingest u_tensor_production (
        .clk(video_clk), .resetn(video_resetn),
        .enable(tensor_production_enable_ddr),
        .release_pulse(tensor_production_release_pulse_ddr),
        .release_mask(tensor_production_release_mask_ddr),
        .tap_data(tensor_tap_data), .tap_accept(tensor_tap_accept),
        .tap_sof(tensor_tap_sof), .tap_eol(tensor_tap_eol),
        .tap_eof(tensor_tap_eof),
        .tap_frame_id(tensor_tap_frame_id),
        .tap_error(tensor_tap_error),
        .ready_mask(tensor_production_ready_ddr),
        .writing_mask(tensor_production_writing_ddr),
        .error_mask(tensor_production_error_ddr),
        .slot_frame_ids(tensor_production_frames_ddr),
        .slot_byte_counts(tensor_production_bytes_ddr),
        .no_slot_counts(tensor_production_no_slot_ddr),
        .missed_frame_counts(tensor_production_missed_ddr),
        .overflow_counts(tensor_production_overflows_ddr),
        .m_axi(tensor_production_write_axi)
    );

    axi4_write_arbiter2 u_tensor_production_arbiter (
        .clk(video_clk), .resetn(video_resetn),
        .s0_axi(tensor_sidecar_write_axi),
        .s1_axi(tensor_production_write_axi),
        .m_axi(preprocess_write_axi)
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
        .clk(video_clk), .resetn(video_resetn),
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
        .overlay_labels(overlay_labels_ddr),
        .m_axis(display_axis), .axi_error(reader_error),
        .fifo_underflow(reader_underflow),
        .debug_active_base(reader_active_base),
        .debug_status(reader_debug_status)
    );

    assign writer_error = |frame_error;
    wire unused_preprocess_command = &{1'b0, preprocess_command_done_ddr,
        preprocess_command_error_ddr, preprocess_batch_cycles_ddr};
endmodule
