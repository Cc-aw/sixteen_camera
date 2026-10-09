# Vivado 2023.2 write_ip_tcl export; generated files are local Vivado state.
if {[current_project -quiet] eq ""} {
    error "Open a project before creating tx_refclk_ibuf"
}
if {[llength [get_ips -quiet tx_refclk_ibuf]] == 0} {
    create_ip -name util_ds_buf -vendor xilinx.com -library ip -version 2.2 -module_name tx_refclk_ibuf
} elseif {[get_property IPDEF [get_ips tx_refclk_ibuf]] ne "xilinx.com:ip:util_ds_buf:2.2"} {
    error "Existing tx_refclk_ibuf has an incompatible IP version"
}

set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} [get_ips tx_refclk_ibuf]
