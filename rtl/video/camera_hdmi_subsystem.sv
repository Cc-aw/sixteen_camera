`timescale 1ns/1ps

// Serialize all camera initialization traffic.  Each camera owns separate
// pins, but only the granted controller may issue IIC writes.  A terminal
// failure releases the grant so one missing camera cannot block later ones.
module ov7670_init_scheduler (
    input  wire       clk,
    input  wire       rstn,
    input  wire [7:0] request,
    input  wire [7:0] terminal,
    output reg  [7:0] grant
);
    reg active;
    reg [2:0] active_channel;

    always @(posedge clk) begin
        if (!rstn) begin
            grant <= 8'd0;
            active <= 1'b0;
            active_channel <= 3'd0;
        end else if (active) begin
            if (terminal[active_channel]) begin
                grant <= 8'd0;
                active <= 1'b0;
            end
        end else if (request[0]) begin
            grant <= 8'b00000001;
            active <= 1'b1;
            active_channel <= 3'd0;
        end else if (request[1]) begin
            grant <= 8'b00000010;
            active <= 1'b1;
            active_channel <= 3'd1;
        end else if (request[2]) begin
            grant <= 8'b00000100;
            active <= 1'b1;
            active_channel <= 3'd2;
        end else if (request[3]) begin
            grant <= 8'b00001000;
            active <= 1'b1;
            active_channel <= 3'd3;
        end else if (request[4]) begin
            grant <= 8'b00010000;
            active <= 1'b1;
            active_channel <= 3'd4;
        end else if (request[5]) begin
            grant <= 8'b00100000;
            active <= 1'b1;
            active_channel <= 3'd5;
        end else if (request[6]) begin
            grant <= 8'b01000000;
            active <= 1'b1;
            active_channel <= 3'd6;
        end else if (request[7]) begin
            grant <= 8'b10000000;
            active <= 1'b1;
            active_channel <= 3'd7;
        end
    end
endmodule

// Eight identical OV7670 ingress pipelines. Each physical DVP interface owns
// its PCLK domain and crosses into the shared DDR clock through an async FIFO.
module camera_hdmi_subsystem (
    input wire sys_rstn,
    input wire sys_init_done,
    input wire camera_ref_clk,
    axi4_if.slave mmio_axi,
    axis_video_if.sink display_axis,
    video_stream_if.source capture_channels [8],
    axi_lite_if.master framebuffer_axil,
    input wire capture_clk,
    input wire capture_resetn,

    output wire [7:0] cam_rst_n,
    output wire [7:0] cam_pwdn,
    output wire [7:0] cam_scl,
    inout wire [7:0] cam_sda,
    output wire [7:0] cam_xclk,
    input wire [7:0] cam_xclk_pad,
    input wire [7:0] cam_rst_n_pad,
    input wire [7:0] cam_pwdn_pad,
    input wire [7:0] cam_scl_pad,
    input wire [7:0] cam_pclk,
    input wire [7:0] cam_vsync,
    input wire [7:0] cam_href,
    input wire [63:0] cam_data,
    input wire hdmi_rx_clk_p,
    input wire hdmi_rx_clk_n,
    input wire [2:0] hdmi_rx_data_p,
    input wire [2:0] hdmi_rx_data_n,
    output wire hdmi_ref_clk_p,
    output wire hdmi_ref_clk_n,
    input wire hdmi_tx_refclk_p,
    input wire hdmi_tx_refclk_n,
    input wire hdmi_tx_hpd,
    inout wire hdmi_tx_ddc_scl,
    inout wire hdmi_tx_ddc_sda,
    output wire [3:0] hdmi_tx_data_p,
    output wire [3:0] hdmi_tx_data_n,
    output wire hdmi_tx_en,
    output wire hdmi_tx_locked,
    input wire hdmi_rx_pwr_det,
    output wire hdmi_rx_hpd,
    inout wire hdmi_rx_ddc_scl,
    inout wire hdmi_rx_ddc_sda,
    inout wire hdmi_clkchip_scl,
    inout wire hdmi_clkchip_sda,
    input wire hdmi_clkchip_lol,
    input wire hdmi_clkchip_int,
    output wire hdmi_clkchip_rst,
    output wire camera_pll_locked,
    output wire [479:0] camera_axis_diag,
    output wire [255:0] malformed_counts,
    output wire [7:0] video_interrupts
);
    localparam integer CAMERA_COUNT = 8;

    axi_lite_if #(.ADDR_WIDTH(18)) camera_axil [CAMERA_COUNT]();
    axis_video_if #(.DATA_WIDTH(48)) unused_hdmi_capture();
    axis_video_if #(.DATA_WIDTH(48)) camera_axis_from_cdc [CAMERA_COUNT]();

    wire [7:0] hdmi_interrupts;
    wire ov7670_ctrl_clk;
    wire [7:0] camera_pixel_valid;
    wire [7:0] camera_pixel_ready;
    wire [7:0][23:0] camera_pixel_data;
    wire [7:0] camera_frame_start;
    wire [7:0] camera_line_last;
    wire [7:0] camera_line_end;
    wire [7:0] camera_scl;
    tri [7:0] camera_sda;
    wire [7:0] camera_xclk;
    wire [7:0] camera_reset_n;
    wire [7:0] camera_pwdn;
    wire [7:0] ov7670_pixel_resetn;
    wire [7:0] camera_init_request;
    wire [7:0] camera_init_terminal;
    wire [7:0] camera_init_grant;
    wire [7:0][383:0] camera_axis_diag_cam;
    wire [383:0] camera_axis_diag_ddr;
    wire [31:0] camera_cdc_fire_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_sof_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_eol_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_fifo_full_stall_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_ready_low_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_fifo_max_level [CAMERA_COUNT];
    wire [31:0] camera_cdc_line_flush_count [CAMERA_COUNT];
    wire [31:0] camera_malformed_count [CAMERA_COUNT];
    wire [31:0] camera_timeout_abort_count [CAMERA_COUNT];
    wire [31:0] camera_pad_error_count [CAMERA_COUNT];
    wire [255:0] camera_stream_diag [CAMERA_COUNT];
    wire [7:0] camera_diag_clear_toggle;

    video_tx_subsystem u_hdmi (
        .mmio_axi(mmio_axi), .display_axis(display_axis),
        .capture_axis(unused_hdmi_capture),
        .framebuffer_axil(framebuffer_axil),
        .camera_axil(camera_axil),
        .capture_clk(capture_clk), .capture_resetn(capture_resetn),
        .hdmi_rx_clk_p(hdmi_rx_clk_p), .hdmi_rx_clk_n(hdmi_rx_clk_n),
        .hdmi_rx_data_p(hdmi_rx_data_p), .hdmi_rx_data_n(hdmi_rx_data_n),
        .hdmi_ref_clk_p(hdmi_ref_clk_p), .hdmi_ref_clk_n(hdmi_ref_clk_n),
        .hdmi_tx_refclk_p(hdmi_tx_refclk_p),
        .hdmi_tx_refclk_n(hdmi_tx_refclk_n), .hdmi_tx_hpd(hdmi_tx_hpd),
        .hdmi_tx_ddc_scl(hdmi_tx_ddc_scl), .hdmi_tx_ddc_sda(hdmi_tx_ddc_sda),
        .hdmi_tx_data_p(hdmi_tx_data_p), .hdmi_tx_data_n(hdmi_tx_data_n),
        .hdmi_tx_en(hdmi_tx_en), .hdmi_tx_locked(hdmi_tx_locked),
        .hdmi_rx_pwr_det(hdmi_rx_pwr_det), .hdmi_rx_hpd(hdmi_rx_hpd),
        .hdmi_rx_ddc_scl(hdmi_rx_ddc_scl), .hdmi_rx_ddc_sda(hdmi_rx_ddc_sda),
        .hdmi_clkchip_scl(hdmi_clkchip_scl),
        .hdmi_clkchip_sda(hdmi_clkchip_sda),
        .hdmi_clkchip_lol(hdmi_clkchip_lol),
        .hdmi_clkchip_int(hdmi_clkchip_int),
        .hdmi_clkchip_rst(hdmi_clkchip_rst),
        .video_interrupts(hdmi_interrupts)
    );
    assign unused_hdmi_capture.tready = 1'b1;

    camera_clocking u_camera_clocking (
        .sys_rstn(sys_rstn), .clk_ref(camera_ref_clk),
        .pll_locked(camera_pll_locked),
        .ov7670_ctrl_clk(ov7670_ctrl_clk)
    );

    ov7670_init_scheduler u_camera_init_scheduler (
        .clk(ov7670_ctrl_clk), .rstn(sys_rstn),
        .request(camera_init_request),
        .terminal(camera_init_terminal), .grant(camera_init_grant)
    );

    genvar camera_index;
    generate
        for (camera_index = 0; camera_index < CAMERA_COUNT;
            camera_index = camera_index + 1) begin : g_camera_frontend
            ov7670_frontend #(
                .VSYNC_FILTER_CYCLES(256),
                .HREF_FILTER_CYCLES(16),
                .MIN_FRAME_LINES(470),
                .MIN_FRAME_INTERVAL_CYCLES(200000),
                .FRAME_RESYNC_TIMEOUT_CYCLES(2000000)
            ) u_camera (
                .sys_rstn(sys_rstn), .sys_init_done(sys_init_done),
                .ov7670_ctrl_clk(ov7670_ctrl_clk),
                .init_grant(camera_init_grant[camera_index]),
                .init_request(camera_init_request[camera_index]),
                .init_terminal(camera_init_terminal[camera_index]),
                .video_clk(capture_clk), .video_resetn(capture_resetn),
                .camera_axil(camera_axil[camera_index]),
                .ov7670_pclk(cam_pclk[camera_index]),
                .ov7670_vsync(cam_vsync[camera_index]),
                .ov7670_href(cam_href[camera_index]),
                .ov7670_data(cam_data[camera_index*8 +: 8]),
                .cam_scl(camera_scl[camera_index]),
                .cam_sda(camera_sda[camera_index]),
                .cam_xclk(camera_xclk[camera_index]),
                .cam_reset_n(camera_reset_n[camera_index]),
                .cam_pwdn(camera_pwdn[camera_index]),
                .cam_xclk_pad(cam_xclk_pad[camera_index]),
                .cam_reset_n_pad(cam_rst_n_pad[camera_index]),
                .cam_pwdn_pad(cam_pwdn_pad[camera_index]),
                .cam_scl_pad(cam_scl_pad[camera_index]),
                .pixel_valid(camera_pixel_valid[camera_index]),
                .pixel_ready(camera_pixel_ready[camera_index]),
                .diag_fifo_full_stall_count(
                    camera_cdc_fifo_full_stall_count[camera_index]),
                .diag_ready_low_count(camera_cdc_ready_low_count[camera_index]),
                .diag_fifo_max_level(camera_cdc_fifo_max_level[camera_index]),
                .diag_line_flush_count(
                    camera_cdc_line_flush_count[camera_index]),
                .stream_diag_counts(camera_stream_diag[camera_index]),
                .stream_timeout_abort_count(
                    camera_timeout_abort_count[camera_index]),
                .diag_clear_toggle(camera_diag_clear_toggle[camera_index]),
                .pixel_data(camera_pixel_data[camera_index]),
                .frame_start(camera_frame_start[camera_index]),
                .line_last(camera_line_last[camera_index]),
                .line_end(camera_line_end[camera_index]),
                .pixel_resetn(ov7670_pixel_resetn[camera_index]),
                .axis_diag(camera_axis_diag_cam[camera_index])
            );

            camera_axis_cdc #(
                .FRAME_WIDTH(640), .FIFO_DEPTH(16384)
            ) u_camera_cdc (
                // The oversampling frontend and FIFO writer now share the
                // 300 MHz DDR UI clock; external PCLK is sampled as data.
                .camera_clk(capture_clk),
                .camera_resetn(ov7670_pixel_resetn[camera_index]),
                .pixel_valid(camera_pixel_valid[camera_index]),
                .pixel_ready(camera_pixel_ready[camera_index]),
                .pixel_data(camera_pixel_data[camera_index]),
                .frame_start(camera_frame_start[camera_index]),
                .line_last(camera_line_last[camera_index]),
                .line_end(camera_line_end[camera_index]),
                .diag_clear_toggle(camera_diag_clear_toggle[camera_index]),
                .diag_fifo_full_stall_count(
                    camera_cdc_fifo_full_stall_count[camera_index]),
                .diag_ready_low_count(camera_cdc_ready_low_count[camera_index]),
                .diag_fifo_max_level(camera_cdc_fifo_max_level[camera_index]),
                .diag_line_flush_count(
                    camera_cdc_line_flush_count[camera_index]),
                .ddr_clk(capture_clk), .ddr_resetn(capture_resetn),
                .diag_fire_count(camera_cdc_fire_count[camera_index]),
                .diag_sof_count(camera_cdc_sof_count[camera_index]),
                .diag_eol_count(camera_cdc_eol_count[camera_index]),
                .m_axis(camera_axis_from_cdc[camera_index])
            );

            camera_axis_to_stream #(
                .FRAME_WIDTH(640), .FRAME_HEIGHT(480),
                .STREAM_ID(camera_index)
            ) u_camera_stream (
                .s_axis(camera_axis_from_cdc[camera_index]),
                .m_stream(capture_channels[camera_index]),
                .diag_clear_toggle(camera_diag_clear_toggle[camera_index]),
                .malformed_frame_count(camera_malformed_count[camera_index]),
                .diag_counts(camera_stream_diag[camera_index]),
                .timeout_abort_count(camera_timeout_abort_count[camera_index])
            );

            assign camera_pad_error_count[camera_index] = 32'd0;

            assign malformed_counts[camera_index*32 +: 32] =
                camera_malformed_count[camera_index] +
                camera_pad_error_count[camera_index];
            tran u_cam_sda(cam_sda[camera_index], camera_sda[camera_index]);
        end
    endgenerate

    assign cam_scl = camera_scl;
    assign cam_xclk = camera_xclk;
    assign cam_rst_n = camera_reset_n;
    assign cam_pwdn = camera_pwdn;

    // The oversampling frontend already produces this diagnostic bus in the
    // DDR UI/capture domain, so no CDC or duplicated 384-bit register bank is
    // needed here.
    assign camera_axis_diag_ddr = camera_axis_diag_cam[0];
    assign camera_axis_diag = {camera_cdc_eol_count[0],
                               camera_cdc_sof_count[0],
                               camera_cdc_fire_count[0],
                               camera_axis_diag_ddr};

    assign video_interrupts = hdmi_interrupts;
    wire unused = &{1'b0, camera_line_last, capture_channels[0].ready,
                    capture_channels[1].ready, capture_channels[2].ready,
                    capture_channels[3].ready, capture_channels[4].ready,
                    capture_channels[5].ready, capture_channels[6].ready,
                    capture_channels[7].ready};
endmodule
