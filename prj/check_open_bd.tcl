puts "CHECK_START"
set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
set bd_file [get_files -quiet */design_1.bd]
puts "BD_COUNT=[llength $bd_file]"
open_bd_design $bd_file
puts "BD_OPEN"
validate_bd_design
puts "BD_VALIDATED"
close_project
