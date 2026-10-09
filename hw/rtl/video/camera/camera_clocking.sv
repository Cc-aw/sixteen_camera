`timescale 1ns/1ps

// One shared 24 MHz control clock feeds all eight independent OV7670 SCCB
// controllers. Each controller divides it locally to the reference 12 MHz
// sensor XCLK used by the verified ztachip implementation.
module camera_clocking (
    input  wire sys_rstn,
    input  wire clk_ref,
    output wire pll_locked,
    output wire ov7670_ctrl_clk
);
    clk_wiz_ov7670 u_ov7670_clk_wiz (
        .clk_out1(ov7670_ctrl_clk), .reset(~sys_rstn),
        .locked(pll_locked), .clk_in1(clk_ref)
    );
endmodule
