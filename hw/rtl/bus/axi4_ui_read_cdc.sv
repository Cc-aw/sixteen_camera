`timescale 1ns/1ps

// AXI4 read-channel bridge from the 150 MHz video domain to the 300 MHz MIG
// UI domain. The response FIFO is part of the return capacity; upstream
// readers still reserve their own FIFO space before issuing each burst.
module axi4_ui_read_cdc #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 256,
    parameter integer ID_WIDTH = 3,
    parameter integer COMMAND_DEPTH = 32,
    parameter integer DATA_DEPTH = 512
) (
    axi4_if.slave  s_axi,
    input  wire    ui_clk,
    input  wire    ui_resetn,
    axi4_if.master m_axi
);
    localparam integer AR_WIDTH = ID_WIDTH + ADDR_WIDTH + 25;
    localparam integer R_WIDTH = ID_WIDTH + DATA_WIDTH + 3;
    wire [AR_WIDTH-1:0] ar_data;
    wire [R_WIDTH-1:0] r_data;
    wire ar_valid, ar_ready, r_valid, r_ready;

    cdc_payload_fifo #(.WIDTH(AR_WIDTH), .DEPTH(COMMAND_DEPTH)) u_ar (
        .w_clk(s_axi.aclk), .w_resetn(s_axi.aresetn),
        .w_valid(s_axi.arvalid), .w_ready(s_axi.arready),
        .w_data({s_axi.arid, s_axi.araddr, s_axi.arlen, s_axi.arsize,
                 s_axi.arburst, s_axi.arlock, s_axi.arcache,
                 s_axi.arprot, s_axi.arqos}),
        .r_clk(ui_clk), .r_resetn(ui_resetn), .r_valid(ar_valid),
        .r_ready(ar_ready), .r_data(ar_data)
    );
    cdc_payload_fifo #(.WIDTH(R_WIDTH), .DEPTH(DATA_DEPTH)) u_r (
        .w_clk(ui_clk), .w_resetn(ui_resetn), .w_valid(r_valid),
        .w_ready(r_ready), .w_data(r_data),
        .r_clk(s_axi.aclk), .r_resetn(s_axi.aresetn),
        .r_valid(s_axi.rvalid), .r_ready(s_axi.rready),
        .r_data({s_axi.rid, s_axi.rdata, s_axi.rresp, s_axi.rlast})
    );

    assign {m_axi.arid, m_axi.araddr, m_axi.arlen, m_axi.arsize,
            m_axi.arburst, m_axi.arlock, m_axi.arcache,
            m_axi.arprot, m_axi.arqos} = ar_data;
    assign ar_ready = m_axi.arready;
    assign r_valid = m_axi.rvalid;
    assign r_data = {m_axi.rid, m_axi.rdata, m_axi.rresp, m_axi.rlast};
    assign m_axi.arvalid = ar_valid;
    assign m_axi.rready = r_ready;
    assign m_axi.aclk = ui_clk;
    assign m_axi.aresetn = ui_resetn;

    assign s_axi.awready = 1'b0;
    assign s_axi.wready = 1'b0;
    assign s_axi.bid = '0;
    assign s_axi.bresp = 2'b00;
    assign s_axi.bvalid = 1'b0;
    assign m_axi.awid = '0;
    assign m_axi.awaddr = '0;
    assign m_axi.awlen = 8'd0;
    assign m_axi.awsize = 3'd0;
    assign m_axi.awburst = 2'd0;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'd0;
    assign m_axi.awprot = 3'd0;
    assign m_axi.awqos = 4'd0;
    assign m_axi.awvalid = 1'b0;
    assign m_axi.wdata = '0;
    assign m_axi.wstrb = '0;
    assign m_axi.wlast = 1'b0;
    assign m_axi.wvalid = 1'b0;
    assign m_axi.bready = 1'b0;
endmodule
