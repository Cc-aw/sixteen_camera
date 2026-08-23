`timescale 1ns/1ps

// HDMI receive subsystem: RX protocol IP, DDC pins and the capture AXIS path.
// GT transceivers and the shared VPHY remain in hdmi_phy_subsystem.
module hdmi_rx_subsystem (
    axis_video_if.source capture_axis,
    axi_lite_if.slave hdmi_rx_axil,
    input wire capture_clk,
    input wire capture_resetn,
    input wire rxoutclk,
    input wire rx_video_clk,
    input wire [2:0][39:0] rx_link_data,
    input wire [2:0] rx_link_valid,
    input wire [7:0] rx_sb_data,
    input wire rx_sb_valid,
    input wire hdmi_rx_pwr_det,
    output wire hdmi_rx_hpd,
    inout wire hdmi_rx_ddc_scl,
    inout wire hdmi_rx_ddc_sda,
    output wire hdmi_rx_irq
);
    wire rx_scl_i, rx_scl_o, rx_scl_t;
    wire rx_sda_i, rx_sda_o, rx_sda_t;
    wire [47:0] rx_video_tdata;
    wire rx_video_tvalid, rx_video_tready, rx_video_tuser, rx_video_tlast;
    wire [47:0] rx_slice_tdata;
    wire rx_slice_tvalid, rx_slice_tready, rx_slice_tuser, rx_slice_tlast;

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
endmodule
