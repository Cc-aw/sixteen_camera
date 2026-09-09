`timescale 1ns/1ps

module top_wrapper (
    input  wire        clk_25m,
    input  wire        sys_rstn,
    input  wire        c0_sys_clk_p,
    input  wire        c0_sys_clk_n,
    input  wire        clk_100m_p,
    input  wire        clk_100m_n,
    input  wire        uart_rxd,
    output wire        uart_txd,
    inout  wire [7:0]  cam_rst_n,
    inout  wire [7:0]  cam_pwdn,
    inout  wire [7:0]  cam_scl,
    inout  wire [7:0]  cam_sda,
    inout  wire [7:0]  cam_xclk,
    input  wire [7:0]  cam_pclk,
    input  wire [7:0]  cam_vsync,
    input  wire [7:0]  cam_href,
    input  wire [63:0] cam_data,
    input  wire        hdmi_rx_clk_p,
    input  wire        hdmi_rx_clk_n,
    input  wire [2:0]  hdmi_rx_data_p,
    input  wire [2:0]  hdmi_rx_data_n,
    output wire        hdmi_ref_clk_p,
    output wire        hdmi_ref_clk_n,
    input  wire        hdmi_tx_refclk_p,
    input  wire        hdmi_tx_refclk_n,
    input  wire        hdmi_tx_hpd,
    inout  wire        hdmi_tx_ddc_scl,
    inout  wire        hdmi_tx_ddc_sda,
    output wire [3:0]  hdmi_tx_data_p,
    output wire [3:0]  hdmi_tx_data_n,
    output wire        hdmi_tx_en,
    input  wire        hdmi_rx_pwr_det,
    output wire        hdmi_rx_hpd,
    inout  wire        hdmi_rx_ddc_scl,
    inout  wire        hdmi_rx_ddc_sda,
    inout  wire        hdmi_clkchip_scl,
    inout  wire        hdmi_clkchip_sda,
    input  wire        hdmi_clkchip_lol,
    input  wire        hdmi_clkchip_int,
    output wire        hdmi_clkchip_rst,
    inout  wire        si5338_scl1,
    inout  wire        si5338_sda1,
    inout  wire        si5338_scl2,
    inout  wire        si5338_sda2,
    output wire [16:0] c0_ddr4_adr,
    output wire [1:0]  c0_ddr4_ba,
    output wire [0:0]  c0_ddr4_cke,
    output wire [0:0]  c0_ddr4_cs_n,
    inout  wire [7:0]  c0_ddr4_dm_dbi_n,
    inout  wire [63:0] c0_ddr4_dq,
    inout  wire [7:0]  c0_ddr4_dqs_c,
    inout  wire [7:0]  c0_ddr4_dqs_t,
    output wire [0:0]  c0_ddr4_odt,
    output wire [0:0]  c0_ddr4_bg,
    output wire        c0_ddr4_reset_n,
    output wire        c0_ddr4_act_n,
    output wire [0:0]  c0_ddr4_ck_c,
    output wire [0:0]  c0_ddr4_ck_t,
    output wire        c0_init_calib_complete
);
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) soc_mem_axi();
    axi4_if #(.ADDR_WIDTH(31), .DATA_WIDTH(64), .ID_WIDTH(4)) soc_mmio_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) soc_fbus_axi();
    wire soc_resetn;
    axis_video_if #(.DATA_WIDTH(48)) ddr_video_axis();
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4))
        camera_capture_channels [8]();
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4))
        hdmi_capture_channels [8]();
    axi_lite_if #(.ADDR_WIDTH(17)) framebuffer_axil();
    wire [7:0] video_interrupts;
    wire hdmi_tx_locked;
    wire video_clk;
    wire video_resetn;
    wire capture_clk;
    wire capture_resetn;
    wire camera_ref_clk;
    wire camera_pll_locked;
    wire [7:0] ov7670_pclk_ibuf;
    wire [7:0] ov7670_xclk_drive;
    wire [7:0] ov7670_reset_n_drive;
    wire [7:0] ov7670_pwdn_drive;
    wire [7:0] ov7670_scl_drive;
    wire [7:0] ov7670_xclk_pad;
    wire [7:0] ov7670_reset_n_pad;
    wire [7:0] ov7670_pwdn_pad;
    wire [7:0] ov7670_scl_pad;
    wire [479:0] camera_axis_diag;
    wire [255:0] camera_malformed_counts;
    wire hdmi_capture_enable;
    wire [31:0] hdmi_transport_frame_count;
    wire [31:0] hdmi_transport_malformed_count;
    wire [255:0] hdmi_channel_overflow_counts;
    wire [255:0] hdmi_channel_frame_counts;
    wire camera_sys_init_done = sys_rstn && c0_init_calib_complete &&
                                camera_pll_locked;

    genvar camera_io_index;
    generate
        for (camera_io_index = 0; camera_io_index < 8;
             camera_io_index = camera_io_index + 1) begin : g_ov7670_io
            IBUF u_pclk_ibuf (
                .I(cam_pclk[camera_io_index]),
                .O(ov7670_pclk_ibuf[camera_io_index])
            );
            IOBUF u_xclk_iobuf (
                .I(ov7670_xclk_drive[camera_io_index]),
                .O(ov7670_xclk_pad[camera_io_index]), .T(1'b0),
                .IO(cam_xclk[camera_io_index])
            );
            IOBUF u_reset_n_iobuf (
                .I(ov7670_reset_n_drive[camera_io_index]),
                .O(ov7670_reset_n_pad[camera_io_index]), .T(1'b0),
                .IO(cam_rst_n[camera_io_index])
            );
            IOBUF u_pwdn_iobuf (
                .I(ov7670_pwdn_drive[camera_io_index]),
                .O(ov7670_pwdn_pad[camera_io_index]), .T(1'b0),
                .IO(cam_pwdn[camera_io_index])
            );
            IOBUF u_scl_iobuf (
                .I(ov7670_scl_drive[camera_io_index]),
                .O(ov7670_scl_pad[camera_io_index]), .T(1'b0),
                .IO(cam_scl[camera_io_index])
            );
        end
    endgenerate

    control_soc_subsystem u_control_soc (
        .sys_rstn(sys_rstn),
        .clk_25m(clk_25m),
        .clk_100m_p(clk_100m_p),
        .clk_100m_n(clk_100m_n),
        .si5338_scl1(si5338_scl1),
        .si5338_sda1(si5338_sda1),
        .si5338_scl2(si5338_scl2),
        .si5338_sda2(si5338_sda2),
        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd),
        .ddr_init_done(c0_init_calib_complete),
        .video_interrupts(video_interrupts),
        .ref_clk_100m(camera_ref_clk),
        .soc_resetn_out(soc_resetn),
        .mem_axi(soc_mem_axi),
        .mmio_axi(soc_mmio_axi),
        .fbus_axi(soc_fbus_axi)
    );

    ddr_memory_subsystem u_ddr_memory (
        .sys_rstn(sys_rstn),
        .c0_sys_clk_p(c0_sys_clk_p),
        .c0_sys_clk_n(c0_sys_clk_n),
        .c0_init_calib_complete(c0_init_calib_complete),
        .c0_ddr4_act_n(c0_ddr4_act_n),
        .c0_ddr4_adr(c0_ddr4_adr),
        .c0_ddr4_ba(c0_ddr4_ba),
        .c0_ddr4_bg(c0_ddr4_bg),
        .c0_ddr4_ck_c(c0_ddr4_ck_c),
        .c0_ddr4_ck_t(c0_ddr4_ck_t),
        .c0_ddr4_cke(c0_ddr4_cke),
        .c0_ddr4_cs_n(c0_ddr4_cs_n),
        .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),
        .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c),
        .c0_ddr4_dqs_t(c0_ddr4_dqs_t),
        .c0_ddr4_odt(c0_ddr4_odt),
        .c0_ddr4_reset_n(c0_ddr4_reset_n),
        .soc_clk(camera_ref_clk),
        .soc_resetn(soc_resetn),
        .soc_mem_axi(soc_mem_axi),
        .fbus_axi(soc_fbus_axi),
        .framebuffer_axil(framebuffer_axil),
        .camera_capture_channels(camera_capture_channels),
        .hdmi_capture_channels(hdmi_capture_channels),
        .hdmi_capture_enable(hdmi_capture_enable),
        .hdmi_transport_frame_count(hdmi_transport_frame_count),
        .hdmi_transport_malformed_count(hdmi_transport_malformed_count),
        .hdmi_channel_overflow_counts(hdmi_channel_overflow_counts),
        .hdmi_channel_frame_counts(hdmi_channel_frame_counts),
        .camera_axis_diag(camera_axis_diag),
        .malformed_counts(camera_malformed_counts),
        .video_axis(ddr_video_axis),
        .capture_clk(capture_clk), .capture_resetn(capture_resetn),
        .video_clk(video_clk), .video_resetn(video_resetn)
    );

    camera_hdmi_subsystem u_camera_hdmi (
        .sys_rstn(sys_rstn), .sys_init_done(camera_sys_init_done),
        .camera_ref_clk(camera_ref_clk),
        .mmio_axi(soc_mmio_axi), .display_axis(ddr_video_axis),
        .camera_capture_channels(camera_capture_channels),
        .hdmi_capture_channels(hdmi_capture_channels),
        .hdmi_capture_enable(hdmi_capture_enable),
        .framebuffer_axil(framebuffer_axil),
        .capture_clk(capture_clk), .capture_resetn(capture_resetn),
        .video_clk(video_clk), .video_resetn(video_resetn),
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
        .hdmi_clkchip_scl(hdmi_clkchip_scl), .hdmi_clkchip_sda(hdmi_clkchip_sda),
        .hdmi_clkchip_lol(hdmi_clkchip_lol), .hdmi_clkchip_int(hdmi_clkchip_int),
        .hdmi_clkchip_rst(hdmi_clkchip_rst),
        .camera_axis_diag(camera_axis_diag),
        .malformed_counts(camera_malformed_counts),
        .hdmi_transport_frame_count(hdmi_transport_frame_count),
        .hdmi_transport_malformed_count(hdmi_transport_malformed_count),
        .hdmi_channel_overflow_counts(hdmi_channel_overflow_counts),
        .hdmi_channel_frame_counts(hdmi_channel_frame_counts),
        .cam_rst_n(ov7670_reset_n_drive),
        .cam_pwdn(ov7670_pwdn_drive), .cam_scl(ov7670_scl_drive),
        .cam_sda(cam_sda), .cam_xclk(ov7670_xclk_drive),
        .cam_xclk_pad(ov7670_xclk_pad),
        .cam_rst_n_pad(ov7670_reset_n_pad),
        .cam_pwdn_pad(ov7670_pwdn_pad), .cam_scl_pad(ov7670_scl_pad),
        .cam_pclk(ov7670_pclk_ibuf),
        .cam_vsync(cam_vsync), .cam_href(cam_href), .cam_data(cam_data),
        .camera_pll_locked(camera_pll_locked),
        .video_interrupts(video_interrupts)
    );
endmodule
