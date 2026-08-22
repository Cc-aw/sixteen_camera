puts "CHECK_START"
set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
puts "PROJECT_OPEN"
set bd_file [get_files -quiet */design_1.bd]
puts "BD_COUNT=[llength $bd_file]"
close_project
puts "CHECK_DONE"
