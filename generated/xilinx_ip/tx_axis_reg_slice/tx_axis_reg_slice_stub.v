// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2023.2 (lin64) Build 4029153 Fri Oct 13 20:13:54 MDT 2023
// Date        : Thu Aug 13 16:06:48 2026
// Host        : tsmc184 running 64-bit Ubuntu 22.04.5 LTS
// Command     : write_verilog -force -mode synth_stub
//               /mnt/data/wzr/13p/ov5645/one_ov5645/demo/4k30to1k60/rtl/ip/tx_axis_reg_slice/tx_axis_reg_slice_stub.v
// Design      : tx_axis_reg_slice
// Purpose     : Stub declaration of top-level module interface
// Device      : xcvu13p-fhga2104-2-i
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "axis_register_slice_v1_1_29_axis_register_slice,Vivado 2023.2" *)
module tx_axis_reg_slice(aclk, aresetn, s_axis_tvalid, s_axis_tready, 
  s_axis_tdata, s_axis_tlast, s_axis_tuser, m_axis_tvalid, m_axis_tready, m_axis_tdata, 
  m_axis_tlast, m_axis_tuser)
/* synthesis syn_black_box black_box_pad_pin="aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[47:0],s_axis_tlast,s_axis_tuser[0:0],m_axis_tvalid,m_axis_tready,m_axis_tdata[47:0],m_axis_tlast,m_axis_tuser[0:0]" */
/* synthesis syn_force_seq_prim="aclk" */;
  input aclk /* synthesis syn_isclock = 1 */;
  input aresetn;
  input s_axis_tvalid;
  output s_axis_tready;
  input [47:0]s_axis_tdata;
  input s_axis_tlast;
  input [0:0]s_axis_tuser;
  output m_axis_tvalid;
  input m_axis_tready;
  output [47:0]m_axis_tdata;
  output m_axis_tlast;
  output [0:0]m_axis_tuser;
endmodule
