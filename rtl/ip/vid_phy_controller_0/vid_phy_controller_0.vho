-- (c) Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- (c) Copyright 2022-2026 Advanced Micro Devices, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of AMD and is protected under U.S. and international copyright
-- and other intellectual property laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- AMD, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND AMD HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) AMD shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or AMD had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- AMD products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of AMD products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.
-- IP VLNV: xilinx.com:ip:vid_phy_controller:2.2
-- IP Revision: 17

-- The following code must appear in the VHDL architecture header.

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
COMPONENT vid_phy_controller_0
  PORT (
    tx_refclk_rdy : IN STD_LOGIC;
    tx_tmds_clk : OUT STD_LOGIC;
    tx_video_clk : OUT STD_LOGIC;
    rx_tmds_clk : OUT STD_LOGIC;
    rx_video_clk : OUT STD_LOGIC;
    rx_tmds_clk_p : OUT STD_LOGIC;
    rx_tmds_clk_n : OUT STD_LOGIC;
    mgtrefclk0_pad_p_in : IN STD_LOGIC;
    mgtrefclk0_pad_n_in : IN STD_LOGIC;
    gtsouthrefclk0_in : IN STD_LOGIC;
    gtsouthrefclk0_odiv2_in : IN STD_LOGIC;
    gtsouthrefclk00_in : IN STD_LOGIC;
    gtsouthrefclk01_in : IN STD_LOGIC;
    txrefclk_ceb : OUT STD_LOGIC;
    phy_rxn_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    phy_rxp_in : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    phy_txn_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    phy_txp_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    rxoutclk : OUT STD_LOGIC;
    txoutclk : OUT STD_LOGIC;
    vid_phy_tx_axi4s_aclk : IN STD_LOGIC;
    vid_phy_tx_axi4s_aresetn : IN STD_LOGIC;
    vid_phy_tx_axi4s_ch0_tdata : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    vid_phy_tx_axi4s_ch0_tuser : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    vid_phy_tx_axi4s_ch0_tvalid : IN STD_LOGIC;
    vid_phy_tx_axi4s_ch0_tready : OUT STD_LOGIC;
    vid_phy_tx_axi4s_ch1_tdata : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    vid_phy_tx_axi4s_ch1_tuser : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    vid_phy_tx_axi4s_ch1_tvalid : IN STD_LOGIC;
    vid_phy_tx_axi4s_ch1_tready : OUT STD_LOGIC;
    vid_phy_tx_axi4s_ch2_tdata : IN STD_LOGIC_VECTOR(39 DOWNTO 0);
    vid_phy_tx_axi4s_ch2_tuser : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    vid_phy_tx_axi4s_ch2_tvalid : IN STD_LOGIC;
    vid_phy_tx_axi4s_ch2_tready : OUT STD_LOGIC;
    vid_phy_rx_axi4s_ch0_tdata : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
    vid_phy_rx_axi4s_ch0_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    vid_phy_rx_axi4s_ch0_tvalid : OUT STD_LOGIC;
    vid_phy_rx_axi4s_ch0_tready : IN STD_LOGIC;
    vid_phy_rx_axi4s_aclk : IN STD_LOGIC;
    vid_phy_rx_axi4s_aresetn : IN STD_LOGIC;
    vid_phy_rx_axi4s_ch1_tdata : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
    vid_phy_rx_axi4s_ch1_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    vid_phy_rx_axi4s_ch1_tvalid : OUT STD_LOGIC;
    vid_phy_rx_axi4s_ch1_tready : IN STD_LOGIC;
    vid_phy_rx_axi4s_ch2_tdata : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
    vid_phy_rx_axi4s_ch2_tuser : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    vid_phy_rx_axi4s_ch2_tvalid : OUT STD_LOGIC;
    vid_phy_rx_axi4s_ch2_tready : IN STD_LOGIC;
    irq : OUT STD_LOGIC;
    vid_phy_sb_aclk : IN STD_LOGIC;
    vid_phy_sb_aresetn : IN STD_LOGIC;
    vid_phy_status_sb_tx_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    vid_phy_status_sb_tx_tvalid : OUT STD_LOGIC;
    vid_phy_status_sb_tx_tready : IN STD_LOGIC;
    vid_phy_status_sb_rx_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    vid_phy_status_sb_rx_tvalid : OUT STD_LOGIC;
    vid_phy_status_sb_rx_tready : IN STD_LOGIC;
    vid_phy_axi4lite_awaddr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    vid_phy_axi4lite_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    vid_phy_axi4lite_awvalid : IN STD_LOGIC;
    vid_phy_axi4lite_awready : OUT STD_LOGIC;
    vid_phy_axi4lite_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    vid_phy_axi4lite_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    vid_phy_axi4lite_wvalid : IN STD_LOGIC;
    vid_phy_axi4lite_wready : OUT STD_LOGIC;
    vid_phy_axi4lite_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    vid_phy_axi4lite_bvalid : OUT STD_LOGIC;
    vid_phy_axi4lite_bready : IN STD_LOGIC;
    vid_phy_axi4lite_araddr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    vid_phy_axi4lite_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    vid_phy_axi4lite_arvalid : IN STD_LOGIC;
    vid_phy_axi4lite_arready : OUT STD_LOGIC;
    vid_phy_axi4lite_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    vid_phy_axi4lite_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    vid_phy_axi4lite_rvalid : OUT STD_LOGIC;
    vid_phy_axi4lite_rready : IN STD_LOGIC;
    vid_phy_axi4lite_aclk : IN STD_LOGIC;
    vid_phy_axi4lite_aresetn : IN STD_LOGIC;
    drpclk : IN STD_LOGIC 
  );
END COMPONENT;
-- COMP_TAG_END ------ End COMPONENT Declaration ------------

-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.

------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG
your_instance_name : vid_phy_controller_0
  PORT MAP (
    tx_refclk_rdy => tx_refclk_rdy,
    tx_tmds_clk => tx_tmds_clk,
    tx_video_clk => tx_video_clk,
    rx_tmds_clk => rx_tmds_clk,
    rx_video_clk => rx_video_clk,
    rx_tmds_clk_p => rx_tmds_clk_p,
    rx_tmds_clk_n => rx_tmds_clk_n,
    mgtrefclk0_pad_p_in => mgtrefclk0_pad_p_in,
    mgtrefclk0_pad_n_in => mgtrefclk0_pad_n_in,
    gtsouthrefclk0_in => gtsouthrefclk0_in,
    gtsouthrefclk0_odiv2_in => gtsouthrefclk0_odiv2_in,
    gtsouthrefclk00_in => gtsouthrefclk00_in,
    gtsouthrefclk01_in => gtsouthrefclk01_in,
    txrefclk_ceb => txrefclk_ceb,
    phy_rxn_in => phy_rxn_in,
    phy_rxp_in => phy_rxp_in,
    phy_txn_out => phy_txn_out,
    phy_txp_out => phy_txp_out,
    rxoutclk => rxoutclk,
    txoutclk => txoutclk,
    vid_phy_tx_axi4s_aclk => vid_phy_tx_axi4s_aclk,
    vid_phy_tx_axi4s_aresetn => vid_phy_tx_axi4s_aresetn,
    vid_phy_tx_axi4s_ch0_tdata => vid_phy_tx_axi4s_ch0_tdata,
    vid_phy_tx_axi4s_ch0_tuser => vid_phy_tx_axi4s_ch0_tuser,
    vid_phy_tx_axi4s_ch0_tvalid => vid_phy_tx_axi4s_ch0_tvalid,
    vid_phy_tx_axi4s_ch0_tready => vid_phy_tx_axi4s_ch0_tready,
    vid_phy_tx_axi4s_ch1_tdata => vid_phy_tx_axi4s_ch1_tdata,
    vid_phy_tx_axi4s_ch1_tuser => vid_phy_tx_axi4s_ch1_tuser,
    vid_phy_tx_axi4s_ch1_tvalid => vid_phy_tx_axi4s_ch1_tvalid,
    vid_phy_tx_axi4s_ch1_tready => vid_phy_tx_axi4s_ch1_tready,
    vid_phy_tx_axi4s_ch2_tdata => vid_phy_tx_axi4s_ch2_tdata,
    vid_phy_tx_axi4s_ch2_tuser => vid_phy_tx_axi4s_ch2_tuser,
    vid_phy_tx_axi4s_ch2_tvalid => vid_phy_tx_axi4s_ch2_tvalid,
    vid_phy_tx_axi4s_ch2_tready => vid_phy_tx_axi4s_ch2_tready,
    vid_phy_rx_axi4s_ch0_tdata => vid_phy_rx_axi4s_ch0_tdata,
    vid_phy_rx_axi4s_ch0_tuser => vid_phy_rx_axi4s_ch0_tuser,
    vid_phy_rx_axi4s_ch0_tvalid => vid_phy_rx_axi4s_ch0_tvalid,
    vid_phy_rx_axi4s_ch0_tready => vid_phy_rx_axi4s_ch0_tready,
    vid_phy_rx_axi4s_aclk => vid_phy_rx_axi4s_aclk,
    vid_phy_rx_axi4s_aresetn => vid_phy_rx_axi4s_aresetn,
    vid_phy_rx_axi4s_ch1_tdata => vid_phy_rx_axi4s_ch1_tdata,
    vid_phy_rx_axi4s_ch1_tuser => vid_phy_rx_axi4s_ch1_tuser,
    vid_phy_rx_axi4s_ch1_tvalid => vid_phy_rx_axi4s_ch1_tvalid,
    vid_phy_rx_axi4s_ch1_tready => vid_phy_rx_axi4s_ch1_tready,
    vid_phy_rx_axi4s_ch2_tdata => vid_phy_rx_axi4s_ch2_tdata,
    vid_phy_rx_axi4s_ch2_tuser => vid_phy_rx_axi4s_ch2_tuser,
    vid_phy_rx_axi4s_ch2_tvalid => vid_phy_rx_axi4s_ch2_tvalid,
    vid_phy_rx_axi4s_ch2_tready => vid_phy_rx_axi4s_ch2_tready,
    irq => irq,
    vid_phy_sb_aclk => vid_phy_sb_aclk,
    vid_phy_sb_aresetn => vid_phy_sb_aresetn,
    vid_phy_status_sb_tx_tdata => vid_phy_status_sb_tx_tdata,
    vid_phy_status_sb_tx_tvalid => vid_phy_status_sb_tx_tvalid,
    vid_phy_status_sb_tx_tready => vid_phy_status_sb_tx_tready,
    vid_phy_status_sb_rx_tdata => vid_phy_status_sb_rx_tdata,
    vid_phy_status_sb_rx_tvalid => vid_phy_status_sb_rx_tvalid,
    vid_phy_status_sb_rx_tready => vid_phy_status_sb_rx_tready,
    vid_phy_axi4lite_awaddr => vid_phy_axi4lite_awaddr,
    vid_phy_axi4lite_awprot => vid_phy_axi4lite_awprot,
    vid_phy_axi4lite_awvalid => vid_phy_axi4lite_awvalid,
    vid_phy_axi4lite_awready => vid_phy_axi4lite_awready,
    vid_phy_axi4lite_wdata => vid_phy_axi4lite_wdata,
    vid_phy_axi4lite_wstrb => vid_phy_axi4lite_wstrb,
    vid_phy_axi4lite_wvalid => vid_phy_axi4lite_wvalid,
    vid_phy_axi4lite_wready => vid_phy_axi4lite_wready,
    vid_phy_axi4lite_bresp => vid_phy_axi4lite_bresp,
    vid_phy_axi4lite_bvalid => vid_phy_axi4lite_bvalid,
    vid_phy_axi4lite_bready => vid_phy_axi4lite_bready,
    vid_phy_axi4lite_araddr => vid_phy_axi4lite_araddr,
    vid_phy_axi4lite_arprot => vid_phy_axi4lite_arprot,
    vid_phy_axi4lite_arvalid => vid_phy_axi4lite_arvalid,
    vid_phy_axi4lite_arready => vid_phy_axi4lite_arready,
    vid_phy_axi4lite_rdata => vid_phy_axi4lite_rdata,
    vid_phy_axi4lite_rresp => vid_phy_axi4lite_rresp,
    vid_phy_axi4lite_rvalid => vid_phy_axi4lite_rvalid,
    vid_phy_axi4lite_rready => vid_phy_axi4lite_rready,
    vid_phy_axi4lite_aclk => vid_phy_axi4lite_aclk,
    vid_phy_axi4lite_aresetn => vid_phy_axi4lite_aresetn,
    drpclk => drpclk
  );
-- INST_TAG_END ------ End INSTANTIATION Template ---------

-- You must compile the wrapper file vid_phy_controller_0.vhd when simulating
-- the core, vid_phy_controller_0. When compiling the wrapper file, be sure to
-- reference the VHDL simulation library.



