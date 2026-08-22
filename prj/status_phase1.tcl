set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
update_compile_order -fileset sources_1
set bd_file [get_files -quiet */design_1.bd]
set wrapper_file [get_files -quiet */design_1_wrapper.v]
set top [get_property top [get_filesets sources_1]]
set missing {}
set generated_count 0
set source_count 0
foreach file_obj [get_files -of_objects [get_filesets sources_1]] {
    incr source_count
    if {[get_property IS_GENERATED $file_obj] eq "1"} { incr generated_count }
    if {![file exists [get_property NAME $file_obj]]} {
        lappend missing [get_property NAME $file_obj]
    }
}
puts "PROJECT=[get_property NAME [current_project]]"
puts "PART=[get_property PART [current_project]]"
puts "TOP=$top"
puts "SOURCE_COUNT=$source_count"
puts "GENERATED_SOURCE_COUNT=$generated_count"
puts "BD_COUNT=[llength $bd_file]"
puts "WRAPPER_COUNT=[llength $wrapper_file]"
puts "MISSING_SOURCE_COUNT=[llength $missing]"
if {[llength $missing] != 0} { puts "MISSING_SOURCES=$missing" }
close_project
