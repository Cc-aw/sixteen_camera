# VU13P / BCVU13 - 8x OV7670
# FMC1 -> CAM0..CAM3
# FMC2 -> CAM4..CAM7
# ATK-FMC-EXTIO BOOT_01=OFF, BOOT_02=OFF (TXS mode for SCCB)
# FPGA-side IO voltage: 1.8 V through EXTIO level translators
# PCLK uses P-side Clock-Capable pins only:
#   CAM0/4 LA17_P_CC, CAM1/5 LA18_P_CC, CAM2/6 LA01_P_CC, CAM3/7 LA00_P_CC
# No CLOCK_DEDICATED_ROUTE FALSE is required for these PCLK assignments.
# Add create_clock constraints after final OV7670 PCLK frequency is known.

# -----------------------------------------------------------------------------
# CAM0 (FMC1)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN F9  [get_ports {cam0_d[0]}]
set_property PACKAGE_PIN F10 [get_ports {cam0_d[1]}]
set_property PACKAGE_PIN C7  [get_ports {cam0_d[2]}]
set_property PACKAGE_PIN D7  [get_ports {cam0_d[3]}]
set_property PACKAGE_PIN C8  [get_ports {cam0_d[4]}]
set_property PACKAGE_PIN C9  [get_ports {cam0_d[5]}]
set_property PACKAGE_PIN E11 [get_ports {cam0_d[6]}]
set_property PACKAGE_PIN F11 [get_ports {cam0_d[7]}]
set_property PACKAGE_PIN E12 [get_ports {cam0_pclk}]
set_property PACKAGE_PIN H15 [get_ports {cam0_vsync}]
set_property PACKAGE_PIN H14 [get_ports {cam0_href}]
set_property PACKAGE_PIN D12 [get_ports {cam0_xclk}]
set_property PACKAGE_PIN B13 [get_ports {cam0_scl}]
set_property PACKAGE_PIN E13 [get_ports {cam0_sda}]
set_property PACKAGE_PIN C13 [get_ports {cam0_reset}]
set_property PACKAGE_PIN E9  [get_ports {cam0_pwdn}]

# -----------------------------------------------------------------------------
# CAM1 (FMC1)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN F15 [get_ports {cam1_d[0]}]
set_property PACKAGE_PIN G15 [get_ports {cam1_d[1]}]
set_property PACKAGE_PIN G12 [get_ports {cam1_d[2]}]
set_property PACKAGE_PIN H12 [get_ports {cam1_d[3]}]
set_property PACKAGE_PIN G10 [get_ports {cam1_d[4]}]
set_property PACKAGE_PIN G11 [get_ports {cam1_d[5]}]
set_property PACKAGE_PIN B7  [get_ports {cam1_d[6]}]
set_property PACKAGE_PIN B8  [get_ports {cam1_d[7]}]
set_property PACKAGE_PIN F13 [get_ports {cam1_pclk}]
set_property PACKAGE_PIN D11 [get_ports {cam1_vsync}]
set_property PACKAGE_PIN D10 [get_ports {cam1_href}]
set_property PACKAGE_PIN D9  [get_ports {cam1_xclk}]
set_property PACKAGE_PIN B12 [get_ports {cam1_scl}]
set_property PACKAGE_PIN E14 [get_ports {cam1_sda}]
set_property PACKAGE_PIN F14 [get_ports {cam1_reset}]
set_property PACKAGE_PIN C12 [get_ports {cam1_pwdn}]

# -----------------------------------------------------------------------------
# CAM2 (FMC1)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN W12  [get_ports {cam2_d[0]}]
set_property PACKAGE_PIN V12  [get_ports {cam2_d[1]}]
set_property PACKAGE_PIN V13  [get_ports {cam2_d[2]}]
set_property PACKAGE_PIN U12  [get_ports {cam2_d[3]}]
set_property PACKAGE_PIN R12  [get_ports {cam2_d[4]}]
set_property PACKAGE_PIN P12  [get_ports {cam2_d[5]}]
set_property PACKAGE_PIN R11  [get_ports {cam2_d[6]}]
set_property PACKAGE_PIN P11  [get_ports {cam2_d[7]}]
set_property PACKAGE_PIN R14  [get_ports {cam2_pclk}]
set_property PACKAGE_PIN V14  [get_ports {cam2_vsync}]
set_property PACKAGE_PIN W14  [get_ports {cam2_href}]
set_property PACKAGE_PIN AA12 [get_ports {cam2_xclk}]
set_property PACKAGE_PIN L13  [get_ports {cam2_scl}]
set_property PACKAGE_PIN M12  [get_ports {cam2_sda}]
set_property PACKAGE_PIN M13  [get_ports {cam2_reset}]
set_property PACKAGE_PIN L14  [get_ports {cam2_pwdn}]

# -----------------------------------------------------------------------------
# CAM3 (FMC1)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN T16  [get_ports {cam3_d[0]}]
set_property PACKAGE_PIN T15  [get_ports {cam3_d[1]}]
set_property PACKAGE_PIN AA14 [get_ports {cam3_d[2]}]
set_property PACKAGE_PIN Y14  [get_ports {cam3_d[3]}]
set_property PACKAGE_PIN M15  [get_ports {cam3_d[4]}]
set_property PACKAGE_PIN L15  [get_ports {cam3_d[5]}]
set_property PACKAGE_PIN P15  [get_ports {cam3_d[6]}]
set_property PACKAGE_PIN N15  [get_ports {cam3_d[7]}]
set_property PACKAGE_PIN N14  [get_ports {cam3_pclk}]
set_property PACKAGE_PIN V15  [get_ports {cam3_vsync}]
set_property PACKAGE_PIN AA13 [get_ports {cam3_href}]
set_property PACKAGE_PIN N13  [get_ports {cam3_xclk}]
set_property PACKAGE_PIN Y13  [get_ports {cam3_scl}]
set_property PACKAGE_PIN U15  [get_ports {cam3_sda}]
set_property PACKAGE_PIN P14  [get_ports {cam3_reset}]
set_property PACKAGE_PIN V16  [get_ports {cam3_pwdn}]

# -----------------------------------------------------------------------------
# CAM4 (FMC2)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN F39 [get_ports {cam4_d[0]}]
set_property PACKAGE_PIN F38 [get_ports {cam4_d[1]}]
set_property PACKAGE_PIN A38 [get_ports {cam4_d[2]}]
set_property PACKAGE_PIN B38 [get_ports {cam4_d[3]}]
set_property PACKAGE_PIN J40 [get_ports {cam4_d[4]}]
set_property PACKAGE_PIN J39 [get_ports {cam4_d[5]}]
set_property PACKAGE_PIN F40 [get_ports {cam4_d[6]}]
set_property PACKAGE_PIN G40 [get_ports {cam4_d[7]}]
set_property PACKAGE_PIN G36 [get_ports {cam4_pclk}]
set_property PACKAGE_PIN C39 [get_ports {cam4_vsync}]
set_property PACKAGE_PIN B40 [get_ports {cam4_href}]
set_property PACKAGE_PIN G37 [get_ports {cam4_xclk}]
set_property PACKAGE_PIN A40 [get_ports {cam4_scl}]
set_property PACKAGE_PIN D39 [get_ports {cam4_sda}]
set_property PACKAGE_PIN A39 [get_ports {cam4_reset}]
set_property PACKAGE_PIN D40 [get_ports {cam4_pwdn}]

# -----------------------------------------------------------------------------
# CAM5 (FMC2)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN E34 [get_ports {cam5_d[0]}]
set_property PACKAGE_PIN F34 [get_ports {cam5_d[1]}]
set_property PACKAGE_PIN H40 [get_ports {cam5_d[2]}]
set_property PACKAGE_PIN H39 [get_ports {cam5_d[3]}]
set_property PACKAGE_PIN C37 [get_ports {cam5_d[4]}]
set_property PACKAGE_PIN D37 [get_ports {cam5_d[5]}]
set_property PACKAGE_PIN G35 [get_ports {cam5_d[6]}]
set_property PACKAGE_PIN H34 [get_ports {cam5_d[7]}]
set_property PACKAGE_PIN E39 [get_ports {cam5_pclk}]
set_property PACKAGE_PIN K37 [get_ports {cam5_vsync}]
set_property PACKAGE_PIN J37 [get_ports {cam5_href}]
set_property PACKAGE_PIN C40 [get_ports {cam5_xclk}]
set_property PACKAGE_PIN H37 [get_ports {cam5_scl}]
set_property PACKAGE_PIN G38 [get_ports {cam5_sda}]
set_property PACKAGE_PIN H38 [get_ports {cam5_reset}]
set_property PACKAGE_PIN J36 [get_ports {cam5_pwdn}]

# -----------------------------------------------------------------------------
# CAM6 (FMC2)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN R31 [get_ports {cam6_d[0]}]
set_property PACKAGE_PIN P31 [get_ports {cam6_d[1]}]
set_property PACKAGE_PIN Y31 [get_ports {cam6_d[2]}]
set_property PACKAGE_PIN W31 [get_ports {cam6_d[3]}]
set_property PACKAGE_PIN P37 [get_ports {cam6_d[4]}]
set_property PACKAGE_PIN N37 [get_ports {cam6_d[5]}]
set_property PACKAGE_PIN L34 [get_ports {cam6_d[6]}]
set_property PACKAGE_PIN K34 [get_ports {cam6_d[7]}]
set_property PACKAGE_PIN R34 [get_ports {cam6_pclk}]
set_property PACKAGE_PIN U32 [get_ports {cam6_vsync}]
set_property PACKAGE_PIN U31 [get_ports {cam6_href}]
set_property PACKAGE_PIN N38 [get_ports {cam6_xclk}]
set_property PACKAGE_PIN L36 [get_ports {cam6_scl}]
set_property PACKAGE_PIN W34 [get_ports {cam6_sda}]
set_property PACKAGE_PIN Y34 [get_ports {cam6_reset}]
set_property PACKAGE_PIN M36 [get_ports {cam6_pwdn}]

# -----------------------------------------------------------------------------
# CAM7 (FMC2)
# -----------------------------------------------------------------------------
set_property PACKAGE_PIN T34 [get_ports {cam7_d[0]}]
set_property PACKAGE_PIN T35 [get_ports {cam7_d[1]}]
set_property PACKAGE_PIN M37 [get_ports {cam7_d[2]}]
set_property PACKAGE_PIN L38 [get_ports {cam7_d[3]}]
set_property PACKAGE_PIN U35 [get_ports {cam7_d[4]}]
set_property PACKAGE_PIN T36 [get_ports {cam7_d[5]}]
set_property PACKAGE_PIN T30 [get_ports {cam7_d[6]}]
set_property PACKAGE_PIN T31 [get_ports {cam7_d[7]}]
set_property PACKAGE_PIN T33 [get_ports {cam7_pclk}]
set_property PACKAGE_PIN Y32 [get_ports {cam7_vsync}]
set_property PACKAGE_PIN V33 [get_ports {cam7_href}]
set_property PACKAGE_PIN R33 [get_ports {cam7_xclk}]
set_property PACKAGE_PIN V34 [get_ports {cam7_scl}]
set_property PACKAGE_PIN W32 [get_ports {cam7_sda}]
set_property PACKAGE_PIN P34 [get_ports {cam7_reset}]
set_property PACKAGE_PIN V32 [get_ports {cam7_pwdn}]

# Apply LVCMOS18 to all OV7670 ports
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_* cam1_* cam2_* cam3_* cam4_* cam5_* cam6_* cam7_*}]
