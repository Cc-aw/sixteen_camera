set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
set bd_file [get_files -quiet */design_1.bd]
if {[llength $bd_file] != 1} { error "BD_COUNT=[llength $bd_file]" }
open_bd_design $bd_file
validate_bd_design
set bd_ip_count [llength [get_bd_cells -quiet -filter {TYPE == ip}]]
set wrapper_files [get_files -quiet */design_1_wrapper.v]
set generated_design [get_files -quiet */design_1.v]
puts "BD_IP_COUNT=$bd_ip_count"
puts "WRAPPER_COUNT=[llength $wrapper_files]"
puts "GENERATED_DESIGN_REGISTERED=[llength $generated_design]"
puts "BD_PATH=$bd_file"
if {[llength $wrapper_files] != 1 || [llength $generated_design] != 0} {
    error "BD source/wrapper registration is incorrect"
}
close_project
