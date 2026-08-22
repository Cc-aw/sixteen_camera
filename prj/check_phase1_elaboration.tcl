set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
update_compile_order -fileset sources_1
set bd_rtl [file normalize [file join $script_dir sixteen_camera.gen \
    sources_1 bd design_1 synth design_1.v]]
if {[llength [get_files -quiet $bd_rtl]] == 0} {
    add_files -fileset sources_1 -norecurse $bd_rtl
}
synth_design -rtl -name rtl_phase1 -top top_wrapper \
    -part xcvu13p-fhga2104-2-i
puts "PHASE1_RTL_ELABORATION=PASS"
close_design
close_project
