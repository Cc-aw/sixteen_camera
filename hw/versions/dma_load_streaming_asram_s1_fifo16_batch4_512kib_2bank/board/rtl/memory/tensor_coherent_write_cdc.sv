`timescale 1ns/1ps

// Ordered channel FIFOs preserve the DMA's outstanding window. The SoC ingress
// allocates TL sources independently of AXI IDs; no ID rotation is necessary.
// Source and destination resets must be asserted together for a global reset.
module tensor_coherent_write_cdc (
    axi4_if.slave tensor_write_axi,
    input wire soc_clk,
    input wire soc_resetn,
    axi4_if.master tensor_soc_axi
);
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) ordered_axi();
    axi4_ui_write_cdc #(
        .RELATED_CLOCKS(0),
        .COMMAND_DEPTH(32), .DATA_DEPTH(512), .RESPONSE_DEPTH(32)
    ) u_cdc (
        .s_axi(tensor_write_axi), .ui_clk(soc_clk),
        .ui_resetn(soc_resetn), .m_axi(ordered_axi)
    );
    assign tensor_soc_axi.aclk = soc_clk;
    assign tensor_soc_axi.aresetn = soc_resetn;
    assign tensor_soc_axi.awid = {2'b00, ordered_axi.awid};
    assign tensor_soc_axi.awaddr = {1'b0, ordered_axi.awaddr | 32'h8000_0000};
    assign tensor_soc_axi.awlen = ordered_axi.awlen;
    assign tensor_soc_axi.awsize = ordered_axi.awsize;
    assign tensor_soc_axi.awburst = ordered_axi.awburst;
    assign tensor_soc_axi.awlock = ordered_axi.awlock;
    assign tensor_soc_axi.awcache = ordered_axi.awcache;
    assign tensor_soc_axi.awprot = ordered_axi.awprot;
    assign tensor_soc_axi.awqos = ordered_axi.awqos;
    assign tensor_soc_axi.awvalid = ordered_axi.awvalid;
    assign ordered_axi.awready = tensor_soc_axi.awready;
    assign tensor_soc_axi.wdata = ordered_axi.wdata;
    assign tensor_soc_axi.wstrb = ordered_axi.wstrb;
    assign tensor_soc_axi.wlast = ordered_axi.wlast;
    assign tensor_soc_axi.wvalid = ordered_axi.wvalid;
    assign ordered_axi.wready = tensor_soc_axi.wready;
    assign ordered_axi.bid = tensor_soc_axi.bid[2:0];
    assign ordered_axi.bresp = tensor_soc_axi.bresp;
    assign ordered_axi.bvalid = tensor_soc_axi.bvalid;
    assign tensor_soc_axi.bready = ordered_axi.bready;
    assign tensor_soc_axi.arid = '0;
    assign tensor_soc_axi.araddr = '0;
    assign tensor_soc_axi.arlen = '0;
    assign tensor_soc_axi.arsize = '0;
    assign tensor_soc_axi.arburst = '0;
    assign tensor_soc_axi.arlock = '0;
    assign tensor_soc_axi.arcache = '0;
    assign tensor_soc_axi.arprot = '0;
    assign tensor_soc_axi.arqos = '0;
    assign tensor_soc_axi.arvalid = 1'b0;
    assign tensor_soc_axi.rready = 1'b0;
    assign ordered_axi.arready = 1'b0;
    assign ordered_axi.rid = '0;
    assign ordered_axi.rdata = '0;
    assign ordered_axi.rresp = '0;
    assign ordered_axi.rlast = 1'b0;
    assign ordered_axi.rvalid = 1'b0;
endmodule
