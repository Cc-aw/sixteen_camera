set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
open_bd_design [get_files design_1.bd]

set interconnect [get_bd_cells axi_interconnect_0]
set mig [get_bd_cells ddr4_0]
set_property CONFIG.M00_HAS_REGSLICE 0 $interconnect

set slice [get_bd_cells -quiet m00_full_regslice]
if {$slice eq ""} {
    set slice [create_bd_cell -type ip \
        -vlnv xilinx.com:ip:axi_register_slice:2.1 m00_full_regslice]
}
set_property -dict [list \
    CONFIG.ADDR_WIDTH {32} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {4} \
    CONFIG.REG_AW {7} CONFIG.REG_W {7} CONFIG.REG_B {7} \
    CONFIG.REG_AR {7} CONFIG.REG_R {7}] $slice

# Remove prior interface connections so repeated updates remain idempotent.
foreach pin_path [list \
    "$interconnect/M00_AXI" "$slice/S_AXI" "$slice/M_AXI" \
    "$mig/C0_DDR4_S_AXI"] {
    set pin [get_bd_intf_pins -quiet $pin_path]
    if {$pin ne ""} {
        foreach net [get_bd_intf_nets -quiet -of_objects $pin] {
            disconnect_bd_intf_net $net $pin
        }
    }
}

foreach pin_path [list "$slice/aclk" "$slice/aresetn"] {
    set pin [get_bd_pins -quiet $pin_path]
    if {$pin ne ""} {
        foreach net [get_bd_nets -quiet -of_objects $pin] {
            disconnect_bd_net $net $pin
        }
    }
}

connect_bd_intf_net [get_bd_intf_pins $interconnect/M00_AXI] \
    [get_bd_intf_pins $slice/S_AXI]
connect_bd_intf_net [get_bd_intf_pins $slice/M_AXI] \
    [get_bd_intf_pins $mig/C0_DDR4_S_AXI]
connect_bd_net [get_bd_pins $mig/c0_ddr4_ui_clk] \
    [get_bd_pins $slice/aclk]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
    [get_bd_pins $slice/aresetn]

validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
export_ip_user_files -of_objects [get_files design_1.bd] -no_script -sync -force
close_project
