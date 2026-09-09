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
    input  wire        soc_clk,
    input  wire        soc_resetn,
    axi4_if.slave      soc_mem_axi,
    axi4_if.master     fbus_axi,
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
    output wire         capture_clk,
    output wire         capture_resetn,
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
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [2:0] video_reset_sync;
    assign capture_clk = ddr_ui_clk;
    assign capture_resetn = ddr_resetn;
    wire unused_soc_clk_100m;

    // Dedicated 2:1 global clock divider: 300.120 MHz MIG UI clock to the
    // 150.060 MHz P3 camera-video domain. No fabric-generated clock is used.
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
    assign video_resetn = video_reset_sync[2];

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) writer_video_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) reader_video_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        preprocess_read_video_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        preprocess_write_video_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) writer_ui_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) reader_ui_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        preprocess_read_ui_axi();
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4))
        all_capture_channels [16]();
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4))
        hdmi_video_channels [8]();
    wire [575:0] hdmi_stats_capture = {
        hdmi_transport_frame_count, hdmi_transport_malformed_count,
        hdmi_channel_frame_counts, hdmi_channel_overflow_counts
    };
    wire [575:0] hdmi_stats_video;
    wire [31:0] hdmi_transport_frame_count_video = hdmi_stats_video[575:544];
    wire [31:0] hdmi_transport_malformed_count_video =
        hdmi_stats_video[543:512];
    wire [255:0] hdmi_channel_frame_counts_video = hdmi_stats_video[511:256];
    wire [255:0] hdmi_channel_overflow_counts_video = hdmi_stats_video[255:0];
    wire [511:0] all_malformed_counts = {
        hdmi_channel_overflow_counts_video, malformed_counts
    };
    wire hdmi_capture_enable_video;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0]
        hdmi_capture_enable_sync = 2'b00;

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(576)
    ) u_hdmi_stats_to_video (
        .src_clk(capture_clk), .src_in(hdmi_stats_capture),
        .dest_clk(video_clk), .dest_out(hdmi_stats_video)
    );

    always @(posedge capture_clk) begin
        if (!capture_resetn)
            hdmi_capture_enable_sync <= 2'b00;
        else
            hdmi_capture_enable_sync <=
                {hdmi_capture_enable_sync[0], hdmi_capture_enable_video};
    end
    assign hdmi_capture_enable = hdmi_capture_enable_sync[1];

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

            video_stream_cdc #(.FIFO_DEPTH(1024)) u_hdmi_stream_cdc (
                .s_stream(hdmi_capture_channels[capture_index]),
                .m_clk(video_clk), .m_resetn(video_resetn),
                .m_stream(hdmi_video_channels[capture_index])
            );

            assign all_capture_channels[capture_index+8].aclk =
                hdmi_video_channels[capture_index].aclk;
            assign all_capture_channels[capture_index+8].aresetn =
                hdmi_video_channels[capture_index].aresetn;
            assign all_capture_channels[capture_index+8].data =
                hdmi_video_channels[capture_index].data;
            assign all_capture_channels[capture_index+8].valid =
                hdmi_video_channels[capture_index].valid;
            assign all_capture_channels[capture_index+8].sof =
                hdmi_video_channels[capture_index].sof;
            assign all_capture_channels[capture_index+8].eol =
                hdmi_video_channels[capture_index].eol;
            assign all_capture_channels[capture_index+8].eof =
                hdmi_video_channels[capture_index].eof;
            assign all_capture_channels[capture_index+8].stream_id =
                hdmi_video_channels[capture_index].stream_id;
            assign all_capture_channels[capture_index+8].frame_id =
                hdmi_video_channels[capture_index].frame_id;
            assign all_capture_channels[capture_index+8].error =
                hdmi_video_channels[capture_index].error;
            assign hdmi_video_channels[capture_index].ready =
                all_capture_channels[capture_index+8].ready;
        end
    endgenerate

    wire writer_error;
    wire reader_error;
    wire reader_underflow;

    axi4_ui_write_cdc u_writer_ui_cdc (
        .s_axi(writer_video_axi), .ui_clk(ddr_ui_clk),
        .ui_resetn(ddr_resetn), .m_axi(writer_ui_axi)
    );
    axi4_ui_read_cdc u_reader_ui_cdc (
        .s_axi(reader_video_axi), .ui_clk(ddr_ui_clk),
        .ui_resetn(ddr_resetn), .m_axi(reader_ui_axi)
    );
    axi4_ui_read_cdc u_preprocess_read_ui_cdc (
        .s_axi(preprocess_read_video_axi), .ui_clk(ddr_ui_clk),
        .ui_resetn(ddr_resetn), .m_axi(preprocess_read_ui_axi)
    );
    // Match demo/ai: framebuffer reads stay on the non-coherent DDR S02
    // read channel, while completed input tensors enter the SoC through its
    // coherent FBus.  The bridge also applies the bit-31 CPU memory alias.
    axi4_write_cdc u_preprocess_fbus_write_cdc (
        .s_axi(preprocess_write_video_axi), .m_clk(soc_clk),
        .m_resetn(soc_resetn), .m_axi(fbus_axi)
    );

    // S01 is deliberately split by AXI channel, matching demo/ai: capture is
    // write-only and HDMI display is read-only.  Terminate the unused return
    // channels locally so each interface still has exactly one driver.
    assign writer_ui_axi.arready = 1'b0;
    assign writer_ui_axi.rid = 3'd0;
    assign writer_ui_axi.rdata = 256'd0;
    assign writer_ui_axi.rresp = 2'b00;
    assign writer_ui_axi.rlast = 1'b0;
    assign writer_ui_axi.rvalid = 1'b0;
    assign reader_ui_axi.awready = 1'b0;
    assign reader_ui_axi.wready = 1'b0;
    assign reader_ui_axi.bid = 3'd0;
    assign reader_ui_axi.bresp = 2'b00;
    assign reader_ui_axi.bvalid = 1'b0;

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
        .video_clk(video_clk),
        .video_resetn(video_resetn),
        .control_axil(framebuffer_axil),
        .capture_channels(all_capture_channels),
        .malformed_counts(all_malformed_counts),
        .hdmi_capture_enable(hdmi_capture_enable_video),
        .hdmi_transport_frame_count(hdmi_transport_frame_count_video),
        .hdmi_transport_malformed_count(
            hdmi_transport_malformed_count_video),
        .hdmi_channel_frame_counts(hdmi_channel_frame_counts_video),
        .writer_axi(writer_video_axi),
        .reader_axi(reader_video_axi),
        .preprocess_read_axi(preprocess_read_video_axi),
        .preprocess_write_axi(preprocess_write_video_axi),
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

        .S01_AXI_awid(writer_ui_axi.awid),
        .S01_AXI_awaddr(writer_ui_axi.awaddr),
        .S01_AXI_awlen(writer_ui_axi.awlen),
        .S01_AXI_awsize(writer_ui_axi.awsize),
        .S01_AXI_awburst(writer_ui_axi.awburst),
        .S01_AXI_awlock(writer_ui_axi.awlock),
        .S01_AXI_awcache(writer_ui_axi.awcache),
        .S01_AXI_awprot(writer_ui_axi.awprot),
        .S01_AXI_awqos(writer_ui_axi.awqos),
        .S01_AXI_awregion(4'h0),
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
        .S01_AXI_arqos(reader_ui_axi.arqos),
        .S01_AXI_arregion(4'h0),
        .S01_AXI_arvalid(reader_ui_axi.arvalid),
        .S01_AXI_arready(reader_ui_axi.arready),
        .S01_AXI_rid(reader_ui_axi.rid),
        .S01_AXI_rdata(reader_ui_axi.rdata),
        .S01_AXI_rresp(reader_ui_axi.rresp),
        .S01_AXI_rlast(reader_ui_axi.rlast),
        .S01_AXI_rvalid(reader_ui_axi.rvalid),
        .S01_AXI_rready(reader_ui_axi.rready),

        // S02 is read-only for preprocessing. Tensor writes use coherent
        // FBus, so terminate the unused S02 write request channels.
        .S02_AXI_awid(3'd0),
        .S02_AXI_awaddr(32'd0),
        .S02_AXI_awlen(8'd0),
        .S02_AXI_awsize(3'd0),
        .S02_AXI_awburst(2'd0),
        .S02_AXI_awlock(1'b0),
        .S02_AXI_awcache(4'd0),
        .S02_AXI_awprot(3'd0),
        .S02_AXI_awqos(4'd0),
        .S02_AXI_awregion(4'h0),
        .S02_AXI_awvalid(1'b0),
        .S02_AXI_awready(),
        .S02_AXI_wdata(256'd0),
        .S02_AXI_wstrb(32'd0),
        .S02_AXI_wlast(1'b0),
        .S02_AXI_wvalid(1'b0),
        .S02_AXI_wready(),
        .S02_AXI_bid(),
        .S02_AXI_bresp(),
        .S02_AXI_bvalid(),
        .S02_AXI_bready(1'b0),
        .S02_AXI_arid(preprocess_read_ui_axi.arid),
        .S02_AXI_araddr(preprocess_read_ui_axi.araddr),
        .S02_AXI_arlen(preprocess_read_ui_axi.arlen),
        .S02_AXI_arsize(preprocess_read_ui_axi.arsize),
        .S02_AXI_arburst(preprocess_read_ui_axi.arburst),
        .S02_AXI_arlock(preprocess_read_ui_axi.arlock),
        .S02_AXI_arcache(preprocess_read_ui_axi.arcache),
        .S02_AXI_arprot(preprocess_read_ui_axi.arprot),
        .S02_AXI_arqos(preprocess_read_ui_axi.arqos),
        .S02_AXI_arregion(4'h0),
        .S02_AXI_arvalid(preprocess_read_ui_axi.arvalid),
        .S02_AXI_arready(preprocess_read_ui_axi.arready),
        .S02_AXI_rid(preprocess_read_ui_axi.rid),
        .S02_AXI_rdata(preprocess_read_ui_axi.rdata),
        .S02_AXI_rresp(preprocess_read_ui_axi.rresp),
        .S02_AXI_rlast(preprocess_read_ui_axi.rlast),
        .S02_AXI_rvalid(preprocess_read_ui_axi.rvalid),
        .S02_AXI_rready(preprocess_read_ui_axi.rready),

        .ddr4_rst(~sys_rstn),
        .ddr4_ui_clk(ddr_ui_clk),
        .init_calib_complete(c0_init_calib_complete),
        .peripheral_aresetn(peripheral_aresetn),
        .soc_clk_100m(unused_soc_clk_100m)
    );

    wire unused_status = &{1'b0, camera_axis_diag, writer_error,
                           reader_error, reader_underflow};
endmodule
