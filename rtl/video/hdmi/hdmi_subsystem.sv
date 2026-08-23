`timescale 1ns/1ps

// HDMI integration boundary. The control plane is shared, while RX, TX and
// the common physical layer are explicit child subsystems.
module hdmi_subsystem (
    axi4_if.slave mmio_axi,
    axis_video_if.sink display_axis,
    axis_video_if.source capture_axis,
    axi_lite_if.master framebuffer_axil,
    axi_lite_if.master camera_axil [8],
    input wire capture_clk,
    input wire capture_resetn,

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
    output wire [7:0] video_interrupts
);
    axi_lite_if #(.ADDR_WIDTH(10)) vphy_axil();
    axi_lite_if #(.ADDR_WIDTH(16)) hdmi_rx_axil();
    axi_lite_if #(.ADDR_WIDTH(17)) hdmi_tx_axil();
    wire [4:0] gpio_in;
    wire [31:0] gpio_out;
    wire gpio_irq, iic_irq, vphy_irq, hdmi_rx_irq, hdmi_tx_irq;
    wire txoutclk, rxoutclk, tx_video_clk, rx_video_clk;
    wire [7:0] tx_sb_data, rx_sb_data;
    wire tx_sb_valid, rx_sb_valid;
    wire [2:0][39:0] tx_link_data, rx_link_data;
    wire [2:0] tx_link_valid, rx_link_valid;

    assign gpio_in = {hdmi_tx_locked, hdmi_clkchip_int, hdmi_clkchip_lol,
                      hdmi_tx_hpd, hdmi_rx_pwr_det};
    assign hdmi_tx_en = gpio_out[0];
    assign hdmi_clkchip_rst = gpio_out[1];

    video_control_subsystem u_control (
        .mmio_axi(mmio_axi), .vphy_axil(vphy_axil),
        .hdmi_rx_axil(hdmi_rx_axil), .hdmi_tx_axil(hdmi_tx_axil),
        .framebuffer_axil(framebuffer_axil), .camera_axil(camera_axil),
        .gpio_in(gpio_in), .gpio_out(gpio_out),
        .hdmi_ctl_iic_scl(hdmi_clkchip_scl),
        .hdmi_ctl_iic_sda(hdmi_clkchip_sda),
        .gpio_irq(gpio_irq), .iic_irq(iic_irq)
    );

    hdmi_rx_subsystem u_rx (
        .capture_axis(capture_axis), .hdmi_rx_axil(hdmi_rx_axil),
        .capture_clk(capture_clk), .capture_resetn(capture_resetn),
        .rxoutclk(rxoutclk), .rx_video_clk(rx_video_clk),
        .rx_link_data(rx_link_data), .rx_link_valid(rx_link_valid),
        .rx_sb_data(rx_sb_data), .rx_sb_valid(rx_sb_valid),
        .hdmi_rx_pwr_det(hdmi_rx_pwr_det), .hdmi_rx_hpd(hdmi_rx_hpd),
        .hdmi_rx_ddc_scl(hdmi_rx_ddc_scl),
        .hdmi_rx_ddc_sda(hdmi_rx_ddc_sda), .hdmi_rx_irq(hdmi_rx_irq)
    );

    hdmi_tx_subsystem u_tx (
        .video_axis(display_axis), .hdmi_tx_axil(hdmi_tx_axil),
        .txoutclk(txoutclk), .tx_video_clk(tx_video_clk),
        .tx_sb_data(tx_sb_data), .tx_sb_valid(tx_sb_valid),
        .tx_link_data(tx_link_data), .tx_link_valid(tx_link_valid),
        .hdmi_tx_hpd(hdmi_tx_hpd), .hdmi_tx_ddc_scl(hdmi_tx_ddc_scl),
        .hdmi_tx_ddc_sda(hdmi_tx_ddc_sda),
        .hdmi_tx_locked(hdmi_tx_locked), .hdmi_tx_irq(hdmi_tx_irq)
    );

    hdmi_phy_subsystem u_phy (
        .vphy_axil(vphy_axil),
        .hdmi_rx_clk_p(hdmi_rx_clk_p), .hdmi_rx_clk_n(hdmi_rx_clk_n),
        .hdmi_rx_data_p(hdmi_rx_data_p), .hdmi_rx_data_n(hdmi_rx_data_n),
        .hdmi_ref_clk_p(hdmi_ref_clk_p), .hdmi_ref_clk_n(hdmi_ref_clk_n),
        .hdmi_tx_refclk_p(hdmi_tx_refclk_p),
        .hdmi_tx_refclk_n(hdmi_tx_refclk_n),
        .tx_refclk_rdy(hdmi_clkchip_lol),
        .hdmi_tx_data_p(hdmi_tx_data_p), .hdmi_tx_data_n(hdmi_tx_data_n),
        .tx_link_data(tx_link_data), .tx_link_valid(tx_link_valid),
        .rx_link_data(rx_link_data), .rx_link_valid(rx_link_valid),
        .tx_sb_data(tx_sb_data), .tx_sb_valid(tx_sb_valid),
        .rx_sb_data(rx_sb_data), .rx_sb_valid(rx_sb_valid),
        .txoutclk(txoutclk), .rxoutclk(rxoutclk),
        .tx_video_clk(tx_video_clk), .rx_video_clk(rx_video_clk),
        .vphy_irq(vphy_irq)
    );

    assign video_interrupts = {3'b000, hdmi_tx_irq, hdmi_rx_irq,
                               vphy_irq, iic_irq, gpio_irq};
endmodule
