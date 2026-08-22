`timescale 1ns/1ps

module video_control_subsystem (
    axi4_if.slave       mmio_axi,
    axi_lite_if.master  vphy_axil,
    axi_lite_if.master  hdmi_rx_axil,
    axi_lite_if.master  hdmi_tx_axil,
    axi_lite_if.master  framebuffer_axil,
    axi_lite_if.master  camera_axil [8],
    input  wire [4:0]   gpio_in,
    output wire [31:0]  gpio_out,
    inout  wire         hdmi_ctl_iic_scl,
    inout  wire         hdmi_ctl_iic_sda,
    output wire         gpio_irq,
    output wire         iic_irq
);
    wire [5:0][17:0] m_awaddr;
    wire [5:0][2:0]  m_awprot;
    wire [5:0]       m_awvalid;
    wire [5:0]       m_awready;
    wire [5:0][31:0] m_wdata;
    wire [5:0][3:0]  m_wstrb;
    wire [5:0]       m_wvalid;
    wire [5:0]       m_wready;
    wire [5:0][1:0]  m_bresp;
    wire [5:0]       m_bvalid;
    wire [5:0]       m_bready;
    wire [5:0][17:0] m_araddr;
    wire [5:0][2:0]  m_arprot;
    wire [5:0]       m_arvalid;
    wire [5:0]       m_arready;
    wire [5:0][31:0] m_rdata;
    wire [5:0][1:0]  m_rresp;
    wire [5:0]       m_rvalid;
    wire [5:0]       m_rready;
    wire ctl_scl_i, ctl_scl_o, ctl_scl_t;
    wire ctl_sda_i, ctl_sda_o, ctl_sda_t;
    axi_lite_if #(.ADDR_WIDTH(18)) peripheral_axil();

    IOBUF u_ctl_scl_iobuf (
        .I(ctl_scl_o), .O(ctl_scl_i), .T(ctl_scl_t), .IO(hdmi_ctl_iic_scl)
    );
    IOBUF u_ctl_sda_iobuf (
        .I(ctl_sda_o), .O(ctl_sda_i), .T(ctl_sda_t), .IO(hdmi_ctl_iic_sda)
    );

    video_mmio_fabric u_mmio_fabric (
        .aclk(mmio_axi.aclk), .aresetn(mmio_axi.aresetn),
        .s_awid(mmio_axi.awid), .s_awaddr(mmio_axi.awaddr),
        .s_awlen(mmio_axi.awlen), .s_awsize(mmio_axi.awsize),
        .s_awburst(mmio_axi.awburst), .s_awlock(mmio_axi.awlock),
        .s_awcache(mmio_axi.awcache), .s_awprot(mmio_axi.awprot),
        .s_awqos(mmio_axi.awqos), .s_awvalid(mmio_axi.awvalid),
        .s_awready(mmio_axi.awready), .s_wdata(mmio_axi.wdata),
        .s_wstrb(mmio_axi.wstrb), .s_wlast(mmio_axi.wlast),
        .s_wvalid(mmio_axi.wvalid), .s_wready(mmio_axi.wready),
        .s_bid(mmio_axi.bid), .s_bresp(mmio_axi.bresp),
        .s_bvalid(mmio_axi.bvalid), .s_bready(mmio_axi.bready),
        .s_arid(mmio_axi.arid), .s_araddr(mmio_axi.araddr),
        .s_arlen(mmio_axi.arlen), .s_arsize(mmio_axi.arsize),
        .s_arburst(mmio_axi.arburst), .s_arlock(mmio_axi.arlock),
        .s_arcache(mmio_axi.arcache), .s_arprot(mmio_axi.arprot),
        .s_arqos(mmio_axi.arqos), .s_arvalid(mmio_axi.arvalid),
        .s_arready(mmio_axi.arready), .s_rid(mmio_axi.rid),
        .s_rdata(mmio_axi.rdata), .s_rresp(mmio_axi.rresp),
        .s_rlast(mmio_axi.rlast), .s_rvalid(mmio_axi.rvalid),
        .s_rready(mmio_axi.rready),
        .m_awaddr(m_awaddr), .m_awprot(m_awprot),
        .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_wdata(m_wdata), .m_wstrb(m_wstrb),
        .m_wvalid(m_wvalid), .m_wready(m_wready),
        .m_bresp(m_bresp), .m_bvalid(m_bvalid), .m_bready(m_bready),
        .m_araddr(m_araddr), .m_arprot(m_arprot),
        .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_rdata(m_rdata), .m_rresp(m_rresp),
        .m_rvalid(m_rvalid), .m_rready(m_rready)
    );

    axi_gpio_0 u_gpio (
        .s_axi_aclk(mmio_axi.aclk), .s_axi_aresetn(mmio_axi.aresetn),
        .s_axi_awaddr(m_awaddr[0][8:0]),
        .s_axi_awvalid(m_awvalid[0]), .s_axi_awready(m_awready[0]),
        .s_axi_wdata(m_wdata[0]), .s_axi_wstrb(m_wstrb[0]),
        .s_axi_wvalid(m_wvalid[0]), .s_axi_wready(m_wready[0]),
        .s_axi_bresp(m_bresp[0]), .s_axi_bvalid(m_bvalid[0]),
        .s_axi_bready(m_bready[0]), .s_axi_araddr(m_araddr[0][8:0]),
        .s_axi_arvalid(m_arvalid[0]), .s_axi_arready(m_arready[0]),
        .s_axi_rdata(m_rdata[0]), .s_axi_rresp(m_rresp[0]),
        .s_axi_rvalid(m_rvalid[0]), .s_axi_rready(m_rready[0]),
        .gpio_io_o(gpio_out), .gpio2_io_i(gpio_in),
        .ip2intc_irpt(gpio_irq)
    );

    axi_iic_0 u_iic (
        .s_axi_aclk(mmio_axi.aclk), .s_axi_aresetn(mmio_axi.aresetn),
        .s_axi_awaddr(m_awaddr[1][8:0]),
        .s_axi_awvalid(m_awvalid[1]), .s_axi_awready(m_awready[1]),
        .s_axi_wdata(m_wdata[1]), .s_axi_wstrb(m_wstrb[1]),
        .s_axi_wvalid(m_wvalid[1]), .s_axi_wready(m_wready[1]),
        .s_axi_bresp(m_bresp[1]), .s_axi_bvalid(m_bvalid[1]),
        .s_axi_bready(m_bready[1]), .s_axi_araddr(m_araddr[1][8:0]),
        .s_axi_arvalid(m_arvalid[1]), .s_axi_arready(m_arready[1]),
        .s_axi_rdata(m_rdata[1]), .s_axi_rresp(m_rresp[1]),
        .s_axi_rvalid(m_rvalid[1]), .s_axi_rready(m_rready[1]),
        .scl_i(ctl_scl_i), .scl_o(ctl_scl_o), .scl_t(ctl_scl_t),
        .sda_i(ctl_sda_i), .sda_o(ctl_sda_o), .sda_t(ctl_sda_t),
        .iic2intc_irpt(iic_irq)
    );

    assign vphy_axil.aclk    = mmio_axi.aclk;
    assign vphy_axil.aresetn = mmio_axi.aresetn;
    assign vphy_axil.awaddr  = m_awaddr[2][9:0];
    assign vphy_axil.awprot  = m_awprot[2];
    assign vphy_axil.awvalid = m_awvalid[2];
    assign m_awready[2]      = vphy_axil.awready;
    assign vphy_axil.wdata   = m_wdata[2];
    assign vphy_axil.wstrb   = m_wstrb[2];
    assign vphy_axil.wvalid  = m_wvalid[2];
    assign m_wready[2]       = vphy_axil.wready;
    assign m_bresp[2]        = vphy_axil.bresp;
    assign m_bvalid[2]       = vphy_axil.bvalid;
    assign vphy_axil.bready  = m_bready[2];
    assign vphy_axil.araddr  = m_araddr[2][9:0];
    assign vphy_axil.arprot  = m_arprot[2];
    assign vphy_axil.arvalid = m_arvalid[2];
    assign m_arready[2]      = vphy_axil.arready;
    assign m_rdata[2]        = vphy_axil.rdata;
    assign m_rresp[2]        = vphy_axil.rresp;
    assign m_rvalid[2]       = vphy_axil.rvalid;
    assign vphy_axil.rready  = m_rready[2];

    assign hdmi_tx_axil.aclk    = mmio_axi.aclk;
    assign hdmi_tx_axil.aresetn = mmio_axi.aresetn;
    assign hdmi_tx_axil.awaddr  = m_awaddr[4][16:0];
    assign hdmi_tx_axil.awprot  = m_awprot[4];
    assign hdmi_tx_axil.awvalid = m_awvalid[4];
    assign m_awready[4]         = hdmi_tx_axil.awready;
    assign hdmi_tx_axil.wdata   = m_wdata[4];
    assign hdmi_tx_axil.wstrb   = m_wstrb[4];
    assign hdmi_tx_axil.wvalid  = m_wvalid[4];
    assign m_wready[4]          = hdmi_tx_axil.wready;
    assign m_bresp[4]           = hdmi_tx_axil.bresp;
    assign m_bvalid[4]          = hdmi_tx_axil.bvalid;
    assign hdmi_tx_axil.bready  = m_bready[4];
    assign hdmi_tx_axil.araddr  = m_araddr[4][16:0];
    assign hdmi_tx_axil.arprot  = m_arprot[4];
    assign hdmi_tx_axil.arvalid = m_arvalid[4];
    assign m_arready[4]         = hdmi_tx_axil.arready;
    assign m_rdata[4]           = hdmi_tx_axil.rdata;
    assign m_rresp[4]           = hdmi_tx_axil.rresp;
    assign m_rvalid[4]          = hdmi_tx_axil.rvalid;
    assign hdmi_tx_axil.rready  = m_rready[4];

    assign hdmi_rx_axil.aclk    = mmio_axi.aclk;
    assign hdmi_rx_axil.aresetn = mmio_axi.aresetn;
    assign hdmi_rx_axil.awaddr  = m_awaddr[3][15:0];
    assign hdmi_rx_axil.awprot  = m_awprot[3];
    assign hdmi_rx_axil.awvalid = m_awvalid[3];
    assign m_awready[3]         = hdmi_rx_axil.awready;
    assign hdmi_rx_axil.wdata   = m_wdata[3];
    assign hdmi_rx_axil.wstrb   = m_wstrb[3];
    assign hdmi_rx_axil.wvalid  = m_wvalid[3];
    assign m_wready[3]          = hdmi_rx_axil.wready;
    assign m_bresp[3]           = hdmi_rx_axil.bresp;
    assign m_bvalid[3]          = hdmi_rx_axil.bvalid;
    assign hdmi_rx_axil.bready  = m_bready[3];
    assign hdmi_rx_axil.araddr  = m_araddr[3][15:0];
    assign hdmi_rx_axil.arprot  = m_arprot[3];
    assign hdmi_rx_axil.arvalid = m_arvalid[3];
    assign m_arready[3]         = hdmi_rx_axil.arready;
    assign m_rdata[3]           = hdmi_rx_axil.rdata;
    assign m_rresp[3]           = hdmi_rx_axil.rresp;
    assign m_rvalid[3]          = hdmi_rx_axil.rvalid;
    assign hdmi_rx_axil.rready  = m_rready[3];

    assign peripheral_axil.aclk    = mmio_axi.aclk;
    assign peripheral_axil.aresetn = mmio_axi.aresetn;
    assign peripheral_axil.awaddr  = m_awaddr[5];
    assign peripheral_axil.awprot  = m_awprot[5];
    assign peripheral_axil.awvalid = m_awvalid[5];
    assign m_awready[5]            = peripheral_axil.awready;
    assign peripheral_axil.wdata   = m_wdata[5];
    assign peripheral_axil.wstrb   = m_wstrb[5];
    assign peripheral_axil.wvalid  = m_wvalid[5];
    assign m_wready[5]             = peripheral_axil.wready;
    assign m_bresp[5]              = peripheral_axil.bresp;
    assign m_bvalid[5]             = peripheral_axil.bvalid;
    assign peripheral_axil.bready  = m_bready[5];
    assign peripheral_axil.araddr  = m_araddr[5];
    assign peripheral_axil.arprot  = m_arprot[5];
    assign peripheral_axil.arvalid = m_arvalid[5];
    assign m_arready[5]            = peripheral_axil.arready;
    assign m_rdata[5]              = peripheral_axil.rdata;
    assign m_rresp[5]              = peripheral_axil.rresp;
    assign m_rvalid[5]             = peripheral_axil.rvalid;
    assign peripheral_axil.rready  = m_rready[5];

    video_peripheral_fabric u_peripheral_fabric (
        .s_axil(peripheral_axil),
        .framebuffer_axil(framebuffer_axil),
        .camera_axil(camera_axil)
    );
endmodule
