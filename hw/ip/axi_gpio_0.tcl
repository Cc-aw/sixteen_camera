# Vivado 2023.2 write_ip_tcl export; generated files are local Vivado state.
if {[current_project -quiet] eq ""} {
    error "Open a project before creating axi_gpio_0"
}
if {[llength [get_ips -quiet axi_gpio_0]] == 0} {
    create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name axi_gpio_0
} elseif {[get_property IPDEF [get_ips axi_gpio_0]] ne "xilinx.com:ip:axi_gpio:2.0"} {
    error "Existing axi_gpio_0 has an incompatible IP version"
}

set_property -dict [list \
  CONFIG.C_ALL_INPUTS_2 {1} \
  CONFIG.C_ALL_OUTPUTS {1} \
  CONFIG.C_GPIO2_WIDTH {5} \
  CONFIG.C_INTERRUPT_PRESENT {1} \
  CONFIG.C_IS_DUAL {1} \
] [get_ips axi_gpio_0]
