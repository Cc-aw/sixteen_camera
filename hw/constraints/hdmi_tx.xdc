###############################################################################
# FMC3 HDMI 2.0 GTY signals
#
# Only the P pin of each GT differential pair is assigned, matching the AMD
# HDMI example and the verified 4k60to1k60 project. The N pin is paired by the
# GT resource.
###############################################################################

# HDMI RX GT reference clock and three data lanes feed the shared Video PHY.
set_property PACKAGE_PIN AN40 [get_ports hdmi_rx_clk_p]
create_clock -name hdmi_rx_mgt_refclk -period 3.367 \
    [get_ports hdmi_rx_clk_p]

set_property PACKAGE_PIN BC45 [get_ports {hdmi_rx_data_p[0]}]
set_property PACKAGE_PIN BA45 [get_ports {hdmi_rx_data_p[1]}]
set_property PACKAGE_PIN AW45 [get_ports {hdmi_rx_data_p[2]}]

# HDMI TX: Bank 125 CH0..CH3. CH3 carries the serialized TMDS clock.
set_property PACKAGE_PIN BD42 [get_ports {hdmi_tx_data_p[0]}]
set_property PACKAGE_PIN BB42 [get_ports {hdmi_tx_data_p[1]}]
set_property PACKAGE_PIN AY42 [get_ports {hdmi_tx_data_p[2]}]
set_property PACKAGE_PIN AV42 [get_ports {hdmi_tx_data_p[3]}]

# 8T49N241 output enters Bank 126 REFCLK0 and reaches Bank 125 through the
# adjacent-Quad reference-clock path selected by the Video PHY configuration.
set_property PACKAGE_PIN AK38 [get_ports hdmi_tx_refclk_p]
create_clock -name hdmi_tx_mgt_refclk -period 3.367 \
    [get_ports hdmi_tx_refclk_p]

###############################################################################
# FMC HDMI control and recovered-clock signals (VCCO = 1.8 V)
###############################################################################

set_property PACKAGE_PIN BC10 [get_ports hdmi_ref_clk_p]
set_property IOSTANDARD LVDS [get_ports hdmi_ref_clk_p]

set_property PACKAGE_PIN BC11 [get_ports hdmi_rx_pwr_det]
set_property PACKAGE_PIN BD11 [get_ports hdmi_rx_hpd]
set_property PACKAGE_PIN AY13 [get_ports hdmi_rx_ddc_scl]
set_property PACKAGE_PIN AW13 [get_ports hdmi_rx_ddc_sda]
set_property IOSTANDARD LVCMOS18 \
    [get_ports {hdmi_rx_pwr_det hdmi_rx_hpd hdmi_rx_ddc_scl hdmi_rx_ddc_sda}]

set_property PACKAGE_PIN BD8  [get_ports hdmi_tx_en]
set_property PACKAGE_PIN AU16 [get_ports hdmi_tx_hpd]
set_property PACKAGE_PIN BD7  [get_ports hdmi_tx_ddc_scl]
set_property PACKAGE_PIN BA7  [get_ports hdmi_tx_ddc_sda]
set_property IOSTANDARD LVCMOS18 \
    [get_ports {hdmi_tx_en hdmi_tx_hpd hdmi_tx_ddc_scl hdmi_tx_ddc_sda}]

set_property PACKAGE_PIN BC15 [get_ports hdmi_clkchip_scl]
set_property PACKAGE_PIN BB7  [get_ports hdmi_clkchip_sda]
set_property PACKAGE_PIN BD15 [get_ports hdmi_clkchip_lol]
set_property PACKAGE_PIN AW11 [get_ports hdmi_clkchip_int]
set_property PACKAGE_PIN AY10 [get_ports hdmi_clkchip_rst]
set_property IOSTANDARD LVCMOS18 \
    [get_ports {hdmi_clkchip_scl hdmi_clkchip_sda hdmi_clkchip_lol \
                hdmi_clkchip_int hdmi_clkchip_rst}]
