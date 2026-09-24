// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (lin64) Build 4029153 Fri Oct 13 20:13:54 MDT 2023
// Date        : Thu Aug 13 18:44:41 2026
// Host        : tsmc184 running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /mnt/data/wzr/13p/ov5645/one_ov5645/demo/4k30to1k60/rtl/ip/v_hdmi_rx_ss_0/bd_0/ip/ip_1/bd_2422_v_vid_in_axi4s_0_stub.v
// Design      : bd_2422_v_vid_in_axi4s_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu13p-fhga2104-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "v_vid_in_axi4s_v5_0_3,Vivado 2023.2" *)
module bd_2422_v_vid_in_axi4s_0(vid_io_in_clk, vid_io_in_ce, vid_io_in_reset, 
  vid_active_video, vid_vblank, vid_hblank, vid_vsync, vid_hsync, vid_field_id, vid_data, aclk, 
  aclken, aresetn, m_axis_video_tdata, m_axis_video_tvalid, m_axis_video_tready, 
  m_axis_video_tuser, m_axis_video_tlast, fid, vtd_active_video, vtd_vblank, vtd_hblank, 
  vtd_vsync, vtd_hsync, vtd_field_id, overflow, underflow, axis_enable, remap_420_en)
/* synthesis syn_black_box black_box_pad_pin="vid_io_in_ce,vid_io_in_reset,vid_active_video,vid_vblank,vid_hblank,vid_vsync,vid_hsync,vid_field_id,vid_data[47:0],aclken,aresetn,m_axis_video_tdata[47:0],m_axis_video_tvalid,m_axis_video_tready,m_axis_video_tuser,m_axis_video_tlast,fid,vtd_active_video,vtd_vblank,vtd_hblank,vtd_vsync,vtd_hsync,vtd_field_id,overflow,underflow,axis_enable,remap_420_en" */
/* synthesis syn_force_seq_prim="vid_io_in_clk" */
/* synthesis syn_force_seq_prim="aclk" */;
  input vid_io_in_clk /* synthesis syn_isclock = 1 */;
  input vid_io_in_ce;
  input vid_io_in_reset;
  input vid_active_video;
  input vid_vblank;
  input vid_hblank;
  input vid_vsync;
  input vid_hsync;
  input vid_field_id;
  input [47:0]vid_data;
  input aclk /* synthesis syn_isclock = 1 */;
  input aclken;
  input aresetn;
  output [47:0]m_axis_video_tdata;
  output m_axis_video_tvalid;
  input m_axis_video_tready;
  output m_axis_video_tuser;
  output m_axis_video_tlast;
  output fid;
  output vtd_active_video;
  output vtd_vblank;
  output vtd_hblank;
  output vtd_vsync;
  output vtd_hsync;
  output vtd_field_id;
  output overflow;
  output underflow;
  input axis_enable;
  input remap_420_en;
endmodule
