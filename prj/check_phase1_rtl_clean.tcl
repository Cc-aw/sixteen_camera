set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
set_property INCREMENTAL_CHECKPOINT {} [get_runs synth_1]
update_compile_order -fileset sources_1
synth_design -rtl -name rtl_phase1_clean -top top_wrapper -part xcvu13p-fhga2104-2-i
puts "PHASE1_RTL_ELABORATION_CLEAN=PASS"
close_design
close_project
