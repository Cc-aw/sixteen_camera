# Vivado 2023.2 write_ip_tcl export; generated files are local Vivado state.
if {[current_project -quiet] eq ""} {
    error "Open a project before creating tx_axis_reg_slice"
}
if {[llength [get_ips -quiet tx_axis_reg_slice]] == 0} {
    create_ip -name axis_register_slice -vendor xilinx.com -library ip -version 1.1 -module_name tx_axis_reg_slice
} elseif {[get_property IPDEF [get_ips tx_axis_reg_slice]] ne "xilinx.com:ip:axis_register_slice:1.1"} {
    error "Existing tx_axis_reg_slice has an incompatible IP version"
}

set_property -dict [list \
  CONFIG.HAS_TLAST {1} \
  CONFIG.TDATA_NUM_BYTES {6} \
  CONFIG.TUSER_WIDTH {1} \
] [get_ips tx_axis_reg_slice]
