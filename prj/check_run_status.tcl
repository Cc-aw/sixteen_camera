set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
foreach run [get_runs] {
    puts "RUN=[get_property NAME $run] STATUS=[get_property STATUS $run] DIR=[get_property DIRECTORY $run]"
}
close_project
