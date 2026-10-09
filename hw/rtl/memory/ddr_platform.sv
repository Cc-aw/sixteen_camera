`timescale 1ns/1ps

// Board-specific DDR platform boundary: MIG, the 300 MHz UI clock/reset and
// the dedicated 150 MHz video clock/reset.  Higher layers see AXI ports only.
module ddr_platform (
    input  wire        sys_rstn,
    input  wire        c0_sys_clk_p,
    input  wire        c0_sys_clk_n,
    output wire        c0_init_calib_complete,
    output wire        c0_ddr4_act_n,
    output wire [16:0] c0_ddr4_adr,
    output wire [1:0]  c0_ddr4_ba,
    output wire [0:0]  c0_ddr4_bg,
    output wire [0:0]  c0_ddr4_ck_c,
    output wire [0:0]  c0_ddr4_ck_t,
    output wire [0:0]  c0_ddr4_cke,
    output wire [0:0]  c0_ddr4_cs_n,
    inout  wire [7:0]  c0_ddr4_dm_dbi_n,
    inout  wire [63:0] c0_ddr4_dq,
    inout  wire [7:0]  c0_ddr4_dqs_c,
    inout  wire [7:0]  c0_ddr4_dqs_t,
    output wire [0:0]  c0_ddr4_odt,
    output wire        c0_ddr4_reset_n,
    axi4_if.slave      soc_ddr_axi,
    axi4_if.slave      writer_ui_axi,
    axi4_if.slave      reader_ui_axi,
    output wire        ddr_ui_clk,
    output wire        ddr_resetn,
    output wire        video_clk,
    output wire        video_resetn
);
    wire [0:0] peripheral_aresetn;
    wire ddr_resetn_raw = peripheral_aresetn[0] &&
                          c0_init_calib_complete;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [2:0] ddr_reset_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [2:0] video_reset_sync;
    wire unused_soc_clk_100m;
    assign ddr_resetn = ddr_reset_sync[2];
    assign video_resetn = video_reset_sync[2];

    BUFGCE_DIV #(.BUFGCE_DIVIDE(2), .IS_CE_INVERTED(1'b0),
                 .IS_CLR_INVERTED(1'b0), .IS_I_INVERTED(1'b0))
    u_camera_video_clk_div (
        .I(ddr_ui_clk), .CE(1'b1), .CLR(1'b0), .O(video_clk)
    );

    always @(posedge ddr_ui_clk or negedge ddr_resetn_raw) begin
        if (!ddr_resetn_raw)
            ddr_reset_sync <= 3'b000;
        else
            ddr_reset_sync <= {ddr_reset_sync[1:0], 1'b1};
    end

    always @(posedge video_clk or negedge ddr_resetn) begin
        if (!ddr_resetn)
            video_reset_sync <= 3'b000;
        else
            video_reset_sync <= {video_reset_sync[1:0], 1'b1};
    end

    design_1_wrapper u_ddr_bd (
        .C0_DDR4_act_n(c0_ddr4_act_n),
        .C0_DDR4_adr(c0_ddr4_adr), .C0_DDR4_ba(c0_ddr4_ba),
        .C0_DDR4_bg(c0_ddr4_bg), .C0_DDR4_ck_c(c0_ddr4_ck_c),
        .C0_DDR4_ck_t(c0_ddr4_ck_t), .C0_DDR4_cke(c0_ddr4_cke),
        .C0_DDR4_cs_n(c0_ddr4_cs_n),
        .C0_DDR4_dm_n(c0_ddr4_dm_dbi_n), .C0_DDR4_dq(c0_ddr4_dq),
        .C0_DDR4_dqs_c(c0_ddr4_dqs_c),
        .C0_DDR4_dqs_t(c0_ddr4_dqs_t), .C0_DDR4_odt(c0_ddr4_odt),
        .C0_DDR4_reset_n(c0_ddr4_reset_n),
        .C0_SYS_CLK_clk_n(c0_sys_clk_n), .C0_SYS_CLK_clk_p(c0_sys_clk_p),

        .S00_ACLK(soc_ddr_axi.aclk), .S00_ARESETN(soc_ddr_axi.aresetn),
        .S00_AXI_awid(soc_ddr_axi.awid),
        .S00_AXI_awaddr({soc_ddr_axi.awaddr[32], soc_ddr_axi.awaddr[30:0]}),
        .S00_AXI_awlen(soc_ddr_axi.awlen),
        .S00_AXI_awsize(soc_ddr_axi.awsize),
        .S00_AXI_awburst(soc_ddr_axi.awburst),
        .S00_AXI_awlock(soc_ddr_axi.awlock),
        .S00_AXI_awcache(soc_ddr_axi.awcache),
        .S00_AXI_awprot(soc_ddr_axi.awprot),
        .S00_AXI_awqos(soc_ddr_axi.awqos), .S00_AXI_awregion(4'h0),
        .S00_AXI_awvalid(soc_ddr_axi.awvalid),
        .S00_AXI_awready(soc_ddr_axi.awready),
        .S00_AXI_wdata(soc_ddr_axi.wdata),
        .S00_AXI_wstrb(soc_ddr_axi.wstrb),
        .S00_AXI_wlast(soc_ddr_axi.wlast),
        .S00_AXI_wvalid(soc_ddr_axi.wvalid),
        .S00_AXI_wready(soc_ddr_axi.wready),
        .S00_AXI_bid(soc_ddr_axi.bid), .S00_AXI_bresp(soc_ddr_axi.bresp),
        .S00_AXI_bvalid(soc_ddr_axi.bvalid),
        .S00_AXI_bready(soc_ddr_axi.bready),
        .S00_AXI_arid(soc_ddr_axi.arid),
        .S00_AXI_araddr({soc_ddr_axi.araddr[32], soc_ddr_axi.araddr[30:0]}),
        .S00_AXI_arlen(soc_ddr_axi.arlen),
        .S00_AXI_arsize(soc_ddr_axi.arsize),
        .S00_AXI_arburst(soc_ddr_axi.arburst),
        .S00_AXI_arlock(soc_ddr_axi.arlock),
        .S00_AXI_arcache(soc_ddr_axi.arcache),
        .S00_AXI_arprot(soc_ddr_axi.arprot),
        .S00_AXI_arqos(soc_ddr_axi.arqos), .S00_AXI_arregion(4'h0),
        .S00_AXI_arvalid(soc_ddr_axi.arvalid),
        .S00_AXI_arready(soc_ddr_axi.arready),
        .S00_AXI_rid(soc_ddr_axi.rid), .S00_AXI_rdata(soc_ddr_axi.rdata),
        .S00_AXI_rresp(soc_ddr_axi.rresp),
        .S00_AXI_rlast(soc_ddr_axi.rlast),
        .S00_AXI_rvalid(soc_ddr_axi.rvalid),
        .S00_AXI_rready(soc_ddr_axi.rready),

        .S01_AXI_awid(writer_ui_axi.awid),
        .S01_AXI_awaddr(writer_ui_axi.awaddr),
        .S01_AXI_awlen(writer_ui_axi.awlen),
        .S01_AXI_awsize(writer_ui_axi.awsize),
        .S01_AXI_awburst(writer_ui_axi.awburst),
        .S01_AXI_awlock(writer_ui_axi.awlock),
        .S01_AXI_awcache(writer_ui_axi.awcache),
        .S01_AXI_awprot(writer_ui_axi.awprot),
        .S01_AXI_awqos(writer_ui_axi.awqos), .S01_AXI_awregion(4'h0),
        .S01_AXI_awvalid(writer_ui_axi.awvalid),
        .S01_AXI_awready(writer_ui_axi.awready),
        .S01_AXI_wdata(writer_ui_axi.wdata),
        .S01_AXI_wstrb(writer_ui_axi.wstrb),
        .S01_AXI_wlast(writer_ui_axi.wlast),
        .S01_AXI_wvalid(writer_ui_axi.wvalid),
        .S01_AXI_wready(writer_ui_axi.wready),
        .S01_AXI_bid(writer_ui_axi.bid),
        .S01_AXI_bresp(writer_ui_axi.bresp),
        .S01_AXI_bvalid(writer_ui_axi.bvalid),
        .S01_AXI_bready(writer_ui_axi.bready),
        .S01_AXI_arid(reader_ui_axi.arid),
        .S01_AXI_araddr(reader_ui_axi.araddr),
        .S01_AXI_arlen(reader_ui_axi.arlen),
        .S01_AXI_arsize(reader_ui_axi.arsize),
        .S01_AXI_arburst(reader_ui_axi.arburst),
        .S01_AXI_arlock(reader_ui_axi.arlock),
        .S01_AXI_arcache(reader_ui_axi.arcache),
        .S01_AXI_arprot(reader_ui_axi.arprot),
        .S01_AXI_arqos(reader_ui_axi.arqos), .S01_AXI_arregion(4'h0),
        .S01_AXI_arvalid(reader_ui_axi.arvalid),
        .S01_AXI_arready(reader_ui_axi.arready),
        .S01_AXI_rid(reader_ui_axi.rid),
        .S01_AXI_rdata(reader_ui_axi.rdata),
        .S01_AXI_rresp(reader_ui_axi.rresp),
        .S01_AXI_rlast(reader_ui_axi.rlast),
        .S01_AXI_rvalid(reader_ui_axi.rvalid),
        .S01_AXI_rready(reader_ui_axi.rready),

        .S02_AXI_awid(3'd0), .S02_AXI_awaddr(32'd0),
        .S02_AXI_awlen(8'd0), .S02_AXI_awsize(3'd0),
        .S02_AXI_awburst(2'd0), .S02_AXI_awlock(1'b0),
        .S02_AXI_awcache(4'd0), .S02_AXI_awprot(3'd0),
        .S02_AXI_awqos(4'd0), .S02_AXI_awregion(4'h0),
        .S02_AXI_awvalid(1'b0), .S02_AXI_awready(),
        .S02_AXI_wdata(256'd0), .S02_AXI_wstrb(32'd0),
        .S02_AXI_wlast(1'b0), .S02_AXI_wvalid(1'b0),
        .S02_AXI_wready(), .S02_AXI_bid(), .S02_AXI_bresp(),
        .S02_AXI_bvalid(), .S02_AXI_bready(1'b0),
        .S02_AXI_arid(3'd0), .S02_AXI_araddr(32'd0),
        .S02_AXI_arlen(8'd0), .S02_AXI_arsize(3'd0),
        .S02_AXI_arburst(2'd0), .S02_AXI_arlock(1'b0),
        .S02_AXI_arcache(4'd0), .S02_AXI_arprot(3'd0),
        .S02_AXI_arqos(4'd0), .S02_AXI_arregion(4'h0),
        .S02_AXI_arvalid(1'b0), .S02_AXI_arready(),
        .S02_AXI_rid(), .S02_AXI_rdata(), .S02_AXI_rresp(),
        .S02_AXI_rlast(), .S02_AXI_rvalid(), .S02_AXI_rready(1'b0),

        .ddr4_rst(~sys_rstn), .ddr4_ui_clk(ddr_ui_clk),
        .init_calib_complete(c0_init_calib_complete),
        .peripheral_aresetn(peripheral_aresetn),
        .soc_clk_100m(unused_soc_clk_100m)
    );
endmodule
