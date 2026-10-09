`timescale 1ns/1ps

// AXI4 write-channel bridge from the 150 MHz video domain to the 300 MHz
// MIG UI domain. AW, W and B each have independent ordered storage so the
// upstream writer may retain its configured multi-burst outstanding window.
module axi4_ui_write_cdc #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 256,
    parameter integer ID_WIDTH = 3,
    parameter integer COMMAND_DEPTH = 32,
    parameter integer DATA_DEPTH = 512,
    parameter integer RESPONSE_DEPTH = 32
) (
    axi4_if.slave  s_axi,
    input  wire    ui_clk,
    input  wire    ui_resetn,
    axi4_if.master m_axi
);
    localparam integer STRB_WIDTH = DATA_WIDTH / 8;
    localparam integer AW_WIDTH = ID_WIDTH + ADDR_WIDTH + 25;
    localparam integer W_WIDTH = DATA_WIDTH + STRB_WIDTH + 1;
    localparam integer B_WIDTH = ID_WIDTH + 2;
    wire [AW_WIDTH-1:0] aw_data;
    wire [W_WIDTH-1:0] w_data;
    wire [B_WIDTH-1:0] b_data;
    wire aw_valid, aw_ready, w_valid, w_ready, b_valid, b_ready;

    cdc_payload_fifo #(.WIDTH(AW_WIDTH), .DEPTH(COMMAND_DEPTH)) u_aw (
        .w_clk(s_axi.aclk), .w_resetn(s_axi.aresetn),
        .w_valid(s_axi.awvalid), .w_ready(s_axi.awready),
        .w_data({s_axi.awid, s_axi.awaddr, s_axi.awlen, s_axi.awsize,
                 s_axi.awburst, s_axi.awlock, s_axi.awcache,
                 s_axi.awprot, s_axi.awqos}),
        .r_clk(ui_clk), .r_resetn(ui_resetn), .r_valid(aw_valid),
        .r_ready(aw_ready), .r_data(aw_data)
    );
    cdc_payload_fifo #(.WIDTH(W_WIDTH), .DEPTH(DATA_DEPTH)) u_w (
        .w_clk(s_axi.aclk), .w_resetn(s_axi.aresetn),
        .w_valid(s_axi.wvalid), .w_ready(s_axi.wready),
        .w_data({s_axi.wdata, s_axi.wstrb, s_axi.wlast}),
        .r_clk(ui_clk), .r_resetn(ui_resetn), .r_valid(w_valid),
        .r_ready(w_ready), .r_data(w_data)
    );
    cdc_payload_fifo #(.WIDTH(B_WIDTH), .DEPTH(RESPONSE_DEPTH)) u_b (
        .w_clk(ui_clk), .w_resetn(ui_resetn), .w_valid(b_valid),
        .w_ready(b_ready), .w_data(b_data),
        .r_clk(s_axi.aclk), .r_resetn(s_axi.aresetn),
        .r_valid(s_axi.bvalid), .r_ready(s_axi.bready),
        .r_data({s_axi.bid, s_axi.bresp})
    );

    assign {m_axi.awid, m_axi.awaddr, m_axi.awlen, m_axi.awsize,
            m_axi.awburst, m_axi.awlock, m_axi.awcache,
            m_axi.awprot, m_axi.awqos} = aw_data;
    assign {m_axi.wdata, m_axi.wstrb, m_axi.wlast} = w_data;
    assign aw_ready = m_axi.awready;
    assign w_ready = m_axi.wready;
    assign b_valid = m_axi.bvalid;
    assign b_data = {m_axi.bid, m_axi.bresp};
    assign m_axi.awvalid = aw_valid;
    assign m_axi.wvalid = w_valid;
    assign m_axi.bready = b_ready;
    assign m_axi.aclk = ui_clk;
    assign m_axi.aresetn = ui_resetn;

    assign s_axi.arready = 1'b0;
    assign s_axi.rid = '0;
    assign s_axi.rdata = '0;
    assign s_axi.rresp = 2'b00;
    assign s_axi.rlast = 1'b0;
    assign s_axi.rvalid = 1'b0;
    assign m_axi.arid = '0;
    assign m_axi.araddr = '0;
    assign m_axi.arlen = 8'd0;
    assign m_axi.arsize = 3'd0;
    assign m_axi.arburst = 2'd0;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'd0;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'd0;
    assign m_axi.arvalid = 1'b0;
    assign m_axi.rready = 1'b0;
endmodule
