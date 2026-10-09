# Vivado 2023.2 write_ip_tcl export; generated files are local Vivado state.
if {[current_project -quiet] eq ""} {
    error "Open a project before creating clk_wiz_ov7670"
}
if {[llength [get_ips -quiet clk_wiz_ov7670]] == 0} {
    create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_ov7670
} elseif {[get_property IPDEF [get_ips clk_wiz_ov7670]] ne "xilinx.com:ip:clk_wiz:6.0"} {
    error "Existing clk_wiz_ov7670 has an incompatible IP version"
}

set_property -dict [list \
  CONFIG.CLKOUT1_REQUESTED_DUTY_CYCLE {50.000} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {24.000} \
  CONFIG.CLKOUT1_REQUESTED_PHASE {0.000} \
  CONFIG.PRIM_IN_FREQ {100.000} \
  CONFIG.PRIM_SOURCE {Global_buffer} \
  CONFIG.RESET_TYPE {ACTIVE_HIGH} \
  CONFIG.USE_LOCKED {true} \
  CONFIG.USE_RESET {true} \
] [get_ips clk_wiz_ov7670]
