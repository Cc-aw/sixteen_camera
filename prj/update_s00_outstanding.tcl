set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
open_bd_design [get_files design_1.bd]

set s00 [get_bd_intf_ports S00_AXI]
if {$s00 eq ""} {
    error "design_1 does not contain the S00_AXI interface"
}

set_property -dict [list \
    CONFIG.NUM_READ_OUTSTANDING {8} \
    CONFIG.NUM_WRITE_OUTSTANDING {8}] $s00

validate_bd_design
save_bd_design
generate_target all [get_files design_1.bd]
export_ip_user_files -of_objects [get_files design_1.bd] \
    -no_script -sync -force

set read_depth [get_property CONFIG.NUM_READ_OUTSTANDING $s00]
set write_depth [get_property CONFIG.NUM_WRITE_OUTSTANDING $s00]
if {$read_depth != 8 || $write_depth != 8} {
    error "S00 outstanding update failed: read=$read_depth write=$write_depth"
}

puts "S00_OUTSTANDING_UPDATE=PASS read=$read_depth write=$write_depth"
close_project
