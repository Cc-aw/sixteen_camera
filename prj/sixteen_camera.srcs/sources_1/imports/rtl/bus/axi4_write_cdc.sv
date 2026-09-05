`timescale 1ns/1ps

// AXI4 write-only asynchronous bridge.  The frame preprocessor has one
// outstanding burst at a time, so preserving AW/W/B ordering is sufficient
// and avoids routing its tensor writes through the non-coherent DDR S02 port.
module axi4_write_cdc #(
    parameter integer FIFO_ADDR_WIDTH = 4
) (
    axi4_if.slave  s_axi,
    input  wire    m_clk,
    input  wire    m_resetn,
    axi4_if.master m_axi
);
    localparam integer AW_WIDTH = 60;
    localparam integer W_WIDTH = 289;
    localparam integer B_WIDTH = 6;

    wire [AW_WIDTH-1:0] aw_fifo_rdata;
    wire [W_WIDTH-1:0] w_fifo_rdata;
    wire [B_WIDTH-1:0] b_fifo_rdata;
    wire aw_fifo_full, aw_fifo_empty;
    wire w_fifo_full, w_fifo_empty;
    wire b_fifo_full, b_fifo_empty;
    reg  m_aw_inflight;

    wire s_aw_fire = s_axi.awvalid && s_axi.awready;
    wire s_w_fire = s_axi.wvalid && s_axi.wready;
    wire s_b_fire = s_axi.bvalid && s_axi.bready;
    wire m_aw_fire = m_axi.awvalid && m_axi.awready;
    wire m_w_fire = m_axi.wvalid && m_axi.wready;
    wire m_b_fire = m_axi.bvalid && m_axi.bready;

    // FBus is used only for coherent tensor writes.  Terminate its read
    // channel locally so it can never become an accidental data source.
    assign s_axi.arready = 1'b0;
    assign s_axi.rid = 3'd0;
    assign s_axi.rdata = 256'd0;
    assign s_axi.rresp = 2'b00;
    assign s_axi.rlast = 1'b0;
    assign s_axi.rvalid = 1'b0;

    assign s_axi.awready = !aw_fifo_full;
    assign s_axi.wready = !w_fifo_full;
    assign s_axi.bid = b_fifo_rdata[5:3];
    assign s_axi.bresp = b_fifo_rdata[2:1];
    assign s_axi.bvalid = !b_fifo_empty;

    assign m_axi.aclk = m_clk;
    assign m_axi.aresetn = m_resetn;
    assign m_axi.awid = {1'b0, aw_fifo_rdata[59:57]};
    // The preprocessor is configured with the 32-bit MIG physical address
    // (0x3000_0000 / 0x3100_0000), while the coherent FBus exposes that DDR
    // storage through Rocket's bit-31 alias (0xB000_0000 / 0xB100_0000).
    // This bridge is dedicated to tensor writes, so apply the alias here
    // without changing the S02 video-frame address space.
    assign m_axi.awaddr = {1'b0, aw_fifo_rdata[56:25] | 32'h8000_0000};
    assign m_axi.awlen = aw_fifo_rdata[24:17];
    assign m_axi.awsize = aw_fifo_rdata[16:14];
    assign m_axi.awburst = aw_fifo_rdata[13:12];
    assign m_axi.awlock = aw_fifo_rdata[11];
    assign m_axi.awcache = aw_fifo_rdata[10:7];
    assign m_axi.awprot = aw_fifo_rdata[6:4];
    assign m_axi.awqos = aw_fifo_rdata[3:0];
    assign m_axi.awvalid = !m_aw_inflight && !aw_fifo_empty;
    assign m_axi.wdata = w_fifo_rdata[288:33];
    assign m_axi.wstrb = w_fifo_rdata[32:1];
    assign m_axi.wlast = w_fifo_rdata[0];
    assign m_axi.wvalid = m_aw_inflight && !w_fifo_empty;
    assign m_axi.bready = !b_fifo_full;

    // FBus reads are deliberately disabled; this bridge has no read FIFO.
    assign m_axi.arid = 4'd0;
    assign m_axi.araddr = 33'd0;
    assign m_axi.arlen = 8'd0;
    assign m_axi.arsize = 3'd0;
    assign m_axi.arburst = 2'd0;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'd0;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'd0;
    assign m_axi.arvalid = 1'b0;
    assign m_axi.rready = 1'b0;

    async_fifo #(.DATA_WIDTH(AW_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_aw_fifo (
        .wclk(s_axi.aclk), .wresetn(s_axi.aresetn),
        .wdata({s_axi.awid, s_axi.awaddr, s_axi.awlen,
                s_axi.awsize, s_axi.awburst, s_axi.awlock, s_axi.awcache,
                s_axi.awprot, s_axi.awqos}),
        .w_en(s_aw_fire), .w_full(aw_fifo_full),
        .rclk(m_clk), .rresetn(m_resetn), .rdata(aw_fifo_rdata),
        .r_en(m_aw_fire), .r_empty(aw_fifo_empty)
    );

    async_fifo #(.DATA_WIDTH(W_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_w_fifo (
        .wclk(s_axi.aclk), .wresetn(s_axi.aresetn),
        .wdata({s_axi.wdata, s_axi.wstrb, s_axi.wlast}),
        .w_en(s_w_fire), .w_full(w_fifo_full),
        .rclk(m_clk), .rresetn(m_resetn), .rdata(w_fifo_rdata),
        .r_en(m_w_fire), .r_empty(w_fifo_empty)
    );

    async_fifo #(.DATA_WIDTH(B_WIDTH), .ADDR_WIDTH(FIFO_ADDR_WIDTH)) u_b_fifo (
        .wclk(m_clk), .wresetn(m_resetn),
        .wdata({m_axi.bid[2:0], m_axi.bresp, 1'b0}),
        .w_en(m_b_fire), .w_full(b_fifo_full),
        .rclk(s_axi.aclk), .rresetn(s_axi.aresetn), .rdata(b_fifo_rdata),
        .r_en(s_b_fire), .r_empty(b_fifo_empty)
    );

    always @(posedge m_clk or negedge m_resetn) begin
        if (!m_resetn)
            m_aw_inflight <= 1'b0;
        else begin
            if (m_aw_fire)
                m_aw_inflight <= 1'b1;
            if (m_b_fire)
                m_aw_inflight <= 1'b0;
        end
    end
endmodule
