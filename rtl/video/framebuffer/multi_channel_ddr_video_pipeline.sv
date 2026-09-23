`timescale 1ns/1ps

// Integration shell for the 150 MHz video data plane. CPU register handling,
// command CDC and telemetry CDC are isolated in video_control_bridge.
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
    axi4_if.master tensor_write_axi,
    axis_video_if.source display_axis,
    output wire writer_error,
    output wire reader_error,
    output wire reader_underflow
);
    localparam integer CHANNEL_WIDTH = CHANNELS <= 1 ? 1 : $clog2(CHANNELS);

    wire cfg_request_toggle, cfg_ack_toggle, cfg_enable;
    wire [31:0] cfg_width, cfg_height, cfg_stride_bytes;
    wire [31:0] cfg_buffers_per_channel, cfg_buffer_stride_bytes;
    wire [CHANNELS*32-1:0] cfg_channel_bases;
    wire [CHANNEL_WIDTH-1:0] cfg_display_channel;
    wire [CHANNEL_WIDTH-1:0] local_display_channel =
        cfg_display_channel - GLOBAL_CHANNEL_BASE;
    wire cfg_display_mode, cfg_hdmi_capture_enable;
    assign hdmi_capture_enable = cfg_hdmi_capture_enable;

    wire tensor_production_enable;
    wire [15:0] tensor_production_admission_mask;
    wire [4:0] tensor_production_admission_limit;
    wire tensor_production_release_pulse;
    wire [31:0] tensor_production_release_mask;
    wire [31:0] tensor_production_ready, tensor_production_writing;
    wire [31:0] tensor_production_error;
    wire tensor_production_quiescent = !tensor_production_enable &&
        tensor_production_writing == 0 && tensor_production_ready == 0;
    wire [32*32-1:0] tensor_production_frames;
    wire [32*64-1:0] tensor_production_timestamps;
    wire [32*32-1:0] tensor_production_versions;
    wire [32*8-1:0] tensor_production_error_codes;
    wire [32*32-1:0] tensor_production_bytes;
    wire [CHANNELS*32-1:0] tensor_production_no_slot;
    wire [CHANNELS*32-1:0] tensor_production_missed;
    wire [CHANNELS*32-1:0] tensor_production_admission_skip;
    wire [CHANNELS*32-1:0] tensor_production_overflows;
    wire [15:0] tensor_dma_outstanding, tensor_dma_outstanding_max;
    wire [31:0] tensor_dma_starvation, tensor_dma_aw_stall;
    wire [31:0] tensor_dma_w_stall, tensor_dma_w_transfer;
    wire [31:0] tensor_dma_b_wait, tensor_dma_bursts;
    wire [31:0] tensor_dma_completed, tensor_dma_resp_errors;

    wire overlay_commit;
    wire [3:0] overlay_stream, overlay_count;
    wire [511:0] overlay_boxes;
    wire [1023:0] overlay_labels;

    wire [31:0] active_width, active_height, active_stride_bytes;
    wire [CHANNELS*32-1:0] writer_frame_counts, drop_counts;
    wire [31:0] reader_frame_count, underflow_count, manager_status;
    wire reader_acquire, reader_grant, reader_done, reader_mode;
    wire [31:0] reader_base, reader_active_base, reader_debug_status;
    wire [CHANNELS*32-1:0] reader_bases;
    wire [CHANNELS-1:0] reader_valid_mask;
    wire [15:0] writer_perf_outstanding_current;
    wire [15:0] writer_perf_outstanding_max;
    wire [31:0] writer_perf_aw_stall_cycles, writer_perf_w_stall_cycles;
    wire [31:0] writer_perf_b_stall_cycles, writer_perf_bursts_issued;
    wire [31:0] writer_perf_bursts_completed, writer_perf_response_errors;

    wire [CHANNELS*48-1:0] tensor_tap_data;
    wire [CHANNELS-1:0] tensor_tap_accept, tensor_tap_sof;
    wire [CHANNELS-1:0] tensor_tap_eol, tensor_tap_eof, tensor_tap_error;
    wire [CHANNELS*32-1:0] tensor_tap_frame_id;

    // The canonical stream is still 640x480 RGB888 for AI.  Only the
    // display-owned path changes geometry and representation before DDR.
    video_stream_if #(.DATA_WIDTH(32), .STREAM_ID_WIDTH(4))
        display_channels [CHANNELS]();
    for (genvar display_ch = 0; display_ch < CHANNELS;
         display_ch++) begin : g_display_scaler
        display_scaler u_scaler (
            .s_video(capture_channels[display_ch]),
            .m_video(display_channels[display_ch])
        );
    end

    video_control_bridge #(
        .CHANNELS(CHANNELS), .GLOBAL_CHANNEL_BASE(GLOBAL_CHANNEL_BASE),
        .CAMERA_PRESENT_MASK(CAMERA_PRESENT_MASK),
        .DEFAULT_CHANNEL_BASES(DEFAULT_CHANNEL_BASES)
    ) u_control_bridge (
        .control_axil(control_axil), .video_clk(video_clk),
        .video_resetn(video_resetn),
        .cfg_request_toggle(cfg_request_toggle),
        .cfg_ack_toggle(cfg_ack_toggle), .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .cfg_hdmi_capture_enable(cfg_hdmi_capture_enable),
        .tensor_production_enable(tensor_production_enable),
        .tensor_production_admission_mask(tensor_production_admission_mask),
        .tensor_production_admission_limit(tensor_production_admission_limit),
        .tensor_production_release_pulse(tensor_production_release_pulse),
        .tensor_production_release_mask(tensor_production_release_mask),
        .tensor_production_ready_mask(tensor_production_ready),
        .tensor_production_writing_mask(tensor_production_writing),
        .tensor_production_error_mask(tensor_production_error),
        .tensor_production_quiescent(tensor_production_quiescent),
        .tensor_production_frame_ids(tensor_production_frames),
        .tensor_production_timestamps(tensor_production_timestamps),
        .tensor_production_versions(tensor_production_versions),
        .tensor_production_error_codes(tensor_production_error_codes),
        .tensor_production_byte_counts(tensor_production_bytes),
        .tensor_production_no_slot_counts(tensor_production_no_slot),
        .tensor_production_missed_counts(tensor_production_missed),
        .tensor_production_admission_skip_counts(tensor_production_admission_skip),
        .tensor_production_overflow_counts(tensor_production_overflows),
        .tensor_dma_outstanding_current(tensor_dma_outstanding),
        .tensor_dma_outstanding_max(tensor_dma_outstanding_max),
        .tensor_dma_source_starvation(tensor_dma_starvation),
        .tensor_dma_aw_stall_cycles(tensor_dma_aw_stall),
        .tensor_dma_w_stall_cycles(tensor_dma_w_stall),
        .tensor_dma_w_transfer_cycles(tensor_dma_w_transfer),
        .tensor_dma_b_wait_cycles(tensor_dma_b_wait),
        .tensor_dma_bursts_issued(tensor_dma_bursts),
        .tensor_dma_bursts_completed(tensor_dma_completed),
        .tensor_dma_response_errors(tensor_dma_resp_errors),
        .overlay_commit(overlay_commit), .overlay_stream(overlay_stream),
        .overlay_count(overlay_count), .overlay_boxes(overlay_boxes),
        .overlay_labels(overlay_labels), .manager_status(manager_status),
        .writer_frame_counts(writer_frame_counts), .drop_counts(drop_counts),
        .malformed_counts(malformed_counts),
        .reader_frame_count(reader_frame_count), .underflow_count(underflow_count),
        .reader_active_base(reader_active_base),
        .reader_debug_status(reader_debug_status),
        .writer_perf_outstanding_current(writer_perf_outstanding_current),
        .writer_perf_outstanding_max(writer_perf_outstanding_max),
        .writer_perf_aw_stall_cycles(writer_perf_aw_stall_cycles),
        .writer_perf_w_stall_cycles(writer_perf_w_stall_cycles),
        .writer_perf_b_stall_cycles(writer_perf_b_stall_cycles),
        .writer_perf_bursts_issued(writer_perf_bursts_issued),
        .writer_perf_bursts_completed(writer_perf_bursts_completed),
        .writer_perf_response_errors(writer_perf_response_errors),
        .hdmi_transport_frame_count(hdmi_transport_frame_count),
        .hdmi_transport_malformed_count(hdmi_transport_malformed_count),
        .hdmi_channel_frame_counts(hdmi_channel_frame_counts)
    );

    frame_store_subsystem #(
        .CHANNELS(CHANNELS), .FRAME_WIDTH(368),
        .FRAME_HEIGHT(270), .FRAME_STRIDE_BYTES(736),
        .PIXEL_BYTES(2),
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .WRITE_OUTSTANDING(WRITE_OUTSTANDING),
        .WRITE_DESCRIPTOR_DEPTH(WRITE_DESCRIPTOR_DEPTH)
    ) u_frame_store (
        .clk(video_clk), .resetn(video_resetn),
        .capture_channels(display_channels), .writer_axi(writer_axi),
        .cfg_request_toggle(cfg_request_toggle), .cfg_ack_toggle(cfg_ack_toggle),
        .cfg_enable(cfg_enable), .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_display_channel(local_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .reader_acquire(reader_acquire), .reader_grant(reader_grant),
        .reader_base(reader_base), .reader_done(reader_done),
        .reader_bases(reader_bases), .reader_valid_mask(reader_valid_mask),
        .reader_mode(reader_mode), .reader_underflow(reader_underflow),
        .active_width(active_width), .active_height(active_height),
        .active_stride_bytes(active_stride_bytes),
        .writer_frame_counts(writer_frame_counts),
        .reader_frame_count(reader_frame_count), .drop_counts(drop_counts),
        .underflow_count(underflow_count), .manager_status(manager_status),
        .writer_error(writer_error),
        .perf_outstanding_current(writer_perf_outstanding_current),
        .perf_outstanding_max(writer_perf_outstanding_max),
        .perf_aw_stall_cycles(writer_perf_aw_stall_cycles),
        .perf_w_stall_cycles(writer_perf_w_stall_cycles),
        .perf_b_stall_cycles(writer_perf_b_stall_cycles),
        .perf_bursts_issued(writer_perf_bursts_issued),
        .perf_bursts_completed(writer_perf_bursts_completed),
        .perf_response_errors(writer_perf_response_errors)
    );

    for (genvar tensor_ch = 0; tensor_ch < CHANNELS; tensor_ch++) begin : g_tensor_tap
        assign tensor_tap_data[tensor_ch*48 +: 48] = capture_channels[tensor_ch].data;
        assign tensor_tap_accept[tensor_ch] = capture_channels[tensor_ch].valid &&
                                               capture_channels[tensor_ch].ready;
        assign tensor_tap_sof[tensor_ch] = capture_channels[tensor_ch].sof;
        assign tensor_tap_eol[tensor_ch] = capture_channels[tensor_ch].eol;
        assign tensor_tap_eof[tensor_ch] = capture_channels[tensor_ch].eof;
        assign tensor_tap_frame_id[tensor_ch*32 +: 32] =
            capture_channels[tensor_ch].frame_id;
        assign tensor_tap_error[tensor_ch] = capture_channels[tensor_ch].error;
    end

    tensor_ingress_subsystem #(
        .CHANNELS(CHANNELS), .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT)
    ) u_tensor_ingress (
        .clk(video_clk), .resetn(video_resetn),
        .production_enable(tensor_production_enable),
        .admission_enable_mask(tensor_production_admission_mask),
        .admission_limit(tensor_production_admission_limit),
        .release_pulse(tensor_production_release_pulse),
        .release_mask(tensor_production_release_mask),
        .tap_data(tensor_tap_data), .tap_accept(tensor_tap_accept),
        .tap_sof(tensor_tap_sof), .tap_eol(tensor_tap_eol),
        .tap_eof(tensor_tap_eof), .tap_frame_id(tensor_tap_frame_id),
        .tap_error(tensor_tap_error), .ready_mask(tensor_production_ready),
        .writing_mask(tensor_production_writing),
        .error_mask(tensor_production_error),
        .slot_frame_ids(tensor_production_frames),
        .slot_timestamps(tensor_production_timestamps),
        .slot_versions(tensor_production_versions),
        .slot_error_codes(tensor_production_error_codes),
        .slot_byte_counts(tensor_production_bytes),
        .no_slot_counts(tensor_production_no_slot),
        .missed_frame_counts(tensor_production_missed),
        .admission_skip_counts(tensor_production_admission_skip),
        .overflow_counts(tensor_production_overflows),
        .perf_outstanding_current(tensor_dma_outstanding),
        .perf_outstanding_max(tensor_dma_outstanding_max),
        .perf_source_starvation(tensor_dma_starvation),
        .perf_aw_stall_cycles(tensor_dma_aw_stall),
        .perf_w_stall_cycles(tensor_dma_w_stall),
        .perf_w_transfer_cycles(tensor_dma_w_transfer),
        .perf_b_wait_cycles(tensor_dma_b_wait),
        .perf_bursts_issued(tensor_dma_bursts),
        .perf_bursts_completed(tensor_dma_completed),
        .perf_response_errors(tensor_dma_resp_errors), .m_axi(tensor_write_axi)
    );

    display_subsystem #(
        .CHANNELS(CHANNELS), .SOURCE_WIDTH(368),
        .SOURCE_HEIGHT(270), .SOURCE_STRIDE_BYTES(736),
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .READ_OUTSTANDING(READ_OUTSTANDING),
        .READ_DESCRIPTOR_DEPTH(READ_DESCRIPTOR_DEPTH)
    ) u_display (
        .clk(video_clk), .resetn(video_resetn),
        .buffer_acquire(reader_acquire), .buffer_grant(reader_grant),
        .buffer_base(reader_base), .buffer_bases(reader_bases),
        .buffer_valid_mask(reader_valid_mask), .buffer_mode(reader_mode),
        .buffer_done(reader_done), .frame_width(active_width),
        .frame_height(active_height), .frame_stride_bytes(active_stride_bytes),
        .overlay_commit(overlay_commit), .overlay_stream(overlay_stream),
        .overlay_count(overlay_count), .overlay_boxes(overlay_boxes),
        .overlay_labels(overlay_labels), .m_axi(reader_axi),
        .m_axis(display_axis), .axi_error(reader_error),
        .fifo_underflow(reader_underflow),
        .debug_active_base(reader_active_base),
        .debug_status(reader_debug_status)
    );

    wire unused_init_done = init_done;
endmodule
