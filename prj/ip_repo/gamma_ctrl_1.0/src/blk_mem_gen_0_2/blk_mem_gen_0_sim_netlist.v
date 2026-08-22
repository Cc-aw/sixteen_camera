// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Fri Dec 22 10:21:40 2023
// Host        : DESKTOP-MGCMP7L running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/Users/Admin/Desktop/mpsoc/code/PL_5EV/ov5645_mipi_hdmi/prj/ip_repo/gamma_ctrl_1.0/src/blk_mem_gen_0_2/blk_mem_gen_0_sim_netlist.v
// Design      : blk_mem_gen_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu5ev-sfvc784-2-i
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "blk_mem_gen_0,blk_mem_gen_v8_4_4,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.2" *) 
(* NotValidForBitStream *)
module blk_mem_gen_0
   (clka,
    addra,
    douta);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [8:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [31:0]douta;

  wire [8:0]addra;
  wire clka;
  wire [31:0]douta;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_rsta_busy_UNCONNECTED;
  wire NLW_U0_rstb_busy_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [31:0]NLW_U0_doutb_UNCONNECTED;
  wire [8:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [8:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "9" *) 
  (* C_ADDRB_WIDTH = "9" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "9" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "1" *) 
  (* C_COUNT_36K_BRAM = "0" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "0" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "0" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     3.163063 mW" *) 
  (* C_FAMILY = "zynquplus" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "0" *) 
  (* C_HAS_ENB = "0" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "0" *) 
  (* C_HAS_RSTB = "0" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "blk_mem_gen_0.mem" *) 
  (* C_INIT_FILE_NAME = "blk_mem_gen_0.mif" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "1" *) 
  (* C_MEM_TYPE = "3" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "512" *) 
  (* C_READ_DEPTH_B = "512" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "32" *) 
  (* C_READ_WIDTH_B = "32" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "0" *) 
  (* C_USE_BYTE_WEA = "0" *) 
  (* C_USE_BYTE_WEB = "0" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "1" *) 
  (* C_WEB_WIDTH = "1" *) 
  (* C_WRITE_DEPTH_A = "512" *) 
  (* C_WRITE_DEPTH_B = "512" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "32" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "zynquplus" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  blk_mem_gen_0_blk_mem_gen_v8_4_4 U0
       (.addra(addra),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .clka(clka),
        .clkb(1'b0),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .dinb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .douta(douta),
        .doutb(NLW_U0_doutb_UNCONNECTED[31:0]),
        .eccpipece(1'b0),
        .ena(1'b0),
        .enb(1'b0),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[8:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(1'b0),
        .rsta_busy(NLW_U0_rsta_busy_UNCONNECTED),
        .rstb(1'b0),
        .rstb_busy(NLW_U0_rstb_busy_UNCONNECTED),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[8:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb(1'b0),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(1'b0),
        .web(1'b0));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2020.2"
`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="cds_rsa_key", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=64)
`pragma protect key_block
QGLtnqZzRetDH6gCWT4Js6wuLlZfrNx/VJp3sfR2NF+cxypO5AxN0oDKLJJtmdrtE/ueNDg+Qf7Z
TqBNRojORA==

`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
B6Ger3hRvfjHkaJ+W8639Kl3TzC9TogLuklOXEiMNdc4Im+DjEUzxb3DKlzu0VW3zxZqjJ3+wsW/
LnRmPCESi5Y9eRJaLFXg79EMfoj4X+nTdHAP6yCfltBADKegZ12gpnB/8ey5yn2KA74LUtPC7jna
iyjqSfsWLGnz6UdXzwk=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BX+DxgMPRyZbYojCUR9Sk8Lq+3ZigBz4yMFHQkmurfdfDzyTPJCE827eGiPyTenK1QPVhEtf9g06
0BFXq/0COPuU1BWJwdkz1c4dE6/exDwhvEh+hPx3vRY6z8fDEf6aGVIXrHDvrmddehe7yMSIpo+k
aXHR06EEdfHCFY4TggYwhcJVXjkE+ApsVuyfmEfPmYjo8hCWyQyBsUWIOY03q1+MvUjjsmTwgs9g
fh5MY9ToaLfoJxPKdCpsqrBX4LJ+VDGFlAqIcqHTE2jCmPiToZAFXB7fzf1wDjFCBlJyFVDBGi0i
m+CouLSb7X1mvVhdDZgNrZDJMV688Bu3o54vew==

`pragma protect key_keyowner="ATRENTA", key_keyname="ATR-SG-2015-RSA-3", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
DaIU/Ddc8USbZ2mURzujJDWDH1JbHl5tFVOOQ2aVaUPIA71yyE38OXVLEtF8rNmujYH30nEeQ+FV
LVJ16aaHw+iiuaqorTM3K5KLohVlN+WlcEtSXHuPNHjw8ddqtzpaX7pH1zqZH+YmfCL5oaNLqDH4
rkBnUl0/Gm/hzSwKjYhXGQFYQ+gGP99OjXakzrAqZzp/Iq4gt+Z5902/JV9thd/isHQImJ0QyK8M
EKM579iPAfXGes2mbiNYHcvDmSPYmW1zlhOE++N1EKeea7j/msnKeyhlC+hGE4Xfn4TVvqgQexCT
rp/wS/MosY6WH1aKFQlFH2hEppA7KXUaQlvG+w==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
XmWoAt4X8hrCJ5yTyug4ajJW5UhfkLNibzjihWzZ4Cr9hQSvWZoTc8rjGsLPbz6Le+/9iI5KxecS
eR0wiAO+G2IkwhZgVBeZdKoFnlnTVAyLjk9wMAFXNyJZM6b1NDbfXlPcUsC6JePvPlwwdWknkSsC
r3KvgkWAS+O3xvRmaNw=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
Hw3Y+rShKrXiUViyNU1/O2qv6TgheLHBnFMj1i9MUGrHYqh9pLfLYUgWR7S2vj4jv4S+Ks0BpP4p
dKEqVAFmTCfQNEUHaVcFPkOHgig6L4mhLY6HUUKJoRgiQepgLi/W3V+ZZPQSQFkB3CU4MsJzhXvR
yLcpDriZy8cnAHD87Zi5DrNGBzj3kigJeM0du6lCQbxtF5aEdoaNP+YTnIFtcqYhoYnswQlYt0sV
HKgFA8VzqzL5WYnpH7+1IKmFkJBHkyqHCa9wPK0qCKnxkuDj70YzPVqQ+cocdKU+/gNdpCOdZlci
F2HTxrgfrXndJru3TiDqu4UavqAe0MNuFp3t0w==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
XPVggoWL6aXz+MpODTOZhEUQDa0vfEnUDaYeEHXm2vGyqKJujN2c/FFAFBeBYdJATLsIsQ+BqoPc
pBbcFYXDBfOtFIW2dH6Y1OoD65KyJ/hAq8coa21kFgq4hFat5vzZ2iIfkCpTUr4vDZO7Xne8cZO9
WsHffoTCt5rS59wWm2b8I5R8Eh2TUbQg3RCyrcnD66cvcEnlXe1CNMQ4/loVJpA4IBinBf820Wjc
vw2fZbGI0jXC+ACSHOviH63Xwmn+aRV5Ppkup7IYoon/ieKapRQeASu3TTY37xSBXiInSdtMTzJ6
+4GfO4eSHVriCk/sWbuTBzfRzoSShrnHjzz5LA==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2020_08", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
L78XuiswVcgO2gtebzL7SA9BC/jJGAM0v6S9pzmyqL+QYzRneiYeGyDmsW33jEVVSTuNjTXkBLY7
yTOKQruatwe4V0OLi6174saSAmPgerSV1GyLP7KhmusLV/N61avC9TPam+tekhKeE0tds4EnJ3et
4JdLh+SE4Z4pcuqCjB5MFneIYKKWDx7siU6oesAQtoSJOesfMchX63MhOjOHFP/ch+1gHv3T45hg
IGF7V7TrdREVE4f9631tlVJ1o2Dypsmo/76Itz5WCGlTMjAnWXN8IXxKN+PZ3dyt1wjrZm2P/td+
xiGszFnSLrRvw/HferwtSmRx8q0fiHZ88roGTw==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
kDX5kq2QEe25429T6vQqBCFvV1McKTJRYfK99ymVNK2GGvGLXSzgwJHwB2fj9rM0wme3zYYY0vQR
x+9F4L7KLlOVY6qY3LB59uDzyXBI3mMZaS905HXHJkdZHWtQWpfHhl27LqL+8FSluaD6F+KFfYOV
CwIOVuCIp/XjxFXpNBik7YiPt4kHOlDA97IXNLnYUn/g1csGqeNWce4UTne50ggWvLYGbTFGmTjT
N67TpUiGRVRCSv8Tax72GWFIMFZk3Tlp68ZUSQEybZMWX1U9XdMdtxfvNGhf8mi5jQJ2SupSzKu4
T/+53IN9T8aLePAiGBKKG1ZBj4y1ZyYA7XYvjw==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 20528)
`pragma protect data_block
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
DMxsVfMuFxs=
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
