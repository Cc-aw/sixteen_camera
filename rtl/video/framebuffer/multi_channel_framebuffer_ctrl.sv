`timescale 1ns/1ps

// AXI-Lite transport shell for the video CSR banks.  Register ownership and
// decode live in rtl/control/csr; this module preserves the legacy software
// address map and independent AXI-Lite address/data handshakes.
module multi_channel_framebuffer_ctrl #(
    parameter integer CHANNELS = 3,
    parameter integer GLOBAL_CHANNEL_BASE = 4,
    parameter [CHANNELS-1:0] CAMERA_PRESENT_MASK =
        {{(CHANNELS-1){1'b0}}, 1'b1},
    parameter [CHANNELS*32-1:0] DEFAULT_CHANNEL_BASES =
        {CHANNELS{32'h0800_0000}}
) (
    input wire ppu_overlay_valid,output wire ppu_overlay_ready,
    input wire [3:0] ppu_overlay_stream,ppu_overlay_count,
    input wire [511:0] ppu_overlay_boxes,input wire [1023:0] ppu_overlay_labels,
    axi_lite_if.slave axil,
    output wire cfg_request_toggle,
    output wire cfg_enable,
    output wire [31:0] cfg_width,
    output wire [31:0] cfg_height,
    output wire [31:0] cfg_stride_bytes,
    output wire [31:0] cfg_buffers_per_channel,
    output wire [CHANNELS*32-1:0] cfg_channel_bases,
    output wire [31:0] cfg_buffer_stride_bytes,
    output wire tensor_production_enable,
    output wire [15:0] tensor_production_admission_mask,
    output wire [4:0] tensor_production_admission_limit,
    output wire tensor_production_release_toggle,
    output wire [31:0] tensor_production_release_mask,
    input wire tensor_production_release_ack,
    input wire [31:0] tensor_production_ready_mask,
    input wire [31:0] tensor_production_writing_mask,
    input wire [31:0] tensor_production_error_mask,
    input wire tensor_production_quiescent,
    input wire [32*32-1:0] tensor_production_frame_ids,
    input wire [32*64-1:0] tensor_production_timestamps,
    input wire [32*32-1:0] tensor_production_versions,
    input wire [32*8-1:0] tensor_production_error_codes,
    input wire [32*32-1:0] tensor_production_byte_counts,
    input wire [16*32-1:0] tensor_production_no_slot_counts,
    input wire [16*32-1:0] tensor_production_missed_counts,
    input wire [16*32-1:0] tensor_production_admission_skip_counts,
    input wire [16*32-1:0] tensor_production_overflow_counts,
    input wire [15:0] tensor_dma_outstanding_current,
    input wire [15:0] tensor_dma_outstanding_max,
    input wire [31:0] tensor_dma_source_starvation,
    input wire [31:0] tensor_dma_aw_stall_cycles,
    input wire [31:0] tensor_dma_w_stall_cycles,
    input wire [31:0] tensor_dma_w_transfer_cycles,
    input wire [31:0] tensor_dma_b_wait_cycles,
    input wire [31:0] tensor_dma_bursts_issued,
    input wire [31:0] tensor_dma_bursts_completed,
    input wire [31:0] tensor_dma_response_errors,
    output wire [((CHANNELS <= 1) ? 1 : $clog2(CHANNELS))-1:0]
        cfg_display_channel,
    output wire cfg_display_mode,
    output wire cfg_hdmi_capture_enable,
    output wire overlay_commit_toggle,
    output wire [3:0] overlay_stream,
    output wire [3:0] overlay_count,
    output wire [8*64-1:0] overlay_boxes,
    output wire [8*128-1:0] overlay_labels,
    input wire overlay_commit_ack_toggle,
    input wire cfg_ack_toggle,
    input wire [31:0] manager_status,
    input wire [CHANNELS*32-1:0] writer_frame_counts,
    input wire [CHANNELS*32-1:0] drop_counts,
    input wire [CHANNELS*32-1:0] malformed_counts,
    input wire [31:0] reader_frame_count,
    input wire [31:0] underflow_count,
    input wire [31:0] reader_active_base,
    input wire [31:0] reader_debug_status,
    input wire [31:0] writer_perf_outstanding_current,
    input wire [31:0] writer_perf_outstanding_max,
    input wire [31:0] writer_perf_aw_stall_cycles,
    input wire [31:0] writer_perf_w_stall_cycles,
    input wire [31:0] writer_perf_b_stall_cycles,
    input wire [31:0] writer_perf_bursts_issued,
    input wire [31:0] writer_perf_bursts_completed,
    input wire [31:0] writer_perf_response_errors,
    input wire [31:0] hdmi_transport_frame_count,
    input wire [31:0] hdmi_transport_malformed_count,
    input wire [8*32-1:0] hdmi_channel_frame_counts,
    input wire [8*32-1:0] hdmi_channel_overflow_counts
);
    reg [9:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0] wstrb_hold;
    reg aw_pending;
    reg w_pending;
    reg bvalid;
    reg [31:0] rdata;
    reg rvalid;

    wire aw_fire = axil.awvalid && axil.awready;
    wire w_fire = axil.wvalid && axil.wready;
    wire write_complete = !bvalid && (aw_pending || aw_fire) &&
                          (w_pending || w_fire);
    wire [9:0] write_addr = aw_pending ? awaddr_hold : axil.awaddr[9:0];
    wire [31:0] write_data = w_pending ? wdata_hold : axil.wdata;
    wire [3:0] write_strb = w_pending ? wstrb_hold : axil.wstrb;
    wire [9:0] read_addr = axil.araddr[9:0];

    wire frame_read_hit, video_read_hit, tensor_read_hit;
    wire overlay_read_hit, telemetry_read_hit;
    wire [31:0] frame_read_data, video_read_data, tensor_read_data;
    wire [31:0] overlay_read_data, telemetry_read_data;
    reg [31:0] selected_read_data;

    assign axil.awready = axil.aresetn && !aw_pending && !bvalid;
    assign axil.wready = axil.aresetn && !w_pending && !bvalid;
    assign axil.bresp = 2'b00;
    assign axil.bvalid = bvalid;
    assign axil.arready = axil.aresetn && !rvalid;
    assign axil.rdata = rdata;
    assign axil.rresp = 2'b00;
    assign axil.rvalid = rvalid;

    always @* begin
        if (frame_read_hit)
            selected_read_data = frame_read_data;
        else if (video_read_hit)
            selected_read_data = video_read_data;
        else if (tensor_read_hit)
            selected_read_data = tensor_read_data;
        else if (overlay_read_hit)
            selected_read_data = overlay_read_data;
        else if (telemetry_read_hit)
            selected_read_data = telemetry_read_data;
        else
            selected_read_data = 32'd0;
    end

    always @(posedge axil.aclk) begin
        if (!axil.aresetn) begin
            awaddr_hold <= 10'd0;
            wdata_hold <= 32'd0;
            wstrb_hold <= 4'd0;
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            bvalid <= 1'b0;
            rdata <= 32'd0;
            rvalid <= 1'b0;
        end else begin
            if (aw_fire) begin
                awaddr_hold <= axil.awaddr[9:0];
                aw_pending <= 1'b1;
            end
            if (w_fire) begin
                wdata_hold <= axil.wdata;
                wstrb_hold <= axil.wstrb;
                w_pending <= 1'b1;
            end
            if (write_complete) begin
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                bvalid <= 1'b1;
            end else if (bvalid && axil.bready) begin
                bvalid <= 1'b0;
            end

            if (axil.arready && axil.arvalid) begin
                rdata <= selected_read_data;
                rvalid <= 1'b1;
            end else if (rvalid && axil.rready) begin
                rvalid <= 1'b0;
            end
        end
    end

    frame_csr #(
        .CHANNELS(CHANNELS), .GLOBAL_CHANNEL_BASE(GLOBAL_CHANNEL_BASE),
        .CAMERA_PRESENT_MASK(CAMERA_PRESENT_MASK),
        .DEFAULT_CHANNEL_BASES(DEFAULT_CHANNEL_BASES)
    ) u_frame_csr (
        .clk(axil.aclk), .resetn(axil.aresetn),
        .write_valid(write_complete), .write_addr(write_addr),
        .write_data(write_data), .write_strb(write_strb),
        .read_addr(read_addr), .read_hit(frame_read_hit),
        .read_data(frame_read_data),
        .cfg_request_toggle(cfg_request_toggle), .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_ack_toggle(cfg_ack_toggle), .manager_status(manager_status)
    );

    video_csr #(
        .CHANNELS(CHANNELS), .GLOBAL_CHANNEL_BASE(GLOBAL_CHANNEL_BASE),
        .CAMERA_PRESENT_MASK(CAMERA_PRESENT_MASK)
    ) u_video_csr (
        .clk(axil.aclk), .resetn(axil.aresetn),
        .write_valid(write_complete), .write_addr(write_addr),
        .write_data(write_data), .write_strb(write_strb),
        .read_addr(read_addr), .read_hit(video_read_hit),
        .read_data(video_read_data),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .cfg_hdmi_capture_enable(cfg_hdmi_capture_enable)
    );

    tensor_csr #(
        .CHANNELS(CHANNELS), .CAMERA_PRESENT_MASK(CAMERA_PRESENT_MASK)
    ) u_tensor_csr (
        .clk(axil.aclk), .resetn(axil.aresetn),
        .write_valid(write_complete), .write_addr(write_addr),
        .write_data(write_data), .write_strb(write_strb),
        .read_addr(read_addr), .read_hit(tensor_read_hit),
        .read_data(tensor_read_data),
        .tensor_production_enable(tensor_production_enable),
        .tensor_production_admission_mask(
            tensor_production_admission_mask),
        .tensor_production_admission_limit(
            tensor_production_admission_limit),
        .tensor_production_release_toggle(
            tensor_production_release_toggle),
        .tensor_production_release_mask(tensor_production_release_mask),
        .tensor_production_release_ack(tensor_production_release_ack),
        .tensor_production_ready_mask(tensor_production_ready_mask),
        .tensor_production_writing_mask(tensor_production_writing_mask),
        .tensor_production_error_mask(tensor_production_error_mask),
        .tensor_production_frame_ids(tensor_production_frame_ids),
        .tensor_production_timestamps(tensor_production_timestamps),
        .tensor_production_versions(tensor_production_versions),
        .tensor_production_error_codes(tensor_production_error_codes),
        .tensor_production_byte_counts(tensor_production_byte_counts),
        .tensor_production_no_slot_counts(
            tensor_production_no_slot_counts),
        .tensor_production_missed_counts(tensor_production_missed_counts),
        .tensor_production_admission_skip_counts(
            tensor_production_admission_skip_counts),
        .tensor_production_overflow_counts(
            tensor_production_overflow_counts),
        .tensor_dma_outstanding_current(tensor_dma_outstanding_current),
        .tensor_dma_outstanding_max(tensor_dma_outstanding_max),
        .tensor_dma_source_starvation(tensor_dma_source_starvation),
        .tensor_dma_aw_stall_cycles(tensor_dma_aw_stall_cycles),
        .tensor_dma_w_stall_cycles(tensor_dma_w_stall_cycles),
        .tensor_dma_w_transfer_cycles(tensor_dma_w_transfer_cycles),
        .tensor_dma_b_wait_cycles(tensor_dma_b_wait_cycles),
        .tensor_dma_bursts_issued(tensor_dma_bursts_issued),
        .tensor_dma_bursts_completed(tensor_dma_bursts_completed),
        .tensor_dma_response_errors(tensor_dma_response_errors)
    );

    overlay_csr #(.CHANNELS(CHANNELS)) u_overlay_csr (
        .ppu_overlay_valid(ppu_overlay_valid),.ppu_overlay_ready(ppu_overlay_ready),
        .ppu_overlay_stream(ppu_overlay_stream),.ppu_overlay_count(ppu_overlay_count),
        .ppu_overlay_boxes(ppu_overlay_boxes),.ppu_overlay_labels(ppu_overlay_labels),

        .clk(axil.aclk), .resetn(axil.aresetn),
        .write_valid(write_complete), .write_addr(write_addr),
        .write_data(write_data), .write_strb(write_strb),
        .read_addr(read_addr), .read_hit(overlay_read_hit),
        .read_data(overlay_read_data),
        .overlay_commit_toggle(overlay_commit_toggle),
        .overlay_stream(overlay_stream), .overlay_count(overlay_count),
        .overlay_boxes(overlay_boxes), .overlay_labels(overlay_labels),
        .overlay_commit_ack_toggle(overlay_commit_ack_toggle)
    );

    telemetry_csr #(.CHANNELS(CHANNELS)) u_telemetry_csr (
        .read_addr(read_addr), .read_hit(telemetry_read_hit),
        .read_data(telemetry_read_data),
        .writer_frame_counts(writer_frame_counts), .drop_counts(drop_counts),
        .malformed_counts(malformed_counts),
        .reader_frame_count(reader_frame_count),
        .underflow_count(underflow_count),
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
        .hdmi_channel_frame_counts(hdmi_channel_frame_counts),
        .hdmi_channel_overflow_counts(hdmi_channel_overflow_counts)
    );

    wire unused_tensor_quiescent = tensor_production_quiescent;
endmodule
