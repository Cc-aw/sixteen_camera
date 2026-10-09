# Vivado 2023.2 write_ip_tcl export; generated files are local Vivado state.
if {[current_project -quiet] eq ""} {
    error "Open a project before creating v_hdmi_rx_ss_0"
}
if {[llength [get_ips -quiet v_hdmi_rx_ss_0]] == 0} {
    create_ip -name v_hdmi_rx_ss -vendor xilinx.com -library ip -version 3.2 -module_name v_hdmi_rx_ss_0
} elseif {[get_property IPDEF [get_ips v_hdmi_rx_ss_0]] ne "xilinx.com:ip:v_hdmi_rx_ss:3.2"} {
    error "Existing v_hdmi_rx_ss_0 has an incompatible IP version"
}

set_property -dict [list \
  CONFIG.C_CD_INVERT {true} \
  CONFIG.C_INCLUDE_LOW_RESO_VID {false} \
  CONFIG.C_INCLUDE_YUV420_SUP {true} \
] [get_ips v_hdmi_rx_ss_0]
