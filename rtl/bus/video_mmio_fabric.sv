`timescale 1ns/1ps

module video_mmio_fabric (
    input  wire         aclk,
    input  wire         aresetn,

    input  wire [3:0]   s_awid,
    input  wire [30:0]  s_awaddr,
    input  wire [7:0]   s_awlen,
    input  wire [2:0]   s_awsize,
    input  wire [1:0]   s_awburst,
    input  wire         s_awlock,
    input  wire [3:0]   s_awcache,
    input  wire [2:0]   s_awprot,
    input  wire [3:0]   s_awqos,
    input  wire         s_awvalid,
    output wire         s_awready,
    input  wire [63:0]  s_wdata,
    input  wire [7:0]   s_wstrb,
    input  wire         s_wlast,
    input  wire         s_wvalid,
    output wire         s_wready,
    output wire [3:0]   s_bid,
    output wire [1:0]   s_bresp,
    output wire         s_bvalid,
    input  wire         s_bready,
    input  wire [3:0]   s_arid,
    input  wire [30:0]  s_araddr,
    input  wire [7:0]   s_arlen,
    input  wire [2:0]   s_arsize,
    input  wire [1:0]   s_arburst,
    input  wire         s_arlock,
    input  wire [3:0]   s_arcache,
    input  wire [2:0]   s_arprot,
    input  wire [3:0]   s_arqos,
    input  wire         s_arvalid,
    output wire         s_arready,
    output wire [3:0]   s_rid,
    output wire [63:0]  s_rdata,
    output wire [1:0]   s_rresp,
    output wire         s_rlast,
    output wire         s_rvalid,
    input  wire         s_rready,

    output wire [5:0][17:0] m_awaddr,
    output wire [5:0][2:0]  m_awprot,
    output wire [5:0]       m_awvalid,
    input  wire [5:0]       m_awready,
    output wire [5:0][31:0] m_wdata,
    output wire [5:0][3:0]  m_wstrb,
    output wire [5:0]       m_wvalid,
    input  wire [5:0]       m_wready,
    input  wire [5:0][1:0]  m_bresp,
    input  wire [5:0]       m_bvalid,
    output wire [5:0]       m_bready,
    output wire [5:0][17:0] m_araddr,
    output wire [5:0][2:0]  m_arprot,
    output wire [5:0]       m_arvalid,
    input  wire [5:0]       m_arready,
    input  wire [5:0][31:0] m_rdata,
    input  wire [5:0][1:0]  m_rresp,
    input  wire [5:0]       m_rvalid,
    output wire [5:0]       m_rready
);

    video_ctrl_bd_smartconnect_0_0 u_control_smartconnect (
        .aclk(aclk), .aresetn(aresetn),
        .S00_AXI_awid(s_awid), .S00_AXI_awaddr(s_awaddr),
        .S00_AXI_awlen(s_awlen), .S00_AXI_awsize(s_awsize),
        .S00_AXI_awburst(s_awburst), .S00_AXI_awlock(s_awlock),
        .S00_AXI_awcache(s_awcache), .S00_AXI_awprot(s_awprot),
        .S00_AXI_awqos(s_awqos), .S00_AXI_awvalid(s_awvalid),
        .S00_AXI_awready(s_awready), .S00_AXI_wdata(s_wdata),
        .S00_AXI_wstrb(s_wstrb), .S00_AXI_wlast(s_wlast),
        .S00_AXI_wvalid(s_wvalid), .S00_AXI_wready(s_wready),
        .S00_AXI_bid(s_bid), .S00_AXI_bresp(s_bresp),
        .S00_AXI_bvalid(s_bvalid), .S00_AXI_bready(s_bready),
        .S00_AXI_arid(s_arid), .S00_AXI_araddr(s_araddr),
        .S00_AXI_arlen(s_arlen), .S00_AXI_arsize(s_arsize),
        .S00_AXI_arburst(s_arburst), .S00_AXI_arlock(s_arlock),
        .S00_AXI_arcache(s_arcache), .S00_AXI_arprot(s_arprot),
        .S00_AXI_arqos(s_arqos), .S00_AXI_arvalid(s_arvalid),
        .S00_AXI_arready(s_arready), .S00_AXI_rid(s_rid),
        .S00_AXI_rdata(s_rdata), .S00_AXI_rresp(s_rresp),
        .S00_AXI_rlast(s_rlast), .S00_AXI_rvalid(s_rvalid),
        .S00_AXI_rready(s_rready),

        .M00_AXI_awaddr(m_awaddr[0][8:0]), .M00_AXI_awprot(m_awprot[0]),
        .M00_AXI_awvalid(m_awvalid[0]), .M00_AXI_awready(m_awready[0]),
        .M00_AXI_wdata(m_wdata[0]), .M00_AXI_wstrb(m_wstrb[0]),
        .M00_AXI_wvalid(m_wvalid[0]), .M00_AXI_wready(m_wready[0]),
        .M00_AXI_bresp(m_bresp[0]), .M00_AXI_bvalid(m_bvalid[0]),
        .M00_AXI_bready(m_bready[0]), .M00_AXI_araddr(m_araddr[0][8:0]),
        .M00_AXI_arprot(m_arprot[0]), .M00_AXI_arvalid(m_arvalid[0]),
        .M00_AXI_arready(m_arready[0]), .M00_AXI_rdata(m_rdata[0]),
        .M00_AXI_rresp(m_rresp[0]), .M00_AXI_rvalid(m_rvalid[0]),
        .M00_AXI_rready(m_rready[0]),

        .M01_AXI_awaddr(m_awaddr[1][8:0]), .M01_AXI_awprot(m_awprot[1]),
        .M01_AXI_awvalid(m_awvalid[1]), .M01_AXI_awready(m_awready[1]),
        .M01_AXI_wdata(m_wdata[1]), .M01_AXI_wstrb(m_wstrb[1]),
        .M01_AXI_wvalid(m_wvalid[1]), .M01_AXI_wready(m_wready[1]),
        .M01_AXI_bresp(m_bresp[1]), .M01_AXI_bvalid(m_bvalid[1]),
        .M01_AXI_bready(m_bready[1]), .M01_AXI_araddr(m_araddr[1][8:0]),
        .M01_AXI_arprot(m_arprot[1]), .M01_AXI_arvalid(m_arvalid[1]),
        .M01_AXI_arready(m_arready[1]), .M01_AXI_rdata(m_rdata[1]),
        .M01_AXI_rresp(m_rresp[1]), .M01_AXI_rvalid(m_rvalid[1]),
        .M01_AXI_rready(m_rready[1]),

        .M02_AXI_awaddr(m_awaddr[2][9:0]), .M02_AXI_awprot(m_awprot[2]),
        .M02_AXI_awvalid(m_awvalid[2]), .M02_AXI_awready(m_awready[2]),
        .M02_AXI_wdata(m_wdata[2]), .M02_AXI_wstrb(m_wstrb[2]),
        .M02_AXI_wvalid(m_wvalid[2]), .M02_AXI_wready(m_wready[2]),
        .M02_AXI_bresp(m_bresp[2]), .M02_AXI_bvalid(m_bvalid[2]),
        .M02_AXI_bready(m_bready[2]), .M02_AXI_araddr(m_araddr[2][9:0]),
        .M02_AXI_arprot(m_arprot[2]), .M02_AXI_arvalid(m_arvalid[2]),
        .M02_AXI_arready(m_arready[2]), .M02_AXI_rdata(m_rdata[2]),
        .M02_AXI_rresp(m_rresp[2]), .M02_AXI_rvalid(m_rvalid[2]),
        .M02_AXI_rready(m_rready[2]),

        .M03_AXI_awaddr(m_awaddr[3][15:0]), .M03_AXI_awprot(m_awprot[3]),
        .M03_AXI_awvalid(m_awvalid[3]), .M03_AXI_awready(m_awready[3]),
        .M03_AXI_wdata(m_wdata[3]), .M03_AXI_wstrb(m_wstrb[3]),
        .M03_AXI_wvalid(m_wvalid[3]), .M03_AXI_wready(m_wready[3]),
        .M03_AXI_bresp(m_bresp[3]), .M03_AXI_bvalid(m_bvalid[3]),
        .M03_AXI_bready(m_bready[3]), .M03_AXI_araddr(m_araddr[3][15:0]),
        .M03_AXI_arprot(m_arprot[3]), .M03_AXI_arvalid(m_arvalid[3]),
        .M03_AXI_arready(m_arready[3]), .M03_AXI_rdata(m_rdata[3]),
        .M03_AXI_rresp(m_rresp[3]), .M03_AXI_rvalid(m_rvalid[3]),
        .M03_AXI_rready(m_rready[3]),

        .M04_AXI_awaddr(m_awaddr[4][16:0]), .M04_AXI_awprot(m_awprot[4]),
        .M04_AXI_awvalid(m_awvalid[4]), .M04_AXI_awready(m_awready[4]),
        .M04_AXI_wdata(m_wdata[4]), .M04_AXI_wstrb(m_wstrb[4]),
        .M04_AXI_wvalid(m_wvalid[4]), .M04_AXI_wready(m_wready[4]),
        .M04_AXI_bresp(m_bresp[4]), .M04_AXI_bvalid(m_bvalid[4]),
        .M04_AXI_bready(m_bready[4]), .M04_AXI_araddr(m_araddr[4][16:0]),
        .M04_AXI_arprot(m_arprot[4]), .M04_AXI_arvalid(m_arvalid[4]),
        .M04_AXI_arready(m_arready[4]), .M04_AXI_rdata(m_rdata[4]),
        .M04_AXI_rresp(m_rresp[4]), .M04_AXI_rvalid(m_rvalid[4]),
        .M04_AXI_rready(m_rready[4]),

        .M05_AXI_awaddr(m_awaddr[5]), .M05_AXI_awprot(m_awprot[5]),
        .M05_AXI_awvalid(m_awvalid[5]), .M05_AXI_awready(m_awready[5]),
        .M05_AXI_wdata(m_wdata[5]), .M05_AXI_wstrb(m_wstrb[5]),
        .M05_AXI_wvalid(m_wvalid[5]), .M05_AXI_wready(m_wready[5]),
        .M05_AXI_bresp(m_bresp[5]), .M05_AXI_bvalid(m_bvalid[5]),
        .M05_AXI_bready(m_bready[5]), .M05_AXI_araddr(m_araddr[5]),
        .M05_AXI_arprot(m_arprot[5]), .M05_AXI_arvalid(m_arvalid[5]),
        .M05_AXI_arready(m_arready[5]), .M05_AXI_rdata(m_rdata[5]),
        .M05_AXI_rresp(m_rresp[5]), .M05_AXI_rvalid(m_rvalid[5]),
        .M05_AXI_rready(m_rready[5])
    );

    genvar i;
    generate for (i=0; i<6; i=i+1) begin : g_zero_extend
        if (i==0 || i==1) begin
            assign m_awaddr[i][17:9] = 0;
            assign m_araddr[i][17:9] = 0;
        end else if (i==2) begin
            assign m_awaddr[i][17:10] = 0;
            assign m_araddr[i][17:10] = 0;
        end else if (i==3) begin
            assign m_awaddr[i][17:16] = 0;
            assign m_araddr[i][17:16] = 0;
        end else if (i==4) begin
            assign m_awaddr[i][17] = 0;
            assign m_araddr[i][17] = 0;
        end
    end endgenerate

endmodule

