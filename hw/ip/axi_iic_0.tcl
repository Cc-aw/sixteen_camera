# Vivado 2023.2 write_ip_tcl export; generated files are local Vivado state.
if {[current_project -quiet] eq ""} {
    error "Open a project before creating axi_iic_0"
}
if {[llength [get_ips -quiet axi_iic_0]] == 0} {
    create_ip -name axi_iic -vendor xilinx.com -library ip -version 2.1 -module_name axi_iic_0
} elseif {[get_property IPDEF [get_ips axi_iic_0]] ne "xilinx.com:ip:axi_iic:2.1"} {
    error "Existing axi_iic_0 has an incompatible IP version"
}
