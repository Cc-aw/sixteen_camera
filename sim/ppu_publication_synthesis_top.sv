`timescale 1ns/1ps
module ppu_publication_synthesis_top(
    input wire clk,resetn,allocate,publish,abort_slot,release_slot,acquire,
    input wire [1:0] command_bank,lease_bank,
    input wire [31:0] command_version,lease_version,
    input wire [5:0] publish_mask,
    output wire [3:0] allocated,reading,fault,
    output wire [127:0] versions,
    output wire [23:0] ready_heads,producer_heads,
    output wire [31:0] rejected_commands,cycles,lines_completed,
    output wire active,
    input wire [4:0] tensor_awid,
    input wire [32:0] tensor_awaddr,
    input wire [7:0] tensor_awlen,
    input wire [2:0] tensor_awsize,
    input wire [1:0] tensor_awburst,
    input wire tensor_awlock,
    input wire [3:0] tensor_awcache,
    input wire [2:0] tensor_awprot,
    input wire [3:0] tensor_awqos,
    input wire tensor_awvalid,
    output wire tensor_awready,
    input wire [255:0] tensor_wdata,
    input wire [31:0] tensor_wstrb,
    input wire tensor_wlast,
    input wire tensor_wvalid,
    output wire tensor_wready,
    output wire [4:0] tensor_bid,
    output wire [1:0] tensor_bresp,
    output wire tensor_bvalid,
    input wire tensor_bready,
    input wire [4:0] tensor_arid,
    input wire [32:0] tensor_araddr,
    input wire [7:0] tensor_arlen,
    input wire [2:0] tensor_arsize,
    input wire [1:0] tensor_arburst,
    input wire tensor_arlock,
    input wire [3:0] tensor_arcache,
    input wire [2:0] tensor_arprot,
    input wire [3:0] tensor_arqos,
    input wire tensor_arvalid,
    output wire tensor_arready,
    output wire [4:0] tensor_rid,
    output wire [255:0] tensor_rdata,
    output wire [1:0] tensor_rresp,
    output wire tensor_rlast,
    output wire tensor_rvalid,
    input wire tensor_rready,
    output wire [4:0] bus_awid,
    output wire [32:0] bus_awaddr,
    output wire [7:0] bus_awlen,
    output wire [2:0] bus_awsize,
    output wire [1:0] bus_awburst,
    output wire bus_awlock,
    output wire [3:0] bus_awcache,
    output wire [2:0] bus_awprot,
    output wire [3:0] bus_awqos,
    output wire bus_awvalid,
    input wire bus_awready,
    output wire [255:0] bus_wdata,
    output wire [31:0] bus_wstrb,
    output wire bus_wlast,
    output wire bus_wvalid,
    input wire bus_wready,
    input wire [4:0] bus_bid,
    input wire [1:0] bus_bresp,
    input wire bus_bvalid,
    output wire bus_bready,
    output wire [4:0] bus_arid,
    output wire [32:0] bus_araddr,
    output wire [7:0] bus_arlen,
    output wire [2:0] bus_arsize,
    output wire [1:0] bus_arburst,
    output wire bus_arlock,
    output wire [3:0] bus_arcache,
    output wire [2:0] bus_arprot,
    output wire [3:0] bus_arqos,
    output wire bus_arvalid,
    input wire bus_arready,
    input wire [4:0] bus_rid,
    input wire [255:0] bus_rdata,
    input wire [1:0] bus_rresp,
    input wire bus_rlast,
    input wire bus_rvalid,
    output wire bus_rready
);
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) tensor_axi(),clean_axi(),bus_axi();
    assign tensor_axi.aclk=clk;assign tensor_axi.aresetn=resetn;
    wire clean_start,clean_abort,clean_busy,clean_done,clean_error;
    wire [32:0] clean_base;wire [31:0] clean_bytes;
    head_publication_manager manager(.*);
    ppu_cache_publish_engine engine(.clk(clk),.resetn(resetn),.start(clean_start),.abort(clean_abort),
        .base(clean_base),.bytes(clean_bytes),.busy(clean_busy),.done(clean_done),.error(clean_error),
        .cycles(cycles),.lines_completed(lines_completed),.m_axi(clean_axi));
    ppu_publication_write_mux mux(.clk(clk),.resetn(resetn),.tensor_axi(tensor_axi),.publish_axi(clean_axi),.m_axi(bus_axi));
    assign tensor_axi.awid=tensor_awid;
    assign tensor_axi.awaddr=tensor_awaddr;
    assign tensor_axi.awlen=tensor_awlen;
    assign tensor_axi.awsize=tensor_awsize;
    assign tensor_axi.awburst=tensor_awburst;
    assign tensor_axi.awlock=tensor_awlock;
    assign tensor_axi.awcache=tensor_awcache;
    assign tensor_axi.awprot=tensor_awprot;
    assign tensor_axi.awqos=tensor_awqos;
    assign tensor_axi.awvalid=tensor_awvalid;
    assign tensor_awready=tensor_axi.awready;
    assign tensor_axi.wdata=tensor_wdata;
    assign tensor_axi.wstrb=tensor_wstrb;
    assign tensor_axi.wlast=tensor_wlast;
    assign tensor_axi.wvalid=tensor_wvalid;
    assign tensor_wready=tensor_axi.wready;
    assign tensor_bid=tensor_axi.bid;
    assign tensor_bresp=tensor_axi.bresp;
    assign tensor_bvalid=tensor_axi.bvalid;
    assign tensor_axi.bready=tensor_bready;
    assign tensor_axi.arid=tensor_arid;
    assign tensor_axi.araddr=tensor_araddr;
    assign tensor_axi.arlen=tensor_arlen;
    assign tensor_axi.arsize=tensor_arsize;
    assign tensor_axi.arburst=tensor_arburst;
    assign tensor_axi.arlock=tensor_arlock;
    assign tensor_axi.arcache=tensor_arcache;
    assign tensor_axi.arprot=tensor_arprot;
    assign tensor_axi.arqos=tensor_arqos;
    assign tensor_axi.arvalid=tensor_arvalid;
    assign tensor_arready=tensor_axi.arready;
    assign tensor_rid=tensor_axi.rid;
    assign tensor_rdata=tensor_axi.rdata;
    assign tensor_rresp=tensor_axi.rresp;
    assign tensor_rlast=tensor_axi.rlast;
    assign tensor_rvalid=tensor_axi.rvalid;
    assign tensor_axi.rready=tensor_rready;
    assign bus_awid=bus_axi.awid;
    assign bus_awaddr=bus_axi.awaddr;
    assign bus_awlen=bus_axi.awlen;
    assign bus_awsize=bus_axi.awsize;
    assign bus_awburst=bus_axi.awburst;
    assign bus_awlock=bus_axi.awlock;
    assign bus_awcache=bus_axi.awcache;
    assign bus_awprot=bus_axi.awprot;
    assign bus_awqos=bus_axi.awqos;
    assign bus_awvalid=bus_axi.awvalid;
    assign bus_axi.awready=bus_awready;
    assign bus_wdata=bus_axi.wdata;
    assign bus_wstrb=bus_axi.wstrb;
    assign bus_wlast=bus_axi.wlast;
    assign bus_wvalid=bus_axi.wvalid;
    assign bus_axi.wready=bus_wready;
    assign bus_axi.bid=bus_bid;
    assign bus_axi.bresp=bus_bresp;
    assign bus_axi.bvalid=bus_bvalid;
    assign bus_bready=bus_axi.bready;
    assign bus_arid=bus_axi.arid;
    assign bus_araddr=bus_axi.araddr;
    assign bus_arlen=bus_axi.arlen;
    assign bus_arsize=bus_axi.arsize;
    assign bus_arburst=bus_axi.arburst;
    assign bus_arlock=bus_axi.arlock;
    assign bus_arcache=bus_axi.arcache;
    assign bus_arprot=bus_axi.arprot;
    assign bus_arqos=bus_axi.arqos;
    assign bus_arvalid=bus_axi.arvalid;
    assign bus_axi.arready=bus_arready;
    assign bus_axi.rid=bus_rid;
    assign bus_axi.rdata=bus_rdata;
    assign bus_axi.rresp=bus_rresp;
    assign bus_axi.rlast=bus_rlast;
    assign bus_axi.rvalid=bus_rvalid;
    assign bus_rready=bus_axi.rready;
endmodule
