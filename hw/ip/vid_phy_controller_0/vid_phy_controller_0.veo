// (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of AMD and is protected under U.S. and international copyright
// and other intellectual property laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// AMD, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) AMD shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or AMD had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// AMD products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of AMD products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.

// IP VLNV: xilinx.com:ip:vid_phy_controller:2.2
// IP Revision: 17

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
vid_phy_controller_0 your_instance_name (
  .tx_refclk_rdy(tx_refclk_rdy),                              // input wire tx_refclk_rdy
  .tx_tmds_clk(tx_tmds_clk),                                  // output wire tx_tmds_clk
  .tx_video_clk(tx_video_clk),                                // output wire tx_video_clk
  .rx_tmds_clk(rx_tmds_clk),                                  // output wire rx_tmds_clk
  .rx_video_clk(rx_video_clk),                                // output wire rx_video_clk
  .rx_tmds_clk_p(rx_tmds_clk_p),                              // output wire rx_tmds_clk_p
  .rx_tmds_clk_n(rx_tmds_clk_n),                              // output wire rx_tmds_clk_n
  .mgtrefclk0_pad_p_in(mgtrefclk0_pad_p_in),                  // input wire mgtrefclk0_pad_p_in
  .mgtrefclk0_pad_n_in(mgtrefclk0_pad_n_in),                  // input wire mgtrefclk0_pad_n_in
  .gtsouthrefclk0_in(gtsouthrefclk0_in),                      // input wire gtsouthrefclk0_in
  .gtsouthrefclk0_odiv2_in(gtsouthrefclk0_odiv2_in),          // input wire gtsouthrefclk0_odiv2_in
  .gtsouthrefclk00_in(gtsouthrefclk00_in),                    // input wire gtsouthrefclk00_in
  .gtsouthrefclk01_in(gtsouthrefclk01_in),                    // input wire gtsouthrefclk01_in
  .txrefclk_ceb(txrefclk_ceb),                                // output wire txrefclk_ceb
  .phy_rxn_in(phy_rxn_in),                                    // input wire [2 : 0] phy_rxn_in
  .phy_rxp_in(phy_rxp_in),                                    // input wire [2 : 0] phy_rxp_in
  .phy_txn_out(phy_txn_out),                                  // output wire [3 : 0] phy_txn_out
  .phy_txp_out(phy_txp_out),                                  // output wire [3 : 0] phy_txp_out
  .rxoutclk(rxoutclk),                                        // output wire rxoutclk
  .txoutclk(txoutclk),                                        // output wire txoutclk
  .vid_phy_tx_axi4s_aclk(vid_phy_tx_axi4s_aclk),              // input wire vid_phy_tx_axi4s_aclk
  .vid_phy_tx_axi4s_aresetn(vid_phy_tx_axi4s_aresetn),        // input wire vid_phy_tx_axi4s_aresetn
  .vid_phy_tx_axi4s_ch0_tdata(vid_phy_tx_axi4s_ch0_tdata),    // input wire [39 : 0] vid_phy_tx_axi4s_ch0_tdata
  .vid_phy_tx_axi4s_ch0_tuser(vid_phy_tx_axi4s_ch0_tuser),    // input wire [0 : 0] vid_phy_tx_axi4s_ch0_tuser
  .vid_phy_tx_axi4s_ch0_tvalid(vid_phy_tx_axi4s_ch0_tvalid),  // input wire vid_phy_tx_axi4s_ch0_tvalid
  .vid_phy_tx_axi4s_ch0_tready(vid_phy_tx_axi4s_ch0_tready),  // output wire vid_phy_tx_axi4s_ch0_tready
  .vid_phy_tx_axi4s_ch1_tdata(vid_phy_tx_axi4s_ch1_tdata),    // input wire [39 : 0] vid_phy_tx_axi4s_ch1_tdata
  .vid_phy_tx_axi4s_ch1_tuser(vid_phy_tx_axi4s_ch1_tuser),    // input wire [0 : 0] vid_phy_tx_axi4s_ch1_tuser
  .vid_phy_tx_axi4s_ch1_tvalid(vid_phy_tx_axi4s_ch1_tvalid),  // input wire vid_phy_tx_axi4s_ch1_tvalid
  .vid_phy_tx_axi4s_ch1_tready(vid_phy_tx_axi4s_ch1_tready),  // output wire vid_phy_tx_axi4s_ch1_tready
  .vid_phy_tx_axi4s_ch2_tdata(vid_phy_tx_axi4s_ch2_tdata),    // input wire [39 : 0] vid_phy_tx_axi4s_ch2_tdata
  .vid_phy_tx_axi4s_ch2_tuser(vid_phy_tx_axi4s_ch2_tuser),    // input wire [0 : 0] vid_phy_tx_axi4s_ch2_tuser
  .vid_phy_tx_axi4s_ch2_tvalid(vid_phy_tx_axi4s_ch2_tvalid),  // input wire vid_phy_tx_axi4s_ch2_tvalid
  .vid_phy_tx_axi4s_ch2_tready(vid_phy_tx_axi4s_ch2_tready),  // output wire vid_phy_tx_axi4s_ch2_tready
  .vid_phy_rx_axi4s_ch0_tdata(vid_phy_rx_axi4s_ch0_tdata),    // output wire [39 : 0] vid_phy_rx_axi4s_ch0_tdata
  .vid_phy_rx_axi4s_ch0_tuser(vid_phy_rx_axi4s_ch0_tuser),    // output wire [0 : 0] vid_phy_rx_axi4s_ch0_tuser
  .vid_phy_rx_axi4s_ch0_tvalid(vid_phy_rx_axi4s_ch0_tvalid),  // output wire vid_phy_rx_axi4s_ch0_tvalid
  .vid_phy_rx_axi4s_ch0_tready(vid_phy_rx_axi4s_ch0_tready),  // input wire vid_phy_rx_axi4s_ch0_tready
  .vid_phy_rx_axi4s_aclk(vid_phy_rx_axi4s_aclk),              // input wire vid_phy_rx_axi4s_aclk
  .vid_phy_rx_axi4s_aresetn(vid_phy_rx_axi4s_aresetn),        // input wire vid_phy_rx_axi4s_aresetn
  .vid_phy_rx_axi4s_ch1_tdata(vid_phy_rx_axi4s_ch1_tdata),    // output wire [39 : 0] vid_phy_rx_axi4s_ch1_tdata
  .vid_phy_rx_axi4s_ch1_tuser(vid_phy_rx_axi4s_ch1_tuser),    // output wire [0 : 0] vid_phy_rx_axi4s_ch1_tuser
  .vid_phy_rx_axi4s_ch1_tvalid(vid_phy_rx_axi4s_ch1_tvalid),  // output wire vid_phy_rx_axi4s_ch1_tvalid
  .vid_phy_rx_axi4s_ch1_tready(vid_phy_rx_axi4s_ch1_tready),  // input wire vid_phy_rx_axi4s_ch1_tready
  .vid_phy_rx_axi4s_ch2_tdata(vid_phy_rx_axi4s_ch2_tdata),    // output wire [39 : 0] vid_phy_rx_axi4s_ch2_tdata
  .vid_phy_rx_axi4s_ch2_tuser(vid_phy_rx_axi4s_ch2_tuser),    // output wire [0 : 0] vid_phy_rx_axi4s_ch2_tuser
  .vid_phy_rx_axi4s_ch2_tvalid(vid_phy_rx_axi4s_ch2_tvalid),  // output wire vid_phy_rx_axi4s_ch2_tvalid
  .vid_phy_rx_axi4s_ch2_tready(vid_phy_rx_axi4s_ch2_tready),  // input wire vid_phy_rx_axi4s_ch2_tready
  .irq(irq),                                                  // output wire irq
  .vid_phy_sb_aclk(vid_phy_sb_aclk),                          // input wire vid_phy_sb_aclk
  .vid_phy_sb_aresetn(vid_phy_sb_aresetn),                    // input wire vid_phy_sb_aresetn
  .vid_phy_status_sb_tx_tdata(vid_phy_status_sb_tx_tdata),    // output wire [7 : 0] vid_phy_status_sb_tx_tdata
  .vid_phy_status_sb_tx_tvalid(vid_phy_status_sb_tx_tvalid),  // output wire vid_phy_status_sb_tx_tvalid
  .vid_phy_status_sb_tx_tready(vid_phy_status_sb_tx_tready),  // input wire vid_phy_status_sb_tx_tready
  .vid_phy_status_sb_rx_tdata(vid_phy_status_sb_rx_tdata),    // output wire [7 : 0] vid_phy_status_sb_rx_tdata
  .vid_phy_status_sb_rx_tvalid(vid_phy_status_sb_rx_tvalid),  // output wire vid_phy_status_sb_rx_tvalid
  .vid_phy_status_sb_rx_tready(vid_phy_status_sb_rx_tready),  // input wire vid_phy_status_sb_rx_tready
  .vid_phy_axi4lite_awaddr(vid_phy_axi4lite_awaddr),          // input wire [9 : 0] vid_phy_axi4lite_awaddr
  .vid_phy_axi4lite_awprot(vid_phy_axi4lite_awprot),          // input wire [2 : 0] vid_phy_axi4lite_awprot
  .vid_phy_axi4lite_awvalid(vid_phy_axi4lite_awvalid),        // input wire vid_phy_axi4lite_awvalid
  .vid_phy_axi4lite_awready(vid_phy_axi4lite_awready),        // output wire vid_phy_axi4lite_awready
  .vid_phy_axi4lite_wdata(vid_phy_axi4lite_wdata),            // input wire [31 : 0] vid_phy_axi4lite_wdata
  .vid_phy_axi4lite_wstrb(vid_phy_axi4lite_wstrb),            // input wire [3 : 0] vid_phy_axi4lite_wstrb
  .vid_phy_axi4lite_wvalid(vid_phy_axi4lite_wvalid),          // input wire vid_phy_axi4lite_wvalid
  .vid_phy_axi4lite_wready(vid_phy_axi4lite_wready),          // output wire vid_phy_axi4lite_wready
  .vid_phy_axi4lite_bresp(vid_phy_axi4lite_bresp),            // output wire [1 : 0] vid_phy_axi4lite_bresp
  .vid_phy_axi4lite_bvalid(vid_phy_axi4lite_bvalid),          // output wire vid_phy_axi4lite_bvalid
  .vid_phy_axi4lite_bready(vid_phy_axi4lite_bready),          // input wire vid_phy_axi4lite_bready
  .vid_phy_axi4lite_araddr(vid_phy_axi4lite_araddr),          // input wire [9 : 0] vid_phy_axi4lite_araddr
  .vid_phy_axi4lite_arprot(vid_phy_axi4lite_arprot),          // input wire [2 : 0] vid_phy_axi4lite_arprot
  .vid_phy_axi4lite_arvalid(vid_phy_axi4lite_arvalid),        // input wire vid_phy_axi4lite_arvalid
  .vid_phy_axi4lite_arready(vid_phy_axi4lite_arready),        // output wire vid_phy_axi4lite_arready
  .vid_phy_axi4lite_rdata(vid_phy_axi4lite_rdata),            // output wire [31 : 0] vid_phy_axi4lite_rdata
  .vid_phy_axi4lite_rresp(vid_phy_axi4lite_rresp),            // output wire [1 : 0] vid_phy_axi4lite_rresp
  .vid_phy_axi4lite_rvalid(vid_phy_axi4lite_rvalid),          // output wire vid_phy_axi4lite_rvalid
  .vid_phy_axi4lite_rready(vid_phy_axi4lite_rready),          // input wire vid_phy_axi4lite_rready
  .vid_phy_axi4lite_aclk(vid_phy_axi4lite_aclk),              // input wire vid_phy_axi4lite_aclk
  .vid_phy_axi4lite_aresetn(vid_phy_axi4lite_aresetn),        // input wire vid_phy_axi4lite_aresetn
  .drpclk(drpclk)                                            // input wire drpclk
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file vid_phy_controller_0.v when simulating
// the core, vid_phy_controller_0. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

