`timescale 1ns/1ps

module tb_video_control_bridge;
    localparam integer CHANNELS = 16;
    reg cpu_clk = 1'b0;
    reg video_clk = 1'b0;
    always #5 cpu_clk = ~cpu_clk;
    always #3 video_clk = ~video_clk;

    reg cpu_resetn = 1'b0;
    reg video_resetn = 1'b0;
    axi_lite_if #(.ADDR_WIDTH(16)) axil();
    assign axil.aclk = cpu_clk;
    assign axil.aresetn = cpu_resetn;

    wire cfg_request_toggle;
    wire cfg_ack_toggle = cfg_request_toggle;
    wire cfg_enable;
    wire [31:0] cfg_width, cfg_height, cfg_stride_bytes;
    wire [31:0] cfg_buffers_per_channel, cfg_buffer_stride_bytes;
    wire [CHANNELS*32-1:0] cfg_channel_bases;
    wire [3:0] cfg_display_channel;
    wire cfg_display_mode, cfg_hdmi_capture_enable;
    wire tensor_enable;
    wire [15:0] tensor_admission_mask;
    wire [4:0] tensor_admission_limit;
    wire tensor_release_pulse;
    wire [31:0] tensor_release_mask;
    wire overlay_commit;
    wire [3:0] overlay_stream, overlay_count;
    wire [511:0] overlay_boxes;
    wire [1023:0] overlay_labels;

    reg release_seen = 1'b0;
    reg overlay_seen = 1'b0;
    reg [31:0] release_mask_seen = 0;
    reg [31:0] overlay_xy_seen = 0;
    reg [31:0] overlay_label_seen = 0;
    integer overlay_commit_count = 0;
    always @(posedge video_clk) begin
        if (tensor_release_pulse) begin
            release_seen <= 1'b1;
            release_mask_seen <= tensor_release_mask;
        end
        if (overlay_commit) begin
            overlay_seen <= 1'b1;
            overlay_commit_count <= overlay_commit_count + 1;
            overlay_xy_seen <= overlay_boxes[31:0];
            overlay_label_seen <= overlay_labels[31:0];
        end
    end

    video_control_bridge #(
        .CHANNELS(CHANNELS), .GLOBAL_CHANNEL_BASE(0),
        .CAMERA_PRESENT_MASK(16'hffff),
        .DEFAULT_CHANNEL_BASES({16{32'h0800_0000}})
    ) dut (
        .control_axil(axil), .video_clk(video_clk),
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
        .tensor_production_enable(tensor_enable),
        .tensor_production_admission_mask(tensor_admission_mask),
        .tensor_production_admission_limit(tensor_admission_limit),
        .tensor_production_release_pulse(tensor_release_pulse),
        .tensor_production_release_mask(tensor_release_mask),
        .tensor_production_ready_mask(32'd0),
        .tensor_production_writing_mask(32'd0),
        .tensor_production_error_mask(32'd0),
        .tensor_production_quiescent(1'b1),
        .tensor_production_frame_ids('0),
        .tensor_production_timestamps('0),
        .tensor_production_versions('0),
        .tensor_production_error_codes('0),
        .tensor_production_byte_counts('0),
        .tensor_production_no_slot_counts('0),
        .tensor_production_missed_counts('0),
        .tensor_production_admission_skip_counts('0),
        .tensor_production_overflow_counts('0),
        .tensor_dma_outstanding_current(16'd0),
        .tensor_dma_outstanding_max(16'd0),
        .tensor_dma_source_starvation(32'd0),
        .tensor_dma_aw_stall_cycles(32'd0),
        .tensor_dma_w_stall_cycles(32'd0),
        .tensor_dma_w_transfer_cycles(32'd0),
        .tensor_dma_b_wait_cycles(32'd0),
        .tensor_dma_bursts_issued(32'd0),
        .tensor_dma_bursts_completed(32'd0),
        .tensor_dma_response_errors(32'd0),
        .overlay_commit(overlay_commit), .overlay_stream(overlay_stream),
        .overlay_count(overlay_count), .overlay_boxes(overlay_boxes),
        .overlay_labels(overlay_labels),
        .manager_status(32'h1357_9bdf),
        .writer_frame_counts({16{32'h0102_0304}}),
        .drop_counts('0), .malformed_counts('0),
        .reader_frame_count(32'h2468_ace0), .underflow_count(32'd0),
        .reader_active_base(32'h8765_4000),
        .reader_debug_status(32'h55aa_aa55),
        .writer_perf_outstanding_current(16'd0),
        .writer_perf_outstanding_max(16'd0),
        .writer_perf_aw_stall_cycles(32'd0),
        .writer_perf_w_stall_cycles(32'd0),
        .writer_perf_b_stall_cycles(32'd0),
        .writer_perf_bursts_issued(32'd0),
        .writer_perf_bursts_completed(32'd0),
        .writer_perf_response_errors(32'd0),
        .hdmi_transport_frame_count(32'h1234_5678),
        .hdmi_transport_malformed_count(32'd0),
        .hdmi_channel_frame_counts('0)
    );

    task automatic axil_write(input [15:0] address, input [31:0] data);
        begin
            @(negedge cpu_clk);
            axil.awaddr = address;
            axil.awvalid = 1'b1;
            axil.wdata = data;
            axil.wstrb = 4'hf;
            axil.wvalid = 1'b1;
            while (!(axil.awready && axil.wready)) @(negedge cpu_clk);
            @(negedge cpu_clk);
            axil.awvalid = 1'b0;
            axil.wvalid = 1'b0;
            while (!axil.bvalid) @(negedge cpu_clk);
        end
    endtask

    integer timeout;
    initial begin
        axil.awaddr = 0; axil.awprot = 0; axil.awvalid = 0;
        axil.wdata = 0; axil.wstrb = 0; axil.wvalid = 0;
        axil.bready = 1; axil.araddr = 0; axil.arprot = 0;
        axil.arvalid = 0; axil.rready = 1;

        repeat (5) @(posedge cpu_clk);
        cpu_resetn = 1'b1;
        repeat (4) @(posedge video_clk);
        video_resetn = 1'b1;

        axil_write(16'h0008, 32'd800);
        axil_write(16'h000c, 32'd600);
        axil_write(16'h0010, 32'd3200);
        axil_write(16'h0000, 32'h0000_0005);
        timeout = 0;
        while (cfg_request_toggle == 0 && timeout < 100) begin
            @(posedge video_clk); timeout = timeout + 1;
        end
        if (!cfg_request_toggle || !cfg_enable || cfg_width != 800 ||
            cfg_height != 600 || cfg_stride_bytes != 3200)
            $fatal(1, "frame configuration mailbox failed");

        axil_write(16'h0018, 32'd5);
        axil_write(16'h0064, 32'd1);
        axil_write(16'h0068, 32'd1);
        repeat (30) @(posedge video_clk);
        if (cfg_display_channel != 5 || !cfg_display_mode ||
            !cfg_hdmi_capture_enable)
            $fatal(1, "display configuration mailbox failed");

        axil_write(16'h02d4, 32'ha5a5_5a5a);
        axil_write(16'h02d0, 32'h0000_0002);
        timeout = 0;
        while (!release_seen && timeout < 100) begin
            @(posedge video_clk); timeout = timeout + 1;
        end
        if (!release_seen || release_mask_seen != 32'ha5a5_5a5a)
            $fatal(1, "tensor release mailbox failed");

        axil_write(16'h0264, 32'd3);
        axil_write(16'h0268, 32'd1);
        axil_write(16'h026c, 32'd0);
        axil_write(16'h0270, 32'h1122_3344);
        axil_write(16'h0294, 32'h5566_7788);
        axil_write(16'h0260, 32'd1);
        timeout = 0;
        while (!overlay_seen && timeout < 150) begin
            @(posedge video_clk); timeout = timeout + 1;
        end
        if (!overlay_seen || overlay_stream != 3 || overlay_count != 1 ||
            overlay_xy_seen != 32'h1122_3344 ||
            overlay_label_seen != 32'h5566_7788)
            $fatal(1, "overlay mailbox was not atomic");

        // Exercise the path used by runtime polling: wait for the first
        // acknowledgement, then submit a different stream immediately.
        timeout = 0;
        while (dut.overlay_ack_cpu != dut.overlay_toggle_cpu &&
               timeout < 100) begin
            @(posedge cpu_clk); timeout = timeout + 1;
        end
        if (dut.overlay_ack_cpu != dut.overlay_toggle_cpu)
            $fatal(1, "first overlay acknowledgement missing");
        axil_write(16'h0264, 32'd4);
        axil_write(16'h0268, 32'd2);
        axil_write(16'h026c, 32'd0);
        axil_write(16'h0270, 32'ha1b2_c3d4);
        axil_write(16'h0294, 32'h2067_6f64);
        axil_write(16'h026c, 32'd1);
        axil_write(16'h0270, 32'h1234_5678);
        axil_write(16'h0294, 32'h2074_6163);
        axil_write(16'h0260, 32'd1);
        timeout = 0;
        while (overlay_commit_count < 2 && timeout < 150) begin
            @(posedge video_clk); timeout = timeout + 1;
        end
        if (overlay_commit_count != 2 || overlay_stream != 4 ||
            overlay_count != 2 || overlay_boxes[31:0] != 32'ha1b2_c3d4 ||
            overlay_boxes[64 +: 32] != 32'h1234_5678 ||
            overlay_labels[31:0] != 32'h2067_6f64 ||
            overlay_labels[128 +: 32] != 32'h2074_6163)
            $fatal(1, "sequential overlay stream commit failed");

        repeat (250) @(posedge cpu_clk);
        if (dut.manager_status_cpu != 32'h1357_9bdf ||
            dut.writer_counts_cpu[5*32 +: 32] != 32'h0102_0304 ||
            dut.hdmi_transport_frames_cpu != 32'h1234_5678)
            $fatal(1, "indexed telemetry refresh failed");

        $display("TB_VIDEO_CONTROL_BRIDGE=PASS");
        $finish;
    end
endmodule
