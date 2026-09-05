`timescale 1ns/1ps

module ddr_memory_subsystem (
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
    axi4_if.slave      soc_mem_axi,
    axi_lite_if.slave  framebuffer_axil,
    video_stream_if.sink camera_capture_channels [8],
    video_stream_if.sink hdmi_capture_channels [8],
    output wire hdmi_capture_enable,
    input wire [479:0] camera_axis_diag,
    input wire [255:0] malformed_counts,
    input wire [31:0] hdmi_transport_frame_count,
    input wire [31:0] hdmi_transport_malformed_count,
    input wire [255:0] hdmi_channel_overflow_counts,
    input wire [255:0] hdmi_channel_frame_counts,
    axis_video_if.source video_axis,
    output wire         video_clk,
    output wire         video_resetn
);
    wire ddr_ui_clk;
    wire [0:0] peripheral_aresetn;
    // Keep DDR calibration completion out of the high-fanout video reset
    // tree.  It is asynchronous to the consumers of this module, so assert
    // the local reset immediately and release it synchronously in ddr_ui_clk.
    wire ddr_resetn_raw = peripheral_aresetn[0] && c0_init_calib_complete;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [2:0] ddr_reset_sync;
    wire ddr_resetn = ddr_reset_sync[2];
    assign video_clk = ddr_ui_clk;
    assign video_resetn = ddr_resetn;
    wire unused_soc_clk_100m;

    always @(posedge ddr_ui_clk or negedge ddr_resetn_raw) begin
        if (!ddr_resetn_raw)
            ddr_reset_sync <= 3'b000;
        else
            ddr_reset_sync <= {ddr_reset_sync[1:0], 1'b1};
    end

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) writer_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) reader_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        preprocess_read_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        preprocess_write_axi();
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4))
        all_capture_channels [16]();
    wire [511:0] all_malformed_counts = {
        hdmi_channel_overflow_counts, malformed_counts
    };

    genvar capture_index;
    generate
        for (capture_index = 0; capture_index < 8;
             capture_index = capture_index + 1) begin : g_capture_merge
            assign all_capture_channels[capture_index].aclk =
                camera_capture_channels[capture_index].aclk;
            assign all_capture_channels[capture_index].aresetn =
                camera_capture_channels[capture_index].aresetn;
            assign all_capture_channels[capture_index].data =
                camera_capture_channels[capture_index].data;
            assign all_capture_channels[capture_index].valid =
                camera_capture_channels[capture_index].valid;
            assign all_capture_channels[capture_index].sof =
                camera_capture_channels[capture_index].sof;
            assign all_capture_channels[capture_index].eol =
                camera_capture_channels[capture_index].eol;
            assign all_capture_channels[capture_index].eof =
                camera_capture_channels[capture_index].eof;
            assign all_capture_channels[capture_index].stream_id =
                camera_capture_channels[capture_index].stream_id;
            assign all_capture_channels[capture_index].frame_id =
                camera_capture_channels[capture_index].frame_id;
            assign all_capture_channels[capture_index].error =
                camera_capture_channels[capture_index].error;
            assign camera_capture_channels[capture_index].ready =
                all_capture_channels[capture_index].ready;

            assign all_capture_channels[capture_index+8].aclk =
                hdmi_capture_channels[capture_index].aclk;
            assign all_capture_channels[capture_index+8].aresetn =
                hdmi_capture_channels[capture_index].aresetn;
            assign all_capture_channels[capture_index+8].data =
                hdmi_capture_channels[capture_index].data;
            assign all_capture_channels[capture_index+8].valid =
                hdmi_capture_channels[capture_index].valid;
            assign all_capture_channels[capture_index+8].sof =
                hdmi_capture_channels[capture_index].sof;
            assign all_capture_channels[capture_index+8].eol =
                hdmi_capture_channels[capture_index].eol;
            assign all_capture_channels[capture_index+8].eof =
                hdmi_capture_channels[capture_index].eof;
            assign all_capture_channels[capture_index+8].stream_id =
                hdmi_capture_channels[capture_index].stream_id;
            assign all_capture_channels[capture_index+8].frame_id =
                hdmi_capture_channels[capture_index].frame_id;
            assign all_capture_channels[capture_index+8].error =
                hdmi_capture_channels[capture_index].error;
            assign hdmi_capture_channels[capture_index].ready =
                all_capture_channels[capture_index+8].ready;
        end
    endgenerate

    wire writer_error;
    wire reader_error;
    wire reader_underflow;

    // S01 is deliberately split by AXI channel, matching demo/ai: capture is
    // write-only and HDMI display is read-only.  Terminate the unused return
    // channels locally so each interface still has exactly one driver.
    assign writer_axi.arready = 1'b0;
    assign writer_axi.rid = 3'd0;
    assign writer_axi.rdata = 256'd0;
    assign writer_axi.rresp = 2'b00;
    assign writer_axi.rlast = 1'b0;
    assign writer_axi.rvalid = 1'b0;
    assign reader_axi.awready = 1'b0;
    assign reader_axi.wready = 1'b0;
    assign reader_axi.bid = 3'd0;
    assign reader_axi.bresp = 2'b00;
    assign reader_axi.bvalid = 1'b0;

    multi_channel_ddr_video_pipeline #(
        .CHANNELS(16),
        .GLOBAL_CHANNEL_BASE(0),
        .CAMERA_PRESENT_MASK(16'hffff),
        .FRAME_WIDTH(640),
        .FRAME_HEIGHT(480),
        .FRAME_STRIDE_BYTES(2560),
        .DEFAULT_CHANNEL_BASES({
            32'h2600_0000, 32'h2400_0000,
            32'h2200_0000, 32'h2000_0000,
            32'h1e00_0000, 32'h1c00_0000,
            32'h1a00_0000, 32'h1800_0000,
            32'h1600_0000, 32'h1400_0000,
            32'h1200_0000, 32'h1000_0000,
            32'h0e00_0000, 32'h0c00_0000,
            32'h0a00_0000, 32'h0800_0000
        })
    ) u_video_framebuffer (
        .init_done(c0_init_calib_complete),
        .ddr_ui_clk(ddr_ui_clk),
        .ddr_resetn(ddr_resetn),
        .control_axil(framebuffer_axil),
        .capture_channels(all_capture_channels),
        .malformed_counts(all_malformed_counts),
        .hdmi_capture_enable(hdmi_capture_enable),
        .hdmi_transport_frame_count(hdmi_transport_frame_count),
        .hdmi_transport_malformed_count(hdmi_transport_malformed_count),
        .hdmi_channel_frame_counts(hdmi_channel_frame_counts),
        .writer_axi(writer_axi),
        .reader_axi(reader_axi),
        .preprocess_read_axi(preprocess_read_axi),
        .preprocess_write_axi(preprocess_write_axi),
        .display_axis(video_axis),
        .writer_error(writer_error),
        .reader_error(reader_error),
        .reader_underflow(reader_underflow)
    );

    design_1_wrapper u_ddr_bd (
        .C0_DDR4_act_n(c0_ddr4_act_n),
        .C0_DDR4_adr(c0_ddr4_adr),
        .C0_DDR4_ba(c0_ddr4_ba),
        .C0_DDR4_bg(c0_ddr4_bg),
        .C0_DDR4_ck_c(c0_ddr4_ck_c),
        .C0_DDR4_ck_t(c0_ddr4_ck_t),
        .C0_DDR4_cke(c0_ddr4_cke),
        .C0_DDR4_cs_n(c0_ddr4_cs_n),
        .C0_DDR4_dm_n(c0_ddr4_dm_dbi_n),
        .C0_DDR4_dq(c0_ddr4_dq),
        .C0_DDR4_dqs_c(c0_ddr4_dqs_c),
        .C0_DDR4_dqs_t(c0_ddr4_dqs_t),
        .C0_DDR4_odt(c0_ddr4_odt),
        .C0_DDR4_reset_n(c0_ddr4_reset_n),
        .C0_SYS_CLK_clk_n(c0_sys_clk_n),
        .C0_SYS_CLK_clk_p(c0_sys_clk_p),

        .S00_ACLK(soc_mem_axi.aclk),
        .S00_ARESETN(soc_mem_axi.aresetn),
        .S00_AXI_awid(soc_mem_axi.awid),
        .S00_AXI_awaddr({soc_mem_axi.awaddr[32], soc_mem_axi.awaddr[30:0]}),
        .S00_AXI_awlen(soc_mem_axi.awlen),
        .S00_AXI_awsize(soc_mem_axi.awsize),
        .S00_AXI_awburst(soc_mem_axi.awburst),
        .S00_AXI_awlock(soc_mem_axi.awlock),
        .S00_AXI_awcache(soc_mem_axi.awcache),
        .S00_AXI_awprot(soc_mem_axi.awprot),
        .S00_AXI_awqos(soc_mem_axi.awqos),
        .S00_AXI_awregion(4'h0),
        .S00_AXI_awvalid(soc_mem_axi.awvalid),
        .S00_AXI_awready(soc_mem_axi.awready),
        .S00_AXI_wdata(soc_mem_axi.wdata),
        .S00_AXI_wstrb(soc_mem_axi.wstrb),
        .S00_AXI_wlast(soc_mem_axi.wlast),
        .S00_AXI_wvalid(soc_mem_axi.wvalid),
        .S00_AXI_wready(soc_mem_axi.wready),
        .S00_AXI_bid(soc_mem_axi.bid),
        .S00_AXI_bresp(soc_mem_axi.bresp),
        .S00_AXI_bvalid(soc_mem_axi.bvalid),
        .S00_AXI_bready(soc_mem_axi.bready),
        .S00_AXI_arid(soc_mem_axi.arid),
        .S00_AXI_araddr({soc_mem_axi.araddr[32], soc_mem_axi.araddr[30:0]}),
        .S00_AXI_arlen(soc_mem_axi.arlen),
        .S00_AXI_arsize(soc_mem_axi.arsize),
        .S00_AXI_arburst(soc_mem_axi.arburst),
        .S00_AXI_arlock(soc_mem_axi.arlock),
        .S00_AXI_arcache(soc_mem_axi.arcache),
        .S00_AXI_arprot(soc_mem_axi.arprot),
        .S00_AXI_arqos(soc_mem_axi.arqos),
        .S00_AXI_arregion(4'h0),
        .S00_AXI_arvalid(soc_mem_axi.arvalid),
        .S00_AXI_arready(soc_mem_axi.arready),
        .S00_AXI_rid(soc_mem_axi.rid),
        .S00_AXI_rdata(soc_mem_axi.rdata),
        .S00_AXI_rresp(soc_mem_axi.rresp),
        .S00_AXI_rlast(soc_mem_axi.rlast),
        .S00_AXI_rvalid(soc_mem_axi.rvalid),
        .S00_AXI_rready(soc_mem_axi.rready),

        .S01_AXI_awid(writer_axi.awid),
        .S01_AXI_awaddr(writer_axi.awaddr),
        .S01_AXI_awlen(writer_axi.awlen),
        .S01_AXI_awsize(writer_axi.awsize),
        .S01_AXI_awburst(writer_axi.awburst),
        .S01_AXI_awlock(writer_axi.awlock),
        .S01_AXI_awcache(writer_axi.awcache),
        .S01_AXI_awprot(writer_axi.awprot),
        .S01_AXI_awqos(writer_axi.awqos),
        .S01_AXI_awregion(4'h0),
        .S01_AXI_awvalid(writer_axi.awvalid),
        .S01_AXI_awready(writer_axi.awready),
        .S01_AXI_wdata(writer_axi.wdata),
        .S01_AXI_wstrb(writer_axi.wstrb),
        .S01_AXI_wlast(writer_axi.wlast),
        .S01_AXI_wvalid(writer_axi.wvalid),
        .S01_AXI_wready(writer_axi.wready),
        .S01_AXI_bid(writer_axi.bid),
        .S01_AXI_bresp(writer_axi.bresp),
        .S01_AXI_bvalid(writer_axi.bvalid),
        .S01_AXI_bready(writer_axi.bready),
        .S01_AXI_arid(reader_axi.arid),
        .S01_AXI_araddr(reader_axi.araddr),
        .S01_AXI_arlen(reader_axi.arlen),
        .S01_AXI_arsize(reader_axi.arsize),
        .S01_AXI_arburst(reader_axi.arburst),
        .S01_AXI_arlock(reader_axi.arlock),
        .S01_AXI_arcache(reader_axi.arcache),
        .S01_AXI_arprot(reader_axi.arprot),
        .S01_AXI_arqos(reader_axi.arqos),
        .S01_AXI_arregion(4'h0),
        .S01_AXI_arvalid(reader_axi.arvalid),
        .S01_AXI_arready(reader_axi.arready),
        .S01_AXI_rid(reader_axi.rid),
        .S01_AXI_rdata(reader_axi.rdata),
        .S01_AXI_rresp(reader_axi.rresp),
        .S01_AXI_rlast(reader_axi.rlast),
        .S01_AXI_rvalid(reader_axi.rvalid),
        .S01_AXI_rready(reader_axi.rready),

        // Preprocess reads and writes share DDR S02. The accelerator exposes
        // separate AXI interfaces so the independent channels remain clear.
        .S02_AXI_awid(preprocess_write_axi.awid),
        .S02_AXI_awaddr(preprocess_write_axi.awaddr),
        .S02_AXI_awlen(preprocess_write_axi.awlen),
        .S02_AXI_awsize(preprocess_write_axi.awsize),
        .S02_AXI_awburst(preprocess_write_axi.awburst),
        .S02_AXI_awlock(preprocess_write_axi.awlock),
        .S02_AXI_awcache(preprocess_write_axi.awcache),
        .S02_AXI_awprot(preprocess_write_axi.awprot),
        .S02_AXI_awqos(preprocess_write_axi.awqos),
        .S02_AXI_awregion(4'h0),
        .S02_AXI_awvalid(preprocess_write_axi.awvalid),
        .S02_AXI_awready(preprocess_write_axi.awready),
        .S02_AXI_wdata(preprocess_write_axi.wdata),
        .S02_AXI_wstrb(preprocess_write_axi.wstrb),
        .S02_AXI_wlast(preprocess_write_axi.wlast),
        .S02_AXI_wvalid(preprocess_write_axi.wvalid),
        .S02_AXI_wready(preprocess_write_axi.wready),
        .S02_AXI_bid(preprocess_write_axi.bid),
        .S02_AXI_bresp(preprocess_write_axi.bresp),
        .S02_AXI_bvalid(preprocess_write_axi.bvalid),
        .S02_AXI_bready(preprocess_write_axi.bready),
        .S02_AXI_arid(preprocess_read_axi.arid),
        .S02_AXI_araddr(preprocess_read_axi.araddr),
        .S02_AXI_arlen(preprocess_read_axi.arlen),
        .S02_AXI_arsize(preprocess_read_axi.arsize),
        .S02_AXI_arburst(preprocess_read_axi.arburst),
        .S02_AXI_arlock(preprocess_read_axi.arlock),
        .S02_AXI_arcache(preprocess_read_axi.arcache),
        .S02_AXI_arprot(preprocess_read_axi.arprot),
        .S02_AXI_arqos(preprocess_read_axi.arqos),
        .S02_AXI_arregion(4'h0),
        .S02_AXI_arvalid(preprocess_read_axi.arvalid),
        .S02_AXI_arready(preprocess_read_axi.arready),
        .S02_AXI_rid(preprocess_read_axi.rid),
        .S02_AXI_rdata(preprocess_read_axi.rdata),
        .S02_AXI_rresp(preprocess_read_axi.rresp),
        .S02_AXI_rlast(preprocess_read_axi.rlast),
        .S02_AXI_rvalid(preprocess_read_axi.rvalid),
        .S02_AXI_rready(preprocess_read_axi.rready),

        .ddr4_rst(~sys_rstn),
        .ddr4_ui_clk(ddr_ui_clk),
        .init_calib_complete(c0_init_calib_complete),
        .peripheral_aresetn(peripheral_aresetn),
        .soc_clk_100m(unused_soc_clk_100m)
    );

    wire unused_status = &{1'b0, camera_axis_diag, writer_error,
                           reader_error, reader_underflow};
endmodule
