###############################################################################
# Inactive FMC1 HDMI pin-map archive.
# Do not add this file to constrs_1 together with the active hdmi_tx.xdc.
###############################################################################

set_property PACKAGE_PIN AL9 [get_ports hdmi_rx_clk_p]
create_clock -name hdmi_rx_mgt_refclk -period 3.367 \
    [get_ports hdmi_rx_clk_p]
set_property PACKAGE_PIN AP2 [get_ports {hdmi_rx_data_p[0]}]
set_property PACKAGE_PIN AM2 [get_ports {hdmi_rx_data_p[1]}]
set_property PACKAGE_PIN AK2 [get_ports {hdmi_rx_data_p[2]}]

set_property PACKAGE_PIN AU5 [get_ports {hdmi_tx_data_p[0]}]
set_property PACKAGE_PIN AT7 [get_ports {hdmi_tx_data_p[1]}]
set_property PACKAGE_PIN AR5 [get_ports {hdmi_tx_data_p[2]}]
set_property PACKAGE_PIN AP7 [get_ports {hdmi_tx_data_p[3]}]
set_property PACKAGE_PIN AG9 [get_ports hdmi_tx_refclk_p]
create_clock -name hdmi_tx_mgt_refclk -period 3.367 \
    [get_ports hdmi_tx_refclk_p]

set_property PACKAGE_PIN N14 [get_ports hdmi_ref_clk_p]
set_property IOSTANDARD LVDS [get_ports hdmi_ref_clk_p]
set_property PACKAGE_PIN M15 [get_ports hdmi_rx_pwr_det]
set_property PACKAGE_PIN L15 [get_ports hdmi_rx_hpd]
set_property PACKAGE_PIN E11 [get_ports hdmi_rx_ddc_scl]
set_property PACKAGE_PIN F11 [get_ports hdmi_rx_ddc_sda]
set_property IOSTANDARD LVCMOS18 \
    [get_ports {hdmi_rx_pwr_det hdmi_rx_hpd hdmi_rx_ddc_scl hdmi_rx_ddc_sda}]

set_property PACKAGE_PIN M13 [get_ports hdmi_tx_en]
set_property PACKAGE_PIN F10 [get_ports hdmi_tx_hpd]
set_property PACKAGE_PIN M12 [get_ports hdmi_tx_ddc_scl]
set_property PACKAGE_PIN V13 [get_ports hdmi_tx_ddc_sda]
set_property IOSTANDARD LVCMOS18 \
    [get_ports {hdmi_tx_en hdmi_tx_hpd hdmi_tx_ddc_scl hdmi_tx_ddc_sda}]

set_property PACKAGE_PIN AA12 [get_ports hdmi_clkchip_scl]
set_property PACKAGE_PIN U12  [get_ports hdmi_clkchip_sda]
set_property PACKAGE_PIN Y12  [get_ports hdmi_clkchip_lol]
set_property PACKAGE_PIN H15  [get_ports hdmi_clkchip_int]
set_property PACKAGE_PIN H14  [get_ports hdmi_clkchip_rst]
set_property IOSTANDARD LVCMOS18 \
    [get_ports {hdmi_clkchip_scl hdmi_clkchip_sda hdmi_clkchip_lol \
                hdmi_clkchip_int hdmi_clkchip_rst}]

