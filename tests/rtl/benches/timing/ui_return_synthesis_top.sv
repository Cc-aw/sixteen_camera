module ui_return_synthesis_top (
    input wire video_clk, video_resetn, ui_clk, ui_resetn,
    input wire [2:0] s_arid,
    input wire [31:0] s_araddr,
    input wire [7:0] s_arlen,
    input wire s_arvalid,
    output wire s_arready,
    output wire [2:0] m_arid,
    output wire [31:0] m_araddr,
    output wire [7:0] m_arlen,
    output wire m_arvalid,
    input wire m_arready,
    input wire [2:0] m_rid,
    input wire [255:0] m_rdata,
    input wire [1:0] m_rresp,
    input wire m_rlast, m_rvalid,
    output wire m_rready,
    output wire [2:0] s_rid,
    output wire [255:0] s_rdata,
    output wire [1:0] s_rresp,
    output wire s_rlast, s_rvalid,
    input wire s_rready
);
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) s_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) m_axi();
    assign s_axi.aclk = video_clk;
    assign s_axi.aresetn = video_resetn;
    assign s_axi.arid = s_arid;
    assign s_axi.araddr = s_araddr;
    assign s_axi.arlen = s_arlen;
    assign s_axi.arsize = 3'd5;
    assign s_axi.arburst = 2'd1;
    assign s_axi.arlock = 0;
    assign s_axi.arcache = 0;
    assign s_axi.arprot = 0;
    assign s_axi.arqos = 0;
    assign s_axi.arvalid = s_arvalid;
    assign s_arready = s_axi.arready;
    assign m_arid = m_axi.arid;
    assign m_araddr = m_axi.araddr;
    assign m_arlen = m_axi.arlen;
    assign m_arvalid = m_axi.arvalid;
    assign m_axi.arready = m_arready;
    assign m_axi.rid = m_rid;
    assign m_axi.rdata = m_rdata;
    assign m_axi.rresp = m_rresp;
    assign m_axi.rlast = m_rlast;
    assign m_axi.rvalid = m_rvalid;
    assign m_rready = m_axi.rready;
    assign s_rid = s_axi.rid;
    assign s_rdata = s_axi.rdata;
    assign s_rresp = s_axi.rresp;
    assign s_rlast = s_axi.rlast;
    assign s_rvalid = s_axi.rvalid;
    assign s_axi.rready = s_rready;
    assign s_axi.awid = 0; assign s_axi.awaddr = 0; assign s_axi.awlen = 0;
    assign s_axi.awsize = 0; assign s_axi.awburst = 0; assign s_axi.awlock = 0;
    assign s_axi.awcache = 0; assign s_axi.awprot = 0; assign s_axi.awqos = 0;
    assign s_axi.awvalid = 0; assign s_axi.wdata = 0; assign s_axi.wstrb = 0;
    assign s_axi.wlast = 0; assign s_axi.wvalid = 0; assign s_axi.bready = 0;
    assign m_axi.awready = 0; assign m_axi.wready = 0;
    assign m_axi.bid = 0; assign m_axi.bresp = 0; assign m_axi.bvalid = 0;
    axi4_ui_read_cdc dut (.s_axi(s_axi), .ui_clk(ui_clk),
        .ui_resetn(ui_resetn), .m_axi(m_axi));
endmodule
