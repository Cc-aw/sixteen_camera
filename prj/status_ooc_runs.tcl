set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
set names {}
foreach run [get_runs] {
    set name [get_property NAME $run]
    if {[string match "design_1_*_synth_1" $name] || $name eq "synth_1"} {
        lappend names $name
        puts "RUN=$name STATUS=[get_property STATUS $run] PROGRESS=[get_property PROGRESS $run]"
    }
}
puts "OOC_RUN_COUNT=[llength $names]"
close_project
