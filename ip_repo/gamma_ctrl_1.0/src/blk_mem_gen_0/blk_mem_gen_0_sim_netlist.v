// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
// Date        : Fri Dec 15 11:23:24 2023
// Host        : DESKTOP-MGCMP7L running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim
//               c:/Users/Admin/Desktop/ov5645_hdmi/ip_repo/gamma_ctrl_1.0/src/blk_mem_gen_0/blk_mem_gen_0_sim_netlist.v
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
wvrY1J2JWxc=
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
