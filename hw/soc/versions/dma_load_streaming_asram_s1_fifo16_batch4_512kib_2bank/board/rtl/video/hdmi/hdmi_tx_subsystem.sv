`timescale 1ns/1ps

// HDMI transmit subsystem: display AXIS, TX protocol IP and DDC pins.
// GT transceivers and the shared VPHY remain in hdmi_phy_subsystem.
module hdmi_tx_subsystem (
    axis_video_if.sink video_axis,
    axi_lite_if.slave hdmi_tx_axil,
    input wire txoutclk,
    input wire tx_video_clk,
    input wire [7:0] tx_sb_data,
    input wire tx_sb_valid,
    output wire [2:0][39:0] tx_link_data,
    output wire [2:0] tx_link_valid,
    input wire hdmi_tx_hpd,
    inout wire hdmi_tx_ddc_scl,
    inout wire hdmi_tx_ddc_sda,
    output wire hdmi_tx_locked,
    output wire hdmi_tx_irq
);
    wire tx_scl_i, tx_scl_o, tx_scl_t;
    wire tx_sda_i, tx_sda_o, tx_sda_t;
    wire [47:0] tx_video_tdata;
    wire tx_video_tvalid, tx_video_tready, tx_video_tuser, tx_video_tlast;
    wire audio_ready_unused;

    IOBUF u_tx_scl_iobuf (
        .I(tx_scl_o), .O(tx_scl_i), .T(tx_scl_t), .IO(hdmi_tx_ddc_scl)
    );
    IOBUF u_tx_sda_iobuf (
        .I(tx_sda_o), .O(tx_sda_i), .T(tx_sda_t), .IO(hdmi_tx_ddc_sda)
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
endmodule
