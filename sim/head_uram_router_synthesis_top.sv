`timescale 1ns/1ps

// Flat-port production-parameter harness for P2 resource/timing checks.
module head_uram_router_synthesis_top #(
    parameter bit SHADOW_DDR = 1'b0
) (
    input  wire         clk,
    input  wire         resetn,
    input  wire [3:0]   s_awid,
    input  wire [32:0]  s_awaddr,
    input  wire [7:0]   s_awlen,
    input  wire [2:0]   s_awsize,
    input  wire [1:0]   s_awburst,
    input  wire         s_awvalid,
    output wire         s_awready,
    input  wire [255:0] s_wdata,
    input  wire [31:0]  s_wstrb,
    input  wire         s_wlast,
    input  wire         s_wvalid,
    output wire         s_wready,
    output wire [3:0]   s_bid,
    output wire [1:0]   s_bresp,
    output wire         s_bvalid,
    input  wire         s_bready,
    input  wire [3:0]   s_arid,
    input  wire [32:0]  s_araddr,
    input  wire [7:0]   s_arlen,
    input  wire [2:0]   s_arsize,
    input  wire [1:0]   s_arburst,
    input  wire         s_arvalid,
    output wire         s_arready,
    output wire [3:0]   s_rid,
    output wire [255:0] s_rdata,
    output wire [1:0]   s_rresp,
    output wire         s_rlast,
    output wire         s_rvalid,
    input  wire         s_rready,

    output wire [3:0]   d_awid,
    output wire [32:0]  d_awaddr,
    output wire [7:0]   d_awlen,
    output wire [2:0]   d_awsize,
    output wire [1:0]   d_awburst,
    output wire         d_awvalid,
    input  wire         d_awready,
    output wire [255:0] d_wdata,
    output wire [31:0]  d_wstrb,
    output wire         d_wlast,
    output wire         d_wvalid,
    input  wire         d_wready,
    input  wire [3:0]   d_bid,
    input  wire [1:0]   d_bresp,
    input  wire         d_bvalid,
    output wire         d_bready,
    output wire [3:0]   d_arid,
    output wire [32:0]  d_araddr,
    output wire [7:0]   d_arlen,
    output wire [2:0]   d_arsize,
    output wire [1:0]   d_arburst,
    output wire         d_arvalid,
    input  wire         d_arready,
    input  wire [3:0]   d_rid,
    input  wire [255:0] d_rdata,
    input  wire [1:0]   d_rresp,
    input  wire         d_rlast,
    input  wire         d_rvalid,
    output wire         d_rready,

    input  wire [1:0]   local_bank,
    input  wire         local_req_valid,
    output wire         local_req_ready,
    input  wire [14:0]  local_req_word_addr,
    output wire [255:0] local_rsp_data,
    output wire         local_rsp_valid,
    input  wire         local_rsp_ready
);
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) s_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) ddr_axi();

    assign s_axi.aclk = clk;
    assign s_axi.aresetn = resetn;
    assign s_axi.awid = s_awid;
    assign s_axi.awaddr = s_awaddr;
    assign s_axi.awlen = s_awlen;
    assign s_axi.awsize = s_awsize;
    assign s_axi.awburst = s_awburst;
    assign s_axi.awlock = 1'b0;
    assign s_axi.awcache = 4'b0010;
    assign s_axi.awprot = 3'b000;
    assign s_axi.awqos = 4'b0000;
    assign s_axi.awvalid = s_awvalid;
    assign s_awready = s_axi.awready;
    assign s_axi.wdata = s_wdata;
    assign s_axi.wstrb = s_wstrb;
    assign s_axi.wlast = s_wlast;
    assign s_axi.wvalid = s_wvalid;
    assign s_wready = s_axi.wready;
    assign s_bid = s_axi.bid;
    assign s_bresp = s_axi.bresp;
    assign s_bvalid = s_axi.bvalid;
    assign s_axi.bready = s_bready;
    assign s_axi.arid = s_arid;
    assign s_axi.araddr = s_araddr;
    assign s_axi.arlen = s_arlen;
    assign s_axi.arsize = s_arsize;
    assign s_axi.arburst = s_arburst;
    assign s_axi.arlock = 1'b0;
    assign s_axi.arcache = 4'b0010;
    assign s_axi.arprot = 3'b000;
    assign s_axi.arqos = 4'b0000;
    assign s_axi.arvalid = s_arvalid;
    assign s_arready = s_axi.arready;
    assign s_rid = s_axi.rid;
    assign s_rdata = s_axi.rdata;
    assign s_rresp = s_axi.rresp;
    assign s_rlast = s_axi.rlast;
    assign s_rvalid = s_axi.rvalid;
    assign s_axi.rready = s_rready;

    assign d_awid = ddr_axi.awid;
    assign d_awaddr = ddr_axi.awaddr;
    assign d_awlen = ddr_axi.awlen;
    assign d_awsize = ddr_axi.awsize;
    assign d_awburst = ddr_axi.awburst;
    assign d_awvalid = ddr_axi.awvalid;
    assign ddr_axi.awready = d_awready;
    assign d_wdata = ddr_axi.wdata;
    assign d_wstrb = ddr_axi.wstrb;
    assign d_wlast = ddr_axi.wlast;
    assign d_wvalid = ddr_axi.wvalid;
    assign ddr_axi.wready = d_wready;
    assign ddr_axi.bid = d_bid;
    assign ddr_axi.bresp = d_bresp;
    assign ddr_axi.bvalid = d_bvalid;
    assign d_bready = ddr_axi.bready;
    assign d_arid = ddr_axi.arid;
    assign d_araddr = ddr_axi.araddr;
    assign d_arlen = ddr_axi.arlen;
    assign d_arsize = ddr_axi.arsize;
    assign d_arburst = ddr_axi.arburst;
    assign d_arvalid = ddr_axi.arvalid;
    assign ddr_axi.arready = d_arready;
    assign ddr_axi.rid = d_rid;
    assign ddr_axi.rdata = d_rdata;
    assign ddr_axi.rresp = d_rresp;
    assign ddr_axi.rlast = d_rlast;
    assign ddr_axi.rvalid = d_rvalid;
    assign d_rready = ddr_axi.rready;

    axi4_head_uram_router #(.SHADOW_DDR(SHADOW_DDR)) dut (
        .clk(clk), .resetn(resetn), .s_axi(s_axi), .m_ddr_axi(ddr_axi),
        .local_read_bank(local_bank),
        .local_read_req_valid(local_req_valid),
        .local_read_req_ready(local_req_ready),
        .local_read_req_word_addr(local_req_word_addr),
        .local_read_rsp_data(local_rsp_data),
        .local_read_rsp_valid(local_rsp_valid),
        .local_read_rsp_ready(local_rsp_ready)
    );
endmodule
