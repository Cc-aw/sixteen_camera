`timescale 1ns/1ps

// HDMI TX data path only. Board-control GPIO/IIC and MMIO decoding live in
// video_control_subsystem, so this module contains no system-level policy.
module hdmi_tx_datapath (
    axis_video_if.sink    video_axis,
    axis_video_if.source  capture_axis,
    axi_lite_if.slave     vphy_axil,
    axi_lite_if.slave     hdmi_rx_axil,
    axi_lite_if.slave     hdmi_tx_axil,

    input  wire           capture_clk,
    input  wire           capture_resetn,

    input  wire           hdmi_rx_clk_p,
    input  wire           hdmi_rx_clk_n,
    input  wire [2:0]     hdmi_rx_data_p,
    input  wire [2:0]     hdmi_rx_data_n,
    input  wire           hdmi_rx_pwr_det,
    output wire           hdmi_rx_hpd,
    inout  wire           hdmi_rx_ddc_scl,
    inout  wire           hdmi_rx_ddc_sda,
    output wire           hdmi_ref_clk_p,
    output wire           hdmi_ref_clk_n,
    input  wire           hdmi_tx_refclk_p,
    input  wire           hdmi_tx_refclk_n,
    input  wire           tx_refclk_rdy,
    output wire [3:0]     hdmi_tx_data_p,
    output wire [3:0]     hdmi_tx_data_n,
    input  wire           hdmi_tx_hpd,
    inout  wire           hdmi_tx_ddc_scl,
    inout  wire           hdmi_tx_ddc_sda,
    output wire           hdmi_tx_locked,
    output wire           vphy_irq,
    output wire           hdmi_rx_irq,
    output wire           hdmi_tx_irq
);
    wire tx_scl_i, tx_scl_o, tx_scl_t;
    wire tx_sda_i, tx_sda_o, tx_sda_t;
    wire tx_refclk, tx_refclk_div2, tx_refclk_bufg;
    wire txoutclk, rxoutclk, tx_video_clk, rx_video_clk;
    wire [7:0] tx_sb_data;
    wire tx_sb_valid;
    wire [39:0] tx_link_data [0:2];
    wire [2:0] tx_link_valid;
    wire [39:0] rx_link_data [0:2];
    wire [2:0] rx_link_valid;
    wire [7:0] rx_sb_data;
    wire rx_sb_valid;
    wire rx_scl_i, rx_scl_o, rx_scl_t;
    wire rx_sda_i, rx_sda_o, rx_sda_t;
    wire [47:0] rx_video_tdata;
    wire rx_video_tvalid, rx_video_tready, rx_video_tuser, rx_video_tlast;
    wire [47:0] rx_slice_tdata;
    wire rx_slice_tvalid, rx_slice_tready, rx_slice_tuser, rx_slice_tlast;
    wire audio_ready_unused;
    wire [47:0] tx_video_tdata;
    wire tx_video_tvalid, tx_video_tready, tx_video_tuser, tx_video_tlast;

    IOBUF u_tx_scl_iobuf (
        .I(tx_scl_o), .O(tx_scl_i), .T(tx_scl_t), .IO(hdmi_tx_ddc_scl)
    );
    IOBUF u_tx_sda_iobuf (
        .I(tx_sda_o), .O(tx_sda_i), .T(tx_sda_t), .IO(hdmi_tx_ddc_sda)
    );
    IOBUF u_rx_scl_iobuf (
        .I(rx_scl_o), .O(rx_scl_i), .T(rx_scl_t), .IO(hdmi_rx_ddc_scl)
    );
    IOBUF u_rx_sda_iobuf (
        .I(rx_sda_o), .O(rx_sda_i), .T(rx_sda_t), .IO(hdmi_rx_ddc_sda)
    );

    assign capture_axis.aclk = capture_clk;
    assign capture_axis.aresetn = capture_resetn;

    rx_axis_reg_slice u_rx_axis_reg_slice (
        .aclk(capture_clk), .aresetn(capture_resetn),
        .s_axis_tdata(rx_video_tdata), .s_axis_tvalid(rx_video_tvalid),
        .s_axis_tready(rx_video_tready), .s_axis_tuser(rx_video_tuser),
        .s_axis_tlast(rx_video_tlast), .m_axis_tdata(rx_slice_tdata),
        .m_axis_tvalid(rx_slice_tvalid), .m_axis_tready(rx_slice_tready),
        .m_axis_tuser(rx_slice_tuser), .m_axis_tlast(rx_slice_tlast)
    );

    axis_video_if #(.DATA_WIDTH(48)) rx_slice_axis();
    assign rx_slice_axis.aclk = capture_clk;
    assign rx_slice_axis.aresetn = capture_resetn;
    assign rx_slice_axis.tdata = rx_slice_tdata;
    assign rx_slice_axis.tvalid = rx_slice_tvalid;
    assign rx_slice_axis.tuser = rx_slice_tuser;
    assign rx_slice_axis.tlast = rx_slice_tlast;
    assign rx_slice_tready = rx_slice_axis.tready;

    axis_downscale_2x2 u_downscale (
        .s_axis(rx_slice_axis), .m_axis(capture_axis)
    );

    v_hdmi_rx_ss_0 u_hdmi_rx (
        .s_axi_cpu_aclk(hdmi_rx_axil.aclk),
        .s_axi_cpu_aresetn(hdmi_rx_axil.aresetn),
        .cable_detect(hdmi_rx_pwr_det), .link_clk(rxoutclk),
        .video_clk(rx_video_clk), .s_axis_video_aclk(capture_clk),
        .s_axis_video_aresetn(capture_resetn),
        .s_axis_audio_aclk(hdmi_rx_axil.aclk),
        .s_axis_audio_aresetn(hdmi_rx_axil.aresetn),
        .LINK_DATA0_IN_tdata(rx_link_data[0]),
        .LINK_DATA0_IN_tvalid(rx_link_valid[0]),
        .LINK_DATA1_IN_tdata(rx_link_data[1]),
        .LINK_DATA1_IN_tvalid(rx_link_valid[1]),
        .LINK_DATA2_IN_tdata(rx_link_data[2]),
        .LINK_DATA2_IN_tvalid(rx_link_valid[2]),
        .SB_STATUS_IN_tdata(rx_sb_data),
        .SB_STATUS_IN_tvalid(rx_sb_valid),
        .VIDEO_OUT_tdata(rx_video_tdata), .VIDEO_OUT_tlast(rx_video_tlast),
        .VIDEO_OUT_tready(rx_video_tready), .VIDEO_OUT_tuser(rx_video_tuser),
        .VIDEO_OUT_tvalid(rx_video_tvalid),
        .AUDIO_OUT_tdata(), .AUDIO_OUT_tid(), .AUDIO_OUT_tready(1'b1),
        .AUDIO_OUT_tvalid(), .acr_cts(), .acr_n(), .acr_valid(), .fid(),
        .hpd(hdmi_rx_hpd), .irq(hdmi_rx_irq),
        .S_AXI_CPU_IN_awaddr(hdmi_rx_axil.awaddr[8:0]),
        .S_AXI_CPU_IN_awprot(hdmi_rx_axil.awprot),
        .S_AXI_CPU_IN_awvalid(hdmi_rx_axil.awvalid),
        .S_AXI_CPU_IN_awready(hdmi_rx_axil.awready),
        .S_AXI_CPU_IN_wdata(hdmi_rx_axil.wdata),
        .S_AXI_CPU_IN_wstrb(hdmi_rx_axil.wstrb),
        .S_AXI_CPU_IN_wvalid(hdmi_rx_axil.wvalid),
        .S_AXI_CPU_IN_wready(hdmi_rx_axil.wready),
        .S_AXI_CPU_IN_bresp(hdmi_rx_axil.bresp),
        .S_AXI_CPU_IN_bvalid(hdmi_rx_axil.bvalid),
        .S_AXI_CPU_IN_bready(hdmi_rx_axil.bready),
        .S_AXI_CPU_IN_araddr(hdmi_rx_axil.araddr[8:0]),
        .S_AXI_CPU_IN_arprot(hdmi_rx_axil.arprot),
        .S_AXI_CPU_IN_arvalid(hdmi_rx_axil.arvalid),
        .S_AXI_CPU_IN_arready(hdmi_rx_axil.arready),
        .S_AXI_CPU_IN_rdata(hdmi_rx_axil.rdata),
        .S_AXI_CPU_IN_rresp(hdmi_rx_axil.rresp),
        .S_AXI_CPU_IN_rvalid(hdmi_rx_axil.rvalid),
        .S_AXI_CPU_IN_rready(hdmi_rx_axil.rready),
        .DDC_OUT_scl_i(rx_scl_i), .DDC_OUT_scl_o(rx_scl_o),
        .DDC_OUT_scl_t(rx_scl_t), .DDC_OUT_sda_i(rx_sda_i),
        .DDC_OUT_sda_o(rx_sda_o), .DDC_OUT_sda_t(rx_sda_t)
    );

    tx_refclk_ibuf u_tx_refclk_ibuf (
        .IBUF_DS_P(hdmi_tx_refclk_p), .IBUF_DS_N(hdmi_tx_refclk_n),
        .IBUF_OUT(tx_refclk), .IBUF_DS_ODIV2(tx_refclk_div2)
    );
    tx_refclk_bufg u_tx_refclk_bufg (
        .BUFG_GT_I(tx_refclk_div2), .BUFG_GT_CE(1'b1),
        .BUFG_GT_CEMASK(1'b0), .BUFG_GT_CLR(1'b0),
        .BUFG_GT_CLRMASK(1'b0), .BUFG_GT_DIV(3'b000),
        .BUFG_GT_O(tx_refclk_bufg)
    );

    tx_axis_reg_slice u_tx_axis_reg_slice (
        .aclk(video_axis.aclk), .aresetn(video_axis.aresetn),
        .s_axis_tdata(video_axis.tdata),
        .s_axis_tvalid(video_axis.tvalid),
        .s_axis_tready(video_axis.tready),
        .s_axis_tuser(video_axis.tuser), .s_axis_tlast(video_axis.tlast),
        .m_axis_tdata(tx_video_tdata), .m_axis_tvalid(tx_video_tvalid),
        .m_axis_tready(tx_video_tready), .m_axis_tuser(tx_video_tuser),
        .m_axis_tlast(tx_video_tlast)
    );

    v_hdmi_tx_ss_0 u_hdmi_tx (
        .s_axi_cpu_aclk(hdmi_tx_axil.aclk),
        .s_axi_cpu_aresetn(hdmi_tx_axil.aresetn),
        .link_clk(txoutclk), .video_clk(tx_video_clk),
        .s_axis_video_aclk(video_axis.aclk),
        .s_axis_video_aresetn(video_axis.aresetn),
        .VIDEO_IN_tdata(tx_video_tdata), .VIDEO_IN_tlast(tx_video_tlast),
        .VIDEO_IN_tready(tx_video_tready), .VIDEO_IN_tuser(tx_video_tuser),
        .VIDEO_IN_tvalid(tx_video_tvalid),
        .s_axis_audio_aclk(hdmi_tx_axil.aclk),
        .s_axis_audio_aresetn(hdmi_tx_axil.aresetn),
        .AUDIO_IN_tdata(32'b0), .AUDIO_IN_tid(8'b0),
        .AUDIO_IN_tvalid(1'b0), .AUDIO_IN_tready(audio_ready_unused),
        .acr_cts(20'b0), .acr_n(20'b0), .acr_valid(1'b0), .fid(1'b0),
        .hpd(hdmi_tx_hpd), .irq(hdmi_tx_irq), .locked(hdmi_tx_locked),
        .SB_STATUS_IN_tdata(tx_sb_data), .SB_STATUS_IN_tvalid(tx_sb_valid),
        .S_AXI_CPU_IN_awaddr(hdmi_tx_axil.awaddr),
        .S_AXI_CPU_IN_awprot(hdmi_tx_axil.awprot),
        .S_AXI_CPU_IN_awvalid(hdmi_tx_axil.awvalid),
        .S_AXI_CPU_IN_awready(hdmi_tx_axil.awready),
        .S_AXI_CPU_IN_wdata(hdmi_tx_axil.wdata),
        .S_AXI_CPU_IN_wstrb(hdmi_tx_axil.wstrb),
        .S_AXI_CPU_IN_wvalid(hdmi_tx_axil.wvalid),
        .S_AXI_CPU_IN_wready(hdmi_tx_axil.wready),
        .S_AXI_CPU_IN_bresp(hdmi_tx_axil.bresp),
        .S_AXI_CPU_IN_bvalid(hdmi_tx_axil.bvalid),
        .S_AXI_CPU_IN_bready(hdmi_tx_axil.bready),
        .S_AXI_CPU_IN_araddr(hdmi_tx_axil.araddr),
        .S_AXI_CPU_IN_arprot(hdmi_tx_axil.arprot),
        .S_AXI_CPU_IN_arvalid(hdmi_tx_axil.arvalid),
        .S_AXI_CPU_IN_arready(hdmi_tx_axil.arready),
        .S_AXI_CPU_IN_rdata(hdmi_tx_axil.rdata),
        .S_AXI_CPU_IN_rresp(hdmi_tx_axil.rresp),
        .S_AXI_CPU_IN_rvalid(hdmi_tx_axil.rvalid),
        .S_AXI_CPU_IN_rready(hdmi_tx_axil.rready),
        .DDC_OUT_scl_i(tx_scl_i), .DDC_OUT_scl_o(tx_scl_o),
        .DDC_OUT_scl_t(tx_scl_t), .DDC_OUT_sda_i(tx_sda_i),
        .DDC_OUT_sda_o(tx_sda_o), .DDC_OUT_sda_t(tx_sda_t),
        .LINK_DATA0_OUT_tdata(tx_link_data[0]),
        .LINK_DATA0_OUT_tvalid(tx_link_valid[0]),
        .LINK_DATA1_OUT_tdata(tx_link_data[1]),
        .LINK_DATA1_OUT_tvalid(tx_link_valid[1]),
        .LINK_DATA2_OUT_tdata(tx_link_data[2]),
        .LINK_DATA2_OUT_tvalid(tx_link_valid[2])
    );

    vid_phy_controller_0 u_vphy (
        .tx_refclk_rdy(tx_refclk_rdy), .tx_tmds_clk(),
        .tx_video_clk(tx_video_clk), .rx_tmds_clk(), .rx_video_clk(rx_video_clk),
        .rx_tmds_clk_p(hdmi_ref_clk_p), .rx_tmds_clk_n(hdmi_ref_clk_n),
        .mgtrefclk0_pad_p_in(hdmi_rx_clk_p),
        .mgtrefclk0_pad_n_in(hdmi_rx_clk_n),
        .gtsouthrefclk0_in(tx_refclk),
        .gtsouthrefclk0_odiv2_in(tx_refclk_bufg),
        .gtsouthrefclk00_in(tx_refclk), .gtsouthrefclk01_in(tx_refclk),
        .txrefclk_ceb(), .phy_rxn_in(hdmi_rx_data_n),
        .phy_rxp_in(hdmi_rx_data_p), .phy_txn_out(hdmi_tx_data_n),
        .phy_txp_out(hdmi_tx_data_p), .rxoutclk(rxoutclk),
        .txoutclk(txoutclk),
        .vid_phy_tx_axi4s_aclk(txoutclk),
        .vid_phy_tx_axi4s_aresetn(1'b1),
        .vid_phy_tx_axi4s_ch0_tdata(tx_link_data[0]),
        .vid_phy_tx_axi4s_ch0_tuser(1'b0),
        .vid_phy_tx_axi4s_ch0_tvalid(tx_link_valid[0]),
        .vid_phy_tx_axi4s_ch0_tready(),
        .vid_phy_tx_axi4s_ch1_tdata(tx_link_data[1]),
        .vid_phy_tx_axi4s_ch1_tuser(1'b0),
        .vid_phy_tx_axi4s_ch1_tvalid(tx_link_valid[1]),
        .vid_phy_tx_axi4s_ch1_tready(),
        .vid_phy_tx_axi4s_ch2_tdata(tx_link_data[2]),
        .vid_phy_tx_axi4s_ch2_tuser(1'b0),
        .vid_phy_tx_axi4s_ch2_tvalid(tx_link_valid[2]),
        .vid_phy_tx_axi4s_ch2_tready(),
        .vid_phy_rx_axi4s_aclk(rxoutclk),
        .vid_phy_rx_axi4s_aresetn(1'b1),
        .vid_phy_rx_axi4s_ch0_tdata(rx_link_data[0]), .vid_phy_rx_axi4s_ch0_tuser(),
        .vid_phy_rx_axi4s_ch0_tvalid(rx_link_valid[0]), .vid_phy_rx_axi4s_ch0_tready(1'b1),
        .vid_phy_rx_axi4s_ch1_tdata(rx_link_data[1]), .vid_phy_rx_axi4s_ch1_tuser(),
        .vid_phy_rx_axi4s_ch1_tvalid(rx_link_valid[1]), .vid_phy_rx_axi4s_ch1_tready(1'b1),
        .vid_phy_rx_axi4s_ch2_tdata(rx_link_data[2]), .vid_phy_rx_axi4s_ch2_tuser(),
        .vid_phy_rx_axi4s_ch2_tvalid(rx_link_valid[2]), .vid_phy_rx_axi4s_ch2_tready(1'b1),
        .irq(vphy_irq), .vid_phy_sb_aclk(vphy_axil.aclk),
        .vid_phy_sb_aresetn(vphy_axil.aresetn),
        .vid_phy_status_sb_tx_tdata(tx_sb_data),
        .vid_phy_status_sb_tx_tvalid(tx_sb_valid),
        .vid_phy_status_sb_tx_tready(1'b1),
        .vid_phy_status_sb_rx_tdata(rx_sb_data), .vid_phy_status_sb_rx_tvalid(rx_sb_valid),
        .vid_phy_status_sb_rx_tready(1'b1),
        .vid_phy_axi4lite_awaddr(vphy_axil.awaddr),
        .vid_phy_axi4lite_awprot(vphy_axil.awprot),
        .vid_phy_axi4lite_awvalid(vphy_axil.awvalid),
        .vid_phy_axi4lite_awready(vphy_axil.awready),
        .vid_phy_axi4lite_wdata(vphy_axil.wdata),
        .vid_phy_axi4lite_wstrb(vphy_axil.wstrb),
        .vid_phy_axi4lite_wvalid(vphy_axil.wvalid),
        .vid_phy_axi4lite_wready(vphy_axil.wready),
        .vid_phy_axi4lite_bresp(vphy_axil.bresp),
        .vid_phy_axi4lite_bvalid(vphy_axil.bvalid),
        .vid_phy_axi4lite_bready(vphy_axil.bready),
        .vid_phy_axi4lite_araddr(vphy_axil.araddr),
        .vid_phy_axi4lite_arprot(vphy_axil.arprot),
        .vid_phy_axi4lite_arvalid(vphy_axil.arvalid),
        .vid_phy_axi4lite_arready(vphy_axil.arready),
        .vid_phy_axi4lite_rdata(vphy_axil.rdata),
        .vid_phy_axi4lite_rresp(vphy_axil.rresp),
        .vid_phy_axi4lite_rvalid(vphy_axil.rvalid),
        .vid_phy_axi4lite_rready(vphy_axil.rready),
        .vid_phy_axi4lite_aclk(vphy_axil.aclk),
        .vid_phy_axi4lite_aresetn(vphy_axil.aresetn), .drpclk(vphy_axil.aclk)
    );
endmodule
