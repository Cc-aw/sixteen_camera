set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]

# Synchronize repository sources before starting a clean top-level synthesis.
source [file join $script_dir .. setup_vivado.tcl]
update_compile_order -fileset sources_1

set synth_run [get_runs synth_1]
set_property AUTO_INCREMENTAL_CHECKPOINT 0 $synth_run
set_property INCREMENTAL_CHECKPOINT {} $synth_run
reset_run $synth_run
launch_runs $synth_run -jobs 8
wait_on_run $synth_run

set synth_status [get_property STATUS $synth_run]
set synth_progress [get_property PROGRESS $synth_run]
puts "SYNTH_STATUS=$synth_status"
puts "SYNTH_PROGRESS=$synth_progress"
if {$synth_status ne "synth_design Complete!" || $synth_progress ne "100%"} {
    error "Synthesis did not complete"
}

puts "SYNTHESIS_BUILD=PASS"
close_project
