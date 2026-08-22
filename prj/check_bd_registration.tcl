set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
set bd_file [get_files -quiet */design_1.bd]
set wrapper_files [get_files -quiet */design_1_wrapper.v]
set generated_design [get_files -quiet */design_1.v]
set non_generated_design {}
foreach generated_file $generated_design {
    if {[get_property IS_GENERATED $generated_file] ne "1"} {
        lappend non_generated_design $generated_file
    }
}
puts "BD_COUNT=[llength $bd_file]"
puts "WRAPPER_COUNT=[llength $wrapper_files]"
puts "GENERATED_DESIGN_REGISTERED=[llength $generated_design]"
puts "GENERATED_DESIGN_PATHS=$generated_design"
puts "NON_GENERATED_DESIGN_PATHS=$non_generated_design"
puts "BD_PATH=$bd_file"
puts "WRAPPER_PATH=$wrapper_files"
if {[llength $bd_file] != 1 || [llength $wrapper_files] != 1 || [llength $non_generated_design] != 0} {
    error "BD source/wrapper registration is incorrect"
}
close_project
