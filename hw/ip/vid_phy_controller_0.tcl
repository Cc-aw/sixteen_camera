# Vivado 2023.2 write_ip_tcl export; generated files are local Vivado state.
if {[current_project -quiet] eq ""} {
    error "Open a project before creating vid_phy_controller_0"
}
if {[llength [get_ips -quiet vid_phy_controller_0]] == 0} {
    create_ip -name vid_phy_controller -vendor xilinx.com -library ip -version 2.2 -module_name vid_phy_controller_0
} elseif {[get_property IPDEF [get_ips vid_phy_controller_0]] ne "xilinx.com:ip:vid_phy_controller:2.2"} {
    error "Existing vid_phy_controller_0 has an incompatible IP version"
}

set_property -dict [list \
  CONFIG.CHANNEL_SITE {X0Y20} \
  CONFIG.C_INPUT_PIXELS_PER_CLOCK {2} \
  CONFIG.C_NIDRU {false} \
  CONFIG.C_Rx_Protocol {HDMI} \
  CONFIG.C_TX_REFCLK_SEL {4} \
  CONFIG.C_Tx_Protocol {HDMI} \
  CONFIG.C_Txrefclk_Rdy_Invert {true} \
  CONFIG.C_Use_GT_CH4_HDMI {true} \
] [get_ips vid_phy_controller_0]
