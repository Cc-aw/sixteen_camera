// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Mon Dec 18 15:35:37 2023
// Host        : DESKTOP-MGCMP7L running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/Users/Admin/Desktop/ov5645_hdmi/ip_repo/gamma_ctrl_1.0/src/blk_mem_gen_0_1/blk_mem_gen_0_sim_netlist.v
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
ymiT17JenUI=
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
