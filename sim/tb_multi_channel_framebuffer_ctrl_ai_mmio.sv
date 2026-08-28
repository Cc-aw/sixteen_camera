`timescale 1ns/1ps

module tb_multi_channel_framebuffer_ctrl_ai_mmio;
    localparam integer CHANNELS = 16;
    axi_lite_if #(.ADDR_WIDTH(16)) axil();

    reg clk = 1'b0;
    always #5 clk = ~clk;
    assign axil.aclk = clk;

    wire cfg_request_toggle;
    wire cfg_enable;
    wire [31:0] cfg_width;
    wire [31:0] cfg_height;
    wire [31:0] cfg_stride_bytes;
    wire [31:0] cfg_buffers_per_channel;
    wire [CHANNELS*32-1:0] cfg_channel_bases;
    wire [31:0] cfg_buffer_stride_bytes;
    wire [31:0] preprocess_arena0_base;
    wire [31:0] preprocess_arena1_base;
    wire [31:0] preprocess_member_stride;
    wire [31:0] preprocess_member_bytes;
    wire [3:0] cfg_display_channel;
    wire cfg_display_mode;
    wire cfg_hdmi_capture_enable;
    wire ai_snapshot_req_toggle;
    wire ai_release_req_toggle;
    wire [CHANNELS-1:0] ai_release_mask;
    wire ai_meta_req_toggle;
    wire [3:0] ai_meta_index;
    reg preprocess_busy = 1'b1;

    reg ai_snapshot_ack_toggle = 1'b0;
    reg ai_release_ack_toggle = 1'b0;
    reg ai_meta_ack_toggle = 1'b0;
    reg ai_snapshot_active = 1'b0;
    reg [CHANNELS-1:0] ai_snapshot_valid_mask = 16'ha55a;
    reg [CHANNELS-1:0] ai_snapshot_fresh_mask = 16'h0f0f;
    reg [CHANNELS-1:0] ai_held_mask = 16'h00ff;
    reg [31:0] ai_meta_addr = 32'd0;
    reg [63:0] ai_meta_frame_id = 64'd0;
    reg [63:0] ai_meta_timestamp = 64'd0;
    reg [31:0] ai_meta_version = 32'd0;
    reg [63:0] ai_snapshot_batch_id = 64'h1122_3344_5566_7788;
    reg [31:0] ai_snapshot_count = 32'd7;
    reg [31:0] ai_release_count = 32'd3;
    reg [31:0] ai_error_count = 32'd2;
    wire preprocess_start_req_toggle;
    wire preprocess_recycle_req_toggle;
    wire [1:0] preprocess_recycle_mask;
    reg preprocess_start_ack_toggle = 1'b0;
    reg preprocess_recycle_ack_toggle = 1'b0;
    wire overlay_commit_toggle;
    wire [3:0] overlay_stream;
    wire [3:0] overlay_count;
    wire [511:0] overlay_boxes;
    reg overlay_commit_ack_toggle = 1'b0;
    multi_channel_framebuffer_ctrl #(
        .CHANNELS(CHANNELS), .GLOBAL_CHANNEL_BASE(1),
        .CAMERA_PRESENT_MASK(16'hffff),
        .DEFAULT_CHANNEL_BASES({CHANNELS{32'h1000_0000}})
    ) dut (
        .axil(axil),
        .cfg_request_toggle(cfg_request_toggle), .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .preprocess_arena0_base(preprocess_arena0_base),
        .preprocess_arena1_base(preprocess_arena1_base),
        .preprocess_member_stride(preprocess_member_stride),
        .preprocess_member_bytes(preprocess_member_bytes),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .cfg_hdmi_capture_enable(cfg_hdmi_capture_enable),
        .ai_snapshot_req_toggle(ai_snapshot_req_toggle),
        .ai_release_req_toggle(ai_release_req_toggle),
        .ai_release_mask(ai_release_mask),
        .ai_meta_req_toggle(ai_meta_req_toggle),
        .ai_meta_index(ai_meta_index),
        .ai_snapshot_ack_toggle(ai_snapshot_ack_toggle),
        .ai_release_ack_toggle(ai_release_ack_toggle),
        .ai_meta_ack_toggle(ai_meta_ack_toggle),
        .ai_snapshot_active(ai_snapshot_active),
        .ai_snapshot_valid_mask(ai_snapshot_valid_mask),
        .ai_snapshot_fresh_mask(ai_snapshot_fresh_mask),
        .ai_held_mask(ai_held_mask),
        .ai_meta_addr(ai_meta_addr), .ai_meta_frame_id(ai_meta_frame_id),
        .ai_meta_timestamp(ai_meta_timestamp),
        .ai_meta_version(ai_meta_version),
        .ai_snapshot_batch_id(ai_snapshot_batch_id),
        .ai_snapshot_count(ai_snapshot_count),
        .ai_release_count(ai_release_count), .ai_error_count(ai_error_count),
        .preprocess_start_req_toggle(preprocess_start_req_toggle),
        .preprocess_recycle_req_toggle(preprocess_recycle_req_toggle),
        .preprocess_recycle_mask(preprocess_recycle_mask),
        .preprocess_start_ack_toggle(preprocess_start_ack_toggle),
        .preprocess_recycle_ack_toggle(preprocess_recycle_ack_toggle),
        .preprocess_busy(preprocess_busy), .preprocess_ready_mask(2'b01),
        .preprocess_active_arena(1'b0),
        .preprocess_active_channel(5'd7),
        .preprocess_completed_channels(5'd7),
        .preprocess_active_tensor_base(32'h3000_0000),
        .preprocess_arena0_batch_id(64'h1122_3344_5566_7788),
        .preprocess_arena1_batch_id(64'h8877_6655_4433_2211),
        .preprocess_arena0_valid_mask(16'h00ff),
        .preprocess_arena1_valid_mask(16'hff00),
        .preprocess_arena0_fresh_mask(16'h000f),
        .preprocess_arena1_fresh_mask(16'hf000),
        .preprocess_last_batch_cycles(32'd1234),
        .preprocess_last_read_beats(32'd2345),
        .preprocess_last_write_beats(32'd3456),
        .preprocess_start_count(32'd4),
        .preprocess_complete_count(32'd3),
        .preprocess_error_count(32'd1),
        .overlay_commit_toggle(overlay_commit_toggle),
        .overlay_stream(overlay_stream), .overlay_count(overlay_count),
        .overlay_boxes(overlay_boxes),
        .overlay_commit_ack_toggle(overlay_commit_ack_toggle),
        .cfg_ack_toggle(cfg_request_toggle), .manager_status(32'd0),
        .writer_frame_counts({CHANNELS{32'd0}}),
        .drop_counts({CHANNELS{32'd0}}),
        .malformed_counts({CHANNELS{32'd0}}),
        .reader_frame_count(32'd0), .underflow_count(32'd0),
        .reader_active_base(32'd0), .reader_debug_status(32'd0),
        .writer_perf_outstanding_current(32'd0),
        .writer_perf_outstanding_max(32'd0),
        .writer_perf_aw_stall_cycles(32'd0),
        .writer_perf_w_stall_cycles(32'd0),
        .writer_perf_b_stall_cycles(32'd0),
        .writer_perf_bursts_issued(32'd0),
        .writer_perf_bursts_completed(32'd0),
        .writer_perf_response_errors(32'd0),
        .hdmi_transport_frame_count(32'd0),
        .hdmi_transport_malformed_count(32'd0),
        .hdmi_channel_frame_counts(256'd0),
        .hdmi_channel_overflow_counts(256'd0)
    );

    task automatic axi_write;
        input [15:0] address;
        input [31:0] data;
        begin
            @(posedge clk); #1;
            axil.awaddr = address;
            axil.awvalid = 1'b1;
            axil.wdata = data;
            axil.wstrb = 4'hf;
            axil.wvalid = 1'b1;
            while (!(axil.awready && axil.wready)) begin
                @(posedge clk); #1;
            end
            @(posedge clk); #1;
            axil.awvalid = 1'b0;
            axil.wvalid = 1'b0;
            while (!axil.bvalid) begin
                @(posedge clk); #1;
            end
            @(posedge clk); #1;
        end
    endtask

    task automatic axi_read;
        input [15:0] address;
        output [31:0] data;
        begin
            @(posedge clk); #1;
            axil.araddr = address;
            axil.arvalid = 1'b1;
            while (!axil.arready) begin
                @(posedge clk); #1;
            end
            @(posedge clk); #1;
            axil.arvalid = 1'b0;
            while (!axil.rvalid) begin
                @(posedge clk); #1;
            end
            data = axil.rdata;
            @(posedge clk); #1;
        end
    endtask

    reg [31:0] value;
    initial begin
        axil.aresetn = 1'b0;
        axil.awaddr = 0; axil.awprot = 0; axil.awvalid = 0;
        axil.wdata = 0; axil.wstrb = 0; axil.wvalid = 0;
        axil.bready = 1'b1;
        axil.araddr = 0; axil.arprot = 0; axil.arvalid = 0;
        axil.rready = 1'b1;
        repeat (4) @(posedge clk);
        axil.aresetn = 1'b1;
        repeat (2) @(posedge clk);

        axi_write(16'h01c0, 32'h1);
        if (ai_snapshot_req_toggle != 1'b1)
            $fatal(1, "snapshot MMIO command did not toggle request");
        axi_read(16'h01c4, value);
        if (!(value & 1)) $fatal(1, "snapshot busy bit missing");
        ai_snapshot_active = 1'b1;
        ai_snapshot_ack_toggle = ai_snapshot_req_toggle;
        repeat (2) @(posedge clk);
        axi_read(16'h01cc, value);
        if (value != 16'ha55a) $fatal(1, "valid mask read=%08x", value);
        axi_read(16'h01d0, value);
        if (value != 16'h0f0f) $fatal(1, "fresh mask read=%08x", value);

        axi_write(16'h01d8, 32'd11);
        if (ai_meta_index != 11 || ai_meta_req_toggle != 1'b1)
            $fatal(1, "metadata index mailbox was not requested");
        ai_meta_addr = 32'h2000_b000;
        ai_meta_frame_id = 64'h0102_0304_0000_000b;
        ai_meta_timestamp = 64'h1111_2222_0000_000b;
        ai_meta_version = 32'h10b;
        ai_meta_ack_toggle = ai_meta_req_toggle;
        repeat (2) @(posedge clk);
        axi_read(16'h01dc, value);
        if (value != 32'h2000_b000) $fatal(1, "metadata addr=%08x", value);
        axi_read(16'h01e0, value);
        if (value != 32'h0000_000b) $fatal(1, "metadata frame low=%08x", value);
        axi_read(16'h01e4, value);
        if (value != 32'h0102_0304) $fatal(1, "metadata frame high=%08x", value);
        axi_read(16'h01f0, value);
        if (value != 32'h10b) $fatal(1, "metadata version=%08x", value);
        axi_read(16'h01f4, value);
        if (value != 32'h5566_7788) $fatal(1, "batch low=%08x", value);

        axi_write(16'h01c8, 32'h0000_00f0);
        if (ai_release_mask != 16'h00f0)
            $fatal(1, "release mask write=%h", ai_release_mask);
        axi_write(16'h01c0, 32'h2);
        if (ai_release_req_toggle != 1'b1)
            $fatal(1, "release MMIO command did not toggle request");
        ai_release_ack_toggle = ai_release_req_toggle;
        repeat (2) @(posedge clk);
        axi_read(16'h01fc, value);
        if (value != {8'd2, 12'd3, 12'd7})
            $fatal(1, "diagnostic register=%08x", value);

        axi_write(16'h0200, 32'h1);
        if (preprocess_start_req_toggle != 1'b1)
            $fatal(1, "preprocess start request missing");
        axi_read(16'h0204, value);
        if (value[0] != 1'b1 || value[2] != 1'b1 || value[4:3] != 2'b01)
            $fatal(1, "preprocess status=%08x", value);
        preprocess_start_ack_toggle = preprocess_start_req_toggle;
        axi_write(16'h0208, 32'h1);
        axi_write(16'h0200, 32'h2);
        if (preprocess_recycle_req_toggle != 1'b1 ||
            preprocess_recycle_mask != 2'b01)
            $fatal(1, "preprocess recycle request missing");
        preprocess_recycle_ack_toggle = preprocess_recycle_req_toggle;
        axi_read(16'h0220, value);
        if (value != 32'h5566_7788)
            $fatal(1, "preprocess arena batch=%08x", value);
        axi_read(16'h0230, value);
        if (value != 32'h0000_00ff)
            $fatal(1, "preprocess arena valid=%08x", value);
        axi_read(16'h0240, value);
        if (value != 1234)
            $fatal(1, "preprocess cycles=%0d", value);

        preprocess_busy = 1'b0;

        axi_write(16'h0280, 32'h3400_0000);
        axi_write(16'h0284, 32'h3500_0000);
        axi_write(16'h0288, 32'h0010_0000);
        axi_write(16'h028c, 32'h000e_1000);
        axi_read(16'h0280, value);
        if (value != 32'h3400_0000 || preprocess_arena0_base != value)
            $fatal(1, "preprocess arena0 config=%08x", value);
        axi_read(16'h0284, value);
        if (value != 32'h3500_0000 || preprocess_arena1_base != value)
            $fatal(1, "preprocess arena1 config=%08x", value);
        axi_read(16'h0288, value);
        if (value != 32'h0010_0000 || preprocess_member_stride != value)
            $fatal(1, "preprocess stride config=%08x", value);
        axi_read(16'h028c, value);
        if (value != 32'h000e_1000 || preprocess_member_bytes != value)
            $fatal(1, "preprocess bytes config=%08x", value);

        axi_write(16'h0264, 32'd15);
        axi_write(16'h0268, 32'd1);
        axi_write(16'h026c, 32'd0);
        axi_write(16'h0270, 32'h0020_000a);
        axi_write(16'h0274, 32'h0000_1234);
        axi_write(16'h0278, 32'd7);
        axi_write(16'h0260, 32'd1);
        if (overlay_stream != 15 || overlay_count != 1 ||
            overlay_commit_toggle != 1'b1)
            $fatal(1, "overlay commit mailbox missing");
        if (overlay_boxes[31:0] != 32'h0020_000a ||
            overlay_boxes[63:32] != 32'h0000_7234)
            $fatal(1, "overlay payload=%016x", overlay_boxes[63:0]);
        axi_read(16'h0260, value);
        if (value[1] != 1'b1)
            $fatal(1, "overlay busy bit missing");
        overlay_commit_ack_toggle = overlay_commit_toggle;
        repeat (2) @(posedge clk);
        axi_read(16'h0260, value);
        if (value[1] != 1'b0)
            $fatal(1, "overlay busy bit did not clear");

        $display("TB_MULTI_CHANNEL_FRAMEBUFFER_CTRL_AI_MMIO=PASS");
        $finish;
    end
endmodule
