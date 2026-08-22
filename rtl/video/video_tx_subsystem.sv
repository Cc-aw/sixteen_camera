`timescale 1ns/1ps

// TX-only video boundary.  The control plane remains on Rocket's 100 MHz
// AXI4-MMIO clock while the display AXIS keeps the DDR reader clock domain.
module video_tx_subsystem (
    axi4_if.slave       mmio_axi,
    axis_video_if.sink  display_axis,
    axis_video_if.source capture_axis,
    axi_lite_if.master  framebuffer_axil,
    axi_lite_if.master  camera_axil [8],
    input wire          capture_clk,
    input wire          capture_resetn,

    input  wire           hdmi_rx_clk_p,
    input  wire           hdmi_rx_clk_n,
    input  wire [2:0]     hdmi_rx_data_p,
    input  wire [2:0]     hdmi_rx_data_n,
    output wire           hdmi_ref_clk_p,
    output wire           hdmi_ref_clk_n,
    input  wire           hdmi_tx_refclk_p,
    input  wire           hdmi_tx_refclk_n,
    input  wire           hdmi_tx_hpd,
    inout  wire           hdmi_tx_ddc_scl,
    inout  wire           hdmi_tx_ddc_sda,
    output wire [3:0]     hdmi_tx_data_p,
    output wire [3:0]     hdmi_tx_data_n,
    output wire           hdmi_tx_en,
    output wire           hdmi_tx_locked,

    input  wire           hdmi_rx_pwr_det,
    output wire           hdmi_rx_hpd,
    inout  wire           hdmi_rx_ddc_scl,
    inout  wire           hdmi_rx_ddc_sda,
    inout  wire           hdmi_clkchip_scl,
    inout  wire           hdmi_clkchip_sda,
    input  wire           hdmi_clkchip_lol,
    input  wire           hdmi_clkchip_int,
    output wire           hdmi_clkchip_rst,
    output wire [7:0]     video_interrupts
);
    axi_lite_if #(.ADDR_WIDTH(10)) vphy_axil();
    axi_lite_if #(.ADDR_WIDTH(16)) hdmi_rx_axil();
    axi_lite_if #(.ADDR_WIDTH(17)) hdmi_tx_axil();
    wire [4:0] gpio_in;
    wire [31:0] gpio_out;
    wire gpio_irq, iic_irq, vphy_irq, hdmi_rx_irq, hdmi_tx_irq;

    assign gpio_in = {hdmi_tx_locked, hdmi_clkchip_int, hdmi_clkchip_lol,
                      hdmi_tx_hpd, hdmi_rx_pwr_det};
    assign hdmi_tx_en = gpio_out[0];
    assign hdmi_clkchip_rst = gpio_out[1];

    video_control_subsystem u_control (
        .mmio_axi(mmio_axi), .vphy_axil(vphy_axil),
        .hdmi_rx_axil(hdmi_rx_axil), .hdmi_tx_axil(hdmi_tx_axil),
        .framebuffer_axil(framebuffer_axil),
        .camera_axil(camera_axil),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out), .hdmi_ctl_iic_scl(hdmi_clkchip_scl),
        .hdmi_ctl_iic_sda(hdmi_clkchip_sda),
        .gpio_irq(gpio_irq), .iic_irq(iic_irq)
    );

    hdmi_tx_datapath u_datapath (
        .video_axis(display_axis), .capture_axis(capture_axis),
        .vphy_axil(vphy_axil), .hdmi_rx_axil(hdmi_rx_axil),
        .hdmi_tx_axil(hdmi_tx_axil), .capture_clk(capture_clk),
        .capture_resetn(capture_resetn),
        .hdmi_rx_clk_p(hdmi_rx_clk_p), .hdmi_rx_clk_n(hdmi_rx_clk_n),
        .hdmi_rx_data_p(hdmi_rx_data_p), .hdmi_rx_data_n(hdmi_rx_data_n),
        .hdmi_rx_pwr_det(hdmi_rx_pwr_det), .hdmi_rx_hpd(hdmi_rx_hpd),
        .hdmi_rx_ddc_scl(hdmi_rx_ddc_scl),
        .hdmi_rx_ddc_sda(hdmi_rx_ddc_sda),
        .hdmi_ref_clk_p(hdmi_ref_clk_p), .hdmi_ref_clk_n(hdmi_ref_clk_n),
        .hdmi_tx_refclk_p(hdmi_tx_refclk_p),
        .hdmi_tx_refclk_n(hdmi_tx_refclk_n),
        .tx_refclk_rdy(hdmi_clkchip_lol),
        .hdmi_tx_data_p(hdmi_tx_data_p), .hdmi_tx_data_n(hdmi_tx_data_n),
        .hdmi_tx_hpd(hdmi_tx_hpd),
        .hdmi_tx_ddc_scl(hdmi_tx_ddc_scl),
        .hdmi_tx_ddc_sda(hdmi_tx_ddc_sda),
        .hdmi_tx_locked(hdmi_tx_locked), .vphy_irq(vphy_irq),
        .hdmi_rx_irq(hdmi_rx_irq),
        .hdmi_tx_irq(hdmi_tx_irq)
    );

    assign video_interrupts = {3'b000, hdmi_tx_irq, hdmi_rx_irq,
                                vphy_irq, iic_irq, gpio_irq};
endmodule
