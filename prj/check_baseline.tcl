set project_file [file normalize [file join [file dirname [info script]] sixteen_camera.xpr]]
open_project $project_file
puts "PROJECT=[get_property NAME [current_project]]"
puts "PART=[get_property PART [current_project]]"
puts "TOP=[get_property TOP [get_filesets sources_1]]"
puts "SOURCE_COUNT=[llength [get_files -of_objects [get_filesets sources_1]]]"
puts "CONSTRAINT_COUNT=[llength [get_files -of_objects [get_filesets constrs_1]]]"
update_compile_order -fileset sources_1
set missing {}
foreach f [get_files -of_objects [get_filesets sources_1]] {
    if {![file exists [get_property NAME $f]]} { lappend missing [get_property NAME $f] }
}
puts "MISSING_COUNT=[llength $missing]"
if {[llength $missing] != 0} { puts "MISSING=$missing" }
close_project
