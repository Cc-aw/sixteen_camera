set script_dir [file dirname [info script]]
open_project [file normalize [file join $script_dir sixteen_camera.xpr]]

update_compile_order -fileset sources_1
reset_run synth_1
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
puts "IMPL_STATUS=[get_property STATUS [get_runs impl_1]]"
close_project
