# ============================================================================
# VU13P / BCVU13 - 8x OV7670 - J2 CAM2-Min-Change + CAM3-Legacy v3
# ============================================================================
# FMC1 -> global CAM0..CAM3
# FMC2 -> global CAM4..CAM7
#
# Physical wiring basis:
#   J1 local CAM0/CAM1, J2 local CAM2/CAM3
#   PCLK only on P-side clock-capable LA17/18/01/00.
#   J1 local CAM0/CAM1 remains identical to anti-interference v2.
#   J2 is redesigned: Local CAM2 changes only RESET (LA01_N -> LA02_N);
#   Local CAM3 is restored to the earlier proven-success wiring.
#   This intentionally prioritizes proven CAM3 behavior and simple Dupont routing.
#
# EXTIO SCCB mode: BOOT_01=OFF, BOOT_02=OFF (TXS mode).
# FPGA-side VADJ is 1.8 V, therefore all camera ports use LVCMOS18.
#
# IMPORTANT:
#   - Adapted to the current top_wrapper flattened array ports:
#       cam_data[63:0], cam_pclk[7:0], cam_vsync[7:0], cam_href[7:0],
#       cam_xclk[7:0], cam_scl[7:0], cam_sda[7:0], cam_rst_n[7:0],
#       cam_pwdn[7:0]
#   - No CLOCK_DEDICATED_ROUTE FALSE is used.
#   - Each 24 MHz PCLK uses a CC input and an explicit IBUF + BUFGCE.
#   - D[7:0], HREF and VSYNC are captured by IOB flops on the rising PCLK edge.
#   - Do not combine this XDC with the old camera pin XDC.
# ============================================================================

# ============================================================================
# FMC1
# ============================================================================

# ---------------------------------------------------------------------------
# CAM0 (FMC1 / Local CAM0 / J1)
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN F9   [get_ports {cam_data[0]}] ; # LA25_N
set_property PACKAGE_PIN F10  [get_ports {cam_data[1]}] ; # LA25_P
set_property PACKAGE_PIN C7   [get_ports {cam_data[2]}] ; # LA26_N
set_property PACKAGE_PIN D7   [get_ports {cam_data[3]}] ; # LA26_P
set_property PACKAGE_PIN C8   [get_ports {cam_data[4]}] ; # LA21_N
set_property PACKAGE_PIN C9   [get_ports {cam_data[5]}] ; # LA21_P
set_property PACKAGE_PIN E11  [get_ports {cam_data[6]}] ; # LA22_N
set_property PACKAGE_PIN F11  [get_ports {cam_data[7]}] ; # LA22_P
set_property PACKAGE_PIN E12  [get_ports {cam_pclk[0]}] ; # LA17_P  P-side CC
set_property PACKAGE_PIN H15  [get_ports {cam_vsync[0]}] ; # LA20_P  mate intentionally unused
set_property PACKAGE_PIN F14  [get_ports {cam_href[0]}] ; # LA31_P
set_property PACKAGE_PIN B8   [get_ports {cam_xclk[0]}] ; # LA19_P
set_property PACKAGE_PIN E14  [get_ports {cam_scl[0]}] ; # LA31_N
set_property PACKAGE_PIN B12  [get_ports {cam_sda[0]}] ; # LA33_N
set_property PACKAGE_PIN D12  [get_ports {cam_rst_n[0]}] ; # LA17_N
set_property PACKAGE_PIN C12  [get_ports {cam_pwdn[0]}] ; # LA33_P

# ---------------------------------------------------------------------------
# CAM1 (FMC1 / Local CAM1 / J1)
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN G13  [get_ports {cam_data[8]}] ; # LA32_N
set_property PACKAGE_PIN H13  [get_ports {cam_data[9]}] ; # LA32_P
set_property PACKAGE_PIN F15  [get_ports {cam_data[10]}] ; # LA30_N
set_property PACKAGE_PIN G15  [get_ports {cam_data[11]}] ; # LA30_P
set_property PACKAGE_PIN G12  [get_ports {cam_data[12]}] ; # LA28_N
set_property PACKAGE_PIN H12  [get_ports {cam_data[13]}] ; # LA28_P
set_property PACKAGE_PIN G10  [get_ports {cam_data[14]}] ; # LA24_N
set_property PACKAGE_PIN G11  [get_ports {cam_data[15]}] ; # LA24_P
set_property PACKAGE_PIN F13  [get_ports {cam_pclk[1]}] ; # LA18_P  P-side CC
set_property PACKAGE_PIN D11  [get_ports {cam_vsync[1]}] ; # LA29_P  mate intentionally unused
set_property PACKAGE_PIN E9   [get_ports {cam_href[1]}] ; # LA27_P
set_property PACKAGE_PIN B7   [get_ports {cam_xclk[1]}] ; # LA19_N
set_property PACKAGE_PIN E13  [get_ports {cam_scl[1]}] ; # LA18_N
set_property PACKAGE_PIN B13  [get_ports {cam_sda[1]}] ; # LA23_N
set_property PACKAGE_PIN D9   [get_ports {cam_rst_n[1]}] ; # LA27_N
set_property PACKAGE_PIN C13  [get_ports {cam_pwdn[1]}] ; # LA23_P

# ---------------------------------------------------------------------------
# CAM2 (FMC1 / Local CAM2 / J2) - CAM2 minimally changed
# Only RESET moved: LA01_N -> LA02_N, to free LA01_N for legacy CAM3 RESET.
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN V12  [get_ports {cam_data[16]}] ; # LA09_N
set_property PACKAGE_PIN W12  [get_ports {cam_data[17]}] ; # LA09_P
set_property PACKAGE_PIN U12  [get_ports {cam_data[18]}] ; # LA12_N
set_property PACKAGE_PIN V13  [get_ports {cam_data[19]}] ; # LA12_P
set_property PACKAGE_PIN P12  [get_ports {cam_data[20]}] ; # LA13_N
set_property PACKAGE_PIN R12  [get_ports {cam_data[21]}] ; # LA13_P
set_property PACKAGE_PIN P11  [get_ports {cam_data[22]}] ; # LA14_N
set_property PACKAGE_PIN R11  [get_ports {cam_data[23]}] ; # LA14_P
set_property PACKAGE_PIN R14  [get_ports {cam_pclk[2]}] ; # LA01_P  P-side CC
set_property PACKAGE_PIN W14  [get_ports {cam_vsync[2]}] ; # LA05_P
set_property PACKAGE_PIN L14  [get_ports {cam_href[2]}] ; # LA10_P
set_property PACKAGE_PIN AA12 [get_ports {cam_xclk[2]}] ; # LA16_P
set_property PACKAGE_PIN L13  [get_ports {cam_scl[2]}] ; # LA10_N
set_property PACKAGE_PIN M12  [get_ports {cam_sda[2]}] ; # LA08_N
set_property PACKAGE_PIN U16  [get_ports {cam_rst_n[2]}] ; # LA02_N  MOVED from LA01_N
set_property PACKAGE_PIN M13  [get_ports {cam_pwdn[2]}] ; # LA08_P
# ---------------------------------------------------------------------------
# CAM3 (FMC1 / Local CAM3 / J2) - legacy proven-success wiring restored
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN T16  [get_ports {cam_data[24]}] ; # LA04_P
set_property PACKAGE_PIN T15  [get_ports {cam_data[25]}] ; # LA04_N
set_property PACKAGE_PIN AA14 [get_ports {cam_data[26]}] ; # LA15_P
set_property PACKAGE_PIN Y14  [get_ports {cam_data[27]}] ; # LA15_N
set_property PACKAGE_PIN M15  [get_ports {cam_data[28]}] ; # LA03_P
set_property PACKAGE_PIN L15  [get_ports {cam_data[29]}] ; # LA03_N
set_property PACKAGE_PIN P15  [get_ports {cam_data[30]}] ; # LA06_P
set_property PACKAGE_PIN N15  [get_ports {cam_data[31]}] ; # LA06_N
set_property PACKAGE_PIN N14  [get_ports {cam_pclk[3]}] ; # LA00_P  P-side CC
set_property PACKAGE_PIN V15  [get_ports {cam_vsync[3]}] ; # LA07_P
set_property PACKAGE_PIN AA13 [get_ports {cam_href[3]}] ; # LA11_P
set_property PACKAGE_PIN N13  [get_ports {cam_xclk[3]}] ; # LA00_N  legacy proven wiring
set_property PACKAGE_PIN Y13  [get_ports {cam_scl[3]}] ; # LA11_N
set_property PACKAGE_PIN U15  [get_ports {cam_sda[3]}] ; # LA07_N
set_property PACKAGE_PIN P14  [get_ports {cam_rst_n[3]}] ; # LA01_N  legacy proven wiring
set_property PACKAGE_PIN V16  [get_ports {cam_pwdn[3]}] ; # LA02_P
# ============================================================================
# FMC2
# ============================================================================

# ---------------------------------------------------------------------------
# CAM4 (FMC2 / Local CAM0 / J1)
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN F39  [get_ports {cam_data[32]}] ; # LA25_N
set_property PACKAGE_PIN F38  [get_ports {cam_data[33]}] ; # LA25_P
set_property PACKAGE_PIN A38  [get_ports {cam_data[34]}] ; # LA26_N
set_property PACKAGE_PIN B38  [get_ports {cam_data[35]}] ; # LA26_P
set_property PACKAGE_PIN J40  [get_ports {cam_data[36]}] ; # LA21_N
set_property PACKAGE_PIN J39  [get_ports {cam_data[37]}] ; # LA21_P
set_property PACKAGE_PIN F40  [get_ports {cam_data[38]}] ; # LA22_N
set_property PACKAGE_PIN G40  [get_ports {cam_data[39]}] ; # LA22_P
set_property PACKAGE_PIN G36  [get_ports {cam_pclk[4]}] ; # LA17_P  P-side CC
set_property PACKAGE_PIN C39  [get_ports {cam_vsync[4]}] ; # LA20_P  mate intentionally unused
set_property PACKAGE_PIN H38  [get_ports {cam_href[4]}] ; # LA31_P
set_property PACKAGE_PIN H34  [get_ports {cam_xclk[4]}] ; # LA19_P
set_property PACKAGE_PIN G38  [get_ports {cam_scl[4]}] ; # LA31_N
set_property PACKAGE_PIN H37  [get_ports {cam_sda[4]}] ; # LA33_N
set_property PACKAGE_PIN G37  [get_ports {cam_rst_n[4]}] ; # LA17_N
set_property PACKAGE_PIN J36  [get_ports {cam_pwdn[4]}] ; # LA33_P

# ---------------------------------------------------------------------------
# CAM5 (FMC2 / Local CAM1 / J1)
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN H35  [get_ports {cam_data[40]}] ; # LA32_N
set_property PACKAGE_PIN J35  [get_ports {cam_data[41]}] ; # LA32_P
set_property PACKAGE_PIN E34  [get_ports {cam_data[42]}] ; # LA30_N
set_property PACKAGE_PIN F34  [get_ports {cam_data[43]}] ; # LA30_P
set_property PACKAGE_PIN H40  [get_ports {cam_data[44]}] ; # LA28_N
set_property PACKAGE_PIN H39  [get_ports {cam_data[45]}] ; # LA28_P
set_property PACKAGE_PIN C37  [get_ports {cam_data[46]}] ; # LA24_N
set_property PACKAGE_PIN D37  [get_ports {cam_data[47]}] ; # LA24_P
set_property PACKAGE_PIN E39  [get_ports {cam_pclk[5]}] ; # LA18_P  P-side CC
set_property PACKAGE_PIN K37  [get_ports {cam_vsync[5]}] ; # LA29_P  mate intentionally unused
set_property PACKAGE_PIN D40  [get_ports {cam_href[5]}] ; # LA27_P
set_property PACKAGE_PIN G35  [get_ports {cam_xclk[5]}] ; # LA19_N
set_property PACKAGE_PIN D39  [get_ports {cam_scl[5]}] ; # LA18_N
set_property PACKAGE_PIN A40  [get_ports {cam_sda[5]}] ; # LA23_N
set_property PACKAGE_PIN C40  [get_ports {cam_rst_n[5]}] ; # LA27_N
set_property PACKAGE_PIN A39  [get_ports {cam_pwdn[5]}] ; # LA23_P

# ---------------------------------------------------------------------------
# CAM6 (FMC2 / Local CAM2 / J2) - CAM2 minimally changed
# Only RESET moved: LA01_N -> LA02_N, to free LA01_N for legacy CAM3 RESET.
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN P31  [get_ports {cam_data[48]}] ; # LA09_N
set_property PACKAGE_PIN R31  [get_ports {cam_data[49]}] ; # LA09_P
set_property PACKAGE_PIN W31  [get_ports {cam_data[50]}] ; # LA12_N
set_property PACKAGE_PIN Y31  [get_ports {cam_data[51]}] ; # LA12_P
set_property PACKAGE_PIN N37  [get_ports {cam_data[52]}] ; # LA13_N
set_property PACKAGE_PIN P37  [get_ports {cam_data[53]}] ; # LA13_P
set_property PACKAGE_PIN K34  [get_ports {cam_data[54]}] ; # LA14_N
set_property PACKAGE_PIN L34  [get_ports {cam_data[55]}] ; # LA14_P
set_property PACKAGE_PIN R34  [get_ports {cam_pclk[6]}] ; # LA01_P  P-side CC
set_property PACKAGE_PIN U31  [get_ports {cam_vsync[6]}] ; # LA05_P
set_property PACKAGE_PIN M36  [get_ports {cam_href[6]}] ; # LA10_P
set_property PACKAGE_PIN N38  [get_ports {cam_xclk[6]}] ; # LA16_P
set_property PACKAGE_PIN L36  [get_ports {cam_scl[6]}] ; # LA10_N
set_property PACKAGE_PIN W34  [get_ports {cam_sda[6]}] ; # LA08_N
set_property PACKAGE_PIN U33  [get_ports {cam_rst_n[6]}] ; # LA02_N  MOVED from LA01_N
set_property PACKAGE_PIN Y34  [get_ports {cam_pwdn[6]}] ; # LA08_P
# ---------------------------------------------------------------------------
# CAM7 (FMC2 / Local CAM3 / J2) - legacy proven-success wiring restored
# ---------------------------------------------------------------------------
set_property PACKAGE_PIN T34  [get_ports {cam_data[56]}] ; # LA04_P
set_property PACKAGE_PIN T35  [get_ports {cam_data[57]}] ; # LA04_N
set_property PACKAGE_PIN M37  [get_ports {cam_data[58]}] ; # LA15_P
set_property PACKAGE_PIN L38  [get_ports {cam_data[59]}] ; # LA15_N
set_property PACKAGE_PIN U35  [get_ports {cam_data[60]}] ; # LA03_P
set_property PACKAGE_PIN T36  [get_ports {cam_data[61]}] ; # LA03_N
set_property PACKAGE_PIN T30  [get_ports {cam_data[62]}] ; # LA06_P
set_property PACKAGE_PIN T31  [get_ports {cam_data[63]}] ; # LA06_N
set_property PACKAGE_PIN T33  [get_ports {cam_pclk[7]}] ; # LA00_P  P-side CC
set_property PACKAGE_PIN Y32  [get_ports {cam_vsync[7]}] ; # LA07_P
set_property PACKAGE_PIN V33  [get_ports {cam_href[7]}] ; # LA11_P
set_property PACKAGE_PIN R33  [get_ports {cam_xclk[7]}] ; # LA00_N  legacy proven wiring
set_property PACKAGE_PIN V34  [get_ports {cam_scl[7]}] ; # LA11_N
set_property PACKAGE_PIN W32  [get_ports {cam_sda[7]}] ; # LA07_N
set_property PACKAGE_PIN P34  [get_ports {cam_rst_n[7]}] ; # LA01_N  legacy proven wiring
set_property PACKAGE_PIN V32  [get_ports {cam_pwdn[7]}] ; # LA02_P
# ============================================================================
# Electrical standard
# ============================================================================
set_property IOSTANDARD LVCMOS18 [get_ports {
    cam_data[*] cam_pclk[*] cam_vsync[*] cam_href[*] cam_xclk[*]
    cam_scl[*] cam_sda[*] cam_rst_n[*] cam_pwdn[*]
}]

# Limit FPGA-driven edge rate on the long single-ended camera wiring.  XCLK
# is the only continuously toggling FPGA output; SCL/reset/PWDN use the same
# conservative setting to avoid injecting fast transients into adjacent LA
# pairs.  This restores the electrical constraints used by the proven older
# pinout.
set_property DRIVE 8 [get_ports {
    cam_xclk[*] cam_scl[*] cam_rst_n[*] cam_pwdn[*]
}]
set_property SLEW SLOW [get_ports {
    cam_xclk[*] cam_scl[*] cam_rst_n[*] cam_pwdn[*]
}]

# Use the high-performance input-buffer path for the source-synchronous DVP
# bus.  This reduces receiver delay/threshold uncertainty; it does not alter
# the existing IOB first-stage sampling architecture.
set_property IBUF_LOW_PWR FALSE [get_ports {
    cam_data[*] cam_pclk[*] cam_vsync[*] cam_href[*]
}]

# ============================================================================
# Source-synchronous DVP input timing
# ============================================================================
# The RGB565 configuration produces a nominal 24 MHz PCLK.  OV7670 changes
# D[7:0] and HREF after the falling PCLK edge; FPGA input flops capture on the
# following rising edge.  The sensor specifies up to 5 ns clock-to-output.
# The -2 ns / +8 ns window adds 3 ns of conservative clock/data PCB and Dupont
# skew around that specification while retaining a half-cycle timing check.
create_clock -name cam_pclk_1 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[0]}]
create_clock -name cam_pclk_2 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[1]}]
create_clock -name cam_pclk_3 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[2]}]
create_clock -name cam_pclk_4 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[3]}]
create_clock -name cam_pclk_5 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[4]}]
create_clock -name cam_pclk_6 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[5]}]
create_clock -name cam_pclk_7 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[6]}]
create_clock -name cam_pclk_8 -period 41.667 -waveform {0.000 20.833} [get_ports {cam_pclk[7]}]

set_input_delay -clock cam_pclk_1 -clock_fall -min -2.000 [get_ports {cam_data[0] cam_data[1] cam_data[2] cam_data[3] cam_data[4] cam_data[5] cam_data[6] cam_data[7] cam_href[0] cam_vsync[0]}]
set_input_delay -clock cam_pclk_1 -clock_fall -max  8.000 [get_ports {cam_data[0] cam_data[1] cam_data[2] cam_data[3] cam_data[4] cam_data[5] cam_data[6] cam_data[7] cam_href[0] cam_vsync[0]}]
set_input_delay -clock cam_pclk_2 -clock_fall -min -2.000 [get_ports {cam_data[8] cam_data[9] cam_data[10] cam_data[11] cam_data[12] cam_data[13] cam_data[14] cam_data[15] cam_href[1] cam_vsync[1]}]
set_input_delay -clock cam_pclk_2 -clock_fall -max  8.000 [get_ports {cam_data[8] cam_data[9] cam_data[10] cam_data[11] cam_data[12] cam_data[13] cam_data[14] cam_data[15] cam_href[1] cam_vsync[1]}]
set_input_delay -clock cam_pclk_3 -clock_fall -min -2.000 [get_ports {cam_data[16] cam_data[17] cam_data[18] cam_data[19] cam_data[20] cam_data[21] cam_data[22] cam_data[23] cam_href[2] cam_vsync[2]}]
set_input_delay -clock cam_pclk_3 -clock_fall -max  8.000 [get_ports {cam_data[16] cam_data[17] cam_data[18] cam_data[19] cam_data[20] cam_data[21] cam_data[22] cam_data[23] cam_href[2] cam_vsync[2]}]
set_input_delay -clock cam_pclk_4 -clock_fall -min -2.000 [get_ports {cam_data[24] cam_data[25] cam_data[26] cam_data[27] cam_data[28] cam_data[29] cam_data[30] cam_data[31] cam_href[3] cam_vsync[3]}]
set_input_delay -clock cam_pclk_4 -clock_fall -max  8.000 [get_ports {cam_data[24] cam_data[25] cam_data[26] cam_data[27] cam_data[28] cam_data[29] cam_data[30] cam_data[31] cam_href[3] cam_vsync[3]}]
set_input_delay -clock cam_pclk_5 -clock_fall -min -2.000 [get_ports {cam_data[32] cam_data[33] cam_data[34] cam_data[35] cam_data[36] cam_data[37] cam_data[38] cam_data[39] cam_href[4] cam_vsync[4]}]
set_input_delay -clock cam_pclk_5 -clock_fall -max  8.000 [get_ports {cam_data[32] cam_data[33] cam_data[34] cam_data[35] cam_data[36] cam_data[37] cam_data[38] cam_data[39] cam_href[4] cam_vsync[4]}]
set_input_delay -clock cam_pclk_6 -clock_fall -min -2.000 [get_ports {cam_data[40] cam_data[41] cam_data[42] cam_data[43] cam_data[44] cam_data[45] cam_data[46] cam_data[47] cam_href[5] cam_vsync[5]}]
set_input_delay -clock cam_pclk_6 -clock_fall -max  8.000 [get_ports {cam_data[40] cam_data[41] cam_data[42] cam_data[43] cam_data[44] cam_data[45] cam_data[46] cam_data[47] cam_href[5] cam_vsync[5]}]
set_input_delay -clock cam_pclk_7 -clock_fall -min -2.000 [get_ports {cam_data[48] cam_data[49] cam_data[50] cam_data[51] cam_data[52] cam_data[53] cam_data[54] cam_data[55] cam_href[6] cam_vsync[6]}]
set_input_delay -clock cam_pclk_7 -clock_fall -max  8.000 [get_ports {cam_data[48] cam_data[49] cam_data[50] cam_data[51] cam_data[52] cam_data[53] cam_data[54] cam_data[55] cam_href[6] cam_vsync[6]}]
set_input_delay -clock cam_pclk_8 -clock_fall -min -2.000 [get_ports {cam_data[56] cam_data[57] cam_data[58] cam_data[59] cam_data[60] cam_data[61] cam_data[62] cam_data[63] cam_href[7] cam_vsync[7]}]
set_input_delay -clock cam_pclk_8 -clock_fall -max  8.000 [get_ports {cam_data[56] cam_data[57] cam_data[58] cam_data[59] cam_data[60] cam_data[61] cam_data[62] cam_data[63] cam_href[7] cam_vsync[7]}]
