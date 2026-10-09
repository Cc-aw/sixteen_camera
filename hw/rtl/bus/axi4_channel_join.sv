`timescale 1ns/1ps

// Join a write-only AXI master and a read-only AXI master onto one physical
// AXI interface. AXI read and write channels remain independent.
module axi4_channel_join (
    axi4_if.slave  write_axi,
    axi4_if.slave  read_axi,
    input  wire    clk,
    input  wire    resetn,
    axi4_if.master m_axi
);
    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;

    assign m_axi.awid = write_axi.awid;
    assign m_axi.awaddr = write_axi.awaddr;
    assign m_axi.awlen = write_axi.awlen;
    assign m_axi.awsize = write_axi.awsize;
    assign m_axi.awburst = write_axi.awburst;
    assign m_axi.awlock = write_axi.awlock;
    assign m_axi.awcache = write_axi.awcache;
    assign m_axi.awprot = write_axi.awprot;
    assign m_axi.awqos = write_axi.awqos;
    assign m_axi.awvalid = write_axi.awvalid;
    assign write_axi.awready = m_axi.awready;
    assign m_axi.wdata = write_axi.wdata;
    assign m_axi.wstrb = write_axi.wstrb;
    assign m_axi.wlast = write_axi.wlast;
    assign m_axi.wvalid = write_axi.wvalid;
    assign write_axi.wready = m_axi.wready;
    assign write_axi.bid = m_axi.bid;
    assign write_axi.bresp = m_axi.bresp;
    assign write_axi.bvalid = m_axi.bvalid;
    assign m_axi.bready = write_axi.bready;

    assign m_axi.arid = read_axi.arid;
    assign m_axi.araddr = read_axi.araddr;
    assign m_axi.arlen = read_axi.arlen;
    assign m_axi.arsize = read_axi.arsize;
    assign m_axi.arburst = read_axi.arburst;
    assign m_axi.arlock = read_axi.arlock;
    assign m_axi.arcache = read_axi.arcache;
    assign m_axi.arprot = read_axi.arprot;
    assign m_axi.arqos = read_axi.arqos;
    assign m_axi.arvalid = read_axi.arvalid;
    assign read_axi.arready = m_axi.arready;
    assign read_axi.rid = m_axi.rid;
    assign read_axi.rdata = m_axi.rdata;
    assign read_axi.rresp = m_axi.rresp;
    assign read_axi.rlast = m_axi.rlast;
    assign read_axi.rvalid = m_axi.rvalid;
    assign m_axi.rready = read_axi.rready;

    assign write_axi.arready = 1'b0;
    assign write_axi.rid = '0;
    assign write_axi.rdata = '0;
    assign write_axi.rresp = 2'b00;
    assign write_axi.rlast = 1'b0;
    assign write_axi.rvalid = 1'b0;
    assign read_axi.awready = 1'b0;
    assign read_axi.wready = 1'b0;
    assign read_axi.bid = '0;
    assign read_axi.bresp = 2'b00;
    assign read_axi.bvalid = 1'b0;
endmodule
