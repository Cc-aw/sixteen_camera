`timescale 1ns/1ps

// Owns the complete CPU/video clock-domain boundary for the video pipeline.
// Commands cross as coherent mailbox records.  Telemetry is serialized into
// indexed records so changing counter banks are never continuously sampled by
// hundreds of independent synchronizers.
module video_control_bridge #(
    parameter integer CHANNELS = 16,
    parameter integer GLOBAL_CHANNEL_BASE = 0,
    parameter [CHANNELS-1:0] CAMERA_PRESENT_MASK =
        {{(CHANNELS-1){1'b0}}, 1'b1},
    parameter [CHANNELS*32-1:0] DEFAULT_CHANNEL_BASES =
        {CHANNELS{32'h0800_0000}}
) (
    axi_lite_if.slave control_axil,
    input  wire video_clk,
    input  wire video_resetn,

    output reg  cfg_request_toggle,
    input  wire cfg_ack_toggle,
    output reg  cfg_enable,
    output reg  [31:0] cfg_width,
    output reg  [31:0] cfg_height,
    output reg  [31:0] cfg_stride_bytes,
    output reg  [31:0] cfg_buffers_per_channel,
    output reg  [CHANNELS*32-1:0] cfg_channel_bases,
    output reg  [31:0] cfg_buffer_stride_bytes,
    output reg  [((CHANNELS <= 1) ? 1 : $clog2(CHANNELS))-1:0]
                    cfg_display_channel,
    output reg  cfg_display_mode,
    output reg  cfg_hdmi_capture_enable,

    output reg  tensor_production_enable,
    output reg  [15:0] tensor_production_admission_mask,
    output reg  [4:0] tensor_production_admission_limit,
    output reg  tensor_production_release_pulse,
    output reg  [31:0] tensor_production_release_mask,
    input  wire [31:0] tensor_production_ready_mask,
    input  wire [31:0] tensor_production_writing_mask,
    input  wire [31:0] tensor_production_error_mask,
    input  wire tensor_production_quiescent,
    input  wire [32*32-1:0] tensor_production_frame_ids,
    input  wire [32*64-1:0] tensor_production_timestamps,
    input  wire [32*32-1:0] tensor_production_versions,
    input  wire [32*8-1:0] tensor_production_error_codes,
    input  wire [32*32-1:0] tensor_production_byte_counts,
    input  wire [CHANNELS*32-1:0] tensor_production_no_slot_counts,
    input  wire [CHANNELS*32-1:0] tensor_production_missed_counts,
    input  wire [CHANNELS*32-1:0] tensor_production_admission_skip_counts,
    input  wire [CHANNELS*32-1:0] tensor_production_overflow_counts,
    input  wire [15:0] tensor_dma_outstanding_current,
    input  wire [15:0] tensor_dma_outstanding_max,
    input  wire [31:0] tensor_dma_source_starvation,
    input  wire [31:0] tensor_dma_aw_stall_cycles,
    input  wire [31:0] tensor_dma_w_stall_cycles,
    input  wire [31:0] tensor_dma_w_transfer_cycles,
    input  wire [31:0] tensor_dma_b_wait_cycles,
    input  wire [31:0] tensor_dma_bursts_issued,
    input  wire [31:0] tensor_dma_bursts_completed,
    input  wire [31:0] tensor_dma_response_errors,

    output reg  overlay_commit,
    output reg  [3:0] overlay_stream,
    output reg  [3:0] overlay_count,
    output reg  [8*64-1:0] overlay_boxes,
    output reg  [8*128-1:0] overlay_labels,

    input  wire [31:0] manager_status,
    input  wire [CHANNELS*32-1:0] writer_frame_counts,
    input  wire [CHANNELS*32-1:0] drop_counts,
    input  wire [CHANNELS*32-1:0] malformed_counts,
    input  wire [31:0] reader_frame_count,
    input  wire [31:0] underflow_count,
    input  wire [31:0] reader_active_base,
    input  wire [31:0] reader_debug_status,
    input  wire [15:0] writer_perf_outstanding_current,
    input  wire [15:0] writer_perf_outstanding_max,
    input  wire [31:0] writer_perf_aw_stall_cycles,
    input  wire [31:0] writer_perf_w_stall_cycles,
    input  wire [31:0] writer_perf_b_stall_cycles,
    input  wire [31:0] writer_perf_bursts_issued,
    input  wire [31:0] writer_perf_bursts_completed,
    input  wire [31:0] writer_perf_response_errors,
    input  wire [31:0] hdmi_transport_frame_count,
    input  wire [31:0] hdmi_transport_malformed_count,
    input  wire [8*32-1:0] hdmi_channel_frame_counts
);
    localparam integer CHANNEL_WIDTH = CHANNELS <= 1 ? 1 : $clog2(CHANNELS);
    localparam integer FRAME_CFG_WIDTH = 162 + CHANNELS*32;
    localparam integer DISPLAY_CFG_WIDTH = CHANNEL_WIDTH + 2;
    localparam integer OVERLAY_RECORD_WIDTH = 203;
    localparam integer CHANNEL_RECORD_WIDTH = CHANNEL_WIDTH + 160;
    localparam [15:0] PRESENT_MASK_16 =
        {{(16-CHANNELS){1'b0}}, CAMERA_PRESENT_MASK};

    wire cfg_request_toggle_cpu;
    wire cfg_enable_cpu;
    wire [31:0] cfg_width_cpu, cfg_height_cpu, cfg_stride_bytes_cpu;
    wire [31:0] cfg_buffers_per_channel_cpu;
    wire [CHANNELS*32-1:0] cfg_channel_bases_cpu;
    wire [31:0] cfg_buffer_stride_bytes_cpu;
    wire [CHANNEL_WIDTH-1:0] cfg_display_channel_cpu;
    wire cfg_display_mode_cpu, cfg_hdmi_capture_enable_cpu;
    wire tensor_enable_cpu;
    wire [15:0] tensor_admission_mask_cpu;
    wire [4:0] tensor_admission_limit_cpu;
    wire tensor_release_toggle_cpu;
    wire [31:0] tensor_release_mask_cpu;
    wire overlay_toggle_cpu;
    wire [3:0] overlay_stream_cpu, overlay_count_cpu;
    wire [511:0] overlay_boxes_cpu;
    wire [1023:0] overlay_labels_cpu;
    wire cfg_ack_toggle_cpu;
    reg tensor_release_ack_cpu;
    reg overlay_ack_cpu;

    wire [31:0] tensor_ready_cpu, tensor_writing_cpu, tensor_error_cpu;
    wire tensor_quiescent_cpu;
    wire [32*32-1:0] tensor_frames_cpu, tensor_versions_cpu;
    wire [32*64-1:0] tensor_timestamps_cpu;
    wire [32*8-1:0] tensor_error_codes_cpu;
    wire [32*32-1:0] tensor_bytes_cpu;
    wire [CHANNELS*32-1:0] tensor_no_slot_channels_cpu;
    wire [CHANNELS*32-1:0] tensor_missed_channels_cpu;
    wire [CHANNELS*32-1:0] tensor_admission_skip_channels_cpu;
    wire [CHANNELS*32-1:0] tensor_overflows_channels_cpu;
    wire [16*32-1:0] tensor_no_slot_cpu =
        {{(16-CHANNELS)*32{1'b0}}, tensor_no_slot_channels_cpu};
    wire [16*32-1:0] tensor_missed_cpu =
        {{(16-CHANNELS)*32{1'b0}}, tensor_missed_channels_cpu};
    wire [16*32-1:0] tensor_admission_skip_cpu =
        {{(16-CHANNELS)*32{1'b0}}, tensor_admission_skip_channels_cpu};
    wire [16*32-1:0] tensor_overflows_cpu =
        {{(16-CHANNELS)*32{1'b0}}, tensor_overflows_channels_cpu};

    reg [31:0] manager_status_cpu, reader_frame_count_cpu;
    reg [31:0] underflow_count_cpu, reader_active_base_cpu;
    reg [31:0] reader_debug_status_cpu;
    reg [CHANNELS*32-1:0] writer_counts_cpu, drop_counts_cpu;
    reg [CHANNELS*32-1:0] malformed_counts_cpu;
    reg [31:0] hdmi_transport_frames_cpu, hdmi_transport_malformed_cpu;
    reg [255:0] hdmi_channel_frames_cpu, hdmi_channel_overflows_cpu;
    reg [31:0] writer_perf_current_cpu, writer_perf_max_cpu;
    reg [31:0] writer_perf_aw_cpu, writer_perf_w_cpu, writer_perf_b_cpu;
    reg [31:0] writer_perf_issued_cpu, writer_perf_completed_cpu;
    reg [31:0] writer_perf_errors_cpu;
    reg [15:0] tensor_dma_current_cpu, tensor_dma_max_cpu;
    reg [31:0] tensor_dma_starvation_cpu, tensor_dma_aw_cpu;
    reg [31:0] tensor_dma_w_cpu, tensor_dma_w_transfer_cpu;
    reg [31:0] tensor_dma_b_wait_cpu, tensor_dma_bursts_cpu;
    reg [31:0] tensor_dma_completed_cpu, tensor_dma_errors_cpu;

    multi_channel_framebuffer_ctrl #(
        .CHANNELS(CHANNELS), .GLOBAL_CHANNEL_BASE(GLOBAL_CHANNEL_BASE),
        .CAMERA_PRESENT_MASK(CAMERA_PRESENT_MASK),
        .DEFAULT_CHANNEL_BASES(DEFAULT_CHANNEL_BASES)
    ) u_control (
        .axil(control_axil),
        .cfg_request_toggle(cfg_request_toggle_cpu),
        .cfg_enable(cfg_enable_cpu), .cfg_width(cfg_width_cpu),
        .cfg_height(cfg_height_cpu), .cfg_stride_bytes(cfg_stride_bytes_cpu),
        .cfg_buffers_per_channel(cfg_buffers_per_channel_cpu),
        .cfg_channel_bases(cfg_channel_bases_cpu),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes_cpu),
        .tensor_production_enable(tensor_enable_cpu),
        .tensor_production_admission_mask(tensor_admission_mask_cpu),
        .tensor_production_admission_limit(tensor_admission_limit_cpu),
        .tensor_production_release_toggle(tensor_release_toggle_cpu),
        .tensor_production_release_mask(tensor_release_mask_cpu),
        .tensor_production_release_ack(tensor_release_ack_cpu),
        .tensor_production_ready_mask(tensor_ready_cpu),
        .tensor_production_writing_mask(tensor_writing_cpu),
        .tensor_production_error_mask(tensor_error_cpu),
        .tensor_production_quiescent(tensor_quiescent_cpu),
        .tensor_production_frame_ids(tensor_frames_cpu),
        .tensor_production_timestamps(tensor_timestamps_cpu),
        .tensor_production_versions(tensor_versions_cpu),
        .tensor_production_error_codes(tensor_error_codes_cpu),
        .tensor_production_byte_counts(tensor_bytes_cpu),
        .tensor_production_no_slot_counts(tensor_no_slot_cpu),
        .tensor_production_missed_counts(tensor_missed_cpu),
        .tensor_production_admission_skip_counts(tensor_admission_skip_cpu),
        .tensor_production_overflow_counts(tensor_overflows_cpu),
        .tensor_dma_outstanding_current(tensor_dma_current_cpu),
        .tensor_dma_outstanding_max(tensor_dma_max_cpu),
        .tensor_dma_source_starvation(tensor_dma_starvation_cpu),
        .tensor_dma_aw_stall_cycles(tensor_dma_aw_cpu),
        .tensor_dma_w_stall_cycles(tensor_dma_w_cpu),
        .tensor_dma_w_transfer_cycles(tensor_dma_w_transfer_cpu),
        .tensor_dma_b_wait_cycles(tensor_dma_b_wait_cpu),
        .tensor_dma_bursts_issued(tensor_dma_bursts_cpu),
        .tensor_dma_bursts_completed(tensor_dma_completed_cpu),
        .tensor_dma_response_errors(tensor_dma_errors_cpu),
        .cfg_display_channel(cfg_display_channel_cpu),
        .cfg_display_mode(cfg_display_mode_cpu),
        .cfg_hdmi_capture_enable(cfg_hdmi_capture_enable_cpu),
        .overlay_commit_toggle(overlay_toggle_cpu),
        .overlay_stream(overlay_stream_cpu), .overlay_count(overlay_count_cpu),
        .overlay_boxes(overlay_boxes_cpu), .overlay_labels(overlay_labels_cpu),
        .overlay_commit_ack_toggle(overlay_ack_cpu),
        .cfg_ack_toggle(cfg_ack_toggle_cpu), .manager_status(manager_status_cpu),
        .writer_frame_counts(writer_counts_cpu), .drop_counts(drop_counts_cpu),
        .malformed_counts(malformed_counts_cpu),
        .reader_frame_count(reader_frame_count_cpu),
        .underflow_count(underflow_count_cpu),
        .reader_active_base(reader_active_base_cpu),
        .reader_debug_status(reader_debug_status_cpu),
        .writer_perf_outstanding_current(writer_perf_current_cpu),
        .writer_perf_outstanding_max(writer_perf_max_cpu),
        .writer_perf_aw_stall_cycles(writer_perf_aw_cpu),
        .writer_perf_w_stall_cycles(writer_perf_w_cpu),
        .writer_perf_b_stall_cycles(writer_perf_b_cpu),
        .writer_perf_bursts_issued(writer_perf_issued_cpu),
        .writer_perf_bursts_completed(writer_perf_completed_cpu),
        .writer_perf_response_errors(writer_perf_errors_cpu),
        .hdmi_transport_frame_count(hdmi_transport_frames_cpu),
        .hdmi_transport_malformed_count(hdmi_transport_malformed_cpu),
        .hdmi_channel_frame_counts(hdmi_channel_frames_cpu),
        .hdmi_channel_overflow_counts(hdmi_channel_overflows_cpu)
    );

    // Frame configuration is held by the CPU register bank while busy and is
    // committed atomically into the video domain.
    reg cfg_request_seen_cpu;
    wire [FRAME_CFG_WIDTH-1:0] frame_cfg_src = {
        cfg_request_toggle_cpu, cfg_enable_cpu, cfg_width_cpu, cfg_height_cpu,
        cfg_stride_bytes_cpu, cfg_buffers_per_channel_cpu,
        cfg_channel_bases_cpu, cfg_buffer_stride_bytes_cpu
    };
    wire [FRAME_CFG_WIDTH-1:0] frame_cfg_dst;
    wire frame_cfg_ready, frame_cfg_valid;
    wire frame_cfg_send = cfg_request_toggle_cpu != cfg_request_seen_cpu;
    cdc_mailbox #(.WIDTH(FRAME_CFG_WIDTH)) u_frame_cfg_mailbox (
        .src_clk(control_axil.aclk), .src_resetn(control_axil.aresetn),
        .src_data(frame_cfg_src), .src_valid(frame_cfg_send),
        .src_ready(frame_cfg_ready), .src_done(),
        .dst_clk(video_clk), .dst_resetn(video_resetn),
        .dst_data(frame_cfg_dst), .dst_valid(frame_cfg_valid)
    );
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn)
            cfg_request_seen_cpu <= 1'b0;
        else if (frame_cfg_send && frame_cfg_ready)
            cfg_request_seen_cpu <= cfg_request_toggle_cpu;
    end
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            cfg_request_toggle <= 1'b0;
            cfg_enable <= 1'b0;
            cfg_width <= 32'd640;
            cfg_height <= 32'd480;
            cfg_stride_bytes <= 32'd2560;
            cfg_buffers_per_channel <= 32'd5;
            cfg_channel_bases <= DEFAULT_CHANNEL_BASES;
            cfg_buffer_stride_bytes <= 32'h0040_0000;
        end else if (frame_cfg_valid) begin
            {cfg_request_toggle, cfg_enable, cfg_width, cfg_height,
             cfg_stride_bytes, cfg_buffers_per_channel, cfg_channel_bases,
             cfg_buffer_stride_bytes} <= frame_cfg_dst;
        end
    end
    // multi_channel_framebuffer_ctrl contains the two destination-domain
    // synchronizer stages for this stable acknowledgement toggle.
    assign cfg_ack_toggle_cpu = cfg_ack_toggle;

    // Display selection and HDMI capture enable are a small coherent record.
    wire [DISPLAY_CFG_WIDTH-1:0] display_cfg_src = {
        cfg_hdmi_capture_enable_cpu, cfg_display_mode_cpu,
        cfg_display_channel_cpu
    };
    reg [DISPLAY_CFG_WIDTH-1:0] display_cfg_sent_cpu;
    wire [DISPLAY_CFG_WIDTH-1:0] display_cfg_dst;
    wire display_cfg_ready, display_cfg_valid;
    wire display_cfg_send = display_cfg_src != display_cfg_sent_cpu;
    cdc_mailbox #(.WIDTH(DISPLAY_CFG_WIDTH)) u_display_cfg_mailbox (
        .src_clk(control_axil.aclk), .src_resetn(control_axil.aresetn),
        .src_data(display_cfg_src), .src_valid(display_cfg_send),
        .src_ready(display_cfg_ready), .src_done(),
        .dst_clk(video_clk), .dst_resetn(video_resetn),
        .dst_data(display_cfg_dst), .dst_valid(display_cfg_valid)
    );
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn)
            display_cfg_sent_cpu <= {1'b0, 1'b0,
                CHANNEL_WIDTH'(GLOBAL_CHANNEL_BASE)};
        else if (display_cfg_send && display_cfg_ready)
            display_cfg_sent_cpu <= display_cfg_src;
    end
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            cfg_display_channel <= CHANNEL_WIDTH'(GLOBAL_CHANNEL_BASE);
            cfg_display_mode <= 1'b0;
            cfg_hdmi_capture_enable <= 1'b0;
        end else if (display_cfg_valid) begin
            {cfg_hdmi_capture_enable, cfg_display_mode,
             cfg_display_channel} <= display_cfg_dst;
        end
    end

    wire [21:0] tensor_cfg_src = {tensor_enable_cpu,
                                  tensor_admission_limit_cpu,
                                  tensor_admission_mask_cpu};
    reg [21:0] tensor_cfg_sent_cpu;
    wire [21:0] tensor_cfg_dst;
    wire tensor_cfg_ready, tensor_cfg_valid;
    wire tensor_cfg_send = tensor_cfg_src != tensor_cfg_sent_cpu;
    cdc_mailbox #(.WIDTH(22)) u_tensor_cfg_mailbox (
        .src_clk(control_axil.aclk), .src_resetn(control_axil.aresetn),
        .src_data(tensor_cfg_src), .src_valid(tensor_cfg_send),
        .src_ready(tensor_cfg_ready), .src_done(),
        .dst_clk(video_clk), .dst_resetn(video_resetn),
        .dst_data(tensor_cfg_dst), .dst_valid(tensor_cfg_valid)
    );
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn)
            tensor_cfg_sent_cpu <= {1'b0, 5'd1, PRESENT_MASK_16};
        else if (tensor_cfg_send && tensor_cfg_ready)
            tensor_cfg_sent_cpu <= tensor_cfg_src;
    end
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            tensor_production_enable <= 1'b0;
            tensor_production_admission_limit <= 5'd1;
            tensor_production_admission_mask <= PRESENT_MASK_16;
        end else if (tensor_cfg_valid) begin
            {tensor_production_enable, tensor_production_admission_limit,
             tensor_production_admission_mask} <= tensor_cfg_dst;
        end
    end

    reg tensor_release_seen_cpu;
    wire release_ready, release_valid, release_done;
    wire [31:0] release_dst;
    wire release_send = tensor_release_toggle_cpu != tensor_release_seen_cpu;
    cdc_mailbox #(.WIDTH(32)) u_release_mailbox (
        .src_clk(control_axil.aclk), .src_resetn(control_axil.aresetn),
        .src_data(tensor_release_mask_cpu), .src_valid(release_send),
        .src_ready(release_ready), .src_done(release_done),
        .dst_clk(video_clk), .dst_resetn(video_resetn),
        .dst_data(release_dst), .dst_valid(release_valid)
    );
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn) begin
            tensor_release_seen_cpu <= 1'b0;
            tensor_release_ack_cpu <= 1'b0;
        end else begin
            if (release_send && release_ready)
                tensor_release_seen_cpu <= tensor_release_toggle_cpu;
            if (release_done)
                tensor_release_ack_cpu <= tensor_release_seen_cpu;
        end
    end
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            tensor_production_release_pulse <= 1'b0;
            tensor_production_release_mask <= 32'd0;
        end else begin
            tensor_production_release_pulse <= release_valid;
            if (release_valid)
                tensor_production_release_mask <= release_dst;
        end
    end

    // Overlay state is eight indexed records rather than one 1544-bit CDC.
    // The destination raises commit only after the final record has landed.
    reg overlay_seen_cpu;
    reg overlay_transfer_active_cpu;
    reg [2:0] overlay_transfer_index_cpu;
    reg overlay_last_pending_cpu;
    wire [OVERLAY_RECORD_WIDTH-1:0] overlay_src = {
        overlay_transfer_index_cpu, overlay_stream_cpu, overlay_count_cpu,
        overlay_boxes_cpu[overlay_transfer_index_cpu*64 +: 64],
        overlay_labels_cpu[overlay_transfer_index_cpu*128 +: 128]
    };
    wire [OVERLAY_RECORD_WIDTH-1:0] overlay_dst;
    wire overlay_ready, overlay_valid, overlay_done;
    wire overlay_start = overlay_toggle_cpu != overlay_seen_cpu;
    wire overlay_send = overlay_transfer_active_cpu;
    wire [2:0] overlay_index_dst = overlay_dst[202:200];
    reg overlay_commit_pending;
    cdc_mailbox #(.WIDTH(OVERLAY_RECORD_WIDTH)) u_overlay_mailbox (
        .src_clk(control_axil.aclk), .src_resetn(control_axil.aresetn),
        .src_data(overlay_src), .src_valid(overlay_send),
        .src_ready(overlay_ready), .src_done(overlay_done),
        .dst_clk(video_clk), .dst_resetn(video_resetn),
        .dst_data(overlay_dst), .dst_valid(overlay_valid)
    );
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn) begin
            overlay_seen_cpu <= 1'b0;
            overlay_ack_cpu <= 1'b0;
            overlay_transfer_active_cpu <= 1'b0;
            overlay_transfer_index_cpu <= 3'd0;
            overlay_last_pending_cpu <= 1'b0;
        end else begin
            if (!overlay_transfer_active_cpu && overlay_start) begin
                overlay_transfer_active_cpu <= 1'b1;
                overlay_transfer_index_cpu <= 3'd0;
                overlay_seen_cpu <= overlay_toggle_cpu;
            end
            if (overlay_send && overlay_ready) begin
                overlay_last_pending_cpu <=
                    overlay_transfer_index_cpu == 3'd7;
                if (overlay_transfer_index_cpu == 3'd7)
                    overlay_transfer_active_cpu <= 1'b0;
                else
                    overlay_transfer_index_cpu <=
                        overlay_transfer_index_cpu + 1'b1;
            end
            if (overlay_done) begin
                if (overlay_last_pending_cpu)
                    overlay_ack_cpu <= overlay_seen_cpu;
                overlay_last_pending_cpu <= 1'b0;
            end
        end
    end
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            overlay_commit <= 1'b0;
            overlay_stream <= 4'd0;
            overlay_count <= 4'd0;
            overlay_boxes <= 512'd0;
            overlay_labels <= 1024'd0;
            overlay_commit_pending <= 1'b0;
        end else begin
            overlay_commit <= overlay_commit_pending;
            overlay_commit_pending <= 1'b0;
            if (overlay_valid) begin
                overlay_labels[overlay_index_dst*128 +: 128] <=
                    overlay_dst[0 +: 128];
                overlay_boxes[overlay_index_dst*64 +: 64] <=
                    overlay_dst[128 +: 64];
                overlay_count <= overlay_dst[192 +: 4];
                overlay_stream <= overlay_dst[196 +: 4];
                if (overlay_index_dst == 3'd7)
                    overlay_commit_pending <= 1'b1;
            end
        end
    end

    tensor_telemetry_cdc #(.CHANNELS(CHANNELS), .SLOTS(32))
    u_tensor_telemetry_cdc (
        .src_clk(video_clk), .src_resetn(video_resetn),
        .src_ready_mask(tensor_production_ready_mask),
        .src_writing_mask(tensor_production_writing_mask),
        .src_error_mask(tensor_production_error_mask),
        .src_frame_ids(tensor_production_frame_ids),
        .src_timestamps(tensor_production_timestamps),
        .src_versions(tensor_production_versions),
        .src_error_codes(tensor_production_error_codes),
        .src_byte_counts(tensor_production_byte_counts),
        .src_no_slot_counts(tensor_production_no_slot_counts),
        .src_missed_counts(tensor_production_missed_counts),
        .src_admission_skip_counts(tensor_production_admission_skip_counts),
        .src_overflow_counts(tensor_production_overflow_counts),
        .dst_clk(control_axil.aclk), .dst_resetn(control_axil.aresetn),
        .dst_ready_mask(tensor_ready_cpu),
        .dst_writing_mask(tensor_writing_cpu),
        .dst_error_mask(tensor_error_cpu), .dst_frame_ids(tensor_frames_cpu),
        .dst_timestamps(tensor_timestamps_cpu),
        .dst_versions(tensor_versions_cpu),
        .dst_error_codes(tensor_error_codes_cpu),
        .dst_byte_counts(tensor_bytes_cpu),
        .dst_no_slot_counts(tensor_no_slot_channels_cpu),
        .dst_missed_counts(tensor_missed_channels_cpu),
        .dst_admission_skip_counts(tensor_admission_skip_channels_cpu),
        .dst_overflow_counts(tensor_overflows_channels_cpu)
    );

    // Scalar status is refreshed one word at a time.
    reg [2:0] general_index;
    reg [31:0] general_value;
    wire general_ready, general_valid;
    wire [34:0] general_dst;
    always @* begin
        case (general_index)
            3'd0: general_value = manager_status;
            3'd1: general_value = reader_frame_count;
            3'd2: general_value = underflow_count;
            3'd3: general_value = reader_active_base;
            3'd4: general_value = reader_debug_status;
            3'd5: general_value = hdmi_transport_frame_count;
            3'd6: general_value = hdmi_transport_malformed_count;
            default: general_value = {31'd0, tensor_production_quiescent};
        endcase
    end
    cdc_mailbox #(.WIDTH(35)) u_general_status_mailbox (
        .src_clk(video_clk), .src_resetn(video_resetn),
        .src_data({general_index, general_value}), .src_valid(1'b1),
        .src_ready(general_ready), .src_done(),
        .dst_clk(control_axil.aclk), .dst_resetn(control_axil.aresetn),
        .dst_data(general_dst), .dst_valid(general_valid)
    );
    always @(posedge video_clk) begin
        if (!video_resetn) general_index <= 3'd0;
        else if (general_ready)
            general_index <= general_index == 3'd7 ? 3'd0 : general_index + 1'b1;
    end
    reg tensor_quiescent_hold_cpu;
    assign tensor_quiescent_cpu = general_dst[32] == 1'b1 && general_valid ?
                                  general_dst[0] : tensor_quiescent_hold_cpu;
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn) begin
            manager_status_cpu <= 0; reader_frame_count_cpu <= 0;
            underflow_count_cpu <= 0; reader_active_base_cpu <= 0;
            reader_debug_status_cpu <= 0; hdmi_transport_frames_cpu <= 0;
            hdmi_transport_malformed_cpu <= 0;
            tensor_quiescent_hold_cpu <= 1'b1;
        end else if (general_valid) begin
            case (general_dst[34:32])
                3'd0: manager_status_cpu <= general_dst[31:0];
                3'd1: reader_frame_count_cpu <= general_dst[31:0];
                3'd2: underflow_count_cpu <= general_dst[31:0];
                3'd3: reader_active_base_cpu <= general_dst[31:0];
                3'd4: reader_debug_status_cpu <= general_dst[31:0];
                3'd5: hdmi_transport_frames_cpu <= general_dst[31:0];
                3'd6: hdmi_transport_malformed_cpu <= general_dst[31:0];
                default: tensor_quiescent_hold_cpu <= general_dst[0];
            endcase
        end
    end

    // Per-channel counters cross as one indexed record instead of five wide
    // continuously changing arrays.
    reg [CHANNEL_WIDTH-1:0] channel_index;
    wire [16*32-1:0] malformed_counts_16 =
        {{(16-CHANNELS)*32{1'b0}}, malformed_counts};
    wire [31:0] hdmi_frame_src = channel_index < 8 ?
        hdmi_channel_frame_counts[channel_index*32 +: 32] : 32'd0;
    wire [31:0] hdmi_overflow_src = channel_index < 8 ?
        malformed_counts_16[(channel_index+8)*32 +: 32] : 32'd0;
    wire [CHANNEL_RECORD_WIDTH-1:0] channel_src = {
        channel_index, hdmi_overflow_src, hdmi_frame_src,
        malformed_counts[channel_index*32 +: 32],
        drop_counts[channel_index*32 +: 32],
        writer_frame_counts[channel_index*32 +: 32]
    };
    wire [CHANNEL_RECORD_WIDTH-1:0] channel_dst;
    wire channel_ready, channel_valid;
    wire [CHANNEL_WIDTH-1:0] channel_dst_index =
        channel_dst[CHANNEL_RECORD_WIDTH-1 -: CHANNEL_WIDTH];
    cdc_mailbox #(.WIDTH(CHANNEL_RECORD_WIDTH)) u_channel_status_mailbox (
        .src_clk(video_clk), .src_resetn(video_resetn),
        .src_data(channel_src), .src_valid(1'b1), .src_ready(channel_ready),
        .src_done(), .dst_clk(control_axil.aclk),
        .dst_resetn(control_axil.aresetn), .dst_data(channel_dst),
        .dst_valid(channel_valid)
    );
    always @(posedge video_clk) begin
        if (!video_resetn) channel_index <= 0;
        else if (channel_ready)
            channel_index <= channel_index == CHANNELS-1 ? 0 : channel_index + 1'b1;
    end
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn) begin
            writer_counts_cpu <= 0; drop_counts_cpu <= 0;
            malformed_counts_cpu <= 0; hdmi_channel_frames_cpu <= 0;
            hdmi_channel_overflows_cpu <= 0;
        end else if (channel_valid) begin
            writer_counts_cpu[channel_dst_index*32 +: 32] <= channel_dst[0 +: 32];
            drop_counts_cpu[channel_dst_index*32 +: 32] <= channel_dst[32 +: 32];
            malformed_counts_cpu[channel_dst_index*32 +: 32] <= channel_dst[64 +: 32];
            if (channel_dst_index < 8) begin
                hdmi_channel_frames_cpu[channel_dst_index*32 +: 32] <=
                    channel_dst[96 +: 32];
                hdmi_channel_overflows_cpu[channel_dst_index*32 +: 32] <=
                    channel_dst[128 +: 32];
            end
        end
    end

    // Writer and tensor DMA performance counters share a 32-bit indexed
    // telemetry stream.  This replaces the former 256/288-bit CDC arrays.
    reg [4:0] perf_index;
    reg [31:0] perf_value;
    wire [36:0] perf_dst;
    wire perf_ready, perf_valid;
    always @* begin
        case (perf_index)
            5'd0: perf_value = {16'd0, writer_perf_outstanding_current};
            5'd1: perf_value = {16'd0, writer_perf_outstanding_max};
            5'd2: perf_value = writer_perf_aw_stall_cycles;
            5'd3: perf_value = writer_perf_w_stall_cycles;
            5'd4: perf_value = writer_perf_b_stall_cycles;
            5'd5: perf_value = writer_perf_bursts_issued;
            5'd6: perf_value = writer_perf_bursts_completed;
            5'd7: perf_value = writer_perf_response_errors;
            5'd8: perf_value = {16'd0, tensor_dma_outstanding_current};
            5'd9: perf_value = {16'd0, tensor_dma_outstanding_max};
            5'd10: perf_value = tensor_dma_source_starvation;
            5'd11: perf_value = tensor_dma_aw_stall_cycles;
            5'd12: perf_value = tensor_dma_w_stall_cycles;
            5'd13: perf_value = tensor_dma_w_transfer_cycles;
            5'd14: perf_value = tensor_dma_b_wait_cycles;
            5'd15: perf_value = tensor_dma_bursts_issued;
            5'd16: perf_value = tensor_dma_bursts_completed;
            default: perf_value = tensor_dma_response_errors;
        endcase
    end
    cdc_mailbox #(.WIDTH(37)) u_perf_status_mailbox (
        .src_clk(video_clk), .src_resetn(video_resetn),
        .src_data({perf_index, perf_value}), .src_valid(1'b1),
        .src_ready(perf_ready), .src_done(),
        .dst_clk(control_axil.aclk), .dst_resetn(control_axil.aresetn),
        .dst_data(perf_dst), .dst_valid(perf_valid)
    );
    always @(posedge video_clk) begin
        if (!video_resetn) perf_index <= 0;
        else if (perf_ready)
            perf_index <= perf_index == 5'd17 ? 0 : perf_index + 1'b1;
    end
    always @(posedge control_axil.aclk) begin
        if (!control_axil.aresetn) begin
            writer_perf_current_cpu <= 0; writer_perf_max_cpu <= 0;
            writer_perf_aw_cpu <= 0; writer_perf_w_cpu <= 0;
            writer_perf_b_cpu <= 0; writer_perf_issued_cpu <= 0;
            writer_perf_completed_cpu <= 0; writer_perf_errors_cpu <= 0;
            tensor_dma_current_cpu <= 0; tensor_dma_max_cpu <= 0;
            tensor_dma_starvation_cpu <= 0; tensor_dma_aw_cpu <= 0;
            tensor_dma_w_cpu <= 0; tensor_dma_w_transfer_cpu <= 0;
            tensor_dma_b_wait_cpu <= 0; tensor_dma_bursts_cpu <= 0;
            tensor_dma_completed_cpu <= 0; tensor_dma_errors_cpu <= 0;
        end else if (perf_valid) begin
            case (perf_dst[36:32])
                5'd0: writer_perf_current_cpu <= perf_dst[31:0];
                5'd1: writer_perf_max_cpu <= perf_dst[31:0];
                5'd2: writer_perf_aw_cpu <= perf_dst[31:0];
                5'd3: writer_perf_w_cpu <= perf_dst[31:0];
                5'd4: writer_perf_b_cpu <= perf_dst[31:0];
                5'd5: writer_perf_issued_cpu <= perf_dst[31:0];
                5'd6: writer_perf_completed_cpu <= perf_dst[31:0];
                5'd7: writer_perf_errors_cpu <= perf_dst[31:0];
                5'd8: tensor_dma_current_cpu <= perf_dst[15:0];
                5'd9: tensor_dma_max_cpu <= perf_dst[15:0];
                5'd10: tensor_dma_starvation_cpu <= perf_dst[31:0];
                5'd11: tensor_dma_aw_cpu <= perf_dst[31:0];
                5'd12: tensor_dma_w_cpu <= perf_dst[31:0];
                5'd13: tensor_dma_w_transfer_cpu <= perf_dst[31:0];
                5'd14: tensor_dma_b_wait_cpu <= perf_dst[31:0];
                5'd15: tensor_dma_bursts_cpu <= perf_dst[31:0];
                5'd16: tensor_dma_completed_cpu <= perf_dst[31:0];
                default: tensor_dma_errors_cpu <= perf_dst[31:0];
            endcase
        end
    end

    initial begin
        if (CHANNELS < 1 || CHANNELS > 16)
            $error("video_control_bridge supports 1-16 channels");
    end
endmodule
