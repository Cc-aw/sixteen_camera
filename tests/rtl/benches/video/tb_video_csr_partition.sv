`timescale 1ns/1ps

module tb_video_csr_partition;
    localparam integer CHANNELS = 16;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    axi_lite_if #(.ADDR_WIDTH(16)) axil();
    assign axil.aclk = clk;
    assign axil.aresetn = resetn;

    wire cfg_request_toggle, cfg_enable;
    wire [31:0] cfg_width, cfg_height, cfg_stride_bytes;
    wire [31:0] cfg_buffers_per_channel, cfg_buffer_stride_bytes;
    wire [CHANNELS*32-1:0] cfg_channel_bases;
    wire tensor_enable, tensor_release_toggle;
    wire [15:0] tensor_admission_mask;
    wire [4:0] tensor_admission_limit;
    wire [31:0] tensor_release_mask;
    wire [3:0] display_channel;
    wire display_mode, hdmi_capture_enable, overlay_toggle;
    wire [3:0] overlay_stream, overlay_count;
    wire [511:0] overlay_boxes;
    wire [1023:0] overlay_labels;

    multi_channel_framebuffer_ctrl #(
        .CHANNELS(CHANNELS), .GLOBAL_CHANNEL_BASE(0),
        .CAMERA_PRESENT_MASK(16'hffff),
        .DEFAULT_CHANNEL_BASES({CHANNELS{32'h0800_0000}})
    ) dut (
        .axil(axil),
        .cfg_request_toggle(cfg_request_toggle), .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .tensor_production_enable(tensor_enable),
        .tensor_production_admission_mask(tensor_admission_mask),
        .tensor_production_admission_limit(tensor_admission_limit),
        .tensor_production_release_toggle(tensor_release_toggle),
        .tensor_production_release_mask(tensor_release_mask),
        .tensor_production_release_ack(tensor_release_toggle),
        .tensor_production_ready_mask(32'h0000_0020),
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
        .tensor_dma_outstanding_current(16'd3),
        .tensor_dma_outstanding_max(16'd7),
        .tensor_dma_source_starvation(32'd11),
        .tensor_dma_aw_stall_cycles(32'd12),
        .tensor_dma_w_stall_cycles(32'd13),
        .tensor_dma_w_transfer_cycles(32'd14),
        .tensor_dma_b_wait_cycles(32'd15),
        .tensor_dma_bursts_issued(32'd16),
        .tensor_dma_bursts_completed(32'd17),
        .tensor_dma_response_errors(32'd18),
        .cfg_display_channel(display_channel),
        .cfg_display_mode(display_mode),
        .cfg_hdmi_capture_enable(hdmi_capture_enable),
        .overlay_commit_toggle(overlay_toggle),
        .overlay_stream(overlay_stream), .overlay_count(overlay_count),
        .overlay_boxes(overlay_boxes), .overlay_labels(overlay_labels),
        .overlay_commit_ack_toggle(overlay_toggle),
        .cfg_ack_toggle(cfg_request_toggle),
        .manager_status(32'h1357_9bdf),
        .writer_frame_counts({16{32'h1111_0001}}),
        .drop_counts({16{32'h2222_0002}}),
        .malformed_counts({16{32'h3333_0003}}),
        .reader_frame_count(32'h4444_0004),
        .underflow_count(32'h5555_0005),
        .reader_active_base(32'h6666_0006),
        .reader_debug_status(32'h7777_0007),
        .writer_perf_outstanding_current(32'd21),
        .writer_perf_outstanding_max(32'd22),
        .writer_perf_aw_stall_cycles(32'd23),
        .writer_perf_w_stall_cycles(32'd24),
        .writer_perf_b_stall_cycles(32'd25),
        .writer_perf_bursts_issued(32'd26),
        .writer_perf_bursts_completed(32'd27),
        .writer_perf_response_errors(32'd28),
        .hdmi_transport_frame_count(32'h8888_0008),
        .hdmi_transport_malformed_count(32'h9999_0009),
        .hdmi_channel_frame_counts({8{32'haaaa_000a}}),
        .hdmi_channel_overflow_counts({8{32'hbbbb_000b}})
    );

    task automatic axil_write(input [15:0] address, input [31:0] data);
        begin
            @(negedge clk);
            axil.awaddr = address;
            axil.awvalid = 1'b1;
            axil.wdata = data;
            axil.wstrb = 4'hf;
            axil.wvalid = 1'b1;
            while (!(axil.awready && axil.wready)) @(negedge clk);
            @(negedge clk);
            axil.awvalid = 1'b0;
            axil.wvalid = 1'b0;
            while (!axil.bvalid) @(negedge clk);
        end
    endtask

    task automatic axil_read(input [15:0] address, output [31:0] data);
        begin
            @(negedge clk);
            axil.araddr = address;
            axil.arvalid = 1'b1;
            while (!axil.arready) @(negedge clk);
            @(negedge clk);
            axil.arvalid = 1'b0;
            while (!axil.rvalid) @(negedge clk);
            data = axil.rdata;
        end
    endtask

    task automatic expect_read(input [15:0] address, input [31:0] expected);
        reg [31:0] actual;
        begin
            axil_read(address, actual);
            if (actual !== expected)
                $fatal(1, "CSR %h expected %h got %h",
                       address, expected, actual);
        end
    endtask

    initial begin
        axil.awaddr = 0; axil.awprot = 0; axil.awvalid = 0;
        axil.wdata = 0; axil.wstrb = 0; axil.wvalid = 0;
        axil.bready = 1; axil.araddr = 0; axil.arprot = 0;
        axil.arvalid = 0; axil.rready = 1;
        repeat (4) @(posedge clk);
        resetn = 1'b1;

        axil_write(16'h0008, 32'd800);
        axil_write(16'h0018, 32'd5);
        axil_write(16'h0064, 32'd1);
        axil_write(16'h02d4, 32'ha5a5_5a5a);
        axil_write(16'h0344, 32'h0000_55aa);
        axil_write(16'h0264, 32'd3);
        axil_write(16'h0268, 32'd2);

        expect_read(16'h0008, 32'd800);
        expect_read(16'h0018, 32'd5);
        expect_read(16'h0064, 32'd1);
        expect_read(16'h02d4, 32'ha5a5_5a5a);
        expect_read(16'h0344, 32'h0000_55aa);
        expect_read(16'h0264, 32'd3);
        expect_read(16'h0268, 32'd2);
        expect_read(16'h0080, 32'h1111_0001);
        expect_read(16'h0140, 32'h4444_0004);
        expect_read(16'h0170, 32'h8888_0008);
        expect_read(16'h0180, 32'haaaa_000a);
        expect_read(16'h01a0, 32'hbbbb_000b);
        expect_read(16'h03fc, 32'd0);

        $display("TB_VIDEO_CSR_PARTITION=PASS");
        $finish;
    end
endmodule
