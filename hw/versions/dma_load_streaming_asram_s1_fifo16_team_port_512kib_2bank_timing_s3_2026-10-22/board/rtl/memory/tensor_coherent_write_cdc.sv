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
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) buffered_axi();
    assign buffered_axi.aclk = tensor_write_axi.aclk;
    assign buffered_axi.aresetn = tensor_write_axi.aresetn;
    // Occupancy-only ready breaks FIFO-reset/full -> DMA credit feedback.
    // Independent AW/W/B storage preserves AXI channel ordering and supports
    // one transfer per cycle once filled. Payload registers have no reset.
    tensor_write_elastic2 #(.WIDTH(60)) u_aw_stage (
        .clk(tensor_write_axi.aclk), .resetn(tensor_write_axi.aresetn),
        .s_valid(tensor_write_axi.awvalid), .s_ready(tensor_write_axi.awready),
        .s_data({tensor_write_axi.awid, tensor_write_axi.awaddr, tensor_write_axi.awlen,
                 tensor_write_axi.awsize, tensor_write_axi.awburst, tensor_write_axi.awlock,
                 tensor_write_axi.awcache, tensor_write_axi.awprot, tensor_write_axi.awqos}),
        .m_valid(buffered_axi.awvalid), .m_ready(buffered_axi.awready),
        .m_data({buffered_axi.awid, buffered_axi.awaddr, buffered_axi.awlen,
                 buffered_axi.awsize, buffered_axi.awburst, buffered_axi.awlock,
                 buffered_axi.awcache, buffered_axi.awprot, buffered_axi.awqos})
    );
    tensor_write_elastic2 #(.WIDTH(289)) u_w_stage (
        .clk(tensor_write_axi.aclk), .resetn(tensor_write_axi.aresetn),
        .s_valid(tensor_write_axi.wvalid), .s_ready(tensor_write_axi.wready),
        .s_data({tensor_write_axi.wdata, tensor_write_axi.wstrb, tensor_write_axi.wlast}),
        .m_valid(buffered_axi.wvalid), .m_ready(buffered_axi.wready),
        .m_data({buffered_axi.wdata, buffered_axi.wstrb, buffered_axi.wlast})
    );
    tensor_write_elastic2 #(.WIDTH(5)) u_b_stage (
        .clk(tensor_write_axi.aclk), .resetn(tensor_write_axi.aresetn),
        .s_valid(buffered_axi.bvalid), .s_ready(buffered_axi.bready),
        .s_data({buffered_axi.bid, buffered_axi.bresp}),
        .m_valid(tensor_write_axi.bvalid), .m_ready(tensor_write_axi.bready),
        .m_data({tensor_write_axi.bid, tensor_write_axi.bresp})
    );
    assign tensor_write_axi.arready = 1'b0;
    assign tensor_write_axi.rid = '0;
    assign tensor_write_axi.rdata = '0;
    assign tensor_write_axi.rresp = '0;
    assign tensor_write_axi.rlast = 1'b0;
    assign tensor_write_axi.rvalid = 1'b0;
    assign buffered_axi.arid = '0;
    assign buffered_axi.araddr = '0;
    assign buffered_axi.arlen = '0;
    assign buffered_axi.arsize = '0;
    assign buffered_axi.arburst = '0;
    assign buffered_axi.arlock = '0;
    assign buffered_axi.arcache = '0;
    assign buffered_axi.arprot = '0;
    assign buffered_axi.arqos = '0;
    assign buffered_axi.arvalid = 1'b0;
    assign buffered_axi.rready = 1'b0;
    axi4_ui_write_cdc #(
        .RELATED_CLOCKS(0),
        .COMMAND_DEPTH(32), .DATA_DEPTH(512), .RESPONSE_DEPTH(32)
    ) u_cdc (
        .s_axi(buffered_axi), .ui_clk(soc_clk),
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

(* KEEP_HIERARCHY = "yes" *)
module tensor_write_elastic2 #(parameter integer WIDTH = 8) (
    input wire clk, resetn,
    input wire s_valid,
    output wire s_ready,
    input wire [WIDTH-1:0] s_data,
    output wire m_valid,
    input wire m_ready,
    output wire [WIDTH-1:0] m_data
);
    reg [1:0] count = 0;
    reg [WIDTH-1:0] head, tail;
    assign s_ready = resetn && count != 2;
    assign m_valid = resetn && count != 0;
    assign m_data = head;
    wire push = s_valid && s_ready;
    wire pop = m_valid && m_ready;
    always @(posedge clk) begin
        if (!resetn) count <= 0;
        else case ({push, pop})
            2'b10: count <= count + 1'b1;
            2'b01: count <= count - 1'b1;
            default: count <= count;
        endcase
        if (resetn) begin
            if (pop && count == 2) head <= tail;
            else if (push && (count == 0 || pop)) head <= s_data;
            if (push && count == 1 && !pop) tail <= s_data;
        end
    end
endmodule
